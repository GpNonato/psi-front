import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'icones.dart';

/// Rótulo pequeno acima de um campo.
class CampoRotulado extends StatelessWidget {
  const CampoRotulado({super.key, required this.rotulo, required this.child});

  final String rotulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: AppText.rotulo),
        const SizedBox(height: 2),
        child,
      ],
    );
  }
}

/// Campo de texto no estilo dos wireframes.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    this.controller,
    this.valorInicial,
    this.hint,
    this.rotulo,
    this.icone,
    this.linhas = 1,
    this.maxLength,
    this.contador = false,
    this.onChanged,
    this.onSubmitted,
    this.teclado,
    this.senha = false,
    this.erro,
    this.autofocus = false,
    this.acaoTeclado,
    this.alto = false,
    this.altura,
  });

  /// Campo mais alto (busca da página inicial).
  final bool alto;

  /// Altura exata do campo de uma linha (ex.: 50 na busca do wireframe 02).
  final double? altura;
  final TextEditingController? controller;
  final String? valorInicial;
  final String? hint;
  final String? rotulo;
  final IconData? icone;
  final int linhas;
  final int? maxLength;
  final bool contador;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? teclado;
  final bool senha;
  final String? erro;
  final bool autofocus;
  final TextInputAction? acaoTeclado;

  @override
  Widget build(BuildContext context) {
    final campo = TextFormField(
      controller: controller,
      initialValue: controller == null ? valorInicial : null,
      maxLines: senha ? 1 : linhas,
      minLines: linhas > 1 ? linhas : null,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      keyboardType: teclado ?? (linhas > 1 ? TextInputType.multiline : null),
      textInputAction: acaoTeclado,
      obscureText: senha,
      autofocus: autofocus,
      style: const TextStyle(fontSize: 15, color: AppColors.texto),
      decoration: InputDecoration(
        hintText: hint,
        // Ícone de 16 px a 16 px da borda e texto a 45 px, como no wireframe 11.
        prefixIcon: icone == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icone(icone, size: 17, color: AppColors.textoSecundario),
              ),
        prefixIconConstraints: const BoxConstraints(),
        errorText: erro,
        counterText: maxLength != null && !contador ? '' : null,
        contentPadding: altura != null
            ? EdgeInsets.symmetric(horizontal: 16, vertical: (altura! - 22) / 2)
            : alto
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 17.5)
                : null,
      ),
    );
    if (rotulo == null) return campo;
    return CampoRotulado(rotulo: rotulo!, child: campo);
  }
}

/// Caixa de seleção (dropdown) com borda arredondada.
class SeletorCaixa<T> extends StatelessWidget {
  const SeletorCaixa({
    super.key,
    required this.valor,
    required this.opcoes,
    required this.rotulo,
    required this.onChanged,
    this.hint = 'Selecione',
    this.altura = 46,
    this.icone,
    this.rotuloCampo,
    this.largura,
    this.semantica,
  });

  final T? valor;
  final List<T> opcoes;
  final String Function(T) rotulo;
  final ValueChanged<T> onChanged;
  final String hint;
  final double altura;
  final IconData? icone;
  final String? rotuloCampo;
  final double? largura;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final atual = valor;
    final texto = atual == null ? hint : rotulo(atual);
    final caixa = LayoutBuilder(
      builder: (context, c) {
        final larguraMenu = c.maxWidth.isFinite ? c.maxWidth : 220.0;
        return PopupMenuButton<T>(
          tooltip: semantica ?? rotuloCampo ?? hint,
          initialValue: atual,
          onSelected: onChanged,
          position: PopupMenuPosition.under,
          constraints: BoxConstraints(
            minWidth: larguraMenu,
            maxWidth: math.max(larguraMenu, 220),
          ),
          itemBuilder: (_) => [
            for (final o in opcoes)
              PopupMenuItem<T>(value: o, height: 42, child: Text(rotulo(o))),
          ],
          child: Container(
            height: altura,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borda),
            ),
            child: Row(
              children: [
                if (icone != null) ...[
                  Icone(icone, size: 18, color: AppColors.textoSecundario),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: atual == null
                          ? AppColors.textoFraco
                          : AppColors.texto,
                    ),
                  ),
                ),
                const Icone(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textoSecundario,
                ),
              ],
            ),
          ),
        );
      },
    );
    final dimensionada =
        largura == null ? caixa : SizedBox(width: largura, child: caixa);
    if (rotuloCampo == null) return dimensionada;
    return CampoRotulado(rotulo: rotuloCampo!, child: dimensionada);
  }
}

