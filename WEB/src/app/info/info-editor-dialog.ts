import { AfterViewInit, Component, ElementRef, OnDestroy, OnInit, ViewEncapsulation, computed, inject, input, output, signal, viewChild } from '@angular/core';
import { Observable, switchMap } from 'rxjs';
import { DataService } from '../data.service';
import { InfoView } from './info-view';
import { IMAGE_ACCEPT, VIDEO_ACCEPT, isVideoUrl } from './markdown';

type Mode = 'md' | 'split' | 'preview';
type BlockKind = 'p' | 'h1' | 'h2' | 'h3' | 'ul' | 'ol' | 'quote';

const TIMELINE = `\`\`\`mermaid
timeline
    title Estructura de la canción
    section Introducción
        Compás 1 : Marcaje
    section Cuerpo
        Compás 9 : Parte 1
        Compás 25 : Parte 2
    section Final
        Compás 41 : Remate
\`\`\``;

const escHtml = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/**
 * Editor de Información a pantalla completa: Markdown y vista previa lado a lado (o cada uno por separado),
 * separador redimensionable, navegación resaltada entre ambos, barra flotante de formato y menú contextual.
 */
@Component({
  selector: 'app-info-editor-dialog',
  imports: [InfoView],
  encapsulation: ViewEncapsulation.None,
  template: `
<div class="ied" role="dialog" aria-modal="true" aria-label="Editor de información" (keydown)="onKeydown($event)">
  <header class="ied-bar">
    <div class="ied-title">
      <p>EDITOR DE INFORMACIÓN</p>
      <h2>{{ title() }}</h2>
    </div>

    <div class="ied-modes" role="group" aria-label="Qué mostrar">
      <button type="button" [class.on]="mode() === 'md'" [attr.aria-pressed]="mode() === 'md'" (click)="mode.set('md')" title="Solo Markdown">
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M6.5 15V9l2.5 3 2.5-3v6" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round"/><path d="M16 9v6m-2-2 2 2 2-2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>
        <span>MD</span>
      </button>
      <button type="button" [class.on]="mode() === 'split'" [attr.aria-pressed]="mode() === 'split'" (click)="mode.set('split')" title="Markdown y vista previa">
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M12 5v14" stroke="currentColor" stroke-width="1.8"/></svg>
        <span>MD + Vista</span>
      </button>
      <button type="button" [class.on]="mode() === 'preview'" [attr.aria-pressed]="mode() === 'preview'" (click)="mode.set('preview')" title="Solo vista previa">
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" stroke-width="1.8"/></svg>
        <span>Vista</span>
      </button>
    </div>

    <div class="ied-actions">
      @if (notice()) { <span class="ied-notice" role="status">{{ notice() }}</span> }
      <button type="button" class="ied-save" (click)="save()" [disabled]="saving() || !dirty()">
        {{ saving() ? 'Guardando…' : dirty() ? 'Guardar' : 'Guardado' }}
      </button>
      <button type="button" class="ied-close" (click)="requestClose()" aria-label="Cerrar editor" title="Cerrar">
        <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </button>
    </div>
  </header>

  @if (error()) { <div class="ied-error" role="alert">{{ error() }}</div> }

  <div #body class="ied-body" [class.vertical]="vertical()" [class.dragging]="dragging()" [attr.data-mode]="mode()">
    @if (mode() !== 'preview') {
      <div class="ied-pane ied-md" [style.flex-basis]="mode() === 'split' ? 'calc(' + split() + '% - 7px)' : null">
        <div class="ied-editwrap">
          <div #mirror class="ied-text ied-mirror" aria-hidden="true" [innerHTML]="mirrorHtml()"></div>
          <textarea #ta class="ied-text ied-input" [value]="md()" spellcheck="true" aria-label="Contenido en Markdown"
            placeholder="## Un título&#10;&#10;Escribe aquí en Markdown…&#10;Pulsa con el botón derecho (o mantén pulsado) para insertar imágenes, vídeos o diagramas."
            (input)="onInput()" (scroll)="syncScroll()" (click)="onCaret()" (keyup)="onKeyup($event)"
            (contextmenu)="onContext($event)" (pointerdown)="onPointerDown($event)" (pointermove)="onPointerMove($event)"
            (pointerup)="cancelPress()" (pointercancel)="cancelPress()"
            (paste)="onPaste($event)" (dragover)="onDragOver($event)" (drop)="onDrop($event)"></textarea>
        </div>
      </div>
    }

    @if (mode() === 'split') {
      <div class="ied-split" role="separator" tabindex="0" [attr.aria-orientation]="vertical() ? 'horizontal' : 'vertical'"
        aria-label="Redimensionar paneles (doble clic para centrar)" [attr.aria-valuenow]="split()"
        (pointerdown)="startDrag($event)" (dblclick)="split.set(50)" (keydown)="onSplitKey($event)">
        <i aria-hidden="true"></i>
      </div>
    }

    @if (mode() !== 'md') {
      <div #pv class="ied-pane ied-pv" (click)="onPreviewClick($event)">
        <app-info-view [markdown]="md()" [mapSource]="true" emptyText="La vista previa aparecerá aquí." />
      </div>
    }
  </div>

  @if (mode() !== 'preview') {
    <nav class="ied-float" aria-label="Formato del texto seleccionado" (mousedown)="$event.preventDefault()">
      <div class="ied-grp">
        <button type="button" title="Texto normal" (click)="block('p')"><b>¶</b></button>
        <button type="button" title="Título grande" (click)="block('h1')"><b>H1</b></button>
        <button type="button" title="Título" (click)="block('h2')"><b>H2</b></button>
        <button type="button" title="Subtítulo" (click)="block('h3')"><b>H3</b></button>
      </div>
      <i class="ied-vsep"></i>
      <div class="ied-grp">
        <button type="button" title="Negrita (Ctrl+B)" (click)="inline('**', '**', 'texto')"><b>B</b></button>
        <button type="button" title="Cursiva (Ctrl+I)" (click)="inline('*', '*', 'texto')"><em class="serif">I</em></button>
        <button type="button" title="Tachado" (click)="inline('~~', '~~', 'texto')"><s>S</s></button>
        <button type="button" title="Código" (click)="inline('\`', '\`', 'código')"><code>&lt;/&gt;</code></button>
      </div>
      <i class="ied-vsep"></i>
      <div class="ied-grp">
        <button type="button" title="Lista" (click)="block('ul')">•</button>
        <button type="button" title="Lista numerada" (click)="block('ol')">1.</button>
        <button type="button" title="Aviso destacado" (click)="block('quote')">❝</button>
        <button type="button" title="Bloque de código" (click)="fence()"><code>{{ '{ }' }}</code></button>
      </div>
      <i class="ied-vsep"></i>
      <div class="ied-grp">
        <button type="button" title="Enlace (Ctrl+K)" (click)="link()">
          <svg viewBox="0 0 24 24" width="17" height="17" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1"/></svg>
        </button>
        <button type="button" title="Separador" (click)="divider()">―</button>
      </div>
    </nav>
  }

  @if (menu(); as m) {
    <div class="ied-ctx" role="menu" [style.left.px]="m.x" [style.top.px]="m.y" (mousedown)="$event.preventDefault()">
      <button type="button" role="menuitem" (click)="copy()" [disabled]="!hasSelection()">Copiar<kbd>Ctrl+C</kbd></button>
      <button type="button" role="menuitem" (click)="paste()">Pegar<kbd>Ctrl+V</kbd></button>
      <p>Insertar</p>
      <button type="button" role="menuitem" (click)="pickImage()">
        <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><rect x="3" y="4" width="18" height="16" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><circle cx="9" cy="10" r="1.8" fill="currentColor"/><path d="m4 18 5-5 4 4 3-3 4 4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/></svg>
        Imagen
      </button>
      <button type="button" role="menuitem" (click)="openVideo()">
        <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="3" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="m10 9 5 3-5 3z" fill="currentColor"/></svg>
        Vídeo
      </button>
      <button type="button" role="menuitem" (click)="insertTimeline()">
        <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M3 12h18M7 12V7m5 5v5m5-5V8" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="7" cy="7" r="1.6" fill="currentColor"/><circle cx="12" cy="17" r="1.6" fill="currentColor"/><circle cx="17" cy="8" r="1.6" fill="currentColor"/></svg>
        Diagrama de tiempo
      </button>
    </div>
  }

  @if (videoPop()) {
    <div class="ied-pop-back" (mousedown)="videoPop.set(false)">
      <div class="ied-pop" role="dialog" aria-label="Insertar vídeo" (mousedown)="$event.stopPropagation()">
        <h3>Insertar vídeo</h3>
        <label>Enlace de YouTube o archivo .mp4
          <input type="url" [value]="videoUrl()" (input)="videoUrl.set($any($event.target).value)" (keydown.enter)="addVideo()" placeholder="https://www.youtube.com/watch?v=…" autocomplete="off">
        </label>
        <label>Título
          <input type="text" [value]="videoTitle()" (input)="videoTitle.set($any($event.target).value)" (keydown.enter)="addVideo()" placeholder="Opcional" autocomplete="off">
        </label>
        <div class="ied-pop-actions">
          <button type="button" class="ghost" (click)="pickVideoFile()">Subir archivo</button>
          <button type="button" class="ghost" (click)="videoPop.set(false)">Cancelar</button>
          <button type="button" class="main" [disabled]="!videoUrl().trim()" (click)="addVideo()">Insertar</button>
        </div>
      </div>
    </div>
  }

  @if (confirmClose()) {
    <div class="ied-pop-back">
      <div class="ied-pop" role="alertdialog" aria-label="Cambios sin guardar">
        <h3>Hay cambios sin guardar</h3>
        <p>Si cierras ahora se perderán los cambios que no hayas guardado.</p>
        <div class="ied-pop-actions">
          <button type="button" class="ghost" (click)="confirmClose.set(false)">Seguir editando</button>
          <button type="button" class="main" (click)="closed.emit()">Descartar y cerrar</button>
        </div>
      </div>
    </div>
  }

  <input #imgInput type="file" hidden multiple [accept]="imageAccept" (change)="onFiles($event)">
  <input #vidInput type="file" hidden [accept]="videoAccept" (change)="onFiles($event)">
</div>
  `,
  styles: [`
.ied{position:fixed;inset:0;z-index:200;display:flex;flex-direction:column;gap:12px;padding:14px 16px 16px;background:var(--bg);background-image:radial-gradient(ellipse at 12% 0%,rgb(243 220 160 / 55%),transparent 45%),radial-gradient(ellipse at 100% 100%,rgb(221 182 166 / 45%),transparent 50%);color:var(--ink)}
.ied-bar{display:grid;grid-template-columns:minmax(0,1fr) auto minmax(0,1fr);align-items:center;gap:12px;flex:none}
.ied-title{min-width:0}
.ied-title p{margin:0 0 2px;font-size:10px;font-weight:700;letter-spacing:1.4px;color:var(--color-brand)}
.ied-title h2{margin:0;font-size:17px;font-weight:600;letter-spacing:-.4px;color:var(--color-brand-dark);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.ied-modes{display:inline-flex;gap:2px;padding:4px;border:1px solid var(--surface-glass-border);border-radius:100px;background:var(--surface-glass);box-shadow:var(--shadow-glass);-webkit-backdrop-filter:blur(var(--glass-blur));backdrop-filter:blur(var(--glass-blur))}
.ied-modes button{display:inline-flex;align-items:center;gap:7px;min-height:38px;padding:0 16px;border:1px solid transparent;border-radius:100px;background:transparent;color:var(--muted);font-size:13px;font-weight:700;cursor:pointer;transition:background var(--motion-fast),color var(--motion-fast)}
.ied-modes button:hover:not(.on){background:rgb(145 0 0 / 6%)}
.ied-modes button.on{background:rgb(145 0 0 / 11%);border-color:var(--tint-border);color:var(--color-brand-dark)}
.ied-actions{display:flex;align-items:center;justify-content:flex-end;gap:10px;min-width:0}
.ied-notice{font-size:12px;font-weight:600;color:#2e7d4f;white-space:nowrap}
.ied-save{min-height:42px;padding:0 22px;border:0;border-radius:100px;background:var(--color-brand);color:#fff;font-weight:700;font-size:14px;cursor:pointer}
.ied-save:disabled{opacity:.5;cursor:default}
.ied-close{display:grid;place-items:center;flex:none;width:42px;height:42px;border:1px solid var(--surface-glass-border);border-radius:50%;background:var(--surface-glass);color:var(--color-brand);cursor:pointer}
.ied-error{flex:none;padding:9px 14px;border:1px solid #f0c9c9;border-radius:12px;background:#fef2f2;color:#b91c1c;font-size:13px;font-weight:600}
.ied-body{position:relative;flex:1;min-height:0;display:flex;gap:0}
.ied-body.vertical{flex-direction:column}
.ied-body.dragging{user-select:none}.ied-body.dragging .ied-pane{pointer-events:none}
.ied-pane{min-width:0;min-height:0;flex:1 1 0;border:1px solid var(--surface-glass-border);border-radius:22px;box-shadow:var(--shadow-glass),inset 0 1px 0 #fff;overflow:hidden}
.ied-md{background:rgb(255 253 248 / 78%);position:relative}
.ied-pv{overflow:auto;padding:26px 28px 120px;background:rgb(255 249 235 / 55%)}
.ied-body[data-mode=split] .ied-md{flex:0 0 auto}
.ied-body[data-mode=split] .ied-pv{flex:1 1 0}
.ied-split{flex:none;position:relative;display:grid;place-items:center;width:14px;cursor:col-resize;touch-action:none;outline:none}
.ied-body.vertical .ied-split{width:auto;height:14px;cursor:row-resize}
.ied-split i{display:block;width:4px;height:44px;border-radius:4px;background:var(--tint-border);transition:background var(--motion-fast),height var(--motion-fast)}
.ied-body.vertical .ied-split i{width:44px;height:4px}
.ied-split:hover i,.ied-split:focus-visible i,.ied-body.dragging .ied-split i{background:var(--color-brand)}
.ied-editwrap{position:absolute;inset:0}
.ied-text{position:absolute;inset:0;margin:0;padding:18px 20px 120px;border:0;box-sizing:border-box;width:100%;height:100%;font-family:ui-monospace,Consolas,monospace;font-size:14px;line-height:1.7;letter-spacing:0;tab-size:4;white-space:pre-wrap;overflow-wrap:break-word;word-break:normal;scrollbar-gutter:stable;overflow-y:auto;overflow-x:hidden}
.ied-mirror{color:transparent;pointer-events:none;overflow:hidden;z-index:0}
.ied-mirror mark{color:transparent;border-radius:5px;background:rgb(232 195 110 / 85%);animation:ied-fade 1.9s ease-out forwards}
.ied-input{z-index:1;resize:none;background:transparent;color:var(--ink);outline:none}
.ied-pane.ied-md:focus-within{border-color:var(--tint-border);box-shadow:var(--shadow-glass),0 0 0 3px var(--tint)}
@keyframes ied-fade{0%,30%{background-color:rgb(232 195 110 / 85%)}100%{background-color:rgb(232 195 110 / 0%)}}
.ied-pv [data-l1].ied-hit{animation:ied-hit 1.9s ease-out;border-radius:8px}
@keyframes ied-hit{0%,30%{background-color:rgb(232 195 110 / 70%);box-shadow:0 0 0 6px rgb(232 195 110 / 70%)}100%{background-color:rgb(232 195 110 / 0%);box-shadow:0 0 0 6px rgb(232 195 110 / 0%)}}
.ied-pv [data-l1]{cursor:pointer}
.ied-body[data-mode=preview] .ied-pv [data-l1]{cursor:auto}
.ied-float{position:absolute;left:50%;bottom:30px;z-index:5;transform:translateX(-50%);display:flex;align-items:center;gap:4px;max-width:calc(100vw - 24px);padding:6px;overflow-x:auto;border:1px solid var(--surface-glass-border);border-radius:100px;background:rgb(255 249 235 / 82%);box-shadow:0 14px 40px rgb(74 10 10 / 22%),inset 0 1px 0 #fff;-webkit-backdrop-filter:blur(var(--glass-blur));backdrop-filter:blur(var(--glass-blur));scrollbar-width:none}
.ied-float::-webkit-scrollbar{display:none}
.ied-grp{display:flex;gap:2px}
.ied-vsep{flex:none;width:1px;height:22px;margin:0 4px;background:var(--tint-border)}
.ied-float button{display:grid;place-items:center;flex:none;min-width:38px;height:38px;padding:0 8px;border:0;border-radius:100px;background:transparent;color:var(--color-brand-dark);font-size:14px;cursor:pointer}
.ied-float button:hover{background:rgb(145 0 0 / 10%)}
.ied-float button:active{background:rgb(145 0 0 / 18%)}
.ied-float .serif{font-family:Georgia,serif}
.ied-float code{font-family:ui-monospace,Consolas,monospace;font-size:12px;background:none;color:inherit;padding:0}
.ied-ctx{position:fixed;z-index:260;width:226px;padding:6px;display:grid;gap:1px;border:1px solid var(--surface-glass-border);border-radius:18px;background:rgb(255 249 235 / 92%);box-shadow:0 18px 50px rgb(74 10 10 / 28%),inset 0 1px 0 #fff;-webkit-backdrop-filter:blur(var(--glass-blur));backdrop-filter:blur(var(--glass-blur))}
.ied-ctx p{margin:6px 10px 2px;font-size:10px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:var(--muted)}
.ied-ctx button{display:flex;align-items:center;gap:9px;min-height:40px;padding:0 12px;border:0;border-radius:12px;background:transparent;color:var(--ink);font-size:14px;font-weight:600;text-align:left;cursor:pointer}
.ied-ctx button:hover:not(:disabled){background:rgb(145 0 0 / 9%)}
.ied-ctx button:disabled{opacity:.4;cursor:default}
.ied-ctx kbd{margin-left:auto;font:inherit;font-size:11px;font-weight:500;color:var(--muted)}
.ied-ctx svg{flex:none;color:var(--color-brand)}
.ied-pop-back{position:fixed;inset:0;z-index:280;display:grid;place-items:center;padding:16px;background:rgb(53 24 20 / 40%)}
.ied-pop{width:min(460px,100%);display:grid;gap:14px;padding:22px;border:1px solid var(--surface-glass-border);border-radius:24px;background:rgb(255 249 235 / 94%);box-shadow:0 24px 70px rgb(74 10 10 / 35%),inset 0 1px 0 #fff}
.ied-pop h3{margin:0;font-size:18px;color:var(--color-brand-dark)}
.ied-pop p{margin:0;font-size:14px;color:var(--muted)}
.ied-pop label{display:grid;gap:6px;font-size:12px;font-weight:600;color:var(--muted)}
.ied-pop input{width:100%;min-height:44px;padding:10px 16px;border:1px solid var(--border);border-radius:100px;background:#fffdf8c9;font-size:15px;color:var(--ink)}
.ied-pop-actions{display:flex;flex-wrap:wrap;gap:8px;justify-content:flex-end}
.ied-pop-actions button{min-height:42px;padding:0 18px;border-radius:100px;font-size:14px;font-weight:700;cursor:pointer}
.ied-pop-actions .ghost{border:1px solid var(--tint-border);background:#fff9;color:var(--color-brand)}
.ied-pop-actions .main{border:0;background:var(--color-brand);color:#fff}
.ied-pop-actions .main:disabled{opacity:.45;cursor:default}
@media (max-width:900px){
  .ied-bar{grid-template-columns:1fr auto}
  .ied-modes{grid-column:1/-1;grid-row:2;justify-self:center}
  .ied-title{grid-column:1;grid-row:1}
  .ied-actions{grid-column:2;grid-row:1}
}
@media (max-width:520px){
  .ied{padding:10px 10px 12px}
  .ied-modes button{padding:0 12px}
  .ied-modes button span{font-size:12px}
  .ied-text{font-size:16px}
  .ied-pv{padding:18px 16px 110px}
  .ied-notice{display:none}
}
  `],
})
export class InfoEditorDialog implements OnInit, AfterViewInit, OnDestroy {
  private data = inject(DataService);

