import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../agenda_agendamento/confirmar_agendamento.dart';
import '../agenda_agendamento/seletor_horario.dart';

/// Perfil público do psicólogo com agendamento (wireframes 03 e 04).
class PerfilPsicologoScreen extends StatefulWidget {
  const PerfilPsicologoScreen(
      {super.key, required this.psicologoId, this.previa = false});

  final String psicologoId;

  /// Aberto pelo próprio psicólogo em "Ver página": sem agendamento.
  final bool previa;

  @override
  State<PerfilPsicologoScreen> createState() => _PerfilPsicologoScreenState();
}

class _PerfilPsicologoScreenState extends State<PerfilPsicologoScreen> {
  EscolhaHorario? _escolha;

  Psicologo? get _psicologo =>
      context.acoes.psicologoOuNulo(widget.psicologoId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = _psicologo;
    if (_escolha == null && p != null) {
      _escolha = escolhaInicial(context.acoes, p);
    }
  }

  Future<void> _agendar(Psicologo p) async {
    final e = _escolha!;
    final h = e.horario;
    if (h == null || widget.previa) return;
    final consulta = await confirmarAgendamento(
      context,
      psicologo: p,
      inicio: h,
      modalidade: e.modalidade,
    );
    if (consulta == null || !mounted) return;
    setState(() =>
        _escolha = escolhaInicial(context.acoes, p, modalidade: e.modalidade));
    await mostrarAgendamentoConfirmado(context, consulta, p);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = store.psicologoOuNulo(widget.psicologoId);
    if (p == null) {
      return PacienteShell(
        secao: SecaoPaciente.buscar,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Perfil não encontrado.', style: AppText.corpo),
              const SizedBox(height: 12),
              BotaoPill('Buscar psicólogos',
                  onPressed: () => irPara(context, Rotas.buscar)),
            ],
          ),
        ),
      );
    }
    final wide = context.isWide;
    final conteudo = wide ? _web(context, p) : _mobile(context, p);
    if (widget.previa) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Prévia da página · psihub.com.br/${p.slug}',
            style: const TextStyle(fontSize: 16),
          ),
          leading: IconButton(
            tooltip: 'Fechar prévia',
            icon: const Icone(Icons.close_rounded),
            onPressed: () => voltarOu(context, Rotas.minhaPagina),
          ),
        ),
        body: conteudo,
      );
    }
    return PacienteShell(
      secao: SecaoPaciente.buscar,
      navInferior: false,
      barraInferior: wide ? null : _barraAgendar(p),
      child: conteudo,
    );
  }

  // ------------------------------------------------------------------ web

  Widget _web(BuildContext context, Psicologo p) {
    return ConteudoComRodape(
      rodape: widget.previa ? const SizedBox(height: 48) : const RodapePsiHub(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          if (!widget.previa)
            Row(
              children: [
                LinkTexto(
                  'Buscar psicólogos',
                  tamanho: 13.5,
                  onTap: () => voltarOu(context, Rotas.buscar),
                ),
                Text(
                  ' ›  ${p.nome}',
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textoSecundario),
                ),
              ],
            ),
          const SizedBox(height: 4),
          _GaleriaWeb(psicologo: p),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, c) {
              final painel = _painelAgendamento(context, p);
              if (c.maxWidth >= 1040) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _colunaPrincipal(context, p)),
                    const SizedBox(width: 32),
                    SizedBox(width: 408, child: painel),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cabecalhoPerfil(p),
                  const SizedBox(height: 24),
                  painel,
                  const SizedBox(height: 16),
                  _colunaPrincipal(context, p, comCabecalho: false),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _cabecalhoPerfil(Psicologo p) {
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(32, 38, 32, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fotoDoPsicologo(p, 112),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                    header: true,
                    child: Text(p.nome,
                        style: AppText.serif(34,
                            familia: familiaDoTema(p.temaFonte)))),
                const SizedBox(height: 4),
                Text(
                  '${p.titulo} · CRP ${p.crp}',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 10),
                NotaInline(nota: p.nota, total: p.totalAvaliacoes),
                const SizedBox(height: 14),
                Text(
                  '${Fmt.plural(p.anosExperiencia, 'ano', 'anos')} de experiência · '
                  '${p.cidade} · ${rotuloModalidades(p.modalidades)}',
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 16),
                Etiquetas(_etiquetasPerfil(p), compacto: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _etiquetasPerfil(Psicologo p) => [
        ...p.especialidades,
        for (final pub in publicosAlvo)
          if (p.publicos.contains(pub) && !p.especialidades.contains(pub)) pub,
      ];

  Widget _colunaPrincipal(BuildContext context, Psicologo p,
      {bool comCabecalho = true}) {
    final store = context.store;
    final avaliacoes = store.avaliacoesDe(p.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comCabecalho) _cabecalhoPerfil(p),
        const SizedBox(height: 20),
        TituloSerif('Sobre', tamanho: 26, familia: familiaDoTema(p.temaFonte)),
        const SizedBox(height: 9),
        // No wireframe 03 o texto quebra antes da largura toda da coluna.
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(p.sobre,
                style: const TextStyle(
                    fontSize: 16.5, height: 1.6, color: AppColors.texto)),
          ),
        ),
        const SizedBox(height: 28),
        CartaoApp(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    flex: 4, child: _info('Abordagem', p.abordagemCompleta)),
                const VerticalDivider(width: 32),
                Expanded(
                    flex: 3,
                    child:
                        _info('Público atendido', juntarLista(_publicos(p)))),
                const VerticalDivider(width: 32),
                Expanded(
                  flex: 3,
                  child: _info(
                    'Valor da sessão',
                    '${Fmt.moeda(p.valorSessao)} · ${p.disponibilidade.duracao} min',
                  ),
                ),
              ],
            ),
          ),
        ),
        // A formação aparece só na prévia da "Minha página" (wireframe 14);
        // o perfil público do wireframe 03 não tem esse bloco.
        const SizedBox(height: 30),
        TituloSerif('O que dizem os ',
            italico: 'pacientes',
            tamanho: 26,
            familia: familiaDoTema(p.temaFonte)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 260, child: ResumoAvaliacoes(psicologo: p)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (avaliacoes.isEmpty)
                    const CartaoApp(
                        child: Text('Ainda não há comentários publicados.')),
                  for (final a in avaliacoes.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CartaoAvaliacao(avaliacao: a),
                    ),
                  LinkTexto(
                    'Ver todas as ${Fmt.plural(p.totalAvaliacoes, 'avaliação', 'avaliações')}',
                    onTap: () => _todasAvaliacoes(context, p),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        TituloSerif('Contato',
            tamanho: 26, familia: familiaDoTema(p.temaFonte)),
        const SizedBox(height: 16),
        CartaoApp(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinhaInfo(
                        icone: Icons.phone_outlined,
                        rotulo: 'WhatsApp',
                        valor: p.whatsapp,
                        larguraRotulo: 96,
                      ),
                      LinhaInfo(
                        icone: Icons.mail_outline_rounded,
                        rotulo: 'E-mail',
                        valor: p.email,
                        larguraRotulo: 96,
                      ),
                      LinhaInfo(
                        icone: Icons.place_outlined,
                        rotulo: 'Endereço',
                        valor: p.endereco,
                        larguraRotulo: 96,
                      ),
                      const SizedBox(height: 8),
                      BotaoPill(
                        'Chamar no WhatsApp',
                        icone: Icons.phone_outlined,
                        estilo: EstiloBotao.contorno,
                        compacto: true,
                        onPressed: () => _whatsapp(context, p),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 256,
                height: 168,
                child: Ilustracao.mapa(descricao: 'Mapa: ${p.endereco}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _publicos(Psicologo p) => [
        for (final pub in publicosAlvo)
          if (p.publicos.contains(pub)) pub
      ];

  Widget _info(String rotulo, String valor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textoSecundario)),
          const SizedBox(height: 8),
          Text(valor,
              style: const TextStyle(fontSize: 15.5, color: AppColors.texto)),
        ],
      );

  Widget _painelAgendamento(BuildContext context, Psicologo p) {
    final e = _escolha!;
    final cor = corDoTema(p.temaCor);
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(24, 17, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agendar consulta',
              style: AppText.serif(22, familia: familiaDoTema(p.temaFonte))),
          const SizedBox(height: 4),
          Text(
            'Sessão de ${p.disponibilidade.duracao} min · ${Fmt.moeda(p.valorSessao)}',
            style: const TextStyle(
                fontSize: 14.5, color: AppColors.textoSecundario),
          ),
          const SizedBox(height: 16),
          SeletorHorario(
            psicologo: p,
            escolha: e,
            cor: cor,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.salvia,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icone(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.texto),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resumoEscolha(e, p.disponibilidade.duracao),
                    style:
                        const TextStyle(fontSize: 14.5, color: AppColors.texto),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          BotaoPill(
            widget.previa ? 'Agendar consulta (prévia)' : 'Agendar consulta',
            expandir: true,
            altura: 52,
            cor: cor,
            onPressed:
                e.horario == null || widget.previa ? null : () => _agendar(p),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text('Horários riscados já estão ocupados',
                style: AppText.fraco),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ celular

  Widget _barraAgendar(Psicologo p) {
    final e = _escolha!;
    final h = e.horario;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bordaSuave)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              h == null
                  ? 'Escolha um dia e um horário'
                  : '${Fmt.diaCurto(h)} · ${Fmt.hora(h)} · ${e.modalidade.rotulo}',
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 10),
            BotaoPill(
              'Agendar consulta',
              expandir: true,
              altura: 52,
              cor: corDoTema(p.temaCor),
              onPressed: h == null ? null : () => _agendar(p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context, Psicologo p) {
    final store = context.store;
    final avaliacoes = store.avaliacoesDe(p.id);
    final favorito = store.favoritos.contains(p.id);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _GaleriaMobile(psicologo: p),
            if (!widget.previa) ...[
              Positioned(
                top: 16,
                left: 16,
                child: BotaoCircular(
                  icone: Icons.arrow_back_rounded,
                  tooltip: 'Voltar',
                  onPressed: () => voltarOu(context, Rotas.buscar),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: BotaoCircular(
                  icone: favorito
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  corIcone: favorito ? AppColors.vermelho : AppColors.texto,
                  tooltip: favorito
                      ? 'Remover dos favoritos'
                      : 'Salvar nos favoritos',
                  onPressed: () => context.acoes.alternarFavorito(p.id),
                ),
              ),
            ],
            Positioned(
              left: 16,
              bottom: -44,
              child: fotoDoPsicologo(p, 80),
            ),
          ],
        ),
        const SizedBox(height: 52),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                  header: true,
                  child: Text(p.nome,
                      style: AppText.serif(27,
                          familia: familiaDoTema(p.temaFonte)))),
              const SizedBox(height: 2),
              Text(
                '${p.titulo} · CRP ${p.crp}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 6),
              NotaInline(nota: p.nota, total: p.totalAvaliacoes, tamanho: 13),
              const SizedBox(height: 12),
              Etiquetas(_etiquetasPerfil(p).take(3).toList(), compacto: true),
              const SizedBox(height: 28),
              TituloSerif('Sobre mim',
                  tamanho: 24, familia: familiaDoTema(p.temaFonte)),
              const SizedBox(height: 8),
              _TextoExpansivel(p.sobre),
              const SizedBox(height: 28),
              TituloSerif('Horários disponíveis',
                  tamanho: 24, familia: familiaDoTema(p.temaFonte)),
              const SizedBox(height: 2),
              Text(
                'Sessão de ${p.disponibilidade.duracao} min · ${Fmt.moeda(p.valorSessao)}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textoSecundario),
              ),
              const SizedBox(height: 14),
              SeletorHorario(
                psicologo: p,
                escolha: _escolha!,
                cor: corDoTema(p.temaCor),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 32),
              TituloSerif('Avaliações',
                  tamanho: 24, familia: familiaDoTema(p.temaFonte)),
              const SizedBox(height: 4),
              NotaInline(nota: p.nota, total: p.totalAvaliacoes, tamanho: 13),
              const SizedBox(height: 14),
              for (final a in avaliacoes.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartaoAvaliacao(avaliacao: a),
                ),
              LinkTexto(
                'Ver todas as ${Fmt.plural(p.totalAvaliacoes, 'avaliação', 'avaliações')}',
                tamanho: 13.5,
                onTap: () => _todasAvaliacoes(context, p),
              ),
              const SizedBox(height: 32),
              TituloSerif('Contato',
                  tamanho: 24, familia: familiaDoTema(p.temaFonte)),
              const SizedBox(height: 12),
              CartaoApp(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _contatoMobile(
                        Icons.phone_outlined, '${p.whatsapp} · WhatsApp'),
                    _contatoMobile(Icons.mail_outline_rounded, p.email),
                    _contatoMobile(Icons.place_outlined, p.endereco),
                    const SizedBox(height: 10),
                    BotaoPill(
                      'Chamar no WhatsApp',
                      icone: Icons.phone_outlined,
                      estilo: EstiloBotao.contorno,
                      expandir: true,
                      onPressed: () => _whatsapp(context, p),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contatoMobile(IconData icone, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icone(icone, size: 18, color: AppColors.lavanda),
            const SizedBox(width: 12),
            Expanded(
              child: Text(texto,
                  style:
                      const TextStyle(fontSize: 14.5, color: AppColors.texto)),
            ),
          ],
        ),
      );

  void _whatsapp(BuildContext context, Psicologo p) {
    avisar(
        context, 'Na versão final, este botão abre o WhatsApp: ${p.whatsapp}.');
  }

  Future<void> _todasAvaliacoes(BuildContext context, Psicologo p) {
    final avaliacoes = context.acoes.avaliacoesDe(p.id);
    return abrirPainel<void>(
      context,
      builder: (_) => PainelConteudo(
        titulo: 'Avaliações de ${primeiroNome(p.nome)}',
        subtitulo: '${Fmt.nota(p.nota)} de média em '
            '${Fmt.plural(p.totalAvaliacoes, 'avaliação', 'avaliações')}',
        children: [
          ResumoAvaliacoes(psicologo: p, comCartao: false),
          const SizedBox(height: 20),
          for (final a in avaliacoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CartaoAvaliacao(avaliacao: a, borda: true),
            ),
          Text(
            avaliacoes.length < p.totalAvaliacoes
                ? 'As outras ${p.totalAvaliacoes - avaliacoes.length} avaliações '
                    'foram publicadas só com a nota, sem comentário.'
                : 'Todas as avaliações são de consultas realizadas.',
            style: AppText.pequeno,
          ),
        ],
      ),
    );
  }
}

/// Resumo com a nota média e a distribuição por estrelas.
class ResumoAvaliacoes extends StatelessWidget {
  const ResumoAvaliacoes(
      {super.key, required this.psicologo, this.comCartao = true});

  final Psicologo psicologo;
  final bool comCartao;

  @override
  Widget build(BuildContext context) {
    final p = psicologo;
    final total = p.totalAvaliacoes;
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(Fmt.nota(p.nota), style: AppText.serif(54, altura: 1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Estrelas(p.nota, tamanho: 17),
                  const SizedBox(height: 4),
                  Text(
                    Fmt.plural(total, 'avaliação', 'avaliações'),
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  child: Text(
                    '${5 - i}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ),
                const Icone(Icons.star_rounded,
                    size: 13, color: AppColors.estrela),
                const SizedBox(width: 10),
                Expanded(
                  child: BarraProgresso(
                    valor: total == 0 ? 0 : p.distribuicao[i] / total,
                    cor: AppColors.lavanda,
                    altura: 5,
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${p.distribuicao[i]}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    if (!comCartao) return conteudo;
    return CartaoApp(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), child: conteudo);
  }
}

/// Uma avaliação publicada ("Marina S. ★★★★★ há 2 semanas").
class CartaoAvaliacao extends StatelessWidget {
  const CartaoAvaliacao(
      {super.key, required this.avaliacao, this.borda = false});

  final Avaliacao avaliacao;
  final bool borda;

  @override
  Widget build(BuildContext context) {
    final a = avaliacao;
    final agora = context.store.agora;
    return CartaoApp(
      padding: const EdgeInsets.all(20),
      raio: 22,
      borda: borda ? const BorderSide(color: AppColors.bordaSuave) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarIniciais(a.autor, tamanho: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.autor,
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.texto),
                          ),
                        ),
                        const Flexible(
                          child:
                              StatusPonto('Consulta realizada', tamanho: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Estrelas(a.nota, tamanho: 13),
                        const SizedBox(width: 8),
                        Text(
                          Fmt.haQuanto(a.data, agora),
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textoFraco),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (a.texto.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(a.texto,
                style: const TextStyle(
                    fontSize: 14.5, height: 1.45, color: AppColors.texto)),
          ],
        ],
      ),
    );
  }
}

/// Foto [indice] da galeria: a primeira é o retrato, as outras mostram o consultório.
Widget fotoDaGaleria(
  Psicologo p,
  int indice, {
  double raio = 18,
  List<Widget> sobreposicoes = const [],
}) {
  if (indice == 0) {
    return Ilustracao.retrato(
      p.id,
      feminino: p.feminino,
      raio: raio,
      descricao: 'Foto principal de ${p.nome}',
      sobreposicoes: sobreposicoes,
    );
  }
  return Ilustracao.ambiente(
    varianteDaGaleria(p.id, indice),
    raio: raio,
    descricao: 'Foto ${indice + 1} de ${p.fotos}: consultório de ${p.nome}',
    sobreposicoes: sobreposicoes,
  );
}

class _GaleriaWeb extends StatelessWidget {
  const _GaleriaWeb({required this.psicologo});

  final Psicologo psicologo;

  @override
  Widget build(BuildContext context) {
    const espaco = 16.0;
    final p = psicologo;
    final botaoFotos = Positioned(
      right: 16,
      bottom: 12,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _verFotos(context, p),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icone(Icons.photo_library_outlined, size: 17),
                const SizedBox(width: 8),
                Text('Ver ${p.fotos} fotos',
                    style: const TextStyle(fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      height: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: fotoDaGaleria(p, 0, raio: 22)),
          const SizedBox(width: espaco),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: fotoDaGaleria(p, 1)),
                      const SizedBox(width: espaco),
                      Expanded(child: fotoDaGaleria(p, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: espaco),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: fotoDaGaleria(p, 3)),
                      const SizedBox(width: espaco),
                      Expanded(
                          child:
                              fotoDaGaleria(p, 4, sobreposicoes: [botaoFotos])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _verFotos(BuildContext context, Psicologo p) {
  return abrirPainel<void>(
    context,
    larguraMax: 760,
    builder: (_) => PainelConteudo(
      titulo: 'Fotos de ${primeiroNome(p.nome)}',
      subtitulo:
          'Imagens de exemplo: as fotos reais entram com o armazenamento de arquivos.',
      children: [
        GradeResponsiva(
          larguraMinItem: 180,
          maxColunas: 3,
          espaco: 12,
          children: [
            for (var i = 0; i < p.fotos; i++)
              SizedBox(height: 150, child: fotoDaGaleria(p, i, raio: 16)),
          ],
        ),
      ],
    ),
  );
}

class _GaleriaMobile extends StatefulWidget {
  const _GaleriaMobile({required this.psicologo});

  final Psicologo psicologo;

  @override
  State<_GaleriaMobile> createState() => _GaleriaMobileState();
}

class _GaleriaMobileState extends State<_GaleriaMobile> {
  int _pagina = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.psicologo;
    final total = p.fotos;
    return SizedBox(
      height: 232,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: total,
            onPageChanged: (i) => setState(() => _pagina = i),
            itemBuilder: (_, i) => fotoDaGaleria(p, i, raio: 0),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Foto ${_pagina + 1} de $total',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < total.clamp(0, 5); i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _pagina.clamp(0, 4)
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.55),
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

class _TextoExpansivel extends StatefulWidget {
  const _TextoExpansivel(this.texto);

  final String texto;

  @override
  State<_TextoExpansivel> createState() => _TextoExpansivelState();
}

class _TextoExpansivelState extends State<_TextoExpansivel> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.texto,
          maxLines: _aberto ? null : 4,
          overflow: _aberto ? null : TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 15, height: 1.55, color: AppColors.texto),
        ),
        const SizedBox(height: 4),
        LinkTexto(
          _aberto ? 'Ler menos' : 'Ler mais',
          tamanho: 13.5,
          onTap: () => setState(() => _aberto = !_aberto),
        ),
      ],
    );
  }
}
