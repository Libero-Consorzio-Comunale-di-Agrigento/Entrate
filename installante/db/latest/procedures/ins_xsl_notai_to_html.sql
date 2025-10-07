--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ins_xsl_notai_to_html stripComments:false runOnChange:true 
 
create or replace procedure INS_XSL_NOTAI_TO_HTML
is
w_conta      number := 0;
d_amount     BINARY_INTEGER := 32767;
d_clob       CLOB := EMPTY_CLOB() ;
w_riga       varchar2(32000);
begin
   dbms_lob.createTemporary(d_clob,TRUE,dbms_lob.SESSION);
   begin
      select count(1)
        into w_conta
        from parametri_import
       where nome  = 'XSLDATA'
           ;
   EXCEPTION
     WHEN others THEN
       w_conta := 0;
   end;
   if w_conta = 0 then
      insert into parametri_import (nome)
      values ('XSLDATA');
   end if;
   update parametri_import
      set parametro = d_clob
    where nome  = 'XSLDATA'
        ;
   w_riga :=
'<xsl:stylesheet version="2.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xpath-default-namespace="http://www.agenziaterritorio.it/ICI.xsd"
 >
 <xsl:output method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
<html>
<style type="text/css">
table.variazione {
   border-width: 2px;
   border-spacing: 3px;
   border-style: solid;
   border-color: gray;
   border-collapse: separate;
   background-color: white;
}
table.variazione th {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(230, 220, 210);
   -moz-border-radius: 3px 3px 3px 3px;
}
table.variazione td {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(230, 220, 210);
   -moz-border-radius: 3px 3px 3px 3px;
    text-align:center;
}
table.soggetto {
   border-width: 1px;
   border-spacing: 3px;
   border-style: solid;
   border-color: gray;
   border-collapse: separate;
   background-color: white;
}
table.soggetto th {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(250, 240, 230);
   -moz-border-radius: 3px 3px 3px 3px;
}
table.soggetto td {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(250, 240, 230);
   -moz-border-radius: 3px 3px 3px 3px;
    text-align:left;
}
table.immobile {
   border-width: 1px;
   border-spacing: 3px;
   border-style: solid;
   border-color: gray;
   border-collapse: separate;
   background-color: white;
}
table.immobile th {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(250, 240, 230);
   -moz-border-radius: 3px 3px 3px 3px;
}
table.immobile td {
   border-width: 0px;
   padding: 3px;
   border-style: ridge;
   border-color: gray;
   background-color: rgb(250, 240, 230);
   -moz-border-radius: 3px 3px 3px 3px;
    text-align:left;
}
h1 {text-align:center;
    margin: 0;
    padding: 0;
}
</style>
<head>
<title>Gestione Notai</title>
</head>
<body>
<table width="816" class="variazione">
    <tr>
      <td>
        <h1>Gestione Notai</h1>
      </td>
    </tr>
    <tr>
      <td>
        <xsl:apply-templates select="DatiOut/DatiRichiesta" />
      </td>
    </tr>
</table>
<br />
    <xsl:apply-templates select="DatiOut/DatiPresenti" />
</body>
</html>
</xsl:template>
<xsl:decimal-format name="percentuale" decimal-separator="," grouping-separator="."/>
<xsl:decimal-format name="euro" decimal-separator="," grouping-separator="."/>
<xsl:template match="DatiOut/DatiRichiesta">
Data Fornitura: <xsl:value-of select="concat(substring(DataIniziale,9,2),''/'',substring(DataIniziale,6,2),''/'',substring(DataIniziale,1,4))"/>
</xsl:template>
<xsl:template match="DatiOut/DatiPresenti">
   <xsl:apply-templates select="Variazioni/Variazione" />
