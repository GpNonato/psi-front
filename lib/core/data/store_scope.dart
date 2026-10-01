import 'package:flutter/widgets.dart';

import 'app_store.dart';

/// Disponibiliza o [AppStore] para a árvore de widgets.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  static AppStore _de(BuildContext context, {required bool ouvir}) {
    final scope = ouvir
        ? context.dependOnInheritedWidgetOfExactType<StoreScope>()
        : context.getInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope não encontrado na árvore de widgets.');
    return scope!.notifier!;
  }
}

extension StoreContext on BuildContext {
  /// Lê o estado e reconstrói o widget quando ele mudar.
  AppStore get store => StoreScope._de(this, ouvir: true);

  /// Lê o estado sem se inscrever (para ações em callbacks).
  AppStore get acoes => StoreScope._de(this, ouvir: false);
}
