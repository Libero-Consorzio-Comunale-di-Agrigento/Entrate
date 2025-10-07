package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CodiceRfid

class CodiceRfidDTO implements DTO<CodiceRfid>, Comparable<CodiceRfidDTO> {

    def uuid = UUID.randomUUID().toString().replace('-', '')

    ContribuenteDTO contribuente
    OggettoDTO oggetto
    String codRfid
    ContenitoreDTO contenitore
    Date dataConsegna
    Date dataRestituzione
    String note
    Date lastUpdated
    String utente
    String idCodiceRfid

    CodiceRfid getDomainObject() {
        return CodiceRfid.findByContribuenteAndOggettoAndCodRfid(contribuente.getDomainObject(), oggetto.getDomainObject(), codRfid)
    }

    CodiceRfid toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as CodiceRfid
    }

    @Override
    int compareTo(CodiceRfidDTO o) {
        return contribuente.codFiscale <=> o.contribuente.codFiscale ?:
                oggetto?.id <=> o.oggetto?.id ?:
                        codRfid <=> o.codRfid
    }
}
