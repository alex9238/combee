import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final Color textColor;
  final double widthButton;
  final double heightButton;
  final VoidCallback onTap;

  const RoundedButton({
    super.key,
    required this.text,
    required this.textColor,
    required this.colors,
    required this.widthButton,
    required this.heightButton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: heightButton,
        width: widthButton,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18), // 🔥 Bordes redondeados
          border: Border.all(color: Colors.black, width: 2), // 🔥 Borde negro
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
