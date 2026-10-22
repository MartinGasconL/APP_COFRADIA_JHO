-- Borrado lógico de canciones oficiales (los borradores se borran físicamente).
ALTER TABLE songs
    ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT FALSE;
