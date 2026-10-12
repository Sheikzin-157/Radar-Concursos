# Radar Concursos Backend

## Worker de lembretes FCM (MVP)

O banco usa `public_data.competition_events`, preferências com opt-in,
dispositivos registrados e `public_data.push_delivery_ledger`.

**Simulação local (sem disparos):**
```bash
npm run reminders:dry-run
```

**Envio real (somente operador autorizado, após configurar o serviço):**
```bash
ENABLE_PUSH_DELIVERY=true npm run reminders:send
```

Variáveis *apenas do servidor*: `DATABASE_URL`, `DATABASE_SSL`,
`FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL` e `FCM_PRIVATE_KEY`.
Nunca colocar a chave privada no aplicativo, no repositório ou em `--dart-define`.
O comando de envio permanece bloqueado por padrão, não foi agendado e não
possui rota pública. O worker seleciona eventos oficiais nas próximas 24 horas,
respeita preferências e evita duplicar envios de um mesmo evento para um usuário.

Por segurança, falhas de envio não são repetidas automaticamente, pois uma
resposta de timeout pode ocorrer depois de o FCM aceitar a mensagem.
Reprocessar falhas exige reconciliação manual. Nesta versão, somente o dispositivo
ativo mais recentemente atualizado de cada usuário recebe o lembrete.
Para múltiplos dispositivos, ampliar a granularidade do ledger antes de habilitar
envios gerais.

Antes de produção: configurar scheduler autenticado (execução única), credenciais
em gerenciador de segredos, métricas, limites de taxa e teste em dispositivo
real. A simulação **não** comprova entrega real.

