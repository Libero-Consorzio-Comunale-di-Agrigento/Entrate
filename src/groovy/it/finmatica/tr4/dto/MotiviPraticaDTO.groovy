package it.finmatica.tr4.dto

import it.finmatica.dto.DTO
import it.finmatica.dto.DtoToEntityUtils
import it.finmatica.tr4.MotiviPratica

public class MotiviPraticaDTO implements DTO<MotiviPratica>, Cloneable {
    private static final long serialVersionUID = 1L;

    Long id;
    Short anno;
    String motivo;
    Short sequenza;
    String tipoPratica;
    String tipoTributo;


    public MotiviPratica getDomainObject() {
        return MotiviPratica.createCriteria().get {
            eq('tipoTributo', this.tipoTributo)
            eq('sequenza', this.sequenza)
        }
    }

    public MotiviPratica toDomain(Map overrides = [:]) {
        return DtoToEntityUtils.toEntity(this, overrides) as MotiviPratica
    }

    /* * * codice personalizzato * * */
    // attenzione: non modificare questa riga se si vuole mantenere il codice personalizzato che segue.
    // qui è possibile inserire codice personalizzato che non verrà eliminato dalla rigenerazione dei DTO.

    def descrizioneMotivo() {
        switch (tipoPratica) {
            case 'D':
                return 'D - Dichiarazione'
            case 'L':
                return 'L - Liquidazione'
            case 'I':
                return 'I - Infrazione'
            case 'A':
                return 'A - Accertamento'
            default:
                return motivo

        }
    }

    /**
     * Necessario per le reflection dei frameworks
     * rimuovibile se vengono rimossi anche tutti gli altri costruttori*/
    public MotiviPraticaDTO() {}

    public MotiviPraticaDTO(String tipoTributo) {
        this.tipoTributo = tipoTributo
    }

    @Override
    public MotiviPraticaDTO clone(){
        def clone = new MotiviPraticaDTO(this.tipoTributo)
        clone.anno = this.anno ? new Short(this.anno) : null
        clone.motivo = new String(this.motivo)
        clone.tipoPratica = new String(this.tipoPratica)
        // this.sequenza verrà valorizzato solo in fase di salvataggio.
        return clone
    }

}
