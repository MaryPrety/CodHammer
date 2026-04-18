import 'package:flutter/material.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AddBalancePage extends StatefulWidget {
  const AddBalancePage({super.key});

  @override
  State<AddBalancePage> createState() => _AddBalancePageState();
}

class _AddBalancePageState extends State<AddBalancePage> {
  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color backgroundColor = Color(0xFF062B42);
  static const Color cardColor = Color(0xFF0A3B5C);
  static const Color textColorSecondary = Colors.white70;

  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  int? _currentBalance;
  bool _isLoadingBalance = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      setState(() {
        _isLoadingBalance = true;
      });
      final profile = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _currentBalance = profile['points'] as int? ?? 0;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  Future<void> _addBalance() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isEnglish = languageProvider.isEnglish;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish 
                ? 'Please enter an amount'
                : 'Пожалуйста, введите сумму',
          ),
          backgroundColor: tertiaryColor,
        ),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isEnglish = languageProvider.isEnglish;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish 
                ? 'Please enter a valid positive number'
                : 'Пожалуйста, введите корректное положительное число',
          ),
          backgroundColor: tertiaryColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.addPoints(amount);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentBalance = result['total_points'] as int? ?? _currentBalance;
          _amountController.clear();
        });

        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final isEnglish = languageProvider.isEnglish;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Balance updated successfully! Added: $amount points'
                  : 'Баланс успешно пополнен! Добавлено: $amount баллов',
            ),
            backgroundColor: secondaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final isEnglish = languageProvider.isEnglish;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish
                  ? 'Error adding balance: $e'
                  : 'Ошибка при пополнении баланса: $e',
            ),
            backgroundColor: tertiaryColor,
          ),
        );
      }
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
            backgroundColor: backgroundColor,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: secondaryColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isEnglish ? 'Add Balance' : 'Пополнить баланс',
              style: const TextStyle(
                color: secondaryColor,
                fontFamily: 'Cornerita',
                fontSize: 20,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Текущий баланс
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: tertiaryColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isEnglish ? 'Current Balance' : 'Текущий баланс',
                        style: const TextStyle(
                          color: textColorSecondary,
                          fontSize: 16,
                          fontFamily: 'Cornerita',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingBalance)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/screw.png',
                              width: 32,
                              height: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_currentBalance ?? 0}',
                              style: const TextStyle(
                                fontFamily: 'StalinistOne',
                                color: Color(0xFFB19CD9),
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Форма пополнения
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: tertiaryColor, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEnglish 
                            ? 'Enter the amount to add:'
                            : 'Введите сумму для пополнения:',
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontFamily: 'Cornerita',
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: secondaryColor,
                          fontSize: 20,
                        ),
                        decoration: InputDecoration(
                          labelText: isEnglish ? 'Amount' : 'Сумма',
                          labelStyle: const TextStyle(color: textColorSecondary),
                          hintText: isEnglish ? 'Enter amount' : 'Введите сумму',
                          hintStyle: const TextStyle(color: textColorSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: tertiaryColor, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: secondaryColor, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: backgroundColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addBalance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                                ),
                              )
                            : Text(
                                isEnglish ? 'Add Balance' : 'Пополнить баланс',
                                style: const TextStyle(
                                  color: backgroundColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cornerita',
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Быстрые суммы
                Text(
                  isEnglish ? 'Quick Add' : 'Быстрое пополнение',
                  style: const TextStyle(
                    color: textColorSecondary,
                    fontSize: 16,
                    fontFamily: 'Cornerita',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [100, 250, 500, 1000].map((amount) {
                    return ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              _amountController.text = amount.toString();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: secondaryColor,
                        side: const BorderSide(color: tertiaryColor, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '+$amount',
                        style: const TextStyle(
                          fontFamily: 'Cornerita',
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