</xsl:template>
<xsl:template match="Variazioni/Variazione">
<table width="800" class="variazione">
       <xsl:attribute name="id">
                      <xsl:value-of select="Trascrizione/Nota/NumeroNota"/>
       </xsl:attribute>
    <tr>
      <td>Anno: <b><xsl:value-of select="Trascrizione/Nota/Anno"/></b>
          <xsl:text>&#160;&#160;</xsl:text>
          Data Presentazione Atto: <b><xsl:value-of select="concat(substring(Trascrizione/Nota/DataPresentazioneAtto,1,2),''/'',substring(Trascrizione/Nota/DataPresentazioneAtto,3,2),''/'',substring(Trascrizione/Nota/DataPresentazioneAtto,5,4))"/></b>
          <xsl:text>&#160;&#160;</xsl:text>
          Data Validità Atto: <xsl:value-of select="concat(substring(Trascrizione/Nota/DataValiditaAtto,1,2),''/'',substring(Trascrizione/Nota/DataValiditaAtto,3,2),''/'',substring(Trascrizione/Nota/DataValiditaAtto,5,4))"/>
          <br />
          Numero Nota: <xsl:value-of select="Trascrizione/Nota/NumeroNota"/>
               <xsl:if test="Trascrizione/NotaRettificata/NumeroNota">
             <xsl:text>&#160;&#160;</xsl:text>Rettifica: <a><xsl:attribute name="href">
                      #<xsl:value-of select="Trascrizione/NotaRettificata/NumeroNota"/>
       </xsl:attribute><xsl:value-of select="Trascrizione/NotaRettificata/NumeroNota"/></a>
          </xsl:if>
          <xsl:text>&#160;&#160;</xsl:text>
          Esito Nota: <xsl:value-of select="Trascrizione/Nota/EsitoNota"/>
          <xsl:text>&#160;&#160;</xsl:text>
          Numero Repertorio: <xsl:value-of select="Trascrizione/Nota/NumeroRepertorio"/>
          <xsl:if test="Trascrizione/Nota/CodiceAtto">
             <xsl:text>&#160;&#160;</xsl:text>Codice Atto: <xsl:value-of select="Trascrizione/Nota/CodiceAtto"/>
          </xsl:if>
      </td>
    </tr>
    <tr>
      <td>Rogante: <xsl:value-of select="Trascrizione/Rogante/CognomeNome"/> (<xsl:value-of select="Trascrizione/Rogante/CodiceFiscale"/>)
          <xsl:text>&#160;&#160;</xsl:text>
          Codice Comune Sede: <xsl:value-of select="Trascrizione/Rogante/Sede"/>
      </td>
    </tr>
    <tr>
      <td><xsl:apply-templates select="Soggetti"/>
      </td>
    </tr>
    <tr>
      <td><xsl:apply-templates select="Immobili"/>
      </td>
    </tr>
</table>
<br />
</xsl:template>
<xsl:template match="Soggetti/Soggetto">
<table width="800" class="soggetto">
    <tr>
      <td>
        <xsl:if test="PersonaFisica">
           <b><xsl:value-of select="PersonaFisica/Cognome"/>
              <xsl:text>&#160;</xsl:text>
              <xsl:value-of select="PersonaFisica/Nome"/>
           </b> (<xsl:value-of select="PersonaFisica/CodiceFiscale"/>)
           <br />
           Nato il <xsl:value-of select="concat(substring(PersonaFisica/DataNascita,1,2),''/'',substring(PersonaFisica/DataNascita,3,2),''/'',substring(PersonaFisica/DataNascita,5,4))"/>
           <xsl:text>&#160;&#160;</xsl:text>
           Codice Comune di Nascita: <xsl:value-of select="PersonaFisica/LuogoNascita"/>
           <br />
        </xsl:if>
        <xsl:if test="PersonaGiuridica">
           <b><xsl:value-of select="PersonaGiuridica/Denominazione"/></b> (<xsl:value-of select="PersonaGiuridica/CodiceFiscale"/>)
           <xsl:text>&#160;&#160;</xsl:text>
           Sede: <xsl:value-of select="PersonaGiuridica/Sede"/>
           <br />
        </xsl:if>
        <xsl:if test="Recapito/Indirizzo">
           Recapito: <xsl:value-of select="Recapito/Indirizzo"/> - <xsl:value-of select="Recapito/CAP"/><xsl:text>&#160;</xsl:text><xsl:value-of select="Recapito/Comune"/> (<xsl:value-of select="Recapito/Provincia"/>)
        </xsl:if>
           </td>
    </tr>
    <xsl:apply-templates select="DatiTitolarita/Titolarita"/>
