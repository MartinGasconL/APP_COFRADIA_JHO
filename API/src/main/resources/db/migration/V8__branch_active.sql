-- Ruta activa de una rama: si TRUE la canción sigue la rama; si FALSE sigue la línea principal.
-- Permite conservar tanto la parte original como su alternativa y alternar entre ambas.
-- Se repite en todas las secciones que comparten branch_key (como branch_from / branch_to).
ALTER TABLE song_sections
    ADD COLUMN branch_active BOOLEAN NOT NULL DEFAULT TRUE AFTER branch_to;
