-- migration-003-customer-types.sql
-- Añade tipo de cliente real (PARTICULAR, AUTONOMO, SOCIEDAD, COMUNIDAD)
-- y campos específicos por tipo + checklist de documentación

ALTER TABLE customer
    -- Tipo de cliente
    ADD COLUMN customer_type          VARCHAR(30)   NOT NULL DEFAULT 'PARTICULAR'    AFTER factusol_code,

    -- Checklist de documentación (comunes a todos)
    ADD COLUMN hoja_encargo           BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN contrato_servicios     BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN autorizacion_mandato   BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN es_deudor              BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN importe_deuda          DECIMAL(10,2) NULL,

    -- Datos de actividad (Autónomo y Sociedad)
    ADD COLUMN epigrafe_iae           VARCHAR(50)   NULL,
    ADD COLUMN actividad              VARCHAR(255)  NULL,
    ADD COLUMN fecha_inicio_actividad DATE          NULL,
    ADD COLUMN regimen_iva            VARCHAR(100)  NULL,
    ADD COLUMN regimen_irpf           VARCHAR(100)  NULL,

    -- Datos de constitución (Sociedad)
    ADD COLUMN fecha_constitucion     DATE          NULL,
    ADD COLUMN notario                VARCHAR(255)  NULL,
    ADD COLUMN protocolo_notarial     VARCHAR(100)  NULL,
    ADD COLUMN capital_social         DECIMAL(12,2) NULL,
    ADD COLUMN objeto_social          TEXT          NULL,

    -- Datos de la Comunidad de Propietarios
    ADD COLUMN presidente_nombre      VARCHAR(200)  NULL,
    ADD COLUMN presidente_nif         VARCHAR(20)   NULL,
    ADD COLUMN secretario_nombre      VARCHAR(200)  NULL,
    ADD COLUMN secretario_nif         VARCHAR(20)   NULL,
    ADD COLUMN compania_seguro        VARCHAR(255)  NULL,
    ADD COLUMN telefono_seguro        VARCHAR(20)   NULL,
    ADD COLUMN poliza_seguro          VARCHAR(100)  NULL;

-- Migrar datos existentes: inferir tipo desde lastName (hack anterior)
UPDATE customer SET customer_type = 'AUTONOMO'  WHERE last_name = 'Autónomo';
UPDATE customer SET customer_type = 'SOCIEDAD'  WHERE last_name = 'Empresa';
-- Los demás quedan como PARTICULAR (DEFAULT)
