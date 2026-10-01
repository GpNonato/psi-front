// Abre todas as telas em quatro tamanhos com as fontes reais. Qualquer erro de
// layout (texto estourando, conteúdo cortado) ou exceção faz o teste falhar.

import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';

import 'util/ambiente.dart';

void main() {
  setUpAll(carregarFontesReais);

  final store = AppStore();
  final rotas = <String>[
    Rotas.entrar,
    Rotas.cadastro,
    Rotas.inicio,
    Rotas.buscar,
    Rotas.busca(texto: 'Ansiedade', modalidade: 'online'),
    Rotas.busca(texto: 'xyz sem resultado'),
    Rotas.clinicas,
    Rotas.consultas,
    Rotas.conta,
    for (final p in store.psicologos) Rotas.perfilPsicologo(p.id),
    '${Rotas.perfilPsicologo('ana')}?previa=1',
    for (final c in store.clinicas) Rotas.paginaClinica(c.id),
    Rotas.agenda,
    Rotas.disponibilidade,
    Rotas.pacientes,
    for (final p in store.pacientes) Rotas.ficha(p.id),
    Rotas.financeiro,
    Rotas.minhaPagina,
    Rotas.destaque,
    Rotas.relatorios,
    Rotas.configuracoes,
    Rotas.maisPsicologo,
    Rotas.equipe,
    Rotas.agendaEquipe,
    Rotas.financeiroEquipe,
    Rotas.paginaDaClinica,
    Rotas.destaqueClinica,
    Rotas.configuracoesClinica,
    Rotas.maisClinica,
    '/rota-que-nao-existe',
  ];

  for (final tela in telas) {
    group('Tela ${tela.nome} (${tela.largura.toInt()}x${tela.altura.toInt()})',
        () {
      for (final rota in rotas) {
        // Sem takeException: se algo der errado, o próprio framework falha o
        // teste e mostra o widget responsável.
        testWidgets(rota, (tester) async {
          usarTela(tester, tela);
          await abrirApp(tester, rota: rota);
          await rolarTudoAteOFim(tester);
        });
      }
    });
  }
}
