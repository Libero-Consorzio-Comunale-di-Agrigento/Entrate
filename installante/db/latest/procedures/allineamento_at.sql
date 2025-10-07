--liquibase formatted sql 
--changeset abrandolini:20250326_152423_allineamento_at stripComments:false runOnChange:true 
 
create or replace procedure ALLINEAMENTO_AT
/***************************************************************************
  NOME:        ALLINEAMENTO_AT
  DESCRIZIONE: Aggiorna i dati anagrafici (indirizzo) dei soggetti per cui
               sono state rilevate differenze rispetto all'anagrafe tributaria.
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  003   10/05/2023  RV      #60284-feedback
                            Modifica gestione stato e note per P.G.
  002   06/03/2023  RV      #60284
                            Modifica verifica data decesso e data fine attivita'
  001   25/11/2022  AB      Trattamento dei soli cod.Ritorno = '0000'
  000   30/05/2022  VD      Prima emissione
***************************************************************************/
( p_elaborazione_id         number
, p_attivita_id             number
, p_dettaglio_id            number
, p_messaggio               out varchar2
) is
  w_conta                   number;
  w_num_trattati            number;
  w_num_scartati            number;
  w_messaggio               varchar2(2000);
  w_messaggio_agg_at        varchar2(100);
  w_ni                      number;
  w_cod_fiscale             varchar2(16);
  w_cod_via                 number;
  w_denominazione_via       varchar2(60);
  w_num_civ                 number;
  w_suffisso                varchar2(10);
  w_scala                   varchar2(5);
  w_piano                   varchar2(5);
  w_interno                 number;
  w_cod_com_res             number;
  w_cod_pro_res             number;
  w_cap_res                 number;
  w_ni_presso               number;
  w_stato                   number(2);
  w_data_ult_eve            date;
  errore                    exception;
begin
  -- Si controlla l'esistenza di risposte alle interrogazioni inviate
  begin
    select count(*)
      into w_conta
      from elaborazioni_massive  elma
         , dettagli_elaborazione deel
         , attivita_elaborazione atel
         , sam_interrogazioni    sain
         , sam_risposte          sari
     where elma.elaborazione_id = p_elaborazione_id
       and elma.elaborazione_id = deel.elaborazione_id
       and elma.elaborazione_id = atel.elaborazione_id
       and atel.attivita_id     = p_attivita_id
       and ((p_dettaglio_id is null and deel.flag_selezionato = 'S') or
            (p_dettaglio_id is not null and p_dettaglio_id = deel.dettaglio_id))
       and sain.elaborazione_id = p_elaborazione_id
       and sain.interrogazione  = sari.interrogazione
       and sain.cod_fiscale     = deel.cod_fiscale
       and trim(sari.cod_ritorno) in ('0000')
       and deel.note is not null;
  exception
    when others then
      w_conta := 0;
  end;
  --
  if w_conta = 0 then
     w_messaggio := 'Non esistono soggetti da allineare!';
     raise errore;
  end if;
  -- Trattamento soggetti
  w_num_trattati := 0;
  w_num_scartati := 0;
  for anag in (select deel.dettaglio_id
                    , elma.tipo_tributo
                    , sari.tipo_record           sari_tipo_record
                    , sari.cod_fiscale           sari_cod_fiscale
                    , sari.data_domicilio        sari_data_domicilio
                    , sari.indirizzo_domicilio   sari_indirizzo_res
                    , decode(sari.comune_domicilio
                            ,null,to_number(null)
                            ,ad4_comune.get_comune(sari.comune_domicilio
                                                  ,sari.provincia_domicilio
                                                  )
                            )                    sari_comune_res
                    , decode(sari.provincia_domicilio
                            ,null,to_number(null)
                            ,ad4_provincia.get_provincia(''
                                                        ,sari.provincia_domicilio
                                                        )
                            )                    sari_prov_res
                    , sari.cap_domicilio         sari_cap_res
                    , sari.indirizzo_sede_legale sari_indirizzo_sede
                    , decode(sari.comune_sede_legale
                            ,null,to_number(null)
                            ,ad4_comune.get_comune(sari.comune_sede_legale
                                                  ,sari.provincia_sede_legale
                                                  )
                            )                    sari_comune_sede
                    , decode(sari.provincia_sede_legale
                            ,null,to_number(null)
                            ,ad4_provincia.get_provincia(''
                                                        ,sari.provincia_sede_legale
                                                        )
                            )                    sari_prov_sede
                    , sari.cap_sede_legale       sari_cap_sede
                    , sari.data_decesso          sari_data_decesso
                    , sari.data_fine_attivita    sari_data_fine_attivita
                    , deel.note
                 from elaborazioni_massive  elma
                    , dettagli_elaborazione deel
                    , sam_interrogazioni    sain
                    , sam_risposte          sari
                where elma.elaborazione_id = p_elaborazione_id
                  and elma.elaborazione_id = deel.elaborazione_id
                  and deel.controllo_at_id is not null
                  and deel.allineamento_at_id is null
                  and ((p_dettaglio_id is null and deel.flag_selezionato = 'S') or
                       (p_dettaglio_id is not null and p_dettaglio_id = deel.dettaglio_id))
                  and sain.elaborazione_id = p_elaborazione_id
                  and sain.interrogazione  = sari.interrogazione
                  and sain.cod_fiscale     = deel.cod_fiscale
                  and deel.note is not null
                  and trim(sari.cod_ritorno) in ('0000')
                order by deel.dettaglio_id)
  loop
    w_messaggio := null;
    -- Conteggio record trattati per effettuare il commit ogni 10 righe
    w_num_trattati := w_num_trattati + 1;
    if mod(w_num_trattati,10) = 0 then
       commit;
    end if;
