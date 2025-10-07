import org.apache.log4j.Level
import org.apache.log4j.Logger

grails.project.groupId = appName // change this to alter the default package name and Maven publishing destination

// The ACCEPT header will not be used for content negotiation for user agents containing the following strings (defaults to the 4 major rendering engines)
grails.mime.disable.accept.header.userAgents = ['Gecko', 'WebKit', 'Presto', 'Trident']
grails.mime.types = [all          : '*/*',
                     atom         : 'application/atom+xml',
                     css          : 'text/css',
                     csv          : 'text/csv',
                     form         : 'application/x-www-form-urlencoded',
                     html         : ['text/html', 'application/xhtml+xml'],
                     js           : 'text/javascript',
                     json         : ['application/json', 'text/json'],
                     multipartForm: 'multipart/form-data',
                     rss          : 'application/rss+xml',
                     text         : 'text/plain',
                     hal          : ['application/hal+json', 'application/hal+xml'],
                     xml          : ['text/xml', 'application/xml']]

// URL Mapping Cache Max Size, defaults to 5000
//grails.urlmapping.cache.maxsize = 1000

// What URL patterns should be processed by the resources plugin
grails.resources.adhoc.patterns = ['/images/*', '/css/*', '/js/*', '/plugins/*']

// Legacy setting for codec used to encode data with ${}
grails.views.default.codec = "html"

// The default scope for controllers. May be prototype, session or singleton.
// If unspecified, controllers are prototype scoped.
grails.controllers.defaultScope = 'singleton'

grails.hibernate.cache.queries = false
// GSP settings
grails {
    views {
        gsp {
            encoding = 'UTF-8'
            htmlcodec = 'xml' // use xml escaping instead of HTML4 escaping
            codecs {
                expression = 'html' // escapes values inside ${}
                scriptlet = 'html' // escapes output from scriptlets in GSPs
                taglib = 'none' // escapes output from taglibs
                staticparts = 'none' // escapes output from static template parts
            }
        }
        // escapes all not-encoded output at final stage of outputting
        filteringCodecForContentType {
            //'text/html' = 'html'
        }
    }
}

grails.converters.encoding = "UTF-8"
// scaffolding templates configuration
grails.scaffolding.templates.domainSuffix = 'Instance'

// Set to false to use the new Grails 1.2 JSONBuilder in the render method
grails.json.legacy.builder = false
// enabled native2ascii conversion of i18n properties files
grails.enable.native2ascii = true
// packages to include in Spring bean scanning
grails.spring.bean.packages = []
// whether to disable processing of multi part requests
grails.web.disable.multipart = false

// request parameters to mask when logging exceptions
grails.exceptionresolver.params.exclude = ['password']

// configure auto-caching of queries by default (if false you can cache individual queries with 'cache: true')
grails.hibernate.cache.queries = false

grails.plugin.xframeoptions.sameOrigin = true

grails.validateable.packages = ['it.finmatica.tr4.comunicazioni.payload']

environments {
    development {
        grails.logging.jul.usebridge = true
    }
    production {
        grails.logging.jul.usebridge = false
        // TODO: grails.serverURL = "http://www.changeme.com"
        def logger = Logger.getRootLogger()
        logger.removeAppender('stdout')
    }
}

// log4j configuration
log4j = {

    debug "it.finmatica.tr4"
    debug "archivio.dizionari"
    debug "elaborazioni"
    debug "pratiche.denunce"

    appenders {
        rollingFile name: 'file',
                maxFileSize: 10485760,
                maxBackupIndex: 10,
                file: "logs/TributiWeb.log",
                layout: pattern(conversionPattern: '%d{ISO8601} %5p [%t] %c{2} - %m%n'),
                threshold: Level.DEBUG
    }

    root {
        info 'file'
        info 'stdout'
    }

    'null' name: 'stacktrace'
}

