// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final Color glowColor;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.width,
    required this.height,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final String imagePath = imageUrl ?? 'assets/person.png';
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:  Color(0xFFFAEFD9).withOpacity(0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.4),
            offset: const Offset(0, 0),
            blurRadius: 6, 
            spreadRadius: 2, 
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildImage(imagePath),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    // Если путь начинается с "assets/", используем Image.asset
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/person.png',
            fit: BoxFit.cover,
          );
        },
      );
    }
    // Иначе пытаемся загрузить как файл
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/person.png',
            fit: BoxFit.cover,
          );
        },
      );
    }
    // По умолчанию используем person.png
    return Image.asset(
      'assets/person.png',
      fit: BoxFit.cover,
    );
  }
}