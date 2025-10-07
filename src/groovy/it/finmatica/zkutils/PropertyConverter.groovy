package it.finmatica.zkutils

import org.zkoss.bind.BindContext
import org.zkoss.bind.Converter
import org.zkoss.zk.ui.Component

class PropertyConverter implements Converter {

	//@Override
	public Object coerceToBean(Object obj, Component component, BindContext context) {
//		println "coerceToBean ${obj}, ${component}"
		return obj?.value
	}
	
	/**
	 * Tra tutti gli elementi del model prendo quello con #property
	 */
	//@Override
	public Object coerceToUi(Object obj, Component component, BindContext context) {
		final String property = (String) context.getConverterArg("property");
//		println "coerceToUi 1: ${obj}, ${component}, ${property}"
		
		// se il selectedItem non ha propery allora ne prendo la stringa
		def propertyValue = obj?.hasProperty(property) ? obj?."$property" : obj
		
//		println "coerceToUi 2: propertyValue=${propertyValue}"
		
//		component.model.each {
//			println "model: ${it."$property"}"
//		}
//		
//		component.items.each {
//			println "items: ${it.value."$property"}"
//		}
		
		int i = component.model.findIndexOf { it?."$property" == propertyValue }
//		println "coerceToUi 3: $i"
		if (i < 0) {
//			println "coerceToUi 4: return null"
			return null
		}
		
//		println "coerceToUi 5: ${component.items[i]}"
		return component.items[i];
	}
	
}