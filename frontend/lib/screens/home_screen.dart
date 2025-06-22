import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _ratingController = TextEditingController();
  String? _selectedImagePath;
  bool _showModal = false;
  Set<String> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
      // Forçar recarregamento das receitas
      context.read<RecipeProvider>().reloadRecipes();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bem-vindo!'),
        content: const Text('Aproveite suas receitas de família!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onImageSelected(String imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
      _showModal = true;
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
      }
    });
  }

  Future<void> _addRecipe() async {
    if (_titleController.text.trim().isEmpty ||
        _ingredientsController.text.trim().isEmpty ||
        _ratingController.text.trim().isEmpty) {
      _showSnackBar('Preencha todos os campos!');
      return;
    }

    final rating = double.tryParse(_ratingController.text);
    if (rating == null || rating < 0 || rating > 5) {
      _showSnackBar('A nota deve ser um número entre 0 e 5');
      return;
    }

    final recipeProvider = context.read<RecipeProvider>();
    await recipeProvider.addRecipe(
      title: _titleController.text.trim(),
      description: _ingredientsController.text.trim(),
      rating: rating,
      imagePath: _selectedImagePath,
    );

    setState(() {
      _showModal = false;
      _selectedImagePath = null;
    });

    _titleController.clear();
    _ingredientsController.clear();
    _ratingController.clear();

    _showSnackBar('Receita adicionada!');
  }

  Future<void> _deleteRecipe(String recipeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja excluir esta receita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final recipeProvider = context.read<RecipeProvider>();
      await recipeProvider.deleteRecipe(recipeId);
      _showSnackBar('Receita excluída!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _debugReloadRecipes() async {
    final recipeProvider = context.read<RecipeProvider>();
    await recipeProvider.clearAllRecipes();
    await recipeProvider.reloadRecipes();
    _showSnackBar('Cache limpo e receitas recarregadas!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              HeaderWidget(onDebugReload: _debugReloadRecipes),
              Expanded(
                child: Consumer<RecipeProvider>(
                  builder: (context, recipeProvider, child) {
                    if (recipeProvider.recipes.isEmpty && !recipeProvider.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma receita encontrada',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicione sua primeira receita!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Indicador de receitas carregadas
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          color: Colors.white,
                          child: Text(
                            '${recipeProvider.recipes.length} receita${recipeProvider.recipes.length != 1 ? 's' : ''} carregada${recipeProvider.recipes.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 80,
                              left: 0,
                              right: 0,
                            ),
                            itemCount: recipeProvider.recipes.length + 1,
                            itemBuilder: (context, index) {
                              if (index == recipeProvider.recipes.length) {
                                if (recipeProvider.isLoading) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (recipeProvider.hasMore) {
                                  recipeProvider.loadMoreRecipes();
                                }
                                return const SizedBox.shrink();
                              }

                              final recipe = recipeProvider.recipes[index];
                              final isExpanded = _expandedItems.contains(recipe.id);

                              return GestureDetector(
                                onTap: () => _toggleItem(recipe.id),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (recipe.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          child: recipe.imageUrl!.startsWith('http')
                                              ? Image.network(
                                                  recipe.imageUrl!,
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  File(recipe.imageUrl!),
                                                  width: double.infinity,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '⭐ ${recipe.rating}',
                                              style: const TextStyle(
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                            if (!isExpanded) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                recipe.description.length > 100
                                                    ? '${recipe.description.substring(0, 100)}...'
                                                    : recipe.description,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Toque para expandir',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                            if (isExpanded) ...[
                                              const SizedBox(height: 8),
                                              if (recipe.ingredients != null) ...[
                                                Text(
                                                  'Ingredientes: ${recipe.ingredients!.take(4).join(', ')}${recipe.ingredients!.length > 4 ? '…' : ''}',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(recipe.description),
                                              ],
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () => _deleteRecipe(recipe.id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFF4444),
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Excluir Receita',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FooterWidget(onImageSelected: _onImageSelected),
          ),
          
          // Modal para adicionar receita
          if (_showModal)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nome da Receita:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Ingredientes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ingredientsController,
                        decoration: const InputDecoration(
                          hintText: 'Ex: farinha, ovo, leite',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Nota (0-5):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ratingController,
                        decoration: const InputDecoration(
                          hintText: '0 a 5',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showModal = false;
                                _selectedImagePath = null;
                              });
                              _titleController.clear();
                              _ingredientsController.clear();
                              _ratingController.clear();
                            },
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _addRecipe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Adicionar',
                              style: TextStyle(color: Colors.white),
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
  }
} 