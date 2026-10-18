import { sendFcmNotification } from './fcm-delivery';

describe('FCM delivery client', () => {
  it('sends a scoped notification without exposing credentials in the payload', async () => {
    const fetcher = jest.fn().mockResolvedValue({ ok: true });
    await sendFcmNotification({
      credentials: {
        projectId: 'radar-concursos-6692f',
        clientEmail: 'sender@example.test',
        privateKey: 'private',
      },
      token: 'test-device-token',
      title: 'Prazo de inscrição',
      body: 'Confira o edital oficial.',
      competitionId: 'contest-123',
      accessToken: 'mock-access-token',
      fetcher: fetcher as unknown as typeof fetch,
    });
    const [url, options] = fetcher.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://fcm.googleapis.com/v1/projects/radar-concursos-6692f/messages:send');
    expect(options.headers).toMatchObject({ Authorization: 'Bearer mock-access-token' });
    expect(JSON.parse(options.body as string)).toEqual({
      message: {
        token: 'test-device-token',
        notification: { title: 'Prazo de inscrição', body: 'Confira o edital oficial.' },
        data: { competitionId: 'contest-123' },
      },
    });
    expect(options.body).not.toContain('private');
  });

  it('rejects failed FCM requests', async () => {
    await expect(sendFcmNotification({
      credentials: { projectId: 'test', clientEmail: 'a', privateKey: 'b' },
      token: 't', title: 'n', body: 'b', competitionId: 'id',
      accessToken: 'access',
      fetcher: jest.fn().mockResolvedValue({ ok: false, status: 403 }) as unknown as typeof fetch,
    })).rejects.toThrow('HTTP 403');
  });
});
