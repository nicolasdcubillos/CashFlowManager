USE LERNER_PLUS;

/* Script para crear la tabla X_SIGLAUBICA */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'X_SIGLAUBICA'
)
BEGIN
    CREATE TABLE [dbo].[X_SIGLAUBICA](
[SIGLA] [char](5) NULL,
[GRUPO] [nchar](40) NULL,
[CODCC] [varchar](20) NULL,
[ELIMINAR] [bit] NULL
) ON [PRIMARY]
END;

/* Script para crear el campo Sigla si no existe en MTUBICA */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'MTUBICA'
    AND COLUMN_NAME = 'SIGLA'
)
BEGIN
    ALTER TABLE MTUBICA
    ADD SIGLA VARCHAR(20);
END;

/* Creando el campo RQ_CANTIDAD_OC si no existe en MVTRADE */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'MVTRADE'
    AND COLUMN_NAME = 'RQ_CANTIDAD_OC'
)
BEGIN
    ALTER TABLE MVTRADE
    ADD RQ_CANTIDAD_OC NUMERIC;
END;

GO
/*
Creando el campo RQ_ESTADO si no existe en MVTRADE

ESTADOS POSIBLES:
0. RQ creada
1. Enviado a despacho
2. OC creada
3. Enviado a despacho & OC creada
*/

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'MVTRADE'
    AND COLUMN_NAME = 'RQ_ESTADO'
)
BEGIN
    ALTER TABLE MVTRADE
    ADD RQ_ESTADO NUMERIC;
END;

/* Creando el campo X_CURRENT si no existe en TIPODCTO */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'TIPODCTO'
    AND COLUMN_NAME = 'X_CURRENT'
)
BEGIN
    ALTER TABLE TIPODCTO
    ADD X_CURRENT NUMERIC;
END;

DROP PROCEDURE dbo.RQ_SaldoInventarioProducto;
GO
DROP PROCEDURE dbo.GuardarTradeRequisicion;
GO
DROP PROCEDURE dbo.GuardarMvTradeRequisicion;
GO
DROP FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
GO
DROP FUNCTION [dbo].[RQ_ConsolidadoRequisicionesRango]
GO
DROP VIEW [dbo].[X_VTEMP_UBICACIONES]
GO
DROP VIEW [dbo].[X_SIGLASCODCC]
GO
DROP PROCEDURE dbo.X_ACTUALIZA_SIGLAUBICA;
GO
DROP PROCEDURE dbo.X_ACTUALIZA_SIGLACODCC;
GO
DROP FUNCTION dbo.RQ_SaldosInventario;
GO

/*
Function GuardarTradeRequisicion:
Función que guarda una línea de requisición en Trade.
Parámetros:
Los necesarios para almacenar la información en Trade.
*/

CREATE PROCEDURE dbo.GuardarTradeRequisicion
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codResponsable VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@rqTipoDcto VARCHAR(255),
@rqNroDcto INTEGER
AS
BEGIN

INSERT INTO
TRADE
(
ORIGEN,
TIPODCTO,
NRODCTO,
FECHA,
FECING,
HORA,
NIT,
PASSWORDIN,
NITRESP,
CODCC,
DCTOPRV,
ACTIVA,
AUTORIZA,
APRUEBA,
APROBADO,
AUTORET,
CALRETE,
CALRETICA,
ORDEN)
VALUES
(
'COM', /* Origen */
@rqTipoDcto, /* Tipodcto */
@rqNroDcto, /* Nrodcto */
CONVERT(DATE, GETDATE()), /* Fecha */
CONVERT(DATE, GETDATE()), /* Fecing */
(SELECT CONVERT(VARCHAR(8), GETDATE(), 108)), /* Hora */
CASE WHEN @codProveedor = '0' THEN '0' ELSE (SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codProveedor) END, /* Nit */
@gCodUsuario, /* Passwordin */
@codResponsable, /* Nitresp */
@codSede, /* Codcc */
@rqNroDcto, /* Dctoprv */
1,			/* Activa */
1,			/* Autoriza */
1,			/* Aprueba */
1,			/* Aprobado */
1,			/* Autoret */
1,			/* Calrete */
1,			/* Calretica */
@rqNroDcto);/* Orden */
END;
GO