--dbms_output.put_line('Cod.fiscale: '||anag.sari_cod_fiscale);
    -- Si selezionano i dati del soggetto da aggiornare
    begin
      select sogg.ni
           , sogg.cod_fiscale
           , sogg.cod_via
           , sogg.denominazione_via
           , sogg.num_civ
           , sogg.suffisso
           , sogg.scala
           , sogg.piano
           , sogg.interno
           , sogg.cod_com_res
           , sogg.cod_pro_res
           , sogg.cap
           , sogg.ni_presso
           , sogg.stato
           , sogg.data_ult_eve
        into w_ni
           , w_cod_fiscale
           , w_cod_via
           , w_denominazione_via
           , w_num_civ
           , w_suffisso
           , w_scala
           , w_piano
           , w_interno
           , w_cod_com_res
           , w_cod_pro_res
           , w_cap_res
           , w_ni_presso
           , w_stato
           , w_data_ult_eve
        from contribuenti cont
           , soggetti sogg
       where cont.cod_fiscale = anag.sari_cod_fiscale
         and cont.ni          = sogg.ni;
    exception
      when others then
        w_messaggio := 'Contribuente '||anag.sari_cod_fiscale||' da aggiornare '||
                       'non presente';
        raise errore;
    end;
    -- Trattamento indirizzi variati: si esegue l'aggiornamento solo se
    -- il codice fiscale di ritorno corrisponde a quello presente su
    -- soggetti
    if anag.sari_cod_fiscale = w_cod_fiscale then
       w_messaggio_agg_at := 'Agg. automatico da Anagrafe Tributaria del '||to_char(sysdate,'dd/mm/yyyy');
       if (anag.sari_tipo_record = 1 and
          (anag.note like '%Data decesso%'))then
          -- Si aggiorna la data di decesso P.F.
