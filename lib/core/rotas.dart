import 'package:flutter/material.dart';

/// Endereços das telas. No web eles aparecem na barra do navegador.
abstract final class Rotas {
  static const entrar = '/entrar';
  static const cadastro = '/cadastro';

  // Paciente
  static const inicio = '/inicio';
  static const buscar = '/buscar';
  static const clinicas = '/clinicas';
  static const consultas = '/consultas';
  static const conta = '/conta';
  static String perfilPsicologo(String id) => '/psicologos/$id';
  static String paginaClinica(String id) => '/clinicas/$id';
  static String busca({String? texto, String? modalidade}) {
    final q = <String, String>{
      if (texto != null && texto.trim().isNotEmpty) 'q': texto.trim(),
      if (modalidade != null) 'modalidade': modalidade,
    };
    return Uri(path: buscar, queryParameters: q.isEmpty ? null : q).toString();
  }

  // Psicólogo
  static const agenda = '/psicologo/agenda';
  static const disponibilidade = '/psicologo/disponibilidade';
  static const pacientes = '/psicologo/pacientes';
  static String ficha(String id) => '/psicologo/pacientes/$id';
  static const financeiro = '/psicologo/financeiro';
  static const minhaPagina = '/psicologo/minha-pagina';
  static const destaque = '/psicologo/destaque';
  static const relatorios = '/psicologo/relatorios';
  static const configuracoes = '/psicologo/configuracoes';
  static const maisPsicologo = '/psicologo/mais';

  // Clínica
  static const equipe = '/clinica/equipe';
  static const agendaEquipe = '/clinica/agenda';
  static const financeiroEquipe = '/clinica/financeiro';
  static const paginaDaClinica = '/clinica/pagina';
  static const destaqueClinica = '/clinica/destaque';
  static const configuracoesClinica = '/clinica/configuracoes';
  static const maisClinica = '/clinica/mais';
}

/// Troca de seção: substitui a pilha de telas, sem animação.
void irPara(BuildContext context, String rota) {
  Navigator.of(context).pushNamedAndRemoveUntil(rota, (_) => false);
}

/// Abre uma tela de detalhe por cima da atual.
Future<T?> abrirTela<T>(BuildContext context, String rota) =>
    Navigator.of(context).pushNamed<T>(rota);

/// Volta para a tela anterior ou, se a tela foi aberta direto pelo endereço,
/// para a seção [padrao].
void voltarOu(BuildContext context, String padrao) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    irPara(context, padrao);
  }
}
