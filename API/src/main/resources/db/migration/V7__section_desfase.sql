-- Indicativo explícito por parte: en esta parte hay desfase de bombos.
-- No se deriva de las pistas asignadas; lo marca el usuario.
ALTER TABLE song_sections
    ADD COLUMN desfase BOOLEAN NOT NULL DEFAULT FALSE AFTER answer;
