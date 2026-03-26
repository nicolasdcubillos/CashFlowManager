USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataEgresos.sql
  Descripcion  : Egresos proyectados del flujo de caja semana a semana.
                 Incluye pagos a proveedores nacionales y del exterior,
                 mano de obra de terceros, personal, impuestos y servicios.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  FUNCION  dbo.CashflowDataEgresos (@FechaInicial, @FechaFinal, @Moneda)
  -------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  egreso y por cada semana del rango indicado. Internamente construye:
    - Semanas               : genera semanas (lunes a domingo) desde
                              @FechaInicial hasta @FechaFinal.
    - TRMSemana             : TRM vigente por semana consultada en MTCAMBIO.
    - PagosProveedor        : suma abonos de cuentas por pagar (ABOCXP)
                              filtrando por FECING dentro del rango de cada
                              semana. Convierte siempre a COP (VALOR * TCAMBIO)
                              y luego divide por TRM si se pide USD.
    - MovContables          : extrae debitos de nomina (cuentas 51x) e
                              impuestos (cuentas 24x) desde MVTO (siempre COP).
                              Filtra por FECHAMVTO. Divide por TRM si USD.
  El resultado final es un UNION ALL de doce conceptos de egreso.

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataEgresos'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataEgresos
(
    @FechaInicial DATE,
    @FechaFinal   DATE,
    @Moneda       VARCHAR(3)
)
RETURNS TABLE
AS
RETURN
(
    WITH Semanas AS
    (
        SELECT
            1 AS Semana,
            @FechaInicial AS LunesSemana
        UNION ALL
        SELECT
            Semana + 1,
            DATEADD(WEEK, 1, LunesSemana)
        FROM Semanas
        WHERE DATEADD(WEEK, 1, LunesSemana) <= @FechaFinal
    ),

    TRMSemana AS
    (
        -- TRM vigente al inicio de cada semana
        SELECT
            s.Semana,
            s.LunesSemana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= s.LunesSemana
                ORDER BY c.FECHA DESC
            ), 1) AS TRM
        FROM Semanas s
    ),

    PagosProveedor AS
    (
        SELECT 
            t.Semana,
            p.CashflowCategoryId,
            SUM(
                CASE 
                    WHEN @Moneda = 'COP'
                        THEN a.VALOR * ISNULL(a.TCAMBIO, 1)
                    WHEN @Moneda = 'USD'
                        THEN a.VALOR * ISNULL(a.TCAMBIO, 1) / NULLIF(t.TRM, 0)
                END
            ) AS Valor
        FROM TRMSemana t
        INNER JOIN ABOCXP a
            ON a.FECING >= t.LunesSemana
           AND a.FECING <  DATEADD(DAY, 7, t.LunesSemana)
           AND a.PAGADO = 1
        INNER JOIN MTPROCLI p
            ON p.NIT = a.NIT
        WHERE p.CashflowCategoryId IS NOT NULL
        GROUP BY 
            t.Semana, 
            p.CashflowCategoryId
    ),

    MovContables AS
    (
        -- MVTO contable: nomina (51x) e impuestos (24x) siempre en COP
        SELECT 
            t.Semana,

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

        FROM TRMSemana t

        LEFT JOIN MVTO m
            ON m.FECHAMVTO >= t.LunesSemana
           AND m.FECHAMVTO <  DATEADD(DAY, 7, t.LunesSemana)

        GROUP BY t.Semana
    )

    SELECT
        cat.ParentName                                             AS Concepto,
        cat.ItemOrder,
        s.Semana,
        ISNULL(pp.Valor, 0)
        + CASE cat.Id WHEN '18' THEN ISNULL(mc.Personal,  0) ELSE 0 END
        + CASE cat.Id WHEN '19' THEN ISNULL(mc.Impuestos, 0) ELSE 0 END AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Semanas s
    LEFT JOIN PagosProveedor pp ON pp.CashflowCategoryId = cat.Id AND pp.Semana = s.Semana
    LEFT JOIN MovContables   mc ON mc.Semana = s.Semana
    WHERE cat.Category = 'EGRESOS'
);
GO