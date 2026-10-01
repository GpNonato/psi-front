import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'cartoes.dart';

enum Ordenacao {
  relevantes('Mais relevantes'),
  avaliados('Melhor avaliados'),
  proximo('Próximo horário'),
  experiencia('Mais experiência');

  const Ordenacao(this.rotulo);
  final String rotulo;
}

enum FiltroDia { hoje, semana }

/// Filtros da busca (RF006, RF019).
class FiltrosBusca {
  String texto = '';
  Set<String> publicos = {};
  Set<Modalidade> modalidades = {};
  bool consultorio = true;
  bool clinica = true;
  double? notaMinima;
  FiltroDia? disponibilidade;
  Ordenacao ordenacao = Ordenacao.relevantes;

  int get ativos =>
      publicos.length +
      modalidades.length +
      (consultorio && clinica ? 0 : 1) +
      (notaMinima == null ? 0 : 1) +
      (disponibilidade == null ? 0 : 1);

  void limpar() {
    publicos = {};
    modalidades = {};
    consultorio = true;
    clinica = true;
    notaMinima = null;
    disponibilidade = null;
  }

  List<Psicologo> aplicar(AppStore store) {
    final q = normalizar(texto);
    final lista = store.psicologos.where((p) {
      if (q.isNotEmpty) {
        final campos = [
          p.nome,
          p.abordagem,
          p.abordagemCompleta,
          ...p.especialidades,
          ...p.publicos,
        ].map(normalizar);
        if (!campos.any((c) => c.contains(q))) return false;
      }
      if (publicos.isNotEmpty && !p.publicos.any(publicos.contains)) {
        return false;
      }
      if (modalidades.isNotEmpty && !p.modalidades.any(modalidades.contains)) {
        return false;
      }
      if (consultorio != clinica) {
        final atendeEmClinica = p.clinicaId != null;
        if (clinica != atendeEmClinica) return false;
      }
      if (notaMinima != null && p.nota < notaMinima!) return false;
      if (disponibilidade == FiltroDia.hoje &&
          !store.temHorarioNoDia(p, store.agora)) {
        return false;
      }
      if (disponibilidade == FiltroDia.semana && !store.temHorarioNaSemana(p)) {
        return false;
      }
      return true;
    }).toList();

    int porNota(Psicologo a, Psicologo b) {
      final n = b.nota.compareTo(a.nota);
      return n != 0 ? n : b.totalAvaliacoes.compareTo(a.totalAvaliacoes);
    }

    switch (ordenacao) {
      case Ordenacao.relevantes:
        lista.sort((a, b) {
          if (a.destaque != b.destaque) return a.destaque ? -1 : 1;
          return porNota(a, b);
        });
      case Ordenacao.avaliados:
        lista.sort(porNota);
      case Ordenacao.proximo:
        final distante = DateTime(9999);
        lista.sort((a, b) => (store.proximoHorario(a) ?? distante)
            .compareTo(store.proximoHorario(b) ?? distante));
      case Ordenacao.experiencia:
        lista.sort((a, b) => b.anosExperiencia.compareTo(a.anosExperiencia));
    }
    return lista;
  }
}

