--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tarsu_asa stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARSU_ASA
/*************************************************************************
 NOME:        ESTRAZIONE_TARSU_ASA
 DESCRIZIONE: Estrazione TARSU maggiorenni non morosi
              Comune di Albano Sant'Alessandro
 NOTE:
 Rev.    Date         Author      Note
 001     12/02/2018   VD          Aggiunti dati anagrafici, soggetti non
                                  residenti e persone giuridiche
 000     17/07/2012   XX          Prima emissione.
*************************************************************************/
( a_ruolo                   in number,
  a_data_rif                date
) is
  --Dichiarazione variabili
  w_numero                  number;
  w_anno                    number;
  cursor sel_cont(a_ruolo number, a_data_rif date, a_anno number) is
    select 1 tipo
         , replace(sogg.cognome,';','')        cognome
         , replace(sogg.nome,';','')           nome
         , replace(sogg.cod_fiscale,';','')    cod_fiscale
         , sogg.cod_fam        cod_famiglia
         , sogg.sesso
         , ad4_comune.get_denominazione(sogg.cod_pro_nas,sogg.cod_com_nas) comune_nascita
         , to_char(sogg.data_nas,'dd/mm/yyyy') data_nascita
         , ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res) comune_residenza
         , nvl(arvi.denom_uff,sogg.denominazione_via) via_residenza
         , sogg.num_civ num_civ_residenza
         , 'RES.' des_tipo
      from soggetti sogg,
           archivio_vie arvi
     where add_months(sogg.data_nas, 216) < a_data_rif
       and sogg.fascia + 0 = 1
       and sogg.cod_via = arvi.cod_via (+)
       and cod_fam in (select distinct cod_fam
                                  from soggetti     sogg
                                     , contribuenti cont
                                     , versamenti   vers
                                 where sogg.fascia + 0  = 1
                                   and sogg.ni          = cont.ni
                                   and cont.cod_fiscale = vers.cod_fiscale
                                   and (vers.ruolo       = a_ruolo or
                                       (vers.tipo_tributo||'' = 'TARSU' and
                                        vers.anno        = a_anno)))
    union
    select 2 tipo
         , replace(sogg.cognome,';','')        cognome
         , replace(sogg.nome,';','')           nome
         , replace(cont.cod_fiscale,';','')    cod_fiscale
         , sogg.cod_fam        cod_famiglia
         , sogg.sesso
         , ad4_comune.get_denominazione(sogg.cod_pro_nas,sogg.cod_pro_nas) comune_nascita
         , to_char(sogg.data_nas,'dd/mm/yyyy') data_nascita
         , ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res) comune_residenza
         , nvl(arvi.denom_uff,sogg.denominazione_via) via_residenza
         , sogg.num_civ
         , 'NON RES.'
      from soggetti sogg,
           contribuenti cont,
           archivio_vie arvi
     where sogg.tipo = 0
       and add_months(sogg.data_nas, 216) < a_data_rif
       and sogg.ni = cont.ni
       and (sogg.tipo_residente = 1 or
           (sogg.tipo_residente = 0 and sogg.fascia + 0 > 1))
       and sogg.cod_via = arvi.cod_via (+)
       and exists (select 'x'
                     from versamenti   vers
                    where vers.cod_fiscale = cont.cod_fiscale
                      and (vers.ruolo       = a_ruolo or
                          (vers.tipo_tributo||'' = 'TARSU' and
                           vers.anno        = a_anno)))
    union
    select 3 tipo
         , replace(sogg.cognome,';','')        cognome
         , replace(sogg.nome,';','')           nome
         , replace(cont.cod_fiscale,';','')    cod_fiscale
         , to_number(null)     cod_famiglia
         , ''                  sesso
         , ''                  comune_nascita
         , ''                  data_nascita
         , ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res) comune_residenza
         , nvl(arvi.denom_uff,sogg.denominazione_via) via_residenza
         , sogg.num_civ
         , 'ATT.' des_tipo
      from soggetti sogg,
           contribuenti cont,
           archivio_vie arvi
     where sogg.tipo = 1
       and sogg.ni = cont.ni
       and sogg.cod_via = arvi.cod_via (+)
       and exists (select 'x'
                     from versamenti   vers
                    where vers.cod_fiscale = cont.cod_fiscale
                      and (vers.ruolo       = a_ruolo or
                          (vers.tipo_tributo||'' = 'TARSU' and
                           vers.anno        = a_anno)))
     order by 1
         , 2
         , 3
         , 4
         ;
  begin
    --Cancello la tabella di lavoro
    begin
      delete wrk_trasmissioni;
    exception
    when others then
      RAISE_APPLICATION_ERROR (-20666,'Errore nella pulizia della tabella di lavoro (' || SQLERRM || ')');
    end;
    --Inserimento intestazione campi nella tabella di lavoro
    /*begin
      insert into wrk_trasmissioni(numero
                                 , dati)
           values (lpad(1,15,0)
                 , 'COD_COMUNE;COD_SOGGETTO;TIPO_SOGGETTO_DIC;TIPO_SOGGETTO;CODICE_FISCALE;'
                || 'PARTITA_IVA;COGNOME;NOME;COMUNE_NASCITA;DATA_NASCITA;SESSO;VIA;CIVICO;'
                || 'ESP;CAP;LOCALITA')
                 ;
    exception
      when others then
        RAISE_APPLICATION_ERROR (-20666,'Errore in inserimento intestazioni campi (' || SQLERRM || ')');
    end;*/
  --
  -- Selezione anno ruolo
  --
  begin
    select anno_ruolo
      into w_anno
      from ruoli
     where ruolo = a_ruolo;
  exception
    when others then
      RAISE_APPLICATION_ERROR (-20999,'Errore in selezione dati ruolo: ' || a_ruolo || ' (' || SQLERRM || ')');
  end;
  w_numero := 0;
  for rec_cont in sel_cont(a_ruolo, a_data_rif, w_anno) loop
     --Inserimento in tabella di lavoro
     w_numero := w_numero + 1;
     begin
       insert into wrk_trasmissioni(numero
                                  , dati)
            values (lpad(w_numero,15,0)
                 , rec_cont.des_tipo              || ';'
                || rec_cont.cognome               || ';'
                || rec_cont.nome                  || ';'
                || rec_cont.cod_fiscale           || ';'
                || rec_cont.cod_famiglia          || ';'
                || rec_cont.sesso                 || ';'
                || rec_cont.comune_nascita        || ';'
                || rec_cont.data_nascita          || ';'
                || rec_cont.comune_residenza      || ';'
                || rec_cont.via_residenza         || ';'
                || rec_cont.num_civ_residenza     || ';'
                   )
            ;
     exception
     when others then
       RAISE_APPLICATION_ERROR (-20666,'Errore in inserimento Contribuente: ' || rec_cont.cod_fiscale || ' (' || SQLERRM || ')');
     end;
  end loop; --Inserimento Contribuente
  commit;
end;
/* End Procedure: ESTRAZIONE_TARSU_ASA */
/

