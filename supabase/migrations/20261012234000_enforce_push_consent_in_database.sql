-- Enforce notification consent at the database boundary, not only in Flutter.
DROP POLICY IF EXISTS "device_insert_own" ON public.user_push_devices;
CREATE POLICY "device_insert_own" ON public.user_push_devices
FOR INSERT TO authenticated
WITH CHECK (
  user_id = (SELECT auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_competition_preferences p
    WHERE p.user_id = (SELECT auth.uid()) AND p.notify_updates = true
  )
);
DROP POLICY IF EXISTS "device_update_own" ON public.user_push_devices;
CREATE POLICY "device_update_own" ON public.user_push_devices
FOR UPDATE TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (
  user_id = (SELECT auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.user_competition_preferences p
    WHERE p.user_id = (SELECT auth.uid()) AND p.notify_updates = true
  )
);
-- Disable stored tokens atomically when a user opts out.
CREATE OR REPLACE FUNCTION public_data.disable_push_tokens_on_opt_out()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  IF NEW.notify_updates = false THEN
    UPDATE public.user_push_devices
       SET enabled = false, updated_at = now()
     WHERE user_id = NEW.user_id AND enabled = true;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public_data.disable_push_tokens_on_opt_out() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS preference_push_opt_out ON public.user_competition_preferences;
CREATE TRIGGER preference_push_opt_out
AFTER INSERT OR UPDATE OF notify_updates ON public.user_competition_preferences
FOR EACH ROW EXECUTE FUNCTION public_data.disable_push_tokens_on_opt_out();
