package it.finmatica.tr4.datiContabili

import grails.transaction.NotTransactional
import grails.transaction.Transactional
import it.finmatica.tr4.CfaAccTributi
import it.finmatica.tr4.DatiContabili
import it.finmatica.tr4.competenze.CompetenzeService
import it.finmatica.tr4.datiesterni.FornitureAEService
import it.finmatica.tr4.TipoTributo
import it.finmatica.tr4.CodiceTributo
import it.finmatica.tr4.GruppoTributo
import it.finmatica.tr4.dto.DatiContabiliDTO
import it.finmatica.tr4.dto.CodiceTributoDTO
import it.finmatica.tr4.dto.CfaAccTributiDTO

import grails.orm.PagedResultList

import java.text.SimpleDateFormat

@Transactional
class DatiContabiliService {

    CompetenzeService competenzeService
    FornitureAEService fornitureAEService

    def salva(DatiContabiliDTO datiContabiliDTO, boolean inModifica) {

        DatiContabili datiContabili = inModifica ? datiContabiliDTO.getDomainObject() : new DatiContabili()
        datiContabili.tipoTributo = datiContabiliDTO?.tipoTributo?.getDomainObject()
        datiContabili.anno = datiContabiliDTO.anno
        datiContabili.tipoImposta = datiContabiliDTO?.tipoImposta
        datiContabili.tipoPratica = datiContabiliDTO?.tipoPratica
        datiContabili.statoPratica = datiContabiliDTO?.statoPratica?.getDomainObject()
        datiContabili.emissioneDal = datiContabiliDTO?.emissioneDal
        datiContabili.emissioneAl = datiContabiliDTO?.emissioneAl
        datiContabili.ripartizioneDal = datiContabiliDTO?.ripartizioneDal
        datiContabili.ripartizioneAl = datiContabiliDTO?.ripartizioneAl
        datiContabili.tributo = datiContabiliDTO?.tributo?.getDomainObject()
        datiContabili.tipoOccupazione = datiContabiliDTO?.tipoOccupazione
        datiContabili.codTributoF24 = datiContabiliDTO?.codTributoF24
        datiContabili.descrizioneTitr = datiContabiliDTO.descrizioneTitr
        datiContabili.annoAcc = datiContabiliDTO?.annoAcc
        datiContabili.numeroAcc = datiContabiliDTO?.numeroAcc
        datiContabili.codEnteComunale = datiContabiliDTO?.codEnteComunale

        datiContabili.save(flush: true, failOnError: true, insert: !inModifica).toDTO()
    }

    def cancella(DatiContabiliDTO datiContabiliDTO) {
        DatiContabili d = datiContabiliDTO.getDomainObject()
        d?.delete(failOnError: true)
    }

    @NotTransactional
    def getDatiContabili() {
        def lista = DatiContabili.list()?.toDTO(["tipoTributo",
                                                 "tributo",
                                                 "statoPratica"])
        def records = []
        lista.each {
            if (competenzeService.tipoAbilitazioneUtente(it.tipoTributo.tipoTributo)) {
                records << it
            }
        }
        return records
    }

