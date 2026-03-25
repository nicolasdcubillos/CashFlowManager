*===========================================================
*  Autor: Nicolas David Cubillos
*  Proyecto: Flujo de Caja INTECPLAST
*  Descripciï¿½n:
*  Generador de Flujo de Caja semanal dinï¿½mico basado en SQL.
*  La lï¿½gica financiera vive en SQL.
*  VFP solo dibuja estructura y fï¿½rmulas en Excel.
*===========================================================
*-----------------------------------------------------------
* PALETA DE COLORES
*-----------------------------------------------------------
#DEFINE COLOR_BLANCO         16777215   && RGB(255,255,255) - fondo hoja
#DEFINE COLOR_TITULO_FUENTE         0   && RGB(  0,  0,  0) - negro, letras header y data
#DEFINE COLOR_HEADER_FONDO   12419407   && RGB( 79,129,189) - azul #4F81BD, fila PERIODO
#DEFINE COLOR_FILA_PAR       15853019   && RGB(219,229,241) - gris claro #DBE5F1, filas pares
#DEFINE COLOR_FILA_IMPAR     16777215   && RGB(255,255,255) - blanco, filas impares
#DEFINE COLOR_TOTALES        14341079   && RGB(215,211,218) - lila claro #D7D3DA, seccion totales
*-----------------------------------------------------------* ENTRY POINT: GenerarCashFlowExcelFecha
* Recibe fecha final. Lee SemanasAtras/SemanasAdelante de BD.
*-----------------------------------------------------------
FUNCTION generarCashFlowExcelFecha
    LPARAMETERS tdFechaFinal

    LOCAL tnSemanasAtras, tnSemanasAdelante

    tnSemanasAtras    = VAL(TRANSFORM(LeerConfigCashFlow("SemanasAtras",    6)))
    tnSemanasAdelante = VAL(TRANSFORM(LeerConfigCashFlow("SemanasAdelante", 6)))

    RETURN GenerarCashFlowExcel(tdFechaFinal, tnSemanasAtras, tnSemanasAdelante)
ENDFUNC

*-----------------------------------------------------------
* ENTRY POINT: GenerarCashFlowExcelSemana
* Recibe aÃ±o e ISO semana. Calcula la fecha del lunes de
* esa semana y delega en GenerarCashFlowExcel.
*-----------------------------------------------------------
FUNCTION generarCashFlowExcelSemana
    LPARAMETERS tnAnio, tnSemana

    LOCAL ldJan4, lnDOW, ldLunesS1, ldFechaFinal
    LOCAL tnSemanasAtras, tnSemanasAdelante

    * ISO 8601: la semana 1 siempre contiene el 4 de enero.
    * Encontramos el lunes de esa semana y sumamos (tnSemana-1)*7 dias.
    ldJan4       = DATE(tnAnio, 1, 4)
    lnDOW        = DOW(ldJan4, 2)              && 1=Lun ... 7=Dom
    ldLunesS1    = ldJan4 - (lnDOW - 1)       && Lunes de la ISO semana 1
    ldFechaFinal = ldLunesS1 + ((tnSemana - 1) * 7)  && Lunes de la semana pedida

    tnSemanasAtras    = VAL(TRANSFORM(LeerConfigCashFlow("SemanasAtras",    6)))
    tnSemanasAdelante = VAL(TRANSFORM(LeerConfigCashFlow("SemanasAdelante", 6)))

    RETURN GenerarCashFlowExcel(ldFechaFinal, tnSemanasAtras, tnSemanasAdelante)
ENDFUNC

