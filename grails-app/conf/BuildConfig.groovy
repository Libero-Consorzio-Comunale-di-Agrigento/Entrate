grails.servlet.version = "3.0" // Change depending on target container compliance (2.5 or 3.0)
grails.project.class.dir = "target/classes"
grails.project.test.class.dir = "target/test-classes"
grails.project.test.reports.dir = "target/test-reports"
grails.project.work.dir = "target/work"
grails.project.target.level = 1.6
grails.project.source.level = 1.6

rails.release.scm.enabled = false

grails.project.repos.releases.type = "maven"
grails.project.repos.releases.url = System.getProperty("releasesUrl")
grails.project.repos.releases.username = System.getProperty("username")
grails.project.repos.releases.password = System.getProperty("password")

grails.project.repos.snapshots.type = "maven"
grails.project.repos.snapshots.url = System.getProperty("snapshotsUrl")
grails.project.repos.snapshots.username = System.getProperty("username")
grails.project.repos.snapshots.password = System.getProperty("password")

grails.project.fork = false

// RELEASE
grails.project.repos.releases.type = "maven"
grails.project.repos.releases.url = System.getProperty("releasesUrl")
grails.project.repos.releases.username = System.getProperty("username")
grails.project.repos.releases.password = System.getProperty("password")

grails.project.repos.snapshots.type = "maven"
grails.project.repos.snapshots.url = System.getProperty("snapshotsUrl")
grails.project.repos.snapshots.username = System.getProperty("username")
grails.project.repos.snapshots.password = System.getProperty("password")

//grails.project.fork = [
//	// configure settings for compilation JVM, note that if you alter the Groovy version forked compilation is required
//	//  compile: [maxMemory: 256, minMemory: 64, debug: false, maxPerm: 256, daemon:true],
//
//	// configure settings for the test-app JVM, uses the daemon by default
//	test: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, daemon:true],
//	// configure settings for the run-app JVM
//	run: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, forkReserve:false],
//	// configure settings for the run-war JVM
//	war: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256, forkReserve:false],
//	// configure settings for the Console UI JVM
//	console: [maxMemory: 768, minMemory: 64, debug: false, maxPerm: 256]
//]

//grails.project.fork = false


grails.war.resources = { stagingDir, args ->
    println("Elimino i jar non necessari dal .war")

    // rimuovo il jar jdbc
    // rimuovo i jar delle lib
    delete(file: "${stagingDir}/WEB-INF/lib/ojdbc14.jar")
}

