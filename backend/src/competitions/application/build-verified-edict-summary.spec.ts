import type { Pool } from 'pg';
import { buildVerifiedEdictSummary } from './build-verified-edict-summary';

describe('verified edital summary', () => {
  const id='11111111-1111-4111-8111-111111111111';
  it('includes exclusively confirmed candidates in reviewed documents',async()=>{
    const query=jest.fn().mockResolvedValue({rows:[
      {source_url:'https://www.gov.br/edital.pdf',document_sha256:'abc',title:'Edital',
        kind:'exam_date',value:'Data da prova: 10 de maio',
        evidence_excerpt:'Data da prova: 10 de maio',source_line:12},
    ]});
    const summary=await buildVerifiedEdictSummary({query} as unknown as Pool,id);
    expect(summary.verifiedFacts).toHaveLength(1);
    expect(summary.verifiedFacts[0].line).toBe(12);
    expect(query.mock.calls[0][0]).toContain("f.review_status='confirmed'");
    expect(query.mock.calls[0][0]).toContain("e.review_status='reviewed'");
  });
  it('returns zero claims if no facts are confirmed',async()=>{
    const query=jest.fn().mockResolvedValue({rows:[{
      source_url:'https://www.gov.br/edital.pdf',document_sha256:'abc',
      title:'Edital',kind:null,value:null,evidence_excerpt:null,source_line:null,
    }]});
    const summary=await buildVerifiedEdictSummary({query} as unknown as Pool,id);
    expect(summary.verifiedFacts).toEqual([]);
  });
  it('fails closed on unreviewed or missing documents',async()=>{
    const query=jest.fn().mockResolvedValue({rows:[]});
    await expect(buildVerifiedEdictSummary({query} as unknown as Pool,id)).rejects.toThrow();
  });
});
