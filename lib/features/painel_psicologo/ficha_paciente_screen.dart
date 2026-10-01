import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../agenda_agendamento/seletor_horario.dart';

/// Ficha do paciente, visível só para o psicólogo (wireframe 12).
class FichaPacienteScreen extends StatelessWidget {
  const FichaPacienteScreen({super.key, required this.pacienteId});

  final String pacienteId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = store.pacienteOuNulo(pacienteId);
    final rota = Rotas.ficha(pacienteId);
    if (p == null) {
      return ProShell(
        papel: Papel.psicologo,
        rota: rota,
        child: PaginaPro(
          titulo: 'Paciente não encontrado',
          children: [
            BotaoPill('Voltar para pacientes',
                onPressed: () => irPara(context, Rotas.pacientes)),
          ],
        ),
      );
    }
    return ProShell(
      papel: Papel.psicologo,
      rota: rota,
      child:
          context.isWide ? _web(context, store, p) : _mobile(context, store, p),
    );
  }

  String _resumo(AppStore store, Paciente p, {bool longo = true}) {
    final idade = '${p.idade(store.agora)} anos';
    final sessoes =
        Fmt.plural(store.sessoesDoPaciente(p.id), 'sessão', 'sessões');
    if (!longo) return '$idade · $sessoes';
    return '$idade · Paciente desde ${Fmt.mesLongo(p.desde.month)} de ${p.desde.year} · $sessoes';
  }

  Widget _selo() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lavandaBorda),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: const Text(
          'Visível só para você',
          style: TextStyle(fontSize: 12.5, color: AppColors.lavandaEscuro),
        ),
      );

  Widget _web(BuildContext context, AppStore store, Paciente p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 26, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LinkTexto('Pacientes',
                  tamanho: 13.5,
                  onTap: () => voltarOu(context, Rotas.pacientes)),
              Text(' ›  ${p.nome}',
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textoSecundario)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarIniciais(p.nome, tamanho: 72),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        header: true,
                        child: Text(p.nome, style: AppText.serif(28))),
                    const SizedBox(height: 2),
                    Text(_resumo(store, p),
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textoSecundario)),
                    const SizedBox(height: 8),
                    _selo(),
                  ],
                ),
              ),
              BotaoPill('Editar dados',
                  estilo: EstiloBotao.contorno,
                  onPressed: () => editarDados(context, p)),
              const SizedBox(width: 12),
              BotaoPill('Agendar sessão',
                  onPressed: () => agendarSessao(context, p)),
            ],
          ),
          const SizedBox(height: 19),
          LayoutBuilder(
            builder: (context, c) {
              final esquerda = [
                _DadosPessoais(paciente: p),
                const SizedBox(height: 16),
                _Anotacoes(paciente: p),
              ];
              final direita = [
                _Documentos(paciente: p),
                const SizedBox(height: 16),
                _Consultas(paciente: p),
                const SizedBox(height: 16),
                _Financeiro(paciente: p),
              ];
              if (c.maxWidth < 980) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...esquerda,
                    const SizedBox(height: 16),
                    ...direita
                  ],
                );
              }
              // Wireframe 12: duas linhas de cartões com a mesma altura
              // (dados pessoais e documentos; anotações e consultas mais
              // financeiro).
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _DadosPessoais(paciente: p)),
                        const SizedBox(width: 24),
                        Expanded(child: _Documentos(paciente: p)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _Anotacoes(paciente: p)),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Consultas(paciente: p),
                              const SizedBox(height: 16),
                              Expanded(child: _Financeiro(paciente: p)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context, AppStore store, Paciente p) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => voltarOu(context, Rotas.pacientes),
            icon: const Icone(Icons.chevron_left_rounded),
            label: const Text('Pacientes'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textoSecundario),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            AvatarIniciais(p.nome, tamanho: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: AppText.serif(24)),
                  Text(_resumo(store, p, longo: false), style: AppText.pequeno),
                  const SizedBox(height: 6),
                  _selo(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: BotaoPill(
                'Ligar',
                icone: Icons.phone_outlined,
                estilo: EstiloBotao.contorno,
                compacto: true,
                onPressed: () => avisar(context,
                    'Na versão final, abre o discador: ${p.telefone}.'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BotaoPill(
                'E-mail',
                icone: Icons.mail_outline_rounded,
                estilo: EstiloBotao.contorno,
                compacto: true,
                onPressed: () => avisar(
                    context, 'Na versão final, abre o e-mail: ${p.email}.'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BotaoPill(
                'Agendar',
                icone: Icons.calendar_today_outlined,
                compacto: true,
                onPressed: () => agendarSessao(context, p),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DadosPessoais(paciente: p),
        const SizedBox(height: 16),
        _Documentos(paciente: p),
        const SizedBox(height: 16),
        _Anotacoes(paciente: p),
        const SizedBox(height: 16),
        _Consultas(paciente: p),
        const SizedBox(height: 16),
        _Financeiro(paciente: p),
      ],
    );
  }
}

// ------------------------------------------------------------------ cartões

class _DadosPessoais extends StatelessWidget {
  const _DadosPessoais({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final wide = context.isWide;
    final dados = [
      ('Nascimento', Fmt.data(p.nascimento)),
      ('CPF', '•••.•••.•••-${p.cpfFinal}'),
      ('Telefone', p.telefone),
      ('E-mail', p.email),
      ('Endereço', p.endereco),
      (wide ? 'Contato de emergência' : 'Emergência', p.contatoEmergencia),
    ];
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoCartao(
            'Dados pessoais',
            acao: LinkTexto('Editar', onTap: () => editarDados(context, p)),
          ),
          const SizedBox(height: 12),
          if (wide)
            Wrap(
              runSpacing: 22,
              children: [
                for (final (r, v) in dados)
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: LinhaInfo(rotulo: r, valor: v),
                    ),
                  ),
              ],
            )
          else
            for (final (r, v)
                in dados.where((d) => d.$1 != 'CPF' && d.$1 != 'Endereço'))
              LinhaInfo(rotulo: r, valor: v, larguraRotulo: 98),
        ],
      ),
    );
  }
}

