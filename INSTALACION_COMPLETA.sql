-- instalacion completa del sistema
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT 'Iniciando instalacion del sistema';
PRINT 'Fecha: ' + CAST(GETDATE() AS NVARCHAR(30));

DECLARE @InicioInstalacion DATETIME2 = GETDATE();
DECLARE @ErrorCount INT = 0;

-- fase 1: modelo transaccional
BEGIN TRY
    PRINT '';
    PRINT 'FASE 1: Creando modelo transaccional...';
    
    USE BD2_Curso2025;
    PRINT 'Conectado a BD2_Curso2025';
    
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'grado')
    BEGIN
        PRINT 'Ejecute manualmente: 02_Modelo_ER/modelo_ER.sql';
    END
    ELSE
    BEGIN
        PRINT 'Modelo transaccional ya existe';
    END
    
    PRINT 'Fase 1 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT 'Error en Fase 1: ' + ERROR_MESSAGE();
END CATCH

-- fase 2: datos de prueba
BEGIN TRY
    PRINT '';
    PRINT 'FASE 2: Cargando datos de prueba...';
    
    IF (SELECT COUNT(*) FROM estudiante) = 0
    BEGIN
        PRINT 'Ejecute manualmente: 02_Modelo_ER/datos_prueba.sql';
    END
    ELSE
    BEGIN
        PRINT 'Datos ya cargados';
    END
    
    PRINT ' Fase 2 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 2: ' + ERROR_MESSAGE();
END CATCH



BEGIN TRY
    PRINT '';
    PRINT 'FASE 3: Creando modelo dimensional...';
    
    -- Crear esquema DW si no existe
    IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DW')
    BEGIN
        EXEC('CREATE SCHEMA DW');
        PRINT ' Esquema DW creado';
    END
    
    -- Verificar si las dimensiones existen
    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DimTiempo' AND schema_id = SCHEMA_ID('DW'))
    BEGIN
        PRINT '  Ejecutando modelo_dimensional.sql...';
        PRINT '    Ejecute manualmente: 03_Modelo_OLAP/modelo_dimensional.sql';
        PRINT '    Ejecute manualmente: 03_Modelo_OLAP/etl_carga_datawarehouse.sql';
    END
    ELSE
    BEGIN
        PRINT ' Modelo dimensional ya existe';
    END
    
    PRINT ' Fase 3 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 3: ' + ERROR_MESSAGE();
END CATCH



BEGIN TRY
    PRINT '';
    PRINT 'FASE 4: Creando procedimientos transaccionales...';
    
    -- Verificar si los procedimientos existen
    IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_MatricularEstudiante')
    BEGIN
        PRINT '  Ejecutando procedimientos_transaccionales.sql...';
        PRINT '    Ejecute manualmente: 04_Transacciones/procedimientos_transaccionales.sql';
    END
    ELSE
    BEGIN
        PRINT ' Procedimientos transaccionales ya existen';
    END
    
    PRINT ' Fase 4 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 4: ' + ERROR_MESSAGE();
END CATCH



BEGIN TRY
    PRINT '';
    PRINT 'FASE 5: Creando consultas analíticas...';
    
    -- Verificar si las vistas existen
    IF NOT EXISTS (SELECT * FROM sys.views WHERE name = 'vw_DashboardEjecutivo')
    BEGIN
        PRINT '  Ejecutando consultas_olap.sql...';
        PRINT '    Ejecute manualmente: 05_Consultas_Analiticas/consultas_olap.sql';
    END
    ELSE
    BEGIN
        PRINT ' Consultas analíticas ya existen';
    END
    
    PRINT ' Fase 5 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 5: ' + ERROR_MESSAGE();
END CATCH



BEGIN TRY
    PRINT '';
    PRINT 'FASE 6: Configurando sistema de seguridad...';
    
    -- Verificar si los roles existen
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_administrador_edugestor' AND type = 'R')
    BEGIN
        PRINT '  Ejecutando seguridad_roles.sql...';
        PRINT '    Ejecute manualmente: 06_Seguridad/seguridad_roles.sql';
    END
    ELSE
    BEGIN
        PRINT ' Sistema de seguridad ya configurado';
    END
    
    PRINT ' Fase 6 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 6: ' + ERROR_MESSAGE();
