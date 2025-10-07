--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_ici_sanz_vers stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_ICI_SANZ_VERS
(  a_anno               IN number,
   a_pratica            IN number,
   a_cod_fiscale        IN varchar2,
   a_data_scad_acconto  IN date,
   a_data_scad_saldo    IN date,
   a_imp_dovuta_acconto IN number,
   a_imp_dovuta_saldo   IN number,
   a_utente             IN varchar2)
IS
C_TIPO_TRIBUTO      CONSTANT varchar2(5) := 'ICI';
C_TARD_VERS_ACC_INF_30   CONSTANT number := 6;
C_TARD_VERS_ACC_SUP_30   CONSTANT number := 7;
C_TARD_VERS_SAL_INF_30   CONSTANT number := 8;
C_TARD_VERS_SAL_SUP_30   CONSTANT number := 9;
C_NUOVO         CONSTANT number := 100;
w_errore                varchar2(200);
errore                  exception;
w_cod_sanzione          number;
w_imp_base_interessi    number;
w_gg_diff               number;
w_cod_istat             varchar2(6);
w_giorni_ritardo        number;
w_imp_dovuta_acconto    number;
w_imp_dovuta_saldo      number;
w_tot_vers_acc          number;
w_versamenti_ravv_acc   number;
w_versamenti_ravv_sal   number;
-- Il cursore estrae tutti i versamenti fatti dopo la data di scadenza
CURSOR sel_vers (p_anno number
               , p_cod_fiscale varchar2
               , p_data_scad_acconto date
               , p_data_scad_saldo date) IS
       select vers.tipo_versamento,vers.data_pagamento,
              vers.importo_versato
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and (    vers.pratica      is null
         --      or  prtr.tipo_pratica  = 'V'
              )
          and vers.tipo_versamento   in ('A','U','S')
        minus
       (select vers.tipo_versamento,vers.data_pagamento,
               vers.importo_versato
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and (    vers.pratica      is null
          --     or  prtr.tipo_pratica  = 'V'
              )
          and vers.tipo_versamento   in ('A','U')
          and vers.data_pagamento   <= p_data_scad_acconto
        union
       select vers.tipo_versamento,vers.data_pagamento,
              vers.importo_versato
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and (    vers.pratica      is null
         --      or  prtr.tipo_pratica  = 'V'
              )
          and vers.tipo_versamento   = 'S'
          and vers.data_pagamento   <= p_data_scad_saldo
        )
       ;
-- il cursore estrae tutti i versamenti a saldo fatti entro la data di scadenza
-- se l'importo dei versamenti in acconto non copre interamente il dovuto i acconto e
-- se l'importo dei versamenti a saldo supera il dovuto a saldo
CURSOR sel_vers_2 (p_anno               number
                  ,p_cod_fiscale        varchar2
                  ,p_data_scad_acconto  date
                  ,p_data_scad_saldo    date
                  ,p_imp_dovuta_acconto number
                  ,p_imp_dovuta_saldo   number) IS
  select vers.data_pagamento,
         vers.importo_versato
    from versamenti       vers
        ,pratiche_tributo prtr
   where vers.anno         = p_anno
     and vers.tipo_tributo   = 'ICI'
     and vers.cod_fiscale   = p_cod_fiscale
     and prtr.pratica (+)   = vers.pratica
     and (    vers.pratica      is null
     --     or  prtr.tipo_pratica  = 'V'
         )
     and vers.tipo_versamento   = 'S'
     and vers.data_pagamento   <= p_data_scad_saldo
     and p_imp_dovuta_saldo <
      (select nvl(sum(vers.importo_versato),0) tot_sal
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and (    vers.pratica      is null
        --       or  prtr.tipo_pratica  = 'V'
              )
          and vers.tipo_versamento   = 'S'
          and vers.data_pagamento   <= p_data_scad_saldo
       )
     and p_imp_dovuta_acconto >
      (select nvl(sum(vers.importo_versato),0) tot_acc
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and (    vers.pratica      is null
        --       or  prtr.tipo_pratica  = 'V'
              )
          and vers.tipo_versamento   in ('A','U')
       )
  order by 1
       ;
