#INCLUDE "protheus.CH"
#INCLUDE "FWMVCDEF.CH"
#Include "Parmtype.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "FWEditPanel.CH"
#INCLUDE "TOPCONN.CH"

// //Variáveis Estáticas
Static cTitulo := "Manutenção de Bloco e Chapa"
Static oPainelIMG := Nil
Static OTBITMAP1 := Nil

/*/{Protheus.doc} GROA037
MANUTENCAO BLOCO/CHAPA
@type  Function
@author Totvs Vitoria
@since 08/08/2019
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function GROA037()

	Local aArea    := GetArea()
	Local oBrowse
	Local cTipoMan :=  GetNewPar("GR_GRUPOMA", "'B','C'")
	Local nTelaNov :=  GetNewPar("GR_PARA037", 0 )
	Local aRet     := {.t.,{}}
	Local cFiltroEnt := ""

	Local __cChave := STRTRAN(TIME(), ":", "") + GETHARDWAREID() + DTOS(DATE())
	If __cChave <> U_TOTVSES(SubString(__cChave,1,6))
		Return Nil
	EndIf

	IF(nTelaNov == 1 )
		aRet := AskIni37()
	EndIf

	If(aRet[1])

		//Instânciando FWMBrowse - Somente com dicionário de dados
		oBrowse := FWMBrowse():New()

		//Setando a tabela de cadastro de comprovante de entrega
		oBrowse:SetAlias("SB8")

		//Caso a tela esteja lenta e escolheu o parametro como 1, o sistema vai dar a opção do usuário escolher os produtos
		if(len(aRet[2]) > 0)
			if aRet[2,1] == "A"
				cFiltroEnt := " B8_SALDO > 0 AND "
			Elseif aRet[2,1] == "S"
				cFiltroEnt := " B8_SALDO = 0 AND "
			EndIf

			cFiltroEnt += " B8_PRODUTO BETWEEN '"+aRet[2,2]+"' AND '"+aRet[2,3]+"'"

		Else
			//https://totvsleste.freshdesk.com/a/tickets/1738
			//Filtro de bloco e chapa conforme o cadastro no grupo
			cFiltroEnt := " R_E_C_N_O_ IN (SELECT SB8.R_E_C_N_O_ "
			cFiltroEnt += "       FROM " + RetSqlName("SB8") + " SB8 "
			cFiltroEnt += " INNER JOIN " + RetSqlName("SB1") + " SB1 "
			cFiltroEnt += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
			cFiltroEnt += "        AND SB1.B1_COD     = SB8.B8_PRODUTO "
			cFiltroEnt += "        AND SB1.D_E_L_E_T_ = '' "
			cFiltroEnt += " INNER JOIN " + RetSqlName("SBM") + " SBM "
			cFiltroEnt += "         ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "' "
			cFiltroEnt += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO "
			cFiltroEnt += "        AND SBM.BM_YTIPO   IN ("+ cTipoMan +") "
			cFiltroEnt += "        AND SBM.D_E_L_E_T_ = '' "
			cFiltroEnt += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
			cFiltroEnt += "        AND SB8.D_E_L_E_T_ = '' ) "
		EndIf

		oBrowse:SetFilterDefault("@"+cFiltroEnt )

		//Setando a descrição da rotina
		oBrowse:SetDescription(cTitulo)

		if u_X3VALID()
			//Ativa a Browse
			oBrowse:Activate()
		EndIF

	EndIF

	RestArea(aArea)

Return

/*/{Protheus.doc} MenuDef
MANUTENÇÃO BLOCO/CHAPA
@type  Function
@author Totvs Vitoria
@since 08/08/2019
@version version
@param param, param_type, param_descr
@return return, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function MenuDef()

	Local aRotina := {}

	//Chamadas necessárias devido um erro na versão 33 que não esta chamando as viewdef de outro programa.
	//Ticket:13074070 totvs SP
	//https://totvsleste.freshdesk.com/a/tickets/2798
	// u_CHAMAVA()
	// u_CHAMAVB()
	// u_CHAMAVC()


	aAdd(aRotina, {'Pesquisar',        'VIEWDEF.GROA037A', 0,1,0,NIL})
	aAdd(aRotina, {'Visualizar',       'VIEWDEF.GROA037A', 0,2,0,NIL}) //https://totvsleste.freshdesk.com/a/tickets/1603
	aAdd(aRotina, {'Alterar',          'VIEWDEF.GROA037A', 0,4,0,NIL})
	aAdd(aRotina, {'Alterar em Lote',  'VIEWDEF.GROA037B', 0,4,0,NIL})
	aAdd(aRotina, {'Fotos',            'VIEWDEF.GROA037C', 0,4,0,NIL})
	aAdd(aRotina, {'Defeitos',         'U_GROA057()'     , 0,4,0,NIL})
	aAdd(aRotina, {'Defeitos teste',   'U_marcadef()'     , 0,4,0,NIL})
	aAdd(aRotina, {'Defeitos em Lote' ,'U_DEFLOTE()'     , 0,4,0,NIL})
	// aAdd(aRotina, {'Fotos do Bundle', 'VIEWDEF.GROA037D', 0,4,0,NIL})

	If ExistBlock("GR037MEN")
		aRotina := ExecBlock("GR037MEN", .f., .f., aRotina  )
	EndIf

