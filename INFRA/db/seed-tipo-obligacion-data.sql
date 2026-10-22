-- seed-tipo-obligacion-data.sql
-- Seed del catalogo tipo_obligacion (modelos/gestiones recurrentes) - idempotente, ejecutar las veces que haga falta.
--
-- Nota sobre "Modelo 111": el prompt original lo lista tanto en FISCAL (retenciones IRPF) como
-- de nuevo en LABORAL ("segun corresponda"). Como tipo_obligacion.codigo es unico, se siembra
-- una unica vez bajo FISCAL; Nomina mensual y Seguros Sociales cubren la parte LABORAL.

INSERT INTO tipo_obligacion (nombre, codigo, familia, activo, frecuencia_defecto) VALUES
    ('Modelo 303 (IVA trimestral)',                 '303', 'FISCAL',  TRUE, 'TRIMESTRAL'),
    ('Modelo 390 (Resumen anual IVA)',               '390', 'FISCAL',  TRUE, 'ANUAL'),
    ('Modelo 111 (Retenciones IRPF trabajo/profesionales)', '111', 'FISCAL', TRUE, 'TRIMESTRAL'),
    ('Modelo 115 (Retenciones alquileres)',          '115', 'FISCAL',  TRUE, 'TRIMESTRAL'),
    ('Modelo 130 (Pago fraccionado IRPF)',           '130', 'FISCAL',  TRUE, 'TRIMESTRAL'),
    ('Modelo 200 (Impuesto sobre Sociedades)',       '200', 'FISCAL',  TRUE, 'ANUAL'),
    ('Modelo 202 (Pago fraccionado Sociedades)',     '202', 'FISCAL',  TRUE, 'TRIMESTRAL'),
    ('Modelo 349 (Operaciones intracomunitarias)',   '349', 'FISCAL',  TRUE, 'TRIMESTRAL'),
    ('Modelo 347 (Operaciones con terceros)',        '347', 'FISCAL',  TRUE, 'ANUAL'),
    ('Nomina mensual',                               'NOMINA', 'LABORAL', TRUE, 'MENSUAL'),
    ('Seguros Sociales',                             'SS',   'LABORAL', TRUE, 'MENSUAL')
ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    familia = VALUES(familia),
    activo = VALUES(activo),
    frecuencia_defecto = VALUES(frecuencia_defecto);
