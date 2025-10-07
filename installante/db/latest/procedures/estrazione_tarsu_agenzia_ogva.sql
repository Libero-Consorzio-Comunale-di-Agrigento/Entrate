--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tarsu_agenzia_ogva stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARSU_AGENZIA_OGVA
(
p_data_validita in varchar2
)
is
--Dichiarazione variabili
w_numero         number;
w_cod_comune_cat varchar2(4);
w_comune         varchar2(40);
w_sigla_prov     varchar2(2);
w_cod_fiscale_com          varchar2(16);
w_denominazione_com        varchar2(60);
w_comune_sede_legale_com   varchar2(40);
w_sigla_pro_sede_leg_com   varchar2(2);
w_anno_riferimento         varchar2(4);
--sogg.tipo = 1 => Persona giuridica
--altrimenti => Persona fisica
--Si usa lo spazio anzichè null perchè altrimenti nn funziona il pad
cursor sel_tarsu_sog(w_data_validita varchar2) is
   select distinct
          ogva.cod_fiscale                     cod_fiscale
        --Persona fisica
        , upper(decode(sogg.tipo
                         , 1, ' '
                         , nvl(sogg.nome,' ')) )         nome
        , upper(decode(sogg.tipo
                         , 1, ' '
                         , nvl(sogg.cognome,' ')) )      cognome
        , decode(sogg.tipo
                         , 1, ' '
                         , nvl(sogg.sesso,' '))         sesso
        , decode(sogg.tipo
                         , 1, ' '
                         , nvl(to_char(sogg.data_nas, 'ddmmyyyy'),' '))
                                               data_nascita
        , decode(sogg.tipo
                         , 1, ' '
                         , nvl(comf.denominazione,' ')) comune
        , decode(sogg.tipo
                         , 1, ' '
                         , decode(comf.comune
                                            , 0, 'EE'
                                            , nvl(prof.sigla,' ')))
                                               sigla_provincia
        --Persona giuridica
        , upper(decode(sogg.tipo
                         , 1, nvl(sogg.cognome_nome,' ')
                         , ' ') )                denominazione
        , upper(decode(sogg.tipo
                         , 1, nvl(comg.denominazione,' ')
                         , ' ')  )               comune_sede_legale
        , decode(sogg.tipo
                         , 1, nvl(prog.sigla,' ')
                         , ' ')                 sigla_prov_sede_legale
        , substr(w_data_validita,7)             anno_riferimento
     from ad4_comuni       comf
        , ad4_provincie    prof
        , ad4_comuni       comg
        , ad4_provincie    prog
        , oggetti_validita ogva
        , contribuenti     cont
        , soggetti         sogg
        , oggetti_pratica  ogpr
        , oggetti          ogge
    where comf.provincia_stato                   = prof.provincia (+)
      and sogg.cod_pro_nas                       = comf.provincia_stato (+)
      and sogg.cod_com_nas                       = comf.comune (+)
      and comg.provincia_stato                   = prog.provincia (+)
      and sogg.cod_pro_res                       = comg.provincia_stato (+)
      and sogg.cod_com_res                       = comg.comune (+)
      and ogpr.oggetto                           = ogge.oggetto
      and ogva.tipo_tributo || ''                = 'TARSU'
      and ogva.cod_fiscale                       = cont.cod_fiscale
      and cont.ni                                = sogg.ni
      and ogpr.oggetto                           = ogva.oggetto
      and ogva.oggetto_pratica                   = ogpr.oggetto_pratica
      and ogpr.titolo_occupazione                is not null
      and ogpr.natura_occupazione                is not null
      and ogpr.destinazione_uso                  is not null
      and to_date(w_data_validita, 'dd/mm/yyyy') between nvl(ogva.dal,to_date('01/01/0001','dd/mm/yyyy'))
                                                     and nvl(ogva.al,to_date('31/12/9999','dd/mm/yyyy'))
        ;
