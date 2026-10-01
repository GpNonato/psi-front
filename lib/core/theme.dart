import 'package:flutter/material.dart';

/// Paleta dos wireframes (seção 6 da documentação).
abstract final class AppColors {
  static const creme = Color(0xFFF2F1EA);
  static const cremeEscuro = Color(0xFFEAE9DF);
  static const oliva = Color(0xFF4F5D2F);
  static const olivaEscuro = Color(0xFF3B4422);

  /// Texto e ícone do item selecionado no menu lateral (sobre a sálvia).
  static const olivaTexto = Color(0xFF30381C);
  static const salvia = Color(0xFFE4E8D3);
  static const salviaForte = Color(0xFFD3D7BB);
  static const placeholder = Color(0xFFE4E2D6);
  static const borda = Color(0xFFDFDDD3);
  static const bordaSuave = Color(0xFFEBE9E1);
  static const texto = Color(0xFF1D1D19);
  static const textoSecundario = Color(0xFF5E5C53);
  static const textoFraco = Color(0xFFA6A396);
  static const lavanda = Color(0xFF635599);
  static const lavandaEscuro = Color(0xFF4E427B);
  static const lavandaClaro = Color(0xFFE6E2F3);
  static const lavandaBorda = Color(0xFFC6BEE4);
  static const estrela = Color(0xFF7465B5);
  static const verde = Color(0xFF2E7D5B);
  static const verdeClaro = Color(0xFFE2F0E7);
  static const ambar = Color(0xFF9A6A12);
  static const vermelho = Color(0xFFB3261E);
  static const azul = Color(0xFF2F6690);
  static const cinzaIndisponivel = Color(0xFFF7F7F2);

  /// Fundo escurecido atrás de diálogos e folhas inferiores: a cor do texto a
  /// 45%, como nos wireframes (mais claro que o preto a 54% do Flutter).
  static const veu = Color(0x731D1D19);
}

/// Estilos de texto. Títulos usam a Fraunces, como nos wireframes; o corpo usa
/// a fonte padrão.
abstract final class AppText {
  static const serifFamily = 'Fraunces';

  /// Título serifado. [familia] troca a fonte (ex.: a escolhida pelo
  /// psicólogo para a própria página).
  static TextStyle serif(
    double tamanho, {
    Color cor = AppColors.texto,
    bool italico = false,
    double altura = 1.15,
    String familia = serifFamily,
  }) =>
      TextStyle(
        fontFamily: familia,
        fontSize: tamanho,
        color: cor,
        fontStyle: italico ? FontStyle.italic : FontStyle.normal,
        fontWeight: FontWeight.w400,
        height: altura,
        // A Fraunces é variável: o tamanho óptico acompanha o tamanho do
        // texto, como o Figma faz no modo automático dos wireframes.
        fontVariations: familia == serifFamily
            ? [
                FontVariation('opsz', tamanho.clamp(9, 144).toDouble()),
                const FontVariation('wght', 400),
              ]
            : null,
      );

  static const rotulo = TextStyle(
    fontSize: 12.5,
    color: AppColors.textoSecundario,
  );
  static const pequeno = TextStyle(
    fontSize: 13,
    color: AppColors.textoSecundario,
    height: 1.35,
  );
  static const corpo = TextStyle(
    fontSize: 15,
    color: AppColors.texto,
    height: 1.5,
  );
  static const fraco = TextStyle(fontSize: 12, color: AppColors.textoFraco);
  static const tituloCartao = TextStyle(
    fontSize: 18,
    color: AppColors.texto,
    fontWeight: FontWeight.w400,
  );
}

/// Cores que o psicólogo pode escolher para a própria página (RF003).
const temasDePagina = <(String, Color)>[
  ('Oliva', Color(0xFF4F5D2F)),
  ('Floresta', Color(0xFF1F4D3A)),
  ('Eucalipto', Color(0xFF3A7A68)),
  ('Musgo', Color(0xFF3D5A3A)),
  ('Lavanda', Color(0xFF6A5AA6)),
  ('Grafite', Color(0xFF3A3A38)),
];

/// Fontes de título oferecidas na tela Minha página (RF029).
const fontesDeTitulo = ['Fraunces', 'Lora', 'DM Serif'];

/// Família (declarada no pubspec) de cada fonte de [fontesDeTitulo].
const familiasDeTitulo = ['Fraunces', 'Lora', 'DMSerifDisplay'];

/// Família dos títulos de uma página, conforme a fonte escolhida.
String familiaDoTema(int indice) =>
    familiasDeTitulo[indice.clamp(0, familiasDeTitulo.length - 1)];

Color corDoTema(int indice) =>
    temasDePagina[indice.clamp(0, temasDePagina.length - 1)].$2;

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: AppColors.oliva,
    primary: AppColors.oliva,
    onPrimary: Colors.white,
    secondary: AppColors.lavanda,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.texto,
    error: AppColors.vermelho,
    outline: AppColors.borda,
    outlineVariant: AppColors.bordaSuave,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: AppColors.creme,
    splashFactory: InkRipple.splashFactory,
    // Mesmas medidas em qualquer plataforma: sem isso, o Chrome no Windows
    // usa densidade compacta e encolhe botões e campos em relação ao
    // desenho dos wireframes.
    visualDensity: VisualDensity.standard,
    // No Windows o padrão seria "Segoe UI", que o Flutter web não tem e troca
    // pelo Roboto; fixar a família deixa as medidas iguais em todo lugar.
    fontFamily: 'Roboto',
  );
  const bordaCampo = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.borda),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.texto,
      displayColor: AppColors.texto,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.bordaSuave,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(color: AppColors.textoFraco, fontSize: 14.5),
      border: bordaCampo,
      enabledBorder: bordaCampo,
      disabledBorder: bordaCampo,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.oliva, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.vermelho),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.vermelho, width: 1.5),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? AppColors.oliva : Colors.white,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: WidgetStateBorderSide.resolveWith(
        (s) => BorderSide(
          color: s.contains(WidgetState.selected)
              ? AppColors.oliva
              : const Color(0xFFC9C6B8),
          width: 1.5,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.oliva
            : const Color(0xFFD6D3C6),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(
        Icon(Icons.circle, color: Colors.transparent),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      barrierColor: AppColors.veu,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: AppColors.veu,
      showDragHandle: true,
      dragHandleColor: AppColors.salviaForte,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33000000),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.bordaSuave),
      ),
      textStyle: const TextStyle(fontSize: 14.5, color: AppColors.texto),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2E3322),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.salvia,
      height: 68,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          color: s.contains(WidgetState.selected)
              ? AppColors.texto
              : AppColors.textoSecundario,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 22,
          color: s.contains(WidgetState.selected)
              ? AppColors.texto
              : AppColors.textoSecundario,
        ),
      ),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.salvia,
      headerForegroundColor: AppColors.texto,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 500),
    ),
  );
}
