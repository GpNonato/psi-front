// Garante que nenhum arquivo do app ficou com acentos corrompidos (texto em
// UTF-8 lido como Windows-1252 e gravado de novo, que vira "Ã§", "Â·" etc.).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arquivos .dart estão em UTF-8 e sem acentos corrompidos', () {
    final corrompido = RegExp('Ã[\u0080-¿§£¡©ª¢³º¨µ]|Â[·°ºª©®«»]|â€');
    final problemas = <String>[];
    for (final pasta in ['lib', 'test', 'tool']) {
      for (final f in Directory(pasta)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final String texto;
        try {
          texto = utf8.decode(f.readAsBytesSync());
        } on FormatException {
          problemas.add('${f.path}: não é UTF-8 válido');
          continue;
        }
        final linhas = const LineSplitter().convert(texto);
        for (var i = 0; i < linhas.length; i++) {
          // Esta própria verificação descreve os padrões no comentário acima.
          if (f.path.endsWith('codificacao_test.dart')) break;
          if (corrompido.hasMatch(linhas[i])) {
            problemas.add('${f.path}:${i + 1}: ${linhas[i].trim()}');
          }
        }
      }
    }
    expect(problemas, isEmpty, reason: problemas.join('\n'));
  });
}