/*
Function GuardarMvTradeRequisicion:
Función que guarda una línea de requisición en MvTrade.
Parámetros:
Los necesarios para almacenar la información en MvTrade.
*/

CREATE PROCEDURE dbo.GuardarMvTradeRequisicion
@codProveedor VARCHAR(255),
@gCodUsuario VARCHAR(255),
@codSede VARCHAR(255),
@codISBN VARCHAR(255),
@cantidad VARCHAR(255),
@precio NUMERIC(12, 2),
@rqTipoDcto VARCHAR(255),
@rqNroDcto INTEGER,
@nota VARCHAR(50),
@tipoDctoPc VARCHAR(255),
@norden INTEGER
AS
BEGIN
    INSERT INTO
MVTRADE
(
ORIGEN,
TIPODCTO,
NRODCTO,
FECHA,
FECING,
NIT,
PRODUCTO,
NOMBRE,
CANTIDAD,
CANTORIG,
RQ_CANTIDAD_OC,
CANVENTA,
CODCC,
TIPOMVTO,
UNDBASE,
UNDVENTA,
VALORUNIT,
VLRVENTA,
PASSWORDIN,
RQ_ESTADO,
BODEGA,
NOTA,
ITEMICA,
ITEMIVA,
ORDENPRV,
TIPODCTOPC,
NORDEN)
VALUES
(
'COM',				/* Origen */
@rqTipoDcto,		/* Tipodcto */
@rqNroDcto,			/* Nrodcto */
CONVERT(DATE, GETDATE()),			/* Fecha */
CONVERT(DATE, GETDATE()),			/* Fecing */
CASE WHEN @codProveedor = '0' THEN '0' ELSE (SELECT NIT FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = @codproveedor) END, /* Nit */
@codISBN,			/* Producto */
(SELECT DESCRIPCIO FROM MTMERCIA WHERE CODIGO = @codISBN), /* Nombre */
@cantidad,			/* Cantidad */
@cantidad,			/* Cantorig */
ISNULL(@cantidad, 0), /* RQ_Cantidad_OC */
@cantidad,			/* Canventa */
@codSede,			/* Codcc */
'0',				/* Tipomvto */
(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN), /* Undbase */
(SELECT UNIDADMED FROM MTMERCIA WHERE CODIGO = @codISBN), /* Undventa */
@precio,			/* Valorunit */
@precio,			/* Vlrventa */
@gCodUsuario,		/* Passwordin */
0,					/* RQ_Estado */
'C',				/* Bodega */
@nota,				/* Nota */
1,					/* ITEMICA */
1,					/* ITEMIVA */
0,					/* ORDENPRV */
@tipoDctoPc,		/* TIPODCTOPC */
@norden);			/* NORDEN */

END;
GO

/*
Function RQ_ConsolidadoRequisiciones:
Esta función retorna el consolidado de requisiciones dada una fecha inicial y final.
Revisará si el estado de la RQ es cero o nulo, significa que la RQ no ha sido pasada a despacho y/o órden de compra.
Parámetros:
@fecha1: Fecha inicial de la consulta
@fecha2: Fecha final de la consulta
@rqTipoDcto: El tipo de documento sobre el cual se va a generar la consulta
*/

