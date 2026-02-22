
*/
*!*
*!*		Nombre: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Autor: Nicolás David Cubillos
*!*
*!*		Contenido: Cargue de Requisiciones desde Archivo Excel - Libreria Lerner
*!*
*!*		Fecha: 1 de junio de 2024
*!*
*/

*---------------------------------------------------

FUNCTION uploadFile(lcFileName, outRqData)
LOCAL outErrorMsg
TRY
	lcLinesWithErrors = 0

* Abriendo el archivo de Excel
	oExcel = CREATEOBJECT("Excel.Application")
	oWorkbook = oExcel.Workbooks.OPEN(lcFileName)
	oExcel.VISIBLE = .T.
&&	oWorkbook.READONLY = .F.
	oSheet = oWorkbook.Sheets(1)

* Validaciones del formato
	lcColumnsCountShouldBe = 11
	IF oSheet.UsedRange.COLUMNS.COUNT != lcColumnsCountShouldBe
		errMsg = "El formato del archivo Excel seleccionado es incorrecto. Debe contener " + ;
			ALLTRIM(STR(lcColumnsCountShouldBe)) + " columnas y contiene " + ALLTRIM(STR(oSheet.UsedRange.COLUMNS.COUNT)) + "."
		ERROR(errMsg)
	ENDIF

	lcActualRow = 1
	outErrorMsg = ""
	lcStartRow = 5
	lnLastCol = oSheet.UsedRange.COLUMNS.COUNT + 1
	oSheet.Cells(lcStartRow - 1, lnLastCol).VALUE = "Detalle del error"
	oSheet.Cells(lcStartRow - 1, lnLastCol).FONT.Bold = .T.

	lcResponsable = getValueWithoutValidate(oSheet.Cells(2, 5).VALUE, oSheet.Cells(2, 4).VALUE, @outErrorMsg)

	lcCodResponsable = getValue(TRANSFORM(oSheet.Cells(3, 5).VALUE), oSheet.Cells(3, 4).VALUE, @outErrorMsg)
	validateResponsable(lcCodResponsable, @outErrorMsg)

	CREATE CURSOR outRqData( ;
		Cargar N(1, 0), ;
		CodProveedor C(50), ;
		NombreProveedor C(50), ;
		ISBN C(20), ;
		Titulo C(100), ;
		AUTOR C(50), ;
		Editorial C(50), ;
		Tema C(50), ;
		Precio N(12,2), ;
		Cantidad N(10,2), ;
		CodSede C(50), ;
		Sede C(50) ;
		)

	FOR lnRow = lcStartRow TO oSheet.UsedRange.ROWS.COUNT
		outErrorMsg = ""

		lcCodProveedor = getValue(TRANSFORM(oSheet.Cells(lnRow, 1).VALUE), oSheet.Cells(1, 1).VALUE, @outErrorMsg)
		validateCodProveedor(lcCodProveedor, @outErrorMsg)

		lcNombreProveedor = getValue(TRANSFORM(oSheet.Cells(lnRow, 2).VALUE), oSheet.Cells(1, 2).VALUE, @outErrorMsg)

		lcISBN = getValue(TRANSFORM(oSheet.Cells(lnRow, 3).VALUE), oSheet.Cells(1, 3).VALUE, @outErrorMsg)
		validateISBN(lcISBN, @outErrorMsg)

		lcTitulo = getValue(TRANSFORM(oSheet.Cells(lnRow, 4).VALUE), oSheet.Cells(1, 4).VALUE, @outErrorMsg)

		lcAutor = getValue(TRANSFORM(oSheet.Cells(lnRow, 5).VALUE), oSheet.Cells(1, 5).VALUE, @outErrorMsg)

		lcEditorial = getValue(TRANSFORM(oSheet.Cells(lnRow, 6).VALUE), oSheet.Cells(1, 6).VALUE, @outErrorMsg)

		lcTema = getValue(TRANSFORM(oSheet.Cells(lnRow, 7).VALUE), oSheet.Cells(1, 7).VALUE, @outErrorMsg)

		lnPrecio = getAndValidateNumericValue(oSheet.Cells(lnRow, 8).VALUE, oSheet.Cells(1, 8).VALUE, @outErrorMsg)

		lnCantidad = getAndValidateNumericValue(oSheet.Cells(lnRow, 9).VALUE, oSheet.Cells(1, 9).VALUE, @outErrorMsg)

		lcCodSede = getValue(TRANSFORM(oSheet.Cells(lnRow, 10).VALUE), oSheet.Cells(1, 10).VALUE, @outErrorMsg)
		validateSede(lcCodSede, @outErrorMsg)

		lcSede = getValueWithoutValidate(oSheet.Cells(lnRow, 11).VALUE, oSheet.Cells(1, 11).VALUE, @outErrorMsg)

		&&lcCodResponsable = getValue(TRANSFORM(oSheet.Cells(lnRow, 12).VALUE), oSheet.Cells(1, 12).VALUE, @outErrorMsg)
		&&validateResponsable(lcCodResponsable, @outErrorMsg)

		&&lcResponsable = getValueWithoutValidate(oSheet.Cells(lnRow, 13).VALUE, oSheet.Cells(1, 13).VALUE, @outErrorMsg)

		IF EMPTY(outErrorMsg)
			oSheet.Cells(lcActualRow, lnLastCol).VALUE = ""

			INSERT INTO outRqData VALUES ( ;
				1, ;
				lcCodProveedor, ;
				lcNombreProveedor, ;
				lcISBN, ;
				lcTitulo, ;
				lcAutor, ;
				lcEditorial, ;
				lcTema, ;
				lnPrecio, ;
				lnCantidad, ;
				lcCodSede, ;
				lcSede ;
				)

		ELSE
			lcLinesWithErrors = lcLinesWithErrors + 1
			oSheet.Cells(lnRow, lnLastCol).VALUE = outErrorMsg
		ENDIF
	NEXT

	IF lcLinesWithErrors > 0
		lcErrorMessage = "Algunas filas en el archivo contienen errores de validación." + CHR(13) + CHR(13) + "Revise el archivo Excel que se ha abierto para ver los detalles del error."
		ERROR(lcErrorMessage)
	ELSE
		MESSAGEBOX ('Requisiciones cargadas correctamente desde el archivo.', 64)
	ENDIF

	oWorkbook.CLOSE(.F.)
	oExcel.QUIT()

	RELEASE oSheet, oWorkbook, oExcel

