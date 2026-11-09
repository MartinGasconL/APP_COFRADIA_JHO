import { test, expect } from '@playwright/test';
import { mockRepertorio } from '../fixtures/repertorio';

test('navegación inferior móvil y transición a escritorio @interfaz', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await mockRepertorio(page);
  await page.goto('/repertorio');
  const dock = page.getByRole('group', { name: 'Accesos principales' });
  await expect(dock).toBeVisible();
  await expect(dock.getByRole('link', { name: 'Repertorio' })).toHaveAttribute(
    'aria-current',
    'page',
  );
  await dock.getByRole('link', { name: 'Canciones' }).click();
  await expect(page).toHaveURL(/\/administracion\/canciones$/);
  await expect(page.getByRole('heading', { name: 'Canciones', exact: true })).toBeVisible();
  await dock.getByRole('link', { name: 'Estudio' }).focus();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/\/administracion\/estudio$/);
  await expect(dock.getByRole('link', { name: 'Estudio' })).toHaveAttribute('aria-current', 'page');
  await page.getByRole('button', { name: 'Abrir menú' }).click();
  await expect(dock).toBeHidden();
  await page.keyboard.press('Escape');
  await expect(dock).toBeVisible();
  await page.setViewportSize({ width: 1440, height: 900 });
  await expect(dock).toBeHidden();
  await expect(page.getByRole('navigation')).toBeVisible();
});

test('superficies legibles con transparencia reducida @interfaz', async ({ page }) => {
  const cdp = await page.context().newCDPSession(page);
  await cdp.send('Emulation.setEmulatedMedia', {
    features: [{ name: 'prefers-reduced-transparency', value: 'reduce' }],
  });
  await mockRepertorio(page);
  await page.goto('/repertorio');
  const panel = page.getByRole('region', { name: 'Filtrar repertorio' });
  await expect(panel).toBeVisible();
  await expect(panel).toHaveCSS('backdrop-filter', 'none');
  await expect(panel).toHaveCSS('background-color', 'rgb(255, 253, 248)');
  await page.getByRole('searchbox', { name: 'Buscar canción' }).fill('no existe');
  await expect(
    page.getByRole('heading', { name: 'No hay canciones con estos filtros' }),
  ).toBeVisible();
  await page.getByRole('button', { name: 'Limpiar filtros' }).click();
  await expect(page.locator('.songs > a')).toHaveCount(3);
});

test('acceso de escritorio con la nueva composición @interfaz', async ({ page }, testInfo) => {
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.goto('/login');
  await page.evaluate(() => document.fonts.ready.then(() => undefined));
  await expect(page.getByRole('heading', { name: 'La fuerza de tocar juntos.' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Entrar' })).toBeVisible();
  await page.screenshot({ path: testInfo.outputPath('login-1440.png'), fullPage: true });
});
