/*
================================================================================
  Archivo      : CashflowDataEgresos.sql
  Descripcion  : Egresos proyectados del flujo de caja semana a semana.
                 Incluye pagos a proveedores nacionales y del exterior,
                 mano de obra de terceros, personal, impuestos y servicios.
  Autor        : CC Sistemas
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataEgresos (@SemanaInicial, @SemanaFinal, @Moneda)
  -------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  egreso y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con sus fechas de inicio y fin.
    - PagosProveedor        : suma abonos de cuentas por pagar (ABOCXP)
                              agrupados por tipo de proveedor y exterior.
                              Convierte siempre a COP (VALOR * TCAMBIO) y
                              luego divide por TRM si se pide USD.
    - TRMSemana             : TRM vigente por semana consultada en MTCAMBIO.
    - MovContables          : extrae debitos de nomina (cuentas 51x) e
                              impuestos (cuentas 24x) desde MVTO (siempre COP).
                              Divide por TRM si se pide USD.
  El resultado final es un UNION ALL de doce conceptos de egreso.

  PROCEDIMIENTO  dbo.CashflowDataEgresosPivot (@SemanaInicial, @SemanaFinal, @Moneda)
  ------------------------------------------------------------------------------------
  Stored Procedure que transpone la salida de la funcion anterior en una
  matriz donde cada columna es un numero de semana. Construye dinamicamente
  la lista de columnas con STRING_AGG/QUOTENAME y ejecuta un PIVOT con
  SUM(Valor) FOR Semana mediante sp_executesql.
  El resultado se ordena por nombre de concepto.

  Ejemplo de uso:
    EXEC dbo.CashflowDataEgresosPivot
         @SemanaInicial = 1,
         @SemanaFinal   = 6,
         @Moneda        = 'COP';
================================================================================
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

    TRMSemana AS
    (
        -- TRM vigente al inicio de cada semana
        SELECT
            f.Semana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= f.FechaInicio
                ORDER BY c.FECHA DESC
            ), 1) AS TRM
        FROM FechaSemana f
    ),

    PagosProveedor AS
    (
        SELECT 
            f.Semana,
            p.TIPOPRV,
            p.EXTERIOR,

            SUM(
                -- Base siempre en COP: VALOR * TCAMBIO (si es USD) o VALOR * 1 (si es COP)
                -- Para USD: dividir el COP resultante por la TRM de la semana
                CASE 
                    WHEN @Moneda = 'COP'
                        THEN a.VALOR * ISNULL(a.TCAMBIO, 1)
                    WHEN @Moneda = 'USD'
                        THEN a.VALOR * ISNULL(a.TCAMBIO, 1) / NULLIF(t.TRM, 0)
                END
            ) AS Valor

        FROM FechaSemana f

        LEFT JOIN TRMSemana t ON t.Semana = f.Semana

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
        -- MVTO contable: nomina (51x) e impuestos (24x) siempre en COP
        SELECT 
            f.Semana,

            SUM(CASE WHEN m.CODIGOCTA LIKE '51%'
                     THEN CASE WHEN @Moneda = 'USD'
                               THEN m.CREDITO / NULLIF(t.TRM, 0)
                               ELSE m.CREDITO
                          END
                     ELSE 0 END) AS Personal,

            SUM(CASE WHEN m.CODIGOCTA LIKE '24%'
                     THEN CASE WHEN @Moneda = 'USD'
                               THEN m.CREDITO / NULLIF(t.TRM, 0)
                               ELSE m.CREDITO
                          END
                     ELSE 0 END) AS Impuestos

        FROM FechaSemana f

        LEFT JOIN TRMSemana t ON t.Semana = f.Semana

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

EXEC dbo.CashflowDataEgresosPivot 4, 6, 'USD'