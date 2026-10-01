// Fluxos completos pela interface, como uma pessoa usaria: cada teste toca nos
// botões das telas e confere o resultado nas outras telas que dependem dele.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';
import 'package:psihub_app/features/perfil_busca/buscar_screen.dart';

import 'util/ambiente.dart';

final _desktop = telas.first;
final _celular = telas[2];
final _quinta = DateTime(2026, 9, 24);

Future<void> _escolherHorario(
    WidgetTester tester, DateTime dia, String hora) async {
  await tocar(tester, porRotulo(Fmt.dataLonga(dia)));
  await tocar(tester, porRotulo('$hora, livre'));
}

Future<void> _digitar(WidgetTester tester, String dica, String texto) async {
  final campo = find.widgetWithText(TextField, dica);
  expect(campo, findsOneWidget, reason: 'campo "$dica"');
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(carregarFontesReais);

  group('Paciente', () {
    testWidgets('entra pela conta de demonstração e sai pelo menu da conta',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester);
      await tocar(tester, find.text('Entrar como paciente'));
      expect(store.papel, Papel.paciente);
      expect(find.text('Buscar'), findsWidgets);

      await tocar(tester, find.byTooltip('Menu da conta'));
      await tocar(tester, find.text('Sair'));
      expect(store.papel, isNull);
      expect(find.text('Entrar como paciente'), findsOneWidget);
    });

    testWidgets(
        'agenda no perfil, vê em Minhas consultas e a psicóloga recebe a Nova',
        (tester) async {
      usarTela(tester, _desktop);
      final store =
          await abrirApp(tester, rota: Rotas.perfilPsicologo(idPsicologoDemo));
      await _escolherHorario(tester, _quinta, '14:30');
      expect(
          find.text('Qui, 24 set · 14:30 às 15:20 · Online'), findsOneWidget);

      await tocar(tester, botao('Agendar consulta'));
      await tocar(tester, botao('Confirmar agendamento'));
      final nova = store.minhasConsultas
          .singleWhere((c) => c.inicio == DateTime(2026, 9, 24, 14, 30));
      expect(nova.nova, isTrue);
      expect(nova.cancelada, isFalse);

      // O horário escolhido deixa de estar livre no perfil.
      await tocar(tester, botao('Ver minhas consultas'));
      expect(find.text('Minhas consultas'), findsWidgets);
      expect(porRotulo(Fmt.dataLonga(_quinta)), findsOneWidget);

      await ir(tester, Rotas.perfilPsicologo(idPsicologoDemo));
      await tocar(tester, porRotulo(Fmt.dataLonga(_quinta)));
      expect(porRotulo('14:30, ocupado'), findsOneWidget);
      expect(porRotulo('14:30, livre'), findsNothing);

      // Na agenda da psicóloga: bloco "Nova" e notificação no topo.
      await ir(tester, Rotas.agenda);
      expect(find.text('Marina S.'), findsWidgets);
      expect(find.text('Nova'), findsWidgets);
      expect(find.text('Marina S. · Qui, 24 set · 14:30'), findsOneWidget);
    });

    testWidgets('horário ocupado não pode ser agendado duas vezes',
        (tester) async {
      usarTela(tester, _desktop);
      final store =
          await abrirApp(tester, rota: Rotas.perfilPsicologo(idPsicologoDemo));
      await tocar(tester, porRotulo(Fmt.dataLonga(_quinta)));
      // 10:00 e 16:30 já estão ocupados no wireframe 03.
      expect(porRotulo('10:00, ocupado'), findsOneWidget);
      await tocar(tester, porRotulo('10:00, ocupado'));
      final antes = store.consultas.length;
      final agendar =
          tester.widget<ButtonStyleButton>(botao('Agendar consulta'));
      // Nada selecionado ainda: o botão continua com o horário anterior ou
      // desabilitado, mas nunca agenda o ocupado.
      if (agendar.onPressed != null) {
        await tocar(tester, botao('Agendar consulta'));
        await tocar(tester, botao('Confirmar agendamento'));
      }
      expect(
        store.consultas.where((c) =>
            c.psicologoId == idPsicologoDemo &&
            c.inicio == DateTime(2026, 9, 24, 10) &&
            !c.cancelada),
        hasLength(1),
      );
      expect(store.consultas.length, lessThanOrEqualTo(antes + 1));
    });

    testWidgets('cancela e o horário volta a ficar livre', (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.consultas);
      final proxima =
          store.minhasConsultas.singleWhere((c) => c.proxima(store.agora));
      await tocar(tester, botao('Cancelar'));
      expect(find.text('Cancelar consulta?'), findsOneWidget);
      await tocar(tester, botao('Cancelar consulta'));

      expect(proxima.cancelada, isTrue);
      expect(find.text('Canceladas'), findsOneWidget);
      expect(find.text('Você não tem consultas marcadas.'), findsOneWidget);
      expect(store.notificacoes(Papel.psicologo).first.titulo,
          'Consulta cancelada');

      await ir(tester, Rotas.perfilPsicologo(idPsicologoDemo));
      await tocar(tester, find.byTooltip('Próxima semana'));
      await tocar(tester, porRotulo(Fmt.dataLonga(DateTime(2026, 10, 2))));
      expect(porRotulo('${Fmt.hora(proxima.inicio)}, livre'), findsNothing,
          reason: '14:30 não é horário da grade de sexta (14:00, 15:00...)');
      expect(porRotulo('14:00, livre'), findsOneWidget);
      expect(porRotulo('15:00, livre'), findsOneWidget);
    });

    testWidgets('remarca: a original é cancelada e a nova aparece',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.consultas);
      final original =
          store.minhasConsultas.singleWhere((c) => c.proxima(store.agora));
      await tocar(tester, botao('Remarcar'));
      expect(find.text('Remarcar consulta'), findsOneWidget);
      await _escolherHorario(tester, _quinta, '15:30');
      await tocar(tester, botao('Confirmar remarcação'));

      expect(original.cancelada, isTrue);
      final nova =
          store.minhasConsultas.singleWhere((c) => c.proxima(store.agora));
      expect(nova.inicio, DateTime(2026, 9, 24, 15, 30));
      expect(find.textContaining('Consulta remarcada para Qui, 24 set · 15:30'),
          findsOneWidget);
      expect(porRotulo(Fmt.dataLonga(_quinta)), findsOneWidget);
      expect(store.notificacoes(Papel.psicologo).first.titulo,
          'Consulta remarcada');
    });

    testWidgets('avalia a consulta realizada e a avaliação entra no perfil',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.consultas);
      final ana = store.psicologo(idPsicologoDemo);
      final total = ana.totalAvaliacoes;
      await tocar(tester, botao('Avaliar'));
      final publicar =
          tester.widget<ButtonStyleButton>(botao('Publicar avaliação'));
      expect(publicar.onPressed, isNull, reason: 'sem nota não publica');

      await tocar(
          tester,
          find.byWidgetPredicate((w) =>
              w is Tooltip && (w.message ?? '').startsWith('4 estrelas')));
      const texto = 'Consulta tranquila e acolhedora, recomendo.';
      await _digitar(
          tester, 'Conte como foi a sua experiência (opcional)', texto);
      await tocar(tester, botao('Publicar avaliação'));

      expect(ana.totalAvaliacoes, total + 1);
      expect(find.text('Avaliada'), findsWidgets);
      expect(botao('Avaliar'), findsNothing);

      await ir(tester, Rotas.perfilPsicologo(idPsicologoDemo));
      expect(find.text(texto), findsOneWidget);
      expect(find.textContaining('${total + 1} avaliações'), findsWidgets);
    });

    testWidgets('filtros da busca batem com o número de resultados',
        (tester) async {
      usarTela(tester, _desktop);
      final store =
          await abrirApp(tester, rota: Rotas.busca(texto: 'Ansiedade'));
      String titulo(FiltrosBusca f) =>
          '${Fmt.plural(f.aplicar(store).length, 'psicólogo', 'psicólogos')} '
          'para "Ansiedade"';
      final f = FiltrosBusca()..texto = 'Ansiedade';
      expect(find.text(titulo(f)), findsOneWidget);

      await tocar(tester, find.widgetWithText(LinhaCheck, 'Presencial'));
      f.modalidades.add(Modalidade.presencial);
      expect(find.text(titulo(f)), findsOneWidget);

      await tocar(tester, porRotulo('4 estrelas ou mais'));
      f.notaMinima = 4;
      expect(find.text(titulo(f)), findsOneWidget);

      await tocar(tester, find.text('Limpar'));
      f
        ..modalidades.clear()
        ..notaMinima = null;
      expect(find.text(titulo(f)), findsOneWidget);
    });

    testWidgets('agenda também pelo celular', (tester) async {
      usarTela(tester, _celular);
      final store =
          await abrirApp(tester, rota: Rotas.perfilPsicologo(idPsicologoDemo));
      await _escolherHorario(tester, _quinta, '17:30');
      expect(find.text('Qui, 24 set · 17:30 · Online'), findsOneWidget);
      await tocar(tester, botao('Agendar consulta'));
      await tocar(tester, botao('Confirmar agendamento'));
      await tocar(tester, botao('Ver minhas consultas'));
      expect(
        store.minhasConsultas
            .where((c) => c.inicio == DateTime(2026, 9, 24, 17, 30)),
        hasLength(1),
      );
      expect(porRotulo(Fmt.dataLonga(_quinta)), findsOneWidget);
    });
  });

  group('Psicóloga', () {
    testWidgets('abre sábado na disponibilidade e o paciente vê os horários',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.disponibilidade);
      final sabado = DateTime(2026, 9, 26);
      await tocar(tester, porRotulo('Atender aos sábados'));
      await tocar(tester, botao('Salvar alterações'));
      expect(store.psicologoAtual.disponibilidade.ativos, contains(6));

      await ir(tester, Rotas.perfilPsicologo(idPsicologoDemo));
      await tocar(tester, porRotulo(Fmt.dataLonga(sabado)));
      expect(porRotulo('08:00, livre'), findsOneWidget);
      expect(porRotulo('11:00, livre'), findsOneWidget);
    });

    testWidgets('escreve uma anotação na ficha', (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.ficha(idPacienteDemo));
      final paciente = store.pacienteOuNulo(idPacienteDemo)!;
      final antes = paciente.anotacoes.length;
      await tocar(tester, find.text('+ Nova anotação'));
      const texto =
          'Trabalhamos respiração diafragmática e combinamos registro diário.';
      await _digitar(
          tester,
          'O que foi trabalhado na sessão, combinados e próximos passos',
          texto);
      await tocar(tester, botao('Salvar anotação'));

      expect(paciente.anotacoes, hasLength(antes + 1));
      expect(find.text(texto), findsOneWidget);
      expect(paciente.anotacoes.first.sessao,
          lessThanOrEqualTo(store.sessoesDoPaciente(idPacienteDemo)),
          reason: 'anotação de uma sessão que ainda não aconteceu');
    });

    testWidgets('marca um lançamento como pago e os totais acompanham',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.financeiro);
      final antes = store.resumo(2026, 9);
      expect(find.text(Fmt.moedaCurta(antes.recebido)), findsWidgets);
      expect(find.text(Fmt.moedaCurta(antes.aReceber)), findsWidgets);

      final pendente =
          store.lancamentosDoMes(2026, 9).firstWhere((l) => !l.pago);
      await tocar(tester, botao('Marcar como pago'));
      await tocar(tester, botao('Confirmar pagamento'));

      expect(pendente.pago, isTrue);
      expect(pendente.forma, isNotNull);
      final depois = store.resumo(2026, 9);
      expect(depois.recebido, antes.recebido + pendente.valor);
      expect(depois.aReceber, antes.aReceber - pendente.valor);
      expect(find.text(Fmt.moedaCurta(depois.recebido)), findsWidgets);
      expect(find.text(Fmt.moedaCurta(depois.aReceber)), findsWidgets);

      // O painel da clínica soma o mesmo valor para a Ana.
      final (_, recebido, aReceber) =
          store.totaisDoMembro(store.membroDoPsicologo(idPsicologoDemo)!, 9);
      expect(recebido, depois.recebido);
      expect(aReceber, depois.aReceber);
    });

    testWidgets('compra destaque avulso e muda de plano', (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.destaque);
      final fimAntes = store.destaquePsicologo.fim!;
      // 72 horas vem marcado, como no wireframe 15.
      final opcao = opcoesDestaque[1];
      await tocar(
          tester, botao('Comprar destaque · ${Fmt.moeda(opcao.preco)}'));
      await tocar(tester, botao('Pagar ${Fmt.moeda(opcao.preco)}'));
      final fim = store.destaquePsicologo.fim!;
      expect(fim.isBefore(fimAntes), isFalse);
      expect(
          fim.isBefore(store.agora.add(Duration(hours: opcao.horas))), isFalse);
      expect(store.destaquePsicologo.ativo(store.agora), isTrue);
      expect(store.psicologoAtual.destaque, isTrue);

      await tocar(tester, botao('Mudar para Destaque+'));
      await tocar(tester, botao('Mudar de plano'));
      expect(store.destaquePsicologo.planoId, 'destaque-plus');
      expect(botao('Mudar para Destaque+'), findsNothing);
    });

    testWidgets('publica a página e o novo nome aparece em todo lugar',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.minhaPagina);
      final nome = find.widgetWithText(TextField, 'Ana Ribeiro');
      expect(nome, findsOneWidget);
      await tester.enterText(nome, 'Ana Paula Ribeiro');
      await tester.pumpAndSettle();
      await tocar(tester, botao('Publicar alterações'));
      expect(store.psicologoAtual.nome, 'Ana Paula Ribeiro');

      await ir(tester, Rotas.buscar);
      expect(find.text('Ana Paula Ribeiro'), findsWidgets);
      await ir(tester, Rotas.paginaClinica(idClinicaDemo));
      expect(find.text('Ana Paula Ribeiro'), findsWidgets);
      await ir(tester, Rotas.equipe);
      expect(find.text('Ana Paula Ribeiro'), findsWidgets);
      expect(find.text('Ana Ribeiro'), findsNothing);
    });

    testWidgets('troca a fonte dos títulos e o perfil publicado acompanha',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.minhaPagina);
      final nome = store.psicologoAtual.nome;
      final perfil = Rotas.perfilPsicologo(store.psicologoAtual.id);
      Finder naFonte(String familia) => find.byWidgetPredicate(
          (w) => w is Text && w.data == nome && w.style?.fontFamily == familia);

      // A prévia muda na hora; o perfil só depois de publicar.
      await tocar(tester, find.text('Lora'));
      expect(naFonte('Lora'), findsWidgets);
      expect(store.psicologoAtual.temaFonte, 0);
      await tocar(tester, botao('Publicar alterações'));
      expect(store.psicologoAtual.temaFonte, 1);
      await ir(tester, perfil);
      expect(naFonte('Lora'), findsOneWidget);

      await ir(tester, Rotas.minhaPagina);
      await tocar(tester, find.text('DM Serif'));
      await tocar(tester, botao('Publicar alterações'));
      await ir(tester, perfil);
      expect(naFonte('DMSerifDisplay'), findsOneWidget);
      expect(naFonte('Lora'), findsNothing);
    });
  });

  group('Clínica', () {
    testWidgets('cadastra psicólogo, recusa CRP repetido e fica aguardando',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.equipe);
      final antes = store.equipe.length;

      Future<void> preencher(String nome, String email, String crp) async {
        await tocar(tester, botao('Cadastrar psicólogo'));
        await _digitar(tester, 'Nome do psicólogo', nome);
        await _digitar(tester, 'nome@email.com', email);
        await _digitar(tester, '00/00000', crp);
        await tocar(tester, botao('Cadastrar e gerar acesso'));
      }

      await preencher('Paula Nogueira', 'paula.nogueira@email.com', '04/55555');
      expect(store.equipe, hasLength(antes + 1));
      expect(store.equipe.last.acesso, Acesso.aguardando);
      expect(find.text('Paula Nogueira'), findsWidgets);

      await preencher('Outra Pessoa', 'outra@email.com', '04/12345');
      expect(find.text('Esse CRP já está na equipe.'), findsOneWidget);
      expect(store.equipe, hasLength(antes + 1));
    });

    testWidgets('tirar alguém da página muda a contagem no card da clínica',
        (tester) async {
      usarTela(tester, _desktop);
      final store = await abrirApp(tester, rota: Rotas.paginaDaClinica);
      final n = store.psicologosDaClinica(idClinicaDemo).length;
      final bruno = store.psicologo('bruno');
      await tocar(
        tester,
        find.descendant(
          of: find.widgetWithText(LinhaSwitch, bruno.nome),
          matching: find.byType(Switch),
        ),
      );
      expect(store.psicologosDaClinica(idClinicaDemo), hasLength(n - 1));

      await ir(tester, Rotas.clinicas);
      expect(find.textContaining(Fmt.plural(n - 1, 'psicólogo', 'psicólogos')),
          findsWidgets);
      await ir(tester, Rotas.paginaClinica(idClinicaDemo));
      expect(find.text(bruno.nome), findsNothing);
    });
  });
}
