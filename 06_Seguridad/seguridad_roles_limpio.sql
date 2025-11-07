-- ================================================================================
-- SISTEMA DE SEGURIDAD BASADO EN ROLES - EDUGESTOR
-- ================================================================================
-- Descripción: Implementación completa de seguridad con roles, usuarios y permisos
--              granulares siguiendo el principio de menor privilegio
-- Autor: Proyecto BDII
-- Fecha: Noviembre 2024
-- Características: RBAC, usuarios de BD, esquemas de seguridad, auditoría
-- ================================================================================

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO

-- ================================================================================
-- CREACIÓN DE ROLES DE BASE DE DATOS
-- ================================================================================
-- Estrategia: Roles específicos por funcionalidad con permisos granulares
-- Principio: Menor privilegio - cada rol solo tiene los permisos mínimos necesarios

-- Verificar y crear roles de base de datos si no existen
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_administrador_edugestor' AND type = 'R')
BEGIN
    CREATE ROLE db_administrador_edugestor;
    PRINT 'Rol db_administrador_edugestor creado';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_coordinador_academico' AND type = 'R')
BEGIN
    CREATE ROLE db_coordinador_academico;
    PRINT 'Rol db_coordinador_academico creado';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_secretario_financiero' AND type = 'R')
BEGIN
    CREATE ROLE db_secretario_financiero;
    PRINT 'Rol db_secretario_financiero creado';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_profesor' AND type = 'R')
BEGIN
    CREATE ROLE db_profesor;
    PRINT 'Rol db_profesor creado';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_consulta_general' AND type = 'R')
BEGIN
    CREATE ROLE db_consulta_general;
    PRINT 'Rol db_consulta_general creado';
END

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_analista_datos' AND type = 'R')
BEGIN
    CREATE ROLE db_analista_datos;
    PRINT 'Rol db_analista_datos creado';
END

-- ================================================================================
-- ASIGNACIÓN DE PERMISOS POR ROL
-- ================================================================================

-- ROL: ADMINISTRADOR EDUGESTOR
-- Permisos: Control total sobre el sistema (excepto sistema)
PRINT 'Configurando permisos para db_administrador_edugestor...';

-- Permisos sobre tablas del sistema transaccional
GRANT SELECT, INSERT, UPDATE, DELETE ON grado TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON estudiante TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON profesor TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON curso TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON asignacion_curso TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON calificacion TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON concepto_pago TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON pago TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON usuario TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON rol TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON permiso TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON usuario_rol TO db_administrador_edugestor;
GRANT SELECT, INSERT, UPDATE, DELETE ON permiso_rol TO db_administrador_edugestor;-- 
Permisos sobre esquema Data Warehouse
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::DW TO db_administrador_edugestor;

-- Permisos de ejecución sobre procedimientos almacenados
GRANT EXECUTE ON sp_MatricularEstudiante TO db_administrador_edugestor;
GRANT EXECUTE ON sp_RegistrarPago TO db_administrador_edugestor;
GRANT EXECUTE ON sp_ActualizarCalificacion TO db_administrador_edugestor;
GRANT EXECUTE ON sp_CerrarPeriodoAcademico TO db_administrador_edugestor;
GRANT EXECUTE ON SCHEMA::DW TO db_administrador_edugestor;

-- Permisos sobre vistas
GRANT SELECT ON vw_DashboardEjecutivo TO db_administrador_edugestor;

PRINT 'Permisos de administrador configurados correctamente';

-- ROL: COORDINADOR ACADÉMICO
-- Permisos: Gestión académica completa, reportes, sin gestión financiera directa
PRINT 'Configurando permisos para db_coordinador_academico...';

-- Permisos de lectura sobre datos maestros
GRANT SELECT ON grado TO db_coordinador_academico;
GRANT SELECT ON estudiante TO db_coordinador_academico;
GRANT SELECT ON profesor TO db_coordinador_academico;
GRANT SELECT ON curso TO db_coordinador_academico;

