USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataIngresos.sql
  Descripcion  : Ingresos proyectados del flujo de caja semana a semana.
                 Clasifica los ingresos por tipo de cliente: nacionales,
                 Carvajal, exterior, reverse factoring, prestamos y otros.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  FUNCION  dbo.CashflowDataIngresos (@FechaInicial, @FechaFinal, @Moneda)
  -------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  ingreso y por cada semana del rango indicado. Internamente construye:
    - Semanas               : genera semanas (lunes a domingo) desde
                              @FechaInicial hasta @FechaFinal.
    - TRMSemana             : TRM vigente por semana consultada en MTCAMBIO.
    - Datos                 : cruza operaciones comerciales (TRADE) con el
                              maestro de clientes/proveedores (MTPROCLI),
                              filtrando por FECING dentro del rango de cada
                              semana, convirtiendo los valores a COP o USD
                              segun @Moneda y la TRM de cada semana.
    - Agrupado              : agrupa por CashflowCategoryId y semana.
  Retorna nueve conceptos de ingreso mediante CROSS JOIN con CashflowCategory.

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataIngresos'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataIngresos
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
        SELECT 
            s.Semana,
            s.LunesSemana,
            (
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= s.LunesSemana
                ORDER BY c.FECHA DESC
            ) AS TRM
        FROM Semanas s
    ),

    Datos AS
    (
        SELECT 
            t.Semana,
            p.CashflowCategoryId,
            SUM(
                CASE 
                    WHEN @Moneda = 'COP'
                        THEN ISNULL(tr.VALORPLAN, 0) * ISNULL(tr.TCAMBIO, 1)
                    WHEN @Moneda = 'USD'
                        THEN ISNULL(tr.VALORPLAN, 0) * ISNULL(tr.TCAMBIO, 1) / NULLIF(t.TRM, 0)
                END
            ) AS Valor
        FROM TRMSemana t
        INNER JOIN TRADE tr
            ON tr.FECING >= t.LunesSemana
           AND tr.FECING <  DATEADD(DAY, 7, t.LunesSemana)
        INNER JOIN MTPROCLI p
            ON p.NIT = tr.NIT
        WHERE p.CashflowCategoryId IS NOT NULL
        GROUP BY 
            t.Semana,
            p.CashflowCategoryId
    )

    SELECT
        cat.ParentName     AS Concepto,
        cat.ItemOrder,
        s.Semana,
        ISNULL(d.Valor, 0) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Semanas s
    LEFT JOIN Datos d ON d.CashflowCategoryId = cat.Id AND d.Semana = s.Semana
    WHERE cat.Category = 'INGRESOS'
)
GO