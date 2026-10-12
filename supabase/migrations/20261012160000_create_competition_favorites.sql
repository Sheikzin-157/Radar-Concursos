-- Favorites are private to the signed-in user.
CREATE TABLE IF NOT EXISTS public.competition_favorites (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  competition_id uuid NOT NULL REFERENCES public_data.competitions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, competition_id)
);

CREATE INDEX IF NOT EXISTS competition_favorites_user_created_idx
  ON public.competition_favorites (user_id, created_at DESC);

ALTER TABLE public.competition_favorites ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.competition_favorites FROM anon;
GRANT SELECT, INSERT, DELETE ON public.competition_favorites TO authenticated;

CREATE POLICY "favorites_read_own"
  ON public.competition_favorites FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- SECURITY DEFINER avoids exposing unpublished catalog rows to authenticated clients.
CREATE OR REPLACE FUNCTION public.is_published_competition(target_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public_data.competitions c
    WHERE c.id = target_id AND c.published_at IS NOT NULL
  );
$$;

REVOKE ALL ON FUNCTION public.is_published_competition(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_published_competition(uuid) TO authenticated;

CREATE POLICY "favorites_insert_own_published"
  ON public.competition_favorites FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = user_id AND
    public.is_published_competition(competition_id)
  );

CREATE POLICY "favorites_delete_own"
  ON public.competition_favorites FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);
