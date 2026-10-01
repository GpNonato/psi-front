// Gera capturas das telas nos tamanhos dos wireframes (docs/imagens/wireframes),
// com as fontes reais, para comparar lado a lado:
//
//   flutter test --update-goldens tool/capturas_test.dart
//
// As imagens ficam em tool/capturas/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';
import 'package:psihub_app/main.dart';

Future<void> _fonte(String familia, List<String> arquivos) async {
  final loader = FontLoader(familia);
  for (final a in arquivos) {
    final bytes = File(a).readAsBytesSync();
    loader
        .addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  }
  await loader.load();
}

String _sdk() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) return flutterRoot;
  return '../flutter-sdk';
}

typedef Passo = Future<void> Function(WidgetTester tester);

Future<void> _ir(WidgetTester tester, String rota) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.pushNamedAndRemoveUntil(rota, (_) => false);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder _porRotulo(String rotulo) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.label == rotulo);

void _captura(String nome, Size tamanho, List<Passo> passos) {
  // As telas web são vistas no Chrome de um computador (Windows); as de
  // celular, num Android. A plataforma muda o alvo de toque dos botões.
  final plataforma =
      tamanho.width >= 900 ? TargetPlatform.windows : TargetPlatform.android;
  testWidgets(variant: TargetPlatformVariant.only(plataforma), nome,
      (tester) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1.0;
    if (plataforma == TargetPlatform.android) {
      // Os wireframes de celular têm a barra de status (47 px) e o
      // indicador de gestos (34 px) de um iPhone.
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    }
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PsiHubApp(store: AppStore()));
    await tester.pumpAndSettle();
    for (final p in passos) {
      await p(tester);
    }
    await tester.pumpAndSettle();
    // Os toques rolam a página até o alvo; os wireframes mostram o topo.
    for (final s
        in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
      final pos = s.position;
      if (pos.axis == Axis.vertical && pos.pixels != pos.minScrollExtent) {
        pos.jumpTo(pos.minScrollExtent);
      }
    }
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('capturas/$nome.png'));
  });
}

Passo ir(String rota) => (t) => _ir(t, rota);