BEGIN
   BEGIN
      select lpad(to_char(d.pro_cliente),3,'0')||
             lpad(to_char(d.com_cliente),3,'0')
        into w_cod_istat
        from dati_generali           d
      ;
   EXCEPTION
      WHEN no_data_found THEN
         w_errore := 'Dati Generali non inseriti';
         RAISE errore;
      WHEN others THEN
         w_errore := 'Errore in ricerca Dati Generali';
         RAISE errore;
   END;
   if w_cod_istat = '038021' then  -- SANT'AGOSTINO
      w_giorni_ritardo := 8;
   else
      w_giorni_ritardo := 5;
   end if;
   -- Versamenti su ravvediemnto
   begin
      w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'ICI',a_anno,'A');
      w_versamenti_ravv_sal   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'ICI',a_anno,'S');
   end;
   -- sottraggo all'imposta dovuta i versamenti (reali) fatti su ravvedimento
   w_imp_dovuta_acconto  := a_imp_dovuta_acconto - w_versamenti_ravv_acc;
   if w_imp_dovuta_acconto < 0 then
      w_imp_dovuta_acconto := 0;
   end if;
   w_imp_dovuta_saldo    := a_imp_dovuta_saldo   - w_versamenti_ravv_sal;
   if w_imp_dovuta_saldo < 0 then
      w_imp_dovuta_saldo := 0;
   end if;
   FOR rec_vers IN sel_vers (a_anno,a_cod_fiscale, a_data_scad_acconto, a_data_scad_saldo) LOOP
      IF rec_vers.tipo_versamento != 'S'
        AND rec_vers.data_pagamento > a_data_scad_acconto THEN
         IF nvl(w_imp_dovuta_acconto,0) < nvl(rec_vers.importo_versato,0) THEN
            w_imp_base_interessi := nvl(w_imp_dovuta_acconto,0);
         ELSE
            w_imp_base_interessi := nvl(rec_vers.importo_versato,0);
         END IF;
         IF nvl(w_imp_base_interessi,0) != 0 THEN
            inserimento_interessi(a_pratica,NULL,a_data_scad_acconto,rec_vers.data_pagamento,w_imp_base_interessi,C_TIPO_TRIBUTO,'A',a_utente);
            w_gg_diff := rec_vers.data_pagamento - a_data_scad_acconto;
         --  IF nvl(rec_vers.importo_versato,0) != nvl(w_imp_dovuta_saldo,0) then
            IF w_gg_diff <= w_giorni_ritardo THEN   -- ANOMALIA 6 e 106
               w_cod_sanzione := C_TARD_VERS_ACC_INF_30;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               w_cod_sanzione := w_cod_sanzione + C_NUOVO;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
            ELSE            -- ANOMALIA 7 e 107
               w_cod_sanzione := C_TARD_VERS_ACC_SUP_30;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               w_cod_sanzione := w_cod_sanzione + C_NUOVO;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
            END IF;    -- fine if se imp. base int. > 0
          --    END IF;
         END IF;
