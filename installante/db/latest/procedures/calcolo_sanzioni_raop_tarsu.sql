--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_raop_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_RAOP_TARSU
/******************************************************************************
  NOME:        CALCOLO_SANZIONI_RAOP_TARSU
  DESCRIZIONE: Calcola sanzioni ravvedimento operoso TARSU
  REVISIONI:
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  005   10/02/2025  DM      #75091
                            Reipristino storicizzazione sanzioni
  006   06/02/2025  RV      #71533
                            Gestione componenti perequative
  005   07/11/2024  DM      #75091
                            Storicizzazione sanzioni
  004   10/06/2024  RV      #72024
                            Aggiunto gestione scadenza_rata_unica
  003   12/03/2024  RV      #55403
                            Agginto gestione ravvedimento su ruoli (a_flag_infrazione = 'R')
  002   28/02/2023  AB      Issue #62651
                            Aggiunta la eliminazione sanzioni per deceduti
  001   20/12/2004          Prima emissione
  ----  ----------  ------  ----------------------------------------------------
  Nota : Per motivi storici TARSU usa quattro parametri (Compatibilità TR4), gli altri tributi cinque
         Un di sarebbe da standardizzare modificando qui e su TR4Web
******************************************************************************/
(a_pratica            IN number
,a_data_pagam         IN date
,a_utente             IN varchar2
,a_flag_infrazione    IN varchar2
) is
--
C_TIPO_TRIBUTO           CONSTANT varchar2(5) := 'TARSU';
--
type t_scadenza_t        is table of date   index by binary_integer;
type t_versato_t         is table of number index by binary_integer;
type t_versato_tardivo_t is table of number index by binary_integer;
type t_tot_imposta_t     is table of number index by binary_integer;
type t_tot_tardivo_2_t   is table of number index by binary_integer;
type t_tot_tardivo_5_t   is table of number index by binary_integer;
type t_tot_tardivo_6_t   is table of number index by binary_integer;
type t_tot_tardivo_8_t   is table of number index by binary_integer;
type t_tot_tardivo_10_t  is table of number index by binary_integer;
type t_tot_tardivo_12_t  is table of number index by binary_integer;
type t_tot_interessi_t   is table of number index by binary_integer;
--
type t_vers_t            is table of number index by binary_integer;
type t_scad_t            is table of date   index by binary_integer;
type t_rata_t            is table of number index by binary_integer;
--
type t_rata_num_t        is table of number index by binary_integer;    -- Numro della rata del parziale
--
type t_tot_tares_t       is table of number index by binary_integer;
--
type t_tot_tefa_t        is table of number index by binary_integer;
type t_versato_tefa_t    is table of number index by binary_integer;
type t_tot_inter_tefa_t  is table of number index by binary_integer;
--
w_errore                 varchar2(2000);
w_check                  number(1);
errore                   exception;
fine                     exception;
--
w_comune                 varchar2(6);
w_delta_anni             number;
w_delta_rate             number;
w_anno                   number;
w_anno_scadenza          number;
w_data_pratica           date;
w_cod_fiscale            varchar2(16);
w_add_eca                number;
w_mag_eca                number;
w_add_pro                number;
w_aliquota               number;
w_conta                  number;
w_imposta                number;
w_flag_sanz              varchar2(1);
w_flag_int               varchar2(1);
w_flag_netto             varchar2(1);
w_versato                number;
w_scadenza               date;
w_scad                   date;
w_interessi              number;
w_ind                    number;
w_ind_max                number;
w_ind_ruoli_base         number;
w_ind_ruoli_max          number;
w_diff_giorni_present    number;
w_diff_giorni            number;
w_giorni_anno            number;
w_giorni_int             number;
w_giorni                 number;
w_data_presentazione     date;
w_cod_sanzione           number;
w_rid                    number;
w_percentuale            number;
w_riduzione              number;
w_riduzione_2            number;
w_sanzione               number;
w_sequenza_sanz          number;
w_num_ruoli              number;
w_num_ruoli_v            number;
w_ruolo                  number;
w_tot_versato            number;
w_tot_omesso             number;
w_tot_imposta            number;
w_tot_tardivo_2          number;
w_tot_tardivo_5          number;
w_tot_tardivo_6          number;
w_tot_tardivo_8          number;
w_tot_tardivo_10         number;
w_tot_tardivo_12         number;
w_tot_interessi          number;
w_num_vers               number;
w_lordo                  number;
w_netto                  number;
w_lordo_tefa             number;
w_stato_sogg             number(2);
--
w_flag_accorpa_rate      varchar2(1);       -- 'S' forza l'accorpamento in una unica rata
                                            -- Per ravvedimento su ruoli multipli o tipo_ravvedimento = 'V'
--
w_tot_imposta_note       varchar2(2000);
w_note                   varchar2(2000);
--
-- Campi per gestione maggiorazione TARES - Componenti perequative
--
w_magg_tares             number;
w_tot_tares              number;
--
w_cod_sanz_tares         number;
--
w_tot_tares_note         varchar2(2000);
w_note_tares             varchar2(2000);
--
-- Campi per gestione separata TEFA, al momento non in uso
--
w_tefa                   number;
w_versato_tefa           number;
w_inter_tefa             number;
--
w_tot_tefa               number;
w_tot_inter_tefa         number;
--
-- Matrice importi rate : 0 : non usato, 1 - 6 : rate (6 ?), 7 - 9 : non usati, 10+ : Parziali su ruoli
--
t_versato                t_versato_t;
t_versato_tardivo        t_versato_tardivo_t;
t_tot_imposta            t_tot_imposta_t;
t_tot_tardivo_2          t_tot_tardivo_2_t;
t_tot_tardivo_5          t_tot_tardivo_5_t;
t_tot_tardivo_6          t_tot_tardivo_6_t;
t_tot_tardivo_8          t_tot_tardivo_8_t;
t_tot_tardivo_10         t_tot_tardivo_10_t;
t_tot_tardivo_12         t_tot_tardivo_12_t;
t_scadenza               t_scadenza_t;
t_tot_interessi          t_tot_interessi_t;
--
t_vers                   t_vers_t;
t_scad                   t_scad_t;
t_rata                   t_rata_t;
--
t_rata_num               t_rata_num_t;
--
t_tot_tares              t_tot_tares_t;
--
t_tot_tefa               t_tot_tefa_t;
t_versato_tefa           t_versato_tefa_t;
t_tot_inter_tefa         t_tot_inter_tefa_t;
--
-- Indici di matrice
--
bind1                    binary_integer;
bind2                    binary_integer;
--
-- Cursore ricerca versamenti
--
cursor sel_vers(a_cod_fiscale varchar2,
                a_anno number,
                a_data_pagamento date)
is
  select nvl(vers.rata,0) rata
        ,nvl(sum(vers.importo_versato),0) importo_versato
        ,vers.data_pagamento
        ,0 delta_rate --f_delta_rate(vers.ruolo) delta_rate
    from versamenti vers
  --      ,scadenze   scad
   where vers.cod_fiscale        = a_cod_fiscale
     and vers.anno               = a_anno
     and vers.tipo_tributo       = C_TIPO_TRIBUTO
     and vers.pratica           is null
  --   and scad.anno               = a_anno
  --   and scad.tipo_tributo       = 'TARSU'
  --   and scad.data_scadenza     <= a_data_pagamento
  --   and scad.rata               = nvl(vers.rata,0) -- + zz_f_delta_rate(vers.ruolo)
   group by
         nvl(vers.rata,0)
        ,vers.data_pagamento
      --  ,zz_f_delta_rate(vers.ruolo)
   order by
         nvl(vers.rata,0)
        ,vers.data_pagamento
      --  ,zz_f_delta_rate(vers.ruolo)
