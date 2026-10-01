// Invariantes dos dados de exemplo: números que aparecem em mais de uma tela
// precisam bater entre si, e nenhuma regra de agenda pode estar violada logo
// ao abrir a demonstração.

import 'package:flutter_test/flutter_test.dart';
import 'package:psihub_app/core/core.dart';
import 'package:psihub_app/features/painel_clinica/agenda_equipe_screen.dart'
    show periodosIndisponiveis;
import 'package:psihub_app/features/painel_psicologo/agenda_screen.dart'
    show descontarConsultas, faixaDeHoras, intervalosEntre;
import 'package:psihub_app/features/perfil_busca/buscar_screen.dart';

int _minutos(DateTime d) => d.hour * 60 + d.minute;

bool _sobrepoe(Consulta a, Consulta b) =>
    a.inicio.isBefore(b.fim) && b.inicio.isBefore(a.fim);

void main() {
  late AppStore store;
  setUp(() => store = AppStore());

  test('ids e endereços públicos são únicos', () {
    void unicos(Iterable<String> valores, String o) {
      final lista = valores.toList();
      expect(lista.toSet().length, lista.length, reason: '$o repetido');
    }

    unicos(store.psicologos.map((p) => p.id), 'id de psicólogo');
    unicos(store.psicologos.map((p) => p.slug), 'endereço de psicólogo');
    unicos(store.clinicas.map((c) => c.id), 'id de clínica');
    unicos(store.clinicas.map((c) => c.slug), 'endereço de clínica');
    unicos(store.consultas.map((c) => c.id), 'id de consulta');
    unicos(store.pacientes.map((p) => p.id), 'id de paciente');
    unicos(store.lancamentos.map((l) => l.id), 'id de lançamento');
    unicos(store.equipe.map((m) => m.id), 'id de membro');
  });

  test('nota de cada psicólogo bate com a distribuição e com as avaliações',
      () {
    for (final p in store.psicologos) {
      expect(p.distribuicao, hasLength(5), reason: p.nome);
      expect(p.distribuicao.every((n) => n >= 0), isTrue, reason: p.nome);
      expect(p.totalAvaliacoes, greaterThan(0), reason: p.nome);
      expect(p.nota, inInclusiveRange(1, 5), reason: p.nome);
      final lista = store.avaliacoesDe(p.id);
      expect(lista.length, lessThanOrEqualTo(p.totalAvaliacoes),
          reason: '${p.nome}: mais avaliações listadas que o total');
      for (var estrelas = 1; estrelas <= 5; estrelas++) {
        final listadas = lista.where((a) => a.nota == estrelas).length;
        expect(listadas, lessThanOrEqualTo(p.distribuicao[5 - estrelas]),
            reason: '${p.nome}: $listadas avaliações de $estrelas estrelas '
                'listadas, mas a distribuição tem ${p.distribuicao[5 - estrelas]}');
      }
      for (final a in lista) {
        expect(a.nota, inInclusiveRange(1, 5), reason: p.nome);
        expect(a.data.isAfter(store.agora), isFalse,
            reason: '${p.nome}: avaliação no futuro');
        expect(a.texto.trim(), isNotEmpty, reason: p.nome);
      }
    }
  });

  test(
      'próximo horário livre está no futuro, na disponibilidade e sem conflito',
      () {
    for (final p in store.psicologos) {
      final h = store.proximoHorario(p);
      expect(h, isNotNull, reason: '${p.nome} sem horário em três semanas');
      expect(h!.isAfter(store.agora), isTrue, reason: p.nome);
      final disp = p.disponibilidade;
      expect(disp.inicios(h.weekday), contains(_minutos(h)), reason: p.nome);
      expect(disp.bloqueioEm(h), isNull, reason: p.nome);
      final fim = h.add(Duration(minutes: disp.duracao));
      final conflito = store.consultas.where((c) =>
          c.psicologoId == p.id &&
          !c.cancelada &&
          c.inicio.isBefore(fim) &&
          c.fim.isAfter(h));
      expect(conflito, isEmpty, reason: '${p.nome}: próximo horário ocupado');
    }
  });

  test('ninguém tem duas consultas ao mesmo tempo', () {
    final ativas = store.consultas.where((c) => !c.cancelada).toList();
    for (var i = 0; i < ativas.length; i++) {
      for (var j = i + 1; j < ativas.length; j++) {
        final a = ativas[i], b = ativas[j];
        if (!_sobrepoe(a, b)) continue;
        expect(a.psicologoId, isNot(b.psicologoId),
            reason: 'Consultas ${a.id} e ${b.id} no mesmo horário de '
                '${a.psicologoId} (${Fmt.dataLonga(a.inicio)} ${Fmt.hora(a.inicio)})');
        expect(a.pacienteId, isNot(b.pacienteId),
            reason: 'Consultas ${a.id} e ${b.id} no mesmo horário para '
                '${a.pacienteNome}');
      }
    }
  });

  // Não exige que a consulta caia dentro das faixas atuais: o wireframe 09 tem
  // Helena às 08:00 numa quarta que o wireframe 10 abre só às 13:00, e mudar a
  // disponibilidade não cancela consultas já marcadas. O que não pode é a
  // agenda desenhar um bloco cinza por cima dela (teste seguinte).
  test('consultas futuras caem em dias de atendimento', () {
    for (final c in store.consultas) {
      if (c.cancelada || !c.inicio.isAfter(store.agora)) continue;
      final p = store.psicologo(c.psicologoId);
      final disp = p.disponibilidade;
      final quando =
          '${p.nome}, ${Fmt.dataLonga(c.inicio)} ${Fmt.hora(c.inicio)}';
      expect(disp.bloqueioEm(c.inicio), isNull,
          reason: '$quando: consulta em dia bloqueado');
      expect(disp.faixasDoDia(c.inicio.weekday), isNotEmpty,
          reason: '$quando: dia sem atendimento');
      expect(c.duracao, disp.duracao, reason: '$quando: duração diferente');
      expect(p.modalidades, contains(c.modalidade),
          reason: '$quando: modalidade que não é oferecida');
    }
  });

  test('agendas não desenham intervalo ou indisponível por baixo de consulta',
      () {
    final segunda = inicioDaSemana(store.agora);
    for (final p in store.psicologos) {
      for (var d = -14; d < 21; d++) {
        final dia = maisDias(segunda, d);
        final consultas = store.consultasNoDia(p.id, dia);
        final faixas = p.disponibilidade.faixasDoDia(dia.weekday);
        final (hIni, hFim) = faixaDeHoras([faixas], consultas);
        final cinzas = [
          ...descontarConsultas(intervalosEntre(faixas), consultas),
          ...descontarConsultas(
              periodosIndisponiveis(faixas, hIni, hFim), consultas),
        ];
        for (final c in consultas) {
          final a = _minutos(c.inicio), b = _minutos(c.fim);
          for (final (x, y) in cinzas) {
            expect(b <= x || a >= y, isTrue,
                reason: '${p.nome}, ${Fmt.dataLonga(dia)}: bloco cinza '
                    '${Fmt.minutos(x)}-${Fmt.minutos(y)} sob a consulta das '
                    '${Fmt.hora(c.inicio)}');
          }
        }
      }
    }
  });

  test('consultas, lançamentos e fichas apontam para quem existe', () {
    for (final c in store.consultas) {
      expect(store.psicologoOuNulo(c.psicologoId), isNotNull, reason: c.id);
      if (c.psicologoId != idPsicologoDemo) continue;
      final paciente = store.pacienteOuNulo(c.pacienteId);
      expect(paciente, isNotNull,
          reason: 'Consulta ${c.id} de paciente fora da lista da psicóloga');
      expect(c.pacienteNome, paciente!.nome, reason: c.id);
    }
    for (final l in store.lancamentos) {
      final paciente = store.pacienteOuNulo(l.pacienteId);
      expect(paciente, isNotNull, reason: 'Lançamento ${l.id}');
      expect(l.pacienteNome, paciente!.nome, reason: l.id);
      expect(l.valor, greaterThan(0), reason: l.id);
      expect(l.sessoes, greaterThan(0), reason: l.id);
      // Pendente pode ter forma combinada (wireframe 13); pago sempre tem.
      if (l.pago) {
        expect(l.forma, isNotNull, reason: 'Lançamento ${l.id} pago sem forma');
      }
      expect(l.data.isAfter(store.agora), isFalse,
          reason: 'Lançamento ${l.id} no futuro');
    }
    // A paciente da demonstração também está na lista da psicóloga.
    expect(store.pacienteOuNulo(store.pacienteId), isNotNull);
    expect(store.pacienteOuNulo(store.pacienteId)!.nome, store.pacienteNome);
  });

  test('ficha do paciente não se contradiz', () {
    for (final p in store.pacientes) {
      final sessoes = store.sessoesDoPaciente(p.id);
      for (final a in p.anotacoes) {
        expect(a.sessao, lessThanOrEqualTo(sessoes),
            reason: '${p.nome}: anotação da sessão ${a.sessao}, '
                'mas só $sessoes sessões');
        expect(a.data.isAfter(store.agora), isFalse, reason: p.nome);
      }
      for (final d in p.documentos) {
        expect(d.data.isAfter(store.agora), isFalse, reason: p.nome);
      }
      final ultima = store.ultimaConsulta(p.id);
      if (ultima != null) {
        expect(ultima.isAfter(store.agora), isFalse, reason: p.nome);
        expect(p.desde.isAfter(ultima), isFalse,
            reason: '${p.nome}: consulta antes de virar paciente');
      }
      final proxima = store.proximaConsulta(p.id);
      if (proxima != null) {
        expect(proxima.fim.isAfter(store.agora), isTrue, reason: p.nome);
      }
      expect(p.idade(store.agora), inInclusiveRange(3, 100), reason: p.nome);
      expect(store.pendenteDoPaciente(p.id), greaterThanOrEqualTo(0));
      expect(store.pagoNoAno(p.id), greaterThanOrEqualTo(0), reason: p.nome);
    }
  });

  test('resumo financeiro soma os lançamentos do mês', () {
    for (final mes in [8, 9]) {
      final lista = store.lancamentosDoMes(store.agora.year, mes);
      final r = store.resumo(store.agora.year, mes);
      final pago = lista.where((l) => l.pago);
      final pendente = lista.where((l) => !l.pago);
      expect(r.recebido, closeTo(pago.fold(0.0, (a, l) => a + l.valor), 0.001));
      expect(r.aReceber,
          closeTo(pendente.fold(0.0, (a, l) => a + l.valor), 0.001));
      expect(r.sessoesPagas, pago.fold(0, (a, l) => a + l.sessoes));
      expect(r.sessoesPendentes, pendente.fold(0, (a, l) => a + l.sessoes));
      expect(r.percentualRecebido, inInclusiveRange(0, 1));
    }
    // O painel da clínica mostra o mesmo total do financeiro da psicóloga.
    final membroAna = store.membroDoPsicologo(idPsicologoDemo)!;
    final (sessoes, recebido, aReceber) = store.totaisDoMembro(membroAna, 9);
    final r = store.resumo(store.agora.year, 9);
    expect(sessoes, r.sessoes);
    expect(recebido, r.recebido);
    expect(aReceber, r.aReceber);
  });

  test('equipe e página da clínica batem', () {
    for (final m in store.equipe) {
      if (m.psicologoId == null) {
        expect(m.acesso, Acesso.aguardando,
            reason: '${m.nome}: ativo sem perfil de psicólogo');
        continue;
      }
      final p = store.psicologo(m.psicologoId!);
      expect(p.clinicaId, idClinicaDemo,
          reason: '${m.nome} está na equipe mas atende em outra clínica');
      expect(m.nome, p.nome);
      expect(m.crp, p.crp);
      final temas = {...p.especialidades, ...p.publicos};
      for (final e in m.especialidades) {
        expect(temas, contains(e),
            reason: '${m.nome}: "$e" na equipe, mas não no perfil');
      }
    }
    for (final p
        in store.psicologos.where((p) => p.clinicaId == idClinicaDemo)) {
      expect(store.membroDoPsicologo(p.id), isNotNull,
          reason: '${p.nome} aparece na clínica mas não está na equipe');
    }
    final visiveis = store.equipe
        .where((m) =>
            m.psicologoId != null &&
            m.acesso == Acesso.ativo &&
            m.exibirNaPagina)
        .length;
    expect(store.psicologosDaClinica(idClinicaDemo).length, visiveis);
    for (final c in store.clinicas) {
      expect(store.psicologosDaClinica(c.id), isNotEmpty, reason: c.nome);
      expect(c.nota, inInclusiveRange(1, 5), reason: c.nome);
    }
  });

  test('temas do início levam ao mesmo número de resultados na busca', () {
    const temas = [
      'Ansiedade',
      'Depressão',
      'Luto',
      'Casais',
      'Crianças',
      'TDAH'
    ];
    for (final t in temas) {
      final resultados = (FiltrosBusca()..texto = t).aplicar(store);
      expect(resultados.length, store.contarPorTema(t),
          reason: '"$t": o início mostra ${store.contarPorTema(t)}, '
              'a busca encontra ${resultados.length} '
              '(${resultados.map((p) => p.nome).join(', ')})');
    }
  });

  test('destaque ativo e selo de destaque andam juntos', () {
    expect(store.psicologoAtual.destaque,
        store.destaquePsicologo.ativo(store.agora));
    expect(store.emDestaque, isNotEmpty);
    expect(planosPsicologo.map((p) => p.id),
        contains(store.destaquePsicologo.planoId));
    expect(planosClinica.map((p) => p.id),
        contains(store.destaqueClinica.planoId));
  });

  test('notificações não estão no futuro e vêm da mais nova para a mais antiga',
      () {
    for (final papel in [Papel.paciente, Papel.psicologo]) {
      final lista = store.notificacoes(papel);
      for (var i = 0; i < lista.length; i++) {
        expect(lista[i].quando.isAfter(store.agora), isFalse,
            reason: '${papel.name}: ${lista[i].titulo}');
        if (i > 0) {
          expect(lista[i].quando.isAfter(lista[i - 1].quando), isFalse,
              reason: '${papel.name}: "${lista[i].titulo}" fora de ordem');
        }
      }
    }
  });

  test('contagem semanal da equipe bate com a agenda do dia a dia', () {
    final segunda = inicioDaSemana(store.agora);
    for (final p in store.psicologos) {
      var soma = 0;
      for (var d = 0; d < 7; d++) {
        soma += store
            .consultasNoDia(p.id, maisDias(segunda, d))
            .where((c) => !c.cancelada)
            .length;
      }
      expect(store.consultasNaSemana(p.id), soma, reason: p.nome);
    }
  });
}
