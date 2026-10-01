import 'package:flutter/material.dart';

import '../theme.dart';
import 'icones.dart';

/// Cartão branco arredondado usado em todas as telas. Quando é clicável, sobe
/// um pouco e ganha sombra ao passar o mouse.
class CartaoApp extends StatefulWidget {
  const CartaoApp({
    super.key,
    required this.child,
    this.padding,
    this.cor = Colors.white,
    this.raio = 24,
    this.borda,
    this.onTap,
  });

  final Widget child;

  /// Espaço interno; por padrão 24 no web e 16 no celular.
  final EdgeInsetsGeometry? padding;
  final Color cor;
  final double raio;
  final BorderSide? borda;
  final VoidCallback? onTap;

  @override
  State<CartaoApp> createState() => _CartaoAppState();
}

class _CartaoAppState extends State<CartaoApp> {
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.raio),
      side: widget.borda ?? BorderSide.none,
    );
    final padding = widget.padding ??
        EdgeInsets.all(MediaQuery.sizeOf(context).width >= 900 ? 24 : 16);
    Widget conteudo = Padding(padding: padding, child: widget.child);
    if (widget.onTap != null) {
      conteudo = InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _sobre = v),
        customBorder: forma,
        // O cartão sobe e ganha sombra; o fundo continua branco.
        hoverColor: Colors.transparent,
        child: conteudo,
      );
    }
    final cartao = Material(
      color: widget.cor,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: conteudo,
    );
    if (widget.onTap == null) return cartao;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _sobre ? -3 : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.raio),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B4422).withValues(alpha: _sobre ? 0.12 : 0),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: cartao,
    );
  }
}

/// Título de cartão com ação opcional à direita ("Dados pessoais ... Editar").
class CabecalhoCartao extends StatelessWidget {
  const CabecalhoCartao(
    this.titulo, {
    super.key,
    this.acao,
    this.icone,
    this.serif = false,
    this.tamanho,
  });

  final String titulo;
  final Widget? acao;
  final IconData? icone;
  final bool serif;
  final double? tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    titulo,
                    style: serif
                        ? AppText.serif(tamanho ?? 22)
                        : TextStyle(
                            fontSize: tamanho ?? 19,
                            color: AppColors.texto,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ),
              ),
              if (icone != null) ...[
                const SizedBox(width: 10),
                Icone(icone, size: 16, color: AppColors.lavanda),
              ],
            ],
          ),
        ),
        if (acao != null) ...[const SizedBox(width: 12), acao!],
      ],
    );
  }
}

/// Aviso em lavanda (sigilo, lembretes, regras).
class AvisoLavanda extends StatelessWidget {
  const AvisoLavanda(
    this.texto, {
    super.key,
    this.icone = Icons.info_outline_rounded,
    this.titulo,
    this.compacto = false,
  });

  final String texto;
  final IconData icone;
  final String? titulo;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: 18, vertical: compacto ? 10 : (titulo != null ? 12 : 14)),
      decoration: BoxDecoration(
        color: AppColors.lavandaClaro,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: titulo != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icone(icone, size: 19, color: AppColors.lavandaEscuro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titulo != null)
                  Text(
                    titulo!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.lavandaEscuro,
                      height: 1.43,
                    ),
                  ),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.lavandaEscuro,
                    height: 1.43,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progresso fina e arredondada.
class BarraProgresso extends StatelessWidget {
  const BarraProgresso({
    super.key,
    required this.valor,
    this.cor = AppColors.oliva,
    this.fundo = const Color(0xFFECEBE3),
    this.altura = 6,
  });

  final double valor;
  final Color cor;
  final Color fundo;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final raio = BorderRadius.circular(altura);
    return LayoutBuilder(
      builder: (context, c) => Container(
        height: altura,
        decoration: BoxDecoration(color: fundo, borderRadius: raio),
        alignment: Alignment.centerLeft,
        child: Container(
          width: c.maxWidth * valor.clamp(0.0, 1.0),
          height: altura,
          decoration: BoxDecoration(color: cor, borderRadius: raio),
        ),
      ),
    );
  }
}

/// Indicador grande (Recebido, A receber, Sessões no mês...).
class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.rotulo,
    required this.valor,
    this.detalhe,
    this.cor = AppColors.texto,
    this.tamanho = 40,
  });

  final String rotulo;
  final String valor;
  final String? detalhe;
  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: AppText.pequeno),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(valor,
              style: AppText.serif(tamanho, cor: cor, altura: 1.05)),
        ),
        if (detalhe != null) ...[
          const SizedBox(height: 5),
          Text(
            detalhe!,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textoSecundario),
          ),
        ],
      ],
    );
  }
}

/// Grade que distribui os itens em colunas conforme a largura disponível.
class GradeResponsiva extends StatelessWidget {
  const GradeResponsiva({
    super.key,
    required this.children,
    this.larguraMinItem = 280,
    this.maxColunas = 3,
    this.espaco = 24,
    this.espacoVertical,
  });

  final List<Widget> children;
  final double larguraMinItem;
  final int maxColunas;
  final double espaco;
  final double? espacoVertical;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = ((c.maxWidth + espaco) / (larguraMinItem + espaco))
            .floor()
            .clamp(1, maxColunas);
        final largura = (c.maxWidth - espaco * (n - 1)) / n;
        return Wrap(
          spacing: espaco,
          runSpacing: espacoVertical ?? espaco,
          children: [
            for (final ch in children) SizedBox(width: largura, child: ch)
          ],
        );
      },
    );
  }
}

/// Linha "rótulo / valor" usada em fichas e resumos.
class LinhaInfo extends StatelessWidget {
  const LinhaInfo({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
    this.larguraRotulo,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;
  final double? larguraRotulo;

  @override
  Widget build(BuildContext context) {
    final rotuloWidget = Text(
      rotulo,
      style: const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
    );
    final valorWidget = Text(
      valor,
      style: const TextStyle(fontSize: 15, color: AppColors.texto),
    );
    if (larguraRotulo != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icone != null) ...[
              Icone(icone, size: 18, color: AppColors.lavanda),
              const SizedBox(width: 10),
            ],
            SizedBox(width: larguraRotulo, child: rotuloWidget),
            Expanded(child: valorWidget),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [rotuloWidget, const SizedBox(height: 6), valorWidget],
    );
  }
}
