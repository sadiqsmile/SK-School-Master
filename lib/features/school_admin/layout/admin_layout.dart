import 'package:flutter/material.dart';
import 'package:school_app/core/widgets/app_drawer.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/providers/current_school_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:school_app/core/services/image_service.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminLayout extends ConsumerWidget {
  final String title;
  final Widget? body;
  final Widget? child;
  final Widget? floatingActionButton;
  final VoidCallback? onSettingsPressed;

  const AdminLayout({
    super.key,
    required this.title,
    this.body,
    this.child,
    this.floatingActionButton,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = body ?? child ?? const SizedBox();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: floatingActionButton,
      drawer: isMobile
          ? const Drawer(
              width: 285,
              child: SafeArea(child: AppDrawer()),
            )
          : null,
      body: isMobile
          ? Column(
              children: [
                _mobileHeader(context, title),
                Expanded(child: page),
              ],
            )
          : Column(
              children: [
                _webTopHeader(ref),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 240,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        child: const AppDrawer(),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F7FB),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 1200,
                                minHeight: double.infinity,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (Navigator.canPop(context))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            icon: const Icon(Icons.arrow_back),
                                            label: const Text('Back'),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      ),
                                    Expanded(child: page),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  
  }


  // MOBILE HEADER
  Widget _mobileHeader(BuildContext context, String title) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE6EAF2)),
          ),
        ),
        child: Row(
          children: [
           
         Navigator.canPop(context)

? IconButton(
    icon: const Icon(
      Icons.arrow_back_rounded,
    ),
    onPressed: () {
      Navigator.pop(context);
    },
  )

: Builder(
    builder: (context) => IconButton(
      icon: const Icon(
        Icons.menu_rounded,
      ),
      onPressed: () =>
          Scaffold.of(context)
              .openDrawer(),
    ),
  ),


           
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
            if (onSettingsPressed != null)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettingsPressed,
                tooltip: 'Settings',
              ),
          ],
        ),
      ),
    );
  }

  // WEB TOP HEADER (UPDATED ONLY)

  Widget _webTopHeader(WidgetRef ref) {
    final schoolAsync = ref.watch(currentSchoolProvider);

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE6EAF2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          schoolAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (school) {
              final data = school.data() ?? {};
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final logo = data['logoUrl'] ?? data['logo'] ?? '';

              return Row(
                children: [
                  GestureDetector(
                    
                   onTap: () async {

  try {

    final bytes =
        await ImageService.pickCropCompressImage();

    if (bytes == null) return;

    final schoolRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(school.id);

    final schoolDoc =
        await schoolRef.get();

    final oldLogo =
        schoolDoc.data()?['logo'] ?? '';

    // CLEAR OLD CACHE
    if (oldLogo.toString().isNotEmpty) {

      await CachedNetworkImage.evictFromCache(
        oldLogo,
      );
    }

    // SINGLE FILE PATH
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('schools')
        .child(school.id)
        .child('branding')
        .child('school_logo.png');

    // OVERWRITE SAME FILE
    await storageRef.putData(

      bytes,

      SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'no-cache',
      ),
    );

    final downloadUrl =
        await storageRef.getDownloadURL();

    // UPDATE FIRESTORE
    await schoolRef.update({

      'logo': downloadUrl,

      'logoUpdatedAt':
          DateTime.now()
              .millisecondsSinceEpoch,
    });

    // CLEAR NEW CACHE ALSO
    await CachedNetworkImage.evictFromCache(
      downloadUrl,
    );

    ref.invalidate(
      currentSchoolProvider,
    );

  } catch (e) {

    debugPrint(
      "School logo update error: $e",
    );
  }
},



                    child: Container(

  width: 52,
  height: 52,

  color: Colors.white,

  child: logo.toString().isNotEmpty

      ? 
      
      
   ClipRRect(
  borderRadius: BorderRadius.circular(12),

  child: CachedNetworkImage(

    imageUrl:
        "$logo?v=${data['logoUpdatedAt'] ?? ''}",

    fit: BoxFit.contain,

    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,

    filterQuality: FilterQuality.high,

    memCacheWidth: 300,

    placeholder: (context, url) {

      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    },

    errorWidget: (
      context,
      url,
      error,
    ) {

      return const Icon(
        Icons.school,
        size: 32,
      );
    },
  ),
)












      : const Icon(
          Icons.school,
          size: 32,
        ),
),

                  ),












                  
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 30, 40, 54),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          _iconBtn(Icons.search_rounded),
          const SizedBox(width: 10),
          _iconBtn(Icons.notifications_none_rounded),
          const SizedBox(width: 12),
          if (onSettingsPressed != null)
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined,
                    size: 20, color: Color(0xFF374151)),
                onPressed: onSettingsPressed,
                tooltip: 'Settings',
                padding: EdgeInsets.zero,
              ),
            )
          else
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE0ECFF),
              child: Text(
                'AD',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Icon(icon, size: 18),
    );
  }
}
