CREATE DATABASE IF NOT EXISTS aseint
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE aseint;

CREATE TABLE customer (
    id                  BIGINT          NOT NULL AUTO_INCREMENT,
    tax_id              VARCHAR(20)     NOT NULL,
    factusol_code       VARCHAR(20),
    first_name          VARCHAR(100)    NOT NULL,
    last_name           VARCHAR(150)    NOT NULL,
    trade_name          VARCHAR(255),
    birth_date          DATE,
    nationality         VARCHAR(100),
    civil_status        VARCHAR(50),
    gender              VARCHAR(10),
    address             VARCHAR(255),
    postal_code         VARCHAR(10),
    city                VARCHAR(100),
    province            VARCHAR(100),
    phone               VARCHAR(20),
    phone2              VARCHAR(20),
    email               VARCHAR(255),
    notification_email  VARCHAR(255),
    iban                VARCHAR(34),
    registration_date   DATE            NOT NULL DEFAULT (CURRENT_DATE),
    termination_date    DATE,
    termination_reason  VARCHAR(500),
    active              BOOLEAN         NOT NULL DEFAULT TRUE,
    billable            BOOLEAN         NOT NULL DEFAULT TRUE,
    notes               TEXT,
    gdpr_consent        BOOLEAN         NOT NULL DEFAULT FALSE,

    PRIMARY KEY (id),
    CONSTRAINT uq_customer_tax_id UNIQUE (tax_id)
);

-- ─────────────────────────────────────────────
-- CATALOG
-- ─────────────────────────────────────────────

CREATE TABLE catalog (
    id          BIGINT          NOT NULL AUTO_INCREMENT,
    code        VARCHAR(50)     NOT NULL,
    name        VARCHAR(255)    NOT NULL,
    description TEXT,
    category    VARCHAR(50)     NOT NULL,   -- FISCAL, LEGAL, NOTARIAL, LABORAL
    active      BOOLEAN         NOT NULL DEFAULT TRUE,

    PRIMARY KEY (id),
    CONSTRAINT uq_catalog_code UNIQUE (code)
);

CREATE TABLE catalog_required_document (
    id                  BIGINT          NOT NULL AUTO_INCREMENT,
    catalog_id          BIGINT          NOT NULL,
    document_type       VARCHAR(100)    NOT NULL,   -- DNI, CONTRATO, AUTORIZACION, MANDATO...
    mandatory           BOOLEAN         NOT NULL DEFAULT TRUE,
    requires_signature  BOOLEAN         NOT NULL DEFAULT FALSE,

    PRIMARY KEY (id),
    CONSTRAINT fk_crd_catalog FOREIGN KEY (catalog_id) REFERENCES catalog (id)
);

CREATE TABLE catalog_deadline (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    catalog_id      BIGINT          NOT NULL,
    name            VARCHAR(255)    NOT NULL,
    offset_type     VARCHAR(30)     NOT NULL,   -- RELATIVE_TO_OPEN, RELATIVE_TO_EVENT, FIXED_DATE
    offset_days     INT,                        -- usado si offset_type es RELATIVE_*
    fixed_date      VARCHAR(5),                 -- usado si offset_type es FIXED_DATE, formato MM-DD
    event_type      VARCHAR(30)     NOT NULL,   -- DEADLINE, REMINDER, TASK

    PRIMARY KEY (id),
    CONSTRAINT fk_cd_catalog FOREIGN KEY (catalog_id) REFERENCES catalog (id)
);

-- ─────────────────────────────────────────────
-- CASE FILE (EXPEDIENTE)
-- ─────────────────────────────────────────────

CREATE TABLE case_file (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    reference       VARCHAR(20)     NOT NULL,   -- EXP-2025-0001
    customer_id     BIGINT          NOT NULL,
    catalog_id      BIGINT          NOT NULL,
    status          VARCHAR(30)     NOT NULL DEFAULT 'OPEN',  -- OPEN, IN_PROGRESS, PENDING_DOCS, RESOLVED, CLOSED, CANCELLED
    open_date       DATE            NOT NULL DEFAULT (CURRENT_DATE),
    close_date      DATE,
    assigned_to     VARCHAR(100),
    billable        BOOLEAN         NOT NULL DEFAULT TRUE,
    notes           TEXT,

    PRIMARY KEY (id),
    CONSTRAINT uq_case_file_reference  UNIQUE (reference),
    CONSTRAINT fk_cf_customer          FOREIGN KEY (customer_id)  REFERENCES customer (id),
    CONSTRAINT fk_cf_catalog           FOREIGN KEY (catalog_id)   REFERENCES catalog (id)
);

-- ─────────────────────────────────────────────
-- DOCUMENT
-- ─────────────────────────────────────────────

