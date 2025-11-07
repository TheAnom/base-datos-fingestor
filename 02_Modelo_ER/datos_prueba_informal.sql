-- Datos de prueba para el sistema educativo
-- Autor: Proyecto BDII
-- Fecha: Noviembre 2024

USE BD2_Curso2025;
GO

-- Insertamos los grados académicos básicos
INSERT INTO grado (nombre, descripcion, nivel_educativo) VALUES
('Primero', 'Primer grado de primaria', 'Primaria'),
('Segundo', 'Segundo grado de primaria', 'Primaria'),
('Tercero', 'Tercer grado de primaria', 'Primaria'),
('Cuarto', 'Cuarto grado de primaria', 'Primaria'),
('Quinto', 'Quinto grado de primaria', 'Primaria'),
('Sexto', 'Sexto grado de secundaria', 'Secundaria'),
('Séptimo', 'Séptimo grado de secundaria', 'Secundaria'),
('Octavo', 'Octavo grado de secundaria', 'Secundaria'),
('Noveno', 'Noveno grado de secundaria', 'Secundaria'),
('Décimo', 'Décimo grado de bachillerato', 'Bachillerato'),
('Undécimo', 'Undécimo grado de bachillerato', 'Bachillerato');

-- Profesores con sus especialidades
INSERT INTO profesor (nombre_completo, documento_identidad, telefono, email, especialidad, titulo_academico, fecha_contratacion, salario_base) VALUES
('María González Pérez', '12345678', '555-0101', 'maria.gonzalez@edugestor.edu', 'Matemáticas', 'Licenciatura en Matemáticas', '2020-02-15', 2500000.00),
('Carlos Rodríguez López', '23456789', '555-0102', 'carlos.rodriguez@edugestor.edu', 'Ciencias Naturales', 'Licenciatura en Biología', '2019-08-20', 2400000.00),
('Ana Martínez Silva', '34567890', '555-0103', 'ana.martinez@edugestor.edu', 'Español y Literatura', 'Licenciatura en Literatura', '2021-01-10', 2300000.00),
('Luis Hernández Castro', '45678901', '555-0104', 'luis.hernandez@edugestor.edu', 'Ciencias Sociales', 'Licenciatura en Historia', '2018-03-05', 2600000.00),
('Patricia Jiménez Mora', '56789012', '555-0105', 'patricia.jimenez@edugestor.edu', 'Inglés', 'Licenciatura en Idiomas', '2022-07-12', 2200000.00),
('Roberto Vargas Solano', '67890123', '555-0106', 'roberto.vargas@edugestor.edu', 'Educación Física', 'Licenciatura en Educación Física', '2020-09-18', 2100000.00),
('Carmen Rojas Vega', '78901234', '555-0107', 'carmen.rojas@edugestor.edu', 'Artes', 'Licenciatura en Artes Plásticas', '2021-11-22', 2000000.00);

-- Cursos que se van a dictar
INSERT INTO curso (nombre, codigo_curso, descripcion, creditos, horas_semanales, profesor_id, grado_id, periodo_academico) VALUES
('Matemáticas Básicas', 'MAT101', 'Fundamentos de aritmética y álgebra básica', 4, 5, 1, 1, '2024-1'),
('Ciencias Naturales I', 'CIE101', 'Introducción a las ciencias naturales', 3, 4, 2, 1, '2024-1'),
('Español y Comunicación', 'ESP101', 'Desarrollo de habilidades comunicativas', 4, 5, 3, 1, '2024-1'),
('Ciencias Sociales I', 'SOC101', 'Historia y geografía básica', 3, 3, 4, 1, '2024-1'),
('Matemáticas Intermedias', 'MAT201', 'Álgebra y geometría intermedia', 4, 5, 1, 6, '2024-1'),
('Biología General', 'BIO201', 'Fundamentos de biología', 4, 4, 2, 6, '2024-1'),
('Literatura Española', 'LIT201', 'Análisis de textos literarios', 3, 4, 3, 6, '2024-1'),
('Historia Universal', 'HIS201', 'Historia mundial y nacional', 3, 3, 4, 6, '2024-1'),
('Inglés Básico', 'ING101', 'Fundamentos del idioma inglés', 3, 4, 5, 1, '2024-1'),
('Educación Física', 'EDF101', 'Desarrollo físico y deportivo', 2, 3, 6, 1, '2024-1'),
('Artes Plásticas', 'ART101', 'Expresión artística y creatividad', 2, 2, 7, 1, '2024-1');

