import { discoverOfficialNoticeLinks } from './discover-official-notices';

describe('official HTML notice discovery', () => {
  const page = 'https://www.gov.br/gestao/pt-br/concursonacional/';
  it('extracts, resolves and deduplicates only official notice links', () => {
    const html = [
      '<a href="/gestao/edital-2026">Edital do concurso 2026</a>',
      '<a href="/gestao/edital-2026">Edital do concurso 2026</a>',
      '<a href="https://evil.example/edital.pdf">Edital externo</a>',
      '<a href="javascript:alert(1)">Edital suspeito</a>',
      '<a href="/ajuda">Ajuda</a>',
    ].join('');
    expect(discoverOfficialNoticeLinks(html, page)).toEqual([
      {title:'Edital do concurso 2026',url:'https://www.gov.br/gestao/edital-2026'},
    ]);
  });
  it('rejects non-government pages and oversized HTML', () => {
    expect(() => discoverOfficialNoticeLinks('', 'https://example.com')).toThrow();
    expect(() => discoverOfficialNoticeLinks('a'.repeat(2_000_001), page)).toThrow();
  });
});
