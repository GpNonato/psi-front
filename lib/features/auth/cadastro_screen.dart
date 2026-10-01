import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'layout_autenticacao.dart';

/// Criar conta (wireframe 08).
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _crp = TextEditingController();
  final _senha = TextEditingController();
  Papel _papel = Papel.psicologo;
  bool _termos = false;
  bool _tentou = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _crp.dispose();
    _senha.dispose();
    super.dispose();
  }

  String? get _erroNome =>
      _nome.text.trim().length < 3 ? 'Informe o nome completo.' : null;

  String? get _erroEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())
          ? null
          : 'Informe um e-mail válido.';

  String? get _erroCrp {
    if (_papel != Papel.psicologo) return null;
    return RegExp(r'^\d{2}/\d{4,6}$').hasMatch(_crp.text.trim())
        ? null
        : 'Use o formato 00/00000.';
  }

  String? get _erroSenha => _senha.text.length < 8
      ? 'A senha precisa de 8 caracteres ou mais.'
      : null;

  bool get _valido =>
      _erroNome == null &&
      _erroEmail == null &&
      _erroCrp == null &&
      _erroSenha == null &&
      _termos;

  void _criar() {
    setState(() => _tentou = true);
    if (!_valido) return;
    final store = context.acoes;
    final conta = switch (_papel) {
      Papel.paciente => store.pacienteNome,
      Papel.psicologo => store.psicologoAtual.nome,
      Papel.clinica => store.clinicaAtual.nome,
    };
    store.entrar(_papel);
    irPara(context, rotaInicialDo(_papel));
    avisar(
      context,
      'Conta criada! Nesta demonstração você entra na conta de exemplo ($conta).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final opcoes = [
      (
        Papel.paciente,
        'Paciente',
        wide
            ? 'Quero encontrar e agendar consultas'
            : 'Encontrar e agendar consultas'
      ),
      (Papel.psicologo, 'Psicólogo(a)', 'Atendo de forma independente'),
      (
        Papel.clinica,
        'Clínica',
        wide
            ? 'Cadastro a clínica e minha equipe'
            : 'Cadastro a clínica e a equipe'
      ),
    ];
    Widget cartao((Papel, String, String) o) => CartaoOpcao(
          selecionado: _papel == o.$1,
          alinharTopo: wide,
          padding: EdgeInsets.fromLTRB(16, wide ? 20 : 14, 12, wide ? 20 : 14),
          onTap: () => setState(() => _papel = o.$1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(o.$2,
                  style: const TextStyle(fontSize: 16, color: AppColors.texto)),
              const SizedBox(height: 4),
              Text(o.$3,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textoSecundario,
                      height: 1.4)),
            ],
          ),
        );

    final crp = CampoTexto(
      controller: _crp,
      rotulo: 'CRP',
      hint: '00/00000',
      erro: _tentou ? _erroCrp : null,
      onChanged: (_) => setState(() {}),
    );
    final email = CampoTexto(
      controller: _email,
      rotulo: 'E-mail',
      hint: 'nome@email.com',
      teclado: TextInputType.emailAddress,
      erro: _tentou ? _erroEmail : null,
      onChanged: (_) => setState(() {}),
    );
    final senha = CampoTexto(
      controller: _senha,
      rotulo: 'Senha',
      hint: wide ? 'Mínimo de 8 caracteres' : '8+ caracteres',
      senha: true,
      erro: _tentou ? _erroSenha : null,
      onChanged: (_) => setState(() {}),
    );

    return LayoutAutenticacao(
      formulario: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true,
              child: Text('Criar conta', style: AppText.serif(wide ? 32 : 28))),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Já tem conta?',
                  style: TextStyle(
                      fontSize: 14.5, color: AppColors.textoSecundario)),
              const SizedBox(width: 8),
              LinkTexto('Entrar', onTap: () => irPara(context, Rotas.entrar)),
            ],
          ),
          SizedBox(height: wide ? 24 : 16),
          const Text('Como você vai usar o PsiHub?', style: AppText.rotulo),
          const SizedBox(height: 10),
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < opcoes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cartao(opcoes[i])),
                  ],
                ],
              ),
            )
          else
            for (final o in opcoes)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8), child: cartao(o)),
          SizedBox(height: wide ? 24 : 12),
          CampoTexto(
            controller: _nome,
            rotulo: _papel == Papel.clinica ? 'Nome da clínica' : 'Nome',
            hint: _papel == Papel.clinica ? 'Nome da clínica' : 'Nome completo',
            erro: _tentou ? _erroNome : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (wide) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: email),
                if (_papel == Papel.psicologo) ...[
                  const SizedBox(width: 16),
                  Expanded(child: crp)
                ],
              ],
            ),
            const SizedBox(height: 10),
            senha,
          ] else ...[
            email,
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_papel == Papel.psicologo) ...[
                  Expanded(child: crp),
                  const SizedBox(width: 16)
                ],
                Expanded(child: senha),
              ],
            ),
          ],
          const SizedBox(height: 13),
          LinhaCheck(
            rotulo: wide
                ? 'Li e aceito os termos de uso e a política de privacidade'
                : 'Aceito termos e política de privacidade',
            valor: _termos,
            onChanged: (v) => setState(() => _termos = v),
          ),
          if (_tentou && !_termos)
            const Padding(
              padding: EdgeInsets.only(left: 34, top: 2),
              child: Text(
                'É preciso aceitar os termos para criar a conta.',
                style: TextStyle(color: AppColors.vermelho, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 18),
          BotaoPill('Criar conta',
              expandir: true, altura: 52, onPressed: _criar),
          const SizedBox(height: 24),
          if (_papel == Papel.psicologo)
            wide
                ? const AvisoLavanda(
                    'A clínica cria o seu acesso; confira seu e-mail.',
                    titulo: 'Atende em uma clínica?',
                  )
                : const Center(
                    child: Text(
                      'Atende em clínica? A clínica cria seu acesso.',
                      style:
                          TextStyle(fontSize: 13.5, color: AppColors.lavanda),
                    ),
                  ),
        ],
      ),
    );
  }
}
