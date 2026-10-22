-- Migración: documentos pendientes por cliente
-- Ejecutar una sola vez sobre la BD existente antes de reiniciar el backend

USE aseint;

ALTER TABLE catalog_required_document
    ADD COLUMN requires_signature BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE document_group
    ADD COLUMN catalog_required_document_id BIGINT NULL,
    ADD CONSTRAINT fk_dg_crd
        FOREIGN KEY (catalog_required_document_id)
        REFERENCES catalog_required_document (id);
