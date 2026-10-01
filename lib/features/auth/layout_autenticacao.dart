import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Moldura das telas de entrada e cadastro (wireframe 08): painel lavanda à
/// esquerda no web e formulário à direita.
class LayoutAutenticacao extends StatelessWidget {
  const LayoutAutenticacao({super.key, required this.formulario});

  final Widget formulario;

  @override
  Widget build(BuildContext context) {
    if (!context.isWide) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                    alignment: Alignment.centerLeft,
                    child: PsiHubLogo(tamanho: 22)),
                const SizedBox(height: 18),
                EntradaSuave(child: formulario),
              ],
            ),
          ),
        ),
      );
    }
    // Wireframe 08 (1440 px): painel de 640 px e formulário de 520 px entre
    // x = 760 e 1280, com o título a cerca de 100 px do topo.
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(flex: 4, child: _PainelLavanda()),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(48, 103, 48, 64),
              child: Align(
                alignment: const Alignment(-0.22, -1),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: EntradaSuave(child: formulario),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelLavanda extends StatelessWidget {
  const _PainelLavanda();

  @override
  Widget build(BuildContext context) {
    const cor = AppColors.lavandaEscuro;
    const itens = [
      'Catálogo com avaliações de pacientes reais',
      'Agenda, pacientes e fluxo de caixa',
      'Clínicas gerenciam toda a equipe',
    ];
    return Container(
      color: AppColors.lavandaClaro,
      padding: const EdgeInsets.fromLTRB(80, 64, 64, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PsiHubLogo(),
          const Spacer(flex: 4),
          const TituloSerif(
            'Cuidado que\n',
            italico: 'começa no encontro.',
            tamanho: 44,
            cor: cor,
            altura: 1.3,
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: const Text(
              'Pacientes encontram e agendam. Psicólogos e clínicas organizam agenda, '
              'pacientes e financeiro em um só lugar.',
              style: TextStyle(fontSize: 16.5, height: 1.6, color: cor),
            ),
          ),
          const SizedBox(height: 43),
          for (final t in itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child:
                        const Icone(Icons.check_rounded, size: 16, color: cor),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                      child: Text(t,
                          style: const TextStyle(fontSize: 15.5, color: cor))),
                ],
              ),
            ),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}

/// Destino inicial de cada perfil depois de entrar.
String rotaInicialDo(Papel papel) => switch (papel) {
      Papel.paciente => Rotas.inicio,
      Papel.psicologo => Rotas.agenda,
      Papel.clinica => Rotas.equipe,
    };
