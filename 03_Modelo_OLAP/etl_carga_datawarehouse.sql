/*
================================================================================
PROCESOS ETL - CARGA DEL DATA WAREHOUSE
================================================================================
Descripción: Procedimientos para extraer, transformar y cargar datos desde 
             el sistema transaccional al modelo dimensional
Autor: Proyecto BDII
Fecha: Noviembre 2024
Estrategia: Carga incremental con control de cambios (SCD Tipo 2)
================================================================================
*/

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO

/*
================================================================================
PROCEDIMIENTO: CARGA DIMENSIÓN TIEMPO
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarDimTiempo
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Valores por defecto: año actual completo
    IF @FechaInicio IS NULL SET @FechaInicio = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
    IF @FechaFin IS NULL SET @FechaFin = DATEFROMPARTS(YEAR(GETDATE()), 12, 31);
    
    DECLARE @FechaActual DATE = @FechaInicio;
    
    PRINT 'Iniciando carga de DimTiempo desde ' + CAST(@FechaInicio AS NVARCHAR(10)) + 
          ' hasta ' + CAST(@FechaFin AS NVARCHAR(10));
    
    WHILE @FechaActual <= @FechaFin
    BEGIN
        -- Insertar solo si no existe
        IF NOT EXISTS (SELECT 1 FROM DW.DimTiempo WHERE fecha = @FechaActual)
        BEGIN
            INSERT INTO DW.DimTiempo (
                fecha, dia, dia_semana, nombre_dia, dia_año, semana_año,
                mes, nombre_mes, mes_año, trimestre, nombre_trimestre, trimestre_año,
                año, periodo_academico, es_periodo_lectivo, es_fin_semana, es_festivo
            )
            VALUES (
                @FechaActual,
                DAY(@FechaActual),
                DATEPART(WEEKDAY, @FechaActual),
                DATENAME(WEEKDAY, @FechaActual),
                DATEPART(DAYOFYEAR, @FechaActual),
                DATEPART(WEEK, @FechaActual),
                MONTH(@FechaActual),
                DATENAME(MONTH, @FechaActual),
                FORMAT(@FechaActual, 'yyyy-MM'),
                DATEPART(QUARTER, @FechaActual),
                'Q' + CAST(DATEPART(QUARTER, @FechaActual) AS NVARCHAR(1)),
                CAST(YEAR(@FechaActual) AS NVARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, @FechaActual) AS NVARCHAR(1)),
                YEAR(@FechaActual),
                -- Período académico: 2024-1 (Ene-Jun), 2024-2 (Jul-Dic)
                CAST(YEAR(@FechaActual) AS NVARCHAR(4)) + '-' + 
                CASE WHEN MONTH(@FechaActual) <= 6 THEN '1' ELSE '2' END,
                -- Período lectivo: excluye diciembre y enero
                CASE WHEN MONTH(@FechaActual) IN (12, 1) THEN 0 ELSE 1 END,
                -- Fin de semana
                CASE WHEN DATEPART(WEEKDAY, @FechaActual) IN (1, 7) THEN 1 ELSE 0 END,
                0 -- Por defecto no es festivo
            );
        END
        
        SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
    END
    
    PRINT 'Carga de DimTiempo completada. Registros procesados: ' + 
          CAST(DATEDIFF(DAY, @FechaInicio, @FechaFin) + 1 AS NVARCHAR(10));
END
GO

/*
================================================================================
PROCEDIMIENTO: CARGA DIMENSIÓN ESTUDIANTE (SCD TIPO 2)
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarDimEstudiante
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando carga de DimEstudiante con SCD Tipo 2';
    
    -- Cerrar registros que han cambiado (SCD Tipo 2)
    UPDATE DW.DimEstudiante 
    SET fecha_fin_vigencia = CAST(GETDATE() AS DATE),
        es_vigente = 0
    WHERE es_vigente = 1
    AND estudiante_id IN (
        SELECT e.estudiante_id
        FROM estudiante e
        INNER JOIN DW.DimEstudiante de ON e.estudiante_id = de.estudiante_id
        WHERE de.es_vigente = 1
        AND (
            e.nombre_completo != de.nombre_completo OR
            e.grado_id != de.grado_id OR
            e.estado != de.estado_actual OR
            e.institucion != ISNULL(de.institucion, '')
        )
    );
    
    -- Insertar nuevos registros y cambios
    INSERT INTO DW.DimEstudiante (
        estudiante_id, nombre_completo, documento_identidad,
        grado_id, grado_nombre, nivel_educativo, institucion,
        edad_ingreso, año_ingreso, estado_actual, es_activo,
        fecha_inicio_vigencia, es_vigente
    )
    SELECT 
        e.estudiante_id,
        e.nombre_completo,
        e.documento_identidad,
        e.grado_id,
        g.nombre,
        g.nivel_educativo,
        e.institucion,
        -- Calcular edad de ingreso aproximada
        CASE 
            WHEN e.fecha_nacimiento IS NOT NULL AND e.fecha_ingreso IS NOT NULL
            THEN DATEDIFF(YEAR, e.fecha_nacimiento, e.fecha_ingreso)
            ELSE NULL
        END,
        YEAR(e.fecha_ingreso),
        e.estado,
        CASE WHEN e.estado = 'ACTIVO' THEN 1 ELSE 0 END,
        CAST(GETDATE() AS DATE),
        1
    FROM estudiante e
    INNER JOIN grado g ON e.grado_id = g.grado_id
    WHERE NOT EXISTS (
        SELECT 1 FROM DW.DimEstudiante de 
        WHERE de.estudiante_id = e.estudiante_id 
        AND de.es_vigente = 1
        AND de.nombre_completo = e.nombre_completo
        AND de.grado_id = e.grado_id
        AND de.estado_actual = e.estado
        AND ISNULL(de.institucion, '') = ISNULL(e.institucion, '')
    );
    
    PRINT 'Carga de DimEstudiante completada';
END
GO

/*
================================================================================
PROCEDIMIENTO: CARGA DIMENSIÓN CURSO (SCD TIPO 2)
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarDimCurso
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando carga de DimCurso con SCD Tipo 2';
    
    -- Cerrar registros que han cambiado
    UPDATE DW.DimCurso 
    SET fecha_fin_vigencia = CAST(GETDATE() AS DATE),
        es_vigente = 0
    WHERE es_vigente = 1
    AND curso_id IN (
        SELECT c.curso_id
        FROM curso c
        INNER JOIN profesor p ON c.profesor_id = p.profesor_id
        INNER JOIN DW.DimCurso dc ON c.curso_id = dc.curso_id
        WHERE dc.es_vigente = 1
        AND (
            c.nombre != dc.nombre_curso OR
            c.profesor_id != dc.profesor_id OR
            p.nombre_completo != dc.profesor_nombre OR
            c.periodo_academico != dc.periodo_academico
        )
    );
    
    -- Insertar nuevos registros y cambios
    INSERT INTO DW.DimCurso (
        curso_id, nombre_curso, codigo_curso, area_conocimiento, materia,
        profesor_id, profesor_nombre, especialidad_profesor,
        creditos, horas_semanales, nivel_dificultad, periodo_academico,
        es_obligatorio, es_activo, fecha_inicio_vigencia, es_vigente
    )
    SELECT 
        c.curso_id,
        c.nombre,
        c.codigo_curso,
        -- Mapear especialidad a área de conocimiento
        CASE 
            WHEN p.especialidad LIKE '%Matemática%' THEN 'Matemáticas'
            WHEN p.especialidad LIKE '%Ciencia%' OR p.especialidad LIKE '%Biología%' THEN 'Ciencias'
            WHEN p.especialidad LIKE '%Español%' OR p.especialidad LIKE '%Literatura%' THEN 'Humanidades'
            WHEN p.especialidad LIKE '%Social%' OR p.especialidad LIKE '%Historia%' THEN 'Ciencias Sociales'
            WHEN p.especialidad LIKE '%Inglés%' OR p.especialidad LIKE '%Idioma%' THEN 'Idiomas'
            WHEN p.especialidad LIKE '%Arte%' THEN 'Artes'
            WHEN p.especialidad LIKE '%Física%' THEN 'Educación Física'
            ELSE 'Otras'
        END,
        c.nombre, -- Materia = nombre del curso
        c.profesor_id,
        p.nombre_completo,
        p.especialidad,
        c.creditos,
        c.horas_semanales,
        -- Determinar nivel de dificultad por créditos
        CASE 
            WHEN c.creditos <= 2 THEN 'Básico'
            WHEN c.creditos <= 4 THEN 'Intermedio'
            ELSE 'Avanzado'
        END,
        c.periodo_academico,
        1, -- Por defecto obligatorio
        CASE WHEN c.estado = 'ACTIVO' THEN 1 ELSE 0 END,
        CAST(GETDATE() AS DATE),
        1
    FROM curso c
    INNER JOIN profesor p ON c.profesor_id = p.profesor_id
    WHERE NOT EXISTS (
        SELECT 1 FROM DW.DimCurso dc 
        WHERE dc.curso_id = c.curso_id 
        AND dc.es_vigente = 1
        AND dc.nombre_curso = c.nombre
        AND dc.profesor_id = c.profesor_id
        AND dc.periodo_academico = c.periodo_academico
    );
    
    PRINT 'Carga de DimCurso completada';
END
GO/
*
================================================================================
PROCEDIMIENTO: CARGA DIMENSIÓN CONCEPTO PAGO
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarDimConceptoPago
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando carga de DimConceptoPago';
    
    -- Cerrar registros que han cambiado
    UPDATE DW.DimConceptoPago 
    SET fecha_fin_vigencia = CAST(GETDATE() AS DATE),
        es_vigente = 0
    WHERE es_vigente = 1
    AND concepto_pago_id IN (
        SELECT cp.concepto_pago_id
        FROM concepto_pago cp
        INNER JOIN DW.DimConceptoPago dcp ON cp.concepto_pago_id = dcp.concepto_pago_id
        WHERE dcp.es_vigente = 1
        AND (
            cp.nombre != dcp.nombre_concepto OR
            cp.tipo_concepto != dcp.tipo_concepto OR
            cp.monto_base != dcp.monto_base
        )
    );
    
    -- Insertar nuevos registros y cambios
    INSERT INTO DW.DimConceptoPago (
        concepto_pago_id, nombre_concepto, descripcion, tipo_concepto,
        categoria_financiera, monto_base, es_obligatorio, permite_fraccionamiento,
        es_activo, fecha_inicio_vigencia, es_vigente
    )
    SELECT 
        cp.concepto_pago_id,
        cp.nombre,
        cp.descripcion,
        cp.tipo_concepto,
        -- Categorizar según tipo y obligatoriedad
        CASE 
            WHEN cp.obligatorio = 1 THEN 'OBLIGATORIO'
            WHEN cp.tipo_concepto IN ('EXAMEN', 'CERTIFICADO') THEN 'EXTRAORDINARIO'
            ELSE 'OPCIONAL'
        END,
        cp.monto_base,
        cp.obligatorio,
        CASE WHEN cp.tipo_concepto = 'MENSUALIDAD' THEN 1 ELSE 0 END,
        cp.activo,
        CAST(GETDATE() AS DATE),
        1
    FROM concepto_pago cp
    WHERE NOT EXISTS (
        SELECT 1 FROM DW.DimConceptoPago dcp 
        WHERE dcp.concepto_pago_id = cp.concepto_pago_id 
        AND dcp.es_vigente = 1
        AND dcp.nombre_concepto = cp.nombre
        AND dcp.tipo_concepto = cp.tipo_concepto
        AND dcp.monto_base = cp.monto_base
    );
    
    PRINT 'Carga de DimConceptoPago completada';
END
GO

/*
================================================================================
PROCEDIMIENTO: CARGA DIMENSIÓN USUARIO
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarDimUsuario
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Iniciando carga de DimUsuario';
    
    -- Cerrar registros que han cambiado
    UPDATE DW.DimUsuario 
    SET fecha_fin_vigencia = CAST(GETDATE() AS DATE),
        es_vigente = 0
    WHERE es_vigente = 1
    AND usuario_id IN (
        SELECT u.usuario_id
        FROM usuario u
        INNER JOIN usuario_rol ur ON u.usuario_id = ur.usuario_id
        INNER JOIN rol r ON ur.rol_id = r.rol_id
        INNER JOIN DW.DimUsuario du ON u.usuario_id = du.usuario_id
        WHERE du.es_vigente = 1
        AND (
            u.nombre_completo != du.nombre_completo OR
            r.nombre != du.rol_nombre OR
            r.nivel_acceso != du.nivel_acceso
        )
    );
    
    -- Insertar nuevos registros y cambios
    INSERT INTO DW.DimUsuario (
        usuario_id, nombre_usuario, nombre_completo, rol_nombre,
        nivel_acceso, departamento, es_activo, fecha_inicio_vigencia, es_vigente
    )
    SELECT 
        u.usuario_id,
        u.nombre_usuario,
        u.nombre_completo,
        r.nombre,
        r.nivel_acceso,
        -- Mapear rol a departamento
        CASE 
            WHEN r.nombre LIKE '%Académico%' OR r.nombre = 'Profesor' THEN 'Académico'
            WHEN r.nombre = 'Secretario' THEN 'Financiero'
            WHEN r.nombre = 'Administrador' THEN 'Administrativo'
            ELSE 'General'
        END,
        u.activo,
        CAST(GETDATE() AS DATE),
        1
    FROM usuario u
    INNER JOIN usuario_rol ur ON u.usuario_id = ur.usuario_id AND ur.activo = 1
    INNER JOIN rol r ON ur.rol_id = r.rol_id AND r.activo = 1
    WHERE NOT EXISTS (
        SELECT 1 FROM DW.DimUsuario du 
        WHERE du.usuario_id = u.usuario_id 
        AND du.es_vigente = 1
        AND du.nombre_completo = u.nombre_completo
        AND du.rol_nombre = r.nombre
        AND du.nivel_acceso = r.nivel_acceso
    );
    
    PRINT 'Carga de DimUsuario completada';
END
GO

/*
================================================================================
PROCEDIMIENTO: CARGA TABLA DE HECHOS - CALIFICACIONES
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarFactCalificaciones
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Por defecto, cargar último mes
    IF @FechaInicio IS NULL SET @FechaInicio = DATEADD(MONTH, -1, GETDATE());
    IF @FechaFin IS NULL SET @FechaFin = GETDATE();
    
    PRINT 'Iniciando carga de FactCalificaciones desde ' + CAST(@FechaInicio AS NVARCHAR(10));
    
    INSERT INTO DW.FactCalificaciones (
        tiempo_key, estudiante_key, curso_key, calificacion_id, asignacion_curso_id,
        nota_parcial1, nota_parcial2, nota_parcial3, nota_final,
        promedio_parciales, diferencia_final_promedio,
        es_aprobado, es_excelente, es_bueno, es_regular, requiere_refuerzo,
        dias_para_calificar
    )
    SELECT 
        dt.tiempo_key,
        de.estudiante_key,
        dc.curso_key,
        cal.calificacion_id,
        cal.asignacion_curso_id,
        cal.nota_parcial1,
        cal.nota_parcial2,
        cal.nota_parcial3,
        cal.nota_final,
        -- Calcular promedio de parciales
        (ISNULL(cal.nota_parcial1, 0) + ISNULL(cal.nota_parcial2, 0) + ISNULL(cal.nota_parcial3, 0)) / 
        CASE 
            WHEN cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial2 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL THEN 3
            WHEN (cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial2 IS NOT NULL) OR 
                 (cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL) OR 
                 (cal.nota_parcial2 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL) THEN 2
            WHEN cal.nota_parcial1 IS NOT NULL OR cal.nota_parcial2 IS NOT NULL OR cal.nota_parcial3 IS NOT NULL THEN 1
            ELSE 1
        END,
        -- Diferencia entre nota final y promedio de parciales
        cal.nota_final - (ISNULL(cal.nota_parcial1, 0) + ISNULL(cal.nota_parcial2, 0) + ISNULL(cal.nota_parcial3, 0)) / 
        CASE 
            WHEN cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial2 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL THEN 3
            WHEN (cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial2 IS NOT NULL) OR 
                 (cal.nota_parcial1 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL) OR 
                 (cal.nota_parcial2 IS NOT NULL AND cal.nota_parcial3 IS NOT NULL) THEN 2
            WHEN cal.nota_parcial1 IS NOT NULL OR cal.nota_parcial2 IS NOT NULL OR cal.nota_parcial3 IS NOT NULL THEN 1
            ELSE 1
        END,
        -- Indicadores de rendimiento
        CASE WHEN cal.nota_final >= 70 THEN 1 ELSE 0 END, -- es_aprobado
        CASE WHEN cal.nota_final >= 90 THEN 1 ELSE 0 END, -- es_excelente
        CASE WHEN cal.nota_final >= 80 AND cal.nota_final < 90 THEN 1 ELSE 0 END, -- es_bueno
        CASE WHEN cal.nota_final >= 70 AND cal.nota_final < 80 THEN 1 ELSE 0 END, -- es_regular
        CASE WHEN cal.nota_final < 70 THEN 1 ELSE 0 END, -- requiere_refuerzo
        -- Días para calificar
        DATEDIFF(DAY, ac.fecha_asignacion, cal.fecha_calificacion)
    FROM calificacion cal
    INNER JOIN asignacion_curso ac ON cal.asignacion_curso_id = ac.asignacion_curso_id
    INNER JOIN DW.DimTiempo dt ON dt.fecha = cal.fecha_calificacion
    INNER JOIN DW.DimEstudiante de ON de.estudiante_id = ac.estudiante_id AND de.es_vigente = 1
    INNER JOIN DW.DimCurso dc ON dc.curso_id = ac.curso_id AND dc.es_vigente = 1
    WHERE cal.fecha_calificacion BETWEEN @FechaInicio AND @FechaFin
    AND NOT EXISTS (
        SELECT 1 FROM DW.FactCalificaciones fc 
        WHERE fc.calificacion_id = cal.calificacion_id
    );
    
    PRINT 'Carga de FactCalificaciones completada. Registros: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
END
GO

/*
================================================================================
PROCEDIMIENTO: CARGA TABLA DE HECHOS - PAGOS
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargarFactPagos
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Por defecto, cargar último mes
    IF @FechaInicio IS NULL SET @FechaInicio = DATEADD(MONTH, -1, GETDATE());
    IF @FechaFin IS NULL SET @FechaFin = GETDATE();
    
    PRINT 'Iniciando carga de FactPagos desde ' + CAST(@FechaInicio AS NVARCHAR(10));
    
    INSERT INTO DW.FactPagos (
        tiempo_key, estudiante_key, concepto_pago_key, usuario_key, pago_id,
        monto_pagado, monto_base_concepto, diferencia_monto, metodo_pago, numero_recibo,
        es_pago_completo, es_pago_parcial, es_pago_excedente, es_pago_puntual,
        dia_mes_pago, es_inicio_mes, es_medio_mes, es_fin_mes
    )
    SELECT 
        dt.tiempo_key,
        de.estudiante_key,
        dcp.concepto_pago_key,
        du.usuario_key,
        p.pago_id,
        p.monto,
        dcp.monto_base,
        p.monto - dcp.monto_base, -- diferencia_monto
        p.metodo_pago,
        p.numero_recibo,
        -- Indicadores de pago
        CASE WHEN p.monto = dcp.monto_base THEN 1 ELSE 0 END, -- es_pago_completo
        CASE WHEN p.monto < dcp.monto_base THEN 1 ELSE 0 END, -- es_pago_parcial
        CASE WHEN p.monto > dcp.monto_base THEN 1 ELSE 0 END, -- es_pago_excedente
        CASE WHEN DAY(p.fecha_pago) <= 5 THEN 1 ELSE 0 END, -- es_pago_puntual (primeros 5 días)
        -- Métricas de tiempo
        DAY(p.fecha_pago), -- dia_mes_pago
        CASE WHEN DAY(p.fecha_pago) <= 10 THEN 1 ELSE 0 END, -- es_inicio_mes
        CASE WHEN DAY(p.fecha_pago) BETWEEN 11 AND 20 THEN 1 ELSE 0 END, -- es_medio_mes
        CASE WHEN DAY(p.fecha_pago) >= 21 THEN 1 ELSE 0 END -- es_fin_mes
    FROM pago p
    INNER JOIN DW.DimTiempo dt ON dt.fecha = p.fecha_pago
    INNER JOIN DW.DimEstudiante de ON de.estudiante_id = p.estudiante_id AND de.es_vigente = 1
    INNER JOIN DW.DimConceptoPago dcp ON dcp.concepto_pago_id = p.concepto_pago_id AND dcp.es_vigente = 1
    INNER JOIN DW.DimUsuario du ON du.usuario_id = p.usuario_id AND du.es_vigente = 1
    WHERE p.fecha_pago BETWEEN @FechaInicio AND @FechaFin
    AND p.estado_pago = 'COMPLETADO'
    AND NOT EXISTS (
        SELECT 1 FROM DW.FactPagos fp 
        WHERE fp.pago_id = p.pago_id
    );
    
    PRINT 'Carga de FactPagos completada. Registros: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
END
GO

/*
================================================================================
PROCEDIMIENTO MAESTRO: CARGA COMPLETA DEL DATA WAREHOUSE
================================================================================
*/