*-----------------------------------------------------------* FUNCION PRINCIPAL
* Genera archivo Excel completo (USD y COP)
*-----------------------------------------------------------
FUNCTION GenerarCashFlowExcel
    LPARAMETERS tdFechaFinal, ;
                tnSemanasAtras, ;
                tnSemanasAdelante

    LOCAL loExcel, loLibro, loHojaUSD
    LOCAL ldFechaBase
    LOCAL lcErrorDetalle, lcNombreArchivo, lcRuta
    LOCAL ARRAY laNomMeses[12]
    laNomMeses[1]  = "Enero"
    laNomMeses[2]  = "Febrero"
    laNomMeses[3]  = "Marzo"
    laNomMeses[4]  = "Abril"
    laNomMeses[5]  = "Mayo"
    laNomMeses[6]  = "Junio"
    laNomMeses[7]  = "Julio"
    laNomMeses[8]  = "Agosto"
    laNomMeses[9]  = "Septiembre"
    laNomMeses[10] = "Octubre"
    laNomMeses[11] = "Noviembre"
    laNomMeses[12] = "Diciembre"

    IF PCOUNT() < 3
        MESSAGEBOX("Debe enviar FechaFinal, SemanasAtras, SemanasAdelante",16,"Error")
        RETURN .F.
    ENDIF

    TRY

        WAIT WINDOW "Inicializando generación de Flujo de Caja..." NOWAIT  && NUEVO

        * Nombre del archivo de salida
        lcNombreArchivo = "FlujoDeCaja_Intecplast_" + ;
                          laNomMeses[MONTH(tdFechaFinal)] + ;
                          TRANSFORM(YEAR(tdFechaFinal)) + ".xlsx"
        lcRuta = ADDBS(CURDIR()) + lcNombreArchivo
        ldFechaBase = tdFechaFinal - (DOW(tdFechaFinal,2) - 1)

        loExcel = CREATEOBJECT("Excel.Application")
        loExcel.Visible = .T.
        loLibro = loExcel.Workbooks.Add

        *===========================================
        * HOJA 1 - USD
        *===========================================
        WAIT WINDOW "Construyendo hoja USD..." NOWAIT  && NUEVO

        loHojaUSD = loLibro.Sheets(1)
        loHojaUSD.Name = "CF I Q-AJUSTADO USD"

        FormatearHojaBase(loHojaUSD)

        WAIT WINDOW "Armando encabezado USD..." NOWAIT  && NUEVO

        ArmarEncabezadoCashFlow(loHojaUSD, ;
                                "USD", ;
                                tdFechaFinal, ;
                                ldFechaBase, ;
                                tnSemanasAtras, ;
                                tnSemanasAdelante)

        WAIT WINDOW "Consultando y dibujando datos USD..." NOWAIT  && NUEVO

        * SQL historico: desde -tnSemanasAtras hasta la semana actual (0)
        IF NOT ArmarDataCashFlowHistorico(loHojaUSD, ;
                                          -tnSemanasAtras, ;
                                          0, ;
                                          "USD")
            RETURN .F.
        ENDIF

        *===========================================
        * HOJA 2 - COP
        *===========================================
        WAIT WINDOW "Construyendo hoja COP..." NOWAIT  && NUEVO

        IF NOT CrearHojaCashFlow(loLibro, ;
                                  "COP", ;
                                  tdFechaFinal, ;
                                  ldFechaBase, ;
                                  tnSemanasAtras, ;
                                  tnSemanasAdelante)
            RETURN .F.
        ENDIF

        * Guardar archivo con nombre estandar
        WAIT WINDOW "Guardando " + lcNombreArchivo + "..." NOWAIT
        loLibro.SaveAs(lcRuta, 51)  && 51 = xlOpenXMLWorkbook (.xlsx)

        WAIT CLEAR
        MESSAGEBOX( ;
            "Flujo de Caja generado exitosamente." + CHR(13)+CHR(10)+CHR(13)+CHR(10) + ;
            "Archivo:    " + lcNombreArchivo + CHR(13)+CHR(10) + ;
            "Periodo:    " + laNomMeses[MONTH(tdFechaFinal)] + " " + TRANSFORM(YEAR(tdFechaFinal)) + CHR(13)+CHR(10) + ;
            "Historico:  " + TRANSFORM(tnSemanasAtras)    + " semanas atras"    + CHR(13)+CHR(10) + ;
            "Proyeccion: " + TRANSFORM(tnSemanasAdelante) + " semanas adelante", ;
            64, ;
            "Flujo de Caja - INTECPLAST")

    CATCH TO loError

        lcErrorDetalle = ;
            "ERROR GENERANDO EXCEL" + CHR(13)+CHR(10)+CHR(13)+CHR(10) + ;
            "Mensaje: " + loError.Message + CHR(13)+CHR(10) + ;
            "Error No: " + TRANSFORM(loError.ErrorNo) + CHR(13)+CHR(10) + ;
            "Procedimiento: " + loError.Procedure + CHR(13)+CHR(10) + ;
            "Lï¿½nea: " + TRANSFORM(loError.LineNo)

        MESSAGEBOX(lcErrorDetalle,16,"Error Fatal")

    ENDTRY

    RETURN .T.
