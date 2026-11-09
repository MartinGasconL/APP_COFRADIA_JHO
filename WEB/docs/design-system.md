# Sistema visual — Liquid Glass

Rediseño inspirado en las referencias de Liquid Glass aportadas: ventana flotante, navegación translúcida, superficies superpuestas y navegación inferior móvil. Conserva la paleta granate, crema, champán y terracota. Las rutas, servicios, modelos y el motor de audio se conservan.

## Organización

- `src/styles/_tokens.scss`: paleta, tipografía, espaciado, radios, sombras y movimiento. Los nombres antiguos (`--blue`, `--navy`, etc.) son alias temporales para las pantallas pendientes.
- `src/styles/_base.scss`: Manrope local, normalización, foco, movimiento reducido y fondo de diálogos.
- `src/styles/_surfaces.scss`: mixins de cristal y diálogos. No genera estilos por sí solo.
- `src/styles/_controls.scss`: mixins para botones primarios, secundarios y campos.
- `src/styles/_patterns.scss`: clases reutilizables `.card`, `.glass-panel`, `.primary-btn` y `.outline`.
- `src/styles/_scene.scss`: fondo cálido con formas decorativas CSS, sin imágenes externas ni interacciones.
- `src/styles/_workspace.scss`: presentación compartida de administración, formularios, reproductor, cronograma y notas.
- `src/styles.scss`: entrada única de estilos globales.
- `src/app/pages/repertorio.scss`: composición específica del piloto.
- `src/app/layout/shell.scss`: navegación, fondo cálido y cabecera translúcida.
- `src/app/pages/recorder-dialog.scss`: presentación de la grabadora separada de su lógica.
- `src/app/pages/login.scss`: acceso en dos columnas en escritorio y formulario compacto en móvil.
- `src/app/part-color.pipe.ts`: correspondencia visual de los seis colores históricos de partes con tokens cálidos, sin cambiar los datos almacenados ni los colores personalizados.

`pages.scss` mantiene los patrones de las pantallas existentes y consume los nuevos mixins. Su separación por pantalla queda para las siguientes fases.

## Uso de superficies

Usar `.glass-panel` en contenedores destacados, como el panel de filtros. El mixin `glass` permite aplicarlo a un elemento encapsulado, como la cabecera. Incluye fondo opaco de respaldo y respeta `prefers-reduced-transparency`.

Las tarjetas repetidas usan fondos claros, sin desenfoque individual. Campos, diálogos y superficies de edición mantienen fondos sólidos para preservar contraste y evitar nuevas capas de composición alrededor de controles de audio.

No aplicar `opacity` al contenedor para simular cristal: también vuelve transparente el texto. Los degradados radiales decorativos son fondos CSS y no capturan eventos.

## Tipografía y accesibilidad

Manrope variable se sirve desde `public/fonts/manrope-variable.ttf`, con su licencia OFL incluida. No requiere solicitudes a Google Fonts en ejecución. Se conserva una fuente alternativa del sistema.

Los controles principales tienen al menos 44 px de altura. Se mantienen etiquetas, enlace de salto al contenido, foco visible, navegación de teclado y gestión de foco de CDK. Los campos conservan texto de 16 px en móvil. La navegación cambia a menú móvil en 900 px, manteniendo el umbral utilizado por el componente.

Las etiquetas de Repertorio usan terracota y amarillo, siempre acompañadas de texto. La correspondencia de colores de partes se aplica exclusivamente al renderizar: cronograma, gráfico y editor muestran los mismos colores cálidos sin modificar los identificadores guardados.

La barra inferior ofrece las tres rutas existentes en pantallas de hasta 900 px. Se oculta al abrir el menú lateral y al pasar a escritorio. El contenido reserva espacio al final para que los controles sigan siendo accesibles por encima de la barra.

## Verificación

Ejecutar `npm run build` y `npm run test:e2e`. La batería de interfaz cubre 320, 390, 768, 1024 y 1440 px, filtros, navegación, ventanas, foco y edición de partes. Espera a la carga de fuentes para medir texto y comprueba también los paneles de cristal.

Revisar las capturas generadas en `test-results` para Repertorio, navegación y diálogos. Las pruebas usan datos simulados; no sustituyen la validación de integración con el backend.
