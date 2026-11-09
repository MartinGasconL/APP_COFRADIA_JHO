import { PartColorPipe } from '../part-color.pipe';
import { Component, computed, effect, inject, OnDestroy, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { DataService, Parte, Track, TRACKS, TRACK_LABEL, TRACK_SHORT } from '../data.service';
import { AudioEngine } from '../audio-engine';
import { InfoView } from '../info/info-view';

@Component({
  imports: [PartColorPipe, CommonModule, FormsModule, RouterLink, InfoView],
  template: `
@if (song(); as s) {
<a class="back" routerLink="/repertorio">← Repertorio</a>
<header class="head"><div><p>CANCIÓN</p><h1>{{ s.title }}</h1><span>{{ s.description }}</span></div></header>

<section class="player card">
  <div>
    <button class="play" (click)="toggle()" [disabled]="!canPlay()" [attr.aria-label]="engine.playing() ? 'Pausar' : 'Reproducir'">
      <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">@if (engine.playing()) { <path fill="currentColor" d="M6 4h4v16H6zM14 4h4v16h-4z"/> } @else { <path fill="currentColor" d="M8 5v14l11-7z"/> }</svg>
    </button>
    <button (click)="engine.stop()" [disabled]="!canPlay()" aria-label="Parar"><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path fill="currentColor" d="M6 6h12v12H6z"/></svg></button>
    <strong>{{ fmt(engine.position()) }} / {{ fmt(engine.duration()) }}</strong>
  </div>

  <div class="ctl">
    <span class="ctl-title" id="pistas-title">Pistas</span>
    <div class="track-box" role="group" aria-labelledby="pistas-title">
      @for (b of trackButtons; track b.key) {
        <button type="button" class="track-seg"
          [class.on]="isOn(b.key)" [class.locked]="!hasTrack(b.key)"
          [disabled]="!hasTrack(b.key)" [attr.aria-pressed]="hasTrack(b.key) ? isOn(b.key) : null"
          [attr.aria-label]="b.label + (hasTrack(b.key) ? '' : ' (sin pista)')"
          [title]="hasTrack(b.key) ? b.label : 'Esta canción no tiene pista de ' + b.label.toLowerCase()"
          (click)="toggleTrack(b.key)">
          <img [src]="b.img" alt="" width="30" height="30">
          <span><b>{{ b.label }}</b>@if (!hasTrack(b.key)) { <em>sin pista</em> }</span>
        </button>
      }
    </div>
  </div>

  <div class="ctl">
    <span class="ctl-title">Velocidad</span>
    <button type="button" class="rate-btn" (click)="nextRate()" [attr.aria-label]="'Velocidad ' + rateLabel() + '. Pulsa para cambiarla'" title="Pulsa para cambiar la velocidad">
      <b>{{ rateLabel() }}</b>
      <span class="rate-bars" aria-hidden="true">@for (i of [0, 1, 2, 3]; track i) { <i [class.on]="i <= rateStep()"></i> }</span>
    </button>
  </div>

  <div class="progress" (click)="scrub($event)"><span [style.width.%]="pct()"></span></div>

  @if (engine.loading()) { <small>Cargando audio…</small> }
  @else if (converting()) { <small>Convirtiendo audio subido, estará disponible en unos segundos…</small> }
  @else if (engine.error()) { <small>{{ engine.error() }}</small> }
</section>

<div class="tabs" role="tablist">
  <button type="button" role="tab" [class.on]="tab() === 'cancion'" [attr.aria-selected]="tab() === 'cancion'" (click)="tab.set('cancion')">Canción</button>
  <button type="button" role="tab" [class.on]="tab() === 'info'" [attr.aria-selected]="tab() === 'info'" (click)="tab.set('info')">Información</button>
</div>

@if (tab() === 'info') {
<section class="info-page card">
  <app-info-view [markdown]="s.info" emptyText="Esta canción aún no tiene información." />
</section>
} @else {
<div class="song-detail-grid">
  <section class="timeline card">
    <header>
      <div><h2>Cronograma</h2><span>Pulsa una parte para escucharla.</span></div>
      <button type="button" class="bpm-btn" [class.on]="engine.metronomeOn()"
        (click)="engine.toggleMetronome(s.bpm)"
        [title]="engine.metronomeOn() ? 'Parar metrónomo' : 'Metrónomo a ' + s.bpm + ' BPM'">
        <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" d="m12 3 6 17H6L12 3Zm0 3-3 9m3-9 1.5 4.5"/></svg>
        {{ s.bpm }} BPM
      </button>
    </header>
    @for (part of s.partes; track part.name) {
    <button class="part"
      [class.playing]="engine.position() >= part.start && engine.position() < part.end"
      [class.selected]="selectedPart() === part"
      [style.--c]="part.color | partColor" (click)="playPart(part)">
      <i><u></u></i>
      <div>
        <small>{{ fmt(part.start) }} — {{ fmt(part.end) }}</small>
        <strong>{{ part.name }}</strong>
        <span>{{ part.note }}</span>
        <p>
          @for (t of part.tracks; track t.track) { <em>{{ short[t.track] }}</em> }
          <em class="pink" *ngIf="part.question || part.answer">{{ part.question ? 'Pregunta' : 'Respuesta' }}</em>
          <em class="tag-desfase" *ngIf="part.desfase">Desfase</em>
        </p>
      </div>
    </button>
    }
  </section>

  <aside class="notes card">
    <header><div class="notes-icon">✎</div><div><p>NOTAS</p><h2>{{ selectedPart() ? selectedPart()!.name : 'Canción completa' }}</h2></div></header>
    @if (selectedPart(); as p) {
      <p class="note-time">{{ fmt(p.start) }} — {{ fmt(p.end) }}</p>
      <p>{{ p.note || 'Sin nota específica para esta parte.' }}</p>
    } @else {
      <p>{{ s.description || 'Sin nota general.' }}</p>
      <p>Selecciona una parte del cronograma para ver sus indicaciones concretas.</p>
    }
    <div class="note-tip">Las notas se editan desde Administración.</div>
  </aside>
</div>
}
}
  `,

})
export class Cancion implements OnInit, OnDestroy {
  private data = inject(DataService);
  private route = inject(ActivatedRoute);
  readonly engine = inject(AudioEngine);

  tab = signal<'cancion' | 'info'>('cancion');

  labels = TRACK_LABEL;
  short = TRACK_SHORT;

  private id = Number(this.route.snapshot.paramMap.get('id'));
  song = computed(() => this.data.find(this.id));
  selectedPart = signal<Parte | null>(null);
  /** Pistas marcadas (multiselección): suenan a la vez. */
  selectedTracks = signal<Track[]>([]);

  /** Botones fijos del selector. Las pistas que la canción no tenga salen bloqueadas. */
  readonly trackButtons: { key: string; label: string; img: string }[] = [
    { key: 'tambor', label: 'Tambor', img: 'pistas/bombo.png' },
    { key: 'bombo', label: 'Bombo', img: 'pistas/tambor.png' },
    { key: 'corneta', label: 'Corneta', img: 'pistas/corneta.png' },
  ];
  private readonly mainKeys = this.trackButtons.map(b => b.key);

  private poll?: number;

  converting = computed(() =>
    Object.values(this.song()?.tracks ?? {}).some(t => t?.status === 'PROCESSING' || t?.status === 'PENDING'));

  canPlay = computed(() => this.availableTracks().length > 0);

  /** Pistas con audio listo, en el orden fijo del MVP. */
  availableTracks = computed(() => {
    const loaded = this.engine.loadedTracks();
    return TRACKS.filter(t => loaded.includes(t));
  });

  constructor() {
    // Mantén la selección dentro de las pistas disponibles; por defecto, todas las principales.
    effect(() => {
      const avail = this.availableTracks();
      const sel = this.selectedTracks();
      const valid = sel.filter(t => avail.includes(t));
      if (valid.length !== sel.length) {
        this.selectedTracks.set(valid);
      } else if (!valid.length && avail.length) {
        const main = avail.filter(t => this.mainKeys.includes(t));
        this.selectedTracks.set(main.length ? main : [avail[0]]);
      }
    });
    // Suenan todas las pistas marcadas a la vez.
    effect(() => this.engine.setActiveTracks(this.selectedTracks()));
  }

  ngOnInit() {
    const load = () => {
      const s = this.song();
      if (s) this.engine.loadSong(s, t => this.data.audioUrl(s.id, t));
    };
    if (this.song()) load();
    else this.data.refresh(this.id).subscribe(load);

    this.poll = window.setInterval(() => {
      if (!this.converting()) return;
      this.data.refresh(this.id).subscribe(() => {
        if (!this.converting()) load();
      });
    }, 3000);
  }

  ngOnDestroy() {
    clearInterval(this.poll);
    this.engine.release();
  }

  private readonly rates = [0.75, 1, 1.25, 1.5];

  rateStep() {
    return Math.max(0, this.rates.indexOf(this.engine.rate()));
  }

  rateLabel() {
    return String(this.engine.rate()).replace('.', ',') + '×';
  }

  /** Sube un escalón de velocidad; tras el más rápido vuelve al más lento. */
  nextRate() {
    const i = this.rates.indexOf(this.engine.rate());
    this.engine.setRate(this.rates[(i + 1) % this.rates.length]);
  }

  hasTrack(key: string) {
    return this.availableTracks().includes(key as Track);
  }

  isOn(key: string) {
    return this.selectedTracks().includes(key as Track);
  }

  /** Marca o desmarca una pista. Siempre queda al menos una marcada. */
  toggleTrack(key: string) {
    const t = key as Track;
    if (!this.hasTrack(key)) return;
    const sel = this.selectedTracks();
    if (!sel.includes(t)) this.selectedTracks.set([...sel, t]);
    else if (sel.length > 1) this.selectedTracks.set(sel.filter(x => x !== t));
  }

  toggle() {
    this.engine.playing() ? this.engine.pause() : this.engine.play();
  }

  playPart(part: Parte) {
    this.selectedPart.set(part);
    const loaded = this.engine.loadedTracks();
    const wins = this.selectedTracks().filter(t => loaded.includes(t)).map(track => {
      // Intervalo propio de la pista dentro de la parte, si lo tiene.
      const own = part.tracks.find(t => t.track === track);
      return { track, start: own ? own.start : part.start, end: own ? own.end : part.end };
    });
    if (!wins.length) return;
    this.engine.play(Math.min(...wins.map(w => w.start)), Math.max(...wins.map(w => w.end)), wins);
  }

  scrub(event: MouseEvent) {
    const el = event.currentTarget as HTMLElement;
    const ratio = (event.clientX - el.getBoundingClientRect().left) / el.clientWidth;
    this.engine.seek(ratio * this.engine.duration());
  }

  pct() {
    const d = this.engine.duration();
    return d ? (this.engine.position() / d) * 100 : 0;
  }

  fmt(n: number) {
    return `${String(Math.floor(n / 60)).padStart(2, '0')}:${String(Math.floor(n % 60)).padStart(2, '0')}`;
  }
}
