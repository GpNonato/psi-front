import 'package:flutter/material.dart';

import '../../core/core.dart';

const _duracoes = [30, 40, 45, 50, 60];
const _intervalos = [0, 5, 10, 15, 20, 30];

/// Disponibilidade semanal (wireframe 10).
class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  State<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
  late Disponibilidade _rascunho =
      context.acoes.psicologoAtual.disponibilidade.copia();
  late DateTime _diaPrevia = _proximaQuinta(context.acoes.agora);
  bool _alterado = false;

  static DateTime _proximaQuinta(DateTime agora) {
    var d = soDia(agora);
    while (d.weekday != DateTime.thursday) {
      d = maisDias(d, 1);
    }
    return d;
  }

  /// "às segundas", "aos sábados" (rótulo dos interruptores de cada dia).
  static String _naSemana(int dia) {
    final nome = Fmt.diaNomeSemana(dia).toLowerCase();
    return dia >= 6 ? 'aos ${nome}s' : 'às ${nome}s';
  }

  void _mudar(VoidCallback f) => setState(() {
        f();
        _alterado = true;
      });

  void _salvar() {
    context.acoes.salvarDisponibilidade(_rascunho);
    setState(() {
      _rascunho = context.acoes.psicologoAtual.disponibilidade.copia();
      _alterado = false;
    });
    avisar(context,
        'Disponibilidade salva. Os pacientes já veem os novos horários.');
  }

  void _alternarDia(int dia, bool ligado) => _mudar(() {
        if (ligado) {
          _rascunho.ativos.add(dia);
          final faixas = _rascunho.faixas[dia] ?? [];
          if (faixas.isEmpty) {
            _rascunho.faixas[dia] = [const Faixa(8 * 60, 12 * 60)];
          }
        } else {
          _rascunho.ativos.remove(dia);
        }
      });

  void _copiarSegunda() {
    final segunda = _rascunho.faixas[DateTime.monday] ?? [];
    _mudar(() {
      for (final d in _rascunho.ativos) {
        if (d != DateTime.monday) _rascunho.faixas[d] = [...segunda];
      }
    });
    avisar(context, 'Horários de segunda copiados para os outros dias ativos.');
  }

  Future<void> _adicionarFaixa(int dia) async {
    final atuais = _rascunho.faixas[dia] ?? [];
    final nova = await abrirPainel<Faixa>(
      context,
      larguraMax: 440,
      builder: (_) => _NovaFaixa(
        dia: dia,
        existentes: atuais,
        duracaoMinima: _rascunho.duracao,
      ),
    );
    if (nova == null) return;
    _mudar(() {
      final lista = [...atuais, nova]
        ..sort((a, b) => a.inicio.compareTo(b.inicio));
      _rascunho.faixas[dia] = lista;
      _rascunho.ativos.add(dia);
    });
  }

  void _removerFaixa(int dia, Faixa f) => _mudar(() {
        final lista = [...?_rascunho.faixas[dia]]..remove(f);
        _rascunho.faixas[dia] = lista;
        if (lista.isEmpty) _rascunho.ativos.remove(dia);
      });

  Future<void> _adicionarBloqueio() async {
    final agora = context.acoes.agora;
    final data = await showDatePicker(
      context: context,
      initialDate: maisDias(agora, 1),
      firstDate: soDia(agora),
      lastDate: maisDias(agora, 365),
      helpText: 'Dia do bloqueio',
    );
    if (data == null || !mounted) return;
    final motivo = await abrirPainel<String>(
      context,
      larguraMax: 440,
      builder: (_) => _MotivoBloqueio(data: data),
    );
    if (motivo == null) return;
    _mudar(() => _rascunho.bloqueios = [
          ..._rascunho.bloqueios,
          Bloqueio(data: data, motivo: motivo),
        ]..sort((a, b) => a.data.compareTo(b.data)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.disponibilidade,
      child: PaginaPro(
        titulo: 'Disponibilidade',
        subtitulo:
            'Pacientes só veem horários livres dentro destes intervalos.',
        acoes: [
          if (_alterado)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SoftChip('Alterações não salvas',
                  fundo: AppColors.lavandaClaro, cor: AppColors.lavandaEscuro),
            ),
          BotaoPill('Salvar alterações', onPressed: _salvar),
        ],
        acoesMobile: const [],
        children: wide ? [_web()] : _mobile(),
      ),
    );
  }

  // ---------------------------------------------------------------- web

  Widget _web() {
    return LayoutBuilder(
      builder: (context, c) {
        final principal = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _cartaoConfiguracao(),
            const SizedBox(height: 24),
            _cartaoSemana(),
            const SizedBox(height: 24),
            _cartaoBloqueios(),
          ],
        );
        if (c.maxWidth < 1040) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [principal, const SizedBox(height: 24), _cartaoPrevia()],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: principal),
            const SizedBox(width: 24),
            SizedBox(width: 344, child: _cartaoPrevia()),
          ],
        );
      },
    );
  }

  Widget _seletorDuracao(
          {String rotulo = 'Duração da sessão', bool curto = false}) =>
      SeletorCaixa<int>(
        rotuloCampo: rotulo,
        valor: _rascunho.duracao,
        opcoes: _duracoes,
        rotulo: (m) => curto ? '$m min' : '$m minutos',
        onChanged: (m) => _mudar(() => _rascunho.duracao = m),
      );

  Widget _seletorIntervalo(
          {String rotulo = 'Intervalo entre sessões', bool curto = false}) =>
      SeletorCaixa<int>(
        rotuloCampo: rotulo,
        valor: _rascunho.intervalo,
        opcoes: _intervalos,
        rotulo: (m) =>
            m == 0 ? 'Sem intervalo' : (curto ? '$m min' : '$m minutos'),
        onChanged: (m) => _mudar(() => _rascunho.intervalo = m),
      );

  Widget _modalidades() => Wrap(
        spacing: 28,
        children: [
          for (final m in Modalidade.values)
            LinhaCheck(
              rotulo: m.rotulo,
              valor: _rascunho.modalidades.contains(m),
              onChanged: (v) {
                if (!v && _rascunho.modalidades.length == 1) {
                  avisar(context, 'Mantenha pelo menos uma modalidade.');
                  return;
                }
                _mudar(() => v
                    ? _rascunho.modalidades.add(m)
                    : _rascunho.modalidades.remove(m));
              },
            ),
        ],
      );

  Widget _cartaoConfiguracao() {
    return CartaoApp(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 22, child: _seletorDuracao()),
          const SizedBox(width: 20),
          Expanded(flex: 22, child: _seletorIntervalo()),
          const SizedBox(width: 24),
          Expanded(
            flex: 25,
            child: CampoRotulado(
              rotulo: 'Modalidades',
              child: SizedBox(
                height: 46,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _modalidades(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoSemana() {
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Horários semanais', style: AppText.serif(22))),
              LinkTexto('Copiar segunda para todos os dias',
                  tamanho: 13.5, onTap: _copiarSegunda),
            ],
          ),
          const SizedBox(height: 6),
          for (var d = 1; d <= 7; d++) ...[
            if (d > 1) const Divider(),
            _linhaDiaWeb(d),
          ],
        ],
      ),
    );
  }

  Widget _linhaDiaWeb(int dia) {
    final ativo = _rascunho.ativos.contains(dia);
    final faixas = _rascunho.faixasDoDia(dia);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Semantics(
            label: 'Atender ${_naSemana(dia)}',
            child: Interruptor(
              valor: ativo,
              onChanged: (v) => _alternarDia(dia, v),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 92,
            child: Text(
              Fmt.diaNomeSemana(dia),
              style: TextStyle(
                  fontSize: 16,
                  color: ativo ? AppColors.texto : AppColors.textoFraco),
            ),
          ),
          Expanded(
            child: ativo
                ? Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final f in faixas)
                        _ChipFaixa(
                            faixa: f, onRemover: () => _removerFaixa(dia, f)),
                      LinkTexto('Adicionar',
                          icone: Icons.add_rounded,
                          onTap: () => _adicionarFaixa(dia)),
                    ],
                  )
                : const Text('Indisponível',
                    style:
                        TextStyle(fontSize: 15, color: AppColors.textoFraco)),
          ),
        ],
      ),
    );
  }

  Widget _cartaoBloqueios() {
    final bloqueios = _rascunho.bloqueios;
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Bloqueios e folgas', style: AppText.serif(22))),
              BotaoPill(
                context.isWide ? 'Adicionar bloqueio' : 'Adicionar',
                icone: Icons.add_rounded,
                estilo: EstiloBotao.contorno,
                compacto: true,
                onPressed: _adicionarBloqueio,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bloqueios.isEmpty)
            const Text('Nenhum bloqueio. Adicione feriados, férias ou folgas.',
                style: AppText.pequeno),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final b in bloqueios)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F0EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icone(Icons.calendar_today_outlined,
                          size: 17, color: AppColors.textoSecundario),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '${Fmt.diaMes(b.data)} · ${b.motivo}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Remover bloqueio',
                        onPressed: () => _mudar(() => _rascunho.bloqueios = [
                              for (final x in _rascunho.bloqueios)
                                if (x != b) x,
                            ]),
                        icon:
                            const Icone(Icons.delete_outline_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartaoPrevia() {
    final store = context.store;
    final p = store.psicologoAtual;
    final horarios =
        store.horariosDoDia(p, _diaPrevia, disponibilidade: _rascunho);
    final artigo = _diaPrevia.weekday >= 6 ? 'o' : 'a';
    final bloqueio = _rascunho.bloqueioEm(_diaPrevia);
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Prévia para o paciente', style: AppText.serif(22)),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Como $artigo ${Fmt.diaNomeSemana(_diaPrevia.weekday).toLowerCase()}, '
                  '${Fmt.diaMes(_diaPrevia)} aparece',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textoSecundario),
                ),
              ),
              IconButton(
                tooltip: 'Dia anterior',
                visualDensity: VisualDensity.compact,
                onPressed: _diaPrevia.isAfter(soDia(store.agora))
                    ? () =>
                        setState(() => _diaPrevia = maisDias(_diaPrevia, -1))
                    : null,
                icon: const Icone(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Próximo dia',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    setState(() => _diaPrevia = maisDias(_diaPrevia, 1)),
                icon: const Icone(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GradeHorarios(
            horarios: horarios,
            selecionado: null,
            onSelecionar: null,
            vazio: bloqueio != null
                ? 'Dia bloqueado: ${bloqueio.motivo}.'
                : 'Sem horários neste dia.',
          ),
          const SizedBox(height: 18),
          Text(
            'Sessões de ${_rascunho.duracao} min + ${_rascunho.intervalo} min de intervalo. '
            'Horários riscados já estão agendados.',
            style: const TextStyle(
                fontSize: 13.5, height: 1.5, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 18),
          const AvisoLavanda(
            'Mudanças na disponibilidade não cancelam consultas existentes.',
            titulo: 'Consultas já marcadas',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- celular

  List<Widget> _mobile() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _seletorDuracao(rotulo: 'Sessão', curto: true)),
          const SizedBox(width: 16),
          Expanded(child: _seletorIntervalo(rotulo: 'Intervalo', curto: true)),
        ],
      ),
      const SizedBox(height: 16),
      CartaoApp(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (var d = 1; d <= 7; d++) ...[
              if (d > 1) const Divider(),
              _linhaDiaMobile(d),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      BotaoPill('Salvar alterações',
          expandir: true, altura: 52, onPressed: _salvar),
      const SizedBox(height: 28),
      CartaoApp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modalidades', style: AppText.serif(22)),
            const SizedBox(height: 8),
            _modalidades(),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _cartaoBloqueios(),
      const SizedBox(height: 16),
      _cartaoPrevia(),
      if (_alterado) ...[
        const SizedBox(height: 16),
        BotaoPill('Salvar alterações',
            expandir: true, altura: 52, onPressed: _salvar),
      ],
    ];
  }

  Widget _linhaDiaMobile(int dia) {
    final ativo = _rascunho.ativos.contains(dia);
    final faixas = _rascunho.faixasDoDia(dia);
    return InkWell(
      onTap: () => _editarDiaMobile(dia),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Semantics(
              label: 'Atender ${_naSemana(dia)}',
              child: Interruptor(
                  valor: ativo, onChanged: (v) => _alternarDia(dia, v)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.diaNomeSemana(dia),
                    style: TextStyle(
                        fontSize: 16,
                        color: ativo ? AppColors.texto : AppColors.textoFraco),
                  ),
                  Text(
                    ativo
                        ? faixas
                            .map((f) =>
                                Fmt.faixa(f.inicio, f.fim).replaceAll(' ', ''))
                            .join(' · ')
                        : 'Indisponível',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: ativo
                          ? AppColors.textoSecundario
                          : AppColors.textoFraco,
                    ),
                  ),
                ],
              ),
            ),
            const Icone(Icons.chevron_right_rounded,
                color: AppColors.textoSecundario),
          ],
        ),
      ),
    );
  }

  Future<void> _editarDiaMobile(int dia) {
    return abrirPainel<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final faixas = _rascunho.faixasDoDia(dia);
          final ativo = _rascunho.ativos.contains(dia);
          return PainelConteudo(
            titulo: Fmt.diaNomeSemana(dia),
            subtitulo:
                ativo ? 'Faixas de horário deste dia' : 'Dia indisponível',
            acoes: BotaoPill('Pronto',
                expandir: true, onPressed: () => Navigator.of(ctx).pop()),
            children: [
              LinhaSwitch(
                rotulo: 'Atender neste dia',
                valor: ativo,
                onChanged: (v) {
                  _alternarDia(dia, v);
                  setLocal(() {});
                },
              ),
              const SizedBox(height: 12),
              if (ativo)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final f in faixas)
                      _ChipFaixa(
                        faixa: f,
                        onRemover: () {
                          _removerFaixa(dia, f);
                          setLocal(() {});
                        },
                      ),
                  ],
                ),
              if (ativo) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: LinkTexto(
                    'Adicionar faixa',
                    icone: Icons.add_rounded,
                    onTap: () async {
                      await _adicionarFaixa(dia);
                      setLocal(() {});
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChipFaixa extends StatelessWidget {
  const _ChipFaixa({required this.faixa, required this.onRemover});

  final Faixa faixa;
  final VoidCallback onRemover;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borda),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Fmt.faixa(faixa.inicio, faixa.fim),
              style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Remover faixa',
            visualDensity: VisualDensity.compact,
            onPressed: onRemover,
            icon: const Icone(Icons.close_rounded,
                size: 18, color: AppColors.textoFraco),
          ),
        ],
      ),
    );
  }
}

