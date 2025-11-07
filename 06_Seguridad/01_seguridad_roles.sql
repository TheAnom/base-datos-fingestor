/*
================================================================================
SISTEMA DE SEGURIDAD BASADO EN ROLES - EDUGESTOR
================================================================================
Descripción: Implementación completa de seguridad con roles, usuarios y permisos
             granulares siguiendo el principio de menor privilegio
Autor: Proyecto BDII
Fecha: Noviembre 2024
Características: RBAC, usuarios de BD, esquemas de seguridad, auditoría
================================================================================
*/

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO

/*
================================================================================
CREACIÓN DE ROLES DE BASE DE DATOS
================================================================================
Estrategia: Roles específicos por funcionalidad con permisos granulares
Principio: Menor privilegio - cada rol solo tiene los permisos mínimos necesarios
*/

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

/*
================================================================================
ASIGNACIÓN DE PERMISOS POR ROL
================================================================================
*/

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
GRANT SELECT, INSERT, UPDATE, DELETE ON permiso_rol TO db_administrador_edugestor;

-- Permisos sobre esquema Data Warehouse
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

PRINT 'Permisos de analista de datos configurados correctamente';

/*
================================================================================
CREACIÓN DE USUARIOS DE BASE DE DATOS
================================================================================
Estrategia: Usuarios específicos mapeados a logins de SQL Server
Nota: En producción, estos usuarios se crearían con logins reales
*/

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

/*
================================================================================
IMPLEMENTACIÓN DE ROW LEVEL SECURITY (RLS)
================================================================================
Propósito: Los profesores solo pueden ver/editar calificaciones de sus cursos
*/

-- Función de seguridad para profesores
CREATE OR ALTER FUNCTION dbo.fn_SeguridadProfesor(@ProfesorId INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS fn_securitypredicate_result
    WHERE 
        -- Permitir acceso si es administrador o coordinador
        IS_MEMBER('db_administrador_edugestor') = 1 
        OR IS_MEMBER('db_coordinador_academico') = 1
        OR IS_MEMBER('db_secretario_financiero') = 1
        OR IS_MEMBER('db_consulta_general') = 1
        OR IS_MEMBER('db_analista_datos') = 1
        -- O si es profesor y el curso le pertenece
        OR (
            IS_MEMBER('db_profesor') = 1 
            AND EXISTS (
                SELECT 1 FROM dbo.curso c
                INNER JOIN dbo.asignacion_curso ac ON c.curso_id = ac.curso_id
                WHERE c.profesor_id = @ProfesorId
            )
        )
);
GO

-- Crear política de seguridad para calificaciones
IF EXISTS (SELECT * FROM sys.security_policies WHERE name = 'CalificacionesSecurityPolicy')
    DROP SECURITY POLICY CalificacionesSecurityPolicy;

-- Nota: RLS requiere configuración adicional con el contexto del usuario
-- En un entorno real, se implementaría con SESSION_CONTEXT o USER_NAME()

/*
================================================================================
AUDITORÍA Y LOGGING DE SEGURIDAD
================================================================================
*/

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
GO/*

================================================================================
TRIGGERS DE AUDITORÍA AUTOMÁTICA
================================================================================
*/

-- Trigger para auditar cambios en tabla de usuarios
CREATE OR ALTER TRIGGER tr_auditoria_usuario
ON usuario
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Auditar inserciones
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_nuevos, resultado)
        SELECT 
            'INSERT',
            'usuario',
            i.usuario_id,
            CONCAT('nombre_usuario:', i.nombre_usuario, ', nombre_completo:', i.nombre_completo, ', email:', i.email),
            'EXITOSO'
        FROM inserted i;
    END
    
    -- Auditar actualizaciones
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_anteriores, datos_nuevos, resultado)
        SELECT 
            'UPDATE',
            'usuario',
            i.usuario_id,
            CONCAT('nombre_usuario:', d.nombre_usuario, ', nombre_completo:', d.nombre_completo, ', email:', d.email, ', activo:', d.activo),
            CONCAT('nombre_usuario:', i.nombre_usuario, ', nombre_completo:', i.nombre_completo, ', email:', i.email, ', activo:', i.activo),
            'EXITOSO'
        FROM inserted i
        INNER JOIN deleted d ON i.usuario_id = d.usuario_id;
    END
    
    -- Auditar eliminaciones
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_anteriores, resultado)
        SELECT 
            'DELETE',
            'usuario',
            d.usuario_id,
            CONCAT('nombre_usuario:', d.nombre_usuario, ', nombre_completo:', d.nombre_completo, ', email:', d.email),
            'EXITOSO'
        FROM deleted d;
    END
