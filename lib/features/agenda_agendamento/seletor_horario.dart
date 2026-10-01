import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Primeira escolha de horário: o primeiro horário livre do psicólogo.
EscolhaHorario escolhaInicial(AppStore store, Psicologo p,
    {Modalidade? modalidade}) {
  final proximo = store.proximoHorario(p);
  final base = proximo ?? store.agora;
  final m = modalidade != null && p.modalidades.contains(modalidade)
      ? modalidade
      : (p.modalidades.contains(Modalidade.online)
          ? Modalidade.online
          : Modalidade.presencial);
  return EscolhaHorario(
    semana: inicioDaSemana(base),
    dia: proximo == null ? null : soDia(proximo),
    horario: proximo,
    modalidade: m,
  );
}

/// Escolha de modalidade, semana, dia e horário (perfil do psicólogo,
/// remarcação e agendamento feito pelo próprio psicólogo).
class SeletorHorario extends StatelessWidget {
  const SeletorHorario({
    super.key,
    required this.psicologo,
    required this.escolha,
    required this.onChanged,
    this.mostrarModalidade = true,
    this.cor = AppColors.oliva,
    this.ignorarConsultaId,
    this.colunas = 3,
  });

  final Psicologo psicologo;
  final EscolhaHorario escolha;
  final VoidCallback onChanged;
  final bool mostrarModalidade;
  final Color cor;
  final String? ignorarConsultaId;
  final int colunas;

  List<Horario> _horarios(AppStore store, DateTime dia) => store.horariosDoDia(
        psicologo,
        dia,
        ignorarConsultaId: ignorarConsultaId,
      );

  void _mudarSemana(AppStore store, int dias) {
    escolha.semana = maisDias(escolha.semana, dias);
    escolha.horario = null;
    escolha.dia = null;
    for (var i = 0; i < 7; i++) {
      final d = maisDias(escolha.semana, i);
      if (_horarios(store, d).isNotEmpty) {
        escolha.dia = d;
        break;
      }
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final dia = escolha.dia;
    final horarios = dia == null ? const <Horario>[] : _horarios(store, dia);
    final podeVoltar = escolha.semana.isAfter(inicioDaSemana(store.agora));
    final modalidades =
        Modalidade.values.where(psicologo.modalidades.contains).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mostrarModalidade && modalidades.length > 1) ...[
          SegmentoPill<Modalidade>(
            opcoes: modalidades,
            valor: escolha.modalidade,
            rotulo: (m) => m.rotulo,
            onChanged: (m) {
              escolha.modalidade = m;
              onChanged();
            },
          ),
          const SizedBox(height: 22),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                Fmt.mesAno(dia ?? escolha.semana),
                style: const TextStyle(fontSize: 15.5, color: AppColors.texto),
              ),
            ),
            IconButton(
              tooltip: 'Semana anterior',
              visualDensity: VisualDensity.compact,
              onPressed: podeVoltar ? () => _mudarSemana(store, -7) : null,
              icon: const Icone(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Próxima semana',
              visualDensity: VisualDensity.compact,
              onPressed: () => _mudarSemana(store, 7),
              icon: const Icone(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FaixaSemana(
          segunda: escolha.semana,
          selecionado: dia,
          cor: cor,
          habilitado: (d) => _horarios(store, d).isNotEmpty,
          onSelecionar: (d) {
            escolha.dia = d;
            escolha.horario = null;
            onChanged();
          },
        ),
        const SizedBox(height: 20),
        if (dia != null) ...[
          Text(
            'Horários livres ${Fmt.naDia(dia)}',
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 12),
          GradeHorarios(
            horarios: horarios,
            selecionado: escolha.horario,
            colunas: colunas,
            cor: cor,
            onSelecionar: (h) {
              escolha.horario = h;
              onChanged();
            },
          ),
        ] else
          const Text(
            'Sem horários livres nesta semana. Veja a próxima.',
            style: AppText.pequeno,
          ),
      ],
    );
  }
}

/// Resumo do horário escolhido ("Qui, 24 set · 14:30 às 15:20 · Online").
String resumoEscolha(EscolhaHorario e, int duracao) {
  final h = e.horario;
  if (h == null) return 'Escolha um dia e um horário';
  return '${Fmt.diaCurto(h)} · ${Fmt.intervalo(h, duracao)} · ${e.modalidade.rotulo}';
}
