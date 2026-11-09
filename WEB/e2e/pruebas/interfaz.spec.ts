import { test, expect, Page } from '@playwright/test';
import { mockRepertorio } from '../fixtures/repertorio';

const screens = [
  ['repertorio', '/repertorio'],
  ['cancion', '/repertorio/1'],
  ['administracion', '/administracion/canciones'],
  ['edicion', '/administracion/canciones/1'],
  ['borradores', '/administracion/estudio'],
  ['estudio', '/administracion/estudio/4'],
  ['parte', '/administracion/estudio/4/parte/0'],
] as const;

async function assertLayout(page: Page) {
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
  await expect(page.locator('vite-error-overlay')).toHaveCount(0);
  const problems = await page.evaluate(() => {
    const issues: string[] = [];
    const width = document.documentElement.clientWidth;
    if (document.documentElement.scrollWidth > width + 1)
      issues.push('Desbordamiento horizontal del documento');
    const visible = (el: HTMLElement) =>
      !!el.getClientRects().length && getComputedStyle(el).visibility !== 'hidden';
    for (const el of document.querySelectorAll<HTMLElement>(
      '.card, .glass-panel, .head, .form-actions, .track-card, .mobile-node, [role="dialog"]',
    )) {
      if (!visible(el)) continue;
      const rect = el.getBoundingClientRect();
      if (rect.left < -1 || rect.right > width + 1)
        issues.push(`${el.className}: fuera de la pantalla`);
      if (el.scrollWidth > el.clientWidth + 1)
        issues.push(`${el.className}: contenido más ancho que su contenedor`);
    }
    for (const el of document.querySelectorAll<HTMLElement>(
      '.songs p b, .part em, .graph-tags em, .head h1, .mobile-title strong, .graph-label strong, .track-name, .track-state, .filters label, .primary-btn, .file-btn, .rec-btn',
    )) {
      if (!visible(el)) continue;
      const style = getComputedStyle(el);
      const clippedHeight =
        ['hidden', 'clip'].includes(style.overflowY) && el.scrollHeight > el.clientHeight + 1;
      if (el.scrollWidth > el.clientWidth + 1 || clippedHeight) {
        issues.push(
          `${el.className || el.tagName}: texto cortado: ${el.textContent?.trim().slice(0, 70)}`,
        );
      }
    }
    const context = document.createElement('canvas').getContext('2d')!;
    for (const select of document.querySelectorAll<HTMLSelectElement>(
      '.filters select, .player select',
    )) {
      const style = getComputedStyle(select);
      context.font = `${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
      const textWidth = context.measureText(select.selectedOptions[0]?.text ?? '').width;
      const available =
        select.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
      if (textWidth > available + 1)
        issues.push(`Opción recortada: ${select.selectedOptions[0]?.text}`);
    }
    return issues;
  });
  expect(problems).toEqual([]);
}

for (const width of [320, 390, 768, 1024, 1440]) {
  test.describe(`Pantalla ${width}px @interfaz`, () => {
    test.use({ viewport: { width, height: 900 } });
    for (const [name, path] of screens) {
      test(`${name}: textos y contenedores completos`, async ({ page }, testInfo) => {
        const errors: string[] = [];
        page.on('pageerror', (error) => errors.push(error.message));
        await mockRepertorio(page);
        await page.goto(path);
        await expect(page.locator('h1')).toBeVisible();
        await expect(
          page.locator('.songs > a, .admin-list > a, .section, .timeline').first(),
        ).toBeVisible();
        await assertLayout(page);
        await page.screenshot({
          path: testInfo.outputPath(`${name}-${width}.png`),
          fullPage: true,
        });
        expect(errors).toEqual([]);
      });
    }
  });
}

test('filtros, estado vacío y navegación al detalle @interfaz', async ({ page }) => {
  await mockRepertorio(page);
  await page.goto('/repertorio');
  await expect(page.locator('.songs > a')).toHaveCount(3);
  await page.getByLabel('Buscar canción').fill('plaza');
  await expect(page.locator('.songs > a')).toHaveCount(1);
  await page.getByLabel('Desfase de bombos').selectOption('no');
  await expect(
    page.getByRole('heading', { name: 'No hay canciones con estos filtros' }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Limpiar filtros' }).click();
  await expect(page.locator('.songs > a')).toHaveCount(3);
  await page.locator('.songs > a').first().click();
  await expect(page).toHaveURL(/\/repertorio\/1$/);
  await expect(page.getByRole('button', { name: 'Reproducir', exact: true })).toBeEnabled();
  await page.getByRole('button', { name: 'Reproducir', exact: true }).click();
  await expect(page.getByRole('button', { name: 'Pausar', exact: true })).toBeVisible();
  await page.getByRole('button', { name: 'Parar', exact: true }).click();
  await page.getByRole('tab', { name: 'Información' }).click();
  await expect(page.getByRole('heading', { name: 'Antes de empezar' })).toBeVisible();
});

test('menú móvil, teclado y cambio a escritorio @interfaz', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await mockRepertorio(page);
  await page.goto('/repertorio');
  await expect(page.getByRole('navigation')).toBeHidden();
  await page.getByRole('button', { name: 'Abrir menú' }).click();
  await expect(page.getByRole('navigation')).toBeVisible();
  await expect(page.getByRole('button', { name: 'Abrir menú' })).toHaveAttribute(
    'aria-expanded',
    'true',
  );
  await page.keyboard.press('Escape');
  await expect(page.getByRole('navigation')).toBeHidden();
  await page.getByRole('button', { name: 'Abrir menú' }).click();
  await page.getByRole('navigation').getByRole('link', { name: 'Estudio' }).click();
  await expect(page).toHaveURL(/\/administracion\/estudio$/);
  await expect(page.getByRole('navigation')).toBeHidden();
  await page.getByRole('button', { name: 'Abrir menú' }).click();
  await page.setViewportSize({ width: 1440, height: 900 });
  await expect(page.locator('.layout')).not.toHaveClass(/nav-open/);
  await expect(page.getByRole('navigation')).toBeVisible();
});

for (const width of [320, 768, 1440]) {
  test(`ventanas de edición y grabación a ${width}px @interfaz`, async ({ page }, testInfo) => {
    await page.setViewportSize({ width, height: 700 });
    await mockRepertorio(page);
    await page.goto('/administracion/canciones/1');
    await page.getByRole('button', { name: '+ Añadir parte', exact: true }).click();
    const dialog = page.getByRole('dialog', { name: 'Añadir parte', exact: true });
    await expect(dialog).toBeVisible();
    await assertLayout(page);
    await page.screenshot({ path: testInfo.outputPath(`modal-parte-${width}.png`) });
    await dialog.getByRole('button', { name: 'Guardar parte', exact: true }).focus();
    await page.keyboard.press('Tab');
    await expect(dialog.getByRole('button', { name: 'Cerrar edición de parte' })).toBeFocused();
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await expect(page.getByRole('button', { name: '+ Añadir parte', exact: true })).toBeFocused();
    await page.getByRole('button', { name: 'Grabar', exact: true }).first().click();
    await expect(
      page.getByRole('dialog', { name: 'Grabar pista desde el micrófono' }),
    ).toBeVisible();
    await assertLayout(page);
    await page.screenshot({ path: testInfo.outputPath(`grabadora-${width}.png`) });
    await page.keyboard.press('Escape');
    await expect(page.getByRole('dialog')).toHaveCount(0);
  });
}

test('cronograma sin solapamientos y edición móvil @interfaz', async ({ page }, testInfo) => {
  await page.setViewportSize({ width: 1680, height: 1000 });
  await mockRepertorio(page);
  await page.goto('/administracion/estudio/4');
  await expect(page.locator('.graph-scroll')).toBeVisible();
  const overlaps = () =>
    page.locator('.graph-label').evaluateAll((labels) => {
      const rects = labels.map((label) => label.getBoundingClientRect());
      return rects.flatMap((a, i) =>
        rects
          .slice(i + 1)
          .filter(
            (b) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top,
          ),
      );
    });
  await expect.poll(async () => (await overlaps()).length).toBe(0);
  // El tamaño del texto también debe provocar una nueva medida de las filas.
  await page.addStyleTag({ content: '.graph-label strong { font-size: 24px !important; }' });
  await expect.poll(async () => (await overlaps()).length).toBe(0);
  await page.screenshot({
    path: testInfo.outputPath('cronograma-texto-grande.png'),
    fullPage: true,
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await expect(page.locator('.graph-scroll')).toBeHidden();
  await expect(page.locator('.mobile-node')).toHaveCount(4);
  await assertLayout(page);
  await page.getByRole('button', { name: 'Opciones de Llamada', exact: false }).click();
  await expect(page.getByRole('button', { name: 'Crear parte alternativa' })).toBeVisible();
  await assertLayout(page);
  await page.getByRole('button', { name: 'Editar parte', exact: true }).click();
  await expect(page).toHaveURL(/\/parte\/0$/);
});

test('acceso en móvil y formulario de canción nueva @interfaz', async ({ page }, testInfo) => {
  await page.setViewportSize({ width: 320, height: 640 });
  await page.goto('/login');
  await expect(page.getByRole('heading', { name: 'Repertorio' })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('login-320.png') });
  await page.getByLabel('Usuario').fill('incorrecto');
  await page.getByLabel('Contraseña').fill('incorrecta');
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('alert')).toContainText('Usuario o contraseña incorrectos');
  await mockRepertorio(page);
  await page.getByLabel('Usuario').fill('admin');
  await page.getByLabel('Contraseña').fill('admin');
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page).toHaveURL(/\/repertorio$/);
  await page.goto('/administracion/canciones/nueva');
  await expect(page.getByRole('heading', { name: 'Crear canción' })).toBeVisible();
  await assertLayout(page);
  await page.goto('/administracion/estudio/nueva');
  await expect(page.getByRole('heading', { name: 'Crear canción' })).toBeVisible();
  await assertLayout(page);
});

test('reordenar partes con alturas variables @interfaz', async ({ page }) => {
  await page.setViewportSize({ width: 1680, height: 1200 });
  await mockRepertorio(page);
  await page.goto('/administracion/estudio/4');
  await expect(page.locator('.graph-scroll')).toBeVisible();
  await page.locator('.graph-scroll').scrollIntoViewIfNeeded();
  const titles = page.locator('.graph-label[data-key^="m"] strong');
  const firstTitle = await titles.first().textContent();
  const secondTitle = await titles.nth(1).textContent();
  const first = page.locator('.g-hit').first();
  const second = page.locator('.g-hit').nth(1);
  const a = await first.boundingBox();
  const b = await second.boundingBox();
  expect(a).not.toBeNull();
  expect(b).not.toBeNull();
  await page.mouse.move(a!.x + a!.width / 2, a!.y + a!.height / 2);
  await page.mouse.down();
  // La pulsación prolongada activa el gesto de arrastre de la aplicación.
  await expect(page.locator('.g-node').first()).toHaveAttribute('r', '9');
  await page.mouse.move(b!.x + b!.width / 2, b!.y + b!.height / 2, { steps: 8 });
  await page.mouse.up();
  await expect(titles.first()).toHaveText(secondTitle!);
  await expect(titles.nth(1)).toHaveText(firstTitle!);
});
