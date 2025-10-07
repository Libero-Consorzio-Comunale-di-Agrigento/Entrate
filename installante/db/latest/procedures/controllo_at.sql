--liquibase formatted sql 
--changeset abrandolini:20250326_152423_controllo_at stripComments:false runOnChange:true 
 
create or replace procedure CONTROLLO_AT
/***************************************************************************
  NOME:        CONTROLLO_AT
  DESCRIZIONE: Esegui i controlli sui dati da allineare provenienti
               dall'anagrafe tributaria.
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  004   04/10/2023  RV      #67132
                            Modificato condizione check data_decesso per P.F.
  003   10/05/2023  RV      #60284-feedback
                            Modifica gestione note per P.G.
  002   06/03/2023  RV      #60284
                            Modifica verifica data decesso + integrazione data fine attivita'
  001   25/11/2022  AB      Sistemate nvl di controllo e cod.Ritorno nelle note
  000   23/05/2022  VD      Prima emissione
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

  w_ni                      number;
  w_cod_fiscale             varchar2(16);
  w_tipo_residente          number;
  w_fascia                  number;
  w_cognome                 varchar2(100);
  w_nome                    varchar2(100);
  w_sesso                   varchar2(1);
  w_data_nas                date;
  w_comune_nas              varchar2(100);
  w_prov_nas                varchar2(2);
  w_indirizzo_res_orig      varchar2(200);
  w_indirizzo_res           varchar2(200);
  w_comune_res              varchar2(100);
  w_prov_res                varchar2(2);
  w_cap_res                 number;
  w_data_decesso            date;
  w_data_ult_eve            date;
  w_denominazione           varchar2(200);
  w_partita_iva             varchar2(11);
  w_indirizzo_sede_orig     varchar2(200);
  w_indirizzo_sede          varchar2(200);
  w_comune_sede             varchar2(100);
  w_prov_sede               varchar2(2);
  w_cap_sede                number;

  errore                    exception;
begin
  -- Si controlla l'esistenza di risposte alle interrogazioni inviate
  begin
    select count(*)
      into w_conta
      from sam_interrogazioni sain
         , sam_risposte       sari
     where sain.elaborazione_id = p_elaborazione_id
       and sain.interrogazione  = sari.interrogazione;
  exception
    when others then
      w_conta := 0;
  end;
  --
  if w_conta = 0 then
     w_messaggio := 'Flusso di Ritorno Anagrafe Tributaria assente!';
     raise errore;
  end if;
  -- Trattamento soggetti
  w_num_trattati := 0;
  w_num_scartati := 0;
  for anag in (select distinct deel.dettaglio_id
                    , sari.tipo_record           sari_tipo_record
                    , sari.cod_fiscale           sari_cod_fiscale
                    , sari.cognome               sari_cognome
                    , sari.nome                  sari_nome
                    , sari.sesso                 sari_sesso
                    , sari.data_nascita          sari_data_nas
                    , sari.comune_nascita        sari_comune_nas
                    , sari.provincia_nascita     sari_prov_nas
                    , sari.indirizzo_domicilio   sari_indirizzo_res_orig
                    , replace(sari.indirizzo_domicilio
                             ,' ','')            sari_indirizzo_res
                    , sari.comune_domicilio      sari_comune_res
                    , sari.provincia_domicilio   sari_prov_res
                    , sari.cap_domicilio         sari_cap_res
                    , sari.data_decesso          sari_data_decesso
                    , sari.denominazione         sari_denominazione
                    , sari.partita_iva           sari_partita_iva
                    , sari.indirizzo_sede_legale sari_indirizzo_sede_orig
                    , replace(sari.indirizzo_sede_legale
                             ,' ','')            sari_indirizzo_sede
                    , sari.comune_sede_legale    sari_comune_sede
                    , sari.provincia_sede_legale sari_prov_sede
                    , sari.cap_sede_legale       sari_cap_sede
                    , sari.data_inizio_attivita  sari_data_iniz_attivita
                    , sari.data_fine_attivita    sari_data_fine_attivita
                    , sari.cod_ritorno           sari_cod_ritorno
                 from elaborazioni_massive  elma
                    , dettagli_elaborazione deel
                    , attivita_elaborazione atel
                    , sam_interrogazioni    sain
                    , sam_risposte          sari
                where elma.elaborazione_id = p_elaborazione_id
                  and elma.elaborazione_id = deel.elaborazione_id
                  and elma.elaborazione_id = atel.elaborazione_id
                  and atel.attivita_id     = p_attivita_id
                  and deel.allineamento_at_id is null
                  and ((p_dettaglio_id is null and deel.flag_selezionato = 'S') or
                       (p_dettaglio_id is not null and p_dettaglio_id = deel.dettaglio_id))
                  and sain.elaborazione_id = p_elaborazione_id
                  and sain.interrogazione  = sari.interrogazione
                  and sain.cod_fiscale     = deel.cod_fiscale
                order by deel.dettaglio_id)
  loop
    w_messaggio := null;
    w_num_trattati := w_num_trattati + 1;
    if mod(w_num_trattati,10) = 0 then
       commit;
    end if;
--dbms_output.put_line('Cod.fiscale: '||anag.sari_cod_fiscale);
    -- Trattamento persone fisiche
    if anag.sari_tipo_record = 1 then
--dbms_output.put_line('PF');
       begin
         select sogg.ni
              , sogg.cod_fiscale
              , sogg.tipo_residente
              , sogg.fascia
              , sogg.cognome
              , sogg.nome
              , sogg.sesso
              , sogg.data_nas
              , comu_nas.denominazione
              , prov_nas.sigla
              , decode(sogg.cod_via
                      ,null,denominazione_via
                      ,arvi.denom_uff
                      )||
                decode(sogg.num_civ,'','',' '||sogg.num_civ)||
                decode(sogg.suffisso,'','','/'||sogg.suffisso)
              , replace(decode(sogg.cod_via
                              ,null,denominazione_via
                              ,arvi.denom_uff
                              )||
                        decode(sogg.num_civ,'','',sogg.num_civ)||
                        decode(sogg.suffisso,'','',sogg.suffisso)
                       ,' ','')
              , comu_res.denominazione
              , prov_res.sigla
              , sogg.cap
              , decode(sogg.stato,50,sogg.data_ult_eve,null) data_decesso
              , sogg.data_ult_eve
           into w_ni
              , w_cod_fiscale
              , w_tipo_residente
              , w_fascia
              , w_cognome
              , w_nome
              , w_sesso
              , w_data_nas
              , w_comune_nas
              , w_prov_nas
              , w_indirizzo_res_orig
              , w_indirizzo_res
              , w_comune_res
              , w_prov_res
              , w_cap_res
              , w_data_decesso
              , w_data_ult_eve
           from contribuenti cont
              , soggetti sogg
              , ad4_comuni comu_nas
              , ad4_province prov_nas
              , ad4_comuni comu_res
              , ad4_province prov_res
              , archivio_vie arvi
          where cont.cod_fiscale = anag.sari_cod_fiscale
            and cont.ni          = sogg.ni
            and sogg.cod_com_nas = comu_nas.comune (+)
            and sogg.cod_pro_nas = comu_nas.provincia_stato (+)
            and sogg.cod_pro_nas = prov_nas.provincia (+)
            and sogg.cod_com_res = comu_res.comune (+)
            and sogg.cod_pro_res = comu_res.provincia_stato (+)
            and sogg.cod_pro_res = prov_res.provincia (+)
            and sogg.cod_via     = arvi.cod_via (+);
       exception
         when others then
           w_ni             := to_number(null);
       end;
       --
--dbms_output.put_line('Ni: '||w_ni);
       if w_ni is not null then
          if w_tipo_residente  = 0 and
             w_fascia in (1,3) then
             w_num_scartati := w_num_scartati + 1;
             w_messaggio    := 'Soggetto residente - allineamento non possibile';
          else
             if anag.sari_cod_fiscale <> nvl(w_cod_fiscale,' ') then
                w_messaggio := w_messaggio||'Codice fiscale - soggetti: '||w_cod_fiscale||', A.T.: '||anag.sari_cod_fiscale||'; ';
             end if;
             if anag.sari_cognome <> nvl(w_cognome,' ') then
                w_messaggio := w_messaggio||'Cognome - soggetti: '||w_cognome||', A.T.: '||anag.sari_cognome||'; ';
             end if;
             if anag.sari_nome <> nvl(w_nome,' ') then
                w_messaggio := w_messaggio||'Nome - soggetti: '||w_nome||', A.T.: '||anag.sari_nome||'; ';
             end if;
             if anag.sari_sesso <> nvl(w_sesso,' ') then
                w_messaggio := w_messaggio||'Sesso - soggetti: '||w_sesso||', A.T.: '||anag.sari_sesso||'; ';
             end if;
             if anag.sari_data_nas <> w_data_nas then
                w_messaggio := w_messaggio||'Data di nascita - soggetti: '||to_char(w_data_nas,'dd/mm/yyyy')
                                          ||', A.T.: '||to_char(anag.sari_data_nas,'dd/mm/yyyy')||'; ';
             end if;
             if anag.sari_comune_nas <> nvl(w_comune_nas,' ') then
                w_messaggio := w_messaggio||'Comune di nascita - soggetti: '||w_comune_nas
                                          ||', A.T.: '||anag.sari_comune_nas||'; ';
             end if;
             if anag.sari_prov_nas <> nvl(w_prov_nas,' ') then
                w_messaggio := w_messaggio||'Provincia di nascita - soggetti: '||w_prov_nas
                                          ||', A.T.: '||anag.sari_prov_nas||'; ';
             end if;
             if anag.sari_comune_res <> nvl(w_comune_res,' ') then
                w_messaggio := w_messaggio||'Comune dom.fiscale - soggetti: '||w_comune_res
                                          ||', A.T.: '||anag.sari_comune_res||'; ';
             end if;
             if anag.sari_prov_res <> nvl(w_prov_res,' ') then
                w_messaggio := w_messaggio||'Provincia dom.fiscale - soggetti: '||w_prov_res
                                          ||', A.T.: '||anag.sari_prov_res||'; ';
             end if;
             if anag.sari_cap_res <> nvl(w_cap_res,0) then
                w_messaggio := w_messaggio||'CAP dom.fiscale - soggetti: '||w_cap_res
                                          ||', A.T.: '||anag.sari_cap_res||'; ';
             end if;
             if anag.sari_indirizzo_res <> nvl(w_indirizzo_res,' ')  then
                w_messaggio := w_messaggio||'Indirizzo dom.fiscale - soggetti: '||w_indirizzo_res_orig
                                          ||', A.T.: '||anag.sari_indirizzo_res_orig||'; ';
             end if;
             if nvl(anag.sari_data_decesso,TO_DATE('31122999','ddmmyyyy')) <>
                            nvl(w_data_decesso,TO_DATE('31122999','ddmmyyyy')) then
                w_messaggio := w_messaggio||'Data decesso - soggetti: '||
                                   TO_CHAR(w_data_decesso,'dd/mm/yyyy')||', A.T.: '||
                                       TO_CHAR(anag.sari_data_decesso,'dd/mm/yyyy')||'; ';
             end if;
          end if;
       else
          w_messaggio := 'Cod.Ritorno: '||anag.sari_cod_ritorno||' Contribuente '||anag.sari_cod_fiscale||' non esistente in anagrafe';
       end if;
    end if;
    -- Trattamento persone giuridiche
    if anag.sari_tipo_record = 2 then
--dbms_output.put_line('PG');
       begin
         select sogg.ni
              , sogg.cod_fiscale
              , sogg.tipo_residente
              , sogg.fascia
              , sogg.cognome_nome
              , sogg.partita_iva
              , decode(sogg.cod_via
                      ,null,denominazione_via
                      ,arvi.denom_uff
                      )||
                decode(sogg.num_civ,'','',sogg.num_civ)||
                decode(sogg.suffisso,'','',sogg.suffisso)
              , replace(decode(sogg.cod_via
                              ,null,denominazione_via
                              ,arvi.denom_uff
                              )||
                        decode(sogg.num_civ,'','',sogg.num_civ)||
                        decode(sogg.suffisso,'','',sogg.suffisso)
                       ,' ','')
              , comu_res.denominazione
              , prov_res.sigla
              , sogg.cap
              , sogg.data_ult_eve
           into w_ni
              , w_cod_fiscale
              , w_tipo_residente
              , w_fascia
              , w_denominazione
              , w_partita_iva
              , w_indirizzo_sede_orig
              , w_indirizzo_sede
              , w_comune_sede
              , w_prov_sede
              , w_cap_sede
              , w_data_ult_eve
           from contribuenti cont
              , soggetti sogg
              , ad4_comuni comu_res
              , ad4_province prov_res
              , archivio_vie arvi
          where cont.cod_fiscale = anag.sari_cod_fiscale
            and cont.ni          = sogg.ni
            and sogg.cod_com_res = comu_res.comune (+)
            and sogg.cod_pro_res = comu_res.provincia_stato (+)
            and sogg.cod_pro_res = prov_res.provincia (+)
            and sogg.cod_via     = arvi.cod_via (+);
       exception
         when others then
           w_ni             := to_number(null);
       end;
       --
       if w_ni is not null then
--dbms_output.put_line('Ni: '||w_ni);
          if w_tipo_residente  = 0 and
             w_fascia in (1,3) then
             w_num_scartati := w_num_scartati + 1;
             w_messaggio    := 'Soggetto residente - allineamento non possibile';
          else
             if anag.sari_cod_fiscale <> nvl(w_cod_fiscale,' ') then
                w_messaggio := w_messaggio||'Codice fiscale - soggetti: '||w_cod_fiscale||', A.T.: '||anag.sari_cod_fiscale||'; ';
             end if;
             if anag.sari_denominazione <> nvl(w_denominazione,' ') then
                w_messaggio := w_messaggio||'Denominazione - soggetti: '||w_denominazione||', A.T.: '||anag.sari_denominazione||'; ';
             end if;
             if anag.sari_partita_iva <> nvl(w_partita_iva,' ') then
                w_messaggio := w_messaggio||'Partita IVA - soggetti: '||w_partita_iva||', A.T.: '||anag.sari_partita_iva||'; ';
             end if;
             if anag.sari_comune_sede <> nvl(w_comune_sede,' ') then
                w_messaggio := w_messaggio||'Comune sede legale - soggetti: '||w_comune_sede
                                          ||', A.T.: '||anag.sari_comune_sede||'; ';
             end if;
             if anag.sari_prov_sede <> nvl(w_prov_sede,' ') then
                w_messaggio := w_messaggio||'Provincia sede legale - soggetti: '||w_prov_sede
                                          ||', A.T.: '||anag.sari_prov_sede||'; ';
             end if;
             if anag.sari_cap_sede <> nvl(w_cap_sede,0) then
                w_messaggio := w_messaggio||'CAP sede legale - soggetti: '||w_cap_sede
                                          ||', A.T.: '||anag.sari_cap_sede||'; ';
             end if;
             if anag.sari_indirizzo_sede <> nvl(w_indirizzo_sede,' ') then
                w_messaggio := w_messaggio||'Indirizzo sede legale - soggetti: '||w_indirizzo_sede_orig
                                          ||', A.T.: '||anag.sari_indirizzo_sede_orig||'; ';
             end if;
             if nvl(anag.sari_data_fine_attivita,TO_DATE('31122999','ddmmyyyy')) <>
                            nvl(w_data_ult_eve,TO_DATE('31122999','ddmmyyyy')) then
                w_messaggio := w_messaggio||'Cessazione Attività - soggetti: '||
                               TO_CHAR(w_data_ult_eve,'dd/mm/yyyy')||', A.T.: '||
                               TO_CHAR(anag.sari_data_fine_attivita,'dd/mm/yyyy')||'; ';
             end if;
          end if;
       else
          w_messaggio := 'Cod.Ritorno: '||anag.sari_cod_ritorno||' Contribuente '||anag.sari_cod_fiscale||' non esistente in anagrafe';
       end if;
    end if;
    -- Aggiornamento dettaglio elaborazione
    begin
      update dettagli_elaborazione
         set controllo_at_id = p_attivita_id
           , note = substr(w_messaggio,1,2000)
       where dettaglio_id = anag.dettaglio_id;
    exception
      when others then
        raise;
    end;
  end loop;
  --
  w_messaggio := 'Soggetti - elaborati: '||w_num_trattati||
                 ', non trattati: '||w_num_scartati;
  p_messaggio := w_messaggio;
exception
  when errore then
    p_messaggio := w_messaggio;
    RAISE_APPLICATION_ERROR
       (-20999,p_messaggio);
  when others then
    raise;
end;
/* End Procedure: CONTROLLO_AT */
/
