import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/core.dart';
import 'features/agenda_agendamento/minhas_consultas_screen.dart';
import 'features/auth/cadastro_screen.dart';
import 'features/auth/entrar_screen.dart';
import 'features/auth/layout_autenticacao.dart';
import 'features/conta/conta_screen.dart';
import 'features/painel_clinica/agenda_equipe_screen.dart';
import 'features/painel_clinica/equipe_screen.dart';
import 'features/painel_clinica/financeiro_equipe_screen.dart';
import 'features/painel_clinica/pagina_clinica_editor_screen.dart';
import 'features/painel_psicologo/agenda_screen.dart';
import 'features/painel_psicologo/disponibilidade_screen.dart';
import 'features/painel_psicologo/ficha_paciente_screen.dart';
import 'features/painel_psicologo/financeiro_screen.dart';
import 'features/painel_psicologo/minha_pagina_screen.dart';
import 'features/painel_psicologo/pacientes_screen.dart';
import 'features/painel_psicologo/relatorios_screen.dart';
import 'features/perfil_busca/buscar_screen.dart';
import 'features/perfil_busca/clinicas_screen.dart';
import 'features/perfil_busca/inicio_screen.dart';
import 'features/perfil_busca/pagina_clinica_screen.dart';
import 'features/perfil_busca/perfil_psicologo_screen.dart';
import 'features/planos/destaque_plano_screen.dart';

class PsiHubApp extends StatefulWidget {
  const PsiHubApp({super.key, this.store});

  /// Permite injetar um estado nos testes.
  final AppStore? store;

  @override
  State<PsiHubApp> createState() => _PsiHubAppState();
}

class _PsiHubAppState extends State<PsiHubApp> {
  late final AppStore _store = widget.store ?? AppStore();

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: _store,
      child: MaterialApp(
        title: 'PsiHub',
        debugShowCheckedModeBanner: false,
        theme: construirTema(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: Rotas.entrar,
        onGenerateRoute: (s) => gerarRota(s, _store),
        onGenerateInitialRoutes: (nome) => [
          gerarRota(RouteSettings(name: nome), _store) ??
              gerarRota(const RouteSettings(name: Rotas.entrar), _store)!,
        ],
        onUnknownRoute: (s) =>
            gerarRota(const RouteSettings(name: Rotas.entrar), _store),
      ),
    );
  }
}

/// Traduz o endereço em tela. A troca de rota é imediata: a barra de navegação
/// fica parada (com o indicador deslizando) e só o conteúdo entra com animação.
Route<dynamic>? gerarRota(RouteSettings settings, AppStore store) {
  final uri = Uri.parse(settings.name ?? '/');
  final q = uri.queryParameters;
  Widget paciente(Widget w) {
    store.garantirPapel(Papel.paciente);
    return w;
  }

  Widget psicologo(Widget w) {
    store.garantirPapel(Papel.psicologo);
    return w;
  }

  Widget clinica(Widget w) {
    store.garantirPapel(Papel.clinica);
    return w;
  }

  final Widget? tela = switch (uri.pathSegments) {
    [] => store.papel == null ? const EntrarScreen() : null,
    ['entrar'] => const EntrarScreen(),
    ['cadastro'] => const CadastroScreen(),
    // Paciente
    ['inicio'] => paciente(const InicioScreen()),
    ['buscar'] => paciente(
        BuscarScreen(
          textoInicial: q['q'],
          modalidadeInicial: Modalidade.values
              .where((m) => m.name == q['modalidade'])
              .firstOrNull,
        ),
      ),
    ['clinicas'] => paciente(const ClinicasScreen()),
    ['consultas'] => paciente(const MinhasConsultasScreen()),
    ['conta'] => paciente(const ContaPacienteScreen()),
    ['psicologos', final id] => () {
        final previa = q['previa'] == '1';
        if (!previa) store.garantirPapel(store.papel ?? Papel.paciente);
        return PerfilPsicologoScreen(psicologoId: id, previa: previa);
      }(),
    ['clinicas', final id] => PaginaClinicaScreen(clinicaId: id),
    // Psicólogo
    ['psicologo', 'agenda'] => psicologo(const AgendaScreen()),
    ['psicologo', 'disponibilidade'] =>
      psicologo(const DisponibilidadeScreen()),
    ['psicologo', 'pacientes'] => psicologo(const PacientesScreen()),
    ['psicologo', 'pacientes', final id] =>
      psicologo(FichaPacienteScreen(pacienteId: id)),
    ['psicologo', 'financeiro'] => psicologo(const FinanceiroScreen()),
    ['psicologo', 'minha-pagina'] => psicologo(const MinhaPaginaScreen()),
    ['psicologo', 'destaque'] =>
      psicologo(const DestaquePlanoScreen(papel: Papel.psicologo)),
    ['psicologo', 'relatorios'] => psicologo(const RelatoriosScreen()),
    ['psicologo', 'configuracoes'] =>
      psicologo(const ConfiguracoesScreen(papel: Papel.psicologo)),
    ['psicologo', 'mais'] =>
      psicologo(const MaisScreen(papel: Papel.psicologo)),
    // Clínica
    ['clinica', 'equipe'] => clinica(const EquipeScreen()),
    ['clinica', 'agenda'] => clinica(const AgendaEquipeScreen()),
    ['clinica', 'financeiro'] => clinica(const FinanceiroEquipeScreen()),
    ['clinica', 'pagina'] => clinica(const PaginaClinicaEditorScreen()),
    ['clinica', 'destaque'] =>
      clinica(const DestaquePlanoScreen(papel: Papel.clinica)),
    ['clinica', 'configuracoes'] =>
      clinica(const ConfiguracoesScreen(papel: Papel.clinica)),
    ['clinica', 'mais'] => clinica(const MaisScreen(papel: Papel.clinica)),
    _ => null,
  };

  if (tela == null) {
    // "/" com alguém já logado vai para a tela inicial do perfil.
    if (uri.pathSegments.isEmpty && store.papel != null) {
      return gerarRota(RouteSettings(name: rotaInicialDo(store.papel!)), store);
    }
    return null;
  }
  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, __, ___) => tela,
  );
}
