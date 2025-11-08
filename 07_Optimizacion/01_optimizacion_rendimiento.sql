

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO



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
    
    -- 3. Índices existentes y su uso
    PRINT '';
    PRINT 'ANÁLISIS DE ÍNDICES EXISTENTES:';
    SELECT 
        OBJECT_NAME(i.object_id) as 'Tabla',
        i.name as 'Índice',
        i.type_desc as 'Tipo',
        us.user_seeks as 'Búsquedas',
        us.user_scans as 'Escaneos',
        us.user_lookups as 'Búsquedas Clave',
        us.user_updates as 'Actualizaciones',
        CASE 
            WHEN us.user_seeks + us.user_scans + us.user_lookups = 0 THEN 'NO USADO'
            WHEN us.user_seeks + us.user_scans + us.user_lookups < us.user_updates THEN 'POCO EFICIENTE'
            ELSE 'EFICIENTE'
        END as 'Estado'
    FROM sys.indexes i
    LEFT JOIN sys.dm_db_index_usage_stats us ON i.object_id = us.object_id AND i.index_id = us.index_id
    WHERE i.object_id IN (SELECT object_id FROM sys.tables WHERE is_ms_shipped = 0)
    AND i.type > 0
    ORDER BY OBJECT_NAME(i.object_id), i.index_id;
    
    -- 4. Fragmentación de índices
    PRINT '';
    PRINT 'FRAGMENTACIÓN DE ÍNDICES:';
    SELECT 
        OBJECT_NAME(ips.object_id) as 'Tabla',
        i.name as 'Índice',
        ips.index_type_desc as 'Tipo',
        ips.avg_fragmentation_in_percent as 'Fragmentación %',
        ips.page_count as 'Páginas',
        CASE 
            WHEN ips.avg_fragmentation_in_percent > 30 THEN 'CRÍTICO - REBUILD'
            WHEN ips.avg_fragmentation_in_percent > 10 THEN 'ALTO - REORGANIZE'
            WHEN ips.avg_fragmentation_in_percent > 5 THEN 'MEDIO - MONITOREAR'
            ELSE 'BUENO'
        END as 'Recomendación'
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count > 100 -- Solo índices con más de 100 páginas
    ORDER BY ips.avg_fragmentation_in_percent DESC;
    
    PRINT '';
    PRINT 'ANÁLISIS INICIAL COMPLETADO';
END
GO

-- Ejecutar análisis inicial
EXEC sp_AnalisisRendimientoInicial;



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
END

-- 6. Índice para consultas de cursos por profesor y período
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

-- Índices para el Data Warehouse (consultas OLAP)

-- 8. Índice para FactCalificaciones por tiempo y curso
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactCalif_tiempo_curso_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactCalif_tiempo_curso_optimizado
    ON DW.FactCalificaciones (tiempo_key, curso_key)
    INCLUDE (estudiante_key, nota_final, es_aprobado, es_excelente);
    PRINT 'Índice IX_FactCalif_tiempo_curso_optimizado creado';
END

-- 9. Índice para FactPagos por tiempo y concepto
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_FactPago_tiempo_concepto_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_FactPago_tiempo_concepto_optimizado
    ON DW.FactPagos (tiempo_key, concepto_pago_key)
    INCLUDE (estudiante_key, monto_pagado, es_pago_completo, es_pago_puntual);
    PRINT 'Índice IX_FactPago_tiempo_concepto_optimizado creado';
END

-- 10. Índice para DimTiempo por jerarquías
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DimTiempo_jerarquia_optimizado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_DimTiempo_jerarquia_optimizado
    ON DW.DimTiempo (año, trimestre, mes)
    INCLUDE (fecha, nombre_mes, periodo_academico);
    PRINT 'Índice IX_DimTiempo_jerarquia_optimizado creado';
