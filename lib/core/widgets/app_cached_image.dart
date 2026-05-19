import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final BoxFit fit;
  final IconData fallbackIcon;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.radius = 100,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback();
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(radius),

      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,

        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,

        memCacheWidth: 300,
        memCacheHeight: 300,

        placeholder: (context, url) =>
            Container(
          alignment: Alignment.center,
          color: Colors.grey.shade100,

          child: const SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),

        errorWidget:
            (context, url, error) =>
                _fallback(),
      ),
    );
  }






  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: Colors.grey.shade100,

      child: Icon(
        fallbackIcon,
        color: Colors.grey,
      ),
    );
  }
}