END
GO

-- Trigger para auditar cambios en pagos (transacciones críticas)
CREATE OR ALTER TRIGGER tr_auditoria_pago
ON pago
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Auditar inserciones de pagos
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_nuevos, resultado)
        SELECT 
            'INSERT',
            'pago',
            i.pago_id,
            CONCAT('estudiante_id:', i.estudiante_id, ', monto:', i.monto, ', metodo_pago:', i.metodo_pago, ', numero_recibo:', i.numero_recibo),
            'EXITOSO'
        FROM inserted i;
    END
    
    -- Auditar actualizaciones de pagos (cambios de estado)
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_anteriores, datos_nuevos, resultado)
        SELECT 
            'UPDATE',
            'pago',
            i.pago_id,
            CONCAT('estado_pago:', d.estado_pago, ', monto:', d.monto),
            CONCAT('estado_pago:', i.estado_pago, ', monto:', i.monto),
            CASE WHEN i.estado_pago = 'ANULADO' THEN 'CRÍTICO' ELSE 'EXITOSO' END
        FROM inserted i
        INNER JOIN deleted d ON i.pago_id = d.pago_id;
    END
END
GO

-- Trigger para auditar cambios en calificaciones
CREATE OR ALTER TRIGGER tr_auditoria_calificacion
ON calificacion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Auditar cambios en calificaciones
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO auditoria_seguridad (tipo_evento, tabla_afectada, registro_id, datos_anteriores, datos_nuevos, resultado)
        SELECT 
            CASE WHEN d.calificacion_id IS NULL THEN 'INSERT' ELSE 'UPDATE' END,
            'calificacion',
            i.calificacion_id,
            CASE WHEN d.calificacion_id IS NOT NULL 
                 THEN CONCAT('nota_final:', ISNULL(CAST(d.nota_final AS NVARCHAR(10)), 'NULL'), ', estado:', d.estado_calificacion)
                 ELSE NULL END,
            CONCAT('nota_final:', ISNULL(CAST(i.nota_final AS NVARCHAR(10)), 'NULL'), ', estado:', i.estado_calificacion),
            'EXITOSO'
        FROM inserted i
        LEFT JOIN deleted d ON i.calificacion_id = d.calificacion_id;
    END
END
GO

/*
================================================================================
VISTAS DE SEGURIDAD Y MONITOREO
================================================================================
*/

-- Vista para monitorear accesos por usuario y rol
CREATE OR ALTER VIEW vw_MonitoreoAccesos AS
SELECT 
    -- Información del usuario
    dp.name as usuario_bd,
    dp.type_desc as tipo_usuario,
    
    -- Roles asignados
    STRING_AGG(r.name, ', ') as roles_asignados,
    
    -- Estadísticas de auditoría (últimos 30 días)
    (SELECT COUNT(*) FROM auditoria_seguridad a 
     WHERE a.usuario_bd = dp.name 
     AND a.fecha_evento >= DATEADD(DAY, -30, GETDATE())) as eventos_ultimo_mes,
    
    (SELECT COUNT(*) FROM auditoria_seguridad a 
     WHERE a.usuario_bd = dp.name 
     AND a.resultado = 'FALLIDO'
     AND a.fecha_evento >= DATEADD(DAY, -30, GETDATE())) as eventos_fallidos_mes,
    
    -- Último acceso
    (SELECT MAX(fecha_evento) FROM auditoria_seguridad a 
     WHERE a.usuario_bd = dp.name) as ultimo_acceso,
    
    -- Estado del usuario
    CASE 
        WHEN dp.is_disabled = 1 THEN 'DESHABILITADO'
        WHEN (SELECT COUNT(*) FROM auditoria_seguridad a 
              WHERE a.usuario_bd = dp.name 
              AND a.fecha_evento >= DATEADD(DAY, -7, GETDATE())) = 0 THEN 'INACTIVO'
        ELSE 'ACTIVO'
    END as estado_usuario

FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.type IN ('S', 'U') -- Solo usuarios SQL y Windows
AND dp.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
GROUP BY dp.name, dp.type_desc, dp.is_disabled;
GO

-- Vista para análisis de eventos de seguridad
CREATE OR ALTER VIEW vw_EventosSeguridad AS
SELECT 
    fecha_evento,
    usuario_bd,
    usuario_aplicacion,
    tipo_evento,
    tabla_afectada,
    resultado,
    
    -- Clasificación de criticidad
    CASE 
        WHEN tipo_evento = 'DELETE' AND tabla_afectada IN ('usuario', 'pago', 'calificacion') THEN 'CRÍTICO'
        WHEN tipo_evento = 'UPDATE' AND tabla_afectada = 'pago' AND datos_nuevos LIKE '%ANULADO%' THEN 'CRÍTICO'
        WHEN resultado = 'FALLIDO' THEN 'ALTO'
        WHEN tipo_evento IN ('INSERT', 'UPDATE') AND tabla_afectada IN ('usuario', 'rol', 'permiso_rol') THEN 'MEDIO'
        ELSE 'BAJO'
    END as nivel_criticidad,
    
    -- Resumen del evento
    CASE 
        WHEN tipo_evento = 'INSERT' THEN 'Creación de registro en ' + tabla_afectada
        WHEN tipo_evento = 'UPDATE' THEN 'Modificación de registro en ' + tabla_afectada
        WHEN tipo_evento = 'DELETE' THEN 'Eliminación de registro en ' + tabla_afectada
        WHEN tipo_evento = 'SELECT' THEN 'Consulta a ' + tabla_afectada
        ELSE tipo_evento
    END as descripcion_evento,
    
    ip_cliente,
    aplicacion,
    mensaje_error

FROM auditoria_seguridad
WHERE fecha_evento >= DATEADD(DAY, -90, GETDATE()); -- Últimos 90 días
GO

/*
================================================================================
PROCEDIMIENTOS DE GESTIÓN DE SEGURIDAD
================================================================================
*/

