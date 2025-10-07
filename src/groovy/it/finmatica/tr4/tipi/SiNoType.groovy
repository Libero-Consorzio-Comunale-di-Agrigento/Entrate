package it.finmatica.tr4.tipi

import java.sql.PreparedStatement
import java.sql.ResultSet
import java.sql.SQLException
import java.sql.Types

import org.hibernate.HibernateException
import org.hibernate.usertype.EnhancedUserType;
import org.hibernate.usertype.UserType
/*
class SiNoType extends  YesNoType {
	
	public String objectToSQLString(Boolean value, Dialect dialect) throws Exception {
		println value
		return StringType.INSTANCE.objectToSQLString( value?.booleanValue() ? "S" : "N", dialect )
	}
}
*/

class SiNoType implements UserType, EnhancedUserType {
	
	@Override
	public Object assemble(Serializable arg0, Object arg1)
			throws HibernateException {
		arg0
	}

	@Override
	public Object deepCopy(Object arg0) throws HibernateException {
		arg0
	}

	@Override
	public Serializable disassemble(Object arg0) throws HibernateException {
		arg0
	}

	@Override
	public boolean equals(Object arg0, Object arg1) throws HibernateException {
		arg0 == arg1
	}

	@Override
	public int hashCode(Object arg0) throws HibernateException {
		arg0.hashCode()
	}

	@Override
	public boolean isMutable() {
		false
	}

	@Override
	public Object nullSafeGet(ResultSet set, String[] names, Object owner)
			throws HibernateException, SQLException {
		
		String sn = set.getString(names[0])
		if (sn == null || sn.equals("N")) { 
			return false		
		} else {
			return true
		}
	}

	@Override
	public void nullSafeSet(PreparedStatement statement, Object value, int index)
			throws HibernateException, SQLException {
		value? statement.setString(index, "S") : statement.setString(index, "")
	}

	@Override
	public Object replace(Object arg0, Object arg1, Object arg2)
			throws HibernateException {
		arg0		
	}

	@Override
	public Class returnedClass() {
		boolean.class
	}

	@Override
	public int[] sqlTypes() {
		// TODO Auto-generated method stub
		return Types.VARCHAR
	}
	
	// TODO: gestire le funzioni per utilizzare il boolean in hql 
	@Override
	public Object fromXMLString(String arg0) {
		// TODO Auto-generated method stub
		println "fromXMLString " + arg0;
		return null;
	}

	@Override
	public String objectToSQLString(Object value) {
		// TODO Auto-generated method stub
		println "objectToSQLString " + value;
		value? "'S'" : null;
	}

	@Override
	public String toXMLString(Object arg0) {
		println "toXMLString " + arg0;
		// TODO Auto-generated method stub
		return null;
	}

}
