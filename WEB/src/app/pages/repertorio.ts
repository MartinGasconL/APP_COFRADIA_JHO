import { Component, computed, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { DataService, Song } from '../data.service';

@Component({
  imports: [CommonModule, FormsModule, RouterLink],
  template: `
<header class="head">
  <div><p>ESPACIO DE SOCIOS</p><h1>Repertorio</h1><span>Las marchas que nos unen. Encuentra tu canción y prepara el próximo ensayo.</span></div>
</header>

<section class="filters card" aria-label="Filtrar repertorio">
  <label class="search-filter">Buscar canción
  <input type="search" [ngModel]="search()" (ngModelChange)="search.set($event)" placeholder="Escribe un título…"></label>
  <label>Uso
  <select [ngModel]="use()" (ngModelChange)="use.set($event)">
    <option value="todos">Todos los usos</option>
    <option value="procesion">Procesión</option>
    <option value="exhibicion">Exhibición</option>
  </select></label>
  <label>Pregunta / respuesta
  <select [ngModel]="qa()" (ngModelChange)="qa.set($event)">
    <option value="todos">Todas</option>
    <option value="si">Con respuesta</option>
    <option value="no">Sin respuesta</option>
  </select></label>
  <label>Desfase de bombos
  <select [ngModel]="desfase()" (ngModelChange)="desfase.set($event)">
    <option value="todos">Todos</option>
    <option value="si">Con desfase</option>
    <option value="no">Sin desfase</option>
  </select></label>
</section>

<div class="list-summary">
  <p role="status">{{ filtered().length }} {{ filtered().length === 1 ? 'canción disponible' : 'canciones disponibles' }}</p>
  @if (hasFilters()) { <button type="button" class="reset-filters" (click)="resetFilters()">Limpiar filtros</button> }
</div>
<section class="songs">
  @for (s of filtered(); track s.id) {
  <a class="card" [routerLink]="['/repertorio', s.id]">
    <i aria-hidden="true">♬</i>
    <div>
      <h2>{{ s.title }}</h2>
      <span>{{ s.description }}</span>
      <p>
        <b *ngIf="s.procesion">Procesión</b>
        <b *ngIf="s.exhibicion">Exhibición</b>
        <b class="tag-desfase" *ngIf="hasDesfase(s)">Desfase de bombos</b>
        <b class="pink" *ngIf="s.qa">Pregunta / respuesta</b>
      </p>
    </div>
    <aside><strong>{{ format(s.duration) }}</strong><small>{{ s.bpm }} BPM</small></aside>
    <span class="song-arrow" aria-hidden="true">›</span>
  </a>
  } @empty {
  <div class="card empty"><h2>No hay canciones con estos filtros</h2><p>Prueba otro título o limpia los filtros para ver todo el repertorio.</p></div>
  }
</section>
  `,

})
export class Repertorio {
  private data = inject(DataService);
  search = signal('');
  use = signal('todos');
  qa = signal('todos');
  desfase = signal('todos');
  hasFilters = computed(() => !!this.search() || this.use() !== 'todos' || this.qa() !== 'todos' || this.desfase() !== 'todos');

  resetFilters() {
    this.search.set('');
    this.use.set('todos');
    this.qa.set('todos');
    this.desfase.set('todos');
  }

  filtered = computed(() => {
    const search = this.search().toLowerCase();
    const use = this.use();
    const qa = this.qa();
    const desfase = this.desfase();
    return this.data.songs().filter(s => {
      if (s.draft) return false;
      const u = use === 'todos' || (use === 'procesion' && s.procesion) || (use === 'exhibicion' && s.exhibicion);
      const q = qa === 'todos' || (qa === 'si') === s.qa;
      const d = desfase === 'todos' || (desfase === 'si') === this.hasDesfase(s);
      const text = !search || s.title.toLowerCase().includes(search);
      return u && q && d && text;
    });
  });

  hasDesfase(s: Song) {
    const parts = [...s.partes, ...(s.ramas ?? []).flatMap(r => r.partes)];
    return parts.some(p => p.desfase);
  }

  format(n: number) {
    return `${String(Math.floor(n / 60)).padStart(2, '0')}:${String(n % 60).padStart(2, '0')}`;
  }
}
