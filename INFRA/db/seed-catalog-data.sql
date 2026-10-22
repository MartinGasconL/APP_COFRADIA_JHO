-- Seed datos catalogo de tramites - ejecutar una unica vez

-- FISCAL

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('IRPF', 'IRPF', 'FISCAL', 'receipt_long', '#1a1ab4', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text","placeholder":"2024"},{"key":"resultado","label":"Resultado","tipo":"text","placeholder":"A ingresar / A devolver"},{"key":"importe","label":"Importe (euro)","tipo":"number"},{"key":"borrador","label":"Numero de borrador AEAT","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='receipt_long', color='#1a1ab4', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'IRPF');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Obtencion datos fiscales AEAT (Clv PIN)' AS label, 'Acceder al portal AEAT con Clve o numero de referencia y descargar borrador y datos fiscales del ejercicio.' AS notes, 5 AS deadline_days, TRUE AS external_dependency, 'AEAT' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Revision del borrador con el cliente', 'Contrastar borrador con documentacion del cliente: rendimientos del trabajo, capital mobiliario e inmobiliario, ganancias patrimoniales, deducciones autonomicas.', 4, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Ajustes y confirmacion de importes', 'Incluir rendimientos no reflejados en el borrador y aplicar deducciones (hipoteca, maternidad, familia numerosa). Validar resultado final con el cliente.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Presentacion telematica Mod. 100 AEAT', 'Presentar telematicamente. Plazo legal: hasta el 30 de junio (25 junio si es a ingresar con domiciliacion bancaria).', 2, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Entrega justificante al cliente', 'Enviar PDF con el justificante de presentacion y el resultado de la declaracion.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
) s WHERE c.code = 'IRPF';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('IVA_TRIMESTRAL', 'IVA Trimestral', 'FISCAL', 'receipt_long', '#1a1ab4', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text","placeholder":"2024"},{"key":"trimestre","label":"Trimestre","tipo":"text","placeholder":"1T / 2T / 3T / 4T"},{"key":"cuotaDevengada","label":"Cuota devengada (euro)","tipo":"number"},{"key":"cuotaSoportada","label":"Cuota soportada deducible (euro)","tipo":"number"},{"key":"resultado","label":"Resultado (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='receipt_long', color='#1a1ab4', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'IVA_TRIMESTRAL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion facturas emitidas y recibidas del trimestre' AS label, 'Solicitar al cliente todas las facturas del periodo. Verificar que no falten facturas de compras con IVA deducible.' AS notes, 5 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Cuadre y conciliacion contable del trimestre', 'Verificar que el IVA repercutido y soportado cuadra con la contabilidad. Revisar prorrata si aplica.', 4, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Cumplimentacion Mod. 303', 'Rellenar el modelo 303. Comprobar saldo anterior (casilla 78) y regularizar si hay devolucion pendiente de trimestres anteriores.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Revision con el cliente y confirmacion', 'Enviar resumen al cliente para visto bueno antes de presentar.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Presentacion telematica AEAT', 'Presentar el Mod. 303. Plazo: hasta el dia 20 del mes siguiente al trimestre (4T hasta el 30 de enero del aÃ±o siguiente).', 1, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Domiciliacion / pago de la cuota', 'Si el resultado es a ingresar, confirmar domiciliacion o pagar en banco. Guardar justificante.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'IVA_TRIMESTRAL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('IMP_SOCIEDADES', 'Imp. Sociedades', 'FISCAL', 'receipt_long', '#1a1ab4', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text","placeholder":"2024"},{"key":"resultado","label":"Resultado contable (euro)","tipo":"number"},{"key":"baseImponible","label":"Base imponible (euro)","tipo":"number"},{"key":"cuotaLiquida","label":"Cuota a ingresar/devolver (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='receipt_long', color='#1a1ab4', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'IMP_SOCIEDADES');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Cierre provisional y cuadre contable del ejercicio' AS label, 'Verificar que todos los asientos del ejercicio estan registrados. Cuadrar libro diario, mayor y balances.' AS notes, 15 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Regularizacion de amortizaciones y provisiones', 'Calcular amortizaciones por tablas fiscales (Ley 27/2014). Dotar provisiones deducibles (insolvencias, existencias).', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Ajustes fiscales extracontables', 'Aplicar diferencias permanentes y temporarias. Revisar gastos no deducibles (multas, liberalidades). Compensar BINs pendientes.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Cumplimentacion Mod. 200', 'Rellenar el modelo 200 en sede electronica AEAT. Revisar balance, P&G, ajustes al resultado y deducciones aplicadas.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Revision y validacion con el cliente', 'Presentar resumen al administrador para conformidad antes de enviar.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Presentacion telematica AEAT', 'Plazo: 25 dias naturales siguientes a los 6 meses del cierre (normalmente hasta el 25 de julio).', 2, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Ingreso cuota / domiciliacion', 'Si hay cuota a ingresar, confirmar pago. Guardar justificante.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 6
) s WHERE c.code = 'IMP_SOCIEDADES';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('PAGOS_FRACCIONADOS', 'Pagos Fraccionados', 'FISCAL', 'receipt_long', '#1a1ab4', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text","placeholder":"2024"},{"key":"periodo","label":"Periodo","tipo":"text","placeholder":"1P (abril) / 2P (octubre) / 3P (diciembre)"},{"key":"modalidad","label":"Modalidad","tipo":"text","placeholder":"Art. 40.2 / Art. 40.3"},{"key":"importe","label":"Importe a ingresar (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='receipt_long', color='#1a1ab4', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'PAGOS_FRACCIONADOS');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Calculo del pago fraccionado' AS label, 'Modalidad art. 40.2: 18% de la cuota integra del ultimo IS. Modalidad art. 40.3: 17% sobre resultado acumulado desde inicio del ejercicio. Obligatoria si volumen de operaciones > 6M.' AS notes, 4 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Cumplimentacion Mod. 202', 'Rellenar el Mod. 202. Comprobar deduccion de pagos fraccionados anteriores del mismo ejercicio.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Presentacion telematica AEAT', 'Plazo: hasta el 20 de abril (1P), 20 de octubre (2P) y 20 de diciembre (3P).', 1, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Entrega justificante al cliente', NULL, 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
) s WHERE c.code = 'PAGOS_FRACCIONADOS';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('RETENCIONES_111_115', 'Retenciones (111/115)', 'FISCAL', 'receipt_long', '#1a1ab4', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text"},{"key":"periodo","label":"Periodo","tipo":"text","placeholder":"1T / 2T / 3T / 4T"},{"key":"modelo","label":"Modelo","tipo":"text","placeholder":"111 (trabajo/actividades) / 115 (arrendamientos)"},{"key":"importe","label":"Importe retenciones (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='receipt_long', color='#1a1ab4', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'RETENCIONES_111_115');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recopilacion de retenciones del periodo' AS label, 'Mod. 111: retenciones sobre nominas, honorarios profesionales y actividades economicas. Mod. 115: retenciones sobre arrendamiento de inmuebles (19%).' AS notes, 4 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Cumplimentacion Mod. 111 y/o 115', 'Verificar NIF de perceptores y cuantias. Cuadrar con los libros de retenciones.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Presentacion telematica AEAT', 'Plazo trimestral: hasta el dia 20 del mes siguiente al trimestre.', 1, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Entrega justificante al cliente', NULL, 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
) s WHERE c.code = 'RETENCIONES_111_115';

-- LABORAL

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('ALTA_AUTONOMO', 'Alta Autonomo', 'LABORAL', 'badge', '#16a34a', TRUE, TRUE,
'[{"key":"actividadIAE","label":"Actividad / Epigrafe IAE","tipo":"text"},{"key":"baseCotizacion","label":"Base de cotizacion elegida","tipo":"text"},{"key":"fechaAlta","label":"Fecha de alta solicitada","tipo":"date"},{"key":"rendimientosPrevistos","label":"Rendimientos netos previstos (euro/anio)","tipo":"number"},{"key":"mutua","label":"Mutua de IT y contingencias profesionales","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='badge', color='#16a34a', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'ALTA_AUTONOMO');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion documentacion del autonomo' AS label, 'Solicitar: DNI/NIE, numero de afiliacion SS, datos bancarios para domiciliacion, direccion fiscal y datos de la actividad.' AS notes, 2 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Alta censal en Hacienda (Mod. 036 / 037)', 'Declarar inicio de actividad. Elegir epigrafe IAE, regimen de IVA (general, recargo de equivalencia, modulos) y regimen IRPF. El alta debe ser previa o simultanea al inicio de la actividad.', 2, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Alta en el RETA (Seguridad Social)', 'Tramitar en Sede Electronica SSTGG. Elegir base de cotizacion segun rendimientos netos previstos (sistema de cotizacion por tramos 2023+). Domiciliar cuota mensual.', 1, FALSE, 'Seguridad Social', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Comunicacion al cliente de obligaciones periodicas', 'Informar de fechas de presentacion de IVA, IRPF, cuota autonomo mensual y obligacion de emitir facturas y llevar registros.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
) s WHERE c.code = 'ALTA_AUTONOMO';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('CONTRATO_LABORAL', 'Contrato Laboral', 'LABORAL', 'badge', '#16a34a', TRUE, TRUE,
'[{"key":"nombreEmpleado","label":"Nombre del empleado","tipo":"text"},{"key":"dniEmpleado","label":"NIF/NIE del empleado","tipo":"text"},{"key":"tipoContrato","label":"Tipo de contrato","tipo":"text","placeholder":"Indefinido / Temporal / Formacion"},{"key":"salarioBruto","label":"Salario bruto anual (euro)","tipo":"number"},{"key":"fechaIncorporacion","label":"Fecha de incorporacion","tipo":"date"},{"key":"convenio","label":"Convenio colectivo aplicable","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='badge', color='#16a34a', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'CONTRATO_LABORAL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion documentacion de empresa y empleado' AS label, 'Solicitar: DNI empleado, numero de afiliacion SS, titulacion si aplica, datos bancarios para nomina.' AS notes, 2 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Redaccion del contrato de trabajo', 'Elegir modalidad contractual. Reflejar categoria profesional segun convenio, jornada, salario y periodo de prueba.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Alta previa en Seguridad Social (Sistema RED)', 'Tramitar el alta con antelacion minima de 1 dia natural antes del inicio de la relacion laboral.', 1, FALSE, 'Seguridad Social', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Firma del contrato por las partes', 'Empresa y trabajador firman el contrato. Se admite firma electronica cualificada.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Comunicacion al SEPE (CONTRAT@)', 'Comunicar el contrato telematicamente a traves de CONTRAT@ en un plazo de 10 dias desde la firma.', 10, FALSE, 'SEPE', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Entrega de copia basica', 'Si hay representacion sindical, entregar copia basica del contrato en el plazo de 10 dias. Entregar copia al empleado.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'CONTRATO_LABORAL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('NOMINAS', 'Nominas', 'LABORAL', 'badge', '#16a34a', TRUE, TRUE,
'[{"key":"mes","label":"Mes y ejercicio","tipo":"text","placeholder":"Enero 2025"},{"key":"numTrabajadores","label":"Numero de trabajadores","tipo":"number"},{"key":"masaSalarial","label":"Masa salarial bruta total (euro)","tipo":"number"},{"key":"cuotaSS","label":"Cuotas SS a cargo empresa (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='badge', color='#16a34a', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'NOMINAS');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion de incidencias del mes' AS label, 'Recopilar: ausencias, IT, horas extra, comisiones, anticipos, cambios de jornada o salario, nuevas altas/bajas.' AS notes, 3 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Elaboracion de nominas', 'Calcular retribuciones brutas, deducciones SS (trabajador y empresa), IRPF segun tipo de retencion de cada empleado.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Envio borrador al cliente para revision', 'Enviar listado de nominas en PDF/Excel para revision y visto bueno antes de tramitar los seguros sociales.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Presentacion Sistema RED - Seguros Sociales', 'Presentar el TC1 antes del ultimo dia habil del mes. Cuadrar el fichero SILTRA con las bases de cotizacion.', 2, FALSE, 'Seguridad Social', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Transferencias bancarias a trabajadores', 'Emitir orden de transferencia o facilitar fichero bancario norma 34. Confirmar pago antes del ultimo dia del mes.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
) s WHERE c.code = 'NOMINAS';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('BAJA_FINIQUITO', 'Baja / Finiquito', 'LABORAL', 'badge', '#16a34a', TRUE, TRUE,
'[{"key":"nombreEmpleado","label":"Nombre del empleado","tipo":"text"},{"key":"causaBaja","label":"Causa de extincion","tipo":"text","placeholder":"Dimision / Despido objetivo / Disciplinario / Expiracion temporal"},{"key":"fechaBaja","label":"Fecha de efectividad","tipo":"date"},{"key":"importeFiniquito","label":"Importe finiquito estimado (euro)","tipo":"number"},{"key":"indemnizacion","label":"Indemnizacion por despido (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='badge', color='#16a34a', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'BAJA_FINIQUITO');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Comunicacion formal de la extincion del contrato' AS label, 'Carta de despido o comunicacion escrita firmada. Verificar si se ha respetado el preaviso legal segun convenio y tipo de extincion.' AS notes, 1 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Calculo del finiquito', 'Incluir: salario devengado pendiente, vacaciones no disfrutadas, parte proporcional de pagas extra e indemnizacion si corresponde (despido objetivo: 20 dias/anio; improcedente: 33 dias/anio).', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Baja en Seguridad Social (Sistema RED)', 'Tramitar la baja en los 3 dias naturales siguientes a la fecha de baja. La comunicacion fuera de plazo genera recargo del 20%.', 3, FALSE, 'Seguridad Social', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Firma del documento de finiquito', 'El documento debe incluir el saldo a liquidar desglosado y la expresion saldo y finiquito. Firmar en presencia de delegado sindical si el empleado lo solicita.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Certificado de empresa al SEPE', 'Emitir certificado de empresa para que el empleado pueda solicitar la prestacion por desempleo. Obligatorio en 10 dias desde la baja.', 10, FALSE, 'SEPE', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Informar al empleado del plazo para solicitar el paro', 'El trabajador dispone de 15 dias habiles desde la fecha de baja para solicitar la prestacion contributiva por desempleo.', 1, FALSE, 'SEPE', 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'BAJA_FINIQUITO';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('IT_BAJA_MEDICA', 'IT / Baja Medica', 'LABORAL', 'badge', '#16a34a', TRUE, TRUE,
'[{"key":"nombreEmpleado","label":"Nombre del empleado","tipo":"text"},{"key":"fechaBaja","label":"Fecha de inicio de la baja","tipo":"date"},{"key":"contingencia","label":"Contingencia","tipo":"text","placeholder":"Enfermedad comun / Accidente laboral / Enfermedad profesional"},{"key":"mutua","label":"Mutua colaboradora","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='badge', color='#16a34a', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'IT_BAJA_MEDICA');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion y registro del parte de baja medica' AS label, 'Desde 2023 los partes se transmiten directamente por via telematica entre medico e INSS. El trabajador debe comunicar la baja al empresario.' AS notes, 1 AS deadline_days, TRUE AS external_dependency, 'Servicio Publico de Salud / Mutua' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Comunicacion a la Mutua o INSS', 'Para accidentes de trabajo: comunicar en 5 dias habiles a la mutua. Para enfermedad profesional: tambien a la Inspeccion de Trabajo.', 5, FALSE, 'Mutua / INSS', 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Control periodico de partes de confirmacion', 'El medico emite partes de confirmacion cada 7 dias (corta duracion) o cada 28 dias (larga duracion). Vigilar que los partes lleguen y se registren.', NULL, TRUE, 'Servicio Publico de Salud / Mutua', 'MANUAL', 2
  UNION ALL SELECT 'Gestion subsidio IT (pago delegado)', 'Dias 1-3: cargo empresa. Dias 4-15: paga empresa y recupera de la SS. Desde el dia 16: mutua/INSS. Si IT es mayor de 20 dias tramitar pago delegado.', NULL, FALSE, 'Seguridad Social / Mutua', 'MANUAL', 3
  UNION ALL SELECT 'Recepcion del alta medica y reincorporacion', 'El trabajador debe reincorporarse al dia siguiente del parte de alta. La no reincorporacion injustificada puede ser causa de despido disciplinario.', NULL, TRUE, 'Servicio Publico de Salud / Mutua', 'MANUAL', 4
  UNION ALL SELECT 'Regularizacion en nomina y actualizacion SS', 'Liquidar el subsidio, descuentos aplicados y base de cotizacion del periodo de IT en la nomina del mes correspondiente.', 2, FALSE, 'Seguridad Social', 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'IT_BAJA_MEDICA';

-- SOCIETARIO

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('CONSTITUCION_SL', 'Constitucion S.L.', 'SOCIETARIO', 'business', '#9333ea', TRUE, TRUE,
'[{"key":"denominacion","label":"Denominacion social","tipo":"text"},{"key":"capitalSocial","label":"Capital social (euro)","tipo":"number","placeholder":"3000"},{"key":"objetoSocial","label":"Objeto social","tipo":"textarea"},{"key":"socios","label":"Socios fundadores","tipo":"textarea"},{"key":"domicilioSocial","label":"Domicilio social","tipo":"text"},{"key":"administrador","label":"Administrador/es","tipo":"text"},{"key":"notaria","label":"Notaria prevista","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='business', color='#9333ea', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'CONSTITUCION_SL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion documentacion de socios y datos de la sociedad' AS label, 'Solicitar: DNI/NIE de todos los socios y administradores, porcentaje de participacion, objeto social, domicilio y denominacion propuesta.' AS notes, 3 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Certificacion negativa de nombre en el Registro Mercantil Central', 'Solicitar en el RMC que la denominacion elegida no coincide con ninguna inscrita. Valida 6 meses. Tramitable online en rmc.es. Plazo de respuesta: 2-3 dias habiles.', 4, TRUE, 'Registro Mercantil Central', 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Redaccion de estatutos sociales', 'Redactar objeto social, capital, participaciones, organo de administracion, adopcion de acuerdos y restricciones a la transmision de participaciones.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Apertura cuenta bancaria y deposito del capital social', 'Depositar el capital social minimo (3.000 euro). Obtener certificado bancario del deposito.', 5, TRUE, 'Entidad bancaria', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Firma de la escritura publica de constitucion ante notario', 'Acudir a notaria con: DNI socios, certificado RMC, certificado bancario y estatutos. El notario eleva los estatutos a escritura publica.', 7, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Liquidacion Mod. 600 - AJD (exento para SL desde 2010)', 'La constitucion de SL esta exenta de Operaciones Societarias del ITPyAJD desde el 03/12/2010. Presentar igualmente el Mod. 600 con la marca de exencion.', 3, FALSE, 'Comunidad Autonoma', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Presentacion en el Registro Mercantil provincial', 'El RM dispone de 15 dias habiles para calificar e inscribir desde la presentacion telematica. Una vez inscrita, la SL adquiere personalidad juridica plena.', 15, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 6
  UNION ALL SELECT 'Alta censal AEAT (Mod. 036) y NIF definitivo', 'Con el CIF provisional se pueden iniciar operaciones. Una vez inscrita en el RM, solicitar el NIF definitivo y presentar Mod. 036 declarando inicio de actividad.', 5, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 7
) s WHERE c.code = 'CONSTITUCION_SL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('CONSTITUCION_SA', 'Constitucion S.A.', 'SOCIETARIO', 'business', '#9333ea', TRUE, TRUE,
'[{"key":"denominacion","label":"Denominacion social","tipo":"text"},{"key":"capitalSocial","label":"Capital social (euro)","tipo":"number","placeholder":"60101"},{"key":"capitalDesembolsado","label":"Capital desembolsado (euro)","tipo":"number","placeholder":"Al menos el 25%"},{"key":"objetoSocial","label":"Objeto social","tipo":"textarea"},{"key":"accionistas","label":"Accionistas fundadores","tipo":"textarea"},{"key":"notaria","label":"Notaria prevista","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='business', color='#9333ea', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'CONSTITUCION_SA');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion documentacion de accionistas y datos de la sociedad' AS label, 'Solicitar DNI de fundadores, distribucion accionarial, tipo de acciones, objeto social y denominacion.' AS notes, 3 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Certificacion negativa de nombre en el Registro Mercantil Central', 'Plazo de respuesta: 2-3 dias habiles.', 4, TRUE, 'Registro Mercantil Central', 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Redaccion de estatutos sociales', 'Los estatutos de la SA son mas complejos: clases de acciones, sistema de convocatoria de juntas, quorums reforzados y regimen de representacion del voto.', 7, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Apertura cuenta bancaria y certificado de desembolso', 'Depositar el capital social minimo (60.101 euro), del cual al menos el 25% debe estar desembolsado. Obtener certificado del banco.', 5, TRUE, 'Entidad bancaria', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Informe pericial de aportaciones no dinerarias (si aplica)', 'Si parte del capital se aporta en especie, es obligatorio un informe pericial elaborado por experto designado por el RM.', 10, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Firma de la escritura publica ante notario', 'Acudir a notaria con: DNI, certificado RMC, certificado bancario e informe pericial si aplica.', 7, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Liquidacion Mod. 600 - AJD', 'Presentar Mod. 600 en la CCAA con exencion de Operaciones Societarias.', 3, FALSE, 'Comunidad Autonoma', 'RELATIVO_PASO_ANTERIOR', 6
  UNION ALL SELECT 'Inscripcion en el Registro Mercantil provincial', 'Plazo de 15 dias habiles para calificacion. La SA no adquiere personalidad juridica hasta la inscripcion.', 15, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 7
  UNION ALL SELECT 'Alta censal AEAT (Mod. 036) y NIF definitivo', NULL, 5, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 8
) s WHERE c.code = 'CONSTITUCION_SA';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('MODIFICACION_ESTATUTOS', 'Modificacion Estatutos', 'SOCIETARIO', 'business', '#9333ea', TRUE, TRUE,
'[{"key":"modificacion","label":"Objeto de la modificacion","tipo":"textarea"},{"key":"articulosAfectados","label":"Articulos estatutarios afectados","tipo":"text"},{"key":"notaria","label":"Notaria","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='business', color='#9333ea', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'MODIFICACION_ESTATUTOS');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Analisis juridico y redaccion propuesta de modificacion' AS label, 'Revisar estatutos vigentes. Redactar la nueva redaccion de los articulos afectados. Verificar si hay derecho de separacion de socios.' AS notes, 5 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Convocatoria de Junta General Extraordinaria', 'La convocatoria debe realizarse con al menos 15 dias de antelacion para SL (1 mes para SA). Incluir en el orden del dia el texto integro de la modificacion.', 15, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Celebracion de Junta y levantamiento de acta', 'Para modificar estatutos en SL se requiere mayoria cualificada (mas del 50% del capital). En SA, quorum reforzado y mayoria absoluta.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Elevacion a escritura publica ante notario', 'El acuerdo de modificacion debe constar en escritura publica para ser inscribible en el RM.', 10, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Inscripcion en el Registro Mercantil', 'La modificacion de estatutos solo produce efectos frente a terceros desde su inscripcion. Plazo de calificacion: 15 dias habiles.', 15, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Actualizacion censal en Hacienda si aplica', 'Si cambia el domicilio fiscal u objeto social: presentar Mod. 036 de modificacion.', 5, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'MODIFICACION_ESTATUTOS';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('AMPLIACION_CAPITAL', 'Ampliacion de Capital', 'SOCIETARIO', 'business', '#9333ea', TRUE, TRUE,
'[{"key":"capitalAnterior","label":"Capital actual (euro)","tipo":"number"},{"key":"aumento","label":"Importe del aumento (euro)","tipo":"number"},{"key":"tipoAportacion","label":"Tipo de aportacion","tipo":"text","placeholder":"Dineraria / No dineraria / Compensacion de creditos"}]')
ON DUPLICATE KEY UPDATE icon='business', color='#9333ea', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'AMPLIACION_CAPITAL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Propuesta de ampliacion y calculo del aumento' AS label, 'Determinar la cuantia, tipo de aportacion y si se reconoce el derecho preferente de suscripcion a los socios actuales.' AS notes, 3 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Convocatoria de Junta General', 'Incluir en el orden del dia la propuesta de ampliacion e informar sobre el derecho de suscripcion preferente.', 15, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Celebracion de Junta y acuerdo de ampliacion', 'Mayoria cualificada de mas del 50% del capital (SL). En SA puede delegarse en los administradores hasta el 50% del capital durante 5 anios (art. 297 LSC).', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Desembolso y certificado bancario de aportacion', 'Para aportaciones dinerarias: ingresar en cuenta y obtener certificado bancario. Para no dinerarias: informe pericial si es SA.', 5, TRUE, 'Entidad bancaria', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Escritura publica de ampliacion ante notario', 'Elevar a escritura el acuerdo de junta con el certificado de desembolso.', 7, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Inscripcion en el Registro Mercantil', 'Hasta la inscripcion las nuevas participaciones no existen juridicamente. Plazo de calificacion: 15 dias habiles.', 15, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'AMPLIACION_CAPITAL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('DISOLUCION_SL', 'Disolucion S.L.', 'SOCIETARIO', 'business', '#9333ea', TRUE, TRUE,
'[{"key":"causaDisolucion","label":"Causa de disolucion","tipo":"text","placeholder":"Acuerdo socios / Perdidas 2/3 capital / Inactividad"},{"key":"liquidadores","label":"Liquidadores nombrados","tipo":"textarea"},{"key":"notaria","label":"Notaria","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='business', color='#9333ea', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'DISOLUCION_SL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Reunion y analisis de la situacion patrimonial' AS label, 'Revisar situacion contable, creditos pendientes, deudas, contratos y obligaciones laborales. Valorar si procede concurso de acreedores.' AS notes, 3 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Convocatoria de Junta de Disolucion', 'Los administradores tienen el deber legal de convocar la junta si concurre causa de disolucion. Incluir nombramiento de liquidadores en el orden del dia.', 15, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Celebracion de Junta y nombramiento de liquidadores', 'Desde la disolucion los administradores cesan y son sustituidos por los liquidadores.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Inscripcion de la disolucion en el Registro Mercantil', 'Publicar en el BORME. Inscribir en el RM provincial.', 10, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Proceso de liquidacion del activo y pago del pasivo', 'Cobrar creditos, vender activos, pagar deudas. Los liquidadores satisfacen primero a los acreedores. Plazo minimo de 3 meses desde publicacion.', NULL, FALSE, NULL, 'MANUAL', 4
  UNION ALL SELECT 'Balance final de liquidacion y cuota de liquidacion', 'Elaborar el balance final. Calcular el haber liquido repartible entre socios. Los socios pueden impugnar el balance en 2 meses.', 15, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Escritura de extincion ante notario', 'Elevar a escritura el balance final aprobado, la declaracion de haber pagado a todos los acreedores y la distribucion del haber social.', 10, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 6
  UNION ALL SELECT 'Cancelacion de la inscripcion en el Registro Mercantil', NULL, 15, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 7
  UNION ALL SELECT 'Baja censal en AEAT (Mod. 036)', 'Presentar Mod. 036 de cese de actividad. Dar de baja a los trabajadores en SS si los hubiera.', 5, FALSE, 'AEAT', 'RELATIVO_PASO_ANTERIOR', 8
) s WHERE c.code = 'DISOLUCION_SL';

-- CIVIL

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('HERENCIA', 'Herencia', 'CIVIL', 'gavel', '#f0a500', TRUE, TRUE,
'[{"key":"causante","label":"Causante (fallecido)","tipo":"text"},{"key":"fechaFallecimiento","label":"Fecha de fallecimiento","tipo":"date"},{"key":"herederos","label":"Herederos","tipo":"textarea"},{"key":"valorMasa","label":"Valor masa hereditaria (euro)","tipo":"number"},{"key":"tieneTestamento","label":"Existe testamento","tipo":"text","placeholder":"Si / No / Pendiente comprobar"},{"key":"notaria","label":"Notaria","tipo":"text"},{"key":"ccaaCompetente","label":"CCAA competente para el ISD","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='gavel', color='#f0a500', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'HERENCIA');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Obtencion certificado literal de defuncion' AS label, 'Solicitar el certificado literal de defuncion en el Registro Civil del lugar de fallecimiento. Puede tramitarse online en mjusticia.gob.es.' AS notes, 5 AS deadline_days, TRUE AS external_dependency, 'Registro Civil' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Certificado de Actos de Ultima Voluntad', 'Solicitar al Ministerio de Justicia para saber si el causante otorgo testamento y ante que notario. Puede solicitarse desde el dia siguiente al registro de la defuncion.', 10, TRUE, 'Ministerio de Justicia', 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Copia autorizada del testamento o declaracion de herederos', 'Si hay testamento: solicitar copia autorizada al notario autorizante. Si no hay testamento: tramitar acta notarial de declaracion de herederos ab intestato.', 15, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Inventario y valoracion de bienes y deudas', 'Inventariar todos los bienes (inmuebles, cuentas bancarias, vehiculos, valores, seguros de vida) y deudas. Valorar a precio de mercado en la fecha de fallecimiento.', 20, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Redaccion del cuaderno particional', 'Documento privado que describe el caudal relicto y propone la adjudicacion de bienes a cada heredero. Debe respetar la legitima (Derecho Comun: 2/3 para hijos; usufructo vidual de 1/2 para el conyuge).', 10, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Liquidacion del Impuesto sobre Sucesiones y Donaciones', 'Plazo: 6 meses desde el fallecimiento, prorrogable otros 6 meses previa solicitud en el 5 mes. Presentar Mod. 650 o el especifico de la CCAA. NOTA: establecer como fecha de referencia del expediente la fecha de fallecimiento.', 150, FALSE, 'CCAA competente', 'RELATIVO_REFERENCIA', 5
  UNION ALL SELECT 'Escritura de aceptacion y adjudicacion de herencia ante notario', 'Si hay inmuebles, la escritura notarial es obligatoria para inscribir en el Registro de la Propiedad.', 15, TRUE, 'Notaria', 'RELATIVO_PASO_ANTERIOR', 6
  UNION ALL SELECT 'Cambio de titularidad en registros y entidades', 'Inscribir inmuebles en el Registro de la Propiedad. Cambiar titularidad de cuentas, vehiculos (DGT) y valores.', 20, TRUE, 'Registro de la Propiedad / Entidades bancarias', 'RELATIVO_PASO_ANTERIOR', 7
) s WHERE c.code = 'HERENCIA';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('ARRAS', 'Arras', 'CIVIL', 'home', '#f0a500', TRUE, TRUE,
'[{"key":"inmueble","label":"Direccion del inmueble","tipo":"text"},{"key":"precio","label":"Precio de venta acordado (euro)","tipo":"number"},{"key":"importeArras","label":"Importe de arras (euro)","tipo":"number"},{"key":"tipoArras","label":"Tipo de arras","tipo":"text","placeholder":"Penitenciales (art. 1454 CC) / Confirmatorias / Penales"},{"key":"fechaEscritura","label":"Fecha limite para escritura","tipo":"date"},{"key":"notaria","label":"Notaria prevista","tipo":"text"}]')
ON DUPLICATE KEY UPDATE icon='home', color='#f0a500', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'ARRAS');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Obtencion nota simple registral del inmueble' AS label, 'Solicitar nota simple informativa para verificar titular registral, cargas, hipotecas, embargos y servidumbres.' AS notes, 3 AS deadline_days, TRUE AS external_dependency, 'Registro de la Propiedad' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Revision juridica del inmueble y cargas', 'Comprobar que el vendedor es el titular registral. Verificar cargas pendientes (hipoteca, embargo, afeccion por IBI).', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Redaccion del contrato de arras', 'Arras penitenciales (art. 1454 CC): si el comprador desiste pierde las arras; si desiste el vendedor devuelve el doble. Incluir precio, forma de pago, plazos y condiciones suspensivas.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Revision y negociacion con las partes', 'Intercambiar revisiones con comprador y vendedor hasta alcanzar el texto definitivo.', 4, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Firma del contrato de arras', 'Firma presencial o mediante firma electronica cualificada. Es documento privado; no requiere notarizacion aunque es recomendable.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Entrega y acreditacion del importe de arras', 'Transferencia bancaria o cheque conformado. Guardar justificante del pago.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Seguimiento hasta escritura publica', 'Vigilar que el comprador obtiene financiacion, que el vendedor cancela cargas y que se cumplen las condiciones suspensivas en el plazo acordado.', NULL, TRUE, 'Notaria / Entidad bancaria', 'MANUAL', 6
) s WHERE c.code = 'ARRAS';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('COMPRAVENTA_INMUEBLE', 'Compraventa Inmueble', 'CIVIL', 'home', '#f0a500', TRUE, TRUE,
'[{"key":"inmueble","label":"Direccion del inmueble","tipo":"text"},{"key":"refCatastral","label":"Referencia catastral","tipo":"text"},{"key":"precio","label":"Precio de venta (euro)","tipo":"number"},{"key":"tipoTransmision","label":"Tipo de transmision","tipo":"text","placeholder":"1a transmision (IVA+AJD) / 2a transmision (ITP)"},{"key":"notaria","label":"Notaria","tipo":"text"},{"key":"fechaFirma","label":"Fecha de firma escritura","tipo":"date"}]')
ON DUPLICATE KEY UPDATE icon='home', color='#f0a500', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'COMPRAVENTA_INMUEBLE');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Obtencion nota simple y analisis registral' AS label, 'Solicitar nota simple para verificar titularidad, cargas y descripcion registral.' AS notes, 3 AS deadline_days, TRUE AS external_dependency, 'Registro de la Propiedad' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Revision juridica completa del inmueble', 'Verificar: titularidad, limitaciones de disposicion, IBI al dia, arrendatarios con derecho de tanteo, situacion urbanistica.', 4, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Preparacion documentacion para notaria', 'Reunir: escritura anterior, nota simple actualizada, recibo IBI, cedula de habitabilidad si aplica, certificado energetico, certificado de deudas con la comunidad de propietarios.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Obtencion financiacion hipotecaria (si aplica)', 'Coordinacion con banco para tasacion, oferta vinculante (FEIN) y acta previa notarial (obligatoria desde Ley 5/2019). Plazo minimo de 10 dias entre el acta y la firma.', NULL, TRUE, 'Entidad bancaria', 'MANUAL', 3
  UNION ALL SELECT 'Firma de la escritura publica ante notario', 'NOTA: establecer como fecha de referencia del expediente la fecha de la escritura. Los plazos fiscales (ITP, Plusvalia) se computan desde esta fecha.', 0, TRUE, 'Notaria', 'RELATIVO_REFERENCIA', 4
  UNION ALL SELECT 'Liquidacion ITP o IVA+AJD ante la CCAA', 'Plazo: 30 dias habiles desde la escritura. ITP (2a transmision): tipo entre 6-10% segun CCAA. IVA (1a transmision vivienda nueva): 10% general o 4% VPO mas AJD autonomico.', 20, FALSE, 'Comunidad Autonoma', 'RELATIVO_REFERENCIA', 5
  UNION ALL SELECT 'Liquidacion Plusvalia Municipal (IIVTNU) - vendedor', 'Plazo: 30 dias habiles desde la escritura. Calcular segun metodo objetivo o real (STC 182/2021).', 25, FALSE, 'Ayuntamiento', 'RELATIVO_REFERENCIA', 6
  UNION ALL SELECT 'Presentacion a inscripcion en el Registro de la Propiedad', 'Presentar copia autorizada con los justificantes de pago de impuestos. El RP tiene 15 dias para calificar.', 10, TRUE, 'Registro de la Propiedad', 'RELATIVO_PASO_ANTERIOR', 7
) s WHERE c.code = 'COMPRAVENTA_INMUEBLE';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('ARRENDAMIENTO', 'Arrendamiento', 'CIVIL', 'home', '#f0a500', TRUE, TRUE,
'[{"key":"inmueble","label":"Direccion del inmueble","tipo":"text"},{"key":"uso","label":"Uso del inmueble","tipo":"text","placeholder":"Vivienda (LAU) / Local / Nave / Turistico"},{"key":"rentaMensual","label":"Renta mensual (euro)","tipo":"number"},{"key":"duracion","label":"Duracion del contrato","tipo":"text","placeholder":"Vivienda: 5 anios (LAU) / Local: libremente pactada"},{"key":"fianza","label":"Fianza (euro)","tipo":"number"},{"key":"fechaInicio","label":"Fecha de inicio","tipo":"date"}]')
ON DUPLICATE KEY UPDATE icon='home', color='#f0a500', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'ARRENDAMIENTO');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Verificacion de la situacion registral y urbanistica del inmueble' AS label, 'Comprobar titularidad, cargas y que el uso esta permitido urbanisticamente. Para arrendamiento turistico, verificar licencia especifica de la CCAA.' AS notes, 3 AS deadline_days, TRUE AS external_dependency, 'Registro de la Propiedad' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Redaccion del contrato de arrendamiento', 'Vivienda (LAU): duracion minima 5 anios (7 si el arrendador es persona juridica), prorroga tacita de 3 anios. Local: duracion libremente pactada. Incluir renta, actualizacion (IPC) y fianza legal (1 mes vivienda / 2 meses locales).', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Revision y negociacion con las partes', 'Ajustar condiciones economicas y clausulas. Documentar el estado del inmueble y el inventario de mobiliario.', 4, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Firma del contrato y entrega de llaves', 'Firmar presencialmente. Arrendatario entrega fianza y garantia adicional en el acto.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Deposito de fianza en organismo autonomico', 'El arrendador debe depositar la fianza en el organismo competente de la CCAA en el plazo establecido (generalmente 30 dias desde la firma). El incumplimiento puede generar multas.', 30, TRUE, 'Organismo autonomico de vivienda', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Registro del contrato (si aplica)', 'El registro es voluntario pero recomendable para oponer el contrato frente a terceros adquirentes del inmueble.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 5
) s WHERE c.code = 'ARRENDAMIENTO';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('DIVORCIO', 'Divorcio', 'CIVIL', 'gavel', '#f0a500', TRUE, TRUE,
'[{"key":"modalidad","label":"Modalidad","tipo":"text","placeholder":"Mutuo acuerdo (notarial/judicial) / Contencioso"},{"key":"hijos","label":"Hijos menores / dependientes","tipo":"text"},{"key":"regimenEconomico","label":"Regimen economico matrimonial","tipo":"text","placeholder":"Gananciales / Separacion de bienes"},{"key":"bienes","label":"Bienes a liquidar","tipo":"textarea"}]')
ON DUPLICATE KEY UPDATE icon='gavel', color='#f0a500', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'DIVORCIO');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Reunion inicial y recogida de documentacion' AS label, 'Solicitar: libro de familia o certificado de matrimonio, DNI de ambos conyuge, certificados de nacimiento de hijos, documentacion patrimonial. Analizar regimen economico matrimonial.' AS notes, 5 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Inventario y propuesta de liquidacion de bienes', 'Para gananciales: inventariar bienes y calcular el haber ganancial de cada conyuge. Incluir deudas comunes. En separacion de bienes: valorar posibles compensaciones economicas.', 10, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Redaccion del convenio regulador', 'El convenio debe regular: guardia y custodia de hijos, regimen de visitas, pension de alimentos, pension compensatoria si aplica, uso de la vivienda familiar y liquidacion del regimen economico.', 10, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Revision y acuerdo de las partes', 'Intercambio de propuestas. Si es contencioso puede haber intento de mediacion familiar.', 15, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Presentacion ante Notario o Juzgado', 'Sin hijos menores y mutuo acuerdo: puede formalizarse ante Notario (Ley 15/2015). Con hijos menores o sin acuerdo: siempre ante el Juzgado de Primera Instancia.', 5, TRUE, 'Notaria / Juzgado de Primera Instancia', 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Ratificacion / Sentencia / Escritura de divorcio', 'Notarial: escritura en pocos dias. Judicial mutuo acuerdo: sentencia en 1-3 meses. Contencioso: sentencia en 6-18 meses segun juzgado.', 45, TRUE, 'Notaria / Juzgado', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Inscripcion en el Registro Civil', 'Inscribir la sentencia o escritura de divorcio en el Registro Civil del lugar de matrimonio. Actualizar tambien el libro de familia.', 10, TRUE, 'Registro Civil', 'RELATIVO_PASO_ANTERIOR', 6
) s WHERE c.code = 'DIVORCIO';

