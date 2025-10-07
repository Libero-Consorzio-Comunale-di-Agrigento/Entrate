
package it.finmatica.datiesterni.datimetrici;

import javax.xml.bind.annotation.*;
import javax.xml.datatype.XMLGregorianCalendar;
import java.io.Serializable;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;


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
 *         &lt;element name="DatiRichiesta">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="Iscrizione" type="{http://www.w3.org/2001/XMLSchema}string"/>
 *                   &lt;element name="DataIniziale" type="{http://www.w3.org/2001/XMLSchema}date"/>
 *                   &lt;element name="N_File" type="{http://www.w3.org/2001/XMLSchema}positiveInteger"/>
 *                   &lt;element name="N_File_Tot" type="{http://www.w3.org/2001/XMLSchema}positiveInteger"/>
 *                 &lt;/sequence>
 *               &lt;/restriction>
 *             &lt;/complexContent>
 *           &lt;/complexType>
 *         &lt;/element>
 *         &lt;element name="Comune">
 *           &lt;simpleType>
 *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *               &lt;maxLength value="4"/>
 *             &lt;/restriction>
 *           &lt;/simpleType>
 *         &lt;/element>
 *         &lt;element name="Uiu" maxOccurs="unbounded">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="SezCens" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                         &lt;length value="1"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="IdUiu">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
 *                         &lt;totalDigits value="9"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="Prog" type="{http://www.w3.org/2001/XMLSchema}anyType"/>
 *                   &lt;element name="Categoria" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                         &lt;length value="3"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="BeneComune" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                         &lt;totalDigits value="1"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="Superficie" minOccurs="0">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                         &lt;totalDigits value="9"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="EsitiAgenzia" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="EsitoSup" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="EsitoAgg" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="2"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="EsitiComune" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="Riscontro">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
 *                                   &lt;totalDigits value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Istanza" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
 *                                   &lt;totalDigits value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="RichiestaPlan" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
 *                                   &lt;totalDigits value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="Identificativo" maxOccurs="unbounded">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="SezUrb" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="3"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Foglio">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Numero">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="5"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Denominatore" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Sub" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Edificialita" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="Indirizzo" maxOccurs="4" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="CodTopo">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="3"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Toponimo">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="16"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Denom">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="50"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Codice" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="5"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Civico" maxOccurs="3" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="6"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Fonte" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Delibera" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="70"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Localita" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="30"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Km" type="{http://www.w3.org/2001/XMLSchema}decimal" minOccurs="0"/>
 *                             &lt;element name="CAP" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="5"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="Ubicazione" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="Lotto" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="2"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Edificio" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="2"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Scala" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="2"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Interno" maxOccurs="2" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="3"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Piano" maxOccurs="4" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="DatiMetrici" maxOccurs="unbounded" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="Ambiente">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="1"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="SuperficieA">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="9"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Altezza" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="AltezzaMax" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="4"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="Soggetti" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="Pf" maxOccurs="unbounded" minOccurs="0">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;sequence>
 *                                       &lt;element name="IdSog">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                             &lt;totalDigits value="9"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Cognome">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="50"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Nome" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="50"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Sesso" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                             &lt;enumeration value="1"/>
 *                                             &lt;enumeration value="2"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="DataNascita" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;length value="8"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Comune" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;length value="4"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="CF" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="16"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
 *                                     &lt;/sequence>
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                             &lt;element name="Pnf" maxOccurs="unbounded" minOccurs="0">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;sequence>
 *                                       &lt;element name="IdSog">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                             &lt;totalDigits value="9"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Denominazione">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="150"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Sede" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;length value="4"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="CF" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="11"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
 *                                     &lt;/sequence>
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                   &lt;element name="DatiNuovi" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence>
 *                             &lt;element name="SuperficieTotale" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="9"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="SuperficieConvenzionale" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                   &lt;totalDigits value="9"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="DataInizioValidita">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="8"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="DataFineValidita" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="8"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="CodiceStradaNazionale" minOccurs="0">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;sequence>
 *                                       &lt;element name="Comune">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;length value="4"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="ProgStrada">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
 *                                             &lt;totalDigits value="7"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                     &lt;/sequence>
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                             &lt;element name="DataCertificazione" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;length value="8"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Provvedimento" minOccurs="0">
 *                               &lt;complexType>
 *                                 &lt;complexContent>
 *                                   &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                                     &lt;sequence>
 *                                       &lt;element name="Data">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;length value="8"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                       &lt;element name="Protocollo" minOccurs="0">
 *                                         &lt;simpleType>
 *                                           &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                             &lt;maxLength value="50"/>
 *                                           &lt;/restriction>
 *                                         &lt;/simpleType>
 *                                       &lt;/element>
 *                                     &lt;/sequence>
 *                                   &lt;/restriction>
 *                                 &lt;/complexContent>
 *                               &lt;/complexType>
 *                             &lt;/element>
 *                             &lt;element name="CodiceStradaComunale" minOccurs="0">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="30"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
 *                   &lt;/element>
 *                 &lt;/sequence>
 *               &lt;/restriction>
 *             &lt;/complexContent>
 *           &lt;/complexType>
 *         &lt;/element>
 *         &lt;element name="Riepilogo" minOccurs="0">
 *           &lt;complexType>
 *             &lt;complexContent>
 *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                 &lt;sequence>
 *                   &lt;element name="DataEstrazione">
 *                     &lt;simpleType>
 *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                         &lt;length value="8"/>
 *                       &lt;/restriction>
 *                     &lt;/simpleType>
 *                   &lt;/element>
 *                   &lt;element name="TotaleUiu" type="{http://www.w3.org/2001/XMLSchema}int"/>
 *                   &lt;element name="Quadratura" minOccurs="0">
 *                     &lt;complexType>
 *                       &lt;complexContent>
 *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *                           &lt;sequence maxOccurs="unbounded">
 *                             &lt;element name="Tipo">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
 *                                   &lt;maxLength value="3"/>
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                             &lt;element name="Valore">
 *                               &lt;simpleType>
 *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
 *                                 &lt;/restriction>
 *                               &lt;/simpleType>
 *                             &lt;/element>
 *                           &lt;/sequence>
 *                         &lt;/restriction>
 *                       &lt;/complexContent>
 *                     &lt;/complexType>
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
        "datiRichiesta",
        "comune",
        "uiu",
        "riepilogo"
})
@XmlRootElement(name = "DatiOut", namespace = "http://")
public class DatiOut {

    @XmlElement(name = "DatiRichiesta", namespace = "http://", required = true)
    protected DatiOut.DatiRichiesta datiRichiesta;
    @XmlElement(name = "Comune", namespace = "http://", required = true)
    protected String comune;
    @XmlElement(name = "Uiu", namespace = "http://", required = true)
    protected List<Uiu> uiu;
    @XmlElement(name = "Riepilogo", namespace = "http://")
    protected DatiOut.Riepilogo riepilogo;

