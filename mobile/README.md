# Radar Concursos — Mobile

Cliente Flutter do MVP.

## Primeira vertical slice

- catálogo público de concursos;
- estados de loading, vazio e erro;
- detalhe do concurso;
- navegação declarativa;
- acesso REST encapsulado em camada de dados;
- estado com Riverpod;
- design foundations centralizadas.

## Ambiente

A API é configurada por compile-time define.

Android Emulator:

    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/v1

iOS Simulator:

    flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/v1

Os runners nativos podem ser gerados no diretório mobile com:

    flutter create . --platforms=android,ios

Esse comando não deve substituir os arquivos em lib/.
