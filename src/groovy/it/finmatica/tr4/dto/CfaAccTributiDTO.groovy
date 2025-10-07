package it.finmatica.tr4.dto

import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.CfaAccTributi

public class CfaAccTributiDTO implements it.finmatica.dto.DTO<CfaAccTributi> {
    private static final long serialVersionUID = 1L;

    short annoAcc
    int numeroAcc
    String descrizioneAcc
    Integer esercizio
    String es
    BigDecimal capitolo
    Integer articolo
    String descrizioneCap
    Date dataAcc
    BigDecimal importoAttuale
    BigDecimal ordinativi
    BigDecimal disponibilita
    BigDecimal codiceLivello
    String descrizioneLivello

    public CfaAccTributi getDomainObject () {
        return CfaAccTributi.createCriteria().get {
            eq('annoAcc', this.annoAcc)
            eq('numeroAcc', this.numeroAcc)
        }
    }
	
    public CfaAccTributi toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides)
    }

    /// Questo serve per BandboxCfaAccTributi

    String descrizioneCompleta
    
    public String getDescrizioneCompleta() {

        if((this.numeroAcc <= 0) && ((this.descrizioneAcc ?: '').isEmpty()) && ((this.descrizioneCompleta ?: '').isEmpty()))
            return null;

        if((this.descrizioneCompleta == null) || (this.descrizioneCompleta.isEmpty())) {
            this.descrizioneCompleta = (this.numeroAcc as String) + " - " + this.descrizioneAcc
        }

        return this.descrizioneCompleta
    }

    public void setDescrizioneCompleta(String descrizioneCompleta) {

        this.descrizioneCompleta = descrizioneCompleta
    }
	
    /* * * codice personalizzato * * */ // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue. 
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.


}
