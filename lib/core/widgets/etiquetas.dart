import 'package:flutter/material.dart';

import '../formatters.dart';
import '../theme.dart';
import 'icones.dart';

/// Etiqueta com contorno lavanda ("Ansiedade", "Luto").
class TagChip extends StatelessWidget {
  const TagChip(
    this.rotulo, {
    super.key,
    this.compacto = false,
    this.onRemover,
  });

  final String rotulo;
  final bool compacto;
  final VoidCallback? onRemover;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        compacto ? 4.5 : 5,
        onRemover != null ? 6 : 10,
        compacto ? 4.5 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lavandaBorda),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              rotulo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compacto ? 12 : 13,
                color: AppColors.lavandaEscuro,
                height: 1.2,
              ),
            ),
          ),
          if (onRemover != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Remover $rotulo',
              child: InkWell(
                onTap: onRemover,
                borderRadius: BorderRadius.circular(10),
                child: const Icone(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.lavandaEscuro,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lista de etiquetas com espaçamento padrão.
class Etiquetas extends StatelessWidget {
  const Etiquetas(this.rotulos, {super.key, this.compacto = false});

  final List<String> rotulos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final r in rotulos) TagChip(r, compacto: compacto)],
    );
  }
}

/// Etiqueta preenchida em sálvia ("Realizada", "Plano atual", "Horário hoje").
class SoftChip extends StatelessWidget {
  const SoftChip(
    this.rotulo, {
    super.key,
    this.fundo = AppColors.salvia,
    this.cor = AppColors.olivaEscuro,
    this.tamanho = 12.5,
    this.icone,
  });

  final String rotulo;
  final Color fundo;
  final Color cor;
  final double tamanho;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icone(icone, size: tamanho + 2, color: cor),
            const SizedBox(width: 5),
          ],
          Text(rotulo, style: TextStyle(fontSize: tamanho, color: cor)),
        ],
      ),
    );
  }
}

/// Situação com bolinha colorida ("● Confirmada", "● Pendente").
class StatusPonto extends StatelessWidget {
  const StatusPonto(
    this.rotulo, {
    super.key,
    this.cor = AppColors.verde,
    this.tamanho = 13,
  });

  final String rotulo;
  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            rotulo,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: tamanho, color: AppColors.texto),
          ),
        ),
      ],
    );
  }
}

/// Filtro em pílula que pode ser ligado e desligado.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro(
    this.rotulo, {
    super.key,
    required this.selecionado,
    required this.onTap,
    this.icone,
    this.compacto = false,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback onTap;
  final IconData? icone;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(compacto ? 8 : 999),
      side: BorderSide(
        color: selecionado || compacto ? Colors.transparent : AppColors.borda,
      ),
    );
    return Semantics(
      button: true,
      selected: selecionado,
      child: Material(
        color: selecionado
            ? AppColors.salvia
            : (compacto ? const Color(0xFFF0EFE8) : Colors.white),
        shape: forma,
        child: InkWell(
          onTap: onTap,
          customBorder: forma,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compacto ? 10 : 16,
              vertical: compacto ? 5 : 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icone(icone, size: 18, color: AppColors.texto),
                  const SizedBox(width: 8),
                ],
                Text(
                  rotulo,
                  style: TextStyle(
                    fontSize: compacto ? 13 : 14,
                    color: AppColors.texto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Estrelas de 1 a 5 (somente leitura).
class Estrelas extends StatelessWidget {
  const Estrelas(this.nota, {super.key, this.tamanho = 14});

  final num nota;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${nota.round()} de 5 estrelas',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icone(
                i <= nota.round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: tamanho,
                color: AppColors.estrela,
              ),
          ],
        ),
      ),
    );
  }
}

/// "★ 4,9 (32 avaliações)"
class NotaInline extends StatelessWidget {
  const NotaInline({
    super.key,
    required this.nota,
    required this.total,
    this.tamanho = 13.5,
  });

  final double nota;
  final int total;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Text('Sem avaliações ainda',
          style:
              TextStyle(fontSize: tamanho, color: AppColors.textoSecundario));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icone(Icons.star_rounded, size: tamanho + 4, color: AppColors.estrela),
        const SizedBox(width: 3),
        Text(
          Fmt.nota(nota),
          style: TextStyle(fontSize: tamanho, color: AppColors.texto),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '(${Fmt.plural(total, 'avaliação', 'avaliações')})',
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(fontSize: tamanho, color: AppColors.textoSecundario),
          ),
        ),
      ],
    );
  }
}

const rotulosNota = {
  1: 'Ruim',
  2: 'Regular',
  3: 'Bom',
  4: 'Muito bom',
  5: 'Excelente',
};

/// Estrelas clicáveis da avaliação.
class SeletorEstrelas extends StatelessWidget {
  const SeletorEstrelas({
    super.key,
    required this.valor,
    required this.onChanged,
    this.tamanho = 44,
  });

  final int valor;
  final ValueChanged<int> onChanged;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            tooltip: '$i ${i == 1 ? 'estrela' : 'estrelas'}: ${rotulosNota[i]}',
            iconSize: tamanho,
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(),
            icon: Icone(
              i <= valor ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i <= valor ? AppColors.estrela : AppColors.borda,
            ),
          ),
      ],
    );
  }
}