cursor sel_tarsu_og(w_data_validita varchar2, w_cod_fiscale varchar2) is
   select ogpr.titolo_occupazione titolo_occupazione
        , ogpr.natura_occupazione natura_occupazione
        , nvl(to_char(ogva.dal, 'ddmmyyyy'), '01011900')
                                  inizio_occupazione
        , nvl(to_char(ogva.al, 'ddmmyyyy'), ' ')
                                  fine_occupazione
        , ogpr.destinazione_uso   destinazione_uso
        , decode(ogge.tipo_oggetto
                                 , 3, 'F'
                                 , 5, 'F'
                                 , 1, 'T'
                                 , ' ')
                                  tipo_unita
        , nvl(ogge.sezione, ' ')  sezione
        , nvl(ogge.foglio, ' ')   foglio
        , nvl(ogge.numero, ' ')   particella
        , ' '                     estensione_particella
        , ' '                     tipo_particella
        , nvl(ogge.subalterno, ' ')
                                  subalterno
        , upper(nvl(decode(ogge.cod_via
                            , null, ogge.indirizzo_localita
                            , arcv.denom_uff), ' '))
                                  via
        , nvl(to_char(ogge.num_civ), ' ')
                                  n_civico
        , nvl(to_char(ogge.interno), ' ')
                                  interno
        , nvl(ogge.scala, ' ')    scala
        , decode (ogge.foglio || ogge.numero || ogge.subalterno
                                                              , null, '3'
                                                              , ' ')
                                  cod_assenza_dati_cat
     from oggetti_pratica  ogpr
        , oggetti          ogge
        , oggetti_validita ogva
        , archivio_vie     arcv
    where ogpr.oggetto                           = ogge.oggetto
      and ogva.tipo_tributo||''                  = 'TARSU'
      and ogva.oggetto_pratica                   = ogpr.oggetto_pratica
      and ogge.cod_via                           = arcv.cod_via (+)
      and ogpr.titolo_occupazione                is not null
      and ogpr.natura_occupazione                is not null
      and ogpr.destinazione_uso                  is not null
      and to_date(w_data_validita, 'dd/mm/yyyy') between nvl(ogva.dal,to_date('01/01/0001','dd/mm/yyyy'))
                                                     and nvl(ogva.al,to_date('31/12/9999','dd/mm/yyyy'))
      and ogva.cod_fiscale                       = w_cod_fiscale
        ;
