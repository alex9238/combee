import 'dart:io';

import 'package:combeetracking/views/home/components/hex_button.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:combeetracking/views/auth/login_page.dart';
import 'package:combeetracking/views/configuration/configuration_page.dart';
import 'package:combeetracking/views/tracking/tracking_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /*BannerAd? _bannerAd;
  bool _isLoaded = false;*/

  @override
  void initState() {
    super.initState();
    //_loadBanner();
    _check();
  }

  // -------------------------------
  // BANNER
  // -------------------------------
  /*Future<void> _loadBanner() async {
    final width =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .physicalSize
            .width /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          width.toInt(),
        );

    if (size == null) return;

    late final BannerAd banner;

    banner = BannerAd(
      adUnitId: Platform.isAndroid
          ? "ca-app-pub-3940256099942544/6300978111"
          : "ca-app-pub-3940256099942544/2934735716",
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print("✅ Banner adaptativo cargado");
          setState(() {
            _bannerAd = banner;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print("❌ Error Banner: $error");
          ad.dispose();
        },
      ),
    );

    await banner.load();
  }*/

  _check() async {
    final prefs = await SharedPreferences.getInstance();

    // Comprobamos si la clave existe
    final exists = await prefs.containsKey("isTracking");

    if (exists) {
      final value = await prefs.getString(
        "isTracking",
      ); // o getString, según cómo la guardaste
      print("✅ 'isTracking' existe. Valor: $value");

      if (value == "true") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackingPage()),
        );

        return;
      }
    } else {
      print("⚠️ 'isTracking' no existe en SharedPreferences.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.greyTitle),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString("isLogin", "false");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
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
                'Rastrea tu unidad',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de bienvenida
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Image.asset(
                      AppImages.logoApp, // Ruta de tu imagen
                      height: 120, // Ajusta la altura según necesites
                      //width: 120, // Ajusta el ancho según necesites
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Botón para ir al tutorial
            /*ElevatedButton.icon(
              onPressed: () {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TutorialPage()),
                );*/
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.school, color: Colors.white),
              label: const Text(
                'VER TUTORIAL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),*/

            const SizedBox(height: 15),
            HexButton(
              text: 'INICIAR RASTREO',
              textColor: Colors.white,
              heightButton: 55,
              widthButton: double.infinity,
              colors: const [Colors.green, Colors.green],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ConfigurationPage(view: AppUser.chofer),
                  ),
                );
              },
            ),

            // Botón para ir al rastreo
            /*ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ConfigurationPage(view: AppUser.chofer),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'INICIAR RASTREO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),*/

            const SizedBox(height: 20),

            // Información de características
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Características:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FeatureItem(icon: Icons.update, text: 'Tiempo Real'),
                        /*FeatureItem(
                          icon: Icons.picture_in_picture,
                          text: 'Overlay',
                        ),*/
                        FeatureItem(
                          icon: Icons.battery_charging_full,
                          text: 'Optimizado',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            /*const SizedBox(height: 20),
            if (_isLoaded)
              Container(
                color: Colors.black12,
                height: _bannerAd!.size.height.toDouble(),
                width: MediaQuery.of(context).size.width,
                child: AdWidget(ad: _bannerAd!),
              ),*/
          ],
        ),
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.greyTitle, size: 30),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
