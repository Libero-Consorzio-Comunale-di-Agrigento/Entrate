package it.finmatica.tr4.commons

import it.finmatica.tr4.archivio.dizionari.FiltroRicercaDatiContabili
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.denunce.FiltroRicercaDenunce
import it.finmatica.tr4.imposte.*
import it.finmatica.tr4.imposte.datiesterni.FiltroRicercaFornitureAE
import it.finmatica.tr4.imposte.supportoservizi.FiltroRicercaSupportoServizi
import it.finmatica.tr4.insolventi.FiltroRicercaInsolventi
import it.finmatica.tr4.versamenti.FiltroRicercaVersamenti
import it.finmatica.tr4.violazioni.FiltroRicercaViolazioni

class TributiSession {

    CompetenzeService competenzeService

    // id della tab WEB_CALCOLO_INDIVIDUALE usata in sessione
    def idWCIN

    // parametri di ricerca nelle anomalie Oggetto/Praticha
    def filtroAnomalie

    // parametri di ricerca nelle denunce
    FiltroRicercaDenunce filtroRicercaDenunce

    FiltroRicercaViolazioni filtroRicercaViolazioni

    FiltroRicercaInsolventi filtroRicercaInsolventi

    // parametri di ricerca nelle denunce
    FiltroRicercaVersamenti filtroRicercaVersamenti

    FiltroRicercaDatiContabili filtroRicercaDatiContabili

    // Ricerca in imposte
    FiltroRicercaImposte filtroRicercaImposte

    // parametri di ricerca nelle imposte
    FiltroRicercaListeDiCaricoRuoli filtroRicercaListeDiCaricoRuoli
    FiltroRicercaListeDiCaricoRuoliDetails filtroRicercaListeDiCaricoRuoliDetails
    FiltroRicercaListeDiCaricoRuoliUtenze filtroRicercaListeDiCaricoRuoliUtenze
    FiltroRicercaListeDiCaricoRuoliPratiche filtroRicercaListeDiCaricoRuoliPratiche
    FiltroRicercaListeDiCaricoRuoliEccedenze filtroRicercaListeDiCaricoRuoliEccedenze

    // Ricerca in datu esterni
    FiltroRicercaFornitureAE filtroRicercaFornitureAE

    // Ricerca in Bonifiche per contribuente
    FiltroRicercaSupportoServizi filtroRicercaSupportoServizi

    // valore soglia tab A Rimborso, Da Pagare, Saldati
    Double dovSoglia

    def competenze

    // Ricerca in Imposte > Detrazioni
    FiltroRicercaImposteDetrazioni filtroRicercaImposteDetrazioni

    // Usato al primo login dell'app per verificare la presenza di oggetti invalidi
    Boolean oggInvalidiFirstTime = true
}