/// Buscar psicólogos (wireframe 02).
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key, this.textoInicial, this.modalidadeInicial});

  final String? textoInicial;
  final Modalidade? modalidadeInicial;

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _filtros = FiltrosBusca();
  late final _busca = TextEditingController(text: widget.textoInicial ?? '');

  @override
  void initState() {
    super.initState();
    _filtros.texto = widget.textoInicial ?? '';
    if (widget.modalidadeInicial != null) {
      _filtros.modalidades = {widget.modalidadeInicial!};
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  void _atualizar(VoidCallback f) => setState(f);

  String? get _rotuloModalidade {
    if (_filtros.modalidades.length != 1) return null;
    return _filtros.modalidades.first.rotulo;
  }

  String _titulo(int n) {
    final base = Fmt.plural(n, 'psicólogo', 'psicólogos');
    final t = _filtros.texto.trim();
    return t.isEmpty ? base : '$base para "$t"';
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _filtros.aplicar(context.store);
    return PacienteShell(
      secao: SecaoPaciente.buscar,
      child: context.isWide ? _web(resultados) : _mobile(resultados),
    );
  }

  Widget _web(List<Psicologo> resultados) {
    return ConteudoComRodape(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Semantics(
            header: true,
            child: Text('Buscar psicólogos', style: AppText.serif(32)),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 14,
                child: CampoTexto(
                  controller: _busca,
                  altura: 50,
                  hint: 'Especialidade, abordagem ou nome',
                  icone: Icons.search_rounded,
                  acaoTeclado: TextInputAction.search,
                  onChanged: (v) => _atualizar(() => _filtros.texto = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: SeletorCaixa<String>(
                  valor: _rotuloModalidade,
                  hint: 'Modalidade',
                  altura: 50,
                  opcoes: const [
                    'Todas as modalidades',
                    'Online',
                    'Presencial'
                  ],
                  rotulo: (s) => s,
                  onChanged: (s) => _atualizar(() {
                    _filtros.modalidades = switch (s) {
                      'Online' => {Modalidade.online},
                      'Presencial' => {Modalidade.presencial},
                      _ => {},
                    };
                  }),
                ),
              ),
              const SizedBox(width: 12),
              BotaoPill(
                'Buscar',
                altura: 50,
                onPressed: () => _atualizar(() {
                  _filtros.texto = _busca.text;
                  FocusScope.of(context).unfocus();
                }),
              ),
              const Spacer(flex: 9),
            ],
          ),
          const SizedBox(height: 23),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Como no wireframe 02, o painel desce até o fim da tela e
              // começa 5 px abaixo da linha de resultados.
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height - 269),
                  child: SizedBox(
                    width: 272,
                    child: CartaoApp(
                        padding: const EdgeInsets.fromLTRB(24, 15, 20, 24),
                        child: _PainelFiltros(
                            filtros: _filtros, onChanged: _atualizar)),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titulo(resultados.length),
                            style: const TextStyle(
                                fontSize: 19, color: AppColors.texto),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: SeletorCaixa<Ordenacao>(
                            valor: _filtros.ordenacao,
                            opcoes: Ordenacao.values,
                            rotulo: (o) => o.rotulo,
                            semantica: 'Ordenar resultados',
                            onChanged: (o) =>
                                _atualizar(() => _filtros.ordenacao = o),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    if (resultados.isEmpty)
                      _SemResultados(onLimpar: () => _atualizar(_limparTudo))
                    else
                      GradeResponsiva(
                        larguraMinItem: 250,
                        children: [
                          for (final p in resultados)
                            CartaoPsicologo(psicologo: p),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _limparTudo() {
    _filtros.limpar();
    _filtros.texto = '';
    _busca.clear();
  }

  Widget _mobile(List<Psicologo> resultados) {
    final online = _filtros.modalidades.length == 1 &&
        _filtros.modalidades.contains(Modalidade.online);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                  header: true,
                  child: Text('Buscar', style: AppText.serif(34))),
              const SizedBox(height: 14),
              CampoTexto(
                controller: _busca,
                hint: 'Especialidade ou nome',
                icone: Icons.search_rounded,
                acaoTeclado: TextInputAction.search,
                onChanged: (v) => _atualizar(() => _filtros.texto = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ChipFiltro(
                _filtros.ativos == 0
                    ? 'Filtros'
                    : 'Filtros (${_filtros.ativos})',
                icone: Icons.tune_rounded,
                selecionado: false,
                onTap: _abrirFiltros,
              ),
              const SizedBox(width: 8),
              ChipFiltro(
                'Online',
                selecionado: online,
                onTap: () => _atualizar(
                  () =>
                      _filtros.modalidades = online ? {} : {Modalidade.online},
                ),
              ),
              const SizedBox(width: 8),
              ChipFiltro(
                '4+ estrelas',
                selecionado: _filtros.notaMinima == 4,
                onTap: () => _atualizar(
                  () =>
                      _filtros.notaMinima = _filtros.notaMinima == 4 ? null : 4,
                ),
              ),
              const SizedBox(width: 8),
              ChipFiltro(
                'Hoje',
                selecionado: _filtros.disponibilidade == FiltroDia.hoje,
                onTap: () => _atualizar(
                  () => _filtros.disponibilidade =
                      _filtros.disponibilidade == FiltroDia.hoje
                          ? null
                          : FiltroDia.hoje,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.plural(resultados.length, 'psicólogo', 'psicólogos'),
                  style: const TextStyle(fontSize: 15, color: AppColors.texto),
                ),
              ),
              PopupMenuButton<Ordenacao>(
                tooltip: 'Ordenar resultados',
                initialValue: _filtros.ordenacao,
                onSelected: (o) => _atualizar(() => _filtros.ordenacao = o),
                itemBuilder: (_) => [
                  for (final o in Ordenacao.values)
                    PopupMenuItem(value: o, child: Text(o.rotulo)),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _filtros.ordenacao.rotulo,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.lavanda),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: resultados.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SemResultados(onLimpar: () => _atualizar(_limparTudo))
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      CartaoResultadoMobile(psicologo: resultados[i]),
                ),
        ),
      ],
    );
  }

  Future<void> _abrirFiltros() {
    return abrirPainel<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          void mudar(VoidCallback f) {
            setLocal(f);
            setState(() {});
          }

          final n = _filtros.aplicar(context.acoes).length;
          return PainelConteudo(
            titulo: 'Filtros',
            acoes: AcoesPainel(
              primario: 'Ver ${Fmt.plural(n, 'resultado', 'resultados')}',
              onPrimario: () => Navigator.of(ctx).pop(),
              secundario: 'Limpar filtros',
              onSecundario: () => mudar(_filtros.limpar),
            ),
            children: [
              _PainelFiltros(
                  filtros: _filtros, onChanged: mudar, mostrarTitulo: false)
            ],
          );
        },
      ),
    );
  }
}

class _PainelFiltros extends StatelessWidget {
  const _PainelFiltros({
    required this.filtros,
    required this.onChanged,
    this.mostrarTitulo = true,
  });

  final FiltrosBusca filtros;
  final void Function(VoidCallback) onChanged;
  final bool mostrarTitulo;

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textoSecundario)),
      );

  @override
  Widget build(BuildContext context) {
    final f = filtros;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mostrarTitulo)
          Row(
            children: [
              const Expanded(
                child: Text('Filtros',
                    style: TextStyle(fontSize: 19, color: AppColors.texto)),
              ),
              LinkTexto('Limpar', onTap: () => onChanged(f.limpar)),
            ],
          ),
        _titulo('Público-alvo'),
        for (final p in publicosAlvo)
          LinhaCheck(
            rotulo: p,
            valor: f.publicos.contains(p),
            onChanged: (v) => onChanged(() {
              v ? f.publicos.add(p) : f.publicos.remove(p);
            }),
          ),
        _titulo('Modalidade'),
        for (final m in Modalidade.values)
          LinhaCheck(
            rotulo: m.rotulo,
            valor: f.modalidades.contains(m),
            onChanged: (v) => onChanged(() {
              v ? f.modalidades.add(m) : f.modalidades.remove(m);
            }),
          ),
        _titulo('Atende em'),
        LinhaCheck(
          rotulo: 'Consultório próprio',
          valor: f.consultorio,
          onChanged: (v) => onChanged(() {
            f.consultorio = v;
            if (!f.consultorio && !f.clinica) f.clinica = true;
          }),
        ),
        LinhaCheck(
          rotulo: 'Clínica',
          valor: f.clinica,
          onChanged: (v) => onChanged(() {
            f.clinica = v;
            if (!f.consultorio && !f.clinica) f.consultorio = true;
          }),
        ),
        _titulo('Avaliação mínima'),
        for (final nota in const [4.0, 3.0])
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: f.notaMinima == nota,
            label: '${nota.toInt()} estrelas ou mais',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(
                  () => f.notaMinima = f.notaMinima == nota ? null : nota),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Row(
                  children: [
                    BolinhaRadio(selecionado: f.notaMinima == nota),
                    const SizedBox(width: 12),
                    Estrelas(nota, tamanho: 15),
                    const SizedBox(width: 8),
                    const Text('ou mais',
                        style: TextStyle(
                            fontSize: 13.5, color: AppColors.textoSecundario)),
                  ],
                ),
              ),
            ),
          ),
        _titulo('Disponibilidade'),
        Wrap(
          spacing: 8,
          children: [
            ChipFiltro(
              'Hoje',
              compacto: true,
              selecionado: f.disponibilidade == FiltroDia.hoje,
              onTap: () => onChanged(() => f.disponibilidade =
                  f.disponibilidade == FiltroDia.hoje ? null : FiltroDia.hoje),
            ),
            ChipFiltro(
              'Esta semana',
              compacto: true,
              selecionado: f.disponibilidade == FiltroDia.semana,
              onTap: () => onChanged(() => f.disponibilidade =
                  f.disponibilidade == FiltroDia.semana
                      ? null
                      : FiltroDia.semana),
            ),
          ],
        ),
      ],
    );
  }
}

class _SemResultados extends StatelessWidget {
  const _SemResultados({required this.onLimpar});

  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return CartaoApp(
      child: Column(
        children: [
          const Icone(Icons.search_off_rounded,
              size: 32, color: AppColors.textoSecundario),
          const SizedBox(height: 12),
          const Text(
            'Nenhum psicólogo encontrado com esses filtros.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.texto),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tente outra especialidade ou remova algum filtro.',
            textAlign: TextAlign.center,
            style: AppText.pequeno,
          ),
          const SizedBox(height: 16),
          BotaoPill('Limpar filtros',
              estilo: EstiloBotao.contorno, onPressed: onLimpar),
        ],
      ),
    );
  }
}
