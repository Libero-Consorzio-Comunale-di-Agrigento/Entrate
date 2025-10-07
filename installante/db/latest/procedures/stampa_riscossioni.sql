--liquibase formatted sql 
--changeset abrandolini:20250326_152423_stampa_riscossioni stripComments:false runOnChange:true 
 
create or replace procedure STAMPA_RISCOSSIONI
(a_anno      IN   number,
 a_da_data   IN   date,
 a_a_data   IN   date)
IS
MIN_REC         CONSTANT number(1) := 1;
bRidotto        Boolean      := FALSE;
w_progressivo   number(12);
w_riga          varchar2(300);
w_dati_cont     varchar2(200);
w_cod_fiscale   varchar2(16);
w_aliquota      number(6,2);
w_estremi       varchar2(30);
w_versato       number(12,2) := 0;
w_importo       number(12,2) := 0;
w_imposta       number(12,2) := 0;
w_rendita       number(12,2) := 0;
w_interessi     number(12,2) := 0;
w_sanzioni      number(12,2) := 0;
w_tot_imposte   number(18,2) := 0;
w_tot_rendite   number(18,2) := 0;
w_tot_interessi number(18,2) := 0;
w_tot_sanzioni  number(18,2) := 0;
w_limite        number(4);
-- Dati della Pratica
CURSOR sel_dati_prtr (p_anno number) IS
select ratr.cod_fiscale
      ,nvl(sum(nvl(prtr.importo_totale,0)),0) importo
      ,nvl(sum(nvl(prtr.importo_ridotto,0)),0) importo_ridotto
  from rapporti_tributo ratr
      ,pratiche_tributo prtr
 where ratr.pratica           = prtr.pratica
   and prtr.tipo_pratica     in ('A','L')
   and prtr.tipo_tributo||''  = 'ICI'
   and prtr.anno              = p_anno
 group by ratr.cod_fiscale
 order by 1
;
-- Dati del Contribuente - questo cursore restituisce un solo record
--                         si poteva usare una select .......
CURSOR sel_dati_cont (p_cod_fiscale varchar2) IS
  select decode(nvl(sogg.tipo,'2'),0,
         rpad(replace(nvl(substr(sogg.cognome_nome,1,40),' '),'/',' '),40)||'|'||
         nvl(sogg.sesso,' ')||'|'||
         rpad(nvl(substr(nvl(comu_nas.denominazione,' '),1,30),' '),30)||'|'||
         decode(prov_nas.sigla,null,'    ','('||rpad(prov_nas.sigla,2,' ')||')')||'|'||
         decode(sogg.data_nas,null,'00/00/0000',to_char(sogg.data_nas,'dd/mm/yyyy')),
         rpad(nvl(substr(sogg.cognome_nome,1,40),' '),40)||'|'||
         ' '||'|'||
         rpad(nvl(substr(nvl(comu_res.denominazione,' '),1,30),' '),30)||'|'||
         decode(prov_nas.sigla,null,'    ','('||rpad(prov_res.sigla,2,' ')||')')||'|'||
         '00/00/0000'
         ) dati_cont
    FROM ad4_comuni    comu_res
        ,ad4_provincie prov_res
        ,ad4_comuni    comu_nas
        ,ad4_provincie prov_nas
        ,soggetti      sogg
        ,contribuenti  cont
   where comu_res.provincia_stato = prov_res.provincia (+)
     and sogg.cod_com_res         = comu_res.comune (+)
     and sogg.cod_pro_res         = comu_res.provincia_stato (+)
     and comu_nas.provincia_stato = prov_nas.provincia (+)
     and sogg.cod_com_nas         = comu_nas.comune (+)
     and sogg.cod_pro_nas         = comu_nas.provincia_stato (+)
     and sogg.ni                  = cont.ni
     and cont.cod_fiscale         = p_cod_fiscale