    @NotTransactional
    def getDatiContabili(def parRicerca) {
        SimpleDateFormat sdf = new SimpleDateFormat(("dd/MM/yyy"))

        List<DatiContabiliDTO> lista = DatiContabili.createCriteria().list() {
            if (parRicerca.anno) {
                eq("anno", parRicerca.anno)
            }

            if (parRicerca.tipoTributo) {
                eq("tipoTributo.tipoTributo", parRicerca.tipoTributo.tipoTributo)
            }

            if (parRicerca.tipoImposta) {
                eq("tipoImposta", parRicerca.tipoImposta)
            }

            if (parRicerca.tipoPratica) {
                eq("tipoPratica", parRicerca.tipoPratica)
            }

            if (parRicerca.statoPratica && parRicerca.statoPratica.tipoStato != "") {
                eq("statoPratica", parRicerca.statoPratica.toDomain())
            }

            if (parRicerca?.ripartizioneDal) {
                sqlRestriction("ripartizione_dal >= TO_DATE('" + sdf.format(parRicerca?.ripartizioneDal).toString() + "','dd/mm/yyyy')")
            }
            if (parRicerca?.ripartizioneAl) {
                sqlRestriction("ripartizione_al <= TO_DATE('" + sdf.format(parRicerca?.ripartizioneAl).toString() + "','dd/mm/yyyy')")
            }

            if (parRicerca?.emissioneDal) {
                sqlRestriction("emissione_dal >= TO_DATE('" + sdf.format(parRicerca?.emissioneDal).toString() + "','dd/mm/yyyy')")
            }
            if (parRicerca?.emissioneAl) {
                sqlRestriction("emissione_al <= TO_DATE('" + sdf.format(parRicerca?.emissioneAl).toString() + "','dd/mm/yyyy')")
            }

            if (parRicerca.annoAcc && parRicerca.annoAcc != 0) {
                eq("annoAcc", parRicerca.annoAcc)
                if (parRicerca.numeroAcc && parRicerca.numeroAcc != 0) {
                    eq("numeroAcc", parRicerca.numeroAcc)
                }
            }

            if (parRicerca?.tributo?.id) {
                eq("tributo", parRicerca.tributo.toDomain())
            }

            if (parRicerca.tipoOccupazione) {
                eq("tipoOccupazione", parRicerca.tipoOccupazione)
            }

            if (parRicerca.codTributoF24) {
                eq("codTributoF24", parRicerca.codTributoF24)
            }

            if (parRicerca.codEnteComunale) {
                eq("codEnteComunale", parRicerca.codEnteComunale)
            }

            order("anno", "desc")
            order("tipoTributo", "asc")
            order("ripartizioneDal", "asc")
            order("emissioneDal", "asc")
            order("codEnteComunale", "asc")
            order("tipoPratica", "asc")
            order("statoPratica", "asc")
            order("tipoImposta", "asc")
            order("tributo", "asc")
            order("codTributoF24", "asc")
            order("tipoOccupazione", "asc")
        }?.toDTO(["tipoTributo", "tributo", "statoPratica"])

        List<DatiContabiliDTO> records = []
        lista.each {
            if (competenzeService.tipoAbilitazioneUtente(it.tipoTributo.tipoTributo)) {
                records << it
            }
        }

        completaDatiContabili(records)

        return records
    }

    def getDato(long id) {
        def dato = DatiContabili.get(id).toDTO(["tipoTributo",
                                     "tributo",
                                     "statoPratica"])

        return dato
    }

    def completaDatiContabili(List<DatiContabiliDTO> records) {
    
		def elencoEnti = []

		String siglaEnte;
        String descr

        records.each { record ->

            descr = record.descrizioneTitr ?: ''
            if (descr.size() == 0) {
                record.descrizioneTitr = record.tipoTributo.getTipoTributoAttuale(record.anno);
            }

			siglaEnte = record.codEnteComunale ?: ''

			if(!siglaEnte.isEmpty()) {
				def enteComunale = elencoEnti.find { it.siglaCFis == siglaEnte }
				if(enteComunale == null) {
					enteComunale = fornitureAEService.getDatiComuneDaSiglaCFis(siglaEnte)
					elencoEnti << enteComunale
				}

				record.desEnteComunale = enteComunale.siglaCFis + ' - ' + enteComunale.descrizione
			}
			else {
				record.desEnteComunale = siglaEnte
			}
        }
    }

