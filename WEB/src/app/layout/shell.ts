import { Component, DestroyRef, HostListener, OnInit, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { A11yModule } from '@angular/cdk/a11y';
import { Router, NavigationEnd, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { filter } from 'rxjs';
import { AuthService } from '../core/auth.service';
import { DataService } from '../data.service';

@Component({
  imports: [RouterOutlet, RouterLink, RouterLinkActive, A11yModule],
  template: `
<div class="layout" [class.nav-open]="navOpen()">
  <a class="skip-link" href="#contenido">Saltar al contenido</a>
  <aside id="navigation" [cdkTrapFocus]="navOpen()">
    <header>
      <i aria-hidden="true">♬</i>
      <span><b>Cofradía</b><small>Repertorio</small></span>
      <button type="button" class="nav-close" (click)="closeNav()" aria-label="Cerrar menú">×</button>
    </header>
    <nav aria-label="Navegación principal">
      <p class="nav-label">Tu música</p>
      <a routerLink="/repertorio" routerLinkActive="active" ariaCurrentWhenActive="page" (click)="navOpen.set(false)"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 18V5l11-2v13M9 8l11-2"/><ellipse cx="6" cy="18" rx="3" ry="2"/><ellipse cx="17" cy="16" rx="3" ry="2"/></svg>Repertorio</a>
      <p class="nav-label">Administración</p>
      <a routerLink="/administracion/canciones" routerLinkActive="active" ariaCurrentWhenActive="page" (click)="navOpen.set(false)"><svg viewBox="0 0 24 24" aria-hidden="true"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M8 16h5"/></svg>Canciones</a>
      <a routerLink="/administracion/estudio" routerLinkActive="active" ariaCurrentWhenActive="page" (click)="navOpen.set(false)"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 3v18M12 3v18M19 3v18M2 8h6M9 16h6M16 9h6"/></svg>Estudio</a>
    </nav>
    <div class="sidebar-footer"><span>ASOCIACIÓN</span><p>Tambores y bombos</p></div>
  </aside>

  <div class="scrim" (click)="closeNav()" aria-hidden="true"></div>

  <main>
    <div class="topbar">
      <button type="button" class="icon-btn menu" (click)="navOpen.set(!navOpen())" aria-label="Abrir menú" [attr.aria-expanded]="navOpen()" aria-controls="navigation">
        <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="M4 7h16M4 12h16M4 17h16"/></svg>
      </button>
      <span class="topbar-title">Asociación de tambores y bombos</span>
      <button type="button" class="icon-btn user" (click)="logout()" title="Cerrar sesión" aria-label="Cerrar sesión">
        <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" d="M9 4H4v16h5M10 12h10m-4-4 4 4-4 4"/></svg>
      </button>
    </div>
    <article class="page-content" id="contenido" tabindex="-1"><router-outlet /></article>
  </main>
</div>
  `,
  styleUrl: './shell.scss',
})
export class Shell implements OnInit {
  private auth = inject(AuthService);
  private router = inject(Router);
  private data = inject(DataService);
  private destroyRef = inject(DestroyRef);

  navOpen = signal(false);

  ngOnInit() {
    this.data.load().subscribe();
    this.router.events.pipe(filter(e => e instanceof NavigationEnd), takeUntilDestroyed(this.destroyRef))
      .subscribe(() => this.navOpen.set(false));
  }

  @HostListener('document:keydown.escape')
  closeNav() { this.navOpen.set(false); }

  @HostListener('window:resize')
  onResize() { if (window.innerWidth > 900) this.navOpen.set(false); }

  logout() {
    this.navOpen.set(false);
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
