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

A API publica do Railway e o ambiente padrao do app sao:

```text
https://radar-concursos-backend-production.up.railway.app/v1
```

Para executar no dispositivo usando a API hospedada:

```bash
flutter run
```

Para gerar um APK de teste conectado ao Railway:

```bash
flutter build apk --debug
```

O APK fica em `build/app/outputs/flutter-apk/app-debug.apk`. Sem concursos publicados, a tela inicial mostra corretamente o estado vazio.

Para desenvolver com um backend local, sobrescreva `API_BASE_URL`:

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

## Notificações Firebase (Android e iOS)

A integração Flutter FCM está preparada, mas exige um projeto Firebase
registrado para o pacote Android `br.com.radarconcursos.radar_concursos`
e o identificador iOS correspondente. Configure o projeto no Firebase Console
e associe os aplicativos Android e iOS conforme o guia oficial do FlutterFire.

Defina os valores públicos por `--dart-define` (não commite credenciais
privadas):

- `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY`;
- `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`,
  `FIREBASE_PROJECT_ID` e `FIREBASE_IOS_BUNDLE_ID` quando aplicável.

Siga os requisitos nativos do Firebase para Google Services no Android,
e no iOS configure APNs, Push Notifications e Background Modes. O SDK
não inicia o registro FCM durante a inicialização do app: o usuário
precisa habilitar os alertas, salvar a preferência e acionar
**Ativar notificações neste celular**. A autorização do sistema
operacional é solicitada somente nesse fluxo.

O serviço de **envio automático** ainda precisa de um worker com
credenciais de servidor FCM HTTP v1 protegidas; nunca armazene uma
chave de serviço Firebase no aplicativo Flutter nem no GitHub.
