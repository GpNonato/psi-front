import 'package:flutter/material.dart';

import '../data/models.dart';
import '../formatters.dart';
import '../theme.dart';

/// Faixa com os sete dias da semana (Seg 21 ... Dom 27).
class FaixaSemana extends StatelessWidget {
  const FaixaSemana({
    super.key,
    required this.segunda,
    required this.selecionado,
    required this.onSelecionar,
    required this.habilitado,
    this.marcador,
    this.cor = AppColors.oliva,
    this.altura = 62,
  });

  final DateTime segunda;
  final DateTime? selecionado;
  final ValueChanged<DateTime> onSelecionar;
  final bool Function(DateTime dia) habilitado;

  /// Mostra um ponto embaixo do dia (ex.: dias com consultas).
  final bool Function(DateTime dia)? marcador;
  final Color cor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 6 ? 6 : 0),
              child: _dia(maisDias(segunda, i)),
            ),
          ),
      ],
    );
  }

  Widget _dia(DateTime d) {
    final sel = selecionado != null && mesmoDia(d, selecionado!);
    final hab = habilitado(d);
    final corTexto = sel
        ? Colors.white
        : hab
            ? AppColors.texto
            : AppColors.textoFraco;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: sel
            ? cor
            : hab
                ? AppColors.borda
                : Colors.transparent,
      ),
    );
    final temMarca = marcador != null && marcador!(d);
    return Semantics(
      button: true,
      enabled: hab,
      selected: sel,
      label: Fmt.dataLonga(d),
      excludeSemantics: true,
      child: Material(
        color: sel
            ? cor
            : hab
                ? Colors.white
                : const Color(0xFFEFEEE6),
        shape: forma,
        child: InkWell(
          onTap: hab ? () => onSelecionar(d) : null,
          customBorder: forma,
          child: SizedBox(
            height: altura,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Fmt.diaCurtoSemana(d.weekday),
                  style: TextStyle(fontSize: 12, color: corTexto),
                ),
                const SizedBox(height: 2),
                Text('${d.day}',
                    style: TextStyle(fontSize: 18, color: corTexto)),
                if (marcador != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: temMarca
                          ? (sel ? Colors.white : AppColors.oliva)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grade de horários de um dia. Horários ocupados aparecem riscados.
class GradeHorarios extends StatelessWidget {
  const GradeHorarios({
    super.key,
    required this.horarios,
    required this.selecionado,
    required this.onSelecionar,
    this.colunas = 3,
    this.cor = AppColors.oliva,
    this.vazio = 'Sem horários livres neste dia.',
  });

  final List<Horario> horarios;
  final DateTime? selecionado;
  final ValueChanged<DateTime>? onSelecionar;
  final int colunas;
  final Color cor;
  final String vazio;

  @override
  Widget build(BuildContext context) {
    if (horarios.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(vazio, style: AppText.pequeno),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        const espaco = 10.0;
        final largura = (c.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final h in horarios) SizedBox(width: largura, child: _slot(h)),
          ],
        );
      },
    );
  }

  Widget _slot(Horario h) {
    final texto = Fmt.hora(h.inicio);
    if (h.ocupado) {
      return Semantics(
        label: '$texto, ocupado',
        excludeSemantics: true,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEEE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 14.5,
              color: AppColors.textoFraco,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textoFraco,
            ),
          ),
        ),
      );
    }
    final sel = selecionado != null && h.inicio == selecionado;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: sel ? cor : AppColors.borda),
    );
    return Semantics(
      button: true,
      selected: sel,
      label: '$texto, livre',
      excludeSemantics: true,
      child: Material(
        color: sel ? cor : Colors.white,
        shape: forma,
        child: InkWell(
          customBorder: forma,
          onTap: onSelecionar == null ? null : () => onSelecionar!(h.inicio),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14.5,
                  color: sel ? Colors.white : AppColors.texto,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado de escolha de horário compartilhado entre o perfil, a remarcação e
/// o agendamento feito pelo psicólogo.
class EscolhaHorario {
  EscolhaHorario(
      {required this.semana, this.dia, this.horario, required this.modalidade});

  DateTime semana;
  DateTime? dia;
  DateTime? horario;
  Modalidade modalidade;
}