ENDFUNC


*-----------------------------------------------------------
* CREA HOJA ADICIONAL (COP)
*-----------------------------------------------------------
FUNCTION CrearHojaCashFlow
    LPARAMETERS loLibro, tcMoneda, ;
                tdFechaFinal, ldFechaBase, ;
                tnSemanasAtras, tnSemanasAdelante

    LOCAL loHoja

    WAIT WINDOW "Creando hoja " + tcMoneda + "..." NOWAIT

    loHoja = loLibro.Sheets.Add(, loLibro.Sheets(loLibro.Sheets.Count))
    loHoja.Name = "CF I Q-AJUSTADO " + tcMoneda

    WAIT WINDOW "Formateando hoja " + tcMoneda + "..." NOWAIT
    FormatearHojaBase(loHoja)

    WAIT WINDOW "Armando encabezado " + tcMoneda + "..." NOWAIT
    ArmarEncabezadoCashFlow(loHoja, ;
                            tcMoneda, ;
                            tdFechaFinal, ;
                            ldFechaBase, ;
                            tnSemanasAtras, ;
                            tnSemanasAdelante)

    WAIT WINDOW "Consultando y dibujando datos " + tcMoneda + "..." NOWAIT
    * SQL historico: desde -tnSemanasAtras hasta la semana actual (0)
    IF NOT ArmarDataCashFlowHistorico(loHoja, ;
                                      -tnSemanasAtras, ;
                                      0, ;
                                      tcMoneda)
        RETURN .F.
    ENDIF

    RETURN .T.
ENDFUNC

*-----------------------------------------------------------
* 1) ARMA ENCABEZADO
* Dibuja tï¿½tulo y estructura visual superior.
*-----------------------------------------------------------
FUNCTION ArmarEncabezadoCashFlow
    LPARAMETERS loHoja, tcMoneda, ;
                tdFechaFinal, ldFechaBase, ;
                tnSemanasAtras, tnSemanasAdelante

    LOCAL lnColumna, lnUltimaColumna
    LOCAL ldFechaSemana, lnSemana, lnTRM, i
    LOCAL lcMes
    LOCAL ARRAY laMeses[12]
    laMeses[1]  = "Enero"
    laMeses[2]  = "Febrero"
    laMeses[3]  = "Marzo"
    laMeses[4]  = "Abril"
    laMeses[5]  = "Mayo"
    laMeses[6]  = "Junio"
    laMeses[7]  = "Julio"
    laMeses[8]  = "Agosto"
    laMeses[9]  = "Septiembre"
    laMeses[10] = "Octubre"
    laMeses[11] = "Noviembre"
    laMeses[12] = "Diciembre"
    lcMes = laMeses[MONTH(tdFechaFinal)]

    loHoja.Cells(2,2).Value = ;
        "Flujo de Caja " + lcMes + " " + ;
        TRANSFORM(YEAR(tdFechaFinal)) + " - Intecplast SAS"

    loHoja.Range("B2").Font.Name   = "Calibri"
    loHoja.Range("B2").Font.Size   = 14
    loHoja.Range("B2").Font.Bold   = .T.
    loHoja.Range("B2").Font.Italic = .T.

    IF tcMoneda = "USD"
        loHoja.Cells(3,2).Value = "TRM"
        loHoja.Cells(3,2).Font.Bold = .T.
    ENDIF

    lnColumna = 3

    FOR i = -tnSemanasAtras TO tnSemanasAdelante

        ldFechaSemana = ldFechaBase + (i * 7)
        lnSemana = WEEK(ldFechaSemana, 2)

        IF tcMoneda = "USD"
            lnTRM = ObtenerTRM(ldFechaSemana)
            loHoja.Cells(3, lnColumna).Value = lnTRM
            loHoja.Cells(3, lnColumna).NumberFormat = "#,##0.00"
        ENDIF

        loHoja.Cells(5, lnColumna).Value = ;
            "SEMANA " + TRANSFORM(lnSemana)

        loHoja.Cells(6, lnColumna).Value = ldFechaSemana
        loHoja.Cells(6, lnColumna).NumberFormat = "dd-mmm"

        IF i = 0
            loHoja.Cells(4, lnColumna).Value = "ACTUAL"
            loHoja.Cells(4, lnColumna).Font.Bold = .T.
            loHoja.Cells(5, lnColumna).Font.Bold = .T.
        ENDIF

        lnColumna = lnColumna + 1

    ENDFOR

    lnUltimaColumna = lnColumna - 1

    loHoja.Cells(5,2).Value = "PERIODO"
    loHoja.Cells(5,2).Font.Bold = .T.

    loHoja.Range( ;
        loHoja.Cells(5,2), ;
        loHoja.Cells(6,lnUltimaColumna) ;
    ).HorizontalAlignment = -4108

    * Fila 5: PERIODO / SEMANA - fondo azul #4F81BD, letra negra, negrilla
    WITH loHoja.Range(loHoja.Cells(5,2), loHoja.Cells(5,lnUltimaColumna))
        .Font.Name      = "Calibri"
        .Font.Size      = 11
        .Font.Bold      = .T.
        .Font.Color     = COLOR_TITULO_FUENTE  && negro
        .Interior.Color = COLOR_HEADER_FONDO   && azul #4F81BD
    ENDWITH

    * Fila 6: fechas - fondo gris claro #DBE5F1, letra negra
    WITH loHoja.Range(loHoja.Cells(6,2), loHoja.Cells(6,lnUltimaColumna))
        .Interior.Color = COLOR_FILA_PAR       && gris claro #DBE5F1
        .Font.Color     = COLOR_TITULO_FUENTE  && negro
    ENDWITH

    * Bordes finos en el bloque del header (filas 5-6)
    WITH loHoja.Range(loHoja.Cells(5,2), loHoja.Cells(6,lnUltimaColumna)).Borders
        .LineStyle = 1   && xlContinuous
        .Weight    = 2   && xlThin
    ENDWITH

