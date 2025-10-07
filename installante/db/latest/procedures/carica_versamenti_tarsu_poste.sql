--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_tarsu_poste stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERSAMENTI_TARSU_POSTE
(p_spese_postali IN number) IS
CURSOR sel_vers IS
  select cont.cod_fiscale
        ,decode(substr(dati,54,3)
               ,'000',substr(dati,57,4)
               ,decode(substr(dati,54,2)
                      ,'00',substr(dati,56,4)
                      ,decode(substr(dati,54,1)
                             ,'0',substr(dati,55,4)
                             ,substr(dati,54,4)
                             )
                      )
                )                                                               anno
        ,'TARSU' tipo_tributo
        ,decode(substr(dati,54,3)
               ,'000',to_number(substr(dati,61,1))
               ,decode(substr(dati,54,2)
                      ,'00',to_number(substr(dati,60,1))
                      ,decode(substr(dati,54,1)
                             ,'0',to_number(substr(dati,59,1))
                             ,to_number(substr(dati,58,1))
                             )
                      )
                )                                                               rata
        ,'VERSAMENTO IMPORTATO DA POSTE' descrizione
        ,substr(dati,39,8) ufficio_pt  -- (provincia, ufficio, sportello)
        ,to_date(decode(sign(substr(dati,20,2)-50)
                       ,1,'19'||substr(dati,20,6)
                       ,'20'||substr(dati,20,6))
                ,'yyyymmdd') data_pagamento
        ,substr(dati,29,10) importo_versato
        ,wta.progressivo progr_anci
        ,decode(lpad(pro_cliente,3,'0')||lpad(com_cliente,3,'0'),'037048',25,6) fonte
        ,'POSTE' utente
        ,trunc(sysdate) data_variazione
        ,to_date(decode(sign(substr(dati,48,2)-50)
                       ,1,'19'||substr(dati,48,6)
                       ,'20'||substr(dati,48,6))
                ,'yyyymmdd') data_reg
        ,substr(dati,47,1) valuta
        ,decode(substr(dati,54,3)
               ,'000',substr(dati,62,1)
               ,decode(substr(dati,54,2)
                      ,'00',substr(dati,61,2)
                      ,decode(substr(dati,54,1)
                             ,'0',substr(dati,60,3)
                             ,substr(dati,59,4)
                             )
                      )
                )                                                               ruolo
    from wrk_tras_anci wta
        ,contribuenti  cont
        ,dati_generali dage
   where wta.anno            = 1
     and ((lpad(pro_cliente,3,'0')||lpad(com_cliente,3,'0')  in ('037048') --Pieve di Cento
       and cont.cod_fiscale  = ltrim(rtrim(substr(dati,63,16))) )
      or (lpad(pro_cliente,3,'0')||lpad(com_cliente,3,'0') not in ('037048')
       and  cont.ni          = to_number(substr(dati,63,7)) ) )
   order by 1;
