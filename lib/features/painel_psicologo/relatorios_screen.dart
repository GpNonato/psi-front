import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Relatórios de atendimento em PDF, gerados em segundo plano (worker de relatórios).
class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final agora = store.agora;
    final titulo =
        'Relatório de atendimentos · ${Fmt.mesLongo(agora.month)} de ${agora.year}';
    void gerar() {
      context.acoes.gerarRelatorio(titulo);
      avisar(
          context, 'Pedido enviado. O PDF aparece aqui quando ficar pronto.');
    }

    return ProShell(
      papel: Papel.psicologo,
      rota: Rotas.relatorios,
      child: PaginaPro(
        titulo: 'Relatórios',
        subtitulo: 'Relatórios de atendimento em PDF',
        acoes: [
          BotaoPill('Gerar relatório do mês',
              icone: Icons.add_rounded, onPressed: gerar)
        ],
        acoesMobile: [
          BotaoPill('Gerar',
              icone: Icons.add_rounded, compacto: true, onPressed: gerar)
        ],
        children: [
          const AvisoLavanda(
            'O PDF é gerado por um serviço separado, fora da tela: você pode continuar usando o '
            'app e ele aparece aqui quando ficar pronto.',
          ),
          const SizedBox(height: 16),
          CartaoApp(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                for (var i = 0; i < store.relatorios.length; i++) ...[
                  if (i > 0) const Divider(indent: 20, endIndent: 20),
                  _linha(context, store.relatorios[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, Relatorio r) {
    final pronto = r.status == StatusRelatorio.pronto;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading:
          const Icone(Icons.picture_as_pdf_outlined, color: AppColors.lavanda),
      title: Text(r.titulo),
      subtitle: Text(
          pronto ? 'Pronto · pedido em ${Fmt.data(r.pedidoEm)}' : 'Gerando…'),
      trailing: pronto
          ? BotaoPill(
              'Baixar PDF',
              estilo: EstiloBotao.contorno,
              compacto: true,
              onPressed: () =>
                  avisar(context, 'Download simulado nesta demonstração.'),
            )
          : const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.oliva),
            ),
    );
  }
}