  markdown = input.required<string>();
  title = input('');
  /** Devuelve el id de la canción, creándola antes si aún no existe (hace falta para subir archivos). */
  ensureSong = input.required<() => Observable<number>>();
  /** Guarda el texto (en la canción). Devuelve el Observable de la petición. */
  saveFn = input.required<(markdown: string) => Observable<unknown>>();
  closed = output<void>();

  imageAccept = IMAGE_ACCEPT;
  videoAccept = VIDEO_ACCEPT;

  md = signal('');
  private original = signal('');
  dirty = computed(() => this.md() !== this.original());
  mode = signal<Mode>('split');
  split = signal(50);
  vertical = signal(false);
  dragging = signal(false);
  saving = signal(false);
  error = signal('');
  notice = signal('');
  mirrorHtml = signal('');
  menu = signal<{ x: number; y: number } | null>(null);
  hasSelection = signal(false);
  videoPop = signal(false);
  videoUrl = signal('');
  videoTitle = signal('');
  confirmClose = signal(false);

  private ta = viewChild<ElementRef<HTMLTextAreaElement>>('ta');
  private mirror = viewChild<ElementRef<HTMLElement>>('mirror');
  private pv = viewChild<ElementRef<HTMLElement>>('pv');
  private body = viewChild.required<ElementRef<HTMLElement>>('body');
  private imgInput = viewChild.required<ElementRef<HTMLInputElement>>('imgInput');
  private vidInput = viewChild.required<ElementRef<HTMLInputElement>>('vidInput');

