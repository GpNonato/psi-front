import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/store_scope.dart';
import '../responsive.dart';
import '../rotas.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'navegacao.dart';

class ItemMenuPro {
  const ItemMenuPro(this.rotulo, this.icone, this.rota);
  final String rotulo;
  final IconData icone;
  final String rota;
}

const itensMenuPsicologo = [
  ItemMenuPro('Agenda', Icons.calendar_today_outlined, Rotas.agenda),
  ItemMenuPro('Disponibilidade', Icons.schedule_rounded, Rotas.disponibilidade),
  ItemMenuPro('Pacientes', Icons.person_outline_rounded, Rotas.pacientes),
  ItemMenuPro('Financeiro', Icons.attach_money_rounded, Rotas.financeiro),
  ItemMenuPro('Minha página', Icons.photo_outlined, Rotas.minhaPagina),
  ItemMenuPro('Destaque e plano', Icons.star_outline_rounded, Rotas.destaque),
  ItemMenuPro('Relatórios', Icons.description_outlined, Rotas.relatorios),
  ItemMenuPro('Configurações', Icons.settings_outlined, Rotas.configuracoes),
];

const itensMenuClinica = [
  ItemMenuPro('Equipe', Icons.person_outline_rounded, Rotas.equipe),
  ItemMenuPro(
      'Agenda da equipe', Icons.calendar_today_outlined, Rotas.agendaEquipe),
  ItemMenuPro('Financeiro', Icons.attach_money_rounded, Rotas.financeiroEquipe),
  ItemMenuPro(
      'Página da clínica', Icons.apartment_outlined, Rotas.paginaDaClinica),
  ItemMenuPro(
      'Destaque e plano', Icons.star_outline_rounded, Rotas.destaqueClinica),
  ItemMenuPro(
      'Configurações', Icons.settings_outlined, Rotas.configuracoesClinica),
];

/// Barra inferior do celular: quatro atalhos e "Mais" com o restante.
const _navPsicologo = [
  ItemMenuPro('Agenda', Icons.calendar_today_outlined, Rotas.agenda),
  ItemMenuPro('Pacientes', Icons.person_outline_rounded, Rotas.pacientes),
  ItemMenuPro('Financeiro', Icons.attach_money_rounded, Rotas.financeiro),
  ItemMenuPro('Página', Icons.photo_outlined, Rotas.minhaPagina),
  ItemMenuPro('Mais', Icons.menu_rounded, Rotas.maisPsicologo),
];

const _navClinica = [
  ItemMenuPro('Equipe', Icons.person_outline_rounded, Rotas.equipe),
  ItemMenuPro('Agenda', Icons.calendar_today_outlined, Rotas.agendaEquipe),
  ItemMenuPro('Financeiro', Icons.attach_money_rounded, Rotas.financeiroEquipe),
  ItemMenuPro('Página', Icons.apartment_outlined, Rotas.paginaDaClinica),
  ItemMenuPro('Mais', Icons.menu_rounded, Rotas.maisClinica),
];

int _indiceNav(Papel papel, String rota) {
  if (papel == Papel.psicologo) {
    if (rota == Rotas.agenda || rota == Rotas.disponibilidade) return 0;
    if (rota.startsWith(Rotas.pacientes)) return 1;
    if (rota == Rotas.financeiro) return 2;
    if (rota == Rotas.minhaPagina) return 3;
    return 4;
  }
  if (rota == Rotas.equipe) return 0;
  if (rota == Rotas.agendaEquipe) return 1;
  if (rota == Rotas.financeiroEquipe) return 2;
  if (rota == Rotas.paginaDaClinica) return 3;
  return 4;
}

void _sair(BuildContext context) {
  context.acoes.sair();
  irPara(context, Rotas.entrar);
}

/// Moldura das telas do psicólogo e da clínica: menu lateral no web e barra
/// inferior no celular (wireframes 09 a 20).
class ProShell extends StatelessWidget {
  const ProShell({
    super.key,
    required this.papel,
    required this.rota,
    required this.child,
    this.navInferior = true,
  });

