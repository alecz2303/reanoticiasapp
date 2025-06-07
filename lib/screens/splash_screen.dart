import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/logo_header.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[700], // Cambia el color a tu marca si prefieres
      body: Center(child: LogoHeader()),
    );
  }
}