-- CONTABLE

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('CONTABILIDAD_MENSUAL', 'Contabilidad Mensual', 'CONTABLE', 'calculate', '#2563eb', TRUE, TRUE,
'[{"key":"mes","label":"Mes y ejercicio","tipo":"text","placeholder":"Enero 2025"},{"key":"numFacturasEmitidas","label":"Num. facturas emitidas","tipo":"number"},{"key":"numFacturasRecibidas","label":"Num. facturas recibidas","tipo":"number"},{"key":"incidencias","label":"Incidencias del mes","tipo":"textarea"}]')
ON DUPLICATE KEY UPDATE icon='calculate', color='#2563eb', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'CONTABILIDAD_MENSUAL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Recepcion facturas emitidas, recibidas y extractos bancarios' AS label, 'Solicitar al cliente toda la documentacion del mes: facturas de venta y compra, extractos bancarios, justificantes de pagos en efectivo y ticketes con IVA deducible.' AS notes, 5 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Registro de asientos contables', 'Contabilizar todas las facturas y operaciones siguiendo el Plan General Contable. Verificar el IVA repercutido y soportado. Registrar nominas, amortizaciones e imputaciones del mes.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Conciliacion bancaria', 'Cuadrar el saldo contable de las cuentas bancarias con los extractos. Identificar y justificar cualquier partida en conciliacion.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Revision de saldos y cuadre del balance', 'Verificar que el balance esta cuadrado, que los saldos de clientes/proveedores son coherentes y que no hay partidas descuadradas.', 2, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Elaboracion y envio de informe mensual al cliente', 'Entregar resumen de ingresos, gastos, resultado del mes, IVA pendiente y cualquier alerta fiscal o contable.', 1, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
) s WHERE c.code = 'CONTABILIDAD_MENSUAL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('CIERRE_ANUAL', 'Cierre Anual', 'CONTABLE', 'calculate', '#2563eb', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio","tipo":"text","placeholder":"2024"},{"key":"resultado","label":"Resultado del ejercicio (euro)","tipo":"number"},{"key":"fechaCierre","label":"Fecha de cierre del ejercicio","tipo":"date"},{"key":"tipoEntidad","label":"Tipo de entidad","tipo":"text","placeholder":"SL / SA / Autonomo / Asociacion"}]')
ON DUPLICATE KEY UPDATE icon='calculate', color='#2563eb', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'CIERRE_ANUAL');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Asientos de ajuste y cierre provisional' AS label, 'Periodificaciones (ingresos y gastos diferidos), ajustes de provisiones, regularizacion de existencias y correcciones de errores de periodos anteriores.' AS notes, 15 AS deadline_days, FALSE AS external_dependency, NULL AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Regularizacion de amortizaciones', 'Calcular las cuotas de amortizacion del ejercicio para todos los elementos del inmovilizado. Revisar bajas e incorporaciones del anio.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Conciliacion bancaria final del ejercicio', 'Cuadrar todas las cuentas bancarias a 31 de diciembre. Verificar que coinciden con los extractos finales del banco.', 3, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Formulacion de las cuentas anuales', 'Elaborar: Balance de situacion, Cuenta de Perdidas y Ganancias, Estado de Cambios en el Patrimonio Neto y Memoria (normal o abreviada segun tamano).', 7, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Aprobacion de cuentas anuales por la Junta General', 'La Junta General debe aprobar las cuentas dentro de los 6 meses siguientes al cierre (antes del 30 de junio para ejercicios que cierran el 31/12).', 60, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Legalizacion de libros contables en Registro Mercantil', 'Presentar en el Portal del RM el fichero de libros firmado electronicamente. Plazo: 4 meses desde el cierre (antes del 30 de abril para ejercicio natural).', 4, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Deposito de cuentas anuales en Registro Mercantil', 'Presentar las cuentas aprobadas en el plazo de 1 mes desde la aprobacion por la Junta. Para ejercicio natural: antes del 30 de julio. Incumplimiento: multa de 1.200 a 60.000 euros (TRLSC).', 30, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 6
) s WHERE c.code = 'CIERRE_ANUAL';