    /**
     * Gets the value of the datiRichiesta property.
     *
     * @return possible object is
     * {@link DatiOut.DatiRichiesta }
     */
    public DatiOut.DatiRichiesta getDatiRichiesta() {
        return datiRichiesta;
    }

    /**
     * Sets the value of the datiRichiesta property.
     *
     * @param value allowed object is
     *              {@link DatiOut.DatiRichiesta }
     */
    public void setDatiRichiesta(DatiOut.DatiRichiesta value) {
        this.datiRichiesta = value;
    }

    /**
     * Gets the value of the comune property.
     *
     * @return possible object is
     * {@link String }
     */
    public String getComune() {
        return comune;
    }

    /**
     * Sets the value of the comune property.
     *
     * @param value allowed object is
     *              {@link String }
     */
    public void setComune(String value) {
        this.comune = value;
    }

    /**
     * Gets the value of the uiu property.
     *
     * <p>
     * This accessor method returns a reference to the live list,
     * not a snapshot. Therefore any modification you make to the
     * returned list will be present inside the JAXB object.
     * This is why there is not a <CODE>set</CODE> method for the uiu property.
     *
     * <p>
     * For example, to add a new item, do as follows:
     * <pre>
     *    getUiu().add(newItem);
     * </pre>
     *
     *
     * <p>
     * Objects of the following type(s) are allowed in the list
     * {@link DatiOut.Uiu }
     */
    public List<Uiu> getUiu() {
        if (uiu == null) {
            uiu = new ArrayList<Uiu>();
        }
        return this.uiu;
    }

    /**
     * Gets the value of the riepilogo property.
     *
     * @return possible object is
     * {@link DatiOut.Riepilogo }
     */
    public DatiOut.Riepilogo getRiepilogo() {
        return riepilogo;
    }

    /**
     * Sets the value of the riepilogo property.
     *
     * @param value allowed object is
     *              {@link DatiOut.Riepilogo }
     */
    public void setRiepilogo(DatiOut.Riepilogo value) {
        this.riepilogo = value;
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
     *         &lt;element name="Iscrizione" type="{http://www.w3.org/2001/XMLSchema}string"/>
     *         &lt;element name="DataIniziale" type="{http://www.w3.org/2001/XMLSchema}date"/>
     *         &lt;element name="N_File" type="{http://www.w3.org/2001/XMLSchema}positiveInteger"/>
     *         &lt;element name="N_File_Tot" type="{http://www.w3.org/2001/XMLSchema}positiveInteger"/>
     *       &lt;/sequence>
     *     &lt;/restriction>
     *   &lt;/complexContent>
     * &lt;/complexType>
     * </pre>
     */
    @XmlAccessorType(XmlAccessType.FIELD)
    @XmlType(name = "", propOrder = {
            "iscrizione",
            "dataIniziale",
            "nFile",
            "nFileTot"
    })
    public static class DatiRichiesta {

        @XmlElement(name = "Iscrizione", namespace = "http://", required = true)
        protected String iscrizione;
        @XmlElement(name = "DataIniziale", namespace = "http://", required = true)
        @XmlSchemaType(name = "date")
        protected XMLGregorianCalendar dataIniziale;
        @XmlElement(name = "N_File", namespace = "http://", required = true)
        @XmlSchemaType(name = "positiveInteger")
        protected BigInteger nFile;
        @XmlElement(name = "N_File_Tot", namespace = "http://", required = true)
        @XmlSchemaType(name = "positiveInteger")
        protected BigInteger nFileTot;

        /**
         * Gets the value of the iscrizione property.
         *
         * @return possible object is
         * {@link String }
         */
        public String getIscrizione() {
            return iscrizione;
        }

        /**
         * Sets the value of the iscrizione property.
         *
         * @param value allowed object is
         *              {@link String }
         */
        public void setIscrizione(String value) {
            this.iscrizione = value;
        }

        /**
         * Gets the value of the dataIniziale property.
         *
         * @return possible object is
         * {@link XMLGregorianCalendar }
         */
        public XMLGregorianCalendar getDataIniziale() {
            return dataIniziale;
        }

        /**
         * Sets the value of the dataIniziale property.
         *
         * @param value allowed object is
         *              {@link XMLGregorianCalendar }
         */
        public void setDataIniziale(XMLGregorianCalendar value) {
            this.dataIniziale = value;
        }

        /**
         * Gets the value of the nFile property.
         *
         * @return possible object is
         * {@link BigInteger }
         */
        public BigInteger getNFile() {
            return nFile;
        }

        /**
         * Sets the value of the nFile property.
         *
         * @param value allowed object is
         *              {@link BigInteger }
         */
        public void setNFile(BigInteger value) {
            this.nFile = value;
        }

        /**
         * Gets the value of the nFileTot property.
         *
         * @return possible object is
         * {@link BigInteger }
         */
        public BigInteger getNFileTot() {
            return nFileTot;
        }

        /**
         * Sets the value of the nFileTot property.
         *
         * @param value allowed object is
         *              {@link BigInteger }
         */
        public void setNFileTot(BigInteger value) {
            this.nFileTot = value;
        }

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
     *         &lt;element name="DataEstrazione">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *               &lt;length value="8"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="TotaleUiu" type="{http://www.w3.org/2001/XMLSchema}int"/>
     *         &lt;element name="Quadratura" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence maxOccurs="unbounded">
     *                   &lt;element name="Tipo">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="3"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Valore">
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
            "dataEstrazione",
            "totaleUiu",
            "quadratura"
    })
    public static class Riepilogo {

        @XmlElement(name = "DataEstrazione", namespace = "http://", required = true)
        protected String dataEstrazione;
        @XmlElement(name = "TotaleUiu", namespace = "http://")
        protected int totaleUiu;
        @XmlElement(name = "Quadratura", namespace = "http://")
        protected DatiOut.Riepilogo.Quadratura quadratura;

        /**
         * Gets the value of the dataEstrazione property.
         *
         * @return possible object is
         * {@link String }
         */
        public String getDataEstrazione() {
            return dataEstrazione;
        }

        /**
         * Sets the value of the dataEstrazione property.
         *
         * @param value allowed object is
         *              {@link String }
         */
        public void setDataEstrazione(String value) {
            this.dataEstrazione = value;
        }

        /**
         * Gets the value of the totaleUiu property.
         */
        public int getTotaleUiu() {
            return totaleUiu;
        }

        /**
         * Sets the value of the totaleUiu property.
         */
        public void setTotaleUiu(int value) {
            this.totaleUiu = value;
        }

        /**
         * Gets the value of the quadratura property.
         *
         * @return possible object is
         * {@link DatiOut.Riepilogo.Quadratura }
         */
        public DatiOut.Riepilogo.Quadratura getQuadratura() {
            return quadratura;
        }

        /**
         * Sets the value of the quadratura property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Riepilogo.Quadratura }
         */
        public void setQuadratura(DatiOut.Riepilogo.Quadratura value) {
            this.quadratura = value;
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
         *       &lt;sequence maxOccurs="unbounded">
         *         &lt;element name="Tipo">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="3"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Valore">
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
                "tipoAndValore"
        })
        public static class Quadratura {

