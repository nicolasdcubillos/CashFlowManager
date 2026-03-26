USE INTECPL;
GO

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

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataEgresos'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataEgresos
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3),
    @FechaBase     DATE = NULL   -- NULL usa GETDATE() (llamada directa / retrocompatible)
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
            DATEADD(WEEK, Semana, ISNULL(@FechaBase, CAST(GETDATE() AS DATE))) AS FechaInicio,
            DATEADD(DAY, 6, DATEADD(WEEK, Semana, ISNULL(@FechaBase, CAST(GETDATE() AS DATE)))) AS FechaFin
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
            p.CashflowCategoryId,
            SUM(
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
        WHERE p.CashflowCategoryId IS NOT NULL
        GROUP BY 
            f.Semana, 
            p.CashflowCategoryId
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
        cat.ParentName                                             AS Concepto,
        cat.ItemOrder,
        n.Semana,
        ISNULL(pp.Valor, 0)
        + CASE cat.Id WHEN '18' THEN ISNULL(mc.Personal,  0) ELSE 0 END
        + CASE cat.Id WHEN '19' THEN ISNULL(mc.Impuestos, 0) ELSE 0 END AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Numeros n
    LEFT JOIN PagosProveedor pp ON pp.CashflowCategoryId = cat.Id AND pp.Semana = n.Semana
    LEFT JOIN MovContables   mc ON mc.Semana = n.Semana
    WHERE cat.Category = 'EGRESOS'
);
GO