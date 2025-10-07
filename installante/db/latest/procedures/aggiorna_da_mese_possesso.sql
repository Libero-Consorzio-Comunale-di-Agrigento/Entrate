--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiorna_da_mese_possesso stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     AGGIORNA_DA_MESE_POSSESSO
/*************************************************************************
 NOME:        AGGIORNA_DA_MESE_POSSESSO
 DESCRIZIONE: Aggiornamento campo da_mesi_possesso in tabella
              OGGETTI_CONTRIBUENTE.
 NOTE:        Si selezionano prima i mesi possesso totali e i mesi
              possesso primo semestre totali, raggruppandoli per oggetto e
              anno. In base al risultato ottenuto e al flag possesso finale
              si calcola il mese inizio possesso.
 Rev.    Date         Author      Note
 4       06/11/2023   AB          Aggiunto il parametro a_cod_fiscale
 3       22/08/2023   AB          Controllo anche con nvl(det_ogco.da_mese_possesso,0) > 12
                                  Anche questo caso dipende dai MUI e somma > 13
 2       09/08/2023   AB          Controllo con nvl(det_ogco.da_mese_possesso,0) = 0
                                  al posto di det_ogco.da_mese_possesso is null
 1       25/11/2020   VD          Aggiunta eliminazione elaborazioni
                                  precedenti (si conserva solo l'ultima)
 0       27/06/2019   VD          Prima emissione
*************************************************************************/
(a_cod_fiscale                varchar2 default '%'
)
is
   errore                     exception;
   w_errore                   varchar2(200);
   w_mese_fine                number;
   w_mese_inizio              number;
   w_righe_lette              number := 0;
   w_righe_agg                number := 0;
   w_righe_non_agg            number := 0;
   w_progr_elab               number := 0;
   w_progr_riga               number := 0;
   w_messaggio                varchar2(2000);
begin
  select nvl(max(progr_elab),0)
    into w_progr_elab
    from wrk_segnalazioni
   where cod_fiscale like a_cod_fiscale;
--
  delete from wrk_segnalazioni
   where progr_elab < w_progr_elab
     and cod_fiscale like a_cod_fiscale;
--
  w_progr_elab := w_progr_elab + 1;
  w_progr_riga := 0;
  for tot_ogco in (select ogco.cod_fiscale
                        , prtr.tipo_tributo
                        , ogco.anno
                        , ogpr.oggetto
                        , max(nvl(ogco.flag_possesso,'N')) flag_possesso
                        , sum(nvl(ogco.mesi_possesso,12)) tot_mesi_possesso
                        , sum(nvl(ogco.mesi_possesso_1sem,-1)) tot_mesi_possesso_1s
                     from pratiche_tributo prtr,
                          oggetti_pratica ogpr,
                          oggetti_contribuente ogco
                    where prtr.tipo_tributo in ('ICI','TASI')
                      and prtr.pratica = ogpr.pratica
                      --and prtr.cod_fiscale = ogco.cod_fiscale
                      and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and ((prtr.data_notifica is not null and
                            prtr.tipo_pratica||'' = 'A' and
                            nvl(prtr.stato_accertamento,'D') = 'D' and
                            nvl(prtr.flag_denuncia,' ')      = 'S')
                        or (prtr.data_notifica is null and
                            prtr.tipo_pratica||'' = 'D')
                          )
                      and ogco.cod_fiscale like a_cod_fiscale
--and ogpr.oggetto = 21854
                    group by ogco.cod_fiscale, prtr.tipo_tributo, ogco.anno, ogpr.oggetto
                    order by 1,2,3,4)
  loop
    if tot_ogco.tot_mesi_possesso between 0 and 12 then
       if tot_ogco.flag_possesso = 'S' then
          w_mese_fine := 12;
       elsif tot_ogco.tot_mesi_possesso = 0 then
          w_mese_fine := 1;
       else
          if tot_ogco.tot_mesi_possesso_1s = 0 then
             if tot_ogco.tot_mesi_possesso > 6 then
                w_mese_fine := tot_ogco.tot_mesi_possesso;
             else
                w_mese_fine := 6 + tot_ogco.tot_mesi_possesso;
             end if;
          elsif
             tot_ogco.tot_mesi_possesso_1s < 0 then
             w_mese_fine := 12;
          else
             if tot_ogco.tot_mesi_possesso > tot_ogco.tot_mesi_possesso_1s then
                w_mese_fine := 6 + tot_ogco.tot_mesi_possesso - tot_ogco.tot_mesi_possesso_1s;
             else
                w_mese_fine := tot_ogco.tot_mesi_possesso;
             end if;
          end if;
       end if;
    else
       w_mese_fine := to_number(null);
    end if;
    for det_ogco in (select ogpr.oggetto_pratica
                          , nvl(ogco.flag_possesso,'N') flag_possesso
                          , nvl(ogco.mesi_possesso,12)  mesi_possesso
                          , ogco.mesi_possesso_1sem
                          , ogco.da_mese_possesso
                          , nvl(ogco.mesi_riduzione,0) mesi_riduzione
                          , nvl(ogco.mesi_esclusione,0) mesi_esclusione
                          , nvl(ogco.flag_riduzione,'N') flag_riduzione
                          , nvl(ogco.flag_esclusione,'N') flag_esclusione
                       from pratiche_tributo prtr,
                            oggetti_pratica ogpr,
                            oggetti_contribuente ogco
                      where ogco.cod_fiscale = tot_ogco.cod_fiscale
                        and ogco.anno = tot_ogco.anno
                        and ogpr.oggetto = tot_ogco.oggetto
                        and prtr.tipo_tributo = tot_ogco.tipo_tributo
                        and prtr.pratica = ogpr.pratica
                        and ((prtr.data_notifica is not null and
                                          prtr.tipo_pratica||'' = 'A' and
                                          nvl(prtr.stato_accertamento,'D') = 'D' and
                                          nvl(prtr.flag_denuncia,' ')      = 'S')
                              or (prtr.data_notifica is null and
                                          prtr.tipo_pratica||'' = 'D')
                                    )
                        --and prtr.cod_fiscale = ogco.cod_fiscale
                        and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      order by nvl(ogco.flag_possesso,'N') desc,
                               nvl(ogco.da_mese_possesso,0) desc,
                               nvl(ogco.mesi_possesso_1sem,0) desc
                    )
    loop
      w_righe_lette := w_righe_lette + 1;