CREATE FUNCTION [dbo].[RQ_ConsolidadoRequisiciones]
(
@fecha1 date,
@fecha2 date,
@rqTipoDcto VARCHAR(255)
)
Returns Table
AS
Return
(
SELECT
CONVERT(VARCHAR, TRADE.FECING, 23) AS FECING,
RTRIM(TRADE.TIPODCTO) AS TIPODCTO,
RTRIM(TRADE.NRODCTO) AS NRODCTO,
MVTRADE.IDMVTRADE,
MVTRADE.PRODUCTO,
MVTRADE.NOMBRE,
MVTRADE.CODCC,
(SELECT CAST(MTPROCLI.DETALLE AS VARCHAR(50)) FROM MTMERCIA, MTPROCLI WHERE MTMERCIA.CODIGO = MVTRADE.PRODUCTO AND CAST(MTPROCLI.DETALLE AS VARCHAR(255))= MTMERCIA.CLASIFICA2) AS CODPROVEEDOR,
ISNULL((SELECT PRECIO FROM MVPRECIO WHERE CODPRODUC = MVTRADE.PRODUCTO AND CODPRECIO = '1'), 0) VALORUNIT,
MVTRADE.NOTA,
CAST(MVTRADE.CANTIDAD AS INTEGER) AS CANTIDAD,
0 AS CHECKOC,
0 AS CANTIDAD_OC,
0 UBICACION1,
0 UBICACION2,
0 UBICACION3,
0 UBICACION4,
CAST(ISNULL((SELECT SUM(SALDO) FROM FNVOF_REPORTECATALOGO(YEAR(@fecha2), MONTH(@fecha2)) WHERE PRODUCTO = MVTRADE.PRODUCTO), 0) AS INTEGER) AS TOTAL_SALDO_INVENTARIO
FROM
TRADE,
MVTRADE
WHERE
TRADE.TIPODCTO = @rqTipoDcto AND
TRADE.NRODCTO = MVTRADE.NRODCTO AND
TRADE.TIPODCTO = MVTRADE.TIPODCTO AND
TRADE.ORIGEN = MVTRADE.ORIGEN AND
TRADE.FECING BETWEEN @fecha1 AND DATEADD(DAY, 1, @fecha2) AND
(MVTRADE.RQ_ESTADO IS NULL OR MVTRADE.RQ_ESTADO = 0)
)

GO

/*
Function RQ_ConsolidadoRequisicionesRango:
Esta función retorna el consolidado de requisiciones dada un número de documento inicial y final
Revisará si el estado de la RQ es cero o nulo, significa que la RQ no ha sido pasada a despacho y/o órden de compra.
Parámetros:
@fecha1: Fecha inicial de la consulta
@fecha2: Fecha final de la consulta
@rqTipoDcto: El tipo de documento sobre el cual se va a generar la consulta
*/

CREATE FUNCTION [dbo].[RQ_ConsolidadoRequisicionesRango]
(
@desde VARCHAR(255),
@hasta VARCHAR(255),
@rqTipoDcto VARCHAR(255)
)
Returns Table
AS
Return
(
SELECT
CONVERT(VARCHAR, TRADE.FECING, 23) AS FECING,
RTRIM(TRADE.TIPODCTO) AS TIPODCTO,
RTRIM(TRADE.NRODCTO) AS NRODCTO,
MVTRADE.IDMVTRADE,
MVTRADE.PRODUCTO,
MVTRADE.NOMBRE,
MVTRADE.CODCC,
(SELECT CAST(MTPROCLI.DETALLE AS VARCHAR(50)) FROM MTMERCIA, MTPROCLI WHERE MTMERCIA.CODIGO = MVTRADE.PRODUCTO AND CAST(MTPROCLI.DETALLE AS VARCHAR(255))= MTMERCIA.CLASIFICA2) AS CODPROVEEDOR,
ISNULL((SELECT PRECIO FROM MVPRECIO WHERE CODPRODUC = MVTRADE.PRODUCTO AND CODPRECIO = '1'), 0) VALORUNIT,
MVTRADE.NOTA,
CAST(MVTRADE.CANTIDAD AS INTEGER) AS CANTIDAD,
0 AS CHECKOC,
CAST(MVTRADE.RQ_CANTIDAD_OC AS INTEGER) AS CANTIDAD_OC,
0 UBICACION1,
0 UBICACION2,
0 UBICACION3,
0 UBICACION4,
CAST(ISNULL((SELECT SUM(SALDO) FROM FNVOF_REPORTECATALOGO(YEAR(GETDATE()), MONTH(GETDATE())) WHERE PRODUCTO = MVTRADE.PRODUCTO), 0) AS INTEGER) AS TOTAL_SALDO_INVENTARIO
FROM
TRADE,
MVTRADE
WHERE
TRADE.TIPODCTO = @rqTipoDcto AND
TRADE.NRODCTO = MVTRADE.NRODCTO AND
TRADE.TIPODCTO = MVTRADE.TIPODCTO AND
TRADE.ORIGEN = MVTRADE.ORIGEN AND
CAST(TRADE.NRODCTO AS INTEGER) BETWEEN CAST(@desde AS INTEGER) AND CAST(@hasta AS INTEGER) AND
(MVTRADE.RQ_ESTADO IS NULL OR MVTRADE.RQ_ESTADO = 0)
)

