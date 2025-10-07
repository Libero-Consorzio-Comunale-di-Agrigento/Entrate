//import grails.plugin.svn.SvnClient;

includeTargets << grailsScript("_GrailsInit")
includeTargets << grailsScript("_GrailsClasspath")
includeTargets << grailsScript("_GrailsWar")
includeTargets << grailsScript("_GrailsPackage")
includeTargets << grailsScript("_GrailsArgParsing")
includeTargets << new File("./scripts/Jasper.groovy")

target(main: "Crea una nuova build") {
	/*if (argsMap.params.contains("jasper")) {
		depends (jasper)
	} else /*if (argsMap.params.contains("ftp")) {
		depends (ftp)
	} else {*/
		depends (classpath, buildInfo, compile, jasper, war)
	//}
}



//  <target name="compile1"> 
//  <mkdir dir="./build/reports"/> 
//  <jrc 
//    srcdir="./reports"
//    destdir="./build/reports"
//    tempdir="./build/reports"
//    keepjava="true"
//    xmlvalidation="true">
//   <classpath refid="runClasspath"/>
//   <include name="**/*.jrxml"/>
//  </jrc>
//</target>


//target(jasper: "Compila i report") {
//	println "Compilo i report jasper..."
//	
//    def sourceDir = (config.'jasper.dir.reports'?:'reports')
//    println "sourceDir = ${sourceDir}"
//    ant.taskdef(name: "jrc"
//			  , classname: "net.sf.jasperreports.ant.JRAntCompileTask")
//    jrc(srcdir:"${basedir}/web-app/${sourceDir}") {
//		include(name:"**/*.jrxml")
//    } 
//	println "Finito di compilare i report jasper..."
//}

target(buildInfo: "Crea le informazioni della build") {
	String version 		= metadata.'app.version'
	String buildVersion = metadata.'app.buildVersion'
	def buildNumber 	= metadata.'app.buildNumber'

	if (!buildNumber) {
		buildNumber = 0
	} else {
		buildNumber = Integer.parseInt(buildNumber)
	}
	
	buildNumber += 1

	metadata.'app.buildVersion' = version
	metadata.'app.buildNumber'  = buildNumber.toString()
	metadata.'app.buildTime'    = new Date().format("dd/MM/yyyy HH:mm:ss")

	metadata.persist()
	
	println ("Inizio la build #$buildNumber per la versione $version")
}
/*
target (release: "Rilascia la versione") {
	println "Copio il war su S:\\SI4\\Affari Generali\\Sfera\\latest\\install\\13.tomcat"
	ant.copy (file:"target/Atti.war", todir:"S:\\SI4\\Affari Generali\\Sfera\\latest\\install\\13.tomcat")
	
	// crea una nuova versione su S:
	println "Creo la versione su S:\\SI4\\Affari Generali\\Sfera\\dist\\v${metadata."app.version"}"
	ant.copy (todir:"S:\\SI4\\Affari Generali\\Sfera\\dist\\v${metadata."app.version"}") {
		fileset (dir:"S:\\SI4\\Affari Generali\\Sfera\\latest")
	}
	
	// copia la versione su P:
	println "Elimino e ricreo la versione su P:"
	ant.delete(dir:"P:\\SI4\\Affari Generali\\Sfera\\Install");
	ant.copy (todir:"P:\\SI4\\Affari Generali\\Sfera\\Install") {
		fileset (dir:"S:\\SI4\\Affari Generali\\Sfera\\latest")
	}
	
	// copia la versione su I:
	println "Elimino e ricreo la versione su I:"
	ant.delete(dir:"I:\\Si4\\Install\\Prodotti\\Affari Generali\\Sfera");
	ant.copy (todir:"I:\\Si4\\Install\\Prodotti\\Affari Generali\\Sfera") {
		fileset (dir:"S:\\SI4\\Affari Generali\\Sfera\\latest")
	}
	
	depends(ftp)
}

target (ftp: "Carico il War su FTP") {
	
	println "Creo la directory su ftp."
	ant.ftp(action:		"mkdir",
			server:		"ftp.ads.it",
			userid:		"genftp",
			password:	"lavoro17",
			remotedir:	"passa/sasdo/SFERA")
	
	println "Carico il war su ftp."
	ant.ftp(action:		"put",
			server:		"ftp.ads.it",
			userid:		"genftp",
			password:	"lavoro17",
			remotedir:	"passa/sasdo/SFERA") {
		fileset (file:"target/Atti.war")
	}
}
*/
setDefaultTarget(main)
