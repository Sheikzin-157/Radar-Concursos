/**
 * Conservative discovery of links to official notices from a reviewed .gov.br
 * HTML page. Candidates are evidence, not automatically approved competitions.
 */
export interface NoticeLink { title: string; url: string }

export function discoverOfficialNoticeLinks(html: string, pageUrl: string): NoticeLink[] {
  const base = new URL(pageUrl);
  if (base.protocol !== 'https:' || !base.hostname.endsWith('.gov.br')) {
    throw new TypeError('Source page must be hosted on .gov.br');
  }
  if (html.length > 2_000_000) throw new RangeError('HTML response too large');
  const links = new Map<string, NoticeLink>();
  const anchorPattern = /<a\b([^>]*?)>([\s\S]*?)<\/a\s*>/gi;
  for (const match of html.matchAll(anchorPattern)) {
    const href = match[1].match(/\bhref\s*=\s*(["'])(.*?)\1/i)?.[2];
    if (!href) continue;
    const title = match[2].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
    if (!/\b(edital|concurso|retifica[cç][aã]o)\b/i.test(title)) continue;
    if (!title || title.length > 255) continue;
    try {
      const url = new URL(href.replace(/&amp;/g, '&'), base);
      if (url.protocol !== 'https:' || !url.hostname.endsWith('.gov.br') ||
          url.username || url.password || url.port) continue;
      url.hash = '';
      if (!links.has(url.toString())) links.set(url.toString(), {title, url: url.toString()});
    } catch { /* malformed or non-web link */ }
    if (links.size >= 100) break;
  }
  return [...links.values()];
}
