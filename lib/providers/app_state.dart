import 'package:flutter/foundation.dart';

/// Estado compartilhado simples: avisa as telas quando os dados do banco mudam,
/// para que listas, painel e relatórios se atualizem sozinhos.
class AppState extends ChangeNotifier {
  void dadosAlterados() => notifyListeners();
}
