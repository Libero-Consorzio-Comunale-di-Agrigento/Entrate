package archivio

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zul.Window

class ListaFamiglieViewModel {
	Window self
	
	
	@Init init(@ContextParam(ContextType.COMPONENT) Window w) {
		this.self = w
	}
	
}
