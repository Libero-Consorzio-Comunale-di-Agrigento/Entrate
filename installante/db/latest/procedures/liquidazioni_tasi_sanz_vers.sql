--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_tasi_sanz_vers stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_TASI_SANZ_VERS
/*************************************************************************
 Rev.  Data        Autore    Descrizione 
 5     14/04/2025  RV        #77608
                             Adeguamento gestione sequenza sanzioni 
 4     03/01/2022  VD        Issue #53295
                             Adeguato a calcolo sanzioni liquidazioni IMU
                             (LIQUIDAZIONI_IMU_SANZ_VERS_711).
                             Modificato calcolo sanzioni in presenza di
                             un unico versamento.
 3     12/07/2016  AB        Nuovo sanzionamento 2016 
 2     21/08/2015  SC        Correzione condizioni sul cursore sel_vers_2:
                             poiche' il parametro p_imp_dovuta_acconto e' gia'
                             al netto dei versamenti, e' sufficiente 
                             che sia maggiore di 0 per considerare 
                             che il pagamento non e' stato fatto o 
                             era parziale.
 1     25/01/2015  VD        Prima emissione
*************************************************************************/
(  a_anno               IN number,
   a_pratica            IN number,
   a_cod_fiscale        IN varchar2,
   a_data_scad_acconto  IN date,
   a_data_scad_saldo    IN date,
   a_imp_dovuta_acconto IN number,
   a_imp_dovuta_saldo   IN number,
   a_utente             IN varchar2)
IS
--
C_TIPO_TRIBUTO           CONSTANT varchar2(5) := 'TASI';
--
C_TARD_VERS_ACC_INF_30   CONSTANT number := 206;
C_TARD_VERS_ACC_SUP_30   CONSTANT number := 207;
C_TARD_VERS_SAL_INF_30   CONSTANT number := 208;
C_TARD_VERS_SAL_SUP_30   CONSTANT number := 209;
C_TARD_VERS_ACC_SUP_90   CONSTANT number := 210;
C_TARD_VERS_SAL_SUP_90   CONSTANT number := 211;
--
w_errore                varchar2(200);
errore                  exception;
--
w_cod_sanzione          number;
w_imp_base_interessi    number;
w_gg_diff               number;
w_cod_istat             varchar2(6);
w_gg_ritardo_1          number := 15;
w_gg_ritardo_2          number := 90;
w_imp_dovuta_acconto    number;
w_imp_dovuta_saldo      number;
w_tot_vers_acc          number;
w_data_vers             date;
w_imp_versato           number;
w_conta_vers            number := 0;
w_versamenti_ravv_acc   number;
w_versamenti_ravv_sal   number;
w_data_pratica          date;

w_ind                         number;
type t_data_vers_t            is table of date index by binary_integer;
t_data_vers                   t_data_vers_t;
type t_imp_vers_t             is table of number index by binary_integer;
t_imp_vers                    t_imp_vers_t;
type t_tipo_vers_t            is table of varchar2(1) index by binary_integer;
t_tipo_vers                   t_tipo_vers_t;

