// Ilustrações desenhadas pelo próprio app (sem arquivos de imagem): retratos dos
// psicólogos, ambientes do consultório para a galeria, a ilustração da página
// inicial e o mapa. Ocupam os espaços de imagem dos wireframes.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import 'marca.dart';

enum _Tipo { retrato, ambiente, encontro, mapa, clinica }

int _hash(String s) {
  var h = 17;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

Color _escurecer(Color c, double t) => Color.lerp(c, Colors.black, t)!;
Color _clarear(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Paint _tinta(Color c) => Paint()..color = c;

/// Imagem ilustrada com cantos arredondados e sobreposições (selos, botões).
class Ilustracao extends StatelessWidget {
  const Ilustracao.retrato(
    String semente, {
    super.key,
    this.feminino,
    this.altura,
    this.largura,
    this.raio = 18,
    this.sobreposicoes = const [],
    this.descricao,
  })  : _tipo = _Tipo.retrato,
        _semente = semente,
        _variante = 0;

  const Ilustracao.ambiente(
    int variante, {
    super.key,
    this.altura,
    this.largura,
    this.raio = 18,
    this.sobreposicoes = const [],
    this.descricao,
  })  : _tipo = _Tipo.ambiente,
        _semente = '',
        _variante = variante,
        feminino = null;

  const Ilustracao.encontro({
    super.key,
    this.altura,
    this.largura,
    this.raio = 24,
    this.sobreposicoes = const [],
    this.descricao,
  })  : _tipo = _Tipo.encontro,
        _semente = '',
        _variante = 0,
        feminino = null;

  const Ilustracao.clinica(
    String semente, {
    super.key,
    this.altura,
    this.largura,
    this.raio = 18,
    this.sobreposicoes = const [],
    this.descricao,
  })  : _tipo = _Tipo.clinica,
        _semente = semente,
        _variante = 0,
        feminino = null;

  const Ilustracao.mapa({
    super.key,
    this.altura,
    this.largura,
    this.raio = 16,
    this.sobreposicoes = const [],
    this.descricao,
  })  : _tipo = _Tipo.mapa,
        _semente = '',
        _variante = 0,
        feminino = null;

  final _Tipo _tipo;
  final String _semente;
  final int _variante;
  final bool? feminino;
  final double? altura;
  final double? largura;
  final double raio;
  final List<Widget> sobreposicoes;

  /// Texto para leitores de tela.
  final String? descricao;

  CustomPainter _pintor() => switch (_tipo) {
        _Tipo.retrato => _PintorRetrato(_semente, feminino),
        _Tipo.ambiente => _PintorAmbiente(_variante),
        _Tipo.encontro => const _PintorEncontro(),
        _Tipo.mapa => const _PintorMapa(),
        _Tipo.clinica => _PintorClinica(_semente),
      };

  @override
  Widget build(BuildContext context) {
    final rotulo = descricao ??
        switch (_tipo) {
          _Tipo.retrato => 'Foto de perfil',
          _Tipo.ambiente => 'Foto do consultório',
          _Tipo.encontro => 'Ilustração de duas pessoas conversando',
          _Tipo.mapa => 'Mapa com a localização',
          _Tipo.clinica => 'Fachada da clínica',
        };
    return SizedBox(
      width: largura,
      height: altura,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              image: true,
              label: rotulo,
              child: RepaintBoundary(child: CustomPaint(painter: _pintor())),
            ),
            ...sobreposicoes,
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ elementos

void _planta(Canvas c, Offset base, double altura,
    {Color vaso = const Color(0xFFC98B6B), int folhas = 7}) {
  final potW = altura * 0.34;
  final potH = altura * 0.28;
  const verdes = [Color(0xFF5E7F4B), Color(0xFF7A9A5E), Color(0xFF4E6B3E)];
  for (var i = 0; i < folhas; i++) {
    final t = folhas == 1 ? 0.5 : i / (folhas - 1);
    final ang = -math.pi * 0.88 + t * math.pi * 0.76;
    final comp = altura * (0.42 + 0.3 * math.sin(t * math.pi));
    final centro = Offset(
      base.dx + math.cos(ang) * comp * 0.5,
      base.dy - potH + math.sin(ang) * comp * 0.5,
    );
    c.save();
    c.translate(centro.dx, centro.dy);
    c.rotate(ang + math.pi / 2);
    c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: comp * 0.36, height: comp),
        _tinta(verdes[i % 3]));
    c.restore();
  }
  final pot = Path()
    ..moveTo(base.dx - potW / 2, base.dy - potH)
    ..lineTo(base.dx + potW / 2, base.dy - potH)
    ..lineTo(base.dx + potW * 0.36, base.dy)
    ..lineTo(base.dx - potW * 0.36, base.dy)
    ..close();
  c.drawPath(pot, _tinta(vaso));
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - potW * 0.56, base.dy - potH * 1.12, potW * 1.12,
          potH * 0.2),
      Radius.circular(potH * 0.06),
    ),
    _tinta(_escurecer(vaso, 0.1)),
  );
}

void _janela(Canvas c, Rect r, {bool paisagem = false, bool cortinas = true}) {
  final m = r.width * 0.05;
  c.drawRRect(RRect.fromRectAndRadius(r.inflate(m), Radius.circular(m)),
      _tinta(Colors.white));
  c.drawRect(
    r,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC9DDE9), Color(0xFFEAF2F5)],
      ).createShader(r),
  );
  if (paisagem) {
    c.save();
    c.clipRect(r);
    c.drawCircle(Offset(r.left + r.width * 0.72, r.top + r.height * 0.3),
        r.height * 0.1, _tinta(const Color(0xFFF7E6B5)));
    final morro1 = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + r.height * 0.7)
      ..quadraticBezierTo(r.left + r.width * 0.3, r.top + r.height * 0.48,
          r.left + r.width * 0.62, r.top + r.height * 0.72)
      ..lineTo(r.right, r.top + r.height * 0.66)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(morro1, _tinta(const Color(0xFFA9C08E)));
    final morro2 = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + r.height * 0.84)
      ..quadraticBezierTo(r.left + r.width * 0.55, r.top + r.height * 0.66,
          r.right, r.top + r.height * 0.82)
      ..lineTo(r.right, r.bottom)
      ..close();
    c.drawPath(morro2, _tinta(const Color(0xFF7F9C68)));
    c.restore();
  }
  final barra = Paint()
    ..color = Colors.white
    ..strokeWidth = r.width * 0.035;
  c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), barra);
  c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), barra);
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(r.left - r.width * 0.12, r.bottom + m,
          r.right + r.width * 0.12, r.bottom + m + r.height * 0.05),
      Radius.circular(r.height * 0.02),
    ),
    _tinta(const Color(0xFFF8F5EE)),
  );
  if (cortinas) {
    final cortina = _tinta(const Color(0xFFDCD5EE));
    for (final lado in [-1.0, 1.0]) {
      final x = lado < 0 ? r.left - m * 2.4 : r.right + m * 2.4 - r.width * 0.2;
      final forma = Path()
        ..moveTo(x, r.top - m * 2)
        ..lineTo(x + r.width * 0.2, r.top - m * 2)
        ..quadraticBezierTo(x + r.width * (lado < 0 ? 0.26 : 0.02), r.center.dy,
            x + r.width * (lado < 0 ? 0.12 : 0.1), r.bottom + m * 3)
        ..lineTo(x + r.width * (lado < 0 ? 0.0 : 0.2), r.bottom + m * 3)
        ..close();
      c.drawPath(forma, cortina);
    }
    c.drawLine(
      Offset(r.left - m * 3, r.top - m * 2),
      Offset(r.right + m * 3, r.top - m * 2),
      Paint()
        ..color = const Color(0xFF8A7560)
        ..strokeWidth = m * 0.7
        ..strokeCap = StrokeCap.round,
    );
  }
}

