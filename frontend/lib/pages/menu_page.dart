import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'add_balance_page.dart';

class MenuPage extends StatelessWidget {
  final VoidCallback onLogout;
  final Function(int) onNavigateToPage;

  const MenuPage({
    super.key,
    required this.onLogout,
    required this.onNavigateToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Заголовок
              const Text(
                'Меню',
                style: TextStyle(
                  fontFamily: 'StalinistOne',
                  color: Color(0xFFCDFBE4),
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 30),
              // Секция магазина
              _buildSectionTitle('Магазин'),
              const SizedBox(height: 15),
              _buildMenuItem(
                context,
                icon: Icons.shopping_bag,
                title: 'Магазин',
                onTap: () => onNavigateToPage(0), // Магазин
              ),
              _buildMenuItem(
                context,
                icon: Icons.shopping_cart,
                title: 'Корзина',
                onTap: () => onNavigateToPage(6), // Корзина
              ),
              _buildMenuItem(
                context,
                icon: Icons.history,
                title: 'История покупок',
                onTap: () => onNavigateToPage(1), // История покупок
              ),
              _buildMenuItem(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Кошелёк',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBalancePage(),
                    ),
                  ).then((_) {
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
                  });
                },
              ),
              const SizedBox(height: 30),
              // Разделитель
              const Divider(
                color: Color(0xFF456978),
                thickness: 1,
              ),
              const SizedBox(height: 30),
              // Основные страницы
              _buildSectionTitle('Навигация'),
              const SizedBox(height: 15),
              _buildMenuItem(
                context,
                icon: Icons.calendar_today,
                title: 'Календарь',
                onTap: () => onNavigateToPage(2), // Календарь
              ),
              _buildMenuItem(
                context,
                icon: Icons.quiz,
                title: 'Опросы',
                onTap: () => onNavigateToPage(3), // Опросы
              ),
              _buildMenuItem(
                context,
                icon: Icons.sports_esports,
                title: 'Ставки',
                onTap: () => onNavigateToPage(4), // Ставки
              ),
              _buildMenuItem(
                context,
                icon: Icons.person,
                title: 'Профиль',
                onTap: () => onNavigateToPage(5), // Профиль
              ),
              const SizedBox(height: 30),
              // Разделитель
              const Divider(
                color: Color(0xFF456978),
                thickness: 1,
              ),
              const SizedBox(height: 30),
              // Настройки
              _buildSectionTitle('Настройки'),
              const SizedBox(height: 15),
              _buildMenuItem(
                context,
                icon: Icons.settings,
                title: 'Настройки',
                onTap: () {
                  // Переход на страницу настроек (в разработке)
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'О приложении',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Помощь',
                onTap: () {
                  _showHelpDialog(context);
                },
              ),
              const SizedBox(height: 30),
              // Разделитель
              const Divider(
                color: Color(0xFF456978),
                thickness: 1,
              ),
              const SizedBox(height: 30),
              // Выход
              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Выйти',
                onTap: () {
                  _showLogoutConfirmation(context);
                },
                isDestructive: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cornerita',
        color: Color(0xFFB19CD9),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3B5C).withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive
              ? Colors.red[300]
              : const Color(0xFFCDFBE4),
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive
                ? Colors.red[300]
                : const Color(0xFFCDFBE4),
            fontFamily: 'Cornerita',
            fontSize: 18,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF456978),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF062B42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'О приложении',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 20,
            ),
          ),
          content: const Text(
            'CodHammer - приложение для управления событиями, опросами и ставками.\n\nВерсия: 1.0.0',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Закрыть',
                style: TextStyle(
                  color: Color(0xFFCDFBE4),
                  fontFamily: 'Cornerita',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF062B42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Помощь',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Для получения помощи обратитесь в службу поддержки:\n\ninfo@codhammer.ru',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Закрыть',
                style: TextStyle(
                  color: Color(0xFFCDFBE4),
                  fontFamily: 'Cornerita',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF062B42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Подтверждение',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Вы уверены, что хотите выйти?',
            style: TextStyle(
              color: Color(0xFFCDFBE4),
              fontFamily: 'Cornerita',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFFB19CD9),
                  fontFamily: 'Cornerita',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ApiService.logout().then((_) => onLogout());
              },
              child: const Text(
                'Выйти',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Cornerita',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