ENDTRY

ENDFUNC

*---------------------------------------------------

FUNCTION getValueWithoutValidate(lcData, lcColumnName, outErrorMsg) AS STRING
RETURN IIF(ISNULL(lcData), "", TRANSFORM(lcData))
ENDFUNC

*---------------------------------------------------

FUNCTION getAndValidateNumericValue(lcData, lcColumnName, outErrorMsg) AS STRING
RETURN getValue(lcData, lcColumnName, @outErrorMsg, .T.)
ENDFUNC

*---------------------------------------------------

FUNCTION getValue(lcData, lcColumnName, outErrorMsg, isNumericValidation) AS STRING
*!*	    MESSAGEBOX("Datos recibidos:" + CHR(13) + ;
*!*	                   "lcData: " + TRANSFORM(lcData) + CHR(13) + ;
*!*	                   "lcTypeReal: " + VARTYPE(lcData) + CHR(13) + ;
*!*	                   "lcColumnName: " + lcColumnName + CHR(13) + ;
*!*	                   "outErrorMsg antes: " + outErrorMsg)

TRY
	IF EMPTY(lcData) OR ISNULL(lcData)
		ERROR("Campo vacío: " + lcColumnName)
		RETURN
	ENDIF

	IF isNumericValidation == .T.
		IF(VARTYPE(lcData) != "N")
			ERROR("El campo debe ser numérico: " + lcColumnName)
			RETURN
		ENDIF
	ENDIF

CATCH TO oErr
	buildErrorMessage(@outErrorMsg, oErr.MESSAGE)
ENDTRY

IF isNumericValidation == .T.
	RETURN CAST(lcData AS INTEGER)
ELSE
	RETURN lcData
ENDIF
ENDFUNC

*---------------------------------------------------

FUNCTION validateCodProveedor(lcCodProveedor, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT DETALLE FROM MTPROCLI WHERE CAST(DETALLE AS VARCHAR(255)) = '" + ALLTRIM(TRANSFORM(lcCodProveedor)) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al validar el código del proveedor.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "El código del proveedor no se encontró en la tabla MTPROCLI")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateISBN(lcISBN, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODIGO FROM MTMERCIA WHERE CODIGO = '" + ALLTRIM(TRANSFORM(lcISBN)) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al validar el ISBN.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "El ISBN no se encontró en la tabla MTMERCIA")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateSede(lcCodSede, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT CODCC FROM CENTCOS WHERE CODCC = '" + ALLTRIM(TRANSFORM(lcCodSede)) + "' AND AUXILIAR = 1"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al validar la sede.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "La sede no se encontró en la tabla CENTCOS o no es auxiliar")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION validateResponsable(lcCodResponsable, outErrorMsg)
LOCAL lcValidation

lcSqlQuery = "SELECT NITASIGNA FROM MTNITRES WHERE NITASIGNA = '" + ALLTRIM(lcCodResponsable) + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = TRANSFORM(lcSqlQuery)
	ERROR("Error al validar el responsable.")
ENDIF

SELECT lcValidation
GO TOP
IF EOF()
	buildErrorMessage(@outErrorMsg, "El responsable no se encontró en la tabla MTNITRES")
ENDIF

USE IN SELECT ("lcValidation")

ENDFUNC

*---------------------------------------------------

FUNCTION buildErrorMessage(outErrorMsg, newError)
outErrorMsg = IIF(!EMPTY(outErrorMsg), outErrorMsg + " | " + newError, newError)
ENDFUNC

