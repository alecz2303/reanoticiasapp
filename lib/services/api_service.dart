import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart'; // Importa tu config aquí

class ApiService {
  // Usa la variable global desde config.dart
  static const String baseUrl = wordpressApiUrl;

  static Future<List<dynamic>> fetchPosts({int perPage = 10, int categoryId = 0}) async {
    String url = "${baseUrl}posts?per_page=$perPage&_embed";
    if (categoryId != 0) url += "&categories=$categoryId";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar noticias');
    }
  }

  static Future<List<dynamic>> fetchPostsBySearch(String query) async {
    String url = "${baseUrl}posts?search=$query&_embed";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en la búsqueda');
    }
  }

  static Future<List<dynamic>> fetchCategories() async {
    final response = await http.get(Uri.parse("${baseUrl}categories"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  static Future<List<dynamic>> fetchComments(int postId) async {
    final response = await http.get(Uri.parse("${baseUrl}comments?post=$postId"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar comentarios');
    }
  }

  static Future<dynamic> fetchPostById(int postId) async {
    const String baseUrl = "https://reanayarit.com/wp-json/wp/v2/"; // pon tu baseUrl si no la tienes como variable global
    final url = "${baseUrl}posts/$postId?_embed";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('No se pudo cargar la noticia');
    }
  }


  static Future<bool> postComment({
    required int postId,
    required String name,
    required String email,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse("${baseUrl}comments"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "post": postId,
        "author_name": name,
        "author_email": email,
        "content": content,
      }),
    );
    return response.statusCode == 201;
  }
}