;
--
-- Cursore ricerca debiti per Ravvedimenti su Versamenti
--
cursor sel_debiti(a_pratica number)
is
  select
      rvdd.ruolo,
      rvdd.rata,
      rvdd.scadenza,
      rvdd.data_interessi,
      rvdd.imposta,
      rvdd.versato_imp,
      rvdd.debito_imp,
      rvdd.tefa,
      rvdd.versato_tefa,
      rvdd.magg_tares,
      rvdd.debito_tefa,
      round((nvl(rvdd.magg_tares,0) * nvl(rvdd.debito_imp,0) / nvl(rvdd.imposta,1)),2) as debito_magg_tares
  from (
    select
      rvdb.ruolo,
      rvdb.rata,
      rvdb.scadenza,
      case when rvdb.scadenza is not null then
        greatest(nvl(ruol.scadenza_rata_unica,rvdb.scadenza),rvdb.scadenza)
      else
        null
      end as data_interessi,
      rvdb.imposta,
      rvdb.versato_imposta as versato_imp,
      nvl(rvdb.imposta,0) - nvl(rvdb.versato_imposta,0) as debito_imp,
      rvdb.tefa,
      rvdb.versato_tefa,
      rvdb.magg_tares,
      nvl(rvdb.tefa,0) - nvl(rvdb.versato_tefa,0) as debito_tefa
    from
      ruoli ruol,
      (
      select
        dbrv.ruolo, 1 as rata, dbrv.scadenza_prima_rata as scadenza,
        dbrv.importo_prima_rata as imposta, dbrv.versato_prima_rata as versato_imposta,
        0 as tefa,
        0 as versato_tefa,
        dbrv.maggiorazione_tares_prima_rata as magg_tares
         from debiti_ravvedimento dbrv
        where dbrv.pratica = a_pratica
      union
      select
        dbrv.ruolo, 2 as rata, dbrv.scadenza_rata_2 as scadenza,
        dbrv.importo_rata_2 as imposta, dbrv.versato_rata_2 as versato_imposta,
        0 as tefa,
        0 as versato_tefa,
        dbrv.maggiorazione_tares_rata_2 as magg_tares
         from debiti_ravvedimento dbrv
        where dbrv.pratica = a_pratica
      union
      select
        dbrv.ruolo, 3 as rata, dbrv.scadenza_rata_3 as scadenza,
        dbrv.importo_rata_3 as imposta, dbrv.versato_rata_3 as versato_imposta,
        0 as tefa,
        0 as versato_tefa,
        dbrv.maggiorazione_tares_rata_3 as magg_tares
         from debiti_ravvedimento dbrv
        where dbrv.pratica = a_pratica
      union
      select
        dbrv.ruolo, 4 as rata, dbrv.scadenza_rata_4 as scadenza,
        dbrv.importo_rata_4 as imposta, dbrv.versato_rata_4 as versato_imposta,
        0 as tefa,
        0 as versato_tefa,
        dbrv.maggiorazione_tares_rata_4 as magg_tares
         from debiti_ravvedimento dbrv
        where dbrv.pratica = a_pratica
      ) rvdb
    where
      rvdb.ruolo = ruol.ruolo(+) and
      rvdb.scadenza is not null and
      rvdb.versato_imposta is not null
    ) rvdd
  order by
    rvdd.ruolo,
    rvdd.rata
;
--
-- Funzione per Data di Scadenza
--
FUNCTION F_DATA_SCAD
(a_anno          IN     number
,a_rata          IN     number
,a_tipo_scad     IN     varchar2
,a_data_scadenza IN OUT date
) Return string
is
  --
  w_err                   varchar2(2000);
  w_data                  date;
  --
BEGIN
   -- Da utilizzare solo per la scadenza di presentazione (D)
   w_err := null;
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_scadenza   = a_tipo_scad
         and scad.tipo_tributo    = 'TARSU'
         and scad.anno            = a_anno
         and nvl(scad.rata,0)     = nvl(a_rata,0)
      ;
      a_data_scadenza := w_data;
      Return w_err;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         if a_tipo_scad = 'V' then
            w_err := 'Scadenza di Versamento per Rata '||to_char(nvl(a_rata,0))||' anno '||to_char(a_anno)||
                     ' Non Prevista.';
         else
            w_err := 'Scadenza di Presentazione per anno '||to_char(a_anno)||' Non Prevista.';
         end if;
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
END F_DATA_SCAD;
--
-- Funzione per il recupero della sequenza della sanzione
--
FUNCTION F_SEQUENZA_SANZIONE
(a_cod_sanzione      IN     number
,a_data_scadenza     IN     date
,a_sequenza          IN OUT number
) Return string
is
  w_err                varchar2(2000);
BEGIN
   w_err := null;
   BEGIN
      select sanz.sequenza
        into a_sequenza
        from sanzioni sanz
       where sanz.tipo_tributo = 'TARSU'
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista in data ' || to_char(a_data_scadenza,'DD/MM/YYYY');
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   return w_err;
END F_SEQUENZA_SANZIONE;
--
-- Funzione per Calcolo Sanzione - Normale
--
FUNCTION F_IMP_SANZ
(a_cod_sanzione      IN     number
,a_importo           IN     number
,a_rid               IN     number
,a_data_scadenza     IN     date
,a_percentuale       IN OUT number
,a_riduzione         IN OUT number
,a_riduzione_2       IN OUT number
,a_sanzione          IN OUT number
,a_sequenza          IN OUT number
) Return string
is
  --
  w_err                varchar2(2000);
  --
  w_impo_sanz          number;
  w_sanzione           number;
  w_sanzione_minima    number;
  --
