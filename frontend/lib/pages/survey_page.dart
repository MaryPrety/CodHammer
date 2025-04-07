// import 'package:flutter/material.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';
// import 'package:pie_chart/pie_chart.dart';

// class SurveyResultsPage extends StatelessWidget {
//   const SurveyResultsPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 40),
//             Text(
//               'Результаты опроса',
//               style: TextStyle(
//                 fontFamily: 'Cornerita',
//                 color: const Color(0xFF90EE90),
//                 fontSize: 40,
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               'Спасибо за участие! Вот статистика ответов:',
//               style: TextStyle(
//                 fontFamily: 'Cornerita',
//                 color: Colors.white,
//                 fontSize: 20,
//               ),
//             ),
//             const SizedBox(height: 30),
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: const [
//                     Question1Result(),
//                     SizedBox(height: 30),
//                     Question2Result(),
//                     SizedBox(height: 30),
//                     Question3Result(),
//                     SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF90EE90),
//                   padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: Text(
//                   'Завершить',
//                   style: TextStyle(
//                     fontFamily: 'Cornerita',
//                     color: const Color(0xFF0E1621),
//                     fontSize: 20,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class Question1Result extends StatelessWidget {
//   const Question1Result({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final Map<String, double> dataMap = {
//       "Да, мне нравится наблюдать": 60,
//       "Да, я участвую": 15,
//       "Нет, мне не интересно": 20,
//       "Нейтрально": 5,
//     };

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '1. Ваш интерес к технологическим мероприятиям:',
//           style: Theme.of(context).textTheme.titleMedium,
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: dataMap.entries.map((entry) {
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4),
//                     child: Row(
//                       children: [
//                         const Icon(Icons.hexagon, color: Color(0xFFDAF7A8), size: 12),
//                         const SizedBox(width: 8),
//                         Text(
//                           '${entry.key} - ${entry.value.toInt()}%',
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//             SizedBox(
//               width: 150,
//               height: 150,
//               child: PieChart(
//                 dataMap: dataMap,
//                 animationDuration: const Duration(milliseconds: 800),
//                 chartRadius: MediaQuery.of(context).size.width / 6,
//                 colorList: const [
//                   Color(0xFFDAF7A8),
//                   Color(0xFFC0B2D6),
//                   Color(0xFF8D72C1),
//                   Color(0xFF6B48FF),
//                 ],
//                 initialAngleInDegree: 0,
//                 chartType: ChartType.disc,
//                 legendOptions: const LegendOptions(
//                   showLegends: false,
//                 ),
//                 chartValuesOptions: const ChartValuesOptions(
//                   showChartValues: false,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

// // Аналогичные классы Question2Result и Question3Result с соответствующими вопросами
// // и данными, как в предыдущем примере, но с русским текстом