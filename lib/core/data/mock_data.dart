// Dados de exemplo da demonstração, tirados dos wireframes (seção 6 da documentação).
// Tudo fica em memória: nada aqui é enviado para a API.

import '../formatters.dart';
import 'models.dart';

/// "Agora" fixo da demonstração: segunda-feira, 21/09/2026, às 14:05, a semana
/// mostrada nos wireframes.
final agoraDemonstracao = DateTime(2026, 9, 21, 14, 5);

const idPacienteDemo = 'marina';
const idPsicologoDemo = 'ana';
const idClinicaDemo = 'equilibrio';

/// Totais do mês informados pelos psicólogos da equipe que não são a Ana
/// (a clínica só vê valores agregados): consultas, recebido e a receber.
typedef TotaisMes = (int, double, double);

class DadosIniciais {
  DadosIniciais({
    required this.psicologos,
    required this.clinicas,
    required this.consultas,
    required this.avaliacoes,
    required this.notificacoesPsicologo,
    required this.notificacoesPaciente,
    required this.pacientes,
    required this.lancamentos,
    required this.equipe,
    required this.destaquePsicologo,
    required this.destaqueClinica,
    required this.relatorios,
    required this.financeiroEquipe,
  });

  final List<Psicologo> psicologos;
  final List<Clinica> clinicas;
  final List<Consulta> consultas;
  final List<Avaliacao> avaliacoes;
  final List<Notificacao> notificacoesPsicologo;
  final List<Notificacao> notificacoesPaciente;
  final List<Paciente> pacientes;
  final List<Lancamento> lancamentos;
  final List<MembroEquipe> equipe;
  final EstadoDestaque destaquePsicologo;
  final EstadoDestaque destaqueClinica;
  final List<Relatorio> relatorios;
  final Map<String, Map<int, TotaisMes>> financeiroEquipe;
}

int _h(int hora, [int minuto = 0]) => hora * 60 + minuto;

Map<int, List<Faixa>> _dias(List<int> dias, List<Faixa> faixas) => {
      for (final d in dias) d: [...faixas]
    };

Disponibilidade _disp(
  Map<int, List<Faixa>> faixas,
  Set<Modalidade> modalidades, {
  List<Bloqueio>? bloqueios,
}) =>
    Disponibilidade(
      duracao: 50,
      intervalo: 10,
      modalidades: modalidades,
      faixas: faixas,
      ativos: faixas.keys.toSet(),
      bloqueios: bloqueios,
    );

const _online = {Modalidade.online};
const _presencial = {Modalidade.presencial};
const _ambas = {Modalidade.online, Modalidade.presencial};

const _nomesPacientes = {
  'marina': 'Marina Souza',
  'mariana': 'Mariana Teixeira',
  'pedro': 'Pedro Alves',
  'helena': 'Helena Rocha',
  'lucas': 'Lucas Moreira',
  'beatriz': 'Beatriz Lima',
  'tiago': 'Tiago Faria',
  'rafaela': 'Rafaela Costa',
  'otavio': 'Otávio Lins',
  'paula': 'Paula Freitas',
  'carla': 'Carla Mendes',
  'vitor': 'Vitor Ramos',
  'sofia': 'Sofia Martins',
  'joao': 'João Pires',
};

const _on = Modalidade.online;
const _pre = Modalidade.presencial;

/// Agenda da Ana: paciente, mês, dia, hora, minuto e modalidade.
const _agendaAna = <(String, int, int, int, int, Modalidade)>[
  // Semana de 7 a 13 de setembro
  ('mariana', 9, 7, 9, 0, _on),
  ('marina', 9, 7, 14, 30, _on),
  ('lucas', 9, 8, 10, 0, _pre),
  ('helena', 9, 9, 8, 0, _on),
  ('rafaela', 9, 9, 15, 0, _pre),
  ('joao', 9, 10, 9, 0, _on),
  ('beatriz', 9, 11, 11, 0, _pre),
  ('tiago', 9, 11, 16, 0, _on),
  // Semana de 14 a 20 de setembro
  ('mariana', 9, 14, 9, 0, _on),
  ('marina', 9, 14, 14, 30, _on),
  ('lucas', 9, 15, 10, 0, _pre),
  ('otavio', 9, 15, 14, 0, _on),
  ('pedro', 9, 15, 15, 0, _on),
  ('helena', 9, 16, 8, 0, _on),
  ('paula', 9, 16, 13, 0, _pre),
  ('carla', 9, 17, 10, 0, _pre),
  ('vitor', 9, 17, 16, 30, _on),
  ('sofia', 9, 18, 9, 0, _on),
  // Semana de 21 a 27 de setembro (a dos wireframes)
  ('mariana', 9, 21, 9, 0, _on),
  ('pedro', 9, 21, 14, 30, _on),
  ('lucas', 9, 22, 10, 0, _pre),
  ('otavio', 9, 22, 14, 0, _on),
  ('helena', 9, 23, 8, 0, _on),
  ('paula', 9, 23, 13, 0, _pre),
  ('rafaela', 9, 23, 15, 0, _pre),
  ('joao', 9, 24, 9, 0, _on), // cancelada pelo paciente
  ('carla', 9, 24, 10, 0, _pre),
  ('vitor', 9, 24, 16, 30, _on),
  ('sofia', 9, 25, 9, 0, _on),
  ('beatriz', 9, 25, 11, 0, _pre),
  ('tiago', 9, 25, 16, 0, _on),
  // Semana seguinte
  ('mariana', 9, 28, 9, 0, _on),
  ('pedro', 9, 28, 14, 30, _on),
  ('lucas', 9, 29, 10, 0, _pre),
  ('helena', 9, 30, 8, 0, _on),
  ('marina', 10, 2, 14, 30, _on),
];

