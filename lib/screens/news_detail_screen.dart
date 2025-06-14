import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_iframe/flutter_html_iframe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/logo_header.dart';
import '../widgets/category_menu.dart';
import '../widgets/comment_form.dart';
import '../widgets/comments_list.dart';
import '../services/api_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final dynamic post;
  final List? categories;
  final int? postId;

  NewsDetailScreen({this.post, this.categories, this.postId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final GlobalKey<CommentsListState> commentsListKey = GlobalKey<CommentsListState>();

  dynamic _post;
  List _categories = [];
  bool _isLoading = true;

  List relatedPosts = [];
  bool relatedLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null && widget.categories != null) {
      _post = widget.post;
      _categories = widget.categories!;
      _isLoading = false;
      fetchRelatedPosts();
    } else if (widget.postId != null) {
      _fetchData();
    }
  }

  Future<void> fetchRelatedPosts() async {
    relatedLoading = true;
    setState(() {});
    final categoriesIds = _post['categories'] ?? [];
    int? catId;
    for (final id in categoriesIds) {
      final cat = _categories.firstWhere((c) => c['id'] == id, orElse: () => null);
      if (cat != null && cat['name'] != 'Principales') {
        catId = id;
        break;
      }
    }
    if (catId != null) {
      final posts = await ApiService.fetchPosts(perPage: 5, categoryId: catId);
      relatedPosts = posts.where((p) => p['id'] != _post['id']).toList();
    } else {
      relatedPosts = [];
    }
    relatedLoading = false;
    setState(() {});
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final post = await ApiService.fetchPostById(widget.postId!);
      final categories = await ApiService.fetchCategories();
      setState(() {
        _post = post;
        _categories = categories;
        _isLoading = false;
      });
      await fetchRelatedPosts();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  /// FILTRO DE HTML: IGNORA iframes vacíos, ads, etc
  List<Widget> _buildContentWidgets(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    List<Widget> widgets = [];

    for (var node in document.body?.nodes ?? []) {
      if (node.nodeType == dom.Node.ELEMENT_NODE) {
        final element = node as dom.Element;

        // ⛔️ Ignora divs de ads por id/clase
        final id = element.id ?? '';
        final clase = element.className ?? '';
        if (id.contains('ads') || id.contains('ad_') || clase.contains('ads') || clase.contains('ad_')) {
          continue;
        }

        // ⛔️ Ignora iframes SIN src válido (o vacíos)
        if (element.localName == 'iframe') {
          final src = element.attributes['src'];
          if (src == null || !src.startsWith('http')) {
            continue;
          }
        }

        // YouTube links
        if (element.localName == 'a' && element.attributes['href'] != null &&
            (element.attributes['href']!.contains('youtube.com') || element.attributes['href']!.contains('youtu.be'))) {
          widgets.add(_buildYoutubePlayer(element.attributes['href']!));
        } else {
          widgets.add(Html(
            data: element.outerHtml,
            onLinkTap: (String? url, Map<String, String> attributes, dom.Element? element) async {
              if (url != null && url.startsWith('http')) {
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

  Widget buildNetworkImageOrPlaceholder(String? url, {double? width, double? height, BoxFit? fit}) {
    if (url != null && url.trim().isNotEmpty && url.trim().startsWith('http')) {
      return Image.network(url.trim(), width: width, height: height, fit: fit ?? BoxFit.cover);
    }
    return Image.asset('assets/placeholder.png', width: width, height: height, fit: fit ?? BoxFit.cover);
  }

  Widget _buildRelatedPostsBlock() {
    if (relatedLoading) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (relatedPosts.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Noticias Relacionadas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          SizedBox(height: 10),
          ...relatedPosts.take(3).map((post) => Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: buildNetworkImageOrPlaceholder(
                post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] as String?,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(post['title']['rendered'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(post: post, categories: _categories),
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    if (widget.postId != null) {
      await _fetchData();
    } else if (_post != null && _categories.isNotEmpty) {
      setState(() => _isLoading = true);
      await fetchRelatedPosts();
      setState(() => _isLoading = false);
    }
    commentsListKey.currentState?.fetchComments();
  }

  /// ----------- SOCIAL SHARE BUTTONS ----------------
  Widget _buildShareButtons() {
    final url = _post['link'] ?? '';
    final title = _post['title']?['rendered'] ?? '';
    if (url.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        children: [
          // WhatsApp
          IconButton(
            icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green, size: 30),
            tooltip: "WhatsApp",
            onPressed: () async {
              final link = Uri.encodeComponent('$title $url');
              final waUrl = 'https://wa.me/?text=$link';
              if (await canLaunchUrl(Uri.parse(waUrl))) {
                await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Facebook
          IconButton(
            icon: FaIcon(FontAwesomeIcons.facebook, color: Colors.blue[900], size: 30),
            tooltip: "Facebook",
            onPressed: () async {
              final fbUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}';
              if (await canLaunchUrl(Uri.parse(fbUrl))) {
                await launchUrl(Uri.parse(fbUrl), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // X (Twitter)
          IconButton(
            icon: FaIcon(FontAwesomeIcons.xTwitter, color: Colors.black, size: 30),
            tooltip: "X (Twitter)",
            onPressed: () async {
              final twUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(url)}';
              if (await canLaunchUrl(Uri.parse(twUrl))) {
                await launchUrl(Uri.parse(twUrl), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Telegram
          IconButton(
            icon: FaIcon(FontAwesomeIcons.telegram, color: Colors.blue, size: 30),
            tooltip: "Telegram",
            onPressed: () async {
              final tgUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(title)}';
              if (await canLaunchUrl(Uri.parse(tgUrl))) {
                await launchUrl(Uri.parse(tgUrl), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Messenger
          IconButton(
            icon: FaIcon(FontAwesomeIcons.facebookMessenger, color: Colors.blueAccent, size: 30),
            tooltip: "Messenger",
            onPressed: () async {
              final msUrl = 'fb-messenger://share?link=${Uri.encodeComponent(url)}';
              if (await canLaunchUrl(Uri.parse(msUrl))) {
                await launchUrl(Uri.parse(msUrl), mode: LaunchMode.externalApplication);
              } else {
                // Si no tiene la app, abre en web
                final webUrl = 'https://www.facebook.com/dialog/send?link=${Uri.encodeComponent(url)}&app_id=YOUR_FACEBOOK_APP_ID&redirect_uri=${Uri.encodeComponent(url)}';
                await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Compartir genérico
          IconButton(
            icon: Icon(Icons.share, color: Colors.red, size: 30),
            tooltip: "Compartir...",
            onPressed: () {
              Share.share('$title\n$url');
            },
          ),
        ],
      ),
    );
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
    final imgUrl = _post['_embedded']?['wp:featuredmedia']?[0]?['source_url'] as String?;
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          padding: EdgeInsets.all(0),
          children: [
            Hero(
              tag: 'newsImage${_post['id']}',
              child: buildNetworkImageOrPlaceholder(imgUrl, width: double.infinity, height: 220, fit: BoxFit.cover),
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
                  _buildShareButtons(), // <<--- Aquí los iconos sociales
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
            _buildRelatedPostsBlock(),
          ],
        ),
      ),
    );
  }
}
