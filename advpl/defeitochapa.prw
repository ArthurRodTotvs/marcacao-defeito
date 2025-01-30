#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "tbiconn.ch"


//Para encontrar mais facil on custochapa
WSRESTFUL defeitochapa DESCRIPTION "API para buscar o defeito v1.02" //FORMAT "aplication/json, text/html"

	WSDATA Page     AS INTEGER OPTIONAL
	WSDATA PageSize AS INTEGER OPTIONAL
	WSDATA Prod     AS CHARACTER OPTIONAL
	WSDATA armazem  AS CHARACTER OPTIONAL
	WSDATA Lote     AS CHARACTER OPTIONAL
	WSDATA Sublote  AS CHARACTER OPTIONAL
	WSDATA Imagem   AS CHARACTER OPTIONAL
	WSDATA tenantId AS CHARACTER OPTIONAL

	WSMETHOD GET DEFEITCH;
		DESCRIPTION "Retorna o base64 da imagem de defeito  chapa";
		WSSYNTAX "/DEFEITCH";
		PATH "/DEFEITCH";
		PRODUCES APPLICATION_JSON

	WSMETHOD POST DEFEITCH;
		DESCRIPTION "Envio o blob da chapa";
		WSSYNTAX "/DEFEITCH";
		PATH "/DEFEITCH";
		PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD GET DEFEITCH QUERYPARAM Page,PageSize,Lote,Sublote WSSERVICE defeitochapa
Return DEFEITCH(self)

WSMETHOD POST DEFEITCH QUERYPARAM Page,PageSize,Lote,Sublote,Imagem WSSERVICE defeitochapa
Return POSTDFCH(self)

