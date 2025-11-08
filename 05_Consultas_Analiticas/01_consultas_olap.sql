-- Consultas OLAP para analisis de datos
USE BD2_Curso2025;
GO

-- Analisis de rendimiento academico por tiempo
-- jerarquias: año > trimestre > mes
WITH RendimientoTemporal AS (
    -- metricas base por fecha
    SELECT 
        dt.año,
        dt.trimestre,
        dt.nombre_trimestre,
        dt.mes,
        dt.nombre_mes,
        dt.periodo_academico,
        
        COUNT(fc.calificacion_key) as total_calificaciones,
        AVG(fc.nota_final) as promedio_general,
        
        SUM(CASE WHEN fc.es_excelente = 1 THEN 1 ELSE 0 END) as estudiantes_excelentes,
        SUM(CASE WHEN fc.es_bueno = 1 THEN 1 ELSE 0 END) as estudiantes_buenos,
        SUM(CASE WHEN fc.es_regular = 1 THEN 1 ELSE 0 END) as estudiantes_regulares,
        SUM(CASE WHEN fc.requiere_refuerzo = 1 THEN 1 ELSE 0 END) as estudiantes_refuerzo,
        
        CAST(SUM(CASE WHEN fc.es_aprobado = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as tasa_aprobacion,
        AVG(CAST(fc.dias_para_calificar AS FLOAT)) as promedio_dias_calificar,
        de.nivel_educativo
        
    FROM DW.FactCalificaciones fc
    INNER JOIN DW.DimTiempo dt ON fc.tiempo_key = dt.tiempo_key
    INNER JOIN DW.DimEstudiante de ON fc.estudiante_key = de.estudiante_key
    WHERE dt.año >= 2024
    AND de.es_vigente = 1
    GROUP BY 
        dt.año, dt.trimestre, dt.nombre_trimestre, dt.mes, dt.nombre_mes, 
        dt.periodo_academico, de.nivel_educativo
),
PromediosComparativos AS (
    -- promedios y rankings
    SELECT *,
        AVG(promedio_general) OVER (
            PARTITION BY nivel_educativo 
            ORDER BY año, mes 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as promedio_movil_3meses,
        
        ROW_NUMBER() OVER (
            PARTITION BY año, nivel_educativo 
            ORDER BY promedio_general DESC
        ) as ranking_mes_año,
        
        LAG(promedio_general, 1) OVER (
            PARTITION BY nivel_educativo 
            ORDER BY año, mes
        ) as promedio_mes_anterior,
        
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
SELECT 
    año as 'Año',
    nombre_trimestre as 'Trimestre',
    nombre_mes as 'Mes',
    periodo_academico as 'Período Académico',
    nivel_educativo as 'Nivel Educativo',
    
    total_calificaciones as 'Total Calificaciones',
    promedio_general as 'Promedio General',
    tasa_aprobacion as 'Tasa Aprobación (%)',
    
    estudiantes_excelentes as 'Excelentes (>=90)',
    estudiantes_buenos as 'Buenos (80-89)',
    estudiantes_regulares as 'Regulares (70-79)',
    estudiantes_refuerzo as 'Requieren Refuerzo (<70)',
    
    promedio_movil_3meses as 'Promedio Móvil 3M',
    variacion_porcentual as 'Variación % vs Mes Anterior',
    ranking_mes_año as 'Ranking en el Año',
    
    promedio_dias_calificar as 'Días Promedio Calificar',
    
    CASE 
        WHEN tasa_aprobacion < 70 THEN 'CRÍTICO'
        WHEN tasa_aprobacion < 80 THEN 'ATENCIÓN'
        ELSE 'NORMAL'
    END as 'Estado Rendimiento',
    
    CASE 
        WHEN promedio_dias_calificar > 15 THEN 'RETRASO'
        WHEN promedio_dias_calificar > 10 THEN 'LENTO'
        ELSE 'OPORTUNO'
    END as 'Estado Calificación'

FROM PromediosComparativos
WHERE total_calificaciones >= 5
ORDER BY año DESC, mes DESC, nivel_educativo, promedio_general DESC;

PRINT 'Consulta 1: Rendimiento academico completada';
GO

-- Analisis financiero multidimensional
WITH AnalisisFinanciero AS (
    SELECT 
        dt.año,
        dt.trimestre_año,
        dt.mes_año,
        dt.nombre_mes,
        dt.es_inicio_mes,
        dt.es_medio_mes,
        dt.es_fin_mes,
        
        dcp.tipo_concepto,
        dcp.categoria_financiera,
        dcp.nombre_concepto,
        
        de.nivel_educativo,
        de.grado_nombre,
        de.institucion,
        
        du.departamento,
        du.rol_nombre,
        
        fp.monto_pagado,
        fp.monto_base_concepto,
        fp.diferencia_monto,
        fp.metodo_pago,
        
        fp.es_pago_completo,
        fp.es_pago_parcial,
        fp.es_pago_excedente,
        fp.es_pago_puntual,
        
        CASE 
            WHEN fp.monto_base_concepto > 0 
            THEN (fp.monto_pagado * 100.0 / fp.monto_base_concepto)
            ELSE 100
        END as porcentaje_pago
        
    FROM DW.FactPagos fp
    INNER JOIN DW.DimTiempo dt ON fp.tiempo_key = dt.tiempo_key
    INNER JOIN DW.DimConceptoPago dcp ON fp.concepto_pago_key = dcp.concepto_pago_key
    INNER JOIN DW.DimEstudiante de ON fp.estudiante_key = de.estudiante_key
    INNER JOIN DW.DimUsuario du ON fp.usuario_key = du.usuario_key
    WHERE dt.año >= 2024
    AND dcp.es_vigente = 1
    AND de.es_vigente = 1
),
MetricasAgregadas AS (
    SELECT 
        año,
        trimestre_año,
        mes_año,
        nombre_mes,
        tipo_concepto,
        categoria_financiera,
        nivel_educativo,
        metodo_pago,
        
        COUNT(*) as total_transacciones,
        COUNT(DISTINCT CASE WHEN es_pago_completo = 1 THEN 1 END) as pagos_completos,
        COUNT(DISTINCT CASE WHEN es_pago_parcial = 1 THEN 1 END) as pagos_parciales,
        COUNT(DISTINCT CASE WHEN es_pago_puntual = 1 THEN 1 END) as pagos_puntuales,
        
        SUM(monto_pagado) as ingresos_totales,
        AVG(monto_pagado) as promedio_pago,
        MIN(monto_pagado) as pago_minimo,
        MAX(monto_pagado) as pago_maximo,
        
        AVG(porcentaje_pago) as porcentaje_cumplimiento_promedio,
        SUM(CASE WHEN es_pago_puntual = 1 THEN monto_pagado ELSE 0 END) as ingresos_puntuales,
        
        SUM(CASE WHEN es_inicio_mes = 1 THEN monto_pagado ELSE 0 END) as ingresos_inicio_mes,
        SUM(CASE WHEN es_medio_mes = 1 THEN monto_pagado ELSE 0 END) as ingresos_medio_mes,
        SUM(CASE WHEN es_fin_mes = 1 THEN monto_pagado ELSE 0 END) as ingresos_fin_mes
        
    FROM AnalisisFinanciero
    GROUP BY 
        año, trimestre_año, mes_año, nombre_mes, tipo_concepto, 
        categoria_financiera, nivel_educativo, metodo_pago
),
AnalisisComparativo AS (
    SELECT *,
        SUM(ingresos_totales) OVER (PARTITION BY año, mes_año) as ingresos_mes_total,
        CAST(ingresos_totales * 100.0 / SUM(ingresos_totales) OVER (PARTITION BY año, mes_año) AS DECIMAL(5,2)) as participacion_mes,
        
        LAG(ingresos_totales, 1) OVER (
            PARTITION BY tipo_concepto, nivel_educativo, metodo_pago 
            ORDER BY año, mes_año
        ) as ingresos_mes_anterior,
        
        CASE 
            WHEN LAG(ingresos_totales, 1) OVER (
                PARTITION BY tipo_concepto, nivel_educativo, metodo_pago 
                ORDER BY año, mes_año
            ) > 0 THEN
                CAST((ingresos_totales - LAG(ingresos_totales, 1) OVER (
                    PARTITION BY tipo_concepto, nivel_educativo, metodo_pago 
                    ORDER BY año, mes_año
                )) * 100.0 / LAG(ingresos_totales, 1) OVER (
                    PARTITION BY tipo_concepto, nivel_educativo, metodo_pago 
                    ORDER BY año, mes_año
                ) AS DECIMAL(5,2))
            ELSE NULL
        END as crecimiento_mensual,
        
        ROW_NUMBER() OVER (
            PARTITION BY año 
            ORDER BY ingresos_totales DESC
        ) as ranking_ingresos_año
        
    FROM MetricasAgregadas
)
SELECT 
    año as 'Año',
    trimestre_año as 'Trimestre',
    nombre_mes as 'Mes',
    tipo_concepto as 'Tipo Concepto',
    categoria_financiera as 'Categoría',
    nivel_educativo as 'Nivel Educativo',
    metodo_pago as 'Método Pago',
    
    total_transacciones as 'Total Transacciones',
    pagos_completos as 'Pagos Completos',
    pagos_parciales as 'Pagos Parciales',
    
    FORMAT(ingresos_totales, 'C', 'es-CO') as 'Ingresos Totales',
    FORMAT(promedio_pago, 'C', 'es-CO') as 'Promedio por Pago',
    
    CAST(pagos_puntuales * 100.0 / total_transacciones AS DECIMAL(5,2)) as 'Puntualidad (%)',
    porcentaje_cumplimiento_promedio as 'Cumplimiento Promedio (%)',
    participacion_mes as 'Participación Mes (%)',
    
    crecimiento_mensual as 'Crecimiento Mensual (%)',
    ranking_ingresos_año as 'Ranking Año',
    
    CAST(ingresos_inicio_mes * 100.0 / ingresos_totales AS DECIMAL(5,2)) as '% Inicio Mes',
    CAST(ingresos_medio_mes * 100.0 / ingresos_totales AS DECIMAL(5,2)) as '% Medio Mes',
    CAST(ingresos_fin_mes * 100.0 / ingresos_totales AS DECIMAL(5,2)) as '% Fin Mes',
    
    CASE 
        WHEN pagos_puntuales * 100.0 / total_transacciones >= 80 THEN 'EXCELENTE'
        WHEN pagos_puntuales * 100.0 / total_transacciones >= 60 THEN 'BUENO'
        ELSE 'MEJORAR'
    END as 'Estado Puntualidad',
    
    CASE 
        WHEN crecimiento_mensual >= 10 THEN 'CRECIENDO'
        WHEN crecimiento_mensual >= 0 THEN 'ESTABLE'
        WHEN crecimiento_mensual >= -10 THEN 'DECLINANDO'
        ELSE 'CRÍTICO'
    END as 'Tendencia'

FROM AnalisisComparativo
WHERE total_transacciones >= 3
ORDER BY año DESC, ingresos_totales DESC, tipo_concepto, nivel_educativo;

PRINT 'Consulta 2: Analisis financiero completada';
GO

/*

Analisis de desempeño de profesores
*/

WITH DesempenoDocente AS (
    SELECT 
        -- Dimensiones del curso
        dc.area_conocimiento,
        dc.materia,
        dc.nombre_curso,
        dc.codigo_curso,
        dc.periodo_academico,
        
        -- Dimensiones del profesor
        dc.profesor_nombre,
        dc.especialidad_profesor,
        dc.creditos,
        dc.horas_semanales,
        dc.nivel_dificultad,
        
        -- Dimensiones del estudiante
        de.nivel_educativo,
        de.grado_nombre,
        
        -- Dimensiones temporales
        dt.año,
        dt.trimestre,
        dt.mes,
        
        -- Métricas de calificaciones
        fc.nota_final,
        fc.promedio_parciales,
        fc.es_aprobado,
        fc.es_excelente,
        fc.requiere_refuerzo,
        fc.dias_para_calificar,
        
        -- Métricas calculadas
        CASE 
            WHEN fc.promedio_parciales > 0 
            THEN fc.nota_final - fc.promedio_parciales 
            ELSE 0 
        END as mejora_final_vs_parciales
        
    FROM DW.FactCalificaciones fc
    INNER JOIN DW.DimCurso dc ON fc.curso_key = dc.curso_key
    INNER JOIN DW.DimEstudiante de ON fc.estudiante_key = de.estudiante_key
    INNER JOIN DW.DimTiempo dt ON fc.tiempo_key = dt.tiempo_key
    WHERE dc.es_vigente = 1
    AND de.es_vigente = 1
    AND dt.año >= 2024
),
MetricasProfesor AS (
    -- CTE para agregaciones por profesor
    SELECT 
        profesor_nombre,
        especialidad_profesor,
        area_conocimiento,
        periodo_academico,
        año,
        
        -- Métricas de carga académica
        COUNT(DISTINCT nombre_curso) as cursos_impartidos,
        COUNT(DISTINCT CONCAT(nombre_curso, grado_nombre)) as secciones_impartidas,
        COUNT(*) as total_estudiantes_atendidos,
        SUM(creditos) as creditos_totales,
        AVG(CAST(horas_semanales AS FLOAT)) as promedio_horas_semanales,
        
        -- Métricas de rendimiento estudiantil
        AVG(nota_final) as promedio_notas_estudiantes,
        CAST(SUM(CASE WHEN es_aprobado = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as tasa_aprobacion,
        CAST(SUM(CASE WHEN es_excelente = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as tasa_excelencia,
        CAST(SUM(CASE WHEN requiere_refuerzo = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) as tasa_refuerzo,
        
        -- Métricas de eficiencia docente
        AVG(CAST(dias_para_calificar AS FLOAT)) as promedio_dias_calificar,
        AVG(mejora_final_vs_parciales) as promedio_mejora_estudiantes,
        
        -- Distribución por nivel de dificultad
        AVG(CASE WHEN nivel_dificultad = 'Básico' THEN nota_final ELSE NULL END) as promedio_cursos_basicos,
        AVG(CASE WHEN nivel_dificultad = 'Intermedio' THEN nota_final ELSE NULL END) as promedio_cursos_intermedios,
        AVG(CASE WHEN nivel_dificultad = 'Avanzado' THEN nota_final ELSE NULL END) as promedio_cursos_avanzados,
        
        -- Métricas por nivel educativo
        COUNT(CASE WHEN nivel_educativo = 'Primaria' THEN 1 END) as estudiantes_primaria,
        COUNT(CASE WHEN nivel_educativo = 'Secundaria' THEN 1 END) as estudiantes_secundaria,
        COUNT(CASE WHEN nivel_educativo = 'Bachillerato' THEN 1 END) as estudiantes_bachillerato
        
    FROM DesempenoDocente
    GROUP BY 
        profesor_nombre, especialidad_profesor, area_conocimiento, periodo_academico, año
),
RankingProfesores AS (
    -- CTE para ranking y comparaciones
    SELECT *,
        -- Rankings por diferentes métricas
        ROW_NUMBER() OVER (ORDER BY tasa_aprobacion DESC, promedio_notas_estudiantes DESC) as ranking_aprobacion,
        ROW_NUMBER() OVER (ORDER BY tasa_excelencia DESC) as ranking_excelencia,
        ROW_NUMBER() OVER (ORDER BY promedio_dias_calificar ASC) as ranking_puntualidad,
        ROW_NUMBER() OVER (ORDER BY total_estudiantes_atendidos DESC) as ranking_carga_academica,
        ROW_NUMBER() OVER (ORDER BY promedio_mejora_estudiantes DESC) as ranking_mejora_estudiantes,
        
        -- Percentiles para clasificación
        NTILE(4) OVER (ORDER BY tasa_aprobacion) as cuartil_aprobacion,
        NTILE(4) OVER (ORDER BY tasa_excelencia) as cuartil_excelencia,
        NTILE(4) OVER (ORDER BY promedio_dias_calificar) as cuartil_puntualidad,
        
        -- Promedios generales para comparación
        AVG(tasa_aprobacion) OVER () as promedio_general_aprobacion,
        AVG(tasa_excelencia) OVER () as promedio_general_excelencia,
        AVG(promedio_dias_calificar) OVER () as promedio_general_dias_calificar,
        
        -- Índice de desempeño compuesto (0-100)
        CAST((
            (tasa_aprobacion * 0.4) + 
            (tasa_excelencia * 0.3) + 
            (CASE WHEN promedio_dias_calificar <= 7 THEN 100 
                  WHEN promedio_dias_calificar <= 14 THEN 80 
                  ELSE 60 END * 0.2) +
            (CASE WHEN promedio_mejora_estudiantes >= 5 THEN 100
                  WHEN promedio_mejora_estudiantes >= 0 THEN 80
                  ELSE 60 END * 0.1)
        ) AS DECIMAL(5,2)) as indice_desempeno_compuesto
        
    FROM MetricasProfesor
)

-- Consulta final con análisis completo de profesores
SELECT 
    -- Identificación del profesor
    profesor_nombre as 'Profesor',
    especialidad_profesor as 'Especialidad',
    area_conocimiento as 'Área Conocimiento',
    periodo_academico as 'Período',
    
    -- Métricas de carga académica
    cursos_impartidos as 'Cursos',
    secciones_impartidas as 'Secciones',
    total_estudiantes_atendidos as 'Total Estudiantes',
    creditos_totales as 'Créditos Totales',
    promedio_horas_semanales as 'Horas/Semana Prom.',
    
    -- Métricas de rendimiento (formateadas)
    promedio_notas_estudiantes as 'Promedio Notas',
    tasa_aprobacion as 'Tasa Aprobación (%)',
    tasa_excelencia as 'Tasa Excelencia (%)',
    tasa_refuerzo as 'Requieren Refuerzo (%)',
    
    -- Métricas de eficiencia
    promedio_dias_calificar as 'Días Prom. Calificar',
    promedio_mejora_estudiantes as 'Mejora Prom. Estudiantes',
    
    -- Distribución por dificultad
    promedio_cursos_basicos as 'Prom. Básicos',
    promedio_cursos_intermedios as 'Prom. Intermedios',
    promedio_cursos_avanzados as 'Prom. Avanzados',
    
    -- Distribución por nivel educativo
    estudiantes_primaria as 'Est. Primaria',
    estudiantes_secundaria as 'Est. Secundaria',
    estudiantes_bachillerato as 'Est. Bachillerato',
    
    -- Rankings y comparaciones
    ranking_aprobacion as 'Rank Aprobación',
    ranking_excelencia as 'Rank Excelencia',
    ranking_puntualidad as 'Rank Puntualidad',
    indice_desempeno_compuesto as 'Índice Desempeño',
    
    -- Clasificaciones por cuartiles
    CASE cuartil_aprobacion
        WHEN 4 THEN ' TOP 25%'
        WHEN 3 THEN ' ALTO'
        WHEN 2 THEN ' MEDIO'
        ELSE ' BAJO 25%'
    END as 'Nivel Aprobación',
    
    CASE cuartil_excelencia
        WHEN 4 THEN ' EXCELENTE'
        WHEN 3 THEN ' MUY BUENO'
        WHEN 2 THEN ' BUENO'
        ELSE ' REGULAR'
    END as 'Nivel Excelencia',
    
    -- Indicadores de alerta y reconocimiento
    CASE 
        WHEN tasa_aprobacion >= promedio_general_aprobacion + 10 THEN ' DESTACADO'
        WHEN tasa_aprobacion >= promedio_general_aprobacion THEN ' SOBRE PROMEDIO'
        WHEN tasa_aprobacion >= promedio_general_aprobacion - 10 THEN ' BAJO PROMEDIO'
        ELSE ' REQUIERE ATENCIÓN'
    END as 'Estado Rendimiento',
    
    CASE 
        WHEN promedio_dias_calificar <= 7 THEN ' MUY RÁPIDO'
        WHEN promedio_dias_calificar <= 14 THEN ' OPORTUNO'
        WHEN promedio_dias_calificar <= 21 THEN ' LENTO'
        ELSE ' MUY LENTO'
    END as 'Estado Puntualidad',
    
    -- Recomendaciones automáticas
    CASE 
        WHEN indice_desempeno_compuesto >= 85 THEN ' MENTOR POTENCIAL'
        WHEN indice_desempeno_compuesto >= 70 THEN ' BUEN DESEMPEÑO'
        WHEN indice_desempeno_compuesto >= 60 THEN ' NECESITA APOYO'
        ELSE ' REQUIERE INTERVENCIÓN'
    END as 'Recomendación'

FROM RankingProfesores
WHERE total_estudiantes_atendidos >= 5 -- Filtrar profesores con carga mínima
ORDER BY indice_desempeno_compuesto DESC, tasa_aprobacion DESC, profesor_nombre;

PRINT 'Consulta OLAP 3: Análisis de Desempeño Docente completada';
PRINT 'Jerarquías: Profesor (Especialidad>Profesor>Curso), Académica (Área>Materia)';
PRINT 'Métricas: Rendimiento, carga académica, eficiencia, rankings y recomendaciones';

/*
================================================================================
VISTA RESUMEN: DASHBOARD EJECUTIVO CON KPIS PRINCIPALES
================================================================================
Propósito: Vista consolidada para dashboard ejecutivo con KPIs críticos
Actualización: Datos en tiempo real del sistema transaccional y analítico
*/

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
PRINT '2. Análisis Financiero Multidimensional con Drill-Down';
PRINT '3. Análisis Comparativo de Profesores y Cursos';
PRINT '4. Vista Dashboard Ejecutivo (vw_DashboardEjecutivo)';
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