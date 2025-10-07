class UrlMappings {

    static excludes = ['/zkau/*']

	static mappings = {
        "/$controller/$action?/$id?(.${format})?"{
            constraints {
                // apply constraints here
            }
        }

        "/"(view:"/index.zul")
        "500"(view:'/error')
	}
}