class _NovaFaixa extends StatefulWidget {
  const _NovaFaixa(
      {required this.dia,
      required this.existentes,
      required this.duracaoMinima});

  final int dia;
  final List<Faixa> existentes;
  final int duracaoMinima;

  @override
  State<_NovaFaixa> createState() => _NovaFaixaState();
}

class _NovaFaixaState extends State<_NovaFaixa> {
  static final _opcoes = [for (var m = 6 * 60; m <= 23 * 60; m += 30) m];
  late int _inicio;
  late int _fim;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final ultimo = widget.existentes.isEmpty
        ? 13 * 60
        : widget.existentes.map((f) => f.fim).reduce((a, b) => a > b ? a : b) +
            60;
    _inicio = _opcoes.firstWhere((m) => m >= ultimo, orElse: () => 18 * 60);
    _fim = (_inicio + 4 * 60).clamp(_inicio + 60, 23 * 60);
  }

  void _confirmar() {
    final nova = Faixa(_inicio, _fim);
    if (_fim <= _inicio) {
      setState(() => _erro = 'O fim precisa ser depois do início.');
    } else if (_fim - _inicio < widget.duracaoMinima) {
      setState(() => _erro = 'A faixa precisa caber pelo menos uma sessão.');
    } else if (widget.existentes.any((f) => f.sobrepoe(nova))) {
      setState(() => _erro = 'Essa faixa se sobrepõe a outra do mesmo dia.');
    } else {
      Navigator.of(context).pop(nova);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Nova faixa · ${Fmt.diaNomeSemana(widget.dia)}',
      acoes: AcoesPainel(primario: 'Adicionar', onPrimario: _confirmar),
      children: [
        Row(
          children: [
            Expanded(
              child: SeletorCaixa<int>(
                rotuloCampo: 'Início',
                valor: _inicio,
                opcoes: _opcoes,
                rotulo: Fmt.minutos,
                onChanged: (v) => setState(() {
                  _inicio = v;
                  _erro = null;
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SeletorCaixa<int>(
                rotuloCampo: 'Fim',
                valor: _fim,
                opcoes: _opcoes,
                rotulo: Fmt.minutos,
                onChanged: (v) => setState(() {
                  _fim = v;
                  _erro = null;
                }),
              ),
            ),
          ],
        ),
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!, style: const TextStyle(color: AppColors.vermelho)),
        ],
      ],
    );
  }
}

class _MotivoBloqueio extends StatefulWidget {
  const _MotivoBloqueio({required this.data});

  final DateTime data;

  @override
  State<_MotivoBloqueio> createState() => _MotivoBloqueioState();
}

class _MotivoBloqueioState extends State<_MotivoBloqueio> {
  final _motivo = TextEditingController(text: 'Folga (dia inteiro)');

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Bloquear ${Fmt.diaCurto(widget.data)}',
      subtitulo: 'Nenhum horário deste dia aparece para os pacientes.',
      acoes: AcoesPainel(
        primario: 'Adicionar bloqueio',
        onPrimario: () => Navigator.of(context).pop(
          _motivo.text.trim().isEmpty
              ? 'Bloqueio (dia inteiro)'
              : _motivo.text.trim(),
        ),
      ),
      children: [
        CampoTexto(
            controller: _motivo,
            rotulo: 'Motivo',
            hint: 'Feriado, férias, congresso...'),
      ],
    );
  }
}
