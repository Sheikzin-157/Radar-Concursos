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


## Railway — primeira implantação do backend

1. No Railway, conecte o repositório `Sheikzin-157/Radar-Concursos` e selecione a branch `feat/mobile-foundation` (não implantar `main` ainda).
2. No serviço, defina **Root Directory** como `/backend`. O Railway detectará `backend/Dockerfile` como `Dockerfile` na raiz do serviço.
3. Adicione no painel de variáveis do serviço `DATABASE_URL` (connection string PostgreSQL obtida do Supabase). Adicione `DATABASE_SSL=true` se for necessário SSL. Nunca comite senhas de banco nem chaves privadas.
4. Configure o Healthcheck Path como `/health/ready` e gere um domínio público HTTPS em Networking. A aplicação escuta a variável `PORT` fornecida pela Railway.
5. Depois do deploy, valide `https://SEU-DOMINIO/health/ready` e `https://SEU-DOMINIO/v1/competitions?limit=1`. Com `API_BASE_URL=https://SEU-DOMINIO/v1`, execute `npm run smoke:api` no diretório `backend`.
6. Passe a URL `https://SEU-DOMINIO/v1` ao Flutter por `--dart-define=API_BASE_URL=https://SEU-DOMINIO/v1`.

O serviço **não** exige variáveis Firebase para listar concursos. Mantenha `ENABLE_PUSH_DELIVERY`, `ENABLE_CATALOG_ADMIN` e `ENABLE_OFFICIAL_SOURCE_INTAKE` desativadas na primeira implantação. O domínio só será utilizável por usuários quando houver concursos oficiais efetivamente revisados e publicados.

