create table public_data.organizations (
  id uuid primary key default gen_random_uuid(),
  official_name varchar(255) not null,
  acronym varchar(50),
  government_sphere varchar(30),
  organization_type varchar(80),
  state_code char(2) references public_data.reference_states(code) on delete restrict,
  official_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public_data.organization_aliases (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public_data.organizations(id) on delete cascade,
  alias varchar(255) not null,
  created_at timestamptz not null default now(),
  unique (organization_id, alias)
);

create table public_data.exam_boards (
  id uuid primary key default gen_random_uuid(),
  official_name varchar(255) not null,
  acronym varchar(50),
  official_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public_data.exam_board_aliases (
  id uuid primary key default gen_random_uuid(),
  exam_board_id uuid not null references public_data.exam_boards(id) on delete cascade,
  alias varchar(255) not null,
  created_at timestamptz not null default now(),
  unique (exam_board_id, alias)
);

create index idx_organizations_state on public_data.organizations(state_code);
create index idx_organizations_name_trgm on public_data.organizations using gin (official_name gin_trgm_ops);
create index idx_exam_boards_name_trgm on public_data.exam_boards using gin (official_name gin_trgm_ops);
