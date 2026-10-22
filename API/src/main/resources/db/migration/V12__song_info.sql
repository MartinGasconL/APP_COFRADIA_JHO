-- La información (Markdown) pasa a ser por canción, en lugar de un documento global.
ALTER TABLE songs
    ADD COLUMN info_markdown MEDIUMTEXT NULL;

DROP TABLE info_page;
