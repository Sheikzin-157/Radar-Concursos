-- Personalized in-app alerts. No push delivery or background scheduler is enabled.
CREATE OR REPLACE FUNCTION public.my_upcoming_competition_alerts()
RETURNS TABLE (
  event_id uuid,
  competition_id uuid,
  competition_title text,
  event_title text,
  event_type text,
  starts_at timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
  SELECT e.id, c.id, c.title::text, e.title::text, e.event_type::text, e.starts_at
  FROM public.user_competition_preferences p
  JOIN public_data.competition_events e ON
    e.starts_at >= now() AND e.starts_at < now() + interval '14 days'
  JOIN public_data.competitions c ON c.id = e.competition_id
    AND c.published_at IS NOT NULL
  JOIN public_data.organizations o ON o.id = c.organization_id
  WHERE p.user_id = (SELECT auth.uid())
    AND p.notify_updates = true
    AND (
      (p.preferred_state IS NOT NULL AND o.state_code = p.preferred_state)
      OR EXISTS (
        SELECT 1 FROM public.competition_favorites f
        WHERE f.user_id = p.user_id AND f.competition_id = c.id
      )
    )
  ORDER BY e.starts_at ASC, e.id ASC
  LIMIT 100;
$$;

REVOKE ALL ON FUNCTION public.my_upcoming_competition_alerts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.my_upcoming_competition_alerts() TO authenticated;
