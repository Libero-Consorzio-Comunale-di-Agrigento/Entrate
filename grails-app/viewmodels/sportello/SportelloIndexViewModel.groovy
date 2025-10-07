package sportello

import org.zkoss.bind.BindUtils
import org.zkoss.bind.annotation.ContextParam
import org.zkoss.bind.annotation.ContextType
import org.zkoss.bind.annotation.Init
import org.zkoss.zk.ui.Sessions
import org.zkoss.zul.Window

class SportelloIndexViewModel {
	Window self
	
	// stato
	String selectedSezione
	String urlSezione
	
	def pagineArchivio = [
	  contribuenti	: "/sportello/contribuenti/listaContribuenti.zul"	
	]
	
	
	@Init init(@ContextParam(ContextType.COMPONENT) Window w) {
		this.self = w
		String elemento = Sessions.getCurrent().getAttribute("elemento")
		Sessions.getCurrent().removeAttribute("elemento")
		setSelectedSezione(elemento)
	}
	
	public List<String> getPatterns () {
		return pagineArchivio.collect { it.key }
	}
	
	public void handleBookmarkChange (String bookmark) {
		setSelectedSezione(bookmark)
	}
	
	public void setSelectedSezione (String value) {
		if (value == null || value.length() == 0) {
			urlSezione = null
		}
		
		selectedSezione = value
		urlSezione 		= pagineArchivio[selectedSezione]

		BindUtils.postNotifyChange(null, null, this, "urlSezione")
	}
}