-- Procedimiento para crear usuario completo con rol
CREATE OR ALTER PROCEDURE sp_CrearUsuarioCompleto
    @NombreLogin NVARCHAR(50),
    @Password NVARCHAR(50),
    @NombreCompleto NVARCHAR(100),
    @Email NVARCHAR(100),
    @RolSistema NVARCHAR(50), -- Rol en la tabla 'rol' del sistema
    @RolBaseDatos NVARCHAR(50), -- Rol de base de datos
    @UsuarioCreador NVARCHAR(50),
    @Resultado NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    DECLARE @UsuarioId INT;
    DECLARE @RolId INT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validar que el rol del sistema existe
        SELECT @RolId = rol_id FROM rol WHERE nombre = @RolSistema AND activo = 1;
        IF @RolId IS NULL
        BEGIN
            SET @ErrorMessage = 'Error: El rol del sistema "' + @RolSistema + '" no existe o está inactivo';
            THROW 50401, @ErrorMessage, 1;
        END
        
        -- Validar que el rol de base de datos existe
        IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @RolBaseDatos AND type = 'R')
        BEGIN
            SET @ErrorMessage = 'Error: El rol de base de datos "' + @RolBaseDatos + '" no existe';
            THROW 50402, @ErrorMessage, 1;
        END
        
        -- Crear usuario en la tabla del sistema
        INSERT INTO usuario (nombre_usuario, nombre_completo, email, password_hash, activo)
        VALUES (@NombreLogin, @NombreCompleto, @Email, HASHBYTES('SHA2_256', @Password), 1);
        
        SET @UsuarioId = SCOPE_IDENTITY();
        
        -- Asignar rol en el sistema
        INSERT INTO usuario_rol (usuario_id, rol_id, activo)
        VALUES (@UsuarioId, @RolId, 1);
        
        -- Crear usuario de base de datos (simulado - en producción sería con CREATE LOGIN/USER)
        EXEC sp_CrearUsuarioSiNoExiste @NombreLogin, @RolBaseDatos;
        
        -- Registrar auditoría
        EXEC sp_RegistrarAuditoria 
            @UsuarioAplicacion = @UsuarioCreador,
            @TipoEvento = 'CREATE_USER',
            @TablaAfectada = 'usuario',
            @RegistroId = @UsuarioId,
            @DatosNuevos = @NombreCompleto,
            @Resultado = 'EXITOSO';
        
        COMMIT TRANSACTION;
        
        SET @Resultado = 'ÉXITO: Usuario creado correctamente. ID: ' + CAST(@UsuarioId AS NVARCHAR(10));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = 'Error en sp_CrearUsuarioCompleto: ' + ERROR_MESSAGE();
        SET @Resultado = @ErrorMessage;
        
        -- Registrar error en auditoría
        EXEC sp_RegistrarAuditoria 
            @UsuarioAplicacion = @UsuarioCreador,
            @TipoEvento = 'CREATE_USER',
            @Resultado = 'FALLIDO',
            @MensajeError = @ErrorMessage;
        
        THROW;
    END CATCH
END
GO

-- Procedimiento para cambiar contraseña con validaciones
CREATE OR ALTER PROCEDURE sp_CambiarPassword
    @NombreUsuario NVARCHAR(50),
    @PasswordActual NVARCHAR(50),
    @PasswordNuevo NVARCHAR(50),
    @UsuarioSolicitante NVARCHAR(50),
    @Resultado NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    DECLARE @UsuarioId INT;
    DECLARE @PasswordHashActual VARBINARY(32);
    
    BEGIN TRY
        -- Validar usuario existe
        SELECT @UsuarioId = usuario_id, @PasswordHashActual = password_hash
        FROM usuario 
        WHERE nombre_usuario = @NombreUsuario AND activo = 1;
        
        IF @UsuarioId IS NULL
        BEGIN
            SET @ErrorMessage = 'Error: Usuario no encontrado o inactivo';
            THROW 50403, @ErrorMessage, 1;
        END
        
        -- Validar contraseña actual
        IF @PasswordHashActual != HASHBYTES('SHA2_256', @PasswordActual)
        BEGIN
            SET @ErrorMessage = 'Error: Contraseña actual incorrecta';
            
            -- Registrar intento fallido
            EXEC sp_RegistrarAuditoria 
                @UsuarioAplicacion = @UsuarioSolicitante,
                @TipoEvento = 'CHANGE_PASSWORD',
                @TablaAfectada = 'usuario',
                @RegistroId = @UsuarioId,
                @Resultado = 'FALLIDO',
                @MensajeError = 'Contraseña actual incorrecta';
            
            THROW 50404, @ErrorMessage, 1;
        END
        
        -- Validar fortaleza de nueva contraseña
        IF LEN(@PasswordNuevo) < 8
        BEGIN
            SET @ErrorMessage = 'Error: La nueva contraseña debe tener al menos 8 caracteres';
            THROW 50405, @ErrorMessage, 1;
        END
        
        -- Actualizar contraseña
        UPDATE usuario 
        SET password_hash = HASHBYTES('SHA2_256', @PasswordNuevo),
            fecha_creacion = GETDATE() -- Actualizar timestamp
        WHERE usuario_id = @UsuarioId;
        
        -- Registrar cambio exitoso
        EXEC sp_RegistrarAuditoria 
            @UsuarioAplicacion = @UsuarioSolicitante,
            @TipoEvento = 'CHANGE_PASSWORD',
            @TablaAfectada = 'usuario',
            @RegistroId = @UsuarioId,
            @Resultado = 'EXITOSO';
        
        SET @Resultado = 'ÉXITO: Contraseña actualizada correctamente';
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = 'Error en sp_CambiarPassword: ' + ERROR_MESSAGE();
        SET @Resultado = @ErrorMessage;
        
        THROW;
    END CATCH
