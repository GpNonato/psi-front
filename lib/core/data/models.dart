// Modelos do domínio usados pelo front-end. Os nomes seguem o vocabulário da
// documentação (seção 5 e contrato da API), mas os dados aqui são só de exemplo.

import '../formatters.dart';

enum Papel { paciente, psicologo, clinica }

enum Modalidade {
  online('Online'),
  presencial('Presencial');

  const Modalidade(this.rotulo);
  final String rotulo;
}

String rotuloModalidades(Iterable<Modalidade> modalidades) {
  final m = modalidades.toSet();
  if (m.length >= 2) return 'Online e presencial';
  if (m.contains(Modalidade.online)) return 'Online';
  if (m.contains(Modalidade.presencial)) return 'Presencial';
  return 'Sem modalidade';
}

const publicosAlvo = ['Crianças', 'Adolescentes', 'Adultos', 'Idosos'];

/// Faixa de horário de um dia da semana, em minutos desde 00:00.
class Faixa {
  const Faixa(this.inicio, this.fim);
  final int inicio;
  final int fim;

  bool sobrepoe(Faixa outra) => inicio < outra.fim && outra.inicio < fim;
}

class Bloqueio {
  const Bloqueio({required this.data, required this.motivo});
  final DateTime data;
  final String motivo;
}

/// Disponibilidade semanal publicada pelo psicólogo (RF008, RF020).
class Disponibilidade {
  Disponibilidade({
    required this.duracao,
    required this.intervalo,
    required this.modalidades,
    required this.faixas,
    required this.ativos,
    List<Bloqueio>? bloqueios,
  }) : bloqueios = bloqueios ?? [];

  int duracao;
  int intervalo;
  Set<Modalidade> modalidades;

  /// Chave: DateTime.monday (1) a DateTime.sunday (7).
  Map<int, List<Faixa>> faixas;
  Set<int> ativos;
  List<Bloqueio> bloqueios;

  Disponibilidade copia() => Disponibilidade(
        duracao: duracao,
        intervalo: intervalo,
        modalidades: {...modalidades},
        faixas: {
          for (final e in faixas.entries) e.key: [...e.value]
        },
        ativos: {...ativos},
        bloqueios: [...bloqueios],
      );

  List<Faixa> faixasDoDia(int weekday) =>
      ativos.contains(weekday) ? (faixas[weekday] ?? const []) : const [];

  Bloqueio? bloqueioEm(DateTime dia) {
    for (final b in bloqueios) {
      if (mesmoDia(b.data, dia)) return b;
    }
    return null;
  }

  /// Horários de início (em minutos) que a disponibilidade gera em um dia.
  List<int> inicios(int weekday) {
    final passo = duracao + intervalo;
    final r = <int>[];
    for (final f in faixasDoDia(weekday)) {
      for (var t = f.inicio; t + duracao <= f.fim; t += passo) {
        r.add(t);
      }
    }
    return r;
  }
}

class Horario {
  const Horario(this.inicio, {this.ocupado = false});
  final DateTime inicio;
  final bool ocupado;
}

class Psicologo {
  Psicologo({
    required this.id,
    required this.nome,
    required this.feminino,
    required this.crp,
    required this.anosExperiencia,
    required this.abordagem,
    required this.abordagemCompleta,
    required this.especialidades,
    required this.publicos,
    required this.cidade,
    required this.distribuicao,
    required this.valorSessao,
    required this.sobre,
    required this.whatsapp,
    required this.email,
    required this.endereco,
    required this.slug,
    required this.disponibilidade,
    this.clinicaId,
    this.formacao = const [],
    this.destaque = false,
    this.fotos = 6,
    this.temaCor = 0,
    this.temaFonte = 0,
  });

  final String id;
  String nome;
  final bool feminino;
  String crp;
  int anosExperiencia;
  String abordagem;
  String abordagemCompleta;
  List<String> especialidades;
  Set<String> publicos;
  String cidade;
  String? clinicaId;

  /// Quantidade de avaliações com 5, 4, 3, 2 e 1 estrela, nessa ordem.
  List<int> distribuicao;
  double valorSessao;
  String sobre;
  List<String> formacao;
  String whatsapp;
  String email;
  String endereco;
  bool destaque;
  int fotos;
  String slug;
  int temaCor;
  int temaFonte;
  Disponibilidade disponibilidade;

  Set<Modalidade> get modalidades => disponibilidade.modalidades;

  int get totalAvaliacoes => distribuicao.fold(0, (a, b) => a + b);

  double get nota {
    final total = totalAvaliacoes;
    if (total == 0) return 0;
    var soma = 0;
    for (var i = 0; i < 5; i++) {
      soma += distribuicao[i] * (5 - i);
    }
    return soma / total;
  }

  String get iniciaisNome => iniciais(nome);
  String get titulo => feminino ? 'Psicóloga clínica' : 'Psicólogo clínico';
  String get profissional => feminino ? 'psicóloga' : 'psicólogo';
  String get artigo => feminino ? 'a' : 'o';