--dbms_output.put_line('Data decesso : ('||w_ni||') '||anag.sari_data_decesso);
          begin
            update soggetti sogg
               set sogg.stato             = decode(anag.sari_data_decesso,null,null,50)
                 , sogg.data_ult_eve      = anag.sari_data_decesso
                 , sogg.note              = 'Data decesso '||to_char(anag.sari_data_decesso,'dd/mm/yyyy')||
                                            ' - '||w_messaggio_agg_at||
                                            decode(sogg.note,'','',' - '||sogg.note)
             where sogg.ni = w_ni;
          exception
            when others then
              w_messaggio := substr('Update SOGGETTI (Ni: '||w_ni||') - '||sqlerrm,1,2000);
              raise errore;
          end;
       end if;
       if (anag.sari_tipo_record = 2 and
          (anag.note like '%Cessazione Attività%')) then
          -- Si aggiorna la data di fine attivita' P.G.
--dbms_output.put_line('Cessazione attività : ('||w_ni||') '||anag.sari_data_fine_attivita);
          begin
            update soggetti sogg
               set sogg.stato             = decode(anag.sari_data_fine_attivita,null,null,-1)
                 , sogg.data_ult_eve      = anag.sari_data_fine_attivita
                 , sogg.note              = 'Cessazione Attività '||to_char(anag.sari_data_fine_attivita,'dd/mm/yyyy')||
                                            ' - '||w_messaggio_agg_at||
                                            decode(sogg.note,'','',' - '||sogg.note)
             where sogg.ni = w_ni;
          exception
            when others then
              w_messaggio := substr('Update SOGGETTI (Ni: '||w_ni||') - '||sqlerrm,1,2000);
              raise errore;
          end;
       end if;
       if (anag.sari_tipo_record = 1 and
          (anag.note like '%Comune dom.fiscale%' or
           anag.note like '%Provincia dom.fiscale%' or
           anag.note like '%CAP dom.fiscale%' or
           anag.note like '%Indirizzo dom.fiscale%')) or
          (anag.sari_tipo_record = 2 and
          (anag.note like '%Comune sede legale%' or
           anag.note like '%Provincia sede legale%' or
           anag.note like '%CAP sede legale%' or
           anag.note like '%Indirizzo sede legale%')) then
          -- Si aggiorna la data di fine validita' di eventuali recapiti
          -- presenti in tabella validi alla data di elaborazione
          begin
            update recapiti_soggetto reso
               set al = trunc(sysdate) - 1
                 , note = w_messaggio_agg_at||
                          decode(note,'','',' - '||note)
             where reso.ni = w_ni
               and reso.tipo_tributo = anag.tipo_tributo
               and reso.tipo_recapito = 1
               and trunc(sysdate) between nvl(dal,to_date('01011901','ddmmyyyy'))
                                      and nvl(al,to_date('31129999','ddmmyyyy'));
          exception
            when others then
              w_messaggio := substr('Update RECAPITI_SOGGETTO (Ni: '||w_ni||
                                    ', Tipo tributo: '||anag.tipo_tributo||') - '||
                                    sqlerrm,1,2000);
              raise errore;
          end;
          -- Si aggiorna la data di fine validita' di eventuali recapiti
          -- presenti in tabella con inizio validita' successivo alla
          -- data di elaborazione
          begin
            update recapiti_soggetto reso
               set al = dal
                 , note = w_messaggio_agg_at||
                          decode(note,'','',' - '||note)
             where reso.ni = w_ni
               and reso.tipo_tributo = anag.tipo_tributo
               and reso.tipo_recapito = 1
               and nvl(dal,to_date('01011901','ddmmyyyy')) > trunc(sysdate);
          exception
            when others then
              w_messaggio := substr('Update RECAPITI_SOGGETTO 2 (Ni: '||w_ni||
                                    ', Tipo tributo: '||anag.tipo_tributo||') - '||
                                    sqlerrm,1,2000);
              raise errore;
          end;
          -- Si inserisce il recapito presente in tabella SOGGETTI nella
          -- tabella RECAPITI_SOGGETTO con data di fine validita'
          begin
            insert into RECAPITI_SOGGETTO
                 ( ni
                 , tipo_tributo
                 , tipo_recapito
                 , descrizione
                 , cod_via
                 , num_civ
                 , suffisso
                 , scala
                 , piano
                 , interno
                 , dal
                 , al
                 , utente
                 , data_variazione
                 , note
                 , cod_pro
                 , cod_com
                 , cap
                 , zipcode
                 , presso
                 )
            values
                 ( w_ni
                 , anag.tipo_tributo
                 , 1
                 , w_denominazione_via
                 , w_cod_via
                 , w_num_civ
                 , w_suffisso
                 , w_scala
                 , w_piano
                 , w_interno
                 , trunc(sysdate) - 1
                 , trunc(sysdate) - 1
                 , 'AN.TR.'
                 , trunc(sysdate)
                 , 'Agg. automatico da A.T. del '||to_char(sysdate,'dd/mm/yyyy')
                 , w_cod_pro_res
                 , w_cod_com_res
                 , w_cap_res
                 , null
                 , (select sogg.cognome_nome
                      from soggetti sogg
                     where ni = w_ni_presso
                       and w_ni_presso is not null)
                 );
          exception
            when others then
              w_messaggio := substr('Insert RECAPITI_SOGGETTO (Ni: '||w_ni||
                                    ', Tipo tributo: '||anag.tipo_tributo||') - '||
                                    sqlerrm,1,2000);
              raise errore;
          end;
          -- Si aggiorna la tabella SOGGETTI con il nuovo indirizzo
          begin
            update soggetti sogg
               set sogg.cod_via           = null
                 , sogg.num_civ           = null
                 , sogg.suffisso          = null
                 , sogg.piano             = null
                 , sogg.scala             = null
                 , sogg.interno           = null
                 , sogg.ni_presso         = null
                 , sogg.denominazione_via = decode(anag.sari_tipo_record
                                                  ,1,anag.sari_indirizzo_res
                                                  ,anag.sari_indirizzo_sede)
                 , sogg.cod_com_res       = decode(anag.sari_tipo_record
                                                  ,1,anag.sari_comune_res
                                                  ,anag.sari_comune_sede)
                 , sogg.cod_pro_res       = decode(anag.sari_tipo_record
                                                  ,1,anag.sari_prov_res
                                                  ,anag.sari_prov_sede)
                 , sogg.cap               = decode(anag.sari_tipo_record
                                                  ,1,anag.sari_cap_res
                                                  ,anag.sari_cap_sede)
                 , sogg.note              = w_messaggio_agg_at||
                                            decode(anag.sari_data_domicilio,'','',' - Residenza dal '||to_char(anag.sari_data_domicilio,'dd/mm/yyyy'))||
                                            decode(sogg.note,'','',' - '||sogg.note)
             where sogg.ni = w_ni;
          exception
            when others then
              w_messaggio := substr('Update SOGGETTI (Ni: '||w_ni||') - '||sqlerrm,1,2000);
              raise errore;
          end;
          w_messaggio := 'Allineamento indirizzo eseguito';
       end if;
    else
       w_messaggio := 'Codici fiscali non congruenti - Allineamento non eseguito';
    end if;
    -- Aggiornamento dettaglio elaborazione
    begin
      update dettagli_elaborazione
         set allineamento_at_id = p_attivita_id
           , note = substr(note||decode(w_messaggio
                                       ,null,null
                                       ,' : '||w_messaggio),1,2000)
       where dettaglio_id = anag.dettaglio_id;
    exception
      when others then
        w_messaggio := substr('Update DETTAGLI_ELABORAZIONE (Id: '||anag.dettaglio_id||
                              ') - '||sqlerrm,1,2000);
        raise errore;
    end;
  end loop;
  --
  w_messaggio := 'Soggetti - elaborati: '||w_num_trattati;
  p_messaggio := w_messaggio;
exception
  when errore then
    p_messaggio := w_messaggio;
    RAISE_APPLICATION_ERROR
       (-20999,p_messaggio);
  when others then
    raise;
end;
/* End Procedure: ALLINEAMENTO_AT */
/

