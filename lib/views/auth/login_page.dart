import 'package:flutter/material.dart';
import 'package:combee/views/concessionaire/route_filter_page.dart';
import 'package:combee/views/configuration/configuration_page.dart';
import 'package:combee/views/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    _loadConfigurationPage();
  }

  _loadConfigurationPage() async {
    if (await _check()) {
      return;
    }
  }

  Future<bool> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final exists = prefs.containsKey("isLogin");

    if (exists) {
      final value = await prefs.getString("isLogin");
      print("✅ 'isLogin' existe. Valor: $value");

      if (value == "true") {
        final value = await prefs.getString("tipo");

        print("✅ 'tipo' existe. Valor: $value");

        if (value == AppUser.chofer) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );

          return true;
        } else if (value == AppUser.concesionario) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RouteFilterPage()),
          );
          return true;
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ConfigurationPage(view: AppUser.checador),
            ),
          );

          return true;
        }
      }
    } else {
      print("⚠️ 'isLogin' no existe en SharedPreferences.");
    }

    return false;
  }

  // Función para abrir la URL de políticas de privacidad
  _openPrivacyPolicy() async {
    const url =
        'https://combee.com-mx.com.mx/politica-privacidad.html'; // Cambia por tu URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Función cuando se presiona Concesionario
  _onConcesionarioTap() async {
    print('Concesionario presionado');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("isLogin", "true");
    await prefs.setString("tipo", AppUser.concesionario);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => RouteFilterPage()),
    );
    // Aquí puedes agregar la navegación o lógica para concesionario
    // Por ejemplo:
    //Navigator.push(context, MaterialPageRoute(builder: (context) => ConcesionarioPage()));
  }

  // Función cuando se presiona Chofer
  _onChoferTap() async {
    print('Chofer presionado');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("isLogin", "true");
    await prefs.setString("tipo", AppUser.chofer);
    // Aquí puedes agregar la navegación o lógica para chofer
    // Por ejemplo:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  _onChecadorTap() async {
    print('Checador presionado');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("isLogin", "true");
    await prefs.setString("tipo", AppUser.checador);
    // Aquí puedes agregar la navegación o lógica para chofer
    // Por ejemplo:
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfigurationPage(view: AppUser.checador),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.third,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo de la app centrado
                        const SizedBox(height: 5),
                        Column(
                          children: [
                            Image.asset(
                              AppImages.logoApp, // Ruta de tu imagen
                              height: 130, // Ajusta la altura según necesites
                              width: 200, // Ajusta el ancho según necesites
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        GestureDetector(
                          onTap: _onConcesionarioTap,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              AppImages.concesionario,
                              height: 150,
                              //width: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        GestureDetector(
                          onTap: _onChoferTap,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              AppImages.chofer,
                              height: 150,
                              //width: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        GestureDetector(
                          onTap: _onChecadorTap,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              AppImages.checador,
                              height: 150,
                              //width: 0,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Políticas de Privacidad SIN CARD
                        GestureDetector(
                          onTap: _openPrivacyPolicy,
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.privacy_tip_outlined,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Políticas de Privacidad',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Toca aquí para leer nuestras políticas de privacidad',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mostrar el CircularProgressIndicator si está cargando
          ],
        ),
      ),
    );
  }

  @override
  Widget buildx(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color.fromARGB(255, 0, 156, 151),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo de la app centrado
            const SizedBox(height: 5),
            Column(
              children: [
                Image.asset(
                  AppImages.logoApp, // Ruta de tu imagen
                  height: 120, // Ajusta la altura según necesites
                  width: 120, // Ajusta el ancho según necesites
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 5),
                const Text(
                  'RUTAS TRACKING', // Cambia por el nombre de tu app
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Card Concesionario con onTap
            GestureDetector(
              onTap: _onConcesionarioTap,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/image/concesionario.png', // Ruta de tu imagen para concesionario
                        height: 60,
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'CONCESIONARIO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card Chofer con onTap
            GestureDetector(
              onTap: _onChoferTap,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/image/chofer.png', // Ruta de tu imagen para chofer
                        height: 60,
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'CHOFER',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _onChecadorTap,
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/image/checador.png', // Ruta de tu imagen para chofer
                        height: 60,
                        width: 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'CHOFER',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Políticas de Privacidad SIN CARD
            GestureDetector(
              onTap: _openPrivacyPolicy,
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Políticas de Privacidad',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Toca aquí para leer nuestras políticas de privacidad',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
