CREATE TABLE IF NOT EXISTS public.user_competition_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  preferred_state char(2),
  notify_updates boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_competition_preferences ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_competition_preferences TO authenticated;
CREATE POLICY "preferences_select_own" ON public.user_competition_preferences
FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));
CREATE POLICY "preferences_insert_own" ON public.user_competition_preferences
FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "preferences_update_own" ON public.user_competition_preferences
FOR UPDATE TO authenticated USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));
CREATE POLICY "preferences_delete_own" ON public.user_competition_preferences
FOR DELETE TO authenticated USING (user_id = (SELECT auth.uid()));
