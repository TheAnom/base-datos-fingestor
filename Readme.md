# Proyecto Base de datos

Base de datos que integra procedimientos transaccionales y analiticos para la institución educativa.

## Permisos Requeridos
- Base de datos BD2_Curso2025 debe existir
- Permisos db_owner en BD2_Curso2025 
- Permisos de sistema para instalación

## PROCESO DE INSTALACIÓN

### MÉTODO 1: INSTALACIÓN AUTOMÁTICA

#### Paso 1: Preparación del Entorno
```sql
-- Verificar versión de SQL Server
SELECT @@VERSION;

-- Verificar permisos actuales
SELECT 
    SUSER_NAME() as 'Usuario Actual',
    IS_SRVROLEMEMBER('sysadmin') as 'Es Admin',
    SERVERPROPERTY('ProductVersion') as 'Versión SQL Server';
```

#### Paso 2: Descarga y Preparación
1. Descargar el proyecto
2. Extraer archivos en carpeta local
3. Verificar que estén todos los archivos .sql

#### Paso 3: Ejecución Automática
1. Abrir SQL Server Management Studio
2. Conectar al servidor con permisos de admin
3. Abrir el archivo INSTALACION_COMPLETA.sql
4. Ejecutar el script completo

#### Paso 4: Verificación
El script muestra:
- Base de datos conectada: BD2_Curso2025
- Tablas del sistema: 13
- Procedimientos almacenados: 15+
- Roles de seguridad: 6
- Índices optimizados: 10

---

### MÉTODO 2: INSTALACIÓN MANUAL

#### Fase 1: Modelo Transaccional (OLTP)
```sql
-- 1.1 Crear estructura base
:r "02_Modelo_ER\modelo_ER.sql"

-- 1.2 Cargar datos de prueba
:r "02_Modelo_ER\datos_prueba.sql"

-- 1.3 Verificar instalación
SELECT COUNT(*) as 'Estudiantes' FROM estudiante;
SELECT COUNT(*) as 'Profesores' FROM profesor;
SELECT COUNT(*) as 'Cursos' FROM curso;
```

Tiempo estimado: 2-3 minutos  
Resultado: 13 tablas creadas, datos de ejemplo cargados

#### Fase 2: Modelo Dimensional (OLAP)
```sql
-- 2.1 Crear esquema dimensional
:r "03_Modelo_OLAP\modelo_dimensional.sql"

-- 2.2 Configurar procesos ETL
:r "03_Modelo_OLAP\etl_carga_datawarehouse.sql"

-- 2.3 Cargar Data Warehouse inicial
EXEC DW.sp_CargaCompletaDataWarehouse 
    @FechaInicio = '2024-01-01',
    @FechaFin = '2024-12-31';
```

Tiempo estimado: 3-5 minutos  
Resultado: Esquema DW creado, dimensiones pobladas

#### Fase 3: Lógica Transaccional
```sql
-- 3.1 Crear procedimientos almacenados
:r "04_Transacciones\procedimientos_transaccionales.sql"

-- 3.2 Probar funcionalidad básica
DECLARE @Resultado NVARCHAR(500);
EXEC sp_MatricularEstudiante 
    @EstudianteId = 1, @CursoId = 1, @UsuarioId = 2,
    @Resultado = @Resultado OUTPUT;
PRINT @Resultado;
```

Tiempo estimado: 2-3 minutos  
Resultado: 4 procedimientos creados y funcionales

#### Fase 4: Consultas Analíticas
```sql
-- 4.1 Crear consultas OLAP y vistas
:r "05_Consultas_Analiticas\consultas_olap.sql"

-- 4.2 Verificar dashboard ejecutivo
SELECT * FROM vw_DashboardEjecutivo;
```

Tiempo estimado: 1-2 minutos  
Resultado: Dashboard funcional con datos en tiempo real

#### Fase 5: Sistema de Seguridad
```sql
-- 5.1 Configurar roles y permisos
:r "06_Seguridad\seguridad_roles.sql"

-- 5.2 Verificar matriz de permisos
EXEC sp_ReporteMatrizPermisos;
```

Tiempo estimado: 2-3 minutos  
Resultado: 6 roles creados, auditoría activa

#### Fase 6: Optimización y Rendimiento
```sql
-- 6.1 Crear índices y procedimientos de mantenimiento
:r "07_Optimizacion\optimizacion_rendimiento.sql"

-- 6.2 Ejecutar optimización inicial
EXEC sp_OptimizacionAutomatica 
    @ActualizarEstadisticas = 1,
    @MantenimientoIndices = 1,
    @EjecutarMantenimiento = 1,
    @GenerarReporte = 1;
```