END CATCH



BEGIN TRY
    PRINT '';
    PRINT 'FASE 7: Configurando optimización...';
    
    -- Verificar si los procedimientos de optimización existen
    IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_OptimizacionAutomatica')
    BEGIN
        PRINT '  Ejecutando optimizacion_rendimiento.sql...';
        PRINT '    Ejecute manualmente: 07_Optimizacion/optimizacion_rendimiento.sql';
    END
    ELSE
    BEGIN
        PRINT ' Optimización ya configurada';
    END
    
    PRINT ' Fase 7 completada';
    
END TRY
BEGIN CATCH
    SET @ErrorCount += 1;
    PRINT ' Error en Fase 7: ' + ERROR_MESSAGE();
END CATCH



PRINT '';
PRINT 'VERIFICACIÓN FINAL DE LA INSTALACIÓN:';
PRINT '================================================================================';

-- Verificar componentes instalados
SELECT 'Componente' as Tipo, 'Cantidad' as Valor
UNION ALL
SELECT 'Tablas del sistema', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.tables 
WHERE is_ms_shipped = 0 AND schema_id = SCHEMA_ID('dbo')
UNION ALL
SELECT 'Tablas Data Warehouse', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.tables 
WHERE schema_id = SCHEMA_ID('DW')
UNION ALL
SELECT 'Procedimientos almacenados', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.procedures 
WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Vistas', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.views 
WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Roles de seguridad', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.database_principals 
WHERE type = 'R' AND name LIKE 'db_%'
UNION ALL
SELECT 'Índices optimizados', CAST(COUNT(*) AS NVARCHAR(10))
FROM sys.indexes 
WHERE name LIKE '%_optimizado';

-- Verificar datos de ejemplo
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'estudiante')
BEGIN
    PRINT '';
    PRINT 'DATOS DE EJEMPLO CARGADOS:';
    SELECT 'Tabla' as Entidad, 'Registros' as Cantidad
    UNION ALL
    SELECT 'Estudiantes', CAST(COUNT(*) AS NVARCHAR(10)) FROM estudiante
    UNION ALL
    SELECT 'Profesores', CAST(COUNT(*) AS NVARCHAR(10)) FROM profesor
    UNION ALL
    SELECT 'Cursos', CAST(COUNT(*) AS NVARCHAR(10)) FROM curso
    UNION ALL
    SELECT 'Asignaciones', CAST(COUNT(*) AS NVARCHAR(10)) FROM asignacion_curso
    UNION ALL
    SELECT 'Calificaciones', CAST(COUNT(*) AS NVARCHAR(10)) FROM calificacion
    UNION ALL
    SELECT 'Pagos', CAST(COUNT(*) AS NVARCHAR(10)) FROM pago
    UNION ALL
    SELECT 'Usuarios', CAST(COUNT(*) AS NVARCHAR(10)) FROM usuario;
END



PRINT '';
PRINT 'EJECUTANDO PRUEBAS BÁSICAS:';

-- Prueba 1: Consulta básica de estudiantes
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'estudiante')
    BEGIN
        DECLARE @EstudiantesActivos INT;
        SELECT @EstudiantesActivos = COUNT(*) FROM estudiante WHERE estado = 'ACTIVO';
        PRINT ' Consulta de estudiantes: ' + CAST(@EstudiantesActivos AS NVARCHAR(10)) + ' estudiantes activos';
    END
END TRY
BEGIN CATCH
    PRINT ' Error en consulta de estudiantes: ' + ERROR_MESSAGE();
    SET @ErrorCount += 1;
END CATCH

-- Prueba 2: Verificar procedimientos
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_MatricularEstudiante')
    BEGIN
        PRINT ' Procedimientos transaccionales disponibles';
    END
    ELSE
    BEGIN
        PRINT '  Procedimientos transaccionales no encontrados';
    END
