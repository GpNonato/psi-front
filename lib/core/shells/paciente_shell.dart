import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store_scope.dart';
import '../formatters.dart';
import '../responsive.dart';
import '../rotas.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'navegacao.dart';
import 'notificacoes.dart';

enum SecaoPaciente { inicio, buscar, clinicas, consultas, conta }

/// Moldura das telas do paciente: barra superior no web e barra inferior no
/// celular (wireframes 01 a 07).
class PacienteShell extends StatelessWidget {
  const PacienteShell({
    super.key,
    required this.secao,
    required this.child,
    this.navInferior = true,
    this.barraInferior,
  });

  final SecaoPaciente secao;
  final Widget child;
  final bool navInferior;

  /// Substitui a barra de navegação (ex.: barra "Agendar consulta" do perfil).
  final Widget? barraInferior;

  @override
  Widget build(BuildContext context) {
    if (context.isWide) {
      return Scaffold(
        body: Column(
          children: [
            BarraSuperiorPaciente(secao: secao),
            Expanded(child: EntradaSuave(child: child)),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(bottom: false, child: EntradaSuave(child: child)),
      bottomNavigationBar: barraInferior ??
          (navInferior ? _NavInferiorPaciente(secao: secao) : null),
    );
  }
}

class BarraSuperiorPaciente extends StatelessWidget {
  const BarraSuperiorPaciente({super.key, required this.secao});

  final SecaoPaciente secao;

  static const _estilo = TextStyle(fontSize: 15, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final compacto = context.larguraTela < 1120;
    final itens = [
      ('Início', SecaoPaciente.inicio, Rotas.inicio),
      ('Buscar psicólogos', SecaoPaciente.buscar, Rotas.buscar),
      ('Clínicas', SecaoPaciente.clinicas, Rotas.clinicas),
      ('Minhas consultas', SecaoPaciente.consultas, Rotas.consultas),
    ];
    // Larguras medidas para o indicador saber para onde deslizar.
    final escala = MediaQuery.textScalerOf(context);
    final padding = compacto ? 12.0 : 25.0;
    final textos = [
      for (final (rotulo, _, _) in itens)
        (TextPainter(
          text: TextSpan(
            text: rotulo,
            style: DefaultTextStyle.of(context).style.merge(_estilo),
          ),
          textDirection: TextDirection.ltr,
          textScaler: escala,
        )..layout())
            .width,
    ];
    final larguras = [for (final t in textos) t + padding * 2 + 2];
    final posicoes = <double>[];
    var x = 0.0;
    for (final l in larguras) {
      posicoes.add(x);
      x += l;
    }
    final indice = itens.indexWhere((i) => i.$2 == secao);
    // O sublinhado acompanha o texto (wireframes 01 a 07), não o item todo.
    final alvoX = indice < 0 ? 0.0 : posicoes[indice] + padding;
    final alvoL = indice < 0 ? 0.0 : textos[indice] + 10;
    final anteriorX = MemoriaIndicador.trocar('topo-x', alvoX);
    final anteriorL = MemoriaIndicador.trocar('topo-l', alvoL);

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.bordaSuave)),
      ),
      // No wireframe o logo fica alinhado ao conteúdo (x = 80) e o nome da
      // pessoa vai até 45 px da borda direita.
      child: LayoutBuilder(
        builder: (context, c) {
          final margem = math.max(32.0, (c.maxWidth - 1280) / 2);
          return Padding(
            padding: EdgeInsets.only(
                left: margem, right: math.max(32.0, margem - 35)),
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-4, 0),
                  child: PsiHubLogo(onTap: () => irPara(context, Rotas.inicio)),
                ),
                SizedBox(width: compacto ? 28 : 66),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: x,
                        height: 72,
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < itens.length; i++)
                                  _ItemNavSuperior(
                                    rotulo: itens[i].$1,
                                    largura: larguras[i],
                                    selecionado: i == indice,
                                    onTap: () {
                                      if (i != indice) {
                                        irPara(context, itens[i].$3);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            if (indice >= 0)
                              TweenAnimationBuilder<Offset>(
                                tween: Tween(
                                    begin: Offset(anteriorX, anteriorL),
                                    end: Offset(alvoX, alvoL)),
                                duration: duracaoIndicador,
                                curve: curvaIndicador,
                                builder: (_, v, __) => Positioned(
                                  left: v.dx,
                                  width: v.dy,
                                  bottom: 0,
                                  height: 3,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.oliva,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(3)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const BotaoNotificacoes(papel: Papel.paciente),
                const SizedBox(width: 6),
                MenuConta(
                  opcoes: const [
                    OpcaoMenu(
                        'conta', 'Minha conta', Icons.person_outline_rounded),
                    OpcaoMenu('sair', 'Sair', Icons.logout_rounded,
                        perigo: true),
                  ],
                  onSelecionar: (v) {
                    if (v == 'conta') {
                      irPara(context, Rotas.conta);
                    } else {
                      context.acoes.sair();
                      irPara(context, Rotas.entrar);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
                    child: Row(
                      children: [
                        AvatarIniciais(store.pacienteNome, tamanho: 36),
                        if (!compacto) ...[
                          const SizedBox(width: 11),
                          Text(
                            primeiroNome(store.pacienteNome),
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.texto),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ItemNavSuperior extends StatelessWidget {
  const _ItemNavSuperior({
    required this.rotulo,
    required this.largura,
    required this.selecionado,
    required this.onTap,
  });

  final String rotulo;
  final double largura;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionado,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.salvia.withValues(alpha: 0.35),
        child: SizedBox(
          width: largura,
          height: 72,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: duracaoIndicador,
              curve: curvaIndicador,
              style: DefaultTextStyle.of(context).style.merge(TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: selecionado
                        ? AppColors.oliva
                        : AppColors.textoSecundario,
                  )),
              child: Text(rotulo, maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavInferiorPaciente extends StatelessWidget {
  const _NavInferiorPaciente({required this.secao});

  final SecaoPaciente secao;

  static const _rotas = [
    Rotas.inicio,
    Rotas.buscar,
    Rotas.consultas,
    Rotas.conta
  ];

  @override
  Widget build(BuildContext context) {
    final indice = switch (secao) {
      SecaoPaciente.inicio => 0,
      SecaoPaciente.buscar || SecaoPaciente.clinicas => 1,
      SecaoPaciente.consultas => 2,
      SecaoPaciente.conta => 3,
    };
    return BarraInferior(
      grupo: 'paciente',
      indice: indice,
      onSelecionar: (i) {
        if (i != indice) irPara(context, _rotas[i]);
      },
      itens: const [
        ItemBarraInferior(Icons.home_outlined, 'Início'),
        ItemBarraInferior(Icons.search_rounded, 'Buscar'),
        ItemBarraInferior(Icons.calendar_today_outlined, 'Consultas'),
        ItemBarraInferior(Icons.person_outline_rounded, 'Perfil'),
      ],
    );
  }
}

/// Conteúdo rolável das páginas web do paciente, com o rodapé sempre no fim da
/// página (mesmo quando o conteúdo é curto).
class ConteudoComRodape extends StatelessWidget {
  const ConteudoComRodape({
    super.key,
    required this.child,
    this.larguraMax = 1344,
    this.rodape = const RodapePsiHub(),
    this.controller,
  });

  final Widget child;
  final double larguraMax;
  final Widget rodape;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
            child: Centralizado(larguraMax: larguraMax, child: child)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Centralizado(child: rodape),
          ),
        ),
      ],
    );
  }
}

/// Rodapé das páginas do paciente no web.
class RodapePsiHub extends StatelessWidget {
  const RodapePsiHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                const PsiHubLogo(tamanho: 19),
                const SizedBox(width: 16),
                const Text('© 2026', style: AppText.fraco),
                const Spacer(),
                for (final (i, t) in const [
                  'Sobre',
                  'Para psicólogos',
                  'Para clínicas',
                  'Privacidade'
                ].indexed) ...[
                  if (i > 0)
                    const Text(' · ',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textoSecundario)),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => avisar(
                        context, '$t: página institucional ainda não criada.'),
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textoSecundario)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
