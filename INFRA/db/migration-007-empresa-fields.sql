-- migration-007-empresa-fields.sql
-- Añade bloques condicionales para clientes Autónomo/Sociedad:
-- Datos generales, Trabajadores, Local y Presupuesto.

CREATE TABLE mutua (
    id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE servicio_prevencion (
    id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN      NOT NULL DEFAULT TRUE
);

ALTER TABLE customer
    -- Datos generales (empresa)
    ADD COLUMN certificado_digital     BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN iae_uploaded            BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN modelo_037_uploaded     BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN cnae_uploaded           BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN alta_autonomos          BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN numero_cuenta           VARCHAR(34)   NULL,
    ADD COLUMN proteccion_datos        BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN normativas              BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN subvenciones            BOOLEAN       NOT NULL DEFAULT FALSE,

    -- Trabajadores
    ADD COLUMN tiene_trabajadores        BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN codigo_cuenta_cotizacion  VARCHAR(30) NULL,
    ADD COLUMN mutua_id                  BIGINT      NULL,
    ADD COLUMN tiene_servicio_prevencion BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN servicio_prevencion_id    BIGINT      NULL,
    ADD COLUMN cursos_formacion          BOOLEAN     NOT NULL DEFAULT FALSE,

    -- Local
    ADD COLUMN tiene_local                    BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN licencia_actividad             BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN alta_centro_trabajo            BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN sanidad                        BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN comunic_establec_comerciales   BOOLEAN NOT NULL DEFAULT FALSE,

    -- Presupuesto
    ADD COLUMN tiene_presupuesto                 BOOLEAN       NOT NULL DEFAULT FALSE,
    ADD COLUMN precio_servicio                   DECIMAL(10,2) NULL,
    ADD COLUMN periodo_facturacion                VARCHAR(20)  NULL,  -- MENSUAL | TRIMESTRAL | SEMESTRAL | ANUAL
    ADD COLUMN hoja_encargo_presupuesto_uploaded  BOOLEAN      NOT NULL DEFAULT FALSE,

    ADD CONSTRAINT fk_customer_mutua FOREIGN KEY (mutua_id) REFERENCES mutua (id) ON DELETE SET NULL,
    ADD CONSTRAINT fk_customer_servicio_prevencion FOREIGN KEY (servicio_prevencion_id) REFERENCES servicio_prevencion (id) ON DELETE SET NULL;
