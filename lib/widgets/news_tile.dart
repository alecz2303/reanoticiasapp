import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsTile extends StatefulWidget {
  final dynamic post;
  final bool big;
  final List categories;
  final Function(int, String)? onCategorySelected;
  final Function(dynamic)? onTap;

  NewsTile({
    required this.post,
    this.big = false,
    required this.categories,
    this.onCategorySelected,
    this.onTap,
  });

  @override
  State<NewsTile> createState() => _NewsTileState();
}

class _NewsTileState extends State<NewsTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown([_]) {
    _controller.reverse();
  }

  void _onTapUp([_]) {
    _controller.forward();
  }

  String getMainCategory(List ids) {
    for (var cat in widget.categories) {
      if (cat['id'] != null && ids.contains(cat['id']) && cat['name'] != 'Principales') {
        return cat['name'];
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.post['title']['rendered'] ?? '';
    final categoryIds = widget.post['categories'] ?? [];
    final imgUrl = widget.post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
    final catDisplay = getMainCategory(categoryIds);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap != null ? () => widget.onTap!(widget.post) : null,
        onTapDown: _onTapDown,
        onTapCancel: _onTapUp,
        onTapUp: _onTapUp,
        child: Card(
          elevation: widget.big ? 6 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Hero(
                  tag: 'newsImage${widget.post['id']}',
                  child: imgUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imgUrl,
                          height: widget.big ? 200 : 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Image.asset(
                            'assets/placeholder.png',
                            height: widget.big ? 200 : 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/noticia_generica.png',
                            height: widget.big ? 200 : 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/noticia_generica.png',
                          height: widget.big ? 200 : 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (catDisplay.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 4),
                        child: Text(
                          catDisplay,
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.big ? 16 : 12,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      maxLines: widget.big ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: widget.big ? 18 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
