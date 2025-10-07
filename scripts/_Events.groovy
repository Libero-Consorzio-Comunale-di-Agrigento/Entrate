eventCreateWarStart = { warName, stagingDir ->
    String appVersion = metadata.'app.version'
    String appName = metadata.'app.name'
    String appGroup = metadata.'app.group'
    String appCode = metadata.'app.code'

    // Gestione config.properties dell'installante
    def configProperties = new File("./installante/config.properties")
    if (configProperties.exists()) {
        println "Inizializzazione versione installante..."
        configProperties.text = configProperties.text.replace("app.version", appVersion)
    }

    println "*** Customized build update of Grails: ${appName}. Current version: ${appVersion}"

    def unknownValue = 'UNKNOWN'
    def buildNumberEnvironment = 'BUILD_NUMBER'
    def buildUrlEnvironment = 'BUILD_URL'
    def scmRevisionEnvironment = 'GIT_COMMIT'
    def scmBranchEnvironment = 'GIT_BRANCH'
    //def scmRevisionEnvironment = 'SVN_REVISION'

    def buildNumberProperty = 'build.number'
    def buildUrlProperty = 'build.url'
    def scmRevisionProperty = 'build.revision'


    def buildNumber = System.getenv(buildNumberEnvironment)
    if( !buildNumber ) {
        buildNumber = System.getProperty(buildNumberProperty, unknownValue)
    }
    println "*** Customized buildNumber: ${buildNumber}"

    def buildUrl = System.getenv(buildUrlEnvironment)
    if( !buildUrl ) {
        buildUrl = System.getProperty(buildUrlProperty, unknownValue)
    }
    println "*** Customized buildUrl: ${buildUrl}"

    def scmRevision = System.getenv(scmRevisionEnvironment)
    if( !scmRevision ) {
        scmRevision = System.getProperty(scmRevisionProperty, unknownValue)
    }
    println "*** Customized scmRevision: ${scmRevision}"

    def scmBranch = System.getenv(scmBranchEnvironment)?:unknownValue
    println "*** Customized scmBranch: ${scmBranch}"

    def buildDate = new Date().format('dd/MM/yyyy - HH:mm:ss')

    ant.propertyfile(file:"${stagingDir}/WEB-INF/classes/application.properties") {
        entry(key:'app.version', value: appVersion)
        entry(key:'app.buildNumber', value: buildNumber)
        entry(key:'app.buildTime', value: buildDate)
    }
    ant.manifest(file: "${stagingDir}/META-INF/MANIFEST.MF", mode: "update") {
        attribute(name: "Build-Time", value: buildDate)
        section(name: "Grails Application") {
            attribute(name: "Specification-Title", value: appName)
            attribute(name: "Specification-Version", value: appVersion)
            attribute(name: "Implementation-Title", value: "${appGroup}.${appCode}.${appName}".toLowerCase())
            attribute(name: "Implementation-Version", value: "${appVersion}-b${buildNumber}")
            attribute(name: "Implementation-Timestamp", value: buildDate)
            attribute(name: "Build-Number", value: buildNumber)
            attribute(name: "Build-Url", value: buildUrl)
            attribute(name: "Git-Commit", value: scmRevision)
            attribute(name: "Git-Branch", value: scmBranch)
        }
    }
    println "*** Customized build update of Grails: ${appName}. Current version: ${appVersion}-b${buildNumber}"
}

eventCompileEnd = {

   // Check for the skipJasperCompile property
    def skipJasperCompile = System.getProperty('skipJasperCompile', 'false').toBoolean()

    if (skipJasperCompile) {
        println "Skipping Jasper report compilation..."
    } else {
        println "Compiling Jasper reports..."
        // define the Jasper Reports Compile Task
        ant.taskdef(name:'reportCompile', classname: 'net.sf.jasperreports.ant.JRAntCompileTask', classpath: projectWorkDir)
        // remove existing jasper files
        ant.delete{
            fileset('dir':'web-app/reports', 'defaultexcludes':'yes'){
                include('name':'**/*.jasper')
            }
        }
        // create a temporary directory for use by the jasper compiler
        ant.mkdir(dir:'target/jasper')
        // compile the reports
        ant.reportCompile(srcdir:'web-app/reports', destdir:'web-app/reports', tempdir:'target/jasper', keepJava:true, xmlvalidation:true){
            include(name:'**/*.jrxml')
        }
    }
}
