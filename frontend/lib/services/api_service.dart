import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      http.Response response;
      final methodUpper = method.toUpperCase();
      
      if (methodUpper == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (methodUpper == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (methodUpper == 'PUT') {
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (methodUpper == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {};
        }
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Регистрация
  static Future<dynamic> register({
    String? username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String studyGroup,
    required int enrollmentYear,
    required String educationalInstitution,
    required String educationalDirection,
    required int age,
    required String phone,
  }) async {
    return await _makeRequest(
      'POST',
      '/register',
      {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'study_group': studyGroup,
        'enrollment_year': enrollmentYear,
        'educational_institution': educationalInstitution,
        'educational_direction': educationalDirection,
        'age': age,
        'phone': phone,
      },
    );
    
  }

  // Авторизация
  static Future<dynamic> login(String emailOrPhone, String password, {bool saveSession = true}) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/login',
        {
          'emailOrPhone': emailOrPhone,
          'password': password,
          'saveSession': saveSession,
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

  // ЗАКОММЕНТИРОВАНО: Проверка кода и завершение авторизации (можно вернуть, раскомментировав)
  /*
  static Future<dynamic> verifyCode(String email, String code) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/verify-code',
        {
          'email': email,
          'code': code,
        },
      );
      
      if (response is Map && response['token'] != null) {
        await _saveToken(response['token']);
        return response;
      } else {
        throw Exception('Токен не получен в ответе сервера');
      }
    } catch (e) {
      throw Exception('Ошибка проверки кода: $e');
    }
  }
  */

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
    try {
      // Вызываем endpoint logout на сервере для удаления сессии из Redis
      await _makeRequest('POST', '/logout', null);
    } catch (e) {
      // Игнорируем ошибки, если сервер недоступен
      debugPrint('Warning: Failed to logout on server: $e');
    } finally {
      // Всегда удаляем токен локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  // Проверка валидности токена
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        return false;
      }
      
      // Проверяем токен, делая запрос к защищенному endpoint
      await _makeRequest('GET', '/current-user', null);
      return true;
    } catch (e) {
      // Если токен невалиден, удаляем его локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      return false;
    }
  }

  // Получение профиля пользователя
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _makeRequest('GET', '/profile', null);
    return response;
  }

  // Обновление профиля
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    required String email,
    required int age,
    required String status,
    required List<String> interests,
    required String firstName,
    required String lastName,
    required String studyGroup,
    required int enrollmentYear,
    required String educationalInstitution,
    required String educationalDirection,
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
          'first_name': firstName,
          'last_name': lastName,
          'study_group': studyGroup,
          'enrollment_year': enrollmentYear,
          'educational_institution': educationalInstitution,
          'educational_direction': educationalDirection,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Создание события (только для админов)
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/createevent');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json'
      };
      
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'type': type,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Получение всех событий
  static Future<List<dynamic>> getEvents() async {
    try {
      final response = await _makeRequest('GET', '/events', null);
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Получение всех опросников
  static Future<List<dynamic>> getSurveys() async {
    try {
      final response = await _makeRequest('GET', '/surveys', null);
      if (response is List) {
        return response;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Создание опросника (только для админов)
  static Future<Map<String, dynamic>> createSurvey({
    required dynamic title, // Может быть String или Map для поддержки многоязычности
    required String description,
    required List<Map<String, dynamic>> questions,
    String? imageUrl,
    DateTime? endDate,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/createsurvey',
        {
          'title': title,
          'description': description,
          'questions': questions,
          if (imageUrl != null) 'image_url': imageUrl,
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to create survey: $e');
    }
  }

  // Прохождение опросника
  static Future<Map<String, dynamic>> submitSurvey({
    required int surveyId,
    required List<dynamic> answers,
  }) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/submitsurvey',
        {
          'survey_id': surveyId,
          'answers': answers,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Failed to submit survey: $e');
    }
  }

  // Получение статистики опросника (только для админов)
  static Future<Map<String, dynamic>> getSurveyStatistics(int surveyId) async {
    try {
      final response = await _makeRequest('GET', '/surveys/$surveyId/statistics', null);
      return response;
    } catch (e) {
      throw Exception('Failed to get survey statistics: $e');
    }
  }

  // Получение роли пользователя из профиля
  static Future<String?> getUserRole() async {
    try {
      final profile = await getProfile();
      return profile['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Пополнение баланса пользователя
  static Future<Map<String, dynamic>> addPoints(int points) async {
    final response = await _makeRequest('POST', '/add-points', {
      'points': points,
    });
    return response;
  }
}