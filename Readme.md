# 📋 GUÍA DE INSTALACIÓN Y EJECUCIÓN - SISTEMA EDUGESTOR

## Proyecto Final - Bases de Datos II

---

## 🎯 INFORMACIÓN GENERAL

**Sistema:** EduGestor - Plataforma Integral de Gestión Educativa  
**Versión:** 1.0.0  
**Autor:** Proyecto BDII - Sistema Educativo Integral  
**Fecha:** Noviembre 2024  
**Licencia:** Académica  

### Descripción Técnica
Sistema de base de datos empresarial que integra procesamiento transaccional (OLTP) y analítico (OLAP) para instituciones educativas, implementando las mejores prácticas de ingeniería de software y administración de bases de datos.

---

## ⚙️ REQUISITOS DEL SISTEMA

### Requisitos Mínimos de Hardware
- **CPU:** Intel Core i5 / AMD Ryzen 5 o superior
- **RAM:** 8 GB mínimo (16 GB recomendado)
- **Almacenamiento:** 10 GB de espacio libre
- **Red:** Conexión estable para descargas de dependencias

### Requisitos de Software
| Componente | Versión Mínima | Versión Recomendada | Estado |
|------------|----------------|---------------------|--------|
| **SQL Server** | 2017 | 2019/2022 | ✅ Requerido |
| **SQL Server Management Studio (SSMS)** | 18.0 | 19.0+ | ✅ Requerido |
| **Windows** | 10 | 11 | ✅ Requerido |
| **.NET Framework** | 4.7.2 | 4.8+ | ⚠️ Dependencia |

### Permisos Requeridos
- **Administrador de SQL Server:** Para creación de base de datos y roles
- **Permisos de sistema:** Para instalación de componentes
- **Acceso de red:** Para validación de licencias (si aplica)

---

## 🚀 PROCESO DE INSTALACIÓN

### MÉTODO 1: INSTALACIÓN AUTOMÁTICA (Recomendado para Desarrollo)

#### Paso 1: Preparación del Entorno
```powershell
# Verificar versión de SQL Server
SELECT @@VERSION;

# Verificar permisos actuales
SELECT 
    SUSER_NAME() as 'Usuario Actual',
    IS_SRVROLEMEMBER('sysadmin') as 'Es Admin',
    SERVERPROPERTY('ProductVersion') as 'Versión SQL Server';
```

