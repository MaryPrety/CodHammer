// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'cart_page.dart'; // Import CartPage
import 'add_balance_page.dart'; // Import AddBalancePage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'StalinistOne', // Default font for the app
      ),
      home: const ShopPage(),
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();

  // Публичный метод для получения списка товаров из состояния
  static List<Product>? getProductsFromState(GlobalKey? widgetKey) {
    if (widgetKey?.currentState != null && widgetKey!.currentWidget is ShopPage) {
      final state = (widgetKey.currentState as _ShopPageState);
      return state.products;
    }
    return null;
  }
}

class _ShopPageState extends State<ShopPage> {
  // Central color constants
  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color glowColor = Color(0xFFFAEFD9);
  static const Color backgroundColor = Color(0xFF062B42);
  static const Color cardColor = Color(0xFF0A3B5C);
  static const Color textColorSecondary = Colors.white70;

  List<String> filterCategories = [
    'MIREA',
    'Robots Battle',
    'RTC MIREA',
    'IPTIP'
  ];
  String selectedCategory = 'MIREA';

  List<Product> products = [
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
      name: 'Notebook "Coat of arms RTU MIREA"',
      price: 150,
      image: 'assets/mirea_notepad.jpg',
      category: 'MIREA',
      descriptionRu: 'Блокнот с гербом РТУ МИРЭА для ваших записей и идей.',
      descriptionEn:
          'Notebook with the coat of arms of RTU MIREA for your notes and ideas.',
    ),
    Product(
      name: 'Penal RTU MIREA',
      price: 200,
      image: 'assets/mirea_pencilbox.jpg',
      category: 'MIREA',
      descriptionRu:
          'Пенал РТУ МИРЭА для хранения ручек, карандашей и других канцелярских принадлежностей.',
      descriptionEn:
          'Pencil case RTU MIREA for storing pens, pencils and other stationery.',
    ),
    Product(
      name: 'Hudi RTU MIREA',
      price: 450,
      image: 'assets/mirea_blouse.jpg',
      category: 'MIREA',
      descriptionRu:
          'Худи РТУ МИРЭА, теплое и стильное, идеально для университета и прогулок.',
      descriptionEn:
          'Hoodie RTU MIREA, warm and stylish, perfect for university and walks.',
    ),
    Product(
      name: 'Club with the emblem of MIREA',
      price: 200,
      image: 'assets/mirea_cup.jpg',
      category: 'MIREA',
      descriptionRu: 'Кружка с эмблемой МИРЭА, для утреннего кофе или чая.',
      descriptionEn: 'Mug with the emblem of MIREA, for morning coffee or tea.',
      details:
          'Mug "Logo PTU MIREA", Transparent (Double bottom), volume 400 ml, borosilicate glass Features ... Article 00088960',
    ),
    Product(
      name: 'Sweatshirt RTU MIREA',
      price: 400,
      image: 'assets/mirea_sweatshirt.jpg',
      category: 'MIREA',
      descriptionRu:
          'Свитшот РТУ МИРЭА, удобная и модная одежда для каждого дня.',
      descriptionEn:
          'Sweatshirt RTU MIREA, comfortable and fashionable clothing for every day.',
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
      details:
          'Print "Robot Battle Print", Black/Green/Grey Features 100% Cotton (Front Panel) Article 00123456',
    ),
    Product(
      name: 'Robot battle backpack',
      price: 700,
      image: 'assets/robot_backpack.png',
      category: 'Robots Battle',
      descriptionRu:
          'Рюкзак "Robot battle", вместительный и прочный для школы или путешествий.',
      descriptionEn:
          'Backpack "Robot battle", spacious and durable for school or travel.',
    ),
    Product(
      name: 'Cap Battle of the Robots',
      price: 450,
      image: 'assets/robot_cap.png',
      category: 'Robots Battle',
      descriptionRu:
          'Кепка "Battle of the Robots", защитит от солнца и подчеркнет ваш стиль.',
      descriptionEn:
          'Cap "Battle of the Robots", protects from the sun and emphasizes your style.',
      details:
          'Cap "Robot Battle Print", Black/Green/Grey Features 100% Cotton (Front Panel) Article 00123456',
    ),
  ];

  List<Product> get filteredProducts {
    return products
        .where((product) => product.category == selectedCategory)
        .toList();
  }

  void _openProductDetails(Product product) {
    showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return ProductDetailsDialog(
          product: product,
        );
      },
    ).then((quantity) {
      setState(() {
        if (quantity != null) {
          product.quantity = quantity;
          print('Quantity updated to: $quantity for product: ${product.name}');
        } else {
          print(
              'Dialog closed without quantity change for product: ${product.name}');
        }
      });
    });
  }

  List<Order> orderHistory = []; // Order history list (moved to ShopPage)

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;

        double screenWidth = MediaQuery.of(context).size.width;
        int crossAxisCount = screenWidth < 600 ? 3 : 4;

        int totalQuantity = 0;
        int totalPrice = 0;

        for (var product in products) {
          totalQuantity += product.quantity;
          totalPrice += product.quantity * product.price;
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
            title: const Text(
              '',
              style: TextStyle(color: secondaryColor),
            ), // Title is handled in main navigation
            leading: IconButton(
              icon: const Icon(
                Icons.account_balance_wallet,
                color: secondaryColor,
              ),
              tooltip: isEnglish ? 'Add Balance' : 'Пополнить баланс',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddBalancePage(),
                  ),
                );
                // Обновляем баланс в header после возврата из страницы пополнения
                // Используем WidgetsBinding для обновления через короткое время
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Находим MainNavigation через context и обновляем баланс
                  final mainNavigation = context.findAncestorStateOfType<State<StatefulWidget>>();
                  if (mainNavigation != null) {
                    // Вызываем метод обновления через dynamic
                    try {
                      (mainNavigation as dynamic).refreshUserPoints();
                    } catch (e) {
                      // Если метод не найден, игнорируем
                    }
                  }
                });
              },
            ),
            actions: [
              // Корзина
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart,
                      color: secondaryColor,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage(
                            products: products,
                            onCartUpdated: () {
                              setState(() {});
                            },
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // Обновляем состояние после возврата
                      });
                    },
                  ),
                  if (totalQuantity > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: tertiaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          totalQuantity > 99 ? '99+' : '$totalQuantity',
                          style: const TextStyle(
                            color: backgroundColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: filterCategories
                          .map(
                            (category) => FilterButton(
                              text: category,
                              isSelected: selectedCategory == category,
                              onPressed: () {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _openProductDetails(filteredProducts[index]),
                          child: ProductCard(
                            product: filteredProducts[index],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (totalQuantity > 0)
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartPage(
                            products: products,
                            onCartUpdated: () {
                              setState(() {});
                            },
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // Обновляем состояние после возврата
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                color: secondaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEnglish ? 'View cart' : 'Открыть корзину',
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                isEnglish ? 'Total: ' : 'Итого: ',
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 18.0,
                                ),
                              ),
                              Text(
                                formatNumber(totalPrice),
                                style: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const FilterButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? _ShopPageState.secondaryColor
              : _ShopPageState.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _ShopPageState.secondaryColor
                  .withOpacity(isSelected ? 1.0 : 0.0),
              width: 2.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _ShopPageState.secondaryColor.withOpacity(0.4),
                    offset: const Offset(0, 0),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? _ShopPageState.backgroundColor
                : _ShopPageState.secondaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: _ShopPageState.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ShopPageState.secondaryColor,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        AvatarWidget(
          product: product,
          imageUrl: product.image,
          width: 120,
          height: 80,
          glowColor: _ShopPageState.glowColor,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/screw.png',
              width: 24,
              height: 24,
              color: _ShopPageState.tertiaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${product.price}',
              style: const TextStyle(
                color: _ShopPageState.tertiaryColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AvatarWidget extends StatelessWidget {
  final Product product;
  final String imageUrl;
  final double width;
  final double height;
  final Color glowColor;

  const AvatarWidget({
    super.key,
    required this.product,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = glowColor;
    if (product.quantity > 0) {
      borderColor = _ShopPageState.tertiaryColor;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.6),
            offset: const Offset(0, 0),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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

class ProductDetailsDialog extends StatefulWidget {
  final Product product;

  const ProductDetailsDialog({
    super.key,
    required this.product,
  });

  @override
  _ProductDetailsDialogState createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;

        String buttonText;
        if (_quantity > 0) {
          buttonText = isEnglish ? 'Add to cart' : 'Добавить в корзину';
        } else if (_quantity == 0 && widget.product.quantity > 0) {
          buttonText = isEnglish ? 'Remove from cart' : 'Удалить из корзины';
        } else {
          buttonText = isEnglish ? 'Close' : 'Закрыть';
        }

        final description = isEnglish
            ? widget.product.descriptionEn
            : widget.product.descriptionRu;

        return Dialog(
          backgroundColor: _ShopPageState.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: AvatarWidget(
                    product: widget.product,
                    imageUrl: widget.product.image,
                    width: 150,
                    height: 150,
                    glowColor: _ShopPageState.glowColor,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontFamily: 'Cornerita',
                      fontSize: 22,
                      color: _ShopPageState.secondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cornerita',
                    fontSize: 16,
                    color: _ShopPageState.textColorSecondary,
                  ),
                ),
                if (widget.product.details != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.product.details!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cornerita',
                      fontSize: 14,
                      color: _ShopPageState.textColorSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove,
                          color: _ShopPageState.secondaryColor),
                      onPressed: () {
                        if (_quantity > 0) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 140,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _ShopPageState.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.product.price} * $_quantity = ${formatNumber(widget.product.price * _quantity)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ShopPageState.secondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add,
                          color: _ShopPageState.secondaryColor),
                      onPressed: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_quantity);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ShopPageState.secondaryColor,
                      foregroundColor: _ShopPageState.backgroundColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      shadowColor:
                          _ShopPageState.secondaryColor.withOpacity(0.4),
                      elevation: 6,
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CheckoutDialog extends StatefulWidget {
  final List<Product> cartProducts;

  const CheckoutDialog({super.key, required this.cartProducts});

  @override
  _CheckoutDialogState createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;

        if (widget.cartProducts.isEmpty) {
          return AlertDialog(
            backgroundColor:
                _ShopPageState.cardColor.withOpacity(0.8),
            title: Text(
              isEnglish ? 'Cart is empty' : 'Корзина пуста',
              style: const TextStyle(color: _ShopPageState.secondaryColor),
            ),
            content: Text(
              isEnglish
                  ? 'Add items to the cart to continue.'
                  : 'Добавьте товары в корзину, чтобы продолжить.',
              style: const TextStyle(
                  color: _ShopPageState.textColorSecondary),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  isEnglish ? 'Close' : 'Закрыть',
                  style: const TextStyle(
                      color: _ShopPageState.secondaryColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }

        int totalPrice = 0;
        for (var product in widget.cartProducts) {
          totalPrice += product.quantity * product.price;
        }

        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(color: Colors.transparent),
              ),
            ),
            Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: _ShopPageState.cardColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEnglish ? 'Order summary' : 'Сводка заказа',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cornerita',
                        fontSize: 22,
                        color: _ShopPageState.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.cartProducts.length,
                      separatorBuilder: (context, index) =>
                          const Divider(
                              color: _ShopPageState.textColorSecondary),
                      itemBuilder: (context, index) {
                        final product = widget.cartProducts[index];
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                    color:
                                        _ShopPageState.secondaryColor),
                              ),
                              Text(
                                '${product.quantity} x ${product.price} = ${formatNumber(product.quantity * product.price)}',
                                style: const TextStyle(
                                  color: _ShopPageState.textColorSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${isEnglish ? 'Total' : 'Итого'}: ${formatNumber(totalPrice)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _ShopPageState.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        List<OrderItem> orderItems = widget.cartProducts
                            .map((product) => OrderItem(
                                product: product,
                                quantity: product.quantity))
                            .toList();
                        Order order = Order(
                          orderId: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          orderDate: DateTime.now(),
                          orderItems: orderItems,
                          totalAmount: totalPrice,
                        );
                        Navigator.of(context).pop(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ShopPageState.secondaryColor,
                        foregroundColor: _ShopPageState.backgroundColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        shadowColor: _ShopPageState.secondaryColor
                            .withOpacity(0.4),
                        elevation: 6,
                      ),
                      child: Text(
                        isEnglish ? 'Place order' : 'Оформить заказ',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OrderHistoryPage extends StatelessWidget {
  final Order order;

  const OrderHistoryPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ShopPageState.backgroundColor,
      appBar: AppBar(
        backgroundColor: _ShopPageState.backgroundColor,
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            final isEnglish = languageProvider.isEnglish;
            return Text(
              isEnglish ? 'Order details' : 'Детали заказа',
              style:
                  const TextStyle(color: _ShopPageState.secondaryColor),
            );
          },
        ),
        iconTheme: const IconThemeData(color: _ShopPageState.secondaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                final isEnglish = languageProvider.isEnglish;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isEnglish ? 'Order ID' : 'Номер заказа'}: ${order.orderId}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: _ShopPageState.secondaryColor,
                      ),
                    ),
                    Text(
                      '${isEnglish ? 'Order date' : 'Дата заказа'}: ${formatDate(order.orderDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: _ShopPageState.textColorSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: order.orderItems.length,
                itemBuilder: (context, index) {
                  final orderItem = order.orderItems[index];
                  return Card(
                    color: _ShopPageState.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: AvatarWidget(
                              product: orderItem.product,
                              imageUrl: orderItem.product.image,
                              width: 100,
                              height: 100,
                              glowColor: _ShopPageState.glowColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  orderItem.product.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: _ShopPageState.secondaryColor),
                                ),
                                Consumer<LanguageProvider>(
                                  builder: (context, languageProvider, _) {
                                    final isEnglish =
                                        languageProvider.isEnglish;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${isEnglish ? 'Quantity' : 'Количество'}: ${orderItem.quantity}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: _ShopPageState
                                                .textColorSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${isEnglish ? 'Price' : 'Цена'}: ${formatNumber(orderItem.product.price * orderItem.quantity)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color:
                                                _ShopPageState.tertiaryColor,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, _) {
                  final isEnglish = languageProvider.isEnglish;
                  return Text(
                    '${isEnglish ? 'Total amount' : 'Итоговая сумма'}: ${formatNumber(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _ShopPageState.secondaryColor,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime dateTime) {
    return "${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }
}

class Product {
  final String name;
  final int price;
  final String image;
  final String category;
  final String descriptionRu;
  final String descriptionEn;
  final String? details;
  int quantity;

  Product({
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.descriptionRu,
    required this.descriptionEn,
    this.details,
    this.quantity = 0,
  });
}

class Order {
  final String orderId;
  final DateTime orderDate;
  final List<OrderItem> orderItems;
  final int totalAmount;

  Order({
    required this.orderId,
    required this.orderDate,
    required this.orderItems,
    required this.totalAmount,
  });
}

class OrderItem {
  final Product product;
  final int quantity;

  OrderItem({
    required this.product,
    required this.quantity,
  });
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
