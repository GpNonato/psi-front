import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'cadastrar_psicologo.dart';

/// Foto do psicólogo da equipe ou, se o acesso ainda não foi ativado, as iniciais.
Widget avatarDoMembro(AppStore store, MembroEquipe m, double tamanho) {
  final p =
      m.psicologoId == null ? null : store.psicologoOuNulo(m.psicologoId!);
  return p == null
      ? AvatarIniciais(m.nome, tamanho: tamanho)
      : fotoDoPsicologo(p, tamanho);
}

/// Equipe da clínica (wireframe 16).
class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key});

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  String _busca = '';
  Acesso? _status;

  List<MembroEquipe> _filtrar(List<MembroEquipe> equipe) {
    final q = normalizar(_busca);
    return equipe.where((m) {
      if (q.isNotEmpty && !normalizar('${m.nome} ${m.crp}').contains(q)) {
        return false;
      }
      if (_status != null && m.acesso != _status) return false;
      return true;
    }).toList();
  }

  void _cadastrar() => cadastrarPsicologo(context);

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final equipe = store.equipe;
    final aguardando =
        equipe.where((m) => m.acesso == Acesso.aguardando).length;
    final lista = _filtrar(equipe);
    final wide = context.isWide;
    return ProShell(
      papel: Papel.clinica,
      rota: Rotas.equipe,
      child: PaginaPro(
        titulo: 'Equipe',
        subtitulo: '${Fmt.plural(equipe.length, 'psicólogo', 'psicólogos')} · '
            '$aguardando aguardando ${wide ? 'primeiro acesso' : 'acesso'}',
        acoes: [
          BotaoPill('Cadastrar psicólogo',
              icone: Icons.add_rounded, onPressed: _cadastrar)
        ],
        acoesMobile: [
          BotaoPill('Cadastrar',
              icone: Icons.add_rounded, compacto: true, onPressed: _cadastrar)
        ],
        children: wide ? _web(store, lista) : _mobile(store, lista),
      ),
    );
  }

  List<Widget> _web(AppStore store, List<MembroEquipe> lista) {
    const cab = TextStyle(fontSize: 12.5, color: AppColors.textoSecundario);
    return [
      Row(
        children: [
          SizedBox(
            width: 340,
            child: CampoTexto(
              hint: 'Buscar por nome ou CRP',
              icone: Icons.search_rounded,
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: SeletorCaixa<String>(
              valor: switch (_status) {
                Acesso.ativo => 'Ativo',
                Acesso.aguardando => 'Aguardando acesso',
                null => null,
              },
              hint: 'Todos os status',
              opcoes: const ['Todos os status', 'Ativo', 'Aguardando acesso'],
              rotulo: (s) => s,
              onChanged: (s) => setState(() {
                _status = switch (s) {
                  'Ativo' => Acesso.ativo,
                  'Aguardando acesso' => Acesso.aguardando,
                  _ => null,
                };
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      CartaoApp(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Row(
                children: [
                  Expanded(flex: 27, child: Text('Psicólogo', style: cab)),
                  Expanded(flex: 12, child: Text('CRP', style: cab)),
                  Expanded(flex: 21, child: Text('Especialidades', style: cab)),
                  Expanded(
                      flex: 14, child: Text('Consultas na semana', style: cab)),
                  Expanded(flex: 15, child: Text('Acesso', style: cab)),
                  SizedBox(width: 120),
                ],
              ),
            ),
            const Divider(),
            if (lista.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum psicólogo com esses filtros.',
                    style: AppText.pequeno),
              ),
            for (var i = 0; i < lista.length; i++) ...[
              if (i > 0) const Divider(indent: 24, endIndent: 24),
              _linhaWeb(store, lista[i]),
            ],
          ],
        ),
      ),
      // O wireframe 16 deixa um respiro grande antes do aviso.
      const SizedBox(height: 88),
      const AvisoLavanda(
        'Cada psicólogo tem painel próprio. A clínica vê agenda e valores agregados, nunca dados ou '
        'documentos dos pacientes.',
        icone: Icons.lock_outline_rounded,
      ),
    ];
  }

  Widget _linhaWeb(AppStore store, MembroEquipe m) {
    final ativo = m.acesso == Acesso.ativo;
    final semana =
        m.psicologoId == null ? null : store.consultasNaSemana(m.psicologoId!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15.5),
      child: Row(
        children: [
          Expanded(
            flex: 27,
            child: Row(
              children: [
                avatarDoMembro(store, m, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nome, style: const TextStyle(fontSize: 15.5)),
                      Text(
                        m.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              flex: 12,
              child: Text(m.crp, style: const TextStyle(fontSize: 15))),
          Expanded(
            flex: 21,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final e in m.especialidades) TagChip(e, compacto: true)
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              ativo && semana != null ? '$semana' : '—',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Expanded(
            flex: 15,
            child: StatusPonto(
              ativo ? 'Ativo' : 'Aguardando acesso',
              cor: ativo ? AppColors.verde : AppColors.ambar,
              tamanho: 12.5,
            ),
          ),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerRight,
              child: ativo
                  ? LinkTexto('Gerenciar',
                      onTap: () => gerenciarMembro(context, m))
                  : LinkTexto('Reenviar acesso', onTap: () => _reenviar(m)),
            ),
          ),
        ],
      ),
    );
  }

  void _reenviar(MembroEquipe m) =>
      avisar(context, 'E-mail de acesso reenviado para ${m.email}.');

  List<Widget> _mobile(AppStore store, List<MembroEquipe> lista) {
    return [
      CampoTexto(
        hint: 'Buscar por nome ou CRP',
        icone: Icons.search_rounded,
        onChanged: (v) => setState(() => _busca = v),
      ),
      const SizedBox(height: 16),
      CartaoApp(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < lista.length; i++) ...[
              if (i > 0) const Divider(),
              _linhaMobile(store, lista[i]),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _linhaMobile(AppStore store, MembroEquipe m) {
    final ativo = m.acesso == Acesso.ativo;
    final semana =
        m.psicologoId == null ? 0 : store.consultasNaSemana(m.psicologoId!);
    return InkWell(
      onTap: () => ativo ? gerenciarMembro(context, m) : _reenviar(m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            avatarDoMembro(store, m, 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.nome, style: const TextStyle(fontSize: 15.5)),
                  Text(
                    ativo
                        ? 'CRP ${m.crp} · $semana na semana'
                        : 'E-mail de acesso enviado',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
            StatusPonto(
              ativo ? 'Ativo' : 'Pendente',
              cor: ativo ? AppColors.verde : AppColors.ambar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Permissões de um psicólogo da equipe.
Future<void> gerenciarMembro(BuildContext context, MembroEquipe m) {
  return abrirPainel<void>(context,
      larguraMax: 520, builder: (_) => _GerenciarMembro(membro: m));
}

class _GerenciarMembro extends StatefulWidget {
  const _GerenciarMembro({required this.membro});

  final MembroEquipe membro;

  @override
  State<_GerenciarMembro> createState() => _GerenciarMembroState();
}

class _GerenciarMembroState extends State<_GerenciarMembro> {
  late bool _exibir = widget.membro.exibirNaPagina;
  late bool _salas = widget.membro.atenderNasSalas;
  late bool _financeiro = widget.membro.incluirNoFinanceiro;

  @override
  Widget build(BuildContext context) {
    final m = widget.membro;
    return PainelConteudo(
      titulo: m.nome,
      subtitulo: 'CRP ${m.crp} · ${m.email}',
      acoes: AcoesPainel(
        primario: 'Salvar permissões',
        onPrimario: () {
          context.acoes.atualizarMembro(
            m,
            exibirNaPagina: _exibir,
            atenderNasSalas: _salas,
            incluirNoFinanceiro: _financeiro,
          );
          Navigator.of(context).pop();
        },
      ),
      children: [
        const Text('Permissões na clínica', style: AppText.rotulo),
        const SizedBox(height: 6),
        LinhaSwitch(
            rotulo: 'Exibir na página da clínica',
            valor: _exibir,
            onChanged: (v) => setState(() => _exibir = v)),
        LinhaSwitch(
            rotulo: 'Atender nas salas da clínica',
            valor: _salas,
            onChanged: (v) => setState(() => _salas = v)),
        LinhaSwitch(
          rotulo: 'Incluir no financeiro da equipe',
          subtitulo: 'Somente valores agregados',
          valor: _financeiro,
          onChanged: (v) => setState(() => _financeiro = v),
        ),
        if (m.psicologoId != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkTexto(
              'Ver página pública',
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.pushNamed(Rotas.perfilPsicologo(m.psicologoId!));
              },
            ),
          ),
        ],
      ],
    );
  }
}
