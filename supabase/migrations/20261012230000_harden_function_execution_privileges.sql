-- Restrict exposed SECURITY DEFINER functions.
REVOKE EXECUTE ON FUNCTION public.is_published_competition(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.my_upcoming_competition_alerts() FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
