import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../comum/especialidades.dart';

/// Cadastrar psicólogo na clínica (wireframe 17).
Future<void> cadastrarPsicologo(BuildContext context) {
  return abrirPainel<void>(context,
      larguraMax: 560, builder: (_) => const _CadastrarPsicologo());
}

class _CadastrarPsicologo extends StatefulWidget {
  const _CadastrarPsicologo();

  @override
  State<_CadastrarPsicologo> createState() => _CadastrarPsicologoState();
}

class _CadastrarPsicologoState extends State<_CadastrarPsicologo> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _crp = TextEditingController();
  final List<String> _especialidades = [];
  bool _exibir = true;
  bool _salas = true;
  bool _financeiro = true;
  bool _tentou = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _crp.dispose();
    super.dispose();
  }

  String? get _erroNome =>
      _nome.text.trim().length < 3 ? 'Informe o nome completo.' : null;
  String? get _erroEmail {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    if (context.acoes.equipe.any((m) => m.email.toLowerCase() == email)) {
      return 'Esse e-mail já está na equipe.';
    }
    return null;
  }

  String? get _erroCrp {
    final crp = _crp.text.trim();
    if (!RegExp(r'^\d{2}/\d{4,6}$').hasMatch(crp)) {
      return 'Use o formato 00/00000.';
    }
    if (context.acoes.equipe.any((m) => m.crp == crp)) {
      return 'Esse CRP já está na equipe.';
    }
    return null;
  }

  Future<void> _adicionar() async {
    final e = await pedirEspecialidade(context, jaTem: _especialidades);
    if (e != null && !_especialidades.contains(e)) {
      setState(() => _especialidades.add(e));
    }
  }

  void _cadastrar() {
    setState(() => _tentou = true);
    if (_erroNome != null || _erroEmail != null || _erroCrp != null) return;
    final messenger = ScaffoldMessenger.of(context);
    final m = context.acoes.cadastrarMembro(
      nome: _nome.text,
      email: _email.text,
      crp: _crp.text,
      especialidades: _especialidades,
      exibirNaPagina: _exibir,
      atenderNasSalas: _salas,
      incluirNoFinanceiro: _financeiro,
    );
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
          content: Text(
              'Acesso gerado. Enviamos um e-mail para ${m.email} criar a senha.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final email = CampoTexto(
      controller: _email,
      rotulo: 'E-mail de acesso',
      hint: 'nome@email.com',
      teclado: TextInputType.emailAddress,
      erro: _tentou ? _erroEmail : null,
      onChanged: (_) => setState(() {}),
    );
    final crp = CampoTexto(
      controller: _crp,
      rotulo: 'CRP',
      hint: '00/00000',
      erro: _tentou ? _erroCrp : null,
      onChanged: (_) => setState(() {}),
    );
    return PainelConteudo(
      titulo: 'Cadastrar psicólogo',
      subtitulo: wide
          ? 'Geramos o acesso e o psicólogo passa a ter o próprio painel.'
          : 'Geramos o acesso ao painel do psicólogo.',
      acoes: AcoesPainel(
          primario: 'Cadastrar e gerar acesso', onPrimario: _cadastrar),
      children: [
        CampoTexto(
          controller: _nome,
          rotulo: 'Nome completo',
          hint: 'Nome do psicólogo',
          erro: _tentou ? _erroNome : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: email),
              const SizedBox(width: 16),
              Expanded(child: crp)
            ],
          )
        else ...[
          email,
          const SizedBox(height: 14),
          crp,
        ],
        const SizedBox(height: 16),
        CampoRotulado(
          rotulo: 'Especialidades',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final e in _especialidades)
                TagChip(e,
                    compacto: true,
                    onRemover: () => setState(() => _especialidades.remove(e))),
              LinkTexto('Adicionar',
                  icone: Icons.add_rounded, onTap: _adicionar),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Permissões na clínica', style: AppText.rotulo),
        const SizedBox(height: 4),
        LinhaSwitch(
            rotulo: 'Exibir na página da clínica',
            valor: _exibir,
            onChanged: (v) => setState(() => _exibir = v)),
        LinhaSwitch(
            rotulo: 'Atender nas salas da clínica',
            valor: _salas,
            onChanged: (v) => setState(() => _salas = v)),
        LinhaSwitch(
          rotulo: wide
              ? 'Incluir no financeiro da equipe (valores agregados)'
              : 'Incluir no financeiro da equipe',
          valor: _financeiro,
          onChanged: (v) => setState(() => _financeiro = v),
        ),
        const SizedBox(height: 16),
        AvisoLavanda(
          wide
              ? 'O psicólogo recebe um e-mail para criar a senha e acessar o painel.'
              : 'Enviamos um e-mail para criar a senha.',
          icone: Icons.mail_outline_rounded,
        ),
      ],
    );
  }
}