void _quadro(Canvas c, Rect r, Color sol, Color morro) {
  c.drawRect(r.inflate(r.width * 0.06), _tinta(const Color(0xFF9A7B58)));
  c.drawRect(r, _tinta(const Color(0xFFF7F2E7)));
  c.drawCircle(Offset(r.left + r.width * 0.66, r.top + r.height * 0.38),
      r.height * 0.18, _tinta(sol));
  final p = Path()
    ..moveTo(r.left, r.bottom)
    ..quadraticBezierTo(r.left + r.width * 0.32, r.top + r.height * 0.42,
        r.left + r.width * 0.66, r.bottom - r.height * 0.12)
    ..quadraticBezierTo(r.left + r.width * 0.84, r.bottom - r.height * 0.24,
        r.right, r.bottom - r.height * 0.06)
    ..lineTo(r.right, r.bottom)
    ..close();
  c.drawPath(p, _tinta(morro));
}

void _poltrona(Canvas c, Offset base, double l, Color cor) {
  final escuro = _escurecer(cor, 0.14);
  final perna = Paint()
    ..color = const Color(0xFF6B5641)
    ..strokeWidth = l * 0.05
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(base.dx - l * 0.34, base.dy - l * 0.14),
      Offset(base.dx - l * 0.4, base.dy), perna);
  c.drawLine(Offset(base.dx + l * 0.34, base.dy - l * 0.14),
      Offset(base.dx + l * 0.4, base.dy), perna);
  c.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(base.dx - l * 0.4, base.dy - l * 1.05, l * 0.8, l * 0.76),
      topLeft: Radius.circular(l * 0.3),
      topRight: Radius.circular(l * 0.3),
      bottomLeft: Radius.circular(l * 0.06),
      bottomRight: Radius.circular(l * 0.06),
    ),
    _tinta(escuro),
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(
            base.dx - l * 0.44, base.dy - l * 0.42, l * 0.88, l * 0.3),
        Radius.circular(l * 0.1)),
    _tinta(cor),
  );
  for (final lado in [-1.0, 1.0]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(base.dx + lado * l * 0.44, base.dy - l * 0.4),
            width: l * 0.17,
            height: l * 0.48),
        Radius.circular(l * 0.085),
      ),
      _tinta(_clarear(cor, 0.06)),
    );
  }
}

void _sofa(Canvas c, Offset base, double l, Color cor) {
  final escuro = _escurecer(cor, 0.12);
  final perna = Paint()
    ..color = const Color(0xFF6B5641)
    ..strokeWidth = l * 0.025
    ..strokeCap = StrokeCap.round;
  for (final x in [-0.42, 0.42]) {
    c.drawLine(Offset(base.dx + l * x, base.dy - l * 0.06),
        Offset(base.dx + l * x * 1.02, base.dy), perna);
  }
  c.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(
            base.dx - l * 0.46, base.dy - l * 0.42, l * 0.92, l * 0.3),
        Radius.circular(l * 0.08)),
    _tinta(escuro),
  );
  for (final x in [-0.22, 0.22]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(base.dx + l * x, base.dy - l * 0.29),
            width: l * 0.42,
            height: l * 0.2),
        Radius.circular(l * 0.06),
      ),
      _tinta(_clarear(cor, 0.12)),
    );
  }
  c.drawRRect(
    RRect.fromRectAndRadius(
        Rect.fromLTWH(
            base.dx - l * 0.47, base.dy - l * 0.18, l * 0.94, l * 0.13),
        Radius.circular(l * 0.05)),
    _tinta(cor),
  );
  for (final lado in [-1.0, 1.0]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(base.dx + lado * l * 0.48, base.dy - l * 0.2),
            width: l * 0.1,
            height: l * 0.26),
        Radius.circular(l * 0.05),
      ),
      _tinta(cor),
    );
  }
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(base.dx - l * 0.3, base.dy - l * 0.3),
          width: l * 0.13,
          height: l * 0.12),
      Radius.circular(l * 0.03),
    ),
    _tinta(const Color(0xFFE3E5D1)),
  );
}

void _luminaria(Canvas c, Offset base, double altura, Color cupula) {
  final poste = Paint()
    ..color = const Color(0xFF3F3A33)
    ..strokeWidth = altura * 0.018
    ..strokeCap = StrokeCap.round;
  final topo = base.dy - altura;
  c.drawCircle(Offset(base.dx, topo + altura * 0.26), altura * 0.24,
      _tinta(const Color(0x33FFF1C0)));
  c.drawLine(base, Offset(base.dx, topo + altura * 0.18), poste);
  c.drawOval(
      Rect.fromCenter(
          center: base, width: altura * 0.2, height: altura * 0.035),
      _tinta(const Color(0xFF3F3A33)));
  final cup = Path()
    ..moveTo(base.dx - altura * 0.08, topo)
    ..lineTo(base.dx + altura * 0.08, topo)
    ..lineTo(base.dx + altura * 0.14, topo + altura * 0.2)
    ..lineTo(base.dx - altura * 0.14, topo + altura * 0.2)
    ..close();
  c.drawPath(cup, _tinta(cupula));
}

