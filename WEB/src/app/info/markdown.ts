import { marked, type Token, type Tokens } from 'marked';
import DOMPurify from 'dompurify';

marked.setOptions({ gfm: true, breaks: true });

const VIDEO = /\.(mp4|webm)$/i;
const AUDIO = /\.(mp3|m4a|wav|ogg)$/i;
const YOUTUBE = /^https?:\/\/(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?(?:.*&)?v=|embed\/|shorts\/)|youtu\.be\/)([\w-]{11})/i;

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/**
 * La sintaxis de imagen `![pie](url)` incrusta, según la URL: imagen, vídeo, audio o vídeo de YouTube.
 * Se emite con <span> (no <figure>) porque marked la envuelve en un <p>.
 * Un bloque ```mermaid se emite como contenedor que la vista convierte en diagrama.
 */
marked.use({
  renderer: {
    image({ href, text }) {
      const url = esc(href);
      const caption = text ? `<span class="md-cap">${esc(text)}</span>` : '';
      const yt = YOUTUBE.exec(href);
      if (yt) {
        return `<span class="md-media md-embed"><iframe src="https://www.youtube-nocookie.com/embed/${yt[1]}" title="${esc(text || 'Vídeo')}" loading="lazy" allowfullscreen></iframe>${caption}</span>`;
      }
      const path = href.split(/[?#]/)[0];
      if (VIDEO.test(path)) return `<span class="md-media md-video"><video controls preload="metadata" playsinline src="${url}"></video>${caption}</span>`;
      if (AUDIO.test(path)) return `<span class="md-media md-audio">${caption}<audio controls preload="metadata" src="${url}"></audio></span>`;
      return `<span class="md-media md-image"><img src="${url}" alt="${esc(text)}" loading="lazy">${caption}</span>`;
    },
    code({ text, lang }) {
      if ((lang ?? '').trim().toLowerCase() === 'mermaid') {
        return `<div class="md-mermaid" data-diagram="${esc(text)}"><pre class="md-mermaid-src">${esc(text)}</pre></div>`;
      }
      return false;
    },
  },
});

// Solo se admite el iframe de YouTube (nocookie); cualquier otro se elimina.
DOMPurify.addHook('uponSanitizeElement', (node, data) => {
  if (data.tagName === 'iframe' && !(node as Element).getAttribute('src')?.startsWith('https://www.youtube-nocookie.com/embed/')) {
    node.parentNode?.removeChild(node);
  }
});
// Los enlaces del contenido se abren en pestaña nueva sin dar acceso a la ventana de origen.
DOMPurify.addHook('afterSanitizeAttributes', node => {
  if (node.tagName === 'A' && node.getAttribute('href')) {
    node.setAttribute('target', '_blank');
    node.setAttribute('rel', 'noopener noreferrer');
  }
});

export interface RenderOptions {
  /** Marca cada bloque con las líneas del Markdown que lo definen (data-l1 / data-l2), para navegar entre texto y vista previa. */
  mapSource?: boolean;
}

const newlines = (s: string) => (s.match(/\n/g) ?? []).length;
/** Líneas que ocupa un fragmento sin contar los saltos finales. */
const spanLines = (raw: string) => newlines(raw.replace(/\s+$/, ''));

/** Rango de líneas [l1, l2] de cada <li> de una lista, en el orden en que aparecen en el HTML (preorden). */
function listItemLines(list: Tokens.List, firstLine: number, acc: [number, number][]) {
  let cursor = 0;
  for (const item of list.items) {
    let idx = list.raw.indexOf(item.raw, cursor);
    if (idx < 0) idx = cursor;
    const l1 = firstLine + newlines(list.raw.slice(0, idx));
    acc.push([l1, l1 + spanLines(item.raw)]);
    cursor = idx + item.raw.length;
    for (const t of item.tokens ?? []) {
      if (t.type !== 'list') continue;
      const inner = item.raw.indexOf(t.raw);
      listItemLines(t as Tokens.List, l1 + (inner > 0 ? newlines(item.raw.slice(0, inner)) : 0), acc);
    }
  }
}

function renderMapped(source: string): string {
  const tokens = marked.lexer(source);
  let line = 0;
  let out = '';
  for (const tok of tokens) {
    const first = line;
    line += newlines(tok.raw);
    if (tok.type === 'space') continue;
    const block = Object.assign([tok], { links: tokens.links }) as Token[] & { links: typeof tokens.links };
    let html = marked.parser(block);
    html = html.replace(/^<([a-z][a-z0-9]*)/i, `<$1 data-l1="${first}" data-l2="${first + spanLines(tok.raw)}"`);
    if (tok.type === 'list') {
      const ranges: [number, number][] = [];
      listItemLines(tok as Tokens.List, first, ranges);
      let i = 0;
      html = html.replace(/<li(?=[\s>])/g, () => {
        const r = ranges[i++];
        return r ? `<li data-l1="${r[0]}" data-l2="${r[1]}"` : '<li';
      });
    }
    out += html;
  }
  return out;
}

/** Convierte Markdown en HTML saneado (el contenido lo edita un administrador pero se trata como no confiable). */
export function renderMarkdown(source: string | null | undefined, options: RenderOptions = {}): string {
  const text = source ?? '';
  const html = options.mapSource ? renderMapped(text) : (marked.parse(text, { async: false }) as string);
  return DOMPurify.sanitize(html, {
    USE_PROFILES: { html: true },
    ADD_TAGS: ['iframe'],
    ADD_ATTR: ['allowfullscreen', 'controls', 'playsinline', 'preload', 'loading'],
  });
}

/** Enlace válido para incrustar como vídeo: YouTube o archivo .mp4/.webm. */
export function isVideoUrl(url: string): boolean {
  const path = url.split(/[?#]/)[0];
  return YOUTUBE.test(url) || ((/^https?:\/\//i.test(url) || url.startsWith('/')) && VIDEO.test(path));
}

export const MEDIA_ACCEPT = 'image/png,image/jpeg,image/gif,image/webp,video/mp4,video/webm,audio/mpeg,audio/mp4,audio/wav,audio/ogg,.mp3,.m4a,.wav,.ogg,.mp4,.webm';
export const IMAGE_ACCEPT = 'image/png,image/jpeg,image/gif,image/webp';
export const VIDEO_ACCEPT = 'video/mp4,video/webm,.mp4,.webm';
