CREATE TABLE IF NOT EXISTS public_data.notice_fact_candidates (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 evidence_id uuid NOT NULL REFERENCES public_data.notice_evidence(id) ON DELETE CASCADE,
 kind text NOT NULL CHECK (kind IN ('registration_period','exam_date','vacancies','salary')),
 value text NOT NULL,
 evidence_excerpt text NOT NULL,
 source_line integer NOT NULL CHECK (source_line > 0),
 review_status text NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending','confirmed','rejected')),
 reviewed_by text,
 reviewed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (evidence_id,kind,source_line,value)
);
CREATE INDEX IF NOT EXISTS notice_fact_candidates_review_idx
 ON public_data.notice_fact_candidates(review_status,created_at);
ALTER TABLE public_data.notice_fact_candidates ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public_data.notice_fact_candidates FROM anon,authenticated;