void _estante(Canvas c, Rect r) {
  final madeira = _tinta(const Color(0xFFB08A63));
  c.drawRect(Rect.fromLTWH(r.left, r.top, r.width * 0.05, r.height), madeira);
  c.drawRect(
      Rect.fromLTWH(r.right - r.width * 0.05, r.top, r.width * 0.05, r.height),
      madeira);
  const cores = [
    Color(0xFF6A5AA6),
    Color(0xFF4F5A2E),
    Color(0xFFB5654A),
    Color(0xFFC49A3C),
    Color(0xFF2F4F6B),
    Color(0xFF8C5A7A),
    Color(0xFF3A7A68),
    Color(0xFFD6CFBF),
  ];
  const n = 3;
  var k = 0;
  for (var i = 0; i < n; i++) {
    final yBase = r.top + r.height * (i + 1) / n - r.height * 0.015;
    final alturaNivel = r.height / n;
    var x = r.left + r.width * 0.08;
    while (x < r.right - r.width * 0.16) {
      if (i == 1 && k % 6 == 4) {
        _planta(c, Offset(x + r.width * 0.07, yBase), alturaNivel * 0.72,
            folhas: 5);
        x += r.width * 0.16;
        k++;
        continue;
      }
      final bw = r.width * (0.05 + 0.025 * (k % 3));
      final bh = alturaNivel * (0.5 + 0.1 * ((k * 7) % 4));
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, yBase - bh, bw, bh), Radius.circular(bw * 0.12)),
        _tinta(cores[(k * 5) % cores.length]),
      );
      x += bw + r.width * 0.012;
      k++;
    }
  }
  for (var i = 0; i <= n; i++) {
    final y = r.top + r.height * i / n;
    c.drawRect(
        Rect.fromLTWH(r.left, y - r.height * 0.015, r.width, r.height * 0.03),
        madeira);
  }
}

void _notebook(Canvas c, Offset base, double l) {
  final tela = Rect.fromCenter(
      center: Offset(base.dx, base.dy - l * 0.36),
      width: l * 0.86,
      height: l * 0.56);
  c.drawRRect(
      RRect.fromRectAndRadius(
          tela.inflate(l * 0.03), Radius.circular(l * 0.04)),
      _tinta(const Color(0xFF3A3A38)));
  c.drawRect(tela, _tinta(const Color(0xFFDCE6EA)));
  final t1 = Rect.fromLTWH(tela.left + tela.width * 0.05,
      tela.top + tela.height * 0.1, tela.width * 0.58, tela.height * 0.8);
  c.drawRect(t1, _tinta(const Color(0xFFE7E3F4)));
  c.drawCircle(Offset(t1.center.dx, t1.top + t1.height * 0.42),
      t1.height * 0.16, _tinta(const Color(0xFFE3B08C)));
  c.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(t1.center.dx - t1.width * 0.25, t1.top + t1.height * 0.64,
          t1.width * 0.5, t1.height * 0.36),
      topLeft: Radius.circular(t1.width * 0.2),
      topRight: Radius.circular(t1.width * 0.2),
    ),
    _tinta(const Color(0xFF6A5AA6)),
  );
  final t2 = Rect.fromLTWH(tela.left + tela.width * 0.67,
      tela.top + tela.height * 0.1, tela.width * 0.28, tela.height * 0.38);
  c.drawRect(t2, _tinta(const Color(0xFFE3E5D1)));
  c.drawCircle(Offset(t2.center.dx, t2.top + t2.height * 0.45), t2.height * 0.2,
      _tinta(const Color(0xFFC98D67)));
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(base.dx, base.dy - l * 0.03),
          width: l * 1.06,
          height: l * 0.06),
      Radius.circular(l * 0.03),
    ),
    _tinta(const Color(0xFF55544F)),
  );
}

void _espelho(Canvas c, Offset centro, double r) {
  c.drawCircle(centro, r * 1.08, _tinta(const Color(0xFFC9A45C)));
  c.drawCircle(
    centro,
    r,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F7F8), Color(0xFFD9E3E7)],
      ).createShader(Rect.fromCircle(center: centro, radius: r)),
  );
  final brilho = Paint()
    ..color = Colors.white
    ..strokeWidth = r * 0.06
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(centro.dx - r * 0.45, centro.dy - r * 0.1),
      Offset(centro.dx - r * 0.1, centro.dy - r * 0.45), brilho);
}

// ------------------------------------------------------------------ retrato

class _PintorRetrato extends CustomPainter {
  _PintorRetrato(this.semente, this.feminino, {this.rosto = false});

  final String semente;
  final bool? feminino;

  /// Enquadramento fechado no rosto (avatares).
  final bool rosto;

