import 'package:flutter/material.dart';

class HexButton extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final Color textColor;
  final double widthButton;
  final double heightButton;

  final VoidCallback onTap;

  const HexButton({
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
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          padding: const EdgeInsets.all(2), // grosor del borde
          decoration: BoxDecoration(
            color: Colors.black, // color del borde
          ),
          child: ClipPath(
            clipper: _HexClipper(),
            child: Container(
              height: heightButton,
              width: widthButton,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double cut = 20; // Tamaño del triángulo lateral

    path.moveTo(cut, 0);
    path.lineTo(size.width - cut, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(cut, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
