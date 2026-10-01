import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../comum/especialidades.dart';

const _abordagens = [
  'TCC',
  'Psicanálise',
  'Gestalt-terapia',
  'Terapia do esquema',
  'Terapia sistêmica',
  'Análise do comportamento',
  'Abordagem centrada na pessoa',
  'Ludoterapia',
];

/// Rascunho da página enquanto o psicólogo edita.
class _Rascunho {
  _Rascunho.de(Psicologo p)
      : nome = TextEditingController(text: p.nome),
        crp = TextEditingController(text: p.crp),
        cidade = TextEditingController(text: p.cidade),
        sobre = TextEditingController(text: p.sobre),
        slug = p.slug,
        anos = p.anosExperiencia,
        especialidades = [...p.especialidades],
        publicos = {...p.publicos},
        abordagem = p.abordagem,
        modalidades = {...p.modalidades},
        temaCor = p.temaCor,
        temaFonte = p.temaFonte;

  final TextEditingController nome;
  final TextEditingController crp;
  final TextEditingController cidade;
  final TextEditingController sobre;
  String slug;
  int anos;
  List<String> especialidades;
  Set<String> publicos;
  String abordagem;
  Set<Modalidade> modalidades;
  int temaCor;
  int temaFonte;

  void dispose() {
    nome.dispose();
    crp.dispose();
    cidade.dispose();
    sobre.dispose();
  }
}

/// Minha página: edição da página pública do psicólogo (wireframe 14).
class MinhaPaginaScreen extends StatefulWidget {
  const MinhaPaginaScreen({super.key});

  @override
  State<MinhaPaginaScreen> createState() => _MinhaPaginaScreenState();
}

class _MinhaPaginaScreenState extends State<MinhaPaginaScreen> {
  late final _Rascunho _r = _Rascunho.de(context.acoes.psicologoAtual);

  /// Avisa os painéis abertos (celular) que o rascunho mudou.
  final _versao = ValueNotifier<int>(0);
  bool _alterado = false;
  bool _previaCelular = false;

  @override
  void dispose() {
    _r.dispose();
    _versao.dispose();
    super.dispose();
  }

  void _mudar(VoidCallback f) {
    setState(() {
      f();
      _alterado = true;
    });
    _versao.value++;
  }

  void _publicar() {
    if (_r.nome.text.trim().length < 3) {
      avisar(context, 'Informe o seu nome antes de publicar.');
      return;
    }
    if (!RegExp(r'^\d{2}/\d{4,6}$').hasMatch(_r.crp.text.trim())) {
      avisar(context, 'O CRP precisa estar no formato 00/00000.');
      return;
    }
    context.acoes.publicarPagina(
      nome: _r.nome.text,
      crp: _r.crp.text,
      anos: _r.anos,
      cidade: _r.cidade.text,
      especialidades: _r.especialidades,
      publicos: _r.publicos,
      abordagem: _r.abordagem,
      modalidades: _r.modalidades,
      sobre: _r.sobre.text,
      temaCor: _r.temaCor,
      temaFonte: _r.temaFonte,
      slug: _r.slug,
    );
    setState(() => _alterado = false);
    avisar(context, 'Página publicada em psihub.com.br/${_r.slug}.');
  }

