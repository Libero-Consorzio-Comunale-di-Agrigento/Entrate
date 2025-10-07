--liquibase formatted sql 
--changeset abrandolini:20250326_152423_tras_riscossioni stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     TRAS_RISCOSSIONI
(a_anno           IN   number,
 a_non_riscossi   IN OUT   number,
 a_da_data        IN   date,
 a_a_data         IN   date)
IS
MIN_REC              CONSTANT number(1) := 1;
errore               exception;
w_errore             varchar2(2000);
bSocieta             Boolean;
bRidotto             Boolean      := FALSE;
w_cod_comune         number(3);
w_cod_provincia      number(3);
w_sigla_cf           varchar2(8);
w_des_comune         varchar2(25);
w_sigla_provincia    varchar2(2);
w_euro               number(6,2);
w_fase_euro          number(1);
w_progressivo        number(12);
w_riga               varchar2(180);
w_dati_cont          varchar2(105);
w_cod_fiscale        varchar2(16);
w_coda               varchar2(20);
w_estremi            varchar2(14);
w_data_versamento    varchar2(8);
w_versato            number(10,2) := 0;
w_importo            number(10,2) := 0;
w_imposta            number(10,2) := 0;
w_rendita            number(10,2) := 0;
w_interessi          number(10,2) := 0;
w_sanzioni           number(10,2) := 0;
w_num_soggetti       number(6)    := 0;
w_num_societa        number(5)    := 0;
w_tot_imposte        number(16,2) := 0;
w_tot_rendite        number(16,2) := 0;
w_tot_interessi      number(16,2) := 0;
w_tot_sanzioni       number(16,2) := 0;
w_1000               number;
w_appoggio           varchar2(16);
w_flag_tipo          number;
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
  select rpad(nvl(sogg.cognome_nome,' '),60) denominazione,
    rpad(nvl(sogg.cognome,' '),24) cognome, rpad(nvl(substr(sogg.nome,1,20),' '),20) nome,
    lpad(nvl(to_char(sogg.data_nas,'yyyy'),0),4,0) anno_nas,
    lpad(nvl(to_char(sogg.data_nas,'mm'),0),2,0) mese_nas,
    lpad(nvl(to_char(sogg.data_nas,'dd'),0),2,0) giorno_nas,
    nvl(sogg.tipo,'2') tipo, nvl(sogg.sesso,' ') sesso,
    rpad(nvl(comu_res.DENOMINAZIONE,' '),25) des_res,
    rpad(nvl(prov_res.SIGLA,' '),2) sigla_pro_res,
    rpad(nvl(comu_nas.DENOMINAZIONE,' '),25) des_nas,
    rpad(nvl(prov_nas.SIGLA,' '),2) sigla_pro_nas
    FROM ad4_comuni comu_res, ad4_provincie prov_res,
    ad4_comuni comu_nas, ad4_provincie prov_nas ,
    soggetti sogg, contribuenti cont
   where comu_res.provincia_stato   = prov_res.provincia (+)
     and sogg.cod_com_res       = comu_res.comune (+)
     and sogg.cod_pro_res      = comu_res.provincia_stato (+)
     and comu_nas.provincia_stato   = prov_nas.provincia (+)
     and sogg.cod_com_nas      = comu_nas.comune (+)
     and sogg.cod_pro_nas      = comu_nas.provincia_stato (+)
     and sogg.ni                = cont.ni
     and cont.cod_fiscale      = p_cod_fiscale
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
FUNCTION f_aliquota_base(p_anno number)
return number
IS
w_return number;
BEGIN
   BEGIN
   select aliquota * 100
     into w_return
     from aliquote
    where anno = p_anno
      and tipo_aliquota = 1
      and tipo_tributo  = 'ICI'
   ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
   WHEN OTHERS THEN
      RETURN -1;
   END;
   RETURN w_return;
