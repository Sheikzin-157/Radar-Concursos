create table public_data.competitions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public_data.organizations(id) on delete restrict,
  exam_board_id uuid references public_data.exam_boards(id) on delete restrict,
  career_category_id uuid references public_data.career_categories(id) on delete restrict,
  title varchar(255) not null,
  competition_type varchar(80),
  current_status varchar(50) not null,
  government_sphere varchar(30),
  summary text,
  reserve_registration boolean,
  total_vacancies integer,
  salary_min numeric(14,2),
  salary_max numeric(14,2),
  registration_fee_min numeric(12,2),
  registration_fee_max numeric(12,2),
  official_url text,
  published_at timestamptz,
  last_official_update_at timestamptz,
  last_validated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint competitions_total_vacancies_nonnegative check (total_vacancies is null or total_vacancies >= 0),
  constraint competitions_salary_range check (salary_min is null or salary_max is null or salary_min <= salary_max),
  constraint competitions_registration_fee_range check (registration_fee_min is null or registration_fee_max is null or registration_fee_min <= registration_fee_max),
  constraint competitions_salary_min_nonnegative check (salary_min is null or salary_min >= 0),
  constraint competitions_salary_max_nonnegative check (salary_max is null or salary_max >= 0),
  constraint competitions_registration_fee_min_nonnegative check (registration_fee_min is null or registration_fee_min >= 0),
  constraint competitions_registration_fee_max_nonnegative check (registration_fee_max is null or registration_fee_max >= 0)
);

create index idx_competitions_public_updates
  on public_data.competitions (last_official_update_at desc, id)
  where published_at is not null;
create index idx_competitions_organization on public_data.competitions(organization_id);
create index idx_competitions_exam_board on public_data.competitions(exam_board_id);
create index idx_competitions_career on public_data.competitions(career_category_id);
create index idx_competitions_status on public_data.competitions(current_status);
create index idx_competitions_title_trgm on public_data.competitions using gin (title gin_trgm_ops);
