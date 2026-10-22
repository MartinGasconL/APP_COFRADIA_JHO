-- El recorte de audio de una pista dentro de una parte necesita precisión de fracción de segundo.
ALTER TABLE song_section_tracks
    MODIFY start_seconds DOUBLE NOT NULL,
    MODIFY end_seconds   DOUBLE NOT NULL;
