# Revisión de interfaz

Rama: `feature/mejora-interfaz`. Fecha: 22 de octubre de 2026.

La revisión cubre acceso, repertorio, detalle de canción, administración, creación y edición de canciones, estudio, edición de partes y ventanas de grabación y edición.

## Problemas encontrados y correcciones

| Problema observado                             | Causa                                                                | Corrección                                                                                   |
| ---------------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Opciones de filtros cortadas                   | Etiqueta y valor dentro de selectores demasiado estrechos            | Etiquetas visibles separadas, opciones breves y distribución adaptable                       |
| Tarjetas de pistas fuera del formulario        | Columnas rígidas, mínimos implícitos y nombres de archivo largos     | Columnas según espacio disponible, `min-width: 0` y salto de línea en los nombres            |
| Botones de subida mal alineados                | Los estilos generales de las etiquetas sobrescribían su distribución | Reglas específicas para los controles de archivo y tamaños coherentes                        |
| Etiquetas del repertorio amontonadas           | Filas sin salto de línea                                             | Etiquetas flexibles, espaciado uniforme y títulos completos                                  |
| Partes del cronograma superpuestas             | Filas fijas de 56 px, independientemente de la altura del contenido  | Medición con `ResizeObserver` y separación según la etiqueta más alta de cada fila           |
| Texto del grafo con formato incorrecto         | Los estilos encapsulados del padre no alcanzaban al componente       | Estilos propios para títulos, etiquetas y estados del grafo                                  |
| Cronograma difícil de usar en móvil            | Diagrama más ancho que su contenedor                                 | Vista de tarjetas cuando el contenedor tiene 640 px o menos, con edición, escucha y opciones |
| Botones y columnas apretados en administración | Espacio insuficiente para título, uso, tempo, pistas y acciones      | Distribución vertical en móvil, manteniendo los datos y las acciones visibles                |
| Barra de guardado sobre los campos en móvil    | Posición fija dentro del desplazamiento                              | Barra en el flujo normal en pantallas pequeñas                                               |
| Estilos incoherentes entre componentes         | Mezcla de estilos globales, encapsulados y repetidos                 | Base visual común y hoja de páginas cargada una vez, limitada a `.page-content`              |

Se mantienen los tonos granate y crema de la aplicación. Se han ajustado la tipografía, las superficies, la jerarquía de encabezados, las separaciones, el menú lateral y los indicadores de navegación. Los filtros incluyen contador y acción para limpiarlos.

Las ventanas tienen nombre accesible, contención del foco, restauración del foco y cierre con Escape. El menú móvil se oculta también para la navegación por teclado cuando está cerrado. Los controles de subida pueden recibir foco. Se respetan las preferencias de movimiento reducido.

## Verificación

Desde `WEB`:

```powershell
npm.cmd run build
npm.cmd run test:e2e:interfaz
```

- Compilación de producción correcta, sin avisos de presupuesto.
- 43 pruebas de Chromium correctas.
- Siete pantallas comprobadas a 320, 390, 768, 1024 y 1440 px.
- Pruebas adicionales de filtros, estado vacío, acceso, reproducción, pestaña de información, menú móvil, ventanas y formularios nuevos.
- Cronograma comprobado a 1680 px, también aumentando el tamaño de sus títulos para verificar que las filas se vuelven a medir, y reordenando partes mediante arrastre.
- Capturas generadas en `test-results/` y reporte en `playwright-report/`.

Las pruebas interceptan las peticiones de la API y usan canciones de prueba con títulos largos, todos los indicativos, ramas y nombres de archivo extensos. La reproducción usa audio silencioso generado localmente. No escriben en la base de datos. La configuración de Playwright ajusta HTTP/HTTPS al `baseURL`, evitando que el servidor se inicie con un protocolo distinto del esperado.

Esta validación cubre la presentación y las interacciones del cliente en Chromium con ventanas de distintos tamaños. No sustituye una prueba de subida/grabación con micrófono real, persistencia contra la API ni una comprobación en Safari/iOS.
