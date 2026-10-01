{{flutter_js}}
{{flutter_build_config}}

// O servidor de desenvolvimento não manda cabeçalhos de cache, e o navegador
// chegava a reaproveitar um main.dart.js antigo depois de um novo build. Um
// parâmetro diferente a cada carregamento garante que a versão atual seja usada.
(function () {
  var versao = Date.now().toString(36);
  var builds = (_flutter.buildConfig && _flutter.buildConfig.builds) || [];
  for (var i = 0; i < builds.length; i++) {
    if (builds[i].mainJsPath) {
      builds[i].mainJsPath += '?v=' + versao;
    }
  }
})();

_flutter.loader.load();