begin
   --Cancello la tabella di lavoro
   begin
    delete wrk_trasmissioni;
   exception
   when others then
    RAISE_APPLICATION_ERROR (-20666,'Errore nella pulizia della tabella di lavoro (' || SQLERRM || ')');
   end;
  w_numero := 0;
   begin
    select comu.sigla_cfis
         , comu.denominazione
         , prov.sigla
      into w_cod_comune_cat
         , w_comune
         , w_sigla_prov
      from dati_generali dage
         , ad4_comuni    comu
         , ad4_provincie prov
     where dage.pro_cliente     = comu.provincia_stato
       and dage.com_cliente     = comu.comune
       and comu.provincia_stato = prov.provincia
         ;
   exception
    when others then
      RAISE_APPLICATION_ERROR (-20666,'Errore nella ricerca del Codice Comune Catastale (' || SQLERRM || ')');
   end;
   -- Estrazione dati del Soggetto ccon i riferimenti del Comune
   begin
    select nvl(sogg.cod_fiscale,sogg.partita_iva)
         , upper(sogg.cognome_nome)
         , comu.denominazione
         , prov.sigla
      into w_cod_fiscale_com
         , w_denominazione_com
         , w_comune_sede_legale_com
         , w_sigla_pro_sede_leg_com
      from soggetti      sogg
         , ad4_comuni    comu
         , ad4_provincie prov
     where sogg.cod_pro_res     = comu.provincia_stato (+)
       and sogg.cod_com_res     = comu.comune (+)
       and comu.provincia_stato = prov.provincia (+)
       and upper(sogg.note)     = 'ANAGRAFICA COMUNE PER TRASMISSIONI'
         ;
   exception
    when others then
      RAISE_APPLICATION_ERROR (-20666,'Errore nella ricerca del Soggetto con i riferimenti del Comune (' || SQLERRM || ')');
   end;
   w_anno_riferimento := substr(p_data_validita,7);
   --Record di testa
   w_numero := w_numero + 1;
   begin
    insert into wrk_trasmissioni(numero
                               , dati)
         values (lpad(w_numero,15,0)
              , '0'                                                --Tipo Record
             || 'SMRIF'                                            --Codice identificativo della fornitura
             || '34'                                               --Codice numerico della fornitura
             || rpad(w_cod_fiscale_com, 16, ' ')                   --Codice Fiscale
             || rpad(' ', 26, ' ')                                 --Cognome
             || rpad(' ', 25, ' ')                                 --Nome
             || ' '                                                --Sesso
             || rpad(' ', 8, ' ')                                  --Data di nascita
             || rpad(' ', 40, ' ')                                 --Comune o Stato estero di nascita
             || rpad(' ', 2, ' ')                                  --Provincia di nascita
             || rpad(w_denominazione_com, 60, ' ')                 --Denominazione
             || rpad(w_comune_sede_legale_com, 40, ' ')            --Comune della sede legale
             || rpad(w_sigla_pro_sede_leg_com, 2, ' ')             --Provincia della sede legale
             || rpad(w_anno_riferimento, 4, ' ')                   --Anno di riferimento
             || rpad(' ', 135, ' ')                                --Filler
             || 'A'                                                --Carattere di controllo
             || 'CR'                                               --Caratteri di fine riga
                )
         ;
   exception
    when others then
      RAISE_APPLICATION_ERROR (-20666,'Errore in inserimento dati Record di testa (' || SQLERRM || ')');
   end;
   for rec_tarsu_sog in sel_tarsu_sog(p_data_validita) loop
      for rec_tarsu_og in sel_tarsu_og(p_data_validita, rec_tarsu_sog.cod_fiscale) loop
         --Record di dettaglio
         w_numero := w_numero + 1;
         begin
          insert into wrk_trasmissioni(numero
                                     , dati)
               values (lpad(w_numero,15,0)
                     , '1'                                                --Tipo Record
                    || rpad(rec_tarsu_sog.cod_fiscale, 16, ' ')           --Codice Fiscale
                    || rpad(rec_tarsu_sog.cognome, 26, ' ')               --Cognome
                    || rpad(rec_tarsu_sog.nome, 25, ' ')                  --Nome
                    || rpad(rec_tarsu_sog.denominazione, 50, ' ')         --Denominazione
                    || rpad(rec_tarsu_sog.comune_sede_legale, 40, ' ')    --Comune della sede legale
                    || rpad(rec_tarsu_sog.sigla_prov_sede_legale, 2, ' ') --Provincia della sede legale
                    || rpad(rec_tarsu_og.titolo_occupazione, 1, ' ')      --Titolo occupazione/detenzione
                    || rpad(rec_tarsu_og.natura_occupazione, 1, ' ')      --Occupazione singolo o nucleo familiare
                    || rpad(rec_tarsu_og.inizio_occupazione, 8, ' ')      --Data di inizio occupazione
                    || rpad(rec_tarsu_og.fine_occupazione, 8, ' ')        --Data di fine occupazione
                    || rpad(rec_tarsu_og.destinazione_uso, 1, ' ')        --Destinazione uso immobile
                    || rpad(w_comune, 20, ' ')                            --Comune amministrativo di ubicazione immobile
                    || rpad(w_sigla_prov, 2, ' ')                         --Provincia di ubicazione immobile
                    || rpad(' ', 20, ' ')                                 --Comune catastale di ubicazione immobile
                    || rpad(w_cod_comune_cat, 5, ' ')                     --Codice Comune Catastale
                    || rpad(rec_tarsu_og.tipo_unita, 1, ' ')              --Tipo Unità
                    || rpad(rec_tarsu_og.sezione, 3, ' ')                 --Sezione
                    || rpad(rec_tarsu_og.foglio, 5, ' ')                  --Foglio
                    || rpad(rec_tarsu_og.particella, 5, ' ')              --Particella
                    || rpad(rec_tarsu_og.estensione_particella, 4, ' ')   --Estensione Particella
                    || rpad(rec_tarsu_og.tipo_particella, 1, ' ')         --Tipo Particella
                    || rpad(rec_tarsu_og.subalterno, 4, ' ')              --Subalterno
                    || rpad(rec_tarsu_og.via, 30, ' ')                    --Via/Piazza/C.so
                    || rpad(rec_tarsu_og.n_civico, 6, ' ')                --N. Civico
                    || rpad(rec_tarsu_og.interno, 2, ' ')                 --Interno
                    || rpad(rec_tarsu_og.scala, 1, ' ')                   --Scala
                    || rpad(rec_tarsu_og.cod_assenza_dati_cat, 1, ' ')    --Codice assenza dati catastali
                    || rpad(' ', 78, ' ')                                 --Filler
                    || 'A'                                                --Carattere di controllo
                    || 'CR'                                               --Caratteri di fine riga
                      )
                ;
         exception
          when others then
            RAISE_APPLICATION_ERROR (-20666,'Errore in inserimento dati Record di dettaglio (' || SQLERRM || ')');
         end;
      end loop; --sel_tarsu_sog
   end loop; --sel_tarsu_sog
   --Record di coda
   w_numero := w_numero + 1;
   begin
    insert into wrk_trasmissioni(numero
                               , dati)
         values (lpad(w_numero,15,0)
              , '9'                                                --Tipo Record
             || 'SMRIF'                                            --Codice identificativo della fornitura
             || '34'                                               --Codice numerico della fornitura
             || rpad(w_cod_fiscale_com, 16, ' ')                   --Codice Fiscale
             || rpad(' ', 26, ' ')                                 --Cognome
             || rpad(' ', 25, ' ')                                 --Nome
             || ' '                                                --Sesso
             || rpad(' ', 8, ' ')                                  --Data di nascita
             || rpad(' ', 40, ' ')                                 --Comune o Stato estero di nascita
             || rpad(' ', 2, ' ')                                  --Provincia di nascita
             || rpad(w_denominazione_com, 60, ' ')                 --Denominazione
             || rpad(w_comune_sede_legale_com, 40, ' ')            --Comune della sede legale
             || rpad(w_sigla_pro_sede_leg_com, 2, ' ')             --Provincia della sede legale
             || rpad(w_anno_riferimento, 4, ' ')                   --Anno di riferimento
             || rpad(' ', 135, ' ')                                --Filler
             || 'A'                                                --Carattere di controllo
             || 'CR'                                               --Caratteri di fine riga
                )
         ;
   exception
    when others then
      RAISE_APPLICATION_ERROR (-20666,'Errore in inserimento dati Record di coda (' || SQLERRM || ')');
   end;
   commit;
end;
/* End Procedure: ESTRAZIONE_TARSU_AGENZIA_OGVA */
/

