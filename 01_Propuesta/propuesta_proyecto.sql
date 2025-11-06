/*
================================================================================
PROYECTO FINAL - BASES DE DATOS II
SISTEMA DE GESTIÓN EDUCATIVA "EduGestor"
================================================================================

AUTOR: Proyecto BDII - Sistema Educativo Integral
FECHA: Noviembre 2024
OBJETIVO: Implementar una solución completa que integre procesamiento 
          transaccional y componentes analíticos para gestión educativa.

================================================================================
1. DESCRIPCIÓN DEL PROBLEMA
================================================================================

Las instituciones educativas requieren un sistema integral que permita:
- Gestionar estudiantes, profesores y cursos de manera eficiente
- Controlar asignaciones académicas y calificaciones
- Administrar pagos y conceptos financieros
- Implementar seguridad basada en roles y permisos
- Generar reportes analíticos para toma de decisiones

PROBLEMÁTICA ACTUAL:
- Datos dispersos en múltiples sistemas
- Falta de integridad referencial
- Ausencia de controles transaccionales
- Reportes limitados para análisis de tendencias
- Seguridad inadecuada en el acceso a información sensible

================================================================================
2. OBJETIVOS DEL PROYECTO
================================================================================

OBJETIVO GENERAL:
Desarrollar una base de datos robusta en SQL Server que integre procesamiento
transaccional (OLTP) y analítico (OLAP) para la gestión educativa integral.

OBJETIVOS ESPECÍFICOS:
1. Diseñar un modelo relacional normalizado para operaciones transaccionales
2. Implementar un modelo dimensional para análisis de datos (Data Warehouse)
3. Desarrollar procedimientos almacenados con control de transacciones
4. Crear un sistema de seguridad basado en roles y permisos
5. Optimizar consultas mediante índices y análisis de planes de ejecución
6. Generar consultas OLAP para análisis multidimensional

================================================================================
3. ALCANCE Y ENTIDADES PRINCIPALES
================================================================================

MÓDULOS DEL SISTEMA:
1. GESTIÓN ACADÉMICA
   - Estudiantes y sus datos personales
   - Profesores y especialidades
   - Cursos y asignaciones
   - Calificaciones y evaluaciones

2. GESTIÓN FINANCIERA
   - Conceptos de pago (inscripciones, mensualidades, exámenes)
   - Registro de pagos por estudiante
   - Control de usuarios que registran transacciones

3. SEGURIDAD Y AUTENTICACIÓN
   - Usuarios del sistema
   - Roles y permisos granulares
   - Control de acceso por funcionalidad

ENTIDADES CLAVE IDENTIFICADAS:
- grado, estudiante, profesor, curso
- asignacion_curso, calificacion
- concepto_pago, pago
- usuario, rol, permiso
- usuario_rol, permiso_rol

================================================================================
4. FUENTE DE DATOS Y TIPO DE INFORMACIÓN
================================================================================

TIPOS DE DATOS A MANEJAR:
- Datos maestros: estudiantes, profesores, cursos, conceptos de pago
- Datos transaccionales: asignaciones, calificaciones, pagos
- Datos de seguridad: usuarios, roles, permisos, sesiones
- Datos analíticos: métricas de rendimiento, tendencias de pago, estadísticas

VOLUMEN ESTIMADO:
- 1,000+ estudiantes por institución
- 50+ profesores
- 100+ cursos diferentes
- 10,000+ transacciones de pago anuales
- 5,000+ calificaciones por período académico

================================================================================
5. ARQUITECTURA TÉCNICA PROPUESTA
================================================================================

COMPONENTE TRANSACCIONAL (OLTP):
- Modelo relacional normalizado (3FN)
- Procedimientos almacenados con T-SQL
- Control de transacciones (COMMIT/ROLLBACK/SAVEPOINT)
- Manejo de errores con TRY...CATCH
- Índices optimizados para operaciones frecuentes

COMPONENTE ANALÍTICO (OLAP):
- Modelo dimensional tipo estrella
- Tablas de hechos: FactCalificaciones, FactPagos
- Dimensiones: DimTiempo, DimEstudiante, DimCurso, DimConceptoPago
- Jerarquías temporales y académicas
- Consultas con agregaciones y drill-down

SEGURIDAD:
- Autenticación de SQL Server
- Roles personalizados por funcionalidad
- Permisos granulares (SELECT, INSERT, UPDATE, DELETE, EXECUTE)
- Principio de menor privilegio

================================================================================
6. CRONOGRAMA DE DESARROLLO
================================================================================

SEMANA 7:  Modelo Entidad-Relación y creación de tablas
SEMANA 8:  Modelo dimensional y estructuras OLAP
SEMANA 9-12: Programación transaccional y procedimientos almacenados
SEMANA 11-13: Implementación de seguridad y roles
SEMANA 14: Optimización y análisis de rendimiento
SEMANA 16-17: Documentación y presentación final

================================================================================
7. CRITERIOS DE ÉXITO
================================================================================

- Modelo relacional completamente normalizado y funcional
- Modelo dimensional que permita análisis multidimensional efectivo
- Procedimientos almacenados robustos con manejo de errores
- Sistema de seguridad que garantice acceso controlado
- Consultas optimizadas con mejoras medibles de rendimiento
- Documentación técnica completa y presentación profesional

================================================================================
*/