GO

/*
Procedure RQ_SaldosInventario:
Función que consulta los saldos de un producto que recibe por parámetro y recibe el saldo agrupado por GRUPO configurado en las tablas.
Parámetros:
@producto - Código del producto a buscar
*/

CREATE FUNCTION [dbo].[RQ_SaldosInventario]
(
    @fecha1 DATE,
    @fecha2 DATE,
@rqTipoDcto VARCHAR(255)
)
Returns Table
AS
Return
(
SELECT
UBICACIONES.GRUPO, UBICACIONES.CODCC, CONSOLIDADO.PRODUCTO, SUM (SALDO) AS SALDO
FROM
X_SIGLAUBICA UBICACIONES
LEFT OUTER JOIN
MTUBICA
ON
UBICACIONES.SIGLA = MTUBICA.SIGLA
LEFT OUTER JOIN
FNVOF_REPORTECATALOGO(YEAR(GETDATE()), MONTH(GETDATE())) SALDOS
ON
SALDOS.UBICACION = MTUBICA.CODUBICA
FULL JOIN
RQ_ConsolidadoRequisiciones(@fecha1, @fecha2, @rqTipoDcto) CONSOLIDADO
ON
CONSOLIDADO.PRODUCTO = SALDOS.PRODUCTO
GROUP BY UBICACIONES.GRUPO, UBICACIONES.CODCC, UBICACIONES.GRUPO, CONSOLIDADO.PRODUCTO
)

/*
SELECT * FROM RQ_SaldosInventario('19990101', '20250101', 'RQ')
*/

GO

/*
Procedure RQ_SaldoInventarioProducto:
Este procedure consulta el saldo de inventario para las RQs encontradas en un rango de fechas y por medio de la
función PIVOT la retorna en columnas variables (columna por ubicación y su saldo de inventario).
El número de columnas varía dependiendo de las sedes que se tengan creadas en el sistema.
Parámetros:
@fecha1: Fecha inicial de la consulta
@fecha2: Fecha final de la consulta
@rqTipoDcto: El tipo de documento sobre el cual se va a generar la consulta
*/

