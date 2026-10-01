import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatters.dart';
import '../theme.dart';

enum TipoBloco { consulta, nova, cancelada, intervalo, indisponivel }

/// Um bloco na agenda: coluna (dia ou psicólogo), início e fim em minutos.
class ItemGrade {
  const ItemGrade({
    required this.coluna,
    required this.inicio,
    required this.fim,
    required this.tipo,
    this.titulo = '',
    this.subtitulo = '',
    this.extra,
    this.direita,
    this.onTap,
  });

  final int coluna;
  final int inicio;
  final int fim;
  final TipoBloco tipo;
  final String titulo;
  final String subtitulo;
  final String? extra;

  /// Texto à direita no formato de linha do tempo do celular.
  final String? direita;
  final VoidCallback? onTap;
}

(Color, Color?, Color, Color) _cores(TipoBloco tipo) => switch (tipo) {
      TipoBloco.consulta => (
          AppColors.salvia,
          null,
          AppColors.texto,
          AppColors.texto
        ),
      TipoBloco.nova => (
          AppColors.lavandaClaro,
          null,
          AppColors.lavandaEscuro,
          AppColors.lavandaEscuro,
        ),
      TipoBloco.cancelada => (
          Colors.white,
          AppColors.borda,
          AppColors.textoFraco,
          AppColors.vermelho,
        ),
      TipoBloco.intervalo => (
          AppColors.cinzaIndisponivel,
          null,
          AppColors.textoFraco,
          AppColors.textoFraco,
        ),
      TipoBloco.indisponivel => (
          AppColors.cinzaIndisponivel,
          null,
          AppColors.textoFraco,
          AppColors.textoFraco,
        ),
    };

/// Agenda em grade (colunas por dia ou por psicólogo), usada na agenda do
/// psicólogo e na agenda da equipe.
class GradeHoraria extends StatelessWidget {
  const GradeHoraria({
    super.key,
    required this.cabecalhos,
    required this.itens,
    required this.horaInicio,
    required this.horaFim,
    this.alturaHora = 72,
    this.colunaAgora,
    this.minutoAgora,
    this.colunasBloqueadas = const {},
    this.larguraMinColuna = 104,
    this.alturaCabecalho = 76,
    this.agoraEmTodas = false,
  });

  /// Desenha a linha do horário atual em todas as colunas (agenda da equipe).
  final bool agoraEmTodas;

  final List<Widget> cabecalhos;
  final List<ItemGrade> itens;
  final int horaInicio;
  final int horaFim;
  final double alturaHora;
  final int? colunaAgora;
  final int? minutoAgora;

  /// Colunas inteiras sem atendimento, com o texto a mostrar.
  final Map<int, String> colunasBloqueadas;
  final double larguraMinColuna;
  final double alturaCabecalho;

  static const _larguraRotulos = 58.0;
  static const _topo = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = cabecalhos.length;
        final disponivel = c.maxWidth - _larguraRotulos;
        final larguraColuna = math.max(larguraMinColuna, disponivel / n);
        final larguraTotal = _larguraRotulos + larguraColuna * n;
        final horas = horaFim - horaInicio;
        final alturaGrade = horas * alturaHora;
        double y(int minuto) =>
            _topo + (minuto - horaInicio * 60) / 60 * alturaHora;
        double x(int coluna) => _larguraRotulos + coluna * larguraColuna;

        final grade = SizedBox(
          width: larguraTotal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: alturaCabecalho,
                child: Row(
                  children: [
                    const SizedBox(width: _larguraRotulos),
                    for (final h in cabecalhos)
                      SizedBox(width: larguraColuna, child: h),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: alturaGrade + _topo * 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final e in colunasBloqueadas.entries)
                      Positioned(
                        left: x(e.key),
                        top: 0,
                        width: larguraColuna,
                        height: alturaGrade + _topo * 2,
                        child: Container(
                          color: AppColors.cinzaIndisponivel,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            e.value,
                            textAlign: TextAlign.center,
                            style: AppText.fraco,
                          ),
                        ),
                      ),
                    for (var i = 0; i <= horas; i++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: y((horaInicio + i) * 60) - 7,
                        child: Row(
                          children: [
                            SizedBox(
                              width: _larguraRotulos,
                              child: Text(
                                Fmt.minutos((horaInicio + i) * 60),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textoFraco,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(height: 1)),
                          ],
                        ),
                      ),
                    for (var j = 0; j < n; j++)
                      Positioned(
                        left: x(j),
                        top: _topo,
                        height: alturaGrade,
                        child: Container(width: 1, color: AppColors.bordaSuave),
                      ),
                    for (final it in itens)
                      Positioned(
                        left: x(it.coluna) + 4,
                        width: larguraColuna - 8,
                        top: y(it.inicio) + 2,
                        height: math.max(24, y(it.fim) - y(it.inicio) - 4),
                        child: BlocoGrade(item: it),
                      ),
                    if (colunaAgora != null &&
                        minutoAgora != null &&
                        minutoAgora! >= horaInicio * 60 &&
                        minutoAgora! <= horaFim * 60)
                      Positioned(
                        left: agoraEmTodas
                            ? _larguraRotulos - 4
                            : x(colunaAgora!) - 4,
                        top: y(minutoAgora!) - 4,
                        width: agoraEmTodas
                            ? larguraColuna * n + 4
                            : larguraColuna + 4,
                        child: IgnorePointer(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.vermelho,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                    height: 2, color: AppColors.vermelho),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (larguraTotal > c.maxWidth + 0.5) {
          return SingleChildScrollView(
              scrollDirection: Axis.horizontal, child: grade);
        }
        return grade;
      },
    );
  }
}

