import 'package:flutter/material.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text('Вход', style: AppTextStyles.header),
                const SizedBox(height: 30),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                AuthButton(
                  text: 'Войти',
                  onPressed: _isLoading
                      ? () {}
                      : () {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);
                            // TODO: Добавьте логику входа
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() => _isLoading = false);
                            });
                          }
                        },
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('Нет аккаунта? Зарегистрируйтесь'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}