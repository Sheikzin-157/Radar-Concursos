CREATE TABLE IF NOT EXISTS public_data.notice_evidence (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 source_url text NOT NULL,
 title varchar(255) NOT NULL,
 document_sha256 char(64) NOT NULL,
 extracted_text text NOT NULL,
 observed_at timestamptz NOT NULL,
 review_status text NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending','reviewed','rejected')),
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE (source_url,document_sha256),
 CONSTRAINT notice_evidence_text_size CHECK (length(extracted_text) <= 500000)
);
CREATE INDEX IF NOT EXISTS notice_evidence_review_idx ON public_data.notice_evidence(review_status,created_at);
ALTER TABLE public_data.notice_evidence ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public_data.notice_evidence FROM anon,authenticated;
