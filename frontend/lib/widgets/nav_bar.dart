import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFFFAEFD9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/Active_calendar.svg', active: true),
          _buildNavItem('assets/Quiz.svg'),
          _buildNavItem('assets/Bet.svg'),
          _buildNavItem('assets/Person.svg'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, {bool active = false}) {
    return SvgPicture.asset(
      iconPath,
      width: 30,
      height: 30,
      color: active ? const Color(0xFF062B42) : const Color(0xFF456978),
    );
  }
}