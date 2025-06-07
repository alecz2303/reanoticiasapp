import 'package:flutter/material.dart';
import 'news_tile.dart';

class CategorySection extends StatelessWidget {
  final String categoryTitle;
  final List posts;
  final List categories;
  final Function(int, String)? onCategorySelected;
  final Function(dynamic)? openDetail;
  final bool loading; // <-- Nuevo

  CategorySection({
    required this.categoryTitle,
    required this.posts,
    required this.categories,
    this.onCategorySelected,
    this.openDetail,
    this.loading = false, // <-- Nuevo
  });

  @override
  Widget build(BuildContext context) {
    // Si aún está cargando Y no hay posts, muestra un mini-loader
    if (loading && posts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Text(
              categoryTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          )),
        ],
      );
    }

    // Si ya cargó pero no hay posts, oculta la sección (comportamiento anterior)
    if (posts.isEmpty) return SizedBox.shrink();

    // Normal: muestra los posts
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Text(
            categoryTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ),
        ...posts.map((post) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: NewsTile(
            post: post,
            big: true,
            categories: categories,
            onCategorySelected: onCategorySelected,
            onTap: openDetail,
          ),
        )),
        SizedBox(height: 10),
      ],
    );
  }
}