CREATE OR ALTER PROCEDURE DW.sp_CargaCompletaDataWarehouse
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @InicioEjecucion DATETIME2 = GETDATE();
    
    PRINT '================================================================================';
    PRINT 'INICIANDO CARGA COMPLETA DEL DATA WAREHOUSE - ' + CAST(@InicioEjecucion AS NVARCHAR(30));
    PRINT '================================================================================';
    
    BEGIN TRY
        -- 1. Cargar dimensiones
        PRINT 'FASE 1: Cargando dimensiones...';
        
        EXEC DW.sp_CargarDimTiempo @FechaInicio, @FechaFin;
        EXEC DW.sp_CargarDimEstudiante;
        EXEC DW.sp_CargarDimCurso;
        EXEC DW.sp_CargarDimConceptoPago;
        EXEC DW.sp_CargarDimUsuario;
        
        -- 2. Cargar tablas de hechos
        PRINT 'FASE 2: Cargando tablas de hechos...';
        
        EXEC DW.sp_CargarFactCalificaciones @FechaInicio, @FechaFin;
        EXEC DW.sp_CargarFactPagos @FechaInicio, @FechaFin;
        
        DECLARE @FinEjecucion DATETIME2 = GETDATE();
        DECLARE @TiempoEjecucion INT = DATEDIFF(SECOND, @InicioEjecucion, @FinEjecucion);
        
        PRINT '================================================================================';
        PRINT 'CARGA COMPLETA FINALIZADA EXITOSAMENTE';
        PRINT 'Tiempo de ejecución: ' + CAST(@TiempoEjecucion AS NVARCHAR(10)) + ' segundos';
        PRINT 'Fecha fin: ' + CAST(@FinEjecucion AS NVARCHAR(30));
        PRINT '================================================================================';
        
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN LA CARGA DEL DATA WAREHOUSE:';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
        PRINT 'Procedimiento: ' + ISNULL(ERROR_PROCEDURE(), 'Principal');
        
        -- Re-lanzar el error
        THROW;
    END CATCH
END
GO

PRINT 'Procedimientos ETL creados exitosamente';
PRINT 'Ejecutar: EXEC DW.sp_CargaCompletaDataWarehouse para cargar el Data Warehouse';
GO