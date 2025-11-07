-- ================================================================================
-- OPTIMIZACIÓN Y ANÁLISIS DE RENDIMIENTO - SISTEMA EDUGESTOR
-- ================================================================================
-- Descripción: Análisis de planes de ejecución, creación de índices optimizados,
--              estadísticas de rendimiento y mejoras de consultas
-- Autor: Proyecto BDII
-- Fecha: Noviembre 2024
-- Características: Índices estratégicos, análisis de fragmentación, estadísticas
-- ================================================================================

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO

-- ================================================================================
-- ANÁLISIS INICIAL DE RENDIMIENTO
-- ================================================================================

-- Procedimiento para analizar el estado actual de la base de datos
CREATE OR ALTER PROCEDURE sp_AnalisisRendimientoInicial
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '================================================================================';
    PRINT 'ANÁLISIS INICIAL DE RENDIMIENTO - SISTEMA EDUGESTOR';
    PRINT '================================================================================';
    
    -- 1. Información general de la base de datos
    PRINT 'INFORMACIÓN GENERAL DE LA BASE DE DATOS:';
    SELECT 
        DB_NAME() as 'Base de Datos',
        (SELECT COUNT(*) FROM sys.tables WHERE type = 'U') as 'Total Tablas',
        (SELECT COUNT(*) FROM sys.indexes WHERE type > 0) as 'Total Índices',
        (SELECT COUNT(*) FROM sys.procedures WHERE type = 'P') as 'Procedimientos Almacenados',
        (SELECT COUNT(*) FROM sys.views WHERE type = 'V') as 'Vistas'
    
    -- 2. Tamaño de las tablas principales
    PRINT '';
    PRINT 'TAMAÑO DE TABLAS PRINCIPALES:';
    SELECT 
        t.name as 'Tabla',
        p.rows as 'Filas',
        CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as 'Tamaño (MB)',
        CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as 'Usado (MB)',
        CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) as 'No Usado (MB)'
    FROM sys.tables t
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.name NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.object_id > 255
    GROUP BY t.name, s.name, p.rows
    ORDER BY SUM(a.total_pages) DESC;
    
    PRINT '';
    PRINT 'ANÁLISIS INICIAL COMPLETADO';
END
GO

-- Ejecutar análisis inicial
EXEC sp_AnalisisRendimientoInicial;

-- ================================================================================
-- CREACIÓN DE ÍNDICES OPTIMIZADOS
-- ================================================================================

PRINT '';
PRINT 'CREANDO ÍNDICES OPTIMIZADOS BASADOS EN PATRONES DE CONSULTA...';

-- Índices para consultas frecuentes en el sistema transaccional

-- 1. Índice compuesto para búsquedas de estudiantes por grado y estado
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_estudiante_grado_estado_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_estudiante_grado_estado_optimizado
    ON estudiante (grado_id, estado)
    INCLUDE (nombre_completo, documento_identidad, telefono, email);
    PRINT 'Índice IX_estudiante_grado_estado_optimizado creado';
END

-- 2. Índice para consultas de asignaciones por curso y estado
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_asignacion_curso_estado_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_asignacion_curso_estado_optimizado
    ON asignacion_curso (curso_id, estado_asignacion)
    INCLUDE (estudiante_id, fecha_asignacion);
    PRINT 'Índice IX_asignacion_curso_estado_optimizado creado';
END

-- 3. Índice para consultas de calificaciones por estado y fecha
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_calificacion_estado_fecha_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_calificacion_estado_fecha_optimizado
    ON calificacion (estado_calificacion, fecha_calificacion)
    INCLUDE (asignacion_curso_id, nota_final, nota_parcial1, nota_parcial2, nota_parcial3);
    PRINT 'Índice IX_calificacion_estado_fecha_optimizado creado';
END

-- 4. Índice para consultas de pagos por fecha y concepto
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_pago_fecha_concepto_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_pago_fecha_concepto_optimizado
    ON pago (fecha_pago, concepto_pago_id)
    INCLUDE (estudiante_id, monto, metodo_pago, estado_pago);
    PRINT 'Índice IX_pago_fecha_concepto_optimizado creado';
END

-- 5. Índice para consultas de pagos por estudiante y estado
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_pago_estudiante_estado_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_pago_estudiante_estado_optimizado
    ON pago (estudiante_id, estado_pago)
    INCLUDE (concepto_pago_id, monto, fecha_pago, metodo_pago);
    PRINT 'Índice IX_pago_estudiante_estado_optimizado creado';
END-
- 6. Índice para consultas de cursos por profesor y período
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_curso_profesor_periodo_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_curso_profesor_periodo_optimizado
    ON curso (profesor_id, periodo_academico, estado)
    INCLUDE (nombre, codigo_curso, creditos, horas_semanales);
    PRINT 'Índice IX_curso_profesor_periodo_optimizado creado';
END

-- 7. Índice para auditoría por fecha y usuario
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_auditoria_fecha_usuario_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_auditoria_fecha_usuario_optimizado
    ON auditoria_seguridad (fecha_evento, usuario_bd)
    INCLUDE (tipo_evento, tabla_afectada, resultado);
    PRINT 'Índice IX_auditoria_fecha_usuario_optimizado creado';
