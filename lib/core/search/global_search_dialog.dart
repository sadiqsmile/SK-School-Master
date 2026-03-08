import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:school_app/core/search/global_search_models.dart';
import 'package:school_app/core/search/global_search_service.dart';
import 'package:school_app/providers/school_admin_provider.dart';

final globalSearchServiceProvider = Provider<GlobalSearchService>((ref) {
  return GlobalSearchService();
});

class GlobalSearchDialog extends ConsumerStatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> open(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const GlobalSearchDialog(),
    );
  }

  @override
  ConsumerState<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<GlobalSearchDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;

  bool _loading = false;
  Object? _error;
  List<GlobalSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _runSearch();
    });
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _results = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final schoolId = await ref.read(schoolIdProvider.future);
      final service = ref.read(globalSearchServiceProvider);
      final r = await service.search(schoolId: schoolId, query: query, perTypeLimit: 10);

      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Search students, teachers, classes…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (_results.isNotEmpty) {
                          _open(_results.first);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Search failed: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: _controller.text.trim().isEmpty
                    ? Center(
                        child: Text(
                          'Start typing to search…',
                          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _loading ? 'Searching…' : 'No results',
                              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final r = _results[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withAlpha(26),
                                  child: Icon(r.icon ?? Icons.search_rounded, color: theme.colorScheme.primary),
                                ),
                                title: Text(
                                  r.title,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text('${r.typeLabel} • ${r.subtitle}'),
                                onTap: () => _open(r),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Press Enter to open the first result.',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(GlobalSearchResult r) {
    Navigator.of(context).pop();
    context.go(r.route);
  }
}
