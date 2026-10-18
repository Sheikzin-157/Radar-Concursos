ALTER TABLE public_data.competition_intake
ADD COLUMN IF NOT EXISTS reviewed_by text;