  private saved?: { s: number; e: number };
  private flashTimer = 0;
  private noticeTimer = 0;
  private pressTimer = 0;
  private pressAt = { x: 0, y: 0 };
  private longPressAt = 0;
  private lastHit: Element | null = null;
  private prevOverflow = '';

  ngOnInit() {
    const text = this.markdown().replace(/\r\n?/g, '\n');
    this.md.set(text);
    this.original.set(text);
    this.updateLayout();
    this.prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    window.addEventListener('resize', this.onResize);
    document.addEventListener('pointerdown', this.onDocPointer, true);
  }

  ngAfterViewInit() {
    setTimeout(() => this.ta()?.nativeElement.focus());
  }

  ngOnDestroy() {
    document.body.style.overflow = this.prevOverflow;
    window.removeEventListener('resize', this.onResize);
    document.removeEventListener('pointerdown', this.onDocPointer, true);
    clearTimeout(this.flashTimer);
    clearTimeout(this.noticeTimer);
    clearTimeout(this.pressTimer);
  }

  private onResize = () => this.updateLayout();
  private updateLayout() { this.vertical.set(window.innerWidth < 760); }

  private onDocPointer = (e: PointerEvent) => {
    if (this.menu() && !(e.target as Element).closest('.ied-ctx')) this.menu.set(null);
  };

