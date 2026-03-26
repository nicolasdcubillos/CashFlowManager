USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataFlujoEconomico.sql
  Descripcion  : Flujo de caja economico (financiamiento) semana a semana.
                 Incluye prestamos, leasing, tarjetas, factoring e intereses.
                 Por ahora todos los conceptos retornan $0 por semana;
                 la implementacion a detalle se realiza en una fase posterior.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  FUNCION  dbo.CashflowDataFlujoEconomico (@FechaInicial, @FechaFinal, @Moneda)
  ---------------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  financiamiento y por cada semana del rango indicado. Internamente construye:
    - Semanas               : genera semanas (lunes a domingo) desde
                              @FechaInicial hasta @FechaFinal.
  Retorna siete conceptos, todos con Valor = 0 hasta implementacion.
  El total "Total Financiamiento" se calcula en VFP (no en SQL).

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataFlujoEconomico'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataFlujoEconomico
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
    )

    -- TODO: implementar logica real por concepto usando @Moneda y TRM

    SELECT
        cat.ParentName           AS Concepto,
        cat.ItemOrder,
        s.Semana,
        CAST(0 AS DECIMAL(18,2)) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Semanas s
    WHERE cat.Category = 'FINANCIAMIENTO'
);
GO
