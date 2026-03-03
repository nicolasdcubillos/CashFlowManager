/*
================================================================================
  Archivo      : CashflowDataIngresos.sql
  Descripcion  : Ingresos proyectados del flujo de caja semana a semana.
                 Clasifica los ingresos por tipo de cliente: nacionales,
                 Carvajal, exterior, reverse factoring, prestamos y otros.
  Autor        : CC Sistemas
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataIngresos (@SemanaInicial, @SemanaFinal, @Moneda)
  -------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  ingreso y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con la fecha de inicio.
    - TRMSemana             : TRM vigente por semana consultada en MTCAMBIO.
    - Datos                 : cruza operaciones comerciales (TRADE) con el
                              maestro de clientes/proveedores (MTPROCLI),
                              convirtiendo los valores a COP o USD segun
                              @Moneda y la TRM de cada semana.
    - Agrupado              : agrupa por tipo de cliente (TIPOCLI) y
                              exterior para obtener totales por categoria.
  Retorna nueve conceptos de ingreso mediante UNION ALL.

  PROCEDIMIENTO  dbo.CashflowDataIngresosPivot (@SemanaInicial, @SemanaFinal, @Moneda)
  -------------------------------------------------------------------------------------
  Stored Procedure que transpone la salida de la funcion en una matriz
  donde cada columna es un numero de semana. Construye dinamicamente la
  lista de columnas con STRING_AGG/QUOTENAME y ejecuta un PIVOT con
  SUM(Valor) FOR Semana mediante sp_executesql.

  Ejemplo de uso:
    EXEC dbo.CashflowDataIngresosPivot
         @SemanaInicial = 1,
         @SemanaFinal   = 6,
         @Moneda        = 'COP';
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataIngresos
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM Numeros
        WHERE Semana + 1 <= @SemanaFinal
    ),

    FechaSemana AS
    (
        SELECT 
            Semana,
            DATEADD(WEEK, Semana, GETDATE()) AS FechaInicio
        FROM Numeros
    ),

    TRMSemana AS
    (
        SELECT 
            f.Semana,
            f.FechaInicio,
            (
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= f.FechaInicio
                ORDER BY c.FECHA DESC
            ) AS TRM
        FROM FechaSemana f
    ),

    Datos AS
    (
        SELECT 
            t.Semana,
            p.TIPOCLI,
            p.EXTERIOR,
            SUM(
                CASE 
                    WHEN @Moneda = 'COP' THEN
                        CASE 
                            WHEN tr.TIPOMONEDA = 'USD'
                                THEN ISNULL(tr.VALORPLAN,0) * t.TRM
                            ELSE ISNULL(tr.VALORPLAN,0)
                        END

                    WHEN @Moneda = 'USD' THEN
                        CASE 
                            WHEN tr.TIPOMONEDA = 'COP'
                                THEN ISNULL(tr.VALORPLAN,0) / NULLIF(t.TRM,0)
                            ELSE ISNULL(tr.VALORPLAN,0)
                        END
                END
            ) AS Valor
        FROM TRMSemana t
        LEFT JOIN TRADE tr
            ON tr.FECHA <= t.FechaInicio
        LEFT JOIN MTPROCLI p
            ON p.NIT = tr.NIT
        GROUP BY 
            t.Semana,
            p.TIPOCLI,
            p.EXTERIOR
    ),

    Agrupado AS
    (
        SELECT
            Semana,

            SUM(CASE WHEN TIPOCLI = '01' THEN Valor ELSE 0 END) AS ClientesNacionales,
            SUM(CASE WHEN TIPOCLI = '02' THEN Valor ELSE 0 END) AS ClientesCarvajal,
            SUM(CASE WHEN EXTERIOR = 1 THEN Valor ELSE 0 END) AS ClientesExterior,
            SUM(CASE WHEN TIPOCLI = '03' THEN Valor ELSE 0 END) AS ReverseFactoring,
            SUM(CASE WHEN TIPOCLI = '04' THEN Valor ELSE 0 END) AS PrestamoPieriplast,
            SUM(CASE WHEN TIPOCLI = '05' THEN Valor ELSE 0 END) AS OtrosIngresos

        FROM Datos
        GROUP BY Semana
    )

    SELECT 'Proyeccion Ventas Carvajal' AS Concepto, Semana, 0 AS Valor FROM Agrupado
    UNION ALL
    SELECT 'Clientes Nacionales', Semana, ClientesNacionales FROM Agrupado
    UNION ALL
    SELECT 'Clientes Nacionales Carvajal', Semana, ClientesCarvajal FROM Agrupado
    UNION ALL
    SELECT 'Clientes del Exterior', Semana, ClientesExterior FROM Agrupado
    UNION ALL
    SELECT 'Reverse Factoring', Semana, ReverseFactoring FROM Agrupado
    UNION ALL
    SELECT 'Prestamo Pieriplast', Semana, PrestamoPieriplast FROM Agrupado
    UNION ALL
    SELECT 'Otros Ingresos', Semana, OtrosIngresos FROM Agrupado
    UNION ALL
    SELECT 'Utilizacion Fiducia Impuesto al Plastico', Semana, 0 FROM Agrupado
    UNION ALL
    SELECT 'Monetizaciones - Usd a Cop', Semana, 0 FROM Agrupado
)
GO

CREATE OR ALTER PROCEDURE dbo.CashflowDataIngresosPivot
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @Columnas NVARCHAR(MAX)
    DECLARE @SQL NVARCHAR(MAX)

    ;WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM Numeros
        WHERE Semana + 1 <= @SemanaFinal
    )
    SELECT @Columnas = STRING_AGG(QUOTENAME(Semana), ',')
    FROM Numeros
    OPTION (MAXRECURSION 1000)

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT Concepto, Semana, Valor
            FROM dbo.CashflowDataIngresos('
            + CAST(@SemanaInicial AS VARCHAR) + ','
            + CAST(@SemanaFinal AS VARCHAR) + ','''
            + @Moneda + ''')
        ) src
        PIVOT
        (
            SUM(Valor)
            FOR Semana IN (' + @Columnas + ')
        ) p
    '

    EXEC sp_executesql @SQL

END
GO