Tiempo estimado: 3-5 minutos  
Resultado: Índices optimizados, rendimiento mejorado

---

## VERIFICACIÓN POST-INSTALACIÓN

### Checklist de Verificación Completa

#### Verificación de Estructura
```sql
-- Contar componentes instalados
SELECT 'Componente' as Tipo, 'Cantidad' as Valor, 'Estado' as Status
UNION ALL
SELECT 'Tablas Sistema', CAST(COUNT(*) AS NVARCHAR(10)), 
       CASE WHEN COUNT(*) = 13 THEN 'OK' ELSE 'ERROR' END
FROM sys.tables WHERE is_ms_shipped = 0 AND schema_id = SCHEMA_ID('dbo')
UNION ALL
SELECT 'Tablas DW', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 7 THEN 'OK' ELSE 'ERROR' END
FROM sys.tables WHERE schema_id = SCHEMA_ID('DW')
UNION ALL
SELECT 'Procedimientos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 15 THEN 'OK' ELSE 'ERROR' END
FROM sys.procedures WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Roles Seguridad', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) = 6 THEN 'OK' ELSE 'ERROR' END
FROM sys.database_principals WHERE type = 'R' AND name LIKE 'db_%';
```

#### Verificación de Datos
```sql
-- verificar datos cargados
SELECT 'Entidad' as Tabla, 'Registros' as Cantidad, 'Estado' as Status
UNION ALL
SELECT 'Estudiantes', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 10 THEN 'OK' ELSE 'POCOS DATOS' END FROM estudiante
UNION ALL
SELECT 'Profesores', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 7 THEN 'OK' ELSE 'POCOS DATOS' END FROM profesor
UNION ALL
SELECT 'Cursos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 11 THEN 'OK' ELSE 'POCOS DATOS' END FROM curso
UNION ALL
SELECT 'Pagos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 25 THEN 'OK' ELSE 'POCOS DATOS' END FROM pago;
```

#### Verificación Funcional
```sql
-- probar que todo funcione
SELECT 
    CASE WHEN COUNT(*) > 0 THEN 'Dashboard OK' 
         ELSE 'Dashboard ERROR' END as 'Estado Dashboard'
FROM vw_DashboardEjecutivo;

-- probar procedimientos
DECLARE @TestResult NVARCHAR(500);
EXEC sp_RegistrarPago 
    @ConceptoPagoId = 1, @EstudianteId = 1, @UsuarioId = 3,
    @Monto = 100000.00, @MetodoPago = 'EFECTIVO',
    @PagoId = NULL, @Resultado = @TestResult OUTPUT;
SELECT CASE WHEN @TestResult LIKE 'ÉXITO%' 
            THEN 'Transacciones OK' 
            ELSE 'Transacciones ERROR' END as 'Estado Transacciones';
```

## GUÍA DE OPERACIÓN

### Operaciones Diarias

#### Rutina Matutina (Administrador)
```sql
-- ver estado del sistema
SELECT * FROM vw_DashboardEjecutivo;

-- revisar eventos criticos
SELECT * FROM vw_EventosSeguridad 
WHERE nivel_criticidad IN ('CRÍTICO', 'ALTO')
AND fecha_evento >= CAST(GETDATE() AS DATE);

-- ver consultas lentas
SELECT * FROM vw_ConsultasActivas 
WHERE [Tiempo Total (ms)] > 30000;
```

#### Operaciones Académicas (Coordinador)
```sql
-- matricular estudiante
DECLARE @Resultado NVARCHAR(500);
EXEC sp_MatricularEstudiante 
    @EstudianteId = [ID_ESTUDIANTE],
    @CursoId = [ID_CURSO],
    @UsuarioId = [ID_USUARIO],
    @Resultado = @Resultado OUTPUT;

-- actualizar calificaciones
EXEC sp_ActualizarCalificacion 
    @AsignacionCursoId = [ID_ASIGNACION],
    @NotaParcial1 = [NOTA1],
    @NotaFinal = [NOTA_FINAL],
    @ProfesorId = [ID_PROFESOR],
    @Resultado = @Resultado OUTPUT;
```

#### Operaciones Financieras (Secretario)
```sql
-- registrar pago
DECLARE @PagoId INT, @Resultado NVARCHAR(500);
EXEC sp_RegistrarPago 
    @ConceptoPagoId = [ID_CONCEPTO],
    @EstudianteId = [ID_ESTUDIANTE],
    @UsuarioId = [ID_USUARIO],
    @Monto = [MONTO],
    @MetodoPago = '[MÉTODO]',
    @PagoId = @PagoId OUTPUT,
    @Resultado = @Resultado OUTPUT;

-- ver pagos de un estudiante
SELECT p.fecha_pago, cp.nombre, p.monto, p.estado_pago
FROM pago p
INNER JOIN concepto_pago cp ON p.concepto_pago_id = cp.concepto_pago_id
WHERE p.estudiante_id = [ID_ESTUDIANTE]
ORDER BY p.fecha_pago DESC;
```

