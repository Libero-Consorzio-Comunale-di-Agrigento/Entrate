package it.finmatica.tr4.commons

import java.util.concurrent.ConcurrentHashMap

import org.codehaus.groovy.grails.commons.GrailsApplication
import org.codehaus.groovy.grails.plugins.support.aware.GrailsApplicationAware
import org.apache.log4j.Logger

class OggettiCacheMap implements GrailsApplicationAware {
	private static final Logger log = Logger.getLogger (OggettiCacheMap.class)
	GrailsApplication grailsApplication
	
	private final ConcurrentHashMap<String, Object> map
	private boolean inizializzata = false
	
	public OggettiCacheMap() {
		map = new ConcurrentHashMap<String, Object>()
	}
	
	public void init() {
		OggettiCache.map = this
	}
	
	def getValore(String oggetto) {
		if (!inizializzata) {
			refresh()
		}
		return map.get(oggetto)
	}
	
	public void refresh(OggettiCache singolo = null) {
		if (singolo) {
			log.debug ("Aggiornamento cache per: " + singolo.getNomeClasse())
			def clazz = grailsApplication.getDomainClass(singolo.getNomeClasse()).clazz
			map.put(singolo.toString(), clazz.list().toDTO(singolo.getDomainCollegate()))
		} else {
			for (OggettiCache oc : OggettiCache.values()) {
				log.debug ("Cache per: " + oc.getNomeClasse())
				
				def clazz = grailsApplication.getDomainClass(oc.getNomeClasse()).clazz
				map.put(oc.toString(), clazz.list().toDTO(oc.getDomainCollegate()))
			}
		}
		inizializzata = true
	}
}
