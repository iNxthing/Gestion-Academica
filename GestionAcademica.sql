DROP DATABASE IF EXISTS gestion_academica;
CREATE DATABASE IF NOT EXISTS gestion_academica;
USE gestion_academica;

CREATE TABLE perfil (
    idPerfil INT AUTO_INCREMENT PRIMARY KEY,
    nombrePerfil VARCHAR(30) NOT NULL
);

INSERT INTO perfil (idPerfil, nombrePerfil) VALUES 
(1, 'ADMINISTRADOR'), 
(2, 'PROFESOR');

CREATE TABLE grado (
    id_grado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(45) NOT NULL
);

INSERT INTO grado (nombre) VALUES ('Sexto'), ('Séptimo');

CREATE TABLE periodo (
    id_periodo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);

INSERT INTO periodo (nombre) VALUES ('Periodo 1'), ('Periodo 2'), ('Periodo 3'), ('Periodo 4');

CREATE TABLE asignatura (
    id_asignatura INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    id_grado INT NOT NULL,
    FOREIGN KEY (id_grado) REFERENCES grado(id_grado)
);

INSERT INTO asignatura (nombre, id_grado) VALUES ('Matemáticas', 1), ('Español', 1);

CREATE TABLE usuario (
    idUsuario INT AUTO_INCREMENT PRIMARY KEY,
    documento VARCHAR(20) NULL,
    nombre VARCHAR(100) NOT NULL,
    usr VARCHAR(45) NOT NULL UNIQUE,
    pass VARCHAR(45) NOT NULL,
    idPerfil INT NOT NULL,
    idAsignatura INT NULL,
    FOREIGN KEY (idPerfil) REFERENCES perfil(idPerfil),
    FOREIGN KEY (idAsignatura) REFERENCES asignatura(id_asignatura)
);

INSERT INTO usuario (documento, nombre, usr, pass, idPerfil, idAsignatura) 
VALUES ('0000', 'Administrador', 'admin', '1234', 1, NULL);

CREATE TABLE estudiante (
    id_estudiante INT AUTO_INCREMENT PRIMARY KEY,
    documento VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    id_grado INT NOT NULL,
    FOREIGN KEY (id_grado) REFERENCES grado(id_grado)
);

CREATE TABLE nota (
    id_nota INT AUTO_INCREMENT PRIMARY KEY,
    id_estudiante INT NOT NULL,
    id_asignatura INT NOT NULL,
    id_periodo INT NOT NULL,
    valor_nota DECIMAL(4, 2) NOT NULL,
    UNIQUE (id_estudiante, id_asignatura, id_periodo),
    FOREIGN KEY (id_estudiante) REFERENCES estudiante(id_estudiante),
    FOREIGN KEY (id_asignatura) REFERENCES asignatura(id_asignatura),
    FOREIGN KEY (id_periodo) REFERENCES periodo(id_periodo)
);

DELIMITER //

DROP PROCEDURE IF EXISTS sp_login //
CREATE PROCEDURE sp_login(
    IN p_usuario VARCHAR(45),
    IN p_clave VARCHAR(45)
)
BEGIN
    IF EXISTS (SELECT 1 FROM usuario WHERE usr = p_usuario AND pass = p_clave) THEN
        SELECT 
            idUsuario,
            usr,
            idPerfil,
            idUsuario AS idProfesor,
            IFNULL(idAsignatura, 0) AS idAsignatura,
            nombre AS nombrePersona
        FROM usuario
        WHERE usr = p_usuario AND pass = p_clave;
    ELSE
        SELECT 0 AS idUsuario, 0 AS idPerfil, 0 AS idProfesor, 0 AS idAsignatura, '' AS nombrePersona;
    END IF;
END //

DROP PROCEDURE IF EXISTS sp_agregar_profesor //
CREATE PROCEDURE sp_agregar_profesor(
    IN p_documento VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_usuario VARCHAR(45),
    IN p_clave VARCHAR(45),
    IN p_id_asignatura INT
)
BEGIN
    INSERT INTO usuario (documento, nombre, usr, pass, idPerfil, idAsignatura)
    VALUES (p_documento, p_nombre, p_usuario, p_clave, 2, p_id_asignatura);
END //

DROP PROCEDURE IF EXISTS sp_listar_profesores //
CREATE PROCEDURE sp_listar_profesores()
BEGIN
    SELECT 
        u.documento AS Documento, 
        u.nombre AS Profesor, 
        a.nombre AS Asignatura, 
        u.usr AS Usuario,
        u.pass AS Clave
    FROM usuario u
    INNER JOIN asignatura a ON u.idAsignatura = a.id_asignatura
    WHERE u.idPerfil = 2
    ORDER BY u.nombre;
END //

DROP PROCEDURE IF EXISTS sp_matricular_estudiante //
CREATE PROCEDURE sp_matricular_estudiante(
    IN p_documento VARCHAR(20),
    IN p_nombre VARCHAR(100),
    IN p_id_grado INT
)
BEGIN
    INSERT INTO estudiante (documento, nombre, id_grado)
    VALUES (p_documento, p_nombre, p_id_grado);
END //

DROP PROCEDURE IF EXISTS sp_matriculados //
CREATE PROCEDURE sp_matriculados()
BEGIN
    SELECT 
        e.documento AS Documento, 
        e.nombre AS Estudiante, 
        g.nombre AS Grado
    FROM estudiante e
    INNER JOIN grado g ON e.id_grado = g.id_grado
    ORDER BY e.nombre;
END //