  final Papel papel;
  final String rota;
  final Widget child;
  final bool navInferior;

  @override
  Widget build(BuildContext context) {
    if (context.isWide) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuLateral(papel: papel, rota: rota),
            Expanded(child: EntradaSuave(child: child)),
          ],
        ),
      );
    }
    final itens = papel == Papel.psicologo ? _navPsicologo : _navClinica;
    final indice = _indiceNav(papel, rota);
    return Scaffold(
      body: SafeArea(bottom: false, child: EntradaSuave(child: child)),
      bottomNavigationBar: navInferior
          ? BarraInferior(
              grupo: papel.name,
              indice: indice,
              itens: [
                for (final it in itens) ItemBarraInferior(it.icone, it.rotulo)
              ],
              onSelecionar: (i) {
                if (itens[i].rota != rota) irPara(context, itens[i].rota);
              },
            )
          : null,
    );
  }
}

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key, required this.papel, required this.rota});

  final Papel papel;
  final String rota;

  static const _alturaItem = 44.0;
  static const _espaco = 6.0;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final itens =
        papel == Papel.psicologo ? itensMenuPsicologo : itensMenuClinica;
    final clinica = store.clinicaAtual;
    final psicologo = papel == Papel.psicologo;
    final (nome, subtitulo) = psicologo
        ? (store.psicologoAtual.nome, clinica.nome)
        : ('Paula Souza', 'Administradora');
    final indice = itens
        .indexWhere((it) => rota == it.rota || rota.startsWith('${it.rota}/'));
    final alvo = indice < 0 ? -1.0 : indice * (_alturaItem + _espaco);
    final anterior = MemoriaIndicador.trocar('lateral-${papel.name}', alvo);

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.bordaSuave)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Como nos wireframes: na psicóloga o primeiro item fica centrado em
          // y = 118; na clínica, o cartão da clínica começa em y = 76.
          Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 16, psicologo ? 42 : 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PsiHubLogo(
                onTap: () =>
                    irPara(context, psicologo ? Rotas.agenda : Rotas.equipe),
              ),
            ),
          ),
          if (!psicologo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    fotoDaClinica(clinica, 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinica.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5, color: AppColors.texto),
                          ),
                          const Text('Conta da clínica',
                              style: AppText.pequeno),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  if (indice >= 0)
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: anterior < 0 ? alvo : anterior, end: alvo),
                      duration: duracaoIndicador,
                      curve: curvaIndicador,
                      builder: (_, y, __) => Positioned(
                        top: y,
                        left: 0,
                        right: 0,
                        height: _alturaItem,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.salvia,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  Column(
                    children: [
                      for (var i = 0; i < itens.length; i++)
                        _ItemMenu(
                          item: itens[i],
                          selecionado: i == indice,
                          onTap: () {
                            if (i != indice || rota != itens[i].rota) {
                              irPara(context, itens[i].rota);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          MenuConta(
            acima: true,
            opcoes: const [
              OpcaoMenu('config', 'Configurações', Icons.settings_outlined),
              OpcaoMenu('sair', 'Sair', Icons.logout_rounded, perigo: true),
            ],
            onSelecionar: (v) {
              if (v == 'config') {
                irPara(
                    context,
                    psicologo
                        ? Rotas.configuracoes
                        : Rotas.configuracoesClinica);
              } else {
                _sair(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 20),
              child: Row(
                children: [
                  if (psicologo)
                    fotoDoPsicologo(store.psicologoAtual, 44)
                  else
                    AvatarIniciais(nome, tamanho: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, color: AppColors.texto),
                        ),
                        Text(
                          subtitulo,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.item,
    required this.selecionado,
    required this.onTap,
  });

  final ItemMenuPro item;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Wireframes: item em cinza, selecionado em oliva escuro, mesmo peso.
    final cor = selecionado ? AppColors.olivaTexto : AppColors.textoSecundario;
    return Padding(
      padding: const EdgeInsets.only(bottom: MenuLateral._espaco),
      child: Semantics(
        selected: selecionado,
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            hoverColor: AppColors.salvia.withValues(alpha: 0.45),
            onTap: onTap,
            child: SizedBox(
              height: MenuLateral._alturaItem,
              child: Row(
                children: [
                  const SizedBox(width: 17),
                  Icone(item.icone, size: 18, color: cor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: cor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estrutura das páginas do painel: título, subtítulo, ações e conteúdo rolável.
class PaginaPro extends StatelessWidget {
  const PaginaPro({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acoes = const [],
    this.acoesMobile,
    this.antesDoTitulo,
    this.aoLadoDoTitulo,
    this.abaixoDoTitulo,
    required this.children,
  });

  /// Linha logo abaixo do título (ex.: endereço da página com "Copiar").
  final Widget? abaixoDoTitulo;

  final String titulo;
  final String? subtitulo;
  final List<Widget> acoes;

  /// Ações no celular; por padrão, só a primeira de [acoes].
  final List<Widget>? acoesMobile;
  final Widget? antesDoTitulo;

  /// Widget logo depois do título no web (ex.: navegação da semana).
  final Widget? aoLadoDoTitulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final visiveis = wide ? acoes : (acoesMobile ?? acoes.take(1).toList());
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(titulo, style: AppText.serif(wide ? 32 : 28)),
        ),
        if (subtitulo != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitulo!,
            style: TextStyle(
              fontSize: wide ? 15 : 14,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
        if (abaixoDoTitulo != null) ...[
          const SizedBox(height: 8),
          abaixoDoTitulo!
        ],
      ],
    );
    return SingleChildScrollView(
      padding: wide
          ? const EdgeInsets.fromLTRB(32, 28, 32, 40)
          : const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (antesDoTitulo != null) ...[
                antesDoTitulo!,
                const SizedBox(height: 14)
              ],
              // Botões centrados na altura do bloco de título (wireframes).
              Row(
                crossAxisAlignment: wide && subtitulo != null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (aoLadoDoTitulo != null && wide) ...[
                    titulos,
                    const SizedBox(width: 40),
                    Expanded(child: aoLadoDoTitulo!),
                  ] else
                    Expanded(child: titulos),
                  for (var i = 0; i < visiveis.length; i++) ...[
                    if (i > 0 || (aoLadoDoTitulo != null && wide))
                      const SizedBox(width: 12),
                    visiveis[i],
                  ],
                ],
              ),
              SizedBox(height: wide ? 20 : 10),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela "Mais" do celular, com os itens que não cabem na barra inferior.
class MaisScreen extends StatelessWidget {
  const MaisScreen({super.key, required this.papel});

  final Papel papel;

  @override
  Widget build(BuildContext context) {
    final itens = papel == Papel.psicologo
        ? [
            itensMenuPsicologo[1],
            itensMenuPsicologo[5],
            itensMenuPsicologo[6],
            itensMenuPsicologo[7],
          ]
        : [itensMenuClinica[4], itensMenuClinica[5]];
    final rota =
        papel == Papel.psicologo ? Rotas.maisPsicologo : Rotas.maisClinica;
    return ProShell(
      papel: papel,
      rota: rota,
      child: PaginaPro(
        titulo: 'Mais',
        children: [
          CartaoApp(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < itens.length; i++) ...[
                  if (i > 0) const Divider(indent: 20, endIndent: 20),
                  ListTile(
                    leading: Icone(itens[i].icone, color: AppColors.texto),
                    title: Text(itens[i].rotulo),
                    trailing: const Icone(Icons.chevron_right_rounded),
                    onTap: () => irPara(context, itens[i].rota),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CartaoApp(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading:
                  const Icone(Icons.logout_rounded, color: AppColors.vermelho),
              title: const Text('Sair',
                  style: TextStyle(color: AppColors.vermelho)),
              onTap: () => _sair(context),
            ),
          ),
        ],
      ),
    );
  }
}
