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
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataFlujoEconomico (@SemanaInicial, @SemanaFinal, @Moneda)
  ---------------------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  financiamiento y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con la fecha de inicio de
                              cada una (base dinamica: GETDATE()).
  Retorna siete conceptos, todos con Valor = 0 hasta implementacion.
  El total "Total Financiamiento" se calcula en VFP (no en SQL).

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataFlujoEconomico'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataFlujoEconomico
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
            DATEADD(WEEK, Semana, ISNULL(@FechaBase, CAST(GETDATE() AS DATE))) AS FechaInicio
        FROM Numeros
    )

    -- TODO: implementar logica real por concepto usando @Moneda y TRM

    SELECT
        cat.ParentName           AS Concepto,
        cat.ItemOrder,
        n.Semana,
        CAST(0 AS DECIMAL(18,2)) AS Valor
    FROM dbo.CashflowCategory cat
    CROSS JOIN Numeros n
    WHERE cat.Category = 'FINANCIAMIENTO'
);
GO
