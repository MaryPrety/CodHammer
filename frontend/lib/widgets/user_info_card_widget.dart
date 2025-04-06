import 'package:flutter/material.dart';

class UserInfoCardWidget extends StatelessWidget {
  final List<Map<String, String>> userInfo;
  final Color textColorSecondary;
  final Color cardColor;

  const UserInfoCardWidget({
    Key? key,
    required this.userInfo,
    required this.textColorSecondary,
    required this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: userInfo.map((info) => _buildInfoRow(info)).toList(),
      ),
    );
  }

  Widget _buildInfoRow(Map<String, String> info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/screw.png',
            width: 24,
            height: 24,
            color: textColorSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['label'] ?? '',
                  style: TextStyle(
                    color: textColorSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  info['value'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFFFAEFD9),
                    fontSize: 14,
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