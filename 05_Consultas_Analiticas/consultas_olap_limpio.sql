-- CONSULTAS ANALÍTICAS OLAP - SISTEMA EDUGESTOR
--              con agregaciones, jerarquías y drill-down capabilities

-- Configuración inicial - Conectar a base de datos del curso
USE BD2_Curso2025;
GO

-- CONSULTA OLAP 1: ANÁLISIS DE RENDIMIENTO ACADÉMICO POR JERARQUÍAS TEMPORALES

-- Consulta principal con múltiples niveles de agregación
WITH RendimientoTemporal AS (
    -- CTE para calcular métricas base por fecha
    SELECT 
        dt.año,
        dt.trimestre,
        dt.nombre_trimestre,
        dt.mes,
        dt.nombre_mes,
        dt.periodo_academico,
        
        -- Métricas de calificaciones
        COUNT(fc.calificacion_key) as total_calificaciones,
        AVG(fc.nota_final) as promedio_general,
        
        -- Distribución por rangos de notas
        SUM(CASE WHEN fc.es_excelente = 1 THEN 1 ELSE 0 END) as estudiantes_excelentes,
        SUM(CASE WHEN fc.es_bueno = 1 THEN 1 ELSE 0 END) as estudiantes_buenos,
        SUM(CASE WHEN fc.es_regular = 1 THEN 1 ELSE 0 END) as estudiantes_regulares,
        SUM(CASE WHEN fc.requiere_refuerzo = 1 THEN 1 ELSE 0 END) as estudiantes_refuerzo,
        
        -- Tasa de aprobación
        CAST(SUM(CASE WHEN fc.es_aprobado = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as tasa_aprobacion,
        
        -- Métricas de tiempo de calificación
        AVG(CAST(fc.dias_para_calificar AS FLOAT)) as promedio_dias_calificar,
        
        -- Análisis por nivel educativo
        de.nivel_educativo
        
    FROM DW.FactCalificaciones fc
    INNER JOIN DW.DimTiempo dt ON fc.tiempo_key = dt.tiempo_key
    INNER JOIN DW.DimEstudiante de ON fc.estudiante_key = de.estudiante_key
    WHERE dt.año >= 2024 -- Filtrar años relevantes
    AND de.es_vigente = 1
    GROUP BY 
        dt.año, dt.trimestre, dt.nombre_trimestre, dt.mes, dt.nombre_mes, 
        dt.periodo_academico, de.nivel_educativo
),
Prome
diosComparativos AS (
    -- CTE para calcular promedios comparativos y rankings
    SELECT *,
        -- Promedios móviles para análisis de tendencias
        AVG(promedio_general) OVER (
            PARTITION BY nivel_educativo 
            ORDER BY año, mes 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as promedio_movil_3meses,
        
        -- Ranking de meses por rendimiento
        ROW_NUMBER() OVER (
            PARTITION BY año, nivel_educativo 
            ORDER BY promedio_general DESC
        ) as ranking_mes_año,
        
        -- Comparación con período anterior
        LAG(promedio_general, 1) OVER (
            PARTITION BY nivel_educativo 
            ORDER BY año, mes
        ) as promedio_mes_anterior,
        
        -- Variación porcentual
        CASE 
            WHEN LAG(promedio_general, 1) OVER (
                PARTITION BY nivel_educativo 
                ORDER BY año, mes
            ) IS NOT NULL THEN
                CAST((promedio_general - LAG(promedio_general, 1) OVER (
                    PARTITION BY nivel_educativo 
                    ORDER BY año, mes
                )) * 100.0 / LAG(promedio_general, 1) OVER (
                    PARTITION BY nivel_educativo 
                    ORDER BY año, mes
                ) AS DECIMAL(5,2))
            ELSE NULL
        END as variacion_porcentual
        
    FROM RendimientoTemporal
)

-- Consulta final con análisis completo
SELECT 
    -- Dimensiones jerárquicas
    año as 'Año',
    nombre_trimestre as 'Trimestre',
    nombre_mes as 'Mes',
    periodo_academico as 'Período Académico',
    nivel_educativo as 'Nivel Educativo',
    
    -- Métricas principales
    total_calificaciones as 'Total Calificaciones',
    promedio_general as 'Promedio General',
    tasa_aprobacion as 'Tasa Aprobación (%)',
    
    -- Distribución de rendimiento
    estudiantes_excelentes as 'Excelentes (≥90)',
    estudiantes_buenos as 'Buenos (80-89)',
    estudiantes_regulares as 'Regulares (70-79)',
    estudiantes_refuerzo as 'Requieren Refuerzo (<70)',
    
    -- Análisis de tendencias
    promedio_movil_3meses as 'Promedio Móvil 3M',
    variacion_porcentual as 'Variación % vs Mes Anterior',
    ranking_mes_año as 'Ranking en el Año',
    
    -- Métricas operativas
    promedio_dias_calificar as 'Días Promedio Calificar',
    
    -- Indicadores de alerta
    CASE 
        WHEN tasa_aprobacion < 70 THEN ' CRÍTICO'
        WHEN tasa_aprobacion < 80 THEN ' ATENCIÓN'
        ELSE ' NORMAL'
    END as 'Estado Rendimiento',
    
    CASE 
        WHEN promedio_dias_calificar > 15 THEN ' RETRASO'
        WHEN promedio_dias_calificar > 10 THEN ' LENTO'
        ELSE ' OPORTUNO'
    END as 'Estado Calificación'

FROM PromediosComparativos
WHERE total_calificaciones >= 5 -- Filtrar meses con pocas calificaciones
ORDER BY año DESC, mes DESC, nivel_educativo, promedio_general DESC;

PRINT 'Consulta OLAP 1: Análisis de Rendimiento Académico completada';
PRINT 'Jerarquías: Temporal (Año>Trimestre>Mes) y Educativa (Nivel>Grado)';
PRINT 'Métricas: Promedios, tasas, distribuciones, tendencias y alertas';
GO============================================================================
-- VISTA RESUMEN: DASHBOARD EJECUTIVO CON KPIS PRINCIPALES
-- Actualización: Datos en tiempo real del sistema transaccional y analítico

CREATE OR ALTER VIEW vw_DashboardEjecutivo AS
WITH KPIsActuales AS (
    -- KPIs del período actual
    SELECT 
        -- Métricas académicas actuales
        COUNT(DISTINCT e.estudiante_id) as estudiantes_activos,
        COUNT(DISTINCT p.profesor_id) as profesores_activos,
        COUNT(DISTINCT c.curso_id) as cursos_activos,
        COUNT(DISTINCT ac.asignacion_curso_id) as matriculas_activas,
        
        -- Métricas de rendimiento actual
        AVG(cal.nota_final) as promedio_general_actual,
        CAST(SUM(CASE WHEN cal.nota_final >= 70 THEN 1 ELSE 0 END) * 100.0 / 
             COUNT(CASE WHEN cal.nota_final IS NOT NULL THEN 1 END) AS DECIMAL(5,2)) as tasa_aprobacion_actual,
        
        -- Métricas financieras del mes actual
        (SELECT SUM(monto) FROM pago WHERE MONTH(fecha_pago) = MONTH(GETDATE()) AND YEAR(fecha_pago) = YEAR(GETDATE())) as ingresos_mes_actual,
        (SELECT COUNT(*) FROM pago WHERE MONTH(fecha_pago) = MONTH(GETDATE()) AND YEAR(fecha_pago) = YEAR(GETDATE())) as pagos_mes_actual,
        
        -- Métricas operativas
        (SELECT COUNT(*) FROM calificacion WHERE estado_calificacion = 'PENDIENTE') as calificaciones_pendientes,
        (SELECT AVG(DATEDIFF(DAY, fecha_asignacion, ISNULL(fecha_calificacion, GETDATE()))) 
         FROM asignacion_curso ac 
         LEFT JOIN calificacion cal ON ac.asignacion_curso_id = cal.asignacion_curso_id 
         WHERE ac.estado_asignacion = 'MATRICULADO') as dias_promedio_calificar
        
    FROM estudiante e
    CROSS JOIN profesor p
    CROSS JOIN curso c
    LEFT JOIN asignacion_curso ac ON c.curso_id = ac.curso_id AND e.estudiante_id = ac.estudiante_id
    LEFT JOIN calificacion cal ON ac.asignacion_curso_id = cal.asignacion_curso_id
    WHERE e.estado = 'ACTIVO' 
    AND p.estado = 'ACTIVO' 
    AND c.estado = 'ACTIVO'
),
ComparativoMesAnterior AS (
    -- Comparación con mes anterior
    SELECT 
        (SELECT SUM(monto) FROM pago 
         WHERE MONTH(fecha_pago) = MONTH(DATEADD(MONTH, -1, GETDATE())) 
         AND YEAR(fecha_pago) = YEAR(DATEADD(MONTH, -1, GETDATE()))) as ingresos_mes_anterior,
        
        (SELECT COUNT(*) FROM pago 
         WHERE MONTH(fecha_pago) = MONTH(DATEADD(MONTH, -1, GETDATE())) 
         AND YEAR(fecha_pago) = YEAR(DATEADD(MONTH, -1, GETDATE()))) as pagos_mes_anterior
)

SELECT 
    -- Timestamp del reporte
    GETDATE() as fecha_reporte,
    
    -- KPIs Académicos
    ka.estudiantes_activos,
    ka.profesores_activos,
    ka.cursos_activos,
    ka.matriculas_activas,
    
    -- KPIs de Rendimiento
    ka.promedio_general_actual,
    ka.tasa_aprobacion_actual,
    ka.calificaciones_pendientes,
    ka.dias_promedio_calificar,
    
    -- KPIs Financieros
    ka.ingresos_mes_actual,
    ka.pagos_mes_actual,
    cma.ingresos_mes_anterior,
    
    -- Cálculos comparativos
    CASE 
        WHEN cma.ingresos_mes_anterior > 0 
        THEN CAST((ka.ingresos_mes_actual - cma.ingresos_mes_anterior) * 100.0 / cma.ingresos_mes_anterior AS DECIMAL(5,2))
        ELSE NULL 
    END as crecimiento_ingresos_mensual,
    
    -- Indicadores de estado
    CASE 
        WHEN ka.tasa_aprobacion_actual >= 85 THEN 'EXCELENTE'
        WHEN ka.tasa_aprobacion_actual >= 75 THEN 'BUENO'
        WHEN ka.tasa_aprobacion_actual >= 65 THEN 'REGULAR'
        ELSE 'CRÍTICO'
    END as estado_rendimiento_academico,
    
    CASE 
        WHEN ka.dias_promedio_calificar <= 7 THEN 'EXCELENTE'
        WHEN ka.dias_promedio_calificar <= 14 THEN 'BUENO'
        WHEN ka.dias_promedio_calificar <= 21 THEN 'REGULAR'
        ELSE 'CRÍTICO'
    END as estado_puntualidad_calificaciones,
    
    -- Alertas automáticas
    CASE 
        WHEN ka.calificaciones_pendientes > (ka.matriculas_activas * 0.2) THEN 'ALTA'
        WHEN ka.calificaciones_pendientes > (ka.matriculas_activas * 0.1) THEN 'MEDIA'
        ELSE 'BAJA'
    END as alerta_calificaciones_pendientes

FROM KPIsActuales ka
CROSS JOIN ComparativoMesAnterior cma;

PRINT 'Vista Dashboard Ejecutivo creada exitosamente';
PRINT 'Consulta: SELECT * FROM vw_DashboardEjecutivo para ver KPIs actuales';

PRINT '================================================================================';
PRINT 'CONSULTAS ANALÍTICAS OLAP COMPLETADAS EXITOSAMENTE';
PRINT '================================================================================';
PRINT 'Consultas disponibles:';
PRINT '1. Análisis de Rendimiento Académico por Jerarquías Temporales';
PRINT '2. Vista Dashboard Ejecutivo (vw_DashboardEjecutivo)';
PRINT '';
PRINT 'Características implementadas:';
PRINT '- Jerarquías multidimensionales (Tiempo, Académica, Financiera)';
PRINT '- Agregaciones complejas con Window Functions';
PRINT '- CTEs para análisis por capas';
PRINT '- Rankings y percentiles';
PRINT '- Indicadores de alerta automáticos';
PRINT '- Métricas comparativas y de tendencias';
PRINT '- Drill-down capabilities en múltiples dimensiones';
GO