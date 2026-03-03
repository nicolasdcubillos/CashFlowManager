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
                              cada una (base fija 2020-01-06).
    - TRM                   : consulta la tasa de cambio vigente en MTCAMBIO
                              para la fecha de inicio de cada semana.
    - Saldos                : acumula movimientos bancarios (MVBANCOS) hasta
                              la fecha de cada semana, separando COP, USD
                              y cuentas de prestamo.
  Retorna cuatro conceptos: Saldo inicial COP, Saldo inicial USD,
  PA Credicorp - Excedentes y Disponible Bancos.

  PROCEDIMIENTO  dbo.CashflowDataHeaderPivot (@SemanaInicial, @SemanaFinal, @Moneda)
  -----------------------------------------------------------------------------------
  Stored Procedure que transpone la salida de la funcion en una matriz
  donde cada columna es un numero de semana. Construye dinamicamente la
  lista de columnas y ejecuta un PIVOT con SUM(Valor) FOR Semana mediante
  sp_executesql. El resultado se ordena con CASE segun el orden logico
  de los conceptos del encabezado.

  Ejemplo de uso:
    EXEC dbo.CashflowDataHeaderPivot
         @SemanaInicial = 1,
         @SemanaFinal   = 6,
         @Moneda        = 'COP';
================================================================================
*/

CREATE OR ALTER FUNCTION dbo.CashflowDataHeader
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
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
            DATEADD(WEEK, Semana, '2020-01-06') AS FechaInicio
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
            SUM(CASE WHEN MV.CODIGOCTA IN ('CTA_PRESTAMO_1','CTA_PRESTAMO_2')
                     THEN MV.VALOR ELSE 0 END) AS Prestamos

        FROM FechaSemana f

        LEFT JOIN TRM t ON t.Semana = f.Semana

        LEFT JOIN MVBANCOS MV 
               ON MV.FECHA <= f.FechaInicio

        LEFT JOIN MTBANCOS MB 
               ON MB.CODIGOCTA = MV.CODIGOCTA

        GROUP BY f.Semana, t.TRM
    )

    SELECT 'Saldo inicial COP' AS Concepto,
           Semana,
           SaldoCOP AS Valor
    FROM Saldos

    UNION ALL

    SELECT 'Saldo inicial USD',
           Semana,
           CASE WHEN @Moneda = 'USD'
                THEN SaldoUSD
                ELSE SaldoUSD * TRM
           END
    FROM Saldos

    UNION ALL

    SELECT 'PA Credicorp - Excedentes',
           Semana,
           Prestamos
    FROM Saldos

    UNION ALL

    SELECT 'Disponible Bancos',
           Semana,
           SaldoCOP + (SaldoUSD * TRM)
    FROM Saldos
)
GO

CREATE OR ALTER PROCEDURE dbo.CashflowDataHeaderPivot
(
    @SemanaInicial INT,
    @SemanaFinal   INT,
    @Moneda        VARCHAR(3)
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @Columnas NVARCHAR(MAX)
    DECLARE @SQL NVARCHAR(MAX)

    ;WITH Numeros AS
    (
        SELECT @SemanaInicial AS Semana
        UNION ALL
        SELECT Semana + 1
        FROM Numeros
        WHERE Semana + 1 <= @SemanaFinal
    )
    SELECT @Columnas = STRING_AGG(QUOTENAME(Semana), ',')
    FROM Numeros
    OPTION (MAXRECURSION 1000)

    SET @SQL = '
        SELECT *
        FROM
        (
            SELECT Concepto, Semana, Valor
            FROM dbo.CashflowDataHeader('
            + CAST(@SemanaInicial AS VARCHAR) + ','
            + CAST(@SemanaFinal AS VARCHAR) + ','''
            + @Moneda + ''')
        ) src
        PIVOT
        (
            SUM(Valor)
            FOR Semana IN (' + @Columnas + ')
        ) p
        ORDER BY
            CASE Concepto
                WHEN ''Saldo inicial COP'' THEN 1
                WHEN ''Saldo inicial USD'' THEN 2
                WHEN ''PA Credicorp - Excedentes'' THEN 3
                WHEN ''Disponible Bancos'' THEN 4
                ELSE 99
            END
    '

    EXEC sp_executesql @SQL

END
GO

EXEC dbo.CashflowDataHeaderPivot 
     @SemanaInicial = 1,
     @SemanaFinal   = 8,
     @Moneda        = 'COP';


    SELECT * from mtprioc

    SP_HELP MTPROCLI

    SELECT * FROM TIPOCL

    REFERENCES COLFUTURO.dbo.TIPOCL (CODTIPOCL)