/// Caixa de marcação com rótulo clicável.
class LinhaCheck extends StatelessWidget {
  const LinhaCheck({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
    this.conteudo,
    this.tamanhoTexto = 15,
  });

  final String rotulo;
  final bool valor;
  final ValueChanged<bool> onChanged;
  final Widget? conteudo;
  final double tamanhoTexto;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!valor),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // A caixa de 18 px fica rente ao conteúdo, como nos wireframes.
              Transform.translate(
                offset: const Offset(-2, 0),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: valor,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: conteudo ??
                    Text(
                      rotulo,
                      style: TextStyle(
                          fontSize: tamanhoTexto, color: AppColors.texto),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bolinha de opção única, desenhada à mão (o Radio do Material depende de RadioGroup).
class BolinhaRadio extends StatelessWidget {
  const BolinhaRadio({super.key, required this.selecionado, this.tamanho = 20});

  final bool selecionado;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selecionado ? AppColors.oliva : const Color(0xFFC9C6B8),
          width: selecionado ? 2 : 1.5,
        ),
      ),
      child: selecionado
          ? Container(
              width: tamanho * 0.5,
              height: tamanho * 0.5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.oliva,
              ),
            )
          : null,
    );
  }
}

/// Cartão de opção única (perfil de uso, duração do destaque...).
class CartaoOpcao extends StatelessWidget {
  const CartaoOpcao({
    super.key,
    required this.selecionado,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.mostrarRadio = true,
    this.alinharTopo = false,
  });

  final bool selecionado;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool mostrarRadio;
  final bool alinharTopo;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selecionado ? AppColors.oliva : AppColors.borda,
        width: selecionado ? 2 : 1,
      ),
    );
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selecionado,
      button: true,
      child: Material(
        color: Colors.white,
        shape: forma,
        child: InkWell(
          onTap: onTap,
          customBorder: forma,
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: alinharTopo
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (mostrarRadio) ...[
                  BolinhaRadio(selecionado: selecionado),
                  const SizedBox(width: 10),
                ],
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interruptor com rótulo.
class LinhaSwitch extends StatelessWidget {
  const LinhaSwitch({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
    this.subtitulo,
  });

  final String rotulo;
  final bool valor;
  final ValueChanged<bool> onChanged;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!valor),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Interruptor(valor: valor, onChanged: onChanged),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.texto)),
                    if (subtitulo != null)
                      Text(subtitulo!, style: AppText.pequeno),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seletor segmentado em pílula ("Online | Presencial", "Dia | Semana").
class SegmentoPill<T> extends StatelessWidget {
  const SegmentoPill({
    super.key,
    required this.opcoes,
    required this.valor,
    required this.rotulo,
    required this.onChanged,
    this.expandir = true,
    this.altura = 40,
    this.fundo = const Color(0xFFEAEBDF),
  });

  /// Cor do trilho atrás das opções.
  final Color fundo;

  final List<T> opcoes;
  final T valor;
  final String Function(T) rotulo;
  final ValueChanged<T> onChanged;
  final bool expandir;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: expandir ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final o in opcoes) _segmento(o)],
      ),
    );
  }

  Widget _segmento(T o) {
    final sel = o == valor;
    final w = Semantics(
      button: true,
      selected: sel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: sel ? AppColors.borda : Colors.transparent),
            ),
            child: Text(
              rotulo(o),
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                color: sel ? AppColors.texto : AppColors.textoSecundario,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
    return expandir ? Expanded(child: w) : w;
  }
}

/// Interruptor no tamanho dos wireframes (cerca de 44 × 26 px).
class Interruptor extends StatelessWidget {
  const Interruptor({super.key, required this.valor, required this.onChanged});

  final bool valor;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 27,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: valor,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
