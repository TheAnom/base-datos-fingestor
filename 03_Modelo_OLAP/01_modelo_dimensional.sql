-- Data warehouse para analisis
USE BD2_Curso2025;
GO

-- crear esquema DW
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DW')
BEGIN
    EXEC('CREATE SCHEMA DW');
    PRINT 'Esquema DW creado';
END
GO

-- dimension tiempo
CREATE TABLE DW.DimTiempo (
    tiempo_key INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    
    dia INT NOT NULL,
    dia_semana INT NOT NULL,
    nombre_dia NVARCHAR(10) NOT NULL,
    dia_año INT NOT NULL,
    
    semana_año INT NOT NULL,
    
    mes INT NOT NULL,
    nombre_mes NVARCHAR(15) NOT NULL,
    mes_año NVARCHAR(7) NOT NULL,
    
    trimestre INT NOT NULL,
    nombre_trimestre NVARCHAR(10) NOT NULL,
    trimestre_año NVARCHAR(7) NOT NULL,
    
    año INT NOT NULL,
    
    periodo_academico NVARCHAR(10),
    es_periodo_lectivo BIT DEFAULT 1,
    
    es_fin_semana BIT NOT NULL,
    es_festivo BIT DEFAULT 0,
    nombre_festivo NVARCHAR(50),
    
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- dimension estudiante
CREATE TABLE DW.DimEstudiante (
    estudiante_key INT IDENTITY(1,1) PRIMARY KEY,
    estudiante_id INT NOT NULL,
    
    nombre_completo NVARCHAR(100) NOT NULL,
    documento_identidad NVARCHAR(20),
    
    grado_id INT,
    grado_nombre NVARCHAR(50),
    nivel_educativo NVARCHAR(50),
    
    institucion NVARCHAR(100),
    
    edad_ingreso INT,
    año_ingreso INT,
    
    estado_actual NVARCHAR(20),
    es_activo BIT DEFAULT 1,
    
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- DIMENSIÓN CURSO
CREATE TABLE DW.DimCurso (
    curso_key INT IDENTITY(1,1) PRIMARY KEY,
    curso_id INT NOT NULL, -- FK al sistema transaccional
    
    -- Información del curso
    nombre_curso NVARCHAR(100) NOT NULL,
    codigo_curso NVARCHAR(10),
    
    -- Jerarquía académica
    area_conocimiento NVARCHAR(50), -- Matemáticas, Ciencias, Humanidades
    materia NVARCHAR(100),
    
    -- Información del profesor
    profesor_id INT,
    profesor_nombre NVARCHAR(100),
    especialidad_profesor NVARCHAR(100),
    
    -- Características del curso
    creditos INT,
    horas_semanales INT,
    nivel_dificultad NVARCHAR(20), -- Básico, Intermedio, Avanzado
    
    -- Período académico
    periodo_academico NVARCHAR(20),
    
    -- Indicadores
    es_obligatorio BIT DEFAULT 1,
    es_activo BIT DEFAULT 1,
    
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- dimension concepto de pago
CREATE TABLE DW.DimConceptoPago (
    concepto_pago_key INT IDENTITY(1,1) PRIMARY KEY,
    concepto_pago_id INT NOT NULL,
    
    nombre_concepto NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(300),
    
    tipo_concepto NVARCHAR(50),
    categoria_financiera NVARCHAR(50),
    
    monto_base DECIMAL(10,2),
    es_obligatorio BIT,
    permite_fraccionamiento BIT DEFAULT 0,
    
    es_activo BIT DEFAULT 1,
    
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- dimension usuario
CREATE TABLE DW.DimUsuario (
    usuario_key INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    
    nombre_usuario NVARCHAR(50) NOT NULL,
    nombre_completo NVARCHAR(100),
    
    rol_nombre NVARCHAR(50),
    nivel_acceso INT,
    departamento NVARCHAR(50),
    
    es_activo BIT DEFAULT 1,
    
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- tabla de hechos calificaciones
CREATE TABLE DW.FactCalificaciones (
    calificacion_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    tiempo_key INT NOT NULL,
    estudiante_key INT NOT NULL,
    curso_key INT NOT NULL,
    
    calificacion_id INT NOT NULL,
    asignacion_curso_id INT NOT NULL,
    
    nota_parcial1 DECIMAL(5,2),
    nota_parcial2 DECIMAL(5,2),
    nota_parcial3 DECIMAL(5,2),
    nota_final DECIMAL(5,2),
    
    promedio_parciales DECIMAL(5,2),
    diferencia_final_promedio DECIMAL(5,2),
    
    es_aprobado BIT,
    es_excelente BIT,
    es_bueno BIT,
    es_regular BIT,
    requiere_refuerzo BIT,
    
    -- Métricas de tiempo
    dias_para_calificar INT, -- Días entre asignación y calificación
    
    -- Metadatos
    fecha_carga DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas
    CONSTRAINT FK_FactCalif_Tiempo FOREIGN KEY (tiempo_key) REFERENCES DW.DimTiempo(tiempo_key),
    CONSTRAINT FK_FactCalif_Estudiante FOREIGN KEY (estudiante_key) REFERENCES DW.DimEstudiante(estudiante_key),
    CONSTRAINT FK_FactCalif_Curso FOREIGN KEY (curso_key) REFERENCES DW.DimCurso(curso_key)
);

-- TABLA DE HECHOS: PAGOS
CREATE TABLE DW.FactPagos (
    pago_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves foráneas a dimensiones
    tiempo_key INT NOT NULL,
    estudiante_key INT NOT NULL,
    concepto_pago_key INT NOT NULL,
    usuario_key INT NOT NULL,
    
    -- Identificadores del sistema transaccional
    pago_id INT NOT NULL,
    
    -- Métricas financieras
    monto_pagado DECIMAL(10,2) NOT NULL,
    monto_base_concepto DECIMAL(10,2),
    diferencia_monto DECIMAL(10,2), -- Diferencia entre pagado y base
    
    -- Información del pago
    metodo_pago NVARCHAR(50),
    numero_recibo NVARCHAR(20),
    
    -- Indicadores de pago
    es_pago_completo BIT,
    es_pago_parcial BIT,
    es_pago_excedente BIT,
    es_pago_puntual BIT, -- Pagado en fecha esperada
    
    -- Métricas de tiempo
    dia_mes_pago INT, -- Día del mes en que se pagó
    es_inicio_mes BIT, -- Primeros 10 días
    es_medio_mes BIT,  -- Días 11-20
    es_fin_mes BIT,    -- Días 21-31
    
    -- Metadatos
    fecha_carga DATETIME2 DEFAULT GETDATE(),
    
    -- Claves foráneas
    CONSTRAINT FK_FactPago_Tiempo FOREIGN KEY (tiempo_key) REFERENCES DW.DimTiempo(tiempo_key),
    CONSTRAINT FK_FactPago_Estudiante FOREIGN KEY (estudiante_key) REFERENCES DW.DimEstudiante(estudiante_key),
    CONSTRAINT FK_FactPago_Concepto FOREIGN KEY (concepto_pago_key) REFERENCES DW.DimConceptoPago(concepto_pago_key),
    CONSTRAINT FK_FactPago_Usuario FOREIGN KEY (usuario_key) REFERENCES DW.DimUsuario(usuario_key)
);

-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS OLAP

-- Índices en dimensiones (campos de jerarquía)
CREATE NONCLUSTERED INDEX IX_DimTiempo_Año_Mes ON DW.DimTiempo(año, mes);
CREATE NONCLUSTERED INDEX IX_DimTiempo_Periodo ON DW.DimTiempo(periodo_academico);
CREATE NONCLUSTERED INDEX IX_DimTiempo_Trimestre ON DW.DimTiempo(año, trimestre);

CREATE NONCLUSTERED INDEX IX_DimEstudiante_Grado ON DW.DimEstudiante(grado_nombre, nivel_educativo);
CREATE NONCLUSTERED INDEX IX_DimEstudiante_Institucion ON DW.DimEstudiante(institucion);
CREATE NONCLUSTERED INDEX IX_DimEstudiante_Vigencia ON DW.DimEstudiante(es_vigente, fecha_inicio_vigencia);

CREATE NONCLUSTERED INDEX IX_DimCurso_Area ON DW.DimCurso(area_conocimiento, materia);
CREATE NONCLUSTERED INDEX IX_DimCurso_Profesor ON DW.DimCurso(profesor_nombre, especialidad_profesor);
CREATE NONCLUSTERED INDEX IX_DimCurso_Periodo ON DW.DimCurso(periodo_academico);

CREATE NONCLUSTERED INDEX IX_DimConcepto_Tipo ON DW.DimConceptoPago(tipo_concepto, categoria_financiera);

-- Índices en tablas de hechos (claves foráneas y métricas)
CREATE NONCLUSTERED INDEX IX_FactCalif_Tiempo_Estudiante ON DW.FactCalificaciones(tiempo_key, estudiante_key);
CREATE NONCLUSTERED INDEX IX_FactCalif_Curso_Tiempo ON DW.FactCalificaciones(curso_key, tiempo_key);
CREATE NONCLUSTERED INDEX IX_FactCalif_NotaFinal ON DW.FactCalificaciones(nota_final, es_aprobado);

CREATE NONCLUSTERED INDEX IX_FactPago_Tiempo_Concepto ON DW.FactPagos(tiempo_key, concepto_pago_key);
CREATE NONCLUSTERED INDEX IX_FactPago_Estudiante_Tiempo ON DW.FactPagos(estudiante_key, tiempo_key);
CREATE NONCLUSTERED INDEX IX_FactPago_Monto ON DW.FactPagos(monto_pagado, metodo_pago);

PRINT 'Modelo Dimensional creado exitosamente';
PRINT 'Esquema: Estrella con 5 dimensiones y 2 tablas de hechos';
PRINT 'Dimensiones: Tiempo, Estudiante, Curso, ConceptoPago, Usuario';
PRINT 'Hechos: Calificaciones, Pagos';
GO