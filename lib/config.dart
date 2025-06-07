import 'package:flutter/material.dart';
// lib/config.dart

/// --- CONFIGURACIÓN GENERAL DEL SITIO ---

/// Cambia esta URL al clonar el proyecto para otro WordPress:
const String wordpressApiUrl = 'https://reanayarit.com/wp-json/wp/v2/';

/// Nombre de tu app (aparece en splash o header si lo usas)
const String appName = 'Rea Nayarit';

/// Color principal de tu marca (puedes usarlo en ThemeData)
const MaterialColor appColor = Colors.red;

/// --- CATEGORÍAS Y MENÚ ---

/// ID especial para la opción "Inicio" del menú
const int inicioCategoryId = -1;

/// ID de la categoría "Principales" en tu WordPress
const int principalesCategoryId = 7;

/// Puedes agregar IDs de otras categorías especiales si tienes:
/// const int avisosCategoryId = 12;

/// --- OTROS AJUSTES Y CONSTANTES ---

/// Número de posts por página en la vista principal
const int postsPerPage = 10;

/// Imagen genérica para posts sin imagen (asegúrate de tenerla en assets)
const String genericNewsImage = 'assets/noticia_generica.png';

/// Placeholder para carga de imágenes
const String placeholderImage = 'assets/placeholder.png';

/// Logo de tu app (en assets)
const String logoImage = 'assets/logo.png';

/// Si usas otro endpoint para comentarios o login, agrégalo aquí.
/// Ejemplo:
/// const String commentsApiUrl = 'https://reanayarit.com/wp-json/wp/v2/comments';

/// --- FIN DE CONFIGURACIÓN ---