### Operaciones Semanales

#### Mantenimiento Automático
```sql
-- ejecutar cada domingo
EXEC sp_OptimizacionAutomatica 
    @ActualizarEstadisticas = 1,
    @MantenimientoIndices = 1,
    @EjecutarMantenimiento = 1;
```

#### Actualización del Data Warehouse
```sql
-- ejecutar cada lunes
EXEC DW.sp_CargaCompletaDataWarehouse 
    @FechaInicio = NULL,
    @FechaFin = NULL;
```

### Operaciones Mensuales

#### Análisis de Rendimiento
```sql
-- reporte mensual
EXEC sp_ReporteRendimientoCompleto;

-- ver fragmentacion
EXEC sp_AnalisisFragmentacion;

-- actividad de usuarios
EXEC sp_ReporteActividadUsuarios 
    @FechaInicio = DATEADD(MONTH, -1, GETDATE()),
    @FechaFin = GETDATE();
```

## SOLUCIÓN DE PROBLEMAS

### Problemas Comunes

#### Error: "Base de datos no existe"
```
Solución:
1. Verificar conexión: USE BD2_Curso2025;
2. Re-ejecutar: 02_Modelo_ER/modelo_ER.sql
```

#### Error: "Procedimiento no encontrado"
```
Solución:
1. Ejecutar: 04_Transacciones/procedimientos_transaccionales.sql
2. Verificar: SELECT name FROM sys.procedures WHERE name LIKE 'sp_%';
```

#### Error: "Acceso denegado"
```
Solución:
1. Verificar rol: SELECT USER_NAME(), IS_MEMBER('db_administrador_edugestor');
2. Re-ejecutar: 06_Seguridad/seguridad_roles.sql
```

#### Error: "Rendimiento lento"
```
Solución:
1. Ejecutar: EXEC sp_OptimizacionAutomatica @EjecutarMantenimiento = 1;
2. Ver fragmentación: EXEC sp_AnalisisFragmentacion;
```

### Logs y Diagnóstico

#### Ubicaciones de Logs
```sql
-- ver auditoria
SELECT TOP 100 * FROM auditoria_seguridad 
ORDER BY fecha_evento DESC;

-- eventos criticos
SELECT * FROM vw_EventosSeguridad 
WHERE nivel_criticidad = 'CRÍTICO'
AND fecha_evento >= DATEADD(DAY, -7, GETDATE());
```

#### Comandos de Diagnóstico
```sql
-- ver estado del sistema
EXEC sp_who2;

-- ver bloqueos
EXEC sp_AnalisisBloqueos;

-- uso de recursos
SELECT 
    DB_NAME() as 'Base de Datos',
    COUNT(*) as 'Conexiones Activas',
    SUM(cpu_time) as 'CPU Total (ms)'
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE s.database_id = DB_ID()
GROUP BY s.database_id;
```

## SOPORTE

### Niveles de Soporte

#### Nivel 1: Auto-servicio
- Documentación: `08_Documentacion/documentacion_tecnica.md`
- Scripts de diagnóstico en sección "Solución de Problemas"

#### Nivel 2: Soporte Técnico
- Revisar logs en `auditoria_seguridad`
- Ejecutar `sp_ReporteRendimientoCompleto`

#### Nivel 3: Soporte Crítico
- Restaurar desde backup
- Ejecutar DBCC CHECKDB

### Información del Proyecto

**Proyecto:** Sistema EduGestor - Bases de Datos II  
**Versión:** 1.0.0  
**Fecha:** Noviembre 2024  

### Recursos

- Documentación: `08_Documentacion/documentacion_tecnica.md`
- Todos los archivos .sql tienen comentarios
- Ejemplos de uso en cada procedimiento

## CHECKLIST DE IMPLEMENTACIÓN

### Pre-Implementación
- [ ] SQL Server 2019+ instalado
- [ ] SSMS instalado
- [ ] Permisos de administrador
- [ ] Espacio en disco suficiente

### Durante la Implementación
- [ ] Scripts ejecutados sin errores
- [ ] Verificaciones completadas
- [ ] Datos de prueba cargados
- [ ] Dashboard funcional

### Post-Implementación
- [ ] Usuarios y roles configurados
- [ ] Backup configurado
- [ ] Monitoreo activo

---

*Última actualización: Noviembre 2024*