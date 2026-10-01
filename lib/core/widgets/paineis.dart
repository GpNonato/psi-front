import 'package:flutter/material.dart';

import '../responsive.dart';
import '../theme.dart';
import 'botoes.dart';
import 'icones.dart';

/// Abre como diálogo no layout web e como folha inferior no celular, como nos
/// wireframes (ex.: Confirmar agendamento, Avaliar consulta).
Future<T?> abrirPainel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double larguraMax = 560,
}) {
  if (context.isWide) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: larguraMax),
          child: builder(ctx),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

/// Estrutura padrão de um painel: título, conteúdo rolável e ações.
class PainelConteudo extends StatelessWidget {
  const PainelConteudo({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.children,
    this.acoes,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> children;
  final Widget? acoes;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final h = wide ? 32.0 : 20.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(h, wide ? 28 : 0, wide ? 18 : h, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(titulo, style: AppText.serif(wide ? 28 : 26)),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitulo!,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (wide)
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icone(Icons.close_rounded),
                ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(h, 18, h, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (acoes != null)
          Padding(
            padding: EdgeInsets.fromLTRB(h, 16, h, wide ? 28 : 16),
            child: acoes,
          ),
      ],
    );
  }
}

/// Botões de um painel: no web, "Voltar" e a ação principal à direita; no
/// celular, a ação principal larga e "Cancelar" embaixo.
class AcoesPainel extends StatelessWidget {
  const AcoesPainel({
    super.key,
    required this.primario,
    required this.onPrimario,
    this.secundario = 'Cancelar',
    this.onSecundario,
    this.corPrimario,
  });

  final String primario;
  final VoidCallback? onPrimario;
  final String secundario;
  final VoidCallback? onSecundario;
  final Color? corPrimario;

  @override
  Widget build(BuildContext context) {
    final voltar = onSecundario ?? () => Navigator.of(context).pop();
    if (context.isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          BotaoPill(secundario,
              onPressed: voltar, estilo: EstiloBotao.contorno),
          const SizedBox(width: 12),
          Flexible(
            child: BotaoPill(primario, onPressed: onPrimario, cor: corPrimario),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotaoPill(
          primario,
          onPressed: onPrimario,
          expandir: true,
          cor: corPrimario,
          altura: 52,
        ),
        const SizedBox(height: 6),
        BotaoPill(
          secundario,
          onPressed: voltar,
          estilo: EstiloBotao.texto,
          expandir: true,
        ),
      ],
    );
  }
}

/// Pede confirmação antes de uma ação (cancelar consulta, trocar plano...).
Future<bool> pedirConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String rotuloConfirmar = 'Confirmar',
  String rotuloVoltar = 'Voltar',
  bool perigo = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: AppText.serif(24)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(mensagem, style: AppText.corpo),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        BotaoPill(
          rotuloVoltar,
          onPressed: () => Navigator.of(ctx).pop(false),
          estilo: EstiloBotao.texto,
          compacto: true,
        ),
        BotaoPill(
          rotuloConfirmar,
          onPressed: () => Navigator.of(ctx).pop(true),
          compacto: true,
          cor: perigo ? AppColors.vermelho : null,
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Mensagem rápida no rodapé da tela.
void avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 3)),
    );
}
