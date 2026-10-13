import type { Pool } from 'pg';
import { reviewNoticeFact, stageNoticeFacts } from './stage-notice-facts';

describe('edital fact staging and moderation', () => {
  const id='11111111-1111-4111-8111-111111111111';
  it('stages extracted candidates with cited lines',async()=>{
    const query=jest.fn().mockResolvedValueOnce({
      rows:[{extracted_text:'Inscrições de 01 a 10 de março'}],
    }).mockResolvedValueOnce({rowCount:1});
    await expect(stageNoticeFacts({query} as unknown as Pool,id)).resolves.toBe(1);
    expect(query.mock.calls[1][0]).toContain('notice_fact_candidates');
    expect(query.mock.calls[1][1][4]).toBe(1);
  });
  it('does not overwrite a reviewed decision',async()=>{
    const query=jest.fn().mockResolvedValue({rowCount:1});
    await expect(reviewNoticeFact({query} as unknown as Pool,id,'confirmed','moderator')).resolves.toBe(true);
    expect(query.mock.calls[0][0]).toContain("review_status='pending'");
    expect(query.mock.calls[0][1]).toEqual([id,'confirmed','moderator']);
  });
  it('rejects invalid IDs before querying',async()=>{
    const query=jest.fn();
    await expect(stageNoticeFacts({query} as unknown as Pool,'not-uuid')).rejects.toThrow();
    expect(query).not.toHaveBeenCalled();
  });
});