END;
BEGIN  -- TRASMISSIONE_RISCOSSIONI_93
  BEGIN  -- CONTROLLO DATI COMUNE
     select com_cliente
           ,pro_cliente
           ,cambio_euro
           ,fase_euro
       into w_cod_comune
           ,w_cod_provincia
           ,w_euro
           ,w_fase_euro
       from dati_generali
     ;
     IF w_cod_comune is NULL OR w_cod_provincia is NULL THEN
        w_errore := 'Elaborazione terminata con anomalie:
                     mancano i codici identificativi del Comune.
                     Caricare la tabella relativa. ('||SQLERRM||')';
        RAISE errore;
     END IF;
  EXCEPTION
     WHEN no_data_found THEN
        null;
     WHEN others THEN
        w_errore := 'Errore in ricerca Dati Generali. (1) ('||SQLERRM||')';
        RAISE errore;
  END;
  if w_fase_euro = 1 then
     w_1000  := 1000;
  else
     w_1000  := 1;
  end if;
  BEGIN
     select rpad(nvl(substr(comu.denominazione,1,25),' '),25)
           ,rpad(nvl(sigla,' '),2)
           ,rpad(comu.SIGLA_CFIS,4)
       into w_des_comune
           ,w_sigla_provincia
           ,w_sigla_cf
       from ad4_comuni    comu
           ,ad4_provincie prov
      where provincia        = provincia_stato
        and comune           = w_cod_comune
        and provincia_stato  = w_cod_provincia
     ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in ricerca dati Comune ('||SQLERRM||')';
        RAISE errore;
  END;
  BEGIN
     delete from wrk_tras_anci;
  END;
-- w_progressivo parte da MIN_REC perche i primi due record (tipo 0 e 1)
-- vengono inseriti in fondo.
  w_cod_fiscale   := NULL;
  a_non_riscossi  := 0;
  w_progressivo   := MIN_REC;
  FOR rec_prtr IN sel_dati_prtr(a_anno) LOOP
     BEGIN
        -- Totale dei versamenti relativi ada Accertamenti del Contribuente
        select to_char(min(data_pagamento),'yyyymmdd') data_versamento
              ,sum(importo_versato)                    importo_versato
          into w_data_versamento
              ,w_versato
          from versamenti vers
              ,pratiche_tributo prtr
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
           w_versato         := 0;
           w_data_versamento := 0;
        WHEN others THEN
           w_errore := 'Errore nel recupero del totale versato per Accertamenti '||
                       'del contribuente '||rec_prtr.cod_fiscale||' ('||SQLERRM||')';
           RAISE errore;
     END;
     -- E' una riscossione se il Totale dei versamenti e` > di 0
     IF nvl(w_versato,0) > 0 THEN
        FOR rec_cont in sel_dati_cont(rec_prtr.cod_fiscale) LOOP
           IF (rec_cont.tipo = '0' ) OR (rec_cont.sesso = 'S' and rec_cont.tipo = '2') THEN
              -- Tipo Record 1
              w_dati_cont := '1'||rec_cont.cognome||rec_cont.nome||rec_cont.sesso
                                ||rec_cont.des_nas||rec_cont.sigla_pro_nas
                                ||rec_cont.anno_nas||rec_cont.mese_nas||rec_cont.giorno_nas
                                ||rpad(rec_prtr.cod_fiscale,16,' ');
--            w_num_soggetti:= w_num_soggetti + 1;
              w_flag_tipo   := 1;
              w_estremi     := lpad(' ',14);
              w_coda        := lpad(' ',20);
           ELSE
              -- Tipo Record 2
              w_dati_cont := '2'||rec_cont.denominazione||rec_cont.des_res
                                ||rec_cont.sigla_pro_res
                                ||rpad(rec_prtr.cod_fiscale,16,' ');
