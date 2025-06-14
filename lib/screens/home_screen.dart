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
  Map<String, bool> categoryLoading = {};
  bool isLoading = true;
  int? selectedCategoryId;
  String? selectedCategoryName;
  List filteredPosts = [];

  // Para animación de icono en SnackBar
  int _refreshIconIndex = 0;
  final List<IconData> _refreshIcons = [
    Icons.refresh,
    Icons.check_circle,
  ];

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

  // Animación de SnackBar con icono animado
  void _showAnimatedSnackBar(BuildContext context) {
    setState(() => _refreshIconIndex = 0);

    final snackBar = SnackBar(
      content: Row(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 600),
            child: Icon(
              _refreshIcons[_refreshIconIndex],
              key: ValueKey(_refreshIcons[_refreshIconIndex]),
              color: Colors.green,
              size: 28,
            ),
            transitionBuilder: (child, animation) =>
                RotationTransition(turns: animation, child: child),
          ),
          SizedBox(width: 10),
          Text('¡Noticias actualizadas!'),
        ],
      ),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Cambia el icono al de "check" después de un pequeño delay
    Future.delayed(Duration(milliseconds: 700), () {
      setState(() => _refreshIconIndex = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un Builder para obtener el context correcto para el SnackBar
    return Builder(
      builder: (snackContext) => Scaffold(
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
            : RefreshIndicator(
                onRefresh: () async {
                  await loadInitData();
                  // Muestra SnackBar cuando termina la recarga
                  _showAnimatedSnackBar(snackContext);
                },
                child: filteredPosts.isNotEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                              loading: loading,
                            );
                          }),
                        ],
                      ),
              ),
      ),
    );
  }
}
