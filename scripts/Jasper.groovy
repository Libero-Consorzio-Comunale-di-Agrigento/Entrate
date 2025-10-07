//import grails.plugin.svn.SvnClient;

includeTargets << grailsScript("_GrailsInit")
includeTargets << grailsScript("_GrailsClasspath")
includeTargets << grailsScript("_GrailsWar")
includeTargets << grailsScript("_GrailsPackage")
includeTargets << grailsScript("_GrailsArgParsing")

def fileJrxml = ("*")

target(jasper: "Crea una nuova build") {
	fileJrxml = argsMap.params[0]?:"*"
	println "Compilo i report jasper..."
	
    def sourceDir = (config.'jasper.dir.reports'?:'reports')
    println "sourceDir = ${sourceDir}"
    ant.taskdef(name: "jrc"
			  , classname: "net.sf.jasperreports.ant.JRAntCompileTask")
    jrc(srcdir:"${basedir}/web-app/${sourceDir}") {
		include(name:"**/${fileJrxml}.jrxml")
    } 
	println "Finito di compilare i report jasper..."
}

setDefaultTarget(jasper)
