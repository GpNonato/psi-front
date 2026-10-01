import 'package:flutter/foundation.dart';

import '../formatters.dart';
import 'mock_data.dart';
import 'models.dart';

/// Estado da demonstração, todo em memória. As ações imitam as regras descritas
/// na documentação (horário ocupado não pode ser agendado, remarcar cancela a
/// consulta original e cria a nova, clínica só vê valores agregados etc.).
class AppStore extends ChangeNotifier {
  AppStore({DateTime? agora}) : agora = agora ?? agoraDemonstracao {
    final d = gerarDadosIniciais();
    psicologos = d.psicologos;
    clinicas = d.clinicas;
    consultas = d.consultas;
    avaliacoes = d.avaliacoes;
    _notificacoesPsicologo = d.notificacoesPsicologo;
    _notificacoesPaciente = d.notificacoesPaciente;
    pacientes = d.pacientes;
    lancamentos = d.lancamentos;
    equipe = d.equipe;
    destaquePsicologo = d.destaquePsicologo;
    destaqueClinica = d.destaqueClinica;
    relatorios = d.relatorios;
    _financeiroEquipe = d.financeiroEquipe;
  }

  /// Relógio da demonstração (fixo na semana dos wireframes).
  final DateTime agora;

  var _seq = 1000;
  String _novoId(String prefixo) => '$prefixo${++_seq}';

  late final List<Psicologo> psicologos;
  late final List<Clinica> clinicas;
  late final List<Consulta> consultas;
  late final List<Avaliacao> avaliacoes;
  late final List<Notificacao> _notificacoesPsicologo;
  late final List<Notificacao> _notificacoesPaciente;
  late final List<Paciente> pacientes;
  late final List<Lancamento> lancamentos;
  late final List<MembroEquipe> equipe;
  late final EstadoDestaque destaquePsicologo;
  late final EstadoDestaque destaqueClinica;
  late final List<Relatorio> relatorios;
  late final Map<String, Map<int, TotaisMes>> _financeiroEquipe;
  final Set<String> favoritos = {};

  // ---------------------------------------------------------------- sessão

  Papel? papel;
  String pacienteNome = 'Marina Souza';
  String get pacienteId => idPacienteDemo;
  String get pacienteEmail => 'marina.souza@email.com';

  void entrar(Papel novo) {
    papel = novo;
    notifyListeners();
  }

  /// Usado na geração de rotas (ex.: link aberto direto no navegador), sem notificar.
  void garantirPapel(Papel novo) => papel = novo;

