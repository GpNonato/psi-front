import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Barras por semana do mês (1–7, 8–14, 15–21, 22–fim).
List<BarraSemana> barrasDoMes(List<Lancamento> lancamentos, int ano, int mes) {
  final ultimoDia = DateTime(ano, mes + 1, 0).day;
  final faixas = [(1, 7), (8, 14), (15, 21), (22, ultimoDia)];
  return [
    for (final (a, b) in faixas)
      BarraSemana(
        '$a–$b',
        lancamentos
            .where((l) => l.pago && l.data.day >= a && l.data.day <= b)
            .fold<double>(0, (s, l) => s + l.valor),
        lancamentos
            .where((l) => !l.pago && l.data.day >= a && l.data.day <= b)
            .fold<double>(0, (s, l) => s + l.valor),
      ),
  ];
}

enum _Filtro { todos, pendentes, pagos }

/// Financeiro do psicólogo (wireframe 13).
class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  late int _mes = context.acoes.agora.month;
  _Filtro _filtro = _Filtro.todos;

  List<Lancamento> _filtrar(List<Lancamento> lista) => switch (_filtro) {
        _Filtro.todos => lista,
        _Filtro.pendentes => lista.where((l) => !l.pago).toList(),
        _Filtro.pagos => lista.where((l) => l.pago).toList(),
      };

  Widget _seletorMes(int ano) => SeletorCaixa<int>(
        valor: _mes,
        opcoes: [for (var m = context.acoes.agora.month; m >= 8; m--) m],
        rotulo: (m) => '${capitalizar(Fmt.mesLongo(m))} $ano',
        semantica: 'Mês',
        altura: 44,
        onChanged: (m) => setState(() => _mes = m),
      );

  Widget _chipsFiltro() => Wrap(
        spacing: 6,
        children: [
          for (final (f, r) in const [
            (_Filtro.todos, 'Todos'),
            (_Filtro.pendentes, 'Pendentes'),
            (_Filtro.pagos, 'Pagos'),
          ])
            ChipFiltro(r,
                compacto: true,
                selecionado: _filtro == f,
                onTap: () => setState(() => _filtro = f)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final ano = store.agora.year;
    final resumo = store.resumo(ano, _mes);
    final anterior = store.resumo(ano, _mes - 1);
    final lancamentos = store.lancamentosDoMes(ano, _mes);
    final wide = context.isWide;
    final dif = resumo.sessoes - anterior.sessoes;
    final mesAnterior = Fmt.mesLongo(_mes - 1 < 1 ? 12 : _mes - 1);

    final kpis = [
      Kpi(
        rotulo: 'Recebido',
        valor: Fmt.moedaCurta(resumo.recebido),
        detalhe:
            Fmt.plural(resumo.sessoesPagas, 'sessão paga', 'sessões pagas'),
        cor: AppColors.verde,
      ),
      Kpi(
        rotulo: 'A receber',
        valor: Fmt.moedaCurta(resumo.aReceber),
        detalhe: Fmt.plural(
            resumo.sessoesPendentes, 'sessão pendente', 'sessões pendentes'),
        cor: AppColors.ambar,
      ),
      Kpi(
        rotulo: 'Sessões no mês',
        valor: '${resumo.sessoes}',
        detalhe: anterior.sessoes == 0
            ? 'sem dados do mês anterior'
            : '${dif >= 0 ? '+' : ''}$dif em relação a $mesAnterior',
      ),
      Kpi(
        rotulo: 'Ticket médio',
        valor: Fmt.moedaCurta(resumo.ticketMedio.round()),
        detalhe: 'por sessão',
      ),
    ];

    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.financeiro,
      child: PaginaPro(
        titulo: 'Financeiro',
        subtitulo: wide
            ? 'Controle dos pagamentos combinados com seus pacientes'
            : null,
        acoes: [
          BotaoPill('Exportar',
              estilo: EstiloBotao.contorno,
              onPressed: () => _exportar(context)),
          BotaoPill('Novo lançamento',
              icone: Icons.add_rounded, onPressed: () => _novo(context)),
        ],
        acoesMobile: [
          BotaoPill('Novo',
              icone: Icons.add_rounded,
              compacto: true,
              onPressed: () => _novo(context)),
        ],
        children: wide
            ? [
                Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 200, child: _seletorMes(ano))),
                const SizedBox(height: 36),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < kpis.length; i++) ...[
                        if (i > 0) const VerticalDivider(width: 40),
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: kpis[i])),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth < 980) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _cartaoGrafico(lancamentos, ano),
                          const SizedBox(height: 24),
                          _cartaoTabela(context, _filtrar(lancamentos)),
                        ],
                      );
                    }
                    // Como no wireframe 13, os dois cartões vão até o fim
                    // da tela e a lista rola por dentro do cartão.
                    final altura = math.max(
                        560.0, MediaQuery.sizeOf(context).height - 345);
                    return SizedBox(
                      height: altura,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 360,
                            child: _cartaoGrafico(lancamentos, ano,
                                preencher: true),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _cartaoTabela(context, _filtrar(lancamentos),
                                rolavel: true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [
                Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 190, child: _seletorMes(ano))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CartaoApp(
                        padding: const EdgeInsets.all(16),
                        child: Kpi(
                          rotulo: 'Recebido',
                          valor: Fmt.moedaCurta(resumo.recebido),
                          cor: AppColors.verde,
                          tamanho: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CartaoApp(
                        padding: const EdgeInsets.all(16),
                        child: Kpi(
                          rotulo: 'A receber',
                          valor: Fmt.moedaCurta(resumo.aReceber),
                          cor: AppColors.ambar,
                          tamanho: 26,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(alignment: Alignment.centerLeft, child: _chipsFiltro()),
                const SizedBox(height: 12),
                _listaMobile(context, _filtrar(lancamentos)),
              ],
      ),
    );
  }

  Widget _cartaoGrafico(List<Lancamento> lancamentos, int ano,
      {bool preencher = false}) {
    final barras = barrasDoMes(lancamentos, ano, _mes);
    Widget legenda(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(t,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textoSecundario)),
          ],
        );
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Por semana',
              style: TextStyle(fontSize: 19, color: AppColors.texto)),
          const SizedBox(height: 8),
          Row(
            children: [
              legenda(AppColors.oliva, 'Recebido'),
              const SizedBox(width: 18),
              legenda(AppColors.lavandaClaro, 'A receber'),
            ],
          ),
          const SizedBox(height: 28),
          if (preencher)
            // As barras ocupam o que sobra do cartão (legenda dos dias: ~34 px).
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => GraficoBarras(
                    barras: barras, altura: math.max(120.0, c.maxHeight - 34)),
              ),
            )
          else
            GraficoBarras(barras: barras, altura: 360),
          const SizedBox(height: 24),
          const Text('Valores informados manualmente.', style: AppText.fraco),
        ],
      ),
    );
  }

  Widget _cartaoTabela(BuildContext context, List<Lancamento> lista,
      {bool rolavel = false}) {
    const cab = TextStyle(fontSize: 12.5, color: AppColors.textoSecundario);
    final linhas = <Widget>[
      if (lista.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child:
              Text('Nenhum lançamento neste filtro.', style: AppText.pequeno),
        ),
      for (var i = 0; i < lista.length; i++) ...[
        if (i > 0) const Divider(),
        _linhaTabela(context, lista[i]),
      ],
    ];
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                  child: Text('Lançamentos',
                      style: TextStyle(fontSize: 19, color: AppColors.texto))),
              _chipsFiltro(),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              SizedBox(width: 72, child: Text('Data', style: cab)),
              Expanded(flex: 30, child: Text('Paciente', style: cab)),
              Expanded(flex: 13, child: Text('Valor', style: cab)),
              Expanded(flex: 10, child: Text('Forma', style: cab)),
              Expanded(flex: 12, child: Text('Status', style: cab)),
              SizedBox(width: 160),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          if (rolavel)
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                primary: false,
                children: linhas,
              ),
            )
          else
            ...linhas,
        ],
      ),
    );
  }

  Widget _linhaTabela(BuildContext context, Lancamento l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
              width: 72,
              child: Text(Fmt.diaMes(l.data),
                  style: const TextStyle(fontSize: 15))),
          Expanded(
            flex: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.pacienteNome, style: const TextStyle(fontSize: 15)),
                Text(l.descricao,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario)),
              ],
            ),
          ),
          Expanded(
              flex: 13,
              child: Text(Fmt.moeda(l.valor),
                  style: const TextStyle(fontSize: 15))),
          Expanded(
            flex: 10,
            child: Text(l.forma ?? '—',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textoSecundario)),
          ),
          Expanded(
            flex: 12,
            child: StatusPonto(
              l.pago ? 'Pago' : 'Pendente',
              cor: l.pago ? AppColors.verde : AppColors.ambar,
              tamanho: 13,
            ),
          ),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: l.pago
                  ? const SizedBox.shrink()
                  : BotaoPill(
                      'Marcar como pago',
                      estilo: EstiloBotao.contorno,
                      compacto: true,
                      altura: 34,
                      onPressed: () => _marcarPago(context, l),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaMobile(BuildContext context, List<Lancamento> lista) {
    return CartaoApp(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          if (lista.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum lançamento neste filtro.',
                  style: AppText.pequeno),
            ),
          for (var i = 0; i < lista.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lista[i].pacienteNome,
                            style: const TextStyle(fontSize: 15.5)),
                        Text(
                          '${Fmt.diaMes(lista[i].data)} · ${lista[i].descricao}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textoSecundario),
                        ),
                        if (!lista[i].pago)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: LinkTexto(
                              'Marcar como pago',
                              cor: AppColors.oliva,
                              tamanho: 13,
                              onTap: () => _marcarPago(context, lista[i]),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Fmt.moeda(lista[i].valor),
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 6),
                      StatusPonto(
                        lista[i].pago ? 'Pago' : 'Pendente',
                        cor: lista[i].pago ? AppColors.verde : AppColors.ambar,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _marcarPago(BuildContext context, Lancamento l) async {
    final paciente = context.acoes.pacienteOuNulo(l.pacienteId);
    final forma = await abrirPainel<String>(
      context,
      larguraMax: 440,
      builder: (_) => _EscolherForma(
        lancamento: l,
        sugerida: l.forma ?? paciente?.formaPreferida ?? 'Pix',
      ),
    );
    if (forma == null || !context.mounted) return;
    context.acoes.marcarComoPago(l, forma);
    avisar(context, 'Pagamento de ${l.pacienteNome} marcado como pago.');
  }

  void _exportar(BuildContext context) {
    avisar(
      context,
      'Exportação simulada: planilha de ${Fmt.mesLongo(_mes)} gerada com '
      '${Fmt.plural(context.acoes.lancamentosDoMes(context.acoes.agora.year, _mes).length, 'lançamento', 'lançamentos')}.',
    );
  }

  Future<void> _novo(BuildContext context) {
    return abrirPainel<void>(context,
        larguraMax: 520, builder: (_) => const _NovoLancamento());
  }
}

class _EscolherForma extends StatefulWidget {
  const _EscolherForma({required this.lancamento, required this.sugerida});

  final Lancamento lancamento;
  final String sugerida;

  @override
  State<_EscolherForma> createState() => _EscolherFormaState();
}

class _EscolherFormaState extends State<_EscolherForma> {
  late String _forma = widget.sugerida;

  @override
  Widget build(BuildContext context) {
    final l = widget.lancamento;
    return PainelConteudo(
      titulo: 'Marcar como pago',
      subtitulo:
          '${l.pacienteNome} · ${Fmt.moeda(l.valor)} · ${Fmt.diaMes(l.data)}',
      acoes: AcoesPainel(
          primario: 'Confirmar pagamento',
          onPrimario: () => Navigator.of(context).pop(_forma)),
      children: [
        const Text('Forma de pagamento', style: AppText.rotulo),
        const SizedBox(height: 10),
        for (final f in formasDePagamento)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CartaoOpcao(
              selecionado: _forma == f,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () => setState(() => _forma = f),
              child: Text(f, style: const TextStyle(fontSize: 15)),
            ),
          ),
      ],
    );
  }
}

class _NovoLancamento extends StatefulWidget {
  const _NovoLancamento();

  @override
  State<_NovoLancamento> createState() => _NovoLancamentoState();
}

class _NovoLancamentoState extends State<_NovoLancamento> {
  Paciente? _paciente;
  String _descricao = 'Sessão individual';
  final _valor = TextEditingController(text: '180,00');
  String _forma = 'Pix';
  bool _pago = true;
  String? _erro;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final valor = double.tryParse(
        _valor.text.replaceAll('.', '').replaceAll(',', '.').trim());
    if (_paciente == null) {
      setState(() => _erro = 'Escolha o paciente.');
      return;
    }
    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.acoes.registrarLancamento(
      pacienteId: _paciente!.id,
      data: context.acoes.agora,
      descricao: _descricao,
      valor: valor,
      pago: _pago,
      forma: _pago ? _forma : null,
      sessoes: _descricao.startsWith('Pacote') ? 4 : 1,
    );
    Navigator.of(context).pop();
    messenger
        .showSnackBar(const SnackBar(content: Text('Lançamento registrado.')));
  }

  @override
  Widget build(BuildContext context) {
    final pacientes = context.store.pacientes;
    return PainelConteudo(
      titulo: 'Novo lançamento',
      subtitulo: 'Pagamentos combinados diretamente com o paciente.',
      acoes: AcoesPainel(primario: 'Registrar lançamento', onPrimario: _salvar),
      children: [
        SeletorCaixa<Paciente>(
          rotuloCampo: 'Paciente',
          valor: _paciente,
          hint: 'Escolha o paciente',
          opcoes: pacientes,
          rotulo: (p) => p.nome,
          onChanged: (p) => setState(() {
            _paciente = p;
            _forma = p.formaPreferida;
            _erro = null;
          }),
        ),
        const SizedBox(height: 14),
        SeletorCaixa<String>(
          rotuloCampo: 'Referente a',
          valor: _descricao,
          opcoes: const ['Sessão individual', 'Pacote 4 sessões'],
          rotulo: (s) => s,
          onChanged: (s) => setState(() {
            _descricao = s;
            _valor.text = s.startsWith('Pacote') ? '640,00' : '180,00';
          }),
        ),
        const SizedBox(height: 14),
        CampoTexto(
          controller: _valor,
          rotulo: 'Valor (R\$)',
          teclado: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        CampoRotulado(
          rotulo: 'Situação',
          child: SegmentoPill<bool>(
            opcoes: const [true, false],
            valor: _pago,
            rotulo: (b) => b ? 'Pago' : 'Pendente',
            onChanged: (b) => setState(() => _pago = b),
          ),
        ),
        if (_pago) ...[
          const SizedBox(height: 14),
          SeletorCaixa<String>(
            rotuloCampo: 'Forma de pagamento',
            valor: _forma,
            opcoes: formasDePagamento,
            rotulo: (s) => s,
            onChanged: (s) => setState(() => _forma = s),
          ),
        ],
        if (_erro != null) ...[
          const SizedBox(height: 12),
          Text(_erro!, style: const TextStyle(color: AppColors.vermelho)),
        ],
      ],
    );
  }
}
