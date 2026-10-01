import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'cartoes.dart';

const _temasExplorar = [
  'Ansiedade',
  'Depressão',
  'Luto',
  'Casais',
  'Crianças',
  'TDAH'
];
const _temasRapidos = ['Ansiedade', 'Casais', 'Crianças', 'Luto'];

/// Início do paciente (wireframe 01): busca e psicólogos e clínicas em destaque.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _busca = TextEditingController();
  Modalidade? _modalidade;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _buscar([String? texto]) {
    irPara(
      context,
      Rotas.busca(texto: texto ?? _busca.text, modalidade: _modalidade?.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PacienteShell(
      secao: SecaoPaciente.inicio,
      child: context.isWide ? _web(context) : _mobile(context),
    );
  }

  Widget _web(BuildContext context) {
    final store = context.store;
    final largura = context.larguraTela;
    return ConteudoComRodape(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          _hero(largura >= 1180),
          const SizedBox(height: 33),
          CabecalhoSecao(
            titulo: 'Psicólogos em ',
            italico: 'destaque',
            subtitulo: 'Perfis patrocinados',
            acao: 'Ver todos',
            onAcao: () => irPara(context, Rotas.buscar),
          ),
          const SizedBox(height: 17),
          _destaques(store.emDestaque),
          const SizedBox(height: 28),
          CabecalhoSecao(
            titulo: 'Clínicas em ',
            italico: 'destaque',
            acao: 'Ver todas',
            onAcao: () => irPara(context, Rotas.clinicas),
          ),
          const SizedBox(height: 10),
          GradeResponsiva(
            larguraMinItem: 300,
            children: [
              for (final c in store.clinicas.where((c) => c.destaque))
                CartaoClinica(clinica: c),
            ],
          ),
          const SizedBox(height: 48),
          const TituloSerif('Explore por ',
              italico: 'especialidade', tamanho: 32),
          const SizedBox(height: 22),
          Wrap(
            spacing: 44,
            runSpacing: 12,
            children: [
              for (final t in _temasExplorar)
                _TemaGrande(
                  tema: t,
                  quantidade: store.contarPorTema(t),
                  onTap: () => _buscar(t),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _hero(bool comIlustracao) {
    // Wireframe 01: ilustração de 276 × 248 a 24 px das bordas, que define a
    // altura do bloco (296 px); o texto começa um pouco abaixo do topo.
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 24, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.salvia,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 20, bottom: comIlustracao ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: TituloSerif(
                      'Encontre quem ',
                      italico: 'cuida',
                      depois: ' de você',
                      tamanho: 52,
                      cor: AppColors.olivaTexto,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Psicólogos e clínicas com horários livres para agendar agora.',
                    style:
                        TextStyle(fontSize: 17.5, color: AppColors.olivaTexto),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: CampoTexto(
                          controller: _busca,
                          alto: true,
                          hint: 'Especialidade, abordagem ou nome',
                          icone: Icons.search_rounded,
                          acaoTeclado: TextInputAction.search,
                          onSubmitted: (_) => _buscar(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SeletorCaixa<String>(
                          valor: _modalidade?.rotulo,
                          hint: 'Modalidade',
                          altura: 58,
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
                      const SizedBox(width: 12),
                      BotaoPill('Buscar', altura: 58, onPressed: _buscar),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (comIlustracao) ...[
            const SizedBox(width: 56),
            const SizedBox(
              width: 276,
              height: 248,
              child: Ilustracao.encontro(raio: 24),
            ),
          ],
        ],
      ),
    );
  }

  Widget _destaques(List<Psicologo> destaques) {
    if (destaques.isEmpty) return const SizedBox.shrink();
    final principal = destaques.first;
    final outros = destaques.skip(1).take(2).toList();
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1150) {
          return SizedBox(
            height: 324,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                    flex: 21,
                    child: CartaoPsicologoDestaque(psicologo: principal)),
                for (final p in outros) ...[
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 10,
                    child: CartaoPsicologo(psicologo: p, preencherAltura: true),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
                height: 324,
                child: CartaoPsicologoDestaque(psicologo: principal)),
            const SizedBox(height: 24),
            GradeResponsiva(
              larguraMinItem: 280,
              maxColunas: 2,
              children: [for (final p in outros) CartaoPsicologo(psicologo: p)],
            ),
          ],
        );
      },
    );
  }

  Widget _mobile(BuildContext context) {
    final store = context.store;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Olá, ${primeiroNome(store.pacienteNome)}',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textoSecundario),
              ),
            ),
            const BotaoNotificacoes(papel: Papel.paciente),
          ],
        ),
        const TituloSerif(
          'Encontre quem\n',
          italico: 'cuida de você',
          tamanho: 30,
        ),
        const SizedBox(height: 20),
        CampoTexto(
          controller: _busca,
          hint: 'Especialidade ou nome',
          icone: Icons.search_rounded,
          acaoTeclado: TextInputAction.search,
          onSubmitted: (_) => _buscar(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _temasRapidos)
              InkWell(
                onTap: () => _buscar(t),
                borderRadius: BorderRadius.circular(8),
                child: TagChip(t),
              ),
          ],
        ),
        const SizedBox(height: 28),
        CabecalhoSecao(
          titulo: 'Psicólogos em ',
          italico: 'destaque',
          acao: 'Ver todos',
          tamanho: 20,
          onAcao: () => irPara(context, Rotas.buscar),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 297,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: store.emDestaque.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 250,
              child: CartaoPsicologo(
                psicologo: store.emDestaque[i],
                preencherAltura: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const CabecalhoSecao(
            titulo: 'Clínicas em ', italico: 'destaque', tamanho: 20),
        const SizedBox(height: 14),
        for (final c in store.clinicas.where((c) => c.destaque))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CartaoClinica(clinica: c, compacto: true),
          ),
      ],
    );
  }
}

class _TemaGrande extends StatelessWidget {
  const _TemaGrande(
      {required this.tema, required this.quantidade, required this.onTap});

  final String tema;
  final int quantidade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$tema, ${Fmt.plural(quantidade, 'psicólogo', 'psicólogos')}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tema, style: AppText.serif(40)),
              Padding(
                padding: const EdgeInsets.only(left: 3, top: 2),
                child: Text(
                  '$quantidade',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.lavanda),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
