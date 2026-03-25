-- ===========================================================
--  CashFlowManager - DDL de tablas de configuracion
--  Autor: Nicolas David Cubillos
--  Descripcion:
--    Crea la tabla CashflowManagerConfig si no existe y la
--    inicializa con los valores por defecto de semanas.
-- ===========================================================

USE INTECPL;

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.TABLES
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'CashflowManagerConfig'
)
BEGIN
    CREATE TABLE dbo.CashflowManagerConfig (
        Config NVARCHAR(100) NOT NULL,
        Value  NVARCHAR(MAX) NULL,
        CONSTRAINT PK_CashflowManagerConfig PRIMARY KEY (Config)
    );

    -- Valores iniciales por defecto
    INSERT INTO dbo.CashflowManagerConfig (Config, Value) VALUES ('SemanasAtras',    '6');
    INSERT INTO dbo.CashflowManagerConfig (Config, Value) VALUES ('SemanasAdelante', '6');
END

-- ===========================================================
--  Tabla: CashflowProjection
--  Almacena la proyeccion total de flujo de caja por NIT,
--  año e ISO semana.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.TABLES
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'CashflowProjection'
)
BEGIN
    CREATE TABLE dbo.CashflowProjection (
        NIT             NVARCHAR(20)   NOT NULL,
        Year            SMALLINT       NOT NULL,
        Week            TINYINT        NOT NULL,
        TotalProjected  DECIMAL(18, 2) NOT NULL DEFAULT 0,
        CONSTRAINT PK_CashflowProjection PRIMARY KEY (NIT, Year, Week)
    );
END