*---------------------------------------------------

FUNCTION saveRQ() AS STRING
rqConsecutAssigned = getRQConsecut()

saveTrade(0, ;
		gCodUsuario, ;
		lcCodResponsable, ;
		outRqData.CodSede, ;
		outRqData.ISBN, ;
		rqConsecutAssigned)
		
SELECT outRqData
GO TOP
SCAN
	saveMvTrade(outRqData.CodProveedor, ;
		gCodUsuario, ;
		outRqData.CodSede, ;
		outRqData.ISBN, ;
		outRqData.Cantidad, ;
		outRqData.Precio, ;
		rqConsecutAssigned, ;
		"")
		
	updateIdPedOrd(rqTipoDctoMae, rqConsecutAssigned)
	
ENDSCAN
updateRQConsecut()
ENDFUNC

*---------------------------------------------------

FUNCTION saveMvTrade(lcCodProveedor, gCodUsuario, lcCodSede, lcISBN, lcCantidad, lcPrecio, rqConsecutAssigned, lcNota) AS STRING

lcSqlQuery = "EXEC dbo.GuardarMvTradeRequisicion '" + ;
			 TRANSFORM(lcCodProveedor) + ;
	"', '" + TRANSFORM(gCodUsuario) + ;
	"', '" + TRANSFORM(lcCodSede) + ;
	"', '" + TRANSFORM(lcISBN) + ;
	"', '" + TRANSFORM(lcCantidad) + ;
	"', '" + TRANSFORM(lcPrecio) + ;
	"', '" + TRANSFORM(rqTipoDctoMae) + ;
	"', '" + TRANSFORM(rqConsecutAssigned) +;
	"', '" + TRANSFORM(lcNota) +;
	"', '', ''" && Enviando tipoDctoPc y norden en blanco

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al guardar la requisicion en la base de datos (dbo.GuardarMvTradeRequisicion).")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION saveTrade(lcCodProveedor, gCodUsuario, lcCodResponsable, lcCodSede, lcISBN, rqConsecutAssigned) AS STRING

lcSqlQuery = "EXEC dbo.GuardarTradeRequisicion '" + ;
			 TRANSFORM(lcCodProveedor) + ;
	"', '" + TRANSFORM(gCodUsuario) + ;
	"', '" + TRANSFORM(lcCodResponsable) + ;
	"', '" + TRANSFORM(lcCodSede) + ;
	"', '" + TRANSFORM(lcISBN) + ;
	"', '" + TRANSFORM(rqTipoDctoMae) + ;
	"', '" + TRANSFORM(rqConsecutAssigned) ;
	+ "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al guardar la requisicion en la base de datos (dbo.GuardarTradeRequisicion).")
ENDIF

ENDFUNC

*---------------------------------------------------

FUNCTION getRQConsecut() AS INTEGER
LOCAL lcValidation

lcSqlQuery = "SELECT CONSECUT + 1 AS CONSECUT FROM CONSECUT WHERE TIPODCTO = '" + rqTipoDctoMae + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al consultar el consecutivo de requisiciones.")
ENDIF

SELECT lcValidation
GO TOP
RETURN lcValidation.CONSECUT

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC

*---------------------------------------------------

FUNCTION updateRQConsecut()
LOCAL lcValidation

lcSqlQuery = "UPDATE CONSECUT SET CONSECUT = CONSECUT + 1 WHERE TIPODCTO = '" + rqTipoDctoMae + "'"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al actualizar el consecutivo de requisiciones.")
ENDIF

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC

*---------------------------------------------------

FUNCTION getRqTipoDcto() AS INTEGER
LOCAL lcValidation

lcSqlQuery = "SELECT TIPODCTO FROM TIPODCTO WHERE DCTOMAE = 'RQ' AND X_CURRENT = 1"

IF SQLEXEC(ON, lcSqlQuery, "lcValidation") != 1
	_CLIPTEXT = lcSqlQuery
	ERROR("Error al consultar el tipo documento de requisiciones.")
ENDIF

SELECT lcValidation
GO TOP
RETURN lcValidation.TIPODCTO

USE IN SELECT ("lcValidation")

RETURN

ENDFUNC

*---------------------------------------------------

FUNCTION updateIdPedOrd(rqTipoDctoMae, rqConsecutAssigned)

lcSqlQuery = "UPDATE MVTRADE SET IDPEDORD = IDMVTRADE " + ;
	" WHERE TIPODCTO = '" + rqTipoDctoMae + "' AND NRODCTO = '" + TRANSFORM(rqConsecutAssigned) + "'"

IF SQLEXEC(ON, lcSqlQuery) != 1
	_CLIPTEXT = lcSqlQuery
	&&ERROR("Error al actualizar el IDPEDORD de la RQ para el registro IdMvTrade " + ALLTRIM(TRANSFORM(lcIdMvTrade)) + ".")
ENDIF

ENDFUNC
