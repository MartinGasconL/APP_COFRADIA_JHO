-- Contenido de la sección "Información" (Markdown editable desde Administración > Canciones).
-- Tabla de una sola fila (id = 1).
CREATE TABLE info_page (
    id         BIGINT   NOT NULL PRIMARY KEY,
    content    MEDIUMTEXT NOT NULL,
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
);

INSERT INTO info_page (id, content) VALUES (1, '## Tips importantes

> Esta sección se edita desde **Administración › Canciones** y admite Markdown.

### Antes de empezar

- Escucha la canción completa antes de practicar una parte.
- Usa el **metrónomo** para fijar el tempo.
- Practica primero a velocidad lenta (0,75×) y sube poco a poco.

### Pregunta / respuesta

Cuando una parte es *pregunta* o *respuesta*, atiende siempre a quién entra primero.
');