    String validaPerCUNI(DatiContabiliDTO dato) {

        String result = ''

        def numeroDati = DatiContabili.createCriteria().list() {
            eq("tipoTributo.tipoTributo", dato.tipoTributo.tipoTributo)
            eq("anno", dato.anno)

            if (dato.id) {
                ne("id", dato.id)
            }
            if (dato.tipoImposta) {
                eq("tipoImposta", dato.tipoImposta)
            } else {
                isNull("tipoImposta")
            }
            if (dato.tipoPratica) {
                eq("tipoPratica", dato.tipoPratica)
            } else {
                isNull("tipoPratica")
            }
            if (dato.statoPratica) {
                eq("statoPratica.tipoStato", dato.statoPratica.tipoStato)
            } else {
                isNull("statoPratica")
            }
            if (dato.tributo) {
                eq("tributo.id", dato.tributo.id)
            } else {
                isNull("tributo")
            }
            if (dato.codTributoF24) {
                eq("codTributoF24", dato.codTributoF24)
            } else {
                isNull("codTributoF24")
            }
            if (dato.tipoOccupazione) {
                isNull("tipoOccupazione")
            } else {
                isNotNull("tipoOccupazione")
            }
        }?.size()

        if (numeroDati > 0) {
            result = "Esistono dei dati contabili similari "
            if (dato.tipoOccupazione) {
                result += "senza"
            } else {
                result += "con"
            }
            result += " il tipo di occupazione!"
            result += " Occorre uniformare le impostazioni per tutte le configurazioni similari"
        }

        return result
    }

    String validaPerGruppiTributo(DatiContabiliDTO dato) {

        String result = ''

        while (1 == 1) {

            if (dato.tipoTributo?.tipoTributo != 'CUNI')
                break

            if (dato.tributo == null)
                break
            if (dato.tributo.gruppoTributo == null)
                break

            TipoTributo tipoTributo = TipoTributo.get(dato.tipoTributo?.tipoTributo)

            String codGruppoTributo = dato.tributo.gruppoTributo
            GruppoTributo gruppoTributo = GruppoTributo.findByTipoTributoAndGruppoTributo(tipoTributo, codGruppoTributo)

            List<CodiceTributoDTO> codiciTributo = CodiceTributo.findAllByTipoTributoAndGruppoTributo(tipoTributo, codGruppoTributo)
            codiciTributo.sort { it.id }

            def listaAcc = DatiContabili.createCriteria().list() {
                projections {
                    groupProperty("annoAcc")
                    groupProperty("numeroAcc")
                }

                eq("tipoTributo.tipoTributo", dato.tipoTributo.tipoTributo)
                eq("anno", dato.anno)

                if (dato.tipoImposta) {
                    eq("tipoImposta", dato.tipoImposta)
                } else {
                    isNull("tipoImposta")
                }
                if (dato.tipoPratica) {
                    eq("tipoPratica", dato.tipoPratica)
                } else {
                    isNull("tipoPratica")
                }
                if (dato.statoPratica) {
                    eq("statoPratica", dato.statoPratica)
                } else {
                    isNull("statoPratica")
                }
                if (dato.tipoOccupazione) {
                    eq("tipoOccupazione", dato.tipoOccupazione)
                } else {
                    isNull("tipoOccupazione")
                }

                'in'("tributo", codiciTributo)
            }

            if (listaAcc?.size() > 1) {
                result = "A parita\' di impostazioni tutti i Tributi dello stesso Gruppo Tributo " + gruppoTributo.descrizione + " ("
                result += codiciTributo.collect { (it.id as String) }.join(', ')
                result += ") dovrebbero riferirsi allo stesso Accertamento Contabile"
            }

            break
        }

        return result
    }

    /// Verifica presenza di Esercizio per l'accertamento contabile
    def validaAccTributoPerAnno(CfaAccTributiDTO cfAaccTributo, Short anno) {

        String message = ''

        def listaAcc = CfaAccTributi.createCriteria().listDistinct() {
            eq("annoAcc", cfAaccTributo.annoAcc as Short)
            eq("numeroAcc", cfAaccTributo.numeroAcc as Integer)
            eq("esercizio", anno as Integer)
        }
        if (listaAcc.size() < 1) {
            message = "L'accertamento contabile " + cfAaccTributo.numeroAcc + "/" + cfAaccTributo.annoAcc +
                    " non prevede dettagli per l'anno di esercizio ${anno}"
        }

        return message
    }