</table>
<br />
</xsl:template>
<xsl:template match="DatiTitolarita/Titolarita">
    <tr>
      <td><xsl:if test="TipologiaImmobile = ''T''">Terreno </xsl:if>
          <xsl:if test="TipologiaImmobile = ''F''">Fabbricato </xsl:if>
          <xsl:value-of select="@Ref_Immobile"/> -
        <xsl:if test="Acquisizione">
           <xsl:if test="Acquisizione/QuotaNumeratore">
              Percentuale Acquisita: <xsl:value-of select="format-number((Acquisizione/QuotaNumeratore div Acquisizione/QuotaDenominatore) div 10,''##0,00'',''percentuale'')"/>%
              <xsl:text>&#160;&#160;</xsl:text>
           </xsl:if>
           Codice Diritto: <xsl:value-of select="Acquisizione/CodiceDiritto"/>
           <xsl:if test="Acquisizione/Regime">
              <xsl:text>&#160;&#160;</xsl:text>
              Regime: <xsl:value-of select="Acquisizione/Regime"/>
           </xsl:if>
                <xsl:if test="PostRegistrazione/QuotaNumeratore">
            <xsl:text>&#160;&#160;</xsl:text>
            Post Reg.: <xsl:value-of select="format-number((PostRegistrazione/QuotaNumeratore div PostRegistrazione/QuotaDenominatore) * 100,''##0,00'',''percentuale'')"/>%
          </xsl:if>
        </xsl:if>
        <xsl:if test="Cessione">
           <xsl:if test="Cessione/QuotaNumeratore">
              Percentuale Ceduta: <xsl:value-of select="format-number((Cessione/QuotaNumeratore div Cessione/QuotaDenominatore) div 10,''##0,00'',''percentuale'')"/>%
              <xsl:text>&#160;&#160;</xsl:text>
           </xsl:if>
           Codice Diritto: <xsl:value-of select="Cessione/CodiceDiritto"/>
           <xsl:if test="Cessione/Regime">
              <xsl:text>&#160;&#160;</xsl:text>
              Regime: <xsl:value-of select="Cessione/Regime"/>
           </xsl:if>
                <xsl:if test="PreRegistrazione/QuotaNumeratore">
            <xsl:text>&#160;&#160;</xsl:text>
            Pre Reg.: <xsl:value-of select="format-number((PreRegistrazione/QuotaNumeratore div PreRegistrazione/QuotaDenominatore) * 100,''##0,00'',''percentuale'')"/>%
          </xsl:if>
        </xsl:if>
      </td>
    </tr>
