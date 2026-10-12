# Radar Concursos — Mobile

Cliente Flutter do MVP do Radar Concursos.

## Primeira vertical slice

- catálogo público de concursos;
- estados de loading, vazio e erro;
- retry e pull-to-refresh;
- detalhe do concurso;
- navegação declarativa com go_router;
- acesso REST encapsulado com Dio;
- estado assíncrono com Riverpod;
- tratamento do envelope de erro do backend;
- design foundations centralizadas;
- runners Android e iOS versionados.

## Executar localmente

Instale o Flutter estável e, a partir do diretório `mobile`, execute:

```bash
flutter pub get
flutter test
```

Android Emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1
```

iOS Simulator:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/v1
```

Para outros dispositivos ou ambientes, informe uma URL acessível do backend em `API_BASE_URL`. Ambientes não locais devem usar HTTPS.

Não execute `flutter create` sobre esta pasta: os runners nativos e as configurações do aplicativo já fazem parte do repositório.