ENDFUNC


*-----------------------------------------------------------
* 2-8) ARMA DATA HISTORICA
* Ejecuta vistas SQL (solo historico) y dibuja Header,
* Ingresos, Egresos, Flujo Economico, Subtotales y Flujo Neto.
* tnSemanaInicial : numero negativo (ej. -5 = 5 semanas atras)
* tnSemanaFinal   : 0 = semana actual (no consulta futuro)
*-----------------------------------------------------------
FUNCTION ArmarDataCashFlowHistorico
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    LOCAL lnFilaActual
    LOCAL lnFilaInicioIngresos, lnFilaFinIngresos
    LOCAL lnFilaInicioEgresos,  lnFilaFinEgresos
    LOCAL lnFilaInicioFlujoEco, lnFilaFinFlujoEco
    LOCAL lnTmpCol, lnUltimaColData
    LOCAL lcSQL, lnResult, laError[1]

    lnFilaActual = 8
    
    *========================================
	* 1) HEADER FINANCIERO (ANTES DE INGRESOS)
	*========================================
	WAIT WINDOW "Dibujando header financiero " + tcMoneda + "..." NOWAIT
	lnFilaActual = DibujarCashflowHeader(loHoja, ;
	                                     tnSemanaInicial, ;
	                                     tnSemanaFinal, ;
	                                     tcMoneda)

    *========================================
    * 2) EJECUTAR VISTA INGRESOS
    *========================================
    WAIT WINDOW "Ejecutando consulta de Ingresos " + tcMoneda + "..." NOWAIT
    LOCAL lnColsec
    lnColsec = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnColsec < 2
        lnColsec = 10
    ENDIF
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnColsec)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    loHoja.Cells(lnFilaActual,2).Value = "Ingresos"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioIngresos = lnFilaActual

    lcSQL = ;
	    "EXEC dbo.CashflowDataIngresosPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    ALLTRIM(tcMoneda) + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrIngresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataIngresosPivot:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 3) Dibujar ingresos
    WAIT WINDOW "Dibujando Ingresos en Excel " + tcMoneda + "..." NOWAIT
    lnFilaActual = DibujarCursor(loHoja, "csrIngresos", lnFilaActual)

    lnFilaFinIngresos = lnFilaActual - 1

    * 4) Subtotal ingresos
    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioIngresos, ;
                                   lnFilaFinIngresos, ;
                                   lnFilaActual, ;
                                   "Total ingresos")

    lnFilaActual = lnFilaActual + 1

    *========================================
    * 5) EJECUTAR VISTA EGRESOS
    *========================================
    WAIT WINDOW "Ejecutando consulta de Egresos " + tcMoneda + "..." NOWAIT
    LOCAL lnColsec2
    lnColsec2 = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnColsec2 < 2
        lnColsec2 = 10
    ENDIF
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnColsec2)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    loHoja.Cells(lnFilaActual,2).Value = "Egresos"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioEgresos = lnFilaActual
    
    lcSQL = ;
	    "EXEC dbo.CashflowDataEgresosPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    ALLTRIM(tcMoneda) + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrEgresos")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataEgresosPivot:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 6) Dibujar egresos
    WAIT WINDOW "Dibujando Egresos en Excel " + tcMoneda + "..." NOWAIT
    lnFilaActual = DibujarCursor(loHoja, "csrEgresos", lnFilaActual)

    lnFilaFinEgresos = lnFilaActual - 1

    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioEgresos, ;
                                   lnFilaFinEgresos, ;
                                   lnFilaActual, ;
                                   "Total egresos")

    lnFilaActual = lnFilaActual + 1

    *========================================
    * 7) EJECUTAR FLUJO ECONOMICO
    *========================================
    WAIT WINDOW "Ejecutando consulta de Flujo Economico " + tcMoneda + "..." NOWAIT
    LOCAL lnColsec3
    lnColsec3 = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnColsec3 < 2
        lnColsec3 = 10
    ENDIF
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnColsec3)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    loHoja.Cells(lnFilaActual,2).Value = "Flujo Economico"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    lnFilaActual = lnFilaActual + 1

    lnFilaInicioFlujoEco = lnFilaActual

    lcSQL = ;
        "EXEC dbo.CashflowDataFlujoEconomicoPivot " + ;
        ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
        ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
        ALLTRIM(tcMoneda) + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrFlujoEco")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataFlujoEconomicoPivot:" + ;
                   CHR(13) + laError[2])
        RETURN .F.
    ENDIF

    * 8) Dibujar flujo economico
    WAIT WINDOW "Dibujando Flujo Economico en Excel " + tcMoneda + "..." NOWAIT
    lnFilaActual = DibujarCursor(loHoja, "csrFlujoEco", lnFilaActual)

    lnFilaFinFlujoEco = lnFilaActual - 1

    lnFilaActual = DibujarSubtotal(loHoja, ;
                                   lnFilaInicioFlujoEco, ;
                                   lnFilaFinFlujoEco, ;
                                   lnFilaActual, ;
                                   "Total Financiamiento")

    lnFilaActual = lnFilaActual + 1

    *========================================
    * 10) FLUJO DE CAJA FINANCIERO (en 0 por ahora)
    *========================================
    lnUltimaColData = loHoja.Cells(lnFilaActual-1, loHoja.Columns.Count).End(-4159).Column
    IF lnUltimaColData < 3
        lnUltimaColData = 10
    ENDIF

    loHoja.Cells(lnFilaActual,2).Value = "Flujo de Caja Financiero"
    loHoja.Cells(lnFilaActual,2).Font.Bold = .T.
    loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnUltimaColData)).Interior.Color = ColorFilaAlternar(lnFilaActual)
    FOR lnTmpCol = 3 TO lnUltimaColData
        loHoja.Cells(lnFilaActual,lnTmpCol).Value         = 0
        loHoja.Cells(lnFilaActual,lnTmpCol).NumberFormat  = "#,##0;-#,##0;" + CHR(34) + "-" + CHR(34)  && 0 muestra guion
        loHoja.Cells(lnFilaActual,lnTmpCol).Font.Bold     = .T.
    ENDFOR
    WITH loHoja.Range(loHoja.Cells(lnFilaActual,2), loHoja.Cells(lnFilaActual,lnUltimaColData)).Borders
        .LineStyle = 1
        .Weight    = 2
    ENDWITH
    lnFilaActual = lnFilaActual + 3  && fila Flujo Financiero + 2 blancos

    *========================================
    * 11) TOTALES (calculados en VFP, sin SQL)
    *========================================
    WAIT WINDOW "Dibujando Totales " + tcMoneda + "..." NOWAIT
    DibujarTotalesCashFlow(loHoja, lnFilaActual, lnUltimaColData)

    * Ajustar ancho columna B al texto mas largo
    loHoja.Columns(2).AutoFit()

