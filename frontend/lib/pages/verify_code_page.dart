// ЗАКОММЕНТИРОВАНО: Страница ввода кода для авторизации через email
// Можно вернуть, раскомментировав весь код ниже

/*
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final bool saveSession;
  final VoidCallback? onVerificationSuccess;

  const VerifyCodePage({
    super.key,
    required this.email,
    required this.saveSession,
    this.onVerificationSuccess,
  });

  @override
  _VerifyCodePageState createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  // Цветовая палитра
  static const _secondaryColor = Color.fromRGBO(205, 251, 228, 1); // Light Green
  static const _tertiaryColor = Color(0xFFB19CD9); // Light Purple
  static const _backgroundColor = Color(0xFF062B42); // Dark Background
  static const _cardColor = Color(0xFF0A3B5C);
  static const _textColorSecondary = Colors.white70;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _secondaryColor),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Ввод кода',
          style: TextStyle(
            fontFamily: 'StalinistOne',
            color: _secondaryColor,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: _secondaryColor.withOpacity(0.7),
              ),
              const SizedBox(height: 30),
              Text(
                'Код отправлен на email',
                style: TextStyle(
                  fontFamily: 'StalinistOne',
                  color: _secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.email,
                style: TextStyle(
                  fontFamily: 'Cornerita',
                  color: _textColorSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              _buildCodeForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
              fontSize: 28,
              letterSpacing: 12,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Введите код из email',
              labelStyle: TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              hintText: '000000',
              hintStyle: TextStyle(
                color: _textColorSecondary.withOpacity(0.3),
                letterSpacing: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _secondaryColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите код';
              }
              if (value.length != 6) {
                return 'Код должен состоять из 6 цифр';
              }
              if (!RegExp(r'^\d+$').hasMatch(value)) {
                return 'Код должен содержать только цифры';
              }
              return null;
            },
            onChanged: (value) {
              // Автоматическая отправка при вводе 6 цифр
              if (value.length == 6 && RegExp(r'^\d+$').hasMatch(value)) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _formKey.currentState!.validate()) {
                    _verifyCode();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                backgroundColor: _tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                shadowColor: _tertiaryColor.withOpacity(0.4),
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await _verifyCode();
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Подтвердить',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tomorrow',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: Text(
              'Назад к входу',
              style: TextStyle(
                fontFamily: 'Cornerita',
                color: _tertiaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.verifyCode(widget.email, _codeController.text);

      final token = await ApiService.getToken();
      if (token != null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          widget.onVerificationSuccess?.call();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ошибка: токен не получен"),
              backgroundColor: _cardColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка проверки кода: $e"),
            backgroundColor: _tertiaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
*/