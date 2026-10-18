export interface ExtractedEditalFact {
  kind: 'registration_period' | 'exam_date' | 'vacancies' | 'salary';
  value: string;
  evidence: string;
  line: number;
  confidence: 'candidate';
}

/** Deterministic candidates only. Never publishes or treats matches as verified facts. */
export function extractEditalFactCandidates(text: string): ExtractedEditalFact[] {
  if (text.length > 500_000) throw new RangeError('Edital text exceeds limit');
  const patterns: Array<{kind: ExtractedEditalFact['kind']; regex: RegExp}> = [
    {kind:'registration_period',regex:/\b(?:inscri[cç][oõ]es|per[ií]odo de inscri[cç][aã]o)\b.{0,110}/i},
    {kind:'exam_date',regex:/\b(?:data da prova|prova objetiva|realiza[cç][aã]o das provas)\b.{0,110}/i},
    {kind:'vacancies',regex:/\b\d{1,6}\s+(?:vagas?|oportunidades)\b.{0,100}/i},
    {kind:'salary',regex:/\b(?:remunera[cç][aã]o|sal[aá]rio|vencimento)\b.{0,110}/i},
  ];
  const result: ExtractedEditalFact[] = [];
  const lines = text.split(/\r?\n/).slice(0,12000);
  for (let index = 0; index < lines.length; index++) {
    const line = lines[index].replace(/\s+/g,' ').trim();
    if (!line) continue;
    for (const pattern of patterns) {
      const match = line.match(pattern.regex);
      if (!match) continue;
      result.push({
        kind:pattern.kind,value:match[0].trim(),evidence:line.slice(0,350),
        line:index+1,confidence:'candidate',
      });
      if (result.length >= 100) return result;
    }
  }
  return result;
}
