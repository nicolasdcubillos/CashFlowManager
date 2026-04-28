USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataProjectionPedidos.sql
  Descripcion  : Valores proyectados del flujo de caja por semana, calculados
                 a partir de la tabla PedidosPendientes (pedidos pendientes
                 de despacho, Puntoventa = 0 solamente).
                 Cada fila se asigna a la semana que contiene su fechaVencim.
                 El valor proyectado por linea es cantidad * valor.
                 Se clasifica por categoria via MTPROCLI.CashflowCategoryId.
                 Retorna TODAS las categorias (INGRESOS, EGRESOS,
                 FINANCIAMIENTO) en una sola consulta; filtrar con @Category
                 en CashflowPivot al invocar.
  Autor        : CC Sistemas
  Fecha        : 2026-04-12
================================================================================

  SINONIMO  dbo.PedidosPendientes_Src
  ------------------------------------
  Se crea en CashflowDataProjection.sql (el script combinador).
  Abstrae la base de datos donde reside PedidosPendientes.

  FUNCION  dbo.CashflowDataProjectionPedidos (@FechaInicial, @FechaFinal, @Moneda)
  ---------------------------------------------------------------------------------
  Columnas de salida:
    Category   VARCHAR(20)    - INGRESOS / EGRESOS / FINANCIAMIENTO
    Concepto   VARCHAR(150)   - ParentName de CashflowCategory
    ItemOrder  INT            - orden de filas dentro de la seccion
    Semana     INT            - semana secuencial (1, 2, 3 ...)
    Valor      DECIMAL(18,2)  - monto proyectado (0 si no hay pedidos)

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataProjectionPedidos'
         y @Category = 'INGRESOS' | 'EGRESOS' | 'FINANCIAMIENTO'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataProjectionPedidos
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
            1             AS Semana,
            @FechaInicial AS LunesSemana
        UNION ALL
        SELECT
            Semana + 1,
            DATEADD(WEEK, 1, LunesSemana)
        FROM Semanas
        WHERE DATEADD(WEEK, 1, LunesSemana) <= @FechaFinal
    ),

    SemanaRango AS
    (
        SELECT
            Semana,
            LunesSemana,
            DATEADD(DAY, 6, LunesSemana) AS DomingoSemana
        FROM Semanas
    ),

    TRMSemana AS
    (
        SELECT
            sr.Semana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO c
                WHERE c.FECHA <= sr.LunesSemana
                ORDER BY c.FECHA DESC
            ), 1) AS TRM
        FROM SemanaRango sr
    ),

    ProyeccionAgrupada AS
    (
        SELECT
            sr.Semana,
            mt.CashflowCategoryId,
            SUM(
                CASE
                    WHEN @Moneda = 'USD'
                        THEN (CAST(pp.cantidad AS DECIMAL(18, 5)) * pp.valor)
                             / NULLIF(t.TRM, 0)
                    ELSE      CAST(pp.cantidad AS DECIMAL(18, 5)) * pp.valor
                END
            ) AS Valor
        FROM  SemanaRango sr
        INNER JOIN dbo.PedidosPendientes_Src pp
            ON  pp.fechaVencim >= sr.LunesSemana
            AND pp.fechaVencim <= sr.DomingoSemana
            AND pp.Puntoventa  = 0
        INNER JOIN MTPROCLI mt
            ON  mt.NIT = pp.Nit
        INNER JOIN TRMSemana t
            ON  t.Semana = sr.Semana
        WHERE mt.CashflowCategoryId IS NOT NULL
        GROUP BY sr.Semana, mt.CashflowCategoryId
    )

    SELECT
        cat.Category,
        cat.ParentName   AS Concepto,
        cat.ItemOrder,
        s.Semana,
        ISNULL(pa.Valor, 0) AS Valor
    FROM  dbo.CashflowCategory cat
    CROSS JOIN Semanas s
    LEFT JOIN ProyeccionAgrupada pa
        ON  pa.CashflowCategoryId = cat.Id
        AND pa.Semana             = s.Semana
);
GO
