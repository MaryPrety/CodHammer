import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final Color glowColor;

  const AvatarWidget({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.glowColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.8),
            offset: const Offset(0, 0),
            blurRadius: 8, //  Уменьшено с 16 до 8
            spreadRadius: 2, // Уменьшено с 4 до 2
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/placeholder.png',
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}