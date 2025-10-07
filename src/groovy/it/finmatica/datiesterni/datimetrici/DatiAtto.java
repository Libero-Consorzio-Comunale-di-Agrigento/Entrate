
package it.finmatica.datiesterni.datimetrici;

import javax.xml.bind.annotation.*;


/**
 * <p>Java class for anonymous complex type.
 *
 * <p>The following schema fragment specifies the expected content contained within this class.
 *
 * <pre>
 * &lt;complexType>
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="SedeRogante" minOccurs="0">
 *           &lt;simpleType>
 *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *               &lt;length value="4"/>
 *             &lt;/restriction>
 *           &lt;/simpleType>
 *         &lt;/element>
 *         &lt;element name="Data" minOccurs="0">
 *           &lt;simpleType>
 *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *               &lt;length value="8"/>
 *             &lt;/restriction>
 *           &lt;/simpleType>
 *         &lt;/element>
 *         &lt;element name="Repertorio" minOccurs="0">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="Numero" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="Raccolta" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                 &lt;/sequence>
 *               &lt;/restriction>
 *             &lt;/complexContent>
 *           &lt;/complexType>
 *         &lt;/element>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "", propOrder = {
        "sedeRogante",
        "data",
        "repertorio"
})
@XmlRootElement(name = "DatiAtto", namespace = "http://")
public class DatiAtto {

    @XmlElement(name = "SedeRogante", namespace = "http://")
    protected String sedeRogante;
    @XmlElement(name = "Data", namespace = "http://")
    protected String data;
    @XmlElement(name = "Repertorio", namespace = "http://")
    protected DatiAtto.Repertorio repertorio;

    /**
     * Gets the value of the sedeRogante property.
     *
     * @return possible object is
     * {@link String }
     */
    public String getSedeRogante() {
        return sedeRogante;
    }

    /**
     * Sets the value of the sedeRogante property.
     *
     * @param value allowed object is
     *              {@link String }
     */
    public void setSedeRogante(String value) {
        this.sedeRogante = value;
    }

    /**
     * Gets the value of the data property.
     *
     * @return possible object is
     * {@link String }
     */
    public String getData() {
        return data;
    }

    /**
     * Sets the value of the data property.
     *
     * @param value allowed object is
     *              {@link String }
     */
    public void setData(String value) {
        this.data = value;
    }

    /**
     * Gets the value of the repertorio property.
     *
     * @return possible object is
     * {@link DatiAtto.Repertorio }
     */
    public DatiAtto.Repertorio getRepertorio() {
        return repertorio;
    }

    /**
     * Sets the value of the repertorio property.
     *
     * @param value allowed object is
     *              {@link DatiAtto.Repertorio }
     */
    public void setRepertorio(DatiAtto.Repertorio value) {
        this.repertorio = value;
    }


    /**
     * <p>Java class for anonymous complex type.
     *
     * <p>The following schema fragment specifies the expected content contained within this class.
     *
     * <pre>
     * &lt;complexType>
     *   &lt;complexContent>
     *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *       &lt;sequence>
     *         &lt;element name="Numero" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="Raccolta" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *       &lt;/sequence>
     *     &lt;/restriction>
     *   &lt;/complexContent>
     * &lt;/complexType>
     * </pre>
     */
    @XmlAccessorType(XmlAccessType.FIELD)
    @XmlType(name = "", propOrder = {
            "numero",
            "raccolta"
    })
    public static class Repertorio {

        @XmlElement(name = "Numero", namespace = "http://")
        protected Integer numero;
        @XmlElement(name = "Raccolta", namespace = "http://")
        protected Integer raccolta;

        /**
         * Gets the value of the numero property.
         *
         * @return possible object is
         * {@link Integer }
         */
        public Integer getNumero() {
            return numero;
        }

        /**
         * Sets the value of the numero property.
         *
         * @param value allowed object is
         *              {@link Integer }
         */
        public void setNumero(Integer value) {
            this.numero = value;
        }

        /**
         * Gets the value of the raccolta property.
         *
         * @return possible object is
         * {@link Integer }
         */
        public Integer getRaccolta() {
            return raccolta;
        }

        /**
         * Sets the value of the raccolta property.
         *
         * @param value allowed object is
         *              {@link Integer }
         */
        public void setRaccolta(Integer value) {
            this.raccolta = value;
        }

    }

}