--dbms_output.put_line('Tipo tributo: '||tot_ogco.tipo_tributo||', Anno: '||tot_ogco.anno||', Oggetto: '||tot_ogco.oggetto||', Oggetto pratica: '||det_ogco.oggetto_pratica||', Mese fine: '||w_mese_fine);
      if w_mese_fine is not null then
         if det_ogco.mesi_possesso >= 0 then
            if det_ogco.mesi_possesso = 0 then
               w_mese_inizio := greatest(w_mese_fine,1);
            else
               w_mese_inizio := w_mese_fine - det_ogco.mesi_possesso + 1;
            end if;
            w_mese_fine := w_mese_fine - det_ogco.mesi_possesso;
--dbms_output.put_line('Mese inizio: '||w_mese_inizio||', Mese fine: '||w_mese_fine);
            if w_mese_inizio < 1 or w_mese_inizio > 12 or
              (nvl(det_ogco.mesi_possesso_1sem,0) > 0 and
               nvl(det_ogco.mesi_possesso_1sem,0) > 6 - w_mese_inizio + 1) then
               w_progr_riga := w_progr_riga + 1;
               begin
                 insert into wrk_segnalazioni
                        (progr_elab, progr_riga, cod_fiscale, oggetto_pratica, messaggio)
                 values (w_progr_elab, w_progr_riga,
                         tot_ogco.cod_fiscale,det_ogco.oggetto_pratica,
                         'Calcolo mese non possibile'
                        );
               exception
                 when others then
                   raise_application_error(-20999,'Ins. segnalazione cf: '||
                   tot_ogco.cod_fiscale||', ogpr: '||det_ogco.oggetto_pratica||
                   ' - '||sqlerrm);
               end;
            else
--               if det_ogco.da_mese_possesso is null then
               if nvl(det_ogco.da_mese_possesso,0) = 0
               or nvl(det_ogco.da_mese_possesso,0) > 12
               or nvl(det_ogco.da_mese_possesso,0) + nvl(det_ogco.mesi_possesso,0) > 13 then  -- AB (09 e 23/08/2023) per trattare anche i casi con 0 e > 12 che sono errati (da MUI)
                  w_righe_agg := w_righe_agg + 1;
