import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Avaliar consulta realizada (wireframe 06).
Future<void> avaliarConsulta(BuildContext context, Consulta consulta) {
  return abrirPainel<void>(
    context,
    larguraMax: 520,
    builder: (_) => _AvaliarConsulta(consulta: consulta),
  );
}

class _AvaliarConsulta extends StatefulWidget {
  const _AvaliarConsulta({required this.consulta});

  final Consulta consulta;

  @override
  State<_AvaliarConsulta> createState() => _AvaliarConsultaState();
}

class _AvaliarConsultaState extends State<_AvaliarConsulta> {
  final _comentario = TextEditingController();
  int _nota = 0;
  bool _comNome = true;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _publicar() {
    final messenger = ScaffoldMessenger.of(context);
    context.acoes.avaliar(
      widget.consulta.id,
      nota: _nota,
      texto: _comentario.text,
      comNome: _comNome,
    );
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
            content: Text('Avaliação publicada no perfil. Obrigado!')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = widget.consulta;
    final p = store.psicologo(c.psicologoId);
    final wide = context.isWide;
    return PainelConteudo(
      titulo: 'Avaliar consulta',
      acoes: AcoesPainel(
        primario: 'Publicar avaliação',
        onPrimario: _nota == 0 ? null : _publicar,
        secundario: 'Cancelar',
      ),
      children: [
        Row(
          children: [
            fotoDoPsicologo(p, 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome, style: AppText.serif(20)),
                  Text(
                    'Consulta de ${wide ? Fmt.diaMesLongo(c.inicio) : Fmt.diaMes(c.inicio)} · '
                    '${c.modalidade.rotulo}',
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textoSecundario),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Center(
          child: Text(
            'Como foi o seu atendimento?',
            style: TextStyle(fontSize: 16, color: AppColors.texto),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SeletorEstrelas(
            valor: _nota,
            onChanged: (v) => setState(() => _nota = v),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _nota == 0
                ? 'Toque nas estrelas para dar uma nota'
                : rotulosNota[_nota]!,
            style: TextStyle(
              fontSize: 15,
              color: _nota == 0 ? AppColors.textoFraco : AppColors.lavanda,
            ),
          ),
        ),
        const SizedBox(height: 22),
        CampoTexto(
          controller: _comentario,
          rotulo: 'Comentário',
          hint: 'Conte como foi a sua experiência (opcional)',
          linhas: 4,
          maxLength: 500,
          contador: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        LinhaCheck(
          rotulo: 'Publicar como "${nomeAbreviado(store.pacienteNome)}"'
              '${wide ? ' (nome abreviado)' : ''}',
          valor: _comNome,
          onChanged: (v) => setState(() => _comNome = v),
        ),
        const SizedBox(height: 12),
        if (wide)
          const AvisoLavanda(
            'Só quem teve consulta realizada pode avaliar.',
            compacto: true,
          )
        else
          const Text(
            'Só quem teve consulta realizada pode avaliar.',
            style: TextStyle(fontSize: 13, color: AppColors.lavanda),
          ),
      ],
    );
  }
}