--
-- 11/01/2001 D.M.
-- Caso di unico (o erroneamente indicato coma acconto) versamento tardivo
-- comprendente sia acconto che saldo.
--
         IF rec_vers.data_pagamento > a_data_scad_saldo THEN
            IF nvl(w_imp_dovuta_acconto,0) + nvl(w_imp_dovuta_saldo,0)
                                         <= nvl(rec_vers.importo_versato,0) THEN
              w_imp_base_interessi := nvl(w_imp_dovuta_saldo,0);
            ELSE
            -- Rimanenza di Versamento tolta la parte in acconto pari alla imposta dovuta in acconto
            -- gia` trattata.
              w_imp_base_interessi := nvl(rec_vers.importo_versato,0) - nvl(w_imp_dovuta_acconto,0);
            END IF;
            IF nvl(w_imp_base_interessi,0) != 0 THEN
               inserimento_interessi(a_pratica,NULL,a_data_scad_saldo,rec_vers.data_pagamento,w_imp_base_interessi,C_TIPO_TRIBUTO,'S',a_utente);
               w_gg_diff := rec_vers.data_pagamento - a_data_scad_acconto;
               IF w_gg_diff <= w_giorni_ritardo THEN   -- ANOMALIA 8 e 108
                 w_cod_sanzione := C_TARD_VERS_SAL_INF_30;
                 inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
                 w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                 inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               ELSE            -- ANOMALIA 9 e 109
                 w_cod_sanzione := C_TARD_VERS_SAL_SUP_30;
                 inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
                 w_cod_sanzione := w_cod_sanzione + C_NUOVO;
                 inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               END IF;    -- fine if se imp. base int. > 0
            END IF; -- fine if base interessi.
         END IF;  -- fine if su data saldo scaduta.
       --
       -- fine if se tipo versam. = acconto o unico.
       --
      ELSIF rec_vers.tipo_versamento = 'S'
        AND rec_vers.data_pagamento > a_data_scad_saldo THEN
         IF nvl(w_imp_dovuta_saldo,0) < nvl(rec_vers.importo_versato,0) THEN
            w_imp_base_interessi := nvl(w_imp_dovuta_saldo,0);
         ELSE
            w_imp_base_interessi := nvl(rec_vers.importo_versato,0);
         END IF;
         IF nvl(w_imp_base_interessi,0) != 0 THEN
            inserimento_interessi(a_pratica,NULL,a_data_scad_saldo,rec_vers.data_pagamento,w_imp_base_interessi,C_TIPO_TRIBUTO,'S',a_utente);
            w_gg_diff := rec_vers.data_pagamento - a_data_scad_saldo;
            IF w_gg_diff <= w_giorni_ritardo THEN   -- ANOMALIA 8 e 108
               w_cod_sanzione := C_TARD_VERS_SAL_INF_30;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               w_cod_sanzione := C_TARD_VERS_SAL_INF_30 + C_NUOVO;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
            ELSE            -- ANOMALIA 9 e 109
               w_cod_sanzione := C_TARD_VERS_SAL_SUP_30;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
               w_cod_sanzione := C_TARD_VERS_SAL_SUP_30 + C_NUOVO;
               inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente);
            END IF;
         END IF;  -- fine if se imp. base int. > 0
      END IF; -- fine if se tipo versam. = saldo
   END LOOP;
-- Inserimento interessi per tardivo versamento in acconto, per versamenti fatti a saldo
-- considerati come acconto
   BEGIN
       select nvl(sum(vers.importo_versato),0) tot_acc
         into w_tot_vers_acc
         from versamenti       vers
             ,pratiche_tributo prtr
        where vers.anno          = a_anno
          and vers.tipo_tributo  = 'ICI'
          and vers.cod_fiscale   = a_cod_fiscale
          and prtr.pratica (+)   = vers.pratica
          and vers.pratica      is null
          and vers.tipo_versamento   in ('A','U')
            ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in estrazione Totale Versamenti in Acconto';
         RAISE errore;
   END;
   --Sottraggo subito all'imposta dovuta in acconto il totale dei versamenti in acconto
   --fatti entro la data di scadenza
   --Inserisco gli interessi sui versamenti a saldo che vengono considerati come acconto,
   --devo prima escludere l'ammontare dei versamenti a saldo che va a coprire l'imposta dovuta a saldo
   w_imp_dovuta_acconto := w_imp_dovuta_acconto - w_tot_vers_acc;
   w_imp_dovuta_saldo   := w_imp_dovuta_saldo;
   w_imp_base_interessi := 0;
   FOR rec_vers_2 IN sel_vers_2 ( a_anno,a_cod_fiscale, a_data_scad_acconto, a_data_scad_saldo
                              , w_imp_dovuta_acconto ,w_imp_dovuta_saldo) LOOP
      if w_imp_dovuta_saldo > 0 then
         if w_imp_dovuta_saldo >= rec_vers_2.importo_versato then
            w_imp_dovuta_saldo := w_imp_dovuta_saldo - rec_vers_2.importo_versato;
         else
            w_imp_base_interessi := rec_vers_2.importo_versato - w_imp_dovuta_saldo;
            w_imp_dovuta_saldo := 0;
         end if;
      else
        w_imp_base_interessi := rec_vers_2.importo_versato;
      end if;
      if w_imp_base_interessi > 0 and w_imp_dovuta_acconto > 0 then
         w_imp_base_interessi := least(w_imp_base_interessi,w_imp_dovuta_acconto);
         inserimento_interessi(a_pratica,NULL,a_data_scad_acconto,rec_vers_2.data_pagamento,w_imp_base_interessi,C_TIPO_TRIBUTO,'A',a_utente);
         w_imp_dovuta_acconto := w_imp_dovuta_acconto - w_imp_base_interessi;
      end if;
   END LOOP;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: LIQUIDAZIONI_ICI_SANZ_VERS */
/

