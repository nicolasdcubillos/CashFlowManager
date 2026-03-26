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

-- ===========================================================
--  Tabla: CashflowCategory
--  Almacena la estructura del flujo de caja.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.TABLES
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'CashflowCategory'
)
BEGIN
    CREATE TABLE dbo.CashflowCategory (
        Id        VARCHAR(5)    NOT NULL,
        Category  VARCHAR(20)   NOT NULL,  -- INGRESOS / EGRESOS / FINANCIAMIENTO
        ParentName  VARCHAR(150)  NOT NULL,
        ItemOrder INT           NOT NULL,
        CONSTRAINT PK_CashflowCategory PRIMARY KEY (Id)
    );
END

IF NOT EXISTS (SELECT 1 FROM dbo.CashflowCategory)
BEGIN
    INSERT INTO dbo.CashflowCategory (Id, Category, ParentName, ItemOrder) VALUES

    -- INGRESOS
    ('01', 'INGRESOS', 'Proyeccion Ventas Carvajal', 1),
    ('02', 'INGRESOS', 'Clientes Nacionales', 2),
    ('03', 'INGRESOS', 'Clientes Nacionales Carvajal', 3),
    ('04', 'INGRESOS', 'Clientes del Exterior', 4),
    ('05', 'INGRESOS', 'Reverse Factoring', 5),
    ('06', 'INGRESOS', 'Prestamo Pieriplast', 6),
    ('07', 'INGRESOS', 'Otros Ingresos', 7),
    ('08', 'INGRESOS', 'Utilizacion Fiducia Impuesto al Plastico', 8),
    ('09', 'INGRESOS', 'Monetizaciones - Usd a Cop', 9),

    -- EGRESOS
    ('10', 'EGRESOS', 'Pago a Proveedores - Nacionales', 1),
    ('11', 'EGRESOS', 'Pago Mano de Obra Terceros', 2),
    ('12', 'EGRESOS', 'Pago a Proveedores - Exterior', 3),
    ('13', 'EGRESOS', 'Pago Exportaciones', 4),
    ('14', 'EGRESOS', 'Pago Nacionalizaciones Tariff from import', 5),
    ('15', 'EGRESOS', 'Pago OC - OS Prepay', 6),
    ('16', 'EGRESOS', 'Pago Moldes', 7),
    ('17', 'EGRESOS', 'Pago de Facturas Negociables Proveedores Ext', 8),
    ('18', 'EGRESOS', 'Pago al Personal', 9),
    ('19', 'EGRESOS', 'Pago de Impuestos', 10),
    ('20', 'EGRESOS', 'Pago de Servicios', 11),
    ('21', 'EGRESOS', 'Pago Arriendos', 12),

    -- FINANCIAMIENTO
    ('22', 'FINANCIAMIENTO', 'Prestamos Corto Plazo', 1),
    ('23', 'FINANCIAMIENTO', 'Retención Cuota Trimestral - Sindicado LT', 2),
    ('24', 'FINANCIAMIENTO', 'Tarjetas de Crédito', 3),
    ('25', 'FINANCIAMIENTO', 'Leasing Financiero', 4),
    ('26', 'FINANCIAMIENTO', 'Confirming Factoring with vendors', 5),
    ('27', 'FINANCIAMIENTO', 'Intereses Créditos', 6),
    ('28', 'FINANCIAMIENTO', 'Retoma Créditos', 7);
END

-- ===========================================================
--  ALTER: MTPROCLI — agregar referencia a CashflowCategory
--  Agrega CashflowCategoryId (nullable) como FK a
--  CashflowCategory.Id para clasificar cada proveedor/cliente
--  dentro del flujo de caja.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.COLUMNS
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'MTPROCLI'
      AND  COLUMN_NAME  = 'CashflowCategoryId'
)
BEGIN
    ALTER TABLE dbo.MTPROCLI
        ADD CashflowCategoryId VARCHAR(5) NULL;

    ALTER TABLE dbo.MTPROCLI
        ADD CONSTRAINT FK_MTPROCLI_CashflowCategory
            FOREIGN KEY (CashflowCategoryId)
            REFERENCES dbo.CashflowCategory (Id);
END

-- ===========================================================
--  ALTER: TRADE — agregar columna FechaCobro
--  Agrega FechaCobro (datetime, nullable) para almacenar
--  la fecha de cobro asignada desde el front de consulta.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.COLUMNS
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'TRADE'
      AND  COLUMN_NAME  = 'FechaCobro'
)
BEGIN
    ALTER TABLE dbo.TRADE
        ADD FechaCobro DATETIME NULL;
END

-- ===========================================================
--  Configuración: agregar ORIGEN a CashflowManagerConfig
--  si no existe, para indicar el origen por defecto a filtrar.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   dbo.CashflowManagerConfig
    WHERE  Config = 'ORIGEN'
)
BEGIN
    INSERT INTO dbo.CashflowManagerConfig (Config, Value)
    VALUES ('ORIGEN', 'FAC');
END
