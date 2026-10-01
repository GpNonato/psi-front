import 'package:flutter/material.dart';

import '../theme.dart';
import 'botoes.dart';

/// Título serifado com uma parte em itálico, como "Psicólogos em *destaque*".
class TituloSerif extends StatelessWidget {
  const TituloSerif(
    this.texto, {
    super.key,
    this.italico,
    this.depois,
    this.tamanho = 28,
    this.cor = AppColors.texto,
    this.maxLinhas,
    this.alinhamento,
    this.altura = 1.15,
    this.familia = AppText.serifFamily,
  });

  final String texto;
  final String? italico;
  final String? depois;
  final double tamanho;
  final Color cor;
  final int? maxLinhas;
  final TextAlign? alinhamento;

  /// Altura da linha (entrelinha) do título.
  final double altura;

  /// Família da fonte (ex.: a escolhida pelo psicólogo para a página).
  final String familia;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style:
            AppText.serif(tamanho, cor: cor, altura: altura, familia: familia),
        children: [
          TextSpan(text: texto),
          if (italico != null)
            TextSpan(
              text: italico,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          if (depois != null) TextSpan(text: depois),
        ],
      ),
      maxLines: maxLinhas,
      overflow: maxLinhas == null ? null : TextOverflow.ellipsis,
      textAlign: alinhamento,
    );
  }
}

/// Cabeçalho de seção: título serifado, subtítulo opcional e link à direita.
class CabecalhoSecao extends StatelessWidget {
  const CabecalhoSecao({
    super.key,
    required this.titulo,
    this.italico,
    this.subtitulo,
    this.acao,
    this.onAcao,
    this.tamanho = 32,
  });

  final String titulo;
  final String? italico;
  final String? subtitulo;
  final String? acao;
  final VoidCallback? onAcao;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: TituloSerif(titulo, italico: italico, tamanho: tamanho),
              ),
              if (subtitulo != null) ...[
                const SizedBox(height: 6),
                Text(subtitulo!, style: AppText.pequeno),
              ],
            ],
          ),
        ),
        if (acao != null) LinkTexto(acao!, onTap: onAcao),
      ],
    );
  }
}
