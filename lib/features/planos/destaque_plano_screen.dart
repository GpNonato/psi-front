import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Destaque e plano do psicólogo (wireframe 15) e da clínica (wireframe 20).
class DestaquePlanoScreen extends StatefulWidget {
  const DestaquePlanoScreen({super.key, required this.papel});

  final Papel papel;

  @override
  State<DestaquePlanoScreen> createState() => _DestaquePlanoScreenState();
}

class _DestaquePlanoScreenState extends State<DestaquePlanoScreen> {
  OpcaoDestaque _opcao = opcoesDestaque[1];
  int _inicio = 0;
  String _pagamento = 'Pix';

  bool get _clinica => widget.papel == Papel.clinica;

  List<Plano> get _planos => _clinica ? planosClinica : planosPsicologo;

  List<(String, DateTime)> _inicios(AppStore store) {
    final agora = store.agora;
    final e = store.destaque(clinica: _clinica);
    return [
      ('Agora (${Fmt.diaMes(agora)}, ${Fmt.hora(agora)})', agora),
      if (e.ativo(agora))
        (
          'Ao fim do destaque atual (${Fmt.diaMes(e.fim!)}, ${Fmt.hora(e.fim!)})',
          e.fim!
        ),
      ('Amanhã às 08:00', DateTime(agora.year, agora.month, agora.day + 1, 8)),
    ];
  }

  Future<void> _comprar() async {
    final store = context.acoes;
    final inicios = _inicios(store);
    final (rotulo, inicio) = inicios[_inicio.clamp(0, inicios.length - 1)];
    final ok = await pedirConfirmacao(
      context,
      titulo: 'Confirmar compra',
      mensagem:
          'Destaque de ${_opcao.rotulo} por ${Fmt.moeda(_opcao.preco)}, pago com '
          '${_pagamento.toLowerCase()}, começando ${rotulo[0].toLowerCase()}${rotulo.substring(1)}.\n\n'
          'Nesta demonstração o pagamento é simulado. Na versão final, ele é feito no provedor de '
          'pagamento e o destaque só ativa depois da confirmação.',
      rotuloConfirmar: 'Pagar ${Fmt.moeda(_opcao.preco)}',
    );
    if (!ok || !mounted) return;
    store.comprarDestaque(clinica: _clinica, opcao: _opcao, inicio: inicio);
    final fim = store.destaque(clinica: _clinica).fim!;
    avisar(
        context, 'Destaque ativo até ${Fmt.diaCurto(fim)}, ${Fmt.hora(fim)}.');
  }

  Future<void> _mudarPlano(Plano plano) async {
    final ok = await pedirConfirmacao(
      context,
      titulo: 'Mudar para ${plano.nome}?',
      mensagem: plano.preco == 0
          ? 'Você passa para o plano gratuito no próximo ciclo e perde os destaques inclusos.'
          : 'A cobrança de ${Fmt.moedaCurta(plano.preco)}/mês começa no próximo ciclo. '
              'Pagamento simulado nesta demonstração.',
      rotuloConfirmar: 'Mudar de plano',
    );
    if (!ok || !mounted) return;
    context.acoes.mudarPlano(clinica: _clinica, planoId: plano.id);
    avisar(context, 'Plano alterado para ${plano.nome}.');
  }

