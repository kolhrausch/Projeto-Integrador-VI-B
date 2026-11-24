import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

/// Cor principal do app (cinza-azulado dos wireframes).
const Color kCorPrincipal = Color(0xFF374151);

/// Faz a tela recarregar seus dados sempre que o [AppState] avisa que o banco mudou.
mixin DataReloadMixin<T extends StatefulWidget> on State<T> {
  late final AppState _appState;

  /// Busca os dados no banco e atualiza a tela (chame setState ao final).
  Future<void> carregar();

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _appState.addListener(_aoMudarDados);
    carregar();
  }

  void _aoMudarDados() {
    if (mounted) {
      carregar();
    }
  }

  @override
  void dispose() {
    _appState.removeListener(_aoMudarDados);
    super.dispose();
  }
}

void mostrarMensagem(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

/// Pergunta de onde vem a foto (galeria ou câmera).
Future<ImageSource?> escolherOrigemFoto(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
}

/// Pergunta por qual canal o catálogo será compartilhado (para a análise de divulgação).
Future<String?> escolherCanal(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Wrap(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Compartilhar catálogo via',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined),
            title: const Text('WhatsApp'),
            onTap: () => Navigator.pop(ctx, 'WHATSAPP'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Instagram'),
            onTap: () => Navigator.pop(ctx, 'INSTAGRAM'),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Outros'),
            onTap: () => Navigator.pop(ctx, 'OUTRO'),
          ),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rotulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.icone, required this.mensagem});

  final IconData icone;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pequena etiqueta arredondada (status, perfil, classe ABC...).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 11)),
    );
  }
}

/// Linha de filtros (chips) com seleção única.
class FiltroChips extends StatelessWidget {
  const FiltroChips({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final List<String> opcoes;
  final int selecionado;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: opcoes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, indice) {
          return ChoiceChip(
            label: Text(opcoes[indice]),
            selected: indice == selecionado,
            onSelected: (_) => aoSelecionar(indice),
          );
        },
      ),
    );
  }
}