ENDFUNC


*-----------------------------------------------------------
* ARMA DATA FUTURA (pendiente de implementar)
* Dibujara proyecciones en las columnas futuras a partir
* de tnSemanaInicial=1 hasta tnSemanaFinal=tnSemanasAdelante.
* Por ahora NO se invoca desde GenerarCashFlowExcel.
*-----------------------------------------------------------
FUNCTION ArmarDataCashFlowFuturo
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    * TODO: implementar consulta y dibujo de semanas futuras

ENDFUNC


*-----------------------------------------------------------
* DIBUJA HEADER FINANCIERO (ANTES DE INGRESOS)
*-----------------------------------------------------------
FUNCTION DibujarCashflowHeader
    LPARAMETERS loHoja, ;
                tnSemanaInicial, ;
                tnSemanaFinal, ;
                tcMoneda

    LOCAL lcSQL, lnResult, laError[1]
    LOCAL lnFilaActual

    lnFilaActual = 8

    WAIT WINDOW "Ejecutando consulta Header " + tcMoneda + "..." NOWAIT

    lcSQL = ;
	    "EXEC dbo.CashflowDataHeaderPivot " + ;
	    ALLTRIM(STR(tnSemanaInicial)) + ", " + ;
	    ALLTRIM(STR(tnSemanaFinal)) + ", '" + ;
	    tcMoneda + "'"

    lnResult = SQLEXEC(ON, lcSQL, "csrHeader")

    IF lnResult < 0
        AERROR(laError)
        MESSAGEBOX("Error ejecutando CashflowDataHeaderPivot:" + CHR(13) + laError[2])
        RETURN lnFilaActual
    ENDIF

    * Dibujar cursor completo
    lnFilaActual = DibujarCursor(loHoja, "csrHeader", lnFilaActual)

    RETURN lnFilaActual