  static const _fundos = [
    Color(0xFFE3E5D1),
    Color(0xFFE7E3F4),
    Color(0xFFF1E4D6),
    Color(0xFFDDE9E1),
    Color(0xFFEDE6D8),
    Color(0xFFE2E8EE),
  ];
  static const _peles = [
    Color(0xFFF2CDB0),
    Color(0xFFE3B08C),
    Color(0xFFC98D67),
    Color(0xFF9A6446),
    Color(0xFF6E4431),
    Color(0xFFF5D9C3),
  ];
  static const _cabelos = [
    Color(0xFF2A1C14),
    Color(0xFF4A3022),
    Color(0xFF6E4A2E),
    Color(0xFF1C1B1A),
    Color(0xFF8C5B34),
    Color(0xFFB08A5B),
    Color(0xFF55504A),
  ];
  static const _roupas = [
    Color(0xFF4F5A2E),
    Color(0xFF6A5AA6),
    Color(0xFFB5654A),
    Color(0xFF2F4F6B),
    Color(0xFFC49A3C),
    Color(0xFF3A7A68),
    Color(0xFF8C5A7A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final r = _hash(semente);
    int escolha(int n, int k) => (r ~/ k) % n;
    final fundo = _fundos[escolha(_fundos.length, 1)];
    final pele = _peles[escolha(_peles.length, 7)];
    var cabelo = _cabelos[escolha(_cabelos.length, 11)];
    // Cabelo sempre contrastando com a pele, para o rosto não sumir.
    if ((cabelo.computeLuminance() - pele.computeLuminance()).abs() < 0.12) {
      cabelo = pele.computeLuminance() > 0.3
          ? const Color(0xFF2A1C14)
          : const Color(0xFF14100D);
    }
    final roupa = _roupas[escolha(_roupas.length, 13)];
    final fem = feminino ?? r.isEven;
    final estilo = fem ? escolha(3, 17) : escolha(4, 17);
    final oculos = escolha(3, 19) == 0;
    final barba = !fem && escolha(3, 23) != 0;

    canvas.drawRect(Offset.zero & size, _tinta(fundo));
    final s = rosto ? math.min(w, h) * 1.5 : math.min(w * 0.9, h * 1.02);
    final cx = w * 0.5;
    final b = rosto ? h + s * 0.2 : h;
    canvas.drawCircle(
        Offset(cx, b - s * 0.55), s * 0.45, _tinta(_clarear(fundo, 0.45)));
    if (!rosto && w / h > 1.35) {
      _planta(canvas, Offset(w * 0.13, b + s * 0.02), s * 0.62);
      _quadro(
        canvas,
        Rect.fromLTWH(w * 0.78, h * 0.16, s * 0.3, s * 0.24),
        _clarear(roupa, 0.45),
        _clarear(const Color(0xFF7F9C68), 0.2),
      );
    }

    final cy = b - s * 0.6;
    final rx = s * 0.145;
    final ry = s * 0.175;
    final pCabelo = _tinta(cabelo);
    final pPele = _tinta(pele);
    final pSombra = _tinta(_escurecer(pele, 0.1));
    final cabeca =
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);

    // Cabelo de trás.
    if (fem) {
      switch (estilo) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(
                  cx - rx * 1.3, cy - ry * 1.12, cx + rx * 1.3, cy + ry * 2.05),
              Radius.circular(rx * 1.1),
            ),
            pCabelo,
          );
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(cx - rx * 1.28, cy - ry * 1.12, cx + rx * 1.28,
                  cy + ry * 0.9),
              Radius.circular(rx * 0.9),
            ),
            pCabelo,
          );
        case 2:
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, cy - ry * 0.12),
                width: rx * 2.9,
                height: ry * 2.5),
            pCabelo,
          );
          for (var i = 0; i < 12; i++) {
            final a = i * math.pi / 6;
            canvas.drawCircle(
              Offset(cx + math.cos(a) * rx * 1.35,
                  cy - ry * 0.12 + math.sin(a) * ry * 1.18),
              rx * 0.42,
              pCabelo,
            );
          }
        default:
          canvas.drawCircle(Offset(cx, cy - ry * 1.14), rx * 0.5, pCabelo);
      }
    }

    // Orelhas, pescoço e tronco.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + lado * rx * 0.97, cy + ry * 0.1),
            width: rx * 0.36,
            height: ry * 0.42),
        pPele,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
            cx - s * 0.058, cy + ry * 0.55, cx + s * 0.058, b - s * 0.28),
        Radius.circular(s * 0.03),
      ),
      pSombra,
    );
    final tronco = Path()
      ..moveTo(cx - s * 0.4, b + 2)
      ..lineTo(cx - s * 0.4, b - s * 0.13)
      ..cubicTo(cx - s * 0.4, b - s * 0.25, cx - s * 0.31, b - s * 0.31,
          cx - s * 0.17, b - s * 0.325)
      ..lineTo(cx + s * 0.17, b - s * 0.325)
      ..cubicTo(cx + s * 0.31, b - s * 0.31, cx + s * 0.4, b - s * 0.25,
          cx + s * 0.4, b - s * 0.13)
      ..lineTo(cx + s * 0.4, b + 2)
      ..close();
    canvas.drawPath(tronco, _tinta(roupa));
    final decote = Path()
      ..moveTo(cx - s * 0.075, b - s * 0.326)
      ..lineTo(cx, b - s * 0.235)
      ..lineTo(cx + s * 0.075, b - s * 0.326)
      ..close();
    canvas.drawPath(decote, pSombra);
    final gola = Paint()
      ..color = _clarear(roupa, 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.014
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - s * 0.078, b - s * 0.328), Offset(cx, b - s * 0.232), gola);
    canvas.drawLine(
        Offset(cx + s * 0.078, b - s * 0.328), Offset(cx, b - s * 0.232), gola);

    // Cabeça e rosto.
    canvas.drawOval(cabeca, pPele);
    final bochecha = _tinta(Color.lerp(pele, const Color(0xFFE07A6A), 0.28)!);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + lado * rx * 0.56, cy + ry * 0.34),
            width: rx * 0.34,
            height: ry * 0.18),
        bochecha,
      );
    }
    if (barba) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, cy + ry * 0.18, w, h));
      canvas.drawOval(cabeca.inflate(s * 0.006), pCabelo);
      canvas.restore();
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + ry * 0.45),
            width: rx * 0.62,
            height: ry * 0.2),
        pPele,
      );
    }

    // Cabelo da frente.
    void tampa(double corte, {double inclinacao = 0, double folga = 1.07}) {
      canvas.save();
      final clip = Path()
        ..moveTo(cx - rx * 1.6, cy + corte * ry + inclinacao * ry)
        ..lineTo(cx + rx * 1.6, cy + corte * ry - inclinacao * ry)
        ..lineTo(cx + rx * 1.6, cy - ry * 3)
        ..lineTo(cx - rx * 1.6, cy - ry * 3)
        ..close();
      canvas.clipPath(clip);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy - ry * 0.02),
            width: rx * 2 * folga,
            height: ry * 2 * (folga - 0.01)),
        pCabelo,
      );
      canvas.restore();
    }

    if (fem) {
      final brinco = _tinta(const Color(0xFFC9A45C));
      for (final lado in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(cx + lado * rx * 1.0, cy + ry * 0.36),
          s * 0.016,
          brinco,
        );
      }
    }

    // Olhos, sobrancelhas e sorriso.
    final olho = _tinta(const Color(0xFF2B2320));
    final traco = Paint()
      ..color = cabelo
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.011
      ..strokeCap = StrokeCap.round;
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + lado * rx * 0.4, cy + ry * 0.08),
            width: s * 0.026,
            height: s * 0.032),
        olho,
      );
      canvas.drawLine(
        Offset(cx + lado * rx * 0.58, cy - ry * 0.1),
        Offset(cx + lado * rx * 0.24, cy - ry * 0.15),
        traco,
      );
    }
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy + ry * 0.36),
          width: rx * 0.52,
          height: ry * 0.26),
      0.15 * math.pi,
      0.7 * math.pi,
      false,
      Paint()
        ..color = _escurecer(pele, 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.011
        ..strokeCap = StrokeCap.round,
    );

    if (fem) {
      switch (estilo) {
        case 0:
          tampa(-0.5, inclinacao: 0.22);
        case 1:
          tampa(-0.36);
        case 2:
          tampa(-0.4);
          for (var i = -2; i <= 2; i++) {
            canvas.drawCircle(
                Offset(cx + i * rx * 0.44, cy - ry * 0.62), rx * 0.3, pCabelo);
          }
        default:
          tampa(-0.46, folga: 1.05);
      }
    } else {
      switch (estilo) {
        case 0:
          tampa(-0.42, inclinacao: 0.08);
        case 1:
          tampa(-0.44);
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + rx * 0.2, cy - ry * 0.92),
                width: rx * 1.5,
                height: ry * 0.6),
            pCabelo,
          );
        case 2:
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, 0, w, cy - ry * 0.28));
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, cy - ry * 0.42),
                width: rx * 2.36,
                height: ry * 1.46),
            pCabelo,
          );
          canvas.restore();
        default:
          tampa(-0.64, folga: 1.05);
      }
    }

    if (oculos) {
      final aro = Paint()
        ..color = const Color(0xFF2B2A28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012;
      for (final lado in [-1.0, 1.0]) {
        canvas.drawCircle(
            Offset(cx + lado * rx * 0.42, cy + ry * 0.08), rx * 0.27, aro);
      }
      canvas.drawLine(Offset(cx - rx * 0.15, cy + ry * 0.06),
          Offset(cx + rx * 0.15, cy + ry * 0.06), aro);
    }
  }

  @override
  bool shouldRepaint(covariant _PintorRetrato old) =>
      old.semente != semente || old.feminino != feminino || old.rosto != rosto;
}

