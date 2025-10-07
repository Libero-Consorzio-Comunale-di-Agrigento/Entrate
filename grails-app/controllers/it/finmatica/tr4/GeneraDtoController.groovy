package it.finmatica.tr4

import it.finmatica.tr4.pratiche.OggettoPratica;
import grails.util.Holders
import groovy.sql.Sql

class GeneraDtoController {
	def dataSource
	
    def index() { 
		def grailsApp = Holders.grailsApplication
		// questo è un hack per aggirare il bug  http://jira.grails.org/browse/GRAILS-10570
		// che non si sa se e quando verrà risolto; se mai verrà risolto tale bug, si potrà
		// usare il generate-dto standard
		
		// per attivare la generazione (solo in configurazione dev) usare un comando tipo:
		// grails -Dplugin.dto.generate=true run-app
		// e poi chiudere l'esecuzione dell'app
		println 'Inzio generazione dei DTO'
		println grailsApp.domainClasses
		//new  it.finmatica.dto.Main().launchGenerator(null, grailsApp, grailsApp.domainClasses)
		render 'Generazione dei DTO in src/groovy terminata'
		
	}
	
	def rendita() {
		
		
		def op = OggettoPratica.get(631081)
		
		Sql sql = new Sql(dataSource)
		println op.valore
		println op.tipoOggetto.tipoOggetto
		println op.pratica.anno
		println op.categoriaCatasto.categoriaCatasto
		
		
		sql.call('{? = call f_pratica(?)}', [Sql.VARCHAR, 269899]) { p ->
			println p
		}
		
		sql.call('{? = call f_rendita(?, ?, ?, ?)}', [Sql.DECIMAL, 6300, 3, 2014, 'C06']) { ren ->
			render ren
		}
		
	}
}
