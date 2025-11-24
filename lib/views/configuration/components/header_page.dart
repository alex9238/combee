import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center, // Alineación centrada en el eje principal
      crossAxisAlignment: CrossAxisAlignment
          .center, // Alineación centrada en el eje transversal
      children: [
        // Ajuste de tamaño para la imagen
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.greca),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Image.asset(AppImages.logoGobiernoHumanista, height: 40),
            ],
          ),
        ),

        // Línea divisoria verde
        Container(height: 8, width: double.infinity, color: AppColors.primary),
      ],
    );
  }
}
