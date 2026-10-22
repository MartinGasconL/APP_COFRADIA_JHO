-- migration-006: Modelo de plazos flexible en pasos
-- Adds fecha_referencia to case_file, plazo_tipo to catalog_step and case_file_step.

ALTER TABLE case_file
    ADD COLUMN fecha_referencia       DATE         NULL AFTER notes,
    ADD COLUMN fecha_referencia_label VARCHAR(100) NULL AFTER fecha_referencia;

ALTER TABLE catalog_step
    ADD COLUMN plazo_tipo ENUM('MANUAL','RELATIVO_APERTURA','RELATIVO_REFERENCIA','RELATIVO_PASO_ANTERIOR')
                          NOT NULL DEFAULT 'MANUAL' AFTER deadline_days;

ALTER TABLE case_file_step
    ADD COLUMN plazo_tipo               ENUM('MANUAL','RELATIVO_APERTURA','RELATIVO_REFERENCIA','RELATIVO_PASO_ANTERIOR')
                                        NOT NULL DEFAULT 'MANUAL' AFTER deadline_days,
    ADD COLUMN plazo_depende_de_paso_id BIGINT NULL               AFTER plazo_tipo,
    ADD COLUMN completed_date           DATE   NULL               AFTER plazo_depende_de_paso_id,
    ADD CONSTRAINT fk_cfs_depends FOREIGN KEY (plazo_depende_de_paso_id)
        REFERENCES case_file_step (id) ON DELETE SET NULL;