</xsl:template>
<xsl:template match="Immobili/*">
<table width="800" class="immobile">
    <tr>
      <td>
        <xsl:choose>
           <xsl:when test="TipologiaImmobile = ''F''">
               Fabbricato
           </xsl:when>
           <xsl:when test="TipologiaImmobile = ''A''">
               Area Fabbricabile
           </xsl:when>
           <xsl:otherwise>
               Terreno
           </xsl:otherwise>
        </xsl:choose>
         <b><xsl:value-of select="@Ref_Immobile"/></b>
        <xsl:if test="CodiceEsito">
            - Codice Esito: <xsl:value-of select="CodiceEsito"/>
        </xsl:if>
            <xsl:if test="FlagGraffato">
            - Flag Graffato: <xsl:value-of select="FlagGraffato"/>
        </xsl:if>
        <br />
        <xsl:choose>
           <xsl:when test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneCensuaria">
              Sezione: <xsl:value-of select="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneCensuaria"/>
           </xsl:when>
           <xsl:otherwise>
              <xsl:if test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneUrbana">
                 <xsl:value-of select="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/SezioneUrbana"/>
              </xsl:if>
           </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Foglio">
           Foglio: <xsl:value-of select="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Foglio"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Numero">
           Numero: <xsl:value-of select="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Numero"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Subalterno">
           Subalterno: <xsl:value-of select="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]/Subalterno"/>
        </xsl:if>
        <xsl:if test="Identificativi[position()=1]/IdentificativoDefinitivo[position()=1]">
           <br />
        </xsl:if>
                                    <xsl:choose>
           <xsl:when test="Identificativo/SezioneCensuaria">
              Sezione: <xsl:value-of select="Identificativo/SezioneCensuaria"/>
           </xsl:when>
           <xsl:otherwise>
              <xsl:if test="Identificativo/SezioneUrbana">
                 <xsl:value-of select="Identificativo/SezioneUrbana"/>
              </xsl:if>
           </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="Identificativo/Foglio">
           Foglio: <xsl:value-of select="Identificativo/Foglio"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="Identificativo/Numero">
           Numero: <xsl:value-of select="Identificativo/Numero"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="Identificativo/Subalterno">
           Subalterno: <xsl:value-of select="Identificativo/Subalterno"/>
        </xsl:if>
        <xsl:if test="Identificativo">
           <br />
        </xsl:if>
        <xsl:if test="Classamento/Zona">
           Zona : <xsl:value-of select="Classamento/Zona"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="Classamento/Natura">
           Natura: <xsl:value-of select="Classamento/Natura"/>
           <xsl:text>&#160;&#160;</xsl:text>
        </xsl:if>
        <xsl:if test="TipologiaImmobile = ''F''">
            Categoria: <xsl:value-of select="Classamento/Categoria"/>
            <xsl:text>&#160;&#160;</xsl:text>
            Classe: <xsl:value-of select="Classamento/Classe"/>
            <br />
            <xsl:if test="Classamento/Superficie">
               Superficie: <xsl:value-of select="Classamento/Superficie"/>
               <xsl:text>&#160;&#160;</xsl:text>
            </xsl:if>
            <xsl:if test="Classamento/RenditaEuro">
               Rendita: <xsl:value-of select="format-number(Classamento/RenditaEuro div 100,''#.##0,00'',''euro'')"/>
            </xsl:if>
            <xsl:if test="Classamento/Superficie or Classamento/RenditaEuro">
               <br />
            </xsl:if>
            Ubicazione : <xsl:value-of select="UbicazioneNota/Indirizzo"/>
            <xsl:if test="UbicazioneNota/Civico1">
               , <xsl:value-of select="UbicazioneNota/Civico1"/>
            </xsl:if>
            <xsl:if test="UbicazioneNota/Interno1">
               <xsl:text>&#160;&#160;</xsl:text>
               Int.: <xsl:value-of select="UbicazioneNota/Interno1"/>
            </xsl:if>
            <xsl:if test="UbicazioneNota/Piano1">
               <xsl:text>&#160;&#160;</xsl:text>
               Piano: <xsl:value-of select="UbicazioneNota/Piano1"/>
            </xsl:if>
            <xsl:if test="UbicazioneNota/Scala">
               <xsl:text>&#160;&#160;</xsl:text>
               Scala: <xsl:value-of select="UbicazioneNota/Scala"/>
            </xsl:if>
        </xsl:if>
        <xsl:if test="TipologiaImmobile = ''T'' or TipologiaImmobile = ''A''">
            Classe: <xsl:value-of select="Classamento/Classe"/><br />
            Ettari: <xsl:value-of select="Classamento/Ettari"/>
            <xsl:text>&#160;&#160;</xsl:text>
            Are: <xsl:value-of select="Classamento/Are"/>
            <xsl:text>&#160;&#160;</xsl:text>
            Centiare : <xsl:value-of select="Classamento/Centiare"/><br />
            <xsl:if test="Partita">
                Partita: <xsl:value-of select="Partita"/>
                <xsl:text>&#160;&#160;</xsl:text>
            </xsl:if>
            <xsl:if test="Classamento/DominicaleEuro">
               Rendita: <xsl:value-of select="format-number(Classamento/DominicaleEuro div 100,''#.##0,00'',''euro'')"/>
            </xsl:if>
        </xsl:if>
      </td>
    </tr>
</table>
<br />
</xsl:template>
</xsl:stylesheet>';
    d_amount := LENGTH(w_riga);
    dbms_lob.writeappend(d_clob, d_amount,w_riga);
    begin
      update parametri_import
         set parametro = d_clob
       where nome  = 'XSLDATA'
       ;
    end;
end;
/