-- Il cursore estrae tutti i versamenti fatti dopo la data di scadenza
CURSOR sel_vers (p_anno number
               , p_cod_fiscale varchar2
               --, p_data_scad_acconto date
               --, p_data_scad_saldo date
               ) IS
       select vers.tipo_versamento
            , vers.data_pagamento
            , sum(vers.importo_versato)   importo_versato
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo = 'TASI'
          and vers.cod_fiscale  = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   in ('A','U','S')
     group by vers.tipo_versamento
            , vers.data_pagamento
     order by vers.data_pagamento;
     /* minus
       (select vers.tipo_versamento
             , vers.data_pagamento
             , sum(vers.importo_versato)   importo_versato
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'TASI'
          and vers.cod_fiscale   = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   in ('A','U')
          and vers.data_pagamento   <= p_data_scad_acconto
     group by vers.tipo_versamento
            , vers.data_pagamento
        union
       select vers.tipo_versamento
            , vers.data_pagamento
            , sum(vers.importo_versato)   importo_versato
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'TASI'
          and vers.cod_fiscale   = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   = 'S'
          and vers.data_pagamento   <= p_data_scad_saldo
     group by vers.tipo_versamento
            , vers.data_pagamento
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
  select vers.data_pagamento
       , vers.importo_versato
    from versamenti       vers
   where vers.anno         = p_anno
     and vers.tipo_tributo   = 'TASI'
     and vers.cod_fiscale   = p_cod_fiscale
     and vers.pratica      is null
     and vers.tipo_versamento   = 'S'
     and vers.data_pagamento   <= p_data_scad_saldo
     and p_imp_dovuta_saldo <
      (select nvl(sum(vers.importo_versato),0) tot_sal
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'TASI'
          and vers.cod_fiscale   = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   = 'S'
          and vers.data_pagamento   <= p_data_scad_saldo
       )
     and p_imp_dovuta_acconto > 0
   /* SC 21/08/2015
     poiche' il parametro p_imp_dovuta_acconto e' gia'
     al netto dei versamenti, e' sufficiente
     che sia maggiore di 0 per considerare
     che il pagamento non e' stato fatto o
     era parziale.
        (select nvl(sum(vers.importo_versato),0) tot_acc
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'TASI'
          and vers.cod_fiscale   = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   in ('A','U')
       )
  order by 1
       ;*/
--------------------------------------------------------------------------------
-- (VD - 03/01/2022): Trattamento versamenti tardivi in acconto
procedure TARDIVO_ACCONTO is
begin
  IF nvl(w_imp_dovuta_acconto,0) < nvl(w_imp_versato,0) THEN
     w_imp_base_interessi := nvl(w_imp_dovuta_acconto,0);
  ELSE
     w_imp_base_interessi := nvl(w_imp_versato,0);
  END IF;
  w_imp_dovuta_acconto := w_imp_dovuta_acconto - w_imp_base_interessi; 
  w_imp_versato        := w_imp_versato - w_imp_base_interessi;
  IF w_data_vers > a_data_scad_acconto
  AND nvl(w_imp_base_interessi,0) != 0 THEN
     inserimento_interessi(a_pratica,NULL,a_data_scad_acconto,w_data_vers,w_imp_base_interessi,C_TIPO_TRIBUTO,'A',a_utente,a_data_scad_acconto);
     w_gg_diff := w_data_vers - a_data_scad_acconto;
     --
     -- (VD - 08/07/2016) - Modifiche per nuovo sanzionamento 2016 
     --
     IF w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') THEN
        IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 206 
           w_cod_sanzione := C_TARD_VERS_ACC_INF_30;
           inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_acconto);
        ELSIF
           w_gg_diff <= w_gg_ritardo_2 THEN            -- ANOMALIA 207 
           w_cod_sanzione := C_TARD_VERS_ACC_SUP_30;
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_acconto);
        ELSE
           w_cod_sanzione := C_TARD_VERS_ACC_SUP_90;   -- ANOMALIA 210 
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_acconto);
        END IF;
     ELSE
        IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 206 
           w_cod_sanzione := C_TARD_VERS_ACC_INF_30;
           inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_acconto);
        ELSE
           w_cod_sanzione := C_TARD_VERS_ACC_SUP_30;   -- ANOMALIA 207 
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_acconto);
        END IF;
     END IF;    
  END IF;
