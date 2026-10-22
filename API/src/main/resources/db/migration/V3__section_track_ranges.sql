-- Cada pista de una parte pasa a tener su propio fragmento (inicio/fin).
-- La tabla anterior era solo join sin datos de rango, se puede recrear.
DROP TABLE IF EXISTS song_section_tracks;

CREATE TABLE song_section_tracks (
    id            BIGINT PRIMARY KEY AUTO_INCREMENT,
    section_id    BIGINT NOT NULL,
    track_type    VARCHAR(30) NOT NULL,
    start_seconds INT NOT NULL,
    end_seconds   INT NOT NULL,
    CONSTRAINT fk_section_tracks_section FOREIGN KEY (section_id) REFERENCES song_sections(id) ON DELETE CASCADE,
    CONSTRAINT uk_section_track UNIQUE (section_id, track_type)
);
