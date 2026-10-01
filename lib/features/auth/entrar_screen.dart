import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'layout_autenticacao.dart';

/// E-mails das contas de exemplo desta demonstração.
const contasDemonstracao = {
  'marina.souza@email.com': Papel.paciente,
  'ana.ribeiro@email.com': Papel.psicologo,
  'contato@clinicaequilibrio.com.br': Papel.clinica,
};

/// Entrar (acesso pelo link "Entrar" do cadastro).
class EntrarScreen extends StatefulWidget {
  const EntrarScreen({super.key});

  @override
  State<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends State<EntrarScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _entrarComo(Papel papel) {
    context.acoes.entrar(papel);
    irPara(context, rotaInicialDo(papel));
  }

  void _entrar() {
    final email = _email.text.trim().toLowerCase();
    final papel = contasDemonstracao[email];
    if (papel == null || _senha.text.length < 8) {
      setState(() {
        _erro =
            'E-mail ou senha incorretos. Nesta demonstração, use um dos acessos '
            'de exemplo abaixo.';
      });
      return;
    }
    _entrarComo(papel);
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return LayoutAutenticacao(
      formulario: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true,
              child: Text('Entrar', style: AppText.serif(wide ? 32 : 28))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Não tem conta?',
                  style: TextStyle(
                      fontSize: 14.5, color: AppColors.textoSecundario)),
              const SizedBox(width: 8),
              LinkTexto('Criar conta',
                  onTap: () => irPara(context, Rotas.cadastro)),
            ],
          ),
          const SizedBox(height: 28),
          CampoTexto(
            controller: _email,
            rotulo: 'E-mail',
            hint: 'nome@email.com',
            teclado: TextInputType.emailAddress,
            acaoTeclado: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          CampoTexto(
            controller: _senha,
            rotulo: 'Senha',
            hint: 'Mínimo de 8 caracteres',
            senha: true,
            acaoTeclado: TextInputAction.done,
            onSubmitted: (_) => _entrar(),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!,
                style:
                    const TextStyle(color: AppColors.vermelho, fontSize: 14)),
          ],
          const SizedBox(height: 24),
          BotaoPill('Entrar', expandir: true, altura: 52, onPressed: _entrar),
          // O link do topo passava despercebido: o cadastro também fica como
          // segundo botão, logo abaixo de "Entrar".
          const SizedBox(height: 12),
          BotaoPill(
            'Criar conta',
            estilo: EstiloBotao.contorno,
            expandir: true,
            altura: 52,
            onPressed: () => irPara(context, Rotas.cadastro),
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Acesso de demonstração', style: AppText.pequeno),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          _BotaoDemo(
            icone: Icons.person_outline_rounded,
            titulo: 'Paciente',
            detalhe: 'Marina Souza · busca, agenda e avalia consultas',
            onTap: () => _entrarComo(Papel.paciente),
          ),
          const SizedBox(height: 10),
          _BotaoDemo(
            icone: Icons.psychology_outlined,
            titulo: 'Psicóloga',
            detalhe: 'Ana Ribeiro · agenda, pacientes, financeiro e página',
            onTap: () => _entrarComo(Papel.psicologo),
          ),
          const SizedBox(height: 10),
          _BotaoDemo(
            icone: Icons.apartment_outlined,
            titulo: 'Clínica',
            detalhe: 'Clínica Equilíbrio · equipe, agenda e financeiro',
            onTap: () => _entrarComo(Papel.clinica),
          ),
          const SizedBox(height: 22),
          const AvisoLavanda(
            'Os dados são fictícios e ficam só na memória do app: nada é enviado para a '
            'API. A data da demonstração é segunda, 21 de setembro de 2026.',
            compacto: true,
          ),
        ],
      ),
    );
  }
}

class _BotaoDemo extends StatelessWidget {
  const _BotaoDemo({
    required this.icone,
    required this.titulo,
    required this.detalhe,
    required this.onTap,
  });

  final IconData icone;
  final String titulo;
  final String detalhe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CartaoOpcao(
      selecionado: false,
      mostrarRadio: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.salvia,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icone(icone, color: AppColors.olivaEscuro),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entrar como ${titulo.toLowerCase()}',
                    style: const TextStyle(fontSize: 15.5)),
                Text(detalhe, style: AppText.pequeno),
              ],
            ),
          ),
          const Icone(Icons.arrow_forward_rounded,
              color: AppColors.textoSecundario),
        ],
      ),
    );
  }
}
