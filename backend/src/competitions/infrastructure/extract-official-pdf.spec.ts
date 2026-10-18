import pdfParse from 'pdf-parse';
import type { Pool } from 'pg';
import { extractOfficialPdf } from './extract-official-pdf';

jest.mock('pdf-parse', () => ({ __esModule: true, default: jest.fn() }));

const mockParse = pdfParse as jest.MockedFunction<typeof pdfParse>;
const pdf = Buffer.concat([Buffer.from('%PDF-1.7\n'), Buffer.alloc(40)]);

function fakeResponse(data: Buffer = pdf) {
  return {
    ok: true,
    headers: { get: (_: string) => String(data.length) },
    arrayBuffer: async () => data,
  };
}

describe('official PDF extraction', () => {
  const source = 'https://www.gov.br/gestao/edital.pdf';
  const pool = { query: jest.fn().mockResolvedValue({rows:[{id:'a'}]}) } as unknown as Pool;
  beforeEach(() => {
    jest.clearAllMocks();
    mockParse.mockResolvedValue({text:'Edital oficial extraído',numpages:2} as Awaited<ReturnType<typeof pdfParse>>);
  });

  it('dry-runs PDF extraction without persisting private evidence', async () => {
    const fetcher = jest.fn().mockResolvedValue(fakeResponse());
    const result = await extractOfficialPdf(pool,source,'Edital', {
      dryRun:true,fetcher:fetcher as unknown as typeof fetch,
    });
    expect(result).toMatchObject({pages:2,staged:false});
    expect(result.sha256).toMatch(/^[a-f0-9]{64}$/);
    expect(pool.query).not.toHaveBeenCalled();
  });

  it('stages extracted text privately and deduplicates by document hash', async () => {
    const fetcher = jest.fn().mockResolvedValue(fakeResponse());
    await extractOfficialPdf(pool,source,'Edital',{
      fetcher:fetcher as unknown as typeof fetch,
    });
    expect((pool.query as jest.Mock).mock.calls[0][0]).toContain('public_data.notice_evidence');
  });

  it('rejects untrusted sources and invalid PDF bytes', async () => {
    const fetcher = jest.fn().mockResolvedValue(fakeResponse(Buffer.from('html')));
    await expect(extractOfficialPdf(pool,source,'Edital',{
      fetcher:fetcher as unknown as typeof fetch,
    })).rejects.toThrow('supported PDF');
    await expect(extractOfficialPdf(pool,'https://example.com/edital.pdf','Edital',{
      fetcher:fetcher as unknown as typeof fetch,
    })).rejects.toThrow();
  });
});