DROP PROCEDURE IF EXISTS sp_guardar_nota //
CREATE PROCEDURE sp_guardar_nota(
    IN p_id_estudiante INT,
    IN p_id_asignatura INT,
    IN p_id_periodo INT,
    IN p_valor_nota DECIMAL(4, 2)
)
BEGIN
    INSERT INTO nota (id_estudiante, id_asignatura, id_periodo, valor_nota)
    VALUES (p_id_estudiante, p_id_asignatura, p_id_periodo, p_valor_nota)
    ON DUPLICATE KEY UPDATE valor_nota = p_valor_nota;
END //

DROP PROCEDURE IF EXISTS sp_listar_para_notas //
CREATE PROCEDURE sp_listar_para_notas(
    IN p_id_asignatura INT,
    IN p_id_periodo INT
)
BEGIN
    SELECT 
        e.id_estudiante AS idEstudiante,
        e.documento AS Documento,
        e.nombre AS Estudiante,
        n.valor_nota AS Nota
    FROM estudiante e
    INNER JOIN asignatura a ON e.id_grado = a.id_grado
    LEFT JOIN nota n ON (e.id_estudiante = n.id_estudiante 
                     AND n.id_asignatura = p_id_asignatura 
                     AND n.id_periodo = p_id_periodo)
    WHERE a.id_asignatura = p_id_asignatura
    ORDER BY e.nombre;
END //

DROP PROCEDURE IF EXISTS sp_filtro_matriculados //
CREATE PROCEDURE sp_filtro_matriculados(
    IN p_id_grado INT,
    IN p_id_asignatura INT
)
BEGIN
    SELECT 
        e.documento AS Documento,
        e.nombre AS Estudiante,
        g.nombre AS Grado,
        a.nombre AS Asignatura,
        IFNULL(u.nombre, 'Sin asignar') AS Profesor
    FROM estudiante e
    INNER JOIN grado g ON e.id_grado = g.id_grado
    INNER JOIN asignatura a ON g.id_grado = a.id_grado
    LEFT JOIN usuario u ON (a.id_asignatura = u.idAsignatura AND u.idPerfil = 2)
    WHERE (p_id_grado IS NULL OR p_id_grado = 0 OR g.id_grado = p_id_grado)
      AND (p_id_asignatura IS NULL OR p_id_asignatura = 0 OR a.id_asignatura = p_id_asignatura)
    ORDER BY g.nombre, a.nombre, e.nombre;
END //

DROP PROCEDURE IF EXISTS sp_reporte_rendimiento //
CREATE PROCEDURE sp_reporte_rendimiento(
    IN p_nota_minima DECIMAL(4, 2),
    IN p_id_grado INT,
    IN p_id_asignatura INT,
    IN p_id_estudiante INT,
    IN p_id_periodo INT
)
BEGIN
    SELECT 
        e.documento AS Documento,
        e.nombre AS Estudiante,
        g.nombre AS Grado,
        a.nombre AS Asignatura,
        per.nombre AS Periodo,
        n.valor_nota AS Nota,
        CASE 
            WHEN n.valor_nota >= p_nota_minima THEN 'APROBADO'
            ELSE 'REPROBADO'
        END AS Estado
    FROM nota n
    INNER JOIN estudiante e ON n.id_estudiante = e.id_estudiante
    INNER JOIN grado g ON e.id_grado = g.id_grado
    INNER JOIN asignatura a ON n.id_asignatura = a.id_asignatura
    INNER JOIN periodo per ON n.id_periodo = per.id_periodo
    WHERE (p_id_grado IS NULL OR p_id_grado = 0 OR g.id_grado = p_id_grado)
      AND (p_id_asignatura IS NULL OR p_id_asignatura = 0 OR a.id_asignatura = p_id_asignatura)
      AND (p_id_estudiante IS NULL OR p_id_estudiante = 0 OR e.id_estudiante = p_id_estudiante)
      AND (p_id_periodo IS NULL OR p_id_periodo = 0 OR per.id_periodo = p_id_periodo)
    ORDER BY g.nombre, a.nombre, per.nombre, e.nombre;
END //

DROP PROCEDURE IF EXISTS sp_combo_grados //
CREATE PROCEDURE sp_combo_grados()
BEGIN
    SELECT 
        id_grado AS idGrado, 
        nombre AS nombreGrado
    FROM grado 
    ORDER BY id_grado;
END //

DROP PROCEDURE IF EXISTS sp_combo_periodos //
CREATE PROCEDURE sp_combo_periodos()
BEGIN
    SELECT 
        id_periodo AS idPeriodo, 
        nombre AS nombrePeriodo 
    FROM periodo 
    ORDER BY id_periodo;
END //

DROP PROCEDURE IF EXISTS sp_combo_asignaturas //
CREATE PROCEDURE sp_combo_asignaturas(IN p_id_asignatura INT)
BEGIN
    SELECT 
        a.id_asignatura AS idAsignatura, 
        CONCAT(a.nombre, ' (', g.nombre, ')') AS nombreAsignatura,
        g.nombre AS nombreGrado
    FROM asignatura a
    INNER JOIN grado g ON a.id_grado = g.id_grado
    WHERE (p_id_asignatura IS NULL OR p_id_asignatura = 0 OR a.id_asignatura = p_id_asignatura)
    ORDER BY a.nombre;
END //

DROP PROCEDURE IF EXISTS sp_combo_estudiantes //
CREATE PROCEDURE sp_combo_estudiantes()
BEGIN
    SELECT 
        id_estudiante AS idEstudiante, 
        CONCAT(documento, ' - ', nombre) AS nombreEstudiante 
    FROM estudiante 
    ORDER BY nombre;
END //

DELIMITER ;
