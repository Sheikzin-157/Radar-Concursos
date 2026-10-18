CREATE TABLE IF NOT EXISTS public_data.competition_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES public_data.competitions(id) ON DELETE CASCADE,
  event_type varchar(50) NOT NULL,
  title varchar(200) NOT NULL,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  official_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT competition_events_dates_valid CHECK (ends_at IS NULL OR ends_at >= starts_at),
  CONSTRAINT competition_events_type_valid CHECK (event_type IN (
    'registration_open', 'registration_close', 'exam', 'results', 'appeal', 'other'
  ))
);
CREATE INDEX IF NOT EXISTS competition_events_by_date
  ON public_data.competition_events (starts_at, id);
CREATE INDEX IF NOT EXISTS competition_events_by_competition
  ON public_data.competition_events (competition_id, starts_at);