/// Bloco de consulta, intervalo ou período indisponível na grade.
class BlocoGrade extends StatelessWidget {
  const BlocoGrade({super.key, required this.item});

  final ItemGrade item;

  @override
  Widget build(BuildContext context) {
    final (fundo, borda, corTitulo, corSub) = _cores(item.tipo);
    final neutro =
        item.tipo == TipoBloco.intervalo || item.tipo == TipoBloco.indisponivel;
    final cancelada = item.tipo == TipoBloco.cancelada;
    final conteudo = neutro
        ? Center(
            child: Text(
              item.titulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: corTitulo),
            ),
          )
        : ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              maxHeight: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: corTitulo,
                      fontWeight: FontWeight.w400,
                      decoration: cancelada ? TextDecoration.lineThrough : null,
                      decorationColor: corTitulo,
                    ),
                  ),
                  // Em colunas estreitas o texto encolhe um pouco em vez de
                  // cortar ("10:00 · Presencial" do wireframe 09).
                  if (item.subtitulo.isNotEmpty)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.subtitulo,
                        maxLines: 1,
                        style: TextStyle(fontSize: 11, color: corSub),
                      ),
                    ),
                  if (item.extra != null)
                    Text(
                      item.extra!,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11.5, color: corSub),
                    ),
                ],
              ),
            ),
          );
    return Semantics(
      button: item.onTap != null,
      label: [item.titulo, item.subtitulo, item.extra ?? '']
          .where((s) => s.isNotEmpty)
          .join(', '),
      excludeSemantics: true,
      child: Material(
        color: fundo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: borda == null ? BorderSide.none : BorderSide(color: borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: conteudo,
          ),
        ),
      ),
    );
  }
}

/// Linha do tempo de um dia, no formato do celular (horas à esquerda).
class LinhaDoTempoDia extends StatelessWidget {
  const LinhaDoTempoDia({
    super.key,
    required this.itens,
    required this.horaInicio,
    required this.horaFim,
    this.alturaHora = 40,
    this.minutoAgora,
  });

  final List<ItemGrade> itens;
  final int horaInicio;
  final int horaFim;
  final double alturaHora;
  final int? minutoAgora;

  static const _larguraRotulos = 48.0;

  @override
  Widget build(BuildContext context) {
    final horas = horaFim - horaInicio;
    double y(int minuto) => (minuto - horaInicio * 60) / 60 * alturaHora + 6;
    return SizedBox(
      height: horas * alturaHora + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i <= horas; i++)
            Positioned(
              left: 0,
              top: y((horaInicio + i) * 60) - 8,
              child: Text(
                Fmt.minutos((horaInicio + i) * 60),
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textoFraco),
              ),
            ),
          for (final it in itens) _item(it, y),
          if (minutoAgora != null &&
              minutoAgora! >= horaInicio * 60 &&
              minutoAgora! <= horaFim * 60)
            Positioned(
              left: _larguraRotulos - 4,
              right: 0,
              top: y(minutoAgora!) - 4,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.vermelho,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                        child: Container(height: 2, color: AppColors.vermelho)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _item(ItemGrade it, double Function(int) y) {
    final neutro =
        it.tipo == TipoBloco.intervalo || it.tipo == TipoBloco.indisponivel;
    final (fundo, borda, corTitulo, corSub) = _cores(it.tipo);
    final topo = y(it.inicio);
    final altura =
        math.max(28.0, math.min(y(it.fim) - topo - 2, alturaHora * 0.8));
    final cancelada = it.tipo == TipoBloco.cancelada;
    final linha = Row(
      children: [
        Expanded(
          child: Text(
            it.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: corTitulo,
              decoration: cancelada ? TextDecoration.lineThrough : null,
              decorationColor: corTitulo,
            ),
          ),
        ),
        if (it.direita != null)
          Text(it.direita!, style: TextStyle(fontSize: 12.5, color: corSub)),
      ],
    );
    return Positioned(
      left: _larguraRotulos + 4,
      right: 0,
      top: topo,
      height: altura,
      child: Semantics(
        button: it.onTap != null,
        label: '${it.titulo}, ${it.direita ?? ''}',
        excludeSemantics: true,
        child: Material(
          color: neutro ? Colors.transparent : fundo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borda == null ? BorderSide.none : BorderSide(color: borda),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: it.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(alignment: Alignment.centerLeft, child: linha),
            ),
          ),
        ),
      ),
    );
  }
}
