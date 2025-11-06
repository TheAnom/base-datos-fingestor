/*
================================================================================
MODELO ENTIDAD-RELACIÓN - SISTEMA EDUGESTOR
================================================================================
Descripción: Modelo relacional normalizado para operaciones transaccionales
Autor: Proyecto BDII
Fecha: Noviembre 2024
Base de Datos: SQL Server
================================================================================
*/

-- Configuración inicial de la base de datos
USE master;
GO

-- Crear base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EduGestor_BDII')
BEGIN
    CREATE DATABASE EduGestor_BDII;
    PRINT 'Base de datos EduGestor_BDII creada exitosamente';
END
ELSE
BEGIN
    PRINT 'La base de datos EduGestor_BDII ya existe';
END
GO

USE EduGestor_BDII;
GO

/*
================================================================================
MÓDULO 1: GESTIÓN ACADÉMICA
================================================================================
*/

-- Tabla: grado
-- Propósito: Almacenar los diferentes grados académicos (1°, 2°, 3°, etc.)
-- Justificación: Entidad independiente para normalizar y evitar redundancia
CREATE TABLE grado (
    grado_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(200),
    nivel_educativo NVARCHAR(50), -- Primaria, Secundaria, Bachillerato
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    activo BIT DEFAULT 1
);

-- Tabla: estudiante  
-- Propósito: Información personal y académica de estudiantes
-- Relación: N:1 con grado (muchos estudiantes pertenecen a un grado)
CREATE TABLE estudiante (
    estudiante_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo NVARCHAR(100) NOT NULL,
    documento_identidad NVARCHAR(20) UNIQUE, -- Cédula o documento oficial
    telefono NVARCHAR(15),
    email NVARCHAR(100),
    fecha_nacimiento DATE,
    direccion NVARCHAR(200),
    grado_id INT NOT NULL,
    institucion NVARCHAR(100),
    fecha_ingreso DATE DEFAULT CAST(GETDATE() AS DATE),
    estado NVARCHAR(20) DEFAULT 'ACTIVO', -- ACTIVO, INACTIVO, GRADUADO
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_estudiante_grado FOREIGN KEY (grado_id) REFERENCES grado(grado_id),
    CONSTRAINT CHK_estudiante_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'GRADUADO')),
    CONSTRAINT CHK_estudiante_email CHECK (email LIKE '%@%.%')
);
-- Ta
bla: profesor
-- Propósito: Información de profesores y sus especialidades
-- Justificación: Entidad independiente para gestionar recursos humanos
CREATE TABLE profesor (
    profesor_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo NVARCHAR(100) NOT NULL,
    documento_identidad NVARCHAR(20) UNIQUE,
    telefono NVARCHAR(15),
    email NVARCHAR(100),
    especialidad NVARCHAR(100), -- Matemáticas, Ciencias, Literatura, etc.
    titulo_academico NVARCHAR(100),
    fecha_contratacion DATE,
    salario_base DECIMAL(10,2),
    estado NVARCHAR(20) DEFAULT 'ACTIVO', -- ACTIVO, INACTIVO, LICENCIA
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Restricciones
    CONSTRAINT CHK_profesor_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'LICENCIA')),
    CONSTRAINT CHK_profesor_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT CHK_profesor_salario CHECK (salario_base > 0)
);

-- Tabla: curso
-- Propósito: Materias o asignaturas que se imparten
-- Relación: N:1 con profesor (un profesor puede tener varios cursos)
CREATE TABLE curso (
    curso_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    codigo_curso NVARCHAR(10) UNIQUE, -- MAT101, CIE201, etc.
    descripcion NVARCHAR(500),
    creditos INT DEFAULT 1,
    horas_semanales INT DEFAULT 2,
    profesor_id INT NOT NULL,
    grado_id INT, -- Algunos cursos pueden ser específicos de un grado
    periodo_academico NVARCHAR(20), -- 2024-1, 2024-2, etc.
    estado NVARCHAR(20) DEFAULT 'ACTIVO',
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_curso_profesor FOREIGN KEY (profesor_id) REFERENCES profesor(profesor_id),
    CONSTRAINT FK_curso_grado FOREIGN KEY (grado_id) REFERENCES grado(grado_id),
    CONSTRAINT CHK_curso_creditos CHECK (creditos > 0),
    CONSTRAINT CHK_curso_horas CHECK (horas_semanales > 0),
    CONSTRAINT CHK_curso_estado CHECK (estado IN ('ACTIVO', 'INACTIVO', 'FINALIZADO'))
);

