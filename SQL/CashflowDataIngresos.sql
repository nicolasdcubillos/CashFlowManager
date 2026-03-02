/*
    CashflowDataIngresos
    Vista y Pivot.

    EXEC dbo.CashflowDataIngresosPivot 
         @SemanaInicial = 1,
         @SemanaFinal   = 6,
         @Moneda        = 'COP';
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