end;
--------------------------------------------------------------------------------
-- (VD - 03/01/2022): Trattamento versamenti tardivi a saldo
procedure TARDIVO_SALDO is
begin
  IF nvl(w_imp_dovuta_saldo,0) < nvl(w_imp_versato,0) THEN
     w_imp_base_interessi := nvl(w_imp_dovuta_saldo,0);
  ELSE
     w_imp_base_interessi := nvl(w_imp_versato,0);
  END IF;
  w_imp_dovuta_saldo := w_imp_dovuta_saldo - w_imp_base_interessi; 
  w_imp_versato      := w_imp_versato - w_imp_base_interessi;
  IF w_data_vers > a_data_scad_saldo 
  AND nvl(w_imp_base_interessi,0) != 0 THEN
     inserimento_interessi(a_pratica,NULL,a_data_scad_saldo,w_data_vers,w_imp_base_interessi,C_TIPO_TRIBUTO,'S',a_utente,a_data_scad_saldo);
     w_gg_diff := w_data_vers - a_data_scad_saldo;
     --
     -- (VD - 08/07/2016) - Modifiche per nuovo sanzionamento 2016 
     --
     IF w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') THEN
        IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 208 
           w_cod_sanzione := C_TARD_VERS_SAL_INF_30;
           inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_saldo);
        ELSIF
           w_gg_diff <= w_gg_ritardo_2 THEN            -- ANOMALIA 209 
           w_cod_sanzione := C_TARD_VERS_SAL_SUP_30;
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_saldo);
        ELSE
           w_cod_sanzione := C_TARD_VERS_SAL_SUP_90;   -- ANOMALIA 211 
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_saldo);
        END IF;
     ELSE
        IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 208 
           w_cod_sanzione := C_TARD_VERS_SAL_INF_30;
           inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_saldo);
        ELSE
           w_cod_sanzione := C_TARD_VERS_SAL_SUP_30;   -- ANOMALIA 209 
           inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_saldo);
        END IF;
     END IF;
  END IF;