ENDFUNC

*-----------------------------------------------------------
* Dibuja cursor completo en Excel
*-----------------------------------------------------------
FUNCTION DibujarCursor
    LPARAMETERS loHoja, tcCursor, lnFilaActual

    LOCAL lnCol, lnTotalCols

    SELECT (tcCursor)
    GO TOP

    SCAN
        lnTotalCols = FCOUNT()
        loHoja.Range( ;
            loHoja.Cells(lnFilaActual, 2), ;
            loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
        ).Interior.Color = ColorFilaAlternar(lnFilaActual)

        FOR lnCol = 1 TO lnTotalCols
            loHoja.Cells(lnFilaActual, lnCol + 1).Value = ;
                EVALUATE(FIELD(lnCol))
        ENDFOR

        * Formato numerico en columnas de datos (col 3 en adelante)
        * 0 muestra guion (-) visualmente, valor real sigue siendo 0
        IF lnTotalCols > 1
            loHoja.Range( ;
                loHoja.Cells(lnFilaActual, 3), ;
                loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
            ).NumberFormat = "#,##0;-#,##0;" + CHR(34) + "-" + CHR(34)
        ENDIF

        * Borde fino en la fila de datos
        WITH loHoja.Range( ;
            loHoja.Cells(lnFilaActual, 2), ;
            loHoja.Cells(lnFilaActual, lnTotalCols + 1) ;
        ).Borders
            .LineStyle = 1
            .Weight    = 2
        ENDWITH

        lnFilaActual = lnFilaActual + 1
    ENDSCAN

    RETURN lnFilaActual
ENDFUNC