/// Consultas da semana dos outros psicólogos (sem nome de paciente):
/// psicólogo, dia de setembro e hora.
const _agendaOutros = <(String, int, int)>[
  ('carlos', 21, 8),
  ('carlos', 21, 10),
  ('carlos', 22, 8),
  ('carlos', 22, 9),
  ('carlos', 22, 14),
  ('carlos', 23, 10),
  ('carlos', 23, 15),
  ('carlos', 24, 8),
  ('carlos', 24, 13),
  ('juliana', 21, 14),
  ('juliana', 21, 16),
  ('juliana', 21, 17),
  ('juliana', 22, 9),
  ('juliana', 22, 10),
  ('juliana', 22, 14),
  ('juliana', 22, 16),
  ('juliana', 23, 8),
  ('juliana', 23, 13),
  ('juliana', 23, 17),
  ('juliana', 24, 10),
  ('juliana', 24, 15),
  ('juliana', 24, 18),
  ('juliana', 25, 11),
  ('bruno', 21, 8),
  ('bruno', 21, 9),
  ('bruno', 21, 11),
  ('bruno', 21, 15),
  ('bruno', 22, 8),
  ('bruno', 22, 15),
  ('bruno', 23, 9),
  ('bruno', 23, 14),
  ('bruno', 24, 11),
  ('bruno', 25, 16),
  ('luiza', 21, 15),
  ('luiza', 22, 8),
  ('luiza', 22, 9),
  ('luiza', 22, 15),
  ('luiza', 23, 10),
  ('luiza', 23, 14),
  ('luiza', 23, 16),
  ('luiza', 24, 8),
  ('luiza', 24, 15),
  ('luiza', 25, 9),
  ('luiza', 25, 14),
  ('rafael', 22, 10),
  ('rafael', 22, 13),
  ('rafael', 23, 8),
  ('rafael', 23, 15),
  ('rafael', 24, 9),
  ('rafael', 24, 16),
  ('rafael', 25, 10),
  ('rafael', 26, 9),
  ('camila', 21, 15),
  ('camila', 22, 9),
  ('camila', 23, 16),
  ('diego', 21, 16),
  ('diego', 22, 14),
  ('patricia', 22, 10),
  ('patricia', 23, 15),
  ('marcos', 21, 15),
  ('marcos', 23, 13),
  ('leticia', 21, 19),
  ('leticia', 22, 18),
  ('renato', 23, 9),
  ('renato', 25, 14),
];

/// Lançamentos de setembro da Ana: dia, paciente, valor, forma e se já foi pago.
/// Fecham os números do wireframe 13: R$ 5.400 em 30 sessões pagas, R$ 1.080
/// em 6 pendentes, 36 sessões e ticket médio de R$ 180. Pendente pode ter a
/// forma já combinada (Pedro, Pix) ou nenhuma ("—").
const _lancamentosSetembro = <(int, String, double, String?, bool)>[
  (21, 'pedro', 180, 'Pix', false),
  (21, 'mariana', 180, 'Pix', true),
  (18, 'marina', 180, 'Pix', true),
  (18, 'sofia', 180, 'Pix', false),
  (18, 'otavio', 180, 'Pix', true),
  (17, 'lucas', 180, null, false),
  (17, 'carla', 180, 'Pix', true),
  (17, 'vitor', 260, 'Pix', true), // avaliação inicial (primeira sessão)
  (16, 'helena', 640, 'Cartão', true), // pacote de 4 sessões
  (16, 'paula', 180, 'Cartão', false),
  (15, 'lucas', 180, null, false),
  (15, 'pedro', 180, 'Pix', true),
  (15, 'otavio', 180, 'Pix', true),
  (14, 'mariana', 180, 'Pix', true),
  (11, 'beatriz', 180, 'Dinheiro', true),
  (11, 'tiago', 180, 'Pix', true),
  (11, 'sofia', 180, 'Pix', true),
  (10, 'pedro', 180, 'Pix', true),
  (10, 'joao', 180, 'Pix', true),
  (9, 'rafaela', 180, null, false),
  (9, 'paula', 180, 'Cartão', true),
  (9, 'helena', 180, 'Cartão', true),
  (8, 'sofia', 180, 'Pix', true),
  (8, 'lucas', 180, 'Pix', true),
  (7, 'mariana', 180, 'Pix', true),
  (7, 'marina', 180, 'Pix', true),
  (4, 'beatriz', 180, 'Dinheiro', true),
  (4, 'tiago', 180, 'Pix', true),
  (3, 'carla', 180, 'Pix', true),
  (3, 'joao', 180, 'Pix', true),
  (2, 'paula', 180, 'Cartão', true),
  (2, 'mariana', 180, 'Pix', true),
  (1, 'otavio', 180, 'Pix', true),
];

const _pacientesAgosto = [
  'marina',
  'mariana',
  'lucas',
  'helena',
  'rafaela',
  'pedro',
  'beatriz',
  'tiago',
  'sofia',
  'paula',
];

