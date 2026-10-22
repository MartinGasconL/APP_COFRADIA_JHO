-- migration-005-catalog-steps.sql
-- Añade icon, color, is_builtin, campos_extra a catalog
-- Crea tabla catalog_step para plantillas de pasos

USE aseint;

ALTER TABLE catalog
    ADD COLUMN icon        VARCHAR(50)  NOT NULL DEFAULT 'folder'  AFTER active,
    ADD COLUMN color       VARCHAR(7)   NOT NULL DEFAULT '#374151' AFTER icon,
    ADD COLUMN is_builtin  BOOLEAN      NOT NULL DEFAULT FALSE      AFTER color,
    ADD COLUMN campos_extra TEXT                                    AFTER is_builtin;

CREATE TABLE catalog_step (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    catalog_id          BIGINT       NOT NULL,
    label               VARCHAR(255) NOT NULL,
    notes               TEXT,
    deadline_days       INT,
    external_dependency BOOLEAN      NOT NULL DEFAULT FALSE,
    responsible_entity  VARCHAR(150),
    sort_order          INT          NOT NULL DEFAULT 0,

    PRIMARY KEY (id),
    CONSTRAINT fk_cs_catalog FOREIGN KEY (catalog_id) REFERENCES catalog (id) ON DELETE CASCADE
);