// ------------------------------------------------------------------ ambientes

class _PintorAmbiente extends CustomPainter {
  const _PintorAmbiente(this.variante);

  final int variante;

  static const _paredes = [
    Color(0xFFEDE6D8),
    Color(0xFFE6E9DC),
    Color(0xFFEDE7F2),
    Color(0xFFF0E6DC),
    Color(0xFFE8EBE4),
    Color(0xFFE9E3D5),
  ];
  static const _pisos = [
    Color(0xFFD8C9AE),
    Color(0xFFCDBB9E),
    Color(0xFFD9D2C3),
    Color(0xFFD6C7AB),
    Color(0xFFCFC3AA),
    Color(0xFFD8CCB4),
  ];

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final v = variante % 6;
    final yPiso = h * 0.76;
    c.drawRect(Rect.fromLTWH(0, 0, w, yPiso), _tinta(_paredes[v]));
    c.drawRect(Rect.fromLTWH(0, yPiso, w, h - yPiso), _tinta(_pisos[v]));
    c.drawRect(Rect.fromLTWH(0, yPiso - h * 0.018, w, h * 0.018),
        _tinta(_escurecer(_paredes[v], 0.07)));
    final u = math.min(h, w * 0.8);
    double x(double f) => w * f;
    final chao = h * 0.92;

    switch (v) {
      case 0:
        _janela(c, Rect.fromLTWH(x(0.08), h * 0.12, u * 0.34, u * 0.4));
        _quadro(c, Rect.fromLTWH(x(0.6), h * 0.16, u * 0.26, u * 0.2),
            const Color(0xFFE7B98A), const Color(0xFF9DB083));
        c.drawOval(
            Rect.fromCenter(
                center: Offset(x(0.58), h * 0.9),
                width: u * 0.95,
                height: u * 0.14),
            _tinta(const Color(0xFFDCD5EE)));
        _poltrona(c, Offset(x(0.58), chao), u * 0.42, AppColors.oliva);
        _luminaria(c, Offset(x(0.84), chao), u * 0.66, const Color(0xFFF3E9D2));
        _planta(c, Offset(x(0.32), chao), u * 0.4);
      case 1:
        _estante(
            c,
            Rect.fromLTWH(
                x(0.07), h * 0.1, math.max(u * 0.46, w * 0.3), h * 0.64));
        c.drawOval(
            Rect.fromCenter(
                center: Offset(x(0.72), h * 0.9),
                width: u * 0.8,
                height: u * 0.12),
            _tinta(const Color(0xFFE3E5D1)));
        _poltrona(c, Offset(x(0.72), chao), u * 0.4, const Color(0xFFB5654A));
        _planta(c, Offset(x(0.92), chao), u * 0.44,
            vaso: const Color(0xFFEDE6D8));
      case 2:
        _espelho(c, Offset(x(0.5), h * 0.3), u * 0.15);
        _sofa(c, Offset(x(0.5), chao), math.min(u * 1.05, w * 0.62),
            const Color(0xFF8E7FC4));
        _planta(c, Offset(x(0.12), chao), u * 0.52);
        _planta(c, Offset(x(0.88), chao), u * 0.38,
            vaso: const Color(0xFF4F5A2E));
      case 3:
        _janela(c, Rect.fromLTWH(x(0.62), h * 0.12, u * 0.32, u * 0.38),
            paisagem: true, cortinas: false);
        final tampo = Rect.fromLTWH(
            x(0.1), h * 0.56, math.max(u * 0.72, w * 0.42), h * 0.035);
        final perna = Paint()
          ..color = const Color(0xFF8A6A4A)
          ..strokeWidth = u * 0.022;
        c.drawLine(Offset(tampo.left + u * 0.03, tampo.bottom),
            Offset(tampo.left + u * 0.03, chao), perna);
        c.drawLine(Offset(tampo.right - u * 0.03, tampo.bottom),
            Offset(tampo.right - u * 0.03, chao), perna);
        c.drawRRect(RRect.fromRectAndRadius(tampo, Radius.circular(u * 0.01)),
            _tinta(const Color(0xFFB08A63)));
        _notebook(c, Offset(tampo.center.dx, tampo.top), u * 0.34);
        _planta(c, Offset(tampo.left + u * 0.08, tampo.top), u * 0.2,
            folhas: 5);
        c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(tampo.right - u * 0.14, tampo.top - u * 0.1,
                  u * 0.07, u * 0.1),
              Radius.circular(u * 0.012)),
          _tinta(const Color(0xFFF7F4EC)),
        );
      case 4:
        _quadro(c, Rect.fromLTWH(x(0.28), h * 0.14, u * 0.32, u * 0.22),
            const Color(0xFFC6BDE8), const Color(0xFF7F9C68));
        _poltrona(c, Offset(x(0.3), chao), u * 0.36, const Color(0xFF7F9C68));
        _poltrona(c, Offset(x(0.52), chao), u * 0.36, AppColors.oliva);
        final mesa = Rect.fromCenter(
            center: Offset(x(0.74), h * 0.8),
            width: u * 0.28,
            height: u * 0.04);
        c.drawLine(
          Offset(mesa.center.dx, mesa.bottom),
          Offset(mesa.center.dx, chao),
          Paint()
            ..color = const Color(0xFF6B5641)
            ..strokeWidth = u * 0.025,
        );
        c.drawRRect(RRect.fromRectAndRadius(mesa, Radius.circular(u * 0.02)),
            _tinta(const Color(0xFFB08A63)));
        c.drawRect(
            Rect.fromLTWH(
                mesa.left + u * 0.04, mesa.top - u * 0.02, u * 0.1, u * 0.02),
            _tinta(const Color(0xFF6A5AA6)));
        _planta(c, Offset(x(0.9), chao), u * 0.62);
      default:
        _janela(c, Rect.fromLTWH(x(0.5) - u * 0.3, h * 0.08, u * 0.6, u * 0.5),
            paisagem: true);
        _planta(c, Offset(x(0.5) - u * 0.12, h * 0.08 + u * 0.535), u * 0.24,
            folhas: 6);
        _planta(c, Offset(x(0.5) + u * 0.14, h * 0.08 + u * 0.535), u * 0.18,
            vaso: const Color(0xFFEDE6D8), folhas: 5);
        c.drawOval(
            Rect.fromCenter(
                center: Offset(x(0.5), h * 0.9),
                width: u * 1.1,
                height: u * 0.12),
            _tinta(const Color(0xFFE3E5D1)));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorAmbiente old) => old.variante != variante;
}

