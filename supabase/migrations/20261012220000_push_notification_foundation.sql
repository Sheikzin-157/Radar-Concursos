-- Device registration for a future push delivery worker. No tokens are exposed to other users.
CREATE TABLE IF NOT EXISTS public.user_push_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  push_token text NOT NULL CHECK (length(push_token) BETWEEN 20 AND 4096),
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, push_token)
);

CREATE INDEX IF NOT EXISTS user_push_devices_user_idx
ON public.user_push_devices(user_id);

ALTER TABLE public.user_push_devices ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.user_push_devices FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_push_devices TO authenticated;

CREATE POLICY "device_read_own" ON public.user_push_devices
FOR SELECT TO authenticated USING (user_id = (SELECT auth.uid()));

CREATE POLICY "device_insert_own" ON public.user_push_devices
FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "device_update_own" ON public.user_push_devices
FOR UPDATE TO authenticated USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "device_delete_own" ON public.user_push_devices
FOR DELETE TO authenticated USING (user_id = (SELECT auth.uid()));

-- Explicit send ledger to prevent duplicate delivery in future workers.
CREATE TABLE IF NOT EXISTS public_data.push_delivery_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id uuid NOT NULL REFERENCES public_data.competition_events(id) ON DELETE CASCADE,
  delivery_type text NOT NULL DEFAULT 'reminder',
  status text NOT NULL CHECK (status IN ('pending', 'sent', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, event_id, delivery_type)
);
ALTER TABLE public_data.push_delivery_ledger ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public_data.push_delivery_ledger FROM anon, authenticated;
