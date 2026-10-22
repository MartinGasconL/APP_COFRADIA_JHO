-- migration-004-comments.sql
-- Muro de actividad/comentarios con @menciones y notificaciones

ALTER TABLE employee
    ADD COLUMN username VARCHAR(50) UNIQUE NULL;

CREATE TABLE case_file_comment (
    id                  BIGINT       AUTO_INCREMENT PRIMARY KEY,
    case_file_id        BIGINT       NOT NULL,
    author_employee_id  BIGINT       NOT NULL,
    content             TEXT         NOT NULL,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comment_case_file FOREIGN KEY (case_file_id)       REFERENCES case_file(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_author    FOREIGN KEY (author_employee_id)  REFERENCES employee(id)
);

CREATE TABLE employee_notification (
    id                   BIGINT       AUTO_INCREMENT PRIMARY KEY,
    employee_id          BIGINT       NOT NULL,
    comment_id           BIGINT       NOT NULL,
    case_file_id         BIGINT       NOT NULL,
    case_file_reference  VARCHAR(20)  NOT NULL,
    is_read              BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_employee FOREIGN KEY (employee_id) REFERENCES employee(id),
    CONSTRAINT fk_notif_comment  FOREIGN KEY (comment_id)  REFERENCES case_file_comment(id) ON DELETE CASCADE
);

CREATE INDEX idx_comment_case_file ON case_file_comment(case_file_id);
CREATE INDEX idx_notif_employee    ON employee_notification(employee_id, is_read);

-- Vincular empleados a sus usuarios de acceso (patrón: inicial + apellido)
UPDATE employee SET username = 'jlaste'      WHERE UPPER(LEFT(first_name,1)) = 'J' AND LOWER(last_name) = 'laste';
UPDATE employee SET username = 'vlaste'      WHERE UPPER(LEFT(first_name,1)) = 'V' AND LOWER(last_name) = 'laste';
UPDATE employee SET username = 'jcastellote' WHERE LOWER(last_name) = 'castellote';
