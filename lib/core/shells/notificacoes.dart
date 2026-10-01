import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store_scope.dart';
import '../formatters.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

Color corDaNotificacao(TipoNotificacao tipo) => switch (tipo) {
      TipoNotificacao.nova => AppColors.verde,
      TipoNotificacao.cancelada => AppColors.vermelho,
      TipoNotificacao.lembrete => AppColors.azul,
      TipoNotificacao.remarcada => AppColors.lavanda,
      TipoNotificacao.info => AppColors.lavanda,
    };

/// Item de notificação (consulta marcada, cancelada, lembrete enviado...).
class ItemNotificacao extends StatelessWidget {
  const ItemNotificacao(this.notificacao, {super.key, required this.agora});

  final Notificacao notificacao;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final n = notificacao;
    return Semantics(
      label: '${n.lida ? '' : 'Não lida. '}${n.titulo}. ${n.detalhe}. '
          '${Fmt.tempoRelativo(n.quando, agora)}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: n.lida ? Colors.white : const Color(0xFFF3F2EC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: corDaNotificacao(n.tipo),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.titulo,
                    style:
                        const TextStyle(fontSize: 15, color: AppColors.texto),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.detalhe,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Fmt.tempoRelativo(n.quando, agora),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textoFraco),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sino com indicador de não lidas; abre a lista de notificações.
class BotaoNotificacoes extends StatelessWidget {
  const BotaoNotificacoes({
    super.key,
    required this.papel,
    this.corFundo = Colors.transparent,
    this.tamanho = 40,
  });

  final Papel papel;
  final Color corFundo;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final naoLidas = context.store.naoLidas(papel);
    return BotaoCircular(
      icone: Icons.notifications_none_rounded,
      tooltip: naoLidas == 0
          ? 'Notificações'
          : 'Notificações, ${Fmt.plural(naoLidas, 'não lida', 'não lidas')}',
      cor: corFundo,
      tamanho: tamanho,
      tamanhoIcone: 21,
      corIcone: AppColors.textoSecundario,
      indicador: naoLidas > 0,
      corIndicador:
          papel == Papel.paciente ? AppColors.lavanda : AppColors.vermelho,
      onPressed: () => abrirNotificacoes(context, papel),
    );
  }
}

Future<void> abrirNotificacoes(BuildContext context, Papel papel) {
  return abrirPainel<void>(
    context,
    larguraMax: 480,
    builder: (_) => _PainelNotificacoes(papel: papel),
  );
}

class _PainelNotificacoes extends StatelessWidget {
  const _PainelNotificacoes({required this.papel});

  final Papel papel;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final lista = store.notificacoes(papel);
    return PainelConteudo(
      titulo: 'Notificações',
      subtitulo: papel == Papel.paciente
          ? 'Confirmações, lembretes e avisos das suas consultas'
          : 'Consultas marcadas, canceladas e lembretes enviados',
      acoes: Align(
        alignment: Alignment.centerRight,
        child: BotaoPill(
          'Marcar todas como lidas',
          estilo: EstiloBotao.contorno,
          compacto: true,
          onPressed: store.naoLidas(papel) == 0
              ? null
              : () => context.acoes.marcarLidas(papel),
        ),
      ),
      children: [
        if (lista.isEmpty)
          const Text('Nenhuma notificação por enquanto.',
              style: AppText.pequeno),
        for (final n in lista) ItemNotificacao(n, agora: store.agora),
      ],
    );
  }
}
