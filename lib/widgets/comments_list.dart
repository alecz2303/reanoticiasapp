import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommentsList extends StatefulWidget {
  final int postId;

  CommentsList({Key? key, required this.postId}) : super(key: key);

  @override
  CommentsListState createState() => CommentsListState();
}

class CommentsListState extends State<CommentsList> {
  List comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    setState(() { isLoading = true; });
    try {
      comments = await ApiService.fetchComments(widget.postId);
    } catch (e) {
      comments = [];
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (comments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Sé el primero en comentar.", style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Comentarios",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...comments.map((comment) {
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(comment['author_name'] ?? "Anónimo",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment['content']['rendered']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? "",
                  ),
                  SizedBox(height: 4),
                  Text(
                    comment['date']?.substring(0, 16)?.replaceAll('T', ' ') ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
