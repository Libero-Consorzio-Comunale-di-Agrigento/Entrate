--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_dv_tarsu_f24 stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_DV_TARSU_F24
(
  p_anno    in number,
  p_imp_da    in number,
  p_imp_a     in number,
  p_spese_postali in number,
  p_num_cont  in out number
)
is
msg_interruzione varchar2(500);

cursor sel_tarsu is
select    rpad('TARSU', 5, ' ')                                                       tipo_tributo
        , imru.anno                                                                   anno
        , max(translate(sogg.cognome_nome, '/', ' '))                                 csoggnome
        , max(sogg.fascia)                                                            fascia
        , max(sogg.stato)                                                             stato
        , max(decode(length(cont.cod_fiscale), 11, null, cont.cod_fiscale))           cod_fis
        , max(decode(length(cont.cod_fiscale), 11, cont.cod_fiscale, null))           p_iva
        , max(cont.ni)                                                                ni
        , max(   decode(sogg.cod_via
                      ,null, sogg.denominazione_via
                      ,arvi.denom_uff
                      )
             || decode(sogg.num_civ, null, '', ', ' || sogg.num_civ)
             || decode(sogg.suffisso, null, '', '/' || sogg.suffisso)
            )                                                                         indirizzo_dich
        ,max(   decode(nvl(sogg.cap, comu.cap)
                      ,null, ''
                      ,nvl(sogg.cap, comu.cap) || ' '
                      )
             || comu.denominazione
             || decode(prov.sigla, null, '', ' (' || prov.sigla || ')')
            )                                                                         residenza_dich
        , coen.presso                                                                 presso
        , coen.indirizzo                                                              indirizzo
        , coen.comune                                                                 comune
        , sum(imru.imposta_ruolo)                                                     imposta_ruolo
        , sum(imru.imposta)                                                           imposta
        , sum(imru.imposta_lorda)                                                     imposta_lorda
        , nvl(sum(imru.addizionale_eca),0)
             + nvl(sum(imru.iva),0)
             + nvl(sum(imru.maggiorazione_eca),0)                                     add_magg_eca
        , sum(imru.addizionale_pro)                                                   addizionale_pro
        , sum(imru.maggiorazione_tares)                                               maggiorazione_tares
        , sum(importo_sgravio)                                                        importo_sgravio
        , nvl(sum(addizionale_eca_sgravio),0)
                 + nvl(sum(iva_sgravio),0)
                 + nvl(sum(maggiorazione_eca_sgravio),0)                              add_magg_eca_sgravio
        , sum(addizionale_pro_sgravio)                                                addizionale_pro_sgravio
        , sum(maggiorazione_tares_sgravio)                                            maggiorazione_tares_sgravio
        , sum(sgravio_tot)                                                            sgravio_tot
        , nvl(f_tot_vers_cont_ruol(imru.anno
                                 ,imru.cod_fiscale
                                 ,'TARSU'
                                 ,decode(nvl(0, 0), 0, null, 0)
                                 ,'V'
                                 )
            ,0
            )                                                                         versato
        , nvl(f_tot_vers_cont_ruol(imru.anno
                                 ,imru.cod_fiscale
                                 ,'TARSU'
                                 ,decode(nvl(0, 0), 0, null, 0)
                                 ,'VN'
                                 )
            ,0
            )                                                                         versato_netto
        , nvl(f_tot_vers_cont_ruol(imru.anno
                                   ,imru.cod_fiscale
                                   ,'TARSU'
                                   ,decode(nvl(0, 0), 0, null, 0)
                                   ,'V'
                                   )
              ,0
              )
         - nvl(f_tot_vers_cont_ruol(imru.anno
                                   ,imru.cod_fiscale
                                   ,'TARSU'
                                   ,decode(nvl(0, 0), 0, null, 0)
                                   ,'VN'
                                   )
              ,0
              )                                                                       versato_maggiorazione
        , sum(imru.imposta_ruolo)
             - nvl(f_tot_vers_cont_ruol(imru.anno
                                       ,imru.cod_fiscale
                                       ,'TARSU'
                                       ,decode(nvl(0, 0)
                                              ,0, null
                                              ,0
                                              )
                                       )
                  ,0
                  )
             - nvl(sum(sgravio_tot), 0)                                               differenza
        , p_spese_postali                                                             spese_postali
        , round(sum(imru.imposta_ruolo)
             - nvl(f_tot_vers_cont_ruol(imru.anno
                                       ,imru.cod_fiscale
                                       ,'TARSU'
                                       ,decode(nvl(0, 0)
                                              ,0, null
                                              ,0
                                              )
                                       )
                  ,0
                  )
             - nvl(sum(sgravio_tot), 0) 
             + p_spese_postali, 0)                                                                          importo_F24
        , 'SOLL' || to_char(p_anno) || '01' || to_char(sysdate,'yyyymmdd')            id_operazione