  /// Até [limite] etiquetas para os cards: especialidades e depois públicos.
  List<String> etiquetas([int limite = 2]) {
    final r = <String>[...especialidades];
    for (final p in publicosAlvo) {
      if (publicos.contains(p) && !r.contains(p)) r.add(p);
    }
    return r.take(limite).toList();
  }
}

class Clinica {
  const Clinica({
    required this.id,
    required this.nome,
    required this.bairro,
    required this.cidade,
    required this.endereco,
    required this.descricao,
    required this.nota,
    required this.avaliacoes,
    required this.slug,
    this.destaque = false,
  });

  final String id;
  final String nome;
  final String bairro;
  final String cidade;
  final String endereco;
  final String descricao;
  final double nota;
  final int avaliacoes;
  final String slug;
  final bool destaque;

  String get iniciaisNome => iniciais(nome);
}

enum StatusConsulta { confirmada, cancelada }

class Consulta {
  Consulta({
    required this.id,
    required this.psicologoId,
    required this.pacienteId,
    required this.pacienteNome,
    required this.inicio,
    required this.modalidade,
    this.duracao = 50,
    this.status = StatusConsulta.confirmada,
    this.nova = false,
    this.avaliacao,
    this.mensagem,
  });

  final String id;
  final String psicologoId;
  final String pacienteId;
  String pacienteNome;
  DateTime inicio;
  int duracao;
  Modalidade modalidade;
  StatusConsulta status;

  /// Marcada há pouco pelo paciente (aparece como "Nova" na agenda).
  bool nova;

  /// Nota dada pelo paciente, quando a consulta já foi avaliada.
  int? avaliacao;
  String? mensagem;

  DateTime get fim => inicio.add(Duration(minutes: duracao));
  bool get cancelada => status == StatusConsulta.cancelada;

  /// Confirmada e com horário já encerrado.
  bool realizada(DateTime agora) => !cancelada && !fim.isAfter(agora);

  /// Confirmada e ainda não encerrada.
  bool proxima(DateTime agora) => !cancelada && fim.isAfter(agora);
}

class Avaliacao {
  const Avaliacao({
    required this.psicologoId,
    required this.autor,
    required this.nota,
    required this.texto,
    required this.data,
  });

  final String psicologoId;
  final String autor;
  final int nota;
  final String texto;
  final DateTime data;
}

enum TipoNotificacao { nova, cancelada, lembrete, remarcada, info }

class Notificacao {
  Notificacao({
    required this.tipo,
    required this.titulo,
    required this.detalhe,
    required this.quando,
    this.lida = false,
  });

  final TipoNotificacao tipo;
  final String titulo;
  final String detalhe;
  final DateTime quando;
  bool lida;
}

class Documento {
  Documento({
    required this.nome,
    required this.data,
    required this.tamanhoKb,
    this.assinado = false,
  });

  String nome;
  final DateTime data;
  final int tamanhoKb;
  final bool assinado;
}

class Anotacao {
  Anotacao({required this.data, required this.sessao, required this.texto});

  final DateTime data;
  final int sessao;
  String texto;
}

/// Paciente na lista do psicólogo, com a ficha (RF023, RF024).
class Paciente {
  Paciente({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.nascimento,
    required this.cpfFinal,
    required this.endereco,
    required this.contatoEmergencia,
    required this.desde,
    this.sessoesAnteriores = 0,
    this.formaPreferida = 'Pix',
    this.valorSessao = 180,
    this.pagoAntes = 0,
    List<Documento>? documentos,
    List<Anotacao>? anotacoes,
  })  : documentos = documentos ?? [],
        anotacoes = anotacoes ?? [];

  final String id;
  String nome;
  String telefone;
  String email;
  DateTime nascimento;
  String cpfFinal;
  String endereco;
  String contatoEmergencia;
  final DateTime desde;

  /// Sessões realizadas antes do período que os dados de exemplo cobrem.
  final int sessoesAnteriores;
  String formaPreferida;
  double valorSessao;

  /// Valor pago no ano antes dos lançamentos de exemplo.
  double pagoAntes;
  final List<Documento> documentos;
  final List<Anotacao> anotacoes;

  int idade(DateTime agora) {
    var anos = agora.year - nascimento.year;
    final fezAniversario = agora.month > nascimento.month ||
        (agora.month == nascimento.month && agora.day >= nascimento.day);
    if (!fezAniversario) anos--;
    return anos;
  }
}

enum StatusPagamento { pago, pendente }

const formasDePagamento = ['Pix', 'Cartão', 'Dinheiro', 'Transferência'];

/// Lançamento financeiro informado manualmente pelo psicólogo (RF025).
class Lancamento {
  Lancamento({
    required this.id,
    required this.data,
    required this.pacienteId,
    required this.pacienteNome,
    required this.descricao,
    required this.valor,
    required this.status,
    this.forma,
    this.sessoes = 1,
  });

  final String id;
  final DateTime data;
  final String pacienteId;
  final String pacienteNome;
  final String descricao;
  final double valor;
  StatusPagamento status;
  String? forma;
  final int sessoes;