END



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
    
    -- Prueba 4: Consulta agregada de rendimiento por curso
    PRINT '';
    PRINT 'PRUEBA 4: Consulta agregada de rendimiento por curso';
    SELECT 
        cur.nombre as curso,
        COUNT(*) as total_estudiantes,
        AVG(c.nota_final) as promedio,
        SUM(CASE WHEN c.nota_final >= 70 THEN 1 ELSE 0 END) as aprobados
    FROM calificacion c
    INNER JOIN asignacion_curso ac ON c.asignacion_curso_id = ac.asignacion_curso_id
    INNER JOIN curso cur ON ac.curso_id = cur.curso_id
    WHERE c.nota_final IS NOT NULL
    GROUP BY cur.curso_id, cur.nombre
    ORDER BY promedio DESC;
    
    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
    
    PRINT '';
    PRINT 'PRUEBAS DE RENDIMIENTO COMPLETADAS';
END
GO



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

-- Procedimiento para análisis de fragmentación y mantenimiento
CREATE OR ALTER PROCEDURE sp_AnalisisFragmentacion
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'ANÁLISIS DE FRAGMENTACIÓN DE ÍNDICES:';
    
    -- Crear tabla temporal para resultados
    CREATE TABLE #FragmentacionIndices (
        NombreTabla NVARCHAR(128),
        NombreIndice NVARCHAR(128),
        FragmentacionPorcentaje DECIMAL(5,2),
        Paginas INT,
        Recomendacion NVARCHAR(50),
        ComandoMantenimiento NVARCHAR(500)
    );
    
    -- Insertar datos de fragmentación
    INSERT INTO #FragmentacionIndices
    SELECT 
        OBJECT_NAME(ips.object_id) as NombreTabla,
        i.name as NombreIndice,
        ips.avg_fragmentation_in_percent as FragmentacionPorcentaje,
        ips.page_count as Paginas,
        CASE 
            WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
            WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
            WHEN ips.avg_fragmentation_in_percent > 5 THEN 'MONITOREAR'
            ELSE 'BUENO'
        END as Recomendacion,
        CASE 
            WHEN ips.avg_fragmentation_in_percent > 30 THEN 
                'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(ips.object_id) + '] REBUILD WITH (ONLINE = OFF);'
            WHEN ips.avg_fragmentation_in_percent > 10 THEN 
                'ALTER INDEX [' + i.name + '] ON [' + OBJECT_NAME(ips.object_id) + '] REORGANIZE;'
            ELSE ''
        END as ComandoMantenimiento
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count > 100
    AND OBJECT_NAME(ips.object_id) NOT LIKE 'sys%';
    
    -- Mostrar resultados
    SELECT * FROM #FragmentacionIndices
    ORDER BY FragmentacionPorcentaje DESC;
    
    -- Generar script de mantenimiento
    PRINT '';
    PRINT 'COMANDOS DE MANTENIMIENTO RECOMENDADOS:';
    SELECT ComandoMantenimiento
    FROM #FragmentacionIndices
    WHERE ComandoMantenimiento != ''
    ORDER BY FragmentacionPorcentaje DESC;
    
    DROP TABLE #FragmentacionIndices;
END
GO

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

