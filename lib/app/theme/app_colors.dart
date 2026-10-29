import 'package:flutter/material.dart';

class AppColors {
  static const deepPurple = Color(0xFF2B1452);
  static const indigo = Color(0xFF3D1F7A);
  static const deepNavy = Color(0xFF0F0A1F);
  static const brightViolet = Color(0xFF7C4DFF);
  static const electricBlue = Color(0xFF4FC3F7);
  static const warmYellow = Color(0xFFFFD54F);
  static const coral = Color(0xFFFF6B8A);
  static const offWhite = Color(0xFFF7F4FF);
  static const cardDark = Color(0xFF1C1333);
  static const cardLight = Color(0xFFFFFFFF);
  static const civilian = Color(0xFF5C6BC0);
  static const imposter = Color(0xFFE53935);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
}

class AppTextStyles {
  static TextStyle display(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 40,
    fontWeight: FontWeight.w900,
    height: 1.05,
    color: c,
  );
  static TextStyle headline(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: c,
  );
  static TextStyle title(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: c,
  );
  static TextStyle body(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: c,
  );
  static TextStyle label(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: c,
  );
  static TextStyle secret(Color c) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.5,
    color: c,
  );
}
