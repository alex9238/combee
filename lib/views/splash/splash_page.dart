import 'package:combee/views/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:combee/core/constants/constants.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera 3 segundos y navega a la página principal
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand, // ocupa toda la pantalla
        children: [
          // Imagen de fondo
          Image.asset(
            AppImages.splash,
            fit: BoxFit.cover, // se adapta a la pantalla completa
          ),
          // Puedes agregar un logo o texto encima
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: const [
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}
