import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'avaliar_consulta.dart';
import 'remarcar_consulta.dart';

/// Minhas consultas do paciente (wireframe 05).
class MinhasConsultasScreen extends StatelessWidget {
  const MinhasConsultasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final agora = store.agora;
    final todas = store.minhasConsultas;
    final proximas = todas.where((c) => c.proxima(agora)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final anteriores = todas.where((c) => c.realizada(agora)).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));
    final canceladas = todas.where((c) => c.cancelada).toList()
      ..sort((a, b) => b.inicio.compareTo(a.inicio));
    final wide = context.isWide;
    final tituloSecao = wide ? 24.0 : 22.0;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: wide ? 40 : 20),
        Semantics(
          header: true,
          child: Text('Minhas consultas', style: AppText.serif(wide ? 34 : 28)),
        ),
        SizedBox(height: wide ? 26 : 14),
        Text('Próximas', style: AppText.serif(tituloSecao)),
        const SizedBox(height: 14),
        if (proximas.isEmpty)
          CartaoApp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Você não tem consultas marcadas.',
                    style: AppText.corpo),
                const SizedBox(height: 12),
                BotaoPill(
                  'Buscar psicólogos',
                  compacto: true,
                  onPressed: () => irPara(context, Rotas.buscar),
                ),
              ],
            ),
          ),
        for (final c in proximas)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CartaoConsulta(consulta: c),
          ),
        if (wide || proximas.isNotEmpty)
          const AvisoLavanda(
            'Você recebe um lembrete 30 minutos antes de cada consulta.',
            icone: Icons.notifications_none_rounded,
          ),
        SizedBox(height: wide ? 40 : 28),
        Text('Anteriores', style: AppText.serif(tituloSecao)),
        const SizedBox(height: 14),
        if (anteriores.isEmpty)
          const CartaoApp(
              child: Text('Nenhuma consulta realizada ainda.',
                  style: AppText.corpo)),
        for (final c in anteriores)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CartaoConsulta(consulta: c),
          ),
        if (canceladas.isNotEmpty) ...[
          SizedBox(height: wide ? 24 : 12),
          Text('Canceladas', style: AppText.serif(tituloSecao)),
          const SizedBox(height: 14),
          for (final c in canceladas)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CartaoConsulta(consulta: c),
            ),
        ],
        const SizedBox(height: 40),
      ],
    );

    return PacienteShell(
      secao: SecaoPaciente.consultas,
      child: wide
          ? ConteudoComRodape(larguraMax: 1024, child: conteudo)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: conteudo,
            ),
    );
  }
}

enum _Situacao { proxima, realizada, avaliada, cancelada }

class _CartaoConsulta extends StatelessWidget {
  const _CartaoConsulta({required this.consulta});

  final Consulta consulta;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = consulta;
    final p = store.psicologo(c.psicologoId);
    final wide = context.isWide;
    final situacao = c.cancelada
        ? _Situacao.cancelada
        : c.proxima(store.agora)
            ? _Situacao.proxima
            : (c.avaliacao != null ? _Situacao.avaliada : _Situacao.realizada);

    final status = switch (situacao) {
      _Situacao.proxima => const StatusPonto('Confirmada'),
      _Situacao.realizada => const SoftChip(
          'Realizada',
          fundo: Color(0xFFEFEEE6),
          cor: AppColors.textoSecundario,
        ),
      _Situacao.avaliada => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SoftChip('Avaliada',
                fundo: Color(0xFFEFEEE6), cor: AppColors.textoSecundario),
            const SizedBox(width: 10),
            Estrelas(c.avaliacao!, tamanho: 15),
          ],
        ),
      _Situacao.cancelada => const SoftChip(
          'Cancelada',
          fundo: Color(0xFFF7E4E1),
          cor: AppColors.vermelho,
        ),
    };

    void agendarDeNovo() =>
        abrirTela<void>(context, Rotas.perfilPsicologo(p.id));
    final acoes = <Widget>[
      if (situacao == _Situacao.proxima) ...[
        BotaoPill(
          'Remarcar',
          estilo: EstiloBotao.contorno,
          compacto: !wide,
          onPressed: () => remarcarConsulta(context, c),
        ),
        BotaoPill(
          'Cancelar',
          estilo: EstiloBotao.perigo,
          compacto: !wide,
          onPressed: () => _cancelar(context, c, p),
        ),
      ] else ...[
        BotaoPill(
          'Agendar de novo',
          estilo: EstiloBotao.contorno,
          compacto: !wide,
          onPressed: agendarDeNovo,
        ),
        if (situacao == _Situacao.realizada)
          BotaoPill('Avaliar',
              compacto: !wide, onPressed: () => avaliarConsulta(context, c)),
      ],
    ];

    final horario = wide
        ? '${Fmt.intervalo(c.inicio, c.duracao)} · ${c.modalidade.rotulo}'
        : '${Fmt.hora(c.inicio)} · ${c.modalidade.rotulo}';
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(p.nome, style: AppText.serif(wide ? 21 : 20)),
        const SizedBox(height: 4),
        Text(horario,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textoSecundario)),
        const SizedBox(height: 8),
        status,
      ],
    );
    final data = _BlocoData(
      data: c.inicio,
      destaque: situacao == _Situacao.proxima,
      compacto: !wide,
    );

    if (wide) {
      return CartaoApp(
        child: Row(
          children: [
            data,
            const SizedBox(width: 24),
            Expanded(child: info),
            for (var i = 0; i < acoes.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              acoes[i],
            ],
          ],
        ),
      );
    }
    return CartaoApp(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [data, const SizedBox(width: 16), Expanded(child: info)],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < acoes.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: acoes[i]),
              ],
              if (acoes.length == 1) const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelar(BuildContext context, Consulta c, Psicologo p) async {
    final ok = await pedirConfirmacao(
      context,
      titulo: 'Cancelar consulta?',
      mensagem:
          'A consulta de ${Fmt.diaCurto(c.inicio)} às ${Fmt.hora(c.inicio)} com '
          '${p.nome} será cancelada e o horário fica livre para outros pacientes.',
      rotuloConfirmar: 'Cancelar consulta',
      rotuloVoltar: 'Manter',
      perigo: true,
    );
    if (!ok || !context.mounted) return;
    context.acoes.cancelarConsulta(c.id, peloPaciente: true);
    avisar(context, 'Consulta cancelada. O horário foi liberado.');
  }
}

class _BlocoData extends StatelessWidget {
  const _BlocoData(
      {required this.data, required this.destaque, required this.compacto});

  final DateTime data;
  final bool destaque;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? AppColors.olivaEscuro : AppColors.textoSecundario;
    return Semantics(
      label: Fmt.dataLonga(data),
      excludeSemantics: true,
      child: Container(
        width: compacto ? 64 : 80,
        height: compacto ? 72 : 88,
        decoration: BoxDecoration(
          color: destaque ? AppColors.salvia : const Color(0xFFF1F0EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(Fmt.diaCurtoSemana(data.weekday),
                style: TextStyle(fontSize: 12.5, color: cor)),
            Text('${data.day}',
                style:
                    AppText.serif(compacto ? 26 : 30, cor: cor, altura: 1.05)),
            Text(Fmt.mesCurto(data.month),
                style: TextStyle(fontSize: 12, color: cor)),
          ],
        ),
      ),
    );
  }
}
