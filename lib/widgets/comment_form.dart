import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommentForm extends StatefulWidget {
  final int postId;
  final VoidCallback? onCommentPosted;

  const CommentForm({Key? key, required this.postId, this.onCommentPosted}) : super(key: key);

  @override
  _CommentFormState createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String comment = '';
  bool isLoading = false;
  String? message;

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isLoading = true; message = null; });

    final success = await ApiService.postComment(
      postId: widget.postId,
      name: name,
      email: email,
      content: comment,
    );

    setState(() {
      isLoading = false;
      message = success ? "¡Comentario enviado!" : "Error al enviar el comentario.";
      if (success) {
        _formKey.currentState!.reset();
        if (widget.onCommentPosted != null) widget.onCommentPosted!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Deja un comentario", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(labelText: "Nombre"),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                onChanged: (v) => name = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Email"),
                validator: (v) => v == null || !v.contains("@") ? "Ingresa un email válido" : null,
                onChanged: (v) => email = v,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Comentario"),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
                minLines: 2,
                maxLines: 5,
                onChanged: (v) => comment = v,
              ),
              SizedBox(height: 8),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      child: Text("Enviar"),
                      onPressed: submit,
                    ),
              if (message != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    message!,
                    style: TextStyle(
                        color: message!.toLowerCase().contains('error')
                            ? Colors.red
                            : Colors.green),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
