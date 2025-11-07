-- Data warehouse del sistema educativo
USE BD2_Curso2025;
GO

-- Esquema para el data warehouse
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DW')
BEGIN
    EXEC('CREATE SCHEMA DW');
    PRINT 'Esquema DW creado';
END
GO

-- Dimension tiempo
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

-- Dimension estudiantes
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
    
    -- control de versiones
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- Dimension cursos
CREATE TABLE DW.DimCurso (
    curso_key INT IDENTITY(1,1) PRIMARY KEY,
    curso_id INT NOT NULL,
    
    nombre_curso NVARCHAR(100) NOT NULL,
    codigo_curso NVARCHAR(10),
    
    area_conocimiento NVARCHAR(50),
    materia NVARCHAR(100),
    
    profesor_id INT,
    profesor_nombre NVARCHAR(100),
    especialidad_profesor NVARCHAR(100),
    
    creditos INT,
    horas_semanales INT,
    nivel_dificultad NVARCHAR(20),
    
    periodo_academico NVARCHAR(20),
    
    es_obligatorio BIT DEFAULT 1,
    es_activo BIT DEFAULT 1,
    
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- Dimension conceptos de pago
CREATE TABLE DW.DimConceptoPago (
    concepto_pago_key INT IDENTITY(1,1) PRIMARY KEY,
    concepto_pago_id INT NOT NULL,
    
    -- Info del concepto
    nombre_concepto NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(300),
    
    -- Clasificación
    tipo_concepto NVARCHAR(50),
    categoria_financiera NVARCHAR(50),
    
    -- Info financiera
    monto_base DECIMAL(10,2),
    es_obligatorio BIT,
    permite_fraccionamiento BIT DEFAULT 0,
    
    -- Estado
    es_activo BIT DEFAULT 1,
    
    -- Control de versiones
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- Dimension usuarios
CREATE TABLE DW.DimUsuario (
    usuario_key INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    
    -- Info del usuario
    nombre_usuario NVARCHAR(50) NOT NULL,
    nombre_completo NVARCHAR(100),
    
    -- Info organizacional
    rol_nombre NVARCHAR(50),
    nivel_acceso INT,
    departamento NVARCHAR(50),
    
    -- Estado
    es_activo BIT DEFAULT 1,
    
    -- Control de versiones
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    es_vigente BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT GETDATE()
);

-- Tabla de hechos calificaciones
CREATE TABLE DW.FactCalificaciones (
    calificacion_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Referencias a las dimensiones
    tiempo_key INT NOT NULL,
    estudiante_key INT NOT NULL,
    curso_key INT NOT NULL,
    
    -- IDs del sistema original
    calificacion_id INT NOT NULL,
    asignacion_curso_id INT NOT NULL,
    
    -- Las notas
    nota_parcial1 DECIMAL(5,2),
    nota_parcial2 DECIMAL(5,2),
    nota_parcial3 DECIMAL(5,2),
    nota_final DECIMAL(5,2),
    
    -- Cálculos útiles
    promedio_parciales DECIMAL(5,2),
    diferencia_final_promedio DECIMAL(5,2),
    
    -- Indicadores para análisis rápido
    es_aprobado BIT,
    es_excelente BIT,
    es_bueno BIT,
    es_regular BIT,
    requiere_refuerzo BIT,
    
    -- Tiempo que tardó en calificar
    dias_para_calificar INT,
    
    fecha_carga DATETIME2 DEFAULT GETDATE(),
    
    -- Relaciones
    CONSTRAINT FK_FactCalif_Tiempo FOREIGN KEY (tiempo_key) REFERENCES DW.DimTiempo(tiempo_key),
    CONSTRAINT FK_FactCalif_Estudiante FOREIGN KEY (estudiante_key) REFERENCES DW.DimEstudiante(estudiante_key),
    CONSTRAINT FK_FactCalif_Curso FOREIGN KEY (curso_key) REFERENCES DW.DimCurso(curso_key)
);

-- Tabla de hechos pagos
CREATE TABLE DW.FactPagos (
    pago_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Referencias a dimensiones
    tiempo_key INT NOT NULL,
    estudiante_key INT NOT NULL,
    concepto_pago_key INT NOT NULL,
    usuario_key INT NOT NULL,
    
    -- ID del sistema original
    pago_id INT NOT NULL,
    
    -- Info del pago
    monto_pagado DECIMAL(10,2) NOT NULL,
    monto_base_concepto DECIMAL(10,2),
    diferencia_monto DECIMAL(10,2),
    
    -- Detalles
    metodo_pago NVARCHAR(50),
    numero_recibo NVARCHAR(20),
    
    -- Indicadores útiles para análisis
    es_pago_completo BIT,
    es_pago_parcial BIT,
    es_pago_excedente BIT,
    es_pago_puntual BIT,
    
    -- Info de cuándo se pagó en el mes
    dia_mes_pago INT,
    es_inicio_mes BIT,
    es_medio_mes BIT,
    es_fin_mes BIT,
    
    fecha_carga DATETIME2 DEFAULT GETDATE(),
    
    -- Relaciones
    CONSTRAINT FK_FactPago_Tiempo FOREIGN KEY (tiempo_key) REFERENCES DW.DimTiempo(tiempo_key),
    CONSTRAINT FK_FactPago_Estudiante FOREIGN KEY (estudiante_key) REFERENCES DW.DimEstudiante(estudiante_key),
    CONSTRAINT FK_FactPago_Concepto FOREIGN KEY (concepto_pago_key) REFERENCES DW.DimConceptoPago(concepto_pago_key),
    CONSTRAINT FK_FactPago_Usuario FOREIGN KEY (usuario_key) REFERENCES DW.DimUsuario(usuario_key)
);

-- Indices para mejorar rendimiento
CREATE NONCLUSTERED INDEX IX_DimTiempo_Año_Mes ON DW.DimTiempo(año, mes);
CREATE NONCLUSTERED INDEX IX_DimTiempo_Periodo ON DW.DimTiempo(periodo_academico);
CREATE NONCLUSTERED INDEX IX_DimEstudiante_Grado ON DW.DimEstudiante(grado_nombre, nivel_educativo);
CREATE NONCLUSTERED INDEX IX_DimCurso_Area ON DW.DimCurso(area_conocimiento, materia);
CREATE NONCLUSTERED INDEX IX_FactCalif_Tiempo_Estudiante ON DW.FactCalificaciones(tiempo_key, estudiante_key);
CREATE NONCLUSTERED INDEX IX_FactPago_Tiempo_Concepto ON DW.FactPagos(tiempo_key, concepto_pago_key);

PRINT 'Data warehouse creado';
PRINT '5 dimensiones y 2 tablas de hechos listas';
GO