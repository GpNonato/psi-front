import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';
import 'package:psihub_app/main.dart';

void main() {
  group('Regras dos dados de exemplo', () {
    test('quinta, 24 set: horários do wireframe 03, com 10:00 e 16:30 ocupados',
        () {
      final store = AppStore();
      final ana = store.psicologo('ana');
      final horarios = store.horariosDoDia(ana, DateTime(2026, 9, 24));
      expect(
        horarios.map((h) => Fmt.hora(h.inicio)),
        [
          '08:00',
          '09:00',
          '10:00',
          '11:00',
          '14:30',
          '15:30',
          '16:30',
          '17:30',
          '18:30'
        ],
      );
      expect(
        horarios.where((h) => h.ocupado).map((h) => Fmt.hora(h.inicio)),
        ['10:00', '16:30'],
      );
    });

    test('agendar ocupa o horário e avisa a psicóloga; cancelar libera', () {
      final store = AppStore();
      final ana = store.psicologo('ana');
      final inicio = DateTime(2026, 9, 24, 14, 30);
      bool ocupado() => store
          .horariosDoDia(ana, inicio)
          .firstWhere((h) => h.inicio == inicio)
          .ocupado;

      final c = store.agendar(
          psicologoId: 'ana', inicio: inicio, modalidade: Modalidade.online);
      expect(ocupado(), isTrue);
      expect(store.notificacoes(Papel.psicologo).first.titulo,
          'Nova consulta marcada');
      expect(
        () => store.agendar(
            psicologoId: 'ana', inicio: inicio, modalidade: Modalidade.online),
        throwsA(isA<ErroAgendamento>()),
      );

      store.cancelarConsulta(c.id, peloPaciente: true);
      expect(ocupado(), isFalse);
      expect(store.notificacoes(Papel.psicologo).first.titulo,
          'Consulta cancelada');
    });

    test('remarcar cancela a consulta original e cria a nova', () {
      final store = AppStore();
      final original =
          store.minhasConsultas.firstWhere((c) => c.proxima(store.agora));
      final nova = store.remarcar(
          original.id, DateTime(2026, 9, 25, 10), Modalidade.online);
      expect(original.cancelada, isTrue);
      expect(nova.inicio, DateTime(2026, 9, 25, 10));
      expect(nova.cancelada, isFalse);
    });

    test('avaliação de consulta realizada entra na nota e no perfil', () {
      final store = AppStore();
      final ana = store.psicologo('ana');
      final antes = ana.totalAvaliacoes;
      final realizada = store.minhasConsultas
          .firstWhere((c) => c.realizada(store.agora) && c.avaliacao == null);
      store.avaliar(realizada.id, nota: 4, texto: 'Muito bom', comNome: true);
      expect(ana.totalAvaliacoes, antes + 1);
      expect(store.avaliacoesDe('ana').first.autor, 'Marina S.');
      expect(realizada.avaliacao, 4);
    });

    test(
        'clínica vê só totais agregados, e os da Ana batem com o financeiro dela',
        () {
      final store = AppStore();
      final ana = store.equipe.firstWhere((m) => m.psicologoId == 'ana');
      final (consultas, recebido, aReceber) = store.totaisDoMembro(ana, 9);
      final resumo = store.resumo(2026, 9);
      expect(consultas, resumo.sessoes);
      expect(recebido, resumo.recebido);
      expect(aReceber, resumo.aReceber);
    });
  });

  group('Telas', () {
    void telaGrande(WidgetTester tester) {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('abre na entrada com os acessos de demonstração',
        (tester) async {
      await tester.pumpWidget(const PsiHubApp());
      await tester.pumpAndSettle();
      expect(find.text('Entrar como paciente'), findsOneWidget);
      expect(find.text('Entrar como psicóloga'), findsOneWidget);
      expect(find.text('Entrar como clínica'), findsOneWidget);
    });

    testWidgets('paciente vê o início com psicólogos e clínicas em destaque',
        (tester) async {
      telaGrande(tester);
      await tester.pumpWidget(const PsiHubApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar como paciente'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar psicólogos'), findsOneWidget);
      expect(find.text('Ana Ribeiro'), findsOneWidget);
      expect(find.text('Clínica Equilíbrio'), findsOneWidget);
    });

    testWidgets('psicóloga vê a agenda da semana', (tester) async {
      telaGrande(tester);
      await tester.pumpWidget(const PsiHubApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar como psicóloga'));
      await tester.pumpAndSettle();
      expect(find.text('21 – 27 de setembro de 2026'), findsOneWidget);
      expect(find.text('Pedro A.'), findsOneWidget);
      expect(find.text('Notificações'), findsOneWidget);
    });

    testWidgets('clínica vê a equipe com o acesso pendente', (tester) async {
      telaGrande(tester);
      await tester.pumpWidget(const PsiHubApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar como clínica'));
      await tester.pumpAndSettle();
      expect(find.text('Fernanda Lima'), findsOneWidget);
      expect(find.text('Reenviar acesso'), findsOneWidget);
    });
  });
}
