#Include "Protheus.CH"
#Include "Rwmake.CH"					

/*/{Protheus.doc} PCOIMP
//TODO PROGRAMA PARA IMPORTAÇÃO DA PLANILHA ORÇAMENTÁRIA.
@author alex.bender
@since 27/08/2019
@version 1.0
@type function
/*/
User Function PCOIMP()
	Local   aDados	:= {}
	Private aHead	:= {" ","Orçamento","Versão","Msg Processamento"}
	Private aTam	:= {10,40,60,100}
	Private aReg	:= {{.F.," "," "," "}}
	Private oA	:= LoadBitmap(GetResources(),'br_verde') 
	Private oB	:= LoadBitmap(GetResources(),'br_vermelho')

	Private cLocalFile	:= Space(1)
	Private nTipo		:= 3     

	SetPrvt("oDlg1","oGrp1","oRMenu1","oGrp3","oBtn1","oGet1","oBtn2","oGrp2","oBrw1","oGrp4","oBtn5","oBtn6","oBtn3","oBtn4")

	oDlg1	:= MSDialog():New( 090,229,590,1090,"Importação de Orçamento",,,.F.,,,,,,.T.,,,.T. )
	oGrp1	:= TGroup():New( 000,002,040,428,"",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )
	oGrp3	:= TGroup():New( 006,005,036,424,"Localização do Arquivo ",oGrp1,CLR_BLACK,CLR_WHITE,.T.,.F. )
	oBtn1	:= TButton():New( 017,009,"Selecione o &Arquivo",oGrp3,{||GetCaminho()},060,012,,,,.T.,,"",,,,.F. )
	oGet1	:= TGet():New( 017,070,{|u| If(PCount()>0,cLocalFile:=u,cLocalFile)},oGrp3,265,010,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","cLocalFile",,)
	oBtn2	:= TButton():New( 017,343,"&Iniciar Importação",oGrp3,{||Processa({||SelArquivo(cLocalFile)},"Realizando Importação de Dados")},070,012,,,,.T.,,"",,,,.F. )
	oGrp2	:= TGroup():New( 040,002,232,428,"Dados do Processamento do Arquivo",oDlg1,CLR_BLACK,CLR_WHITE,.T.,.F. )

	oBrw1	:= TCBrowse():New(048,006,420,180,,aHead,aTam,oGrp2,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	oBrw1:SetArray(aReg)
	oBrw1:BLINE := { ||{IIF(aReg[oBrw1:nAt, 1],oA,oB),;
							aReg[oBrw1:nAt, 2],;
							aReg[oBrw1:nAt, 3],;
							aReg[oBrw1:nAt, 4],;					     	
							}	}
	oBrw1:bHeaderClick  := {|oBrw1,nCol| Ordenar(nCol)}
	oBrw1:Refresh()

	oBtn3      := TButton():New( 233,190,"Sai&r",oDlg1,{||oDlg1:End()},044,012,,,,.T.,,"",,,,.F. )

	oDlg1:Activate(,,,.T.)
Return .T.

/*/{Protheus.doc} GRAVPCO
//TODO FUNÇÃO GRAVA PLANILHA ORÇAMENTÁRIA.
@author alex.bender
@since 27/08/2019
@version 1.0
@param aDados, array, descricao
@type function
/*/
Static Function GRAVPCO(aDados)
	Local aParam		:= {}
	Local aErro		:= {}
	Local nOperac		:= 3
	Local cErro		:= ""
	Local cMsgLog		:= ""
	Local nQtdProx		:= 0
	Local nQtdeSuc		:= 0
	Local nQtdeFal		:= 0
	Local cMostraErro	:= ""
	Local aRetValid		:= {}
	Local cMsgVal		:= ""
	Local aRetK1		:= {}
	Local aRetK2		:= {}
	Local aRetK3		:= {}
	Private cMsgErro	:= ""

	If Len(aDados) > 0
		aReg := {}
		ProcRegua(Len(aDados)) 
		For i:=1 To Len(aDados)
			IncProc("Realizando importação... Orçamento: "+aDados[i,3]+Chr(13)+Chr(10)+"Sucesso:"+cValToChar(nQtdeSuc)+" Falha:"+cValToChar(nQtdeFal)   )
			cMsgVal := ValDados(aDados[i])

			If Empty(cMsgVal)
					aRetK1 := GravaAK1(aDados[i])
					If aRetK1[1,1]
						Begin Transaction
							aRetK3:= GravaAK3(aDados[i])
							If aRetK3[1,1]
								aRetK2 := GravaAK2(aDados[i])
								If !aRetK2[1,1]
									DisarmTransaction()
									cMsgErro := aRetK2[1,2]
								EndIf
							Else 
								DisarmTransaction()
								cMsgErro := aRetK3[1,2]
							EndIf
						End Transaction
					Else
						cMsgErro := aRetK1[1,2]
					EndIf
				
				If !Empty(cMsgErro)
					AADD(aReg,{.F.,aDados[i,3],cVersao,cMsgErro})
					nQtdeFal++
				Else
					AADD(aReg,{.T.,aDados[i,3],cVersao,"Importado com sucesso"})
					nQtdeSuc++
				EndIf
			Else
				AADD(aReg,{.F.,aDados[i,3],cVersao,cMsgVal})
				nQtdeFal++
			EndIf
		Next i

		If Len(aReg) == 0
			AADD(aReg,{.T.," "," "," "})
		EndIf

		If !Empty(cMsgErro)
			MemoWrite("C:\Temp\LogImpAtivo.txt",cMsgLog)
			MsgAlert('Houve erro no processamento das informações. Um ou mais itens, não foram importados (Falhas:'+cValToChar(nQtdeFal)+' Sucesso:'+cValToChar(nQtdeSuc)+'). Verifique o Log gerado em "C:\Temp\" com o nome LogImpAtivo.txt.',"Verifique")
		Else
			MsgInfo("Importação realizada com sucesso. Foram importados ("+cValToChar(nQtdeSuc)+") Registro.","Sucesso")
		EndIf
		SetGrid()
	EndIf
Return .T.

/*/{Protheus.doc} GravaAK1
//TODO FONTE PARA GRAVAR TABELA AK1.
@author alex.bender
@since 27/08/2019
@version 1.0
@param aDados, array, descricao
@type function
/*/
Static Function GravaAK1(aDados)
	Local aParam		:= {}
	Local aGrvAK1		:= {}
	Local aErro		:= {}
	Local nOperac		:= 3
	Local cErro		:= ""
	Local cMsgLog		:= ""
	Local cVersao		:= "001"
	Local cMostraErro	:= ""
	Local aRet		:= {}
	Local cMsgLog		:= ""

	Private lMsErroAuto	:= .F.
	Private lMsHelpAuto	:= .T.

	//VALIDA AK1 EXISTE - AK1_FILIAL+AK1_CODIGO+AK1_VERSAO
	DbSelectArea("AK1")
	DbSetOrder(1)
	If !DbSeek(xFilial("AK1")+PadR(aDados[03],TamSX3("AK1_CODIGO")[1],' ')+cVersao )

		aGrvAK1 := {}
		Aadd( aGrvAK1, {"AK1_CODIGO", aDados[03]	, NIL})
		Aadd( aGrvAK1, {"AK1_DESCRI", aDados[04]	, NIL})
		Aadd( aGrvAK1, {"AK1_VERSAO", cVersao		, NIL})
		Aadd( aGrvAK1, {"AK1_NMAX"  , aDados[05]	, NIL})
		Aadd( aGrvAK1, {"AK1_TPPERI", aDados[06]	, NIL})
		Aadd( aGrvAK1, {"AK1_INIPER", CtoD(aDados[07])	, NIL})
		Aadd( aGrvAK1, {"AK1_FIMPER", CtoD(aDados[08])	, NIL})
		Aadd( aGrvAK1, {"AK1_VERREV", aDados[09]	, NIL})

		MsExecAuto( { |u,v,w,x,y,z| PCOA100(u,v,w,x,y,z)} ,3,,,,aGrvAK1,)
		If lMsErroAuto 
			cMostraErro := FwCutOff(MostraErro("c:\temp","erro"),.T.)
			cMsgLog += "Planilha Orçamentária Nº: "+ aDados[03]+ " Versão: "+cVersao+" Erro: "+ cMostraErro + Chr(13)+Chr(10)	
		Endif
	Endif

	If !Empty(cMsgLog)
		AADD(aRet, {.F., cMsgLog})
	Else
		AADD(aRet, {.T., ""})
	EndIf
Return aRet

/*/{Protheus.doc} GravaAK3
//TODO FONTE PARA GRAVAR TABELA AK3.
@author alex.bender
@since 27/08/2019
@version 1.0
@param aDados, array, descricao
@type function
/*/
Static Function GravaAK3(aDados)
	Local cCod		:= aDados[03]
	Local cVersao		:= "001"
	Local aRet		:= {{.T., ""}}
	Local aContas		:= {} 
	Local cTipoK5		:= ""
	Local cDescK5		:= ""
	Local cCodSupK5		:= ""
	Local k			:= 1
	
	If Len(aDados) > 0
		aContas := RetContas(aDados[11])
				
		DbSelectArea("AK3")
		DbSetOrder(1)
		If !AK3->(DbSeek(xFilial("AK3")+PadR(aDados[03],TamSX3("AK3_ORCAME")[1],' ')+PadR(cVersao,TamSX3("AK3_VERSAO")[1],' ')+aDados[11]  ))
			RecLock("AK3",.T.)
				AK3->AK3_FILIAL		:= xFilial("AK3")
				AK3->AK3_ORCAME		:= aDados[03]
				AK3->AK3_VERSAO		:= cVersao
				AK3->AK3_CO		:= aDados[03]
				AK3->AK3_PAI		:= ' '
				AK3->AK3_TIPO		:= ' '
				AK3->AK3_DESCRI		:= aDados[04]
				AK3->AK3_NIVEL		:= "001"
			AK3->(MsUnLock())	
		EndIf
		
		For k:=1 To Len (aContas)	
			DbSelectArea("AK5")
			DbSetOrder(1)
			If AK5->(DbSeek(xFilial("AK5")+aContas[k,1]))
				cTipoK5		:= AK5->AK5_TIPO
				cDescK5		:= AK5->AK5_DESCRI
				cCodSupK5	:= AK5->AK5_COSUP
			EndIf
			
			DbSelectArea("AK3")
			DbSetOrder(1)
			If !AK3->(DbSeek(xFilial("AK3")+PadR(aDados[03],TamSX3("AK3_ORCAME")[1],' ')+PadR(cVersao,TamSX3("AK3_VERSAO")[1],' ')+aContas[k,1]  ))
				RecLock("AK3",.T.)
					AK3->AK3_FILIAL		:= xFilial("AK3")
					AK3->AK3_ORCAME		:= aDados[03]
					AK3->AK3_VERSAO		:= cVersao
					AK3->AK3_CO		:= aContas[k,1]
					AK3->AK3_PAI		:= IIF(Empty(aContas[k,2]),aDados[03],aContas[k,2])
					AK3->AK3_TIPO		:= cTipoK5
					AK3->AK3_DESCRI		:= cDescK5
					AK3->AK3_NIVEL		:= aContas[k,3]
				AK3->(MsUnLock())	
			EndIf
		Next k		
	EndIf
Return aRet

/*/{Protheus.doc} GravaAK2
//TODO FONTE PARA GRAVAR TABELA AK2.
@author alex.bender
@since 27/08/2019
@version 1.0
@param aDados, array, descricao
@type function
/*/
Static Function GravaAK2(aDados)
	Local x		:= 0
	Local cVersao	:= "001"
	Local aRet	:= {{.T., ""}}

	If Len(aDados) > 0
		For x := 0 To 11 
			//VALIDA AK2 EXISTE - AK2_FILIAL+AK2_ORCAME+AK2_VERSAO+AK2_CO+DTOS(AK2_PERIOD)+AK2_ID 
			DBSelectArea("AK2")
			DBSetorder(1)
			If !DbSeek(xFilial("AK2")+PadR(aDados[03],TamSX3("AK2_ORCAME")[1],' ')+PadR(cVersao,TamSX3("AK2_VERSAO")[1],' ')+PadR(aDados[11],TamSX3("AK2_CO")[1],' ')+DTOS(MonthSum(CtoD(aDados[7]),x))+aDados[01]    )
				RecLock("AK2",.T.)
					AK2->AK2_FILIAL := xFilial( "AK2" )
					AK2->AK2_ID 	:= aDados[01]
					AK2->AK2_ORCAME := aDados[03]
					AK2->AK2_VERSAO := cVersao
					AK2->AK2_CO 	:= aDados[11]
					AK2->AK2_PERIOD := MonthSum(CtoD(aDados[7]),x) //PRIMEIRA DATA DE CADA MÊS
					AK2->AK2_CC 	:= aDados[10]
					AK2->AK2_ITCTB  := aDados[12]
					AK2->AK2_CLVLR  := aDados[13]
					AK2->AK2_CLASSE := aDados[14]
					AK2->AK2_VALOR  := Val(Replace(Replace(aDados[15+x],'.',''),',','.'))
					AK2->AK2_MOEDA  := 1
					AK2->AK2_DATAI  := CtoD(aDados[07])
					AK2->AK2_DATAF  := CtoD(aDados[08])	
				AK2->( MsUnLOCK() )						
			EndIf
		Next x
	EndIf
Return aRet

/*/{Protheus.doc} ValDados
//TODO FUNÇÃO PARA VALIDAÇÃO DOS DADOS.
@author alex.bender
@since 27/08/2019
@version 1.0
@return ${return}, ${return_description}
@param aDados, array, descricao
@type function
/*/
Static Function ValDados(aDados)
	Local aRet	:= {}
	Local cMsgVal	:= ""

	//VALIDAÇÃO CENTRO DE CUSTO - TABELA CTT
	If !Empty(alltrim(aDados[10]))
		DbSelectArea("CTT")
		DbSetOrder(1)
		If !DbSeek(xFilial("CTT")+PadR(aDados[10],TamSX3("CTT_CUSTO")[1],' ') )
			cMsgVal += "Centro de Custo Cód: " + AllTrim(aDados[10]) + " não Cadastrado; "
		EndIf
	EndIf

	//VALIDAÇÃO CONTA ORÇAMENTÁRIA - TABELA AK5
	If !Empty(AllTrim(aDados[11]))
		DbSelectArea("AK5")
		DbSetOrder(1)
		If !DbSeek(xFilial("AK5")+PadR(aDados[11],TamSX3("AK5_CODIGO")[1],' ') )
			cMsgVal += "Conta Orçamentária Cód: " + AllTrim(aDados[11]) + " não Cadastrado; "
		EndIf
	Else
		cMsgVal += "Conta orçamentária é Obrigatório no arquivo; "
	EndIf

	//VALIDAÇÃO ITEM CONTABIL - TABELA CTD
	If !Empty(AllTrim(aDados[12]))
		DbSelectArea("CTD")
		DbSetOrder(1)
		If !DbSeek(xFilial("CTD")+PadR(aDados[12],TamSX3("CTD_ITEM")[1],' ') )
			cMsgVal += "Item Contábil Cód: " + AllTrim(aDados[12]) + " não Cadastrado; "
		EndIf
	EndIf

	//VALIDAÇÃO CLASSE VALOR - TABELA CTH
	If !Empty(AllTrim(aDados[13]))
		DbSelectArea("CTH")
		DbSetOrder(1)
		If !DbSeek(xFilial("CTH")+PadR(aDados[13],TamSX3("CTD_ITEM")[1],' ') )
			cMsgVal += "Classe de Valor Cód: " + AllTrim(aDados[13]) + " não Cadastrado; "
		EndIf
	EndIf

	//VALIDAÇÃO CLASSE ORÇAMENTÁRIA - TABELA AK6
	If !Empty(AllTrim(aDados[14]))
		DbSelectArea("AK6")
		DbSetOrder(1)
		If !DbSeek(xFilial("AK6")+PadR(aDados[14],TamSX3("AK6_CODIGO")[1],' ') )
			cMsgVal += "Classe Orçamenária Cód: " + AllTrim(aDados[14]) + " não Cadastrado; "
		EndIf
	Else
		cMsgVal += "Classe Orçamentária é Obrigatório no arquivo; "
	EndIf

	If !Empty(AllTrim(cMsgVal))
		AADD(aRet,{.F., cMsgVal})
	Else
		AADD(aRet,{.T.,""})
	EndIf
	RestArea(aArea)

Return cMsgVal

/*/{Protheus.doc} GetCaminho
//TODO FUNCAO PARA CARREGAR O CAMINHO DO ARQUIVO A SER CARREGADO.
@author alex.bender
@since 27/08/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function GetCaminho()
	Local cCadastro 	:= "Ler arquivo texto"
	Local cTitulo1  	:= "Selecione o arquivo"
	Local cExtens   	:= "Arquivo CSV | *.csv|Arquivo TXT| *.txt"
	Private cMainPath  	:= ""

	cLocalFile := cGetFile(cExtens,cTitulo1,,cMainPath,.T.)
	oGet1:Refresh()
	oDlg1:Refresh()
Return .T.


/*/{Protheus.doc} SelArquivo
//TODO FUNCAO PARA CARREGAR OS DADOS DO ARQUIVO DE TEXTO.
@author alex.bender
@since 27/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cCaminho, characters, descricao
@type function
/*/
Static Function SelArquivo(cCaminho)
	Local cBuffer   	:= ""
	Local cFileOpen 	:= ""
	Local aLinha		:= {}
	Private cMainPath  	:= ""
	Private aDados		:= {}

	If !File(cCaminho)
		MsgAlert("Arquivo texto: "+cCaminho+" não localizado",cCadastro)
		Return aDados
	Endif

	FT_FUSE(cCaminho)  
	FT_FGOTOP() 

	ProcRegua(FT_FLASTREC())

	While !FT_FEOF() 
		IncProc()

		cBuffer := FT_FREADLN()+";;;;;;"
		aLinha := StrTokArr( replace(replace(replace(cBuffer,';;','; ;'),';;','; ;'),';;','; ;'), ";" )

		AADD(aDados,aLinha)

		FT_FSKIP()   
	EndDo

	FT_FUSE()

	If Len(aDados) > 0
		Processa({||GRAVPCO(aDados)},"Importando Planilha Orçamentária")
	EndIf
Return .T.


/*/{Protheus.doc} SetGrid
//TODO FUNCAO PARA ATUALIZAR OS DADOS DA GRID CONTENDO AS INFORMACAOES DA IMPORTAÇÃO.
@author alex.bender
@since 27/08/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
Static Function SetGrid()
	If Len(aReg) > 0 
		oBrw1:SetArray(aReg)
		oBrw1:BLINE := { ||{IIF(aReg[oBrw1:nAt, 1],oA,oB),;
								aReg[oBrw1:nAt, 2],;
								aReg[oBrw1:nAt, 3],;
								aReg[oBrw1:nAt, 4],;					     	
								}	}
		oBrw1:Refresh()
		oDlg1:Refresh()
	EndIf
Return .T.

/*/{Protheus.doc} QualPai
//TODO Funcao que retorna qual a conta PAI da conta informada
@author alex.bender
@since 28/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cConta, characters, descricao
@type function
/*/
Static Function QualPai(cConta)
	Local cContaPai := cConta
	
	If !Empty(cContaPai)
		cContaPai := Posicione("AK5",1,xFilial("AK5")+cConta, "AK5_COSUP")
	EndIf
Return cContaPai

/*/{Protheus.doc} RetContas
//TODO Retornas as contas Pai e Filha com cada Nível
@author alex.bender
@since 28/08/2019
@version 1.0
@return ${return}, ${return_description}
@param cContaIN, characters, descricao
@type function
/*/
Static Function RetContas(cContaIN)
	Local aContas	:= {}
	Local cConta	:= cContaIN
	Local cContaPai	:= cContaIN 
	Local cContaOld	:= cContaIN
	Local cNivel    := "005"
	
	While !Empty(cContaPai)
		cContaOld := cContaPai
		cContaPai := QualPai(cContaPai)
		If !Empty(cContaPai)
			AADD(aContas,{cContaOld, cContaPai, cNivel})
			cNivel := Tira1(cNivel)
		EndIf
	EndDo
	If Empty(cContaPai)
		AADD(aContas,{cContaOld, "", cNivel})
	EndIf
Return aContas
