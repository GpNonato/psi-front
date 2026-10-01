import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/icones.dart';

/// Faz o conteúdo de uma página entrar com um leve fade e deslize ao trocar de
/// seção. A barra de navegação fica parada; só o conteúdo anima.
class EntradaSuave extends StatefulWidget {
  const EntradaSuave({super.key, required this.child});

  final Widget child;

  @override
  State<EntradaSuave> createState() => _EntradaSuaveState();
}

class _EntradaSuaveState extends State<EntradaSuave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();
  late final Animation<double> _curva =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curva,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.012), end: Offset.zero)
            .animate(_curva),
        child: widget.child,
      ),
    );
  }
}

/// Lembra onde estava o indicador de cada barra de navegação, para ele deslizar
/// da posição anterior até a nova quando a página muda.
class MemoriaIndicador {
  MemoriaIndicador._();

  static final _valores = <String, double>{};

  /// Devolve a posição anterior (ou [atual], na primeira vez) e guarda a nova.
  static double trocar(String grupo, double atual) {
    final anterior = _valores[grupo] ?? atual;
    _valores[grupo] = atual;
    return anterior;
  }
}

const duracaoIndicador = Duration(milliseconds: 340);
const curvaIndicador = Curves.easeOutCubic;

class ItemBarraInferior {
  const ItemBarraInferior(this.icone, this.rotulo);
  final IconData icone;
  final String rotulo;
}

/// Barra inferior do celular (wireframes mobile), com a pílula sálvia deslizando
/// até o item selecionado.
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    super.key,
    required this.grupo,
    required this.itens,
    required this.indice,
    required this.onSelecionar,
  });

  final String grupo;
  final List<ItemBarraInferior> itens;
  final int indice;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    final anterior = MemoriaIndicador.trocar('barra-$grupo', indice.toDouble());
    // Como nos wireframes, o indicador de gestos do celular fica em parte por
    // cima da barra (não se reserva a área toda).
    final inset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bordaSuave)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: inset > 14 ? inset - 14 : 6),
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, c) {
              final larguraItem = c.maxWidth / itens.length;
              return Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: anterior, end: indice.toDouble()),
                    duration: duracaoIndicador,
                    curve: curvaIndicador,
                    builder: (_, v, __) => Positioned(
                      left: v * larguraItem + (larguraItem - 60) / 2,
                      top: 11,
                      width: 60,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.salvia,
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < itens.length; i++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: i == indice,
                            label: itens[i].rotulo,
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => onSelecionar(i),
                              child: Column(
                                children: [
                                  const SizedBox(height: 11),
                                  SizedBox(
                                    height: 30,
                                    child: Icone(
                                      itens[i].icone,
                                      size: 20,
                                      color: i == indice
                                          ? AppColors.texto
                                          : AppColors.textoSecundario,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AnimatedDefaultTextStyle(
                                    duration: duracaoIndicador,
                                    style: DefaultTextStyle.of(context)
                                        .style
                                        .merge(TextStyle(
                                          fontSize: 12,
                                          height: 1,
                                          color: i == indice
                                              ? AppColors.texto
                                              : AppColors.textoSecundario,
                                          fontWeight: i == indice
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                        )),
                                    child: Text(itens[i].rotulo, maxLines: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class OpcaoMenu {
  const OpcaoMenu(this.valor, this.rotulo, this.icone, {this.perigo = false});
  final String valor;
  final String rotulo;
  final IconData icone;
  final bool perigo;
}

/// Menu suspenso da conta (avatar e nome), compacto e sem sobras de espaço.
class MenuConta extends StatelessWidget {
  const MenuConta({
    super.key,
    required this.opcoes,
    required this.onSelecionar,
    required this.child,
    this.acima = false,
  });

  final List<OpcaoMenu> opcoes;
  final ValueChanged<String> onSelecionar;
  final Widget child;

  /// Abre para cima (rodapé do menu lateral).
  final bool acima;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu da conta',
      position: PopupMenuPosition.under,
      offset: acima ? const Offset(0, -128) : const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 200),
      onSelected: onSelecionar,
      itemBuilder: (_) => [
        for (final o in opcoes)
          PopupMenuItem<String>(
            value: o.valor,
            height: 42,
            child: Row(
              children: [
                Icone(o.icone,
                    size: 19,
                    color: o.perigo
                        ? AppColors.vermelho
                        : AppColors.textoSecundario),
                const SizedBox(width: 12),
                Text(
                  o.rotulo,
                  style: TextStyle(
                      fontSize: 14.5,
                      color: o.perigo ? AppColors.vermelho : AppColors.texto),
                ),
              ],
            ),
          ),
      ],
      child: child,
    );
  }
}
