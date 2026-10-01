// Formatação de datas, horas e valores em português do Brasil, sem dependências externas.

const _diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _diasNomes = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
const _mesesCurtos = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];
const _mesesLongos = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String _dois(int n) => n.toString().padLeft(2, '0');

abstract final class Fmt {
  /// "Seg", "Ter"...
  static String diaCurtoSemana(int weekday) => _diasCurtos[weekday - 1];

  /// "Segunda", "Terça"...
  static String diaNomeSemana(int weekday) => _diasNomes[weekday - 1];

  /// "Segunda-feira"... (sábado e domingo ficam sem "-feira").
  static String diaLongoSemana(int weekday) => weekday >= 6
      ? _diasNomes[weekday - 1]
      : '${_diasNomes[weekday - 1]}-feira';

  static String mesCurto(int mes) => _mesesCurtos[mes - 1];
  static String mesLongo(int mes) => _mesesLongos[mes - 1];

  /// "Setembro 2026"
  static String mesAno(DateTime d) =>
      '${capitalizar(mesLongo(d.month))} ${d.year}';

  /// "14:30"
  static String hora(DateTime d) => '${_dois(d.hour)}:${_dois(d.minute)}';

  /// 870 -> "14:30"
  static String minutos(int m) => '${_dois(m ~/ 60)}:${_dois(m % 60)}';

  /// "08:00 – 12:00"
  static String faixa(int inicio, int fim) =>
      '${minutos(inicio)} – ${minutos(fim)}';

  /// "24 set"
  static String diaMes(DateTime d) => '${d.day} ${mesCurto(d.month)}';

  /// "Qui, 24 set"
  static String diaCurto(DateTime d) =>
      '${diaCurtoSemana(d.weekday)}, ${diaMes(d)}';

  /// "24 de setembro"
  static String diaMesLongo(DateTime d) => '${d.day} de ${mesLongo(d.month)}';

  /// "Quinta-feira, 24 de setembro"
  static String dataLonga(DateTime d) =>
      '${diaLongoSemana(d.weekday)}, ${diaMesLongo(d)}';

  /// "24/09/2026"
  static String data(DateTime d) =>
      '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// "Hoje", "Amanhã" ou "Qui, 24 set".
  static String relativo(DateTime d, DateTime agora) {
    final dias = soDia(d).difference(soDia(agora)).inDays;
    if (dias == 0) return 'Hoje';
    if (dias == 1) return 'Amanhã';
    return diaCurto(d);
  }

  /// "Hoje · 14:30" ou "Qui, 24 set · 14:30".
  static String quando(DateTime d, DateTime agora) =>
      '${relativo(d, agora)} · ${hora(d)}';

  /// "14:30 às 15:20"
  static String intervalo(DateTime inicio, int duracao) =>
      '${hora(inicio)} às ${hora(inicio.add(Duration(minutes: duracao)))}';

  /// "21 – 27 de setembro de 2026" ou "28 set – 4 out de 2026".
  static String semana(DateTime segunda) {
    final domingo = segunda.add(const Duration(days: 6));
    if (segunda.month == domingo.month) {
      return '${segunda.day} – ${domingo.day} de ${mesLongo(segunda.month)} de ${segunda.year}';
    }
    return '${diaMes(segunda)} – ${diaMes(domingo)} de ${domingo.year}';
  }

