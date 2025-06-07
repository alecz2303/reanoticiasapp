import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/logo_header.dart';
import '../widgets/category_menu.dart';
import '../widgets/news_grid.dart';
import '../widgets/category_section.dart';
import '../widgets/news_tile.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List categories = [];
  List postsPrincipales = [];
  Map<String, List> categoryPosts = {};
  Map<String, bool> categoryLoading = {}; // Para saber si una sección sigue cargando
  bool isLoading = true;
  int? selectedCategoryId;
  String? selectedCategoryName;
  List filteredPosts = [];

  @override
  void initState() {
    super.initState();
    loadInitData();
  }

  Future<void> loadInitData() async {
    // Paso 1: carga las categorías y principales
    categories = await ApiService.fetchCategories();
    final mainCategory = categories.firstWhere((c) => c['name'] == "Principales", orElse: () => null);
    final mainCategoryId = mainCategory != null ? mainCategory['id'] : 0;
    postsPrincipales = await ApiService.fetchPosts(perPage: 5, categoryId: mainCategoryId);

    // Marca todas las categorías como "cargando"
    for (var cat in categories) {
      if (cat['name'] != 'Principales') {
        categoryLoading[cat['name']] = true;
      }
    }

    setState(() {
      isLoading = false;
      selectedCategoryId = -1; // "Inicio" seleccionado por default
      selectedCategoryName = "Inicio";
      filteredPosts = [];
    });

    // Paso 2: carga las otras categorías en segundo plano
    Future.microtask(() async {
      for (var cat in categories) {
        if (cat['name'] != 'Principales') {
          var posts = await ApiService.fetchPosts(perPage: 3, categoryId: cat['id']);
          setState(() {
            categoryPosts[cat['name']] = posts;
            categoryLoading[cat['name']] = false;
          });
        }
      }
    });
  }

  Future<void> filterByCategory(int categoryId, String categoryName) async {
    setState(() {
      isLoading = true;
      selectedCategoryId = categoryId;
      selectedCategoryName = categoryName;
    });
    if (categoryId == -1) { // Si es "Inicio"
      filteredPosts = [];
    } else {
      filteredPosts = await ApiService.fetchPosts(perPage: 50, categoryId: categoryId);
    }
    setState(() {
      isLoading = false;
    });
  }

  void goToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  Future<void> openDetail(post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(post: post, categories: categories),
      ),
    );
    if (result != null && result is Map) {
      filterByCategory(result['id'], result['name']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: LogoHeader(),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: goToSearch,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: CategoryMenu(
            categories: categories,
            selectedCategoryId: selectedCategoryId,
            onCategorySelected: (int id, String name) => filterByCategory(id, name),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredPosts.isNotEmpty
          ? ListView(
        children: filteredPosts.map((post) =>
            NewsTile(
              post: post,
              big: true,
              categories: categories,
              onCategorySelected: (int id, String name) => filterByCategory(id, name),
              onTap: openDetail,
            ),
        ).toList(),
      )
          : ListView(
        children: [
          NewsGrid(
            postsPrincipales: postsPrincipales,
            categories: categories,
            onCategorySelected: (int id, String name) => filterByCategory(id, name),
            openDetail: openDetail,
          ),
          ...categories.where((cat) => cat['name'] != 'Principales').map((cat) {
            final name = cat['name'];
            final posts = categoryPosts[name] ?? [];
            final loading = categoryLoading[name] ?? false;
            return CategorySection(
              categoryTitle: name,
              posts: posts,
              categories: categories,
              onCategorySelected: (int id, String name) => filterByCategory(id, name),
              openDetail: openDetail,
              loading: loading, // Debes agregar esto a tu CategorySection para mostrar loader
            );
          }),
        ],
      ),
    );
  }
}