-- Procedimiento para mantenimiento automático de índices
CREATE OR ALTER PROCEDURE sp_MantenimientoIndices
    @UmbralReorganizar DECIMAL(5,2) = 10.0,
    @UmbralReconstruir DECIMAL(5,2) = 30.0,
    @EjecutarComandos BIT = 0 -- 0 = Solo mostrar, 1 = Ejecutar
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(500);
    DECLARE @Tabla NVARCHAR(128);
    DECLARE @Indice NVARCHAR(128);
    DECLARE @Fragmentacion DECIMAL(5,2);
    DECLARE @Accion NVARCHAR(20);
    DECLARE @Contador INT = 0;
    
    PRINT 'INICIANDO MANTENIMIENTO DE ÍNDICES...';
    PRINT 'Umbral Reorganizar: ' + CAST(@UmbralReorganizar AS NVARCHAR(10)) + '%';
    PRINT 'Umbral Reconstruir: ' + CAST(@UmbralReconstruir AS NVARCHAR(10)) + '%';
    PRINT 'Modo: ' + CASE WHEN @EjecutarComandos = 1 THEN 'EJECUTAR' ELSE 'SOLO MOSTRAR' END;
    PRINT '';
    
    -- Cursor para índices fragmentados
    DECLARE cursor_indices CURSOR FOR
        SELECT 
            OBJECT_NAME(ips.object_id) as tabla,
            i.name as indice,
            ips.avg_fragmentation_in_percent as fragmentacion,
            CASE 
                WHEN ips.avg_fragmentation_in_percent >= @UmbralReconstruir THEN 'REBUILD'
                WHEN ips.avg_fragmentation_in_percent >= @UmbralReorganizar THEN 'REORGANIZE'
                ELSE 'NINGUNA'
            END as accion
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
        INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
        WHERE ips.page_count > 100
        AND ips.avg_fragmentation_in_percent >= @UmbralReorganizar
        AND OBJECT_NAME(ips.object_id) NOT LIKE 'sys%'
        AND i.type > 0; -- Excluir heaps
    
    OPEN cursor_indices;
    FETCH NEXT FROM cursor_indices INTO @Tabla, @Indice, @Fragmentacion, @Accion;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Accion = 'REBUILD'
            SET @SQL = 'ALTER INDEX [' + @Indice + '] ON [' + @Tabla + '] REBUILD WITH (ONLINE = OFF, SORT_IN_TEMPDB = ON)';
        ELSE IF @Accion = 'REORGANIZE'
            SET @SQL = 'ALTER INDEX [' + @Indice + '] ON [' + @Tabla + '] REORGANIZE';
        
        PRINT @Accion + ': ' + @Tabla + '.' + @Indice + ' (Fragmentación: ' + CAST(@Fragmentacion AS NVARCHAR(10)) + '%)';
        
        IF @EjecutarComandos = 1
        BEGIN
            BEGIN TRY
                EXEC sp_executesql @SQL;
                PRINT '   Ejecutado exitosamente';
                SET @Contador += 1;
            END TRY
            BEGIN CATCH
                PRINT '   Error: ' + ERROR_MESSAGE();
            END CATCH
        END
        ELSE
        BEGIN
            PRINT '  Comando: ' + @SQL;
        END
        
        FETCH NEXT FROM cursor_indices INTO @Tabla, @Indice, @Fragmentacion, @Accion;
    END
    
    CLOSE cursor_indices;
    DEALLOCATE cursor_indices;
    
    PRINT '';
    IF @EjecutarComandos = 1
        PRINT 'MANTENIMIENTO COMPLETADO. Índices procesados: ' + CAST(@Contador AS NVARCHAR(10));
    ELSE
        PRINT 'ANÁLISIS COMPLETADO. Use @EjecutarComandos = 1 para ejecutar el mantenimiento.';
END
GO



-- Vista para monitorear consultas activas
CREATE OR ALTER VIEW vw_ConsultasActivas AS
SELECT 
    s.session_id as 'ID Sesión',
    s.login_name as 'Usuario',
    s.host_name as 'Host',
    s.program_name as 'Aplicación',
    r.status as 'Estado',
    r.command as 'Comando',
    r.cpu_time as 'Tiempo CPU (ms)',
    r.total_elapsed_time as 'Tiempo Total (ms)',
    r.logical_reads as 'Lecturas Lógicas',
    r.reads as 'Lecturas Físicas',
    r.writes as 'Escrituras',
    r.blocking_session_id as 'Bloqueado Por',
    SUBSTRING(st.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) as 'Consulta SQL'
FROM sys.dm_exec_sessions s
INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE s.is_user_process = 1
AND r.session_id != @@SPID;
GO

