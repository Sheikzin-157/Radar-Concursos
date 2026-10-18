import { buildNoticeEvidence } from './notice-evidence';

describe('notice evidence', () => {
  const input = {
    sourceUrl: 'https://www.gov.br/gestao/edital.pdf',
    title: 'Edital do concurso',
    bytes: Buffer.from('documento oficial'),
    text: 'Inscrições e provas conforme edital.',
    observedAt: '2026-10-12T12:00:00.000Z',
  };
  it('records a stable SHA-256 fingerprint for auditing', () => {
    const result = buildNoticeEvidence(input);
    expect(result.documentSha256).toMatch(/^[a-f0-9]{64}$/);
    expect(buildNoticeEvidence(input).documentSha256).toBe(result.documentSha256);
    expect(result.sourceUrl).toBe(input.sourceUrl);
  });
  it('rejects untrusted origins and oversized files', () => {
    expect(() => buildNoticeEvidence({...input,sourceUrl:'https://example.com/a.pdf'})).toThrow();
    expect(() => buildNoticeEvidence({...input,bytes:Buffer.alloc(10_000_001)})).toThrow();
  });
});