--   DATI PER STAMPA f24

       , max(sogg.cognome)                                                            cognome
       , max(sogg.nome)                                                               nome
       , max(to_char(sogg.data_nas,'dd/mm/yyyy'))                                     data_nascita
       , max(sogg.sesso)                                                              sesso
       , max(cona.denominazione)                                                      comune_nascita
       , max(prna.sigla)                                                              provincia_nascita
       , max(cont.cod_fiscale)                                                        cod_fiscale_F24
       , 'EL'                                                                         sezione
       , 3944                                                                         codice_trib
       , max(cfis.sigla_cfis)                                                         codice_ente
       , '0101'                                                                       rateazione
       , max(imru.nr_utenze)                                                          numero_immobili
    from (  select ogim.cod_fiscale
                  ,round(sum(  ogim.imposta
                            + nvl(ogim.addizionale_eca, 0)
                            + nvl(ogim.maggiorazione_eca, 0)
                            + nvl(ogim.addizionale_pro, 0)
                            + nvl(ogim.iva, 0)),0) 
                   + round(sum(nvl(ogim.maggiorazione_tares,0)),0)
                     imposta_ruolo
                  ,sum(ogim.imposta) imposta
                  ,sum(ogim.addizionale_eca) addizionale_eca
                  ,sum(ogim.maggiorazione_eca) maggiorazione_eca
                  ,sum(ogim.addizionale_pro) addizionale_pro
                  ,sum(ogim.iva) iva
                  ,sum(ogim.maggiorazione_tares) maggiorazione_tares
                  ,round(sum(  ogim.imposta
                            + nvl(ogim.addizionale_eca, 0)
                            + nvl(ogim.maggiorazione_eca, 0)
                            + nvl(ogim.addizionale_pro, 0)
                            + nvl(ogim.iva, 0)),0) imposta_lorda
                  ,count(distinct ogpr.oggetto) nr_utenze
                  ,ogim.ruolo
                  ,ogim.anno
              from pratiche_tributo prtr
                  ,tipi_tributo titr
                  ,codici_tributo cotr
                  ,oggetti_pratica ogpr
                  ,oggetti_imposta ogim
                  ,ruoli ruol
             where titr.tipo_tributo = cotr.tipo_tributo
               and cotr.tributo = ogpr.tributo + 0
               and cotr.tipo_tributo = prtr.tipo_tributo || ''
               and prtr.tipo_tributo || '' = 'TARSU'
               and prtr.cod_fiscale || '' = ogim.cod_fiscale
               and prtr.pratica = ogpr.pratica
               and ogpr.oggetto_pratica = ogim.oggetto_pratica
               and ogpr.tributo =
                     decode(-1, -1, ogpr.tributo, -1)
               and ogim.ruolo is not null
               and ogim.flag_calcolo = 'S'
               and ogim.anno = to_number(p_anno)
               and ogim.ruolo =
                     nvl(nvl(decode(0, 0, to_number(''), 0)
                             ,f_ruolo_totale(ogim.cod_fiscale
                                         ,to_number(p_anno)
                                         ,'TARSU'
                                         ,-1
                                         ))
                             ,ogim.ruolo
                             )
--               and ogim.cod_fiscale like 'MSCSVT75E02M208E'
               and ruol.ruolo = ogim.ruolo
               and ruol.invio_consorzio is not null
          group by ogim.cod_fiscale, ogim.ruolo, ogim.anno) imru
        , (  select sum(nvl(importo, 0)
                      - nvl(addizionale_eca,0)
                      - nvl(maggiorazione_eca,0)
                      - nvl(addizionale_pro,0)
                      - nvl(iva,0)
                      - nvl(maggiorazione_tares,0)) importo_sgravio
                  ,sum(addizionale_eca) addizionale_eca_sgravio
                  ,sum(maggiorazione_eca) maggiorazione_eca_sgravio
                  ,sum(addizionale_pro) addizionale_pro_sgravio
                  ,sum(iva) iva_sgravio
                  ,sum(maggiorazione_tares) maggiorazione_tares_sgravio
                  ,sum(nvl(importo, 0)) sgravio_tot
                  ,ruolo
                  ,cod_fiscale
              from sgravi
             where ruolo =
                     nvl(nvl(decode(0, 0, to_number(''), 0)
                             ,f_ruolo_totale(cod_fiscale
                                         ,to_number(p_anno)
                                         ,'TARSU'
                                         ,-1
                                         ))
                             ,ruolo
                             )
          group by cod_fiscale, ruolo) sgra
        , contribuenti cont
        , soggetti sogg
        , archivio_vie arvi
        , ad4_comuni comu
        , ad4_provincie prov
        , contribuenti_ente coen
        , ad4_comuni cona
        , ad4_provincie prna
        , ad4_comuni cfis
        , dati_generali dage
   where imru.cod_fiscale = cont.cod_fiscale
     and cont.ni = sogg.ni
     and sogg.cognome_nome_ric like '%'
     and sogg.cod_via = arvi.cod_via(+)
     and comu.provincia_stato = prov.provincia(+)
     and sogg.cod_pro_res = comu.provincia_stato(+)
     and sogg.cod_com_res = comu.comune(+)
     and imru.cod_fiscale = sgra.cod_fiscale(+)
     and imru.ruolo = sgra.ruolo(+)
     and coen.ni    = cont.ni
     and coen.tipo_tributo = 'TARSU' 
     and sogg.cod_pro_nas = cona.provincia_stato(+)
     and sogg.cod_com_nas = cona.comune(+)
     and sogg.cod_pro_nas = prna.provincia(+)
     and dage.pro_cliente = cfis.provincia_stato(+) 
     and dage.com_cliente = cfis.comune (+) 
