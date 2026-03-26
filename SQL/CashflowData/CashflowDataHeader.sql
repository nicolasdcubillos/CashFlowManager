USE INTECPL;
GO

/*
================================================================================
  Archivo      : CashflowDataHeader.sql
  Descripcion  : Saldos bancarios iniciales y disponibilidad de caja por
                 semana para el encabezado del flujo de caja.
                 Incluye saldo COP, saldo USD convertido, prestamos y
                 total disponible en bancos.
  Autor        : CC Sistemas
  Fecha        : 2026-03-26
================================================================================

  FUNCION  dbo.CashflowDataHeader (@FechaInicial, @FechaFinal, @Moneda)
  -----------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  saldo y por cada semana del rango indicado. Internamente construye:
    - Semanas               : genera semanas (lunes a domingo) desde
                              @FechaInicial hasta @FechaFinal.
    - TRM                   : consulta la tasa de cambio vigente en MTCAMBIO
                              para la fecha de inicio de cada semana.
    - Saldos                : invoca fnvOF_ReporteMVBancos_Saldos por semana
                              (lunes a domingo) y agrupa Saldo_Final separando
                              COP y USD segun Otra_Moneda. Convierte segun
                              @Moneda usando la TRM de cada semana.
  Retorna cuatro conceptos: Saldo inicial COP, Saldo inicial USD,
  PA Credicorp - Excedentes y Disponible Bancos.

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataHeader'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataHeader
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

    TRM AS
    (
        SELECT 
            s.Semana,
            s.LunesSemana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO
                WHERE FECHA <= s.LunesSemana
                ORDER BY FECHA DESC
            ),1) AS TRM
        FROM Semanas s
    ),

    Saldos AS
    (
        SELECT 
            s.Semana,
            t.TRM,

            -- Pesos y MultiMoneda tienen otramon='N' => COP; OtraMoneda tiene otramon='S' => USD
            SUM(CASE WHEN fn.Tipo_Moneda IN ('Pesos', 'MultiMoneda') THEN fn.Saldo_Final ELSE 0 END) AS SaldoCOP,
            SUM(CASE WHEN fn.Tipo_Moneda = 'OtraMoneda'              THEN fn.Saldo_Final ELSE 0 END) AS SaldoUSD,

            -- Prestamos separados por moneda para conversion limpia
            SUM(CASE WHEN fn.Banco IN ('CTA_PRESTAMO_1','CTA_PRESTAMO_2')
                          AND fn.Tipo_Moneda IN ('Pesos', 'MultiMoneda')
                     THEN fn.Saldo_Final ELSE 0 END) AS PrestamosCOP,
            SUM(CASE WHEN fn.Banco IN ('CTA_PRESTAMO_1','CTA_PRESTAMO_2')
                          AND fn.Tipo_Moneda = 'OtraMoneda'
                     THEN fn.Saldo_Final ELSE 0 END) AS PrestamosUSD

        FROM Semanas s

        LEFT JOIN TRM t ON t.Semana = s.Semana

        CROSS APPLY dbo.fnvOF_ReporteMVBancos_Saldos(
            s.LunesSemana,
            DATEADD(DAY, 6, s.LunesSemana)
        ) fn

        GROUP BY s.Semana, t.TRM
    )

    -- Saldo COP: si piden USD se divide por TRM
    SELECT 'Saldo inicial COP' AS Concepto,
           1                   AS ItemOrder,
           Semana,
           CASE WHEN @Moneda = 'USD'
                THEN SaldoCOP / NULLIF(TRM, 0)
                ELSE SaldoCOP
           END AS Valor
    FROM Saldos

    UNION ALL

    -- Saldo USD: si piden COP se multiplica por TRM
    SELECT 'Saldo inicial USD',
           2,
           Semana,
           CASE WHEN @Moneda = 'USD'
                THEN SaldoUSD
                ELSE SaldoUSD * TRM
           END
    FROM Saldos

    UNION ALL

    -- Prestamos: conversion limpia separando COP y USD
    SELECT 'PA Credicorp - Excedentes',
           3,
           Semana,
           CASE WHEN @Moneda = 'USD'
                THEN PrestamosCOP / NULLIF(TRM, 0) + PrestamosUSD
                ELSE PrestamosCOP + PrestamosUSD * TRM
           END
    FROM Saldos

    UNION ALL

    -- Disponible total: suma homogenea en la moneda pedida
    SELECT 'Disponible Bancos',
           4,
           Semana,
           CASE WHEN @Moneda = 'USD'
                THEN SaldoCOP / NULLIF(TRM, 0) + SaldoUSD
                ELSE SaldoCOP + (SaldoUSD * TRM)
           END
    FROM Saldos
)
GO