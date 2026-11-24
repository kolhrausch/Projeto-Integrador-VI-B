import 'package:flutter/material.dart';

/// Gráfico de barras simples (sem bibliotecas externas).
class GraficoBarras extends StatelessWidget {
  const GraficoBarras({
    super.key,
    required this.valores,
    required this.rotulos,
    this.altura = 120,
  });

  final List<int> valores;
  final List<String> rotulos;
  final double altura;

  @override
  Widget build(BuildContext context) {
    var maior = 0;
    for (final v in valores) {
      if (v > maior) {
        maior = v;
      }
    }
    final cor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: altura + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < valores.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maior == 0
                          ? 2.0
                          : (altura * valores[i] / maior).clamp(2.0, altura).toDouble(),
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rotulos[i], style: const TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfico de linha simples (sem bibliotecas externas).
class GraficoLinha extends StatelessWidget {
  const GraficoLinha({super.key, required this.valores, this.altura = 110});

  final List<int> valores;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinhaPainter(valores, Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _LinhaPainter extends CustomPainter {
  _LinhaPainter(this.valores, this.cor);

  final List<int> valores;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) {
      return;
    }
    var maior = 0;
    for (final v in valores) {
      if (v > maior) {
        maior = v;
      }
    }
    final escala = maior == 0 ? 1 : maior;
    const margem = 8.0;
    final largura = size.width - margem * 2;
    final altura = size.height - margem * 2;

    final linha = Paint()
      ..color = cor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final ponto = Paint()
      ..color = cor
      ..style = PaintingStyle.fill;

    final caminho = Path();
    final pontos = <Offset>[];
    for (var i = 0; i < valores.length; i++) {
      final x = valores.length == 1
          ? size.width / 2
          : margem + largura * i / (valores.length - 1);
      final y = margem + altura - altura * valores[i] / escala;
      pontos.add(Offset(x, y));
      if (i == 0) {
        caminho.moveTo(x, y);
      } else {
        caminho.lineTo(x, y);
      }
    }
    canvas.drawPath(caminho, linha);
    if (valores.length <= 31) {
      for (final p in pontos) {
        canvas.drawCircle(p, 3, ponto);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinhaPainter antigo) {
    return antigo.valores != valores || antigo.cor != cor;
  }
}
