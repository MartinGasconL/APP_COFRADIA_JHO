-- migration-002-drive-hierarchy.sql
-- Adds folder hierarchy support to document_group

ALTER TABLE document_group
    ADD COLUMN parent_id BIGINT NULL AFTER notes,
    ADD COLUMN is_folder TINYINT(1) NOT NULL DEFAULT 0 AFTER parent_id;

ALTER TABLE document_group
    ADD CONSTRAINT fk_doc_group_parent
        FOREIGN KEY (parent_id) REFERENCES document_group(id) ON DELETE CASCADE;

-- Mark existing empty groups (no documents, status ACTIVE) as folders
UPDATE document_group
SET is_folder = 1
WHERE status = 'ACTIVE'
  AND id NOT IN (SELECT DISTINCT document_group_id FROM document);
