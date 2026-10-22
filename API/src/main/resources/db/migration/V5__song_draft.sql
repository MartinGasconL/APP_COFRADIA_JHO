-- Borradores del Estudio vs canciones oficiales. Las existentes quedan como oficiales.
ALTER TABLE songs ADD COLUMN draft BOOLEAN NOT NULL DEFAULT FALSE;
