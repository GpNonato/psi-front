import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../painel_psicologo/agenda_screen.dart'
    show descontarConsultas, faixaDeHoras, minutosDoDia;

/// Períodos sem atendimento dentro da grade (antes, entre e depois das faixas).
List<(int, int)> periodosIndisponiveis(
    List<Faixa> faixas, int horaInicio, int horaFim) {
  final ordenadas = [...faixas]..sort((a, b) => a.inicio.compareTo(b.inicio));
  final r = <(int, int)>[];
  var cursor = horaInicio * 60;
  for (final f in ordenadas) {
    if (f.inicio > cursor) r.add((cursor, f.inicio));
    if (f.fim > cursor) cursor = f.fim;
  }
  if (cursor < horaFim * 60) r.add((cursor, horaFim * 60));
  return r;
}

String naoAtendeEm(int weekday) {
  final nome = Fmt.diaNomeSemana(weekday).toLowerCase();
  return weekday >= 6 ? 'Não atende aos ${nome}s' : 'Não atende às ${nome}s';
}

/// Agenda da equipe, somente leitura e sem nomes de pacientes (wireframe 18).
class AgendaEquipeScreen extends StatefulWidget {
  const AgendaEquipeScreen({super.key});

  @override
  State<AgendaEquipeScreen> createState() => _AgendaEquipeScreenState();
}

class _AgendaEquipeScreenState extends State<AgendaEquipeScreen> {
  late DateTime _dia = soDia(context.acoes.agora);
  String? _selecionado;