  bool get pago => status == StatusPagamento.pago;
}

class ResumoFinanceiro {
  const ResumoFinanceiro({
    required this.recebido,
    required this.aReceber,
    required this.sessoesPagas,
    required this.sessoesPendentes,
  });

  final double recebido;
  final double aReceber;
  final int sessoesPagas;
  final int sessoesPendentes;

  int get sessoes => sessoesPagas + sessoesPendentes;
  double get ticketMedio => sessoes == 0 ? 0 : (recebido + aReceber) / sessoes;
  double get percentualRecebido {
    final total = recebido + aReceber;
    return total == 0 ? 0 : recebido / total;
  }
}

enum Acesso { ativo, aguardando }

/// Psicólogo vinculado à clínica (RF026).
class MembroEquipe {
  MembroEquipe({
    required this.id,
    required this.nome,
    required this.email,
    required this.crp,
    required this.especialidades,
    this.psicologoId,
    this.acesso = Acesso.ativo,
    this.exibirNaPagina = true,
    this.atenderNasSalas = true,
    this.incluirNoFinanceiro = true,
  });

  final String id;
  String nome;
  final String email;
  String crp;
  List<String> especialidades;

  /// Perfil público do psicólogo, quando o acesso já foi ativado.
  final String? psicologoId;
  Acesso acesso;
  bool exibirNaPagina;
  bool atenderNasSalas;
  bool incluirNoFinanceiro;
}

class Plano {
  const Plano({
    required this.id,
    required this.nome,
    required this.preco,
    required this.recursos,
    required this.destaquesPorMes,
    required this.resumo,
  });

  final String id;
  final String nome;
  final double preco;
  final List<String> recursos;
  final int destaquesPorMes;
  final String resumo;
}

const planosPsicologo = [
  Plano(
    id: 'gratuito',
    nome: 'Gratuito',
    preco: 0,
    recursos: [
      'Página e agenda online',
      'Até 20 pacientes',
      'Sem destaques inclusos'
    ],
    destaquesPorMes: 0,
    resumo: 'Sem destaques inclusos',
  ),
  Plano(
    id: 'profissional',
    nome: 'Profissional',
    preco: 49,
    recursos: [
      'Pacientes e documentos ilimitados',
      'Financeiro completo',
      '4 destaques de 24 h por mês',
    ],
    destaquesPorMes: 4,
    resumo: '4 destaques de 24 h por mês incluídos',
  ),
  Plano(
    id: 'destaque-plus',
    nome: 'Destaque+',
    preco: 99,
    recursos: [
      'Tudo do Profissional',
      '10 destaques de 24 h por mês',
      'Relatórios de desempenho',
    ],
    destaquesPorMes: 10,
    resumo: '10 destaques de 24 h por mês incluídos',
  ),
];

const planosClinica = [
  Plano(
    id: 'gratuito',
    nome: 'Gratuito',
    preco: 0,
    recursos: [
      'Página da clínica',
      'Até 3 psicólogos',
      'Sem destaques inclusos'
    ],
    destaquesPorMes: 0,
    resumo: 'Sem destaques inclusos',
  ),
  Plano(
    id: 'clinica',
    nome: 'Clínica',
    preco: 149,
    recursos: [
      'Até 10 psicólogos',
      'Financeiro da equipe',
      '4 destaques de 24 h por mês',
    ],
    destaquesPorMes: 4,
    resumo: '4 destaques de 24 h por mês incluídos',
  ),
  Plano(
    id: 'clinica-plus',
    nome: 'Clínica+',
    preco: 299,
    recursos: [
      'Psicólogos ilimitados',
      '12 destaques por mês',
      'Destacar psicólogos da equipe',
    ],
    destaquesPorMes: 12,
    resumo: '12 destaques por mês incluídos',
  ),
];

class OpcaoDestaque {
  const OpcaoDestaque(this.rotulo, this.horas, this.preco);
  final String rotulo;
  final int horas;
  final double preco;
}

const opcoesDestaque = [
  OpcaoDestaque('24 horas', 24, 19.90),
  OpcaoDestaque('72 horas', 72, 49.90),
  OpcaoDestaque('7 dias', 168, 99.90),
];

/// Destaque patrocinado e plano de um psicólogo ou de uma clínica (RF021, RF022).
class EstadoDestaque {
  EstadoDestaque({
    required this.planoId,
    this.fim,
    this.usadosNoMes = 0,
    this.visualizacoes = 0,
    this.cliques = 0,
    this.agendamentos = 0,
  });

  String planoId;
  DateTime? fim;
  int usadosNoMes;
  int visualizacoes;
  int cliques;
  int agendamentos;

  bool ativo(DateTime agora) => fim != null && fim!.isAfter(agora);
}

enum StatusRelatorio { gerando, pronto }

class Relatorio {
  Relatorio({
    required this.titulo,
    required this.pedidoEm,
    this.status = StatusRelatorio.gerando,
  });

  final String titulo;
  final DateTime pedidoEm;
  StatusRelatorio status;
}

class ErroAgendamento implements Exception {
  const ErroAgendamento(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}