Return aRotina

//------------------------------------------------------------
/*/{Protheus.doc} ValidMed
Valida medidas.
@author Kenny Roger Martins
@since 08/03/2021
/*/
//------------------------------------------------------------
USER Function ValidMed(oModel, cCampo, lMensagem)

	Local lRet := .T.
	Local aAreaSB8 := SB8->(GetArea())

	Default lMensagem := .T.

	SB8->(DbSetOrder(3))

	If SB8->(DbSeek(oModel:GetValue("B8_FILIAL") + oModel:GetValue("B8_PRODUTO") + oModel:GetValue("B8_LOCAL") + oModel:GetValue("B8_LOTECTL") + oModel:GetValue("B8_NUMLOTE")))

		lRet := U_GROVLMED(&("SB8->" + cCampo), oModel:GetValue(cCampo), cCampo, lMensagem)

	EndIf

	RestArea(aAreaSB8)

Return lRet

User Function DefLote()
	Local cExpSql := ""
	Local aTotais     := {}

	cExpSql := "     SELECT SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB1.B1_DESC,    "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE, "
	cExpSql += "            SB8.B8_SALDO,   "
	cExpSql += "            SB8.B8_DTVALID, "
	cExpSql += "            SB8.B8_YCLASSI, "
	cExpSql += "            SB8.B8_YCOMLIQ, "
	cExpSql += "            SB8.B8_YALTLIQ, "
	cExpSql += "            SB8.B8_YESPLIQ, "
	cExpSql += "            SB8.B8_YTOTLIQ, "
	cExpSql += "            SBM.BM_YTIPO    "
	cExpSql += "       FROM " + RetSqlName("SB8") + " SB8 (NOLOCK) "
	cExpSql += " INNER JOIN " + RetSqlName("SB1") + " SB1 (NOLOCK) "
	cExpSql += "         ON SB1.B1_FILIAL  = '" + xFilial("SB1") + "' "
	cExpSql += "        AND SB1.B1_COD     = SB8.B8_PRODUTO "
	cExpSql += "        AND SB1.D_E_L_E_T_ = '' "
	cExpSql += " INNER JOIN " + RetSqlName("SBM") + " SBM (NOLOCK) "
	cExpSql += "         ON SBM.BM_FILIAL  = '" + xFilial("SBM") + "' "
	cExpSql += "        AND SBM.BM_GRUPO   = SB1.B1_GRUPO "
	cExpSql += "        AND SBM.BM_YTIPO   = 'C' "
	cExpSql += "        AND SBM.D_E_L_E_T_ = '' "
	cExpSql += "      WHERE SB8.B8_FILIAL  = '" + xFilial("SB8") + "' "
	cExpSql += "        AND SB8.B8_SALDO   > 0  "
	cExpSql += "        AND SB8.B8_EMPENHO = 0  "
	cExpSql += "        AND SB8.D_E_L_E_T_ = '' "
	cExpSql += "   ORDER BY SB8.B8_FILIAL,  "
	cExpSql += "            SB8.B8_LOCAL,   "
	cExpSql += "            SB8.B8_PRODUTO, "
	cExpSql += "            SB8.B8_LOTECTL, "
	cExpSql += "            SB8.B8_NUMLOTE  "

	aAdd( aTotais, {"B8_FILIAL","COUNT","Contador","@E 999,999"} )
	aAdd( aTotais, {"B8_YTOTLIQ","SUM","Total Líquido","@E 999,999,999.99"} )

	aChapas := U_GROCGEN("SB8", , "Estoque de Materiais", cExpSql, {"BM_YTIPO", "B8_LOTECTL", "B8_NUMLOTE", "B8_PRODUTO","B8_LOCAL"}, .T.,aTotais,100)[2]

	U_GROA057(, .T., aChapas)
