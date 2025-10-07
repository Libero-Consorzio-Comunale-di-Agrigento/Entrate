package it.finmatica.utility

import net.sf.jasperreports.engine.JRDataSource
import net.sf.jasperreports.engine.JRException
import net.sf.jasperreports.engine.JRField

class MapDataSource implements JRDataSource {

    private Collection<?> data
    private Iterator<?> iterator
    private Object currentBean

    MapDataSource(Collection<?> data) {
        this.data = data
        if (this.data != null) {
            this.iterator = this.data.iterator()
        }
    }

    @Override
    boolean next() throws JRException {
        boolean hasNext = false;
        if (this.iterator != null) {
            hasNext = this.iterator.hasNext();
            if (hasNext) {
                this.currentBean = this.iterator.next();
            }
        }

        return hasNext;
    }

    @Override
    Object getFieldValue(JRField jrField) throws JRException {
        return currentBean[jrField.name]
    }

    public void moveFirst() {
        if (this.data != null) {
            this.iterator = this.data.iterator();
        }

    }

    public Collection<?> getData() {
        return this.data;
    }

    public int getRecordCount() {
        return this.data == null ? 0 : this.data.size();
    }
}