*-----------------------------------------------------------
* Dibuja subtotal por columna usando fï¿½rmula SUM
*-----------------------------------------------------------
FUNCTION DibujarSubtotal
    LPARAMETERS loHoja, ;
                lnFilaInicio, ;
                lnFilaFin, ;
                lnFilaSubtotal, ;
                tcTitulo

    LOCAL lnCol, lcLetraCol
    LOCAL lnUltimaCol

    loHoja.Cells(lnFilaSubtotal,2).Value = tcTitulo
    loHoja.Cells(lnFilaSubtotal,2).Font.Bold = .T.

    lnUltimaCol = loHoja.Cells(lnFilaInicio, ;
                   loHoja.Columns.Count).End(-4159).Column

    loHoja.Range( ;
        loHoja.Cells(lnFilaSubtotal, 2), ;
        loHoja.Cells(lnFilaSubtotal, lnUltimaCol) ;
    ).Interior.Color = ColorFilaAlternar(lnFilaSubtotal)

    FOR lnCol = 3 TO lnUltimaCol

        lcLetraCol = ColumnaLetra(lnCol)

        loHoja.Cells(lnFilaSubtotal,lnCol).Formula = ;
            "=SUM(" + ;
            lcLetraCol + TRANSFORM(lnFilaInicio) + ":" + ;
            lcLetraCol + TRANSFORM(lnFilaFin) + ")"

        loHoja.Cells(lnFilaSubtotal,lnCol).Font.Bold = .T.
        loHoja.Cells(lnFilaSubtotal,lnCol).NumberFormat = "#,##0;-#,##0;" + CHR(34) + "-" + CHR(34)  && 0 muestra guion

    ENDFOR

    * Borde fino en la fila de subtotal
    WITH loHoja.Range( ;
        loHoja.Cells(lnFilaSubtotal, 2), ;
        loHoja.Cells(lnFilaSubtotal, lnUltimaCol) ;
    ).Borders
        .LineStyle = 1
        .Weight    = 2
    ENDWITH

    RETURN lnFilaSubtotal
ENDFUNC


*-----------------------------------------------------------
* Dibuja seccion de Totales (calculados en VFP, sin SQL)
* Color fijo #D7D3DA sin alternar - 7 conceptos en 0 por ahora
*-----------------------------------------------------------
FUNCTION DibujarTotalesCashFlow
    LPARAMETERS loHoja, lnFilaInicio, lnUltimaCol

    LOCAL lnFila, lnCol, lnIdx
    LOCAL ARRAY laTitulos[7]
    laTitulos[1] = "PA Credicorp - Caja Retenida Reserva Credito (83237)"
    laTitulos[2] = "PA Credicorp - Caja Retenida Pago Cuota Trimestral (83238)"
    laTitulos[3] = "FIC Credicorp - Provision Impuesto al Plastico"
    laTitulos[4] = "Disponible Bancos"
    laTitulos[5] = "TOTAL 30 NOV 2025"
    laTitulos[6] = "TOTAL CONTABILIDAD"
    laTitulos[7] = "DIFERENCIA"

    lnFila = lnFilaInicio

    FOR lnIdx = 1 TO 7

        loHoja.Cells(lnFila,2).Value = laTitulos[lnIdx]

        * Color fijo #D7D3DA en toda la fila, sin alternar
        loHoja.Range( ;
            loHoja.Cells(lnFila,2), ;
            loHoja.Cells(lnFila,lnUltimaCol) ;
        ).Interior.Color = COLOR_TOTALES

        FOR lnCol = 3 TO lnUltimaCol
            loHoja.Cells(lnFila,lnCol).Value        = 0  && TODO: calcular con data en memoria
            loHoja.Cells(lnFila,lnCol).NumberFormat = "#,##0;-#,##0;" + CHR(34) + "-" + CHR(34)  && 0 muestra guion
        ENDFOR

        WITH loHoja.Range( ;
            loHoja.Cells(lnFila,2), ;
            loHoja.Cells(lnFila,lnUltimaCol) ;
        ).Borders
            .LineStyle = 1
            .Weight    = 2
        ENDWITH

        lnFila = lnFila + 1

    ENDFOR

ENDFUNC


