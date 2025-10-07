--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aliquota_mobile_k stripComments:false runOnChange:true 
 
create or replace procedure ALIQUOTA_MOBILE_K
/*************************************************************************
 La procedure aggiorna l'aliquota di oggetti_imposta in base ai dati
 presenti nella tabella ALIQUOTE_MOBILI (aliquota per scaglioni di rendita)
 Utilizzata nel calcolo individuale (pratiche K)
 Versione  Data              Autore    Descrizione
 0         26/05/2015        VD        Prima emissione
 1         16/07/2015        SC        Salviamo anche tipo_aliquota.
                                       Si fa il calcolo per ogni abitazione
                                       principale e sue pertinenze.
                                       Per riconoscere le pertinenze è
                                       obbligatorio valorizzare
                                       oggetto_pratica_rif_ap.
*************************************************************************/
( a_tipo_tributo           varchar2
, a_anno_rif               number
, a_pratica                number
)
is
  w_aliquota                   number := 0;
  w_flag_pertinenze            varchar2(1);
  w_rendita                    number;
  w_rendita_totale             number := 0;
  w_tipo_aliquota_ap           number;
  w_rottura_old                number := -1;
CURSOR sel_ogco IS
  select nvl(ogpr.oggetto_pratica_rif_ap, ogpr.oggetto_pratica) rottura,
         ogpr.tipo_oggetto,
         ogpr.valore,
         f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno_rif,'CA')
                                                    categoria_catasto_ogpr,
         ogpr.oggetto_pratica,
         ogim.oggetto_imposta,
         ogco.anno anno_ogco,
         ogco.cod_fiscale cod_fiscale_ogco,
         ogim.tipo_aliquota,
         ogco.flag_ab_principale flag_ab_principale,
         ogco.detrazione,
         ogim.detrazione_acconto,
         ogpr.oggetto_pratica_rif_ap
    from oggetti ogge,
         oggetti_pratica ogpr,
         oggetti_imposta ogim,
         oggetti_contribuente ogco
   where ogpr.pratica             = a_pratica
     and ogpr.tipo_oggetto        in (3,55)
     and ogge.oggetto             = ogpr.oggetto
     and ogpr.oggetto_pratica     = ogco.oggetto_pratica
     and ogim.oggetto_pratica     = ogpr.oggetto_pratica
     and ogco.anno                = ogim.anno
     and ogim.tipo_tributo        = a_tipo_tributo
     and f_dato_riog(ogco.cod_fiscale,ogpr.oggetto_pratica,a_anno_rif,'CA') not in ('A01','A08','A09')
   order by 1, 7;
   type t_ogpr                  is table of number index by binary_integer;
   type t_ogim                  is table of number index by binary_integer;
   ogpr_da_aggiornare           t_ogpr;
   ogim_da_aggiornare           t_ogim;
   i                            binary_integer := 0;
