import 'package:flutter/material.dart';
import 'package:combee/views/checker/components/checker_select_form_page.dart';
import 'package:combee/views/configuration/configuration_page.dart';
import '../../core/constants/constants.dart';

class CheckerSelectPage extends StatefulWidget {
  const CheckerSelectPage({super.key});

  @override
  State<CheckerSelectPage> createState() => _CheckerSelectPageState();
}

class _CheckerSelectPageState extends State<CheckerSelectPage> {
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
          mainAxisSize: MainAxisSize.min, // evita que ocupe todo el ancho
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppImages.logoPantallaAppBar, // tu imagen PNG
              height: 30, // ajusta tamaño
            ),
            const SizedBox(width: 8), // espacio entre imagen y texto
            Flexible(
              child: Text(
                'Seleccionar Parada Checador',
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
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ConfigurationPage(view: AppUser.checador),
              ),
            );
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
                CheckerSelectFormPage(onLogin: setLoading, onChange: setChange),
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