grails.plugins.springsecurity.securityConfigType = 'InterceptUrlMap'
grails.plugins.springsecurity.interceptUrlMap = [
        '/f24/**'       : ['IS_AUTHENTICATED_ANONYMOUSLY'],
        '/F24Pratica/**': ['IS_AUTHENTICATED_ANONYMOUSLY'],
        '/'                : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/index.zul'       : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/archivio/*'      : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/pratiche/*'      : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/sportello/*'     : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/ufficiotributi/*': ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/multiEnte/*'     : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO
        '/standalone.zul'  : ["hasAnyRole('TR4_AMM', 'AMM', 'TR4_TRIB', 'TRIB')"],    // ruoli di accesso: il primo è la concatenazione tra MODULO_RUOLO, il secondo è solo il RUOLO

]

grails.plugins.amministrazionedatabase.publicUrlPatterns = [
        "/smartPND/*",
        "/f24/*",
        "/F24Pratica/*",
        "/static/*",
        "/login/*",
        "/logout/*",
        "/zkau/*"
]

//Plugin AfcQuartz:
grails.plugins.afcquartz.utenteBatch = 'TR4'

// Aggiunti dal AmministrazioneDatabase Plugin:
grails.plugins.amministrazionedatabase.jndiAd4 = "jdbc/ad4"
grails.plugins.amministrazionedatabase.jndiTarget = 'jdbc/tr4' // jndi di connessione all' applicativo
grails.plugins.amministrazionedatabase.modulo = 'TR4' // codice del MODULO AD4 dell'applicativo
grails.plugins.amministrazionedatabase.istanza = 'TR4' // codice dell'ISTANZA AD4 dell'applicativo

// Aggiunti dal AnagrafeSoggetti Plugin:
grails.plugins.anagrafesoggetti.dbUser.abilitato = false
grails.plugins.anagrafesoggetti.jndiAs4 = 'jdbc/as4' // jndi di connessione ad AS4

// Aggiunti dal StrutturaOrganizzativa Plugin:
grails.plugins.strutturaorganizzativa.dbUser.abilitato = false
grails.plugins.strutturaorganizzativa.jndiSo4 = 'jdbc/so4' // jndi di connessione ad SO4
grails.plugins.strutturaorganizzativa.urlSceltaEnte = '/multiEnte' // url a cui redirigere per la scelta dell'ente.
grails.plugins.strutturaorganizzativa.multiEnte.abilitato = false // indica se abilitare o meno il multi-ente.
grails.plugins.strutturaorganizzativa.multiEnte.nomeFiltro = 'multiEnteFilter' // nome del filtro hibernate da abilitare.
grails.plugins.strutturaorganizzativa.multiEnte.nomeParametro = 'enteCorrente' // url a cui redirigere per la scelta dell'ente.

// configurazione del plugin dto:
grails.plugins.dto.suffix = "DTO"
grails.plugins.dto.exclude = ["it.finmatica.so4.struttura.So4Componente", "it.finmatica.so4.struttura.So4RuoloComponente", "it.finmatica.so4.struttura.So4AttrComponente"]
grails.plugins.dto.packageMappings = ["it.finmatica.ad4"  : "it.finmatica.ad4.dto"
                                      , "it.finmatica.as4": "it.finmatica.as4.dto"
                                      , "it.finmatica.so4": "it.finmatica.so4.dto"
                                      , "it.finmatica.tr4": "it.finmatica.tr4.dto"]


grails.naming.entries = ['jdbc/tr4': [type           : "javax.sql.DataSource",
                                      auth           : "Container",
                                      description    : "Data source for TR4",

                                      /* Sviluppo */
                                      url            : "jdbc:oracle:thin:@//svi-detr-fin-db19.finmatica.local:1521/p_detr_svi01",
                                      username       : "TR4",
                                      password       : "tr4",

                                      /* Test
                                      url            : "jdbc:oracle:thin:@tst-detr-fin-db11:1521:testpal",
                                      username       : "tr4test",
                                      password       : "tr4test",
                                      */

                                      /* tst-tr-fin-as1 DB
                                      url            : "jdbc:oracle:thin:@tst-detr-fin-db11:1521:ORCL",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Test performance
                                      url: 			"jdbc:oracle:thin:@tst-tr-fin-db:1521:orcl",
                                      username: 		"TR4",
                                      password: 		"tr4",
                                      */

                                      /* Castelnuovo di Garfagnana
                                      url: 			"jdbc:oracle:thin:@10.30.37.2:1521:orcl",
                                      username: 		"tr4",
                                      password: 		"tr4",
                                      */

                                      /* S.Donato
                                      url: 			"jdbc:oracle:thin:@10.27.182.27:1521:orcl",
                                      username: 		"TR4_bon",
                                      password: 		"tr4_bon",
                                      */

                                      /* Codigoro
                                      url            : "jdbc:oracle:thin:@10.27.187.121:1521:orcl",
                                      username       : "TR4_bon",
                                      password       : "tr4_bon",
                                      */

                                      /* Reggello
                                      url            : "jdbc:oracle:thin:@10.220.87.1:1521:A2004194",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Valeggio
                                      url            : "jdbc:oracle:thin:@10.220.225.1:1521:A2005380",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Cittadella
                                      url: 			"jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=10.220.77.1)(PORT=1521))(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME=A2005010)))",
                                      username: 		"tr4",
                                      password: 		"tr4",
                                      */

                                      /* Belluno
                                      url            : "jdbc:oracle:thin:@10.220.67.1:1521:A2005000",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Porto Mantovano
                                      url            : "jdbc:oracle:thin:@10.27.69.1:1521:c",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Casalgrande
                                      url            : "jdbc:oracle:thin:@10.27.147.101:1521:CSG",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* San Gimignano
                                      url            : "jdbc:oracle:thin:@10.27.54.200:1521:orcl",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Dosolo
                                      url: 			"jdbc:oracle:thin:@10.30.48.2:1521:orcl",
                                      username: 		"tr4",
                                      password: 		"tr4",
                                      */

                                      /* Rubiera
                                      url            : "jdbc:oracle:thin:@10.27.147.101:1521:rub",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* San Lazzaro
                                      url            : "jdbc:oracle:thin:@10.27.21.52:1521:slazz",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Occhiobello
                                      url            : "jdbc:oracle:thin:@10.27.133.10:1521:orcl",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Sabbioneta
                                      url            : "jdbc:oracle:thin:@10.210.205.1:1521:orcl",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Palau
                                      url            : "jdbc:oracle:thin:@DB-2107539-001.cloud.finmatica:1521:A2107539",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Careggine
                                      url: 			"jdbc:oracle:thin:@10.30.37.2:1521:orcl",
                                      username: 		"tr4car",
                                      password: 		"tr4car",
                                      */

                                      /* Livorno
                                      url: 			"jdbc:oracle:thin:@10.27.103.2:1521:orcl",
                                      username: 		"tr4",
                                      password: 		"tr4",
                                      */

                                      /* Castelfiorentino
                                      url            : "jdbc:oracle:thin:@10.220.206.1:1521:A2004150",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Pontedera
                                      url            : "jdbc:oracle:thin:@10.27.162.9:1521:C",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Bovezzo
                                      url            : "jdbc:oracle:thin:@10.220.82.1:1521:A2003045",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Bagheria
                                      url            : "jdbc:oracle:thin:@10.30.51.1:1521:ORCL",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Pioltello
                                      url            : "jdbc:oracle:thin:@db-2003235-001.cloud.finmatica:1521:A2003235",
                                      username       : "TR4",
                                      password       : "tr4",
                                      */

                                      /* Malnate
                                      url            : "jdbc:oracle:thin:@DB-2003444-001.cloud.finmatica:1521:A2003444",
                                      username       : "TR4mal",
                                      password       : "tr4mal",
                                      */

                                      /* Sant'Antioco
                                      url            : "jdbc:oracle:thin:@db-2106002-001.cloud.finmatica:1521:A2106002",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Frosinone
                                      url            : "jdbc:oracle:thin:@db-2101558-001.cloud.finmatica:1521:A2101558",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Carloforte
                                      url            : "jdbc:oracle:thin:@10.220.199.1:1521:A2110888",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Albano
                                      url            : "jdbc:oracle:thin:@10.220.105.1:1521:A2003400",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Bovezzo
                                      url            : "jdbc:oracle:thin:@db-2003045-001.cloud.finmatica:1521/A2003045",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Trezzano
                                      url            : "jdbc:oracle:thin:@db-2003291-001.cloud.finmatica:1521:A2003291",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Bovezzo
                                      url            : "jdbc:oracle:thin:@10.220.82.1:1521:A2003045",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Provincia di Como
                                      url            : "jdbc:oracle:thin:@172.16.10.65:1521:ORA817",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Borgosatollo
                                      url            : "jdbc:oracle:thin:@db-2003030-001.cloud.finmatica:1521:A2003030",
                                      username       : "tr4",
                                      password       : "tr4",
                                      */

                                      /* Induno
                                      url            : "jdbc:oracle:thin:@db-2003444-001.cloud.finmatica:1521:B2003444",
                                      username       : "tr4ind",
                                      password       : "tr4ind",
                                      */

                                      driverClassName: "oracle.jdbc.driver.OracleDriver",
                                      maxActive      : "100",
                                      maxIdle        : "100"],
                         'jdbc/ad4': [type           : "javax.sql.DataSource",
                                      auth           : "Container",
                                      description    : "Data source for AD4",
                                      url            : "jdbc:oracle:thin:@//svi-detr-fin-db19.finmatica.local:1521/p_detr_svi01",
                                      username       : "ad4",
                                      password       : "ad4",
                                      driverClassName: "oracle.jdbc.driver.OracleDriver",
                                      maxActive      : "100",
                                      maxIdle        : "100"],
                         'jdbc/as4': [type           : "javax.sql.DataSource",
                                      auth           : "Container",
                                      description    : "Data source for AS4",
                                      url            : "jdbc:oracle:thin:@//svi-detr-fin-db19.finmatica.local:1521/p_detr_svi01",
                                      username       : "as4",
                                      password       : "as4",
                                      driverClassName: "oracle.jdbc.driver.OracleDriver",
                                      maxActive      : "100",
                                      maxIdle        : "100"],
                         'jdbc/so4': [type           : "javax.sql.DataSource",
                                      auth           : "Container",
                                      description    : "Data source for SO4",
                                      url            : "jdbc:oracle:thin:@//svi-detr-fin-db19.finmatica.local:1521/p_detr_svi01",
                                      username       : "so4",
                                      password       : "so4",
                                      driverClassName: "oracle.jdbc.driver.OracleDriver",
                                      maxActive      : "100",
                                      maxIdle        : "100"]]