-- Procedimiento para identificar bloqueos
CREATE OR ALTER PROCEDURE sp_AnalisisBloqueos
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'ANÁLISIS DE BLOQUEOS ACTIVOS:';
    
    -- Bloqueos activos
    SELECT 
        blocking.session_id as 'Sesión Bloqueadora',
        blocked.session_id as 'Sesión Bloqueada',
        blocking_login.login_name as 'Usuario Bloqueador',
        blocked_login.login_name as 'Usuario Bloqueado',
        blocked.wait_type as 'Tipo Espera',
        blocked.wait_time as 'Tiempo Espera (ms)',
        blocked.wait_resource as 'Recurso',
        SUBSTRING(blocking_text.text, (blocking_req.statement_start_offset/2)+1,
            ((CASE blocking_req.statement_end_offset
                WHEN -1 THEN DATALENGTH(blocking_text.text)
                ELSE blocking_req.statement_end_offset
            END - blocking_req.statement_start_offset)/2) + 1) as 'SQL Bloqueador',
        SUBSTRING(blocked_text.text, (blocked.statement_start_offset/2)+1,
            ((CASE blocked.statement_end_offset
                WHEN -1 THEN DATALENGTH(blocked_text.text)
                ELSE blocked.statement_end_offset
            END - blocked.statement_start_offset)/2) + 1) as 'SQL Bloqueado'
    FROM sys.dm_exec_requests blocked
    INNER JOIN sys.dm_exec_sessions blocked_login ON blocked.session_id = blocked_login.session_id
    INNER JOIN sys.dm_exec_requests blocking_req ON blocked.blocking_session_id = blocking_req.session_id
    INNER JOIN sys.dm_exec_sessions blocking ON blocking_req.session_id = blocking.session_id
    CROSS APPLY sys.dm_exec_sql_text(blocked.sql_handle) blocked_text
    CROSS APPLY sys.dm_exec_sql_text(blocking_req.sql_handle) blocking_text
    WHERE blocked.blocking_session_id != 0;
    
    -- Si no hay bloqueos
    IF @@ROWCOUNT = 0
        PRINT 'No se encontraron bloqueos activos.';
END
GO



-- Procedimiento para reporte completo de rendimiento
CREATE OR ALTER PROCEDURE sp_ReporteRendimientoCompleto
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '================================================================================';
    PRINT 'REPORTE COMPLETO DE RENDIMIENTO - ' + CAST(GETDATE() AS NVARCHAR(30));
    PRINT '================================================================================';
    
    -- 1. Resumen de la base de datos
    PRINT '1. RESUMEN DE LA BASE DE DATOS:';
    SELECT 
        DB_NAME() as 'Base de Datos',
        CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2)) as 'Tamaño Total (MB)',
        (SELECT COUNT(*) FROM sys.tables WHERE type = 'U') as 'Tablas',
        (SELECT COUNT(*) FROM sys.indexes WHERE type > 0) as 'Índices',
        (SELECT COUNT(*) FROM sys.procedures WHERE type = 'P') as 'Procedimientos'
    FROM sys.master_files 
    WHERE database_id = DB_ID();
    
    -- 2. Top 5 tablas más grandes
    PRINT '';
    PRINT '2. TOP 5 TABLAS MÁS GRANDES:';
    SELECT TOP 5
        t.name as 'Tabla',
        p.rows as 'Filas',
        CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) as 'Tamaño (MB)'
    FROM sys.tables t
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    WHERE t.is_ms_shipped = 0 AND i.object_id > 255
    GROUP BY t.name, p.rows
    ORDER BY SUM(a.total_pages) DESC;
    
    -- 3. Índices más fragmentados
    PRINT '';
    PRINT '3. TOP 5 ÍNDICES MÁS FRAGMENTADOS:';
    SELECT TOP 5
        OBJECT_NAME(ips.object_id) as 'Tabla',
        i.name as 'Índice',
        CAST(ips.avg_fragmentation_in_percent AS DECIMAL(5,2)) as 'Fragmentación %',
        ips.page_count as 'Páginas'
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count > 100
    ORDER BY ips.avg_fragmentation_in_percent DESC;
    
    -- 4. Consultas más costosas (últimas 24 horas)
    PRINT '';
    PRINT '4. TOP 5 CONSULTAS MÁS COSTOSAS:';
    SELECT TOP 5
        qs.execution_count as 'Ejecuciones',
        CAST(qs.total_elapsed_time / 1000000.0 AS DECIMAL(10,2)) as 'Tiempo Total (seg)',
        CAST(qs.total_elapsed_time / qs.execution_count / 1000000.0 AS DECIMAL(10,4)) as 'Tiempo Promedio (seg)',
        qs.total_logical_reads / qs.execution_count as 'Lecturas Promedio',
        LEFT(REPLACE(REPLACE(st.text, CHAR(13), ' '), CHAR(10), ' '), 100) as 'Consulta (Primeros 100 chars)'
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE st.dbid = DB_ID()
    AND qs.last_execution_time >= DATEADD(HOUR, -24, GETDATE())
    ORDER BY qs.total_elapsed_time DESC;
    
    -- 5. Estadísticas de esperas
    PRINT '';
    PRINT '5. TOP 5 TIPOS DE ESPERA:';
    SELECT TOP 5
        wait_type as 'Tipo Espera',
        waiting_tasks_count as 'Tareas Esperando',
        CAST(wait_time_ms / 1000.0 AS DECIMAL(10,2)) as 'Tiempo Espera (seg)',
        CAST(signal_wait_time_ms / 1000.0 AS DECIMAL(10,2)) as 'Tiempo Señal (seg)',
        CAST(wait_time_ms * 100.0 / SUM(wait_time_ms) OVER() AS DECIMAL(5,2)) as 'Porcentaje'
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
        'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT'
    )
    ORDER BY wait_time_ms DESC;
    
    PRINT '';
    PRINT 'REPORTE COMPLETADO';
