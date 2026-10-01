import 'package:flutter/material.dart';

/// Ícone em traço fino, como nos wireframes (desenhos no estilo Lucide: grade
/// de 24 × 24, traço 2, pontas e cantos arredondados).
///
/// O código continua usando os [IconData] do Material como nome do ícone; os
/// que têm desenho aqui aparecem em traço, os outros caem no [Icon] comum.
class Icone extends StatelessWidget {
  const Icone(
    this.icone, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData? icone;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final tamanho = size ?? tema.size ?? 24;
    var cor = color ?? tema.color ?? const Color(0xFF000000);
    final opacidade = tema.opacity ?? 1;
    if (opacidade < 1) cor = cor.withValues(alpha: cor.a * opacidade);
    final desenho = icone == null ? null : _desenhos[icone];
    if (desenho == null) {
      return Icon(icone,
          size: tamanho, color: cor, semanticLabel: semanticLabel);
    }
    // Como o Icon do Flutter: se o pai impõe uma caixa maior (botão redondo,
    // por exemplo), o desenho mantém o tamanho pedido e fica no centro.
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: tamanho,
          child: CustomPaint(painter: _PintorIcone(desenho, cor, tamanho)),
        ),
      ),
    );
  }
}

class _Desenho {
  _Desenho(List<String> caminhos, {this.preenchido = false})
      : _fontes = caminhos;

  final List<String> _fontes;
  final bool preenchido;
  late final List<Path> caminhos = [for (final d in _fontes) caminhoSvg(d)];
}

class _PintorIcone extends CustomPainter {
  const _PintorIcone(this.desenho, this.cor, this.tamanho);

  final _Desenho desenho;
  final Color cor;
  final double tamanho;

