import 'package:flutter/material.dart';

const kBg = Color(0xFF0B0B0F);
const kInk = Color(0xFFF4F4F6);
const kMuted = Color(0xFF8A8A96);
const kAccent = Color(0xFF7C5CFF);
const kAccent2 = Color(0xFF34D1BF);
const kAccent3 = Color(0xFFFF6B9D);
const kCard = Color(0xFF16161D);

ThemeData buildTheme({String? fontFamily}) => ThemeData(
  brightness: Brightness.dark,
  fontFamily: fontFamily,
  scaffoldBackgroundColor: kBg,
  colorScheme: const ColorScheme.dark(
    primary: kAccent,
    secondary: kAccent2,
    surface: kCard,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 44,
      height: 1.05,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      color: kInk,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: kInk,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: kMuted),
    labelSmall: TextStyle(
      fontSize: 11,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      color: kAccent2,
    ),
  ),
  useMaterial3: true,
);

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall);
}