CREATE PROCEDURE [dbo].[RQ_SaldoInventarioProducto]
(
    @fecha1 DATE,
    @fecha2 DATE,
@rqTipoDcto VARCHAR(255)
)
AS
BEGIN
    DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
    DECLARE @year INT = YEAR(@fecha2);
    DECLARE @month INT = MONTH(@fecha2);

    -- Get the distinct GRUPO values and concatenate them into a string
    SELECT @columns = STUFF((
SELECT DISTINCT ', ' + QUOTENAME(GRUPO)
FROM X_VTEMP_UBICACIONES
FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    -- Build the dynamic SQL query
    SET @sql = N'
    SELECT ' + @columns + ', TIPODCTO, NRODCTO, PRODUCTO, IDMVTRADE
    FROM
    (
        SELECT
            Requisiciones.TIPODCTO,
            Requisiciones.NRODCTO,
            Requisiciones.PRODUCTO,
Requisiciones.IDMVTRADE,
            UBIC.GRUPO,
            COALESCE(CAST(SUM(ISNULL(RCATALOGO.SALDO, 0)) AS INT), 0) AS SALDO
        FROM
            (SELECT DISTINCT TIPODCTO, NRODCTO, PRODUCTO, IDMVTRADE
             FROM RQ_ConsolidadoRequisiciones(''' + CONVERT(NVARCHAR, @fecha1, 112) + ''', ''' + CONVERT(NVARCHAR, @fecha2, 112) + ''', ''' + @rqTipoDcto + ''')
            ) AS Requisiciones
        LEFT JOIN
            FNVOF_REPORTECATALOGO(' + CAST(@year AS NVARCHAR(4)) + ', ' + CAST(@month AS NVARCHAR(2)) + ') RCATALOGO
        ON
            Requisiciones.PRODUCTO = RCATALOGO.PRODUCTO
        LEFT JOIN
            X_VTEMP_UBICACIONES UBIC
        ON
            RCATALOGO.UBICACION = UBIC.CODIGO
        GROUP BY
            Requisiciones.TIPODCTO, Requisiciones.NRODCTO, Requisiciones.PRODUCTO, Requisiciones.IDMVTRADE, UBIC.GRUPO
    ) AS SourceTable
    PIVOT
    (
        MAX(SALDO)
        FOR GRUPO IN (' + @columns + N')
    ) AS PivotTable';

    -- Wrap the PIVOT result to replace NULLs with empty string
    SET @sql = N'
    SELECT ' + @columns + ',
           ISNULL(TIPODCTO, '''') AS TIPODCTO,
           ISNULL(NRODCTO, '''') AS NRODCTO,
           ISNULL(PRODUCTO, '''') AS PRODUCTO,
           ISNULL(IDMVTRADE, '''') AS IDMVTRADE
    FROM (' + @sql + N') AS Pivoted';

    -- Execute the dynamic SQL query
    EXEC sp_executesql @sql;
END;
GO

CREATE VIEW X_VTEMP_UBICACIONES
AS
SELECT  MTUBICA.CODUBICA CODIGO,
MTUBICA.NOMBRE NOMBRE,
MTUBICA.SIGLA ,
X_SIGLAUBICA.GRUPO,
X_SIGLAUBICA.CODCC CENTROCOSTO,
CENTCOS.NOMBRE  NOMBRE_CENTROCOSTOS
FROM  X_SIGLAUBICA,MTUBICA,CENTCOS
WHERE MTUBICA.SIGLA=X_SIGLAUBICA.SIGLA
AND X_SIGLAUBICA.CODCC=CENTCOS.CODCC
GO

CREATE VIEW  [dbo].[X_SIGLASCODCC]
AS
SELECT X_SIGLAUBICA.SIGLA,
X_SIGLAUBICA.GRUPO,
X_SIGLAUBICA.CODCC,
CENTCOS.NOMBRE,
X_SIGLAUBICA.ELIMINAR
FROM X_SIGLAUBICA, CENTCOS
WHERE CENTCOS.AUXILIAR=1
AND X_SIGLAUBICA.CODCC=CENTCOS.CODCC

GO

CREATE Procedure [dbo].[X_ACTUALIZA_SIGLAUBICA]
(
@pCodUbica VarChar (20),
@pSigla VarChar(20)
)
As

--Comienza Control de Error
Begin Try

UPDATE MTUBICA
set SIGLA=RTRIM(@pSigla)
where  CODUBICA =RTRIM(@pCodUbica)

End Try
----Atrapa los errores
Begin Catch
-- Ejecutar Sp que muestra informacion del error
Exec ofsp_ObtenerInformacionError 'No es posible ejecutar procedimiento almacenado  X_ACTUALIZA_SIGLAUBICA'
End Catch

GO


CREATE Procedure X_ACTUALIZA_SIGLACODCC
-- Se declaran los parámetros de actualización
(
@pSigla Varchar (5),
@pGrupo Varchar (60),
@PCodcc Varchar (20),
@pEliminar Bit
)

As Begin


-- Inicia transacción
Begin Try
If @pEliminar = 1
Begin
-- Valida integridad referencial
Execute DBO.OF_SP_ValidarForeingkey X_SIGLAUBICA,@pSigla
End
-----------------------------------------------------------------------------------
-- Corre las rutinas de eliminación, actualización e inserción
-- Eliminación
If @pEliminar = 1
Begin
Delete X_SIGLAUBICA Where Sigla = @pSigla
End
Else
Begin
-- Actualización
If  Exists(Select Sigla  From X_SIGLAUBICA  Where Sigla = @pSigla)
Begin
Update X_SIGLAUBICA Set  GRUPO = @pGrupo,Codcc=@PCodcc  Where Sigla = @psigla
End
-- Inserción
Else
Begin
Insert  X_SIGLAUBICA (Sigla,grupo,codcc,Eliminar)
Values (@pSigla,@pGrupo,@PCodcc,0)
End
End
-----------------------------------------------------------------------------------
-- Finaliza transacción
End Try


--- Recolección de errores
BEGIN CATCH

DECLARE @ErrorMessage NVARCHAR(4000);
SELECT @ErrorMessage = ERROR_MESSAGE()

IF @ErrorMessage='Error de integridad'
BEGIN
Raiserror('No se puede Eliminar un registro que tenga relacion con otra tabla',11,1)
END
ELSE
BEGIN
Exec ofsp_ObtenerInformacionError 'No es posible ejecutar procedimiento almacenado de X_ACTUALIZA_SIGLACODCC '
END
END CATCH
End

/*
EXEC dbo.RQ_SaldoInventarioProductoTemp '20240115', '20241030', 'RQ'

SELECT TIPODCTO, NRODCTO FROM TRADE;

SELECT TIPODCTO, NRODCTO, RQ_ESTADO, * FROM MVTRADE;

DELETE FROM MVTRADE;

DELETE FROM TRADE;

SELECT TIPODCTO, NRODCTO, RQ_CANTIDAD_FINAL FROM MVTRADE

CREATE TABLE TEMP_UBICACIONES (
    codigo VARCHAR(50) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    grupo VARCHAR(50) NOT NULL,
    sigla VARCHAR(50) NOT NULL,
    centrocosto VARCHAR(50) NOT NULL
);

SELECT
SIGLA
FROM
TEMP_UBICACIONES
WHERE
SIGLA NOT LIKE '%APLICA%'
GROUP BY
SIGLA;
SELECT * FROM TEMP_UBICACIONES;
SELECT SIGLA FROM TEMP_UBICACIONES WHERE CODIGO = 'CA1'


SELECT GRUPO, SIGLA FROM TEMP_UBICACIONES GROUP BY GRUPO, SIGLA;



SELECT
UBIC.GRUPO,
SUM(SALDO)
FROM
FNVOF_REPORTECATALOGO(2025, 05) RCATALOGO
RIGHT OUTER JOIN
TEMP_UBICACIONES UBIC ON RCATALOGO.UBICACION = UBIC.CODIGO
WHERE
RCATALOGO.PRODUCTO = '076645906205-1667   '
GROUP BY
UBIC.GRUPO

SELECT GRUPO FROM TEMP_UBICACIONES GROUP BY GRUPO



SELECT
    UBIC.GRUPO + REPLICATE(' ', 5) + CAST(SUM(SALDO) AS VARCHAR(20)) AS ConcatenatedResult
FROM
    FNVOF_REPORTECATALOGO(2025, 05) RCATALOGO,
    TEMP_UBICACIONES UBIC
WHERE
    RCATALOGO.PRODUCTO = '076645906205-1667   ' AND
    RCATALOGO.UBICACION = UBIC.CODIGO
GROUP BY
    UBIC.GRUPO


GO

EXEC dbo.GuardarRequisicion '99', '123', '123', '001                                               ', 'SPV739596           ', '5', '12000'
SELECT * FROM RQ_ConsolidadoRequisiciones('20240615', '20241026', 'RQ')
SELECT * FROM RQ_ConsolidadoRequisiciones('2024.07.24', '2024.07.29', 'ASD') ORDER BY IDMVTRADE
/*DROP TABLE RQ_EXCEL_CONFIG;*/

/*
CREATE TABLE RQ_EXCEL_CONFIG (
    COLUMN_NAME NVARCHAR(100),
    EXCLUDE_VALIDATIONS BIT,
    DATA_TYPE NVARCHAR(50),
    POSITION INT
);

INSERT INTO RQ_EXCEL_CONFIG (COLUMN_NAME, EXCLUDE_VALIDATIONS, DATA_TYPE, POSITION) VALUES
('cod proveedor', 0, 'I', 1),
('nombre proveedor', 0, 'C', 2),
('isbn', 0, 'C', 3),
('titulo', 0, 'C', 4),
('autor', 0, 'C', 5),
('editorial', 0, 'C', 6),
('tema', 0, 'C', 7),
('precio', 0, 'N', 8),
('cantidad', 0, 'I', 9),
('SEDE', 0, 'C', 10),
('LIBRERO', 0, 'C', 11),
('ESTADO', 0, 'C', 12);

SELECT * FROM RQ_EXCEL_CONFIG ORDER BY POSITION;

EXEC dbo.RQ_SaldoInventarioProductoTemp '20240115', '20241030', 'RQ'


INSERT INTO MTPOPUPREPORTE
    (CAMPOMOSTRAR, CAMPOVALOR, COMENTARIO, IDPOPUP, SENTENCIA, TABLA)
VALUES
    ('Grupo', 'Sigla', 'Consulta Maestro Siglas Ubicaciones', 'SIGLAUBICA', 'SELECT SIGLA, GRUPO FROM X_SIGLAUBICA', 'X_SIGLAUBICA');


UPDATE MTUBICA SET SIGLA = (SELECT SIGLA FROM TEMP_UBICACIONES TU WHERE TU.codigo = CODUBICA)

INSERT INTO MTGLOBAL (ACTFIJOS, AUTOLIQUID, BANCOS, CAMPO, CARTERA, CLASIFICA, CLIENTES, CODEMPRESA, COMPRAS, COMUN, CONTABLE, CONTANIIF, COSREALES, COSSTANDAR, CTRLPISO, CXP, DESCRIPCIO, ESEMPRESA, FACTURAS, IMPORTACIO, INVENTARIO, MEMO, MERCADEO, MODIFICAB, MRP, MTTOMAQUIN, NOMINA, ORDCOMPRA, ORDEN, PAIS, PEDIDOS, PPTOADMON, PPTOOFICIA, PRICAT, PRODUCCION, PROVEEDOR, PUNTOVENTA, RECHUMANO, SERVICIO, STADSINCRO, TALLERES, TECNICO, TIPO, USUARIO, VALIDACION, VALOR, VENDEDOR)
SELECT ACTFIJOS, AUTOLIQUID, BANCOS, 'EMAILCOPIARQ', CARTERA, CLASIFICA, CLIENTES, CODEMPRESA, COMPRAS, COMUN, CONTABLE, CONTANIIF, COSREALES, COSSTANDAR, CTRLPISO, CXP, DESCRIPCIO, ESEMPRESA, FACTURAS, IMPORTACIO, INVENTARIO, MEMO, MERCADEO, MODIFICAB, MRP, MTTOMAQUIN, NOMINA, ORDCOMPRA, ORDEN, PAIS, PEDIDOS, PPTOADMON, PPTOOFICIA, PRICAT, PRODUCCION, PROVEEDOR, PUNTOVENTA, RECHUMANO, SERVICIO, STADSINCRO, TALLERES, TECNICO, TIPO, USUARIO, VALIDACION, VALOR, VENDEDOR
FROM MTGLOBAL
WHERE CAMPO = 'EMAILCOPIA';


*/ */