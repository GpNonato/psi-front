import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Situação financeira do paciente, como aparece na lista.
(String, String, Color) situacaoFinanceira(AppStore store, Paciente p) {
  final pendente = store.pendenteDoPaciente(p.id);
  if (pendente > 0) {
    return (
      '${Fmt.moedaCurta(pendente)} pendente',
      'Pendente',
      AppColors.ambar
    );
  }
  return ('Em dia', 'Em dia', AppColors.verde);
}

/// Lista de pacientes (wireframe 11).
class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  String _busca = '';
  String _consulta = 'Todos';
  String? _financeiro;

  List<Paciente> _filtrar(AppStore store) {
    final q = normalizar(_busca);
    final digitos = _busca.replaceAll(RegExp(r'\D'), '');
    return store.pacientes.where((p) {
      if (q.isNotEmpty) {
        final porNome = normalizar(p.nome).contains(q);
        final porTelefone = digitos.isNotEmpty &&
            p.telefone.replaceAll(RegExp(r'\D'), '').contains(digitos);
        if (!porNome && !porTelefone) return false;
      }
      final temProxima = store.proximaConsulta(p.id) != null;
      if (_consulta == 'Com consulta marcada' && !temProxima) return false;
      if (_consulta == 'Sem consulta marcada' && temProxima) return false;
      if (_financeiro != null) {
        final pendente = store.pendenteDoPaciente(p.id) > 0;
        if (_financeiro == 'Pendente' && !pendente) return false;
        if (_financeiro == 'Em dia' && pendente) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _novo() async {
    final p = await abrirPainel<Paciente>(context,
        larguraMax: 480, builder: (_) => const _NovoPaciente());
    if (p == null || !mounted) return;
    avisar(context, '${p.nome} entrou na sua lista de pacientes.');
    abrirTela<void>(context, Rotas.ficha(p.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final lista = _filtrar(store);
    final wide = context.isWide;
    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.pacientes,
      child: PaginaPro(
        titulo: 'Pacientes',
        subtitulo: Fmt.plural(
            store.pacientes.length, 'paciente ativo', 'pacientes ativos'),
        acoes: [
          BotaoPill('Novo paciente', icone: Icons.add_rounded, onPressed: _novo)
        ],
        acoesMobile: [
          BotaoPill('Novo',
              icone: Icons.add_rounded, compacto: true, onPressed: _novo)
        ],
        children: wide ? _web(store, lista) : _mobile(store, lista),
      ),
    );
  }

  Widget _filtro(double largura, Widget campo) => Flexible(
        flex: largura.round(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largura),
          child: campo,
        ),
      );

  List<Widget> _web(AppStore store, List<Paciente> lista) {
    const cab = TextStyle(fontSize: 12.5, color: AppColors.textoSecundario);
    return [
      // Larguras do wireframe (340/220/220), encolhendo em telas menores.
      Row(
        children: [
          _filtro(
            340,
            CampoTexto(
              hint: 'Buscar por nome ou telefone',
              icone: Icons.search_rounded,
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          const SizedBox(width: 12),
          _filtro(
            220,
            SeletorCaixa<String>(
              valor: _consulta,
              opcoes: const [
                'Todos',
                'Com consulta marcada',
                'Sem consulta marcada'
              ],
              rotulo: (s) => s,
              onChanged: (s) => setState(() => _consulta = s),
            ),
          ),
          const SizedBox(width: 12),
          _filtro(
            220,
            SeletorCaixa<String>(
              valor: _financeiro,
              hint: 'Situação financeira',
              opcoes: const ['Todas as situações', 'Em dia', 'Pendente'],
              rotulo: (s) => s,
              onChanged: (s) => setState(
                  () => _financeiro = s.startsWith('Todas') ? null : s),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      CartaoApp(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 14),
              child: Row(
                children: [
                  Expanded(flex: 30, child: Text('Paciente', style: cab)),
                  Expanded(
                      flex: 15, child: Text('Última consulta', style: cab)),
                  Expanded(
                      flex: 20, child: Text('Próxima consulta', style: cab)),
                  Expanded(flex: 9, child: Text('Sessões', style: cab)),
                  Expanded(flex: 16, child: Text('Financeiro', style: cab)),
                  SizedBox(width: 90),
                ],
              ),
            ),
            const Divider(),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum paciente com esses filtros.',
                    style: AppText.pequeno),
              ),
            for (var i = 0; i < lista.length; i++) ...[
              if (i > 0) const Divider(indent: 24, endIndent: 24),
              _linhaWeb(store, lista[i]),
            ],
          ],
        ),
      ),
      const SizedBox(height: 40),
      const AvisoLavanda(
        'Dados e documentos dos pacientes são visíveis apenas para você (sigilo profissional · CFP e LGPD).',
        icone: Icons.lock_outline_rounded,
      ),
    ];
  }

  Widget _linhaWeb(AppStore store, Paciente p) {
    final ultima = store.ultimaConsulta(p.id);
    final proxima = store.proximaConsulta(p.id);
    final (fin, _, cor) = situacaoFinanceira(store, p);
    const texto = TextStyle(fontSize: 15, color: AppColors.texto);
    return InkWell(
      onTap: () => abrirTela<void>(context, Rotas.ficha(p.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 30,
              child: Row(
                children: [
                  AvatarIniciais(p.nome, tamanho: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nome, style: const TextStyle(fontSize: 15.5)),
                        Text(p.telefone,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textoSecundario)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                flex: 15,
                child: Text(ultima == null ? '—' : Fmt.diaMes(ultima),
                    style: texto)),
            Expanded(
              flex: 20,
              child: Text(
                  proxima == null
                      ? '—'
                      : Fmt.quando(proxima.inicio, store.agora),
                  style: texto),
            ),
            Expanded(
                flex: 9,
                child: Text('${store.sessoesDoPaciente(p.id)}', style: texto)),
            Expanded(
                flex: 16, child: StatusPonto(fin, cor: cor, tamanho: 12.5)),
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerRight,
                child: LinkTexto('Abrir ficha',
                    onTap: () => abrirTela<void>(context, Rotas.ficha(p.id))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _mobile(AppStore store, List<Paciente> lista) {
    return [
      CampoTexto(
        hint: 'Buscar paciente',
        icone: Icons.search_rounded,
        onChanged: (v) => setState(() => _busca = v),
      ),
      const SizedBox(height: 16),
      CartaoApp(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child:
                    Text('Nenhum paciente encontrado.', style: AppText.pequeno),
              ),
            for (var i = 0; i < lista.length; i++) ...[
              if (i > 0) const Divider(),
              _linhaMobile(store, lista[i]),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      const AvisoLavanda(
        'Visível apenas para você (CFP e LGPD)',
        icone: Icons.lock_outline_rounded,
        compacto: true,
      ),
    ];
  }

  Widget _linhaMobile(AppStore store, Paciente p) {
    final proxima = store.proximaConsulta(p.id);
    final (_, curto, cor) = situacaoFinanceira(store, p);
    return InkWell(
      onTap: () => abrirTela<void>(context, Rotas.ficha(p.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        child: Row(
          children: [
            AvatarIniciais(p.nome, tamanho: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: const TextStyle(fontSize: 15.5)),
                  Text(
                    proxima == null
                        ? 'Sem consulta marcada'
                        : 'Próx.: ${Fmt.quando(proxima.inicio, store.agora)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            StatusPonto(curto, cor: cor, tamanho: 13),
          ],
        ),
      ),
    );
  }
}

class _NovoPaciente extends StatefulWidget {
  const _NovoPaciente();

  @override
  State<_NovoPaciente> createState() => _NovoPacienteState();
}

class _NovoPacienteState extends State<_NovoPaciente> {
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_nome.text.trim().length < 3) {
      setState(() => _erro = 'Informe o nome do paciente.');
      return;
    }
    final p = context.acoes.adicionarPaciente(
      nome: _nome.text,
      telefone:
          _telefone.text.trim().isEmpty ? 'Não informado' : _telefone.text,
      email: _email.text.trim().isEmpty ? 'Não informado' : _email.text,
    );
    Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Novo paciente',
      subtitulo: 'Os dados ficam visíveis só para você.',
      acoes: AcoesPainel(primario: 'Adicionar paciente', onPrimario: _salvar),
      children: [
        CampoTexto(
            controller: _nome,
            rotulo: 'Nome completo',
            hint: 'Nome do paciente',
            erro: _erro),
        const SizedBox(height: 14),
        CampoTexto(
            controller: _telefone,
            rotulo: 'Telefone',
            hint: '(31) 90000-0000',
            teclado: TextInputType.phone),
        const SizedBox(height: 14),
        CampoTexto(
            controller: _email,
            rotulo: 'E-mail',
            hint: 'nome@email.com',
            teclado: TextInputType.emailAddress),
      ],
    );
  }
}
