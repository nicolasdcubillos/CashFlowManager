USE [INTECPL]
GO
/****** Object:  UserDefinedFunction [dbo].[fnvOF_ReporteMVBancos_Saldos]    Script Date: 26/04/2026 6:32:40 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Incidente: 15990 
	se le agrega un CTE a la funcion para almacenar la informacion que devuelve 
	y despues de este consultar las cuentas que no estan incluidas en esa consulta 
	para que muestre el saldo inicial y el saldo finaly despues se unen las consultas 
	para que devuelva 1 solo conjunto de informacion.
	Autor: Andres zapata
	Fecha: 10 - Octubre 2018 

	SELECT * FROM fnvOF_ReporteMVBancos_Saldos ('20180801', '20180831')
	DROP FUNCTION dbo.fnvOF_ReporteMVBancos_Saldos 
*/
--se  retira la condicion de filtrar por la fecha de consignacion -24-sep-2012
ALTER FUNCTION [dbo].[fnvOF_ReporteMVBancos_Saldos] 
	(
		@FechaInicial AS DateTime,
		@FechaFinal AS DateTime
	)

Returns Table
As
Return 
(
with CTE(Banco,Nombre_Banco,Tipo_Moneda,Saldo_Anterior,Ingresos,Egresos,Saldo_Final,Saldo)
as
(
	SELECT mtbancos.codigocta AS Banco
		,mtbancos.nombre AS Nombre_Banco
		--,mtbancos.otramon AS Otra_Moneda
		,(case when MTBANCOS.otramon='N' AND MTBANCOS.Moneda='' then 'Pesos' 
			   when MTBANCOS.otramon='S' AND MTBANCOS.Moneda='' then 'OtraMoneda'
			   when MTBANCOS.otramon='N' AND MTBANCOS.Moneda<>'' then 'MultiMoneda'
		 END) as Tipo_Moneda
		,[dbo].[SaldoAnteriorBanco](@FechaInicial, mtbancos.codigocta) AS Saldo_Anterior
		,sum(isnull(debito, 0)) AS Ingresos
		,sum(isnull(CREDITO, 0)) AS Egresos
		,(([dbo].[SaldoAnteriorBanco](@FechaInicial, mtbancos.codigocta)) + (sum(isnull(debito, 0)) - (sum(isnull(CREDITO, 0))))) AS Saldo_Final
		,sum(isnull(debito, 0) - isnull(CREDITO, 0)) AS Saldo
	FROM vreporteMvbancosNuevo
	RIGHT JOIN mtbancos ON (vreporteMvbancosNuevo.Banco = mtbancos.CODIGOCTA AND vreporteMvbancosNuevo.fecha BETWEEN @FechaInicial AND @FechaFinal)
	WHERE vreporteMvbancosNuevo.Saldo <> 0
	GROUP BY banco,mtbancos.nombre,mtbancos.codigocta,mtbancos.otramon,MTBANCOS.Moneda
)
select CodigoCta as Banco, nombre as Nombre_Banco
,(case	when otramon='N' AND Moneda='' then 'Pesos' 
		when otramon='S' AND Moneda='' then 'OtraMoneda'
		when otramon='N' AND Moneda<>'' then 'MultiMoneda'
	 END) as Tipo_Moneda
,[dbo].[SaldoAnteriorBanco](@FechaInicial, mtbancos.codigocta) AS Saldo_Anterior
,0 as Ingresos
,0 as Egresos
,[dbo].[SaldoAnteriorBanco](@FechaInicial, mtbancos.codigocta) AS Saldo_Final
,0 as Saldo
from mtbancos where codigocta not in(SELECT Banco FROM CTE)
and [dbo].[SaldoAnteriorBanco](@FechaInicial, mtbancos.codigocta) <> 0
union 
Select Banco,Nombre_Banco,Tipo_Moneda,Saldo_Anterior,Ingresos,Egresos,Saldo_Final,Saldo from CTE

)