  void _verPagina() {
    if (_alterado) {
      avisar(context,
          'A página mostra a versão publicada. Publique para ver as alterações.');
    }
    abrirTela<void>(context,
        '${Rotas.perfilPsicologo(context.acoes.psicologoAtual.id)}?previa=1');
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: 'https://psihub.com.br/${_r.slug}'));
    avisar(context, 'Endereço copiado.');
  }

  Future<void> _editarEndereco() async {
    final novo = await abrirPainel<String>(context,
        larguraMax: 480, builder: (_) => _EditarEndereco(slug: _r.slug));
    if (novo != null) _mudar(() => _r.slug = novo);
  }

  Future<void> _adicionarEspecialidade() async {
    final e = await pedirEspecialidade(context, jaTem: _r.especialidades);
    if (e != null && !_r.especialidades.contains(e)) {
      _mudar(() => _r.especialidades.add(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final linkEndereco = Tooltip(
      message: 'Editar o endereço da página',
      child: InkWell(
        onTap: _editarEndereco,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'psihub.com.br/${_r.slug}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textoSecundario),
          ),
        ),
      ),
    );
    final endereco = Row(
      children: [
        if (wide)
          Flexible(child: linkEndereco)
        else
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: linkEndereco),
          ),
        if (wide) const SizedBox(width: 60),
        LinkTexto('Copiar', onTap: _copiar),
      ],
    );
    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.minhaPagina,
      child: PaginaPro(
        titulo: 'Minha página',
        abaixoDoTitulo: endereco,
        acoes: [
          if (_alterado)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SoftChip('Alterações não publicadas',
                  fundo: AppColors.lavandaClaro, cor: AppColors.lavandaEscuro),
            ),
          BotaoPill('Ver página',
              estilo: EstiloBotao.contorno, onPressed: _verPagina),
          BotaoPill('Publicar alterações', onPressed: _publicar),
        ],
        acoesMobile: [
          BotaoPill('Publicar', compacto: true, onPressed: _publicar)
        ],
        children: wide ? [_web()] : _mobile(),
      ),
    );
  }

  // ---------------------------------------------------------------- web

  Widget _web() {
    return LayoutBuilder(
      builder: (context, c) {
        final esquerda = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // No wireframe os campos quase encostam no fim deste cartão.
            CartaoApp(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: _secaoInformacoes()),
            const SizedBox(height: 16),
            CartaoApp(child: _secaoAtendimento()),
            const SizedBox(height: 16),
            CartaoApp(child: _secaoSobre()),
          ],
        );
        final direita = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CartaoApp(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
                child: _secaoTema()),
            const SizedBox(height: 16),
            CartaoApp(child: _secaoPrevia()),
          ],
        );
        if (c.maxWidth < 1040) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [esquerda, const SizedBox(height: 16), direita],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 480, child: esquerda),
            const SizedBox(width: 24),
            Expanded(child: direita),
          ],
        );
      },
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 19, color: AppColors.texto)),
      );

  Widget _secaoInformacoes({bool comTitulo = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comTitulo) _titulo('Informações'),
        Row(
          children: [
            fotoDoPsicologo(context.store.psicologoAtual, 80),
            const SizedBox(width: 16),
            BotaoPill(
              'Trocar foto',
              estilo: EstiloBotao.contorno,
              compacto: true,
              altura: 42,
              onPressed: () => avisar(context,
                  'O envio de fotos entra com o armazenamento de arquivos.'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _galeria(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoTexto(
                controller: _r.nome,
                rotulo: 'Nome',
                onChanged: (_) => _mudar(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CampoTexto(
                controller: _r.crp,
                rotulo: 'CRP',
                onChanged: (_) => _mudar(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SeletorCaixa<int>(
                rotuloCampo: 'Experiência',
                valor: _r.anos,
                opcoes: [for (var i = 1; i <= 40; i++) i],
                rotulo: (n) => Fmt.plural(n, 'ano', 'anos'),
                onChanged: (n) => _mudar(() => _r.anos = n),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CampoTexto(
                controller: _r.cidade,
                rotulo: 'Cidade',
                onChanged: (_) => _mudar(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _galeria() {
    final p = context.store.psicologoAtual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Ilustracao.ambiente(
                varianteDaGaleria(p.id, i + 1),
                largura: 52,
                altura: 52,
                raio: 10,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Galeria · ${p.fotos} fotos',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textoSecundario),
            ),
            const SizedBox(width: 10),
            LinkTexto(
              'Gerenciar',
              tamanho: 12.5,
              onTap: () => avisar(
                  context, 'A galeria entra com o armazenamento de arquivos.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secaoAtendimento({bool comTitulo = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comTitulo) _titulo('Atendimento'),
        CampoRotulado(
          rotulo: 'Especialidades',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in _r.especialidades)
                TagChip(e,
                    onRemover: () => _mudar(() => _r.especialidades.remove(e))),
              LinkTexto('Adicionar',
                  icone: Icons.add_rounded, onTap: _adicionarEspecialidade),
            ],
          ),
        ),
        const SizedBox(height: 18),
        CampoRotulado(
          rotulo: 'Público-alvo',
          child: Wrap(
            spacing: 12,
            children: [
              for (final p in publicosAlvo)
                LinhaCheck(
                  rotulo: p,
                  valor: _r.publicos.contains(p),
                  onChanged: (v) => _mudar(
                      () => v ? _r.publicos.add(p) : _r.publicos.remove(p)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SeletorCaixa<String>(
                rotuloCampo: 'Abordagem',
                valor: _r.abordagem,
                opcoes: _abordagens,
                rotulo: (s) => s,
                onChanged: (s) => _mudar(() => _r.abordagem = s),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CampoRotulado(
                rotulo: 'Modalidade',
                child: Wrap(
                  spacing: 16,
                  children: [
                    for (final m in Modalidade.values)
                      LinhaCheck(
                        rotulo: m.rotulo,
                        valor: _r.modalidades.contains(m),
                        onChanged: (v) {
                          if (!v && _r.modalidades.length == 1) return;
                          _mudar(() => v
                              ? _r.modalidades.add(m)
                              : _r.modalidades.remove(m));
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _secaoSobre({bool comTitulo = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comTitulo) _titulo('Sobre mim'),
        CampoTexto(
          controller: _r.sobre,
          linhas: 6,
          maxLength: 600,
          contador: true,
          hint: 'Conte como você trabalha e quem você atende',
          onChanged: (_) => _mudar(() {}),
        ),
      ],
    );
  }

  Widget _cores({bool compacto = false}) {
    final tamanho = compacto ? 38.0 : 44.0;
    final itens = [
      for (var i = 0; i < temasDePagina.length; i++)
        Semantics(
          button: true,
          selected: _r.temaCor == i,
          label: 'Cor ${temasDePagina[i].$1}',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _mudar(() => _r.temaCor = i),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: FormaFolha.raio(tamanho + 10),
                      border: Border.all(
                        color: _r.temaCor == i
                            ? AppColors.texto
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child:
                        FormaFolha(tamanho: tamanho, cor: temasDePagina[i].$2),
                  ),
                  const SizedBox(height: 1),
                  Text(temasDePagina[i].$1,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
    ];
    if (compacto) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: itens,
      );
    }
    // O anel da cor escolhida fica para fora da margem (wireframe 14).
    return Transform.translate(
      offset: const Offset(-7, 0),
      child: Wrap(spacing: 14, runSpacing: 12, children: itens),
    );
  }

  Widget _fontes() {
    return Row(
      children: [
        for (var i = 0; i < fontesDeTitulo.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              button: true,
              selected: _r.temaFonte == i,
              child: Material(
                color: _r.temaFonte == i ? AppColors.oliva : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: _r.temaFonte == i
                          ? AppColors.oliva
                          : AppColors.borda),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _mudar(() => _r.temaFonte = i),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      // Cada opção aparece na própria fonte (wireframe 14).
                      child: Text(
                        fontesDeTitulo[i],
                        style: AppText.serif(
                          16,
                          familia: familiaDoTema(i),
                          cor: _r.temaFonte == i
                              ? Colors.white
                              : AppColors.texto,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _secaoTema() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _titulo('Tema da página'),
        const Text('Cor principal', style: AppText.rotulo),
        const SizedBox(height: 2),
        _cores(),
        const SizedBox(height: 9),
        const Text('Fonte dos títulos', style: AppText.rotulo),
        const SizedBox(height: 5),
        Row(children: [SizedBox(width: 384, child: _fontes())]),
      ],
    );
  }

  Widget _secaoPrevia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
                child: Text('Prévia', style: TextStyle(fontSize: 19))),
            SegmentoPill<bool>(
              opcoes: const [false, true],
              valor: _previaCelular,
              expandir: false,
              altura: 38,
              rotulo: (c) => c ? 'Celular' : 'Computador',
              onChanged: (c) => setState(() => _previaCelular = c),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: _previaCelular ? 340 : double.infinity),
            child: _PreviaPagina(rascunho: _r, celular: _previaCelular),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- celular

  List<Widget> _mobile() {
    final titulo = context.store.psicologoAtual.titulo;
    return [
      CartaoApp(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                fotoDoPsicologo(context.store.psicologoAtual, 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_r.nome.text, style: AppText.serif(22)),
                      Text(titulo, style: AppText.pequeno),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: Etiquetas(_r.especialidades.take(2).toList(),
                        compacto: true)),
                BotaoPill('Ver página',
                    estilo: EstiloBotao.contorno,
                    compacto: true,
                    onPressed: _verPagina),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const TituloSerif('Tema da página', tamanho: 22),
      const SizedBox(height: 12),
      _cores(compacto: true),
      const SizedBox(height: 12),
      _fontes(),
      const SizedBox(height: 20),
      CartaoApp(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            _item(
                'Informações',
                'Foto, nome, CRP, cidade',
                () => _editarSecao(
                    'Informações', () => _secaoInformacoes(comTitulo: false))),
            const Divider(),
            _item(
                'Atendimento',
                'Especialidades, público, modalidade',
                () => _editarSecao(
                    'Atendimento', () => _secaoAtendimento(comTitulo: false))),
            const Divider(),
            _item(
                'Sobre mim',
                'Apresentação e formação',
                () => _editarSecao(
                    'Sobre mim', () => _secaoSobre(comTitulo: false))),
            const Divider(),
            _item('Endereço da página', 'psihub.com.br/${_r.slug}',
                _editarEndereco),
          ],
        ),
      ),
    ];
  }

  Widget _item(String titulo, String subtitulo, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 16)),
                  Text(subtitulo, style: AppText.pequeno),
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

  Future<void> _editarSecao(String titulo, Widget Function() conteudo) {
    return abrirPainel<void>(
      context,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: _versao,
        builder: (ctx, _, __) => PainelConteudo(
          titulo: titulo,
          acoes: BotaoPill('Concluir',
              expandir: true, onPressed: () => Navigator.of(ctx).pop()),
          children: [conteudo()],
        ),
      ),
    );
  }
}

class _PreviaPagina extends StatelessWidget {
  const _PreviaPagina({required this.rascunho, required this.celular});

  final _Rascunho rascunho;
  final bool celular;

  @override
  Widget build(BuildContext context) {
    final r = rascunho;
    final cor = corDoTema(r.temaCor);
    final p = context.store.psicologoAtual;
    final horarios = ['08:00', '09:00', '11:00', '14:30', '15:30', '17:30'];
    // A prévia já mostra a fonte escolhida, antes de publicar.
    final familia = familiaDoTema(r.temaFonte);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.creme,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bordaSuave),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Text(r.nome.text,
                        style: AppText.serif(17, familia: familia),
                        overflow: TextOverflow.ellipsis)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: cor, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    celular ? 'Agendar' : 'Agendar consulta',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    fotoDoPsicologo(
                        context.store.psicologoAtual, celular ? 56 : 72),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.nome.text,
                              style: AppText.serif(celular ? 22 : 28,
                                  cor: AppColors.texto, familia: familia)),
                          Text('${p.titulo} · CRP ${r.crp.text}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textoSecundario)),
                          const SizedBox(height: 6),
                          Etiquetas(
                              r.especialidades.take(celular ? 2 : 3).toList(),
                              compacto: true),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Sobre mim', style: AppText.serif(19, familia: familia)),
                const SizedBox(height: 6),
                Text(
                  r.sobre.text,
                  maxLines: celular ? 5 : 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                Text('Horários disponíveis',
                    style: AppText.serif(19, familia: familia)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in horarios)
                      Container(
                        width: 76,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: h == '14:30' ? cor : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: h == '14:30' ? cor : AppColors.borda),
                        ),
                        child: Text(
                          h,
                          style: TextStyle(
                              fontSize: 12.5,
                              color: h == '14:30'
                                  ? Colors.white
                                  : AppColors.texto),
                        ),
                      ),
                  ],
                ),
                if (p.formacao.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Formação',
                            style: AppText.serif(16, familia: familia)),
                        const SizedBox(height: 6),
                        for (final f in p.formacao)
                          Text(f,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textoSecundario,
                                  height: 1.5)),
                      ],
                    ),
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

class _EditarEndereco extends StatefulWidget {
  const _EditarEndereco({required this.slug});

  final String slug;

  @override
  State<_EditarEndereco> createState() => _EditarEnderecoState();
}

class _EditarEnderecoState extends State<_EditarEndereco> {
  late final _texto = TextEditingController(text: widget.slug);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = gerarSlug(_texto.text);
    return PainelConteudo(
      titulo: 'Endereço da página',
      subtitulo: 'Use letras, números e hífens.',
      acoes: AcoesPainel(
        primario: 'Salvar endereço',
        onPrimario:
            slug.length < 3 ? null : () => Navigator.of(context).pop(slug),
      ),
      children: [
        CampoTexto(
          controller: _texto,
          rotulo: 'Endereço',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Text('psihub.com.br/$slug',
            style: const TextStyle(fontSize: 14, color: AppColors.lavanda)),
      ],
    );
  }
}