-- Estudiantes de ejemplo
INSERT INTO estudiante (nombre_completo, documento_identidad, telefono, email, fecha_nacimiento, direccion, grado_id, institucion) VALUES
('Juan Carlos Pérez Morales', 'E12345678', '555-1001', 'juan.perez@estudiante.edu', '2010-03-15', 'Calle 123 #45-67', 1, 'Colegio San José'),
('María Fernanda López García', 'E23456789', '555-1002', 'maria.lopez@estudiante.edu', '2010-07-22', 'Carrera 89 #12-34', 1, 'Colegio San José'),
('Carlos Andrés Rodríguez Vega', 'E34567890', '555-1003', 'carlos.rodriguez@estudiante.edu', '2010-11-08', 'Avenida 56 #78-90', 1, 'Colegio San José'),
('Ana Sofía Martínez Cruz', 'E45678901', '555-1004', 'ana.martinez@estudiante.edu', '2010-01-30', 'Calle 234 #56-78', 1, 'Colegio San José'),
('Luis Miguel Hernández Silva', 'E56789012', '555-1005', 'luis.hernandez@estudiante.edu', '2010-09-12', 'Carrera 123 #45-67', 1, 'Colegio San José'),
('Patricia Elena Jiménez Mora', 'E67890123', '555-1006', 'patricia.jimenez@estudiante.edu', '2005-04-18', 'Avenida 789 #01-23', 6, 'Colegio San José'),
('Roberto José Vargas Castro', 'E78901234', '555-1007', 'roberto.vargas@estudiante.edu', '2005-12-05', 'Calle 345 #67-89', 6, 'Colegio San José'),
('Carmen Lucía Rojas Solano', 'E89012345', '555-1008', 'carmen.rojas@estudiante.edu', '2005-08-27', 'Carrera 456 #78-90', 6, 'Colegio San José'),
('Diego Alejandro Morales Vega', 'E90123456', '555-1009', 'diego.morales@estudiante.edu', '2005-02-14', 'Avenida 567 #89-01', 6, 'Colegio San José'),
('Valentina Gómez Herrera', 'E01234567', '555-1010', 'valentina.gomez@estudiante.edu', '2005-06-03', 'Calle 678 #90-12', 6, 'Colegio San José');

-- Conceptos por los que se puede pagar
INSERT INTO concepto_pago (nombre, descripcion, monto_base, tipo_concepto, obligatorio) VALUES
('Matrícula Anual', 'Pago de matrícula para el año académico', 500000.00, 'INSCRIPCION', 1),
('Mensualidad', 'Pago mensual de pensión', 200000.00, 'MENSUALIDAD', 1),
('Examen Supletorio', 'Costo de examen supletorio o de recuperación', 50000.00, 'EXAMEN', 0),
('Certificado de Estudios', 'Emisión de certificado académico', 25000.00, 'CERTIFICADO', 0),
('Seguro Estudiantil', 'Seguro de accidentes para estudiantes', 75000.00, 'OTROS', 1),
('Material Didáctico', 'Costo de materiales y libros', 150000.00, 'OTROS', 1),
('Actividades Extracurriculares', 'Deportes, arte y otras actividades', 100000.00, 'OTROS', 0);

