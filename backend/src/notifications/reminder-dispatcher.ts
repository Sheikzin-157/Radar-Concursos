import type { Pool } from 'pg';
import { getFcmAccessToken, readFcmCredentials, sendFcmNotification } from './fcm-delivery';

/**
 * Explicit, server-only dispatcher. No public HTTP route or scheduler is
 * installed. Invoke from a trusted, single-instance job after deployment.
 */
export async function dispatchUpcomingReminders(
  pool: Pool,
  options: { dryRun?: boolean; batchSize?: number } = {},
): Promise<{ eligible: number; sent: number; failed: number }> {
  const credentials = readFcmCredentials();
  if (!credentials && !options.dryRun) {
    throw new Error('FCM credentials are not configured');
  }
  const batchSize = Math.min(Math.max(options.batchSize ?? 50, 1), 100);
  const result = await pool.query<{
    user_id: string; event_id: string; competition_id: string;
    event_title: string; competition_title: string; push_token: string;
  }>(
    `SELECT p.user_id, e.id AS event_id, c.id AS competition_id,
            e.title AS event_title, c.title AS competition_title, d.push_token
       FROM public.user_competition_preferences p
       JOIN public.user_push_devices d ON d.user_id = p.user_id AND d.enabled = true
       JOIN public_data.competition_events e
         ON e.starts_at >= now() AND e.starts_at < now() + interval '24 hours'
       JOIN public_data.competitions c ON c.id = e.competition_id
         AND c.published_at IS NOT NULL
       JOIN public_data.organizations o ON o.id = c.organization_id
       WHERE p.notify_updates = true
         AND (
           (p.preferred_state IS NOT NULL AND o.state_code = p.preferred_state)
           OR EXISTS (
             SELECT 1 FROM public.competition_favorites f
             WHERE f.user_id = p.user_id AND f.competition_id = c.id
           )
         )
         AND NOT EXISTS (
           SELECT 1 FROM public_data.push_delivery_ledger l
           WHERE l.user_id = p.user_id AND l.event_id = e.id
             AND l.delivery_type = 'reminder' AND l.status IN ('pending', 'sent')
         )
       ORDER BY e.starts_at, e.id, p.user_id
       LIMIT $1`,
    [batchSize],
  );
  if (options.dryRun) {
    return { eligible: result.rows.length, sent: 0, failed: 0 };
  }
  if (result.rows.length === 0) return { eligible: 0, sent: 0, failed: 0 };
  const accessToken = await getFcmAccessToken(credentials!);
  let sent = 0;
  let failed = 0;
  for (const row of result.rows) {
    // Atomic claim: concurrent workers cannot send the same event to one user.
    const claim = await pool.query(
      `INSERT INTO public_data.push_delivery_ledger
         (user_id, event_id, delivery_type, status)
       VALUES ($1, $2, 'reminder', 'pending')
       ON CONFLICT (user_id, event_id, delivery_type) DO NOTHING
       RETURNING id`,
      [row.user_id, row.event_id],
    );
    if (!claim.rowCount) continue;
    try {
      await sendFcmNotification({
        credentials: credentials!, accessToken, token: row.push_token,
        title: row.event_title, body: row.competition_title,
        competitionId: row.competition_id,
      });
      await pool.query(
        `UPDATE public_data.push_delivery_ledger SET status='sent' WHERE id=$1`,
        [claim.rows[0].id],
      );
      sent++;
    } catch {
      await pool.query(
        `UPDATE public_data.push_delivery_ledger SET status='failed' WHERE id=$1`,
        [claim.rows[0].id],
      );
      failed++;
    }
  }
  return { eligible: result.rows.length, sent, failed };
}
