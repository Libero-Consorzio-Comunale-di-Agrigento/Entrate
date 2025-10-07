package it.finmatica.tr4

import org.hibernate.HibernateException
import org.hibernate.MappingException
import org.hibernate.dialect.Dialect
import org.hibernate.engine.SessionImplementor
import org.hibernate.id.Configurable
import org.hibernate.id.IdentifierGenerator
import org.hibernate.type.Type

import java.sql.CallableStatement
import java.sql.Connection
import java.sql.SQLException
import java.sql.Types

class NrIdGenerator implements IdentifierGenerator, Configurable {

    private String storedProcedure
    private String tableName

    @Override
    Serializable generate(SessionImplementor sessionImplementor, Object o) throws HibernateException {
        Long result = null;
        try {

            Connection connection = sessionImplementor.connection()
            CallableStatement callableStmt = connection.prepareCall(storedProcedure)
            callableStmt.registerOutParameter("A_NR", Types.BIGINT)

            if (tableName) {
                callableStmt.setString("A_TABELLA", tableName)
            }

            callableStmt.executeQuery()
            result = callableStmt.getLong("A_NR")
            connection.close()
            callableStmt.close()
        } catch (SQLException sqlException) {
            throw new HibernateException(sqlException)
        }
        return result;
    }

    @Override
    void configure(Type type, Properties properties, Dialect dialect) throws MappingException {
        storedProcedure = properties.getProperty("storedProcedure")
        tableName = properties.getProperty("tableName")
        if (!storedProcedure) {
            throw new RuntimeException("Definire il nome della procedura.")
        } else {
            storedProcedure = "call " + storedProcedure + (tableName ? "(?, ?)" : "(?)")
        }
    }
}
