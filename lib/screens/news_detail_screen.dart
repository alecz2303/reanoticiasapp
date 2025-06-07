import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../widgets/logo_header.dart';
import '../widgets/category_menu.dart';
import '../widgets/comment_form.dart';
import '../widgets/comments_list.dart';
import '../services/api_service.dart'; // Importa tu servicio API

class NewsDetailScreen extends StatefulWidget {
  final dynamic post;        // Puede ser null si llegas desde push
  final List? categories;    // Puede ser null si llegas desde push
  final int? postId;         // Para push

  NewsDetailScreen({this.post, this.categories, this.postId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final GlobalKey<CommentsListState> commentsListKey = GlobalKey<CommentsListState>();

  dynamic _post;
  List _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null && widget.categories != null) {
      _post = widget.post;
      _categories = widget.categories!;
      _isLoading = false;
    } else if (widget.postId != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    try {
      final post = await ApiService.fetchPostById(widget.postId!);
      final categories = await ApiService.fetchCategories();
      setState(() {
        _post = post;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Muestra error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo cargar la noticia")),
      );
    }
  }

  String getMainCategory(List ids) {
    for (var cat in _categories) {
      if (cat['id'] != null && ids.contains(cat['id']) && cat['name'] != 'Principales') {
        return cat['name'];
      }
    }
    return '';
  }

  Widget _buildYoutubePlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(autoPlay: false, mute: false),
        ),
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
      ),
    );
  }

  List<Widget> _buildContentWidgets(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    List<Widget> widgets = [];

    for (var node in document.body?.nodes ?? []) {
      if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final element = node as dom.Element;
        // YouTube link simple (no iframe)
        if (element.localName == 'a' && element.attributes['href'] != null &&
            (element.attributes['href']!.contains('youtube.com') || element.attributes['href']!.contains('youtu.be'))) {
          widgets.add(_buildYoutubePlayer(element.attributes['href']!));
        } else {
          // Para todo lo demás (incluye iframes de FB, Insta, etc)
          widgets.add(Html(
            data: element.outerHtml,
            onLinkTap: (String? url, Map<String, String> attributes, dom.Element? element) async {
              if (url != null) {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              }
            },
            extensions: [
              const IframeHtmlExtension(),
            ],
          ));
        }
      } else if (node.nodeType == dom.Node.TEXT_NODE) {
        final text = node.text?.trim();
        if (text != null && text.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(text),
          ));
        }
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Cargando...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _post['title']['rendered'] ?? '';
    final content = _post['content']['rendered'] ?? '';
    final imgUrl = _post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] ?? '';
    final date = _post['date'] ?? '';
    final categoryIds = _post['categories'] ?? [];
    final categoryName = getMainCategory(categoryIds);

    return Scaffold(
      appBar: AppBar(
        title: LogoHeader(),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: CategoryMenu(
            categories: _categories,
            selectedCategoryId: null,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(0),
        children: [
          if (imgUrl.isNotEmpty)
            Hero(
              tag: 'newsImage${_post['id']}',
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png',
                image: imgUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(date)),
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                SizedBox(height: 12),
                ..._buildContentWidgets(content),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: CommentForm(
                    key: ValueKey('form-${_post['id']}'),
                    postId: _post['id'],
                    onCommentPosted: () {
                      commentsListKey.currentState?.fetchComments();
                    },
                  ),
                ),
                SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: CommentsList(
                    key: commentsListKey,
                    postId: _post['id'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