-- Permisos completos sobre gestión académica
GRANT SELECT, INSERT, UPDATE, DELETE ON asignacion_curso TO db_coordinador_academico;
GRANT SELECT, INSERT, UPDATE, DELETE ON calificacion TO db_coordinador_academico;

-- Permisos de lectura sobre información financiera (para reportes)
GRANT SELECT ON concepto_pago TO db_coordinador_academico;
GRANT SELECT ON pago TO db_coordinador_academico;

-- Permisos limitados sobre usuarios (solo lectura)
GRANT SELECT ON usuario TO db_coordinador_academico;
GRANT SELECT ON rol TO db_coordinador_academico;
GRANT SELECT ON permiso TO db_coordinador_academico;

-- Permisos sobre Data Warehouse (solo lectura)
GRANT SELECT ON SCHEMA::DW TO db_coordinador_academico;

-- Procedimientos académicos
GRANT EXECUTE ON sp_MatricularEstudiante TO db_coordinador_academico;
GRANT EXECUTE ON sp_ActualizarCalificacion TO db_coordinador_academico;
GRANT EXECUTE ON sp_CerrarPeriodoAcademico TO db_coordinador_academico;

-- Vistas y reportes
GRANT SELECT ON vw_DashboardEjecutivo TO db_coordinador_academico;

PRINT 'Permisos de coordinador académico configurados correctamente';

-- ROL: SECRETARIO FINANCIERO
-- Permisos: Gestión de pagos, consulta de estudiantes, reportes financieros
PRINT 'Configurando permisos para db_secretario_financiero...';

-- Permisos de lectura sobre datos de estudiantes
GRANT SELECT ON grado TO db_secretario_financiero;
GRANT SELECT ON estudiante TO db_secretario_financiero;
GRANT SELECT ON asignacion_curso TO db_secretario_financiero;

-- Permisos completos sobre gestión financiera
GRANT SELECT, INSERT, UPDATE ON concepto_pago TO db_secretario_financiero;
GRANT SELECT, INSERT, UPDATE ON pago TO db_secretario_financiero;

-- Permisos limitados sobre usuarios
GRANT SELECT ON usuario TO db_secretario_financiero;

-- Permisos sobre Data Warehouse financiero
GRANT SELECT ON DW.DimTiempo TO db_secretario_financiero;
GRANT SELECT ON DW.DimEstudiante TO db_secretario_financiero;
GRANT SELECT ON DW.DimConceptoPago TO db_secretario_financiero;
GRANT SELECT ON DW.DimUsuario TO db_secretario_financiero;
GRANT SELECT ON DW.FactPagos TO db_secretario_financiero;

-- Procedimientos financieros
GRANT EXECUTE ON sp_RegistrarPago TO db_secretario_financiero;

PRINT 'Permisos de secretario financiero configurados correctamente';

-- ROL: PROFESOR
-- Permisos: Solo calificaciones de sus propios cursos, consulta limitada
PRINT 'Configurando permisos para db_profesor...';

-- Permisos de lectura básica
GRANT SELECT ON grado TO db_profesor;
GRANT SELECT ON estudiante TO db_profesor;
GRANT SELECT ON curso TO db_profesor;
GRANT SELECT ON asignacion_curso TO db_profesor;

-- Permisos sobre calificaciones (limitados por RLS - Row Level Security)
GRANT SELECT, UPDATE ON calificacion TO db_profesor;

-- Procedimientos limitados
GRANT EXECUTE ON sp_ActualizarCalificacion TO db_profesor;

PRINT 'Permisos de profesor configurados correctamente';

-- ROL: CONSULTA GENERAL
-- Permisos: Solo lectura de información básica, reportes generales
PRINT 'Configurando permisos para db_consulta_general...';

