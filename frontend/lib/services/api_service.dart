import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8080'; 

  // Общий метод для запросов
  static Future<dynamic> _makeRequest(
    String method,
    String endpoint,
    dynamic body,
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json'
    };  
  
    // Добавляем токен
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = method.toUpperCase() == 'GET'
      ? await http.get(url, headers: headers)
      : await http.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Регистрация
  static Future<dynamic> register({
    required String username,
    required String email,
    required String password,
    int? age,
    String? phone,
  }) async {
    return await _makeRequest(
      'POST',
      '/register',
      {
        'username': username,
        'email': email,
        'password': password,
        'age': age,
        'phone': phone,
      },
    );
    
  }

  // Авторизация
  static Future<dynamic> login(String emailOrPhone, String password) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/login',
        {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );
      
      if (response is Map && response['token'] != null) {
        await _saveToken(response['token']);
        return response;
      } else {
        throw Exception('Токен не получен в ответе сервера');
      }
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  // Получение списка пользователей
  static Future<List<dynamic>> getUsers() async {
    return await _makeRequest('GET', '/users', null);
  }

  // Сохранение токена
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Получение токена
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Удаление токена (выход)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Получение профиля пользователя
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _makeRequest('GET', '/profile', null);
    return response;
  }

  // Обновление профиля
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required int age,
    required String status,
    required List<String> interests,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/profile-update',
        {
          'username': name,
          'email': email,
          'age': age,
          'status': status,
          'interests': interests,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}