grails.project.dependency.resolver = "maven" // or ivy
grails.project.dependency.resolution = {
    // inherit Grails' default dependencies
    inherits("global") {
        excludes "itext"
        // specify dependency exclusions here; for example, uncomment this to disable ehcache:
        // excludes 'ehcache'
    }
    log "error" // log level of Ivy resolver, either 'error', 'warn', 'info', 'debug' or 'verbose'
    checksums true // Whether to verify checksums on resolve
    legacyResolve false
    // whether to do a secondary resolve on plugin installation, not advised and here for backwards compatibility

    repositories {
        inherits true // Whether to inherit repository definitions from plugins

        mavenLocal()

        mavenRepo("https://nexus.finmatica.it/repository/maven-public")
        mavenRepo("https://nexus.finmatica.it/repository/finmatica-snapshots") {
            updatePolicy 'always'
        }
        //TODO: da rimuovere al rilascio di it.finmatica.grails.plugins:afc-quartz:0.3
        mavenRepo("http://svi-redmine:8081/artifactory/finmatica-grails-plugins") {
            updatePolicy 'always'
        }
        mavenRepo "http://mavensync.zkoss.org/eval"
        //mavenRepo "http://jasperreports.sourceforge.net/maven2/"
        //mavenRepo "http://jaspersoft.artifactoryonline.com/jaspersoft/jaspersoft-repo/"

        mavenRepo "http://mavensync.zkoss.org/maven2/"
        grailsPlugins()
        grailsHome()
        grailsCentral()
        mavenCentral()
        // uncomment these (or add new ones) to enable remote dependency resolution from public Maven repositories
        //mavenRepo "http://repository.codehaus.org"
        //mavenRepo "http://download.java.net/maven/2/"
        //mavenRepo "http://repository.jboss.com/maven2/"
    }

    dependencies {
        // specify dependencies here under either 'build', 'compile', 'runtime', 'test' or 'provided' scopes e.g.
        // runtime 'mysql:mysql-connector-java:5.1.24'
        runtime "it.finmatica.zk:finmatica-zk-commons:1.0"
        provided 'commons-dbcp:commons-dbcp:1.4'
        provided 'oracle:ojdbc14:10.2.0.5.0'

        compile "org.codehaus.groovy:groovy-all:2.4.15"
        runtime "xalan:xalan:2.7.1"
        runtime "xalan:serializer:2.7.1"
        runtime "xerces:xercesImpl:2.7.1"
        build "com.lowagie:itext:2.1.7"
        compile "org.xhtmlrenderer:flying-saucer-core:9.0.4"
        compile "org.xhtmlrenderer:flying-saucer-pdf:9.0.4"
        compile 'org.jfree:jfreechart:1.0.19'
        compile "org.zkoss.chart:zkcharts:3.0.1"

        compile "org.apache.poi:poi:3.17"
        compile "org.apache.poi:poi-ooxml:3.17"

        compile 'org.apache.tika:tika-core:1.3'
        compile 'org.apache.tika:tika-parsers:1.3'

        // Permette di utlizzare l'editor avanzato.
        // Introdotto per le mail, ma commentato perché ci sono alcuni problemi.
        // compile "org.zkoss.zkforge:ckez:4.4.6.3"

        compile 'net.sf.jmimemagic:jmimemagic:0.1.5'

        compile group: 'org.apache.pdfbox', name: 'pdfbox', version: '2.0.15'
        compile group: 'org.apache.pdfbox', name: 'pdfbox-tools', version: '2.0.15'

        // Stampe ASPOSE
        runtime "it.finmatica.reporter:finmatica-reporter2:1.2.9"
        runtime "com.aspose:aspose-words:16.11.0"
        test "org.spockframework:spock-grails-support:0.7-groovy-2.0"

        // Integrazione WEBGIS
        compile 'com.github.groovy-wslite:groovy-wslite:1.1.2'

        compile 'ar.com.fdvs:DynamicJasper-core-fonts:1.0'

        provided "it.finmatica:finmatica-cim:2.0"

        provided "it.finmatica:finmatica-accesscontrol:2.0.4"

        runtime "org.apache.commons:commons-collections4:4.1"
        runtime "commons-beanutils:commons-beanutils:1.9.4"

        //Gestione File CVS
        compile "org.apache.commons:commons-csv:1.6"

        // Serve per fare il test dell'installante
//        build('org.apache.ant:ant-jsch:1.9.12')
    }

    plugins {
        // plugins for the build system only
        build ":tomcat:7.0.52.1"
        build ":release:3.1.2"

        // plugins for the compile step
        compile ":scaffolding:2.1.2"
        compile ':cache:1.1.8'

        // plugins needed at runtime but not for compilation
        //runtime ":hibernate:3.6.10.6" // or ":hibernate4:4.1.11.6"
        runtime(":hibernate:3.6.10.6")
//		{
//			excludes 'ehcache-core'
//		}
        //compile ":hibernate4:4.3.5.4"
        runtime ":database-migration:1.4.0"
        runtime ":jquery:1.11.1"
        runtime ":resources:1.2.14"

        //compile ":csv:0.3.1"
        //runtime ':db-reverse-engineer:0.5'

        runtime ":console:1.4.4"

        compile ":export:1.6.1"

        compile "it.finmatica.grails.plugins:finmatica-zk:2.5.1.4"
        compile "it.finmatica.grails.plugins:dto:1.2.2"
        compile ("it.finmatica.grails.plugins:amministrazione-database:2.2.3.6") {
            excludes "it.finmatica:finmatica-accesscontrol:1.21"
        }

        // Cambiata versione perché la 2.2.0.2 dipende da finmatica-zk-2.5-snapshot non più reperibile nel repository aziendale.
        compile "it.finmatica.grails.plugins:anagrafe-soggetti:2.2"
        compile "it.finmatica.grails.plugins:struttura-organizzativa:2.6.2"
        compile "it.finmatica.grails.plugins:afc-quartz:0.4"
        compile "it.finmatica.grails.plugins:confapps:1.0"

        build("it.finmatica.grails.plugins:grails-ci-plugin:1.5") { export = false }
        build('it.finmatica.grails.plugins:ads-installer:1.5')

        // Uncomment these (or add new ones) to enable additional resources capabilities
        //runtime ":zipped-resources:1.0.1"
        //runtime ":cached-resources:1.1"
        //runtime ":yui-minify-resources:0.1.5"


        runtime(":xframeoptions:1.0")

        compile ":jasper:1.10.0"
        test(":spock:0.7") {
            exclude "spock-grails-support"
        }
        // per usare il code coverage: grails test-app -coverage
        test "org.grails.plugins:code-coverage:2.0.3-3"
    }
}

