-- Metadatos de audio por pista y base para versiones futuras de una misma canción.
ALTER TABLE song_tracks
    ADD COLUMN content_type     VARCHAR(120) NULL AFTER media_status,
    ADD COLUMN size_bytes       BIGINT       NULL AFTER content_type,
    ADD COLUMN duration_seconds INT          NULL AFTER size_bytes,
    ADD COLUMN media_version    INT          NOT NULL DEFAULT 1 AFTER duration_seconds,
    ADD COLUMN updated_at       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER media_version;

-- Estados: PENDING -> PROCESSING -> READY | FAILED
ALTER TABLE song_tracks ALTER COLUMN media_status SET DEFAULT 'PENDING';
