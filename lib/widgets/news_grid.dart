import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'news_tile.dart';

class NewsGrid extends StatelessWidget {
  final List postsPrincipales;
  final List categories;
  final Function(int, String)? onCategorySelected;
  final Function(dynamic)? openDetail;

  NewsGrid({
    required this.postsPrincipales,
    required this.categories,
    this.onCategorySelected,
    this.openDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (postsPrincipales.isEmpty) return SizedBox.shrink();

    final principal = postsPrincipales[0];
    final otros = postsPrincipales.sublist(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimationLimiter(
          child: Column(
            children: [
              AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: NewsTile(
                      post: principal,
                      big: true,
                      categories: categories,
                      onCategorySelected: onCategorySelected,
                      onTap: openDetail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        AnimationLimiter(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: otros.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, idx) {
              return AnimationConfiguration.staggeredGrid(
                position: idx,
                duration: const Duration(milliseconds: 400),
                columnCount: 2,
                child: SlideAnimation(
                  verticalOffset: 30.0,
                  child: FadeInAnimation(
                    child: NewsTile(
                      post: otros[idx],
                      categories: categories,
                      onCategorySelected: onCategorySelected,
                      onTap: openDetail,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