// ------------------------------------------------------------------ encontro

class _PintorEncontro extends CustomPainter {
  const _PintorEncontro();

  void _pessoaSentada(Canvas c, Offset base, double l,
      {required Color roupa,
      required Color calca,
      required Color pele,
      required Color cabelo,
      bool coque = false}) {
    // Desenhada virada para a direita; a base é o chão sob a poltrona.
    _poltronaLateral(c, base, l,
        roupa == AppColors.lavanda ? AppColors.oliva : const Color(0xFF9D8FD0));
    final pCalca = _tinta(calca);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx - l * 0.2, base.dy - l * 0.64,
              base.dx + l * 0.42, base.dy - l * 0.47),
          Radius.circular(l * 0.08)),
      pCalca,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx + l * 0.28, base.dy - l * 0.62,
              base.dx + l * 0.43, base.dy - l * 0.04),
          Radius.circular(l * 0.07)),
      pCalca,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx + l * 0.3, base.dy - l * 0.08,
              base.dx + l * 0.58, base.dy),
          Radius.circular(l * 0.04)),
      _tinta(const Color(0xFF3A3632)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx - l * 0.3, base.dy - l * 1.22,
              base.dx + l * 0.06, base.dy - l * 0.5),
          Radius.circular(l * 0.16)),
      _tinta(roupa),
    );
    final braco = Paint()
      ..color = _escurecer(roupa, 0.12)
      ..strokeWidth = l * 0.13
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(base.dx - l * 0.1, base.dy - l * 1.02),
        Offset(base.dx + l * 0.12, base.dy - l * 0.68), braco);
    c.drawCircle(
        Offset(base.dx + l * 0.16, base.dy - l * 0.66), l * 0.06, _tinta(pele));
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx - l * 0.14, base.dy - l * 1.3,
              base.dx - l * 0.02, base.dy - l * 1.16),
          Radius.circular(l * 0.03)),
      _tinta(_escurecer(pele, 0.1)),
    );
    final cabeca = Rect.fromCenter(
        center: Offset(base.dx - l * 0.06, base.dy - l * 1.42),
        width: l * 0.3,
        height: l * 0.34);
    if (coque) {
      c.drawCircle(Offset(cabeca.left + l * 0.02, cabeca.top + l * 0.06),
          l * 0.08, _tinta(cabelo));
    }
    c.drawOval(cabeca, _tinta(pele));
    c.save();
    c.clipRect(Rect.fromLTRB(cabeca.left - l, cabeca.top - l, cabeca.right + l,
        cabeca.center.dy - l * 0.02));
    c.drawOval(cabeca.inflate(l * 0.015), _tinta(cabelo));
    c.restore();
    c.save();
    c.clipRect(Rect.fromLTRB(cabeca.left - l, cabeca.top - l,
        cabeca.center.dx - l * 0.02, cabeca.bottom - l * 0.08));
    c.drawOval(cabeca.inflate(l * 0.015), _tinta(cabelo));
    c.restore();
  }

  void _poltronaLateral(Canvas c, Offset base, double l, Color cor) {
    final perna = Paint()
      ..color = const Color(0xFF6B5641)
      ..strokeWidth = l * 0.045
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(base.dx - l * 0.36, base.dy - l * 0.2),
        Offset(base.dx - l * 0.42, base.dy), perna);
    c.drawLine(Offset(base.dx + l * 0.3, base.dy - l * 0.2),
        Offset(base.dx + l * 0.36, base.dy), perna);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              base.dx - l * 0.52, base.dy - l * 1.08, l * 0.24, l * 0.9),
          Radius.circular(l * 0.12)),
      _tinta(_escurecer(cor, 0.14)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              base.dx - l * 0.48, base.dy - l * 0.46, l * 0.9, l * 0.26),
          Radius.circular(l * 0.1)),
      _tinta(cor),
    );
  }

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    c.drawRect(Offset.zero & size, _tinta(const Color(0xFFEEF0E2)));
    final u = math.min(w, h);
    c.drawCircle(
        Offset(w * 0.74, h * 0.26), u * 0.2, _tinta(const Color(0xFFE2DCF3)));
    for (var i = 0; i < 5; i++) {
      c.save();
      c.translate(w * 0.06, h * 0.02);
      c.rotate(0.35 + i * 0.28);
      c.drawOval(Rect.fromLTWH(0, -u * 0.035, u * 0.34, u * 0.07),
          _tinta(const Color(0xFFD3DAC0)));
      c.restore();
    }
    final yPiso = h * 0.82;
    c.drawRect(
        Rect.fromLTWH(0, yPiso, w, h - yPiso), _tinta(const Color(0xFFE4DECD)));
    c.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, yPiso + (h - yPiso) * 0.45),
            width: w * 0.82,
            height: (h - yPiso) * 0.6),
        _tinta(const Color(0xFFDAD3EC)));
    final fio = Paint()
      ..color = const Color(0xFF6B6358)
      ..strokeWidth = u * 0.006;
    c.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.2), fio);
    c.drawCircle(
        Offset(w * 0.5, h * 0.25), u * 0.1, _tinta(const Color(0x40FFF1C0)));
    c.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.24),
            width: u * 0.16,
            height: u * 0.12),
        math.pi,
        math.pi,
        true,
        _tinta(const Color(0xFFC49A3C)));
    final l = u * 0.34;
    final chao = yPiso + (h - yPiso) * 0.4;
    _pessoaSentada(
      c,
      Offset(w * 0.28, chao),
      l,
      roupa: AppColors.lavanda,
      calca: const Color(0xFF3B4422),
      pele: const Color(0xFFE3B08C),
      cabelo: const Color(0xFF2A1C14),
      coque: true,
    );
    c.save();
    c.translate(w * 0.72, 0);
    c.scale(-1, 1);
    c.translate(-w * 0.72, 0);
    _pessoaSentada(
      c,
      Offset(w * 0.72, chao),
      l,
      roupa: const Color(0xFFB5654A),
      calca: const Color(0xFF2F4F6B),
      pele: const Color(0xFF9A6446),
      cabelo: const Color(0xFF1C1B1A),
    );
    c.restore();
    final mesa = Rect.fromCenter(
        center: Offset(w * 0.5, chao - l * 0.5),
        width: l * 0.5,
        height: l * 0.06);
    c.drawLine(
      Offset(mesa.center.dx, mesa.bottom),
      Offset(mesa.center.dx, chao),
      Paint()
        ..color = const Color(0xFF6B5641)
        ..strokeWidth = l * 0.04,
    );
    c.drawRRect(RRect.fromRectAndRadius(mesa, Radius.circular(l * 0.03)),
        _tinta(const Color(0xFFB08A63)));
    _planta(c, Offset(mesa.center.dx + l * 0.08, mesa.top), l * 0.34,
        folhas: 6);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              mesa.left + l * 0.04, mesa.top - l * 0.08, l * 0.08, l * 0.08),
          Radius.circular(l * 0.015)),
      _tinta(const Color(0xFFF7F4EC)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------ mapa

class _PintorMapa extends CustomPainter {
  const _PintorMapa();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final m = math.min(w, h);
    c.drawRect(Offset.zero & size, _tinta(const Color(0xFFEAE7DA)));
    c.save();
    c.translate(w / 2, h / 2);
    c.rotate(-0.3);
    final d = math.sqrt(w * w + h * h);
    final rua = Paint()
      ..color = Colors.white
      ..strokeWidth = m * 0.032;
    for (var x = -d; x <= d; x += d * 0.15) {
      c.drawLine(Offset(x, -d), Offset(x, d), rua);
    }
    for (var y = -d; y <= d; y += d * 0.13) {
      c.drawLine(Offset(-d, y), Offset(d, y), rua);
    }
    c.restore();
    final parque = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.6, w * 0.32, h * 0.34),
        Radius.circular(m * 0.06));
    c.drawRRect(parque, _tinta(const Color(0xFFD1DDB9)));
    final arvore = _tinta(const Color(0xFFB9CD9C));
    for (var i = 0; i < 9; i++) {
      c.drawCircle(
        Offset(parque.left + parque.width * (0.15 + 0.35 * (i % 3)),
            parque.top + parque.height * (0.22 + 0.28 * (i ~/ 3))),
        m * 0.03,
        arvore,
      );
    }
    final agua = Path()
      ..moveTo(w * 0.6, h)
      ..cubicTo(w * 0.68, h * 0.8, w * 0.88, h * 0.86, w, h * 0.68)
      ..lineTo(w, h)
      ..close();
    c.drawPath(agua, _tinta(const Color(0xFFC6DAE5)));
    final p1 = Offset(-w * 0.1, h * 0.22);
    final p2 = Offset(w * 1.1, h * 0.64);
    c.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFFE0D2AE)
          ..strokeWidth = m * 0.085);
    c.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFFF7EED3)
          ..strokeWidth = m * 0.066);
    final centro = Offset(w * 0.5, h * 0.4);
    final r = m * 0.085;
    c.drawOval(
      Rect.fromCenter(
          center: Offset(centro.dx, centro.dy + r * 1.95),
          width: r * 1.4,
          height: r * 0.42),
      _tinta(const Color(0x33000000)),
    );
    final pino = Path()
      ..moveTo(centro.dx, centro.dy + r * 1.9)
      ..cubicTo(centro.dx - r * 0.35, centro.dy + r * 1.2, centro.dx - r,
          centro.dy + r * 0.6, centro.dx - r, centro.dy)
      ..arcToPoint(Offset(centro.dx + r, centro.dy), radius: Radius.circular(r))
      ..cubicTo(centro.dx + r, centro.dy + r * 0.6, centro.dx + r * 0.35,
          centro.dy + r * 1.2, centro.dx, centro.dy + r * 1.9)
      ..close();
    c.drawPath(pino, _tinta(AppColors.oliva));
    c.drawCircle(centro, r * 0.38, _tinta(Colors.white));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Variante de foto de ambiente para o psicólogo e a posição na galeria.