-- Roles básicos del sistema
INSERT INTO rol (nombre, descripcion, nivel_acceso) VALUES
('Administrador', 'Acceso completo al sistema', 4),
('Coordinador Académico', 'Gestión académica y reportes', 3),
('Secretario', 'Registro de estudiantes y pagos', 2),
('Profesor', 'Acceso a calificaciones de sus cursos', 2),
('Consulta', 'Solo lectura de información básica', 1);

-- Permisos que se pueden asignar
INSERT INTO permiso (nombre, descripcion, modulo, operacion) VALUES
('Ver Estudiantes', 'Consultar información de estudiantes', 'ACADEMICO', 'SELECT'),
('Crear Estudiantes', 'Registrar nuevos estudiantes', 'ACADEMICO', 'INSERT'),
('Editar Estudiantes', 'Modificar información de estudiantes', 'ACADEMICO', 'UPDATE'),
('Eliminar Estudiantes', 'Eliminar registros de estudiantes', 'ACADEMICO', 'DELETE'),
('Ver Calificaciones', 'Consultar calificaciones', 'ACADEMICO', 'SELECT'),
('Editar Calificaciones', 'Modificar calificaciones', 'ACADEMICO', 'UPDATE'),
('Ver Pagos', 'Consultar información de pagos', 'FINANCIERO', 'SELECT'),
('Registrar Pagos', 'Crear nuevos registros de pago', 'FINANCIERO', 'INSERT'),
('Anular Pagos', 'Anular transacciones de pago', 'FINANCIERO', 'UPDATE'),
('Gestionar Usuarios', 'Administrar usuarios del sistema', 'SEGURIDAD', 'ALL'),
('Ver Reportes', 'Acceso a reportes del sistema', 'REPORTES', 'SELECT'),
('Ejecutar Procedimientos', 'Ejecutar procedimientos almacenados', 'ACADEMICO', 'EXECUTE');

-- Usuarios de ejemplo para el sistema
INSERT INTO usuario (nombre_usuario, nombre_completo, email, password_hash) VALUES
('admin', 'Administrador del Sistema', 'admin@edugestor.edu', 'hash_admin_password'),
('coord_academico', 'Coordinador Académico Principal', 'coordinador@edugestor.edu', 'hash_coord_password'),
('secretaria1', 'María Secretaria González', 'secretaria1@edugestor.edu', 'hash_sec1_password'),
('prof_matematicas', 'María González Pérez', 'maria.gonzalez@edugestor.edu', 'hash_prof_mat_password'),
('prof_ciencias', 'Carlos Rodríguez López', 'carlos.rodriguez@edugestor.edu', 'hash_prof_cie_password'),
('consulta_general', 'Usuario de Consulta', 'consulta@edugestor.edu', 'hash_consulta_password');

PRINT 'Datos maestros insertados correctamente';
GO

-- Ahora vamos con los datos transaccionales

-- Asignamos roles a los usuarios
INSERT INTO usuario_rol (usuario_id, rol_id) VALUES
(1, 1), -- admin es administrador
(2, 2), -- coordinador académico
(3, 3), -- secretaria
(4, 4), -- profesor de matemáticas
(5, 4), -- profesor de ciencias
(6, 5); -- usuario de consulta

-- Le damos permisos a cada rol
-- El admin puede hacer todo
INSERT INTO permiso_rol (rol_id, permiso_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1, 10), (1, 11), (1, 12);

-- El coordinador maneja lo académico y ve reportes
INSERT INTO permiso_rol (rol_id, permiso_id) VALUES
(2, 1), (2, 2), (2, 3), (2, 5), (2, 6), (2, 7), (2, 11), (2, 12);

-- La secretaria maneja estudiantes y pagos
INSERT INTO permiso_rol (rol_id, permiso_id) VALUES
(3, 1), (3, 2), (3, 3), (3, 7), (3, 8);

