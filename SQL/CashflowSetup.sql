-- ===========================================================
--  CashFlowManager - Setup centralizado
--  Autor: Nicolas David Cubillos
--  Descripcion:
--    Script único de despliegue: crea tablas, aplica ALTERs
--    y define funciones del módulo CashFlowManager.
--    Idempotente: puede ejecutarse múltiples veces sin error.
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

-- ===========================================================
--  Tabla: CashflowBankClassification
--  Catálogo de clasificación de moneda para cuentas bancarias.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.TABLES
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'CashflowBankClassification'
)
BEGIN
    CREATE TABLE dbo.CashflowBankClassification (
        Id          VARCHAR(3)    NOT NULL,
        Descripcion NVARCHAR(100) NOT NULL,
        ItemOrder   TINYINT       NOT NULL DEFAULT 0,
        CONSTRAINT PK_CashflowBankClassification PRIMARY KEY (Id)
    );

    INSERT INTO dbo.CashflowBankClassification (Id, Descripcion, ItemOrder) VALUES
        ('COP', 'Pesos Colombianos', 1),
        ('USD', 'Dólares Americanos', 2),
        ('PCA', 'PA Credicorp - Excedentes', 3);
END

-- Idempotente: agrega PCA si la tabla ya existía antes de este script
IF NOT EXISTS (SELECT 1 FROM dbo.CashflowBankClassification WHERE Id = 'PCA')
    INSERT INTO dbo.CashflowBankClassification (Id, Descripcion, ItemOrder)
    VALUES ('PCA', 'PA Credicorp - Excedentes', 3);

-- ===========================================================
--  ALTER: MTBANCOS — agregar referencia a CashflowBankClassification
--  Agrega CashflowBankClassificationId (nullable) como FK a
--  CashflowBankClassification.Id para indicar la moneda de
--  cada cuenta bancaria en el flujo de caja.
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM   INFORMATION_SCHEMA.COLUMNS
    WHERE  TABLE_SCHEMA = 'dbo'
      AND  TABLE_NAME   = 'MTBANCOS'
      AND  COLUMN_NAME  = 'CashflowBankClassificationId'
)
BEGIN
    ALTER TABLE dbo.MTBANCOS
        ADD CashflowBankClassificationId VARCHAR(3) NULL;

    ALTER TABLE dbo.MTBANCOS
        ADD CONSTRAINT FK_MTBANCOS_CashflowBankClassification
            FOREIGN KEY (CashflowBankClassificationId)
            REFERENCES dbo.CashflowBankClassification (Id);
END
GO

-- Nota: la consulta de saldo bancario por moneda reutiliza la función
-- legacy dbo.fnvOF_ReporteMVBancos_Saldos filtrando por
-- MTBANCOS.CashflowBankClassificationId. Ver CashFlowRepository.GetBankBalanceTotal.
--
-- Uso de referencia:
--   SELECT SUM(s.Saldo_Final)
--   FROM dbo.fnvOF_ReporteMVBancos_Saldos('2026-04-25', '2026-04-25') s
--   INNER JOIN dbo.MTBANCOS b ON RTRIM(b.CODIGOCTA) = RTRIM(s.Banco)
--   WHERE b.CashflowBankClassificationId = 'COP'  -- o 'USD'
GO
