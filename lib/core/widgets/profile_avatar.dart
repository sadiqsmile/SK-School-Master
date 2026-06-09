import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xffEEF2FF),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: !hasImage
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
                color: const Color(0xff5B5FEF),
              ),
            )
          : null,
    );
  }
}