  Future<void> _gerenciar(Plano plano) {
    final agora = context.acoes.agora;
    return abrirPainel<void>(
      context,
      larguraMax: 480,
      builder: (ctx) => PainelConteudo(
        titulo: 'Plano ${plano.nome}',
        subtitulo: plano.preco == 0
            ? 'Plano gratuito'
            : '${Fmt.moedaCurta(plano.preco)}/mês',
        acoes: AcoesPainel(
          primario: 'Fechar',
          onPrimario: () => Navigator.of(ctx).pop(),
          secundario: 'Cancelar assinatura',
          onSecundario: plano.preco == 0
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  _mudarPlano(_planos.first);
                },
        ),
        children: [
          for (final r in plano.recursos) _itemRecurso(r),
          const SizedBox(height: 12),
          if (plano.preco > 0)
            Text(
              'Próxima cobrança: ${Fmt.diaMes(DateTime(agora.year, agora.month + 1, agora.day))} · Pix',
              style: AppText.pequeno,
            ),
        ],
      ),
    );
  }

  Widget _itemRecurso(String r) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icone(Icons.check_rounded, size: 18, color: AppColors.oliva),
            const SizedBox(width: 10),
            Expanded(
                child: Text(r,
                    style: const TextStyle(fontSize: 14.5, height: 1.35))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final e = store.destaque(clinica: _clinica);
    final plano = _planos.firstWhere((p) => p.id == e.planoId,
        orElse: () => _planos.first);
    final wide = context.isWide;
    return ProShell(
      papel: widget.papel,
      rota: _clinica ? Rotas.destaqueClinica : Rotas.destaque,
      child: PaginaPro(
        titulo: 'Destaque e plano',
        subtitulo:
            wide ? 'Apareça no topo da página inicial e das buscas' : null,
        children: wide
            ? [
                _cartaoStatus(store, e, plano),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final compra =
                        CartaoApp(child: _compra(store, completo: true));
                    if (c.maxWidth < 1080) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          compra,
                          const SizedBox(height: 24),
                          _planosWeb(e),
                        ],
                      );
                    }
                    // Como no wireframe 15, os cartões descem até o fim da
                    // tela (com um mínimo para telas baixas).
                    final altura = math.max(
                        640.0, MediaQuery.sizeOf(context).height - 312);
                    return SizedBox(
                      height: altura,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 420, child: compra),
                          const SizedBox(width: 24),
                          Expanded(child: _planosWeb(e, preencher: true)),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [
                _cartaoStatusMobile(store, e, plano),
                const SizedBox(height: 22),
                const TituloSerif('Destaque avulso', tamanho: 22),
                const SizedBox(height: 12),
                _compra(store, completo: false),
                const SizedBox(height: 22),
                _planoAtualMobile(plano),
              ],
      ),
    );
  }

  String _tituloStatus(AppStore store) => _clinica
      ? 'A ${store.clinicaAtual.nome} está em destaque'
      : 'Seu perfil está em destaque';

  Widget _cartaoStatus(AppStore store, EstadoDestaque e, Plano plano) {
    final agora = store.agora;
    final ativo = e.ativo(agora);
    const cor = AppColors.lavandaEscuro;
    Widget metrica(int valor, String rotulo) => SizedBox(
          width: 168,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.numero(valor), style: AppText.serif(26, cor: cor)),
              const SizedBox(height: 4),
              Text(rotulo, style: const TextStyle(fontSize: 12.5, color: cor)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 31, 24, 35),
      decoration: BoxDecoration(
          color: AppColors.lavandaClaro,
          borderRadius: BorderRadius.circular(24)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icone(
                        ativo ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.lavanda,
                        size: 26),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        ativo ? _tituloStatus(store) : 'Sem destaque ativo',
                        style: AppText.serif(21, cor: cor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ativo
                      ? 'Termina em ${e.fim!.difference(agora).inHours} h (${Fmt.diaMes(e.fim!)}, '
                          '${Fmt.hora(e.fim!)}) · ${e.usadosNoMes} de ${plano.destaquesPorMes} destaques '
                          'do plano usados neste mês'
                      : 'Compre um destaque avulso ou use os destaques incluídos no plano.',
                  style: const TextStyle(fontSize: 14.5, color: cor),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: BarraProgresso(
                    valor: plano.destaquesPorMes == 0
                        ? 0
                        : e.usadosNoMes / plano.destaquesPorMes,
                    cor: AppColors.lavanda,
                    fundo: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          metrica(e.visualizacoes, 'Visualizações'),
          metrica(
              e.cliques, _clinica ? 'Cliques na página' : 'Cliques no perfil'),
          metrica(e.agendamentos, 'Agendamentos'),
        ],
      ),
    );
  }

  Widget _cartaoStatusMobile(AppStore store, EstadoDestaque e, Plano plano) {
    final agora = store.agora;
    final ativo = e.ativo(agora);
    const cor = AppColors.lavandaEscuro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.lavandaClaro,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icone(Icons.star_rounded, color: AppColors.lavanda),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ativo
                      ? 'Em destaque até ${Fmt.diaMes(e.fim!)}, ${Fmt.hora(e.fim!)}'
                      : 'Sem destaque ativo',
                  style: const TextStyle(fontSize: 16, color: cor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${e.usadosNoMes} de ${plano.destaquesPorMes} destaques do plano usados',
            style: const TextStyle(fontSize: 13.5, color: cor),
          ),
          const SizedBox(height: 10),
          BarraProgresso(
            valor: plano.destaquesPorMes == 0
                ? 0
                : e.usadosNoMes / plano.destaquesPorMes,
            cor: AppColors.lavanda,
            fundo: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            '${Fmt.numero(e.visualizacoes)} visualizações · ${e.cliques} cliques · '
            '${e.agendamentos} agendamentos',
            style: const TextStyle(fontSize: 12.5, color: cor),
          ),
        ],
      ),
    );
  }

  Widget _compra(AppStore store, {required bool completo}) {
    final inicios = _inicios(store);
    final indice = _inicio.clamp(0, inicios.length - 1);
    Widget forma(String rotulo, String valor) => Expanded(
          child: Semantics(
            button: true,
            selected: _pagamento == valor,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      _pagamento == valor ? AppColors.oliva : AppColors.borda,
                  width: _pagamento == valor ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _pagamento = valor),
                child: SizedBox(
                    height: 46,
                    child: Center(
                        child: Text(rotulo,
                            style: const TextStyle(fontSize: 15)))),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (completo) ...[
          const Text('Comprar destaque avulso', style: TextStyle(fontSize: 19)),
          const SizedBox(height: 8),
          Text(
            _clinica
                ? 'Coloque a página da clínica em destaque por um período, além dos destaques do plano.'
                : 'Coloque a página do seu perfil em destaque por um período, além dos destaques do plano.',
            style: const TextStyle(
                fontSize: 14.5, height: 1.5, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 22),
        ],
        for (final o in opcoesDestaque)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CartaoOpcao(
              selecionado: _opcao == o,
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: completo ? 20 : 16),
              onTap: () => setState(() => _opcao = o),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text(o.rotulo, style: const TextStyle(fontSize: 16))),
                  Text(Fmt.moeda(o.preco),
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        if (completo) ...[
          const SizedBox(height: 8),
          SeletorCaixa<int>(
            rotuloCampo: 'Início',
            valor: indice,
            opcoes: [for (var i = 0; i < inicios.length; i++) i],
            rotulo: (i) => inicios[i].$1,
            onChanged: (i) => setState(() => _inicio = i),
          ),
          const SizedBox(height: 18),
          const Text('Forma de pagamento', style: AppText.rotulo),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            forma('Pix', 'Pix'),
            const SizedBox(width: 12),
            forma(completo ? 'Cartão de crédito' : 'Cartão', 'Cartão'),
          ],
        ),
        SizedBox(height: completo ? 28 : 16),
        BotaoPill(
          'Comprar destaque · ${Fmt.moeda(_opcao.preco)}',
          expandir: true,
          altura: 52,
          onPressed: _comprar,
        ),
        if (completo) ...[
          const SizedBox(height: 14),
          const Center(
              child: Text('Selo "Patrocinado" aparece no card.',
                  style: AppText.fraco)),
        ],
      ],
    );
  }

  Widget _planosWeb(EstadoDestaque e, {bool preencher = false}) {
    final cartoes = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _planos.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
              child:
                  _cartaoPlano(_planos[i], atual: _planos[i].id == e.planoId)),
        ],
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Text('Planos', style: TextStyle(fontSize: 19))),
            Text('Cobrança mensal · cancele quando quiser',
                style: TextStyle(
                    fontSize: 13.5, color: AppColors.textoSecundario)),
          ],
        ),
        const SizedBox(height: 16),
        if (preencher)
          Expanded(child: cartoes)
        else
          SizedBox(height: 606, child: cartoes),
      ],
    );
  }

  Widget _cartaoPlano(Plano plano, {required bool atual}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: atual ? AppColors.oliva : Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: atual
                  ? const SoftChip('Plano atual', cor: AppColors.texto)
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          Text(plano.nome, style: AppText.serif(20)),
          const SizedBox(height: 6),
          Text(
            plano.preco == 0 ? 'R\$ 0' : '${Fmt.moedaCurta(plano.preco)}/mês',
            style: const TextStyle(fontSize: 23, color: AppColors.texto),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          for (final r in plano.recursos) _itemRecurso(r),
          const Spacer(),
          BotaoPill(
            atual ? 'Gerenciar plano' : 'Mudar para ${plano.nome}',
            estilo: EstiloBotao.contorno,
            compacto: true,
            expandir: true,
            onPressed: () => atual ? _gerenciar(plano) : _mudarPlano(plano),
          ),
        ],
      ),
    );
  }

  Widget _planoAtualMobile(Plano plano) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.oliva, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftChip('Plano atual', cor: AppColors.texto),
          const SizedBox(height: 12),
          Text(
            '${plano.nome} · ${plano.preco == 0 ? 'R\$ 0' : '${Fmt.moedaCurta(plano.preco)}/mês'}',
            style: AppText.serif(20),
          ),
          const SizedBox(height: 4),
          Text(plano.resumo, style: AppText.pequeno),
          const SizedBox(height: 14),
          LinkTexto('Ver planos', onTap: _verPlanosMobile),
        ],
      ),
    );
  }

  Future<void> _verPlanosMobile() {
    return abrirPainel<void>(
      context,
      builder: (ctx) {
        final e = ctx.store.destaque(clinica: _clinica);
        return PainelConteudo(
          titulo: 'Planos',
          subtitulo: 'Cobrança mensal · cancele quando quiser',
          children: [
            for (final p in _planos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          p.id == e.planoId ? AppColors.oliva : AppColors.borda,
                      width: p.id == e.planoId ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${p.nome} · ${p.preco == 0 ? 'R\$ 0' : '${Fmt.moedaCurta(p.preco)}/mês'}',
                        style: AppText.serif(19),
                      ),
                      const SizedBox(height: 10),
                      for (final r in p.recursos) _itemRecurso(r),
                      BotaoPill(
                        p.id == e.planoId
                            ? 'Plano atual'
                            : 'Mudar para ${p.nome}',
                        estilo: EstiloBotao.contorno,
                        compacto: true,
                        onPressed: p.id == e.planoId
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                _mudarPlano(p);
                              },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
