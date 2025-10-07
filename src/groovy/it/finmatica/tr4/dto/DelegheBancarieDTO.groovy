package it.finmatica.tr4.dto

import it.finmatica.ad4.dto.autenticazione.Ad4UtenteDTO
import it.finmatica.tr4.DelegheBancarie

import java.util.Date
import java.util.Map

public class DelegheBancarieDTO implements it.finmatica.dto.DTO<DelegheBancarie> {
    private static final long serialVersionUID = 1L

    Long id
    String cinBancario
    Integer codAbi
    Integer codCab
    String codControlloCc
    String codFiscale
    String codiceFiscaleInt
    String cognomeNomeInt
    String contoCorrente
    Date dataRitiroDelega
    Date lastUpdated
    boolean flagDelegaCessata
    boolean flagRataUnica
    Byte ibanCinEuropa
    String ibanPaese
    String note
    String tipoTributo
    Ad4UtenteDTO utente


    public DelegheBancarie getDomainObject () {
        return DelegheBancarie.createCriteria().get {
            eq('codFiscale', this.codFiscale)
            eq('tipoTributo', this.tipoTributo)
        }
    }
    public DelegheBancarie toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }


    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


    public String getIban() {
        String iban = ""
        //Si costruisce IBAN soltanto se non sono nulli questi campi
        if(contoCorrente && ibanPaese && ibanCinEuropa && cinBancario && codAbi && codCab){
            String seq = (((contoCorrente)?contoCorrente.toUpperCase():"" ).concat(((codControlloCc)?codControlloCc.toUpperCase():"" )) as String).padLeft(13, "0")

            iban = ((ibanPaese)?ibanPaese.toUpperCase():"")
            iban+= ((ibanCinEuropa)? (ibanCinEuropa.toString() as String).padLeft(2, "0") :"" )
            iban+= ((cinBancario)?cinBancario.toUpperCase():"" )
            iban+= ((codAbi)? (codAbi.toString().toUpperCase() as String).padLeft(5, "0")  :"" )
            iban+= ((codCab)? (codCab.toString().toUpperCase() as String).padLeft(5, "0")  :"" )
            iban+= ((seq)?seq.substring(1,seq.length()):"" )
        }
        return iban
    }

}