end;
--------------------------------------------------------------------------------
--                    INIZIO
--------------------------------------------------------------------------------
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

   -- (Recupero la data della pratica per gestire correttamente le sanzioni dal 1/1/2016)  AB 12/07/2016
  	BEGIN
  		select data
  		  into w_data_pratica
  		  from pratiche_tributo
  		 where pratica = a_pratica
  		 ;
  	EXCEPTION
  	   WHEN others THEN
  		 w_errore := 'Errore in Ricerca Data Pratica '||a_pratica||
  							 ') '||'('||SQLERRM||')';
  		 RAISE errore;
  	END;

   -- Versamenti su ravvediemnto
   begin
      w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'TASI',a_anno,'A');
      w_versamenti_ravv_sal   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'TASI',a_anno,'S');
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
   --
   w_ind               := 0;
   --w_tot_versato_acc   := 0;
   --w_tot_versato_saldo := 0;
   --w_tot_versato_mini  := 0;
   --
   -- (VD - 03/01/2022): si seleziona il numero dei versamenti sono stati effettuati
   begin
     select count(*)
       into w_conta_vers
       from versamenti       vers
      where vers.anno         = a_anno
        and vers.tipo_tributo = 'TASI'
        and vers.cod_fiscale  = a_cod_fiscale
        and vers.pratica      is null
        and vers.tipo_versamento   in ('A','U','S');
   exception
     when others then
       w_conta_vers := 0;
   end;
   -- (VD - 03/01/2022): se esiste un solo versamento, si tratta per tipologia
   --                    (e non per data)
   if w_conta_vers = 1 then
      for rec_vers IN sel_vers (a_anno,a_cod_fiscale) 
      LOOP
         w_data_vers   := rec_vers.data_pagamento;
         w_imp_versato := nvl(rec_vers.importo_versato,0);
         if w_imp_versato > 0 then
            if a_data_scad_acconto is not null
            AND rec_vers.tipo_versamento in ('A','U')
            AND nvl(w_imp_dovuta_acconto,0) > 0 THEN
               TARDIVO_ACCONTO;
            END IF;
         END IF;
         -- Trattamento versamenti a saldo
         if w_imp_versato > 0 then
            if a_data_scad_saldo is not null
            AND rec_vers.tipo_versamento = 'S' 
            AND nvl(w_imp_dovuta_saldo,0) > 0 THEN
               TARDIVO_SALDO;
            end if;
         end if;
         --
         -- Se dopo aver trattato il versamento per tipo rimane un versato
         -- in eccedenza, si attribuisce all'altra tipologia di versamento
         -- (se eccedenza in acconto si attribuisce al saldo e viceversa)
         if w_imp_versato > 0 then
            if rec_vers.tipo_versamento in ('A','U') THEN
               TARDIVO_SALDO;
            else
               TARDIVO_ACCONTO;
            end if;
         end if;
      END LOOP;
   else
      w_conta_vers := 0;

      FOR rec_vers IN sel_vers (a_anno,a_cod_fiscale) 
      LOOP
         w_conta_vers  := w_conta_vers + 1;
         w_imp_versato := nvl(rec_vers.importo_versato,0);
         --
         IF w_imp_versato > 0 then
            if a_data_scad_acconto is not null 
            AND nvl(w_imp_dovuta_acconto,0) > 0 THEN
               if rec_vers.data_pagamento <= a_data_scad_acconto then
                  IF nvl(w_imp_dovuta_acconto,0) < nvl(w_imp_versato,0) THEN
                     w_imp_base_interessi := nvl(w_imp_dovuta_acconto,0);
                  ELSE
                     w_imp_base_interessi := nvl(w_imp_versato,0);
                  END IF;
                  w_imp_dovuta_acconto := w_imp_dovuta_acconto - w_imp_base_interessi; 
                  w_imp_versato        := w_imp_versato - w_imp_base_interessi;
               else
                  -- (VD - 03/01/2022): il primo versamento si considera 
                  --                    sempre in acconto
                  if rec_vers.tipo_versamento = 'A' or
                     w_conta_vers = 1 then
                     w_ind := w_ind + 1;
                     t_tipo_vers (w_ind) := rec_vers.tipo_versamento;
                     t_data_vers (w_ind) := rec_vers.data_pagamento;
                     t_imp_vers (w_ind)  := w_imp_versato;
                     w_imp_versato       := 0;
                  end if;
               end if;
            end if;
         end if;
         IF w_imp_versato > 0 then
            if a_data_scad_saldo is not null 
            AND nvl(w_imp_dovuta_saldo,0) > 0 THEN
               if rec_vers.data_pagamento <= a_data_scad_saldo then
                  IF nvl(w_imp_dovuta_saldo,0) < nvl(w_imp_versato,0) THEN
                     w_imp_base_interessi := nvl(w_imp_dovuta_saldo,0);
                  ELSE
                     w_imp_base_interessi := nvl(w_imp_versato,0);
                  END IF;
                  w_imp_dovuta_saldo := w_imp_dovuta_saldo - w_imp_base_interessi; 
                  w_imp_versato      := w_imp_versato - w_imp_base_interessi;
               else
                  if rec_vers.tipo_versamento = 'S' then
                     w_ind := w_ind + 1;
                     t_tipo_vers (w_ind) := rec_vers.tipo_versamento;
                     t_data_vers (w_ind) := rec_vers.data_pagamento;
                     t_imp_vers (w_ind)  := w_imp_versato;
                     w_imp_versato       := 0;
                  end if;
               end if;
            end if;
         end if;
         if w_imp_versato > 0 then   
            w_ind := w_ind + 1;
            t_tipo_vers (w_ind) := rec_vers.tipo_versamento;
            t_data_vers (w_ind) := rec_vers.data_pagamento;
            t_imp_vers (w_ind)  := w_imp_versato;
         end if;
      END LOOP;
      --
      -- (VD - 03/01/2022): si scorre l'array degli eventuali versamenti 
      --                    tardivi/in eccesso e si emettono le relative sanzioni
      --
      if w_ind > 0 then
        for w_ind in t_data_vers.first .. t_data_vers.last
        loop
          w_imp_versato := t_imp_vers (w_ind);
          w_data_vers   := t_data_vers (w_ind);
         --      
          if w_imp_versato > 0 then
             if a_data_scad_acconto is not null 
             AND nvl(w_imp_dovuta_acconto,0) > 0 THEN
                TARDIVO_ACCONTO;
             END IF;
          END IF;
          --
          if w_imp_versato > 0 then
             if a_data_scad_saldo is not null 
             AND nvl(w_imp_dovuta_saldo,0) > 0 THEN
                TARDIVO_SALDO;
             end if;
          end if;
        END LOOP;
      end if;
   END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'LIQUIDAZIONI_TASI_SANZ_VERS: '||sqlerrm);
END;
/