#### Paso 2: Descarga y Preparación
1. **Clonar/Descargar** el repositorio del proyecto
2. **Extraer** todos los archivos en una carpeta local (ej: `C:\EduGestor\`)
3. **Verificar** que todos los archivos .sql estén presentes:
   ```
   ✅ INSTALACION_COMPLETA.sql
   ✅ 02_Modelo_ER/modelo_ER.sql
   ✅ 02_Modelo_ER/datos_prueba.sql
   ✅ 03_Modelo_OLAP/modelo_dimensional.sql
   ✅ [... resto de archivos]
   ```

#### Paso 3: Ejecución Automática
1. **Abrir SQL Server Management Studio (SSMS)**
2. **Conectar** al servidor SQL Server con permisos de administrador
3. **Abrir** el archivo `INSTALACION_COMPLETA.sql`
4. **Ejecutar** el script completo (F5 o Ctrl+E)

```sql
-- Comando de instalación automática
:r "C:\EduGestor\INSTALACION_COMPLETA.sql"
```

#### Paso 4: Verificación Automática
El script incluye verificaciones automáticas que mostrarán:
```
✅ Base de datos creada: EduGestor_BDII
✅ Tablas del sistema: 13
✅ Procedimientos almacenados: 15+
✅ Roles de seguridad: 6
✅ Índices optimizados: 10
```

---

### MÉTODO 2: INSTALACIÓN MANUAL (Recomendado para Producción)

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

**⏱️ Tiempo estimado:** 2-3 minutos  
**✅ Criterio de éxito:** 13 tablas creadas, datos de ejemplo cargados

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

**⏱️ Tiempo estimado:** 3-5 minutos  
**✅ Criterio de éxito:** Esquema DW creado, dimensiones pobladas

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

**⏱️ Tiempo estimado:** 2-3 minutos  
**✅ Criterio de éxito:** 4 procedimientos creados y funcionales

#### Fase 4: Consultas Analíticas
```sql
-- 4.1 Crear consultas OLAP y vistas
:r "05_Consultas_Analiticas\consultas_olap.sql"

-- 4.2 Verificar dashboard ejecutivo
SELECT * FROM vw_DashboardEjecutivo;
```

**⏱️ Tiempo estimado:** 1-2 minutos  
**✅ Criterio de éxito:** Dashboard funcional con datos en tiempo real

#### Fase 5: Sistema de Seguridad
```sql
-- 5.1 Configurar roles y permisos
:r "06_Seguridad\seguridad_roles.sql"

-- 5.2 Verificar matriz de permisos
EXEC sp_ReporteMatrizPermisos;
```

**⏱️ Tiempo estimado:** 2-3 minutos  
**✅ Criterio de éxito:** 6 roles creados, auditoría activa

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

**⏱️ Tiempo estimado:** 3-5 minutos  
**✅ Criterio de éxito:** Índices optimizados, rendimiento mejorado

---

## 🔍 VERIFICACIÓN POST-INSTALACIÓN

### Checklist de Verificación Completa

#### ✅ Verificación de Estructura
```sql
-- Contar componentes instalados
SELECT 'Componente' as Tipo, 'Cantidad' as Valor, 'Estado' as Status
UNION ALL
SELECT 'Tablas Sistema', CAST(COUNT(*) AS NVARCHAR(10)), 
       CASE WHEN COUNT(*) = 13 THEN '✅ OK' ELSE '❌ ERROR' END
FROM sys.tables WHERE is_ms_shipped = 0 AND schema_id = SCHEMA_ID('dbo')
UNION ALL
SELECT 'Tablas DW', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 7 THEN '✅ OK' ELSE '❌ ERROR' END
FROM sys.tables WHERE schema_id = SCHEMA_ID('DW')
UNION ALL
SELECT 'Procedimientos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 15 THEN '✅ OK' ELSE '❌ ERROR' END
FROM sys.procedures WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Roles Seguridad', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) = 6 THEN '✅ OK' ELSE '❌ ERROR' END
FROM sys.database_principals WHERE type = 'R' AND name LIKE 'db_%';
```

#### ✅ Verificación de Datos
```sql
-- Verificar datos de ejemplo
SELECT 'Entidad' as Tabla, 'Registros' as Cantidad, 'Estado' as Status
UNION ALL
SELECT 'Estudiantes', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 10 THEN '✅ OK' ELSE '⚠️ POCOS DATOS' END FROM estudiante
UNION ALL
SELECT 'Profesores', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 7 THEN '✅ OK' ELSE '⚠️ POCOS DATOS' END FROM profesor
UNION ALL
SELECT 'Cursos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 11 THEN '✅ OK' ELSE '⚠️ POCOS DATOS' END FROM curso
UNION ALL
SELECT 'Pagos', CAST(COUNT(*) AS NVARCHAR(10)),
       CASE WHEN COUNT(*) >= 25 THEN '✅ OK' ELSE '⚠️ POCOS DATOS' END FROM pago;
```

#### ✅ Verificación Funcional
```sql
-- Probar funcionalidades críticas
-- 1. Dashboard ejecutivo
SELECT 
    CASE WHEN COUNT(*) > 0 THEN '✅ Dashboard OK' 
         ELSE '❌ Dashboard ERROR' END as 'Estado Dashboard'
FROM vw_DashboardEjecutivo;

-- 2. Procedimientos transaccionales
DECLARE @TestResult NVARCHAR(500);
EXEC sp_RegistrarPago 
    @ConceptoPagoId = 1, @EstudianteId = 1, @UsuarioId = 3,
    @Monto = 100000.00, @MetodoPago = 'EFECTIVO',
    @PagoId = NULL, @Resultado = @TestResult OUTPUT;
SELECT CASE WHEN @TestResult LIKE 'ÉXITO%' 
            THEN '✅ Transacciones OK' 
            ELSE '❌ Transacciones ERROR' END as 'Estado Transacciones';

-- 3. Sistema de seguridad
SELECT CASE WHEN COUNT(*) > 0 
            THEN '✅ Auditoría OK' 
            ELSE '❌ Auditoría ERROR' END as 'Estado Auditoría'
FROM auditoria_seguridad;
```

---

## 🎮 GUÍA DE OPERACIÓN

### Operaciones Diarias

#### 🌅 Rutina Matutina (Administrador)
```sql
-- 1. Verificar estado general del sistema
SELECT * FROM vw_DashboardEjecutivo;

-- 2. Revisar eventos de seguridad críticos
SELECT * FROM vw_EventosSeguridad 
WHERE nivel_criticidad IN ('CRÍTICO', 'ALTO')
AND fecha_evento >= CAST(GETDATE() AS DATE);

-- 3. Verificar consultas activas problemáticas
SELECT * FROM vw_ConsultasActivas 
WHERE [Tiempo Total (ms)] > 30000; -- Más de 30 segundos
```

#### 📚 Operaciones Académicas (Coordinador)
```sql
-- 1. Matricular nuevo estudiante
DECLARE @Resultado NVARCHAR(500);
EXEC sp_MatricularEstudiante 
    @EstudianteId = [ID_ESTUDIANTE],
    @CursoId = [ID_CURSO],
    @UsuarioId = [ID_USUARIO],
    @Resultado = @Resultado OUTPUT;
PRINT @Resultado;

-- 2. Actualizar calificaciones
EXEC sp_ActualizarCalificacion 
    @AsignacionCursoId = [ID_ASIGNACION],
    @NotaParcial1 = [NOTA1],
    @NotaParcial2 = [NOTA2],
    @NotaFinal = [NOTA_FINAL],
    @ProfesorId = [ID_PROFESOR],
    @Resultado = @Resultado OUTPUT;

-- 3. Consultar rendimiento por curso
-- Ver archivo: 05_Consultas_Analiticas/consultas_olap.sql
```

#### 💰 Operaciones Financieras (Secretario)
```sql
-- 1. Registrar pago
DECLARE @PagoId INT, @Resultado NVARCHAR(500);
EXEC sp_RegistrarPago 
    @ConceptoPagoId = [ID_CONCEPTO],
    @EstudianteId = [ID_ESTUDIANTE],
    @UsuarioId = [ID_USUARIO],
    @Monto = [MONTO],
    @MetodoPago = '[MÉTODO]',
    @NumeroRecibo = '[RECIBO]',
    @PagoId = @PagoId OUTPUT,
    @Resultado = @Resultado OUTPUT;

-- 2. Consultar estado de pagos por estudiante
SELECT p.fecha_pago, cp.nombre, p.monto, p.estado_pago
FROM pago p
INNER JOIN concepto_pago cp ON p.concepto_pago_id = cp.concepto_pago_id
WHERE p.estudiante_id = [ID_ESTUDIANTE]
ORDER BY p.fecha_pago DESC;
```

### Operaciones Semanales

#### 🔧 Mantenimiento Automático
```sql
-- Ejecutar cada domingo a las 2:00 AM
EXEC sp_OptimizacionAutomatica 
    @ActualizarEstadisticas = 1,
    @MantenimientoIndices = 1,
    @EjecutarMantenimiento = 1,
    @GenerarReporte = 1;
```

#### 📊 Actualización del Data Warehouse
```sql
-- Ejecutar cada lunes a las 6:00 AM
EXEC DW.sp_CargaCompletaDataWarehouse 
    @FechaInicio = NULL, -- Última semana
    @FechaFin = NULL;
```

### Operaciones Mensuales

#### 📈 Análisis de Rendimiento Completo
```sql
-- Generar reporte mensual completo
EXEC sp_ReporteRendimientoCompleto;

-- Análisis de fragmentación
EXEC sp_AnalisisFragmentacion;

-- Reporte de actividad de usuarios
EXEC sp_ReporteActividadUsuarios 
    @FechaInicio = DATEADD(MONTH, -1, GETDATE()),
    @FechaFin = GETDATE();
```

---

## 🚨 SOLUCIÓN DE PROBLEMAS

### Problemas Comunes y Soluciones

#### ❌ Error: "Base de datos no existe"
**Síntoma:** Mensaje de error al ejecutar consultas
```
Solución:
1. Verificar conexión: USE EduGestor_BDII;
2. Re-ejecutar: 02_Modelo_ER/modelo_ER.sql
3. Verificar permisos de creación de BD
```

#### ❌ Error: "Procedimiento no encontrado"
**Síntoma:** `Could not find stored procedure 'sp_MatricularEstudiante'`
```
Solución:
1. Ejecutar: 04_Transacciones/procedimientos_transaccionales.sql
2. Verificar esquema: SELECT name FROM sys.procedures WHERE name LIKE 'sp_%';
3. Revisar permisos de ejecución
```

#### ❌ Error: "Acceso denegado"
**Síntoma:** Permisos insuficientes para operaciones
```
Solución:
1. Verificar rol actual: SELECT USER_NAME(), IS_MEMBER('db_administrador_edugestor');
2. Re-ejecutar: 06_Seguridad/seguridad_roles.sql
3. Contactar administrador de BD
```

#### ❌ Error: "Rendimiento lento"
**Síntoma:** Consultas tardan más de 30 segundos
```
Solución:
1. Ejecutar: EXEC sp_OptimizacionAutomatica @EjecutarMantenimiento = 1;
2. Verificar fragmentación: EXEC sp_AnalisisFragmentacion;
3. Revisar consultas activas: SELECT * FROM vw_ConsultasActivas;
```

### Logs y Diagnóstico

#### 📋 Ubicaciones de Logs
```sql
-- Log de auditoría del sistema
SELECT TOP 100 * FROM auditoria_seguridad 
ORDER BY fecha_evento DESC;

-- Log de errores de SQL Server
EXEC xp_readerrorlog 0, 1, 'EduGestor';

-- Eventos de seguridad críticos
SELECT * FROM vw_EventosSeguridad 
WHERE nivel_criticidad = 'CRÍTICO'
AND fecha_evento >= DATEADD(DAY, -7, GETDATE());
```

#### 🔍 Comandos de Diagnóstico
```sql
-- Estado general del sistema
EXEC sp_who2;

-- Procesos bloqueados
EXEC sp_AnalisisBloqueos;

-- Uso de recursos
SELECT 
    DB_NAME() as 'Base de Datos',
    COUNT(*) as 'Conexiones Activas',
    SUM(cpu_time) as 'CPU Total (ms)',
    SUM(logical_reads) as 'Lecturas Lógicas'
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
WHERE s.database_id = DB_ID()
GROUP BY s.database_id;
```

---

## 📞 SOPORTE Y CONTACTO

### Niveles de Soporte

#### 🟢 Nivel 1: Auto-servicio
- **Documentación:** `08_Documentacion/documentacion_tecnica.md`
- **Scripts de diagnóstico:** Sección "Solución de Problemas"
- **Verificaciones automáticas:** `INSTALACION_COMPLETA.sql`

#### 🟡 Nivel 2: Soporte Técnico
- **Logs del sistema:** Revisar `auditoria_seguridad`
- **Análisis de rendimiento:** `sp_ReporteRendimientoCompleto`
- **Escalamiento:** Contactar administrador de BD

#### 🔴 Nivel 3: Soporte Crítico
- **Fallas del sistema:** Restaurar desde backup
- **Corrupción de datos:** Ejecutar DBCC CHECKDB
- **Problemas de seguridad:** Revisar matriz de permisos

### Información de Contacto

**Proyecto:** Sistema EduGestor - Bases de Datos II  
**Desarrollador:** Proyecto BDII - Sistema Educativo Integral  
**Versión:** 1.0.0  
**Fecha de Release:** Noviembre 2024  
**Soporte:** Documentación técnica incluida  

### Recursos Adicionales

- **Documentación Completa:** `08_Documentacion/documentacion_tecnica.md`
- **Código Fuente:** Todos los archivos .sql incluyen comentarios detallados
- **Ejemplos de Uso:** Casos prácticos en cada procedimiento almacenado
- **Mejores Prácticas:** Implementadas según estándares de la industria

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

### Pre-Implementación
- [ ] Servidor SQL Server 2019+ instalado y configurado
- [ ] SSMS instalado y funcional
- [ ] Permisos de administrador verificados
- [ ] Backup del sistema actual (si aplica)
- [ ] Espacio en disco suficiente (10+ GB)

### Durante la Implementación
- [ ] Todos los scripts ejecutados sin errores
- [ ] Verificaciones post-instalación completadas
- [ ] Datos de prueba cargados correctamente
- [ ] Dashboard ejecutivo funcional
- [ ] Procedimientos transaccionales probados

### Post-Implementación
- [ ] Usuarios y roles configurados
- [ ] Capacitación del personal completada
- [ ] Procedimientos de backup configurados
- [ ] Monitoreo de rendimiento activo
- [ ] Plan de mantenimiento programado

---

*Documento elaborado por ingenieros especializados en bases de datos empresariales. Última actualización: Noviembre 2024*