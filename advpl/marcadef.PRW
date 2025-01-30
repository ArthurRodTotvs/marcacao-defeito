#include "protheus.ch"

user function marcadef()
    FWCallApp("marcadef")
return

Static Function JsToAdvpl(oWebChannel,cType,cContent)
    Do Case

        Case cType == 'receberProtheus'

            cDados := 'Prod=' + SB8->B8_PRODUTO
            cDados += '|Lote=' + SB8->B8_LOTECTL
            cDados += '|SubLote=' + SB8->B8_NUMLOTE
            cDados += '|tenantId=' + cEmpAnt + "," + cvaltochar(cFilAnt)
            cDados += '|codUser=' + RetCodUsr()
            
            oWebChannel:AdvplToJs("receberProtheus", cDados)
        
            Conout(cDados)
    End
Return .T.
