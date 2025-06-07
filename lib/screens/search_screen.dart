import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'news_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List categories;
  SearchScreen({required this.categories});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  List results = [];
  bool isLoading = false;

  Future<void> search(String query) async {
    setState(() { isLoading = true; });
    results = await ApiService.fetchPostsBySearch(query);
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar Noticias')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar por título...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => search(_controller.text),
                ),
              ),
              onSubmitted: search,
            ),
            SizedBox(height: 16),
            if (isLoading)
              CircularProgressIndicator()
            else if (results.isEmpty && _controller.text.isNotEmpty)
              Text('No se encontraron resultados')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, idx) {
                    final post = results[idx];
                    return ListTile(
                      leading: post['_embedded'] != null &&
                              post['_embedded']['wp:featuredmedia'] != null &&
                              post['_embedded']['wp:featuredmedia'].length > 0
                          ? Image.network(
                              post['_embedded']['wp:featuredmedia'][0]['source_url'],
                              width: 56, height: 56, fit: BoxFit.cover,
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[300],
                              child: Icon(Icons.article, color: Colors.grey[700]),
                            ),
                      title: Text(post['title']['rendered'] ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: post['categories'] != null && post['categories'].isNotEmpty
                          ? Text(
                              _getCategoryName(post['categories'], widget.categories),
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailScreen(
                              post: post,
                              categories: widget.categories,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(List postCats, List allCats) {
    for (final catId in postCats) {
      final cat = allCats.firstWhere((c) => c['id'] == catId, orElse: () => null);
      if (cat != null && cat['name'] != 'Principales') return cat['name'];
    }
    return '';
  }
}