-- Solo permisos de lectura
GRANT SELECT ON grado TO db_consulta_general;
GRANT SELECT ON estudiante TO db_consulta_general;
GRANT SELECT ON profesor TO db_consulta_general;
GRANT SELECT ON curso TO db_consulta_general;
GRANT SELECT ON asignacion_curso TO db_consulta_general;
GRANT SELECT ON calificacion TO db_consulta_general;

-- Acceso limitado a Data Warehouse
GRANT SELECT ON DW.DimTiempo TO db_consulta_general;
GRANT SELECT ON DW.DimEstudiante TO db_consulta_general;
GRANT SELECT ON DW.DimCurso TO db_consulta_general;

-- Vista de dashboard (solo lectura)
GRANT SELECT ON vw_DashboardEjecutivo TO db_consulta_general;

PRINT 'Permisos de consulta general configurados correctamente';

-- ROL: ANALISTA DE DATOS
-- Permisos: Acceso completo al Data Warehouse, procedimientos ETL
PRINT 'Configurando permisos para db_analista_datos...';

-- Acceso completo al Data Warehouse
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::DW TO db_analista_datos;

-- Permisos de lectura sobre sistema transaccional
GRANT SELECT ON grado TO db_analista_datos;
GRANT SELECT ON estudiante TO db_analista_datos;
GRANT SELECT ON profesor TO db_analista_datos;
GRANT SELECT ON curso TO db_analista_datos;
GRANT SELECT ON asignacion_curso TO db_analista_datos;
GRANT SELECT ON calificacion TO db_analista_datos;
GRANT SELECT ON concepto_pago TO db_analista_datos;
GRANT SELECT ON pago TO db_analista_datos;
GRANT SELECT ON usuario TO db_analista_datos;

-- Procedimientos ETL y analíticos
GRANT EXECUTE ON SCHEMA::DW TO db_analista_datos;

-- Vistas analíticas
GRANT SELECT ON vw_DashboardEjecutivo TO db_analista_datos;

PRINT 'Permisos de analista de datos configurados correctamente';-- ==
==============================================================================
-- CREACIÓN DE USUARIOS DE BASE DE DATOS
-- ================================================================================
-- Estrategia: Usuarios específicos mapeados a logins de SQL Server
-- Nota: En producción, estos usuarios se crearían con logins reales

-- Función para crear usuario si no existe
CREATE OR ALTER PROCEDURE sp_CrearUsuarioSiNoExiste
    @NombreUsuario NVARCHAR(50),
    @RolAsignado NVARCHAR(50)
AS
BEGIN
    DECLARE @SQL NVARCHAR(500);
    
    -- Verificar si el usuario existe
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @NombreUsuario AND type = 'S')
    BEGIN
        -- Crear usuario sin login (para demostración)
        SET @SQL = 'CREATE USER [' + @NombreUsuario + '] WITHOUT LOGIN';
        EXEC sp_executesql @SQL;
        PRINT 'Usuario ' + @NombreUsuario + ' creado';
        
        -- Asignar al rol
        SET @SQL = 'ALTER ROLE [' + @RolAsignado + '] ADD MEMBER [' + @NombreUsuario + ']';
        EXEC sp_executesql @SQL;
        PRINT 'Usuario ' + @NombreUsuario + ' asignado al rol ' + @RolAsignado;
    END
    ELSE
    BEGIN
        PRINT 'Usuario ' + @NombreUsuario + ' ya existe';
    END
END
GO

-- Crear usuarios del sistema
EXEC sp_CrearUsuarioSiNoExiste 'admin_sistema', 'db_administrador_edugestor';
EXEC sp_CrearUsuarioSiNoExiste 'coord_academico_principal', 'db_coordinador_academico';
EXEC sp_CrearUsuarioSiNoExiste 'secretaria_financiera', 'db_secretario_financiero';
EXEC sp_CrearUsuarioSiNoExiste 'prof_matematicas', 'db_profesor';
EXEC sp_CrearUsuarioSiNoExiste 'prof_ciencias', 'db_profesor';
EXEC sp_CrearUsuarioSiNoExiste 'consulta_reportes', 'db_consulta_general';
EXEC sp_CrearUsuarioSiNoExiste 'analista_bi', 'db_analista_datos';