class _Documentos extends StatelessWidget {
  const _Documentos({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final wide = context.isWide;
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoCartao(
            'Documentos',
            icone: Icons.lock_outline_rounded,
            acao: BotaoPill(
              'Enviar',
              icone: Icons.upload_rounded,
              estilo: EstiloBotao.contorno,
              compacto: true,
              altura: 36,
              onPressed: () => enviarDocumento(context, p),
            ),
          ),
          const SizedBox(height: 8),
          if (p.documentos.isEmpty)
            const Text('Nenhum documento enviado.', style: AppText.pequeno),
          // Linhas de 60 px separadas por 12 px (wireframe 12).
          for (final d in p.documentos)
            Container(
              margin: EdgeInsets.only(bottom: d == p.documentos.last ? 0 : 12),
              padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F0EA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icone(Icons.description_outlined,
                      color: AppColors.lavanda),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.nome, style: const TextStyle(fontSize: 15)),
                        Text(
                          wide
                              ? '${d.assinado ? 'Assinado · ' : ''}${Fmt.data(d.data)} · ${d.tamanhoKb} KB'
                              : Fmt.data(d.data),
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções do documento',
                    icon: const Icone(Icons.more_horiz_rounded),
                    onSelected: (v) async {
                      if (v == 'baixar') {
                        avisar(context,
                            'Na versão final, o arquivo abre por um link temporário.');
                        return;
                      }
                      final ok = await pedirConfirmacao(
                        context,
                        titulo: 'Excluir documento?',
                        mensagem: '"${d.nome}" será removido da ficha.',
                        rotuloConfirmar: 'Excluir',
                        perigo: true,
                      );
                      if (ok && context.mounted) {
                        context.acoes.removerDocumento(p, d);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'baixar', child: Text('Baixar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
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

class _Anotacoes extends StatelessWidget {
  const _Anotacoes({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final wide = context.isWide;
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoCartao(
            wide ? 'Anotações das sessões' : 'Anotações',
            icone: Icons.lock_outline_rounded,
            acao: LinkTexto(
              wide ? '+ Nova anotação' : '+ Nova',
              onTap: () => escreverAnotacao(context, p),
            ),
          ),
          const SizedBox(height: 14),
          if (p.anotacoes.isEmpty)
            const Text('Nenhuma anotação ainda.', style: AppText.pequeno),
          for (final a in p.anotacoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: const Color(0xFFF1F0EA),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => escreverAnotacao(context, p, anotacao: a),
                  child: Container(
                    constraints: BoxConstraints(minHeight: wide ? 120 : 96),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Fmt.diaMes(a.data)} · Sessão ${a.sessao}',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.texto),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.texto,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _statusConsulta(Consulta c, DateTime agora) {
  if (c.cancelada) {
    return const SoftChip('Cancelada',
        fundo: Color(0xFFF7E4E1), cor: AppColors.vermelho, tamanho: 12);
  }
  if (c.proxima(agora)) return const StatusPonto('Confirmada', tamanho: 12.5);
  return const SoftChip('Realizada',
      fundo: Color(0xFFEFEEE6), cor: AppColors.textoSecundario, tamanho: 12);
}

class _Consultas extends StatelessWidget {
  const _Consultas({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final todas = store.consultasDoPaciente(paciente.id);
    final futuras = todas.where((c) => c.proxima(store.agora)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final passadas =
        todas.where((c) => !c.proxima(store.agora) && !c.cancelada).toList();
    final visiveis = [...futuras.take(2), ...passadas].take(3).toList();
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoCartao(
            'Consultas',
            acao: LinkTexto('Ver histórico',
                onTap: () => _historico(context, paciente)),
          ),
          const SizedBox(height: 6),
          if (visiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child:
                  Text('Nenhuma consulta registrada.', style: AppText.pequeno),
            ),
          for (var i = 0; i < visiveis.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Icone(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textoSecundario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${Fmt.diaCurto(visiveis[i].inicio)} · ${Fmt.hora(visiveis[i].inicio)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  _statusConsulta(visiveis[i], store.agora),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _historico(BuildContext context, Paciente p) {
    return abrirPainel<void>(
      context,
      builder: (ctx) {
        final store = ctx.store;
        final todas = store.consultasDoPaciente(p.id);
        return PainelConteudo(
          titulo: 'Histórico de consultas',
          subtitulo:
              '${p.nome} · ${Fmt.plural(store.sessoesDoPaciente(p.id), 'sessão realizada', 'sessões realizadas')}',
          children: [
            for (final c in todas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Fmt.diaCurto(c.inicio)} · ${Fmt.hora(c.inicio)} · ${c.modalidade.rotulo}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    _statusConsulta(c, store.agora),
                  ],
                ),
              ),
            if (p.sessoesAnteriores > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mais ${Fmt.plural(p.sessoesAnteriores, 'sessão anterior', 'sessões anteriores')} '
                  'a este período.',
                  style: AppText.pequeno,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Financeiro extends StatelessWidget {
  const _Financeiro({required this.paciente});

  final Paciente paciente;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = paciente;
    final pago = store.pagoNoAno(p.id);
    final pendente = store.pendenteDoPaciente(p.id);
    final wide = context.isWide;
    return CartaoApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoCartao(
            'Financeiro',
            acao: wide
                ? LinkTexto('Ver lançamentos',
                    onTap: () => _lancamentos(context, p))
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Kpi(
                  rotulo: 'Pago em ${store.agora.year}',
                  valor: Fmt.moeda(pago),
                  cor: AppColors.verde,
                  tamanho: wide ? 30 : 26,
                ),
              ),
              Expanded(
                child: Kpi(
                  rotulo: 'Pendente',
                  valor: Fmt.moeda(pendente),
                  cor: pendente > 0 ? AppColors.ambar : AppColors.texto,
                  tamanho: wide ? 30 : 26,
                ),
              ),
            ],
          ),
          if (wide) ...[
            const SizedBox(height: 16),
            Text(
              'Valor por sessão: ${Fmt.moeda(p.valorSessao)} · Forma preferida: ${p.formaPreferida}',
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textoSecundario),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: BotaoPill(
              'Registrar pagamento',
              estilo: EstiloBotao.contorno,
              compacto: true,
              expandir: !wide,
              onPressed: () => registrarPagamento(context, p),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _lancamentos(BuildContext context, Paciente p) {
    return abrirPainel<void>(
      context,
      builder: (ctx) {
        final lista = ctx.store.lancamentosDoPaciente(p.id);
        return PainelConteudo(
          titulo: 'Lançamentos',
          subtitulo: p.nome,
          children: [
            if (lista.isEmpty)
              const Text('Nenhum lançamento ainda.', style: AppText.pequeno),
            for (final l in lista)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(width: 64, child: Text(Fmt.diaMes(l.data))),
                    Expanded(child: Text(l.descricao, style: AppText.pequeno)),
                    Text(Fmt.moeda(l.valor)),
                    const SizedBox(width: 12),
                    StatusPonto(
                      l.pago ? 'Pago' : 'Pendente',
                      cor: l.pago ? AppColors.verde : AppColors.ambar,
                      tamanho: 12.5,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------ ações

Future<void> editarDados(BuildContext context, Paciente p) {
  return abrirPainel<void>(context, builder: (_) => _EditarDados(paciente: p));
}

class _EditarDados extends StatefulWidget {
  const _EditarDados({required this.paciente});

  final Paciente paciente;

  @override
  State<_EditarDados> createState() => _EditarDadosState();
}

class _EditarDadosState extends State<_EditarDados> {
  late final _nome = TextEditingController(text: widget.paciente.nome);
  late final _telefone = TextEditingController(text: widget.paciente.telefone);
  late final _email = TextEditingController(text: widget.paciente.email);
  late final _endereco = TextEditingController(text: widget.paciente.endereco);
  late final _emergencia =
      TextEditingController(text: widget.paciente.contatoEmergencia);
  late DateTime _nascimento = widget.paciente.nascimento;

  @override
  void dispose() {
    for (final c in [_nome, _telefone, _email, _endereco, _emergencia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _nascimento,
      firstDate: DateTime(1920),
      lastDate: context.acoes.agora,
      helpText: 'Data de nascimento',
    );
    if (d != null) setState(() => _nascimento = d);
  }

  void _salvar() {
    if (_nome.text.trim().length < 3) return;
    context.acoes.atualizarPaciente(
      widget.paciente,
      nome: _nome.text,
      telefone: _telefone.text,
      email: _email.text,
      nascimento: _nascimento,
      endereco: _endereco.text,
      contatoEmergencia: _emergencia.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Editar dados',
      acoes: AcoesPainel(primario: 'Salvar', onPrimario: _salvar),
      children: [
        CampoTexto(controller: _nome, rotulo: 'Nome completo'),
        const SizedBox(height: 14),
        CampoRotulado(
          rotulo: 'Nascimento',
          child: OutlinedButton.icon(
            onPressed: _escolherData,
            icon: const Icone(Icons.calendar_today_outlined, size: 18),
            label: Text(Fmt.data(_nascimento)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.texto,
              minimumSize: const Size(0, 46),
              side: const BorderSide(color: AppColors.borda),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        CampoTexto(
            controller: _telefone,
            rotulo: 'Telefone',
            teclado: TextInputType.phone),
        const SizedBox(height: 14),
        CampoTexto(
            controller: _email,
            rotulo: 'E-mail',
            teclado: TextInputType.emailAddress),
        const SizedBox(height: 14),
        CampoTexto(controller: _endereco, rotulo: 'Endereço'),
        const SizedBox(height: 14),
        CampoTexto(controller: _emergencia, rotulo: 'Contato de emergência'),
      ],
    );
  }
}

Future<void> enviarDocumento(BuildContext context, Paciente p) {
  return abrirPainel<void>(context,
      larguraMax: 480, builder: (_) => _EnviarDocumento(paciente: p));
}

class _EnviarDocumento extends StatefulWidget {
  const _EnviarDocumento({required this.paciente});

  final Paciente paciente;

  @override
  State<_EnviarDocumento> createState() => _EnviarDocumentoState();
}

class _EnviarDocumentoState extends State<_EnviarDocumento> {
  final _nome = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _enviar() {
    if (_nome.text.trim().isEmpty) return;
    context.acoes.adicionarDocumento(widget.paciente, _nome.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Enviar documento',
      subtitulo: 'Contratos, encaminhamentos, laudos e escalas.',
      acoes: AcoesPainel(primario: 'Enviar', onPrimario: _enviar),
      children: [
        CampoTexto(
          controller: _nome,
          rotulo: 'Nome do arquivo',
          hint: 'Ex.: Termo de consentimento.pdf',
          autofocus: true,
          onSubmitted: (_) => _enviar(),
        ),
        const SizedBox(height: 14),
        const AvisoLavanda(
          'Envio simulado nesta demonstração: nenhum arquivo sai do seu computador. Na versão '
          'final, o documento fica privado e só abre por link temporário.',
          icone: Icons.lock_outline_rounded,
          compacto: true,
        ),
      ],
    );
  }
}

Future<void> escreverAnotacao(BuildContext context, Paciente p,
    {Anotacao? anotacao}) {
  return abrirPainel<void>(
    context,
    builder: (_) => _EscreverAnotacao(paciente: p, anotacao: anotacao),
  );
}

class _EscreverAnotacao extends StatefulWidget {
  const _EscreverAnotacao({required this.paciente, this.anotacao});

  final Paciente paciente;
  final Anotacao? anotacao;

  @override
  State<_EscreverAnotacao> createState() => _EscreverAnotacaoState();
}

class _EscreverAnotacaoState extends State<_EscreverAnotacao> {
  late final _texto = TextEditingController(text: widget.anotacao?.texto ?? '');

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_texto.text.trim().isEmpty) return;
    final a = widget.anotacao;
    if (a == null) {
      context.acoes.adicionarAnotacao(widget.paciente, _texto.text);
    } else {
      context.acoes.editarAnotacao(a, _texto.text);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.anotacao;
    return PainelConteudo(
      titulo: a == null ? 'Nova anotação' : 'Sessão ${a.sessao}',
      subtitulo: a == null
          ? 'Fica na ficha, visível só para você.'
          : '${Fmt.diaMes(a.data)} · ${widget.paciente.nome}',
      acoes: AcoesPainel(primario: 'Salvar anotação', onPrimario: _salvar),
      children: [
        CampoTexto(
          controller: _texto,
          hint: 'O que foi trabalhado na sessão, combinados e próximos passos',
          linhas: 7,
          maxLength: 2000,
          contador: true,
          autofocus: true,
        ),
      ],
    );
  }
}

Future<void> registrarPagamento(BuildContext context, Paciente p) {
  return abrirPainel<void>(context,
      larguraMax: 480, builder: (_) => _RegistrarPagamento(paciente: p));
}

class _RegistrarPagamento extends StatefulWidget {
  const _RegistrarPagamento({required this.paciente});

  final Paciente paciente;

  @override
  State<_RegistrarPagamento> createState() => _RegistrarPagamentoState();
}

class _RegistrarPagamentoState extends State<_RegistrarPagamento> {
  late final _valor = TextEditingController(
    text: widget.paciente.valorSessao.toStringAsFixed(2).replaceAll('.', ','),
  );
  late String _forma = widget.paciente.formaPreferida;
  String _descricao = 'Sessão individual';
  String? _erro;

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    final valor = double.tryParse(
        _valor.text.replaceAll('.', '').replaceAll(',', '.').trim());
    if (valor == null || valor <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    context.acoes.registrarLancamento(
      pacienteId: widget.paciente.id,
      data: context.acoes.agora,
      descricao: _descricao,
      valor: valor,
      pago: true,
      forma: _forma,
      sessoes: _descricao.startsWith('Pacote') ? 4 : 1,
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
        content: Text('Pagamento de ${Fmt.moeda(valor)} registrado.')));
  }

  @override
  Widget build(BuildContext context) {
    return PainelConteudo(
      titulo: 'Registrar pagamento',
      subtitulo: '${widget.paciente.nome} · informado manualmente',
      acoes: AcoesPainel(primario: 'Registrar', onPrimario: _salvar),
      children: [
        SeletorCaixa<String>(
          rotuloCampo: 'Referente a',
          valor: _descricao,
          opcoes: const ['Sessão individual', 'Pacote 4 sessões'],
          rotulo: (s) => s,
          onChanged: (s) => setState(() {
            _descricao = s;
            final base =
                widget.paciente.valorSessao * (s.startsWith('Pacote') ? 4 : 1);
            _valor.text = base.toStringAsFixed(2).replaceAll('.', ',');
          }),
        ),
        const SizedBox(height: 14),
        CampoTexto(
          controller: _valor,
          rotulo: 'Valor (R\$)',
          teclado: const TextInputType.numberWithOptions(decimal: true),
          erro: _erro,
        ),
        const SizedBox(height: 14),
        SeletorCaixa<String>(
          rotuloCampo: 'Forma de pagamento',
          valor: _forma,
          opcoes: formasDePagamento,
          rotulo: (s) => s,
          onChanged: (s) => setState(() => _forma = s),
        ),
      ],
    );
  }
}

/// O psicólogo marca uma sessão para o paciente.
Future<void> agendarSessao(BuildContext context, Paciente p) {
  return abrirPainel<void>(context,
      larguraMax: 520, builder: (_) => _AgendarSessao(paciente: p));
}

class _AgendarSessao extends StatefulWidget {
  const _AgendarSessao({required this.paciente});

  final Paciente paciente;

  @override
  State<_AgendarSessao> createState() => _AgendarSessaoState();
}

class _AgendarSessaoState extends State<_AgendarSessao> {
  late final EscolhaHorario _escolha =
      escolhaInicial(context.acoes, context.acoes.psicologoAtual);
  String? _erro;

  void _confirmar() {
    final h = _escolha.horario;
    if (h == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final c = context.acoes
          .agendarParaPaciente(widget.paciente, h, _escolha.modalidade);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Sessão marcada: ${Fmt.diaCurto(c.inicio)} · ${Fmt.hora(c.inicio)}.')),
      );
    } on ErroAgendamento catch (e) {
      setState(() => _erro = e.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.store.psicologoAtual;
    return PainelConteudo(
      titulo: 'Agendar sessão',
      subtitulo: widget.paciente.nome,
      acoes: AcoesPainel(
        primario: 'Agendar',
        onPrimario: _escolha.horario == null ? null : _confirmar,
      ),
      children: [
        SeletorHorario(
          psicologo: p,
          escolha: _escolha,
          onChanged: () => setState(() => _erro = null),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.salvia, borderRadius: BorderRadius.circular(14)),
          child: Text(resumoEscolha(_escolha, p.disponibilidade.duracao)),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 10),
          Text(_erro!, style: const TextStyle(color: AppColors.vermelho)),
        ],
      ],
    );
  }
}