*-----------------------------------------------------------
* Retorna color alterno: azul pastel o gris muy claro
*-----------------------------------------------------------
FUNCTION ColorFilaAlternar
    LPARAMETERS lnFila
    IF lnFila % 2 = 0
        RETURN COLOR_FILA_PAR    && azul pastel
    ELSE
        RETURN COLOR_FILA_IMPAR  && gris claro
    ENDIF
ENDFUNC


*-----------------------------------------------------------
* Convierte nï¿½mero de columna a letra (A,B,C,...,AA)
*-----------------------------------------------------------
FUNCTION ColumnaLetra
    LPARAMETERS lnCol

    LOCAL lcLetra
    lcLetra = ""

    DO WHILE lnCol > 0
        lnCol = lnCol - 1
        lcLetra = CHR((lnCol % 26) + 65) + lcLetra
        lnCol = INT(lnCol / 26)
    ENDDO

    RETURN lcLetra
ENDFUNC


*-----------------------------------------------------------
* Formato base hoja Excel
*-----------------------------------------------------------
FUNCTION FormatearHojaBase
    LPARAMETERS loHoja

    loHoja.Cells.Font.Name = "Calibri"
    loHoja.Cells.Font.Size = 11
    loHoja.Columns(1).ColumnWidth = 3    && col A vacia delgada (formato)
    && col B: ancho inicial, AutoFit se aplica al terminar de dibujar datos

    * Fondo blanco toda la hoja
    loHoja.Cells.Interior.Color = COLOR_BLANCO  && fondo blanco toda la hoja

    * Sin lineas de cuadricula
    loHoja.Activate()
    loHoja.Parent.Parent.ActiveWindow.DisplayGridlines = .F.

    * Inmovilizar: filas 1-6 y columnas A-B fijas al desplazarse
    loHoja.Parent.Parent.ActiveWindow.FreezePanes = .F.  && reset previo
    loHoja.Cells(8, 3).Select()                          && C7 = justo debajo fila 6, a la derecha de col B
    loHoja.Parent.Parent.ActiveWindow.FreezePanes = .T.

ENDFUNC

*-----------------------------------------------------------* LEE VALOR DE CONFIGURACION DESDE CashflowManagerConfig
* Retorna tnDefault si el registro no existe o hay error.
*-----------------------------------------------------------
FUNCTION LeerConfigCashFlow
    LPARAMETERS tcConfig, tnDefault

    LOCAL lcSQL, lnResult, luValor

    lcSQL    = "SELECT Value FROM dbo.CashflowManagerConfig WHERE Config = '" + ALLTRIM(tcConfig) + "'"
    lnResult = SQLEXEC(ON, lcSQL, "csrCfg")

    IF lnResult <= 0
        IF USED("csrCfg")
            USE IN csrCfg
        ENDIF
        THROW "LeerConfigCashFlow: error al consultar la configuracion '" + ALLTRIM(tcConfig) + "' (SQLEXEC=" + TRANSFORM(lnResult) + ")"
    ENDIF

    SELECT csrCfg
    luValor = ALLTRIM(NVL(csrCfg.Value, ""))
    USE IN csrCfg

    IF !EMPTY(luValor)
        RETURN luValor
    ENDIF

    RETURN tnDefault
ENDFUNC

*-----------------------------------------------------------* OBTENER TRM DESDE SQL SERVER
* Devuelve la TRM para una fecha especï¿½fica.
*-----------------------------------------------------------
FUNCTION ObtenerTRM
    LPARAMETERS tdFecha

    LOCAL lcSQL, lnResultado, lnValor, lcFecha

    lnValor = 0
    lcFecha = DTOC(tdFecha, 1)

    lcSQL = ;
        "SELECT TOP 1 VALOR FROM MTCAMBIO " + ;
        "WHERE FECHA >= '" + lcFecha + "' " + ;
        "AND FECHA < DATEADD(DAY,1,'" + lcFecha + "') " + ;
        "ORDER BY FECHA DESC"

    lnResultado = SQLEXEC(ON, lcSQL, "curTRM")

    IF lnResultado > 0 AND RECCOUNT("curTRM") > 0
        SELECT curTRM
        lnValor = curTRM.VALOR
        USE IN curTRM
    ENDIF

    RETURN lnValor
ENDFUNC