-- Tabla: asignacion_curso
-- Propósito: Relación N:M entre estudiantes y cursos (matrícula)
-- Justificación: Tabla de unión para resolver relación muchos a muchos
CREATE TABLE asignacion_curso (
    asignacion_curso_id INT IDENTITY(1,1) PRIMARY KEY,
    estudiante_id INT NOT NULL,
    curso_id INT NOT NULL,
    fecha_asignacion DATE DEFAULT CAST(GETDATE() AS DATE),
    estado_asignacion NVARCHAR(20) DEFAULT 'MATRICULADO',
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_asignacion_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante(estudiante_id),
    CONSTRAINT FK_asignacion_curso FOREIGN KEY (curso_id) REFERENCES curso(curso_id),
    CONSTRAINT CHK_asignacion_estado CHECK (estado_asignacion IN ('MATRICULADO', 'RETIRADO', 'COMPLETADO')),
    
    -- Restricción única: un estudiante no puede estar matriculado dos veces en el mismo curso
    CONSTRAINT UK_estudiante_curso UNIQUE (estudiante_id, curso_id)
);

-- Tabla: calificacion
-- Propósito: Notas y evaluaciones de estudiantes por curso
-- Relación: 1:1 con asignacion_curso (cada asignación tiene una calificación final)
CREATE TABLE calificacion (
    calificacion_id INT IDENTITY(1,1) PRIMARY KEY,
    asignacion_curso_id INT NOT NULL UNIQUE, -- Relación 1:1
    nota_parcial1 DECIMAL(5,2),
    nota_parcial2 DECIMAL(5,2),
    nota_parcial3 DECIMAL(5,2),
    nota_final DECIMAL(5,2),
    fecha_calificacion DATE DEFAULT CAST(GETDATE() AS DATE),
    observaciones NVARCHAR(500),
    estado_calificacion NVARCHAR(20) DEFAULT 'PENDIENTE',
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_calificacion_asignacion FOREIGN KEY (asignacion_curso_id) REFERENCES asignacion_curso(asignacion_curso_id),
    CONSTRAINT CHK_nota_parcial1 CHECK (nota_parcial1 >= 0 AND nota_parcial1 <= 100),
    CONSTRAINT CHK_nota_parcial2 CHECK (nota_parcial2 >= 0 AND nota_parcial2 <= 100),
    CONSTRAINT CHK_nota_parcial3 CHECK (nota_parcial3 >= 0 AND nota_parcial3 <= 100),
    CONSTRAINT CHK_nota_final CHECK (nota_final >= 0 AND nota_final <= 100),
    CONSTRAINT CHK_calificacion_estado CHECK (estado_calificacion IN ('PENDIENTE', 'APROBADO', 'REPROBADO'))
);/*
=
===============================================================================
MÓDULO 2: GESTIÓN FINANCIERA
================================================================================
*/

-- Tabla: concepto_pago
-- Propósito: Catálogo de conceptos por los cuales se realizan pagos
-- Justificación: Normalización para evitar redundancia en descripciones
CREATE TABLE concepto_pago (
    concepto_pago_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    descripcion NVARCHAR(300),
    monto_base DECIMAL(10,2), -- Monto sugerido o base
    tipo_concepto NVARCHAR(50), -- INSCRIPCION, MENSUALIDAD, EXAMEN, CERTIFICADO
    obligatorio BIT DEFAULT 1, -- Si es obligatorio para todos los estudiantes
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Restricciones
    CONSTRAINT CHK_concepto_monto CHECK (monto_base >= 0),
    CONSTRAINT CHK_concepto_tipo CHECK (tipo_concepto IN ('INSCRIPCION', 'MENSUALIDAD', 'EXAMEN', 'CERTIFICADO', 'OTROS'))
);

/*
================================================================================
MÓDULO 3: SEGURIDAD Y AUTENTICACIÓN
================================================================================
*/

-- Tabla: rol
-- Propósito: Definir roles del sistema para control de acceso
-- Justificación: Implementar seguridad basada en roles (RBAC)
CREATE TABLE rol (
    rol_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(200),
    nivel_acceso INT DEFAULT 1, -- 1=Básico, 2=Intermedio, 3=Avanzado, 4=Administrador
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Restricciones
    CONSTRAINT CHK_rol_nivel CHECK (nivel_acceso BETWEEN 1 AND 4)
);

-- Tabla: permiso
-- Propósito: Definir permisos granulares del sistema
-- Justificación: Control detallado de operaciones permitidas
CREATE TABLE permiso (
    permiso_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(200),
    modulo NVARCHAR(50), -- ACADEMICO, FINANCIERO, SEGURIDAD, REPORTES
    operacion NVARCHAR(20), -- SELECT, INSERT, UPDATE, DELETE, EXECUTE
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Restricciones
    CONSTRAINT CHK_permiso_operacion CHECK (operacion IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'EXECUTE', 'ALL'))
);

