-- Ramas de partes (bifurcación con punto de reconciliación).
-- branch_key NULL = línea principal. Con valor = parte de una rama.
-- branch_from / branch_to = sort_order de la parte principal donde bifurca / reconcilia.
ALTER TABLE song_sections
    ADD COLUMN branch_key  VARCHAR(40) NULL AFTER sort_order,
    ADD COLUMN branch_from  INT        NULL AFTER branch_key,
    ADD COLUMN branch_to    INT        NULL AFTER branch_from;