;
-- Sanzioni delle Pratiche di Liquidazione e Accertamento
-- di Riscossione.
CURSOR sel_dati_sapr (p_cod_fiscale varchar2) IS
select nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NS',decode(prtr.tipo_pratica||prtr.tipo_evento
                                 ,'LR',0
                                      ,nvl(sapr.importo,0)
                                 )
                          ,0
                     )
              ),0
          ) imposta
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NS',decode(prtr.tipo_pratica||prtr.tipo_evento
                                 ,'LR',0
                                      ,round(nvl(sapr.importo,0)
                                             * (100 - nvl(sapr.riduzione,0)) / 100,2
                                            )
                                 )
                          ,0
                     )
              ),0
          ) imposta_rid
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NS',decode(prtr.tipo_pratica||prtr.tipo_evento
                                 ,'LR',nvl(sapr.importo,0)
                                      ,0
                                 )
                          ,0
                     )
              ),0
          ) rendita
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NS',decode(prtr.tipo_pratica||prtr.tipo_evento
                                 ,'LR',round(nvl(sapr.importo,0)
                                             * (100 - nvl(sapr.riduzione,0)) / 100,2
                                            )
                                      ,0
                                 )
                          ,0
                     )
              ),0
          ) rendita_rid
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'SN',nvl(sapr.importo,0)
                          ,0
                     )
              ),0
          ) interessi
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'SN',round(nvl(sapr.importo,0)
                                 * (100 - nvl(sapr.riduzione,0)) / 100,2
                                )
                          ,0
                     )
              ),0
          ) interessi_rid
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NN',nvl(sapr.importo,0)
                          ,0
                     )
              ),0
          ) sanzioni
      ,nvl(sum(decode(nvl(sanz.flag_interessi,'N')||nvl(sanz.flag_imposta,'N')
                     ,'NN',round(nvl(sapr.importo,0)
                                 * (100 - nvl(sapr.riduzione,0)) / 100,2
                                )
                          ,0
                     )
              ),0
          ) sanzioni_rid
  from sanzioni         sanz
      ,sanzioni_pratica sapr
      ,pratiche_tributo prtr
      ,rapporti_tributo ratr
 where sanz.cod_sanzione          = sapr.cod_sanzione
   and sanz.sequenza              = sapr.sequenza_sanz
   and sanz.tipo_tributo          = sapr.tipo_tributo
   and sapr.pratica               = prtr.pratica
   and prtr.tipo_tributo||''      = 'ICI'
   and prtr.tipo_pratica         in ('L','A')
   and ratr.pratica               = prtr.pratica
   and ratr.cod_fiscale           = p_cod_fiscale
;
BEGIN  -- STAMPA_RISCOSSIONI
  BEGIN
     select decode(fase_euro,1,1000,1)
       into w_limite
       from dati_generali
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Dati Generali Non Presenti !');
     WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
  END;
-- w_progressivo parte da MIN_REC perche i primi due record (tipo 0 e 1)
-- vengono inseriti in fondo.
  w_cod_fiscale   := NULL;
  w_progressivo   := MIN_REC;
  BEGIN
    delete wrk_tras_anci
    ;
  EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in pulizia tabella di lavoro '||
                   ' ('||SQLERRM||')');
  END;
  BEGIN
    select aliquota
      into w_aliquota
      from aliquote
     where anno = a_anno
       and tipo_aliquota = 1
       and tipo_tributo  = 'ICI'
    ;
  EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in estrazione Aliquota '||
                   ' ('||SQLERRM||')');
  END;
  FOR rec_prtr IN sel_dati_prtr(a_anno) LOOP
     BEGIN
     -- Totale dei versamenti relativi al Contribuente
        select rpad(nvl(min(substr(nvl(numero,' '),1,8)),' '),8,' ')||'|'||
               decode(min(data),null,'00/00/0000',to_char(min(data),'dd/mm/yyyy'))
              ,sum(importo_versato) importo_versato
          into w_estremi
              ,w_versato
          from versamenti         vers
              ,pratiche_tributo   prtr
         where prtr.tipo_pratica    in ('L','A')
           and prtr.tipo_tributo     = vers.tipo_tributo
           and prtr.pratica          = vers.pratica
           and prtr.anno             = vers.anno
           and vers.anno             = a_anno
           and vers.tipo_tributo||'' = 'ICI'
           and vers.cod_fiscale      = rec_prtr.cod_fiscale
           and vers.data_pagamento   between a_da_data and a_a_data
        ;
     EXCEPTION
        WHEN no_data_found THEN
           w_versato := 0;
           w_estremi := '        |00/00/0000';
           WHEN others THEN
              RAISE_APPLICATION_ERROR
              (-20999,'Errore nel recupero del totale versato per Accertamenti del '||
              'contribuente '||rec_prtr.cod_fiscale||' ('||SQLERRM||')');
     END;