BEGIN
   w_err := null;
   BEGIN
      select sanz.sanzione_minima
            ,sanz.sanzione
            ,round(sanz.percentuale / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
            ,sanz.sequenza
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
            ,a_sequenza
        from sanzioni sanz
       where sanz.tipo_tributo = 'TARSU'
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista.';
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   w_impo_sanz := a_importo * nvl(a_percentuale,0) / 100;
   if nvl(w_sanzione_minima,0) > w_impo_sanz then
      w_impo_sanz := w_sanzione_minima;
   end if;
   a_sanzione := w_impo_sanz;
   Return w_err;
END F_IMP_SANZ;
--
-- Funzione per Calcolo Sanzione - Giornaliera
--
FUNCTION F_IMP_SANZ_GG
(a_cod_sanzione      IN     number
,a_importo           IN     number
,a_rid               IN     number
,a_diff_gg           in     number
,a_data_scadenza     in     date
,a_percentuale       IN OUT number
,a_riduzione         IN OUT number
,a_riduzione_2       IN OUT number
,a_sanzione          IN OUT number
,a_sequenza          IN OUT number
) Return string
is
  --
  w_err                varchar2(2000);
  --
  w_impo_sanz          number;
  w_sanzione           number;
  w_sanzione_minima    number;
  --
BEGIN
   w_err := null;
   BEGIN
      select sanz.sanzione_minima
            ,sanz.sanzione
            ,round(sanz.percentuale * a_diff_gg / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
            ,sanz.sequenza
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
            ,a_sequenza
        from sanzioni sanz
       where sanz.tipo_tributo = 'TARSU'
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine
      ;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista.';
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   w_impo_sanz := a_importo * nvl(a_percentuale,0) / 100;
   if nvl(w_sanzione_minima,0) > w_impo_sanz then
      w_impo_sanz := w_sanzione_minima;
   end if;
   a_sanzione := w_impo_sanz;
   Return w_err;
END F_IMP_SANZ_GG;
--
-- Verifica presenza sanzione
--
function F_CHECK_SANZIONE_RAVV
(a_pratica        number,
 a_cod_sanzione   number,
 a_sequenza       number,
 a_percentuale    number
)
RETURN number
IS
   w_return number;
BEGIN
   BEGIN
  select count(1)
    into w_return
    from sanzioni_pratica
   where pratica    = a_pratica
     and cod_sanzione = a_cod_sanzione
     and sequenza = a_sequenza
     and percentuale = a_percentuale
  ;
  EXCEPTION
     WHEN others THEN
         w_return := -1;
  END;
  RETURN w_return;
END F_CHECK_SANZIONE_RAVV;
--
-- Aggiunge/Aggiorna sanzione ravvedimento
--
procedure AGGIORNAMENTO_SANZIONE_RAVV
(a_pratica         number,
 a_cod_sanzione    number,
 a_importo         number,
 a_giorni          number,
 a_percentuale     number,
 a_riduzione       number,
 a_riduzione_2     number,
 a_note            varchar2,
 a_utente          varchar2,
 a_sequenza_sanz   number
)
IS
--
errore             exception;
w_errore           varchar2(200);
--
w_check            number;
--
w_percentuale      number;
--
BEGIN
 if  round(a_importo,2) <> 0 then
  w_percentuale := round(a_percentuale,2);
  w_check := f_check_sanzione_ravv(a_pratica,a_cod_sanzione,a_sequenza_sanz,w_percentuale);
  if w_check = 0 then
     BEGIN
          insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo
               ,percentuale,importo,riduzione,riduzione_2
               ,utente,data_variazione,giorni,note,sequenza_sanz
               )
          values(a_pratica,a_cod_sanzione,C_TIPO_TRIBUTO
               ,w_percentuale,a_importo,a_riduzione,a_riduzione_2
               ,a_utente,trunc(sysdate),a_giorni,a_note,a_sequenza_sanz
               )
          ;
      EXCEPTION
    WHEN others THEN
           w_errore := 'Errore inserendo Sanzione '||a_cod_sanzione||' su Pratica '||a_pratica;
       RAISE errore;
     END;
  else
     BEGIN
      update sanzioni_pratica
           set importo      = importo + round(a_importo,2)
    -- Aggiorniamo il valore di 'giorni' come richiesto dai Servizi
    -- (RV) 2024/03/08 : contrordine, per i ravvedimenti non serve
    --     , giorni         = case when nvl(giorni,0) > a_giorni then nvl(giorni,0) else a_giorni end
           , giorni         = null
           , note           = note||w_note
         where pratica      = a_pratica
           and cod_sanzione = a_cod_sanzione
           and sequenza_sanz = a_sequenza_sanz
           and percentuale = w_percentuale
        ;
      EXCEPTION
    WHEN others THEN
           w_errore := 'Errore aggiornamento Sanzione '||a_cod_sanzione||' di Pratica '||a_pratica;
       RAISE errore;
     END;
  end if;
 end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END AGGIORNAMENTO_SANZIONE_RAVV;
--
-- ======================================= --
-- R A V V E D I M E N T O   O P E R O S O --
-- ======================================= --
--
BEGIN
  w_errore := null;
  --
  w_tot_imposta_note := '';
  w_tot_tares_note := '';
  --
--
-- Si memorizza il codice del comune per eventuali personalizzazioni.
--
  BEGIN
    select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
      into w_comune
      from dati_generali
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       w_errore := 'Dati generali Non presenti';
       RAISE ERRORE;
  END;
  --
  BEGIN
    select prtr.data
          ,prtr.anno
          ,prtr.cod_fiscale
      into w_data_pratica
          ,w_anno
          ,w_cod_fiscale
      from pratiche_tributo prtr
     where prtr.pratica = a_pratica
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       w_errore := 'Pratica '||to_char(a_pratica)||' Assente';
       RAISE ERRORE;
  END;
  --
  if w_anno < 1998 then
    w_errore := 'Gestione Non Prevista per Anni col Vecchio Sanzionamento';
    RAISE ERRORE;
  end if;
  --
  BEGIN
    select nvl(cata.addizionale_eca,0)
          ,nvl(cata.maggiorazione_eca,0)
          ,nvl(cata.addizionale_pro,0)
          ,nvl(cata.aliquota,0)
          ,nvl(cata.flag_sanzione_add_p,'N')
          ,nvl(cata.flag_interessi_add,'N')
      into w_add_eca
          ,w_mag_eca
          ,w_add_pro
          ,w_aliquota
          ,w_flag_sanz
          ,w_flag_int
      from carichi_tarsu cata
     where cata.anno = w_anno
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       w_errore := 'Carichi TARSU Non Previsti per anno '||to_char(w_anno);
  END;
  --
  w_delta_anni := 0;
--
-- Per Lumezzane esiste un correttivo di 1 anno
--
  if w_comune = '017096' then
    w_delta_anni := 1;
  end if;
--
-- Seve a gestire gli squilibri tra netto ed addizionali.
-- Si presuppone l'imposta già netta, con la addizionale prov o tefa
-- esposta da contabilizzare a parte.
-- 2024/02/15 (RV) : Da non usare, lavoriamo solo sul lordo
--
-- if a_flag_infrazione = 'R' then
      w_flag_netto := 'N';
--  else
--    w_flag_netto := 'N';
-- end if;
--
-- Si verifica che non esistano altri ravvedimenti nello stesso anno
--
   if a_flag_infrazione <> 'R' then
     BEGIN
        select count(*)
          into w_conta
          from sanzioni_pratica    sapr
              ,pratiche_tributo    prtr
         where sapr.pratica           = prtr.pratica
           and prtr.cod_fiscale       = w_cod_fiscale
           and prtr.anno              = w_anno
           and prtr.tipo_tributo||''  = 'TARSU'
           and nvl(prtr.stato_accertamento,'D')
                                      = 'D'
           and prtr.tipo_pratica      = 'V'
           and prtr.pratica          <> a_pratica
        ;
     END;
     if w_conta > 0 then
        w_errore := 'Esistono altre pratiche di ravvedimento';
        RAISE ERRORE;
     end if;
  end if;
  --
  -- Verifica delle scadenze
  --
  if a_flag_infrazione = 'R' then
    --
-- Serve verificare data ravvedimento ?
    --
--    pratica.dataRiferimentoRavvedimento
    w_data_presentazione := to_date('0101'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy');
  else
    --
    -- Se esiste una denuncia di variazione effettuata dopo la scadenza
    -- di presentazione della denuncia, la data di presentazione
    -- del ravvedimento slitta alla data di presentazione del successivo
    -- anno.
    --
    w_errore := F_DATA_SCAD(w_anno + w_delta_anni,null,'D',w_data_presentazione);
    if w_errore is not null then
      RAISE ERRORE;
    end if;
    --
    BEGIN
      select count(*)
        into w_conta
        from pratiche_tributo prtr
       where prtr.tipo_tributo        = 'TARSU'
         and prtr.cod_fiscale         = w_cod_fiscale
         and prtr.anno                = w_anno
         and prtr.tipo_pratica       in ('D','A')
         and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                      = 'S'
         and nvl(prtr.stato_accertamento,'D')
                                      = 'D'
         and prtr.data                > w_data_presentazione
      ;
    END;
    --
    if w_conta > 0 then
      w_errore := F_DATA_SCAD(w_anno + w_delta_anni + 1,null,'D',w_data_presentazione);
      if w_errore is not null then
         RAISE ERRORE;
      end if;
    end if;
    --
    if a_data_pagam > w_data_presentazione then
      w_errore := 'La data di Pagamento '||to_char(a_data_pagam,'dd/mm/yyyy')||' e` > della scadenza '||
                  to_char(w_data_presentazione,'dd/mm/yyyy')||' per ravvedersi';
      RAISE ERRORE;
    end if;
  end if;
  --
  BEGIN
    select to_date('0101'||lpad(to_char(w_anno + 1),4,'0'),'ddmmyyyy') -
           to_date('0101'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
          ,a_data_pagam - w_data_presentazione
      into w_giorni_anno
          ,w_diff_giorni_present
      from dual
    ;
  END;
  --
  w_giorni_int := 0;
  w_num_ruoli_v := 0;
  if a_flag_infrazione = 'R' then
    --
    -- I Ravvedimenti 'R' non hanno opggetti, contro i ruoli in debiti_ravvedimento
    --
    BEGIN
      select 1
           , max(derv.ruolo)
           , count(derv.ruolo)
        into w_num_ruoli
           , w_ruolo
           , w_num_ruoli_v
        from debiti_ravvedimento derv
       where derv.pratica         = a_pratica
      ;
    END;
    w_flag_accorpa_rate := 'S';
  else
    --
    -- Viene determinato se tutti gli oggetti del ravvedimento
    -- sono riferiti allo stesso ruolo.
    --
    BEGIN
      select count(distinct nvl(substr(ogim.note,1,10),0))
           , max(to_number(substr(ogim.note,1,10)))
        into w_num_ruoli
           , w_ruolo
        from oggetti_imposta ogim
           , oggetti_pratica ogpr
       where ogim.oggetto_pratica = ogpr.oggetto_pratica
         and ogpr.pratica         = a_pratica
      ;
    END;
    if (w_num_ruoli > 1) then
      w_flag_accorpa_rate := 'S';
    else
      w_flag_accorpa_rate := null;
    end if;
  end if;
  --
--dbms_output.put_line('Calcolo sanzioni Ravvedimento: '||a_pratica||', tipo: '||a_flag_infrazione||
--                                                         ', ruoli: '||w_num_ruoli||', ultimo: '||w_ruolo);
  --
--
-- Pulizia Sanzioni Precedenti
--
  BEGIN
    delete from sanzioni_pratica sapr
     where sapr.pratica = a_pratica
    ;
  END;
--
-- Memorizzazione del Versato con relativa Data di Pagamento e Rata
--
  w_tot_versato := 0;
  w_num_vers := 0;
  --
  if a_flag_infrazione <> 'R' then
    bInd1 := 0;
    FOR rec_vers in sel_vers(w_cod_fiscale,w_anno,a_data_pagam)
    LOOP
      bInd1 := bInd1 + 1;
      t_vers(bInd1)     := rec_vers.importo_versato;
      t_scad(bInd1)     := rec_vers.data_pagamento;
      if rec_vers.rata = 0 then
         t_rata(bInd1)  := 1 + rec_vers.delta_rate;
      else
         t_rata(bInd1)  := rec_vers.rata + rec_vers.delta_rate;
      end if;
      w_tot_versato     := w_tot_versato + rec_vers.importo_versato;
    END LOOP;
    w_num_vers := bInd1;
  end if;
--
-- Determinazione della Imposta Lorda e della Scadenza
--
  w_ind := 0;
  w_tot_omesso := 0;
  --
  if a_flag_infrazione = 'R' then
    --
    -- Totali da debiti_ravvedimento
    --
    w_ind_ruoli_base := 10;
    w_ind_ruoli_max := w_ind_ruoli_base;
    --
    w_ind_max := w_ind_ruoli_base;
    --
    bInd1 := 0;
    loop
      bInd1 := bInd1 + 1;
      if bInd1 > w_ind_max then
         exit;
      end if;
      --
      t_scadenza(bInd1)            := null;
      t_tot_imposta(bInd1)         := 0;
      t_tot_tefa(bInd1)            := 0;
      t_tot_tares(bInd1)           := 0;
      t_versato(bInd1)             := 0;
      t_versato_tefa(bInd1)        := 0;
      t_versato_tardivo(bInd1)     := 0;
      t_tot_interessi(bInd1)       := 0;
      t_tot_inter_tefa(bInd1)      := 0;
      t_tot_tardivo_2(bInd1)       := 0;
      t_tot_tardivo_5(bInd1)       := 0;
      t_tot_tardivo_6(bInd1)       := 0;
      t_tot_tardivo_8(bInd1)       := 0;
      t_tot_tardivo_10(bInd1)      := 0;
      t_tot_tardivo_12(bInd1)      := 0;
      t_rata_num(bInd1)            := 0;
    end loop;
    --
    -- Totali da debiti_ravvedimento
    --
    bInd1 := w_ind_ruoli_base;
    begin
      for rec_dbrv in sel_debiti(a_pratica)
      loop
      --dbms_output.put_line('Ruolo: '||rec_dbrv.ruolo||', Rata: '||rec_dbrv.rata||
      --                    ', Scadenza: '||to_char(rec_dbrv.scadenza,'YYYY/mm/dd')||
      --                    ', Interessi dal: '||to_char(rec_dbrv.data_interessi,'YYYY/mm/dd'));
      --dbms_output.put_line(' Imposta: '||rec_dbrv.imposta||', versato: '||rec_dbrv.versato_imp||', dovuto: '||rec_dbrv.debito_imp);
      --dbms_output.put_line(' TEFA: '||rec_dbrv.tefa||', versato: '||rec_dbrv.versato_tefa||', dovuto: '||rec_dbrv.debito_tefa);
      --dbms_output.put_line(' Quota Perequative: '||rec_dbrv.magg_tares||', dovuto: '||rec_dbrv.debito_magg_tares);
        --
        t_rata_num(bInd1)            := rec_dbrv.rata;
        --
        t_tot_imposta(bInd1)         := rec_dbrv.debito_imp;
        t_versato(bInd1)             := rec_dbrv.versato_imp;
        t_tot_tefa(bInd1)            := rec_dbrv.debito_tefa;
        t_versato_tefa(bInd1)        := rec_dbrv.versato_tefa;
        t_tot_tares(bInd1)           := rec_dbrv.debito_magg_tares;
        t_scadenza(bInd1)            := rec_dbrv.data_interessi;
        --
        t_tot_interessi(bInd1)       := 0;
        t_tot_inter_tefa(bInd1)      := 0;
        --
        t_versato_tardivo(bInd1)     := 0;
        t_tot_tardivo_2(bInd1)       := 0;
        t_tot_tardivo_5(bInd1)       := 0;
        t_tot_tardivo_6(bInd1)       := 0;
        t_tot_tardivo_8(bInd1)       := 0;
        t_tot_tardivo_10(bInd1)      := 0;
        t_tot_tardivo_12(bInd1)      := 0;
        --
        w_tot_omesso := w_tot_omesso + t_tot_imposta(bInd1);
        --
        w_magg_tares := rec_dbrv.debito_magg_tares;
        w_netto := rec_dbrv.debito_imp - w_magg_tares;
        --
        if w_netto != 0 then
          w_note := 'Dovuto: '||to_char(round(w_netto,2),'99G999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.''')||
                    ' al: '||to_char(rec_dbrv.scadenza,'dd/mm/yyyy')||' - ';
          w_tot_imposta_note := substr(concat(w_tot_imposta_note,w_note),1,2000);
        end if;
        if w_magg_tares != 0 then
          w_note := 'Dovuto: '||to_char(round(w_magg_tares,2),'99G999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.''')||
                    ' al: '||to_char(rec_dbrv.scadenza,'dd/mm/yyyy')||' - ';
          w_tot_tares_note := substr(concat(w_tot_tares_note,w_note),1,2000);
        end if;
        --
        bInd1 := bInd1 + 1;
        --
        w_ind_ruoli_max := w_ind_ruoli_max + 1;
      end loop;
    exception
      when NO_DATA_FOUND then
        w_errore := 'Dati dei Debiti non trovati per pratica: '||a_pratica;
        raise errore;
      when OTHERS THEN
        w_errore := 'Errore ricavando dati Debiti per pratica '||a_pratica||': '||to_char(SQLCODE)||' - '||SQLERRM;
        raise errore;
    end;
    w_ind_max := w_ind_ruoli_max - 1;
  else
    --
    -- Totali da oggetti imposta
    --
    w_ind_max := 6;      -- Max cinque rate ??
    --
    LOOP
      w_ind := w_Ind + 1;
      if w_ind > w_ind_max then
         exit;
      end if;
      --
      -- In OGIM nelle note sono memorizzati: il ruolo nei primi 10 caratteri,
      -- il numero delle rate scadute alla data di emissione del ruolo di 1 carattere,
      -- il numero di rate di 1 carattere (0 se non rateizzato) e 4 elementi di
      -- 75 caratteri da intendersi come 5 importi che contengono la imposta netta,
      -- la addizionale ECA, la maggiorazione ECA, la addizionale PRO, la aliquota;
      -- questi importi sono a zero se non significativi. La imposta viene totalizzata
      -- secondo la rata effettiva di scadenza e non rispettivamente al numero di rata
      -- memorizzato. La non rateizzazione (rata 0) viene accorpata nella prima rata.
      -- La scadenza della prima rata viene ricavata tra la scadenza minore tra rata 0
      -- e rata 1 (a onor del vero entrambe dovrebbero essere uguali).
      --
      BEGIN
         select min( decode(w_ind
                               ,1,ruol.scadenza_prima_rata
                               ,2,ruol.scadenza_rata_2
                               ,3,ruol.scadenza_rata_3
                               ,4,ruol.scadenza_rata_4
                               )
                    )
           into w_scadenza
           from ruoli ruol
              , oggetti_imposta ogim
              , oggetti_pratica ogpr
          where ogim.oggetto_pratica = ogpr.oggetto_pratica
            and ogpr.pratica         = a_pratica
            and ruol.ruolo           = to_number(substr(ogim.note,1,10))
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_scadenza        := to_date('31122999','ddmmyyyy');
      END;
      --
      if w_scadenza < a_data_pagam then
         BEGIN
            select nvl(sum(to_number(substr(ogim.note
                                           ,(w_ind - 1) * 75 + 13
                                           ,15
                                           )
                                    ) / 100 +
                           to_number(substr(ogim.note
                                           ,(w_ind - 1) * 75 + 28
                                           ,15
                                           )
                                    ) / 100 +
                           to_number(substr(ogim.note
                                           ,(w_ind - 1) * 75 + 43
                                           ,15
                                           )
                                    ) / 100 +
                           to_number(substr(ogim.note
                                           ,(w_ind - 1) * 75 + 58
                                           ,15
                                           )
                                    ) / 100 +
                           to_number(substr(ogim.note
                                           ,(w_ind - 1) * 75 + 73
                                           ,15
                                           )
                                    ) / 100
                          ),0
                      )
              into w_imposta
              from oggetti_imposta ogim
                  ,oggetti_pratica ogpr
             where ogim.oggetto_pratica = ogpr.oggetto_pratica
               and ogpr.pratica         = a_pratica
               and w_ind          between 1
                                      and
                   to_number(substr(ogim.note,12,1)) +
                   decode(to_number(substr(ogim.note,12,1)),0,1,0)
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_imposta         := 0;
         END;
      else
         w_imposta := 0;
      end if;
      --
      bInd1                        := w_ind;
      t_scadenza(bInd1)            := w_scadenza;
      t_tot_imposta(bInd1)         := w_imposta;
      t_tot_tefa(bInd1)            := 0;
      t_tot_tares(bInd1)           := 0;
      t_versato(bInd1)             := 0;
      t_versato_tefa(bInd1)        := 0;
      t_versato_tardivo(bInd1)     := 0;
      t_tot_interessi(bInd1)       := 0;
      t_tot_inter_tefa(bInd1)      := 0;
      t_tot_tardivo_2(bInd1)       := 0;
      t_tot_tardivo_5(bInd1)       := 0;
      t_tot_tardivo_6(bInd1)       := 0;
      t_tot_tardivo_8(bInd1)       := 0;
      t_tot_tardivo_10(bInd1)      := 0;
      t_tot_tardivo_12(bInd1)      := 0;
      w_tot_omesso := w_tot_omesso + w_imposta;
    END LOOP;
  end if;
--
-- Calcola Sanzione
--
--dbms_output.put_line('Calcolo sanzioni');
  --
  if a_flag_infrazione = 'R' then
    --
    -- Tipo R, per rata
    --
    bInd1 := 0;
    LOOP
      bInd1 := bInd1 + 1;
      if bInd1 > w_ind_max then
         exit;
      end if;
      --
      w_imposta := t_tot_imposta(bInd1);
    --w_tefa := t_tot_tefa(bInd1);
      w_magg_tares := t_tot_tares(bInd1);
      --
    --dbms_output.put_line(' Elaboro debito: '||w_imposta||', di cui C.P.: '||w_magg_tares);
      --
      w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
      w_scadenza      := t_scadenza(bInd1);
      w_diff_giorni   := a_data_pagam - w_scadenza;
      --
      if w_diff_giorni > 0 then
        -- (VD - 05/02/2020): Ravvedimento operoso lungo
        if w_diff_giorni > 730 and
          a_data_pagam >= to_date('01012020','ddmmyyyy') then
          w_cod_sanzione := 166;
          w_rid := 6;
        elsif
          w_diff_giorni > 365 and
          a_data_pagam >= to_date('01012020','ddmmyyyy') then
          w_cod_sanzione := 165;
          w_rid := 7;
        elsif
         (w_diff_giorni > 90 and
          a_data_pagam >= to_date('01012015','ddmmyyyy')) or
         (w_diff_giorni > 30 and
          a_data_pagam < to_date('01012015','ddmmyyyy')) then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
          w_cod_sanzione := 155;
         else
          w_cod_sanzione := 152;
         end if;
         if w_anno > 1999 then
          if w_scadenza > to_date('31/01/2011','dd/mm/yyyy') then
             w_rid := 8;
          elsif a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
             w_rid := 10;
          else
             w_rid := 5;
          end if;
         else
          w_rid    := 6;
         end if;
        elsif w_diff_giorni > 30 then
         if  sign(2 - w_anno_scadenza + w_anno) < 1 then
          w_cod_sanzione := 155;
         else
          w_cod_sanzione := 152;
         end if;
         if w_anno > 1999 then
          if w_scadenza > to_date('31/01/2011','dd/mm/yyyy') then
             w_rid := 9;
          elsif a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
             w_rid := 10;
          else
             w_rid := 5;
          end if;
         else
          w_rid := 6;
         end if;
        else
         if w_data_pratica >= to_date('06072011','ddmmyyyy') then
          if w_diff_giorni <= 15 then
             w_cod_sanzione := 157;
             w_rid := 10;
          else
             w_cod_sanzione := 158;
             w_rid := 10;
          end if;
         else
          w_cod_sanzione := 151;
          if w_scadenza > to_date('31/01/2011','dd/mm/yyyy') then
             w_rid := 10;
          elsif a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
             w_rid := 12;
          else
             w_rid := 8;
          end if;
         end if;
        end if;
        --
        -- (VD - 18/01/2016): Se la pratica e' del 2016 e il versamento e'
        --                    stato effettuato entro 90 gg dalla scadenza,
        --                    la sanzione viene dimezzata (la riduzione
        --                    viene raddoppiata)
        if w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
          w_diff_giorni <= 90 then
          w_rid := w_rid * 2;
        end if;
        --
      --dbms_output.put_line('  Diff.Dovuto 1: '||w_imposta);
        if w_flag_netto = 'N' and w_flag_sanz = 'S' then
          -- Non serve scorporo addizionali, evitiamo ricalcoli ed eventuali arrotondamenti
          w_lordo := w_imposta;
        else
          -- Gestisce scorporo addizionali se richiesto
          if w_flag_netto = 'N' then
             w_netto := w_imposta - w_magg_tares;
             w_netto := f_trova_netto(w_netto,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
          else
             w_netto := w_imposta - w_magg_tares;
          end if ;
          w_lordo := w_netto;
        --dbms_output.put_line('  Diff.Dovuto 2: '||w_imposta||', Netto: '||w_netto);
          --
          if w_flag_sanz = 'S' then
             w_lordo   := w_lordo + round(w_netto * nvl(w_add_pro,0) / 100,2);
          end if;
          w_lordo := w_lordo + w_magg_tares;
        end if;
        --
      --dbms_output.put_line('  Diff.Dovuto 3: '||w_imposta||', Lordo: '||w_lordo);
        --
        if w_cod_sanzione = 157 then
           -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
           w_errore := F_IMP_SANZ_GG( w_cod_sanzione, w_lordo
                                     , w_rid, w_diff_giorni
                                     , w_scadenza
                                     , w_percentuale, w_riduzione
                                     , w_riduzione_2, w_sanzione, w_sequenza_sanz
                                     );
        else
           w_errore := F_IMP_SANZ( w_cod_sanzione, w_lordo
                                  , w_rid
                                  , w_scadenza
                                  , w_percentuale, w_riduzione
                                  , w_riduzione_2, w_sanzione, w_sequenza_sanz
                                  );
        end if;
        if w_errore is not null then
           w_errore := 'Errore in Calcolo Sanzione TARSU per Codice '||to_char(w_cod_sanzione);
           RAISE ERRORE;
        end if;
        w_note := 'In: '||to_char(round(w_sanzione,2),'99G999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.''')||
                  ' gg: '||to_char(w_diff_giorni)||
                  ' dal: '||to_char(w_scadenza,'dd/mm/yyyy')||
                  ' base: '||to_char(round(w_lordo,2),'99G999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.''')||
                  ' - ';
        --
        AGGIORNAMENTO_SANZIONE_RAVV(a_pratica,w_cod_sanzione,w_sanzione,w_diff_giorni,
                                    w_percentuale,w_riduzione,w_riduzione_2,w_note,a_utente,w_sequenza_sanz);
      end if;
    END LOOP;
  end if;
  --
  if a_flag_infrazione in ('O','I') then
    --
    -- Tipi I e O, sul totale evaso
    --
    if a_flag_infrazione = 'O' then
       w_cod_sanzione := 102;
    else
       w_cod_sanzione := 104;
    end if;
    if w_diff_giorni_present > 90 then
       if w_anno > 1999 then
          if a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
             w_rid := 10;
          else
             w_rid := 5;
          end if;
       else
          w_rid := 6;
       end if;
    else
       if a_data_pagam >= to_date('29/11/2008','dd/mm/yyyy') then
          w_rid := 12;
       else
          w_rid := 8;
       end if;
    end if;
    --
    w_imposta := w_tot_omesso;
    if w_flag_netto = 'N' then
       w_netto := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
    else
       w_netto := w_imposta;
    end if ;
    w_lordo := w_netto;
    if w_flag_sanz = 'S' then
       w_lordo := w_lordo + round(w_netto * nvl(w_add_pro,0) / 100,2);
    end if;
    --
    w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_rid, w_scadenza,
                            w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz
                           );
    if w_errore is not null then
       w_errore := 'Errore in Calcolo Sanzione TARSU per Codice '||to_char(w_cod_sanzione);
       RAISE ERRORE;
    end if;
    BEGIN
       insert into sanzioni_pratica
             (pratica,cod_sanzione,tipo_tributo
             ,percentuale,importo,riduzione,riduzione_2
             ,utente,data_variazione,note,sequenza_sanz
             )
       values(a_pratica,w_cod_sanzione,'TARSU'
             ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
             ,a_utente,trunc(sysdate),null,w_sequenza_sanz
             )
       ;
    END;
  end if;
--
-- Analisi versamenti
--
--dbms_output.put_line('Analisi versamenti');
  --
  if w_num_vers > 0 then
    --
    -- Determinazione del Versato Tardivo e Omesso (viene gestito come tardivo alla data di Pagamento)
    -- Assegnazione degli eventuali versamenti ad ogni rata fino al raggiungimento della imposta
    --
    bInd1 := 0;
    LOOP
      bInd1 := bInd1 + 1;
      if bInd1 > w_ind_max then
        exit;
      end if;
      --
      w_imposta := t_tot_imposta(bInd1);
      --
      if w_imposta > 0 then
        bInd2 := 0;
        LOOP
          bInd2 := bInd2 + 1;
          if bInd2 > w_num_vers then
           exit;
          end if;
         if t_rata(bInd2) = bInd1 and t_vers(bInd2) > 0 then
            w_versato := t_vers(bInd2);
            if w_versato > w_imposta then
               w_versato := w_imposta;
            end if;
            if t_scad(bInd2) > t_scadenza(bInd1) then
               w_scad          := t_scad(bInd2);
               w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
               w_scadenza      := t_scadenza(bInd1);
               w_diff_giorni   := w_scad + 1 - w_scadenza;
            else
               w_diff_giorni   := 0;
            end if;
            t_tot_imposta(bInd1) := t_tot_imposta(bInd1) - w_versato;
            t_vers(bInd2)        := t_vers(bInd2)        - w_versato;
            w_imposta            := w_imposta            - w_versato;
            if w_diff_giorni > 0 then
               if w_diff_giorni > 30 then
                  if sign(2 - w_anno_scadenza + w_anno) < 1 then
                     if w_comune = '017096' then
                        --
                        -- Per Lumezzane (017096) se il ravvedimento avviene dopo il primo anno,
                        -- la riduzione passa ad un mezzo invece di un quinto o un sesto.
                        --
                        w_rid          := 2;
                        t_tot_tardivo_2(bInd1) := t_tot_tardivo_2(bInd1) + w_versato;
                     else
                        if w_anno > 1999 then
                           -- D.L. 185/2008 (art.16 comma 5)
                           if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                              w_rid := 10;
                              t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
                           else
                              w_rid := 5;
                              t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
                           end if;
                        else
                           w_rid       := 6;
                           t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
                        end if;
                     end if;
                  else
                     if w_anno > 1999 then
                        if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                           w_rid := 10;
                           t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
                        else
                           w_rid := 5;
                           t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
                        end if;
                     else
                        w_rid       := 6;
                        t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
                     end if;
                  end if;
               else
                  if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                     w_rid := 12;
                     t_tot_tardivo_12(bInd1) := t_tot_tardivo_12(bInd1) + w_versato;
                  else
                     w_rid := 8;
                     t_tot_tardivo_8(bInd1) := t_tot_tardivo_8(bInd1) + w_versato;
                  end if;
               end if;
              --
              -- Interessi
              --
               if w_flag_int = 'N' and w_flag_netto = 'N' then
                  w_lordo := f_trova_netto(w_versato,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
               else
                  w_lordo := w_versato;
               end if;
               w_interessi := F_CALCOLO_INTERESSI_GG(w_lordo,w_scadenza + 1,w_scad,w_giorni_anno);
               t_tot_interessi(bInd1) := t_tot_interessi(bInd1) + nvl(w_interessi,0);
               --
               t_tot_inter_tefa(bInd1) := 0;
            end if;
          end if;
        END LOOP;
      end if;
    END LOOP;
    --
    -- Compensazione di eventuali pagamenti in eccesso su altre Rate
    --
    bInd1 := 0;
    LOOP
     bInd1 := bInd1 + 1;
     if bInd1 > w_ind_max then
        exit;
     end if;
     w_imposta := t_tot_imposta(bInd1);
     if w_imposta > 0 then
        bInd2 := 0;
        LOOP
           bInd2 := bInd2 + 1;
           if bInd2 > w_num_vers then
              exit;
           end if;
           if t_vers(bInd2) > 0 then
              w_versato := t_vers(bInd2);
              if w_versato > w_imposta then
                 w_versato := w_imposta;
              end if;
              if t_scad(bInd2) > t_scadenza(bInd1) then
                 w_scad          := t_scad(bInd2);
                 w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
                 w_scadenza      := t_scadenza(bInd1);
                 w_diff_giorni   := w_scad + 1 - w_scadenza;
              else
                 w_diff_giorni   := 0;
              end if;
              t_tot_imposta(bInd1) := t_tot_imposta(bInd1) - w_versato;
              t_vers(bInd2)        := t_vers(bInd2)        - w_versato;
              w_imposta            := w_imposta            - w_versato;
              if w_diff_giorni > 0 then
                if w_diff_giorni > 30 then
                if sign(2 - w_anno_scadenza + w_anno) < 1 then
                   if w_comune = '017096' then
                      --
                      -- Per Lumezzane (017096) se il ravvedimento avviene dopo il primo anno,
                      -- la riduzione passa ad un mezzo invece di un quinto o un sesto
                      --
                      w_rid          := 2;
                      t_tot_tardivo_2(bInd1) := t_tot_tardivo_2(bInd1) + w_versato;
                   else
                      if w_anno > 1999 then
                         if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                            w_rid := 10;
                            t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
                         else
                            w_rid := 5;
                            t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
                         end if;
                      else
                         w_rid       := 6;
                         t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
                      end if;
                   end if;
                else
                   if w_anno > 1999 then
                      if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                         w_rid := 10;
                         t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
                      else
                         w_rid := 5;
                         t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
                      end if;
                   else
                      w_rid       := 6;
                      t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
                   end if;
                end if;
                else
                if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                   w_rid := 12;
                   t_tot_tardivo_12(bInd1) := t_tot_tardivo_12(bInd1) + w_versato;
                else
                   w_rid := 8;
                   t_tot_tardivo_8(bInd1) := t_tot_tardivo_8(bInd1) + w_versato;
                end if;
                end if;
              --
              -- Interessi
              --
              if w_flag_int = 'N' and w_flag_netto = 'N' then
                w_lordo := f_trova_netto(w_versato,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
              else
                w_lordo := w_versato;
              end if;
              w_interessi := F_CALCOLO_INTERESSI_GG(w_lordo,w_scadenza +1,w_scad,w_giorni_anno);
              t_tot_interessi(bInd1) := t_tot_interessi(bInd1) + nvl(w_interessi,0);
              --
              t_tot_inter_tefa(bInd1) := 0;
            end if;
          end if;
        END LOOP;
      end if;
    END LOOP;
  end if; -- w_num_vers > 0
--
-- Interessi sulla Tassa Evasa
--
--dbms_output.put_line('Interessi Evasa');
  --
  bInd1 := 0;
  LOOP
    bInd1 := bInd1 + 1;
    if bInd1 > w_ind_max then
       exit;
    end if;
    --
    w_imposta := t_tot_imposta(bInd1);
    w_tefa := t_tot_tefa(bInd1);
    w_magg_tares := t_tot_tares(bInd1);
    --
    if w_imposta > 0 then
       w_versato := w_imposta;
    else
       w_versato := 0;
    end if;
    if w_tefa > 0 then
       w_versato_tefa := w_tefa;
    else
       w_versato_tefa := 0;
    end if;
    --
    w_scad          := a_data_pagam;
    w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
    w_scadenza      := t_scadenza(bInd1);
    w_diff_giorni   := w_scad + 1 - w_scadenza;
    --
  --if w_versato > 0 or w_versato_tefa > 0 then
  --  dbms_output.put_line('Interessi di '||bInd1||'/'||w_ind_max||', su rata: '||t_rata_num(bInd1));
  --end if;
    --
    if w_diff_giorni > 0 and w_versato > 0 then
      if w_diff_giorni > 30 then
        if sign(2 - w_anno_scadenza + w_anno) < 1 then
           if w_comune = '017096' then
              --
              -- Per Lumezzane (017096) se il ravvedimento avviene dopo il primo anno,
              -- la riduzione passa ad un mezzo invece di un quinto o un sesto.
              --
              w_rid          := 2;
              t_tot_tardivo_2(bInd1) := t_tot_tardivo_2(bInd1) + w_versato;
           else
              if w_anno > 1999 then
                 if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                    w_rid := 10;
                    t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
                 else
                    w_rid := 5;
                    t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
                 end if;
              else
                 w_rid       := 6;
                 t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
              end if;
           end if;
        else
           if w_anno > 1999 then
              if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
                 w_rid := 10;
                 t_tot_tardivo_10(bInd1) := t_tot_tardivo_10(bInd1) + w_versato;
              else
                 w_rid := 5;
                 t_tot_tardivo_5(bInd1) := t_tot_tardivo_5(bInd1) + w_versato;
              end if;
           else
              w_rid       := 6;
              t_tot_tardivo_6(bInd1) := t_tot_tardivo_6(bInd1) + w_versato;
           end if;
        end if;
      else
        if w_scad >= to_date('29/11/2008','dd/mm/yyyy') then
           w_rid := 12;
           t_tot_tardivo_12(bInd1) := t_tot_tardivo_12(bInd1) + w_versato;
        else
           w_rid := 8;
           t_tot_tardivo_8(bInd1) := t_tot_tardivo_8(bInd1) + w_versato;
        end if;
      end if;
      --
      -- Interessi sul Tardivo
      --
      if w_flag_netto = 'N' then
        w_lordo_tefa := 0;
        if w_flag_int = 'N' then
          w_lordo := f_trova_netto(w_versato,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
        else
          w_lordo := w_versato;
        end if;
      else
        w_lordo := w_versato;
        w_lordo_tefa := w_versato_tefa;
      end if;
      --
      w_giorni := w_scad - w_scadenza;
      if w_giorni > w_giorni_int then
        w_giorni_int := w_giorni;
      end if;
      w_interessi := f_calcolo_interessi_gg(w_lordo,w_scadenza + 1,w_scad,w_giorni_anno);
      w_inter_tefa := f_calcolo_interessi_gg(w_lordo_tefa,w_scadenza + 1,w_scad,w_giorni_anno);
      --
    --dbms_output.put_line('Imposta: '||w_lordo||', Int: '||round(w_interessi,2)||', GG: '||w_diff_giorni||'/'||w_giorni_anno);
    --dbms_output.put_line('TEFA: '||w_lordo_tefa||', Int: '||round(w_inter_tefa,4)||', GG: '||w_diff_giorni||'/'||w_giorni_anno);
      --
      if a_flag_infrazione = 'R' then
        -- Per i Ravvedimenti 'R' li aggiungo qui cos' si salva i dettagli di ogni calcolo
        inserimento_interessi(a_pratica,null,w_scadenza + 1,w_scad,w_lordo,C_TIPO_TRIBUTO,'S','TR4');
      end if;
      --
      t_tot_interessi(bInd1) := t_tot_interessi(bInd1) + nvl(w_interessi,0);
      t_tot_inter_tefa(bInd1) := t_tot_inter_tefa(bInd1) + nvl(w_inter_tefa,0);
    end if;
  END LOOP;
  --
  if a_flag_infrazione = 'R' then
    --
    -- Accorpa totali per rata fisica
    --
    bInd1 := w_ind_ruoli_base;
    loop
      if(bInd1 > w_ind_max) then
        exit;
      end if;
      --
    --dbms_output.put_line('Accorpamento di '||bInd1||'/'||w_ind_ruoli_max||', su rata: '||t_rata_num(bInd1));
    --dbms_output.put_line(' Dovuto: '||t_tot_imposta(bInd1)||', interessi: '||t_tot_interessi(bInd1));
    --dbms_output.put_line(' TEFA: '||t_tot_tefa(bInd1)||', interessi: '||t_tot_inter_tefa(bInd1));
      --
      bInd2 := t_rata_num(bInd1);
      --
      t_tot_imposta(bInd2) := t_tot_imposta(bInd2) + t_tot_imposta(bInd1);
      t_tot_interessi(bInd2) := t_tot_interessi(bInd2) + t_tot_interessi(bInd1);
      t_versato(bInd2) := t_versato(bInd2) + t_versato(bInd1);
      --
      t_tot_tefa(bInd2) := t_tot_tefa(bInd2) + t_tot_tefa(bInd1);
      t_tot_inter_tefa(bInd2) := t_tot_inter_tefa(bInd2) + t_tot_inter_tefa(bInd1);
      t_versato_tefa(bInd2) := t_versato_tefa(bInd2) + t_versato_tefa(bInd1);
      --
      t_tot_tares(bInd2) := t_tot_tares(bInd2) + t_tot_tares(bInd1);
      --
      bInd1 := bInd1 + 1;
    end loop;
    --
    w_ind_max := 6;
  end if;
--
-- Se il ravvedimento si riferisce a ruoli differenti,
-- si accorpano le eventuali rate nella prima per evitare di creare caos per chi opera.
-- Come scadenza viene utilizzata la data_pagamento del ravvedimento,
-- in questo modo non dovrebbero uscire tardivi versamenti e interessi
-- In caso contrario, si spostano gli elementi delle rate nei primi elementi delle tabelle.
--
-- Nota : L'accorpamento viene fatto sempre per i ravvedimento di tipo 'V' (Vedi sopra)
--
--dbms_output.put_line('Ruoli multipli');
  --
  if w_flag_accorpa_rate = 'S' then
    bInd1             := 0;
    w_tot_imposta     := 0;
    w_tot_tefa        := 0;
    w_tot_tares       := 0;
    w_tot_tardivo_2   := 0;
    w_tot_tardivo_5   := 0;
    w_tot_tardivo_6   := 0;
    w_tot_tardivo_8   := 0;
    w_tot_tardivo_10  := 0;
    w_tot_tardivo_12  := 0;
    w_tot_interessi   := 0;
    w_tot_inter_tefa  := 0;
    LOOP
      bInd1 := bInd1 + 1;
      if bInd1 > w_ind_max then
        exit;
      end if;
      w_tot_imposta   := w_tot_imposta + t_tot_imposta(bInd1);
      w_tot_tefa      := w_tot_tefa + t_tot_tefa(bInd1);
      w_tot_tares     := w_tot_tares + t_tot_tares(bInd1);
      w_tot_tardivo_2 := w_tot_tardivo_2 + t_tot_tardivo_2(bInd1);
      w_tot_tardivo_5 := w_tot_tardivo_5 + t_tot_tardivo_5(bInd1);
      w_tot_tardivo_6 := w_tot_tardivo_6 + t_tot_tardivo_6(bInd1);
      w_tot_tardivo_8 := w_tot_tardivo_8 + t_tot_tardivo_8(bInd1);
      w_tot_tardivo_10 := w_tot_tardivo_10 + t_tot_tardivo_10(bInd1);
      w_tot_tardivo_12 := w_tot_tardivo_12 + t_tot_tardivo_12(bInd1);
      w_tot_interessi := w_tot_interessi + t_tot_interessi(bInd1);
      w_tot_inter_tefa := w_tot_inter_tefa + t_tot_inter_tefa(bInd1);
      t_scadenza(bInd1)       := to_date('31122999','ddmmyyyy');
      t_tot_imposta(bInd1)    := 0;
      t_tot_tardivo_2(bInd1)  := 0;
      t_tot_tardivo_5(bInd1)  := 0;
      t_tot_tardivo_6(bInd1)  := 0;
      t_tot_tardivo_8(bInd1)  := 0;
      t_tot_tardivo_10(bInd1) := 0;
      t_tot_tardivo_12(bInd1) := 0;
      t_tot_interessi(bInd1)  := 0;
    END LOOP;
    t_scadenza(1)           := a_data_pagam;
    t_tot_imposta(1)        := w_tot_imposta;
    t_tot_tefa(1)           := w_tot_tefa;
    t_tot_tares(1)          := w_tot_tares;
    t_tot_tardivo_2(1)      := w_tot_tardivo_2;
    t_tot_tardivo_5(1)      := w_tot_tardivo_5;
    t_tot_tardivo_6(1)      := w_tot_tardivo_6;
    t_tot_tardivo_8(1)      := w_tot_tardivo_8;
    t_tot_tardivo_10(1)     := w_tot_tardivo_10;
    t_tot_tardivo_12(1)     := w_tot_tardivo_12;
    t_tot_interessi(1)      := w_tot_interessi;
    t_tot_inter_tefa(1)     := w_tot_inter_tefa;
    w_delta_rate            := 0;
  elsif w_delta_rate > 0 then
    bInd1 := w_delta_rate;
    LOOP
      bInd1 := bInd1 + 1;
      w_tot_interessi := 0;
      if bInd1 > w_ind_max then
        exit;
      end if;
      bInd2 := bInd1 - w_delta_rate;
      t_scadenza(bInd2)      := t_scadenza(bInd1);
      t_tot_imposta(bInd2)   := t_tot_imposta(bInd1);
      t_tot_tardivo_2(bInd2) := t_tot_tardivo_2(bInd1);
      t_tot_tardivo_5(bInd2) := t_tot_tardivo_5(bInd1);
      t_tot_tardivo_6(bInd2) := t_tot_tardivo_6(bInd1);
      t_tot_tardivo_8(bInd2) := t_tot_tardivo_8(bInd1);
      t_tot_tardivo_10(bInd2) := t_tot_tardivo_10(bInd1);
      t_tot_tardivo_12(bInd2) := t_tot_tardivo_12(bInd1);
      t_tot_interessi(bInd2) := t_tot_interessi(bInd1);
      w_tot_interessi        := w_tot_interessi + t_tot_interessi(bInd1);
      t_scadenza(bInd1)      := to_date('31122999','ddmmyyyy');
      t_tot_imposta(bInd1)   := 0;
      t_tot_tardivo_2(bInd1) := 0;
      t_tot_tardivo_5(bInd1) := 0;
      t_tot_tardivo_6(bInd1) := 0;
      t_tot_tardivo_8(bInd1) := 0;
      t_tot_tardivo_10(bInd1) := 0;
      t_tot_tardivo_12(bInd1) := 0;
      t_tot_interessi(bInd1) := 0;
    END LOOP;
  else
    w_tot_interessi := 0;
    w_tot_inter_tefa := 0;
    bInd1 := 0;
    LOOP
      bInd1 := bInd1 + 1;
      if bInd1 > w_ind_max then
        exit;
      end if;
      w_tot_interessi := w_tot_interessi + nvl(t_tot_interessi(bInd1),0);
      w_tot_inter_tefa := w_tot_inter_tefa + nvl(t_tot_inter_tefa(bInd1),0);
    END LOOP;
  end if;
--
-- Analisi dei Totali Memorizzati ed Emissione delle Sanzioni
--
  bInd1           := 0;
  LOOP
    bInd1 := bInd1 + 1;
    if (bInd1 > 4) or ((w_flag_accorpa_rate = 'S') and (bInd1 > 1)) then
       exit;
    end if;
    --
    -- Tassa Evasa
    --
    w_imposta := t_tot_imposta(bInd1);
    w_interessi := t_tot_interessi(bInd1);
    w_versato := t_versato(bInd1);
    --
    w_tefa := t_tot_tefa(bInd1);
    w_inter_tefa := t_tot_inter_tefa(bInd1);
    w_versato_tefa := t_versato_tefa(bInd1);
    --
    w_imposta := w_imposta + w_tefa;
    w_interessi := w_interessi + w_inter_tefa;
    w_versato := w_versato + w_versato_tefa;
    --
    if a_flag_infrazione = 'R' then
      w_magg_tares := t_tot_tares(bInd1);   -- In questo caso separariamo il Netto dalla C.P.
    else
      w_magg_tares := 0.0;
    end if;
    --
  --dbms_output.put_line('Rata : '||bInd1||', evaso: '||w_imposta||', di cui C.P.: '||w_magg_tares||', interessi: '||w_interessi);
    --
    if a_flag_infrazione = 'R' then
      w_cod_sanzione := 101;       -- Tutto in una unica voce
      w_cod_sanz_tares := 561;
      w_note := w_tot_imposta_note;
      w_note_tares := w_tot_tares_note;
    else
      w_cod_sanzione := 101;       -- 1r1 : Evasa
      w_cod_sanzione := w_cod_sanzione + bInd1 * 10;
      w_cod_sanz_tares := 0;
      w_note := null;
      w_note_tares := null;
    end if;
    --
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_netto := w_imposta - w_magg_tares;
        w_netto := f_trova_netto(w_netto,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_netto := w_imposta - w_magg_tares;
      end if;
      BEGIN
        w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza,w_sequenza_sanz);
        if w_errore is not null then
           RAISE ERRORE;
        end if;
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU',
              null,w_netto,null,null,
              a_utente,trunc(sysdate),w_note,w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    -- Componenti Perequative
    --
    if w_magg_tares > 0 then
      BEGIN
        w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza,w_sequenza_sanz);
        if w_errore is not null then
           RAISE ERRORE;
        end if;
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanz_tares,'TARSU',
              null,w_magg_tares,null,null,
              a_utente,trunc(sysdate),w_note_tares,w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    -- Tardivo Versamento
    --
    w_cod_sanzione := 108 + bInd1 * 10;
    --
    w_imposta := t_tot_tardivo_2(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
         w_lordo := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,2,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/2 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    w_imposta := t_tot_tardivo_5(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_lordo := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,5,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/5 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    w_imposta := t_tot_tardivo_10(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_lordo := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,10,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/10 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    w_imposta := t_tot_tardivo_6(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_lordo := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,6,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/6 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    -- Tardivo Versamento <= 30GG
    --
    w_cod_sanzione := 109 + bInd1 * 10;
    --
    w_imposta := t_tot_tardivo_8(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_lordo := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,8,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/8 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
    --
    w_imposta := t_tot_tardivo_12(bInd1);
    if w_imposta > 0 then
      if w_flag_netto = 'N' then
        w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
      else
        w_lordo  := w_imposta;
      end if;
      if w_flag_sanz = 'S' then
        w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
      end if;
      w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,12,w_scadenza,w_percentuale,w_riduzione,w_riduzione_2,w_sanzione,w_sequenza_sanz);
      if w_errore is not null then
        RAISE ERRORE;
      end if;
      BEGIN
        insert into sanzioni_pratica
              (pratica,cod_sanzione,tipo_tributo
              ,percentuale,importo,riduzione,riduzione_2
              ,utente,data_variazione,note,sequenza_sanz
              )
        values(a_pratica,w_cod_sanzione,'TARSU'
              ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
              ,a_utente,trunc(sysdate),'Ulteriore detrazione di 1/12 per Ravvedimento Operoso.',w_sequenza_sanz
              )
        ;
      END;
    end if;
  END LOOP;
--
-- Interessi
--
--dbms_output.put_line('Interessi');
  --
  if a_flag_infrazione = 'R' then
    --
    -- Per i Ravvedimenti R li abbiamo già dettagliati sopra, quindi non serve
    -- Aggiorniamo solo il valore di 'giorni' come richiesto dai Servizi
    -- (RV) 2024/03/08 : contrordine, per i ravvedimenti non serve
    --
    w_cod_sanzione := 199;
  else
    if w_tot_interessi > 0 then
      BEGIN
         w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza,w_sequenza_sanz);
         if w_errore is not null then
           RAISE ERRORE;
         end if;
         insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo
               ,percentuale,importo,riduzione,riduzione_2
               ,utente,data_variazione,note,sequenza_sanz
               )
         values(a_pratica,199,'TARSU'
               ,null,round(w_tot_interessi,2),null,null
               ,a_utente,trunc(sysdate),null,w_sequenza_sanz
               )
         ;
      END;
    end if;
    --
  --if w_tot_inter_tefa > 0 then
  --end if;
  end if;
  --
  -- (AB - 28/02/2023): se il contribuente è deceduto, si eliminano
  --                    le sanzioni lasciando solo imposta evasa,
  --                    interessi e spese di notifica
  BEGIN
    select stato
      into w_stato_sogg
      from soggetti sogg, contribuenti cont
     where sogg.ni = cont.ni
       and cont.cod_fiscale = w_cod_fiscale
    ;
  EXCEPTION
    WHEN others THEN
       w_errore := 'Errore in ricerca soggetti: '||SQLERRM;
       RAISE errore;
  END;
  --
  if w_stato_sogg = 50 then
    ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
  end if;
  --
  COMMIT;
EXCEPTION
   WHEN FINE THEN null;
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: CALCOLO_SANZIONI_RAOP_TARSU */
/