  List<Psicologo> _membros(AppStore store) => [
        for (final m in store.equipe)
          if (m.acesso == Acesso.ativo && m.psicologoId != null)
            store.psicologo(m.psicologoId!),
      ];

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final membros = _membros(store);
    return ProShell(
      papel: Papel.clinica,
      rota: Rotas.agendaEquipe,
      child: context.isWide ? _web(store, membros) : _mobile(store, membros),
    );
  }

  List<Consulta> _consultas(AppStore store, Psicologo p) =>
      store.consultasNoDia(p.id, _dia).where((c) => !c.cancelada).toList();

  Widget _navegacao(AppStore store, {required bool compacto}) {
    return Row(
      mainAxisSize: compacto ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (compacto)
          Expanded(
            child: Text(
              '${Fmt.diaCurtoSemana(_dia.weekday)}, ${Fmt.diaMesLongo(_dia)}',
              style: const TextStyle(
                  fontSize: 14.5, color: AppColors.textoSecundario),
            ),
          ),
        IconButton(
          tooltip: 'Dia anterior',
          visualDensity: compacto ? VisualDensity.compact : null,
          onPressed: () => setState(() => _dia = maisDias(_dia, -1)),
          icon: const Icone(Icons.chevron_left_rounded),
        ),
        if (!compacto)
          Text(
            '${Fmt.diaNomeSemana(_dia.weekday)}, ${Fmt.diaMesLongo(_dia)} de ${_dia.year}',
            style: const TextStyle(fontSize: 16),
          ),
        IconButton(
          tooltip: 'Próximo dia',
          visualDensity: compacto ? VisualDensity.compact : null,
          onPressed: () => setState(() => _dia = maisDias(_dia, 1)),
          icon: const Icone(Icons.chevron_right_rounded),
        ),
        if (!compacto) ...[
          const SizedBox(width: 12),
          BotaoPill(
            'Hoje',
            estilo: EstiloBotao.contorno,
            compacto: true,
            onPressed: () => setState(() => _dia = soDia(store.agora)),
          ),
        ],
      ],
    );
  }

  Widget _web(AppStore store, List<Psicologo> membros) {
    final agora = store.agora;
    final faixas = [
      for (final p in membros) p.disponibilidade.faixasDoDia(_dia.weekday)
    ];
    final consultas = [for (final p in membros) _consultas(store, p)];
    final (hIni, hFim) = faixaDeHoras(faixas, consultas.expand((l) => l));
    final itens = <ItemGrade>[];
    final bloqueadas = <int, String>{};
    for (var col = 0; col < membros.length; col++) {
      if (faixas[col].isEmpty ||
          membros[col].disponibilidade.bloqueioEm(_dia) != null) {
        bloqueadas[col] =
            faixas[col].isEmpty ? naoAtendeEm(_dia.weekday) : 'Bloqueio no dia';
        continue;
      }
      for (final (a, b) in descontarConsultas(
          periodosIndisponiveis(faixas[col], hIni, hFim), consultas[col])) {
        itens.add(ItemGrade(
            coluna: col,
            inicio: a,
            fim: b,
            tipo: TipoBloco.indisponivel,
            titulo: 'Indisponível'));
      }
      for (final c in consultas[col]) {
        itens.add(
          ItemGrade(
            coluna: col,
            inicio: minutosDoDia(c.inicio),
            fim: minutosDoDia(c.fim),
            tipo: TipoBloco.consulta,
            titulo: 'Consulta',
            subtitulo: '${Fmt.hora(c.inicio)} · ${c.duracao} min',
          ),
        );
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Em telas estreitas a navegação desce para baixo do título.
          Wrap(
            spacing: 40,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                  header: true,
                  child: Text('Agenda da equipe', style: AppText.serif(32))),
              _navegacao(store, compacto: false),
            ],
          ),
          const SizedBox(height: 20),
          const AvisoLavanda(
            'Somente leitura. Cada psicólogo gerencia a própria agenda; nomes de pacientes não são exibidos.',
          ),
          const SizedBox(height: 20),
          CartaoApp(
            padding: const EdgeInsets.only(bottom: 12),
            child: GradeHoraria(
              cabecalhos: [
                for (var i = 0; i < membros.length; i++)
                  _CabecalhoMembro(
                      psicologo: membros[i], consultas: consultas[i].length),
              ],
              itens: itens,
              horaInicio: hIni,
              horaFim: hFim,
              alturaHora: 74,
              larguraMinColuna: 170,
              colunasBloqueadas: bloqueadas,
              colunaAgora: mesmoDia(_dia, agora) ? 0 : null,
              minutoAgora: minutosDoDia(agora),
              agoraEmTodas: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobile(AppStore store, List<Psicologo> membros) {
    if (membros.isEmpty) {
      return const Center(child: Text('Nenhum psicólogo ativo na equipe.'));
    }
    final agora = store.agora;
    final p = membros.firstWhere((m) => m.id == _selecionado,
        orElse: () => membros.first);
    final faixas = p.disponibilidade.faixasDoDia(_dia.weekday);
    final consultas = _consultas(store, p);
    final (hIni, hFim) = faixaDeHoras([faixas], consultas);
    final itens = <ItemGrade>[
      for (final (a, b) in descontarConsultas(
          periodosIndisponiveis(faixas, hIni, hFim), consultas))
        if (faixas.isNotEmpty)
          ItemGrade(
            coluna: 0,
            inicio: a,
            fim: b,
            tipo: TipoBloco.indisponivel,
            titulo: 'Indisponível',
            direita: '${Fmt.minutos(a)} – ${Fmt.minutos(b)}',
          ),
      for (final c in consultas)
        ItemGrade(
          coluna: 0,
          inicio: minutosDoDia(c.inicio),
          fim: minutosDoDia(c.fim),
          tipo: TipoBloco.consulta,
          titulo: 'Consulta',
          direita: '${Fmt.hora(c.inicio)} · ${c.duracao} min',
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Semantics(
            header: true,
            child: Text('Agenda da equipe', style: AppText.serif(32))),
        _navegacao(store, compacto: true),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final m in membros)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Semantics(
                    button: true,
                    selected: m.id == p.id,
                    label: m.nome,
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selecionado = m.id),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: FormaFolha.raio(52),
                              border: Border.all(
                                color: m.id == p.id
                                    ? AppColors.oliva
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: fotoDoPsicologo(m, 46),
                          ),
                          const SizedBox(height: 4),
                          Text(primeiroNome(m.nome),
                              style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const AvisoLavanda('Somente leitura · sem dados de pacientes',
            compacto: true),
        const SizedBox(height: 16),
        Text(
          '${p.nome} · ${Fmt.plural(consultas.length, 'consulta', 'consultas')}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 14),
        if (faixas.isEmpty)
          CartaoApp(
              child: Text(naoAtendeEm(_dia.weekday), style: AppText.corpo))
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

class _CabecalhoMembro extends StatelessWidget {
  const _CabecalhoMembro({required this.psicologo, required this.consultas});

  final Psicologo psicologo;
  final int consultas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          fotoDoPsicologo(psicologo, 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  psicologo.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  consultas == 0
                      ? 'Sem atendimentos'
                      : Fmt.plural(consultas, 'consulta', 'consultas'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textoSecundario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
