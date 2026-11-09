/**
 * Convierte los bloques ```mermaid ya renderizados (div.md-mermaid[data-diagram]) en diagramas SVG.
 * Mermaid es pesado: se carga bajo demanda, solo cuando hay algún diagrama.
 */
const cache = new Map<string, string>();
let counter = 0;
let ready: Promise<typeof import('mermaid').default> | undefined;

function load() {
  ready ??= import('mermaid').then(({ default: mermaid }) => {
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: 'strict',
      theme: 'base',
      fontFamily: 'inherit',
      themeVariables: {
        primaryColor: '#f9eded',
        primaryTextColor: '#540f19',
        primaryBorderColor: '#dfb8bb',
        lineColor: '#910000',
        secondaryColor: '#f3dca0',
        tertiaryColor: '#fff8dc',
        textColor: '#292126',
        cScale0: '#910000', cScale1: '#c98a1b', cScale2: '#2f6f73', cScale3: '#5b4b8a',
        cScale4: '#6b7f3a', cScale5: '#a0522d', cScale6: '#540f19', cScale7: '#b8353d',
        cScaleLabel0: '#fff', cScaleLabel1: '#fff', cScaleLabel2: '#fff', cScaleLabel3: '#fff',
        cScaleLabel4: '#fff', cScaleLabel5: '#fff', cScaleLabel6: '#fff', cScaleLabel7: '#fff',
      },
    });
    return mermaid;
  });
  return ready;
}

export async function renderDiagrams(root: HTMLElement) {
  const nodes = Array.from(root.querySelectorAll<HTMLElement>('.md-mermaid[data-diagram]'));
  if (!nodes.length) return;
  const todo: HTMLElement[] = [];
  for (const el of nodes) {
    const hit = cache.get(el.dataset['diagram'] ?? '');
    if (hit) { el.innerHTML = hit; el.classList.add('is-ready'); } else todo.push(el);
  }
  if (!todo.length) return;
  const mermaid = await load();
  for (const el of todo) {
    const src = el.dataset['diagram'] ?? '';
    if (!el.isConnected) continue;
    try {
      const ok = await mermaid.parse(src, { suppressErrors: true });
      if (!ok) throw new Error('sintaxis');
      const { svg } = await mermaid.render('mmd-' + ++counter, src);
      cache.set(src, svg);
      if (el.isConnected) { el.innerHTML = svg; el.classList.add('is-ready'); }
    } catch {
      if (el.isConnected) {
        el.classList.add('is-error');
        el.innerHTML = '<span class="md-mermaid-err">No se puede dibujar el diagrama: revisa su sintaxis.</span>';
      }
    }
  }
}
