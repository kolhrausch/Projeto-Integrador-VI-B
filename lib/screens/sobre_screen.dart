import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// Tela "Sobre o app" com o nome completo de todos os integrantes (item 7 da Etapa 1).
class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  static const String versao = '1.0.0';

  static const List<String> integrantes = [
    'Erick Alves Kolhrausch',
    'Natanael Almeida de Jesus',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: kCorPrincipal,
              child: Icon(Icons.storefront, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Vitrine', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text('Versão $versao', style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Projeto Integrador VI-B')),
          Center(
            child: Text(
              'Análise e Desenvolvimento de Sistemas',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SectionTitle('Integrantes do grupo'),
          for (final nome in integrantes)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person_outline, color: kCorPrincipal),
                ),
                title: Text(nome),
              ),
            ),
        ],
      ),
    );
  }
}
