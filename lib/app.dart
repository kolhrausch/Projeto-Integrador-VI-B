import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'widgets/common.dart';

class VitrineApp extends StatelessWidget {
  const VitrineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitrine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kCorPrincipal),
        appBarTheme: const AppBarTheme(
          backgroundColor: kCorPrincipal,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