END

-- ================================================================================
-- ESTADÍSTICAS PERSONALIZADAS
-- ================================================================================

-- Crear estadísticas para columnas frecuentemente filtradas

-- Estadística para combinación estudiante-grado
IF NOT EXISTS (SELECT * FROM sys.stats WHERE name = 'STAT_estudiante_grado_estado')
BEGIN
    CREATE STATISTICS STAT_estudiante_grado_estado
    ON estudiante (grado_id, estado, fecha_ingreso);
    PRINT 'Estadística STAT_estudiante_grado_estado creada';
END

-- Estadística para pagos por fecha y monto
IF NOT EXISTS (SELECT * FROM sys.stats WHERE name = 'STAT_pago_fecha_monto')
BEGIN
    CREATE STATISTICS STAT_pago_fecha_monto
    ON pago (fecha_pago, monto, metodo_pago);
    PRINT 'Estadística STAT_pago_fecha_monto creada';
END

-- ================================================================================
-- CONSULTAS DE PRUEBA PARA ANÁLISIS DE PLANES DE EJECUCIÓN
-- ================================================================================

-- Procedimiento para ejecutar consultas de prueba y analizar rendimiento
CREATE OR ALTER PROCEDURE sp_PruebasRendimiento
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;
    
    PRINT '================================================================================';
    PRINT 'EJECUTANDO PRUEBAS DE RENDIMIENTO';
    PRINT '================================================================================';
    
    -- Prueba 1: Consulta de estudiantes por grado (debe usar índice optimizado)
    PRINT 'PRUEBA 1: Consulta de estudiantes por grado';
    SELECT e.nombre_completo, e.documento_identidad, g.nombre as grado
    FROM estudiante e
    INNER JOIN grado g ON e.grado_id = g.grado_id
    WHERE e.grado_id = 1 AND e.estado = 'ACTIVO';
    
    -- Prueba 2: Consulta de pagos por rango de fechas (debe usar índice de fecha)
    PRINT '';
    PRINT 'PRUEBA 2: Consulta de pagos por rango de fechas';
    SELECT p.fecha_pago, p.monto, cp.nombre, e.nombre_completo
    FROM pago p
    INNER JOIN concepto_pago cp ON p.concepto_pago_id = cp.concepto_pago_id
    INNER JOIN estudiante e ON p.estudiante_id = e.estudiante_id
    WHERE p.fecha_pago BETWEEN '2024-01-01' AND '2024-03-31'
    AND p.estado_pago = 'COMPLETADO';
    
    -- Prueba 3: Consulta de calificaciones pendientes (debe usar índice de estado)
    PRINT '';
    PRINT 'PRUEBA 3: Consulta de calificaciones pendientes';
    SELECT c.calificacion_id, e.nombre_completo, cur.nombre as curso, c.fecha_calificacion
    FROM calificacion c
    INNER JOIN asignacion_curso ac ON c.asignacion_curso_id = ac.asignacion_curso_id
    INNER JOIN estudiante e ON ac.estudiante_id = e.estudiante_id
    INNER JOIN curso cur ON ac.curso_id = cur.curso_id
    WHERE c.estado_calificacion = 'PENDIENTE';
    
    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
    
    PRINT '';
    PRINT 'PRUEBAS DE RENDIMIENTO COMPLETADAS';
END
GO

-- ================================================================================
-- ANÁLISIS DE CONSULTAS COSTOSAS
-- ================================================================================

-- Vista para identificar consultas costosas
CREATE OR ALTER VIEW vw_ConsultasCostosas AS
SELECT TOP 20
    qs.sql_handle,
    qs.execution_count as 'Ejecuciones',
    qs.total_elapsed_time / 1000000.0 as 'Tiempo Total (seg)',
    qs.total_elapsed_time / qs.execution_count / 1000000.0 as 'Tiempo Promedio (seg)',
    qs.total_logical_reads as 'Lecturas Lógicas Total',
    qs.total_logical_reads / qs.execution_count as 'Lecturas Lógicas Promedio',
    qs.total_physical_reads as 'Lecturas Físicas Total',
    qs.creation_time as 'Fecha Creación Plan',
    qs.last_execution_time as 'Última Ejecución',
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset
        END - qs.statement_start_offset)/2) + 1) as 'Consulta SQL'
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.dbid = DB_ID()
ORDER BY qs.total_elapsed_time DESC;
GO

-- ================================================================================
-- PROCEDIMIENTOS DE MANTENIMIENTO AUTOMÁTICO
-- ================================================================================

