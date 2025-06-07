import 'package:flutter/material.dart';

class CategoryMenu extends StatelessWidget {
  final List categories;
  final Function(int, String)? onCategorySelected;
  final int? selectedCategoryId;

  const CategoryMenu({
    Key? key,
    required this.categories,
    this.onCategorySelected,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List allCategories = [
      {'id': -1, 'name': 'Inicio'},
      ...categories
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 350),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: Row(
          key: ValueKey(selectedCategoryId),
          children: allCategories.map((category) {
            final isSelected = selectedCategoryId == category['id'] ||
                (selectedCategoryId == null && category['id'] == -1);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (onCategorySelected != null) {
                    onCategorySelected!(category['id'], category['name']);
                  } else {
                    Navigator.pop(context, {'id': category['id'], 'name': category['name']});
                  }
                },
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category['id'] == -1) ...[
                        Icon(Icons.home, size: 18, color: isSelected ? Colors.white : Colors.blue.shade900),
                        SizedBox(width: 4),
                      ],
                      Text(category['name']),
                    ],
                  ),
                  backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
