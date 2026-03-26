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
  Fecha        : 2026-03-02
================================================================================

  FUNCION  dbo.CashflowDataHeader (@SemanaInicial, @SemanaFinal, @Moneda)
  -----------------------------------------------------------------------
  Tabla-funcion (RETURNS TABLE) que genera una fila por cada concepto de
  saldo y por cada semana del rango indicado. Internamente construye:
    - Numeros / FechaSemana : rango de semanas con la fecha de inicio de
                              cada una (base dinamica: GETDATE()).
    - TRM                   : consulta la tasa de cambio vigente en MTCAMBIO
                              para la fecha de inicio de cada semana.
    - Saldos                : acumula movimientos bancarios (MVBANCOS) hasta
                              la fecha de cada semana, separando COP y USD
                              por OTRAMON, y Prestamos COP/USD por cuenta.
                              Todos los conceptos se convierten limpiamente
                              segun @Moneda usando la TRM de cada semana.
  Retorna cuatro conceptos: Saldo inicial COP, Saldo inicial USD,
  PA Credicorp - Excedentes y Disponible Bancos.

  PIVOT: usar dbo.CashflowPivot con @FunctionName = 'CashflowDataHeader'.
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataHeader
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
    ),

    TRM AS
    (
        SELECT 
            f.Semana,
            ISNULL((
                SELECT TOP 1 VALOR
                FROM MTCAMBIO
                WHERE FECHA <= f.FechaInicio
                ORDER BY FECHA DESC
            ),1) AS TRM
        FROM FechaSemana f
    ),

    Saldos AS
    (
        SELECT 
            f.Semana,
            t.TRM,

            SUM(CASE WHEN MB.OTRAMON = 'N' THEN MV.VALOR ELSE 0 END) AS SaldoCOP,
            SUM(CASE WHEN MB.OTRAMON = 'S' THEN MV.VALOR ELSE 0 END) AS SaldoUSD,

            -- Prestamos separados por moneda para conversion limpia
            SUM(CASE WHEN MV.CODIGOCTA IN ('CTA_PRESTAMO_1','CTA_PRESTAMO_2')
                          AND MB.OTRAMON = 'N'
                     THEN MV.VALOR ELSE 0 END) AS PrestamosCOP,
            SUM(CASE WHEN MV.CODIGOCTA IN ('CTA_PRESTAMO_1','CTA_PRESTAMO_2')
                          AND MB.OTRAMON = 'S'
                     THEN MV.VALOR ELSE 0 END) AS PrestamosUSD

        FROM FechaSemana f

        LEFT JOIN TRM t ON t.Semana = f.Semana

        LEFT JOIN MVBANCOS MV 
               ON MV.FECHA <= f.FechaInicio

        LEFT JOIN MTBANCOS MB 
               ON MB.CODIGOCTA = MV.CODIGOCTA

        GROUP BY f.Semana, t.TRM
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