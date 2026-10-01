import 'package:flutter/material.dart';

import '../../core/core.dart';

String textoProximoHorario(AppStore store, Psicologo p) {
  final proximo = store.proximoHorario(p);
  return proximo == null
      ? 'Sem horários livres'
      : Fmt.quando(proximo, store.agora);
}

void abrirPerfil(BuildContext context, Psicologo p) =>
    abrirTela<void>(context, Rotas.perfilPsicologo(p.id));

/// Trecho curto de uma avaliação para o card em destaque: a última frase.
String trechoCitacao(String texto) {
  final frases = texto
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((f) => f.trim())
      .where((f) => f.isNotEmpty)
      .toList();
  if (frases.length < 2) return texto.trim();
  return frases.last;
}

/// Card de psicólogo (início e busca no web, carrossel no celular).
class CartaoPsicologo extends StatelessWidget {
  const CartaoPsicologo({
    super.key,
    required this.psicologo,
    this.preencherAltura = false,
  });

  final Psicologo psicologo;

  /// Em linhas de altura fixa, a foto ocupa o espaço que sobrar.
  final bool preencherAltura;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = psicologo;
    final foto = Ilustracao.retrato(
      p.id,
      feminino: p.feminino,
      altura: preencherAltura ? null : 128,
      raio: 16,
      descricao: 'Foto de ${p.nome}',
      sobreposicoes: [
        if (p.destaque)
          const Positioned(top: 10, left: 10, child: SeloDestaque()),
      ],
    );
    return CartaoApp(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      onTap: () => abrirPerfil(context, p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: preencherAltura ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (preencherAltura) Expanded(child: foto) else foto,
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 15, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.serif(18),
                ),
                const SizedBox(height: 3),
                Text(
                  'CRP ${p.crp} · ${Fmt.plural(p.anosExperiencia, 'ano', 'anos')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 5),
                NotaInline(nota: p.nota, total: p.totalAvaliacoes, tamanho: 13),
                const SizedBox(height: 2),
                Etiquetas(p.etiquetas(), compacto: true),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Próximo horário',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5, color: AppColors.textoFraco),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            textoProximoHorario(store, p),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.texto),
                          ),
                        ],
                      ),
                    ),
                    BotaoPill(
                      'Agendar',
                      compacto: true,
                      altura: 36,
                      onPressed: () => abrirPerfil(context, p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card grande do primeiro psicólogo em destaque (início, web).
class CartaoPsicologoDestaque extends StatelessWidget {
  const CartaoPsicologoDestaque({super.key, required this.psicologo});

  final Psicologo psicologo;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = psicologo;
    final avaliacoes = store.avaliacoesDe(p.id);
    final citacao = avaliacoes.isEmpty ? null : avaliacoes.first;
    final trecho = citacao == null ? null : trechoCitacao(citacao.texto);
    return CartaoApp(
      padding: const EdgeInsets.all(12),
      onTap: () => abrirPerfil(context, p),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 236,
            child: Ilustracao.retrato(
              p.id,
              feminino: p.feminino,
              raio: 16,
              descricao: 'Foto de ${p.nome}',
              sobreposicoes: const [
                Positioned(top: 10, left: 10, child: SeloDestaque())
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.serif(28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CRP ${p.crp} · ${p.abordagem} · ${Fmt.plural(p.anosExperiencia, 'ano', 'anos')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textoSecundario),
                  ),
                  const SizedBox(height: 8),
                  NotaInline(nota: p.nota, total: p.totalAvaliacoes),
                  const SizedBox(height: 22),
                  if (citacao != null) ...[
                    Text(
                      '“$trecho”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15.5, height: 1.5, color: AppColors.texto),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— ${citacao.autor}, paciente',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textoSecundario),
                    ),
                  ],
                  const Spacer(),
                  Etiquetas(p.etiquetas(), compacto: true),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Próximo horário',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5, color: AppColors.textoFraco),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              textoProximoHorario(store, p),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14.5, color: AppColors.texto),
                            ),
                          ],
                        ),
                      ),
                      BotaoPill('Agendar',
                          onPressed: () => abrirPerfil(context, p)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resultado da busca no celular (foto à esquerda).
class CartaoResultadoMobile extends StatelessWidget {
  const CartaoResultadoMobile({super.key, required this.psicologo});

  final Psicologo psicologo;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = psicologo;
    final etiqueta = p.etiquetas(1);
    return CartaoApp(
      padding: const EdgeInsets.all(12),
      raio: 20,
      onTap: () => abrirPerfil(context, p),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            height: 124,
            child: Ilustracao.retrato(
              p.id,
              feminino: p.feminino,
              raio: 14,
              descricao: 'Foto de ${p.nome}',
              sobreposicoes: [
                if (p.destaque)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icone(Icons.star_rounded,
                        size: 18, color: AppColors.estrela),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.serif(19),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.abordagem} · ${Fmt.plural(p.anosExperiencia, 'ano', 'anos')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 4),
                NotaInline(
                    nota: p.nota, total: p.totalAvaliacoes, tamanho: 12.5),
                const SizedBox(height: 8),
                if (etiqueta.isNotEmpty)
                  TagChip(etiqueta.first, compacto: true),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        textoProximoHorario(store, p),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.texto),
                      ),
                    ),
                    BotaoPill(
                      'Agendar',
                      compacto: true,
                      altura: 36,
                      onPressed: () => abrirPerfil(context, p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de clínica (início, lista de clínicas).
class CartaoClinica extends StatelessWidget {
  const CartaoClinica(
      {super.key, required this.clinica, this.compacto = false});

  final Clinica clinica;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = clinica;
    final n = store.psicologosDaClinica(c.id).length;
    void abrir() => abrirTela<void>(context, Rotas.paginaClinica(c.id));
    return CartaoApp(
      padding: EdgeInsets.all(compacto ? 16 : 20),
      onTap: abrir,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fotoDaClinica(c, compacto ? 56 : 64),
          SizedBox(width: compacto ? 14 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.serif(compacto ? 20 : 21),
                      ),
                    ),
                    if (c.destaque) const SeloDestaque(fundoBranco: false),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.bairro}, BH · ${Fmt.plural(n, 'psicólogo', 'psicólogos')}',
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textoSecundario),
                ),
                const SizedBox(height: 6),
                NotaInline(nota: c.nota, total: c.avaliacoes, tamanho: 13),
                if (!compacto) ...[
                  const SizedBox(height: 12),
                  BotaoPill(
                    'Ver clínica',
                    estilo: EstiloBotao.contorno,
                    compacto: true,
                    onPressed: abrir,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de psicólogo da equipe, na página da clínica (wireframe 07).
class CartaoMembroClinica extends StatelessWidget {
  const CartaoMembroClinica({super.key, required this.psicologo});

  final Psicologo psicologo;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = psicologo;
    final wide = context.isWide;
    final hoje = store.temHorarioNoDia(p, store.agora);
    return CartaoApp(
      padding: wide
          ? const EdgeInsets.fromLTRB(24, 24, 24, 12)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              fotoDoPsicologo(p, wide ? 64 : 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.serif(20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CRP ${p.crp} · ${Fmt.plural(p.anosExperiencia, 'ano', 'anos')}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textoSecundario),
                    ),
                    NotaInline(
                        nota: p.nota, total: p.totalAvaliacoes, tamanho: 12.5),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${p.abordagem} · ${rotuloModalidades(p.modalidades)}',
            style: const TextStyle(fontSize: 15, color: AppColors.texto),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in p.etiquetas()) TagChip(e, compacto: true),
              if (hoje) const SoftChip('Horário hoje', tamanho: 12),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próximo horário',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textoFraco),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      textoProximoHorario(store, p),
                      style: const TextStyle(
                          fontSize: 14.5, color: AppColors.texto),
                    ),
                  ],
                ),
              ),
              if (wide) ...[
                LinkTexto(
                  'Ver página',
                  cor: AppColors.oliva,
                  tamanho: 15,
                  onTap: () => abrirPerfil(context, p),
                ),
                const SizedBox(width: 12),
              ],
              BotaoPill('Agendar',
                  compacto: true,
                  altura: wide ? 38 : null,
                  onPressed: () => abrirPerfil(context, p)),
            ],
          ),
        ],
      ),
    );
  }
}
