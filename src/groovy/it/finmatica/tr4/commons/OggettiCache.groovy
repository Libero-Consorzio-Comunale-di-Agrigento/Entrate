package it.finmatica.tr4.commons

import it.finmatica.tr4.*
import it.finmatica.tr4.anomalie.TipoAnomalia
import it.finmatica.tr4.caricamento.LocazioneTipiTracciato
import it.finmatica.tr4.comunicazioni.ComunicazioneParametri
import it.finmatica.tr4.comunicazioni.TipiCanale

enum OggettiCache {

    MOLTIPLICATORI("Tabella dei moltiplicatori", Moltiplicatore.class.name, []),
    RIVALUTAZIONI_RENDITA("Tabella delle rivalutazioni", RivalutazioneRendita.class.name, []),
    CATEGORIE_CATASTO("Tabella delle categorie catasto", CategoriaCatasto.class.name, []),
    TIPI_OGGETTO("Tabella dei tipi oggetto", TipoOggetto.class.name, ["oggettiTributo"]),
    ALIQUOTE("Tabella delle aliquote", Aliquota.class.name, ["tipoAliquota"]),
    TIPI_ALIQUOTA("Tabella dei tipi aliquota", TipoAliquota.class.name, ["aliquote"]),
    CARICHI_TARSU("Tabella dei carichi tarsu", CaricoTarsu.class.name, []),
    TIPI_CONTATTO("Tabella dei tipi contatto", TipoContatto.class.name, []),
    TIPI_TRIBUTO("Tabella dei tipi tributo", TipoTributo.class.name, []),
    CODICI_TRIBUTO("Tabella dei codici tributo", CodiceTributo.class.name, []),
    TIPI_AREA("Tabella dei tipi area", TipoArea.class.name, []),
    TIPI_ANOMALIA("Tabella dei tipi anomalia", TipoAnomalia.class.name, []),
    OGGETTI_TRIBUTO("Tabella dei tipi oggetto per tributo", OggettoTributo.class.name, []),
    INSTALLAZIONE_PARAMETRI("Tabella dei parametri di installazione", InstallazioneParametro.class.name, []),
    LOCAZIONI_TIPI_TRACCIATO("Tabella dei tracciati delle lozazioni", LocazioneTipiTracciato.class.name, []),
    TIPI_MODELLO("Tabella dei tipi modello", TipiModello.class.name, []),
    TIPI_STATO("Tabella dei tipi stato", TipoStato.class.name, []),
    TIPI_ATTO("Tabella dei tipi atto", TipoAtto.class.name, []),
    CODICI_F24("Tabella dei codici F24", CodiceF24.class.name, []),
    TIPI_EXPORT("Tabella dei tipi di export", TipiExport.class.name, []),
    TIPI_NOTIFICA("Tabella dei tipi di notifica", TipoNotifica.class.name, []),
    DATI_GENERALI("Tabella dei dati generali", DatoGenerale.class.name, ["comuneCliente.ad4Comune.provincia"]),
    COMUNICAZIONE_PARAMETRI("Tabella comunicazione parametri", ComunicazioneParametri.class.name, [])

    public static OggettiCacheMap map

    private final String descrizione
    private final String nomeClasse
    private final List domainCollegate

    OggettiCache(String descrizione, String nomeClasse, List domainCollegate) {
        this.descrizione = descrizione
        this.nomeClasse = nomeClasse
        this.domainCollegate = domainCollegate
    }

    def getValore() {
        return map.getValore(this.toString())
    }

    String getNomeClasse() {
        return this.nomeClasse
    }

    List getDomainCollegate() {
        return this.domainCollegate
    }
}