/*/{Protheus.doc} DEFEITCH
	(long_description)
	Rotina para retornar a imagem em base 64
	@type  Static Function
	@author user
	@since 28/10/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function DEFEITCH(oWS)

	Local lOk  := .t.
	Local cPastaSer := "\grplus\defeitos\"  // pasta no servidor onde estão as imagens
	Local cGrupo	:= ""
	Local cCodBar   := ""
	Local cLocImag  := ""
	Local lOpenEnv  := .t.
	Local cJsonRet  := ""
	Local cProduto  := ""
	Local cLote     := ""
	Local cSublote  := ""
	Local cTnantId  := ""

	DEFAULT oWS:Page      := 1
	DEFAULT oWS:PageSize  := 10
	DEFAULT oWS:Prod      := SB8->B8_PRODUTO
	DEFAULT oWS:Lote      := SB8->B8_LOTECTL
	DEFAULT oWS:Sublote   := SB8->B8_NUMLOTE

	cProduto  := cvaltochar(oWS:Prod)
	cLote     := cvaltochar(oWS:Lote)
	cSublote  := cvaltochar(oWS:Sublote)
	cTnantId  := cvaltochar(oWS:tenantId)

	OPEMEMP(lOpenEnv, cTnantId)

	cTipoMat := Posicione("SB5", 1, xFilial("SB5") + cProduto , "B5_YTIPMAT")
	cGrupo   := Posicione("SB1", 1, xFilial("SB1") + cProduto , "B1_GRUPO")
	cTipo    := Posicione("SBM", 1, xFilial("SBM") + cGrupo, "BM_YTIPO")
	cCodBar  := U_GETCODBAR(cTipoMat, cLote, cSublote)

	cImage   := cCodBar + ".bmp"     // nome da imagem que será salva

	cLocImag := cPastaSer + cImage

	If File(cLocImag)

		nH := fOpen(cLocImag,0)
		nSize := fSeek(nH,0,2)
		fSeek(nH,0)
		cImgBuffer := Space(nSize)
		nRead := fRead(nH, @cImgBuffer, nSize)
		fClose(nH)

		cJsonRet += '{'
		cJsonRet += '"status": "'      + "OK" + '",'
		cJsonRet += '"mensagem": "'    + "Imagem encontrada" + '",'
		cJsonRet += '"imagebase64": "' + Encode64(cImgBuffer) + '"'
		cJsonRet += '}'

		lOk  := .t.
	else
		cJsonRet += '{'
		cJsonRet += '"status": "'   + "ERRO" + '",'
		cJsonRet += '"mensagem": "' + "Não foi encontrado a imagem com os dados informados. produto : " + cProduto + " Lote : " +  cLote + " Sublote : "  +  cSublote +"'"
		cJsonRet += '}'

		lOk  := .f.
	EndIf

	If lOk
		oWS:SetResponse(cJsonRet)
	Else
		//Ou retorna o erro encontrado durante o processamento
		SetRestFault(500,cJsonRet)
	EndIf

	IF lOpenEnv
        RESET ENVIRONMENT
    ENDIF

Return lOk


/*/{Protheus.doc} DEFEITCH
	(long_description)
	Rotina para retornar a imagem em base 64
	@type  Static Function
	@author user
	@since 28/10/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function POSTDFCH(oWS)

	Local aRet  	:= {.t.,""}
	Local cPastaSer := "\grplus\defeitos\"  // pasta no servidor onde estão as imagens
	Local cGrupo	:= ""
	Local cCodBar   := ""
	Local cLocImag  := ""
	Local lOpenEnv  := .t.
	Local cJsonRet  := ""
	Local cProduto  := ""
	Local cLote     := ""
	Local cSublote   := ""

	DEFAULT oWS:Page      := 1
	DEFAULT oWS:PageSize  := 10
	DEFAULT oWS:Prod      := SB8->B8_PRODUTO
	DEFAULT oWS:Lote      := SB8->B8_LOTECTL
	DEFAULT oWS:Sublote   := SB8->B8_NUMLOTE
	DEFAULT oWS:Imagem    := ""

	OPEMEMP(lOpenEnv, cvaltochar(oWS:tenantId))

	cProduto  := cvaltochar(oWS:Prod)
	cLote     := cvaltochar(oWS:Lote)
	cSublote  := cvaltochar(oWS:Sublote)
	cImagem   := Decode64(cvaltochar(oWS:Imagem)) 

	cTipoMat := Posicione("SB5", 1, xFilial("SB5") + cProduto , "B5_YTIPMAT")
	cGrupo   := Posicione("SB1", 1, xFilial("SB1") + cProduto , "B1_GRUPO")
	cTipo    := Posicione("SBM", 1, xFilial("SBM") + cGrupo, "BM_YTIPO")
	cCodBar  := U_GETCODBAR(cTipoMat, cLote, cSublote)

	cImageLo :=  cPastaSer + cCodBar + ".bmp"     // nome da imagem que será salva

	aRet := SaveTo( cImageLo, cImagem )

	If aRet[1]
		cJsonRet += '{'
		cJsonRet += '"status": "'      + "OK" + '",'
		cJsonRet += '"mensagem": "'    + "Imagem salva com sucesso" + '"'
		cJsonRet += '}'

		oWS:SetResponse(cJsonRet)
	else
		cJsonRet += '{'
		cJsonRet += '"status": "'   + "ERRO" + '",'
		cJsonRet += '"mensagem": "' + "Erro ao tentar salvar a imagem. produto : " + cProduto + " Lote : " +  cLote + " Sublote : "  +  cSublote + " Erro: " +aRet[2] +"'"
		cJsonRet += '}'

		SetRestFault(500,cJsonRet)
	EndIf

	IF lOpenEnv
        RESET ENVIRONMENT
    ENDIF

Return aRet[1]




static function SaveTo( cFile, cImgBuffer )
	Local nH, nSize , nSaved
	Local cError := ''

	If file(cFile)
		FErase(cFile)
	Endif

// Cria o arquivo no disco 
	nH := fCreate(cFile)

	If nH == -1
		cError := "APDBIMAGE:SaveTo() File Create Error ( FERROR "+cValToChar( Ferror() )+")"
		Return {.F.,cError}
	Endif

// Calcula tamanho do buffer de memoria
// e grava ele no arquivo 
	nSize := len(cImgBuffer)
	nSaved := fWrite(nH,cImgBuffer)

// Fecha o arquivo 
	fClose(nH)

	If nSaved < nSize

		cError := "APDBIMAGE:SaveTo() Write Error ( FERROR "+cValToChar( Ferror() )+")"

		Return {.F.,cError}
	Endif

Return {.T.,cError}

static Function OPEMEMP(lOpenEnv, cTeId)

	Local aTeId

	Default cTeId := "01,0101"

	If Type("cFilAnt") == "C" .AND. TCIsConnected()
		ConOut("Ambiente Protheus aberto e pronto para uso")
		lOpenEnv := .F.
	Else

		aTeId := Separa(cTeId, ",")
		Prepare Environment Empresa aTeId[1] Filial aTeId[2]

		lOpenEnv := .T.
	EndIf

Return