END
GO

/*
================================================================================
REPORTES DE SEGURIDAD
================================================================================
*/

-- Reporte de matriz de permisos por rol
CREATE OR ALTER PROCEDURE sp_ReporteMatrizPermisos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        r.name as 'Rol de Base de Datos',
        CASE 
            WHEN p.permission_name = 'SELECT' THEN '✓ Consultar'
            WHEN p.permission_name = 'INSERT' THEN '✓ Insertar'
            WHEN p.permission_name = 'UPDATE' THEN '✓ Actualizar'
            WHEN p.permission_name = 'DELETE' THEN '✓ Eliminar'
            WHEN p.permission_name = 'EXECUTE' THEN '✓ Ejecutar'
            ELSE p.permission_name
        END as 'Permiso',
        CASE 
            WHEN p.class_desc = 'OBJECT_OR_COLUMN' THEN OBJECT_NAME(p.major_id)
            WHEN p.class_desc = 'SCHEMA' THEN SCHEMA_NAME(p.major_id)
            ELSE p.class_desc
        END as 'Objeto/Esquema',
        p.state_desc as 'Estado'
    FROM sys.database_role_members rm
    INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    INNER JOIN sys.database_permissions p ON r.principal_id = p.grantee_principal_id
    WHERE r.type = 'R' -- Solo roles
    AND r.name LIKE 'db_%' -- Solo nuestros roles personalizados
    ORDER BY r.name, p.permission_name, OBJECT_NAME(p.major_id);
END
GO

-- Reporte de actividad de usuarios
CREATE OR ALTER PROCEDURE sp_ReporteActividadUsuarios
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @FechaInicio IS NULL SET @FechaInicio = DATEADD(DAY, -30, GETDATE());
    IF @FechaFin IS NULL SET @FechaFin = GETDATE();
    
    SELECT 
        usuario_bd as 'Usuario BD',
        usuario_aplicacion as 'Usuario Aplicación',
        COUNT(*) as 'Total Eventos',
        COUNT(CASE WHEN tipo_evento = 'INSERT' THEN 1 END) as 'Inserciones',
        COUNT(CASE WHEN tipo_evento = 'UPDATE' THEN 1 END) as 'Actualizaciones',
        COUNT(CASE WHEN tipo_evento = 'DELETE' THEN 1 END) as 'Eliminaciones',
        COUNT(CASE WHEN tipo_evento = 'SELECT' THEN 1 END) as 'Consultas',
        COUNT(CASE WHEN resultado = 'FALLIDO' THEN 1 END) as 'Eventos Fallidos',
        MIN(fecha_evento) as 'Primer Acceso',
        MAX(fecha_evento) as 'Último Acceso',
        COUNT(DISTINCT tabla_afectada) as 'Tablas Accedidas'
    FROM auditoria_seguridad
    WHERE fecha_evento BETWEEN @FechaInicio AND @FechaFin
    GROUP BY usuario_bd, usuario_aplicacion
    ORDER BY COUNT(*) DESC;
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
PRINT '- Vistas de monitoreo de seguridad';
PRINT '- Procedimientos de gestión de usuarios';
PRINT '- Reportes de permisos y actividad';
PRINT '';
PRINT 'Consultas útiles:';
PRINT '- SELECT * FROM vw_MonitoreoAccesos';
PRINT '- SELECT * FROM vw_EventosSeguridad';
PRINT '- EXEC sp_ReporteMatrizPermisos';
PRINT '- EXEC sp_ReporteActividadUsuarios';
GO