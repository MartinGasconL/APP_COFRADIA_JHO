import { Page } from '@playwright/test';

const instruments = ['TAMBOR', 'BOMBO', 'BOMBO_DESFASE1', 'BOMBO_DESFASE2', 'COMPLETA'];
const section = (title: string, index: number, branch = false) => ({
  title,
  note: 'Escucha la entrada de los tambores y mantén el pulso hasta la respuesta de todos los bombos.',
  startSeconds: index * 30,
  endSeconds: (index + 1) * 30,
  color: ['#910000', '#0e7490', '#6d28d9'][index % 3],
  question: true,
  answer: false,
  desfase: true,
  branchKey: branch ? 'alternativa' : null,
  branchFrom: branch ? 0 : null,
  branchTo: branch ? 2 : null,
  branchActive: true,
  tracks: instruments.map((type) => ({
    type,
    startSeconds: index * 30,
    endSeconds: (index + 1) * 30,
  })),
});

export const songs = [
  { id: 1, title: 'La llamada de los tambores — encuentro de la cofradía', draft: false },
  { id: 2, title: 'Marcha de la plaza', draft: false },
  { id: 3, title: 'Redoble final', draft: false },
  { id: 4, title: 'Ensayo de la procesión — versión con respuesta de bombos', draft: true },
].map((song) => ({
  ...song,
  description:
    'Una marcha para tocar juntos, con entradas de tambor, respuestas y desfases de bombos.',
  bpm: 90,
  durationSeconds: 180,
  procession: true,
  exhibition: true,
  info: '## Antes de empezar\n\nEscucha la llamada y espera a la señal.\n\n> Mantén el pulso durante la respuesta.\n\n- Tambores: entrada suave\n- Bombos: respuesta conjunta',
  tracks: instruments.map((type, index) => ({
    id: index + 1,
    type,
    originalFilename: `grabacion_del_ensayo_general_con_respuesta_de_bombos_${type.toLowerCase()}.wav`,
    status: 'READY',
    durationSeconds: 180,
    version: 1,
  })),
  sections: [
    section('Llamada de entrada con todos los instrumentos', 0),
    section('Pregunta de tambores y respuesta de los bombos en dos grupos', 1),
    section('Cierre de la marcha y redoble final', 2),
    ...(song.draft ? [section('Respuesta alternativa con desfase de bombos', 1, true)] : []),
  ],
}));

// Audio silencioso local: verifica los controles sin depender de la API ni de grabaciones reales.
function silentWav() {
  const samples = 8000;
  const wav = Buffer.alloc(44 + samples * 2);
  wav.write('RIFF');
  wav.writeUInt32LE(wav.length - 8, 4);
  wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(8000, 24);
  wav.writeUInt32LE(16000, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write('data', 36);
  wav.writeUInt32LE(samples * 2, 40);
  return wav;
}

export async function mockRepertorio(page: Page) {
  await page.addInitScript(() => sessionStorage.setItem('cofradia.user', 'admin'));
  await page.route('**/api/**', async (route) => {
    const url = new URL(route.request().url());
    if (url.pathname.endsWith('/audio')) {
      return route.fulfill({ contentType: 'audio/wav', body: silentWav() });
    }
    const match = url.pathname.match(/\/songs(?:\/(\d+))?$/);
    if (match && route.request().method() === 'GET') {
      return route.fulfill({
        json: match[1] ? songs.find((s) => s.id === Number(match[1])) : songs,
      });
    }
    // Ninguna comprobación visual debe escribir en la base de datos real.
    return route.fulfill({ status: 405, json: { message: 'Solo lectura en la prueba visual' } });
  });
}
