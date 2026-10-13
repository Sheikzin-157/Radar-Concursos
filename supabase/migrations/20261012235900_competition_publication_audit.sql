CREATE TABLE IF NOT EXISTS public_data.competition_publication_audit (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 intake_id uuid NOT NULL REFERENCES public_data.competition_intake(id),
 competition_id uuid NOT NULL REFERENCES public_data.competitions(id),
 reviewer text NOT NULL,
 action text NOT NULL CHECK (action IN ('publish')),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS competition_publication_audit_intake_idx ON public_data.competition_publication_audit(intake_id,created_at DESC);
ALTER TABLE public_data.competition_publication_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public_data.competition_publication_audit FROM anon,authenticated;
CREATE UNIQUE INDEX IF NOT EXISTS competition_published_url_unique ON public_data.competitions (official_url) WHERE official_url IS NOT NULL;
