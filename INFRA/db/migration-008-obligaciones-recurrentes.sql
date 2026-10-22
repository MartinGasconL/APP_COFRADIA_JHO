-- migration-008-obligaciones-recurrentes.sql
-- Modelo de obligaciones recurrentes (regla) + tareas de obligacion (instancia perezosa)
-- para la matriz de cumplimiento. No toca case_file / case_file_step / catalog.

CREATE TABLE tipo_obligacion (
    id                BIGINT       NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(255) NOT NULL,
    codigo            VARCHAR(20),
    familia           ENUM('FISCAL','LABORAL','OTROS') NOT NULL,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,
    frecuencia_defecto ENUM('MENSUAL','TRIMESTRAL','ANUAL') NULL,

    PRIMARY KEY (id),
    UNIQUE KEY uk_tipo_obligacion_codigo (codigo)
);

-- La regla recurrente: "el cliente X presenta el 303 trimestral". Sin estado, sin periodo.
CREATE TABLE obligacion (
    id                     BIGINT NOT NULL AUTO_INCREMENT,
    cliente_id             BIGINT NOT NULL,
    tipo_obligacion_id     BIGINT NOT NULL,
    frecuencia             ENUM('MENSUAL','TRIMESTRAL','ANUAL') NOT NULL,
    fecha_alta             DATE   NOT NULL,
    fecha_baja             DATE   NULL,
    responsable_defecto_id BIGINT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_obligacion_cliente FOREIGN KEY (cliente_id) REFERENCES customer (id) ON DELETE CASCADE,
    CONSTRAINT fk_obligacion_tipo FOREIGN KEY (tipo_obligacion_id) REFERENCES tipo_obligacion (id) ON DELETE RESTRICT,
    CONSTRAINT fk_obligacion_responsable FOREIGN KEY (responsable_defecto_id) REFERENCES employee (id) ON DELETE SET NULL,
    INDEX idx_obligacion_cliente_tipo (cliente_id, tipo_obligacion_id)
);
-- Nota: MySQL no soporta constraints de exclusion por rango. La regla "no dos obligaciones
-- activas del mismo (cliente, tipo) con vigencia solapada" se valida en ObligacionService.

-- La instancia perezosa: "303 de X del 1T 2026". Solo existe fila cuando se toca la celda.
CREATE TABLE tarea_obligacion (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    obligacion_id  BIGINT NOT NULL,
    periodo        VARCHAR(20) NOT NULL COMMENT 'Periodo canonico: 2026-T1 / 2026-M03 / 2026-A',
    fecha_limite   DATE   NOT NULL,
    estado         ENUM('PENDIENTE','HECHA','NO_APLICA') NOT NULL DEFAULT 'PENDIENTE',
    responsable_id BIGINT NULL,
    completed_date DATE   NULL,
    notas          TEXT   NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_tarea_obligacion FOREIGN KEY (obligacion_id) REFERENCES obligacion (id) ON DELETE CASCADE,
    CONSTRAINT fk_tarea_responsable FOREIGN KEY (responsable_id) REFERENCES employee (id) ON DELETE SET NULL,
    UNIQUE KEY uk_tarea_obligacion_periodo (obligacion_id, periodo)
);
