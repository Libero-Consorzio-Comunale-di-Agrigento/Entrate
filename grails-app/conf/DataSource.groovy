import org.grails.plugin.hibernate.filter.HibernateFilterDomainConfiguration;

dataSource {
	pooled  = false
//	dialect = 'org.hibernate.dialect.Oracle9iDialect'
	dialect = 'it.finmatica.tr4.dialect.TributiOracleDialect'
	configClass = HibernateFilterDomainConfiguration
//	configClass = it.finmatica.utility.legacydb.MyCustomGrailsAnnotationConfiguration
}

hibernate {
	cache.use_second_level_cache = false
	cache.use_query_cache = true
	cache.provider_class = 'net.sf.ehcache.hibernate.EhCacheProvider'
}

//hibernate.default_schema = "TR4"

// environment specific settings
environments {
    development {
        dataSource {
			//dbCreate = "validate"
			jndiName = "java:comp/env/jdbc/tr4"
//			driverClassName = "oracle.jdbc.driver.OracleDriver"
//            url = "jdbc:oracle:thin:@galles:1521:pal"
//			username = "TR4"
//			password = "tr4"
			logSql = true
			formatSql = false
        }
    }
    test {
        dataSource {
            dbCreate="none"
			//dbCreate = "validate"
			jndiName = "java:comp/env/jdbc/tr4"
//			driverClassName = "oracle.jdbc.driver.OracleDriver"
//            url = "jdbc:oracle:thin:@galles:1521:pal"
//			username = "TR4"
//			password = "tr4"
//			logSql = true
        }
    }
    production {
        dataSource {
            dbCreate="none"
			//dbCreate = "validate"
			jndiName = "java:comp/env/jdbc/tr4"
//			driverClassName = "oracle.jdbc.driver.OracleDriver"
//            url = "jdbc:oracle:thin:@galles:1521:pal"
//			username = "TR4"
//			password = "tr4"
        }
    }
}