Return Nil


 /*/{Protheus.doc} nomeFunction
	(long_description)
	Validar os campos porque com essas rotinas, tem algumas situações onde o padrão apresenta erro.
	//DOCUMENTAÇÃO
	//https://totvsleste.freshdesk.com/a/solutions/articles/22000260136
	//https://totvsleste.freshdesk.com/a/solutions/articles/22000250110
	@type  Function
	@author user
	@since 18/04/2023
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
	/*/
user Function X3VALID()

	Local cSql 		:= ""
	Local lRet      := .t.
	Local cMessage  := ""

	// cSql := "     SELECT UPPER(X3_VALID) AS VALID, 'A103LOTCTL()' AS 'FUNCAO' ,X3_CAMPO "
	// cSql += "       FROM " + RetSqlName("SX3") + " SX3 "
	// cSql += "     WHERE  SX3.X3_CAMPO   in ('D1_NUMLOTE ','D1_LOTECTL ', 'D2_LOTECTL','D2_NUMLOTE','D3_LOTECTL','D3_NUMLOTE') "
	// cSql += "        AND UPPER(X3_VALID) LIKE '%A103LOTCTL%'"
	// cSql += "        AND SX3.D_E_L_E_T_ = '' "

	// cSql += "        UNION          "

	// cSql += "     SELECT UPPER(X3_VALID)AS VALID, 'A240LOTE()' AS 'FUNCAO' ,X3_CAMPO "
	// cSql += "       FROM " + RetSqlName("SX3") + " SX3 "
	// cSql += "     WHERE SX3.X3_CAMPO in ('D1_NUMLOTE ','D1_LOTECTL ', 'D2_LOTECTL','D2_NUMLOTE','D3_LOTECTL','D3_NUMLOTE')"
	// cSql += "        AND UPPER(X3_VALID) LIKE '%A240LOTE%'"
	// cSql += "        AND SX3.D_E_L_E_T_ = '' "

	// TCQUERY cSql NEW ALIAS qQeryVal

	// While qQeryVal->(!Eof())
	// 	cMessage+= "Campo:"+qQeryVal->X3_CAMPO + CHR(13)+ CHR(10)
	// 	cMessage+= "Valid:"+qQeryVal->VALID + CHR(13)+ CHR(10)
	// 	cMessage+= "Função para retirar:"+qQeryVal->FUNCAO + CHR(13) + CHR(10)+ CHR(13) + CHR(10)

	// 	qQeryVal->(dbSkip())
	// EndDo

	// qQeryVal->(DbCloseArea())

	// if !EMPTY( cMessage )
	// 	lRet   := .F.
	// 	cSolution := "Favor informar a equipe de Ti para verificar o problema e remover essas funções informadas da SX3 dos campos abaixo:"+ CHR(13) + CHR(10)
	// 	cSolution += cMessage
	// 	cSolution += "Apos remover as validações, reinicie o dbAces"+ CHR(13)+ CHR(10)
	// 	cSolution += "Documentação: https://totvsleste.freshdesk.com/a/solutions/articles/22000260136"+ CHR(13) + CHR(10)

	// 	If IsBlind()
	// 		conout("GRAOA037_X3VALID" + cSolution)
	// 	Else
	// 		u_HELPMSG("GRAOA037_X3VALID",cSolution)
	// 	EndIf

	// EndIF

Return lRet

//Tela inicial onde o usuário pode selecionar os dados para filtrar na SB8
static Function AskIni37(lAltQue)

	Local aCBSituac := StrTokArr(AllTrim("A=Com saldo;S=Sem saldo;T=Todas"),";")
	Local aAsk 		:= {}
	Local aRet      := {}
	Local lRet      := .T.
	Local aParamBox := {}
	Local cLotPDe   :=  PADR("BL",TAMSX3("B2_COD")[1],"Z")
	Local cLotPAt   :=  PADR("CH",TAMSX3("B2_COD")[1],"Z")

	aAdd(aParamBox, {2, "Status das chapas",StrTokArr(aCBSituac[1], "=")[1], aCBSituac, 60, "", .F.})
	aAdd(aParamBox, {1, "Produto de ?" , cLotPDe ,'','.T.','SB1','.T.',TAMSX3("B2_COD")[1] * 5,.F.})
	aAdd(aParamBox, {1, "Produto ate ?", cLotPAt ,'','.T.','SB1','.T.',TAMSX3("B2_COD")[1] * 5,.F.})

	lRet := ParamBox(aParamBox, "Informe os dados para SB8", aRet)

Return {lRet,aRet}