int varianteDaGaleria(String psicologoId, int indice) =>
    (_hash(psicologoId) + indice) % 6;

// ------------------------------------------------------------------ clínica

class _PintorClinica extends CustomPainter {
  const _PintorClinica(this.semente, {this.rosto = false});

  final String semente;

  /// Enquadramento fechado na fachada (avatares).
  final bool rosto;

  static const _fachadas = [
    Color(0xFFEFE6D6),
    Color(0xFFE3E5D1),
    Color(0xFFE9E3F2),
    Color(0xFFF1E4D6),
  ];
  static const _toldos = [
    AppColors.oliva,
    Color(0xFF6A5AA6),
    Color(0xFFB5654A),
    Color(0xFF3A7A68),
  ];

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final r = _hash(semente);
    final fachada = _fachadas[r % _fachadas.length];
    final toldo = _toldos[(r ~/ 5) % _toldos.length];
    final area = Offset.zero & size;
    c.drawRect(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCE7EE), Color(0xFFF1F0E8)],
        ).createShader(area),
    );
    final m = math.min(w, h);
    if (!rosto) {
      c.drawCircle(
          Offset(w * 0.84, h * 0.2), m * 0.08, _tinta(const Color(0xFFF7E6B5)));
    }
    final chao = h * (rosto ? 0.9 : 0.87);
    c.drawRect(
        Rect.fromLTWH(0, chao, w, h - chao), _tinta(const Color(0xFFD9D2C3)));
    c.drawRect(Rect.fromLTWH(0, chao - h * 0.025, w, h * 0.03),
        _tinta(const Color(0xFFC5D3AA)));

    final pw = rosto ? w * 0.86 : math.min(w * 0.62, h * 1.15);
    final ph = rosto ? h * 0.7 : h * 0.64;
    final predio = Rect.fromLTWH((w - pw) / 2, chao - ph, pw, ph);
    c.drawRRect(
      RRect.fromRectAndCorners(
        predio,
        topLeft: Radius.circular(pw * 0.05),
        topRight: Radius.circular(pw * 0.05),
      ),
      _tinta(fachada),
    );
    final faixa = Rect.fromLTWH(predio.left, predio.top, pw, ph * 0.13);
    c.drawRRect(
      RRect.fromRectAndCorners(
        faixa,
        topLeft: Radius.circular(pw * 0.05),
        topRight: Radius.circular(pw * 0.05),
      ),
      _tinta(_escurecer(fachada, 0.07)),
    );
    // Placa com a folha no alto da fachada.
    final placa = Rect.fromCenter(
        center: faixa.center, width: pw * 0.34, height: ph * 0.08);
    c.drawRRect(RRect.fromRectAndRadius(placa, Radius.circular(ph * 0.02)),
        _tinta(Colors.white));
    final folha = ph * 0.055;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
            center: Offset(placa.left + placa.height * 0.7, placa.center.dy),
            width: folha,
            height: folha),
        topLeft: Radius.circular(folha * 0.5),
        topRight: Radius.circular(folha * 0.5),
        bottomRight: Radius.circular(folha * 0.5),
        bottomLeft: Radius.circular(folha * 0.16),
      ),
      _tinta(toldo),
    );
    final letras = Paint()
      ..color = const Color(0xFFBDB6A6)
      ..strokeWidth = ph * 0.014
      ..strokeCap = StrokeCap.round;
    c.drawLine(
      Offset(placa.left + placa.height * 1.3, placa.center.dy),
      Offset(placa.right - placa.height * 0.5, placa.center.dy),
      letras,
    );

    // Janelas (duas fileiras) com floreiras.
    const colunas = 3;
    final jw = pw * 0.19;
    final jh = ph * 0.2;
    final folgaX = (pw - colunas * jw) / (colunas + 1);
    for (var i = 0; i < colunas; i++) {
      for (var j = 0; j < 2; j++) {
        if (j == 1 && i == 1) continue;
        final jr = Rect.fromLTWH(
          predio.left + folgaX + i * (jw + folgaX),
          predio.top + ph * 0.21 + j * (jh + ph * 0.13),
          jw,
          jh,
        );
        c.drawRect(jr.inflate(pw * 0.012), _tinta(Colors.white));
        c.drawRect(
          jr,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC6DAE6), Color(0xFFEAF2F5)],
            ).createShader(jr),
        );
        c.drawLine(
          Offset(jr.center.dx, jr.top),
          Offset(jr.center.dx, jr.bottom),
          Paint()
            ..color = Colors.white
            ..strokeWidth = pw * 0.012,
        );
        if ((i + j + r) % 2 == 0) {
          final floreira = Rect.fromLTWH(jr.left - pw * 0.01,
              jr.bottom + pw * 0.012, jw + pw * 0.02, ph * 0.04);
          for (var k = 0; k < 4; k++) {
            c.drawCircle(
              Offset(floreira.left + floreira.width * (0.15 + k * 0.23),
                  floreira.top),
              ph * 0.028,
              _tinta(
                  k.isEven ? const Color(0xFF6F8F5A) : const Color(0xFF8BA872)),
            );
          }
          c.drawRect(floreira, _tinta(_escurecer(toldo, 0.1)));
        }
      }
    }

    // Porta com toldo.
    final dw = jw * 1.1;
    final dh = ph * 0.33;
    final porta = Rect.fromLTWH(predio.center.dx - dw / 2, chao - dh, dw, dh);
    c.drawRRect(
      RRect.fromRectAndCorners(porta,
          topLeft: Radius.circular(dw * 0.18),
          topRight: Radius.circular(dw * 0.18)),
      _tinta(_escurecer(toldo, 0.15)),
    );
    final vidro = porta.deflate(dw * 0.12);
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(vidro.left, vidro.top, vidro.right, porta.bottom),
        topLeft: Radius.circular(dw * 0.12),
        topRight: Radius.circular(dw * 0.12),
      ),
      _tinta(const Color(0xFFDCE8EE)),
    );
    c.drawLine(
      Offset(porta.center.dx, vidro.top),
      Offset(porta.center.dx, porta.bottom),
      Paint()
        ..color = _escurecer(toldo, 0.15)
        ..strokeWidth = dw * 0.05,
    );
    final tw = dw * 1.9;
    final toldoRect = Rect.fromLTWH(
        predio.center.dx - tw / 2, porta.top - ph * 0.12, tw, ph * 0.08);
    c.drawRRect(RRect.fromRectAndRadius(toldoRect, Radius.circular(ph * 0.015)),
        _tinta(toldo));
    const gomos = 6;
    for (var k = 0; k < gomos; k++) {
      final gx = toldoRect.left + toldoRect.width * (k + 0.5) / gomos;
      c.drawCircle(
        Offset(gx, toldoRect.bottom),
        toldoRect.width / gomos / 2,
        _tinta(k.isEven ? toldo : _clarear(toldo, 0.25)),
      );
    }

    // Árvore e arbusto.
    if (!rosto) {
      final tronco = Rect.fromLTWH(
          predio.left - w * 0.1, chao - h * 0.3, m * 0.035, h * 0.3);
      c.drawRect(tronco, _tinta(const Color(0xFF8A6A4A)));
      for (final (dx, dy, raio) in const [
        (0.0, -0.36, 0.13),
        (-0.08, -0.28, 0.1),
        (0.08, -0.27, 0.11)
      ]) {
        c.drawCircle(
          Offset(tronco.center.dx + dx * m, chao + dy * h),
          raio * m,
          _tinta(dx == 0 ? const Color(0xFF7A9A5E) : const Color(0xFF6A8A50)),
        );
      }
      c.drawOval(
        Rect.fromCenter(
            center: Offset(predio.right + w * 0.07, chao - h * 0.03),
            width: m * 0.28,
            height: m * 0.16),
        _tinta(const Color(0xFF6F8F5A)),
      );
    } else {
      for (final lado in [-1.0, 1.0]) {
        c.drawOval(
          Rect.fromCenter(
              center: Offset(w / 2 + lado * pw * 0.42, chao - h * 0.02),
              width: w * 0.2,
              height: h * 0.12),
          _tinta(const Color(0xFF6F8F5A)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PintorClinica old) =>
      old.semente != semente || old.rosto != rosto;
}

/// Foto ilustrada de um psicólogo no formato de folha, no lugar das iniciais.
class AvatarRetrato extends StatelessWidget {
  const AvatarRetrato(this.semente,
      {super.key, this.feminino, this.tamanho = 40, this.rotulo});

  final String semente;
  final bool? feminino;
  final double tamanho;
  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: rotulo ?? 'Foto de perfil',
      child: ClipRRect(
        borderRadius: FormaFolha.raio(tamanho),
        child: SizedBox.square(
          dimension: tamanho,
          child: RepaintBoundary(
            child: CustomPaint(
                painter: _PintorRetrato(semente, feminino, rosto: true)),
          ),
        ),
      ),
    );
  }
}

/// Imagem da clínica (fachada ilustrada) no formato de folha.
class AvatarClinica extends StatelessWidget {
  const AvatarClinica(this.semente,
      {super.key, this.tamanho = 64, this.nome = 'clínica'});

  final String semente;
  final String nome;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Fachada: $nome',
      child: ClipRRect(
        borderRadius: FormaFolha.raio(tamanho),
        child: SizedBox.square(
          dimension: tamanho,
          child: RepaintBoundary(
            child: CustomPaint(painter: _PintorClinica(semente, rosto: true)),
          ),
        ),
      ),
    );
  }
}

/// Foto do psicólogo em formato de folha (no lugar das iniciais).
Widget fotoDoPsicologo(Psicologo p, double tamanho) => AvatarRetrato(p.id,
    feminino: p.feminino, tamanho: tamanho, rotulo: 'Foto de ${p.nome}');

/// Imagem da clínica em formato de folha.
Widget fotoDaClinica(Clinica c, double tamanho) =>
    AvatarClinica(c.id, tamanho: tamanho, nome: c.nome);