--
begin
--
-- Selezione flag pertinenze
--
  begin
    select tipo_aliquota, flag_pertinenze
      into w_tipo_aliquota_ap, w_flag_pertinenze
      from aliquote
     where flag_ab_principale = 'S'
       and tipo_tributo = 'TASI'
       and anno = a_anno_rif
    ;
  exception
    when no_data_found or too_many_rows then
      w_flag_pertinenze := 'N';
      w_tipo_aliquota_ap := 2; --se non trovo il tipo al dell'abitazione
                                -- principale, metto il classico 2.
  end;
  for rec_ogco in sel_ogco
  loop
    declare
        w_flag_ab_ap                 varchar2(1);
        w_tial_ap                    number;
        w_detr_ap                    number;
        w_detr_acc_ap                number;
    begin
    -- se è specificato il rif_ap devo verificare se l'abitazione è
    -- abitazione principale
        if rec_ogco.oggetto_pratica_rif_ap is not null
        and w_flag_pertinenze = 'S'
        and rec_ogco.rottura > 0 then
           begin
           select flag_ab_principale
                , ogim.tipo_aliquota
                , nvl(ogco.detrazione, 0)
                , nvl(ogim.detrazione_acconto, 0)
             into w_flag_ab_ap, w_tial_ap, w_detr_ap, w_detr_acc_ap
             from oggetti ogge,
                  oggetti_pratica ogpr,
                  oggetti_imposta ogim,
                  oggetti_contribuente ogco
            where ogpr.pratica             = a_pratica
              and ogpr.tipo_oggetto        in (3,55)
              and ogge.oggetto             = ogpr.oggetto
              and ogpr.oggetto_pratica     = ogco.oggetto_pratica
              and ogim.oggetto_pratica     = ogpr.oggetto_pratica
              and ogco.anno                = ogim.anno
              and ogim.tipo_tributo        = a_tipo_tributo
              and ogpr.oggetto_pratica = rec_ogco.oggetto_pratica_rif_ap
              and f_dato_riog(ogco.cod_fiscale,ogpr.oggetto_pratica,a_anno_rif,'CA') not in ('A01','A08','A09');
           exception
           when others then
                null;
           end;
        end if;
        IF  (rec_ogco.flag_ab_principale = 'S' or
            (rec_ogco.tipo_aliquota = w_tipo_aliquota_ap and
            (nvl(rec_ogco.detrazione,0) != 0 or
             nvl(rec_ogco.detrazione_acconto,0) != 0)
             ) or
             --pertinenze di abitazione principale
            (rec_ogco.oggetto_pratica_rif_ap is not null and
             w_flag_ab_ap = 'S' or
             (w_tial_ap = w_tipo_aliquota_ap and
             (w_detr_ap != 0 or w_detr_acc_ap != 0)
            ))
        and (    w_flag_pertinenze = 'S'
             or (w_flag_pertinenze is null and rec_ogco.categoria_catasto_ogpr like 'A%')
            )
            ) THEN
            if w_rottura_old = -1 then
               w_rottura_old := rec_ogco.rottura;
            end if;
            if w_rottura_old !=  rec_ogco.rottura then
            dbms_output.put_line('w_rendita_totale  '||w_rendita_totale);
               -- calcolo della aliquota mobili e  set dei valori sulle righe
               begin
                select aliquota
                  into w_aliquota
                  from aliquote_mobili
                 where tipo_tributo = a_tipo_tributo
                   and anno = a_anno_rif
                   and w_rendita_totale between da_rendita and nvl(a_rendita,9999999999);
               exception
                when others then
                     w_aliquota := 0;
               end;
               FOR k IN ogpr_da_aggiornare.FIRST .. ogpr_da_aggiornare.LAST LOOP
                  BEGIN
                     update oggetti_pratica
                        set indirizzo_occ = lpad(w_tipo_aliquota_ap, 2,'0')||
                                            lpad(to_char(w_aliquota * 100),6,'0')||
                                            substr(indirizzo_occ,9)
                      where oggetto_pratica = ogpr_da_aggiornare(k)
                     ;
                  EXCEPTION
                    WHEN others THEN
                     raise_application_error
                     (-20999,'Errore in Aggiornamento Dati Anno Precedente - ogpr -'||
                             ' ('||SQLERRM||')');
                  END;
               END LOOP;
               FOR k IN ogim_da_aggiornare.FIRST .. ogim_da_aggiornare.LAST LOOP
                  begin
                    update oggetti_imposta
                       set aliquota = w_aliquota
                         , tipo_aliquota = w_tipo_aliquota_ap
                     where oggetto_imposta = ogim_da_aggiornare(k);
                  exception
                    when others then
                      raise_application_error
                      (-20999,'Errore in update OGGETTI_IMPOSTA ('||sqlerrm||')');
                  end;
               END LOOP;
               w_rottura_old := rec_ogco.rottura;
               w_rendita_totale := 0;
               i := 0;
               ogpr_da_aggiornare.delete;
               ogim_da_aggiornare.delete;
            end if;
            i := i+1;
            dbms_output.put_line('rec_ogco.valore '||rec_ogco.valore);
            ogpr_da_aggiornare(i) := rec_ogco.oggetto_pratica;
            ogim_da_aggiornare(i) := rec_ogco.oggetto_imposta;
            w_rendita_totale := w_rendita_totale + rec_ogco.valore;
        end if;
    end;
  end loop;
--
dbms_output.put_line('w_rendita_totale  '||w_rendita_totale);
-- calcolo della aliquota mobili e  set dei valori sulle righe
  begin
    select aliquota
      into w_aliquota
      from aliquote_mobili
     where tipo_tributo = a_tipo_tributo
       and anno = a_anno_rif
       and w_rendita_totale between da_rendita and nvl(a_rendita,9999999999);
  exception
  when others then
     w_aliquota := 0;
  end;
  FOR k IN ogpr_da_aggiornare.FIRST .. ogpr_da_aggiornare.LAST LOOP
      BEGIN
         update oggetti_pratica
            set indirizzo_occ = lpad(w_tipo_aliquota_ap, 2,'0')||
                                lpad(to_char(w_aliquota * 100),6,'0')||
                                substr(indirizzo_occ,9)
          where oggetto_pratica = ogpr_da_aggiornare(k)
         ;
      EXCEPTION
        WHEN others THEN
         raise_application_error
         (-20999,'Errore in Aggiornamento Dati Anno Precedente - ogpr -'||
                 ' ('||SQLERRM||')');
      END;
  END LOOP;
  FOR k IN ogim_da_aggiornare.FIRST .. ogim_da_aggiornare.LAST LOOP
      begin
        update oggetti_imposta
           set aliquota = w_aliquota
             , tipo_aliquota = w_tipo_aliquota_ap
         where oggetto_imposta = ogim_da_aggiornare(k);
      exception
        when others then
          raise_application_error
          (-20999,'Errore in update OGGETTI_IMPOSTA ('||sqlerrm||')');
      end;
  END LOOP;
exception
  when others then
    raise_application_error
    (-20999,'Errore in calcolo aliquota mobile ('||sqlerrm||')');
end;
/* End Procedure: ALIQUOTA_MOBILE_K */
/

