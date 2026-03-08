import 'package:firebase_storage/firebase_storage.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:school_app/models/school_branding.dart';
import 'package:school_app/providers/school_branding_provider.dart';
import 'package:school_app/providers/school_admin_provider.dart';
import 'package:school_app/providers/school_provider.dart';

class BrandingScreen extends ConsumerStatefulWidget {
  const BrandingScreen({super.key});

  @override
  ConsumerState<BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends ConsumerState<BrandingScreen> {
  bool _initializedFromRemote = false;
  bool _hasLocalEdits = false;

  Color _primary = const Color(SchoolBranding.defaultPrimaryColorValue);
  Color _secondary = const Color(SchoolBranding.defaultSecondaryColorValue);

  bool _uploadingLogo = false;

  @override
  Widget build(BuildContext context) {
    final schoolName = ref.watch(schoolProvider).maybeWhen(
          data: (doc) => (doc.data()?['name'] ?? '').toString().trim(),
          orElse: () => '',
        );

    final brandingAsync = ref.watch(schoolBrandingProvider);
    final logoUrlAsync = ref.watch(schoolBrandingLogoUrlProvider);

    ref.listen<AsyncValue<SchoolBranding>>(schoolBrandingProvider, (prev, next) {
      final remote = next.asData?.value;
      if (remote == null) return;

      if (!_initializedFromRemote && mounted) {
        setState(() {
          _primary = remote.primaryColor;
          _secondary = remote.secondaryColor;
          _initializedFromRemote = true;
          _hasLocalEdits = false;
        });
        return;
      }

      // If the user hasn't made local edits, keep the UI in sync.
      if (!_hasLocalEdits && mounted) {
        setState(() {
          _primary = remote.primaryColor;
          _secondary = remote.secondaryColor;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branding'),
        actions: [
          IconButton(
            tooltip: 'Reset to SK default',
            onPressed: _uploadingLogo
                ? null
                : () {
                    setState(() {
                      _primary = const Color(SchoolBranding.defaultPrimaryColorValue);
                      _secondary = const Color(SchoolBranding.defaultSecondaryColorValue);
                      _hasLocalEdits = true;
                    });
                  },
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: (_uploadingLogo || brandingAsync.isLoading)
                ? null
                : () async {
                    final current = brandingAsync.asData?.value ?? SchoolBranding.defaults();
                    final updated = current.copyWith(
                      primaryColorValue: _primary.toARGB32(),
                      secondaryColorValue: _secondary.toARGB32(),
                    );

                    try {
                      await ref.read(saveSchoolBrandingProvider)(branding: updated);
                      if (!context.mounted) return;
                      setState(() => _hasLocalEdits = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Branding saved')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: brandingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load branding: $e'),
          ),
        ),
        data: (branding) {
          final logoUrl = logoUrlAsync.asData?.value;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      _PreviewHeader(
                        schoolName: schoolName.isEmpty ? 'Your School' : schoolName,
                        primary: _primary,
                        secondary: _secondary,
                        logoUrl: logoUrl,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tip: Branding is shown after login (safe mode) — super admin always uses the SK theme.',
                        style: TextStyle(color: Color(0xFF64748B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logo',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _LogoPreview(logoUrl: logoUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (branding.logoPath ?? '').trim().isEmpty
                                      ? 'No logo uploaded yet'
                                      : 'Logo uploaded',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Recommended: square image (e.g., 512×512).',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: _uploadingLogo
                                ? null
                                : () => _pickAndUploadLogo(context, branding),
                            icon: _uploadingLogo
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_rounded),
                            label: Text(_uploadingLogo ? 'Uploading...' : 'Upload logo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: (_uploadingLogo || (branding.logoPath ?? '').trim().isEmpty)
                                ? null
                                : () => _removeLogo(context, branding),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gradient colors',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fixed direction: top-left → bottom-right',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      ColorPicker(
                        color: _primary,
                        onColorChanged: (c) => setState(() {
                          _primary = c;
                          _hasLocalEdits = true;
                        }),
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.wheel: true,
                          ColorPickerType.accent: false,
                          ColorPickerType.primary: false,
                          ColorPickerType.both: false,
                          ColorPickerType.custom: false,
                        },
                        enableShadesSelection: false,
                        heading: const Text(
                          'Primary',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Divider(height: 24),
                      ColorPicker(
                        color: _secondary,
                        onColorChanged: (c) => setState(() {
                          _secondary = c;
                          _hasLocalEdits = true;
                        }),
                        pickersEnabled: const <ColorPickerType, bool>{
                          ColorPickerType.wheel: true,
                          ColorPickerType.accent: false,
                          ColorPickerType.primary: false,
                          ColorPickerType.both: false,
                          ColorPickerType.custom: false,
                        },
                        enableShadesSelection: false,
                        heading: const Text(
                          'Secondary',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Note: Uploading logos requires Firebase Storage to be enabled in the Firebase Console for your project.',
                style: TextStyle(color: Color(0xFF64748B), height: 1.35),
              ),
              const SizedBox(height: 70),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context, SchoolBranding branding) async {
    setState(() => _uploadingLogo = true);

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) {
        setState(() => _uploadingLogo = false);
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Selected file is empty');
      }

      final schoolId = await ref.read(schoolIdProvider.future);
      final objectPath = 'schools/$schoolId/branding/logo';

      final contentType = _contentTypeForFileName(file.name);

      await FirebaseStorage.instance
          .ref(objectPath)
          .putData(
            bytes,
            SettableMetadata(
              contentType: contentType,
              cacheControl: 'public,max-age=3600',
            ),
          );

      await ref.read(saveSchoolBrandingProvider)(
            branding: branding.copyWith(
              logoPath: objectPath,
              primaryColorValue: _primary.toARGB32(),
              secondaryColorValue: _secondary.toARGB32(),
            ),
          );

      if (!context.mounted) return;
      setState(() {
        _uploadingLogo = false;
        _hasLocalEdits = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo uploaded')),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _uploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
    }
  }

  Future<void> _removeLogo(BuildContext context, SchoolBranding branding) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove logo?'),
        content: const Text('This will remove the logo from dashboards and marks cards.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _uploadingLogo = true);
    try {
      final objectPath = (branding.logoPath ?? '').trim();
      if (objectPath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(objectPath).delete();
        } catch (_) {
          // Ignore delete failures; we still clear the pointer.
        }
      }

      await ref.read(saveSchoolBrandingProvider)(
            branding: branding.copyWith(
              logoPath: null,
              primaryColorValue: _primary.toARGB32(),
              secondaryColorValue: _secondary.toARGB32(),
            ),
          );

      if (!context.mounted) return;
      setState(() {
        _uploadingLogo = false;
        _hasLocalEdits = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo removed')),
      );
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _uploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  String _contentTypeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.schoolName,
    required this.primary,
    required this.secondary,
    required this.logoUrl,
  });

  final String schoolName;
  final Color primary;
  final Color secondary;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _LogoCircle(logoUrl: logoUrl, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dashboard header preview',
                  style: TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return _LogoCircle(logoUrl: logoUrl, size: 56);
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.logoUrl, required this.size});

  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = (logoUrl ?? '').trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(Icons.school_rounded, color: Color(0xFF0F172A))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) {
                  debugPrint('LOGO LOAD ERROR: $error');
                }
                return const Icon(Icons.image_not_supported_rounded);
              },
            ),
    );
  }
}