group by imru.cod_fiscale
           , imru.anno
           , coen.presso
           , coen.indirizzo
           , coen.comune
           , 'SOLL' || to_char(p_anno) || '01' || to_char(sysdate,'yyyymmdd')
having sum(imru.imposta_ruolo)
            - nvl(f_tot_vers_cont_ruol(imru.anno
                                      ,imru.cod_fiscale
                                      ,'TARSU'
                                      ,decode(nvl(0, 0)
                                             ,0, null
                                             ,0
                                             )
                                      )
                 ,0
                 )
            - nvl(sum(sgravio_tot), 0)
            between nvl(p_imp_da, 0)
                and nvl(p_imp_a, 9999999999999999)              
order by max(decode(length(cont.cod_fiscale), 11, null, cont.cod_fiscale))
;
w_progressivo    number;     
BEGIN
   --Cancello la tabella di lavoro
   begin
      delete wrk_trasmissioni;
   exception
     when others then
        RAISE_APPLICATION_ERROR (-20666,'Errore nella pulizia della tabella di lavoro (' || SQLERRM || ')');
   end;

  msg_interruzione := 'INIZIO';
  w_progressivo    := 1; 
     
       begin                   
         insert into wrk_trasmissioni 
               (numero, dati)
         select w_progressivo
               , 'TIPO_TRIBUTO'
              ||';ANNO'
              ||';COGNOME_NOME RAGIONE_SOCIALE'
              ||';FASCIA'
              ||';STATO'
              ||';CODICE_FISCALE'
              ||';PARTITA_IVA'
              ||';NUMERO_INDIVIDUALE'
              ||';INDIRIZZO_DI_ANAGRAFE'
              ||';RESIDENZA_DI_ANAGRAFE'
              ||';PRESSO'
              ||';INDIRIZZO'  
              ||';COMUNE'
              ||';IMPOSTA_A_RUOLO'
              ||';IMPOSTA'
              ||';IMPOSTA_LORDA'
              ||';ADDIZIONALI_E_MAGGIORAZIONI_ECA'
              ||';ADDIZIONALE_PROVINCIALE'
              ||';MAGGIORAZIONE_TARES'
              ||';IMPORTO_SGRAVIO_LORDO'
              ||';ADDIZIONALI_E_MAGG_ECA_SU_SGRAVIO'
              ||';ADDIZIONALE_PROVINCIALE_SGRAVIO'
              ||';MAGGIORAZIONE_TARES_SGRAVIO'
              ||';SGRAVIO_TOTALE'
              ||';VERSATO'
              ||';VERSATO_NETTO'
              ||';VERSATO_MAGGIORAZIONE'  
              ||';DIFFERENZA'
              ||';SPESE_POSTALI'
              ||';IMPORTO_F24'
              ||';IDENTIFICATIVO_OPERAZIONE'
              ||';COGNOME'
              ||';NOME'
              ||';DATA_NASCITA'
              ||';SESSO'
              ||';COMUNE_NASCITA'
              ||';PROVINCIA_NASCITA'
              ||';CODICE_FISCALE_PARTITA_IVA'
              ||';SEZIONE'
              ||';CODICE_TRIBUTO'
              ||';CODICE_ENTE'
              ||';RATEAZIONE'
              ||';NUMERO_IMMOBILI'
           from dual
        ;       
       exception
         when others then 
           raise_application_error(-20919,'Errore in inserimento wrk_trasmissioni '
                                        ||' - progressivo '||w_progressivo
                                        ||' ('||sqlerrm||')');
       end;  

       w_progressivo := w_progressivo + 1; 

     FOR rec_tarsu IN sel_tarsu LOOP
       begin                   
         insert into wrk_trasmissioni 
               (numero, dati)
         select w_progressivo
              , rec_tarsu.tipo_tributo
              ||';'||rec_tarsu.anno
              ||';'||rec_tarsu.csoggnome
              ||';'||rec_tarsu.fascia
              ||';'||rec_tarsu.stato
              ||';'||rec_tarsu.cod_fis
              ||';'||rec_tarsu.p_iva
              ||';'||rec_tarsu.ni
              ||';'||rec_tarsu.indirizzo_dich
              ||';'||rec_tarsu.residenza_dich
              ||';'||rec_tarsu.presso
              ||';'||rec_tarsu.indirizzo  
              ||';'||rec_tarsu.comune
              ||';'||ltrim(translate(to_char(rec_tarsu.imposta_ruolo,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.imposta,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.imposta_lorda,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.add_magg_eca,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.addizionale_pro,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.maggiorazione_tares,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.importo_sgravio,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.add_magg_eca_sgravio,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.addizionale_pro_sgravio,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.maggiorazione_tares_sgravio,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.sgravio_tot,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.versato,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.versato_netto,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.versato_maggiorazione,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.differenza,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.spese_postali,'999999990.00'),'.',','))
              ||';'||ltrim(translate(to_char(rec_tarsu.importo_F24,'999999990.00'),'.',','))
              ||';'||rec_tarsu.id_operazione
              ||';'||rec_tarsu.cognome
              ||';'||rec_tarsu.nome
              ||';'||rec_tarsu.data_nascita
              ||';'||rec_tarsu.sesso
              ||';'||rec_tarsu.comune_nascita
              ||';'||rec_tarsu.provincia_nascita
              ||';'||rec_tarsu.cod_fiscale_F24
              ||';'||rec_tarsu.sezione
              ||';'||rec_tarsu.codice_trib
              ||';'||rec_tarsu.codice_ente
              ||';'||rec_tarsu.rateazione
              ||';'||rec_tarsu.numero_immobili                            
           from dual
        ;       
       exception
         when others then 
           raise_application_error(-20919,'Errore in inserimento wrk_trasmissioni '
                                        ||' - progressivo '||w_progressivo
                                        ||' ('||sqlerrm||')');
       end;   
     w_progressivo := w_progressivo + 1;
  end loop;
  msg_interruzione := 'FINE';
  p_num_cont := w_progressivo - 2;  
  commit;
  dbms_output.put_line('----------------------------------' );
  dbms_output.put_line(' Totale Contribuentiti Estratti: ' || to_char(w_progressivo - 2));
  dbms_output.put_line('----------------------------------' );
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR(-20919,'Errore generico '||
                                   msg_interruzione||
                                   ' ('||sqlerrm||')');
END;
/* End Procedure: ESTRAZIONE_DV_TARSU_F24 */
/