w_100                number;
w_euro               number(6,2);
w_spese_postali      number(6,2);
w_spese_postali_rata number(6,2);
w_tot_spese_rata     number(6,2);
w_rate               number(2);
w_importo_versato    number(15,2);
w_controllo          number;
w_sequenza           number;
w_non_contribuenti   number;
w_errore             varchar2(2000);
w_errore2            varchar2(2000);
errore               exception;
errore2              exception;
w_rata               number(2);
BEGIN
  BEGIN
     select decode(fase_euro,1,1,100), cambio_euro
       into w_100,w_euro
       from dati_generali
     ;
    dbms_output.put_line('sel dage '||w_100||' - '||w_euro);
  EXCEPTION
     WHEN no_data_found THEN
        w_100 := 1;
        w_euro := 1936.27;
    dbms_output.put_line('sel dage ndf'||w_100||' - '||w_euro);
  END;
  w_non_contribuenti := 0;
  FOR rec_vers IN sel_vers LOOP
     BEGIN
     select count(*)
       into w_controllo
       from ruoli ruol
          , ruoli_contribuente ruco
      where ruol.anno_ruolo    = rec_vers.anno
       and ruol.ruolo          = ruco.ruolo
      and ruol.ruolo           = rec_vers.ruolo
       and ruco.cod_fiscale    = nvl(rec_vers.cod_fiscale,' ')
       ;
    dbms_output.put_line('count_ruco '||w_100||' - '||w_euro);
    END;
    if w_controllo > 0 then
    dbms_output.put_line('dentro if '||w_100||' - '||w_euro);
      IF w_100 = 1 AND rec_vers.valuta = 2 THEN
         w_importo_versato := round(rec_vers.importo_versato * w_euro);
         w_spese_postali   := round(p_spese_postali * w_euro);
      ELSIF w_100 = 100 AND rec_vers.valuta = 1 THEN
         w_importo_versato := round(rec_vers.importo_versato / w_euro,2);
         w_spese_postali   := round(p_spese_postali / w_euro,2);
      ELSE
         w_importo_versato := round(rec_vers.importo_versato / w_100,2);
         w_spese_postali   := p_spese_postali;
      END IF;
      IF rec_vers.rata = 0 THEN
         w_importo_versato := w_importo_versato - w_spese_postali;
         w_spese_postali_rata := w_spese_postali ;
      ELSE
        BEGIN
          select rate
            into w_rate
            from ruoli
           where ruolo = rec_vers.ruolo;
        EXCEPTION
          WHEN others THEN
            w_errore := 'Errore in ricerca rate ruolo '||rec_vers.ruolo||
                        ' ('||sqlerrm||')';
            RAISE errore;
        END;
        w_tot_spese_rata := 0;
        w_spese_postali_rata := 0;
        w_rata := rec_vers.rata;
        FOR c_rata IN 1..w_rata LOOP
          IF c_rata = w_rate THEN
           w_spese_postali_rata := w_spese_postali - w_tot_spese_rata ;
          ELSE
            w_spese_postali_rata := round(w_spese_postali/w_rate,2);
            w_tot_spese_rata     := w_tot_spese_rata + w_spese_postali_rata;
          END IF;
        END LOOP;
        w_importo_versato := w_importo_versato - w_spese_postali_rata;
      END IF;
    dbms_output.put_line('insert '||w_100||' - '||w_euro);
      BEGIN -- Assegnazione Numero Progressivo
         select nvl(max(vers.sequenza),0)+1
           into w_sequenza
           from versamenti vers
          where vers.cod_fiscale     = rec_vers.cod_fiscale
            and vers.anno            = rec_vers.anno
            and vers.tipo_tributo    = rec_vers.tipo_tributo
         ;
      END;
      BEGIN
        insert into versamenti
              ( cod_fiscale, anno, tipo_tributo, rata, descrizione, ufficio_pt
              , data_pagamento, importo_versato, progr_anci, fonte, utente
              , data_variazione, data_reg, sequenza, ruolo, spese_spedizione)
        values ( rec_vers.cod_fiscale, rec_vers.anno, rec_vers.tipo_tributo
               , rec_vers.rata, rec_vers.descrizione, rec_vers.ufficio_pt
               , rec_vers.data_pagamento, w_importo_versato, rec_vers.progr_anci
               , rec_vers.fonte, rec_vers.utente, rec_vers.data_variazione
               , rec_vers.data_reg, w_sequenza, rec_vers.ruolo, w_spese_postali_rata)
        ;
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in inserimento versamento'||
                      ' progressivo '||rec_vers.progr_anci||
                      ' ('||sqlerrm||')';
          RAISE errore;
      END;
      BEGIN
        delete wrk_tras_anci
         where progressivo = rec_vers.progr_anci
           and anno = 1;
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in eliminazione wrk_tras_anci'||
                      ' progressivo '||rec_vers.progr_anci||
                      ' ('||sqlerrm||')';
          RAISE errore;
      END;
    else
      w_non_contribuenti := w_non_contribuenti + 1;
    end if;
  END LOOP;
 /* if w_non_contribuenti > 0 then
      commit;
      w_errore2 := 'Non caricati ' || w_non_contribuenti || ' versamenti, per codice fiscale riferito al ruolo non trovato';
          RAISE errore2;
  end if; */
EXCEPTION
  WHEN errore THEN
    RAISE_APPLICATION_ERROR(-20919,w_errore);
  WHEN errore2 THEN
   RAISE_APPLICATION_ERROR(-20920,w_errore2);
  WHEN others THEN
    w_errore := 'Errore generico ('||sqlerrm||')';
END;
/* End Procedure: CARICA_VERSAMENTI_TARSU_POSTE */
/