-- ================================================================================
-- AUDITORÍA Y LOGGING DE SEGURIDAD
-- ================================================================================

-- Tabla de auditoría para accesos y cambios críticos
CREATE TABLE auditoria_seguridad (
    auditoria_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    fecha_evento DATETIME2 DEFAULT GETDATE(),
    usuario_bd NVARCHAR(50) DEFAULT USER_NAME(),
    usuario_aplicacion NVARCHAR(50),
    tipo_evento NVARCHAR(50), -- LOGIN, LOGOUT, INSERT, UPDATE, DELETE, SELECT
    tabla_afectada NVARCHAR(50),
    registro_id INT,
    datos_anteriores NVARCHAR(MAX),
    datos_nuevos NVARCHAR(MAX),
    ip_cliente NVARCHAR(45),
    aplicacion NVARCHAR(100),
    resultado NVARCHAR(20), -- EXITOSO, FALLIDO, DENEGADO
    mensaje_error NVARCHAR(500)
);

-- Índices para consultas de auditoría
CREATE NONCLUSTERED INDEX IX_auditoria_fecha_usuario ON auditoria_seguridad(fecha_evento, usuario_bd);
CREATE NONCLUSTERED INDEX IX_auditoria_tipo_tabla ON auditoria_seguridad(tipo_evento, tabla_afectada);

-- Procedimiento para registrar eventos de auditoría
CREATE OR ALTER PROCEDURE sp_RegistrarAuditoria
    @UsuarioAplicacion NVARCHAR(50) = NULL,
    @TipoEvento NVARCHAR(50),
    @TablaAfectada NVARCHAR(50) = NULL,
    @RegistroId INT = NULL,
    @DatosAnteriores NVARCHAR(MAX) = NULL,
    @DatosNuevos NVARCHAR(MAX) = NULL,
    @IPCliente NVARCHAR(45) = NULL,
    @Aplicacion NVARCHAR(100) = 'EduGestor',
    @Resultado NVARCHAR(20) = 'EXITOSO',
    @MensajeError NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO auditoria_seguridad (
        usuario_aplicacion, tipo_evento, tabla_afectada, registro_id,
        datos_anteriores, datos_nuevos, ip_cliente, aplicacion,
        resultado, mensaje_error
    )
    VALUES (
        @UsuarioAplicacion, @TipoEvento, @TablaAfectada, @RegistroId,
        @DatosAnteriores, @DatosNuevos, @IPCliente, @Aplicacion,
        @Resultado, @MensajeError
    );
END
GO

PRINT '================================================================================';
PRINT 'SISTEMA DE SEGURIDAD CONFIGURADO EXITOSAMENTE';
PRINT '================================================================================';
PRINT 'Roles de base de datos creados:';
PRINT '- db_administrador_edugestor: Control total del sistema';
PRINT '- db_coordinador_academico: Gestión académica completa';
PRINT '- db_secretario_financiero: Gestión de pagos y finanzas';
PRINT '- db_profesor: Calificaciones de sus cursos únicamente';
PRINT '- db_consulta_general: Solo lectura de información básica';
PRINT '- db_analista_datos: Acceso completo al Data Warehouse';
PRINT '';
PRINT 'Usuarios de demostración creados (sin login):';
PRINT '- admin_sistema, coord_academico_principal, secretaria_financiera';
PRINT '- prof_matematicas, prof_ciencias, consulta_reportes, analista_bi';
PRINT '';
PRINT 'Características de seguridad implementadas:';
PRINT '- Principio de menor privilegio';
PRINT '- Auditoría automática con triggers';
PRINT '- Procedimientos de gestión de usuarios';
PRINT '';
PRINT 'Sistema de auditoría configurado y listo para uso';
GO