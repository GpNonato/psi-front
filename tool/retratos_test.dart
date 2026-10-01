// Grade com todos os retratos ilustrados, para ajustar o desenho:
//   flutter test --update-goldens tool/retratos_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';

void main() {
  testWidgets('retratos', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final store = AppStore();
    final pessoas = [
      for (final p in store.psicologos) (p.nome, p.feminino),
      ('Marina Souza', true),
      ('Pedro Alves', false),
    ];
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (nome, fem) in pessoas)
                  Ilustracao.retrato(nome,
                      feminino: fem, largura: 180, altura: 200),
                const Ilustracao.retrato('Ana Ribeiro',
                    feminino: true, largura: 300, altura: 128),
                const Ilustracao.encontro(largura: 276, altura: 248),
                const Ilustracao.mapa(largura: 256, altura: 168),
                for (var v = 0; v < 6; v++)
                  Ilustracao.ambiente(v, largura: 180, altura: 140),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('capturas/retratos.png'));
  });
}
