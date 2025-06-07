class Post {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final List<String> categories;
  final String date;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.categories,
    required this.date,
  });
}
