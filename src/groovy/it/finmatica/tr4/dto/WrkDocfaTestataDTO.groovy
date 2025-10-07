package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.WrkDocfaTestata

class WrkDocfaTestataDTO implements it.finmatica.dto.DTO<WrkDocfaTestata> {

    int documentoId
    int documentoMultiId
    Byte unitaDestOrd
    Byte unitaDestSpec
    Byte unitaNonCensite
    Byte unitaSoppresse
    Byte unitaVariate
    Byte unitaCostituite
    WrkDocfaCausaliDTO causale
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

    public WrkDocfaTestata getDomainObject() {
        return WrkDocfaTestata.findByDocumentoIdAndDocumentoMultiId(documentoId, documentoMultiId)
    }

    public WrkDocfaTestata toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }
}
