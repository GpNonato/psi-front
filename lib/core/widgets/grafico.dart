import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatters.dart';
import '../theme.dart';

class BarraSemana {
  const BarraSemana(this.rotulo, this.recebido, this.aReceber);
  final String rotulo;
  final double recebido;
  final double aReceber;
}

/// Gráfico de barras empilhadas (recebido e a receber), sem bibliotecas externas.
class GraficoBarras extends StatelessWidget {
  const GraficoBarras({super.key, required this.barras, this.altura = 280});

  final List<BarraSemana> barras;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final maximo = barras.fold<double>(
      0,
      (m, b) => math.max(m, b.recebido + b.aReceber),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: altura,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final b in barras)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _barra(b, maximo),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final b in barras)
              Expanded(
                child: Text(
                  b.rotulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textoSecundario),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _barra(BarraSemana b, double maximo) {
    if (maximo <= 0 || b.recebido + b.aReceber <= 0) {
      return const Align(
        alignment: Alignment.bottomCenter,
        child: Text('—', style: TextStyle(color: AppColors.textoFraco)),
      );
    }
    return Semantics(
      label: '${b.rotulo}: recebido ${Fmt.moedaCurta(b.recebido)}, '
          'a receber ${Fmt.moedaCurta(b.aReceber)}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final hRec = c.maxHeight * b.recebido / maximo;
          final hPend = c.maxHeight * b.aReceber / maximo;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hPend > 0)
                Tooltip(
                  message: 'A receber: ${Fmt.moedaCurta(b.aReceber)}',
                  child: Container(
                    height: math.max(hPend - 4, 3),
                    decoration: BoxDecoration(
                      color: AppColors.lavandaClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (hPend > 0 && hRec > 0) const SizedBox(height: 4),
              if (hRec > 0)
                Tooltip(
                  message: 'Recebido: ${Fmt.moedaCurta(b.recebido)}',
                  child: Container(
                    height: hRec,
                    decoration: BoxDecoration(
                      color: AppColors.oliva,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