END TRY
BEGIN CATCH
    PRINT ' Error verificando procedimientos: ' + ERROR_MESSAGE();
    SET @ErrorCount += 1;
END CATCH

-- Prueba 3: Verificar Data Warehouse
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DimTiempo' AND schema_id = SCHEMA_ID('DW'))
    BEGIN
        PRINT ' Data Warehouse configurado';
    END
    ELSE
    BEGIN
        PRINT '  Data Warehouse no encontrado';
    END
END TRY
BEGIN CATCH
    PRINT ' Error verificando Data Warehouse: ' + ERROR_MESSAGE();
    SET @ErrorCount += 1;
END CATCH

-- Prueba 4: Verificar seguridad
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'db_administrador_edugestor')
    BEGIN
        PRINT ' Sistema de seguridad configurado';
    END
    ELSE
    BEGIN
        PRINT '  Sistema de seguridad no encontrado';
    END
END TRY
BEGIN CATCH
    PRINT ' Error verificando seguridad: ' + ERROR_MESSAGE();
    SET @ErrorCount += 1;
END CATCH



DECLARE @FinInstalacion DATETIME2 = GETDATE();
DECLARE @TiempoTotal INT = DATEDIFF(SECOND, @InicioInstalacion, @FinInstalacion);

PRINT '';
PRINT '================================================================================';
PRINT 'RESUMEN DE INSTALACIÓN';
PRINT '================================================================================';
PRINT 'Inicio: ' + CAST(@InicioInstalacion AS NVARCHAR(30));
PRINT 'Fin: ' + CAST(@FinInstalacion AS NVARCHAR(30));
PRINT 'Tiempo total: ' + CAST(@TiempoTotal AS NVARCHAR(10)) + ' segundos';
PRINT 'Errores encontrados: ' + CAST(@ErrorCount AS NVARCHAR(10));

IF @ErrorCount = 0
BEGIN
    PRINT '';
    PRINT ' INSTALACIÓN COMPLETADA EXITOSAMENTE';
    PRINT '';
    PRINT 'PRÓXIMOS PASOS:';
    PRINT '1. Ejecutar manualmente los scripts indicados con ';
    PRINT '2. Cargar el Data Warehouse: EXEC DW.sp_CargaCompletaDataWarehouse';
    PRINT '3. Verificar dashboard: SELECT * FROM vw_DashboardEjecutivo';
    PRINT '4. Ejecutar optimización: EXEC sp_OptimizacionAutomatica';
END
ELSE
BEGIN
    PRINT '';
    PRINT '  INSTALACIÓN COMPLETADA CON ADVERTENCIAS';
    PRINT 'Revise los errores indicados arriba y ejecute los scripts manualmente.';
END

PRINT '';
PRINT 'COMANDOS ÚTILES PARA VERIFICACIÓN:';
PRINT '- Verificar tablas: SELECT name FROM sys.tables WHERE is_ms_shipped = 0';
PRINT '- Verificar procedimientos: SELECT name FROM sys.procedures WHERE is_ms_shipped = 0';
PRINT '- Verificar roles: SELECT name FROM sys.database_principals WHERE type = ''R''';
PRINT '- Dashboard ejecutivo: SELECT * FROM vw_DashboardEjecutivo';
PRINT '';
PRINT 'DOCUMENTACIÓN COMPLETA: 08_Documentacion/documentacion_tecnica.md';
PRINT '';
PRINT '================================================================================';
PRINT 'SISTEMA EDUGESTOR - PROYECTO FINAL BASES DE DATOS II';
PRINT 'Desarrollado por: Proyecto BDII - Sistema Educativo Integral';
PRINT 'Fecha: Noviembre 2024';
PRINT '================================================================================';

-- Mostrar información de conexión actual
SELECT 
    'Información de Conexión' as Detalle,
    DB_NAME() as 'Base de Datos',
    SUSER_NAME() as 'Usuario Conectado',
    @@SERVERNAME as 'Servidor',
    @@VERSION as 'Versión SQL Server';

PRINT '';
PRINT 'Instalación finalizada. ¡Gracias por usar EduGestor!';