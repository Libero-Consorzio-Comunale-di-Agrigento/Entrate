--liquibase formatted sql 
--changeset abrandolini:20250326_152423_liquidazioni_ici_sanz_vers_711 stripComments:false runOnChange:true 
 
create or replace procedure LIQUIDAZIONI_ICI_SANZ_VERS_711
/************************************************************************* 
 Rev.  Data         Autore    Descrizione
 011   14/04/2025   RV        #77608
                              Adeguamento gestione sequenza sanzioni 
 010   27/12/2021   VD        Modificato calcolo sanzioni in presenza di
                              un unico versamento
 009   03/05/2018   VD        Modificata totalizzazione versamenti per 
                              gestire eventuali eccedenze 
 008   18/07/2014   VD        Corretto calcolo interessi nel caso di cui 
                              alla rev. 7 
 007   14/07/2017   VD        Corretta gestione 2 versamenti in acconto di 
                              cui il secondo tardivo anche per il saldo 
 006   16/12/2016   VD        Modificato trattamento versamenti: ora la 
                              tipologia prevale sulla data pagamento.
                              Aggiunto trattamento finale per gestire 
                              versamenti in acconto in eccesso a copertura 
                              del saldo e viceversa 
 005   07/09/2016   VD        Aggiunto controllo su data versamento unico: 
                              viene considerato di mini IMU solo se la data 
                              è maggiore sia della data di acconto che della 
                              data di saldo 
 004   25/08/2016   VD        Modificato trattamento versamenti: 
                              anzichè considerare il totale diviso 
                              per tipo, ora i versamenti vengono 
                              trattati una alla volta.
 003   08/07/2016   VD        Gestione nuovo sanzionamento per versamenti 
                              effettuati oltre 90 gg dalla scadenza (relativi 
                              a pratiche dal 2016) 
 002   21/08/2015   SC        Correzione condizioni sul cursore sel_vers_2:
                              poiche' il parametro p_imp_dovuta_acconto 
                              e' gia' al netto dei versamenti, e' sufficiente 
                              che sia maggiore di 0 per considerare che il 
                              pagamento non e' stato fatto o era parziale.
 001   25/11/2014   PM        Correzione estrazione versamenti tardivi per 
                              gestire dei versamenti doppi nello stesso giorno  
*************************************************************************/
(  a_anno                     IN number,
   a_pratica                  IN number,
   a_cod_fiscale              IN varchar2,
   a_data_scad_acconto        IN date,
   a_data_scad_saldo          IN date,
   a_imp_dovuta_acconto       IN number,
   a_imp_dovuta_saldo         IN number,
   a_utente                   IN varchar2,
   a_data_scad_mini           IN date     default NULL,
   a_imp_dovuta_mini          IN number   default NULL)
IS
--
C_TIPO_TRIBUTO                CONSTANT varchar2(5) := 'ICI';
--
C_TARD_VERS_ACC_INF_30        CONSTANT number := 206;
C_TARD_VERS_ACC_SUP_30        CONSTANT number := 207;
C_TARD_VERS_SAL_INF_30        CONSTANT number := 208;
C_TARD_VERS_SAL_SUP_30        CONSTANT number := 209;
C_TARD_VERS_ACC_SUP_90        CONSTANT number := 210;
C_TARD_VERS_SAL_SUP_90        CONSTANT number := 211;
--
C_TARD_VERS_MINI_INF_15       CONSTANT number := 504;
C_TARD_VERS_MINI_INF_90       CONSTANT number := 505;
C_TARD_VERS_MINI_SUP_90       CONSTANT number := 506;
--
w_errore                varchar2(200);
errore                  exception;
w_cod_sanzione          number;
w_imp_base_interessi    number;
w_gg_diff               number;
w_cod_istat             varchar2(6);
w_gg_ritardo_1          number := 15;
w_gg_ritardo_2          number := 90;
w_imp_dovuta_acconto    number;
--w_imp_dovuta_acconto_meno_vers number;
w_imp_dovuta_saldo      number;
w_imp_dovuta_mini       number;
w_data_vers             date;
w_imp_versato           number;
--w_tot_versato_acc       number := 0;
--w_tot_versato_sal       number := 0;
--w_tot_versato_mini      number := 0;
w_conta_vers            number := 0;
w_versamenti_ravv_acc   number;
w_versamenti_ravv_sal   number;
w_data_pratica          date;
--w_data_acconto          date := to_date(null);
--w_data_saldo            date := to_date(null);
--w_data_mini             date := to_date(null);

