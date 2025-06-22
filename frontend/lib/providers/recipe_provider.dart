import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final double rating;
  final String? imageUrl;
  final List<String>? ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.rating,
    this.imageUrl,
    this.ingredients,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'].toString(),
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      imageUrl: json['image'] ?? json['thumbnail'],
      ingredients: json['ingredients'] != null 
          ? List<String>.from(json['ingredients'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rating': rating,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
    };
  }
}

class RecipeProvider with ChangeNotifier {
  static const String _apiUrl = 'http://192.168.15.53:8000';
  static const int _pageSize = 100;
  
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  RecipeProvider() {
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRecipes = prefs.getString('receitas');
      
      if (savedRecipes != null) {
        final List<dynamic> recipesJson = json.decode(savedRecipes);
        _recipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();
        _hasMore = false;
        notifyListeners();
      } else {
        await _fetchRecipes();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar receitas: $e');
      }
    }
  }

  Future<void> _fetchRecipes() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://dummyjson.com/recipes?limit=$_pageSize&skip=$_skip'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> recipesJson = data['recipes'] ?? [];
        
        if (recipesJson.isNotEmpty) {
          final newRecipes = recipesJson.map((json) => Recipe.fromJson(json)).toList();
          _recipes.addAll(newRecipes);
          _skip += _pageSize;
          
          if (recipesJson.length < _pageSize) {
            _skip = 0;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar receitas: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRecipe({
    required String title,
    required String description,
    required double rating,
    String? imagePath,
  }) async {
    try {
      final authProvider = AuthProvider();
      final emailLogado = authProvider.loggedInEmail;
      
      if (emailLogado != null) {
        // Buscar dados atuais do usuário
        final response = await http.get(Uri.parse('$_apiUrl/user/$emailLogado'));
        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          final updatedSharedRecipes = (userData['shared_recipes'] ?? 0) + 1;

          // Atualizar o contador no backend
          await http.post(
            Uri.parse('$_apiUrl/update-user/$emailLogado'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'shared_recipes': updatedSharedRecipes}),
          );
        }
      }

      final newRecipe = Recipe(
        id: '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        description: description,
        rating: rating,
        imageUrl: imagePath,
      );

      _recipes.insert(0, newRecipe);
      await _saveRecipes();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao adicionar receita: $e');
      }
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    _recipes.removeWhere((recipe) => recipe.id == recipeId);
    await _saveRecipes();
    notifyListeners();
  }

  Future<void> clearAllRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('receitas');
      _recipes.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao limpar receitas: $e');
      }
    }
  }

  Future<void> _saveRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recipesJson = _recipes.map((recipe) => recipe.toJson()).toList();
      await prefs.setString('receitas', json.encode(recipesJson));
      
      if (kDebugMode) {
        print('Receitas salvas: ${_recipes.length}');
        print('Primeira receita: ${_recipes.isNotEmpty ? _recipes.first.title : 'Nenhuma'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar receitas: $e');
      }
    }
  }

  Future<void> reloadRecipes() async {
    await _loadRecipes();
  }

  void loadMoreRecipes() {
    if (!_isLoading && _hasMore) {
      _fetchRecipes();
    }
  }
} 