-- Los profesores solo ven y califican
INSERT INTO permiso_rol (rol_id, permiso_id) VALUES
(4, 1), (4, 5), (4, 6);

-- Usuario de consulta solo ve cosas básicas
INSERT INTO permiso_rol (rol_id, permiso_id) VALUES
(5, 1), (5, 5), (5, 7), (5, 11);

-- Matriculamos estudiantes en cursos
-- Estudiantes de primer grado
INSERT INTO asignacion_curso (estudiante_id, curso_id) VALUES
-- Juan Carlos en todas las materias de primero
(1, 1), (1, 2), (1, 3), (1, 4), (1, 9), (1, 10), (1, 11),
-- María Fernanda también
(2, 1), (2, 2), (2, 3), (2, 4), (2, 9), (2, 10), (2, 11),
-- Carlos Andrés igual
(3, 1), (3, 2), (3, 3), (3, 4), (3, 9), (3, 10), (3, 11),
-- Ana Sofía también
(4, 1), (4, 2), (4, 3), (4, 4), (4, 9), (4, 10), (4, 11),
-- Luis Miguel igual
(5, 1), (5, 2), (5, 3), (5, 4), (5, 9), (5, 10), (5, 11);

-- Estudiantes de sexto grado
INSERT INTO asignacion_curso (estudiante_id, curso_id) VALUES
-- Patricia en materias de sexto
(6, 5), (6, 6), (6, 7), (6, 8),
-- Roberto también
(7, 5), (7, 6), (7, 7), (7, 8),
-- Carmen igual
(8, 5), (8, 6), (8, 7), (8, 8),
-- Diego también
(9, 5), (9, 6), (9, 7), (9, 8),
-- Valentina igual
(10, 5), (10, 6), (10, 7), (10, 8);

-- Ponemos algunas calificaciones de ejemplo
INSERT INTO calificacion (asignacion_curso_id, nota_parcial1, nota_parcial2, nota_parcial3, nota_final, estado_calificacion) VALUES
-- Juan Carlos - buen estudiante
(1, 85.5, 88.0, 90.5, 88.0, 'APROBADO'),
(2, 92.0, 89.5, 91.0, 90.8, 'APROBADO'),
(3, 78.5, 82.0, 85.5, 82.0, 'APROBADO'),
(4, 88.0, 85.5, 87.0, 86.8, 'APROBADO'),

-- María Fernanda - excelente estudiante
(8, 95.0, 92.5, 94.0, 93.8, 'APROBADO'),
(9, 89.5, 91.0, 88.5, 89.7, 'APROBADO'),
(10, 87.0, 89.5, 92.0, 89.5, 'APROBADO'),
(11, 91.5, 88.0, 90.0, 89.8, 'APROBADO'),

-- Carlos Andrés - estudiante promedio
(15, 76.0, 78.5, 82.0, 78.8, 'APROBADO'),
(16, 83.5, 80.0, 85.5, 83.0, 'APROBADO'),
(17, 79.0, 81.5, 84.0, 81.5, 'APROBADO'),
(18, 85.0, 82.5, 87.5, 85.0, 'APROBADO');

-- Registramos algunos pagos
INSERT INTO pago (concepto_pago_id, estudiante_id, usuario_id, monto, fecha_pago, metodo_pago, numero_recibo) VALUES
-- Matrículas del año
(1, 1, 3, 500000.00, '2024-01-15', 'TRANSFERENCIA', 'REC-2024-001'),
(1, 2, 3, 500000.00, '2024-01-16', 'EFECTIVO', 'REC-2024-002'),
(1, 3, 3, 500000.00, '2024-01-17', 'TARJETA', 'REC-2024-003'),
(1, 4, 3, 500000.00, '2024-01-18', 'TRANSFERENCIA', 'REC-2024-004'),
(1, 5, 3, 500000.00, '2024-01-19', 'EFECTIVO', 'REC-2024-005'),
(1, 6, 3, 500000.00, '2024-01-20', 'TRANSFERENCIA', 'REC-2024-006'),
(1, 7, 3, 500000.00, '2024-01-21', 'TARJETA', 'REC-2024-007'),
(1, 8, 3, 500000.00, '2024-01-22', 'EFECTIVO', 'REC-2024-008'),
(1, 9, 3, 500000.00, '2024-01-23', 'TRANSFERENCIA', 'REC-2024-009'),
(1, 10, 3, 500000.00, '2024-01-24', 'TARJETA', 'REC-2024-010'),

