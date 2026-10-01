import 'package:flutter/material.dart';

import '../../core/core.dart';

Widget _linhaResumo(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icone(icone, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto,
                style: const TextStyle(fontSize: 15, color: AppColors.texto)),
          ),
        ],
      ),
    );

String _textoModalidade(Psicologo p, Modalidade m) => m == Modalidade.online
    ? 'Atendimento online'
    : 'Atendimento presencial · ${p.endereco}';

/// Painel "Confirmar agendamento" (wireframe 04). Devolve a consulta criada.
Future<Consulta?> confirmarAgendamento(
  BuildContext context, {
  required Psicologo psicologo,
  required DateTime inicio,
  required Modalidade modalidade,
}) {
  return abrirPainel<Consulta>(
    context,
    builder: (_) => _ConfirmarAgendamento(
      psicologo: psicologo,
      inicio: inicio,
      modalidade: modalidade,
    ),
  );
}

class _ConfirmarAgendamento extends StatefulWidget {
  const _ConfirmarAgendamento({
    required this.psicologo,
    required this.inicio,
    required this.modalidade,
  });

  final Psicologo psicologo;
  final DateTime inicio;
  final Modalidade modalidade;

  @override
  State<_ConfirmarAgendamento> createState() => _ConfirmarAgendamentoState();
}

class _ConfirmarAgendamentoState extends State<_ConfirmarAgendamento> {
  final _mensagem = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  void _confirmar() {
    try {
      final c = context.acoes.agendar(
        psicologoId: widget.psicologo.id,
        inicio: widget.inicio,
        modalidade: widget.modalidade,
        mensagem: _mensagem.text,
      );
      Navigator.of(context).pop(c);
    } on ErroAgendamento catch (e) {
      setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.psicologo;
    final duracao = p.disponibilidade.duracao;
    final wide = context.isWide;
    return PainelConteudo(
      titulo: 'Confirmar agendamento',
      acoes: AcoesPainel(
        primario: 'Confirmar agendamento',
        onPrimario: _confirmar,
        secundario: 'Voltar',
        corPrimario: corDoTema(p.temaCor),
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            color: AppColors.creme,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  fotoDoPsicologo(p, 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nome, style: AppText.serif(20)),
                        Text(
                          '${p.titulo} · CRP ${p.crp}',
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _linhaResumo(
                  Icons.calendar_today_outlined, Fmt.dataLonga(widget.inicio)),
              _linhaResumo(
                Icons.schedule_rounded,
                '${Fmt.intervalo(widget.inicio, duracao)} · $duracao min',
              ),
              _linhaResumo(
                widget.modalidade == Modalidade.online
                    ? Icons.videocam_outlined
                    : Icons.place_outlined,
                _textoModalidade(p, widget.modalidade),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Valor da sessão',
                      style: TextStyle(fontSize: 15, color: AppColors.texto)),
                  const SizedBox(height: 2),
                  Text(
                    wide
                        ? 'Pagamento combinado diretamente com ${p.artigo} ${p.profissional}.'
                        : 'Pagamento combinado com ${p.artigo} ${p.profissional}.',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoFraco),
                  ),
                ],
              ),
            ),
            Text(
              Fmt.moeda(p.valorSessao),
              style: const TextStyle(fontSize: 17, color: AppColors.texto),
            ),
          ],
        ),
        // Wireframe 04: no web há o campo de mensagem; no celular, o aviso
        // do lembrete.
        if (wide) ...[
          const SizedBox(height: 20),
          CampoTexto(
            controller: _mensagem,
            rotulo: 'Mensagem para ${p.artigo} ${p.profissional} (opcional)',
            hint: 'Conte brevemente o que te traz à terapia',
            linhas: 2,
            maxLength: 300,
          ),
        ] else ...[
          const SizedBox(height: 16),
          const AvisoLavanda(
            'Lembrete 30 min antes da consulta',
            icone: Icons.notifications_none_rounded,
            compacto: true,
          ),
        ],
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!,
              style: const TextStyle(color: AppColors.vermelho, fontSize: 14)),
        ],
      ],
    );
  }
}

/// Confirmação depois de agendar (visibilidade do estado do sistema).
Future<void> mostrarAgendamentoConfirmado(
  BuildContext context,
  Consulta consulta,
  Psicologo psicologo,
) {
  return abrirPainel<void>(
    context,
    larguraMax: 500,
    builder: (ctx) => PainelConteudo(
      titulo: 'Consulta agendada',
      acoes: AcoesPainel(
        primario: 'Ver minhas consultas',
        onPrimario: () {
          Navigator.of(ctx).pop();
          irPara(context, Rotas.consultas);
        },
        secundario: 'Fechar',
      ),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.verdeClaro,
                shape: BoxShape.circle,
              ),
              child: const Icone(Icons.check_rounded, color: AppColors.verde),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Sua consulta com ${psicologo.nome} está confirmada.',
                style: const TextStyle(fontSize: 16, color: AppColors.texto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _linhaResumo(
            Icons.calendar_today_outlined, Fmt.dataLonga(consulta.inicio)),
        _linhaResumo(
          Icons.schedule_rounded,
          Fmt.intervalo(consulta.inicio, consulta.duracao),
        ),
        _linhaResumo(
          consulta.modalidade == Modalidade.online
              ? Icons.videocam_outlined
              : Icons.place_outlined,
          _textoModalidade(psicologo, consulta.modalidade),
        ),
        const SizedBox(height: 18),
        const AvisoLavanda(
          'Você recebe um lembrete 30 minutos antes. Se precisar, dá para remarcar '
          'ou cancelar em Minhas consultas.',
          icone: Icons.notifications_none_rounded,
        ),
      ],
    ),
  );
}