END
GO



-- Procedimiento maestro para optimización automática
CREATE OR ALTER PROCEDURE sp_OptimizacionAutomatica
    @ActualizarEstadisticas BIT = 1,
    @MantenimientoIndices BIT = 1,
    @EjecutarMantenimiento BIT = 0,
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
        
        -- 2. Mantenimiento de índices
        IF @MantenimientoIndices = 1
        BEGIN
            PRINT '';
            PRINT 'FASE 2: Analizando fragmentación de índices...';
            EXEC sp_MantenimientoIndices 
                @UmbralReorganizar = 10.0,
                @UmbralReconstruir = 30.0,
                @EjecutarComandos = @EjecutarMantenimiento;
        END
        
        -- 3. Generar reporte
        IF @GenerarReporte = 1
        BEGIN
            PRINT '';
            PRINT 'FASE 3: Generando reporte de rendimiento...';
            EXEC sp_ReporteRendimientoCompleto;
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

-- Ejecutar análisis de fragmentación
PRINT '';
PRINT 'EJECUTANDO ANÁLISIS DE FRAGMENTACIÓN...';
EXEC sp_AnalisisFragmentacion;

PRINT '';
PRINT '================================================================================';
PRINT 'OPTIMIZACIÓN Y ANÁLISIS DE RENDIMIENTO COMPLETADO';
PRINT '================================================================================';
PRINT 'Índices optimizados creados: 10';
PRINT 'Estadísticas personalizadas: 2';
PRINT 'Procedimientos de mantenimiento: 4';
PRINT 'Vistas de monitoreo: 2';
PRINT '';
PRINT 'Procedimientos disponibles para mantenimiento:';
PRINT '- sp_OptimizacionAutomatica: Optimización completa automática';
PRINT '- sp_ActualizarEstadisticas: Actualización de estadísticas';
PRINT '- sp_MantenimientoIndices: Mantenimiento de índices fragmentados';
PRINT '- sp_ReporteRendimientoCompleto: Reporte completo de rendimiento';
PRINT '- sp_AnalisisBloqueos: Análisis de bloqueos activos';
PRINT '';
PRINT 'Vistas de monitoreo:';
PRINT '- vw_ConsultasCostosas: Top consultas más costosas';
PRINT '- vw_ConsultasActivas: Consultas ejecutándose actualmente';
PRINT '';
PRINT 'Recomendación: Ejecutar sp_OptimizacionAutomatica semanalmente';
GO