  /// 1240 -> "1.240"
  static String numero(int v) {
    final s = v.abs().toString();
    final b = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// 1980 -> "R$ 1.980,00"
  static String moeda(num v) {
    final centavosTotais = (v.abs() * 100).round();
    final inteiro = centavosTotais ~/ 100;
    final centavos = centavosTotais % 100;
    final texto = 'R\$ ${numero(inteiro)},${_dois(centavos)}';
    return v < 0 ? '-$texto' : texto;
  }

  /// 5400 -> "R$ 5.400" (mantém os centavos quando existem).
  static String moedaCurta(num v) {
    if ((v * 100).round() % 100 != 0) return moeda(v);
    final texto = 'R\$ ${numero(v.abs().round())}';
    return v < 0 ? '-$texto' : texto;
  }

  /// 4.875 -> "4,9"
  static String nota(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

  /// "agora", "há 5 min", "há 2 h", "ontem", "há 3 dias" ou "24 set".
  static String tempoRelativo(DateTime quando, DateTime agora) {
    final dif = agora.difference(quando);
    if (dif.inMinutes < 1) return 'agora';
    if (dif.inMinutes < 60) return 'há ${dif.inMinutes} min';
    if (mesmoDia(quando, agora)) return 'há ${dif.inHours} h';
    final dias = soDia(agora).difference(soDia(quando)).inDays;
    if (dias == 1) return 'ontem';
    if (dias < 7) return 'há $dias dias';
    return diaMes(quando);
  }

  /// "1 consulta", "3 consultas".
  static String plural(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  /// "na quinta, 24 set" ou "no sábado, 26 set".
  static String naDia(DateTime d) =>
      '${d.weekday >= 6 ? 'no' : 'na'} ${diaNomeSemana(d.weekday).toLowerCase()}, ${diaMes(d)}';

  /// Tempo desde uma data passada: "hoje", "há 3 dias", "há 2 semanas", "há 1 mês".
  static String haQuanto(DateTime data, DateTime agora) {
    final dias = soDia(agora).difference(soDia(data)).inDays;
    if (dias <= 0) return 'hoje';
    if (dias == 1) return 'ontem';
    if (dias < 7) return 'há $dias dias';
    if (dias < 30) {
      final s = dias ~/ 7;
      return 'há $s ${s == 1 ? 'semana' : 'semanas'}';
    }
    if (dias < 365) {
      final m = dias ~/ 30;
      return 'há $m ${m == 1 ? 'mês' : 'meses'}';
    }
    final a = dias ~/ 365;
    return 'há $a ${a == 1 ? 'ano' : 'anos'}';
  }
}

/// ["Adolescentes", "Adultos"] -> "Adolescentes e adultos"
String juntarLista(List<String> itens, {bool minusculas = true}) {
  if (itens.isEmpty) return '';
  final r = [
    for (var i = 0; i < itens.length; i++)
      i > 0 && minusculas ? itens[i].toLowerCase() : itens[i],
  ];
  if (r.length == 1) return r.first;
  return '${r.sublist(0, r.length - 1).join(', ')} e ${r.last}';
}

String capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

DateTime soDia(DateTime d) => DateTime(d.year, d.month, d.day);

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Segunda-feira da semana de [d].
DateTime inicioDaSemana(DateTime d) =>
    soDia(d).subtract(Duration(days: d.weekday - 1));

DateTime maisDias(DateTime d, int dias) =>
    DateTime(d.year, d.month, d.day + dias, d.hour, d.minute);

const _semAcento = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

/// Minúsculas e sem acentos, para buscas.
String normalizar(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().trim().split('')) {
    b.write(_semAcento[ch] ?? ch);
  }
  return b.toString();
}

List<String> _partes(String nome) =>
    nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

/// "Ana Ribeiro" -> "AR"
String iniciais(String nome) {
  final partes = _partes(nome);
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

/// "Marina Souza" -> "Marina S."
String nomeAbreviado(String nome) {
  final partes = _partes(nome);
  if (partes.length < 2) return nome.trim();
  return '${partes.first} ${partes.last[0].toUpperCase()}.';
}

String primeiroNome(String nome) {
  final partes = _partes(nome);
  return partes.isEmpty ? nome : partes.first;
}

/// "Ana Ribeiro" -> "ana-ribeiro"
String gerarSlug(String texto) {
  final base = normalizar(texto).replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return base.replaceAll(RegExp(r'^-+|-+$'), '');
}
