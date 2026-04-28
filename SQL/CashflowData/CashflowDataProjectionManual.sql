USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataProjectionManual.sql
  Descripcion  : Valores proyectados MANUALES del flujo de caja por semana.
                 Lee la tabla CashflowProjection (ingresada via UI),
                 clasifica cada NIT a traves de MTPROCLI.CashflowCategoryId
                 y agrupa por categoria.
                 Retorna TODAS las categorias (INGRESOS, EGRESOS,
                 FINANCIAMIENTO) en una sola consulta; filtrar con @Category
                 en CashflowPivot al invocar.
  Autor        : CC Sistemas
  Fecha        : 2026-04-12
================================================================================

  FUNCION  dbo.CashflowDataProjectionManual (@FechaInicial, @FechaFinal, @Moneda)
  ---------------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto x
  semana del rango indicado. Internamente construye:
    - Semanas               : genera semanas (lunes a domingo) desde
                              @FechaInicial hasta @FechaFinal.
    - SemanaISO             : convierte cada fecha a (ISOYear, ISOWeek) para
                              cruzar contra CashflowProjection.
    - TRMSemana             : TRM vigente para conversion a USD.
    - ProyeccionAgrupada    : suma TotalProjected por CashflowCategoryId.

  Columnas de salida:
    Category   VARCHAR(20)    - INGRESOS / EGRESOS / FINANCIAMIENTO
    Concepto   VARCHAR(150)   - ParentName de CashflowCategory
    ItemOrder  INT            - para ordenar filas dentro de la seccion
    Semana     INT            - semana secuencial (1, 2, 3 ...)
    Valor      DECIMAL(18,2)  - monto proyectado (0 si no hay datos)

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataProjectionManual'
         y @Category = 'INGRESOS' | 'EGRESOS' | 'FINANCIAMIENTO'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataProjectionManual
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

    SemanaISO AS
    (
        SELECT
            Semana,
            LunesSemana,
            -- ISO year: ano al que pertenece la ISO week
            YEAR(DATEADD(DAY, 26 - DATEPART(ISO_WEEK, LunesSemana), LunesSemana)) AS ISOYear,
            DATEPART(ISO_WEEK, LunesSemana) AS ISOWeek
        FROM Semanas
    ),

    TRMSemana AS
    (
        SELECT
            s.Semana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= s.LunesSemana
                ORDER BY c.FECHA DESC
            ), 1) AS TRM
        FROM SemanaISO s
    ),

    ProyeccionAgrupada AS
    (
        SELECT
            s.Semana,
            p.CashflowCategoryId,
            SUM(
                CASE
                    WHEN @Moneda = 'USD'
                        THEN cp.TotalProjected / NULLIF(t.TRM, 0)
                    ELSE cp.TotalProjected
                END
            ) AS Valor
        FROM SemanaISO s
        INNER JOIN CashflowProjection cp
            ON cp.[Year] = s.ISOYear
           AND cp.Week   = s.ISOWeek
        INNER JOIN MTPROCLI p
            ON p.NIT = cp.NIT
        INNER JOIN TRMSemana t
            ON t.Semana = s.Semana
        WHERE p.CashflowCategoryId IS NOT NULL
        GROUP BY s.Semana, p.CashflowCategoryId
    )

    SELECT
        cat.Category,
        cat.ParentName   AS Concepto,
        cat.ItemOrder,
        s.Semana,
        ISNULL(pa.Valor, 0) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Semanas s
    LEFT JOIN ProyeccionAgrupada pa
        ON pa.CashflowCategoryId = cat.Id
       AND pa.Semana = s.Semana
);
GO