-- Procedimiento para actualizar estadísticas automáticamente
CREATE OR ALTER PROCEDURE sp_ActualizarEstadisticas
    @ModoCompleto BIT = 0 -- 0 = Muestreo, 1 = Completo
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(500);
    DECLARE @Tabla NVARCHAR(128);
    DECLARE @Estadistica NVARCHAR(128);
    DECLARE @Contador INT = 0;
    
    PRINT 'INICIANDO ACTUALIZACIÓN DE ESTADÍSTICAS...';
    
    -- Cursor para recorrer todas las estadísticas
    DECLARE cursor_estadisticas CURSOR FOR
        SELECT 
            OBJECT_NAME(s.object_id) as tabla,
            s.name as estadistica
        FROM sys.stats s
        INNER JOIN sys.tables t ON s.object_id = t.object_id
        WHERE t.is_ms_shipped = 0
        AND s.auto_created = 0; -- Solo estadísticas creadas manualmente
    
    OPEN cursor_estadisticas;
    FETCH NEXT FROM cursor_estadisticas INTO @Tabla, @Estadistica;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            IF @ModoCompleto = 1
                SET @SQL = 'UPDATE STATISTICS [' + @Tabla + '] ([' + @Estadistica + ']) WITH FULLSCAN';
            ELSE
                SET @SQL = 'UPDATE STATISTICS [' + @Tabla + '] ([' + @Estadistica + ']) WITH SAMPLE 20 PERCENT';
            
            EXEC sp_executesql @SQL;
            SET @Contador += 1;
            
            PRINT 'Estadística actualizada: ' + @Tabla + '.' + @Estadistica;
            
        END TRY
        BEGIN CATCH
            PRINT 'Error actualizando ' + @Tabla + '.' + @Estadistica + ': ' + ERROR_MESSAGE();
        END CATCH
        
        FETCH NEXT FROM cursor_estadisticas INTO @Tabla, @Estadistica;
    END
    
    CLOSE cursor_estadisticas;
    DEALLOCATE cursor_estadisticas;
    
    PRINT 'ACTUALIZACIÓN COMPLETADA. Total estadísticas actualizadas: ' + CAST(@Contador AS NVARCHAR(10));
END
GO

-- ================================================================================
-- PROCEDIMIENTO MAESTRO PARA OPTIMIZACIÓN AUTOMÁTICA
-- ================================================================================

-- Procedimiento maestro para optimización automática
CREATE OR ALTER PROCEDURE sp_OptimizacionAutomatica
    @ActualizarEstadisticas BIT = 1,
    @GenerarReporte BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @InicioEjecucion DATETIME2 = GETDATE();
    
    PRINT '================================================================================';
    PRINT 'INICIANDO OPTIMIZACIÓN AUTOMÁTICA - ' + CAST(@InicioEjecucion AS NVARCHAR(30));
    PRINT '================================================================================';
    
    BEGIN TRY
        -- 1. Actualizar estadísticas
        IF @ActualizarEstadisticas = 1
        BEGIN
            PRINT 'FASE 1: Actualizando estadísticas...';
            EXEC sp_ActualizarEstadisticas @ModoCompleto = 0;
        END
        
        -- 2. Generar reporte
        IF @GenerarReporte = 1
        BEGIN
            PRINT '';
            PRINT 'FASE 2: Generando reporte de rendimiento...';
            EXEC sp_AnalisisRendimientoInicial;
        END
        
        DECLARE @FinEjecucion DATETIME2 = GETDATE();
        DECLARE @TiempoEjecucion INT = DATEDIFF(SECOND, @InicioEjecucion, @FinEjecucion);
        
        PRINT '';
        PRINT '================================================================================';
        PRINT 'OPTIMIZACIÓN AUTOMÁTICA COMPLETADA EXITOSAMENTE';
        PRINT 'Tiempo de ejecución: ' + CAST(@TiempoEjecucion AS NVARCHAR(10)) + ' segundos';
        PRINT 'Fecha fin: ' + CAST(@FinEjecucion AS NVARCHAR(30));
        PRINT '================================================================================';
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN LA OPTIMIZACIÓN AUTOMÁTICA:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'Principal');
        
        THROW;
    END CATCH
END
GO

-- Ejecutar pruebas de rendimiento
PRINT '';
PRINT 'EJECUTANDO PRUEBAS DE RENDIMIENTO...';
EXEC sp_PruebasRendimiento;

PRINT '';
PRINT '================================================================================';
PRINT 'OPTIMIZACIÓN Y ANÁLISIS DE RENDIMIENTO COMPLETADO';
PRINT '================================================================================';
PRINT 'Índices optimizados creados: 7';
PRINT 'Estadísticas personalizadas: 2';
PRINT 'Procedimientos de mantenimiento: 3';
PRINT 'Vistas de monitoreo: 1';
PRINT '';
PRINT 'Procedimientos disponibles para mantenimiento:';
PRINT '- sp_OptimizacionAutomatica: Optimización completa automática';
PRINT '- sp_ActualizarEstadisticas: Actualización de estadísticas';
PRINT '- sp_AnalisisRendimientoInicial: Análisis completo de rendimiento';
PRINT '';
PRINT 'Vistas de monitoreo:';
PRINT '- vw_ConsultasCostosas: Top consultas más costosas';
PRINT '';
PRINT 'Recomendación: Ejecutar sp_OptimizacionAutomatica semanalmente';
GO