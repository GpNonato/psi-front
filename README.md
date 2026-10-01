# PsiHub App

Front-end do PsiHub em Flutter (web e mobile, mesmo código). Estrutura base criada
pela issue [A2](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2026-2-ti5-0492100-psihub/issues/2); telas de cada trilha são preenchidas pelas issues
B1, B2 e B3.

## Validado

`flutter pub get`, `flutter analyze`, `flutter test` e `flutter build web` rodam sem
erro (Flutter 3.47.5 estável). Faltam plugins nativos: as pastas `android/` e `ios/`
foram geradas pelo `flutter create`, mas ainda não foram testadas em emulador/device
real.

## Estrutura

- `lib/main.dart` : navegação entre as três telas principais.
- `lib/features/perfil_busca/` : perfil de psicólogo/clínica e busca (issue [B2](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2026-2-ti5-0492100-psihub/issues/4))
- `lib/features/agenda_agendamento/` : agenda e agendamento de consulta (issue [B3](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2026-2-ti5-0492100-psihub/issues/5))
- `lib/features/painel_psicologo/` : painel do psicólogo (componente A3 da
  [seção 5.2 da documentação](../../docs/5.modelagem.md#modelagem), sem issue própria ainda)

## Como rodar

```bash
flutter pub get
flutter run -d chrome   # web
flutter run              # dispositivo/emulador conectado
```
