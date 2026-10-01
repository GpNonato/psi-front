import 'package:flutter/material.dart';

import '../formatters.dart';
import '../theme.dart';
import 'icones.dart';

/// Forma de folha do logotipo e dos avatares: cantos arredondados, exceto o
/// inferior esquerdo.
class FormaFolha extends StatelessWidget {
  const FormaFolha({
    super.key,
    required this.tamanho,
    required this.cor,
    this.child,
  });

  final double tamanho;
  final Color cor;
  final Widget? child;

  static BorderRadius raio(double t) => BorderRadius.only(
        topLeft: Radius.circular(t * 0.5),
        topRight: Radius.circular(t * 0.5),
        bottomRight: Radius.circular(t * 0.5),
        bottomLeft: Radius.circular(t * 0.16),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cor, borderRadius: raio(tamanho)),
      child: child,
    );
  }
}

/// Cérebro desenhado em traço, visto de cima (dois hemisférios e giros).
class _PintorCerebro extends CustomPainter {
  const _PintorCerebro(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dx = (size.width - s) / 2;
    final dy = (size.height - s) / 2;
    Offset p(double x, double y) => Offset(dx + x * s, dy + y * s);
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path hemisferio(bool direito) {
      double x(double v) => direito ? 1 - v : v;
      final a = p(x(0.47), 0.15);
      final path = Path()..moveTo(a.dx, a.dy);
      void curva(
          double x1, double y1, double x2, double y2, double x3, double y3) {
        final c1 = p(x(x1), y1);
        final c2 = p(x(x2), y2);
        final fim = p(x(x3), y3);
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, fim.dx, fim.dy);
      }

      curva(0.36, 0.05, 0.17, 0.09, 0.16, 0.27);
      curva(0.03, 0.31, 0.03, 0.52, 0.12, 0.57);
      curva(0.05, 0.72, 0.17, 0.88, 0.31, 0.85);
      curva(0.37, 0.95, 0.46, 0.93, 0.47, 0.86);
      final base = p(x(0.47), 0.15);
      path.lineTo(base.dx, base.dy);
      return path;
    }

    Path giros(bool direito) {
      double x(double v) => direito ? 1 - v : v;
      final path = Path();
      void curva(double x0, double y0, double x1, double y1, double x2,
          double y2, double x3, double y3) {
        final a = p(x(x0), y0);
        final c1 = p(x(x1), y1);
        final c2 = p(x(x2), y2);
        final b = p(x(x3), y3);
        path
          ..moveTo(a.dx, a.dy)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
      }

      curva(0.17, 0.42, 0.25, 0.36, 0.3, 0.47, 0.39, 0.4);
      curva(0.22, 0.66, 0.28, 0.58, 0.35, 0.69, 0.41, 0.6);
      curva(0.29, 0.2, 0.31, 0.27, 0.36, 0.3, 0.42, 0.26);
      return path;
    }

    for (final direito in [false, true]) {
      canvas.drawPath(hemisferio(direito), traco);
      canvas.drawPath(giros(direito), traco);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorCerebro old) => old.cor != cor;
}

/// Só o cérebro do símbolo (ícones do app).
class CerebroPsiHub extends StatelessWidget {
  const CerebroPsiHub(
      {super.key, required this.tamanho, this.cor = Colors.white});

  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size.square(tamanho), painter: _PintorCerebro(cor));
  }
}

/// Símbolo do PsiHub: a folha com um cérebro dentro.
class MarcaPsiHub extends StatelessWidget {
  const MarcaPsiHub({super.key, this.tamanho = 28, this.cor = AppColors.oliva});

  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FormaFolha(
        tamanho: tamanho,
        cor: cor,
        child: CustomPaint(
          size: Size.square(tamanho * 0.64),
          painter: const _PintorCerebro(Colors.white),
        ),
      ),
    );
  }
}

class PsiHubLogo extends StatelessWidget {
  const PsiHubLogo({super.key, this.tamanho = 26, this.onTap});

  final double tamanho;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MarcaPsiHub(tamanho: tamanho * 1.08),
        SizedBox(width: tamanho * 0.4),
        Text(
          'PsiHub',
          style: AppText.serif(tamanho, cor: AppColors.olivaEscuro, altura: 1),
        ),
      ],
    );
    if (onTap == null) return Semantics(label: 'PsiHub', child: conteudo);
    return Semantics(
      button: true,
      label: 'PsiHub, ir para o início',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.all(4), child: conteudo),
      ),
    );
  }
}

enum TomAvatar { lavanda, salvia, oliva }

/// Avatar com as iniciais do nome, no formato de folha dos wireframes.
class AvatarIniciais extends StatelessWidget {
  const AvatarIniciais(
    this.nome, {
    super.key,
    this.tamanho = 40,
    this.tom = TomAvatar.lavanda,
  });

  final String nome;
  final double tamanho;
  final TomAvatar tom;

  @override
  Widget build(BuildContext context) {
    final (fundo, texto) = switch (tom) {
      TomAvatar.lavanda => (AppColors.lavandaClaro, AppColors.lavandaEscuro),
      TomAvatar.salvia => (AppColors.salvia, AppColors.olivaEscuro),
      TomAvatar.oliva => (AppColors.oliva, Colors.white),
    };
    return ExcludeSemantics(
      child: FormaFolha(
        tamanho: tamanho,
        cor: fundo,
        child: Text(
          iniciais(nome),
          style: TextStyle(
            fontSize: tamanho * 0.36,
            color: texto,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Espaço reservado para fotos, mapas e ilustrações (os wireframes não têm imagens).
class ImagemPlaceholder extends StatelessWidget {
  const ImagemPlaceholder({
    super.key,
    this.rotulo,
    this.altura,
    this.largura,
    this.raio = 18,
    this.icone = Icons.image_outlined,
    this.sobreposicoes = const [],
  });

  final String? rotulo;
  final double? altura;
  final double? largura;
  final double raio;
  final IconData icone;
  final List<Widget> sobreposicoes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: AppColors.placeholder,
        borderRadius: BorderRadius.circular(raio),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icone(icone, size: 18, color: const Color(0xFF6E6C60)),
                if (rotulo != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    rotulo!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textoFraco),
                  ),
                ],
              ],
            ),
          ),
          ...sobreposicoes,
        ],
      ),
    );
  }
}

/// Selo "Destaque" dos perfis patrocinados.
class SeloDestaque extends StatelessWidget {
  const SeloDestaque(
      {super.key, this.fundoBranco = true, this.rotulo = 'Destaque'});

  final bool fundoBranco;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: fundoBranco
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icone(Icons.star_rounded, size: 14, color: AppColors.estrela),
          const SizedBox(width: 4),
          Text(
            rotulo,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.lavandaEscuro),
          ),
        ],
      ),
    );
  }
}