    @NotTransactional
    def getDatiContabili(DatiContabiliDTO dato) {

        List<DatiContabiliDTO> lista = DatiContabili.createCriteria().list() {
            eq("tipoTributo.tipoTributo", dato.tipoTributo.tipoTributo)
            eq("anno", dato.anno)

            if (dato.tipoImposta) {
                eq("tipoImposta", dato.tipoImposta)
            } else {
                isNull("tipoImposta")
            }
            if (dato.tipoPratica) {
                eq("tipoPratica", dato.tipoPratica)
            } else {
                isNull("tipoPratica")
            }
            if (dato.statoPratica) {
                eq("statoPratica.tipoStato", dato.statoPratica.tipoStato)
            } else {
                isNull("statoPratica")
            }
            if (dato.tributo) {
                eq("tributo.id", dato.tributo.id)
            } else {
                isNull("tributo")
            }
            if (dato.codTributoF24) {
                eq("codTributoF24", dato.codTributoF24)
            } else {
                isNull("codTributoF24")
            }
            if (dato.tipoOccupazione) {
                eq("tipoOccupazione", dato.tipoOccupazione)
            } else {
                isNull("tipoOccupazione")
            }
            if (dato.codEnteComunale) {
                eq("codEnteComunale", dato.codEnteComunale)
            } else {
                isNull("codEnteComunale")
            }
        }?.toDTO(["tipoTributo", "tributo", "statoPratica"])

        return lista
    }

    def getListaAnniAccertamentoContabile(def annoEsercizio) {

        def lista = CfaAccTributi.createCriteria().listDistinct() {
            eq("esercizio", annoEsercizio as Integer)
            projections {
                groupProperty("annoAcc")
            }
            order("annoAcc", "asc")
        }

        return lista
    }

    def getCfaAccTributiBandBox(def filtri, int pageSize, int activePage, int allowEmpty) {

        String filtroDescr = null
        Integer filtroNum = null

        /// Scompone le due parti del filtro usando il '-' come separatore
        String filtroCompleto = filtri?.descrizioneCompleta ?: ''

        if(!filtroCompleto.isEmpty()) {
            def tokens = filtroCompleto.tokenize('-')
            def numTokens = tokens.size()

            if(numTokens > 0) {
                if(numTokens > 1) {
                    /// Due parti : numero e descrizione
                    if(tokens[0].isInteger()) {
                        filtroNum = tokens[0] as Integer
                    }
                    else {
                        filtroNum = -1
                    }
                    filtroDescr = tokens[1].trim()
                }
                else {
                    /// Una parte : numero (e intero) o descrizione (alfanumerico)
                    if(tokens[0].isInteger()) {
                        filtroNum = tokens[0] as Integer
                    }
                    else {
                        filtroDescr = tokens[0].trim()
                    }
                }
            }
        }

        Integer esercizio = filtri.esercizio
        Integer annoAcc = filtri.annoAcc

        List<CfaAccTributiDTO> elencoTotale = CfaAccTributi.createCriteria().listDistinct() {
            eq("annoAcc", annoAcc as Short)
            if(esercizio) {
                eq("esercizio", esercizio as Integer)
            }

            if((filtroDescr) || (filtroNum)) {
                or {
                    if(filtroNum) {
                        sqlRestriction("to_char(numero_acc) like ('%' || to_char(" + (filtroNum as String) + ") ||'%')")
                    }
                    if(filtroDescr) {
                        ilike("descrizioneAcc", '%' + filtroDescr + "%")
                    }
                }
            }

            order("numeroAcc", "asc")
            order("descrizioneAcc", "asc")
        }?.toDTO()

        if(allowEmpty > 0) {

            CfaAccTributiDTO empty = new CfaAccTributiDTO();
            empty.numeroAcc = -1
            empty.descrizioneAcc = ""

            List<CfaAccTributiDTO> temp = []
            temp.add(empty)
            temp.addAll(elencoTotale)
            elencoTotale = temp
        }

        def totale = elencoTotale.size()
        def fromIndex = pageSize * activePage
        def toIndex = fromIndex + pageSize

         List<CfaAccTributiDTO> elenco = []

        if ((totale > 0) && (fromIndex < totale)) {
            if(toIndex >= totale) {
                toIndex = totale - 1
            }
            elenco = elencoTotale[fromIndex..toIndex]
        }

        return [ lista: elenco, totale: totale ]
    }
}
