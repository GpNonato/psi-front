// Utilidades dos testes: fontes reais (para medir textos como no navegador),
// tamanhos de tela e navegação.

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

/// Carrega Roboto, os ícones do Material e as fontes de título (Fraunces, Lora
/// e DM Serif Display). Sem isso, o ambiente de teste usa uma fonte de blocos,
/// bem mais larga que a real.
Future<void> carregarFontesReais() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '../flutter-sdk';
  final pasta = '$sdk/bin/cache/artifacts/material_fonts';
  await _fonte('Roboto', [
    '$pasta/roboto-regular.ttf',
    '$pasta/roboto-medium.ttf',
    '$pasta/roboto-bold.ttf',
    '$pasta/roboto-italic.ttf',
  ]);
  await _fonte('MaterialIcons', ['$pasta/materialicons-regular.otf']);
  await _fonte('Fraunces', [
    'assets/fonts/Fraunces-Variable.ttf',
    'assets/fonts/Fraunces-Italic-Variable.ttf',
  ]);
  await _fonte('Lora', [
    'assets/fonts/Lora-Variable.ttf',
    'assets/fonts/Lora-Italic-Variable.ttf',
  ]);
  await _fonte('DMSerifDisplay', [
    'assets/fonts/DMSerifDisplay-Regular.ttf',
    'assets/fonts/DMSerifDisplay-Italic.ttf',
  ]);
}

class Tela {
  const Tela(this.nome, this.largura, this.altura);
  final String nome;
  final double largura;
  final double altura;
}

const telas = [
  Tela('desktop', 1440, 1024),
  Tela('tablet', 1024, 768),
  Tela('celular', 390, 844),
  Tela('celular pequeno', 360, 740),
];

void usarTela(WidgetTester tester, Tela tela) {
  tester.view.physicalSize = Size(tela.largura, tela.altura);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<AppStore> abrirApp(WidgetTester tester, {String? rota}) async {
  final store = AppStore();
  await tester.pumpWidget(PsiHubApp(store: store));
  await tester.pumpAndSettle();
  if (rota != null) await ir(tester, rota);
  return store;
}

Future<void> ir(WidgetTester tester, String rota) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.pushNamedAndRemoveUntil(rota, (_) => false);
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, Finder alvo) async {
  expect(alvo, findsWidgets, reason: 'não achei $alvo para tocar');
  await tester.ensureVisible(alvo.first);
  await tester.pumpAndSettle();
  await tester.tap(alvo.first);
  await tester.pumpAndSettle();
}

Finder porRotulo(String rotulo) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.label == rotulo);

Finder botao(String texto) => find.ancestor(
      of: find.text(texto),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

/// Leva cada área rolável vertical até o fim, para montar e medir o conteúdo
/// que fica abaixo da dobra.
Future<void> rolarTudoAteOFim(WidgetTester tester) async {
  for (var volta = 0; volta < 2; volta++) {
    final estados =
        tester.stateList<ScrollableState>(find.byType(Scrollable)).toList();
    for (final estado in estados) {
      final pos = estado.position;
      if (pos.axis == Axis.vertical && pos.maxScrollExtent > pos.pixels) {
        pos.jumpTo(pos.maxScrollExtent);
      }
    }
    await tester.pumpAndSettle();
  }
}
