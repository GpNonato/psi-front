import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../perfil_busca/cartoes.dart';

/// Aba "Perfil" do paciente.
class ContaPacienteScreen extends StatefulWidget {
  const ContaPacienteScreen({super.key});

  @override
  State<ContaPacienteScreen> createState() => _ContaPacienteScreenState();
}

class _ContaPacienteScreenState extends State<ContaPacienteScreen> {
  bool _email = true;
  bool _push = true;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final wide = context.isWide;
    final favoritos =
        store.psicologos.where((p) => store.favoritos.contains(p.id)).toList();
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: wide ? 40 : 20),
        Semantics(
            header: true,
            child: Text('Minha conta', style: AppText.serif(wide ? 34 : 28))),
        const SizedBox(height: 20),
        CartaoApp(
          child: Row(
            children: [
              AvatarIniciais(store.pacienteNome, tamanho: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.pacienteNome, style: AppText.serif(24)),
                    Text(store.pacienteEmail, style: AppText.pequeno),
                    const Text('(31) 98888-1111', style: AppText.pequeno),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CartaoApp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoCartao('Notificações'),
              const SizedBox(height: 8),
              const Text(
                'O lembrete 30 minutos antes da consulta é sempre enviado.',
                style: AppText.pequeno,
              ),
              const SizedBox(height: 8),
              LinhaSwitch(
                rotulo: 'Avisos por e-mail',
                valor: _email,
                onChanged: (v) => setState(() => _email = v),
              ),
              LinhaSwitch(
                rotulo: 'Notificações no celular',
                valor: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CartaoApp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CabecalhoCartao('Psicólogos salvos'),
              const SizedBox(height: 12),
              if (favoritos.isEmpty)
                const Text(
                  'Toque no coração de um perfil para salvar aqui.',
                  style: AppText.pequeno,
                ),
              for (final p in favoritos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: fotoDoPsicologo(p, 40),
                  title: Text(p.nome),
                  subtitle: Text(textoProximoHorario(store, p)),
                  trailing: const Icone(Icons.chevron_right_rounded),
                  onTap: () => abrirPerfil(context, p),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const AvisoLavanda(
          'Seus dados de saúde são tratados conforme a LGPD e só o seu psicólogo vê a sua ficha.',
          icone: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 20),
        BotaoPill(
          'Sair',
          estilo: EstiloBotao.perigo,
          icone: Icons.logout_rounded,
          onPressed: () {
            context.acoes.sair();
            irPara(context, Rotas.entrar);
          },
        ),
        const SizedBox(height: 32),
      ],
    );
    return PacienteShell(
      secao: SecaoPaciente.conta,
      child: wide
          ? ConteudoComRodape(larguraMax: 820, child: conteudo)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: conteudo,
            ),
    );
  }
}

/// Configurações do psicólogo e da clínica.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key, required this.papel});

  final Papel papel;

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _email = true;
  bool _push = true;
  bool _resumo = false;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final psicologo = widget.papel == Papel.psicologo;
    final (nome, email) = psicologo
        ? (store.psicologoAtual.nome, store.psicologoAtual.email)
        : (
            'Paula Souza · ${store.clinicaAtual.nome}',
            'contato@clinicaequilibrio.com.br'
          );
    return ProShell(
      papel: widget.papel,
      rota: psicologo ? Rotas.configuracoes : Rotas.configuracoesClinica,
      child: PaginaPro(
        titulo: 'Configurações',
        subtitulo: 'Conta, notificações e privacidade',
        children: [
          CartaoApp(
            child: Row(
              children: [
                if (psicologo)
                  fotoDoPsicologo(store.psicologoAtual, 56)
                else
                  fotoDaClinica(store.clinicaAtual, 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome, style: const TextStyle(fontSize: 17)),
                      Text(email, style: AppText.pequeno),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CartaoApp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CabecalhoCartao('Notificações'),
                const SizedBox(height: 8),
                LinhaSwitch(
                  rotulo: 'Consultas marcadas e canceladas por e-mail',
                  valor: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                LinhaSwitch(
                  rotulo: 'Notificações em tempo real',
                  subtitulo: 'No celular e no navegador',
                  valor: _push,
                  onChanged: (v) => setState(() => _push = v),
                ),
                LinhaSwitch(
                  rotulo: 'Resumo semanal da agenda',
                  valor: _resumo,
                  onChanged: (v) => setState(() => _resumo = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AvisoLavanda(
            psicologo
                ? 'Fichas, anotações e documentos dos pacientes ficam visíveis só para você '
                    '(sigilo profissional, CFP e LGPD).'
                : 'A clínica vê apenas agenda e valores agregados da equipe, nunca dados ou '
                    'documentos dos pacientes.',
            icone: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: BotaoPill(
              'Sair da conta',
              estilo: EstiloBotao.perigo,
              icone: Icons.logout_rounded,
              onPressed: () {
                context.acoes.sair();
                irPara(context, Rotas.entrar);
              },
            ),
          ),
        ],
      ),
    );
  }
}
