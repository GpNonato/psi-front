import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';

/// "Página da clínica" no painel. O editor com layout, seções e capa (RF031)
/// ainda não tem wireframe (seção 6.5 da documentação); por enquanto a tela
/// mostra a página publicada e quem aparece nela.
class PaginaClinicaEditorScreen extends StatelessWidget {
  const PaginaClinicaEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = store.clinicaAtual;
    final wide = context.isWide;
    final membros =
        store.equipe.where((m) => m.acesso == Acesso.ativo).toList();
    void abrirPublica() => abrirTela<void>(context, Rotas.paginaClinica(c.id));
    final resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.nome, style: AppText.serif(28)),
        Text(
          'Clínica de psicologia · ${c.bairro}, ${c.cidade}',
          style:
              const TextStyle(fontSize: 15, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 10),
        Text(c.descricao, style: const TextStyle(fontSize: 15, height: 1.5)),
      ],
    );
    return ProShell(
      papel: Papel.clinica,
      rota: Rotas.paginaDaClinica,
      child: PaginaPro(
        titulo: 'Página da clínica',
        abaixoDoTitulo: Row(
          children: [
            Text('psihub.com.br/${c.slug}',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textoSecundario)),
            const SizedBox(width: 16),
            LinkTexto(
              'Copiar',
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: 'https://psihub.com.br/${c.slug}'));
                avisar(context, 'Endereço copiado.');
              },
            ),
          ],
        ),
        acoes: [
          BotaoPill('Ver página',
              estilo: EstiloBotao.contorno, onPressed: abrirPublica)
        ],
        acoesMobile: [
          BotaoPill('Ver',
              estilo: EstiloBotao.contorno,
              compacto: true,
              onPressed: abrirPublica)
        ],
        children: [
          const AvisoLavanda(
            'O editor com layout, seções, ordem e foto de capa ainda não tem wireframe (seção 6.5 da '
            'documentação). Por enquanto, veja a página publicada e escolha quem aparece nela.',
            titulo: 'Editor da página em produção',
          ),
          const SizedBox(height: 20),
          CartaoApp(
            child: wide
                ? Row(
                    children: [
                      fotoDaClinica(c, 80),
                      const SizedBox(width: 24),
                      Expanded(child: resumo),
                      const SizedBox(width: 24),
                      BotaoPill('Abrir página pública',
                          onPressed: abrirPublica),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      fotoDaClinica(c, 80),
                      const SizedBox(height: 16),
                      resumo,
                      const SizedBox(height: 16),
                      BotaoPill('Abrir página pública',
                          onPressed: abrirPublica),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          CartaoApp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CabecalhoCartao('Psicólogos exibidos na página'),
                const SizedBox(height: 4),
                const Text(
                  'Só aparecem psicólogos com acesso ativo e a permissão ligada.',
                  style: AppText.pequeno,
                ),
                const SizedBox(height: 10),
                for (final m in membros)
                  LinhaSwitch(
                    rotulo: m.nome,
                    subtitulo: m.especialidades.join(' · '),
                    valor: m.exibirNaPagina,
                    onChanged: (v) => context.acoes.atualizarMembro(
                      m,
                      exibirNaPagina: v,
                      atenderNasSalas: m.atenderNasSalas,
                      incluirNoFinanceiro: m.incluirNoFinanceiro,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
