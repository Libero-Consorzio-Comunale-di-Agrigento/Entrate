package it.finmatica.tr4.reports.F24


import org.apache.log4j.Logger
import org.springframework.beans.BeansException
import org.springframework.context.ApplicationContext
import org.springframework.context.ApplicationContextAware

class DefaultDatiF24Factory implements DatiF24Factory, ApplicationContextAware {
	
	private static final Logger log = Logger.getLogger(DefaultDatiF24Factory.class)
	
	ApplicationContext context

	@Override
	public void setApplicationContext(ApplicationContext context)
	throws BeansException {
		this.context = context
	}

	@Override
	public DatiF24 creaDatiF24(String siglaComune, String tipoTributo, int tipoPagamento) {
		DatiF24 datiF24
		try {
			datiF24 = context?.getBean("datiF24${tipoTributo}")
			datiF24.setSiglaComune(siglaComune)
			datiF24.setTipoPagamento(tipoPagamento)
			return datiF24
		} catch (Exception e) {
			log.error("Creazione bean datiF24${tipoTributo}", e)
		}
	}

	@Override
	public DatiF24 creaDatiF24(String siglaComune) {
		creaDatiF24(siglaComune, "Bianco", -1)
	}

	@Override
	public DatiF24 creaDatiF24(String siglaComune, def pratica, def tipo) {
		
		def tipoTributo = ""
		def bean = ""
		switch (tipo) {
			case 'V':
				bean = 'datiF24Violazione'
				tipoTributo = pratica.tipoTributo.tipoTributo
				break
			case 'R':
				bean = 'datiF24Rate'
				break
			case 'I':
				bean = 'datiF24Imposta'
				break
			default:
				throw new RuntimeException("Tipo '$tipo' non supportato.")
		}
		
		DatiF24 datiF24
		try {
			datiF24 = context?.getBean(bean + tipoTributo)
			datiF24.setSiglaComune(siglaComune)
			return datiF24
		} catch (Exception e) {
			log.error("Creazione bean $bean$tipoTributo", e)
		}
	}
}