--dbms_output.put_line('Mese inizio calcolato: '||w_mese_inizio);
                  begin
                    update oggetti_contribuente
                       set da_mese_possesso = w_mese_inizio,
                           note = ltrim(note||' Agg. DA_MESE_POSSESSO')
                     where cod_fiscale = tot_ogco.cod_fiscale
                       and oggetto_pratica = det_ogco.oggetto_pratica;
                  exception
                    when others then
                      w_messaggio := substr(sqlerrm,1,2000);
                      w_progr_riga := w_progr_riga + 1;
                      w_righe_agg := w_righe_agg - 1;
                      begin
                        insert into wrk_segnalazioni
                               (progr_elab, progr_riga, cod_fiscale, oggetto_pratica, messaggio)
                        values (w_progr_elab, w_progr_riga,
                                tot_ogco.cod_fiscale,det_ogco.oggetto_pratica,
                                w_messaggio
                               );
                      exception
                        when others then
                          raise_application_error(-20999,'Ins. segnalazione cf: '||
                          tot_ogco.cod_fiscale||', ogpr: '||det_ogco.oggetto_pratica||
                          ' - '||sqlerrm);
                      end;
                  end;
               else
                  w_righe_non_agg := w_righe_non_agg + 1;
               end if;
            end if;
         end if;
      else
         if tot_ogco.tot_mesi_possesso > 12 then
--            if det_ogco.da_mese_possesso is null then
            if nvl(det_ogco.da_mese_possesso,0) = 0
            or nvl(det_ogco.da_mese_possesso,0) > 12
            or nvl(det_ogco.da_mese_possesso,0) + nvl(det_ogco.mesi_possesso,0) > 13 then  -- AB (09 e 23/08/2023) per trattare anche i casi con 0 e > 12 che sono errati (da MUI)
               if det_ogco.mesi_possesso between 1 and 12 then
                  w_righe_agg := w_righe_agg + 1;
                  begin
                    update oggetti_contribuente
                       set da_mese_possesso = decode(nvl(det_ogco.mesi_possesso,12)
                                                    ,0,12
                                                      ,12 - nvl(det_ogco.mesi_possesso,12) + 1)
                         , note = ltrim(note||' Agg. DA_MESE_POSSESSO')
                     where cod_fiscale = tot_ogco.cod_fiscale
                       and oggetto_pratica = det_ogco.oggetto_pratica;
                  exception
                    when others then
                      w_messaggio := substr(sqlerrm,1,2000);
                      w_progr_riga := w_progr_riga + 1;
                      begin
                        insert into wrk_segnalazioni
                               (progr_elab, progr_riga, cod_fiscale, oggetto_pratica, messaggio)
                        values (w_progr_elab, w_progr_riga,
                                tot_ogco.cod_fiscale,det_ogco.oggetto_pratica,
                                w_messaggio
                               );
                      exception
                        when others then
                          raise_application_error(-20999,'Ins. segnalazione cf: '||
                                                         tot_ogco.cod_fiscale||', ogpr: '||det_ogco.oggetto_pratica||
                                                         ' - '||sqlerrm);
                      end;
                  end;
               else
                  w_progr_riga := w_progr_riga + 1;
                  begin
                    insert into wrk_segnalazioni
                           (progr_elab, progr_riga, cod_fiscale, oggetto_pratica, messaggio)
                    values (w_progr_elab, w_progr_riga,
                            tot_ogco.cod_fiscale,det_ogco.oggetto_pratica,
                            'Calcolo mese non possibile'
                           );
                  exception
                    when others then
                      raise_application_error(-20999,'Ins. segnalazione cf: '||
                      tot_ogco.cod_fiscale||', ogpr: '||det_ogco.oggetto_pratica||
                      ' - '||sqlerrm);
                  end;
               end if;
            else
               w_righe_non_agg := w_righe_non_agg + 1;
            end if;
         end if;
      end if;
    end loop;
  end loop;
  --
  dbms_output.put_line('Righe lette: '||w_righe_lette);
  dbms_output.put_line('Righe aggiornate: '||w_righe_agg);
  dbms_output.put_line('Righe con dato gia'' presente: '||w_righe_non_agg);
exception
  when errore then
    RAISE_APPLICATION_ERROR(-20999,w_errore||' ('||SQLERRM||')',true);
  when others then
    RAISE_APPLICATION_ERROR(-20999,'Errore in calcolo mese da ('||SQLERRM||')');
end;
/* End Procedure: AGGIORNA_DA_MESE_POSSESSO */
/
