package it.finmatica.tr4

class WrkDocfaTestata implements Serializable {

    int documentoId
    int documentoMultiId
    Byte unitaDestOrd
    Byte unitaDestSpec
    Byte unitaNonCensite
    Byte unitaSoppresse
    Byte unitaVariate
    Byte unitaCostituite
    WrkDocfaCausali causale
    String note1
    String note2
    String note3
    String note4
    String note5
    String cognomeDic
    String nomeDic
    String comuneDic
    String provinciaDic
    String indirizzoDic
    String civicoDic
    String capDic
    String cognomeTec
    String nomeTec
    String codFiscaleTec
    String alboTec
    String numIscrizioneTec
    String provIscrizioneTec
    Date dataRealizzazione
    Long fonte

    static mapping = {
        id composite: ["documentoId", "documentoMultiId"]
        version false

        causale column: "causale"
    }

    static constraints = {
        unitaDestOrd nullable: true
        unitaDestSpec nullable: true
        unitaNonCensite nullable: true
        unitaSoppresse nullable: true
        unitaVariate nullable: true
        unitaCostituite nullable: true
        causale nullable: true
        note1 nullable: true
        note2 nullable: true
        note3 nullable: true
        note4 nullable: true
        note5 nullable: true
        cognomeDic nullable: true
        nomeDic nullable: true
        comuneDic nullable: true
        provinciaDic nullable: true
        indirizzoDic nullable: true
        civicoDic nullable: true
        capDic nullable: true
        cognomeTec nullable: true
        nomeTec nullable: true
        codFiscaleTec nullable: true
        alboTec nullable: true
        numIscrizioneTec nullable: true
        provIscrizioneTec nullable: true
        dataRealizzazione nullable: true
        fonte nullable: true
    }
}
