// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'shop_page.dart'; // Import ShopPage related classes

class StoryPage extends StatefulWidget {
  final List<Order> orderHistory; // Receive order history

  const StoryPage({super.key, required this.orderHistory});

  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  List<Order> _orderHistory = [];
  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color textColorSecondary = Colors.white70;
  static const Color cardColor = Color(0xFF0A3B5C);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color glowColor = Color(0xFFFAEFD9);
  static const Color backgroundColor = Color(0xFF062B42);

  @override
  void initState() {
    super.initState();
    _orderHistory = widget.orderHistory; // Initialize order history from widget
    if (_orderHistory.isEmpty) {
      _loadDummyOrderHistory();
    }
  }

  void _loadDummyOrderHistory() {
    // Dummy data for demonstration
    List<Product> dummyProducts = [
      Product(
        name: 'Thermo Krasava',
        price: 250,
        image: 'assets/mirea_thermos.jpg',
        category: 'MIREA',
        descriptionRu:
            'Термос "Красава" РТУ МИРЭА, сохранит ваш напиток горячим или холодным.',
        descriptionEn:
            'Thermo "Krasava" RTU MIREA, keeps your drink hot or cold.',
      ),
      Product(
        name: 'Robot Battle T-shirt',
        price: 600,
        image: 'assets/robot_T-shirt.png',
        category: 'Robots Battle',
        descriptionRu:
            'Футболка "Robot Battle" с ярким принтом, для фанатов робототехники.',
        descriptionEn:
            'T-shirt "Robot Battle" with a bright print, for robotics fans.',
      ),
    ];

    List<OrderItem> orderItems1 = [
      OrderItem(product: dummyProducts[0], quantity: 2),
      OrderItem(product: dummyProducts[1], quantity: 1),
    ];

    _orderHistory = [
      Order(
        orderId: '12345',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        orderItems: orderItems1,
        totalAmount: orderItems1.fold(
            0, (sum, item) => sum + item.product.price * item.quantity),
      ),
      Order(
        orderId: '67890',
        orderDate: DateTime.now().subtract(const Duration(days: 3)),
        orderItems: [OrderItem(product: dummyProducts[1], quantity: 3)],
        totalAmount: 3 * dummyProducts[1].price,
      ),
    ];
    setState(() {}); // Trigger rebuild to show dummy data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'История покупок',
          style: TextStyle(
            fontFamily: 'StalinistOne',
            color: secondaryColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: secondaryColor),
      ),
      body: _orderHistory.isEmpty
          ? const Center(
              child: Text('История заказов пуста.',
                  style: TextStyle(color: textColorSecondary)),
            )
          : ListView.builder(
              itemCount: _orderHistory.length,
              itemBuilder: (context, index) {
                final order = _orderHistory[index];
                return Card(
                  color: cardColor,
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: order.orderItems.isNotEmpty
                              ? AvatarWidget(
                                  product: order.orderItems.first.product,
                                  imageUrl:
                                      order.orderItems.first.product.image,
                                  width: 70,
                                  height: 70,
                                  glowColor: glowColor,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Заказ №: ${order.orderId}',
                                  style: const TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold)),
                              Text('Дата: ${formatDate(order.orderDate)}',
                                  style: const TextStyle(
                                      color: textColorSecondary)),
                            ],
                          ),
                        ),
                        Text(formatNumber(order.totalAmount),
                            style: const TextStyle(
                                color: tertiaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String formatDate(DateTime dateTime) {
    return "${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  String formatNumber(int number, {int fractionDigits = 1}) {
    if (number >= 1000000) {
      double millions = number / 1000000.0;
      return '${millions.toStringAsFixed(fractionDigits)}M';
    } else if (number >= 1000) {
      double thousands = number / 1000.0;
      return '${thousands.toStringAsFixed(fractionDigits)}k';
    } else {
      return number.toString();
    }
  }
}
