// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'shop_page.dart'; // Import ShopPage related classes
import 'story_page.dart'; // Import StoryPage

class CartPage extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onCartUpdated;

  const CartPage({
    super.key,
    required this.products,
    required this.onCartUpdated,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color textColorSecondary = Colors.white70;
  static const Color cardColor = Color(0xFF0A3B5C);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color glowColor = Color(0xFFFAEFD9);
  static const Color backgroundColor = Color(0xFF062B42);

  List<Product> get cartProducts {
    return widget.products.where((p) => p.quantity > 0).toList();
  }

  int get totalPrice {
    int total = 0;
    for (var product in cartProducts) {
      total += product.quantity * product.price;
    }
    return total;
  }

  void _updateQuantity(Product product, int newQuantity) {
    setState(() {
      product.quantity = newQuantity;
    });
    widget.onCartUpdated();
  }

  void _removeFromCart(Product product) {
    setState(() {
      product.quantity = 0;
    });
    widget.onCartUpdated();
  }

  void _openCheckoutDialog() async {
    if (cartProducts.isEmpty) {
      final isEnglish = Provider.of<LanguageProvider>(context, listen: false).isEnglish;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text(
              isEnglish ? 'Cart is empty' : 'Корзина пуста',
              style: const TextStyle(color: secondaryColor),
            ),
            content: Text(
              isEnglish
                  ? 'Add items to the cart to continue.'
                  : 'Добавьте товары в корзину, чтобы продолжить.',
              style: const TextStyle(color: textColorSecondary),
            ),
            actions: <Widget>[
              CloseButton(
                color: secondaryColor,
              ),
            ],
          );
        },
      );
      return;
    }

    final order = await Navigator.push<Order>(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutDialog(cartProducts: cartProducts),
      ),
    );

    if (order != null) {
      // Очищаем корзину после оформления заказа
      for (var p in widget.products) {
        p.quantity = 0;
      }
      widget.onCartUpdated();
      
      // Переходим на страницу истории покупок
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryPage(orderHistory: [order]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: secondaryColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              isEnglish ? 'Cart' : 'Корзина',
              style: const TextStyle(
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
          body: cartProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: textColorSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isEnglish
                            ? 'Your cart is empty'
                            : 'Ваша корзина пуста',
                        style: TextStyle(
                          color: textColorSecondary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isEnglish
                            ? 'Add items from the shop'
                            : 'Добавьте товары из магазина',
                        style: TextStyle(
                          color: textColorSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: cartProducts.length,
                        itemBuilder: (context, index) {
                          final product = cartProducts[index];
                          return Card(
                            color: cardColor,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: AvatarWidget(
                                      product: product,
                                      imageUrl: product.image,
                                      width: 80,
                                      height: 80,
                                      glowColor: glowColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            color: secondaryColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/screw.png',
                                              width: 16,
                                              height: 16,
                                              color: tertiaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${product.price}',
                                              style: const TextStyle(
                                                color: tertiaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: secondaryColor,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              if (product.quantity > 1) {
                                                _updateQuantity(
                                                    product, product.quantity - 1);
                                              } else {
                                                _removeFromCart(product);
                                              }
                                            },
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${product.quantity}',
                                              style: const TextStyle(
                                                color: secondaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: secondaryColor,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              _updateQuantity(
                                                  product, product.quantity + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatNumber(product.price * product.quantity),
                                        style: const TextStyle(
                                          color: tertiaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEnglish ? 'Total:' : 'Итого:',
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatNumber(totalPrice),
                                style: const TextStyle(
                                  color: tertiaryColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openCheckoutDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                foregroundColor: backgroundColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor: secondaryColor.withOpacity(0.4),
                                elevation: 6,
                              ),
                              child: Text(
                                isEnglish ? 'Checkout' : 'Оформить заказ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
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