w_ind                         number;
type t_data_vers_t            is table of date index by binary_integer;
t_data_vers                   t_data_vers_t;
type t_imp_vers_t             is table of number index by binary_integer;
t_imp_vers                    t_imp_vers_t;
type t_tipo_vers_t            is table of varchar2(1) index by binary_integer;
t_tipo_vers                   t_tipo_vers_t;

-- Il cursore estrae tutti i versamenti 
CURSOR sel_vers (p_anno              number
               , p_cod_fiscale       varchar2
               ) IS
       select vers.tipo_versamento
            , vers.data_pagamento
            , sum(vers.importo_versato)   importo_versato
         from versamenti       vers
        where vers.anno         = p_anno
          and vers.tipo_tributo   = 'ICI'
          and vers.cod_fiscale   = p_cod_fiscale
          and vers.pratica      is null
          and vers.tipo_versamento   in ('A','U','S')
     group by vers.tipo_versamento
            , vers.data_pagamento
     order by /*decode(vers.tipo_versamento,'S',2,1)
            , */ vers.data_pagamento
       ;
--------------------------------------------------------------------------------
-- (VD - 27/12/2021): Trattamento versamenti tardivi in acconto
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
-- (VD - 27/12/2021): Trattamento versamenti tardivi a saldo
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
   -- Versamenti su ravvedimento 
   begin
      w_versamenti_ravv_acc   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'ICI',a_anno,'A');
      w_versamenti_ravv_sal   := F_IMPORTO_VERS_RAVV(a_cod_fiscale,'ICI',a_anno,'S');
   end;
   -- sottraggo all'imposta dovuta i versamenti (reali) fatti su ravvedimento
   w_imp_dovuta_acconto  := a_imp_dovuta_acconto - w_versamenti_ravv_acc;
   if w_imp_dovuta_acconto < 0 then
      w_imp_dovuta_acconto := 0;
   end if;
   w_imp_dovuta_saldo    := a_imp_dovuta_saldo - w_versamenti_ravv_sal;
   if w_imp_dovuta_saldo < 0 then
      w_imp_dovuta_saldo := 0;
   end if;
   w_imp_dovuta_mini := nvl(a_imp_dovuta_mini,0);
   --
   w_ind               := 0;
   --w_tot_versato_acc   := 0;
   --w_tot_versato_saldo := 0;
   --w_tot_versato_mini  := 0;
   --
   -- (VD - 23/12/2021): si seleziona il numero dei versamenti sono stati effettuati
   begin
     select count(*)
       into w_conta_vers
       from versamenti       vers
      where vers.anno         = a_anno
        and vers.tipo_tributo = 'ICI'
        and vers.cod_fiscale  = a_cod_fiscale
        and vers.pratica      is null
        and vers.tipo_versamento   in ('A','U','S');
   exception
     when others then
       w_conta_vers := 0;
   end;
   -- (VD - 27/12/2021): se esiste un solo versamento, si tratta per tipologia
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
         --dbms_output.put_line('LIQUIDAZIONI_ICI_SANZ_VERS_711 w_conta_vers '||w_conta_vers);
         --dbms_output.put_line('LIQUIDAZIONI_ICI_SANZ_VERS_711 w_imp_dovuta_acconto '||w_imp_dovuta_acconto);
         --dbms_output.put_line('LIQUIDAZIONI_ICI_SANZ_VERS_711 w_imp_dovuta_saldo '||w_imp_dovuta_saldo);
         --dbms_output.put_line('LIQUIDAZIONI_ICI_SANZ_VERS_711 w_imp_dovuta_mini '||w_imp_dovuta_mini);
         --dbms_output.put_line('LIQUIDAZIONI_ICI_SANZ_VERS_711 w_imp_versato '||w_imp_versato);
         --
         -- Trattamento mini IMU: si considera l'eventuale versamento unico  
         -- come relativo alla mini IMU  
         -- (VD - 07/09/2016): il versamento unico viene considerato di mini IMU 
         --                    solo se la data e' superiore sia alla scadenza 
         --                    dell'acconto che alla scadenza del saldo 
         -- 
         IF rec_vers.tipo_versamento = 'U' 
           AND w_imp_versato > 0
           AND a_data_scad_mini is not null 
           AND rec_vers.data_pagamento > a_data_scad_acconto
           AND rec_vers.data_pagamento > a_data_scad_saldo 
           AND nvl(w_imp_dovuta_mini,0) > 0 THEN
            IF nvl(w_imp_dovuta_mini,0) < nvl(w_imp_versato,0) THEN
               w_imp_base_interessi := nvl(w_imp_dovuta_mini,0);
            ELSE
               w_imp_base_interessi := nvl(w_imp_versato,0);
            END IF;
            w_imp_dovuta_mini := w_imp_dovuta_mini - w_imp_base_interessi;
            w_imp_versato     := w_imp_versato - w_imp_base_interessi;
            if rec_vers.data_pagamento > a_data_scad_mini THEN
               IF nvl(w_imp_base_interessi,0) != 0 THEN
                  inserimento_interessi(a_pratica,NULL,a_data_scad_mini,rec_vers.data_pagamento,w_imp_base_interessi,C_TIPO_TRIBUTO,'M',a_utente,a_data_scad_mini);
                  w_gg_diff := rec_vers.data_pagamento - a_data_scad_mini;
                  --
                  -- (VD - 08/07/2016) - Modifiche per nuovo sanzionamento 2016 
                  --
                  IF w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') THEN
                     IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 504 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_15;
                        inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_mini);
                     ELSIF
                        w_gg_diff <= w_gg_ritardo_2 THEN            -- ANOMALIA 505 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_90;
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     ELSE
                        w_cod_sanzione := C_TARD_VERS_MINI_SUP_90;   -- ANOMALIA 506 
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     END IF;
                  ELSE
                     IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 504 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_15;
                        inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_mini);
                     ELSE
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_90;   -- ANOMALIA 505 
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     END IF;
                  END IF;
               END IF;  -- fine if se imp. base int. > 0 
            END IF; -- fine if se tipo versam. = unico (per mini IMU) 
         END IF;
         --
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo mini 1: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo mini 1: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo mini 1: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo mini 1: '||w_imp_dovuta_saldo);
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
                  -- (VD - 27/12/2021): il primo versamento si considera 
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
         --
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo acconto: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo acconto: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo acconto: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo acconto: '||w_imp_dovuta_saldo);
         --
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
         --
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo saldo: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo saldo: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo saldo: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo saldo: '||w_imp_dovuta_saldo);
         --
         IF w_imp_versato > 0 then
            if a_data_scad_mini is not null 
            AND nvl(w_imp_dovuta_mini,0) > 0 THEN
               if rec_vers.data_pagamento <= a_data_scad_mini then
                  IF nvl(w_imp_dovuta_mini,0) < nvl(w_imp_versato,0) THEN
                     w_imp_base_interessi := nvl(w_imp_dovuta_mini,0);
                  ELSE
                     w_imp_base_interessi := nvl(w_imp_versato,0);
                  END IF;
                  w_imp_dovuta_mini := w_imp_dovuta_mini - w_imp_base_interessi; 
                  w_imp_versato     := w_imp_versato - w_imp_base_interessi;
               else
                  if rec_vers.tipo_versamento = 'U' then
                     w_ind := w_ind + 1;
                     t_tipo_vers (w_ind) := rec_vers.tipo_versamento;
                     t_data_vers (w_ind) := rec_vers.data_pagamento;
                     t_imp_vers (w_ind)  := w_imp_versato;
                     w_imp_versato       := 0;
                  end if;
               end if;
            end if;
         end if;
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo mini 2: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo mini 2: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo mini 2: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo mini 2: '||w_imp_dovuta_saldo);
         --
         if w_imp_versato > 0 then   
            w_ind := w_ind + 1;
            t_tipo_vers (w_ind) := rec_vers.tipo_versamento;
            t_data_vers (w_ind) := rec_vers.data_pagamento;
            t_imp_vers (w_ind)  := w_imp_versato;
         end if;
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Elemento '||w_ind||': Data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')||', Importo: '||w_imp_versato);
      END LOOP;
      --
      -- Si scorre l'array degli eventuali versamenti tardivi/in eccesso e si
      -- emettono le relative sanzioni
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
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo acconto 2: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo acconto 2: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo acconto 2: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo acconto 2: '||w_imp_dovuta_saldo);
         -- Trattamento versamenti a saldo
         if w_imp_versato > 0 then
            if a_data_scad_saldo is not null 
            AND nvl(w_imp_dovuta_saldo,0) > 0 THEN
               TARDIVO_SALDO;
            end if;
         end if;
         --
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo saldo 2: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo saldo 2: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo saldo 2: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo saldo 2: '||w_imp_dovuta_saldo);      
         --
         -- Trattamento eventuale mini IMU residua
         --
         IF nvl(w_imp_versato,0) > 0 then
            if a_data_scad_mini is not null 
            AND nvl(w_imp_dovuta_mini,0) > 0 THEN
               IF nvl(w_imp_dovuta_mini,0) < nvl(w_imp_versato,0) THEN
                  w_imp_base_interessi := nvl(w_imp_dovuta_mini,0);
               ELSE
                  w_imp_base_interessi := nvl(w_imp_versato,0);
               END IF;
               w_imp_dovuta_mini  := w_imp_dovuta_mini - w_imp_base_interessi; 
               w_imp_versato      := w_imp_versato - w_imp_base_interessi;
               --
               IF w_data_vers > a_data_scad_mini 
               AND nvl(w_imp_base_interessi,0) != 0 THEN
                  inserimento_interessi(a_pratica,NULL,a_data_scad_mini,w_data_vers,w_imp_base_interessi,C_TIPO_TRIBUTO,'M',a_utente,a_data_scad_mini);
                  w_gg_diff := w_data_vers - a_data_scad_mini;
                  --
                  -- (VD - 08/07/2016) - Modifiche per nuovo sanzionamento 2016 
                  --
                  IF w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') THEN
                     IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 504 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_15;
                        inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_mini);
                     ELSIF
                        w_gg_diff <= w_gg_ritardo_2 THEN            -- ANOMALIA 505 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_90;
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     ELSE
                        w_cod_sanzione := C_TARD_VERS_MINI_SUP_90;  -- ANOMALIA 506 
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     END IF;
                  ELSE
                     IF w_gg_diff <= w_gg_ritardo_1 THEN            -- ANOMALIA 504 
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_15;
                        inserimento_sanzione_ici_gg(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,w_gg_diff,a_utente,a_data_scad_mini);
                     ELSE
                        w_cod_sanzione := C_TARD_VERS_MINI_INF_90;  -- ANOMALIA 505 
                        inserimento_sanzione_ici(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,w_imp_base_interessi,a_utente,a_data_scad_mini);
                     END IF;
                  END IF;
               END IF;  -- fine if se imp. base int. > 0 
            end if;
         END IF;
         --dbms_output.put_line('------------------------------------------------');
         --dbms_output.put_line('Imp.versato dopo mini 3: '||w_imp_versato);
         --dbms_output.put_line('Imp.mini dopo mini 3: '||w_imp_dovuta_mini);
         --dbms_output.put_line('Imp.acconto dopo mini 3: '||w_imp_dovuta_acconto);
         --dbms_output.put_line('Imp.saldo dopo mini 3: '||w_imp_dovuta_saldo);
       end loop;
     end if;
   end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,'LIQUIDAZIONI_ICI_SANZ_VERS_711: '||sqlerrm);
END;
/* End Procedure: LIQUIDAZIONI_ICI_SANZ_VERS_711 */
/
