import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'detalhe_consulta.dart';

/// Faixa de horas da grade: cobre a disponibilidade e as consultas dos dias.
(int, int) faixaDeHoras(
    Iterable<List<Faixa>> faixasPorDia, Iterable<Consulta> consultas) {
  var inicio = 8, fim = 18;
  for (final faixas in faixasPorDia) {
    for (final f in faixas) {
      inicio = math.min(inicio, f.inicio ~/ 60);
    }
  }
  for (final c in consultas) {
    inicio = math.min(inicio, c.inicio.hour);
    fim = math.max(fim, c.fim.hour + (c.fim.minute > 0 ? 1 : 0));
  }
  return (inicio.clamp(6, 12), fim.clamp(14, 23));
}

/// Intervalos entre as faixas de atendimento de um dia (ex.: almoço).
List<(int, int)> intervalosEntre(List<Faixa> faixas) {
  final ordenadas = [...faixas]..sort((a, b) => a.inicio.compareTo(b.inicio));
  return [
    for (var i = 1; i < ordenadas.length; i++)
      if (ordenadas[i].inicio > ordenadas[i - 1].fim)
        (ordenadas[i - 1].fim, ordenadas[i].inicio),
  ];
}

int minutosDoDia(DateTime d) => d.hour * 60 + d.minute;

/// Tira dos períodos sem atendimento os horários das consultas. Mudar a
/// disponibilidade não cancela o que já foi marcado (wireframe 10), então uma
/// consulta pode cair fora das faixas atuais e o bloco cinza não pode ficar
/// por baixo dela.
List<(int, int)> descontarConsultas(
    List<(int, int)> periodos, Iterable<Consulta> consultas) {
  var r = periodos;
  for (final c in consultas) {
    final a = minutosDoDia(c.inicio), b = minutosDoDia(c.fim);
    r = [
      for (final (x, y) in r)
        if (b <= x || a >= y)
          (x, y)
        else ...[
          if (a > x) (x, a),
          if (b < y) (b, y),
        ],
    ];
  }
  // Sobras muito curtas viram só ruído visual.
  return [
    for (final (x, y) in r)
      if (y - x >= 15) (x, y)
  ];
}

