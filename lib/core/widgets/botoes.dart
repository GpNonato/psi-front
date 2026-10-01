import 'package:flutter/material.dart';

import '../theme.dart';
import 'icones.dart';

enum EstiloBotao { primario, contorno, contornoLavanda, texto, perigo, lavanda }

/// Botão em pílula dos wireframes.
class BotaoPill extends StatelessWidget {
  const BotaoPill(
    this.rotulo, {
    super.key,
    required this.onPressed,
    this.estilo = EstiloBotao.primario,
    this.icone,
    this.expandir = false,
    this.compacto = false,
    this.cor,
    this.altura,
  });

  final String rotulo;
  final VoidCallback? onPressed;
  final EstiloBotao estilo;
  final IconData? icone;
  final bool expandir;
  final bool compacto;
  final Color? cor;
  final double? altura;

  @override
  Widget build(BuildContext context) {
    final h = altura ?? (compacto ? 38.0 : 48.0);
    final base = cor ?? AppColors.oliva;
    // Parte do estilo do tema para manter a família da fonte: o texto de botão
    // não herda o estilo do tema quando o botão recebe um textStyle próprio.
    final texto =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).merge(
      TextStyle(
        fontSize: compacto ? 13.5 : 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    );
    final padding = EdgeInsets.symmetric(horizontal: compacto ? 18 : 26);
    const forma = StadiumBorder();
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icone != null) ...[
          Icone(icone, size: compacto ? 17 : 19),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    ButtonStyle textoStyle(Color c) => TextButton.styleFrom(
          foregroundColor: c,
          minimumSize: Size(0, h),
          padding: padding,
          shape: forma,
          textStyle: texto,
        );

    final Widget botao = switch (estilo) {
      EstiloBotao.primario => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: base,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.salviaForte,
            disabledForegroundColor: Colors.white,
            minimumSize: Size(0, h),
            padding: padding,
            shape: forma,
            textStyle: texto,
            elevation: 0,
          ),
          child: conteudo,
        ),
      EstiloBotao.contorno => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: base,
            backgroundColor: Colors.white,
            side: BorderSide(color: onPressed == null ? AppColors.borda : base),
            minimumSize: Size(0, h),
            padding: padding,
            shape: forma,
            textStyle: texto,
          ),
          child: conteudo,
        ),
      EstiloBotao.contornoLavanda => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lavandaEscuro,
            side: const BorderSide(color: AppColors.lavandaEscuro),
            minimumSize: Size(0, h),
            padding: padding,
            shape: forma,
            textStyle: texto,
          ),
          child: conteudo,
        ),
      EstiloBotao.texto => TextButton(
          onPressed: onPressed,
          style: textoStyle(base),
          child: conteudo,
        ),
      EstiloBotao.perigo => TextButton(
          onPressed: onPressed,
          style: textoStyle(AppColors.vermelho),
          child: conteudo,
        ),
      EstiloBotao.lavanda => TextButton(
          onPressed: onPressed,
          style: textoStyle(AppColors.lavanda),
          child: conteudo,
        ),
    };
    return expandir ? SizedBox(width: double.infinity, child: botao) : botao;
  }
}

/// Link em lavanda ("Ver todos", "Limpar", "Editar"...).
class LinkTexto extends StatelessWidget {
  const LinkTexto(
    this.rotulo, {
    super.key,
    required this.onTap,
    this.tamanho = 14,
    this.cor = AppColors.lavanda,
    this.icone,
  });

  final String rotulo;
  final VoidCallback? onTap;
  final double tamanho;
  final Color cor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icone(icone, size: tamanho + 3, color: cor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  rotulo,
                  style: TextStyle(fontSize: tamanho, color: cor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão redondo com ícone (voltar, favoritar, notificações).
class BotaoCircular extends StatelessWidget {
  const BotaoCircular({
    super.key,
    required this.icone,
    required this.onPressed,
    required this.tooltip,
    this.tamanho = 40,
    this.cor = Colors.white,
    this.corIcone = AppColors.texto,
    this.indicador = false,
    this.corIndicador = AppColors.lavanda,
    this.tamanhoIcone,
  });

  final IconData icone;

  /// Tamanho do ícone; por padrão, pouco mais da metade do botão.
  final double? tamanhoIcone;
  final VoidCallback? onPressed;
  final String tooltip;
  final double tamanho;
  final Color cor;
  final Color corIcone;
  final bool indicador;
  final Color corIndicador;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: cor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: tamanho,
                height: tamanho,
                child: Icone(icone,
                    size: tamanhoIcone ?? tamanho * 0.52, color: corIcone),
              ),
            ),
          ),
          if (indicador)
            Positioned(
              top: tamanho * 0.16,
              right: tamanho * 0.18,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: corIndicador,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
