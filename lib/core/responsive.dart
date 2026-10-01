import 'package:flutter/widgets.dart';

/// A partir desta largura o app usa o layout web (barra superior ou menu
/// lateral); abaixo dela, o layout mobile com barra inferior.
const larguraLayoutWeb = 900.0;

extension ResponsiveContext on BuildContext {
  double get larguraTela => MediaQuery.sizeOf(this).width;
  bool get isWide => larguraTela >= larguraLayoutWeb;
}

/// Centraliza o conteúdo com largura máxima, como nos wireframes web.
class Centralizado extends StatelessWidget {
  const Centralizado({
    super.key,
    required this.child,
    this.larguraMax = 1344,
    this.padding = const EdgeInsets.symmetric(horizontal: 32),
  });

  final Widget child;
  final double larguraMax;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMax),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