--            w_num_societa := w_num_societa + 1;
              w_flag_tipo   := 2;
              w_estremi     := lpad(' ',10);
              w_coda        := lpad(' ',17);
           END IF;
           w_cod_fiscale := rec_prtr.cod_fiscale;
        END LOOP;  -- rec_cont
        IF (abs(w_versato - rec_prtr.importo_ridotto) < w_1000) THEN
           bRidotto := TRUE;
        ELSE
           bRidotto := FALSE;
        END IF;
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
        w_riga := w_dati_cont||w_estremi||lpad(w_data_versamento,8,'0');
        if w_fase_euro = 1 then
           w_riga := w_riga||lpad(trunc(w_imposta),10,0)||lpad(trunc(w_rendita),10,0)
                           ||lpad(trunc(w_interessi),10,0)||lpad(trunc(w_sanzioni),10,0)
                           ||'0'||w_coda;
        else
           w_riga := w_riga||lpad(w_imposta * 100,10,0)||lpad(w_rendita * 100,10,0)
                           ||lpad(w_interessi * 100,10,0)||lpad(w_sanzioni * 100,10,0)
                           ||'1'||w_coda;
        end if;
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
           w_errore := 'Errore in inserimento record dati ('||SQLERRM||')';
           RAISE errore;
        END;
        IF w_flag_tipo = 1 THEN
           w_num_soggetti := w_num_soggetti + 1;
        ELSE
           w_num_societa  := w_num_societa + 1;
        END IF;
     ELSE
        a_non_riscossi := a_non_riscossi + 1;
     END IF;  -- w_versato > 0 ...
  END LOOP;  -- rec_prtr
  IF w_progressivo = MIN_REC THEN
     w_errore := 'Non e'' presente nessuna riscossione. Impossibile creare il file relativo.';
     RAISE errore;
  ELSE
     -- CREAZIONE TIPO RECORD 0
     w_appoggio := w_sigla_cf||'A'||'001';
     w_riga := '0'||w_appoggio||to_char(sysdate,'yyyy')||to_char(sysdate,'mm')
                  ||to_char(sysdate,'dd')
                  ||w_des_comune||w_sigla_provincia||f_aliquota_base(a_anno)||lpad(' ',133);
     BEGIN
        insert into WRK_TRAS_ANCI (anno, progressivo,dati)
        values (a_anno,1,w_riga)
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in inserimento record di testa 0 ('||SQLERRM||')';
           RAISE errore;
     END;
     -- CREAZIONE TIPO RECORD 9
     w_riga := '9'||w_appoggio||to_char(sysdate,'yyyy')||to_char(sysdate,'mm')
                  ||to_char(sysdate,'dd')
                  ||lpad(w_num_soggetti,6,0)||lpad(w_num_societa,5,0);
     if w_fase_euro = 1 then
        w_riga := w_riga
                  ||lpad(w_tot_imposte,16,0)||lpad(w_tot_rendite,16,0)
                  ||lpad(w_tot_interessi,16,0)||lpad(w_tot_sanzioni,16,0)
                  ||lpad(round(w_tot_imposte/w_euro,2)*100,16,0)
                  ||lpad(round(w_tot_rendite/w_euro,2)*100,16,0)
                  ||lpad(round(w_tot_interessi/w_euro,2)*100,16,0)
                  ||lpad(round(w_tot_sanzioni/w_euro,2)*100,16,0);
     else
        w_riga := w_riga
                  ||lpad(round(w_tot_imposte*w_euro,0),16,0)
                  ||lpad(round(w_tot_rendite*w_euro),16,0)
                  ||lpad(round(w_tot_interessi*w_euro,0),16,0)
                  ||lpad(round(w_tot_sanzioni*w_euro,0),16,0)
                  ||lpad(w_tot_imposte*100,16,0)
                  ||lpad(w_tot_rendite*100,16,0)
                  ||lpad(w_tot_interessi*100,16,0)
                  ||lpad(w_tot_sanzioni*100,16,0);
     end if;
     w_riga := w_riga||lpad(' ',23);
     BEGIN
        insert into WRK_TRAS_ANCI (anno,progressivo,dati)
        values (a_anno,w_progressivo+1,w_riga)
        ;
     EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in inserimento record di coda 9 ('||SQLERRM||')';
           RAISE errore;
     END;
  END IF;  -- w_progressivo = MIN_REC
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN others THEN
        ROLLBACK;
   RAISE_APPLICATION_ERROR
          (-20999,'Errore in Trasmissione Riscossioni su supporto magnetico ('||SQLERRM||')');
END;
/* End Procedure: TRAS_RISCOSSIONI */
/
