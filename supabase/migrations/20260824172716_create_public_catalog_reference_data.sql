create table public_data.reference_states (
  code char(2) primary key,
  name varchar(80) not null unique,
  created_at timestamptz not null default now()
);

create table public_data.career_categories (
  id uuid primary key default gen_random_uuid(),
  code varchar(80) not null unique,
  name varchar(120) not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_career_categories_active_name
  on public_data.career_categories (active, name);