-- Tabla: usuario
-- Propósito: Usuarios del sistema con credenciales de acceso
-- Justificación: Autenticación y trazabilidad de operaciones
CREATE TABLE usuario (
    usuario_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_usuario NVARCHAR(50) NOT NULL UNIQUE,
    nombre_completo NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) UNIQUE,
    password_hash NVARCHAR(255) NOT NULL, -- Hash de la contraseña
    ultimo_acceso DATETIME2,
    intentos_fallidos INT DEFAULT 0,
    bloqueado BIT DEFAULT 0,
    fecha_expiracion DATE,
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Restricciones
    CONSTRAINT CHK_usuario_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT CHK_usuario_intentos CHECK (intentos_fallidos >= 0)
);-- 
Tabla: pago
-- Propósito: Registro de todos los pagos realizados por estudiantes
-- Relaciones: N:1 con estudiante, concepto_pago y usuario
CREATE TABLE pago (
    pago_id INT IDENTITY(1,1) PRIMARY KEY,
    concepto_pago_id INT NOT NULL,
    estudiante_id INT NOT NULL,
    usuario_id INT NOT NULL, -- Usuario que registra el pago
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATE DEFAULT CAST(GETDATE() AS DATE),
    metodo_pago NVARCHAR(50) DEFAULT 'EFECTIVO', -- EFECTIVO, TARJETA, TRANSFERENCIA
    numero_recibo NVARCHAR(20) UNIQUE,
    observaciones NVARCHAR(300),
    estado_pago NVARCHAR(20) DEFAULT 'COMPLETADO',
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_pago_concepto FOREIGN KEY (concepto_pago_id) REFERENCES concepto_pago(concepto_pago_id),
    CONSTRAINT FK_pago_estudiante FOREIGN KEY (estudiante_id) REFERENCES estudiante(estudiante_id),
    CONSTRAINT FK_pago_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id),
    CONSTRAINT CHK_pago_monto CHECK (monto > 0),
    CONSTRAINT CHK_pago_metodo CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CHEQUE')),
    CONSTRAINT CHK_pago_estado CHECK (estado_pago IN ('COMPLETADO', 'PENDIENTE', 'ANULADO'))
);

-- Tabla: usuario_rol
-- Propósito: Asignación de roles a usuarios (relación 1:1)
-- Justificación: Un usuario tiene un rol principal, simplifica la gestión
CREATE TABLE usuario_rol (
    usuario_rol_id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL UNIQUE, -- Relación 1:1
    rol_id INT NOT NULL,
    fecha_asignacion DATE DEFAULT CAST(GETDATE() AS DATE),
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas
    CONSTRAINT FK_usuario_rol_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(usuario_id),
    CONSTRAINT FK_usuario_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(rol_id)
);

-- Tabla: permiso_rol
-- Propósito: Asignación de permisos a roles (relación N:M)
-- Justificación: Un rol puede tener múltiples permisos y un permiso puede asignarse a varios roles
CREATE TABLE permiso_rol (
    permiso_rol_id INT IDENTITY(1,1) PRIMARY KEY,
    rol_id INT NOT NULL,
    permiso_id INT NOT NULL,
    fecha_asignacion DATE DEFAULT CAST(GETDATE() AS DATE),
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas y restricciones
    CONSTRAINT FK_permiso_rol_rol FOREIGN KEY (rol_id) REFERENCES rol(rol_id),
    CONSTRAINT FK_permiso_rol_permiso FOREIGN KEY (permiso_id) REFERENCES permiso(permiso_id),
    
    -- Restricción única: un rol no puede tener el mismo permiso duplicado
    CONSTRAINT UK_rol_permiso UNIQUE (rol_id, permiso_id)
);

/*
================================================================================
ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS FRECUENTES
================================================================================
*/

-- Índices en campos de búsqueda frecuente
CREATE NONCLUSTERED INDEX IX_estudiante_documento ON estudiante(documento_identidad);
CREATE NONCLUSTERED INDEX IX_estudiante_grado ON estudiante(grado_id);
CREATE NONCLUSTERED INDEX IX_estudiante_estado ON estudiante(estado);

CREATE NONCLUSTERED INDEX IX_profesor_especialidad ON profesor(especialidad);
CREATE NONCLUSTERED INDEX IX_profesor_estado ON profesor(estado);

CREATE NONCLUSTERED INDEX IX_curso_profesor ON curso(profesor_id);
CREATE NONCLUSTERED INDEX IX_curso_grado ON curso(grado_id);
CREATE NONCLUSTERED INDEX IX_curso_periodo ON curso(periodo_academico);

CREATE NONCLUSTERED INDEX IX_pago_fecha ON pago(fecha_pago);
CREATE NONCLUSTERED INDEX IX_pago_estudiante ON pago(estudiante_id);
CREATE NONCLUSTERED INDEX IX_pago_concepto ON pago(concepto_pago_id);

CREATE NONCLUSTERED INDEX IX_usuario_nombre ON usuario(nombre_usuario);
CREATE NONCLUSTERED INDEX IX_usuario_email ON usuario(email);

PRINT 'Modelo Entidad-Relación creado exitosamente';
PRINT 'Total de tablas creadas: 13';
PRINT 'Total de índices creados: 11';
GO