DadosIniciais gerarDadosIniciais() {
  var seq = 0;
  String id(String prefixo) => '$prefixo${++seq}';

  // ---------------- Psicólogos ----------------
  final ana = Psicologo(
    id: 'ana',
    nome: 'Ana Ribeiro',
    feminino: true,
    crp: '04/12345',
    anosExperiencia: 8,
    abordagem: 'TCC',
    abordagemCompleta: 'Terapia cognitivo-comportamental',
    especialidades: ['Ansiedade', 'Luto', 'Transições de vida'],
    publicos: {'Adolescentes', 'Adultos'},
    cidade: 'Belo Horizonte, MG',
    clinicaId: 'equilibrio',
    distribuicao: [29, 2, 1, 0, 0],
    valorSessao: 180,
    sobre:
        'Sou psicóloga clínica e atendo adolescentes e adultos que passam por '
        'ansiedade, luto e transições de vida. Acredito em um espaço de escuta '
        'acolhedor, com objetivos construídos em conjunto e respeito ao tempo de '
        'cada pessoa.',
    formacao: [
      'Mestrado em Psicologia Clínica · PUC Minas',
      'Especialização em TCC',
    ],
    whatsapp: '(31) 99999-0000',
    email: 'ana.ribeiro@email.com',
    endereco: 'Clínica Equilíbrio · Av. Afonso Pena, 1500, sala 402',
    slug: 'ana-ribeiro',
    destaque: true,
    fotos: 8,
    disponibilidade: _disp(
      {
        1: [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(18))],
        2: [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(18))],
        3: [Faixa(_h(13), _h(20))],
        4: [Faixa(_h(8), _h(12)), Faixa(_h(14, 30), _h(19, 30))],
        5: [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(17))],
      },
      {..._ambas},
      bloqueios: [
        Bloqueio(data: DateTime(2026, 10, 12), motivo: 'Feriado (dia inteiro)'),
      ],
    ),
  );

  final manhaTarde = [Faixa(_h(8), _h(12)), Faixa(_h(13), _h(18))];

  final psicologos = <Psicologo>[
    ana,
    Psicologo(
      id: 'juliana',
      nome: 'Juliana Prado',
      feminino: true,
      crp: '04/34567',
      anosExperiencia: 5,
      abordagem: 'Gestalt-terapia',
      abordagemCompleta: 'Gestalt-terapia',
      especialidades: ['Relacionamentos'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'equilibrio',
      distribuicao: [34, 6, 1, 0, 0],
      valorSessao: 160,
      sobre:
          'Atendo adultos que querem olhar para os próprios relacionamentos: '
          'casais, família, amizades e trabalho. Na Gestalt-terapia, o foco é '
          'o aqui e agora e a forma como você se relaciona com o que sente.',
      formacao: ['Especialização em Gestalt-terapia · IGT'],
      whatsapp: '(31) 98888-2222',
      email: 'juliana.prado@email.com',
      endereco: 'Atendimento online',
      slug: 'juliana-prado',
      destaque: true,
      disponibilidade: _disp(
        {
          1: [Faixa(_h(13), _h(19))],
          ..._dias([2, 3, 4, 5], [Faixa(_h(8), _h(12)), Faixa(_h(13), _h(19))]),
        },
        {..._online},
      ),
    ),
    Psicologo(
      id: 'luiza',
      nome: 'Luiza Martins',
      feminino: true,
      crp: '04/67890',
      anosExperiencia: 6,
      abordagem: 'Ludoterapia',
      abordagemCompleta: 'Ludoterapia',
      especialidades: ['TDAH'],
      publicos: {'Crianças'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'equilibrio',
      distribuicao: [9, 0, 0, 0, 0],
      valorSessao: 170,
      sobre:
          'Trabalho com crianças por meio do brincar, com participação da família '
          'em todo o processo. Atendo questões de comportamento, TDAH, ansiedade '
          'infantil e dificuldades escolares.',
      formacao: ['Especialização em Psicologia Infantil · UFMG'],
      whatsapp: '(31) 97777-3333',
      email: 'luiza.martins@email.com',
      endereco: 'Clínica Equilíbrio · Av. Afonso Pena, 1500, sala 405',
      slug: 'luiza-martins',
      destaque: true,
      disponibilidade: _disp(
        {
          1: [Faixa(_h(14), _h(18))],
          ..._dias([2, 3, 4, 5], [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(18))]),
        },
        {..._presencial},
      ),
    ),
    Psicologo(
      id: 'bruno',
      nome: 'Bruno Castro',
      feminino: false,
      crp: '04/56789',
      anosExperiencia: 10,
      abordagem: 'Terapia do esquema',
      abordagemCompleta: 'Terapia do esquema',
      especialidades: ['Ansiedade'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'equilibrio',
      distribuicao: [8, 3, 1, 0, 0],
      valorSessao: 190,
      sobre:
          'Ajudo adultos a identificar padrões que se repetem em relacionamentos, '
          'no trabalho e na forma de lidar com a ansiedade, usando a terapia do '
          'esquema.',
      formacao: ['Formação em Terapia do Esquema · Wainer'],
      whatsapp: '(31) 96666-4444',
      email: 'bruno.castro@email.com',
      endereco: 'Atendimento online',
      slug: 'bruno-castro',
      disponibilidade: _disp(_dias([1, 2, 3, 4, 5], manhaTarde), {..._online}),
    ),
    Psicologo(
      id: 'rafael',
      nome: 'Rafael Duarte',
      feminino: false,
      crp: '04/45678',
      anosExperiencia: 15,
      abordagem: 'Terapia sistêmica',
      abordagemCompleta: 'Terapia sistêmica',
      especialidades: ['Casais', 'Famílias'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'equilibrio',
      distribuicao: [22, 4, 1, 0, 0],
      valorSessao: 220,
      sobre:
          'Atendo casais e famílias em momentos de crise, mudança ou conflito, '
          'olhando para a comunicação e os vínculos entre as pessoas.',
      formacao: ['Especialização em Terapia Familiar Sistêmica'],
      whatsapp: '(31) 95555-5555',
      email: 'rafael.duarte@email.com',
      endereco: 'Clínica Equilíbrio · Av. Afonso Pena, 1500, sala 410',
      slug: 'rafael-duarte',
      disponibilidade: _disp(
        {
          ..._dias([2, 3, 4, 5], manhaTarde),
          6: [Faixa(_h(8), _h(12))],
        },
        {..._ambas},
      ),
    ),
    Psicologo(
      id: 'carlos',
      nome: 'Carlos Menezes',
      feminino: false,
      crp: '04/23456',
      anosExperiencia: 12,
      abordagem: 'Psicanálise',
      abordagemCompleta: 'Psicanálise',
      especialidades: ['Depressão'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'equilibrio',
      distribuicao: [13, 4, 1, 0, 0],
      valorSessao: 200,
      sobre:
          'Psicanalista, atendo adultos em sofrimento com depressão, angústia e '
          'questões de relacionamento, em sessões presenciais.',
      formacao: ['Formação em Psicanálise · Círculo Psicanalítico de MG'],
      whatsapp: '(31) 94444-6666',
      email: 'carlos.menezes@email.com',
      endereco: 'Clínica Equilíbrio · Av. Afonso Pena, 1500, sala 403',
      slug: 'carlos-menezes',
      disponibilidade: _disp(
        {
          1: [Faixa(_h(8), _h(12))],
          ..._dias([2, 3, 4], [Faixa(_h(8), _h(12)), Faixa(_h(13), _h(17))]),
          5: [Faixa(_h(8), _h(12))],
        },
        {..._presencial},
      ),
    ),
    Psicologo(
      id: 'camila',
      nome: 'Camila Torres',
      feminino: true,
      crp: '04/11223',
      anosExperiencia: 7,
      abordagem: 'Psicanálise',
      abordagemCompleta: 'Psicanálise',
      especialidades: ['Depressão', 'Ansiedade'],
      publicos: {'Adultos', 'Idosos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'acolher',
      distribuicao: [15, 3, 0, 0, 0],
      valorSessao: 170,
      sobre: 'Atendo adultos e idosos em processos de depressão, ansiedade e '
          'mudanças de fase da vida.',
      whatsapp: '(31) 93333-7777',
      email: 'camila.torres@email.com',
      endereco: 'Espaço Acolher · Rua Pernambuco, 1200',
      slug: 'camila-torres',
      disponibilidade: _disp(
        _dias([1, 2, 3, 4, 5], [Faixa(_h(9), _h(12)), Faixa(_h(14), _h(19))]),
        {..._ambas},
      ),
    ),
    Psicologo(
      id: 'diego',
      nome: 'Diego Nunes',
      feminino: false,
      crp: '04/33445',
      anosExperiencia: 4,
      abordagem: 'TCC',
      abordagemCompleta: 'Terapia cognitivo-comportamental',
      especialidades: ['Ansiedade', 'TDAH'],
      publicos: {'Adolescentes', 'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'acolher',
      distribuicao: [6, 2, 0, 0, 0],
      valorSessao: 150,
      sobre: 'Trabalho com adolescentes e jovens adultos com ansiedade, TDAH e '
          'desafios de rotina e estudo.',
      whatsapp: '(31) 92222-8888',
      email: 'diego.nunes@email.com',
      endereco: 'Espaço Acolher · Rua Pernambuco, 1200',
      slug: 'diego-nunes',
      disponibilidade: _disp(
        _dias([1, 2, 3, 4], [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(18))]),
        {..._presencial},
      ),
    ),
    Psicologo(
      id: 'patricia',
      nome: 'Patrícia Gomes',
      feminino: true,
      crp: '04/55667',
      anosExperiencia: 11,
      abordagem: 'Terapia sistêmica',
      abordagemCompleta: 'Terapia sistêmica',
      especialidades: ['Casais', 'Famílias', 'Luto'],
      publicos: {'Adultos', 'Idosos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'raizes',
      distribuicao: [12, 2, 1, 0, 0],
      valorSessao: 200,
      sobre:
          'Acompanho casais e famílias, inclusive em processos de luto, com um '
          'olhar sistêmico para os vínculos.',
      whatsapp: '(31) 91111-9999',
      email: 'patricia.gomes@email.com',
      endereco: 'Instituto Raízes · Av. Otacílio Negrão de Lima, 3000',
      slug: 'patricia-gomes',
      disponibilidade: _disp(
        {
          2: [Faixa(_h(9), _h(13))],
          ..._dias([3, 4, 5], [Faixa(_h(9), _h(13)), Faixa(_h(15), _h(19))]),
          6: [Faixa(_h(9), _h(13))],
        },
        {..._ambas},
      ),
    ),
    Psicologo(
      id: 'renato',
      nome: 'Renato Alves',
      feminino: false,
      crp: '04/77889',
      anosExperiencia: 13,
      abordagem: 'Gestalt-terapia',
      abordagemCompleta: 'Gestalt-terapia',
      especialidades: ['Relacionamentos', 'Depressão'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      clinicaId: 'raizes',
      distribuicao: [9, 2, 0, 0, 0],
      valorSessao: 180,
      sobre:
          'Atendimento online para adultos, com foco em relacionamentos e depressão.',
      whatsapp: '(31) 90000-1111',
      email: 'renato.alves@email.com',
      endereco: 'Atendimento online',
      slug: 'renato-alves',
      disponibilidade: _disp(
        _dias([1, 3, 5], [Faixa(_h(8), _h(12)), Faixa(_h(14), _h(18))]),
        {..._online},
      ),
    ),
    Psicologo(
      id: 'marcos',
      nome: 'Marcos Vieira',
      feminino: false,
      crp: '04/66778',
      anosExperiencia: 9,
      abordagem: 'Análise do comportamento',
      abordagemCompleta: 'Análise do comportamento',
      especialidades: ['TDAH', 'Ansiedade'],
      publicos: {'Crianças', 'Adolescentes'},
      cidade: 'Belo Horizonte, MG',
      distribuicao: [10, 3, 1, 0, 0],
      valorSessao: 160,
      sobre: 'Consultório próprio. Atendo crianças e adolescentes com TDAH, '
          'ansiedade e dificuldades de aprendizagem, com orientação aos pais.',
      whatsapp: '(31) 98765-0000',
      email: 'marcos.vieira@email.com',
      endereco: 'Consultório próprio · Rua da Bahia, 900, sala 12',
      slug: 'marcos-vieira',
      disponibilidade: _disp(
        _dias([1, 2, 3, 4, 5], [Faixa(_h(13), _h(19))]),
        {..._presencial},
      ),
    ),
    Psicologo(
      id: 'leticia',
      nome: 'Letícia Rocha',
      feminino: true,
      crp: '04/88990',
      anosExperiencia: 3,
      abordagem: 'Abordagem centrada na pessoa',
      abordagemCompleta: 'Abordagem centrada na pessoa',
      especialidades: ['Ansiedade', 'Depressão', 'Transições de vida'],
      publicos: {'Adultos'},
      cidade: 'Belo Horizonte, MG',
      distribuicao: [5, 1, 0, 0, 0],
      valorSessao: 130,
      sobre: 'Atendimento online à noite e aos sábados, para quem tem a rotina '
          'cheia durante o dia.',
      whatsapp: '(31) 97654-0000',
      email: 'leticia.rocha@email.com',
      endereco: 'Atendimento online',
      slug: 'leticia-rocha',
      disponibilidade: _disp(
        {
          ..._dias([1, 2, 3, 4, 5], [Faixa(_h(18), _h(21))]),
          6: [Faixa(_h(9), _h(12))],
        },
        {..._online},
      ),
    ),
  ];

  // ---------------- Clínicas ----------------
  const clinicas = <Clinica>[
    Clinica(
      id: 'equilibrio',
      nome: 'Clínica Equilíbrio',
      bairro: 'Savassi',
      cidade: 'Belo Horizonte',
      endereco: 'Av. Afonso Pena, 1500 · sala 402',
      descricao:
          'Há 10 anos cuidando da saúde emocional de crianças, adolescentes e '
          'adultos, com uma equipe de psicólogos de diferentes abordagens.',
      nota: 4.8,
      avaliacoes: 64,
      slug: 'clinica-equilibrio',
      destaque: true,
    ),
    Clinica(
      id: 'acolher',
      nome: 'Espaço Acolher',
      bairro: 'Funcionários',
      cidade: 'Belo Horizonte',
      endereco: 'Rua Pernambuco, 1200',
      descricao:
          'Atendimento acolhedor para adolescentes, adultos e idosos, com foco em '
          'ansiedade, depressão e mudanças de fase da vida.',
      nota: 4.9,
      avaliacoes: 88,
      slug: 'espaco-acolher',
      destaque: true,
    ),
    Clinica(
      id: 'raizes',
      nome: 'Instituto Raízes',
      bairro: 'Pampulha',
      cidade: 'Belo Horizonte',
      endereco: 'Av. Otacílio Negrão de Lima, 3000',
      descricao:
          'Terapia de casais, famílias e adultos, com olhar sistêmico para os '
          'vínculos e atendimento online e presencial.',
      nota: 4.7,
      avaliacoes: 31,
      slug: 'instituto-raizes',
      destaque: true,
    ),
  ];

  // ---------------- Consultas ----------------
  final consultas = <Consulta>[];
  for (final (pac, mes, dia, hora, minuto, modalidade) in _agendaAna) {
    final inicio = DateTime(2026, mes, dia, hora, minuto);
    consultas.add(
      Consulta(
        id: id('c'),
        psicologoId: 'ana',
        pacienteId: pac,
        pacienteNome: _nomesPacientes[pac]!,
        inicio: inicio,
        modalidade: modalidade,
        status: pac == 'joao' && mesmoDia(inicio, DateTime(2026, 9, 24))
            ? StatusConsulta.cancelada
            : StatusConsulta.confirmada,
        avaliacao: pac == 'marina' && mesmoDia(inicio, DateTime(2026, 9, 7))
            ? 5
            : null,
      ),
    );
  }
  final porId = {for (final p in psicologos) p.id: p};
  for (final (psi, dia, hora) in _agendaOutros) {
    consultas.add(
      Consulta(
        id: id('c'),
        psicologoId: psi,
        // Um paciente diferente por consulta (a clínica não vê nomes).
        pacienteId: 'paciente-$psi-$dia-$hora',
        pacienteNome: 'Paciente',
        inicio: DateTime(2026, 9, dia, hora),
        modalidade: porId[psi]!.modalidades.first,
      ),
    );
  }

  // ---------------- Avaliações publicadas ----------------
  final avaliacoes = <Avaliacao>[
    Avaliacao(
      psicologoId: 'ana',
      autor: 'Marina S.',
      nota: 5,
      texto:
          'A Ana me ajudou muito a lidar com a ansiedade no trabalho. Escuta atenta '
          'e acolhedora, me sinto à vontade em todas as sessões.',
      data: DateTime(2026, 9, 7, 16),
    ),
    Avaliacao(
      psicologoId: 'ana',
      autor: 'João C.',
      nota: 5,
      texto:
          'Profissional pontual e muito cuidadosa. O atendimento online funciona muito bem.',
      data: DateTime(2026, 8, 21, 10),
    ),
    Avaliacao(
      psicologoId: 'juliana',
      autor: 'Carolina M.',
      nota: 5,
      texto:
          'Me sinto ouvida e respeitada. As sessões online são tranquilas e pontuais.',
      data: DateTime(2026, 9, 10),
    ),
    Avaliacao(
      psicologoId: 'luiza',
      autor: 'Fernanda R.',
      nota: 5,
      texto:
          'Meu filho adora as sessões. A Luiza tem muita paciência e criatividade.',
      data: DateTime(2026, 9, 3),
    ),
    Avaliacao(
      psicologoId: 'bruno',
      autor: 'Rodrigo P.',
      nota: 4,
      texto:
          'Bom profissional, direto ao ponto. Me ajudou a entender meus padrões.',
      data: DateTime(2026, 8, 28),
    ),
    Avaliacao(
      psicologoId: 'rafael',
      autor: 'Aline T.',
      nota: 5,
      texto: 'Ajudou muito na comunicação do casal. Sessões leves e objetivas.',
      data: DateTime(2026, 9, 12),
    ),
    Avaliacao(
      psicologoId: 'carlos',
      autor: 'Eduardo S.',
      nota: 5,
      texto: 'Escuta cuidadosa e respeitosa. Recomendo.',
      data: DateTime(2026, 8, 30),
    ),
    Avaliacao(
      psicologoId: 'camila',
      autor: 'Beatriz C.',
      nota: 5,
      texto: 'Acolhedora e atenta aos detalhes.',
      data: DateTime(2026, 9, 1),
    ),
    Avaliacao(
      psicologoId: 'diego',
      autor: 'Gustavo L.',
      nota: 5,
      texto: 'Me ajudou a lidar com a ansiedade antes das provas.',
      data: DateTime(2026, 9, 5),
    ),
    Avaliacao(
      psicologoId: 'patricia',
      autor: 'Roberto A.',
      nota: 5,
      texto: 'Nos ajudou a atravessar um momento difícil em família.',
      data: DateTime(2026, 8, 25),
    ),
    Avaliacao(
      psicologoId: 'renato',
      autor: 'Felipe G.',
      nota: 5,
      texto: 'Sessões leves e produtivas.',
      data: DateTime(2026, 9, 8),
    ),
    Avaliacao(
      psicologoId: 'marcos',
      autor: 'Luciana F.',
      nota: 4,
      texto: 'Muito bom com crianças, meu filho evoluiu bastante.',
      data: DateTime(2026, 8, 18),
    ),
    Avaliacao(
      psicologoId: 'leticia',
      autor: 'Priscila M.',
      nota: 5,
      texto: 'Os horários à noite ajudaram muito na minha rotina.',
      data: DateTime(2026, 9, 14),
    ),
  ];

  // ---------------- Notificações ----------------
  final notificacoesPsicologo = <Notificacao>[
    Notificacao(
      tipo: TipoNotificacao.lembrete,
      titulo: 'Lembrete enviado',
      detalhe: 'Pedro A. · Hoje · 14:30',
      quando: DateTime(2026, 9, 21, 14),
    ),
    Notificacao(
      tipo: TipoNotificacao.cancelada,
      titulo: 'Consulta cancelada',
      detalhe: 'João P. · Qui, 24 set · 09:00',
      quando: DateTime(2026, 9, 21, 13, 2),
    ),
    Notificacao(
      tipo: TipoNotificacao.nova,
      titulo: 'Nova consulta marcada',
      detalhe: 'Beatriz L. · Sex, 25 set · 11:00',
      quando: DateTime(2026, 9, 20, 18, 20),
      lida: true,
    ),
    Notificacao(
      tipo: TipoNotificacao.nova,
      titulo: 'Nova consulta marcada',
      detalhe: 'Vitor R. · Qui, 24 set · 16:30',
      quando: DateTime(2026, 9, 19, 11, 40),
      lida: true,
    ),
  ];
  final notificacoesPaciente = <Notificacao>[
    Notificacao(
      tipo: TipoNotificacao.info,
      titulo: 'Como foi sua consulta?',
      detalhe: 'Avalie a consulta de 14 set com Ana Ribeiro',
      quando: DateTime(2026, 9, 14, 15, 30),
    ),
    Notificacao(
      tipo: TipoNotificacao.lembrete,
      titulo: 'Lembrete de consulta',
      detalhe: 'Ana Ribeiro · Seg, 14 set · 14:30',
      quando: DateTime(2026, 9, 14, 14),
      lida: true,
    ),
  ];

  // ---------------- Pacientes da Ana ----------------
  Paciente paciente(
    String pid, {
    required String telefone,
    required DateTime nascimento,
    required DateTime desde,
    required int anteriores,
    String cpf = '00',
    String? endereco,
    String? emergencia,
    List<Documento>? documentos,
    List<Anotacao>? anotacoes,
    String forma = 'Pix',
  }) {
    final nome = _nomesPacientes[pid]!;
    return Paciente(
      id: pid,
      nome: nome,
      telefone: telefone,
      email: '${gerarSlug(nome).replaceAll('-', '.')}@email.com',
      nascimento: nascimento,
      cpfFinal: cpf,
      endereco: endereco ?? 'Belo Horizonte, MG',
      contatoEmergencia: emergencia ?? 'Não informado',
      desde: desde,
      sessoesAnteriores: anteriores,
      formaPreferida: forma,
      documentos: documentos ??
          [
            Documento(
              nome: 'Contrato terapêutico.pdf',
              data: desde,
              tamanhoKb: 180,
              assinado: true,
            ),
          ],
      anotacoes: anotacoes ??
          [
            Anotacao(
              data: DateTime(2026, 9, 15),
              sessao: anteriores + 1,
              texto:
                  'Sessão de acompanhamento. Retomamos os objetivos combinados '
                  'no início do processo.',
            ),
          ],
    );
  }

  final pacientes = <Paciente>[
    paciente(
      'marina',
      telefone: '(31) 98888-1111',
      nascimento: DateTime(1992, 4, 12),
      desde: DateTime(2026, 3, 2),
      anteriores: 10,
      cpf: '12',
      endereco: 'Rua Pernambuco, 800 · BH',
      emergencia: 'Paulo Souza · (31) 97777-0000',
      documentos: [
        Documento(
          nome: 'Contrato terapêutico.pdf',
          data: DateTime(2026, 3, 2),
          tamanhoKb: 180,
          assinado: true,
        ),
        Documento(
          nome: 'Encaminhamento psiquiátrico.pdf',
          data: DateTime(2026, 5, 15),
          tamanhoKb: 96,
        ),
        Documento(
          nome: 'Inventário de ansiedade (BAI).pdf',
          data: DateTime(2026, 8, 10),
          tamanhoKb: 220,
        ),
      ],
      anotacoes: [
        Anotacao(
          data: DateTime(2026, 9, 14),
          sessao: 12,
          texto:
              'Relatou melhora do sono. Retomamos o registro de pensamentos sobre '
              'o trabalho; combinar exercício de exposição gradual.',
        ),
        Anotacao(
          data: DateTime(2026, 9, 7),
          sessao: 11,
          texto:
              'Crise de ansiedade antes de reunião importante. Trabalhamos técnicas '
              'de respiração e reestruturação cognitiva.',
        ),
        Anotacao(
          data: DateTime(2026, 8, 31),
          sessao: 10,
          texto: 'Revisão dos objetivos terapêuticos com a paciente. Ajuste de '
              'frequência mantido semanal.',
        ),
      ],
    ),
    paciente('pedro',
        telefone: '(31) 97777-2222',
        nascimento: DateTime(1988, 7, 3),
        desde: DateTime(2026, 6, 1),
        anteriores: 7,
        cpf: '47'),
    paciente('helena',
        telefone: '(31) 96666-3333',
        nascimento: DateTime(1979, 11, 20),
        desde: DateTime(2025, 10, 6),
        anteriores: 18,
        cpf: '81',
        forma: 'Cartão'),
    paciente('lucas',
        telefone: '(31) 95555-4444',
        nascimento: DateTime(2009, 2, 14),
        desde: DateTime(2026, 7, 7),
        anteriores: 3,
        cpf: '30',
        emergencia: 'Cláudia Moreira (mãe) · (31) 95555-0000'),
    paciente('beatriz',
        telefone: '(31) 94444-5555',
        nascimento: DateTime(1995, 5, 9),
        desde: DateTime(2025, 12, 5),
        anteriores: 14,
        cpf: '55',
        forma: 'Dinheiro'),
    paciente('tiago',
        telefone: '(31) 93333-6666',
        nascimento: DateTime(2001, 9, 30),
        desde: DateTime(2026, 8, 7),
        anteriores: 2,
        cpf: '68'),
    paciente('rafaela',
        telefone: '(31) 92222-7777',
        nascimento: DateTime(1990, 1, 25),
        desde: DateTime(2026, 4, 1),
        anteriores: 8,
        cpf: '90'),
    paciente('mariana',
        telefone: '(31) 91111-8888',
        nascimento: DateTime(1985, 3, 17),
        desde: DateTime(2026, 6, 8),
        anteriores: 6,
        cpf: '23'),
    paciente('otavio',
        telefone: '(31) 99876-1234',
        nascimento: DateTime(1998, 8, 8),
        desde: DateTime(2026, 8, 4),
        anteriores: 3,
        cpf: '64'),
    paciente('paula',
        telefone: '(31) 98765-4321',
        nascimento: DateTime(1976, 12, 1),
        desde: DateTime(2026, 5, 6),
        anteriores: 5,
        cpf: '17',
        forma: 'Cartão'),
    paciente('carla',
        telefone: '(31) 97654-3210',
        nascimento: DateTime(2003, 6, 21),
        desde: DateTime(2026, 9, 3),
        anteriores: 1,
        cpf: '38'),
    paciente('vitor',
        telefone: '(31) 96543-2109',
        nascimento: DateTime(1993, 10, 10),
        desde: DateTime(2026, 9, 10),
        anteriores: 0,
        cpf: '76'),
    paciente('sofia',
        telefone: '(31) 95432-1098',
        nascimento: DateTime(1999, 4, 4),
        desde: DateTime(2026, 5, 4),
        anteriores: 7,
        cpf: '05'),
    paciente('joao',
        telefone: '(31) 94321-0987',
        nascimento: DateTime(1982, 2, 28),
        desde: DateTime(2026, 7, 2),
        anteriores: 2,
        cpf: '99'),
  ];

  // ---------------- Lançamentos da Ana ----------------
  final lancamentos = <Lancamento>[];
  for (final (dia, pac, valor, forma, pago) in _lancamentosSetembro) {
    final pacote = valor > 500;
    lancamentos.add(
      Lancamento(
        id: id('l'),
        data: DateTime(2026, 9, dia),
        pacienteId: pac,
        pacienteNome: _nomesPacientes[pac]!,
        descricao: pacote
            ? 'Pacote 4 sessões'
            : (valor > 180 ? 'Avaliação inicial' : 'Sessão individual'),
        valor: valor,
        forma: forma,
        status: pago ? StatusPagamento.pago : StatusPagamento.pendente,
        sessoes: pacote ? 4 : 1,
      ),
    );
  }
  // Agosto: 32 sessões pagas ("+4 em relação a agosto" no wireframe 13).
  var n = 0;
  for (var dia = 3; dia <= 31 && n < 32; dia++) {
    final data = DateTime(2026, 8, dia);
    if (data.weekday >= DateTime.saturday) continue;
    final porDia = dia.isOdd ? 2 : 1;
    for (var k = 0; k < porDia && n < 32; k++) {
      final pac = _pacientesAgosto[n % _pacientesAgosto.length];
      final pacienteDoDia = pacientes.firstWhere((p) => p.id == pac);
      lancamentos.add(
        Lancamento(
          id: id('l'),
          data: data,
          pacienteId: pac,
          pacienteNome: _nomesPacientes[pac]!,
          descricao: 'Sessão individual',
          valor: 180,
          forma: pacienteDoDia.formaPreferida,
          status: StatusPagamento.pago,
        ),
      );
      n++;
    }
  }
  // O que a Marina pagou antes de agosto, para fechar R$ 1.980,00 no ano.
  final marina = pacientes.first;
  final pagoMarina = lancamentos
      .where((l) => l.pacienteId == 'marina' && l.pago)
      .fold<double>(0, (a, l) => a + l.valor);
  marina.pagoAntes = 1980 - pagoMarina;
  for (final p in pacientes.skip(1)) {
    p.pagoAntes = p.sessoesAnteriores * 90.0;
  }

  // ---------------- Equipe da Clínica Equilíbrio ----------------
  MembroEquipe membro(Psicologo p, List<String> especialidades) => MembroEquipe(
        id: 'm-${p.id}',
        nome: p.nome,
        email: p.email,
        crp: p.crp,
        especialidades: especialidades,
        psicologoId: p.id,
      );
  final equipe = <MembroEquipe>[
    membro(ana, ['Ansiedade', 'Luto']),
    membro(porId['carlos']!, ['Depressão', 'Adultos']),
    membro(porId['juliana']!, ['Relacionamentos']),
    membro(porId['bruno']!, ['Ansiedade', 'Adultos']),
    membro(porId['luiza']!, ['Crianças', 'TDAH']),
    membro(porId['rafael']!, ['Casais', 'Famílias']),
    MembroEquipe(
      id: 'm-fernanda',
      nome: 'Fernanda Lima',
      email: 'fernanda.lima@email.com',
      crp: '04/78901',
      especialidades: ['Adolescentes'],
      acesso: Acesso.aguardando,
    ),
  ];

  return DadosIniciais(
    psicologos: psicologos,
    clinicas: clinicas,
    consultas: consultas,
    avaliacoes: avaliacoes,
    notificacoesPsicologo: notificacoesPsicologo,
    notificacoesPaciente: notificacoesPaciente,
    pacientes: pacientes,
    lancamentos: lancamentos,
    equipe: equipe,
    destaquePsicologo: EstadoDestaque(
      planoId: 'profissional',
      fim: DateTime(2026, 9, 22, 9),
      usadosNoMes: 2,
      visualizacoes: 1240,
      cliques: 86,
      agendamentos: 7,
    ),
    destaqueClinica: EstadoDestaque(
      planoId: 'clinica',
      fim: DateTime(2026, 9, 22, 9),
      usadosNoMes: 2,
      visualizacoes: 1240,
      cliques: 86,
      agendamentos: 7,
    ),
    relatorios: [
      Relatorio(
        titulo: 'Relatório de atendimentos · agosto de 2026',
        pedidoEm: DateTime(2026, 9, 1, 7),
        status: StatusRelatorio.pronto,
      ),
    ],
    financeiroEquipe: {
      'carlos': {9: (36, 6120, 360), 8: (34, 6120, 0)},
      'juliana': {9: (56, 9000, 1080), 8: (52, 8320, 0)},
      'bruno': {9: (40, 6480, 540), 8: (38, 7220, 0)},
      'luiza': {9: (44, 7200, 180), 8: (41, 6970, 0)},
      'rafael': {9: (32, 5400, 900), 8: (30, 6600, 0)},
    },
  );
}