INSERT INTO catalog (code, name, category, icon, color, is_builtin, active, campos_extra)
VALUES ('AUDITORIA', 'Auditoria', 'CONTABLE', 'calculate', '#2563eb', TRUE, TRUE,
'[{"key":"ejercicio","label":"Ejercicio auditado","tipo":"text","placeholder":"2024"},{"key":"tipoAuditoria","label":"Tipo de auditoria","tipo":"text","placeholder":"Obligatoria (TRLAC) / Voluntaria / Por encargo de socios (art. 265 LSC)"},{"key":"auditorDesignado","label":"Auditor designado","tipo":"text"},{"key":"honorariosAuditoria","label":"Honorarios de auditoria (euro)","tipo":"number"}]')
ON DUPLICATE KEY UPDATE icon='calculate', color='#2563eb', is_builtin=TRUE;

DELETE FROM catalog_step WHERE catalog_id = (SELECT id FROM catalog WHERE code = 'AUDITORIA');
INSERT INTO catalog_step (catalog_id, label, notes, deadline_days, external_dependency, responsible_entity, plazo_tipo, sort_order)
SELECT c.id, s.label, s.notes, s.deadline_days, s.external_dependency, s.responsible_entity, s.plazo_tipo, s.sort_order
FROM catalog c CROSS JOIN (
  SELECT 'Contratacion del auditor y carta de encargo' AS label, 'Si es obligatoria: el auditor es designado por el Registro Mercantil. Si es voluntaria: nombramiento por la Junta General. Emitir carta de encargo con alcance y plazos (NIA-ES 210).' AS notes, 5 AS deadline_days, TRUE AS external_dependency, 'Auditor / Registro Mercantil' AS responsible_entity, 'RELATIVO_APERTURA' AS plazo_tipo, 0 AS sort_order
  UNION ALL SELECT 'Planificacion de la auditoria', 'El auditor elabora el plan: evaluacion del control interno, riesgos significativos, materialidad y areas de enfoque.', 7, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 1
  UNION ALL SELECT 'Preparacion de la documentacion contable para el auditor', 'Poner a disposicion: libros contables, mayores, balances, contratos significativos, actas de junta, impuestos presentados y toda la documentacion soporte.', 5, FALSE, NULL, 'RELATIVO_PASO_ANTERIOR', 2
  UNION ALL SELECT 'Trabajo de campo - pruebas de auditoria', 'El auditor realiza pruebas de control y sustantivas: circularizacion de clientes/proveedores, inventario fisico, revision de partidas significativas.', 20, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 3
  UNION ALL SELECT 'Revision de incidencias y carta de recomendaciones', 'El auditor comunica las salvedades detectadas (carta de representacion de la direccion). Reunion de cierre para valorar ajustes o discrepancias.', 7, TRUE, NULL, 'RELATIVO_PASO_ANTERIOR', 4
  UNION ALL SELECT 'Emision del informe de auditoria', 'El auditor emite el informe (opinion favorable, con salvedades, desfavorable o denegada). Debe cumplir las NIA-ES y estar firmado por el auditor (NIA-ES 700/705/706).', 7, TRUE, 'Auditor / ICAC', 'RELATIVO_PASO_ANTERIOR', 5
  UNION ALL SELECT 'Deposito cuentas anuales con informe en el Registro Mercantil', 'Las cuentas auditadas se depositan junto con el informe en el mismo plazo que el deposito ordinario (1 mes desde la aprobacion por la Junta).', 30, TRUE, 'Registro Mercantil', 'RELATIVO_PASO_ANTERIOR', 6
) s WHERE c.code = 'AUDITORIA';

