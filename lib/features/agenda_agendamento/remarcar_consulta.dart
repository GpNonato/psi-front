import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'seletor_horario.dart';

/// Remarcação: escolhe outro horário do mesmo psicólogo. A consulta original é
/// cancelada e a nova é criada de uma vez só.
Future<void> remarcarConsulta(BuildContext context, Consulta consulta) {
  return abrirPainel<void>(
    context,
    larguraMax: 520,
    builder: (_) => _RemarcarConsulta(consulta: consulta),
  );
}

class _RemarcarConsulta extends StatefulWidget {
  const _RemarcarConsulta({required this.consulta});

  final Consulta consulta;

  @override
  State<_RemarcarConsulta> createState() => _RemarcarConsultaState();
}

class _RemarcarConsultaState extends State<_RemarcarConsulta> {
  late final EscolhaHorario _escolha;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final store = context.acoes;
    final p = store.psicologo(widget.consulta.psicologoId);
    _escolha = escolhaInicial(store, p, modalidade: widget.consulta.modalidade);
  }

  void _confirmar() {
    final h = _escolha.horario;
    if (h == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final nova =
          context.acoes.remarcar(widget.consulta.id, h, _escolha.modalidade);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Consulta remarcada para ${Fmt.diaCurto(nova.inicio)} · ${Fmt.hora(nova.inicio)}.',
            ),
          ),
        );
    } on ErroAgendamento catch (e) {
      setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = widget.consulta;
    final p = store.psicologo(c.psicologoId);
    return PainelConteudo(
      titulo: 'Remarcar consulta',
      subtitulo:
          'Atual: ${Fmt.diaCurto(c.inicio)} · ${Fmt.hora(c.inicio)} com ${p.nome}',
      acoes: AcoesPainel(
        primario: 'Confirmar remarcação',
        onPrimario: _escolha.horario == null ? null : _confirmar,
        secundario: 'Voltar',
      ),
      children: [
        SeletorHorario(
          psicologo: p,
          escolha: _escolha,
          ignorarConsultaId: c.id,
          onChanged: () => setState(() => _erro = null),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.salvia,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            resumoEscolha(_escolha, c.duracao),
            style: const TextStyle(fontSize: 14.5),
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 10),
          Text(_erro!, style: const TextStyle(color: AppColors.vermelho)),
        ],
      ],
    );
  }
}