-- E` una riscossione se il Totale dei versamenti e` > di 0
     IF nvl(w_versato,0) > 0      THEN
        FOR rec_cont in sel_dati_cont(rec_prtr.cod_fiscale) LOOP
           w_dati_cont   := rec_cont.dati_cont||'|'||rpad(rec_prtr.cod_fiscale,16,' ')||'|';
           w_estremi     := '        |00/00/0000';
           w_cod_fiscale := rec_prtr.cod_fiscale;
        END LOOP;  -- rec_cont
        FOR rec_sapr in sel_dati_sapr(rec_prtr.cod_fiscale) LOOP
           IF bRidotto THEN
              w_imposta    := w_imposta    + rec_sapr.imposta_rid;
              w_rendita    := w_rendita    + rec_sapr.rendita_rid;
              w_sanzioni   := w_sanzioni   + rec_sapr.sanzioni_rid;
              w_interessi  := w_interessi  + rec_sapr.interessi_rid;
           ELSE
              w_imposta    := w_imposta    + rec_sapr.imposta;
              w_rendita    := w_rendita    + rec_sapr.rendita;
              w_sanzioni   := w_sanzioni   + rec_sapr.sanzioni;
              w_interessi  := w_interessi  + rec_sapr.interessi;
           END IF;
        END LOOP;  -- rec_sapr
        w_riga := w_dati_cont||w_estremi;
        w_riga := w_riga||'|'||lpad(to_char(w_imposta * 100),10,0)||'|'||
                  lpad(to_char(w_rendita * 100),10,0)
                  ||'|'||lpad(to_char(w_interessi * 100),10,0)||'|'||
                  lpad(to_char(w_sanzioni * 100),10,0);
        w_progressivo   := w_progressivo   + 1;
        w_tot_imposte   := w_tot_imposte   + w_imposta;
        w_tot_rendite   := w_tot_rendite   + w_rendita;
        w_tot_interessi := w_tot_interessi + w_interessi;
        w_tot_sanzioni  := w_tot_sanzioni  + w_sanzioni;
        w_versato       := 0;
        w_imposta       := 0;
        w_rendita       := 0;
        w_interessi     := 0;
        w_sanzioni      := 0;
        BEGIN
           insert into WRK_TRAS_ANCI (anno,progressivo,dati)
           values (a_anno,w_progressivo,w_riga)
           ;
           w_riga := NULL;
        EXCEPTION
           WHEN others THEN
              RAISE_APPLICATION_ERROR
              (-20999,'Errore in inserimento record dati '||
              ' ('||SQLERRM||')');
        END;
     END IF;  -- w_versato > 0 ...
  END LOOP;  -- rec_prtr
  IF w_progressivo = MIN_REC THEN
     RAISE_APPLICATION_ERROR
     (-20999,'Non e'' presente nessuna riscossione. Impossibile creare il file relativo. '||
     ' ('||SQLERRM||')');
  END IF;  -- w_progressivo = MIN_REC
EXCEPTION
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Stampa Riscossioni ('||SQLERRM||')');
END;
/* End Procedure: STAMPA_RISCOSSIONI */
/
