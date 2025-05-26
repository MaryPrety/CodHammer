// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class UserInfoCardWidget extends StatelessWidget {
  // Параметры виджета
  final List<Map<String, String>> userInfo; // Список данных пользователя
  final Color textColorSecondary; // Цвет вторичного текста
  final Color cardColor; // Цвет фона карточки
  final bool isEnglish; // Флаг для определения языка

  const UserInfoCardWidget({
    super.key,
    required this.userInfo,
    required this.textColorSecondary,
    required this.cardColor,
    required this.isEnglish, // Добавлен флаг для языка
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Отступы внутри карточки
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5), // Полупрозрачный фон карточки
        borderRadius: BorderRadius.circular(12), // Закругленные углы
      ),
      child: Column(
        children: userInfo.map((info) => _buildInfoRow(info)).toList(), // Создание строк для каждого элемента userInfo
      ),
    );
  }

  // Метод для создания строки с информацией
  Widget _buildInfoRow(Map<String, String> info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Вертикальные отступы между строками
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание по верхнему краю
        children: [
          // Иконка винта (замените на нужную иконку)
          Image.asset(
            'assets/screw.png',
            width: 24,
            height: 24,
            color: textColorSecondary, // Цвет иконки
          ),
          const SizedBox(width: 12), // Отступ между иконкой и текстом
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Выравнивание текста по левому краю
              children: [
                // Название поля (например, "Возраст" или "Interests")
                Text(
                  info['label'] ?? '', // Если label отсутствует, используется пустая строка
                  style: TextStyle(
                    color: textColorSecondary, // Цвет вторичного текста
                    fontSize: isEnglish ? 12 : 14, // Размер шрифта для названия поля
                    fontFamily: isEnglish ? 'Tomorrow' : 'Cornerita', // Шрифт зависит от языка
                  ),
                ),
                // Значение поля (например, "21 год" или "robotics, IoT devices")
                Text(
                  info['value'] ?? '', // Если value отсутствует, используется пустая строка
                  style: TextStyle(
                    color: const Color(0xFFFAEFD9), // Основной цвет текста
                    fontSize: isEnglish ? 14 : 16, // Размер шрифта для значения поля
                    fontFamily: isEnglish ? 'Tomorrow' : 'Cornerita', // Шрифт зависит от языка
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