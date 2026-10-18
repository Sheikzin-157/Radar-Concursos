-- Raw official-source submissions are private and never exposed as published competitions.
CREATE TABLE IF NOT EXISTS public_data.competition_intake (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 organization_name varchar(255) NOT NULL,
 title varchar(255) NOT NULL,
 official_url text NOT NULL UNIQUE,
 status varchar(50) NOT NULL,
 state_code char(2) NOT NULL REFERENCES public_data.reference_states(code),
 source_checked_at timestamptz NOT NULL,
 review_status text NOT NULL DEFAULT 'pending'
  CHECK (review_status IN ('pending','approved','rejected')),
 reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS competition_intake_review_idx
 ON public_data.competition_intake (review_status, created_at);
ALTER TABLE public_data.competition_intake ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public_data.competition_intake FROM anon, authenticated;