  // ---------- Guardar / cerrar
  save() {
    if (this.saving() || !this.dirty()) return;
    this.saving.set(true);
    this.error.set('');
    const text = this.md();
    this.saveFn()(text).subscribe({
      next: () => {
        this.original.set(text);
        this.saving.set(false);
        this.toast('Guardado');
      },
      error: err => {
        this.saving.set(false);
        this.error.set('No se pudo guardar: ' + (err?.error?.message || err?.message || 'error desconocido'));
      },
    });
  }

  requestClose() {
    if (this.dirty()) this.confirmClose.set(true);
    else this.closed.emit();
  }

  onKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      e.stopPropagation();
      if (this.menu()) this.menu.set(null);
      else if (this.videoPop()) this.videoPop.set(false);
      else if (this.confirmClose()) this.confirmClose.set(false);
      else this.requestClose();
      return;
    }
    if (!(e.ctrlKey || e.metaKey)) return;
    const k = e.key.toLowerCase();
    if (k === 's') { e.preventDefault(); this.save(); }
    else if (k === 'b' && this.ta()) { e.preventDefault(); this.inline('**', '**', 'texto'); }
    else if (k === 'i' && this.ta()) { e.preventDefault(); this.inline('*', '*', 'texto'); }
    else if (k === 'k' && this.ta()) { e.preventDefault(); this.link(); }
  }

  private toast(text: string) {
    this.notice.set(text);
    clearTimeout(this.noticeTimer);
    this.noticeTimer = window.setTimeout(() => this.notice.set(''), 2200);
  }

  // ---------- Texto
  onInput() {
    this.md.set(this.ta()!.nativeElement.value);
  }

  syncScroll() {
    const t = this.ta()?.nativeElement;
    const m = this.mirror()?.nativeElement;
    if (t && m) m.scrollTop = t.scrollTop;
  }

  // ---------- Navegación resaltada entre texto y vista previa
  /** Rango de caracteres [inicio, fin) de las líneas l1..l2 (ambas incluidas). */
  private charRange(l1: number, l2: number): [number, number] {
    const lines = this.md().split('\n');
    let start = 0;
    for (let i = 0; i < l1 && i < lines.length; i++) start += lines[i].length + 1;
    let end = start;
    for (let i = l1; i <= l2 && i < lines.length; i++) end += lines[i].length + (i < l2 ? 1 : 0);
    return [start, end];
  }

  /** Vista previa → texto: resalta en el Markdown las líneas que definen el bloque pulsado. */
  onPreviewClick(e: MouseEvent) {
    if (this.mode() !== 'split') return;
    const target = e.target as Element;
    if (target.closest('a, button, video, audio, iframe')) return;
    const el = target.closest<HTMLElement>('[data-l1]');
    if (!el) return;
    const [s, end] = this.charRange(+el.dataset['l1']!, +el.dataset['l2']!);
    const text = this.md();
    this.mirrorHtml.set(`${escHtml(text.slice(0, s))}<mark>${escHtml(text.slice(s, end)) || ' '}</mark>${escHtml(text.slice(end))}\n `);
    clearTimeout(this.flashTimer);
    this.flashTimer = window.setTimeout(() => this.mirrorHtml.set(''), 2000);
    requestAnimationFrame(() => {
      const mk = this.mirror()?.nativeElement.querySelector('mark') as HTMLElement | null;
      const ta = this.ta()?.nativeElement;
      if (!mk || !ta) return;
      ta.scrollTop = Math.max(0, mk.offsetTop - ta.clientHeight * 0.3);
      this.syncScroll();
    });
  }

  onKeyup(e: KeyboardEvent) {
    if (/^(Arrow|Page|Home|End)/.test(e.key)) this.onCaret();
  }

  /** Texto → vista previa: resalta el bloque de la vista previa que corresponde a la posición del cursor. */
  onCaret() {
    const ta = this.ta()?.nativeElement;
    if (ta) this.hasSelection.set(ta.selectionEnd > ta.selectionStart);
    if (this.mode() !== 'split' || !ta || ta.selectionEnd !== ta.selectionStart) return;
    const pv = this.pv()?.nativeElement;
    if (!pv) return;
    const line = (ta.value.slice(0, ta.selectionStart).match(/\n/g) ?? []).length;
    let best: HTMLElement | null = null;
    let bestSpan = Infinity;
    pv.querySelectorAll<HTMLElement>('[data-l1]').forEach(el => {
      const l1 = +el.dataset['l1']!;
      const l2 = +el.dataset['l2']!;
      if (line >= l1 && line <= l2 && l2 - l1 <= bestSpan) { best = el; bestSpan = l2 - l1; }
    });
    const hit = best as HTMLElement | null;
    if (!hit || hit === this.lastHit) return;
    this.lastHit = hit;
    hit.classList.remove('ied-hit');
    void hit.offsetWidth;
    hit.classList.add('ied-hit');
    hit.scrollIntoView({ block: 'center', behavior: 'smooth' });
    window.setTimeout(() => hit.classList.remove('ied-hit'), 2000);
  }

  // ---------- Separador redimensionable
  startDrag(e: PointerEvent) {
    e.preventDefault();
    const sep = e.currentTarget as HTMLElement;
    try { sep.setPointerCapture(e.pointerId); } catch { /* puntero sin captura */ }
    const rect = this.body().nativeElement.getBoundingClientRect();
    const vert = this.vertical();
    this.dragging.set(true);
    const move = (ev: PointerEvent) => {
      if (ev.buttons === 0 && ev.pointerType === 'mouse') { end(); return; }
      const ratio = vert ? (ev.clientY - rect.top) / rect.height : (ev.clientX - rect.left) / rect.width;
      this.split.set(Math.min(80, Math.max(20, ratio * 100)));
    };
    const end = () => {
      sep.removeEventListener('pointermove', move);
      sep.removeEventListener('pointerup', end);
      sep.removeEventListener('pointercancel', end);
      sep.removeEventListener('lostpointercapture', end);
      window.removeEventListener('blur', end);
      this.dragging.set(false);
    };
    sep.addEventListener('pointermove', move);
    sep.addEventListener('pointerup', end);
    sep.addEventListener('pointercancel', end);
    sep.addEventListener('lostpointercapture', end);
    window.addEventListener('blur', end);
  }

  onSplitKey(e: KeyboardEvent) {
    const step = e.shiftKey ? 10 : 3;
    const dec = this.vertical() ? 'ArrowUp' : 'ArrowLeft';
    const inc = this.vertical() ? 'ArrowDown' : 'ArrowRight';
    if (e.key === dec) { e.preventDefault(); this.split.update(v => Math.max(20, v - step)); }
    else if (e.key === inc) { e.preventDefault(); this.split.update(v => Math.min(80, v + step)); }
    else if (e.key === 'Home' || e.key === 'Enter') { e.preventDefault(); this.split.set(50); }
  }

  // ---------- Edición (barra flotante)
  private el() { return this.ta()!.nativeElement; }

  /** Reemplaza un rango conservando el historial de deshacer del navegador. */
  private put(start: number, end: number, text: string, selFrom?: number, selTo?: number) {
    const el = this.el();
    el.focus();
    el.setSelectionRange(start, end);
    let ok = false;
    try { ok = document.execCommand('insertText', false, text); } catch { /* sin execCommand */ }
    if (!ok) {
      el.setRangeText(text, start, end, 'end');
      el.dispatchEvent(new Event('input', { bubbles: true }));
    }
    if (selFrom != null) el.setSelectionRange(selFrom, selTo ?? selFrom);
    this.md.set(el.value);
    this.hasSelection.set(el.selectionEnd > el.selectionStart);
  }

  inline(before: string, after: string, placeholder: string) {
    const el = this.el();
    const v = el.value;
    const s = el.selectionStart;
    const e = el.selectionEnd;
    const sel = v.slice(s, e) || placeholder;
    if (e > s && v.slice(s - before.length, s) === before && v.slice(e, e + after.length) === after) {
      this.put(s - before.length, e + after.length, sel, s - before.length, s - before.length + sel.length);
      return;
    }
    this.put(s, e, before + sel + after, s + before.length, s + before.length + sel.length);
  }

  block(kind: BlockKind) {
    const el = this.el();
    const v = el.value;
    const s = el.selectionStart;
    let e = el.selectionEnd;
    if (e > s && v[e - 1] === '\n') e--;
    const ls = v.lastIndexOf('\n', s - 1) + 1;
    let le = v.indexOf('\n', e);
    if (le < 0) le = v.length;
    const lines = v.slice(ls, le).split('\n');
    const has: Record<BlockKind, RegExp> = { p: /^$/, h1: /^#\s/, h2: /^##\s/, h3: /^###\s/, ul: /^[-*+]\s/, ol: /^\d+\.\s/, quote: /^>\s?/ };
    const strip = (l: string) => l.replace(/^(\s*)(#{1,6}\s+|[-*+]\s+|\d+\.\s+|>\s?)/, '$1');
    const filled = lines.filter(l => l.trim());
    const toggleOff = kind !== 'p' && filled.length > 0 && filled.every(l => has[kind].test(l.trimStart()));
    let n = 0;
    const out = lines.map(l => {
      const base = strip(l);
      if (kind === 'p' || toggleOff || !l.trim()) return base;
      n++;
      const prefix = { h1: '# ', h2: '## ', h3: '### ', ul: '- ', ol: `${n}. `, quote: '> ' }[kind];
      return prefix + base.trimStart();
    }).join('\n');
    this.put(ls, le, out, ls, ls + out.length);
  }

  fence() {
    const el = this.el();
    const v = el.value;
    const s = el.selectionStart;
    const e = el.selectionEnd;
    const sel = v.slice(s, e) || 'código';
    const lead = s > 0 && v[s - 1] !== '\n' ? '\n' : '';
    const text = `${lead}\`\`\`\n${sel}\n\`\`\`\n`;
    const from = s + lead.length + 4;
    this.put(s, e, text, from, from + sel.length);
  }

  link() {
    const el = this.el();
    const s = el.selectionStart;
    const e = el.selectionEnd;
    const sel = el.value.slice(s, e) || 'texto del enlace';
    const urlFrom = s + sel.length + 3;
    this.put(s, e, `[${sel}](https://)`, urlFrom, urlFrom + 8);
  }

  divider() {
    this.insertBlock('---');
  }

  /** Inserta un bloque en la posición guardada (menú contextual) o en el cursor. */
  private insertBlock(text: string) {
    const el = this.el();
    const v = el.value;
    const pos = this.saved ? this.saved.e : el.selectionEnd;
    this.saved = undefined;
    const lead = pos > 0 && v[pos - 1] !== '\n' ? '\n\n' : pos > 0 && v[pos - 2] !== '\n' ? '\n' : '';
    const full = lead + text + '\n\n';
    this.put(pos, pos, full, pos + full.length);
  }

  // ---------- Menú contextual (botón derecho / pulsación larga)
  onContext(e: MouseEvent) {
    e.preventDefault();
    if (Date.now() - this.longPressAt < 900) return;
    this.openMenu(e.clientX, e.clientY);
  }

  onPointerDown(e: PointerEvent) {
    if (e.pointerType !== 'touch') return;
    this.pressAt = { x: e.clientX, y: e.clientY };
    clearTimeout(this.pressTimer);
    this.pressTimer = window.setTimeout(() => {
      this.longPressAt = Date.now();
      this.openMenu(this.pressAt.x, this.pressAt.y);
    }, 550);
  }

  onPointerMove(e: PointerEvent) {
    if (this.pressTimer && Math.hypot(e.clientX - this.pressAt.x, e.clientY - this.pressAt.y) > 10) this.cancelPress();
  }

  cancelPress() {
    clearTimeout(this.pressTimer);
    this.pressTimer = 0;
  }

  private openMenu(x: number, y: number) {
    const el = this.el();
    this.saved = { s: el.selectionStart, e: el.selectionEnd };
    this.hasSelection.set(el.selectionEnd > el.selectionStart);
    this.menu.set({ x: Math.max(8, Math.min(x, window.innerWidth - 236)), y: Math.max(8, Math.min(y, window.innerHeight - 290)) });
  }

  copy() {
    const el = this.el();
    const text = el.value.slice(el.selectionStart, el.selectionEnd);
    this.menu.set(null);
    if (!text) return;
    navigator.clipboard?.writeText(text).then(() => this.toast('Copiado'), () => {
      el.focus();
      document.execCommand('copy');
    });
  }

  paste() {
    const sel = this.saved;
    this.menu.set(null);
    if (!navigator.clipboard?.readText) { this.toast('Usa Ctrl+V para pegar'); return; }
    navigator.clipboard.readText().then(text => {
      if (!text) return;
      const el = this.el();
      const s = sel?.s ?? el.selectionStart;
      const e = sel?.e ?? el.selectionEnd;
      this.put(s, e, text, s + text.length);
    }, () => this.toast('El navegador no permite pegar desde el menú: usa Ctrl+V'));
  }

  insertTimeline() {
    this.menu.set(null);
    this.insertBlock(TIMELINE);
  }

  pickImage() {
    this.menu.set(null);
    this.imgInput().nativeElement.click();
  }

  openVideo() {
    this.menu.set(null);
    this.videoUrl.set('');
    this.videoTitle.set('');
    this.videoPop.set(true);
  }

  pickVideoFile() {
    this.videoPop.set(false);
    this.vidInput().nativeElement.click();
  }

  addVideo() {
    const url = this.videoUrl().trim();
    if (!isVideoUrl(url)) {
      this.error.set('El enlace debe ser de YouTube o de un archivo .mp4 / .webm.');
      return;
    }
    this.error.set('');
    this.videoPop.set(false);
    this.insertBlock(`![${this.videoTitle().trim().replace(/[[\]]/g, '')}](${url})`);
  }

  // ---------- Archivos (imágenes y vídeos)
  onFiles(e: Event) {
    const input = e.target as HTMLInputElement;
    this.uploadAll(Array.from(input.files ?? []));
    input.value = '';
  }

  onPaste(e: ClipboardEvent) {
    const files = Array.from(e.clipboardData?.files ?? []);
    if (!files.length) return;
    e.preventDefault();
    this.uploadAll(files);
  }

  onDragOver(e: DragEvent) {
    if (e.dataTransfer?.types.includes('Files')) e.preventDefault();
  }

  onDrop(e: DragEvent) {
    const files = Array.from(e.dataTransfer?.files ?? []);
    if (!files.length) return;
    e.preventDefault();
    this.uploadAll(files);
  }

  private uploadAll(files: File[]) {
    if (!files.length) return;
    this.error.set('');
    this.toast('Subiendo…');
    const run = (i: number) => {
      if (i >= files.length) { this.toast('Insertado'); return; }
      this.ensureSong()().pipe(switchMap(id => this.data.uploadInfoMedia(id, files[i]))).subscribe({
        next: r => { this.insertBlock(`![${r.name.replace(/\.[^.]+$/, '')}](${r.url})`); run(i + 1); },
        error: err => {
          this.notice.set('');
          this.error.set(`No se pudo subir "${files[i].name}": ` + (err?.error?.message || err?.message || 'error desconocido'));
        },
      });
    };
    run(0);
  }
}
