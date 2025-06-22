import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  static const String _apiUrl = 'http://192.168.15.53:8000';
  
  String? _loggedInEmail;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  String? get loggedInEmail => _loggedInEmail;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadLoggedInUser();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInEmail = prefs.getString('emailLogado');
    if (_loggedInEmail != null) {
      await _loadUserData();
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_loggedInEmail == null) return;
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/user/$_loggedInEmail'));
      if (response.statusCode == 200) {
        _userData = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  Future<bool> sendOTP(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      _isLoading = false;
      notifyListeners();

      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emailLogado', email);
        _loggedInEmail = email;
        await _loadUserData();
      }

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'name': name}),
      );

      _isLoading = false;
      notifyListeners();

      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
    String? lastName,
    int? age,
    int? sharedRecipes,
  }) async {
    if (_loggedInEmail == null) return false;

    try {
      final updateData = <String, dynamic>{};
      if (lastName != null) updateData['last_name'] = lastName;
      if (age != null) updateData['age'] = age;
      if (sharedRecipes != null) updateData['shared_recipes'] = sharedRecipes;

      final response = await http.post(
        Uri.parse('$_apiUrl/update-user/$_loggedInEmail'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('emailLogado');
    _loggedInEmail = null;
    _userData = null;
    notifyListeners();
  }
} 