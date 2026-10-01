// Gera o favicon e os ícones do app web a partir do símbolo do PsiHub
// (folha com cérebro):
//
//   flutter test --update-goldens tool/icones_test.dart
//
// Depois, copie tool/icones/*.png para web/ (favicon.png) e web/icons/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';

void _icone(String nome, double lado, Widget Function(double lado) desenho) {
  testWidgets(nome, (tester) async {
    tester.view.physicalSize = Size(lado, lado);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final chave = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: chave,
            child: SizedBox.square(dimension: lado, child: desenho(lado)),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(chave), matchesGoldenFile('icones/$nome.png'));
  });
}

/// Folha com cérebro, com uma margem pequena (ícone comum, fundo transparente).
Widget _marca(double lado) => Center(child: MarcaPsiHub(tamanho: lado * 0.92));

/// Ícone "maskable": fundo oliva ocupando tudo e o cérebro dentro da área segura.
Widget _mascaravel(double lado) => Container(
      color: AppColors.oliva,
      alignment: Alignment.center,
      child: CerebroPsiHub(tamanho: lado * 0.46),
    );

void main() {
  _icone('favicon', 64, _marca);
  _icone('Icon-192', 192, _marca);
  _icone('Icon-512', 512, _marca);
  _icone('Icon-maskable-192', 192, _mascaravel);
  _icone('Icon-maskable-512', 512, _mascaravel);
}