-- Documento lógico: agrupa todas las versiones de un mismo documento
-- case_file_id es nullable: documentos generales del cliente no van ligados a un expediente
CREATE TABLE document_group (
    id                              BIGINT          NOT NULL AUTO_INCREMENT,
    case_file_id                    BIGINT          NULL,       -- NULL para documentos generales del cliente
    customer_id                     BIGINT          NULL,       -- FK directa al cliente para docs generales
    catalog_required_document_id    BIGINT          NULL,       -- NULL si es doc ad-hoc
    document_type                   VARCHAR(100)    NOT NULL,
    name                            VARCHAR(255)    NOT NULL,
    status                          VARCHAR(30)     NOT NULL DEFAULT 'PENDING',
    notes                           TEXT,

    PRIMARY KEY (id),
    CONSTRAINT fk_dg_case_file  FOREIGN KEY (case_file_id)                 REFERENCES case_file (id),
    CONSTRAINT fk_dg_customer   FOREIGN KEY (customer_id)                  REFERENCES customer (id),
    CONSTRAINT fk_dg_crd        FOREIGN KEY (catalog_required_document_id) REFERENCES catalog_required_document (id)
);

-- Versión física de un documento almacenada en MinIO
CREATE TABLE document (
    id                  BIGINT          NOT NULL AUTO_INCREMENT,
    document_group_id   BIGINT          NOT NULL,
    version             INT             NOT NULL DEFAULT 1,
    original_filename   VARCHAR(255)    NOT NULL,
    content_type        VARCHAR(100)    NOT NULL,   -- application/pdf, image/jpeg...
    file_size_bytes     BIGINT          NOT NULL,
    bucket              VARCHAR(100)    NOT NULL DEFAULT 'aseint-docs',
    object_key          VARCHAR(500)    NOT NULL,   -- customers/1/case-files/EXP-2025-0001/v1_dni.pdf
    checksum            VARCHAR(64)     NOT NULL,   -- SHA-256
    upload_date         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uploaded_by         VARCHAR(100),

    PRIMARY KEY (id),
    CONSTRAINT uq_doc_group_version     UNIQUE (document_group_id, version),
    CONSTRAINT fk_doc_document_group    FOREIGN KEY (document_group_id) REFERENCES document_group (id)
);

-- ─────────────────────────────────────────────
-- CALENDAR
-- ─────────────────────────────────────────────

CREATE TABLE calendar_account (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    provider        VARCHAR(30)     NOT NULL,           -- GOOGLE, MICROSOFT, APPLE
    account_email   VARCHAR(255)    NOT NULL,
    calendar_id     VARCHAR(255),                       -- ID del calendario dentro del proveedor
    access_token    TEXT,                               -- cifrado en aplicación
    refresh_token   TEXT,                               -- cifrado en aplicación
    active          BOOLEAN         NOT NULL DEFAULT TRUE,

    PRIMARY KEY (id),
    CONSTRAINT uq_calendar_account UNIQUE (provider, account_email)
);

CREATE TABLE calendar_event (
    id              BIGINT          NOT NULL AUTO_INCREMENT,
    ical_uid        VARCHAR(255)    NOT NULL,            -- RFC 5545, identificador universal
    title           VARCHAR(255)    NOT NULL,
    description     TEXT,
    start_datetime  DATETIME        NOT NULL,
    end_datetime    DATETIME        NOT NULL,
    all_day         BOOLEAN         NOT NULL DEFAULT FALSE,
    location        VARCHAR(500),
    event_type      VARCHAR(30)     NOT NULL,            -- APPOINTMENT, DEADLINE, REMINDER, TASK
    status          VARCHAR(30)     NOT NULL DEFAULT 'SCHEDULED',  -- SCHEDULED, COMPLETED, CANCELLED
    auto_generated  BOOLEAN         NOT NULL DEFAULT FALSE,
    customer_id     BIGINT,                             -- opcional: cita de cliente sin expediente
    case_file_id    BIGINT,                             -- opcional: cita sobre un expediente concreto
    catalog_deadline_id BIGINT,                         -- opcional: plantilla que lo generó

    PRIMARY KEY (id),
    CONSTRAINT uq_calendar_event_ical_uid   UNIQUE (ical_uid),
    CONSTRAINT fk_ce_customer               FOREIGN KEY (customer_id)           REFERENCES customer (id),
    CONSTRAINT fk_ce_case_file              FOREIGN KEY (case_file_id)          REFERENCES case_file (id),
    CONSTRAINT fk_ce_catalog_deadline       FOREIGN KEY (catalog_deadline_id)   REFERENCES catalog_deadline (id)
);

CREATE TABLE calendar_event_sync (
    id                      BIGINT          NOT NULL AUTO_INCREMENT,
    calendar_event_id       BIGINT          NOT NULL,
    calendar_account_id     BIGINT          NOT NULL,
    external_event_id       VARCHAR(255)    NOT NULL,   -- ID del evento en el proveedor
    external_calendar_id    VARCHAR(255),               -- calendario concreto dentro del proveedor
    sync_status             VARCHAR(30)     NOT NULL DEFAULT 'PENDING',  -- PENDING, SYNCED, ERROR, DELETED
    last_synced_at          DATETIME,

    PRIMARY KEY (id),
    CONSTRAINT uq_ces_event_account     UNIQUE (calendar_event_id, calendar_account_id),
    CONSTRAINT fk_ces_event             FOREIGN KEY (calendar_event_id)     REFERENCES calendar_event (id),
    CONSTRAINT fk_ces_account           FOREIGN KEY (calendar_account_id)   REFERENCES calendar_account (id)
);
