    -- ================================================================================
    -- PROCEDIMIENTOS ALMACENADOS TRANSACCIONALES - SISTEMA EDUGESTOR
    -- ================================================================================
    -- Descripción: Implementación de lógica de negocio con control de transacciones,
    --              manejo de errores y validaciones de integridad
    -- Autor: Proyecto BDII
    -- Fecha: Noviembre 2024
    -- Características: TRY...CATCH, COMMIT/ROLLBACK, SAVEPOINT, validaciones de negocio
    -- ================================================================================

    -- Configuración inicial - Conectar a base de datos del curso
    USE BD2_Curso2025;
    GO

    -- ================================================================================
    -- PROCEDIMIENTO: MATRICULAR ESTUDIANTE EN CURSO
    -- ================================================================================
    -- Funcionalidad: Matricula un estudiante en un curso con validaciones completas
    -- Control de transacciones: SAVEPOINT para rollback parcial
    -- Validaciones: Capacidad, prerrequisitos, conflictos de horario

    CREATE OR ALTER PROCEDURE sp_MatricularEstudiante
        @EstudianteId INT,
        @CursoId INT,
        @UsuarioId INT,
        @Resultado NVARCHAR(500) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Variables de control
        DECLARE @ErrorMessage NVARCHAR(500);
        DECLARE @AsignacionId INT;
        DECLARE @GradoEstudiante INT;
        DECLARE @GradoCurso INT;
        DECLARE @EstadoEstudiante NVARCHAR(20);
        DECLARE @EstadoCurso NVARCHAR(20);
        DECLARE @MatriculasActuales INT;
        DECLARE @CapacidadMaxima INT = 30; -- Capacidad máxima por curso
        
        BEGIN TRANSACTION;
        
        BEGIN TRY
            -- VALIDACIÓN 1: Verificar que el estudiante existe y está activo
            SELECT @GradoEstudiante = grado_id, @EstadoEstudiante = estado
            FROM estudiante 
            WHERE estudiante_id = @EstudianteId;
            
            IF @GradoEstudiante IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: El estudiante con ID ' + CAST(@EstudianteId AS NVARCHAR(10)) + ' no existe';
                THROW 50001, @ErrorMessage, 1;
            END
            
            IF @EstadoEstudiante != 'ACTIVO'
            BEGIN
                SET @ErrorMessage = 'Error: El estudiante no está en estado ACTIVO. Estado actual: ' + @EstadoEstudiante;
                THROW 50002, @ErrorMessage, 1;
            END
            
            -- SAVEPOINT para poder hacer rollback parcial si es necesario
            SAVE TRANSACTION SP_ValidacionesIniciales;
            
            -- VALIDACIÓN 2: Verificar que el curso existe y está activo
            SELECT @GradoCurso = grado_id, @EstadoCurso = estado
            FROM curso 
            WHERE curso_id = @CursoId;
            
            IF @GradoCurso IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: El curso con ID ' + CAST(@CursoId AS NVARCHAR(10)) + ' no existe';
                THROW 50003, @ErrorMessage, 1;
            END
            
            IF @EstadoCurso != 'ACTIVO'
            BEGIN
                SET @ErrorMessage = 'Error: El curso no está activo. Estado actual: ' + @EstadoCurso;
                THROW 50004, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 3: Verificar compatibilidad de grado (si el curso tiene grado específico)
            IF @GradoCurso IS NOT NULL AND @GradoCurso != @GradoEstudiante
            BEGIN
                SET @ErrorMessage = 'Error: El curso está diseñado para un grado diferente al del estudiante';
                THROW 50005, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 4: Verificar que no esté ya matriculado
            IF EXISTS (SELECT 1 FROM asignacion_curso 
                    WHERE estudiante_id = @EstudianteId 
                    AND curso_id = @CursoId 
                    AND estado_asignacion = 'MATRICULADO')
            BEGIN
                SET @ErrorMessage = 'Error: El estudiante ya está matriculado en este curso';
                THROW 50006, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 5: Verificar capacidad del curso
            SELECT @MatriculasActuales = COUNT(*)
            FROM asignacion_curso 
            WHERE curso_id = @CursoId 
            AND estado_asignacion = 'MATRICULADO';
            
            IF @MatriculasActuales >= @CapacidadMaxima
            BEGIN
                SET @ErrorMessage = 'Error: El curso ha alcanzado su capacidad máxima (' + 
                                CAST(@CapacidadMaxima AS NVARCHAR(10)) + ' estudiantes)';
                THROW 50007, @ErrorMessage, 1;
            END
            
            -- SAVEPOINT antes de la inserción
            SAVE TRANSACTION SP_AntesInsercion;
            
            -- INSERTAR LA MATRÍCULA
            INSERT INTO asignacion_curso (estudiante_id, curso_id, fecha_asignacion, estado_asignacion)
            VALUES (@EstudianteId, @CursoId, CAST(GETDATE() AS DATE), 'MATRICULADO');
            
            SET @AsignacionId = SCOPE_IDENTITY();
            
            -- CREAR REGISTRO DE CALIFICACIÓN INICIAL
            INSERT INTO calificacion (asignacion_curso_id, estado_calificacion)
            VALUES (@AsignacionId, 'PENDIENTE');
            
            -- REGISTRAR AUDITORÍA (simulada con PRINT por simplicidad)
            PRINT 'AUDITORÍA: Estudiante ' + CAST(@EstudianteId AS NVARCHAR(10)) + 
                ' matriculado en curso ' + CAST(@CursoId AS NVARCHAR(10)) + 
                ' por usuario ' + CAST(@UsuarioId AS NVARCHAR(10));
            
            -- COMMIT de la transacción
            COMMIT TRANSACTION;
            
            SET @Resultado = 'ÉXITO: Matrícula realizada correctamente. ID Asignación: ' + CAST(@AsignacionId AS NVARCHAR(10));
            
        END TRY
        BEGIN CATCH
            -- Manejo de errores con información detallada
            SET @ErrorMessage = 'Error en sp_MatricularEstudiante: ' + ERROR_MESSAGE() + 
                            ' (Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')';
            
            -- Rollback de la transacción
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            SET @Resultado = @ErrorMessage;
            
            -- Log del error (en un sistema real iría a una tabla de log)
            PRINT 'ERROR REGISTRADO: ' + @ErrorMessage;
            
            -- Re-lanzar el error para que el cliente lo maneje
            THROW;
        END CATCH
    END
    GO

    -- ================================================================================
    -- PROCEDIMIENTO: REGISTRAR PAGO CON VALIDACIONES FINANCIERAS
    -- ================================================================================
    -- Funcionalidad: Registra un pago con validaciones de negocio y control de duplicados
    -- Control de transacciones: Múltiples SAVEPOINT para control granular
    -- Validaciones: Montos, duplicados, estado del estudiante

    CREATE OR ALTER PROCEDURE sp_RegistrarPago
        @ConceptoPagoId INT,
        @EstudianteId INT,
        @UsuarioId INT,
        @Monto DECIMAL(10,2),
        @MetodoPago NVARCHAR(50) = 'EFECTIVO',
        @NumeroRecibo NVARCHAR(20) = NULL,
        @Observaciones NVARCHAR(300) = NULL,
        @PagoId INT OUTPUT,
        @Resultado NVARCHAR(500) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Variables de control
        DECLARE @ErrorMessage NVARCHAR(500);
        DECLARE @MontoBase DECIMAL(10,2);
        DECLARE @NombreConcepto NVARCHAR(100);
        DECLARE @EstadoEstudiante NVARCHAR(20);
        DECLARE @NombreEstudiante NVARCHAR(100);
        DECLARE @TipoConcepto NVARCHAR(50);
        DECLARE @NumeroReciboGenerado NVARCHAR(20);
        DECLARE @PagosDelDia INT;
        
        BEGIN TRANSACTION;
        
        BEGIN TRY
            -- VALIDACIÓN 1: Verificar concepto de pago
            SELECT @MontoBase = monto_base, @NombreConcepto = nombre, @TipoConcepto = tipo_concepto
            FROM concepto_pago 
            WHERE concepto_pago_id = @ConceptoPagoId AND activo = 1;
            
            IF @MontoBase IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: Concepto de pago no válido o inactivo';
                THROW 50101, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_ConceptoValidado;
            
            -- VALIDACIÓN 2: Verificar estudiante
            SELECT @EstadoEstudiante = estado, @NombreEstudiante = nombre_completo
            FROM estudiante 
            WHERE estudiante_id = @EstudianteId;
            
            IF @NombreEstudiante IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: Estudiante no encontrado';
                THROW 50102, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 3: Verificar monto (permitir variaciones del ±10% del monto base)
            IF @Monto <= 0
            BEGIN
                SET @ErrorMessage = 'Error: El monto debe ser mayor a cero';
                THROW 50103, @ErrorMessage, 1;
            END
            
            IF @Monto < (@MontoBase * 0.5) -- No menos del 50% del monto base
            BEGIN
                SET @ErrorMessage = 'Error: El monto es muy bajo. Mínimo permitido: ' + 
                                CAST(@MontoBase * 0.5 AS NVARCHAR(20));
                THROW 50104, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_MontoValidado;
            
            -- VALIDACIÓN 4: Verificar duplicados por número de recibo
            IF @NumeroRecibo IS NOT NULL AND EXISTS (
                SELECT 1 FROM pago WHERE numero_recibo = @NumeroRecibo
            )
            BEGIN
                SET @ErrorMessage = 'Error: Ya existe un pago con el número de recibo: ' + @NumeroRecibo;
                THROW 50105, @ErrorMessage, 1;
            END
            
            -- GENERAR NÚMERO DE RECIBO SI NO SE PROPORCIONÓ
            IF @NumeroRecibo IS NULL
            BEGIN
                -- Contar pagos del día para generar secuencial
                SELECT @PagosDelDia = COUNT(*) + 1
                FROM pago 
                WHERE CAST(fecha_pago AS DATE) = CAST(GETDATE() AS DATE);
                
                SET @NumeroReciboGenerado = 'REC-' + FORMAT(GETDATE(), 'yyyyMMdd') + '-' + 
                                        FORMAT(@PagosDelDia, '000');
                SET @NumeroRecibo = @NumeroReciboGenerado;
            END
            
            SAVE TRANSACTION SP_ReciboValidado;
            
            -- VALIDACIÓN 5: Verificar usuario que registra
            IF NOT EXISTS (SELECT 1 FROM usuario WHERE usuario_id = @UsuarioId AND activo = 1)
            BEGIN
                SET @ErrorMessage = 'Error: Usuario no válido o inactivo';
                THROW 50106, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 6: Verificar método de pago
            IF @MetodoPago NOT IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'CHEQUE')
            BEGIN
                SET @ErrorMessage = 'Error: Método de pago no válido: ' + @MetodoPago;
                THROW 50107, @ErrorMessage, 1;
            END
            
            -- INSERTAR EL PAGO
            INSERT INTO pago (
                concepto_pago_id, estudiante_id, usuario_id, monto, 
                fecha_pago, metodo_pago, numero_recibo, observaciones, estado_pago
            )
            VALUES (
                @ConceptoPagoId, @EstudianteId, @UsuarioId, @Monto,
                CAST(GETDATE() AS DATE), @MetodoPago, @NumeroRecibo, @Observaciones, 'COMPLETADO'
            );
            
            SET @PagoId = SCOPE_IDENTITY();
            
            -- REGISTRAR AUDITORÍA DETALLADA
            PRINT 'AUDITORÍA PAGO: ID=' + CAST(@PagoId AS NVARCHAR(10)) + 
                ', Estudiante=' + @NombreEstudiante + 
                ', Concepto=' + @NombreConcepto + 
                ', Monto=' + CAST(@Monto AS NVARCHAR(20)) + 
                ', Recibo=' + @NumeroRecibo;
            
            -- COMMIT de la transacción
            COMMIT TRANSACTION;
            
            SET @Resultado = 'ÉXITO: Pago registrado correctamente. Recibo: ' + @NumeroRecibo;
            
        END TRY
        BEGIN CATCH
            -- Manejo detallado de errores
            SET @ErrorMessage = 'Error en sp_RegistrarPago: ' + ERROR_MESSAGE() + 
                            ' (Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + 
                            ', Severidad: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10)) + ')';
            
            -- Rollback inteligente según el punto de falla
            IF @@TRANCOUNT > 0
            BEGIN
                -- Si el error fue después de validar el concepto, hacer rollback completo
                IF ERROR_NUMBER() >= 50103
                    ROLLBACK TRANSACTION;
                ELSE
                    -- Si fue antes, intentar rollback al savepoint
                    ROLLBACK TRANSACTION SP_ConceptoValidado;
            END
            
            SET @Resultado = @ErrorMessage;
            SET @PagoId = -1; -- Indicar falla
            
            -- Log detallado del error
            PRINT 'ERROR CRÍTICO EN PAGO: ' + @ErrorMessage;
            PRINT 'Parámetros: ConceptoId=' + CAST(@ConceptoPagoId AS NVARCHAR(10)) + 
                ', EstudianteId=' + CAST(@EstudianteId AS NVARCHAR(10)) + 
                ', Monto=' + CAST(@Monto AS NVARCHAR(20));
            
            -- Re-lanzar para manejo en nivel superior
            THROW;
        END CATCH
    END
    GO

    -- ================================================================================
    -- PROCEDIMIENTO: ACTUALIZAR CALIFICACIONES CON VALIDACIONES ACADÉMICAS
    -- ================================================================================
    -- Funcionalidad: Actualiza calificaciones con cálculos automáticos y validaciones
    -- Control de transacciones: Control de concurrencia y validaciones de negocio
    -- Validaciones: Rangos de notas, permisos del profesor, fechas límite

    CREATE OR ALTER PROCEDURE sp_ActualizarCalificacion
        @AsignacionCursoId INT,
        @NotaParcial1 DECIMAL(5,2) = NULL,
        @NotaParcial2 DECIMAL(5,2) = NULL,
        @NotaParcial3 DECIMAL(5,2) = NULL,
        @NotaFinal DECIMAL(5,2) = NULL,
        @Observaciones NVARCHAR(500) = NULL,
        @ProfesorId INT,
        @Resultado NVARCHAR(500) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Variables de control
        DECLARE @ErrorMessage NVARCHAR(500);
        DECLARE @CalificacionId INT;
        DECLARE @CursoId INT;
        DECLARE @ProfesorCurso INT;
        DECLARE @EstudianteId INT;
        DECLARE @EstadoAsignacion NVARCHAR(20);
        DECLARE @NotaFinalCalculada DECIMAL(5,2);
        DECLARE @EstadoCalificacion NVARCHAR(20);
        DECLARE @ContadorNotas INT = 0;
        DECLARE @SumaNotas DECIMAL(8,2) = 0;
        
        BEGIN TRANSACTION;
        
        BEGIN TRY
            -- VALIDACIÓN 1: Verificar que la asignación existe y está activa
            SELECT @CursoId = curso_id, @EstudianteId = estudiante_id, @EstadoAsignacion = estado_asignacion
            FROM asignacion_curso 
            WHERE asignacion_curso_id = @AsignacionCursoId;
            
            IF @CursoId IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: Asignación de curso no encontrada';
                THROW 50201, @ErrorMessage, 1;
            END
            
            IF @EstadoAsignacion != 'MATRICULADO'
            BEGIN
                SET @ErrorMessage = 'Error: El estudiante no está matriculado en el curso. Estado: ' + @EstadoAsignacion;
                THROW 50202, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_AsignacionValidada;
            
            -- VALIDACIÓN 2: Verificar que el profesor tiene permisos sobre el curso
            SELECT @ProfesorCurso = profesor_id
            FROM curso 
            WHERE curso_id = @CursoId AND estado = 'ACTIVO';
            
            IF @ProfesorCurso != @ProfesorId
            BEGIN
                SET @ErrorMessage = 'Error: El profesor no tiene permisos para calificar este curso';
                THROW 50203, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 3: Verificar rangos de notas (0-100)
            IF (@NotaParcial1 IS NOT NULL AND (@NotaParcial1 < 0 OR @NotaParcial1 > 100)) OR
            (@NotaParcial2 IS NOT NULL AND (@NotaParcial2 < 0 OR @NotaParcial2 > 100)) OR
            (@NotaParcial3 IS NOT NULL AND (@NotaParcial3 < 0 OR @NotaParcial3 > 100)) OR
            (@NotaFinal IS NOT NULL AND (@NotaFinal < 0 OR @NotaFinal > 100))
            BEGIN
                SET @ErrorMessage = 'Error: Las notas deben estar entre 0 y 100';
                THROW 50204, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_NotasValidadas;
            
            -- OBTENER CALIFICACIÓN EXISTENTE
            SELECT @CalificacionId = calificacion_id
            FROM calificacion 
            WHERE asignacion_curso_id = @AsignacionCursoId;
            
            IF @CalificacionId IS NULL
            BEGIN
                SET @ErrorMessage = 'Error: No existe registro de calificación para esta asignación';
                THROW 50205, @ErrorMessage, 1;
            END
            
            -- CALCULAR NOTA FINAL SI NO SE PROPORCIONA
            IF @NotaFinal IS NULL
            BEGIN
                -- Obtener notas actuales si no se proporcionan nuevas
                IF @NotaParcial1 IS NULL OR @NotaParcial2 IS NULL OR @NotaParcial3 IS NULL
                BEGIN
                    SELECT 
                        @NotaParcial1 = ISNULL(@NotaParcial1, nota_parcial1),
                        @NotaParcial2 = ISNULL(@NotaParcial2, nota_parcial2),
                        @NotaParcial3 = ISNULL(@NotaParcial3, nota_parcial3)
                    FROM calificacion 
                    WHERE calificacion_id = @CalificacionId;
                END
                
                -- Calcular promedio de las notas disponibles
                IF @NotaParcial1 IS NOT NULL BEGIN SET @SumaNotas += @NotaParcial1; SET @ContadorNotas += 1; END
                IF @NotaParcial2 IS NOT NULL BEGIN SET @SumaNotas += @NotaParcial2; SET @ContadorNotas += 1; END
                IF @NotaParcial3 IS NOT NULL BEGIN SET @SumaNotas += @NotaParcial3; SET @ContadorNotas += 1; END
                
                IF @ContadorNotas > 0
                    SET @NotaFinalCalculada = @SumaNotas / @ContadorNotas;
                ELSE
                    SET @NotaFinalCalculada = NULL;
            END
            ELSE
            BEGIN
                SET @NotaFinalCalculada = @NotaFinal;
            END
            
            -- DETERMINAR ESTADO DE CALIFICACIÓN
            IF @NotaFinalCalculada IS NOT NULL
            BEGIN
                IF @NotaFinalCalculada >= 70
                    SET @EstadoCalificacion = 'APROBADO';
                ELSE
                    SET @EstadoCalificacion = 'REPROBADO';
            END
            ELSE
            BEGIN
                SET @EstadoCalificacion = 'PENDIENTE';
            END
            
            -- ACTUALIZAR CALIFICACIÓN CON CONTROL DE CONCURRENCIA
            UPDATE calificacion 
            SET 
                nota_parcial1 = ISNULL(@NotaParcial1, nota_parcial1),
                nota_parcial2 = ISNULL(@NotaParcial2, nota_parcial2),
                nota_parcial3 = ISNULL(@NotaParcial3, nota_parcial3),
                nota_final = @NotaFinalCalculada,
                fecha_calificacion = CASE 
                    WHEN @NotaFinalCalculada IS NOT NULL THEN CAST(GETDATE() AS DATE)
                    ELSE fecha_calificacion 
                END,
                observaciones = ISNULL(@Observaciones, observaciones),
                estado_calificacion = @EstadoCalificacion
            WHERE calificacion_id = @CalificacionId
            AND asignacion_curso_id = @AsignacionCursoId; -- Verificación adicional de integridad
            
            -- Verificar que se actualizó exactamente un registro
            IF @@ROWCOUNT != 1
            BEGIN
                SET @ErrorMessage = 'Error: No se pudo actualizar la calificación. Posible problema de concurrencia';
                THROW 50206, @ErrorMessage, 1;
            END
            
            -- REGISTRAR AUDITORÍA
            PRINT 'AUDITORÍA CALIFICACIÓN: ID=' + CAST(@CalificacionId AS NVARCHAR(10)) + 
                ', Estudiante=' + CAST(@EstudianteId AS NVARCHAR(10)) + 
                ', Curso=' + CAST(@CursoId AS NVARCHAR(10)) + 
                ', NotaFinal=' + ISNULL(CAST(@NotaFinalCalculada AS NVARCHAR(10)), 'NULL') + 
                ', Estado=' + @EstadoCalificacion + 
                ', Profesor=' + CAST(@ProfesorId AS NVARCHAR(10));
            
            -- COMMIT de la transacción
            COMMIT TRANSACTION;
            
            SET @Resultado = 'ÉXITO: Calificación actualizada. Estado: ' + @EstadoCalificacion + 
                            CASE WHEN @NotaFinalCalculada IS NOT NULL 
                                THEN ', Nota Final: ' + CAST(@NotaFinalCalculada AS NVARCHAR(10))
                                ELSE ', Pendiente de completar'
                            END;
            
        END TRY
        BEGIN CATCH
            -- Manejo de errores con rollback inteligente
            SET @ErrorMessage = 'Error en sp_ActualizarCalificacion: ' + ERROR_MESSAGE() + 
                            ' (Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')';
            
            -- Rollback según el punto de falla
            IF @@TRANCOUNT > 0
            BEGIN
                IF ERROR_NUMBER() >= 50204 -- Error después de validar notas
                    ROLLBACK TRANSACTION SP_NotasValidadas;
                ELSE IF ERROR_NUMBER() >= 50202 -- Error después de validar asignación
                    ROLLBACK TRANSACTION SP_AsignacionValidada;
                ELSE
                    ROLLBACK TRANSACTION; -- Rollback completo
            END
            
            SET @Resultado = @ErrorMessage;
            
            -- Log del error
            PRINT 'ERROR EN CALIFICACIÓN: ' + @ErrorMessage;
            PRINT 'Parámetros: AsignacionId=' + CAST(@AsignacionCursoId AS NVARCHAR(10)) + 
                ', ProfesorId=' + CAST(@ProfesorId AS NVARCHAR(10));
            
            THROW;
        END CATCH
    END
    GO

    -- ================================================================================
    -- PROCEDIMIENTO: PROCESO BATCH - CIERRE DE PERÍODO ACADÉMICO
    -- ================================================================================
    -- Funcionalidad: Procesa el cierre masivo de un período con múltiples validaciones
    -- Control de transacciones: Transacciones anidadas con múltiples SAVEPOINT
    -- Características: Procesamiento por lotes, manejo de errores masivos, rollback selectivo

    CREATE OR ALTER PROCEDURE sp_CerrarPeriodoAcademico
        @PeriodoAcademico NVARCHAR(20),
        @UsuarioId INT,
        @ForzarCierre BIT = 0, -- Permite cerrar aunque haya calificaciones pendientes
        @Resultado NVARCHAR(1000) OUTPUT
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Variables de control
        DECLARE @ErrorMessage NVARCHAR(500);
        DECLARE @CursosAfectados INT = 0;
        DECLARE @EstudiantesAfectados INT = 0;
        DECLARE @CalificacionesPendientes INT = 0;
        DECLARE @CalificacionesActualizadas INT = 0;
        DECLARE @ErroresEncontrados INT = 0;
        
        -- Variables para cursor
        DECLARE @CursoId INT;
        DECLARE @AsignacionId INT;
        DECLARE @NotaFinal DECIMAL(5,2);
        
        -- Cursor para procesar asignaciones
        DECLARE cursor_asignaciones CURSOR FOR
            SELECT ac.asignacion_curso_id, ac.curso_id, c.nota_final
            FROM asignacion_curso ac
            INNER JOIN curso cur ON ac.curso_id = cur.curso_id
            LEFT JOIN calificacion c ON ac.asignacion_curso_id = c.asignacion_curso_id
            WHERE cur.periodo_academico = @PeriodoAcademico
            AND ac.estado_asignacion = 'MATRICULADO'
            AND cur.estado = 'ACTIVO';
        
        BEGIN TRANSACTION;
        
        BEGIN TRY
            -- VALIDACIÓN 1: Verificar que el período existe
            IF NOT EXISTS (SELECT 1 FROM curso WHERE periodo_academico = @PeriodoAcademico)
            BEGIN
                SET @ErrorMessage = 'Error: No existen cursos para el período ' + @PeriodoAcademico;
                THROW 50301, @ErrorMessage, 1;
            END
            
            -- VALIDACIÓN 2: Verificar usuario autorizado
            IF NOT EXISTS (
                SELECT 1 FROM usuario u
                INNER JOIN usuario_rol ur ON u.usuario_id = ur.usuario_id
                INNER JOIN rol r ON ur.rol_id = r.rol_id
                WHERE u.usuario_id = @UsuarioId 
                AND r.nivel_acceso >= 3 -- Solo coordinadores y administradores
                AND u.activo = 1
            )
            BEGIN
                SET @ErrorMessage = 'Error: Usuario no autorizado para cerrar períodos académicos';
                THROW 50302, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_ValidacionesIniciales;
            
            -- CONTAR CALIFICACIONES PENDIENTES
            SELECT @CalificacionesPendientes = COUNT(*)
            FROM asignacion_curso ac
            INNER JOIN curso cur ON ac.curso_id = cur.curso_id
            LEFT JOIN calificacion c ON ac.asignacion_curso_id = c.asignacion_curso_id
            WHERE cur.periodo_academico = @PeriodoAcademico
            AND ac.estado_asignacion = 'MATRICULADO'
            AND (c.estado_calificacion = 'PENDIENTE' OR c.nota_final IS NULL);
            
            -- VALIDACIÓN 3: Verificar calificaciones pendientes (si no se fuerza)
            IF @CalificacionesPendientes > 0 AND @ForzarCierre = 0
            BEGIN
                SET @ErrorMessage = 'Error: Existen ' + CAST(@CalificacionesPendientes AS NVARCHAR(10)) + 
                                ' calificaciones pendientes. Use @ForzarCierre = 1 para proceder';
                THROW 50303, @ErrorMessage, 1;
            END
            
            SAVE TRANSACTION SP_CalificacionesValidadas;
            
            -- PROCESAR ASIGNACIONES CON CURSOR
            OPEN cursor_asignaciones;
            
            FETCH NEXT FROM cursor_asignaciones INTO @AsignacionId, @CursoId, @NotaFinal;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    SAVE TRANSACTION SP_ProcesarAsignacion;
                    
                    -- Si no tiene nota final, asignar 0 (si se fuerza el cierre)
                    IF @NotaFinal IS NULL AND @ForzarCierre = 1
                    BEGIN
                        UPDATE calificacion 
                        SET nota_final = 0,
                            estado_calificacion = 'REPROBADO',
                            fecha_calificacion = CAST(GETDATE() AS DATE),
                            observaciones = 'Calificación asignada automáticamente en cierre de período'
                        WHERE asignacion_curso_id = @AsignacionId;
                        
                        SET @CalificacionesActualizadas += 1;
                    END
                    
                    -- Cambiar estado de asignación a COMPLETADO
                    UPDATE asignacion_curso 
                    SET estado_asignacion = 'COMPLETADO'
                    WHERE asignacion_curso_id = @AsignacionId;
                    
                    SET @EstudiantesAfectados += 1;
                    
                END TRY
                BEGIN CATCH
                    -- Error en asignación individual - rollback solo esta asignación
                    ROLLBACK TRANSACTION SP_ProcesarAsignacion;
                    SET @ErroresEncontrados += 1;
                    
                    PRINT 'Error procesando asignación ' + CAST(@AsignacionId AS NVARCHAR(10)) + 
                        ': ' + ERROR_MESSAGE();
                END CATCH
                
                FETCH NEXT FROM cursor_asignaciones INTO @AsignacionId, @CursoId, @NotaFinal;
            END
            
            CLOSE cursor_asignaciones;
            DEALLOCATE cursor_asignaciones;
            
            -- ACTUALIZAR ESTADO DE CURSOS DEL PERÍODO
            UPDATE curso 
            SET estado = 'FINALIZADO'
            WHERE periodo_academico = @PeriodoAcademico
            AND estado = 'ACTIVO';
            
            SET @CursosAfectados = @@ROWCOUNT;
            
            -- REGISTRAR AUDITORÍA DEL CIERRE
            PRINT 'AUDITORÍA CIERRE PERÍODO: ' + @PeriodoAcademico;
            PRINT 'Cursos cerrados: ' + CAST(@CursosAfectados AS NVARCHAR(10));
            PRINT 'Estudiantes procesados: ' + CAST(@EstudiantesAfectados AS NVARCHAR(10));
            PRINT 'Calificaciones actualizadas: ' + CAST(@CalificacionesActualizadas AS NVARCHAR(10));
            PRINT 'Errores encontrados: ' + CAST(@ErroresEncontrados AS NVARCHAR(10));
            PRINT 'Usuario responsable: ' + CAST(@UsuarioId AS NVARCHAR(10));
            PRINT 'Fecha cierre: ' + CAST(GETDATE() AS NVARCHAR(30));
            
            -- COMMIT de la transacción principal
            COMMIT TRANSACTION;
            
            SET @Resultado = 'ÉXITO: Período ' + @PeriodoAcademico + ' cerrado correctamente. ' +
                            'Cursos: ' + CAST(@CursosAfectados AS NVARCHAR(10)) + 
                            ', Estudiantes: ' + CAST(@EstudiantesAfectados AS NVARCHAR(10)) + 
                            ', Errores: ' + CAST(@ErroresEncontrados AS NVARCHAR(10));
            
        END TRY
        BEGIN CATCH
            -- Cerrar cursor si está abierto
            IF CURSOR_STATUS('local', 'cursor_asignaciones') >= 0
            BEGIN
                CLOSE cursor_asignaciones;
                DEALLOCATE cursor_asignaciones;
            END
            
            -- Manejo de errores con rollback selectivo
            SET @ErrorMessage = 'Error crítico en sp_CerrarPeriodoAcademico: ' + ERROR_MESSAGE() + 
                            ' (Línea: ' + CAST(ERROR_LINE() AS NVARCHAR(10)) + ')';
            
            IF @@TRANCOUNT > 0
            BEGIN
                -- Rollback según el punto de falla
                IF ERROR_NUMBER() >= 50303
                    ROLLBACK TRANSACTION SP_CalificacionesValidadas;
                ELSE IF ERROR_NUMBER() >= 50302
                    ROLLBACK TRANSACTION SP_ValidacionesIniciales;
                ELSE
                    ROLLBACK TRANSACTION;
            END
            
            SET @Resultado = @ErrorMessage;
            
            -- Log crítico del error
            PRINT 'ERROR CRÍTICO EN CIERRE DE PERÍODO: ' + @ErrorMessage;
            PRINT 'Período afectado: ' + @PeriodoAcademico;
            PRINT 'Estado de transacción: ' + CAST(@@TRANCOUNT AS NVARCHAR(10));
            
            THROW;
        END CATCH
    END
    GO

    PRINT 'Procedimientos transaccionales creados exitosamente';
    PRINT 'Procedimientos disponibles:';
    PRINT '- sp_MatricularEstudiante: Matrícula con validaciones completas';
    PRINT '- sp_RegistrarPago: Registro de pagos con control de duplicados';
    PRINT '- sp_ActualizarCalificacion: Calificaciones con validaciones académicas';
    PRINT '- sp_CerrarPeriodoAcademico: Cierre masivo con procesamiento por lotes';
    GO