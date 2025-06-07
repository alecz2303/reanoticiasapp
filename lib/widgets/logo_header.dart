import 'package:flutter/material.dart';
import '../config.dart';

class LogoHeader extends StatefulWidget {
  @override
  _LogoHeaderState createState() => _LogoHeaderState();
}

class _LogoHeaderState extends State<LogoHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _controller,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              logoImage,
              height: 40,
            ),
            SizedBox(width: 12),
            Flexible(   // <-- Esto es clave
              child: Text(
                appName,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
                overflow: TextOverflow.ellipsis, // <-- Esto evita el desbordamiento
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
