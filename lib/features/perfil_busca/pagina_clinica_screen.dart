import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'cartoes.dart';

/// Página institucional da clínica (wireframe 07).
class PaginaClinicaScreen extends StatefulWidget {
  const PaginaClinicaScreen({super.key, required this.clinicaId});

  final String clinicaId;

  @override
  State<PaginaClinicaScreen> createState() => _PaginaClinicaScreenState();
}

class _PaginaClinicaScreenState extends State<PaginaClinicaScreen> {
  final _sobre = GlobalKey();
  final _equipe = GlobalKey();
  final _local = GlobalKey();
  String? _especialidade;
  String? _publico;
  Modalidade? _modalidade;

  void _rolarPara(GlobalKey chave) {
    final ctx = chave.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Psicologo> _filtrar(List<Psicologo> equipe) => equipe.where((p) {
        if (_especialidade != null &&
            !p.especialidades.contains(_especialidade)) {
          return false;
        }
        if (_publico != null && !p.publicos.contains(_publico)) return false;
        if (_modalidade != null && !p.modalidades.contains(_modalidade)) {
          return false;
        }
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = store.clinicaOuNula(widget.clinicaId);
    if (c == null) {
      return Scaffold(
        body: Center(
          child: BotaoPill('Voltar para o início',
              onPressed: () => irPara(context, Rotas.inicio)),
        ),
      );
    }
    final equipe = store.psicologosDaClinica(c.id);
    final modalidades = {for (final p in equipe) ...p.modalidades};
    return Scaffold(
      body: SafeArea(
        child: context.isWide
            ? _web(context, c, equipe, modalidades)
            : _mobile(context, c, equipe, modalidades),
      ),
    );
  }

  Widget _logo(Clinica c, double tamanho) => Container(
        width: tamanho,
        height: tamanho,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.oliva,
          borderRadius: FormaFolha.raio(tamanho),
        ),
        child: Text(
          c.iniciaisNome,
          style: TextStyle(color: Colors.white, fontSize: tamanho * 0.32),
        ),
      );

  Widget _voltar(BuildContext context) => IconButton(
        tooltip: 'Voltar',
        onPressed: () => voltarOu(context, Rotas.inicio),
        icon: const Icone(Icons.arrow_back_rounded),
      );

  Widget _web(
    BuildContext context,
    Clinica c,
    List<Psicologo> equipe,
    Set<Modalidade> modalidades,
  ) {
    final filtrados = _filtrar(equipe);
    final especialidades =
        {for (final p in equipe) ...p.especialidades}.toList()..sort();
    return Column(
      children: [
        Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.bordaSuave)),
          ),
          child: Centralizado(
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  _voltar(context),
                  const SizedBox(width: 4),
                  _logo(c, 36),
                  const SizedBox(width: 12),
                  Text(c.nome, style: AppText.serif(24)),
                  const Spacer(),
                  for (final (rotulo, chave) in [
                    ('Sobre', _sobre),
                    ('Equipe', _equipe),
                    ('Localização', _local)
                  ])
                    TextButton(
                      onPressed: () => _rolarPara(chave),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.texto),
                      child: Text(rotulo, style: const TextStyle(fontSize: 15)),
                    ),
                  const SizedBox(width: 20),
                  BotaoPill('Agendar consulta',
                      onPressed: () => _rolarPara(_equipe)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: EntradaSuave(
            child: ConteudoComRodape(
              rodape: const _RodapeClinica(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  CartaoApp(
                    key: _sobre,
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: fotoDaClinica(c, 112),
                        ),
                        const SizedBox(width: 26),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 17),
                              Semantics(
                                  header: true,
                                  child:
                                      Text(c.nome, style: AppText.serif(36))),
                              const SizedBox(height: 4),
                              Text(
                                'Clínica de psicologia · ${c.bairro}, ${c.cidade}',
                                style: const TextStyle(
                                    fontSize: 16.5,
                                    color: AppColors.textoSecundario),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 44,
                                runSpacing: 8,
                                children: [
                                  _iconeTexto(Icons.place_outlined, c.endereco),
                                  _iconeTexto(Icons.videocam_outlined,
                                      rotuloModalidades(modalidades)),
                                  _iconeTexto(
                                    Icons.person_outline_rounded,
                                    Fmt.plural(equipe.length, 'psicólogo',
                                        'psicólogos'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // No wireframe 07 o texto quebra perto de 630 px.
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 630),
                                child: Text(
                                  c.descricao,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.55,
                                      color: AppColors.texto),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          key: _local,
                          width: 296,
                          height: 184,
                          child:
                              Ilustracao.mapa(descricao: 'Mapa: ${c.endereco}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TituloSerif('Nossa ',
                      key: _equipe, italico: 'equipe', tamanho: 32),
                  const SizedBox(height: 6),
                  const Text(
                    'Escolha um profissional para ver os horários livres e agendar.',
                    style: TextStyle(
                        fontSize: 15.5, color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 260,
                        child: SeletorCaixa<String>(
                          valor: _especialidade,
                          hint: 'Todas as especialidades',
                          opcoes: [
                            'Todas as especialidades',
                            ...especialidades
                          ],
                          rotulo: (s) => s,
                          onChanged: (s) => setState(
                            () => _especialidade =
                                s.startsWith('Todas') ? null : s,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: SeletorCaixa<String>(
                          valor: _publico,
                          hint: 'Público-alvo',
                          opcoes: const ['Todos os públicos', ...publicosAlvo],
                          rotulo: (s) => s,
                          onChanged: (s) => setState(
                            () => _publico = s.startsWith('Todos') ? null : s,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 200,
                        child: SeletorCaixa<String>(
                          valor: _modalidade?.rotulo,
                          hint: 'Modalidade',
                          opcoes: const [
                            'Todas as modalidades',
                            'Online',
                            'Presencial'
                          ],
                          rotulo: (s) => s,
                          onChanged: (s) => setState(() {
                            _modalidade = switch (s) {
                              'Online' => Modalidade.online,
                              'Presencial' => Modalidade.presencial,
                              _ => null,
                            };
                          }),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.plural(filtrados.length, 'psicólogo', 'psicólogos'),
                        style: const TextStyle(
                            fontSize: 14.5, color: AppColors.textoSecundario),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (filtrados.isEmpty)
                    const CartaoApp(
                      child:
                          Text('Nenhum psicólogo da equipe com esses filtros.'),
                    )
                  else
                    GradeResponsiva(
                      larguraMinItem: 330,
                      children: [
                        for (final p in filtrados)
                          CartaoMembroClinica(psicologo: p)
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconeTexto(IconData icone, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icone(icone, size: 19, color: AppColors.textoSecundario),
          const SizedBox(width: 8),
          Text(texto,
              style: const TextStyle(fontSize: 15, color: AppColors.texto)),
        ],
      );

  Widget _mobile(
    BuildContext context,
    Clinica c,
    List<Psicologo> equipe,
    Set<Modalidade> modalidades,
  ) {
    final filtrados = _filtrar(equipe);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
          child: Row(
            children: [
              _voltar(context),
              _logo(c, 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.serif(19),
                ),
              ),
              BotaoPill('Agendar',
                  compacto: true, onPressed: () => _rolarPara(_equipe)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: EntradaSuave(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      fotoDaClinica(c, 80),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.nome, style: AppText.serif(26)),
                            Text(
                              '${c.bairro}, ${c.cidade}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textoSecundario),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icone(Icons.person_outline_rounded,
                                    size: 16, color: AppColors.textoSecundario),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${Fmt.plural(equipe.length, 'psicólogo', 'psicólogos')} · '
                                    '${rotuloModalidades(modalidades)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textoSecundario),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(c.descricao,
                      style: const TextStyle(fontSize: 15, height: 1.55)),
                  const SizedBox(height: 26),
                  TituloSerif('Nossa equipe', key: _equipe, tamanho: 24),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChipFiltro(
                          'Filtros',
                          icone: Icons.tune_rounded,
                          selecionado: false,
                          onTap: () => setState(() {
                            _especialidade = null;
                            _publico = null;
                            _modalidade = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        ChipFiltro(
                          'Ansiedade',
                          selecionado: _especialidade == 'Ansiedade',
                          onTap: () => setState(
                            () => _especialidade = _especialidade == 'Ansiedade'
                                ? null
                                : 'Ansiedade',
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChipFiltro(
                          'Adultos',
                          selecionado: _publico == 'Adultos',
                          onTap: () => setState(() => _publico =
                              _publico == 'Adultos' ? null : 'Adultos'),
                        ),
                        const SizedBox(width: 8),
                        ChipFiltro(
                          'Online',
                          selecionado: _modalidade == Modalidade.online,
                          onTap: () => setState(
                            () => _modalidade = _modalidade == Modalidade.online
                                ? null
                                : Modalidade.online,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtrados.isEmpty)
                    const CartaoApp(
                        child: Text(
                            'Nenhum psicólogo da equipe com esses filtros.')),
                  for (final p in filtrados)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CartaoMembroClinica(psicologo: p),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rodapé da página da clínica ("Página criada com PsiHub").
class _RodapeClinica extends StatelessWidget {
  const _RodapeClinica();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(),
          SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Página criada com', style: AppText.fraco),
              SizedBox(width: 8),
              PsiHubLogo(tamanho: 15),
            ],
          ),
          SizedBox(height: 28),
        ],
      ),
    );
  }
}
