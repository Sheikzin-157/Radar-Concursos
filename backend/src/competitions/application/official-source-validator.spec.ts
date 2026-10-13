import { validateOfficialCompetitionDraft } from './official-source-validator';

const valid = {
  organizationName: 'Órgão de teste',
  title: 'Concurso de teste',
  officialUrl: 'https://www.example.gov.br/edital',
  status: 'open',
  stateCode: 'CE',
  sourceCheckedAt: '2026-10-11T12:00:00Z',
};

describe('official competition intake validation', () => {
  it('keeps the official reference and verifiable fields', () => {
    expect(validateOfficialCompetitionDraft(valid)).toEqual(valid);
  });

  it.each([
    [{ ...valid, officialUrl: 'http://www.example.gov.br' }, 'http'],
    [{ ...valid, officialUrl: 'https://user:pass@example.gov.br' }, 'credentials'],
    [{ ...valid, stateCode: 'XX' }, 'state'],
    [{ ...valid, sourceCheckedAt: '2099-01-01T00:00:00Z' }, 'future'],
    [{ ...valid, title: '' }, 'empty'],
  ])('rejects invalid source data: %s (%s)', (record) => {
    expect(() => validateOfficialCompetitionDraft(record)).toThrow();
  });
});