  @override
  void paint(Canvas canvas, Size size) {
    final lado = tamanho < size.shortestSide ? tamanho : size.shortestSide;
    final escala = lado / 24;
    canvas
      ..save()
      ..translate(
          (size.width - 24 * escala) / 2, (size.height - 24 * escala) / 2)
      ..scale(escala);
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final preenchimento = Paint()..color = cor;
    for (final p in desenho.caminhos) {
      if (desenho.preenchido) canvas.drawPath(p, preenchimento);
      canvas.drawPath(p, traco);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PintorIcone old) =>
      old.desenho != desenho || old.cor != cor || old.tamanho != tamanho;
}

String _circulo(num cx, num cy, num r) =>
    'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 ${-2 * r} 0';

String _retangulo(num x, num y, num w, num h, num r) =>
    'M${x + r} ${y}h${w - 2 * r}a$r $r 0 0 1 $r ${r}v${h - 2 * r}'
    'a$r $r 0 0 1 ${-r} ${r}h${-(w - 2 * r)}a$r $r 0 0 1 ${-r} ${-r}'
    'v${-(h - 2 * r)}a$r $r 0 0 1 $r ${-r}z';

final _estrela = _Desenho(const [
  'M12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 '
      '2 9.27 8.91 8.26z',
]);
final _estrelaCheia = _Desenho(
  const [
    'M12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 '
        '2 9.27 8.91 8.26z',
  ],
  preenchido: true,
);
const _coracao =
    'M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2'
    '-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z';
final _arquivo = _Desenho([
  'M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z',
  'M14 2v4a2 2 0 0 0 2 2h4',
  'M10 9H8',
  'M16 13H8',
  'M16 17H8',
]);
final _imagem = _Desenho([
  _retangulo(3, 3, 18, 18, 2),
  _circulo(9, 9, 2),
  'm21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21',
]);
final _usuario = _Desenho([
  'M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2',
  _circulo(12, 7, 4),
]);
final _calendario = _Desenho([
  'M8 2v4',
  'M16 2v4',
  _retangulo(3, 4, 18, 18, 2),
  'M3 10h18',
]);

final Map<IconData, _Desenho> _desenhos = {
  Icons.calendar_today_outlined: _calendario,
  Icons.add_rounded: _Desenho(const ['M5 12h14', 'M12 5v14']),
  Icons.search_rounded: _Desenho([_circulo(11, 11, 8), 'm21 21-4.3-4.3']),
  Icons.search_off_rounded: _Desenho([
    _circulo(11, 11, 8),
    'm21 21-4.3-4.3',
    'm13.5 8.5-5 5',
    'm8.5 8.5 5 5',
  ]),
  Icons.lock_outline_rounded: _Desenho([
    _retangulo(3, 11, 18, 11, 2),
    'M7 11V7a5 5 0 0 1 10 0v4',
  ]),
  Icons.person_outline_rounded: _usuario,
  Icons.people_outline_rounded: _Desenho([
    'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2',
    _circulo(9, 7, 4),
    'M22 21v-2a4 4 0 0 0-3-3.87',
    'M16 3.13a4 4 0 0 1 0 7.75',
  ]),
  Icons.chevron_right_rounded: _Desenho(const ['m9 18 6-6-6-6']),
  Icons.chevron_left_rounded: _Desenho(const ['m15 18-6-6 6-6']),
  Icons.keyboard_arrow_down_rounded: _Desenho(const ['m6 9 6 6 6-6']),
  Icons.unfold_more_rounded: _Desenho(const ['m7 15 5 5 5-5', 'm7 9 5-5 5 5']),
  Icons.arrow_back_rounded: _Desenho(const ['m12 19-7-7 7-7', 'M19 12H5']),
  Icons.arrow_forward_rounded: _Desenho(const ['M5 12h14', 'm12 5 7 7-7 7']),
  Icons.star_rounded: _estrelaCheia,
  Icons.star_outline_rounded: _estrela,
  Icons.place_outlined: _Desenho([
    'M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z',
    _circulo(12, 10, 3),
  ]),
  Icons.phone_outlined: _Desenho(const [
    'M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1'
        '-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 '
        '12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6'
        'l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 '
        '16.92z',
  ]),
  Icons.logout_rounded: _Desenho(const [
    'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4',
    'm16 17 5-5-5-5',
    'M21 12H9',
  ]),
  Icons.close_rounded: _Desenho(const ['M18 6 6 18', 'm6 6 12 12']),
  Icons.check_rounded: _Desenho(const ['M20 6 9 17l-5-5']),
  Icons.videocam_outlined: _Desenho([
    'm22 8-6 4 6 4V8Z',
    _retangulo(2, 6, 14, 12, 2),
  ]),
  Icons.schedule_rounded: _Desenho([_circulo(12, 12, 10), 'M12 6v6l4 2']),
  Icons.notifications_none_rounded: _Desenho(const [
    'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9',
    'M10.3 21a1.94 1.94 0 0 0 3.4 0',
  ]),
  Icons.mail_outline_rounded: _Desenho([
    _retangulo(2, 4, 20, 16, 2),
    'm22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7',
  ]),
  Icons.attach_money_rounded: _Desenho(const [
    'M12 2v20',
    'M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6',
  ]),
  // "Configurações" nos wireframes: dois círculos concêntricos.
  Icons.settings_outlined:
      _Desenho([_circulo(12, 12, 10), _circulo(12, 12, 4)]),
  Icons.apartment_outlined: _Desenho(const [
    'M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z',
    'M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2',
    'M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2',
    'M10 6h4',
    'M10 10h4',
    'M10 14h4',
    'M10 18h4',
  ]),
  Icons.tune_rounded: _Desenho(const [
    'M21 4h-7',
    'M10 4H3',
    'M21 12h-9',
    'M8 12H3',
    'M21 20h-5',
    'M12 20H3',
    'M14 2v4',
    'M8 10v4',
    'M16 18v4',
  ]),
  Icons.photo_outlined: _imagem,
  Icons.image_outlined: _imagem,
  Icons.photo_library_outlined: _Desenho([
    'M18 22H4a2 2 0 0 1-2-2V6',
    'm22 13-1.296-1.296a2.41 2.41 0 0 0-3.408 0L11 18',
    _circulo(12, 8, 2),
    _retangulo(6, 2, 16, 16, 2),
  ]),
  Icons.menu_rounded: _Desenho(const ['M4 12h16', 'M4 6h16', 'M4 18h16']),
  Icons.description_outlined: _arquivo,
  Icons.picture_as_pdf_outlined: _arquivo,
  Icons.upload_rounded: _Desenho(const [
    'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4',
    'm17 8-5-5-5 5',
    'M12 3v12',
  ]),
  Icons.more_horiz_rounded: _Desenho([
    _circulo(12, 12, 1),
    _circulo(19, 12, 1),
    _circulo(5, 12, 1),
  ]),
  Icons.info_outline_rounded: _Desenho([
    _circulo(12, 12, 10),
    'M12 16v-4',
    'M12 8h.01',
  ]),
  Icons.home_outlined: _Desenho(const [
    'M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8',
    'M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 '
        '21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
  ]),
  Icons.favorite_border_rounded: _Desenho(const [_coracao]),
  Icons.favorite_rounded: _Desenho(const [_coracao], preenchido: true),
  Icons.delete_outline_rounded: _Desenho(const [
    'M3 6h18',
    'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6',
    'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2',
    'M10 11v6',
    'M14 11v6',
  ]),
};

/// Converte o atributo `d` de um `<path>` SVG em um [Path] (comandos M, L, H,
/// V, C, S, Q, A e Z, absolutos e relativos).
Path caminhoSvg(String d) {
  final tokens = RegExp(r'[MmLlHhVvCcSsQqAaZz]|-?(?:\d+\.?\d*|\.\d+)')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0;
  String? cmd;
  var x = 0.0, y = 0.0, inicioX = 0.0, inicioY = 0.0;
  double? controleX, controleY;
  bool ehComando(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (ehComando(tokens[i])) {
      cmd = tokens[i++];
    }
    if (cmd == null) break;
    final relativo = cmd == cmd.toLowerCase();
    final ox = relativo ? x : 0.0, oy = relativo ? y : 0.0;
    var novoControle = false;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + n();
        y = oy + n();
        path.moveTo(x, y);
        inicioX = x;
        inicioY = y;
        // Pares seguintes a um M são linhas.
        cmd = relativo ? 'l' : 'L';
      case 'L':
        x = ox + n();
        y = oy + n();
        path.lineTo(x, y);
      case 'H':
        x = ox + n();
        path.lineTo(x, y);
      case 'V':
        y = oy + n();
        path.lineTo(x, y);
      case 'C':
        final x1 = ox + n(), y1 = oy + n();
        final x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controleX = x2;
        controleY = y2;
        novoControle = true;
      case 'S':
        final x1 = controleX == null ? x : 2 * x - controleX;
        final y1 = controleY == null ? y : 2 * y - controleY;
        final x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        controleX = x2;
        controleY = y2;
        novoControle = true;
      case 'Q':
        final x1 = ox + n(), y1 = oy + n();
        x = ox + n();
        y = oy + n();
        path.quadraticBezierTo(x1, y1, x, y);
      case 'A':
        final rx = n(), ry = n(), rotacao = n();
        final grande = n() != 0, horario = n() != 0;
        x = ox + n();
        y = oy + n();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotacao,
          largeArc: grande,
          clockwise: horario,
        );
      case 'Z':
        path.close();
        x = inicioX;
        y = inicioY;
        cmd = null;
      default:
        i++;
    }
    if (!novoControle) {
      controleX = null;
      controleY = null;
    }
  }
  return path;
}
