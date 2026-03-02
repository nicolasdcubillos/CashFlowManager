/*
    CashflowDataEgresos
    Vista y Pivot.
    
    EXEC dbo.CashflowDataEgresosPivot 
         @SemanaInicial = 1,
         @SemanaFinal   = 6,
         @Moneda        = 'COP';
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataEgresos
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
            DATEADD(WEEK, Semana, CAST(GETDATE() AS DATE)) AS FechaInicio,
            DATEADD(DAY, 6, DATEADD(WEEK, Semana, CAST(GETDATE() AS DATE))) AS FechaFin
        FROM Numeros
    ),

    PagosProveedor AS
    (
        SELECT 
            f.Semana,
            p.TIPOPRV,
            p.EXTERIOR,

            SUM(
                CASE 
                    WHEN @Moneda = 'COP'
                        THEN a.VALOR * ISNULL(a.TCAMBIO,1)
                    WHEN @Moneda = 'USD'
                        THEN a.VALOR
                END
            ) AS Valor

        FROM FechaSemana f

        LEFT JOIN ABOCXP a
            ON a.FECHA BETWEEN f.FechaInicio AND f.FechaFin
           AND a.PAGADO = 1

        LEFT JOIN MTPROCLI p
            ON p.NIT = a.NIT

        GROUP BY 
            f.Semana, 
            p.TIPOPRV, 
            p.EXTERIOR
    ),

    MovContables AS
    (
        SELECT 
            f.Semana,

            SUM(CASE WHEN m.CODIGOCTA LIKE '51%' 
                     THEN m.CREDITO ELSE 0 END) AS Personal,

            SUM(CASE WHEN m.CODIGOCTA LIKE '24%' 
                     THEN m.CREDITO ELSE 0 END) AS Impuestos

        FROM FechaSemana f

        LEFT JOIN MVTO m
            ON m.FECHAMVTO BETWEEN f.FechaInicio AND f.FechaFin

        GROUP BY f.Semana
    )

    SELECT 
        'Pago a Proveedores - Nacionales' AS Concepto,
        Semana,
        SUM(CASE WHEN TIPOPRV = '01' THEN Valor ELSE 0 END) AS Valor
    FROM PagosProveedor
    GROUP BY Semana

    UNION ALL

    SELECT 
        'Pago Mano de Obra Terceros',
        Semana,
        SUM(CASE WHEN TIPOPRV = '02' THEN Valor ELSE 0 END)
    FROM PagosProveedor
    GROUP BY Semana

    UNION ALL

    SELECT 
        'Pago a Proveedores - Exterior',
        Semana,
        SUM(CASE WHEN EXTERIOR = 1 THEN Valor ELSE 0 END)
    FROM PagosProveedor
    GROUP BY Semana

    UNION ALL

    SELECT 
        'Pago Exportaciones',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago Nacionalizaciones Tariff from import',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago OC - OS Prepay',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago Moldes',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago de Facturas Negociables Proveedores Ext',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago al Personal',
        Semana,
        Personal
    FROM MovContables

    UNION ALL

    SELECT 
        'Pago de Impuestos',
        Semana,
        Impuestos
    FROM MovContables

    UNION ALL

    SELECT 
        'Pago de Servicios',
        Semana,
        0
    FROM FechaSemana

    UNION ALL

    SELECT 
        'Pago Arriendos',
        Semana,
        0
    FROM FechaSemana
);
GO

CREATE OR ALTER PROCEDURE dbo.CashflowDataEgresosPivot
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Columnas NVARCHAR(MAX);
    DECLARE @SQL      NVARCHAR(MAX);

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
    OPTION (MAXRECURSION 1000);

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT 
                Concepto,
                Semana,
                Valor
            FROM dbo.CashflowDataEgresos('
            + CAST(@SemanaInicial AS VARCHAR(10)) + ','
            + CAST(@SemanaFinal   AS VARCHAR(10)) + ','''
            + @Moneda + ''')
        ) AS src
        PIVOT
        (
            SUM(Valor)
            FOR Semana IN (' + @Columnas + ')
        ) AS p
        ORDER BY Concepto;
    ';

    EXEC sp_executesql @SQL;
END;
GO