-- Algunas mensualidades
(2, 1, 3, 200000.00, '2024-02-05', 'EFECTIVO', 'REC-2024-011'),
(2, 2, 3, 200000.00, '2024-02-06', 'TRANSFERENCIA', 'REC-2024-012'),
(2, 3, 3, 200000.00, '2024-02-07', 'TARJETA', 'REC-2024-013'),
(2, 4, 3, 200000.00, '2024-02-08', 'EFECTIVO', 'REC-2024-014'),
(2, 5, 3, 200000.00, '2024-02-09', 'TRANSFERENCIA', 'REC-2024-015'),

-- Más mensualidades
(2, 1, 3, 200000.00, '2024-03-05', 'TRANSFERENCIA', 'REC-2024-016'),
(2, 2, 3, 200000.00, '2024-03-06', 'EFECTIVO', 'REC-2024-017'),
(2, 6, 3, 200000.00, '2024-03-07', 'TARJETA', 'REC-2024-018'),
(2, 7, 3, 200000.00, '2024-03-08', 'TRANSFERENCIA', 'REC-2024-019'),
(2, 8, 3, 200000.00, '2024-03-09', 'EFECTIVO', 'REC-2024-020'),

-- Material didáctico
(6, 1, 3, 150000.00, '2024-01-30', 'EFECTIVO', 'REC-2024-021'),
(6, 2, 3, 150000.00, '2024-01-31', 'TRANSFERENCIA', 'REC-2024-022'),
(6, 6, 3, 150000.00, '2024-02-01', 'TARJETA', 'REC-2024-023'),
(6, 7, 3, 150000.00, '2024-02-02', 'EFECTIVO', 'REC-2024-024'),

-- Seguros estudiantiles
(5, 1, 3, 75000.00, '2024-02-15', 'TRANSFERENCIA', 'REC-2024-025'),
(5, 2, 3, 75000.00, '2024-02-16', 'EFECTIVO', 'REC-2024-026'),
(5, 3, 3, 75000.00, '2024-02-17', 'TARJETA', 'REC-2024-027'),
(5, 6, 3, 75000.00, '2024-02-18', 'TRANSFERENCIA', 'REC-2024-028'),
(5, 7, 3, 75000.00, '2024-02-19', 'EFECTIVO', 'REC-2024-029');

-- Verificamos que todo se haya insertado bien
SELECT 'Grados' as Tabla, COUNT(*) as Total FROM grado
UNION ALL
SELECT 'Profesores', COUNT(*) FROM profesor
UNION ALL
SELECT 'Estudiantes', COUNT(*) FROM estudiante
UNION ALL
SELECT 'Cursos', COUNT(*) FROM curso
UNION ALL
SELECT 'Asignaciones', COUNT(*) FROM asignacion_curso
UNION ALL
SELECT 'Calificaciones', COUNT(*) FROM calificacion
UNION ALL
SELECT 'Conceptos Pago', COUNT(*) FROM concepto_pago
UNION ALL
SELECT 'Pagos', COUNT(*) FROM pago
UNION ALL
SELECT 'Usuarios', COUNT(*) FROM usuario
UNION ALL
SELECT 'Roles', COUNT(*) FROM rol
UNION ALL
SELECT 'Permisos', COUNT(*) FROM permiso;

PRINT 'Listo! Todos los datos de prueba están cargados';
GO