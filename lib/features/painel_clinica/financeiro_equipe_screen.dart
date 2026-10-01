import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'equipe_screen.dart' show avatarDoMembro;

/// Financeiro da equipe, só com valores agregados (wireframe 19).
class FinanceiroEquipeScreen extends StatefulWidget {
  const FinanceiroEquipeScreen({super.key});

  @override
  State<FinanceiroEquipeScreen> createState() => _FinanceiroEquipeScreenState();
}

class _FinanceiroEquipeScreenState extends State<FinanceiroEquipeScreen> {
  late int _mes = context.acoes.agora.month;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final ano = store.agora.year;
    final membros = [
      for (final m in store.equipe)
        if (m.acesso == Acesso.ativo && m.incluirNoFinanceiro) m,
    ];
    final totais = [for (final m in membros) store.totaisDoMembro(m, _mes)];
    final recebido = totais.fold<double>(0, (s, t) => s + t.$2);
    final aReceber = totais.fold<double>(0, (s, t) => s + t.$3);
    final consultas = totais.fold<int>(0, (s, t) => s + t.$1);
    final ativos = store.equipe.where((m) => m.acesso == Acesso.ativo).length;
    final aguardando = store.equipe.length - ativos;
    final wide = context.isWide;

    final seletor = SeletorCaixa<int>(
      valor: _mes,
      opcoes: [for (var m = store.agora.month; m >= 8; m--) m],
      rotulo: (m) => '${capitalizar(Fmt.mesLongo(m))} $ano',
      semantica: 'Mês',
      onChanged: (m) => setState(() => _mes = m),
    );

    return ProShell(
      papel: Papel.clinica,
      rota: Rotas.financeiroEquipe,
      child: PaginaPro(
        titulo: wide ? 'Financeiro da equipe' : 'Financeiro',
        subtitulo: wide ? 'Totais informados por cada psicólogo' : null,
        acoes: [
          BotaoPill(
            'Exportar',
            estilo: EstiloBotao.contorno,
            onPressed: () => avisar(context,
                'Exportação simulada: planilha com os totais agregados gerada.'),
          ),
        ],
        acoesMobile: const [],
        children: wide
            ? [
                Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 200, child: seletor)),
                const SizedBox(height: 28),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Kpi(
                          rotulo: 'Recebido pela equipe',
                          valor: Fmt.moedaCurta(recebido),
                          detalhe: Fmt.mesLongo(_mes),
                          cor: AppColors.verde,
                        ),
                      ),
                      const VerticalDivider(width: 40),
                      Expanded(
                        child: Kpi(
                          rotulo: 'A receber',
                          valor: Fmt.moedaCurta(aReceber),
                          detalhe: 'pendências dos psicólogos',
                          cor: AppColors.ambar,
                        ),
                      ),
                      const VerticalDivider(width: 40),
                      Expanded(
                        child: Kpi(
                            rotulo: 'Consultas',
                            valor: '$consultas',
                            detalhe: 'realizadas no mês'),
                      ),
                      const VerticalDivider(width: 40),
                      Expanded(
                        child: Kpi(
                          rotulo: 'Psicólogos ativos',
                          valor: '$ativos',
                          detalhe: '$aguardando aguardando acesso',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _tabela(membros, totais),
                const SizedBox(height: 28),
                const AvisoLavanda(
                  'Somente valores agregados. Nomes de pacientes e detalhes das sessões ficam com cada psicólogo.',
                  icone: Icons.lock_outline_rounded,
                ),
              ]
            : [
                Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: 190, child: seletor)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CartaoApp(
                        padding: const EdgeInsets.all(16),
                        child: Kpi(
                            rotulo: 'Recebido',
                            valor: Fmt.moedaCurta(recebido),
                            cor: AppColors.verde,
                            tamanho: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CartaoApp(
                        padding: const EdgeInsets.all(16),
                        child: Kpi(
                            rotulo: 'A receber',
                            valor: Fmt.moedaCurta(aReceber),
                            cor: AppColors.ambar,
                            tamanho: 26),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const TituloSerif('Por psicólogo', tamanho: 22),
                const SizedBox(height: 12),
                CartaoApp(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < membros.length; i++) ...[
                        if (i > 0) const Divider(),
                        _linhaMobile(membros[i], totais[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AvisoLavanda(
                  'Só valores agregados, sem pacientes',
                  icone: Icons.lock_outline_rounded,
                  compacto: true,
                ),
              ],
      ),
    );
  }

  double _percentual(TotaisMes t) {
    final total = t.$2 + t.$3;
    return total == 0 ? 0 : t.$2 / total;
  }

  Widget _tabela(List<MembroEquipe> membros, List<TotaisMes> totais) {
    const cab = TextStyle(fontSize: 12.5, color: AppColors.textoSecundario);
    return CartaoApp(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 14),
            child: Row(
              children: [
                Expanded(flex: 30, child: Text('Psicólogo', style: cab)),
                Expanded(flex: 11, child: Text('Consultas', style: cab)),
                Expanded(flex: 13, child: Text('Recebido', style: cab)),
                Expanded(flex: 13, child: Text('A receber', style: cab)),
                Expanded(flex: 33, child: Text('% recebido', style: cab)),
              ],
            ),
          ),
          const Divider(),
          for (var i = 0; i < membros.length; i++) ...[
            if (i > 0) const Divider(indent: 24, endIndent: 24),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 17.5),
              child: Row(
                children: [
                  Expanded(
                    flex: 30,
                    child: Row(
                      children: [
                        avatarDoMembro(context.store, membros[i], 40),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(membros[i].nome,
                                style: const TextStyle(fontSize: 15.5))),
                      ],
                    ),
                  ),
                  Expanded(
                      flex: 11,
                      child: Text('${totais[i].$1}',
                          style: const TextStyle(fontSize: 15))),
                  Expanded(
                      flex: 13,
                      child: Text(Fmt.moedaCurta(totais[i].$2),
                          style: const TextStyle(fontSize: 15))),
                  Expanded(
                    flex: 13,
                    child: Text(
                      Fmt.moedaCurta(totais[i].$3),
                      style:
                          const TextStyle(fontSize: 15, color: AppColors.ambar),
                    ),
                  ),
                  Expanded(
                    flex: 33,
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                BarraProgresso(valor: _percentual(totais[i]))),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${(_percentual(totais[i]) * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textoSecundario),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linhaMobile(MembroEquipe m, TotaisMes t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          avatarDoMembro(context.store, m, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                        child:
                            Text(m.nome, style: const TextStyle(fontSize: 15))),
                    Text(Fmt.moedaCurta(t.$2),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: BarraProgresso(valor: _percentual(t))),
                    const SizedBox(width: 8),
                    Text(
                      '${Fmt.moedaCurta(t.$3)} a receber',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.ambar),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
