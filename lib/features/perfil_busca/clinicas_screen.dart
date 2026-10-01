import 'package:flutter/material.dart';

import '../../core/core.dart';
import 'cartoes.dart';

/// Lista de clínicas (item "Clínicas" da barra superior do paciente).
class ClinicasScreen extends StatefulWidget {
  const ClinicasScreen({super.key});

  @override
  State<ClinicasScreen> createState() => _ClinicasScreenState();
}

class _ClinicasScreenState extends State<ClinicasScreen> {
  String _texto = '';

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final q = normalizar(_texto);
    final lista = store.clinicas
        .where(
            (c) => q.isEmpty || normalizar('${c.nome} ${c.bairro}').contains(q))
        .toList();
    final wide = context.isWide;
    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: wide ? 32 : 20),
        Semantics(
            header: true,
            child: Text('Clínicas', style: AppText.serif(wide ? 38 : 34))),
        const SizedBox(height: 6),
        const Text(
          'Clínicas de psicologia com página própria no PsiHub.',
          style: TextStyle(fontSize: 15, color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: wide ? 520 : double.infinity,
          child: CampoTexto(
            hint: 'Buscar por nome ou bairro',
            icone: Icons.search_rounded,
            onChanged: (v) => setState(() => _texto = v),
          ),
        ),
        const SizedBox(height: 24),
        if (lista.isEmpty)
          const CartaoApp(child: Text('Nenhuma clínica encontrada.')),
        GradeResponsiva(
          larguraMinItem: 300,
          espaco: wide ? 24 : 12,
          children: [
            for (final c in lista) CartaoClinica(clinica: c, compacto: !wide)
          ],
        ),
        SizedBox(height: wide ? 8 : 32),
      ],
    );
    return PacienteShell(
      secao: SecaoPaciente.clinicas,
      child: wide
          ? ConteudoComRodape(child: conteudo)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: conteudo,
            ),
    );
  }
}