void main() {
  setUpAll(() async {
    final fontes = '${_sdk()}/bin/cache/artifacts/material_fonts';
    await _fonte('Roboto', [
      '$fontes/roboto-regular.ttf',
      '$fontes/roboto-medium.ttf',
      '$fontes/roboto-bold.ttf',
      '$fontes/roboto-italic.ttf',
    ]);
    await _fonte('MaterialIcons', ['$fontes/materialicons-regular.otf']);
    await _fonte('DMSerifDisplay', [
      'assets/fonts/DMSerifDisplay-Regular.ttf',
      'assets/fonts/DMSerifDisplay-Italic.ttf',
    ]);
    await _fonte('Fraunces', [
      'assets/fonts/Fraunces-Variable.ttf',
      'assets/fonts/Fraunces-Italic-Variable.ttf',
    ]);
    await _fonte('Lora', [
      'assets/fonts/Lora-Variable.ttf',
      'assets/fonts/Lora-Italic-Variable.ttf',
    ]);
  });

  const web = 1440.0;
  const cel = 390.0;

  final paciente = ir(Rotas.inicio);
  final psicologo = ir(Rotas.agenda);
  final clinica = ir(Rotas.equipe);

  Future<void> agendarQuinta(WidgetTester t) async {
    await _tocar(t, _porRotulo('Quinta-feira, 24 de setembro').first);
    await _tocar(t, _porRotulo('14:30, livre').first);
  }

  // ----------------------------------------------------------------- web
  _captura('web-00-entrar', const Size(web, 1024), [ir(Rotas.entrar)]);
  _captura('web-08-cadastro', const Size(web, 1024), [ir(Rotas.cadastro)]);
  _captura('web-01-inicio', const Size(web, 1330), [paciente]);
  _captura('web-02-buscar', const Size(web, 1024),
      [ir(Rotas.busca(texto: 'Ansiedade'))]);
  _captura('web-02b-buscar-tudo', const Size(web, 1024), [ir(Rotas.buscar)]);
  _captura('web-03-perfil', const Size(web, 1770),
      [paciente, ir(Rotas.perfilPsicologo('ana')), agendarQuinta]);
  _captura('web-04-confirmar', const Size(web, 1770), [
    paciente,
    ir(Rotas.perfilPsicologo('ana')),
    agendarQuinta,
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Agendar consulta')),
  ]);
  _captura('web-05-consultas', const Size(web, 1024), [ir(Rotas.consultas)]);
  _captura('web-06-avaliar', const Size(web, 1024), [
    ir(Rotas.consultas),
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Avaliar')),
    (t) => _tocar(t, find.byTooltip('4 estrelas: Muito bom')),
    (t) async {
      await t.enterText(
        find.byType(TextField).first,
        'A Ana me ajudou muito a lidar com a ansiedade no trabalho. Escuta atenta e acolhedora.',
      );
      await t.pumpAndSettle();
    },
  ]);
  _captura('web-07-clinica', const Size(web, 1100),
      [paciente, ir(Rotas.paginaClinica('equilibrio'))]);
  _captura('web-09-agenda', const Size(web, 1024), [psicologo]);
  _captura('web-10-disponibilidade', const Size(web, 1024),
      [ir(Rotas.disponibilidade)]);
  _captura('web-11-pacientes', const Size(web, 1024), [ir(Rotas.pacientes)]);
  _captura('web-12-ficha', const Size(web, 1024), [ir(Rotas.ficha('marina'))]);
  _captura('web-13-financeiro', const Size(web, 1024), [ir(Rotas.financeiro)]);
  _captura(
      'web-14-minha-pagina', const Size(web, 1024), [ir(Rotas.minhaPagina)]);
  _captura('web-15-destaque', const Size(web, 1024), [ir(Rotas.destaque)]);
  _captura('web-16-equipe', const Size(web, 1024), [clinica]);
  _captura('web-17-cadastrar', const Size(web, 1024), [
    clinica,
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Cadastrar psicólogo')),
  ]);
  _captura(
      'web-18-agenda-equipe', const Size(web, 1024), [ir(Rotas.agendaEquipe)]);
  _captura('web-19-financeiro-equipe', const Size(web, 1024),
      [ir(Rotas.financeiroEquipe)]);
  _captura('web-20-destaque-clinica', const Size(web, 1024),
      [ir(Rotas.destaqueClinica)]);

  // ----------------------------------------------------------------- celular
  _captura('cel-08-cadastro', const Size(cel, 844), [ir(Rotas.cadastro)]);
  _captura('cel-01-inicio', const Size(cel, 844), [paciente]);
  _captura('cel-02-buscar', const Size(cel, 844),
      [ir(Rotas.busca(texto: 'Ansiedade'))]);
  _captura('cel-03-perfil', const Size(cel, 1740),
      [paciente, ir(Rotas.perfilPsicologo('ana')), agendarQuinta]);
  _captura('cel-04-confirmar', const Size(cel, 844), [
    paciente,
    ir(Rotas.perfilPsicologo('ana')),
    agendarQuinta,
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Agendar consulta')),
  ]);
  _captura('cel-05-consultas', const Size(cel, 844), [ir(Rotas.consultas)]);
  _captura('cel-06-avaliar', const Size(cel, 844), [
    ir(Rotas.consultas),
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Avaliar')),
    (t) => _tocar(t, find.byTooltip('4 estrelas: Muito bom')),
  ]);
  _captura('cel-07-clinica', const Size(cel, 844),
      [paciente, ir(Rotas.paginaClinica('equilibrio'))]);
  _captura('cel-09-agenda', const Size(cel, 844), [psicologo]);
  _captura('cel-10-disponibilidade', const Size(cel, 844),
      [ir(Rotas.disponibilidade)]);
  _captura('cel-11-pacientes', const Size(cel, 844), [ir(Rotas.pacientes)]);
  _captura('cel-12-ficha', const Size(cel, 1400), [ir(Rotas.ficha('marina'))]);
  _captura('cel-13-financeiro', const Size(cel, 844), [ir(Rotas.financeiro)]);
  _captura(
      'cel-14-minha-pagina', const Size(cel, 844), [ir(Rotas.minhaPagina)]);
  _captura('cel-15-destaque', const Size(cel, 900), [ir(Rotas.destaque)]);
  _captura('cel-16-equipe', const Size(cel, 844), [clinica]);
  _captura('cel-17-cadastrar', const Size(cel, 844), [
    clinica,
    (t) => _tocar(t, find.widgetWithText(FilledButton, 'Cadastrar')),
  ]);
  _captura(
      'cel-18-agenda-equipe', const Size(cel, 844), [ir(Rotas.agendaEquipe)]);
  _captura('cel-19-financeiro-equipe', const Size(cel, 844),
      [ir(Rotas.financeiroEquipe)]);
  _captura('cel-20-destaque-clinica', const Size(cel, 900),
      [ir(Rotas.destaqueClinica)]);
}
