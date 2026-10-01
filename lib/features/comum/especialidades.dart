import 'package:flutter/material.dart';

import '../../core/core.dart';

const sugestoesEspecialidades = [
  'Ansiedade',
  'Depressão',
  'Luto',
  'Transições de vida',
  'Relacionamentos',
  'Casais',
  'Famílias',
  'Crianças',
  'Adolescentes',
  'TDAH',
  'Autoestima',
  'Trauma',
];

/// Pede uma especialidade nova (texto livre ou sugestão).
Future<String?> pedirEspecialidade(BuildContext context,
    {List<String> jaTem = const []}) {
  return abrirPainel<String>(
    context,
    larguraMax: 480,
    builder: (ctx) => _NovaEspecialidade(jaTem: jaTem),
  );
}

class _NovaEspecialidade extends StatefulWidget {
  const _NovaEspecialidade({required this.jaTem});

  final List<String> jaTem;

  @override
  State<_NovaEspecialidade> createState() => _NovaEspecialidadeState();
}

class _NovaEspecialidadeState extends State<_NovaEspecialidade> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _escolher(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(capitalizar(v));
  }

  @override
  Widget build(BuildContext context) {
    final sugestoes = sugestoesEspecialidades
        .where((s) => !widget.jaTem.contains(s))
        .toList();
    return PainelConteudo(
      titulo: 'Adicionar especialidade',
      acoes: AcoesPainel(
        primario: 'Adicionar',
        onPrimario: () => _escolher(_texto.text),
      ),
      children: [
        CampoTexto(
          controller: _texto,
          hint: 'Ex.: Ansiedade',
          autofocus: true,
          onSubmitted: _escolher,
        ),
        const SizedBox(height: 16),
        const Text('Sugestões', style: AppText.rotulo),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in sugestoes)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _escolher(s),
                child: TagChip(s),
              ),
          ],
        ),
      ],
    );
  }
}