            @XmlElements({
                    @XmlElement(name = "Tipo", namespace = "http://", required = true, type = String.class),
                    @XmlElement(name = "Valore", namespace = "http://", required = true, type = Integer.class)
            })
            protected List<Serializable> tipoAndValore;

            /**
             * Gets the value of the tipoAndValore property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the tipoAndValore property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getTipoAndValore().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link String }
             * {@link Integer }
             */
            public List<Serializable> getTipoAndValore() {
                if (tipoAndValore == null) {
                    tipoAndValore = new ArrayList<Serializable>();
                }
                return this.tipoAndValore;
            }

        }

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
     *         &lt;element name="SezCens" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *               &lt;length value="1"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="IdUiu">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
     *               &lt;totalDigits value="9"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="Prog" type="{http://www.w3.org/2001/XMLSchema}anyType"/>
     *         &lt;element name="Categoria" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *               &lt;length value="3"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="BeneComune" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *               &lt;totalDigits value="1"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="Superficie" minOccurs="0">
     *           &lt;simpleType>
     *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *               &lt;totalDigits value="9"/>
     *             &lt;/restriction>
     *           &lt;/simpleType>
     *         &lt;/element>
     *         &lt;element name="EsitiAgenzia" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="EsitoSup" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="EsitoAgg" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="2"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="EsitiComune" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="Riscontro">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
     *                         &lt;totalDigits value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Istanza" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
     *                         &lt;totalDigits value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="RichiestaPlan" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
     *                         &lt;totalDigits value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="Identificativo" maxOccurs="unbounded">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="SezUrb" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="3"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Foglio">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Numero">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="5"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Denominatore" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Sub" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Edificialita" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="Indirizzo" maxOccurs="4" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="CodTopo">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="3"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Toponimo">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="16"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Denom">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="50"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Codice" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="5"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Civico" maxOccurs="3" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="6"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Fonte" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Delibera" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="70"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Localita" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="30"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Km" type="{http://www.w3.org/2001/XMLSchema}decimal" minOccurs="0"/>
     *                   &lt;element name="CAP" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="5"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="Ubicazione" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="Lotto" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="2"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Edificio" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="2"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Scala" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="2"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Interno" maxOccurs="2" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="3"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Piano" maxOccurs="4" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="DatiMetrici" maxOccurs="unbounded" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="Ambiente">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="1"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="SuperficieA">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="9"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Altezza" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="AltezzaMax" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="4"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="Soggetti" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="Pf" maxOccurs="unbounded" minOccurs="0">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;sequence>
     *                             &lt;element name="IdSog">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                                   &lt;totalDigits value="9"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Cognome">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="50"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Nome" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="50"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Sesso" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                                   &lt;enumeration value="1"/>
     *                                   &lt;enumeration value="2"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="DataNascita" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;length value="8"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Comune" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;length value="4"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="CF" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="16"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
     *                           &lt;/sequence>
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                   &lt;element name="Pnf" maxOccurs="unbounded" minOccurs="0">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;sequence>
     *                             &lt;element name="IdSog">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                                   &lt;totalDigits value="9"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Denominazione">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="150"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Sede" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;length value="4"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="CF" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="11"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
     *                           &lt;/sequence>
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                 &lt;/sequence>
     *               &lt;/restriction>
     *             &lt;/complexContent>
     *           &lt;/complexType>
     *         &lt;/element>
     *         &lt;element name="DatiNuovi" minOccurs="0">
     *           &lt;complexType>
     *             &lt;complexContent>
     *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                 &lt;sequence>
     *                   &lt;element name="SuperficieTotale" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="9"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="SuperficieConvenzionale" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
     *                         &lt;totalDigits value="9"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="DataInizioValidita">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="8"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="DataFineValidita" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="8"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="CodiceStradaNazionale" minOccurs="0">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;sequence>
     *                             &lt;element name="Comune">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;length value="4"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="ProgStrada">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
     *                                   &lt;totalDigits value="7"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                           &lt;/sequence>
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                   &lt;element name="DataCertificazione" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;length value="8"/>
     *                       &lt;/restriction>
     *                     &lt;/simpleType>
     *                   &lt;/element>
     *                   &lt;element name="Provvedimento" minOccurs="0">
     *                     &lt;complexType>
     *                       &lt;complexContent>
     *                         &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
     *                           &lt;sequence>
     *                             &lt;element name="Data">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;length value="8"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                             &lt;element name="Protocollo" minOccurs="0">
     *                               &lt;simpleType>
     *                                 &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                                   &lt;maxLength value="50"/>
     *                                 &lt;/restriction>
     *                               &lt;/simpleType>
     *                             &lt;/element>
     *                           &lt;/sequence>
     *                         &lt;/restriction>
     *                       &lt;/complexContent>
     *                     &lt;/complexType>
     *                   &lt;/element>
     *                   &lt;element name="CodiceStradaComunale" minOccurs="0">
     *                     &lt;simpleType>
     *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
     *                         &lt;maxLength value="30"/>
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
            "sezCens",
            "idUiu",
            "prog",
            "categoria",
            "beneComune",
            "superficie",
            "esitiAgenzia",
            "esitiComune",
            "identificativo",
            "indirizzo",
            "ubicazione",
            "datiMetrici",
            "soggetti",
            "datiNuovi"
    })
    public static class Uiu {

        @XmlElement(name = "SezCens", namespace = "http://")
        protected String sezCens;
        @XmlElement(name = "IdUiu", namespace = "http://", required = true)
        protected BigInteger idUiu;
        @XmlElement(name = "Prog", namespace = "http://", required = true)
        protected Integer prog;
        @XmlElement(name = "Categoria", namespace = "http://")
        protected String categoria;
        @XmlElement(name = "BeneComune", namespace = "http://")
        protected Integer beneComune;
        @XmlElement(name = "Superficie", namespace = "http://")
        protected Integer superficie;
        @XmlElement(name = "EsitiAgenzia", namespace = "http://")
        protected DatiOut.Uiu.EsitiAgenzia esitiAgenzia;
        @XmlElement(name = "EsitiComune", namespace = "http://")
        protected DatiOut.Uiu.EsitiComune esitiComune;
        @XmlElement(name = "Identificativo", namespace = "http://", required = true)
        protected List<Identificativo> identificativo;
        @XmlElement(name = "Indirizzo", namespace = "http://")
        protected List<Indirizzo> indirizzo;
        @XmlElement(name = "Ubicazione", namespace = "http://")
        protected DatiOut.Uiu.Ubicazione ubicazione;
        @XmlElement(name = "DatiMetrici", namespace = "http://")
        protected List<DatiMetrici> datiMetrici;
        @XmlElement(name = "Soggetti", namespace = "http://")
        protected DatiOut.Uiu.Soggetti soggetti;
        @XmlElement(name = "DatiNuovi", namespace = "http://")
        protected DatiOut.Uiu.DatiNuovi datiNuovi;

        /**
         * Gets the value of the sezCens property.
         *
         * @return possible object is
         * {@link String }
         */
        public String getSezCens() {
            return sezCens;
        }

        /**
         * Sets the value of the sezCens property.
         *
         * @param value allowed object is
         *              {@link String }
         */
        public void setSezCens(String value) {
            this.sezCens = value;
        }

        /**
         * Gets the value of the idUiu property.
         *
         * @return possible object is
         * {@link BigInteger }
         */
        public BigInteger getIdUiu() {
            return idUiu;
        }

        /**
         * Sets the value of the idUiu property.
         *
         * @param value allowed object is
         *              {@link BigInteger }
         */
        public void setIdUiu(BigInteger value) {
            this.idUiu = value;
        }

        /**
         * Gets the value of the prog property.
         *
         * @return possible object is
         * {@link Object }
         */
        public Integer getProg() {
            return prog;
        }

        /**
         * Sets the value of the prog property.
         *
         * @param value allowed object is
         *              {@link Object }
         */
        public void setProg(Integer value) {
            this.prog = value;
        }

        /**
         * Gets the value of the categoria property.
         *
         * @return possible object is
         * {@link String }
         */
        public String getCategoria() {
            return categoria;
        }

        /**
         * Sets the value of the categoria property.
         *
         * @param value allowed object is
         *              {@link String }
         */
        public void setCategoria(String value) {
            this.categoria = value;
        }

        /**
         * Gets the value of the beneComune property.
         *
         * @return possible object is
         * {@link Integer }
         */
        public Integer getBeneComune() {
            return beneComune;
        }

        /**
         * Sets the value of the beneComune property.
         *
         * @param value allowed object is
         *              {@link Integer }
         */
        public void setBeneComune(Integer value) {
            this.beneComune = value;
        }

        /**
         * Gets the value of the superficie property.
         *
         * @return possible object is
         * {@link Integer }
         */
        public Integer getSuperficie() {
            return superficie;
        }

        /**
         * Sets the value of the superficie property.
         *
         * @param value allowed object is
         *              {@link Integer }
         */
        public void setSuperficie(Integer value) {
            this.superficie = value;
        }

        /**
         * Gets the value of the esitiAgenzia property.
         *
         * @return possible object is
         * {@link DatiOut.Uiu.EsitiAgenzia }
         */
        public DatiOut.Uiu.EsitiAgenzia getEsitiAgenzia() {
            return esitiAgenzia;
        }

        /**
         * Sets the value of the esitiAgenzia property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Uiu.EsitiAgenzia }
         */
        public void setEsitiAgenzia(DatiOut.Uiu.EsitiAgenzia value) {
            this.esitiAgenzia = value;
        }

        /**
         * Gets the value of the esitiComune property.
         *
         * @return possible object is
         * {@link DatiOut.Uiu.EsitiComune }
         */
        public DatiOut.Uiu.EsitiComune getEsitiComune() {
            return esitiComune;
        }

        /**
         * Sets the value of the esitiComune property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Uiu.EsitiComune }
         */
        public void setEsitiComune(DatiOut.Uiu.EsitiComune value) {
            this.esitiComune = value;
        }

        /**
         * Gets the value of the identificativo property.
         *
         * <p>
         * This accessor method returns a reference to the live list,
         * not a snapshot. Therefore any modification you make to the
         * returned list will be present inside the JAXB object.
         * This is why there is not a <CODE>set</CODE> method for the identificativo property.
         *
         * <p>
         * For example, to add a new item, do as follows:
         * <pre>
         *    getIdentificativo().add(newItem);
         * </pre>
         *
         *
         * <p>
         * Objects of the following type(s) are allowed in the list
         * {@link DatiOut.Uiu.Identificativo }
         */
        public List<Identificativo> getIdentificativo() {
            if (identificativo == null) {
                identificativo = new ArrayList<Identificativo>();
            }
            return this.identificativo;
        }

        /**
         * Gets the value of the indirizzo property.
         *
         * <p>
         * This accessor method returns a reference to the live list,
         * not a snapshot. Therefore any modification you make to the
         * returned list will be present inside the JAXB object.
         * This is why there is not a <CODE>set</CODE> method for the indirizzo property.
         *
         * <p>
         * For example, to add a new item, do as follows:
         * <pre>
         *    getIndirizzo().add(newItem);
         * </pre>
         *
         *
         * <p>
         * Objects of the following type(s) are allowed in the list
         * {@link DatiOut.Uiu.Indirizzo }
         */
        public List<Indirizzo> getIndirizzo() {
            if (indirizzo == null) {
                indirizzo = new ArrayList<Indirizzo>();
            }
            return this.indirizzo;
        }

        /**
         * Gets the value of the ubicazione property.
         *
         * @return possible object is
         * {@link DatiOut.Uiu.Ubicazione }
         */
        public DatiOut.Uiu.Ubicazione getUbicazione() {
            return ubicazione;
        }

        /**
         * Sets the value of the ubicazione property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Uiu.Ubicazione }
         */
        public void setUbicazione(DatiOut.Uiu.Ubicazione value) {
            this.ubicazione = value;
        }

        /**
         * Gets the value of the datiMetrici property.
         *
         * <p>
         * This accessor method returns a reference to the live list,
         * not a snapshot. Therefore any modification you make to the
         * returned list will be present inside the JAXB object.
         * This is why there is not a <CODE>set</CODE> method for the datiMetrici property.
         *
         * <p>
         * For example, to add a new item, do as follows:
         * <pre>
         *    getDatiMetrici().add(newItem);
         * </pre>
         *
         *
         * <p>
         * Objects of the following type(s) are allowed in the list
         * {@link DatiOut.Uiu.DatiMetrici }
         */
        public List<DatiMetrici> getDatiMetrici() {
            if (datiMetrici == null) {
                datiMetrici = new ArrayList<DatiMetrici>();
            }
            return this.datiMetrici;
        }

        /**
         * Gets the value of the soggetti property.
         *
         * @return possible object is
         * {@link DatiOut.Uiu.Soggetti }
         */
        public DatiOut.Uiu.Soggetti getSoggetti() {
            return soggetti;
        }

        /**
         * Sets the value of the soggetti property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Uiu.Soggetti }
         */
        public void setSoggetti(DatiOut.Uiu.Soggetti value) {
            this.soggetti = value;
        }

        /**
         * Gets the value of the datiNuovi property.
         *
         * @return possible object is
         * {@link DatiOut.Uiu.DatiNuovi }
         */
        public DatiOut.Uiu.DatiNuovi getDatiNuovi() {
            return datiNuovi;
        }

        /**
         * Sets the value of the datiNuovi property.
         *
         * @param value allowed object is
         *              {@link DatiOut.Uiu.DatiNuovi }
         */
        public void setDatiNuovi(DatiOut.Uiu.DatiNuovi value) {
            this.datiNuovi = value;
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
         *         &lt;element name="Ambiente">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="1"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="SuperficieA">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="9"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Altezza" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="4"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="AltezzaMax" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="4"/>
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
                "ambiente",
                "superficieA",
                "altezza",
                "altezzaMax"
        })
        public static class DatiMetrici {

            @XmlElement(name = "Ambiente", namespace = "http://", required = true)
            protected String ambiente;
            @XmlElement(name = "SuperficieA", namespace = "http://")
            protected int superficieA;
            @XmlElement(name = "Altezza", namespace = "http://")
            protected Integer altezza;
            @XmlElement(name = "AltezzaMax", namespace = "http://")
            protected Integer altezzaMax;

            /**
             * Gets the value of the ambiente property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getAmbiente() {
                return ambiente;
            }

            /**
             * Sets the value of the ambiente property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setAmbiente(String value) {
                this.ambiente = value;
            }

            /**
             * Gets the value of the superficieA property.
             */
            public int getSuperficieA() {
                return superficieA;
            }

            /**
             * Sets the value of the superficieA property.
             */
            public void setSuperficieA(int value) {
                this.superficieA = value;
            }

            /**
             * Gets the value of the altezza property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getAltezza() {
                return altezza;
            }

            /**
             * Sets the value of the altezza property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setAltezza(Integer value) {
                this.altezza = value;
            }

            /**
             * Gets the value of the altezzaMax property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getAltezzaMax() {
                return altezzaMax;
            }

            /**
             * Sets the value of the altezzaMax property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setAltezzaMax(Integer value) {
                this.altezzaMax = value;
            }

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
         *         &lt;element name="SuperficieTotale" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="9"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="SuperficieConvenzionale" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="9"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="DataInizioValidita">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="8"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="DataFineValidita" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="8"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="CodiceStradaNazionale" minOccurs="0">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;sequence>
         *                   &lt;element name="Comune">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;length value="4"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="ProgStrada">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
         *                         &lt;totalDigits value="7"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                 &lt;/sequence>
         *               &lt;/restriction>
         *             &lt;/complexContent>
         *           &lt;/complexType>
         *         &lt;/element>
         *         &lt;element name="DataCertificazione" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="8"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Provvedimento" minOccurs="0">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;sequence>
         *                   &lt;element name="Data">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;length value="8"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Protocollo" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="50"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                 &lt;/sequence>
         *               &lt;/restriction>
         *             &lt;/complexContent>
         *           &lt;/complexType>
         *         &lt;/element>
         *         &lt;element name="CodiceStradaComunale" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="30"/>
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
                "superficieTotale",
                "superficieConvenzionale",
                "dataInizioValidita",
                "dataFineValidita",
                "codiceStradaNazionale",
                "dataCertificazione",
                "provvedimento",
                "codiceStradaComunale"
        })
        public static class DatiNuovi {

            @XmlElement(name = "SuperficieTotale", namespace = "http://")
            protected Integer superficieTotale;
            @XmlElement(name = "SuperficieConvenzionale", namespace = "http://")
            protected Integer superficieConvenzionale;
            @XmlElement(name = "DataInizioValidita", namespace = "http://", required = true)
            protected String dataInizioValidita;
            @XmlElement(name = "DataFineValidita", namespace = "http://")
            protected String dataFineValidita;
            @XmlElement(name = "CodiceStradaNazionale", namespace = "http://")
            protected DatiOut.Uiu.DatiNuovi.CodiceStradaNazionale codiceStradaNazionale;
            @XmlElement(name = "DataCertificazione", namespace = "http://")
            protected String dataCertificazione;
            @XmlElement(name = "Provvedimento", namespace = "http://")
            protected DatiOut.Uiu.DatiNuovi.Provvedimento provvedimento;
            @XmlElement(name = "CodiceStradaComunale", namespace = "http://")
            protected String codiceStradaComunale;

            /**
             * Gets the value of the superficieTotale property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getSuperficieTotale() {
                return superficieTotale;
            }

            /**
             * Sets the value of the superficieTotale property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setSuperficieTotale(Integer value) {
                this.superficieTotale = value;
            }

            /**
             * Gets the value of the superficieConvenzionale property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getSuperficieConvenzionale() {
                return superficieConvenzionale;
            }

            /**
             * Sets the value of the superficieConvenzionale property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setSuperficieConvenzionale(Integer value) {
                this.superficieConvenzionale = value;
            }

            /**
             * Gets the value of the dataInizioValidita property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getDataInizioValidita() {
                return dataInizioValidita;
            }

            /**
             * Sets the value of the dataInizioValidita property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setDataInizioValidita(String value) {
                this.dataInizioValidita = value;
            }

            /**
             * Gets the value of the dataFineValidita property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getDataFineValidita() {
                return dataFineValidita;
            }

            /**
             * Sets the value of the dataFineValidita property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setDataFineValidita(String value) {
                this.dataFineValidita = value;
            }

            /**
             * Gets the value of the codiceStradaNazionale property.
             *
             * @return possible object is
             * {@link DatiOut.Uiu.DatiNuovi.CodiceStradaNazionale }
             */
            public DatiOut.Uiu.DatiNuovi.CodiceStradaNazionale getCodiceStradaNazionale() {
                return codiceStradaNazionale;
            }

            /**
             * Sets the value of the codiceStradaNazionale property.
             *
             * @param value allowed object is
             *              {@link DatiOut.Uiu.DatiNuovi.CodiceStradaNazionale }
             */
            public void setCodiceStradaNazionale(DatiOut.Uiu.DatiNuovi.CodiceStradaNazionale value) {
                this.codiceStradaNazionale = value;
            }

            /**
             * Gets the value of the dataCertificazione property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getDataCertificazione() {
                return dataCertificazione;
            }

            /**
             * Sets the value of the dataCertificazione property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setDataCertificazione(String value) {
                this.dataCertificazione = value;
            }

            /**
             * Gets the value of the provvedimento property.
             *
             * @return possible object is
             * {@link DatiOut.Uiu.DatiNuovi.Provvedimento }
             */
            public DatiOut.Uiu.DatiNuovi.Provvedimento getProvvedimento() {
                return provvedimento;
            }

            /**
             * Sets the value of the provvedimento property.
             *
             * @param value allowed object is
             *              {@link DatiOut.Uiu.DatiNuovi.Provvedimento }
             */
            public void setProvvedimento(DatiOut.Uiu.DatiNuovi.Provvedimento value) {
                this.provvedimento = value;
            }

            /**
             * Gets the value of the codiceStradaComunale property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getCodiceStradaComunale() {
                return codiceStradaComunale;
            }

            /**
             * Sets the value of the codiceStradaComunale property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setCodiceStradaComunale(String value) {
                this.codiceStradaComunale = value;
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
             *         &lt;element name="Comune">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;length value="4"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="ProgStrada">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}positiveInteger">
             *               &lt;totalDigits value="7"/>
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
                    "comune",
                    "progStrada"
            })
            public static class CodiceStradaNazionale {

                @XmlElement(name = "Comune", namespace = "http://", required = true)
                protected String comune;
                @XmlElement(name = "ProgStrada", namespace = "http://", required = true)
                protected BigInteger progStrada;

                /**
                 * Gets the value of the comune property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getComune() {
                    return comune;
                }

                /**
                 * Sets the value of the comune property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setComune(String value) {
                    this.comune = value;
                }

                /**
                 * Gets the value of the progStrada property.
                 *
                 * @return possible object is
                 * {@link BigInteger }
                 */
                public BigInteger getProgStrada() {
                    return progStrada;
                }

                /**
                 * Sets the value of the progStrada property.
                 *
                 * @param value allowed object is
                 *              {@link BigInteger }
                 */
                public void setProgStrada(BigInteger value) {
                    this.progStrada = value;
                }

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
             *         &lt;element name="Data">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;length value="8"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Protocollo" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="50"/>
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
                    "data",
                    "protocollo"
            })
            public static class Provvedimento {

                @XmlElement(name = "Data", namespace = "http://", required = true)
                protected String data;
                @XmlElement(name = "Protocollo", namespace = "http://")
                protected String protocollo;

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
                 * Gets the value of the protocollo property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getProtocollo() {
                    return protocollo;
                }

                /**
                 * Sets the value of the protocollo property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setProtocollo(String value) {
                    this.protocollo = value;
                }

            }

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
         *         &lt;element name="EsitoSup" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="1"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="EsitoAgg" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="2"/>
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
                "esitoSup",
                "esitoAgg"
        })
        public static class EsitiAgenzia {

            @XmlElement(name = "EsitoSup", namespace = "http://")
            protected Integer esitoSup;
            @XmlElement(name = "EsitoAgg", namespace = "http://")
            protected String esitoAgg;

            /**
             * Gets the value of the esitoSup property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getEsitoSup() {
                return esitoSup;
            }

            /**
             * Sets the value of the esitoSup property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setEsitoSup(Integer value) {
                this.esitoSup = value;
            }

            /**
             * Gets the value of the esitoAgg property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getEsitoAgg() {
                return esitoAgg;
            }

            /**
             * Sets the value of the esitoAgg property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setEsitoAgg(String value) {
                this.esitoAgg = value;
            }

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
         *         &lt;element name="Riscontro">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
         *               &lt;totalDigits value="1"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Istanza" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
         *               &lt;totalDigits value="1"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="RichiestaPlan" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}integer">
         *               &lt;totalDigits value="1"/>
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
                "riscontro",
                "istanza",
                "richiestaPlan"
        })
        public static class EsitiComune {

            @XmlElement(name = "Riscontro", namespace = "http://", required = true)
            protected BigInteger riscontro;
            @XmlElement(name = "Istanza", namespace = "http://")
            protected BigInteger istanza;
            @XmlElement(name = "RichiestaPlan", namespace = "http://")
            protected BigInteger richiestaPlan;

            /**
             * Gets the value of the riscontro property.
             *
             * @return possible object is
             * {@link BigInteger }
             */
            public BigInteger getRiscontro() {
                return riscontro;
            }

            /**
             * Sets the value of the riscontro property.
             *
             * @param value allowed object is
             *              {@link BigInteger }
             */
            public void setRiscontro(BigInteger value) {
                this.riscontro = value;
            }

            /**
             * Gets the value of the istanza property.
             *
             * @return possible object is
             * {@link BigInteger }
             */
            public BigInteger getIstanza() {
                return istanza;
            }

            /**
             * Sets the value of the istanza property.
             *
             * @param value allowed object is
             *              {@link BigInteger }
             */
            public void setIstanza(BigInteger value) {
                this.istanza = value;
            }

            /**
             * Gets the value of the richiestaPlan property.
             *
             * @return possible object is
             * {@link BigInteger }
             */
            public BigInteger getRichiestaPlan() {
                return richiestaPlan;
            }

            /**
             * Sets the value of the richiestaPlan property.
             *
             * @param value allowed object is
             *              {@link BigInteger }
             */
            public void setRichiestaPlan(BigInteger value) {
                this.richiestaPlan = value;
            }

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
         *         &lt;element name="SezUrb" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="3"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Foglio">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="4"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Numero">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="5"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Denominatore" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="4"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Sub" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="4"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Edificialita" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="1"/>
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
                "sezUrb",
                "foglio",
                "numero",
                "denominatore",
                "sub",
                "edificialita"
        })
        public static class Identificativo {

            @XmlElement(name = "SezUrb", namespace = "http://")
            protected String sezUrb;
            @XmlElement(name = "Foglio", namespace = "http://", required = true)
            protected String foglio;
            @XmlElement(name = "Numero", namespace = "http://", required = true)
            protected String numero;
            @XmlElement(name = "Denominatore", namespace = "http://")
            protected Integer denominatore;
            @XmlElement(name = "Sub", namespace = "http://")
            protected String sub;
            @XmlElement(name = "Edificialita", namespace = "http://")
            protected String edificialita;

            /**
             * Gets the value of the sezUrb property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getSezUrb() {
                return sezUrb;
            }

            /**
             * Sets the value of the sezUrb property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setSezUrb(String value) {
                this.sezUrb = value;
            }

            /**
             * Gets the value of the foglio property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getFoglio() {
                return foglio;
            }

            /**
             * Sets the value of the foglio property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setFoglio(String value) {
                this.foglio = value;
            }

            /**
             * Gets the value of the numero property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getNumero() {
                return numero;
            }

            /**
             * Sets the value of the numero property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setNumero(String value) {
                this.numero = value;
            }

            /**
             * Gets the value of the denominatore property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getDenominatore() {
                return denominatore;
            }

            /**
             * Sets the value of the denominatore property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setDenominatore(Integer value) {
                this.denominatore = value;
            }

            /**
             * Gets the value of the sub property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getSub() {
                return sub;
            }

            /**
             * Sets the value of the sub property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setSub(String value) {
                this.sub = value;
            }

            /**
             * Gets the value of the edificialita property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getEdificialita() {
                return edificialita;
            }

            /**
             * Sets the value of the edificialita property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setEdificialita(String value) {
                this.edificialita = value;
            }

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
         *         &lt;element name="CodTopo">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="3"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Toponimo">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="16"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Denom">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="50"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Codice" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="5"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Civico" maxOccurs="3" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="6"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Fonte" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="1"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Delibera" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;length value="70"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Localita" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="30"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Km" type="{http://www.w3.org/2001/XMLSchema}decimal" minOccurs="0"/>
         *         &lt;element name="CAP" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *               &lt;totalDigits value="5"/>
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
                "codTopo",
                "toponimo",
                "denom",
                "codice",
                "civico",
                "fonte",
                "delibera",
                "localita",
                "km",
                "cap"
        })
        public static class Indirizzo {

            @XmlElement(name = "CodTopo", namespace = "http://")
            protected int codTopo;
            @XmlElement(name = "Toponimo", namespace = "http://", required = true)
            protected String toponimo;
            @XmlElement(name = "Denom", namespace = "http://", required = true)
            protected String denom;
            @XmlElement(name = "Codice", namespace = "http://")
            protected Integer codice;
            @XmlElement(name = "Civico", namespace = "http://")
            protected List<String> civico;
            @XmlElement(name = "Fonte", namespace = "http://")
            protected Integer fonte;
            @XmlElement(name = "Delibera", namespace = "http://")
            protected String delibera;
            @XmlElement(name = "Localita", namespace = "http://")
            protected String localita;
            @XmlElement(name = "Km", namespace = "http://")
            protected BigDecimal km;
            @XmlElement(name = "CAP", namespace = "http://")
            protected Integer cap;

            /**
             * Gets the value of the codTopo property.
             */
            public int getCodTopo() {
                return codTopo;
            }

            /**
             * Sets the value of the codTopo property.
             */
            public void setCodTopo(int value) {
                this.codTopo = value;
            }

            /**
             * Gets the value of the toponimo property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getToponimo() {
                return toponimo;
            }

            /**
             * Sets the value of the toponimo property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setToponimo(String value) {
                this.toponimo = value;
            }

            /**
             * Gets the value of the denom property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getDenom() {
                return denom;
            }

            /**
             * Sets the value of the denom property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setDenom(String value) {
                this.denom = value;
            }

            /**
             * Gets the value of the codice property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getCodice() {
                return codice;
            }

            /**
             * Sets the value of the codice property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setCodice(Integer value) {
                this.codice = value;
            }

            /**
             * Gets the value of the civico property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the civico property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getCivico().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link String }
             */
            public List<String> getCivico() {
                if (civico == null) {
                    civico = new ArrayList<String>();
                }
                return this.civico;
            }

            /**
             * Gets the value of the fonte property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getFonte() {
                return fonte;
            }

            /**
             * Sets the value of the fonte property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setFonte(Integer value) {
                this.fonte = value;
            }

            /**
             * Gets the value of the delibera property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getDelibera() {
                return delibera;
            }

            /**
             * Sets the value of the delibera property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setDelibera(String value) {
                this.delibera = value;
            }

            /**
             * Gets the value of the localita property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getLocalita() {
                return localita;
            }

            /**
             * Sets the value of the localita property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setLocalita(String value) {
                this.localita = value;
            }

            /**
             * Gets the value of the km property.
             *
             * @return possible object is
             * {@link BigDecimal }
             */
            public BigDecimal getKm() {
                return km;
            }

            /**
             * Sets the value of the km property.
             *
             * @param value allowed object is
             *              {@link BigDecimal }
             */
            public void setKm(BigDecimal value) {
                this.km = value;
            }

            /**
             * Gets the value of the cap property.
             *
             * @return possible object is
             * {@link Integer }
             */
            public Integer getCAP() {
                return cap;
            }

            /**
             * Sets the value of the cap property.
             *
             * @param value allowed object is
             *              {@link Integer }
             */
            public void setCAP(Integer value) {
                this.cap = value;
            }

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
         *         &lt;element name="Pf" maxOccurs="unbounded" minOccurs="0">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;sequence>
         *                   &lt;element name="IdSog">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *                         &lt;totalDigits value="9"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Cognome">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="50"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Nome" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="50"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Sesso" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *                         &lt;enumeration value="1"/>
         *                         &lt;enumeration value="2"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="DataNascita" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;length value="8"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Comune" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;length value="4"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="CF" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="16"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
         *                 &lt;/sequence>
         *               &lt;/restriction>
         *             &lt;/complexContent>
         *           &lt;/complexType>
         *         &lt;/element>
         *         &lt;element name="Pnf" maxOccurs="unbounded" minOccurs="0">
         *           &lt;complexType>
         *             &lt;complexContent>
         *               &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
         *                 &lt;sequence>
         *                   &lt;element name="IdSog">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
         *                         &lt;totalDigits value="9"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Denominazione">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="150"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="Sede" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;length value="4"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element name="CF" minOccurs="0">
         *                     &lt;simpleType>
         *                       &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *                         &lt;maxLength value="11"/>
         *                       &lt;/restriction>
         *                     &lt;/simpleType>
         *                   &lt;/element>
         *                   &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
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
                "pf",
                "pnf"
        })
        public static class Soggetti {

            @XmlElement(name = "Pf", namespace = "http://")
            protected List<Pf> pf;
            @XmlElement(name = "Pnf", namespace = "http://")
            protected List<Pnf> pnf;

            /**
             * Gets the value of the pf property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the pf property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getPf().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link DatiOut.Uiu.Soggetti.Pf }
             */
            public List<Pf> getPf() {
                if (pf == null) {
                    pf = new ArrayList<Pf>();
                }
                return this.pf;
            }

            /**
             * Gets the value of the pnf property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the pnf property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getPnf().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link DatiOut.Uiu.Soggetti.Pnf }
             */
            public List<Pnf> getPnf() {
                if (pnf == null) {
                    pnf = new ArrayList<Pnf>();
                }
                return this.pnf;
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
             *         &lt;element name="IdSog">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
             *               &lt;totalDigits value="9"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Cognome">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="50"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Nome" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="50"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Sesso" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
             *               &lt;enumeration value="1"/>
             *               &lt;enumeration value="2"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="DataNascita" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;length value="8"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Comune" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;length value="4"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="CF" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="16"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
             *       &lt;/sequence>
             *     &lt;/restriction>
             *   &lt;/complexContent>
             * &lt;/complexType>
             * </pre>
             */
            @XmlAccessorType(XmlAccessType.FIELD)
            @XmlType(name = "", propOrder = {
                    "idSog",
                    "cognome",
                    "nome",
                    "sesso",
                    "dataNascita",
                    "comune",
                    "cf",
                    "datiAtto"
            })
            public static class Pf {

                @XmlElement(name = "IdSog", namespace = "http://")
                protected int idSog;
                @XmlElement(name = "Cognome", namespace = "http://", required = true)
                protected String cognome;
                @XmlElement(name = "Nome", namespace = "http://")
                protected String nome;
                @XmlElement(name = "Sesso", namespace = "http://")
                protected Integer sesso;
                @XmlElement(name = "DataNascita", namespace = "http://")
                protected String dataNascita;
                @XmlElement(name = "Comune", namespace = "http://")
                protected String comune;
                @XmlElement(name = "CF", namespace = "http://")
                protected String cf;
                @XmlElement(name = "DatiAtto", namespace = "http://")
                protected DatiAtto datiAtto;

                /**
                 * Gets the value of the idSog property.
                 */
                public int getIdSog() {
                    return idSog;
                }

                /**
                 * Sets the value of the idSog property.
                 */
                public void setIdSog(int value) {
                    this.idSog = value;
                }

                /**
                 * Gets the value of the cognome property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getCognome() {
                    return cognome;
                }

                /**
                 * Sets the value of the cognome property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setCognome(String value) {
                    this.cognome = value;
                }

                /**
                 * Gets the value of the nome property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getNome() {
                    return nome;
                }

                /**
                 * Sets the value of the nome property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setNome(String value) {
                    this.nome = value;
                }

                /**
                 * Gets the value of the sesso property.
                 *
                 * @return possible object is
                 * {@link Integer }
                 */
                public Integer getSesso() {
                    return sesso;
                }

                /**
                 * Sets the value of the sesso property.
                 *
                 * @param value allowed object is
                 *              {@link Integer }
                 */
                public void setSesso(Integer value) {
                    this.sesso = value;
                }

                /**
                 * Gets the value of the dataNascita property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getDataNascita() {
                    return dataNascita;
                }

                /**
                 * Sets the value of the dataNascita property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setDataNascita(String value) {
                    this.dataNascita = value;
                }

                /**
                 * Gets the value of the comune property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getComune() {
                    return comune;
                }

                /**
                 * Sets the value of the comune property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setComune(String value) {
                    this.comune = value;
                }

                /**
                 * Gets the value of the cf property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getCF() {
                    return cf;
                }

                /**
                 * Sets the value of the cf property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setCF(String value) {
                    this.cf = value;
                }

                /**
                 * Gets the value of the datiAtto property.
                 *
                 * @return possible object is
                 * {@link DatiAtto }
                 */
                public DatiAtto getDatiAtto() {
                    return datiAtto;
                }

                /**
                 * Sets the value of the datiAtto property.
                 *
                 * @param value allowed object is
                 *              {@link DatiAtto }
                 */
                public void setDatiAtto(DatiAtto value) {
                    this.datiAtto = value;
                }

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
             *         &lt;element name="IdSog">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}int">
             *               &lt;totalDigits value="9"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Denominazione">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="150"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="Sede" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;length value="4"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element name="CF" minOccurs="0">
             *           &lt;simpleType>
             *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
             *               &lt;maxLength value="11"/>
             *             &lt;/restriction>
             *           &lt;/simpleType>
             *         &lt;/element>
             *         &lt;element ref="{http://}DatiAtto" minOccurs="0"/>
             *       &lt;/sequence>
             *     &lt;/restriction>
             *   &lt;/complexContent>
             * &lt;/complexType>
             * </pre>
             */
            @XmlAccessorType(XmlAccessType.FIELD)
            @XmlType(name = "", propOrder = {
                    "idSog",
                    "denominazione",
                    "sede",
                    "cf",
                    "datiAtto"
            })
            public static class Pnf {

                @XmlElement(name = "IdSog", namespace = "http://")
                protected int idSog;
                @XmlElement(name = "Denominazione", namespace = "http://", required = true)
                protected String denominazione;
                @XmlElement(name = "Sede", namespace = "http://")
                protected String sede;
                @XmlElement(name = "CF", namespace = "http://")
                protected String cf;
                @XmlElement(name = "DatiAtto", namespace = "http://")
                protected DatiAtto datiAtto;

                /**
                 * Gets the value of the idSog property.
                 */
                public int getIdSog() {
                    return idSog;
                }

                /**
                 * Sets the value of the idSog property.
                 */
                public void setIdSog(int value) {
                    this.idSog = value;
                }

                /**
                 * Gets the value of the denominazione property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getDenominazione() {
                    return denominazione;
                }

                /**
                 * Sets the value of the denominazione property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setDenominazione(String value) {
                    this.denominazione = value;
                }

                /**
                 * Gets the value of the sede property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getSede() {
                    return sede;
                }

                /**
                 * Sets the value of the sede property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setSede(String value) {
                    this.sede = value;
                }

                /**
                 * Gets the value of the cf property.
                 *
                 * @return possible object is
                 * {@link String }
                 */
                public String getCF() {
                    return cf;
                }

                /**
                 * Sets the value of the cf property.
                 *
                 * @param value allowed object is
                 *              {@link String }
                 */
                public void setCF(String value) {
                    this.cf = value;
                }

                /**
                 * Gets the value of the datiAtto property.
                 *
                 * @return possible object is
                 * {@link DatiAtto }
                 */
                public DatiAtto getDatiAtto() {
                    return datiAtto;
                }

                /**
                 * Sets the value of the datiAtto property.
                 *
                 * @param value allowed object is
                 *              {@link DatiAtto }
                 */
                public void setDatiAtto(DatiAtto value) {
                    this.datiAtto = value;
                }

            }

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
         *         &lt;element name="Lotto" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="2"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Edificio" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="2"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Scala" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="2"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Interno" maxOccurs="2" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="3"/>
         *             &lt;/restriction>
         *           &lt;/simpleType>
         *         &lt;/element>
         *         &lt;element name="Piano" maxOccurs="4" minOccurs="0">
         *           &lt;simpleType>
         *             &lt;restriction base="{http://www.w3.org/2001/XMLSchema}string">
         *               &lt;maxLength value="4"/>
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
                "lotto",
                "edificio",
                "scala",
                "interno",
                "piano"
        })
        public static class Ubicazione {

            @XmlElement(name = "Lotto", namespace = "http://")
            protected String lotto;
            @XmlElement(name = "Edificio", namespace = "http://")
            protected String edificio;
            @XmlElement(name = "Scala", namespace = "http://")
            protected String scala;
            @XmlElement(name = "Interno", namespace = "http://")
            protected List<String> interno;
            @XmlElement(name = "Piano", namespace = "http://")
            protected List<String> piano;

            /**
             * Gets the value of the lotto property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getLotto() {
                return lotto;
            }

            /**
             * Sets the value of the lotto property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setLotto(String value) {
                this.lotto = value;
            }

            /**
             * Gets the value of the edificio property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getEdificio() {
                return edificio;
            }

            /**
             * Sets the value of the edificio property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setEdificio(String value) {
                this.edificio = value;
            }

            /**
             * Gets the value of the scala property.
             *
             * @return possible object is
             * {@link String }
             */
            public String getScala() {
                return scala;
            }

            /**
             * Sets the value of the scala property.
             *
             * @param value allowed object is
             *              {@link String }
             */
            public void setScala(String value) {
                this.scala = value;
            }

            /**
             * Gets the value of the interno property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the interno property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getInterno().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link String }
             */
            public List<String> getInterno() {
                if (interno == null) {
                    interno = new ArrayList<String>();
                }
                return this.interno;
            }

            /**
             * Gets the value of the piano property.
             *
             * <p>
             * This accessor method returns a reference to the live list,
             * not a snapshot. Therefore any modification you make to the
             * returned list will be present inside the JAXB object.
             * This is why there is not a <CODE>set</CODE> method for the piano property.
             *
             * <p>
             * For example, to add a new item, do as follows:
             * <pre>
             *    getPiano().add(newItem);
             * </pre>
             *
             *
             * <p>
             * Objects of the following type(s) are allowed in the list
             * {@link String }
             */
            public List<String> getPiano() {
                if (piano == null) {
                    piano = new ArrayList<String>();
                }
                return this.piano;
            }

        }

    }

}