  void sair() {
    papel = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------- consultas gerais

  Psicologo psicologo(String id) => psicologos.firstWhere((p) => p.id == id);

  Psicologo? psicologoOuNulo(String id) {
    for (final p in psicologos) {
      if (p.id == id || p.slug == id) return p;
    }
    return null;
  }

  Psicologo get psicologoAtual => psicologo(idPsicologoDemo);

  Clinica clinica(String id) => clinicas.firstWhere((c) => c.id == id);

  Clinica? clinicaOuNula(String id) {
    for (final c in clinicas) {
      if (c.id == id || c.slug == id) return c;
    }
    return null;
  }

  Clinica get clinicaAtual => clinica(idClinicaDemo);

  Consulta consulta(String id) => consultas.firstWhere((c) => c.id == id);

  List<Psicologo> get emDestaque =>
      psicologos.where((p) => p.destaque).toList();

  /// Psicólogos exibidos na página pública da clínica.
  List<Psicologo> psicologosDaClinica(String clinicaId) {
    final lista = psicologos.where((p) => p.clinicaId == clinicaId).toList();
    if (clinicaId != idClinicaDemo) return lista;
    // Na clínica da demonstração vale a ordem da equipe (wireframes 07 e 16).
    int ordem(Psicologo p) {
      final i = equipe.indexWhere((m) => m.psicologoId == p.id);
      return i < 0 ? equipe.length : i;
    }

    return lista.where((p) {
      final m = membroDoPsicologo(p.id);
      return m == null || (m.exibirNaPagina && m.acesso == Acesso.ativo);
    }).toList()
      ..sort((a, b) => ordem(a).compareTo(ordem(b)));
  }

  List<Avaliacao> avaliacoesDe(String psicologoId) =>
      avaliacoes.where((a) => a.psicologoId == psicologoId).toList();

  /// Quantos psicólogos têm a especialidade ou atendem o público informado.
  int contarPorTema(String tema) {
    final t = normalizar(tema);
    return psicologos
        .where((p) =>
            p.especialidades.any((e) => normalizar(e) == t) ||
            p.publicos.any((e) => normalizar(e) == t))
        .length;
  }

  // ---------------------------------------------------------------- horários

  /// Horários de um dia gerados pela disponibilidade, com os já ocupados
  /// marcados. Horários que já passaram não aparecem.
  List<Horario> horariosDoDia(
    Psicologo p,
    DateTime dia, {
    Disponibilidade? disponibilidade,
    String? ignorarConsultaId,
  }) {
    final disp = disponibilidade ?? p.disponibilidade;
    if (disp.bloqueioEm(dia) != null) return const [];
    final base = soDia(dia);
    final ocupadas = consultas
        .where((c) =>
            c.psicologoId == p.id &&
            !c.cancelada &&
            c.id != ignorarConsultaId &&
            mesmoDia(c.inicio, dia))
        .toList();
    final r = <Horario>[];
    for (final minuto in disp.inicios(dia.weekday)) {
      final inicio = base.add(Duration(minutes: minuto));
      if (!inicio.isAfter(agora)) continue;
      final fim = inicio.add(Duration(minutes: disp.duracao));
      final ocupado =
          ocupadas.any((c) => c.inicio.isBefore(fim) && c.fim.isAfter(inicio));
      r.add(Horario(inicio, ocupado: ocupado));
    }
    return r;
  }

  bool temHorarioNoDia(Psicologo p, DateTime dia) =>
      horariosDoDia(p, dia).any((h) => !h.ocupado);

  /// Primeiro horário livre nas próximas três semanas.
  DateTime? proximoHorario(Psicologo p) {
    for (var i = 0; i < 21; i++) {
      final dia = maisDias(soDia(agora), i);
      for (final h in horariosDoDia(p, dia)) {
        if (!h.ocupado) return h.inicio;
      }
    }
    return null;
  }

  /// Tem horário livre até o domingo desta semana.
  bool temHorarioNaSemana(Psicologo p) {
    final domingo = maisDias(inicioDaSemana(agora), 6);
    var dia = soDia(agora);
    while (!dia.isAfter(domingo)) {
      if (temHorarioNoDia(p, dia)) return true;
      dia = maisDias(dia, 1);
    }
    return false;
  }

  bool _horarioLivre(Psicologo p, DateTime inicio, {String? ignorar}) =>
      horariosDoDia(p, inicio, ignorarConsultaId: ignorar)
          .any((h) => h.inicio == inicio && !h.ocupado);

  bool _pacienteOcupado(String pacienteId, DateTime inicio, int duracao,
      {String? ignorar}) {
    final fim = inicio.add(Duration(minutes: duracao));
    return consultas.any((c) =>
        c.pacienteId == pacienteId &&
        c.id != ignorar &&
        !c.cancelada &&
        c.inicio.isBefore(fim) &&
        c.fim.isAfter(inicio));
  }

  // ---------------------------------------------------------------- paciente

  List<Consulta> get minhasConsultas =>
      consultas.where((c) => c.pacienteId == pacienteId).toList();

  List<Notificacao> notificacoes(Papel p) =>
      p == Papel.paciente ? _notificacoesPaciente : _notificacoesPsicologo;

  int naoLidas(Papel p) => notificacoes(p).where((n) => !n.lida).length;

  void marcarLidas(Papel p) {
    for (final n in notificacoes(p)) {
      n.lida = true;
    }
    if (p == Papel.psicologo) {
      for (final c in consultas) {
        c.nova = false;
      }
    }
    notifyListeners();
  }

  void marcarLida(Notificacao n) {
    n.lida = true;
    notifyListeners();
  }

  /// Agenda uma consulta para o paciente logado (RF009). Lança
  /// [ErroAgendamento] se o horário não estiver mais livre.
  Consulta agendar({
    required String psicologoId,
    required DateTime inicio,
    required Modalidade modalidade,
    String? mensagem,
  }) {
    final p = psicologo(psicologoId);
    if (!_horarioLivre(p, inicio)) {
      throw const ErroAgendamento(
          'Esse horário acabou de ser ocupado. Escolha outro horário.');
    }
    if (_pacienteOcupado(pacienteId, inicio, p.disponibilidade.duracao)) {
      throw const ErroAgendamento('Você já tem uma consulta nesse horário.');
    }
    // Na agenda da psicóloga vale o nome que está na ficha dela.
    final nome = p.id == idPsicologoDemo
        ? (pacienteOuNulo(pacienteId)?.nome ?? pacienteNome)
        : pacienteNome;
    final c = Consulta(
      id: _novoId('c'),
      psicologoId: p.id,
      pacienteId: pacienteId,
      pacienteNome: nome,
      inicio: inicio,
      duracao: p.disponibilidade.duracao,
      modalidade: modalidade,
      nova: true,
      mensagem: (mensagem ?? '').trim().isEmpty ? null : mensagem!.trim(),
    );
    consultas.add(c);
    if (p.id == idPsicologoDemo) {
      _notificacoesPsicologo.insert(
        0,
        Notificacao(
          tipo: TipoNotificacao.nova,
          titulo: 'Nova consulta marcada',
          detalhe:
              '${nomeAbreviado(nome)} · ${Fmt.diaCurto(inicio)} · ${Fmt.hora(inicio)}',
          quando: agora,
        ),
      );
      if (destaquePsicologo.ativo(agora)) destaquePsicologo.agendamentos++;
    }
    _notificacoesPaciente.insert(
      0,
      Notificacao(
        tipo: TipoNotificacao.nova,
        titulo: 'Consulta confirmada',
        detalhe: '${p.nome} · ${Fmt.diaCurto(inicio)} · ${Fmt.hora(inicio)}',
        quando: agora,
      ),
    );
    notifyListeners();
    return c;
  }

  /// Cancela mudando o status (o registro fica no histórico e o horário é liberado).
  void cancelarConsulta(String consultaId, {required bool peloPaciente}) {
    final c = consulta(consultaId);
    c.status = StatusConsulta.cancelada;
    c.nova = false;
    final p = psicologo(c.psicologoId);
    final detalhe = '${Fmt.diaCurto(c.inicio)} · ${Fmt.hora(c.inicio)}';
    if (peloPaciente && c.psicologoId == idPsicologoDemo) {
      _notificacoesPsicologo.insert(
        0,
        Notificacao(
          tipo: TipoNotificacao.cancelada,
          titulo: 'Consulta cancelada',
          detalhe: '${nomeAbreviado(c.pacienteNome)} · $detalhe',
          quando: agora,
        ),
      );
    }
    if (!peloPaciente && c.pacienteId == pacienteId) {
      _notificacoesPaciente.insert(
        0,
        Notificacao(
          tipo: TipoNotificacao.cancelada,
          titulo: 'Consulta cancelada pel${p.artigo} ${p.profissional}',
          detalhe: '${p.nome} · $detalhe',
          quando: agora,
        ),
      );
    }
    notifyListeners();
  }

  /// Remarca: cancela a consulta original e cria a nova de uma vez só.
  Consulta remarcar(
      String consultaId, DateTime novoInicio, Modalidade modalidade) {
    final antiga = consulta(consultaId);
    final p = psicologo(antiga.psicologoId);
    if (!_horarioLivre(p, novoInicio, ignorar: antiga.id)) {
      throw const ErroAgendamento(
          'Esse horário acabou de ser ocupado. Escolha outro horário.');
    }
    if (_pacienteOcupado(antiga.pacienteId, novoInicio, antiga.duracao,
        ignorar: antiga.id)) {
      throw const ErroAgendamento('Você já tem uma consulta nesse horário.');
    }
    antiga.status = StatusConsulta.cancelada;
    antiga.nova = false;
    final nova = Consulta(
      id: _novoId('c'),
      psicologoId: antiga.psicologoId,
      pacienteId: antiga.pacienteId,
      pacienteNome: antiga.pacienteNome,
      inicio: novoInicio,
      duracao: antiga.duracao,
      modalidade: modalidade,
      nova: true,
      mensagem: antiga.mensagem,
    );
    consultas.add(nova);
    if (p.id == idPsicologoDemo) {
      _notificacoesPsicologo.insert(
        0,
        Notificacao(
          tipo: TipoNotificacao.remarcada,
          titulo: 'Consulta remarcada',
          detalhe:
              '${nomeAbreviado(antiga.pacienteNome)} · ${Fmt.diaCurto(novoInicio)} · ${Fmt.hora(novoInicio)}',
          quando: agora,
        ),
      );
    }
    notifyListeners();
    return nova;
  }

  /// Avaliação de uma consulta realizada (RF018).
  void avaliar(
    String consultaId, {
    required int nota,
    required String texto,
    required bool comNome,
  }) {
    final c = consulta(consultaId);
    if (!c.realizada(agora) || c.avaliacao != null) return;
    c.avaliacao = nota;
    final p = psicologo(c.psicologoId);
    p.distribuicao[5 - nota] += 1;
    avaliacoes.insert(
      0,
      Avaliacao(
        psicologoId: p.id,
        autor: comNome ? nomeAbreviado(pacienteNome) : 'Paciente do PsiHub',
        nota: nota,
        texto: texto.trim(),
        data: agora,
      ),
    );
    for (final n in _notificacoesPaciente) {
      if (n.tipo == TipoNotificacao.info) n.lida = true;
    }
    notifyListeners();
  }

  void alternarFavorito(String psicologoId) {
    if (!favoritos.remove(psicologoId)) favoritos.add(psicologoId);
    notifyListeners();
  }

  // ---------------------------------------------------------------- psicólogo: agenda

  /// O psicólogo abriu a consulta: ela deixa de aparecer como "Nova".
  void marcarVista(Consulta c) {
    if (!c.nova) return;
    c.nova = false;
    notifyListeners();
  }

  List<Consulta> consultasNoDia(String psicologoId, DateTime dia) => consultas
      .where((c) => c.psicologoId == psicologoId && mesmoDia(c.inicio, dia))
      .toList()
    ..sort((a, b) => a.inicio.compareTo(b.inicio));

  int consultasNaSemana(String psicologoId, [DateTime? referencia]) {
    final segunda = inicioDaSemana(referencia ?? agora);
    final proxima = maisDias(segunda, 7);
    return consultas
        .where((c) =>
            c.psicologoId == psicologoId &&
            !c.cancelada &&
            !c.inicio.isBefore(segunda) &&
            c.inicio.isBefore(proxima))
        .length;
  }

  void salvarDisponibilidade(Disponibilidade d) {
    psicologoAtual.disponibilidade = d.copia();
    notifyListeners();
  }

  // ---------------------------------------------------------------- psicólogo: pacientes

  Paciente? pacienteOuNulo(String id) {
    for (final p in pacientes) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Consulta> consultasDoPaciente(String pacienteId) => consultas
      .where(
          (c) => c.pacienteId == pacienteId && c.psicologoId == idPsicologoDemo)
      .toList()
    ..sort((a, b) => b.inicio.compareTo(a.inicio));

  DateTime? ultimaConsulta(String pacienteId) {
    DateTime? r;
    for (final c in consultasDoPaciente(pacienteId)) {
      if (c.realizada(agora) && (r == null || c.inicio.isAfter(r))) {
        r = c.inicio;
      }
    }
    return r;
  }

  Consulta? proximaConsulta(String pacienteId) {
    Consulta? r;
    for (final c in consultasDoPaciente(pacienteId)) {
      if (c.proxima(agora) && (r == null || c.inicio.isBefore(r.inicio))) r = c;
    }
    return r;
  }

  int sessoesDoPaciente(String pacienteId) {
    final p = pacienteOuNulo(pacienteId);
    final realizadas =
        consultasDoPaciente(pacienteId).where((c) => c.realizada(agora)).length;
    return (p?.sessoesAnteriores ?? 0) + realizadas;
  }

  List<Lancamento> lancamentosDoPaciente(String pacienteId) =>
      lancamentos.where((l) => l.pacienteId == pacienteId).toList()
        ..sort((a, b) => b.data.compareTo(a.data));

  double pendenteDoPaciente(String pacienteId) => lancamentos
      .where((l) => l.pacienteId == pacienteId && !l.pago)
      .fold<double>(0, (a, l) => a + l.valor);

  double pagoNoAno(String pacienteId) {
    final p = pacienteOuNulo(pacienteId);
    final pagos = lancamentos
        .where((l) =>
            l.pacienteId == pacienteId && l.pago && l.data.year == agora.year)
        .fold<double>(0, (a, l) => a + l.valor);
    return (p?.pagoAntes ?? 0) + pagos;
  }

  Paciente adicionarPaciente({
    required String nome,
    required String telefone,
    required String email,
  }) {
    final p = Paciente(
      id: _novoId('p'),
      nome: nome.trim(),
      telefone: telefone.trim(),
      email: email.trim(),
      nascimento: DateTime(1990, 1, 1),
      cpfFinal: '00',
      endereco: 'Não informado',
      contatoEmergencia: 'Não informado',
      desde: agora,
    );
    pacientes.insert(0, p);
    notifyListeners();
    return p;
  }

  void atualizarPaciente(
    Paciente p, {
    required String nome,
    required String telefone,
    required String email,
    required DateTime nascimento,
    required String endereco,
    required String contatoEmergencia,
  }) {
    p
      ..nome = nome.trim()
      ..telefone = telefone.trim()
      ..email = email.trim()
      ..nascimento = nascimento
      ..endereco = endereco.trim()
      ..contatoEmergencia = contatoEmergencia.trim();
    for (final c in consultas) {
      if (c.pacienteId == p.id) c.pacienteNome = p.nome;
    }
    for (final l in lancamentos.where((l) => l.pacienteId == p.id).toList()) {
      final i = lancamentos.indexOf(l);
      lancamentos[i] = Lancamento(
        id: l.id,
        data: l.data,
        pacienteId: l.pacienteId,
        pacienteNome: p.nome,
        descricao: l.descricao,
        valor: l.valor,
        status: l.status,
        forma: l.forma,
        sessoes: l.sessoes,
      );
    }
    notifyListeners();
  }

  void adicionarDocumento(Paciente p, String nome) {
    var arquivo = nome.trim();
    if (!arquivo.toLowerCase().endsWith('.pdf')) arquivo = '$arquivo.pdf';
    p.documentos.insert(
      0,
      Documento(nome: arquivo, data: agora, tamanhoKb: 60 + arquivo.length * 7),
    );
    notifyListeners();
  }

  void removerDocumento(Paciente p, Documento d) {
    p.documentos.remove(d);
    notifyListeners();
  }

  void adicionarAnotacao(Paciente p, String texto) {
    final ultima = p.anotacoes.isEmpty
        ? p.sessoesAnteriores
        : p.anotacoes.map((a) => a.sessao).reduce((a, b) => a > b ? a : b);
    // A anotação é da sessão seguinte à última anotada, mas nunca de uma
    // sessão que ainda não aconteceu (aí fica na última realizada).
    final realizadas = sessoesDoPaciente(p.id);
    var sessao = ultima + 1;
    if (sessao > realizadas) sessao = realizadas;
    if (sessao < 1) sessao = 1;
    p.anotacoes.insert(
      0,
      Anotacao(data: agora, sessao: sessao, texto: texto.trim()),
    );
    notifyListeners();
  }

  void editarAnotacao(Anotacao a, String texto) {
    a.texto = texto.trim();
    notifyListeners();
  }

  /// O psicólogo marca uma sessão para um paciente da lista.
  Consulta agendarParaPaciente(
      Paciente paciente, DateTime inicio, Modalidade modalidade) {
    final p = psicologoAtual;
    if (!_horarioLivre(p, inicio)) {
      throw const ErroAgendamento('Esse horário já está ocupado.');
    }
    if (_pacienteOcupado(paciente.id, inicio, p.disponibilidade.duracao)) {
      throw const ErroAgendamento(
          'O paciente já tem uma consulta nesse horário.');
    }
    final c = Consulta(
      id: _novoId('c'),
      psicologoId: p.id,
      pacienteId: paciente.id,
      pacienteNome: paciente.nome,
      inicio: inicio,
      duracao: p.disponibilidade.duracao,
      modalidade: modalidade,
    );
    consultas.add(c);
    if (paciente.id == pacienteId) {
      _notificacoesPaciente.insert(
        0,
        Notificacao(
          tipo: TipoNotificacao.nova,
          titulo: 'Nova consulta marcada pel${p.artigo} ${p.profissional}',
          detalhe: '${p.nome} · ${Fmt.diaCurto(inicio)} · ${Fmt.hora(inicio)}',
          quando: agora,
        ),
      );
    }
    notifyListeners();
    return c;
  }

  // ---------------------------------------------------------------- psicólogo: financeiro

  List<Lancamento> lancamentosDoMes(int ano, int mes) => lancamentos
      .where((l) => l.data.year == ano && l.data.month == mes)
      .toList()
    ..sort((a, b) => b.data.compareTo(a.data));

  ResumoFinanceiro resumo(int ano, int mes) {
    var recebido = 0.0, aReceber = 0.0;
    var pagas = 0, pendentes = 0;
    for (final l in lancamentosDoMes(ano, mes)) {
      if (l.pago) {
        recebido += l.valor;
        pagas += l.sessoes;
      } else {
        aReceber += l.valor;
        pendentes += l.sessoes;
      }
    }
    return ResumoFinanceiro(
      recebido: recebido,
      aReceber: aReceber,
      sessoesPagas: pagas,
      sessoesPendentes: pendentes,
    );
  }

  void marcarComoPago(Lancamento l, String forma) {
    l
      ..status = StatusPagamento.pago
      ..forma = forma;
    notifyListeners();
  }

  void registrarLancamento({
    required String pacienteId,
    required DateTime data,
    required String descricao,
    required double valor,
    required bool pago,
    String? forma,
    int sessoes = 1,
  }) {
    final p = pacienteOuNulo(pacienteId);
    lancamentos.add(
      Lancamento(
        id: _novoId('l'),
        data: data,
        pacienteId: pacienteId,
        pacienteNome: p?.nome ?? 'Paciente',
        descricao: descricao,
        valor: valor,
        status: pago ? StatusPagamento.pago : StatusPagamento.pendente,
        forma: forma,
        sessoes: sessoes,
      ),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------- psicólogo: página

  void publicarPagina({
    required String nome,
    required String crp,
    required int anos,
    required String cidade,
    required List<String> especialidades,
    required Set<String> publicos,
    required String abordagem,
    required Set<Modalidade> modalidades,
    required String sobre,
    required int temaCor,
    required int temaFonte,
    required String slug,
  }) {
    final p = psicologoAtual;
    p
      ..nome = nome.trim()
      ..crp = crp.trim()
      ..anosExperiencia = anos
      ..cidade = cidade.trim()
      ..especialidades = [...especialidades]
      ..publicos = {...publicos}
      ..abordagem = abordagem
      ..abordagemCompleta =
          abordagem == 'TCC' ? 'Terapia cognitivo-comportamental' : abordagem
      ..sobre = sobre.trim()
      ..temaCor = temaCor
      ..temaFonte = temaFonte
      ..slug = slug;
    p.disponibilidade.modalidades = {...modalidades};
    // A equipe da clínica mostra o mesmo nome, CRP e temas do perfil.
    final m = membroDoPsicologo(p.id);
    if (m != null) {
      final temas = {...p.especialidades, ...p.publicos};
      final mantidas = m.especialidades.where(temas.contains).toList();
      m
        ..nome = p.nome
        ..crp = p.crp
        ..especialidades = mantidas.isEmpty ? p.etiquetas(2) : mantidas;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- destaque e planos

  EstadoDestaque destaque({required bool clinica}) =>
      clinica ? destaqueClinica : destaquePsicologo;

  /// Compra simulada: em produção a ativação só acontece quando o provedor de
  /// pagamento confirma (seção 5 da documentação).
  void comprarDestaque({
    required bool clinica,
    required OpcaoDestaque opcao,
    required DateTime inicio,
  }) {
    final e = destaque(clinica: clinica);
    final fimNovo = inicio.add(Duration(hours: opcao.horas));
    if (e.fim == null || fimNovo.isAfter(e.fim!)) e.fim = fimNovo;
    if (!clinica) psicologoAtual.destaque = true;
    notifyListeners();
  }

  void mudarPlano({required bool clinica, required String planoId}) {
    destaque(clinica: clinica).planoId = planoId;
    notifyListeners();
  }

  // ---------------------------------------------------------------- relatórios

  /// Simula o pedido ao worker de relatórios: o PDF fica pronto depois.
  Future<void> gerarRelatorio(String titulo) async {
    final r = Relatorio(titulo: titulo, pedidoEm: agora);
    relatorios.insert(0, r);
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 2));
    r.status = StatusRelatorio.pronto;
    notifyListeners();
  }

  // ---------------------------------------------------------------- clínica

  MembroEquipe? membroDoPsicologo(String psicologoId) {
    for (final m in equipe) {
      if (m.psicologoId == psicologoId) return m;
    }
    return null;
  }

  MembroEquipe cadastrarMembro({
    required String nome,
    required String email,
    required String crp,
    required List<String> especialidades,
    required bool exibirNaPagina,
    required bool atenderNasSalas,
    required bool incluirNoFinanceiro,
  }) {
    final m = MembroEquipe(
      id: _novoId('m'),
      nome: nome.trim(),
      email: email.trim(),
      crp: crp.trim(),
      especialidades: especialidades,
      acesso: Acesso.aguardando,
      exibirNaPagina: exibirNaPagina,
      atenderNasSalas: atenderNasSalas,
      incluirNoFinanceiro: incluirNoFinanceiro,
    );
    equipe.add(m);
    notifyListeners();
    return m;
  }

  void atualizarMembro(
    MembroEquipe m, {
    required bool exibirNaPagina,
    required bool atenderNasSalas,
    required bool incluirNoFinanceiro,
  }) {
    m
      ..exibirNaPagina = exibirNaPagina
      ..atenderNasSalas = atenderNasSalas
      ..incluirNoFinanceiro = incluirNoFinanceiro;
    notifyListeners();
  }

  /// Totais do mês de um psicólogo da equipe, só agregados (RNF010).
  TotaisMes totaisDoMembro(MembroEquipe m, int mes) {
    if (m.psicologoId == idPsicologoDemo) {
      final r = resumo(agora.year, mes);
      return (r.sessoes, r.recebido, r.aReceber);
    }
    return _financeiroEquipe[m.psicologoId]?[mes] ?? (0, 0.0, 0.0);
  }
}
