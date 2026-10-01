import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Detalhes de uma consulta na agenda do psicólogo.
Future<void> abrirDetalheConsulta(BuildContext context, Consulta consulta) {
  context.acoes.marcarVista(consulta);
  return abrirPainel<void>(
    context,
    larguraMax: 480,
    builder: (_) => _DetalheConsulta(consulta: consulta),
  );
}

class _DetalheConsulta extends StatelessWidget {
  const _DetalheConsulta({required this.consulta});

  final Consulta consulta;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = consulta;
    final paciente = store.pacienteOuNulo(c.pacienteId);
    final (status, cor) = c.cancelada
        ? ('Cancelada', AppColors.vermelho)
        : c.realizada(store.agora)
            ? ('Realizada', AppColors.textoSecundario)
            : ('Confirmada', AppColors.verde);
    Widget linha(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icone(i, size: 18, color: AppColors.textoSecundario),
              const SizedBox(width: 12),
              Expanded(child: Text(t, style: const TextStyle(fontSize: 15))),
            ],
          ),
        );
    final podeCancelar = c.proxima(store.agora);
    return PainelConteudo(
      titulo: c.pacienteNome,
      acoes: Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (podeCancelar)
            BotaoPill(
              'Cancelar consulta',
              estilo: EstiloBotao.perigo,
              compacto: true,
              onPressed: () async {
                final ok = await pedirConfirmacao(
                  context,
                  titulo: 'Cancelar consulta?',
                  mensagem:
                      'O paciente é avisado e o horário fica livre na sua agenda.',
                  rotuloConfirmar: 'Cancelar consulta',
                  rotuloVoltar: 'Manter',
                  perigo: true,
                );
                if (!ok || !context.mounted) return;
                context.acoes.cancelarConsulta(c.id, peloPaciente: false);
                Navigator.of(context).pop();
              },
            ),
          if (paciente != null)
            BotaoPill(
              'Abrir ficha',
              compacto: true,
              onPressed: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.pushNamed(Rotas.ficha(paciente.id));
              },
            ),
        ],
      ),
      children: [
        StatusPonto(status, cor: cor),
        const SizedBox(height: 16),
        linha(Icons.calendar_today_outlined, Fmt.dataLonga(c.inicio)),
        linha(Icons.schedule_rounded,
            '${Fmt.intervalo(c.inicio, c.duracao)} · ${c.duracao} min'),
        linha(
          c.modalidade == Modalidade.online
              ? Icons.videocam_outlined
              : Icons.place_outlined,
          c.modalidade == Modalidade.online
              ? 'Atendimento online'
              : 'Atendimento presencial',
        ),
        if (c.mensagem != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.creme,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('“${c.mensagem}”',
                style: const TextStyle(fontSize: 14.5, height: 1.45)),
          ),
      ],
    );
  }
}
