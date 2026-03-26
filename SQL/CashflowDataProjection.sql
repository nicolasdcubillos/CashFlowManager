USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataProjection.sql
  Descripcion  : Valores proyectados (manuales) del flujo de caja por semana.
                 Lee la tabla CashflowProjection, clasifica cada NIT a traves
                 de MTPROCLI.CashflowCategoryId y agrupa por categoria.
                 Retorna TODAS las categorias (INGRESOS, EGRESOS,
                 FINANCIAMIENTO) en una sola consulta; filtrar con @Category
                 en CashflowPivot al invocar.
  Autor        : CC Sistemas
  Fecha        : 2026-03-25
================================================================================

  FUNCION  dbo.CashflowDataProjection (@SemanaInicial, @SemanaFinal, @Moneda)
  ---------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto x
  semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas relativas con fecha de inicio.
    - SemanaISO             : convierte cada fecha a (ISOYear, ISOWeek) para
                              cruzar contra CashflowProjection.
    - TRMSemana             : TRM vigente para conversion a USD.
    - ProyeccionAgrupada    : suma TotalProjected por CashflowCategoryId.

  Columnas de salida:
    Category   VARCHAR(20)    - INGRESOS / EGRESOS / FINANCIAMIENTO
    Concepto   VARCHAR(150)   - ParentName de CashflowCategory
    ItemOrder  INT            - para ordenar filas dentro de la seccion
    Semana     INT            - semana relativa (1, 2, 3 ...)
    Valor      DECIMAL(18,2)  - monto proyectado (0 si no hay datos)

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataProjection'
         y @Category = 'INGRESOS' | 'EGRESOS' | 'FINANCIAMIENTO'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataProjection
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
        FROM   Numeros
        WHERE  Semana + 1 <= @SemanaFinal
    ),

    FechaSemana AS
    (
        SELECT
            Semana,
            DATEADD(WEEK, Semana, ISNULL(@FechaBase, CAST(GETDATE() AS DATE))) AS FechaInicio
        FROM Numeros
    ),

    SemanaISO AS
    (
        SELECT
            Semana,
            FechaInicio,
            -- ISO year: ano al que pertenece la ISO week
            YEAR(DATEADD(DAY, 26 - DATEPART(ISO_WEEK, FechaInicio), FechaInicio)) AS ISOYear,
            DATEPART(ISO_WEEK, FechaInicio) AS ISOWeek
        FROM FechaSemana
    ),

    TRMSemana AS
    (
        SELECT
            s.Semana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= s.FechaInicio
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
        n.Semana,
        ISNULL(pa.Valor, 0) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Numeros n
    LEFT JOIN ProyeccionAgrupada pa
        ON pa.CashflowCategoryId = cat.Id
       AND pa.Semana = n.Semana
);
GO
