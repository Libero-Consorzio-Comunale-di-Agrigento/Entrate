package it.finmatica.utility.legacydb

import org.codehaus.groovy.grails.orm.hibernate.cfg.GrailsAnnotationConfiguration
import org.hibernate.MappingException
import org.hibernate.mapping.RootClass

class MyCustomGrailsAnnotationConfiguration extends
		GrailsAnnotationConfiguration {

			private static final long serialVersionUID = 1;
			private boolean _alreadyProcessed=false;
			@Override
			protected void secondPassCompile() throws MappingException {
				println "secondPassCompile"
				super.secondPassCompile();
				if(_alreadyProcessed){
					return;
				}
				println "secondPassCompile"
				classes.values().each{rootClass ->
					if(rootClass instanceof RootClass){
						def domainClass = null
						Boolean hasForeigners = false
						try{
							domainClass = Class.forName(rootClass.entityName, false, Thread.currentThread().getContextClassLoader())
							hasForeigners = domainClass.metaClass.hasProperty(domainClass, 'foreigners')
						} catch(Exception e) { }
						
						if (domainClass && hasForeigners) {
							rootClass?.table?.foreignKeyIterator?.each { fKey ->
								fKey?.columnIterator?.each { column ->
									domainClass.foreigners?.each { attrName, columns ->
										println "Column: " + column.name
										columns.each { columnItmName, columnItmValue ->
											def exp = attrName + "_"
											columnItmName.split("").each { exp+= (it==~/[A-Z]/) ? "_" + it:it }
											exp = exp.toLowerCase() + "(.id)?\$"
											println "\tExpression: " + exp
											if (column.name.matches(exp)) {
												println "\tMatch: " + column.name + " changing to " + columnItmValue
												column.name = columnItmValue
											}
										}
									}
								}
							}
						}
					}
				}
				_alreadyProcessed = true;
			}
}
