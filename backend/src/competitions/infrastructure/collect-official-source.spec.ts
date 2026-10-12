import type { Pool } from 'pg';
import { collectOfficialSource } from './collect-official-source';

const source = {
  name: 'Fonte governamental de teste',
  url: 'https://concursos.example.gov.br/api/editais',
  organizationName: 'Órgão de teste',
  stateCode: 'CE',
  status: 'open',
};
const data = [{
  title: 'Concurso público de teste',
  officialUrl: 'https://concursos.example.gov.br/edital',
}];

describe('official source collector', () => {
  it('validates a JSON feed in dry run without database writes', async () => {
    const fetcher = jest.fn().mockResolvedValue({
      ok: true, headers: { get: () => 'application/json' },
      json: async () => data,
    });
    const query = jest.fn();
    const result = await collectOfficialSource(
      {query} as unknown as Pool, source,
      {dryRun: true, fetcher: fetcher as unknown as typeof fetch},
    );
    expect(result).toEqual({examined: 1, staged: 0});
    expect(query).not.toHaveBeenCalled();
    expect(fetcher.mock.calls[0][1]).toMatchObject({redirect:'error'});
  });

  it('stages reviewed-source candidates and never directly publishes', async () => {
    const fetcher = jest.fn().mockResolvedValue({
      ok: true, headers: { get: () => 'application/json' },
      json: async () => data,
    });
    const query = jest.fn().mockResolvedValue({rows:[{id:'id',review_status:'pending'}]});
    const result = await collectOfficialSource(
      {query} as unknown as Pool, source,
      {fetcher: fetcher as unknown as typeof fetch},
    );
    expect(result.staged).toBe(1);
    expect(query.mock.calls[0][0]).toContain('public_data.competition_intake');
    expect(query.mock.calls[0][0]).not.toContain('published_at');
  });

  it('rejects external hosts, HTTP and redirects', async () => {
    const fetcher = jest.fn();
    const pool = {query:jest.fn()} as unknown as Pool;
    for (const url of ['http://example.gov.br/api','https://example.com/api',
      'https://evilgov.br.example.com/api']) {
      await expect(collectOfficialSource(pool,{...source,url},{
        fetcher: fetcher as unknown as typeof fetch,
      })).rejects.toThrow();
    }
    expect(fetcher).not.toHaveBeenCalled();
  });
});
