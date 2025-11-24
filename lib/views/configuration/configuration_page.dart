import 'package:flutter/material.dart';
import 'package:combee/core/constants/app_users.dart';
import 'package:combee/views/auth/login_page.dart';
import 'package:combee/views/configuration/components/configuration_page_form.dart';
import 'package:combee/views/configuration/components/header_page.dart';
import 'package:combee/views/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

class ConfigurationPage extends StatefulWidget {
  final String view;
  const ConfigurationPage({super.key, required this.view});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  bool isLoading = false;

  bool isChange = false;

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  void setChange(bool value) {
    setState(() {
      isChange = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppImages.logoPantallaAppBar, height: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Configuración ${widget.view}',
                overflow: TextOverflow.ellipsis, // evita desbordamiento
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.greyTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true, // centra correctamente
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            if (widget.view == AppUser.chofer) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            } else if (widget.view == AppUser.concesionario) {
              Navigator.pop(context, isChange);
            } else {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString("isLogin", "false");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            }
          },
        ),
      ),
      body: Stack(
        children: [
          /*Positioned.fill(
            child: Image.asset(AppImages.fondo, fit: BoxFit.cover),
          ),*/
          SingleChildScrollView(
            child: Column(
              children: [
                //const PageHeader(),

                // Logo Data Chiapas
                ConfigurationPageForm(
                  onLogin: setLoading,
                  view: widget.view,
                  onChange: setChange,
                ),
                const SizedBox(height: 15),
                // Información de contacto
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        "POWERED BY COMBEE",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5), // Fondo oscuro
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