/// Agenda do psicólogo (wireframe 09).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _dia = soDia(context.acoes.agora);
  bool _semana = true;

  @override
  Widget build(BuildContext context) {
    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.agenda,
      child: context.isWide ? _web(context) : _mobile(context),
    );
  }

  ItemGrade _itemConsulta(Consulta c, int coluna,
      {bool mobile = false, bool proxima = false}) {
    final tipo = c.cancelada
        ? TipoBloco.cancelada
        : (c.nova ? TipoBloco.nova : TipoBloco.consulta);
    final nome = nomeAbreviado(c.pacienteNome);
    final quando = '${Fmt.hora(c.inicio)} · ${c.modalidade.rotulo}';
    return ItemGrade(
      coluna: coluna,
      inicio: minutosDoDia(c.inicio),
      fim: minutosDoDia(c.fim),
      tipo: tipo,
      titulo: mobile && proxima
          ? '$nome · Próxima'
          : (mobile && c.nova ? '$nome · Nova' : nome),
      subtitulo: c.cancelada ? 'Cancelada' : quando,
      extra: c.nova && !c.cancelada ? 'Nova' : null,
      direita: c.cancelada ? 'Cancelada' : quando,
      onTap: () => abrirDetalheConsulta(context, c),
    );
  }

  // ---------------------------------------------------------------- web

  Widget _web(BuildContext context) {
    final store = context.store;
    final p = store.psicologoAtual;
    final agora = store.agora;
    final segunda = inicioDaSemana(_dia);
    final dias =
        _semana ? [for (var i = 0; i < 7; i++) maisDias(segunda, i)] : [_dia];
    final consultasPorDia = [
      for (final d in dias) store.consultasNoDia(p.id, d)
    ];
    final faixasPorDia = [
      for (final d in dias) p.disponibilidade.faixasDoDia(d.weekday)
    ];
    final (hIni, hFim) =
        faixaDeHoras(faixasPorDia, consultasPorDia.expand((l) => l));

    final itens = <ItemGrade>[];
    final bloqueadas = <int, String>{};
    for (var col = 0; col < dias.length; col++) {
      final d = dias[col];
      final bloqueio = p.disponibilidade.bloqueioEm(d);
      if (bloqueio != null) {
        bloqueadas[col] = 'Bloqueado\n${bloqueio.motivo}';
      } else if (faixasPorDia[col].isEmpty) {
        bloqueadas[col] = 'Indisponível';
      } else {
        for (final (a, b) in descontarConsultas(
            intervalosEntre(faixasPorDia[col]), consultasPorDia[col])) {
          itens.add(ItemGrade(
              coluna: col,
              inicio: a,
              fim: b,
              tipo: TipoBloco.intervalo,
              titulo: 'Intervalo'));
        }
      }
      for (final c in consultasPorDia[col]) {
        itens.add(_itemConsulta(c, col));
      }
    }
    final colunaHoje = dias.indexWhere((d) => mesmoDia(d, agora));

    final titulo = _semana
        ? Fmt.semana(segunda)
        : '${Fmt.dataLonga(_dia)} de ${_dia.year}';
    final cabecalho = Row(
      children: [
        Semantics(
            header: true, child: Text('Agenda', style: AppText.serif(32))),
        const SizedBox(width: 36),
        IconButton(
          tooltip: _semana ? 'Semana anterior' : 'Dia anterior',
          onPressed: () =>
              setState(() => _dia = maisDias(_dia, _semana ? -7 : -1)),
          icon: const Icone(Icons.chevron_left_rounded),
        ),
        Flexible(
          child: Text(
            titulo,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, color: AppColors.texto),
          ),
        ),
        IconButton(
          tooltip: _semana ? 'Próxima semana' : 'Próximo dia',
          onPressed: () =>
              setState(() => _dia = maisDias(_dia, _semana ? 7 : 1)),
          icon: const Icone(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 12),
        BotaoPill(
          'Hoje',
          estilo: EstiloBotao.contorno,
          compacto: true,
          onPressed: () => setState(() => _dia = soDia(agora)),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 220,
          child: SegmentoPill<bool>(
            opcoes: const [false, true],
            valor: _semana,
            altura: 40,
            fundo: Colors.transparent,
            rotulo: (s) => s ? 'Semana' : 'Dia',
            onChanged: (s) => setState(() => _semana = s),
          ),
        ),
        const Spacer(),
        const BotaoNotificacoes(papel: Papel.psicologo, tamanho: 32),
        fotoDoPsicologo(p, 36),
      ],
    );

    final grade = CartaoApp(
      padding: EdgeInsets.zero,
      child: GradeHoraria(
        cabecalhos: [
          for (final d in dias)
            _CabecalhoDia(
              dia: d,
              hoje: mesmoDia(d, agora),
              onTap: _semana
                  ? () => setState(() {
                        _dia = d;
                        _semana = false;
                      })
                  : null,
            ),
        ],
        itens: itens,
        horaInicio: hIni,
        horaFim: hFim,
        colunaAgora: colunaHoje >= 0 ? colunaHoje : null,
        minutoAgora: minutosDoDia(agora),
        colunasBloqueadas: bloqueadas,
        larguraMinColuna: _semana ? 100 : 300,
        // 80 px por hora, como no wireframe 09 (08:00 a 18:00 cabem na tela).
        alturaHora: 80,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cabecalho,
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 1080) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: grade),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 296,
                      // A grade tem 96 px de cabeçalho e 80 px por hora; o
                      // cartão "Hoje" e o espaço somam 158 px.
                      child: _ColunaLateral(
                          alturaMinimaNotificacoes:
                              96 + 80.0 * (hFim - hIni) - 158),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  grade,
                  const SizedBox(height: 24),
                  const _ColunaLateral()
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- celular

  Widget _mobile(BuildContext context) {
    final store = context.store;
    final p = store.psicologoAtual;
    final agora = store.agora;
    final consultas = store.consultasNoDia(p.id, _dia);
    final faixas = p.disponibilidade.faixasDoDia(_dia.weekday);
    final (hIni, hFim) = faixaDeHoras([faixas], consultas);
    final ativas = consultas.where((c) => !c.cancelada).toList();
    final proxima = ativas.where((c) => c.inicio.isAfter(agora)).firstOrNull;
    final itens = <ItemGrade>[
      for (final (a, b)
          in descontarConsultas(intervalosEntre(faixas), consultas))
        ItemGrade(
          coluna: 0,
          inicio: a,
          fim: b,
          tipo: TipoBloco.intervalo,
          titulo: 'Intervalo',
          direita: '${Fmt.minutos(a)} – ${Fmt.minutos(b)}',
        ),
      for (final c in consultas)
        _itemConsulta(c, 0,
            mobile: true, proxima: mesmoDia(_dia, agora) && c == proxima),
    ];
    Notificacao? aviso;
    for (final n in store.notificacoes(Papel.psicologo)) {
      if (!n.lida && n.tipo == TipoNotificacao.nova) {
        aviso = n;
        break;
      }
    }
    final bloqueio = p.disponibilidade.bloqueioEm(_dia);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
                child: Semantics(
                    header: true,
                    child: Text('Agenda', style: AppText.serif(28)))),
            const BotaoNotificacoes(papel: Papel.psicologo),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                Fmt.mesAno(_dia),
                style: const TextStyle(
                    fontSize: 14.5, color: AppColors.textoSecundario),
              ),
            ),
            IconButton(
              tooltip: 'Semana anterior',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _dia = maisDias(_dia, -7)),
              icon: const Icone(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Próxima semana',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _dia = maisDias(_dia, 7)),
              icon: const Icone(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FaixaSemana(
          segunda: inicioDaSemana(_dia),
          selecionado: _dia,
          habilitado: (d) =>
              p.disponibilidade.faixasDoDia(d.weekday).isNotEmpty ||
              store.consultasNoDia(p.id, d).isNotEmpty,
          marcador: (d) =>
              store.consultasNoDia(p.id, d).any((c) => !c.cancelada),
          onSelecionar: (d) => setState(() => _dia = d),
        ),
        const SizedBox(height: 14),
        if (aviso != null) ...[
          _AvisoNotificacao(notificacao: aviso),
          const SizedBox(height: 14),
        ],
        Text(
          '${Fmt.relativo(_dia, agora)} · ${Fmt.plural(ativas.length, 'consulta', 'consultas')}',
          style: const TextStyle(fontSize: 16, color: AppColors.texto),
        ),
        const SizedBox(height: 14),
        if (bloqueio != null)
          CartaoApp(
              child: Text('Dia bloqueado: ${bloqueio.motivo}.',
                  style: AppText.corpo))
        else if (faixas.isEmpty && consultas.isEmpty)
          const CartaoApp(
              child: Text('Você não atende neste dia.', style: AppText.corpo))
        else
          LinhaDoTempoDia(
            itens: itens,
            horaInicio: hIni,
            horaFim: hFim,
            minutoAgora: mesmoDia(_dia, agora) ? minutosDoDia(agora) : null,
          ),
      ],
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  const _CabecalhoDia({required this.dia, required this.hoje, this.onTap});

  final DateTime dia;
  final bool hoje;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${Fmt.dataLonga(dia)}${hoje ? ', hoje' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Fmt.diaCurtoSemana(dia.weekday),
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: hoje
                  ? const BoxDecoration(
                      color: AppColors.oliva, shape: BoxShape.circle)
                  : null,
              child: Text(
                '${dia.day}',
                style: TextStyle(
                    fontSize: 16.5,
                    color: hoje ? Colors.white : AppColors.texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColunaLateral extends StatelessWidget {
  const _ColunaLateral({this.alturaMinimaNotificacoes = 0});

  /// Altura mínima do cartão de notificações (para terminar junto com a grade).
  final double alturaMinimaNotificacoes;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = store.psicologoAtual;
    final agora = store.agora;
    final hoje =
        store.consultasNoDia(p.id, agora).where((c) => !c.cancelada).toList();
    final proxima = hoje.where((c) => c.inicio.isAfter(agora)).firstOrNull;
    final notificacoes = store.notificacoes(Papel.psicologo);
    final destaque = store.destaquePsicologo;
    final plano = planosPsicologo.firstWhere((pl) => pl.id == destaque.planoId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.salvia,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hoje',
                  style: TextStyle(fontSize: 13.5, color: AppColors.texto)),
              const SizedBox(height: 6),
              Text(Fmt.plural(hoje.length, 'consulta', 'consultas'),
                  style: AppText.serif(28)),
              const SizedBox(height: 10),
              Text(
                proxima == null
                    ? 'Sem mais consultas hoje'
                    : 'Próxima: ${nomeAbreviado(proxima.pacienteNome)} às ${Fmt.hora(proxima.inicio)}',
                style: const TextStyle(fontSize: 14.5, color: AppColors.texto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // No wireframe 09 o cartão vai até o fim da grade, com "Ver todas" no
        // rodapé.
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: alturaMinimaNotificacoes),
          child: CartaoApp(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _notificacoesEDestaque(
                    context, notificacoes, agora, destaque, plano),
                Center(
                  child: LinkTexto(
                    'Ver todas',
                    onTap: () => abrirNotificacoes(context, Papel.psicologo),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificacoesEDestaque(
      BuildContext context,
      List<Notificacao> notificacoes,
      DateTime agora,
      EstadoDestaque destaque,
      Plano plano) {
    final store = context.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text('Notificações',
                    style: TextStyle(fontSize: 19, color: AppColors.texto)),
              ),
              LinkTexto(
                'Marcar como lidas',
                tamanho: 13,
                onTap: store.naoLidas(Papel.psicologo) == 0
                    ? null
                    : () => context.acoes.marcarLidas(Papel.psicologo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final n in notificacoes.take(4)) ItemNotificacao(n, agora: agora),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.lavandaClaro,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: destaque.ativo(agora)
                ? [
                    const Row(
                      children: [
                        Icone(Icons.star_outline_rounded,
                            size: 20, color: AppColors.lavanda),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seu perfil está em destaque',
                            style: TextStyle(
                                fontSize: 14.5, color: AppColors.lavandaEscuro),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Termina em ${destaque.fim!.difference(agora).inHours} h · '
                      '${destaque.usadosNoMes} de ${plano.destaquesPorMes} destaques do plano '
                      'usados neste mês.',
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.lavandaEscuro),
                    ),
                    const SizedBox(height: 12),
                    BarraProgresso(
                      valor: plano.destaquesPorMes == 0
                          ? 1
                          : destaque.usadosNoMes / plano.destaquesPorMes,
                      cor: AppColors.lavanda,
                      fundo: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    BotaoPill(
                      'Ver desempenho',
                      estilo: EstiloBotao.contornoLavanda,
                      compacto: true,
                      onPressed: () => irPara(context, Rotas.destaque),
                    ),
                  ]
                : [
                    const Text(
                      'Seu perfil não está em destaque',
                      style: TextStyle(
                          fontSize: 14.5, color: AppColors.lavandaEscuro),
                    ),
                    const SizedBox(height: 12),
                    BotaoPill(
                      'Comprar destaque',
                      estilo: EstiloBotao.contornoLavanda,
                      compacto: true,
                      onPressed: () => irPara(context, Rotas.destaque),
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AvisoNotificacao extends StatelessWidget {
  const _AvisoNotificacao({required this.notificacao});

  final Notificacao notificacao;

  @override
  Widget build(BuildContext context) {
    final n = notificacao;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: corDaNotificacao(n.tipo), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.titulo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F5A40),
                  ),
                ),
                Text(n.detalhe,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF1F5A40))),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dispensar aviso',
            onPressed: () => context.acoes.marcarLida(n),
            icon: const Icone(Icons.close_rounded,
                size: 20, color: Color(0xFF1F5A40)),
          ),
        ],
      ),
    );
  }
}
