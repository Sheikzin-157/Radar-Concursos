import { extractEditalFactCandidates } from './extract-edital-facts';

describe('edital fact candidates', () => {
  it('preserves exact evidence and line reference', () => {
    const candidates = extractEditalFactCandidates(
      'Concurso público\nInscrições de 01 a 10 de março\n20 vagas para cargo\nRemuneração de R$ 3.000\nData da prova: 20 de abril',
    );
    expect(candidates.map(x=>x.kind)).toEqual([
      'registration_period','vacancies','salary','exam_date',
    ]);
    expect(candidates[0]).toMatchObject({
      line:2,evidence:'Inscrições de 01 a 10 de março',confidence:'candidate',
    });
  });
  it('never produces facts from unrelated content', () => {
    expect(extractEditalFactCandidates('Informações gerais.')).toEqual([]);
  });
  it('rejects overly long extracted texts', () => {
    expect(() => extractEditalFactCandidates('x'.repeat(500_001))).toThrow(RangeError);
  });
});