coverage {
    enabledByDefault = false
    xml = true
    // appendCoverageResults = true
    exclusions = [
            '**/*Test*',
            '**/*TagLib*/**',
            '**/plugins/**',
            'java/  **',
            'javax/**',
            'org/**',
            '**/com/**',
            '**_gsp',
            'oracle/**',
            'net/**',
            'groovy**',
            'grails/*',
            'javassist/*',
            'gps/**',
            'geb/**',
            'antlr/**',
            '**/*_closure*',
            '_*',
            'liquibase/*',
            '**/GrailsPlugin*'
    ]
    // list of directories to search for source to include in coverage reports
    sourceInclusions = [
            'src/java',
            'src/groovy',
            'grails-app/conf',
            'grails-app/controllers',
            'grails-app/domain',
            'grails-app/services',
            'grails-app/utils',
            'grails-app/viewmodels'
    ]
}


grails.naming.entries = [
        'jdbc/tr4': [
                type           : "javax.sql.DataSource",
                auth           : "Container",
                description    : "Data source for TR4",
                url            : "jdbc:oracle:thin:@galles2:1521:pal",
                username       : "TR4",
                password       : "tr4",
                driverClassName: "oracle.jdbc.driver.OracleDriver",
                maxActive      : "100",
                maxIdle        : "100"],
        'jdbc/ad4': [
                type           : "javax.sql.DataSource",
                auth           : "Container",
                description    : "Data source for AD4",
                url            : "jdbc:oracle:thin:@galles2:1521:pal",
                username       : "ad4",
                password       : "ad4",
                driverClassName: "oracle.jdbc.driver.OracleDriver",
                maxActive      : "100",
                maxIdle        : "100"]
]

finmatica.installante = {
    applyDb {
        debug = true
        config {

            componenti = "TRV4"

            /*
                TRWCUJB0: CUNI
                TRWIMJB0: IMU
                TRWTAJB0: TARI
                TRWTEJB0: TEFA
             */
            moduli = "TRWIMJB0,TRWTAJB0,TRWCUJB0,TRWTEJB0"

            // Codici comune e provincia del cliente
            tributiweb.codiceComune = "100"
            tributiweb.codiceProvincia = "0"
            tributiweb.province = "X"
            tr4.tr4spws.password = "TR4SPWS"
            tr4.tr4ws.password = "TR4WS"

            global.db.target.url = "jdbc:oracle:thin:@//svi-detr-fin-db19.finmatica.local:1521/p_detr_svi01"
            // specificare user e password di system in modo da poter creare la tablespace
            global.db.system.username = "adstune"
            global.db.system.password = "tune"

            global.db.target.username = "TR4INST"
            global.db.target.password = "TR4"

            // è possibile modificare il codice di istanza in modo da installare più volte sullo stesso server.
            progetto.istanza.codice = "TR4INST"

            global.db.ad4.username="AD4"
            global.db.ad4.password="AD4"

            global.db.gsd.username = "GSDINST"
            global.db.gsd.password="GSD"

            global.db.cfa.username = "CFA"
            global.db.cfa.password = "CFA"

            global.db.trb.username = "TRB"
            global.db.trb.password = "TRB"

            global.db.depag.username = "DEPAG"
            global.db.depag.password = "DEPAG"

            global.db.tr4web.username = "TR4WEB"
            global.db.tr4web.password = "TR4WEB"
        }
    }
}
