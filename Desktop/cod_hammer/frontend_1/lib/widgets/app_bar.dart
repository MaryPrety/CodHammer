import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isProfilePage;
  final int? screwCount;
  final int? gemCount;
  final VoidCallback? onTitleTap; // Новый параметр для обработки нажатия

  const CustomAppBar({
    super.key,
    required this.title,
    this.isProfilePage = false,
    this.screwCount,
    this.gemCount,
    this.onTitleTap, // Добавляем возможность передать колбэк
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: GestureDetector(
        onTap: onTitleTap, // Обрабатываем нажатие на заголовок
        child: isProfilePage && (screwCount != null || gemCount != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'StalinistOne',
                      color: Color(0xFFCDFBE4),
                      fontSize: 16,
                    ),
                  ),
                  if (screwCount != null) ...[
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/screw.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCount(screwCount!),
                      style: const TextStyle(
                        fontFamily: 'StalinistOne',
                        color: Color(0xFFB19CD9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (gemCount != null) ...[
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/screw.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCount(gemCount!),
                      style: const TextStyle(
                        fontFamily: 'StalinistOne',
                        color: Color(0xFFB19CD9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              )
            : Text(
                title,
                style: const TextStyle(
                  fontFamily: 'StalinistOne',
                  color: Color(0xFFCDFBE4),
                  fontSize: 16,
                ),
              ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF062B42),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatCount(int count) {
    if (count >= 1000000) {
      double millions = count / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}m';
    } else if (count >= 1000) {
      double thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    } else {
      return count.toString();
    }
  }
}