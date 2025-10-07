--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_acc_sanzioni_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACC_SANZIONI_TARSU
/*******************************************************************************
Rev.  Data         Autore    Descrizione
18    30/07/2025   RV        #77694
                             Integrato gestione importi rateizzati Maggiorazione
                             Tares (Componentio Perequative) per Calcolo Sanzioni
17    20/05/2025   RV        #77609
                             Adeguamento nuovo DL regime sanzionatorio
16    16/09/2024   RV        #55525
                             Standardizzato note Sanzioni Interessi
15    02/02/2023   RV        #55324
                             Modificato x codice sanzione 898 spese notifica sollecito
14    20/12/2022   AB        aggiunto la riduzione per la 197
13    23/09/2022   VD        Gestione solleciti: si emettono solo le sanzioni
                             relative all'imposta evasa e alle spese di
                             notifica per consentire la stampa dei dati corretti
                             utilizzando il package STAMPA_ACCERTAMENTI_TARSU.
                             Aggiunto parametro per gestione spese di notifica.
12    25/02/2019   VD        Aggiunta selezione della riduzione per la
                             sanzione 199 (interessi) dal relativo dizionario
11    19/02/2019   VD        Raggruppamento sanzioni in presenza di calcolo
                             interessi: ora raggruppa anche se l'importo
                             sanzione risultante e' minore di zero.
10    10/05/2018   VD        Modificato ordinamento selezione versamenti: non
                             per rata/data versamento ma per data versamento/rata.
                             Modificata attribuzione versamenti a importi dovuti.
9     14/02/2018   VD        Corretta gestione sgravi: prima lo sgravio veniva
                             interamente attribuito alla prima rata, ora viene
                             ripartito in parti uguali su tutte le rate del
                             ruolo.
8     30/01/2018   VD        Modificata gestione attribuzione versamenti per
                             tenere conto degli arrotondamenti
7     21/01/2016   VD        Corretta gestione raggruppamento sanzioni: le spese
                             di notifica vengono escluse dal raggruppamento e
                             dalla eliminazione
                             Aggiunta selezione della riduzione per la sanzione
                             108 (omesso versamento) dal relativo dizionario
6     08/01/2016   VD        Modificata gestione maggiorazione Tares su rate:
                             ora viene memorizzata solo sull'ultima rata
5     29/01/2015   VD        Sostituito codice sanzione 115 con codice 197
4     10/12/2014   VD        Modificato raggruppamento sanzioni.
                             Viene eseguito sempre in presenza di date calcolo
                             interessi; inoltre, si eliminano le sanzioni
                             pratica con causale diversa da 101, 108, 199.
                             Nella gestione della Rata unica tolto il controllo
                             sui cod_sanzione e inserito quello sul tipo_causale (AB)
3     18/11/2014   VD        Aggiunta gestione flag blocco tardivo versamento
2     11/11/2014   VD        Eliminata totalizzazione errata (giorni + interessi)
                             Aggiunte totalizzazioni mancanti (interessi su
                             eccedenze di pagamento)
1     25/09/2014   XX        Cambiata selezione del flag x decidere se dobbiamo
                             o no calcolare la sanzione per la maggiorazione tares
*******************************************************************************/
(a_pratica            IN number
,a_utente             IN varchar2
,a_interessi_dal      in date
,a_interessi_al       in date
,a_se_spese_notifica  in varchar2 default null
) is
i                        number;
w_errore                 varchar2(2000);
errore                   exception;
fine                     exception;
w_flag_sanz_magg_tares   number; --Indica se gestire interessi e sanzioni su Magg Tares o Componenti Perequative
w_flag_cope              number; --Annualità con componenti perequative
w_cod_istat              varchar(6);
--w_delta_rate             number;
w_anno                   number;
w_anno_scadenza          number;
w_data_pratica           date;
w_cod_fiscale            varchar2(16);
w_tipo_pratica           varchar2(1);
w_add_eca                number;
w_mag_eca                number;
w_add_pro                number;
w_aliquota               number;
w_imposta                number;
w_magg_tares             number;
w_magg_tares_rata        number;
w_magg_tares_rata_cnt    number;
w_flag_sanz              varchar2(1);
w_flag_int               varchar2(1);
w_flag_no_tardivo        varchar2(1);
w_versato                number;
w_versato_magg_tares     number;
w_scadenza               date;
w_scadenza_imp           date;
w_scadenza_tares         date;
w_data_notifica          date;
w_data_pag               date;
w_interessi              number;
w_interessi_magg_tares   number;
w_ind_ruolo              number(12); -- Dieci caratteri per il ruolo 0 e num_rata
w_diff_giorni            number;
w_giorni_anno            number;
w_cod_base_imp           number;     -- Codice sanzione base per imposte
w_cod_base_tares         number;     -- Codice sanzione base per Tares : imposte
w_cod_base_tares_int     number;     -- Codice sanzione base per Tares : interessi
w_cod_sanzione           number;
w_cod_sanzione_spese     number;
w_seq_sanzione           number;
w_percentuale            number;
w_riduzione              number;
w_sanzione               number;
w_imp_sanzioni           number;
w_num_ruoli              number;
w_ruolo                  number;
w_tot_versato            number;
w_tot_omesso             number;
--w_tot_imposta_originale  number;
--w_tot_imposta            number;
--w_tot_tardivo_30         number;
--w_tot_tardivo            number;
--w_tot_interessi          number;
w_num_vers               number;
w_lordo                  number;
--w_semestri               number;
w_rate_analizzate        number;
--
w_sgravio_tares          number;
w_tot_tares              number;
w_tot_sgravio_tares      number;
--
type t_ruoli_ruolo_t               is table of number index by binary_integer;
t_ruoli_ruolo                      t_ruoli_ruolo_t;
type t_ruoli_tipo_ruolo_t          is table of number index by binary_integer;
t_ruoli_tipo_ruolo                 t_ruoli_tipo_ruolo_t;
type t_ruoli_tipo_emissione_t      is table of varchar2(1) index by binary_integer;
t_ruoli_tipo_emissione             t_ruoli_tipo_emissione_t;
type t_ruoli_sgravio_comp_t        is table of number index by binary_integer;
t_ruoli_sgravio_comp               t_ruoli_sgravio_comp_t;
type t_ruoli_esiste_acconto_t      is table of number index by binary_integer;
t_ruoli_esiste_acconto             t_ruoli_esiste_acconto_t;
type t_ruoli_num_rate_t            is table of number index by binary_integer;
t_ruoli_num_rate                   t_ruoli_num_rate_t;
--
type t_ruoli_sgravio_tares_t       is table of number index by binary_integer;
t_ruoli_sgravio_tares              t_ruoli_sgravio_tares_t;
--
type t_importo_rata_t              is table of number index by binary_integer;
t_importo_rata                     t_importo_rata_t;  -- importo rata
type t_imp_ult_rata_t              is table of number index by binary_integer;
t_imp_ult_rata                     t_imp_ult_rata_t;  -- importo ultima rata (ricavato per differenza)
type t_importo_ruolo_t             is table of number index by binary_integer;
t_importo_ruolo                    t_importo_ruolo_t; -- importo totale del ruolo arrotondato
type t_imp_rata_arr_t              is table of number index by binary_integer;
t_imp_rata_arr                     t_imp_rata_arr_t;  -- importo rata
type t_last_rata_arr_t             is table of number index by binary_integer;
t_last_rata_arr                    t_last_rata_arr_t;  -- importo ultima rata (ricavato per differenza)
type t_imp_ruolo_arr_t             is table of number index by binary_integer;
t_imp_ruolo_arr                    t_imp_ruolo_arr_t; -- importo totale del ruolo arrotondato
type t_tot_imp_tot_imp_orig_t      is table of number index by binary_integer;
t_tot_imp_tot_imp_orig             t_tot_imp_tot_imp_orig_t;--omesso ?
type t_tot_imp_tot_imposta_t       is table of number index by binary_integer;
t_tot_imp_tot_imposta              t_tot_imp_tot_imposta_t;--imposta dovuta
type t_tot_imp_tot_tardivo_30_t    is table of number index by binary_integer;
t_tot_imp_tot_tardivo_30           t_tot_imp_tot_tardivo_30_t;--tardivo entro 30gg
type t_tot_imp_tot_tardivo_t       is table of number index by binary_integer;
t_tot_imp_tot_tardivo              t_tot_imp_tot_tardivo_t;--tardivo oltre 30gg
type t_tot_imp_scadenza_t          is table of date index by binary_integer;
t_tot_imp_scadenza                 t_tot_imp_scadenza_t;--scadenza della rata
type t_tot_imp_tot_interessi_t     is table of number index by binary_integer;
t_tot_imp_tot_interessi            t_tot_imp_tot_interessi_t;--interessi calcolati
type t_tot_imp_gg_interessi_t      is table of number index by binary_integer;
t_tot_imp_gg_interessi             t_tot_imp_gg_interessi_t;--gg di interesse
type t_tot_imp_note_interessi_t    is table of varchar2(2000) index by binary_integer;
t_tot_imp_note_interessi           t_tot_imp_note_interessi_t;-- memorizza i valori usati per il calcolo degli interessi
type t_vers_versato_t              is table of number index by binary_integer;
t_vers_versato                     t_vers_versato_t;
type t_vers_magg_tares_t           is table of number index by binary_integer;
t_vers_magg_tares                  t_vers_magg_tares_t;
type t_vers_data_pag_t             is table of date index by binary_integer;
t_vers_data_pag                    t_vers_data_pag_t;
type t_vers_rata_t                 is table of number index by binary_integer;
t_vers_rata                        t_vers_rata_t;
type t_magg_tares_tot_imp_orig_t   is table of number index by binary_integer;
t_magg_tares_tot_imp_orig          t_magg_tares_tot_imp_orig_t;--omesso ?
type t_magg_tares_tot_imposta_t    is table of number index by binary_integer;
t_magg_tares_tot_imposta           t_magg_tares_tot_imposta_t;--imposta dovuta
type t_magg_tares_tot_tardivo_30_t is table of number index by binary_integer;
t_magg_tares_tot_tardivo_30        t_magg_tares_tot_tardivo_30_t;--tardivo entro 30gg
type t_magg_tares_tot_tardivo_t    is table of number index by binary_integer;
t_magg_tares_tot_tardivo           t_magg_tares_tot_tardivo_t;--tardivo oltre 30gg
type t_magg_tares_scadenza_t       is table of date index by binary_integer;
t_magg_tares_scadenza              t_magg_tares_scadenza_t;--scadenza della rata
type t_magg_tares_tot_interessi_t  is table of number index by binary_integer;
t_magg_tares_tot_interessi         t_magg_tares_tot_interessi_t;--interessi calcolati
type t_magg_tares_gg_interessi_t   is table of number index by binary_integer;
t_magg_tares_gg_interessi          t_magg_tares_gg_interessi_t;--gg di interesse
type t_magg_tares_note_interessi_t is table of varchar2(2000) index by binary_integer;
t_magg_tares_note_interessi        t_magg_tares_note_interessi_t;-- memorizza i valori usati per il calcolo degli interessi
--
bind1                    binary_integer;
bind2                    binary_integer;
--
w_i_ruolo                binary_integer;
w_num_rate               number;
w_importo_rata           number;
w_imp_ult_rata           number;
w_rata_arr               number;
w_last_rata_arr          number;
w_importo_ruolo_arr      number;
w_versato_arr            number;
w_sgravio_rata           number;
w_sgravio_ult_rata       number;
w_step                   varchar2(100);
-------------------------------------------------------------------------
cursor sel_vers
( a_cod_fiscale varchar2
, a_anno number
)
is
select nvl(vers.rata,0) rata
     , nvl(sum(vers.importo_versato),0) - sum(nvl(vers.maggiorazione_tares,0)) importo_versato --SC 10/03/2014 Att  TARES: Accertamenti Automatici .
     , vers.data_pagamento
     , 0    delta_rate    -- f_delta_rate(vers.ruolo) delta_rate
     , nvl(sum(vers.maggiorazione_tares),0) maggiorazione_tares --SC 10/03/2014 Att  TARES: Accertamenti Automatici .
  from versamenti       vers
  --   , scadenze         scad
     , pratiche_tributo prtr
 where vers.cod_fiscale                 = a_cod_fiscale
   and vers.anno                        = a_anno
   and vers.tipo_tributo                = 'TARSU'
 --  and scad.anno                        = a_anno
 --  and scad.tipo_tributo                = 'TARSU'
--   and scad.rata                        = nvl(vers.rata,0) -- + f_delta_rate(vers.ruolo)
   and prtr.pratica   (+)               = vers.pratica
   and (    nvl(prtr.tipo_pratica,'D')  = 'D'
        or  nvl(prtr.tipo_pratica,'D')  = 'A'
        and nvl(prtr.anno,a_anno - 1)  <> a_anno
       )
 group by
       nvl(vers.rata,0)
     , vers.data_pagamento
   --  , f_delta_rate(vers.ruolo)
 order by
       vers.data_pagamento
     , nvl(vers.rata,0)
   --  , f_delta_rate(vers.ruolo)
;
-------------------------------------------------------------------------
cursor sel_omessa_merge
( p_pratica number
, p_flag_magg_tares varchar2
)
is
  select sum(importo) as importo
       , sapr.sequenza_sanz
       , sapr.percentuale
       , sapr.riduzione
       , sanz.data_inizio
       , sanz.data_fine
       , min(sanz.cod_sanzione) as cod_sanzione_err
       , listagg(to_char(sanz.cod_sanzione), ', ') WITHIN GROUP(ORDER BY sanz.cod_sanzione) as cod_sanzione_list
    from sanzioni_pratica sapr,
         sanzioni sanz
   where sapr.pratica = p_pratica
     and sapr.cod_sanzione in (select cod_sanzione
                                 from sanzioni
                                where tipo_causale not in ('E','I','S')
                                  and nvl(flag_magg_tares,'N') = p_flag_magg_tares
                                  and tipo_tributo = 'TARSU'
                              )
    and sapr.cod_sanzione = sanz.cod_sanzione
    and sapr.sequenza_sanz = sanz.sequenza
  group by
        sapr.sequenza_sanz
      , sapr.percentuale
      , sapr.riduzione
      , sanz.data_inizio
      , sanz.data_fine
;
-------------------------------------------------------------------------
FUNCTION F_CONTA_RATE_ANALIZZATE
( p_indice_ruolo number
)
return number
is
  --
  w_ret    number;
  w_indice number;
  --
begin
  w_ret := 0;
  --
  w_indice := p_indice_ruolo - 1;
  while w_indice > 0 loop
      w_ret := w_ret + t_ruoli_num_rate(w_indice);
      w_indice := w_indice - 1;
  end loop;
  --
  return w_ret;
end;
-------------------------------------------------------------------------
FUNCTION F_SEQUENZA_SANZIONE
( s_cod_sanzione    IN number
, s_data_inizio     in date default null
)
return number
IS
  --
  w_seq_sanz          number;
  --
BEGIN
  begin
    select sanz.sequenza
      into w_seq_sanz
      from sanzioni sanz
     where sanz.cod_sanzione = s_cod_sanzione
       and sanz.TIPO_TRIBUTO = 'TARSU'
       and s_data_inizio between
           sanz.data_inizio and sanz.data_fine;
    exception
     when others then
        w_errore := 'Sanzione '||to_char(s_cod_sanzione)||' non presente alla data '||to_char(s_data_inizio,'DD/MM/YYYY')||' '||' ('||SQLERRM||')';
        raise errore;
  end;
  --
  return w_seq_sanz;
END;
-------------------------------------------------------------------------
-- in caso di rata unica, con scadenza diversa dalla prima rata
-- se il contribuente ha pagato la rata unica alla scadenza
-- e ha pagato tutto, non si devono sanzionare i tardivi sulle rate precedenti.
-- Per questo cancella la pratica con le sanzioni.
-- In tutti gli altri casi esce senza fare nulla.
-------------------------------------------------------------------------
PROCEDURE GESTIONE_RATA_UNICA
( p_cod_fiscale varchar2
, p_pratica number
, p_anno number
, p_ruolo number
)
IS
  --
  w_scadenza_rata_zero date;
  w_scadenza_seconda date;
  w_scadenza_terza date;
  w_scadenza_quarta date;
  w_ruolo  number;
  w_rata_unica number;
  w_data_versamento date;
  w_esistono_omessi number;
  --
BEGIN
  begin
     select data_scadenza
       into w_scadenza_rata_zero
       from scadenze
      where anno = p_anno
        and tipo_scadenza = 'V'
        and tipo_tributo = 'TARSU'
        and rata = 0
        and data_scadenza is not null
     ;
  exception
  when others then
       return;
  end;
  --dbms_output.put_line('GESTIONE_RATA_UNICA w_scadenza_rata_zero '||w_scadenza_rata_zero);
  begin
     select ruoli.ruolo, scadenza_rata_2, scadenza_rata_3, scadenza_rata_4
       into w_ruolo, w_scadenza_seconda, w_scadenza_terza, w_scadenza_quarta
       from ruoli
          , ruoli_contribuente ruco
      where invio_consorzio is not null
        and tipo_emissione = 'T'
        and scadenza_rata_2 is not null
        and ruoli.ruolo = p_ruolo
        and ruoli.tipo_ruolo = 1
        and anno_ruolo = p_anno
        and ruco.cod_fiscale = p_cod_fiscale
        and ruco.ruolo = ruoli.ruolo
     ;
  exception
  when others then
       return;
  end;
  --dbms_output.put_line('GESTIONE_RATA_UNICA w_scadenza_seconda, w_scadenza_terza, w_scadenza_quarta '||w_scadenza_seconda||' '||w_scadenza_terza||' '||w_scadenza_quarta);
  if w_scadenza_seconda = w_scadenza_rata_zero then
     w_rata_unica := 2;
  elsif w_scadenza_terza = w_scadenza_rata_zero then
     w_rata_unica := 3;
  elsif w_scadenza_quarta = w_scadenza_rata_zero then
     w_rata_unica := 4;
  end if;
  --dbms_output.put_line('GESTIONE_RATA_UNICA w_rata_unica '||w_rata_unica);
  if w_rata_unica is null then
     return;
  end if;
  begin
     select data_pagamento, importo_versato
       into w_data_versamento
          , w_versato
       from versamenti
      where cod_fiscale = p_cod_fiscale
        and tipo_tributo = 'TARSU'
        and anno = p_anno;
  exception
  when others then
       return;
  end;
  --dbms_output.put_line('GESTIONE_RATA_UNICA w_data_versamento w_versato '||w_data_versamento||' '||w_versato);
  if w_data_versamento > w_scadenza_rata_zero then
     return;
  end if;
  begin
    select count(1)
      into w_esistono_omessi
      from sanzioni sanz, sanzioni_pratica sapr
     where sapr.pratica = a_pratica
       and sanz.cod_sanzione = sapr.cod_sanzione
       and sanz.tipo_causale in ('O','P')
       --
       --  RV (2025/05/14) : siccome ci interessa solo se ci sono ommessi o meno, nemmeno quanti, evitiamo
       --                    di fare logiche strane che darebbero risultati possibilmente errati e prendiamo
       --                    solo le eventuali sanzioni_pratica con match sulla sequenza storica originale
       --
       and sanz.sequenza = sapr.sequenza_sanz
       --
     --and sanz.sequenza = 1
    ;  -- sostituito i controlli su cod_sanzione AB 10/12/14
    if w_esistono_omessi > 0 then
       return;
    end if;
  exception
  when others then
       raise;
  end;
--dbms_output.put_line('GESTIONE_RATA_UNICA w_esistono_omessi '||w_esistono_omessi);
  --
  delete pratiche_tributo
   where pratica = p_pratica;
--dbms_output.put_line('GESTIONE_RATA_UNICA ');
  --
END GESTIONE_RATA_UNICA;
-------------------------------------------------------------------------
-- Funzione per Calcolo Sanzione
-------------------------------------------------------------------------
FUNCTION F_IMP_SANZ
( a_cod_sanzione      IN     number
, a_importo           IN     number
, a_data_inizio       in     date
, a_percentuale       IN OUT number
, a_riduzione         IN OUT number
, a_sanzione          IN OUT number
)
Return string
IS
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
            ,sanz.percentuale
            ,sanz.riduzione
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
        from sanzioni sanz
       where sanz.tipo_tributo = 'TARSU'
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_inizio between
             sanz.data_inizio and sanz.data_fine
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        w_errore := 'Sanzione '||a_cod_sanzione||' non prevista per la data '||to_char(a_data_inizio);
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
-------------------------------------------------------------------------
-- Somma gli importi di Evasa e genera Saznione Unica
-------------------------------------------------------------------------
procedure RAGGRUPPA_SAPR_EVASA
( p_pratica          in number
, p_flag_magg_tares  in varchar2
, p_cod_sanzione     in number
, p_data_inizio      in date
, p_utente           in varchar2
)
is
  --
  w_importo_tassa_evasa      number;
  --
  w_seq_sanzione             number;
  --
BEGIN
  begin
    select sum(importo)
      into w_importo_tassa_evasa
      from sanzioni_pratica
     where pratica = p_pratica
       and cod_sanzione in (select cod_sanzione
                              from sanzioni
                             where tipo_causale = 'E'
                               and nvl(flag_magg_tares,'N') = p_flag_magg_tares
                               and tipo_tributo = 'TARSU')
         ;
  EXCEPTION
     WHEN others THEN
       w_importo_tassa_evasa := 0;
  end;
  --
  if w_importo_tassa_evasa <> 0 then
    w_seq_sanzione := F_SEQUENZA_SANZIONE(p_cod_sanzione,p_data_inizio);
    BEGIN
       insert into sanzioni_pratica
             (pratica,cod_sanzione
             ,tipo_tributo,percentuale
             ,importo,riduzione
             ,utente,data_variazione,note,
             sequenza_sanz
             )
       values(p_pratica,p_cod_sanzione
             ,'TARSU',null
             ,w_importo_tassa_evasa,null
             ,p_utente,trunc(sysdate),null
             ,w_seq_sanzione
             )
            ;
    EXCEPTION
        WHEN others THEN
           w_errore := 'Errore in inserimento sanzione ('||p_cod_sanzione||')';
           RAISE errore;
    END;
  end if;
END;
-------------------------------------------------------------------------
-- Somma gli importi di Omessa e genera Saznione Unica
-------------------------------------------------------------------------
procedure RAGGRUPPA_SAPR_OMESSA
( p_pratica          in number
, p_flag_magg_tares  in varchar2
, p_cod_sanzione     in number
, p_utente           in varchar2
)
is
  --
  w_importo_omesso           number;
  --
--w_cod_sanz_omesso          number;
  w_list_sanz_omesso         varchar(2000);
  w_seq_sanz_omesso          number;
  w_perc_omesso              number;
  w_riduz_omesso             number;
  w_inizio_omesso            date;
  w_fine_omesso              date;
  --
  w_seq_diz                  number;
  w_perc_diz                 number;
  w_riduz_diz                number;
  --
  w_seq_sanzione             number;
  --
BEGIN
  BEGIN
    FOR rec_omessa in sel_omessa_merge(p_pratica, p_flag_magg_tares)
    LOOP
      w_importo_omesso := rec_omessa.importo;
      w_seq_sanz_omesso := rec_omessa.sequenza_sanz;
      w_perc_omesso := rec_omessa.percentuale;
      w_riduz_omesso := rec_omessa.riduzione;
      w_inizio_omesso := rec_omessa.data_inizio;
      w_fine_omesso := rec_omessa.data_fine;
    --w_cod_sanz_omesso := rec_omessa.cod_sanzione_err;
      w_list_sanz_omesso := rec_omessa.cod_sanzione_list;
      --
    --dbms_output.put_line('Importo: '||w_importo_omesso);
    --dbms_output.put_line('Dal: '||to_char(w_inizio_omesso,'YYYY/MM/dd')||', Al: '||to_char(w_fine_omesso,'YYYY/MM/dd')||', Sanz: '||w_list_sanz_omesso);
    --dbms_output.put_line('Seq: '||w_seq_sanz_omesso||', Perc: '||w_perc_omesso||', Riduz: '||w_riduz_omesso);
      --
      if w_importo_omesso <> 0 then
        --
        -- Legge dati del dizionario e verifica coerenza dell'accorpamento
        --
        BEGIN
         select sanz.sequenza,
                sanz.percentuale,
                sanz.riduzione
           into w_seq_diz,
                w_perc_diz,
                w_riduz_diz
           from sanzioni sanz
          where sanz.tipo_tributo = 'TARSU'
            and sanz.cod_sanzione = p_cod_sanzione
            and w_inizio_omesso between
                sanz.data_inizio and sanz.data_fine
          ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
              w_errore := 'Sanzione '||p_cod_sanzione||' non prevista per la data '||to_char(w_inizio_omesso);
              RAISE errore;
           WHEN OTHERS THEN
              w_errore := to_char(SQLCODE)||' - '||SQLERRM;
              RAISE errore;
        END;
      --dbms_output.put_line('Diz: '||w_seq_diz||', Perc: '||w_perc_diz||', Riduz: '||w_riduz_diz);
        --
        if (w_seq_diz <> w_seq_sanz_omesso) or
           (nvl(w_perc_diz,0) <> nvl(w_perc_omesso,0)) or
           (nvl(w_riduz_diz,0) <> nvl(w_riduz_omesso,0)) then
               w_errore := 'Incoerenza Sanzione '||p_cod_sanzione||' con Sanzione/i '||w_list_sanz_omesso||chr(13)||chr(10)||
                                          'Verificare Dizionario Sanzioni : Sequenza, Percentuale, Riduzione e Data Inizio/Fine';
               RAISE errore;
        end if;
        --
        w_seq_sanzione := w_seq_sanz_omesso;
    --  dbms_output.put_line('Sanz: '||p_cod_sanzione||', Seq: '||w_seq_sanzione);
        BEGIN
          insert into
                 sanzioni_pratica
                 (pratica,cod_sanzione,tipo_tributo,
                  importo,percentuale,riduzione,sequenza_sanz,
                  utente,data_variazione,note
                 )
          values (p_pratica,p_cod_sanzione,'TARSU',
                  w_importo_omesso,w_perc_omesso,w_riduz_omesso,w_seq_sanzione,
                  p_utente,trunc(sysdate),null
                 )
          ;
        EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in inserimento sanzione ('||p_cod_sanzione||')';
               RAISE errore;
        END;
      end if;
    END LOOP;
  EXCEPTION
    WHEN errore then
      RAISE errore;
    WHEN others THEN
      w_errore := to_char(SQLCODE)||' - '||SQLERRM;
      RAISE errore;
  END;
END;
-------------------------------------------------------------------------
-- Somma gli importi degli Interessi e genera Saznione Unica
-------------------------------------------------------------------------
procedure RAGGRUPPA_SAPR_INTERESSI
( p_pratica          in number
, p_flag_magg_tares  in varchar2
, p_cod_sanzione     in number
, p_data_inizio      in date
, p_utente           in varchar2
)
is
  --
  w_importo_interessi        number;
  --
  w_giorni_interesse         number;
  w_note_interessi           varchar(2000);
  --
  w_seq_sanzione             number;
  --
BEGIN
  begin
    select sum(importo)
         , max(giorni)
         , listagg(note) WITHIN GROUP(ORDER BY cod_sanzione, giorni) as note
      into w_importo_interessi
         , w_giorni_interesse
         , w_note_interessi
      from sanzioni_pratica
     where pratica = p_pratica
       and cod_sanzione in (select cod_sanzione
                              from sanzioni
                             where tipo_causale = 'I'
                               and nvl(flag_magg_tares,'N') = p_flag_magg_tares
                               and tipo_tributo = 'TARSU')
   ;
  EXCEPTION
     WHEN others THEN
       w_importo_interessi := 0;
  end;
  --
  if w_importo_interessi > 0 then
    BEGIN
       select sanz.riduzione
         into w_riduzione
         from sanzioni sanz
        where sanz.tipo_tributo = 'TARSU'
          and sanz.cod_sanzione = p_cod_sanzione
          and p_data_inizio between
              sanz.data_inizio and sanz.data_fine
       ;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          w_errore := 'Sanzione '||p_cod_sanzione||' non prevista per la data '||to_char(p_data_inizio);
          RAISE errore;
       WHEN OTHERS THEN
          w_errore := to_char(SQLCODE)||' - '||SQLERRM;
          RAISE errore;
    END;
  else
    w_riduzione := to_number(null);
  end if;
  --
  if w_importo_interessi <> 0 then
    w_seq_sanzione := F_SEQUENZA_SANZIONE(p_cod_sanzione,p_data_inizio);
    BEGIN
       insert into
              sanzioni_pratica
              (pratica,cod_sanzione,sequenza_sanz
              ,tipo_tributo,percentuale,importo
              ,riduzione,giorni
              ,utente,data_variazione,note
              )
       values (p_pratica,p_cod_sanzione,w_seq_sanzione
              ,'TARSU',null,w_importo_interessi
              ,w_riduzione,w_giorni_interesse
              ,p_utente,trunc(sysdate),substr(w_note_interessi,1,2000)
              )
       ;
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento Interessi ('||p_cod_sanzione||')';
        RAISE errore;
    END;
  end if;
END;
-------------------------------------------------------------------------
procedure RAGGRUPPA_SAPR_ACC_TARSU
( p_pratica          in number
, p_utente           in varchar2
, p_data_inizio      in date
)
is
  --
  i_cod_sanzione             number;
  --
begin
  --
  -- Accorpa Evaso : Imposta
  --
  i_cod_sanzione := 101;
  RAGGRUPPA_SAPR_EVASA(p_pratica, 'N', i_cod_sanzione, p_data_inizio, p_utente);
  --
  -- Accorpa Evaso : TARES (Componenti perequative)
  --
  i_cod_sanzione := 542;
  RAGGRUPPA_SAPR_EVASA(p_pratica, 'S', i_cod_sanzione, p_data_inizio, p_utente);
  --
  -- Accorpa Ommesso : Imposta
  --
  i_cod_sanzione := 108;
  RAGGRUPPA_SAPR_OMESSA(p_pratica, 'N', i_cod_sanzione, p_utente);
  --
  -- Accorpa Ommesso : TARES (Componenti perequative)
  --
  i_cod_sanzione := 543;
  RAGGRUPPA_SAPR_OMESSA(p_pratica, 'S', i_cod_sanzione, p_utente);
  --
  -- Accorpa Interessi : Imposta
  --
  i_cod_sanzione := 199;
  RAGGRUPPA_SAPR_INTERESSI(p_pratica, 'N', i_cod_sanzione, p_data_inizio, p_utente);
  --
  -- Accorpa Interessi : TARES (Componenti perequative)
  --
  i_cod_sanzione := 910;
  RAGGRUPPA_SAPR_INTERESSI(p_pratica, 'S', i_cod_sanzione, p_data_inizio, p_utente);
  --
  -- Elimina sanzioni accorpate
  --
  begin
    delete sanzioni_pratica sapr
     where pratica = p_pratica
       and cod_sanzione not in (101,108,199,   -- Sanzione accorpata : Imposta
                                542,543,910,   -- Sanzione accorpata : TARES (Componenti perequative)
                                197,898)       -- Spese di spedizione varie
    ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in Cancellazioni Sanzioni Rate';
        RAISE errore;
  end;
end RAGGRUPPA_SAPR_ACC_TARSU;
--
--
-- ========================================= --
-- S A N Z I O N I   A C C E R T A M E N T O --
-- ========================================= --
--
--
BEGIN
   w_errore := null;
   BEGIN
      select lpad(to_char(d.pro_cliente),3,'0')
          || lpad(to_char(d.com_cliente),3,'0')
        into w_cod_istat
        from dati_generali   d
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca Dati Generali';
         RAISE errore;
   END;
   w_step := 'a';
    -- dbms_output.put_line('w_step '||w_step);
   BEGIN
      select prtr.data
           , prtr.anno
           , prtr.cod_fiscale
           , prtr.tipo_pratica
        into w_data_pratica
           , w_anno
           , w_cod_fiscale
           , w_tipo_pratica
        from pratiche_tributo prtr
       where prtr.pratica = a_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Pratica '||to_char(a_pratica)||' Assente.';
         RAISE ERRORE;
   END;
   if w_anno < 1998 then
      w_errore := 'Gestione non prevista per anni col vecchio sanzionamento';
      RAISE ERRORE;
   end if;
   --
   w_flag_cope := 0;
   begin
   -- (RV: 23/05/2025) : modificato select per Componenti Perequative
/**
      select distinct 1
        into w_flag_sanz_magg_tares
        from carichi_tarsu
       where anno = w_anno
         and maggiorazione_tares is not null
       ;
**/
      select distinct 1
        into w_flag_sanz_magg_tares
        from componenti_perequative
       where anno = w_anno
      ;
      w_flag_cope := w_flag_sanz_magg_tares;
   exception
     when others then
       w_flag_sanz_magg_tares := 0;
   end;
   BEGIN
      select nvl(cata.addizionale_eca,0)
           , nvl(cata.maggiorazione_eca,0)
           , nvl(cata.addizionale_pro,0)
           , nvl(cata.aliquota,0)
           , nvl(cata.flag_sanzione_add_p,'N')
           , nvl(cata.flag_interessi_add,'N')
           , nvl(cata.flag_no_tardivo,'N')
        into w_add_eca
           , w_mag_eca
           , w_add_pro
           , w_aliquota
           , w_flag_sanz
           , w_flag_int
           , w_flag_no_tardivo
        from carichi_tarsu cata
       where cata.anno = w_anno
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Carichi TARSU non previsti per anno '||to_char(w_anno);
   END;
   BEGIN
      select to_date('0101'||lpad(to_char(w_anno + 1),4,'0'),'ddmmyyyy') -
             to_date('0101'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
        into w_giorni_anno
        from dual
      ;
   END;
   w_step := 'b';
    -- dbms_output.put_line('w_step '||w_step);
--
-- Viene determinato se tutti gli oggetti dell`accertamento
-- sono riferiti allo stesso ruolo.
--
   w_num_ruoli := 0;
   BEGIN
--      select count(distinct nvl(substr(ogim.note,1,10),0))
--           , max(to_number(substr(ogim.note,1,10)))
--        into w_num_ruoli
--           , w_ruolo
--        from oggetti_imposta ogim
--           , oggetti_pratica ogpr
--       where ogim.oggetto_pratica = ogpr.oggetto_pratica
--         and ogpr.pratica         = a_pratica
--      ;
--   for r in (select distinct to_number (nvl (substr  (ogim.note, 1, 10), 0)) ruolo
--                  , nvl(ruoli.SCADENZA_PRIMA_RATA,to_date('31122999','ddmmyyyy')) -- VD: a cosa serve senza alias?
--                  , ruoli.tipo_ruolo
--                  , ruoli.tipo_emissione
--                  , to_number (decode(nvl (substr  (ogim.note, 12, 1), '0'),'0','1',nvl (substr  (ogim.note, 12, 1), 0))) num_rate
--               from oggetti_imposta ogim
--                  , oggetti_pratica ogpr
--                  , ruoli
--              where ogim.oggetto_pratica = ogpr.oggetto_pratica
--                and ogpr.pratica         = a_pratica
--                and ruoli.ruolo = to_number(NVL (SUBSTR (ogim.note, 1, 10),0))
--              order by 2)
   --
   -- (VD - 30/01/2018): aggiunta selezione importo ruolo
   --
   for r in (select to_number (nvl (substr  (ogim.note, 1, 10), 0)) ruolo
                  , ruoli.tipo_ruolo
                  , ruoli.tipo_emissione
                  , to_number (decode(nvl (substr  (ogim.note, 12, 1), '0'),'0','1',nvl (substr  (ogim.note, 12, 1), 0))) num_rate
                  , sum(imposta + nvl(addizionale_pro,0) + nvl(addizionale_eca,0) + nvl(maggiorazione_eca,0) + nvl(iva,0)) importo_ruolo
               from oggetti_imposta ogim
                  , oggetti_pratica ogpr
                  , ruoli
              where ogim.oggetto_pratica = ogpr.oggetto_pratica
                and ogpr.pratica         = a_pratica
                and ruoli.ruolo = to_number(NVL (SUBSTR (ogim.note, 1, 10),0))
              group by to_number (nvl (substr  (ogim.note, 1, 10), 0))
                  , ruoli.tipo_ruolo
                  , ruoli.tipo_emissione
                  , to_number (decode(nvl (substr  (ogim.note, 12, 1), '0'),'0','1',nvl (substr  (ogim.note, 12, 1), 0)))
              order by 2,3)
    loop
        w_num_ruoli := w_num_ruoli + 1;
        t_ruoli_ruolo(w_num_ruoli) := r.ruolo;
        t_ruoli_tipo_ruolo(w_num_ruoli) := r.tipo_ruolo;
        t_ruoli_tipo_emissione(w_num_ruoli) := r.tipo_emissione;
        t_ruoli_num_rate(w_num_ruoli) := r.num_rate;
        --
        -- (VD - 30/01/2018): aggiunto calcolo importo ruolo arrotondato e
        --                    importi rate; memorizzazione di tutti i nuovi
        --                    valori su appositi array
        --
        w_importo_ruolo_arr := round(r.importo_ruolo);
        w_rata_arr          := round(w_importo_ruolo_arr / r.num_rate);
        w_last_rata_arr     := w_importo_ruolo_arr - (w_rata_arr * (r.num_rate - 1));
        w_importo_rata      := round(r.importo_ruolo / r.num_rate,2);
        w_imp_ult_rata      := r.importo_ruolo - (w_importo_rata * (r.num_rate - 1));
        t_importo_rata(w_num_ruoli)  := w_importo_rata;
        t_imp_ult_rata(w_num_ruoli)  := w_imp_ult_rata;
        t_importo_ruolo(w_num_ruoli) := r.importo_ruolo;
        t_imp_rata_arr(w_num_ruoli)  := w_rata_arr;
        t_last_rata_arr(w_num_ruoli) := w_last_rata_arr;
        t_imp_ruolo_arr(w_num_ruoli) := w_importo_ruolo_arr;
    --  dbms_output.put_line('Importo ruolo arr. '||w_importo_ruolo_arr);
   end loop;
   END;
-- dbms_output.put_line('w_num_ruoli '||w_num_ruoli);
--
-- Pulizia Sanzioni Precedenti
--
   BEGIN
      delete from sanzioni_pratica sapr
       where sapr.pratica = a_pratica
      ;
   END;
--
-- Memorizzazione del Versato con relativa Data di Pagamento e Rata.
--
   bInd2 := 0;
   w_tot_versato := 0;
   FOR rec_vers in sel_vers(w_cod_fiscale,w_anno)
   LOOP
      bInd2 := bInd2 + 1;
      t_vers_versato(bInd2)     := rec_vers.importo_versato;
      t_vers_magg_tares(bInd2)  := rec_vers.maggiorazione_tares;
      t_vers_data_pag(bInd2)    := rec_vers.data_pagamento;
      if rec_vers.rata = 0 then
         t_vers_rata(bInd2)     := 1 + rec_vers.delta_rate;
      else
         t_vers_rata(bInd2)     := rec_vers.rata + rec_vers.delta_rate;
      end if;
      w_tot_versato             := w_tot_versato + rec_vers.importo_versato;
      -- dbms_output.put_line('Versamento('||bInd2||').versato '||t_vers_versato(bInd2));
      -- dbms_output.put_line('Versamento('||bInd2||').data_pag '||to_char(t_vers_data_pag(bInd2),'dd/mm/yyyy'));
      -- dbms_output.put_line('Versamento('||bInd2||').vers_rata '||t_vers_rata(bInd2));
   END LOOP;
   w_num_vers := bInd2;
   -- dbms_output.put_line('Tot.versato: '||w_tot_versato||' w_num_vers '||w_num_vers);
--   if bInd2 > 0 then
--      -- dbms_output.put_line(' t_vers('||bInd2||').versato '||t_vers_versato(bInd2));
--      -- dbms_output.put_line(' w_tot_versato '||w_tot_versato);
--   end if;
   -- Estrazione del dato di sgravio + compensazione per tutta la pratica
   w_step := 'c';
   w_i_ruolo := 0;
   LOOP
      w_i_ruolo := w_i_ruolo + 1;
      if w_i_ruolo > w_num_ruoli then
        exit;
      end if;
      --
      BEGIN
        select nvl(sum(impo.sgravio_comp),0) as sgravio_comp_tot,
               nvl(sum(impo.sgravio_tares),0) as sgravio_tares_tot,
               max(impo.rata) as num_rate
          into t_ruoli_sgravio_comp(w_i_ruolo)
             , t_ruoli_sgravio_tares(w_i_ruolo)
             , w_num_rate
          from (
                select ogim.oggetto_pratica,
                  --   ogim.note,
                       (to_number(substr(ogim.note,313,15)) / 100) as sgravio_comp,
                       case when length(ogim.note) >= 472 then
                            to_number(substr(ogim.note,458,15)) / 100
                       else
                         0
                       end as sgravio_tares,
                       to_number(substr(ogim.note,12,1)) as rata
                  from oggetti_imposta ogim,
                       oggetti_pratica ogpr
                 where ogim.oggetto_pratica = ogpr.oggetto_pratica
                   and ogpr.pratica         = a_pratica
                   and to_number(substr(ogim.note,1,10)) = t_ruoli_ruolo(w_i_ruolo)
               ) impo
         ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          t_ruoli_sgravio_comp(w_i_ruolo)  := 0;
          t_ruoli_sgravio_tares(w_i_ruolo) := 0;
          w_num_rate                       := 1;
      END;
   END LOOP;
--
-- Determinazione della Imposta Lorda e della Scadenza.
-- (per ogni ruolo estratto)
--
   w_tot_omesso := 0;
   w_i_ruolo := 0;
   loop
     w_i_ruolo := w_i_ruolo + 1;
     if w_i_ruolo > w_num_ruoli then
        exit;
     end if;
     --
 --  dbms_output.put_line('Sgravio totale: '||t_ruoli_sgravio_comp(w_i_ruolo)||', Sgravio TARES: '||t_ruoli_sgravio_tares(w_i_ruolo));
     if t_ruoli_sgravio_comp(w_i_ruolo) <> 0 then
        w_sgravio_rata     := round(t_ruoli_sgravio_comp(w_i_ruolo) / t_ruoli_num_rate(w_i_ruolo),2);
        w_sgravio_ult_rata := t_ruoli_sgravio_comp(w_i_ruolo) - round(w_sgravio_rata * (t_ruoli_num_rate(w_i_ruolo) - 1),2);
     else
        w_sgravio_rata     := 0;
        w_sgravio_ult_rata := 0;
     end if;
 --  dbms_output.put_line('Sgravio rata: '||w_sgravio_rata||', sgravio ult. rata: '||w_sgravio_ult_rata);
     w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
 --  dbms_output.put_line('Ruolo: '||t_ruoli_ruolo(w_i_ruolo)||', w_rate_analizzate '||w_rate_analizzate);
     i   := w_rate_analizzate;
     LOOP
       i   := i + 1;
       w_ind_ruolo := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
       if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
          exit;
       end if;
    --
    -- In OGIM nelle note sono memorizzati:
    -- * il ruolo nei primi 10 caratteri,
    -- * il numero delle rate scadute alla data di emissione del ruolo di 1 carattere,
    -- * il numero di rate di 1 carattere (0 se non rateizzato)
    -- * 4 elementi di 75 caratteri da intendersi come 5 importi che contengono
    --   la imposta netta rata n
    --   la addizionale ECA rata n
    --   la maggiorazione ECA rata n
    --   la addizionale PRO rata n
    --   la aliquota IVA rata n
    -- * 1 elemento di 75 caratteri da intendersi come 5 importi che contengono
    --   importo totale sgravio e compesnazione
    --   importo arrotondato imposta ogim rata 1 se previsto
    --   importo arrotondato imposta ogim rata 2 se previsto
    --   importo arrotondato imposta ogim rata 3 se previsto
    --   importo arrotondato imposta ogim rata 4 se previsto
    -- * 1 elemento di 10 caratteri con la scadenza ricalcolata o '0         '
    -- * 1 elementi di 75 caratteri da intendersi come 5 importi che contengono
    --   la maggiorazione TARES rata 1
    --   la maggiorazione TARES rata 2
    --   la maggiorazione TARES rata 3
    --   la maggiorazione TARES rata 4
    --   sgravio totale maggiorazione TARES
    -- questi importi sono a zero se non significativi. La imposta viene totalizzata
    -- secondo la rata effettiva di scadenza e non rispettivamente al numero di rata
    -- memorizzato. La non rateizzazione (rata 0) viene accorpata nella prima rata.
    -- La scadenza della prima rata viene ricavata tra la scadenza minore tra rata 0
    -- e rata 1 (a onor del vero entrambe dovrebbero essere uguali).
    --
       BEGIN
       -- se la scadenza è stata ricalcolata (per ruoli TOTALI)
       -- l'ho scritta nell'ultimo campo delle note.
         select case
                  when max(ruol.scadenza_rata_unica) is not null and
                       max(ruol.scadenza_rata_unica) > max(ruol.SCADENZA_PRIMA_RATA) then
                   max(ruol.scadenza_rata_unica)
                  else
                   min(nvl(to_date(decode(substr(ogim.note, 388, 10),
                                          rpad('0', 10),
                                          '',
                                          substr(ogim.note, 388, 10)),
                                   'dd/mm/yyyy'),
                           decode(i - w_rate_analizzate,
                                  1,
                                  ruol.scadenza_prima_rata,
                                  2,
                                  ruol.scadenza_rata_2,
                                  3,
                                  ruol.scadenza_rata_3,
                                  4,
                                  ruol.scadenza_rata_4)))
                end
           into w_scadenza
           from ruoli ruol, oggetti_imposta ogim, oggetti_pratica ogpr
          where ogim.oggetto_pratica = ogpr.oggetto_pratica
            and ogpr.pratica = a_pratica
            and ruol.ruolo = to_number(substr(ogim.note, 1, 10))
            and to_number(substr(ogim.note, 1, 10)) =
                t_ruoli_ruolo(w_i_ruolo);
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             w_scadenza        := to_date('31122999','ddmmyyyy');
       END;
       --
       if w_cod_istat = '049014'-- Portoferraio
          and w_anno = 2013
          and i - w_rate_analizzate = 1 then
       -- Nel 2013 Portoferraio ha notificato avviso di pagamento in alcuni casi dopo la scadenza della
       -- prima rata. Dobbiamo tenerne conto nel calcolo degli interessi: se la rata è la prima
       -- la scadenza diventa la data di notifica e non la data di scadenza effettiva.
       -- la notifica è caricata come contatto di tipo 31 o 72
          w_data_notifica := null;
          begin
            select max(data)
              into w_data_notifica
              from contatti_contribuente
             where cod_fiscale = w_cod_fiscale
               and anno = w_anno
               and tipo_contatto in (31,72)
               and nvl(tipo_tributo,'TARSU') = 'TARSU'
            ;
          exception
            when others then null;
          end;
          if w_data_notifica is null then
             null; -- se non c'è notifica lasciamo tutto come prima
          elsif w_data_notifica <= to_date('31/07/2013','dd/mm/yyyy') then
             w_scadenza := to_date('31/07/2013','dd/mm/yyyy');  -- calcoliamo gli interessi dal 31/7
          else
             w_scadenza := w_data_notifica + 30; -- interessi da 30 gg dopo la notifica
          end if;
       end if;
       --
       BEGIN
          select distinct 1
            into t_ruoli_esiste_acconto(w_i_ruolo)
            from ruoli ruol
           where ruol.invio_consorzio is not null
             and ruol.anno_ruolo = w_anno
             and ruol.tipo_ruolo = 1
             and ruol.tipo_emissione = 'A'
             and t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
             and t_ruoli_tipo_ruolo(w_i_ruolo) = 1;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             t_ruoli_esiste_acconto(w_i_ruolo) := 0;
       END;
       w_step := 'd';
       declare
         w_rata_idx number;
--       w_note varchar2(2000);
       BEGIN
/**
***
        dbms_output.put_line('ruolo '||t_ruoli_ruolo(w_i_ruolo)||' w_scadenza '||w_scadenza);
        dbms_output.put_line('pratica '||a_pratica);
        FOR N IN ( select ogim.note , ogim.oggetto_imposta
                    from oggetti_imposta ogim
                       , oggetti_pratica ogpr
                   where ogim.oggetto_pratica = ogpr.oggetto_pratica
                     and ogpr.pratica         = a_pratica
                     and i - w_rate_analizzate between 1
                                   and to_number(substr(ogim.note,12,1)) +
                                       decode(to_number(substr(ogim.note,12,1)),0,1,0)
                   and to_number(substr(ogim.note,1,10)) = t_ruoli_ruolo(w_i_ruolo))
       LOOP
          DBMS_OUTPUT.PUT_LINE('**** '||N.OGGETTO_IMPOSTA);
          dbms_output.put_line(substr(N.note,1,255));
          --dbms_output.put_line(substr(N.note,256));
       END LOOP;
***
**/
          --
          w_rata_idx := (i - w_rate_analizzate - 1);
          --
          -- Calcola i totali per pratica e ruolo
          -- Se non trova il Totale Arrotondato calcola la somma tra rateazioni e sgravio
          --
          select nvl(sum(decode(to_number(rtrim(substr(ogim.note
                                                  ,(w_rata_idx * 15) + 328
                                                  ,15
                                                  ))) / 100 -- Totale arrotondato (solitamente 0 o nullo)
                          ,null,to_number(substr(ogim.note
                                                ,(w_rata_idx * 75) + 13 + 0
                                                ,15
                                                )) / 100 +  -- Imposta
                                to_number(substr(ogim.note
                                                ,(w_rata_idx * 75) + 13 + 15
                                                ,15
                                                )) / 100 +  -- Add. ECA
                                to_number(substr(ogim.note
                                                ,(w_rata_idx * 75) + 13 + 30
                                                ,15
                                                )) / 100 +  -- Magg. ECA
                                to_number(substr(ogim.note
                                                ,(w_rata_idx * 75) + 13 + 45
                                                ,15
                                                )) / 100 +  -- Add. PRO
                                to_number(substr(ogim.note
                                                ,(w_rata_idx * 75) + 13 + 60
                                                ,15
                                                )) / 100    -- IVA
                           ,nvl(to_number(substr(ogim.note
                                                ,(w_rata_idx * 15) + 328
                                                ,15
                                                )) / 100    -- Totale arrotondato
                              ,0)
                           )
                       ),0
                 ) as imposta
               , nvl(sum(decode(to_number(rtrim(substr(ogim.note,(w_rata_idx * 15) + 398 ,15))) / 100
                          ,null,0
                           ,nvl(to_number(substr(ogim.note,(w_rata_idx * 15) + 398,15)) / 100    -- Magg Tares x Rata
                              ,0)
                           )
                       ),0
                 ) as magg_tares_rata
               , nvl(sum(decode(to_number(rtrim(substr(ogim.note,(w_rata_idx * 15) + 398,15))),null,0,1)),0
                 ) as magg_tares_rata_cnt
               , nvl(sum(nvl(maggiorazione_tares,0)),0) as magg_tares
            into w_imposta
               , w_magg_tares_rata
               , w_magg_tares_rata_cnt
               , w_magg_tares
            from oggetti_imposta ogim
               , oggetti_pratica ogpr
           where ogim.oggetto_pratica = ogpr.oggetto_pratica
             and ogpr.pratica         = a_pratica
             and i - w_rate_analizzate between 1
                                    and to_number(substr(ogim.note,12,1)) +
                                        decode(to_number(substr(ogim.note,12,1)),0,1,0)
             and to_number(substr(ogim.note,1,10)) = t_ruoli_ruolo(w_i_ruolo);
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_imposta             := 0;
            w_magg_tares_rata     := 0;
            w_magg_tares_rata_cnt := 0;
            w_magg_tares          := 0;
         WHEN OTHERS THEN
            W_ERRORE := 'ERRORE RECUPERO IMPOSTA '||TO_CHAR(A_PRATICA)||' '||TO_CHAR(w_ind_ruolo)||' '||SQLERRM;
            RAISE ERRORE;
       END;
       w_step := 'e';
        -- dbms_output.put_line('VD - w_step '||w_step||' w_magg_tares '||w_magg_tares);
        -- dbms_output.put_line('VD - w_step '||w_step||' w_imposta '||w_imposta);
       bInd1                                := w_ind_ruolo;
       --t_tot_imp_tot_imp_orig(bInd1)        := w_imposta - least(w_imposta ,t_ruoli_sgravio_comp(w_i_ruolo));
       --t_tot_imp_tot_imposta(bInd1)         := w_imposta - least(w_imposta ,t_ruoli_sgravio_comp(w_i_ruolo));
       if i < t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
          t_tot_imp_tot_imp_orig(bInd1)     := w_imposta - least(w_imposta ,w_sgravio_rata);
          t_tot_imp_tot_imposta(bInd1)      := w_imposta - least(w_imposta ,w_sgravio_rata);
       else
          t_tot_imp_tot_imp_orig(bInd1)     := w_imposta - least(w_imposta ,w_sgravio_ult_rata);
          t_tot_imp_tot_imposta(bInd1)      := w_imposta - least(w_imposta ,w_sgravio_ult_rata);
       end if;
       t_tot_imp_scadenza(bInd1)            := w_scadenza;
       t_tot_imp_tot_interessi(bInd1)       := 0;
       t_tot_imp_tot_tardivo_30(bInd1)      := 0;
       t_tot_imp_tot_tardivo(bInd1)         := 0;
       t_tot_imp_gg_interessi(bInd1)        := 0;
       t_tot_imp_note_interessi(bInd1)      := ' ';
   --  dbms_output.put_line('t_tot_imposte('||bInd1||').tot_imposta_originale '||t_tot_imp_tot_imp_orig(bInd1));
       --
       if w_magg_tares_rata_cnt > 0 then
         -- Maggiorazione TARES (Componenti Perequative) valorizzate per rata
         if i < t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
            t_magg_tares_tot_imp_orig(bInd1)      := w_magg_tares_rata;
            t_magg_tares_tot_imposta(bInd1)       := w_magg_tares_rata;
         else
            t_magg_tares_tot_imp_orig(bInd1)      := w_magg_tares_rata;
            t_magg_tares_tot_imposta(bInd1)       := w_magg_tares_rata;
         end if;
         t_magg_tares_scadenza(bInd1)          := w_scadenza;
       else
         -- La Maggiorazione TARES va solo sull'ultima rata 'valorizzata'
         if w_scadenza is not null and i - w_rate_analizzate = t_ruoli_num_rate(w_i_ruolo) then
            t_magg_tares_tot_imp_orig(bInd1)      := w_magg_tares;
            t_magg_tares_tot_imposta(bInd1)       := w_magg_tares;
            t_magg_tares_scadenza(bInd1)          := w_scadenza;
         else
            t_magg_tares_tot_imp_orig(bInd1)      := 0;
            t_magg_tares_tot_imposta(bInd1)       := 0;
            t_magg_tares_scadenza(bInd1)          := null;
         end if;
       end if;
       t_magg_tares_tot_tardivo_30(bInd1)       := 0;
       t_magg_tares_tot_tardivo(bInd1)          := 0;
       t_magg_tares_tot_interessi(bInd1)        := 0;
       t_magg_tares_gg_interessi(bInd1)         := 0;
       t_magg_tares_note_interessi(bInd1)       := '';
       w_tot_omesso                             := w_tot_omesso + t_tot_imp_tot_imp_orig(bInd1);
       t_ruoli_sgravio_comp(w_i_ruolo)          := t_ruoli_sgravio_comp(w_i_ruolo)
                                                   - least(w_imposta ,t_ruoli_sgravio_comp(w_i_ruolo));
      END LOOP;
      --
      -- Calcolo Sgravi TARES per Rata
      --
      w_tot_tares := 0;
      w_tot_sgravio_tares := 0;
      --
      i   := w_rate_analizzate;
      LOOP
        i   := i + 1;
        if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
          exit;
        end if;
        bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
        w_tot_tares := w_tot_tares + t_magg_tares_tot_imp_orig(bInd1);
      END LOOP;
  --  dbms_output.put_line('TARES Ruolo: '||t_ruoli_totale_tares(w_i_ruolo)||', Sgravio: '||t_ruoli_sgravio_tares(w_i_ruolo));
      --
      -- Applica Sgravi TARES per Rata
      --
      if w_tot_tares <> 0 then
        i   := w_rate_analizzate;
        LOOP
          i   := i + 1;
          if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
            exit;
          end if;
          bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
          --
      --  dbms_output.put_line('TARES Rata Ruolo: '||t_magg_tares_tot_imp_orig(bInd1));
          w_sgravio_tares := round((t_ruoli_sgravio_tares(w_i_ruolo) * t_magg_tares_tot_imp_orig(bInd1)) / w_tot_tares,2);
          if i = t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
            w_sgravio_tares := t_ruoli_sgravio_tares(w_i_ruolo) - w_tot_sgravio_tares;
        --  dbms_output.put_line('Ultima rata - Sgravio : '||t_ruoli_sgravio_tares(w_i_ruolo)||', contabilizzato: '||w_tot_sgravio_tares);
          end if;
          t_magg_tares_tot_imp_orig(bInd1) := t_magg_tares_tot_imp_orig(bInd1) - w_sgravio_tares;
          t_magg_tares_tot_imposta(bInd1) := t_magg_tares_tot_imposta(bInd1) - w_sgravio_tares;
          w_tot_sgravio_tares := w_tot_sgravio_tares + w_sgravio_tares;
      --  dbms_output.put_line('TARES Rata Ruolo (Sgravio): '||w_sgravio_tares||', Residuo: '||t_magg_tares_tot_imp_orig(bInd1));
        END LOOP;
      end if;
   end loop;
--
-- Determinazione del Versato Tardivo e Omesso.
--
-- Assegnazione degli eventuali versamenti ad ogni rata fino al raggiungimento della imposta.
--
   --w_num_vers = numero dei versamenti
   if w_num_vers > 0 then
      w_i_ruolo := 0;
      LOOP
        w_i_ruolo := w_i_ruolo + 1;
        if w_i_ruolo > w_num_ruoli then
           exit;
        end if;
        --
        -- (VD - 30/01/2018): memorizzazione nuovi valori ruolo in variabili
        --
        w_importo_ruolo_arr := t_imp_ruolo_arr (w_i_ruolo);
        w_importo_rata  := t_importo_rata (w_i_ruolo);
        w_imp_ult_rata  := t_imp_ult_rata (w_i_ruolo);
        w_rata_arr      := t_imp_rata_arr (w_i_ruolo);
        w_last_rata_arr := t_last_rata_arr (w_i_ruolo);
         -- dbms_output.put_line('w_rata_arr: '||w_rata_arr||', w_ult_rata_arr: '||w_last_rata_arr);
        w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
        i := w_rate_analizzate;
        LOOP
            i   := i + 1;
            -- dbms_output.put_line('I: '||i);
            bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
            if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
               exit;
            end if;
            w_imposta := t_tot_imp_tot_imposta(bInd1);
            w_magg_tares := t_magg_tares_tot_imposta(bInd1);
            if w_imposta > 0 then
               bInd2 := 0;
                LOOP
                   bInd2 := bInd2 + 1;
                   if bInd2 > w_num_vers then
                     exit;
                   end if;
                   -- dbms_output.put_line('preprepre '||bInd1||' t_vers('||bInd2||').rata '||t_vers_rata(bInd2)||' '||t_vers_versato(bInd2));
                   -- dbms_output.put_line('*** t_tot_imp('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
                   -- (VD - 10/05/2018): aggiunto test su totale imposta dovuta per non creare valori negativi nella imposta dovuta
                   if t_vers_versato(bInd2) <> 0 /*and t_vers_rata(bInd2) = i*/ and t_tot_imp_tot_imposta(bInd1) > 0 then
                   -- dbms_output.put_line('postpostpost '||bInd1||' bInd2 '||bInd2);
                      w_versato := t_vers_versato(bInd2);
                      if w_flag_cope > 0 and w_versato <> 0 then
                        -- Componenti Pereqautive : al momento il versato fa parte del totale. Scorpora.
                        w_versato_magg_tares := t_vers_magg_tares(bInd2);
                    --  dbms_output.put_line('Dovuto Imp.: '||w_imposta||', dovuto TARES: '||w_magg_tares);
                    --  dbms_output.put_line('Versato Imp.: '||w_versato||', versato TARES: '||w_versato_magg_tares);
                        if w_versato_magg_tares = 0 then
                          w_versato_magg_tares := round((w_versato * w_magg_tares) / (w_imposta + w_magg_tares),2);
                          if ((w_magg_tares - w_versato_magg_tares) < 0.05) or 
                            (w_versato_magg_tares > w_magg_tares) then
                            w_versato_magg_tares := w_magg_tares;
                          end if;
                          w_versato := w_versato - w_versato_magg_tares;
                          t_vers_versato(bInd2) := w_versato;
                          t_vers_magg_tares(bInd2) := w_versato_magg_tares;
                        end if;
                      end if;
                      -- (VD - 10/05/2018): aggiunta determinazione importo arrotondato
                      w_versato_arr := round(w_versato);
                      if w_versato > round(w_imposta) then
                         w_versato := w_imposta;
                         w_versato_arr := w_imposta;
                      /*else
                         --
                         -- (VD - 30/01/2018): se il versato è superiore all'importo della rata, si utilizza
                         --                    quest'ultimo come parametro di confronto
                         --
                         if t_vers_rata(bInd2) = t_ruoli_num_rate(w_i_ruolo) and w_versato > w_imp_ult_rata then
                            w_versato := w_imp_ult_rata;
                            w_versato_arr := w_last_rata_arr;
                         elsif t_vers_rata(bInd2) <> t_ruoli_num_rate(w_i_ruolo) and w_versato > w_importo_rata then
                            w_versato := w_importo_rata;
                            w_versato_arr := w_rata_arr;
                         end if; */
                         -- dbms_output.put_line('Versato: '||w_versato||', versato arr. '||w_versato_arr);
                      end if;
                      --Se il pagamento è successivo alla scadenza
                      if t_vers_data_pag(bInd2) > t_tot_imp_scadenza(bInd1) then
                         w_data_pag             := t_vers_data_pag(bInd2);
                         w_anno_scadenza        := to_number(to_char(w_scadenza,'yyyy'));
                         w_scadenza             := t_tot_imp_scadenza(bInd1);
                         -- dbms_output.put_line('Scadenza '||w_scadenza);
                         w_diff_giorni          := w_data_pag + 1 - w_scadenza;
                      else
                         w_diff_giorni          := 0;
                      end if;
                      -- dbms_output.put_line('Diff.giorni '||w_diff_giorni);
                      --if bInd2 = 3 then
                      --w_errore := 'Diff.giorni: '||to_char(w_diff_giorni)||' Imposta: '||to_char(w_imposta)||' Versato: '||to_char(w_versato);
                      --raise errore;
                      --end if;
                       -- dbms_output.put_line('+++++++++++++++++++++++++++ t_vers('||bInd2||').versato '||t_vers_versato(bInd2));
                       -- dbms_output.put_line('+++++++++++++++++++++++++++ t_tot_imposte('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
                       -- dbms_output.put_line('w_versato: '||w_versato);
                      --
                      -- (VD - 30/01/2018): Se il residuo di imposta è inferiore all'euro, significa
                      --                    che l'importo del versamento era arrotondato, quindi
                      --                    non vanno considerati eventuali residui
                      --
                      if abs(w_imposta - w_versato) < 1 then
                         t_tot_imp_tot_imposta(bInd1) := 0;
                      else
                         t_tot_imp_tot_imposta(bInd1) := greatest(0,w_imposta - w_versato);
                      end if;
                      -- (VD - 10/05/2018): aggiornamento variabile w_imposta
                      w_imposta := t_tot_imp_tot_imposta(bInd1);
                      -- dbms_output.put_line('* t_tot_imp('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
                      -- 29/04/2014 SC se per l'ultima rata mi è rimasto meno di un euro, annullo perchè significa
                      -- che l'importo chiesto era stato arrotondato per difetto, ma l'hanno pagato tutto.
                      --
                      -- (VD - 30/01/2018): test non piu necessario per modifiche precedenti
                      --
                      --  if t_tot_imp_tot_imposta(bInd1) < 1 and t_ruoli_num_rate(w_i_ruolo) = i then
                      --     t_tot_imp_tot_imposta(bInd1) := 0;
                      --  end if;
                      --
                      -- 29/04/2014 SC se mi sono rimasti meno di 50 centesimi di versato lo annullo per non spalmarlo sulle altre rate.
                      --
                      -- (VD - 30/01/2018): modificato test per importi arrotondati
                      --
--                      if round(t_vers_versato(bInd2) - w_versato,0) = 0 then
-- dbms_output.put_line('VD - Vers.tabella '||t_vers_versato(bInd2)||', w_versato '||w_versato);
                      if abs(t_vers_versato(bInd2) - w_versato) < 1 then
                         t_vers_versato(bInd2) := 0;
                      else
                         t_vers_versato(bInd2) := t_vers_versato(bInd2) - w_versato_arr;
                      end if;
                      --
                      --  (VD - 30/01/2018): se il totale versato (anche con importi
                      --                     rata diversi da quelli previsti)
                      --                     concide con il totale del ruolo arrotondato,
                      --                     si azzera l'eventuale versamento residuo
                      --
                      --if t_vers_rata(bInd2) = t_ruoli_num_rate(w_i_ruolo) and
                      --   w_tot_versato = w_importo_ruolo_arr then
                      --   t_vers_versato(bInd2) := 0;
                      --end if;
                       -- dbms_output.put_line('-------------------------- t_vers('||bInd2||').versato '||t_vers_versato(bInd2));
                      -- Verifica gestione Tardivi Versamenti
                      if w_flag_no_tardivo = 'N' then  -- Gestione tardivo versamento
                         if w_diff_giorni > 0 then
                            if w_diff_giorni > 30 then
                               t_tot_imp_tot_tardivo(bInd1) := t_tot_imp_tot_tardivo(bInd1) + w_versato;
                            else
                               t_tot_imp_tot_tardivo_30(bInd1) := t_tot_imp_tot_tardivo_30(bInd1) + w_versato;
                            end if;
                         --
                         -- Interessi.
                         --
                            w_lordo     := w_versato;
                            if w_flag_int = 'N' then
                               w_lordo := F_TROVA_NETTO(w_lordo,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
                            end if;
                            if w_lordo > 0 then
                                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza+1,w_data_pag,365,'TARSU');
                                 -- dbms_output.put_line('interessi per '||bInd1||': '||w_interessi);
                                -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                                t_tot_imp_note_interessi(bInd1) := substr(ltrim(t_tot_imp_note_interessi(bInd1)||chr(10)||chr(13)||
                                                                'In: '||to_char(round(w_interessi,2))||' gg: '||to_char(w_data_pag - w_scadenza)||
                                                                ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                                ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(round(w_lordo,2))||' - '
                                                                ),1,2000);
                                if t_tot_imp_gg_interessi(bInd1) = 0 or t_tot_imp_gg_interessi(bInd1) is null then
                                   t_tot_imp_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                                else
                                   t_tot_imp_gg_interessi(bInd1) := null;
                                end if;
                                t_tot_imp_tot_interessi(bInd1) := t_tot_imp_tot_interessi(bInd1) + w_interessi;
                                -- dbms_output.put_line('interessi per t_tot_imposte('||bInd1||').tot_interessi: '||t_tot_imp_tot_interessi(bInd1));
                            end if;
                         end if;
                      end if;
                   end if;
                END LOOP;
            end if;
            w_interessi := 0;
            if w_flag_sanz_magg_tares > 0 then
                w_magg_tares := t_magg_tares_tot_imposta(bInd1);
                if w_magg_tares > 0 then
                   bInd2 := 0;
                    LOOP
                       bInd2 := bInd2 + 1;
                       if bInd2 > w_num_vers then
                         exit;
                       end if;
                       -- dbms_output.put_line('t_vers(bInd2).magg_tares '||t_vers_magg_tares(bInd2));
                       -- dbms_output.put_line('t_vers(bInd2).rata '||t_vers_rata(bInd2));
                       if t_vers_rata(bInd2) = to_number(substr(lpad(bInd1,12,'0'), 12)) and t_vers_magg_tares(bInd2) <> 0 then
                          w_versato_magg_tares := t_vers_magg_tares(bInd2);
                          if w_versato_magg_tares > w_magg_tares then
                             w_versato_magg_tares := w_magg_tares;
                          end if;
                          --Se il pagamento è successivo alla scadenza
                          if t_vers_data_pag(bInd2) > t_magg_tares_scadenza(bInd1) then
                             w_data_pag          := t_vers_data_pag(bInd2);
                             w_anno_scadenza     := to_number(to_char(w_scadenza,'yyyy'));
                             w_scadenza          := t_magg_tares_scadenza(bInd1);
                             w_diff_giorni       := w_data_pag + 1 - w_scadenza;
                          else
                             w_diff_giorni       := 0;
                          end if;
                          t_magg_tares_tot_imposta(bInd1) := t_magg_tares_tot_imposta(bInd1) - w_versato_magg_tares;
                          t_vers_magg_tares(bInd2)        := t_vers_magg_tares(bInd2)        - w_versato_magg_tares;
                          w_magg_tares                    := w_magg_tares                    - w_versato_magg_tares;
                          -- dbms_output.put_line('vers '||bInd2||' resta da pagare w_magg_tares '||w_magg_tares||' w_diff_giorni '||w_diff_giorni);
                          -- Verifica gestione Tardivi Versamenti
                          if w_flag_no_tardivo = 'N' then  -- Gestione tardivo versamento
                             if w_diff_giorni > 0 then
                                if w_diff_giorni > 30 then
                                   t_magg_tares_tot_tardivo(bInd1) := t_magg_tares_tot_tardivo(bInd1) + w_versato_magg_tares;
                                else
                                   t_magg_tares_tot_tardivo_30(bInd1) := t_magg_tares_tot_tardivo_30(bInd1) + w_versato_magg_tares;
                                end if;
                             --
                             -- Interessi.
                             --
                                w_lordo     := w_versato_magg_tares;
                                if w_lordo > 0 then
                                    w_interessi_magg_tares := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza+1,w_data_pag,365,'TARSU');
                                    -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                                    t_magg_tares_note_interessi(bInd1) := substr(ltrim(t_magg_tares_note_interessi(bInd1)||chr(10)||chr(13)||
                                                                        'In: '||round(w_interessi_magg_tares,2)||' gg: '||to_char((w_data_pag - w_scadenza))||
                                                                        ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                                        ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(w_lordo)||' - '
                                                                       ),1,2000);
                                    if t_magg_tares_gg_interessi(bInd1) = 0 or t_magg_tares_gg_interessi(bInd1) is null then
                                       t_magg_tares_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                                    else
                                      t_magg_tares_gg_interessi(bInd1) := null;
                                    end if;
                                    -- dbms_output.put_line('t_magg_tares('||bInd1||').note_interessi '||t_magg_tares_note_interessi(bInd1)) ;
                                    t_magg_tares_tot_interessi(bInd1) := t_magg_tares_tot_interessi(bInd1) + w_interessi_magg_tares;
                                end if;
                             end if;
                          end if;
                       end if;
                    END LOOP;
                end if;
            end if;
        END LOOP;
      END LOOP;
      w_step := 'f';
      -- dbms_output.put_line('w_step '||w_step);
   --
   -- Compensazione di eventuali pagamenti in eccesso  su altre Rate.
   --
      w_i_ruolo := 0;
      LOOP
        w_i_ruolo := w_i_ruolo + 1;
        if w_i_ruolo > w_num_ruoli then
           exit;
        end if;
        w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
        i   := w_rate_analizzate;
        LOOP
            i   := i + 1;
            bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
            if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
               exit;
            end if;
            w_imposta := t_tot_imp_tot_imposta(bInd1);
            if w_imposta > 0 then
                bInd2 := 0;
                LOOP
                   bInd2 := bInd2 + 1;
                   if bInd2 > w_num_vers then
                      exit;
                   end if;
                    -- dbms_output.put_line(' rata numero '||bInd1);
                    -- dbms_output.put_line('versamento n. '||bInd2 );
                    -- dbms_output.put_line('t_vers('||bInd2||').data_pag '||t_vers_data_pag(bInd2));
                    -- dbms_output.put_line('t_tot_imposte('||bInd1||').scadenza '||t_tot_imp_scadenza(bInd1));
                    -- dbms_output.put_line('t_vers('||bInd2||').versato '||t_vers_versato(bInd2));
                    -- dbms_output.put_line('t_tot_imposte('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
                   if t_vers_versato(bInd2) <> 0 then
                      w_versato := t_vers_versato(bInd2);
                      if w_versato > w_imposta then
                         w_versato := w_imposta;
                      end if;
                       -- dbms_output.put_line('t_vers('||bInd2||').data_pag '||t_vers_data_pag(bInd2));
                       -- dbms_output.put_line('t_tot_imposte('||bInd1||').scadenza '||t_tot_imp_scadenza(bInd1));
                      if t_vers_data_pag(bInd2) > t_tot_imp_scadenza(bInd1) then
                         w_data_pag      := t_vers_data_pag(bInd2);
                         w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
                         w_scadenza      := t_tot_imp_scadenza(bInd1);
                         w_diff_giorni   := w_data_pag + 1 - w_scadenza;
                      else
                         w_diff_giorni   := 0;
                      end if;
                      -- dbms_output.put_line('---------------------- w_diff_giorni '||w_diff_giorni);
                      t_tot_imp_tot_imposta(bInd1) := t_tot_imp_tot_imposta(bInd1) - w_versato;
                      t_vers_versato(bInd2) := t_vers_versato(bInd2) - w_versato;
                      w_imposta             := w_imposta             - w_versato;
                      -- dbms_output.put_line('vers '||bInd2||' A resta da pagare w_imposta '||w_imposta);
                      -- Verifica gestione Tardivi Versamenti
                      if w_flag_no_tardivo = 'N' then  -- Gestione tardivo versamento
                         if w_diff_giorni > 0 then
                            if w_diff_giorni > 30 then
                               t_tot_imp_tot_tardivo(bInd1) := t_tot_imp_tot_tardivo(bInd1) + w_versato;
                            else
                               t_tot_imp_tot_tardivo_30(bInd1) := t_tot_imp_tot_tardivo_30(bInd1) + w_versato;
                            end if;
                             -- dbms_output.put_line('---------------------- t_tot_imposte(bInd1).tot_tardivo '||t_tot_imp_tot_tardivo(bInd1));
                             -- dbms_output.put_line('---------------------- t_tot_imposte(bInd1).tot_tardivo_30 '||t_tot_imp_tot_tardivo_30(bInd1));
                            --
                            -- Interessi.
                            --
                            w_lordo     := w_versato;
                            if w_flag_int = 'N' then
                               w_lordo := F_TROVA_NETTO(w_lordo,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
                            end if;
                            if w_lordo > 0 then
                                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza +1,w_data_pag,365,'TARSU');
                                 -- dbms_output.put_line('---------------------- w_interessi '||w_interessi);
                                t_tot_imp_tot_interessi(bInd1) := t_tot_imp_tot_interessi(bInd1) + w_interessi;
                                -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                                t_tot_imp_note_interessi(bInd1) := substr(ltrim(t_tot_imp_note_interessi(bInd1)||chr(10)||chr(13)||
                                                                'In: '||to_char(round(w_interessi,2))||' gg: '||to_char(w_data_pag - w_scadenza)||
                                                                ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                                ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(round(w_lordo,2))||' - '
                                                                ),1,2000);
                                if t_tot_imp_gg_interessi(bInd1) = 0 or t_tot_imp_gg_interessi(bInd1) is null then
                                   t_tot_imp_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                                else
                                   t_tot_imp_gg_interessi(bInd1) := null;
                                end if;
                               --
                               --  VD (11/11/2014): eliminata totalizzazione errata (vengono sommati gli interessi ai giorni)
                               --                   la totalizzazione degli interessi e' posizionata immediatamente dopo il calcolo
                               --  t_tot_imp_gg_interessi(bInd1) := t_tot_imp_gg_interessi(bInd1) + w_interessi;
                               --
                            end if;
                         end if;
                      end if;
                   end if;
                END LOOP;
            end if;
            if w_flag_sanz_magg_tares > 0 then
                w_imposta := t_magg_tares_tot_imposta(bInd1);
                if w_imposta > 0 then
                    bInd2 := 0;
                    LOOP
                       bInd2 := bInd2 + 1;
                       if bInd2 > w_num_vers then
                          exit;
                       end if;
                       if t_vers_magg_tares(bInd2) <> 0 then
                          w_versato_magg_tares := t_vers_magg_tares(bInd2);
                          if w_versato_magg_tares > w_imposta then
                             w_versato_magg_tares := w_imposta;
                          end if;
                          if t_vers_data_pag(bInd2) > t_magg_tares_scadenza(bInd1) then
                             w_data_pag      := t_vers_data_pag(bInd2);
                             w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
                             w_scadenza      := t_magg_tares_scadenza(bInd1);
                             w_diff_giorni   := w_data_pag + 1 - w_scadenza;
                          else
                             w_diff_giorni   := 0;
                          end if;
                          -- dbms_output.put_line('entro nel calcolo interessi magg tares w_data_pag '||w_data_pag);
                          -- dbms_output.put_line('entro nel calcolo interessi magg tares w_scadenza '||w_scadenza);
                          -- dbms_output.put_line('entro nel calcolo interessi magg tares w_diff_giorni '||w_diff_giorni);
                          t_magg_tares_tot_imposta(bInd1) := t_magg_tares_tot_imposta(bInd1) - w_versato_magg_tares;
                          t_vers_magg_tares(bInd2)        := t_vers_magg_tares(bInd2)        - w_versato_magg_tares;
                          w_imposta                       := w_imposta                       - w_versato_magg_tares;
                          -- dbms_output.put_line('vers '||bInd2||' B resta da pagare w_imposta '||w_imposta);
                          -- Verifica gestione Tardivi Versamenti
                          if w_flag_no_tardivo = 'N' then  -- Gestione tardivo versamento
                             if w_diff_giorni > 0 then
                                if w_diff_giorni > 30 then
                                   t_magg_tares_tot_tardivo(bInd1) := t_magg_tares_tot_tardivo(bInd1) + w_versato_magg_tares;
                                else
                                   t_magg_tares_tot_tardivo_30(bInd1) := t_magg_tares_tot_tardivo_30(bInd1) + w_versato_magg_tares;
                                end if;
                                --
                                -- Interessi.
                                --
                                w_lordo     := w_versato_magg_tares;
                                if w_lordo > 0 then
                                    w_interessi_magg_tares := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza +1,w_data_pag,365,'TARSU');
                                    -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                                    t_magg_tares_tot_interessi(bInd1) := t_magg_tares_tot_interessi(bInd1) + w_interessi_magg_tares;
                                    t_magg_tares_note_interessi(bInd1) := substr(ltrim(t_magg_tares_note_interessi(bInd1)||chr(10)||chr(13)||
                                                                        'In: '||round(w_interessi_magg_tares,2)||' gg: '||to_char((w_data_pag - w_scadenza))||
                                                                        ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                                        ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(w_lordo)||' - '
                                                                       ),1,2000);
                                    if t_magg_tares_gg_interessi(bInd1) = 0 or t_magg_tares_gg_interessi(bInd1) is null then
                                       t_magg_tares_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                                    else
                                       t_magg_tares_gg_interessi(bInd1) := null;
                                    end if;
                                    --
                                    --  VD (11/11/2014): eliminata totalizzazione errata (vengono sommati gli interessi ai giorni)
                                    --                   la totalizzazione degli interessi e' posizionata immediatamente dopo il calcolo
                                    --  t_magg_tares_gg_interessi(bInd1) := t_magg_tares_gg_interessi(bInd1) + w_interessi_magg_tares;
                                end if;
                             end if;
                             -- dbms_output.put_line('t_magg_tares('||bInd1||').note_interessi '||t_magg_tares_note_interessi(bInd1)) ;
                          end if;
                       end if;
                    END LOOP;
                end if;
            end if;
        END LOOP;
      END LOOP;
      w_step := 'g';
      -- dbms_output.put_line('w_step '||w_step);
   --
   -- Determinazione di eventuali eccedenze di pagamento sulle rate e
   -- Calcolo degli interessi.
   -- Se esistono eccedenze di pagamento la Imposta diventa negativa.
   --
      w_i_ruolo := 0;
      LOOP
        w_i_ruolo := w_i_ruolo + 1;
        if w_i_ruolo > w_num_ruoli then
           exit;
        end if;
         -- dbms_output.put_line('ECCEDENZE RUOLO '||t_ruoli_ruolo(w_i_ruolo));
        w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
        i   := w_rate_analizzate;
        LOOP
            i   := i + 1;
            bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10, 0)||'0'||(i);
            if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
               exit;
            end if;
            w_imposta := t_tot_imp_tot_imposta(bInd1);
            -- dbms_output.put_line('ECCEDENZE t_tot_imposte('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
            bInd2 := 0;
            LOOP
                bInd2 := bInd2 + 1;
                if bInd2 > w_num_vers then
                   exit;
                end if;
                if /*t_vers(bInd2).rata = i and*/ t_vers_versato(bInd2) <> 0 then
                   w_versato := t_vers_versato(bInd2);
                   -- dbms_output.put_line('ECCEDENZE t_vers('||bInd2||').versato '||t_vers_versato(bInd2));
                   if trunc(sysdate) > t_tot_imp_scadenza(bInd1) then
                      w_data_pag          := trunc(sysdate);
                      w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
                      w_scadenza      := t_vers_data_pag(bInd2);
                      --
                      -- gestione interessi tramite parametri di ingresso
                      --
                      if a_interessi_dal is not null and a_interessi_al is not null then
                         w_data_pag      := a_interessi_al;
                         w_scadenza      := a_interessi_dal - 1;
                      end if;
                      w_diff_giorni   := w_data_pag + 1 - w_scadenza;
                   else
                      w_diff_giorni   := 0;
                   end if;
                   t_tot_imp_tot_imposta(bInd1) := t_tot_imp_tot_imposta(bInd1) - w_versato;
                   t_vers_versato(bInd2)        := t_vers_versato(bInd2)        - w_versato;
                   w_imposta                    := w_imposta                    - w_versato;
                   -- dbms_output.put_line('ECCEDENZE t_tot_imposte('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
                   -- dbms_output.put_line('ECCEDENZE imposta MENO VERSATO '||w_imposta);
                   if w_diff_giorni > 0 then
                   --
                   -- Interessi.
                   --
                      w_lordo     := w_versato;
                      if w_flag_int = 'N' then
                         w_lordo := F_TROVA_NETTO(w_lordo,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
                      end if;
                      if w_lordo > 0 then
                          w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_lordo * -1,w_scadenza +1,w_data_pag,365,'TARSU');
                          --
                          -- VD (11/11/2014): Aggiunta totalizzazione interessi
                          --
                          t_tot_imp_tot_interessi(bInd1) := t_tot_imp_tot_interessi(bInd1) + w_interessi;
                          -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                          if nvl(t_tot_imp_note_interessi(bInd1), ' ') <> ' '  and nvl(w_interessi, 0) > 0 then
                             t_tot_imp_note_interessi(bInd1) := t_tot_imp_note_interessi(bInd1)||chr(10)||chr(13);
                          else
                             t_tot_imp_note_interessi(bInd1) := ' ';
                          end if;
                          t_tot_imp_note_interessi(bInd1) := substr(ltrim(t_tot_imp_note_interessi(bInd1)||chr(10)||chr(13)||
                                                          'In: '||to_char(round(w_interessi,2))||' gg: '||to_char(w_data_pag - w_scadenza)||
                                                          ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                          ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(round(w_lordo,2))||' - '
                                                          ),1,2000);
                          if t_tot_imp_gg_interessi(bInd1) = 0 or t_tot_imp_gg_interessi(bInd1) is null then
                             t_tot_imp_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                          else
                             t_tot_imp_gg_interessi(bInd1) := null;
                          end if;
                          --
                          -- VD (11/11/2014): eliminata totalizzazione errata (vengono sommati gli interessi ai giorni)
                          --                  la totalizzazione degli interessi e' posizionata immediatamente dopo il calcolo
                          -- t_tot_imp_gg_interessi(bInd1) := t_tot_imp_gg_interessi(bInd1) + w_interessi;
                      end if;
                   end if;
                end if;
            END LOOP;
            if w_flag_sanz_magg_tares > 0 then
                w_imposta := t_magg_tares_tot_imposta(bInd1);
                --dbms_output.put_line('t_magg_tares('||bInd1||').tot_imposta '||t_magg_tares_tot_imposta(bInd1));
                bInd2 := 0;
                LOOP
                    bInd2 := bInd2 + 1;
                    if bInd2 > w_num_vers then
                       exit;
                    end if;
                    if t_vers_rata(bInd2) = to_number(substr(lpad(bInd1,12,'0'),12)) and t_vers_magg_tares(bInd2) <> 0 then
                       w_versato_magg_tares := t_vers_magg_tares(bInd2);
                       if nvl(w_versato_magg_tares, 0) > w_imposta then
                          w_versato_magg_tares := w_imposta;
                       end if;
                       if trunc(sysdate) > t_magg_tares_scadenza(bInd1) then
                          w_data_pag      := trunc(sysdate);
                          w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
                          w_scadenza      := t_vers_data_pag(bInd2);
                          --
                          -- gestione interessi tramite parametri di ingresso
                          --
                          if a_interessi_dal is not null and a_interessi_al is not null then
                             w_data_pag      := a_interessi_al;
                             w_scadenza      := a_interessi_dal - 1;
                          end if;
                          w_diff_giorni   := w_data_pag + 1 - w_scadenza;
                       else
                          w_diff_giorni   := 0;
                       end if;
                       t_magg_tares_tot_imposta(bInd1) := t_magg_tares_tot_imposta(bInd1) - w_versato_magg_tares;
                       t_vers_magg_tares(bInd2)        := t_vers_magg_tares(bInd2)        - w_versato_magg_tares;
                       w_imposta                       := w_imposta                       - w_versato_magg_tares;
                       -- dbms_output.put_line('vers '||bInd2||' C resta da pagare w_imposta '||w_imposta);
                       if w_diff_giorni > 0 then
                       --
                       -- Interessi.
                       --
                          w_lordo     := w_versato_magg_tares;
                          if w_lordo > 0 then
                              w_interessi_magg_tares := F_CALCOLO_INTERESSI_GG_TITR(w_lordo * -1,w_scadenza +1,w_data_pag,365,'TARSU');
                              --
                              -- VD (11/11/2014): Aggiunta totalizzazione interessi
                              --
                              t_magg_tares_tot_interessi(bInd1) := t_magg_tares_tot_interessi(bInd1) + w_interessi_magg_tares;
                              -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
                              if nvl(t_magg_tares_note_interessi(bInd1), ' ') <> ' '  and nvl(w_interessi_magg_tares, 0) > 0 then
                                 t_magg_tares_note_interessi(bInd1) := t_magg_tares_note_interessi(bInd1)||chr(10)||chr(13);
                              else
                                 t_magg_tares_note_interessi(bInd1) := ' ';
                              end if;
                              t_magg_tares_note_interessi(bInd1) := substr(ltrim(t_magg_tares_note_interessi(bInd1)||chr(10)||chr(13)||
                                                                  'In: '||round(w_interessi_magg_tares,2)||' gg: '||to_char((w_data_pag - w_scadenza))||
                                                                  ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                                  ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(w_lordo)||' - '
                                                                 ),1,2000);
                              if t_magg_tares_gg_interessi(bInd1) = 0 or t_magg_tares_gg_interessi(bInd1) is null then
                                 t_magg_tares_gg_interessi(bInd1) := w_data_pag - w_scadenza;
                              else
                                 t_magg_tares_gg_interessi(bInd1) := null;
                              end if;
                              --
                              -- VD (11/11/2014): eliminata totalizzazione errata (vengono sommati gli interessi ai giorni)
                              --                  la totalizzazione degli interessi e' posizionata immediatamente dopo il calcolo
                              -- t_magg_tares_gg_interessi(bInd1) := t_magg_tares_gg_interessi(bInd1) + w_interessi_magg_tares;
                          end if;
                       end if;
                    end if;
                END LOOP;
            end if;
        END LOOP;
      END LOOP;
   end if;
   w_step := 'h';
   -- dbms_output.put_line('w_step '||w_step);
--
-- Interessi sull`Omesso.
--
  w_i_ruolo := 0;
   LOOP
     w_i_ruolo := w_i_ruolo + 1;
     if w_i_ruolo > w_num_ruoli then
        exit;
     end if;
     w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
     i   := w_rate_analizzate;
     LOOP
        i   := i + 1;
        bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
        if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
           exit;
        end if;
        w_imposta := t_tot_imp_tot_imposta(bInd1);
        --dbms_output.put_line('  t_tot_imposte('||bInd1||').tot_imposta '||t_tot_imp_tot_imposta(bInd1));
        if w_imposta > 0 then
           w_lordo := w_imposta;
        else
           w_lordo := 0;
        end if;
        w_data_pag      := trunc(sysdate);
        w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
        w_scadenza      := t_tot_imp_scadenza(bInd1);
        --
        -- gestione interessi tramite parametri di ingresso
        --
        if a_interessi_dal is not null and a_interessi_al is not null then
           w_data_pag      := a_interessi_al;
           w_scadenza      := a_interessi_dal - 1;
        end if;
        w_diff_giorni   := w_data_pag + 1 - w_scadenza;
        if w_diff_giorni > 0 /*and w_versato > 0*/ then
           --
           -- Interessi.
           --
           if w_flag_int = 'N' then
              w_lordo := F_TROVA_NETTO(w_lordo,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
           end if;
           if w_lordo > 0 then
           --if w_cod_istat = '049011' then
               w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza +1,w_data_pag,365,'TARSU');
               --else
                    --w_interessi := F_CALCOLO_INTERESSI('TARSU',w_lordo,w_scadenza,w_data_pag,w_semestri);
               --end if;
               -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
               t_tot_imp_note_interessi(bInd1) := substr(ltrim(t_tot_imp_note_interessi(bInd1)||chr(10)||chr(13)||
                                                'In: '||to_char(round(w_interessi,2))||' gg: '||to_char(w_data_pag - w_scadenza)||
                                                ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(round(w_lordo,2))||' - '
                                               ),1,2000);
               if t_tot_imp_gg_interessi(bInd1) = 0 or t_tot_imp_gg_interessi(bInd1) is null then
                  t_tot_imp_gg_interessi(bInd1) := w_data_pag - w_scadenza;
               else
                  t_tot_imp_gg_interessi(bInd1) := null;
               end if;
               t_tot_imp_tot_interessi(bInd1) := t_tot_imp_tot_interessi(bInd1) + w_interessi;
           end if;
        end if;
        if w_flag_sanz_magg_tares > 0 then
            w_imposta := t_magg_tares_tot_imposta(bInd1);
            -- dbms_output.put_line('w_imposta '||w_imposta) ;
            if w_imposta > 0 then
               w_lordo := w_imposta;
            else
               w_lordo := 0;
            end if;
            w_data_pag      := trunc(sysdate);
            w_anno_scadenza := to_number(to_char(w_scadenza,'yyyy'));
            w_scadenza      := t_magg_tares_scadenza(bInd1);
            --
            -- gestione interessi tramite parametri di ingresso
            --
            if a_interessi_dal is not null and a_interessi_al is not null then
               w_data_pag      := a_interessi_al;
               w_scadenza      := a_interessi_dal - 1;
            end if;
            w_diff_giorni := w_data_pag + 1 - w_scadenza;
            -- dbms_output.put_line('Interessi Maggiorazione TARES bInd1: '||bInd1);
            -- dbms_output.put_line('w_lordo '||w_lordo) ;
            -- dbms_output.put_line('w_diff_giorni '||w_diff_giorni) ;
            if w_diff_giorni > 0 and w_lordo > 0 then
            --
            -- Interessi.
            --
               --w_lordo     := w_versato_magg_tares; Questa l'ho commentata perchè non ha senso (Piero)
               w_interessi_magg_tares := F_CALCOLO_INTERESSI_GG_TITR(w_lordo,w_scadenza +1,w_data_pag,365,'TARSU');
               -- dbms_output.put_line('w_interessi_magg_tares '||w_interessi_magg_tares) ;
               -- prima di annullare i gg di interesse e di sommare i valori, li salvo sulle note per dare modo di risalire al calcolo
               t_magg_tares_note_interessi(bInd1) := substr(ltrim(t_magg_tares_note_interessi(bInd1)||chr(10)||chr(13)||
                                                    'In: '||round(w_interessi_magg_tares,2)||' gg: '||to_char((w_data_pag - w_scadenza))||
                                                    ' dal: '||to_char(w_scadenza + 1,'dd/mm/yyyy')||
                                                    ' al: '||to_char(w_data_pag,'dd/mm/yyyy')||' base: '||to_char(w_lordo)||' - '
                                                  ),1,2000);
               if t_magg_tares_gg_interessi(bInd1) = 0 or t_magg_tares_gg_interessi(bInd1) is null then
                  t_magg_tares_gg_interessi(bInd1) := w_data_pag - w_scadenza;
               else
                  t_magg_tares_gg_interessi(bInd1) := null;
               end if;
               t_magg_tares_tot_interessi(bInd1) := t_magg_tares_tot_interessi(bInd1) + w_interessi_magg_tares;
            end if;
            -- dbms_output.put_line('t_magg_tares(bInd1).note_interessi '||t_magg_tares_note_interessi(bInd1)) ;
        end if;
     END LOOP;
   END LOOP;
--
-- Se l`accertamento si riferisce a ruoli differenti ,
-- si accorpano le eventuali rate nella prima per evitare di creare caos per chi opera.
-- Come scadenza unica viene utilizzata la sysdate,
-- in questo modo non dovrebbero uscire tardivi versamenti e interessi
-- In caso contrario, si spostano gli elementi delle rate nei primi elementi delle tabelle.
-- Qui non gestisco la magg tares perchè introdotta nel 2013
-- PER RIVOLI NON FACCIAMO IL GIRO: VISTO CHE ASSEGNANO LE DATE DOVREMMO AVER CALCOLATO TUTTO GIUSTO
--   if w_num_ruoli > 1 and w_anno < 2013 and w_cod_istat <> '001219' then --Non Rivoli
--      w_tot_imposta_originale:= 0;
--      w_tot_imposta     := 0;
--      w_tot_tardivo_30  := 0;
--      w_tot_tardivo     := 0;
--
--      w_i_ruolo := 0;
--      LOOP
--        w_i_ruolo := w_i_ruolo + 1;
--        if w_i_ruolo > w_num_ruoli then
--            exit;
--        end if;
--        w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
--        i   := w_rate_analizzate;
--        LOOP
--            i   := i + 1;
--            bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
--            if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
--                exit;
--            end if;
--            w_tot_imposta_originale := w_tot_imposta_originale + t_tot_imp_tot_imp_orig(bInd1);
--            w_tot_imposta           := w_tot_imposta    + t_tot_imp_tot_imposta(bInd1);
--            w_tot_tardivo_30        := w_tot_tardivo_30 + t_tot_imp_tot_tardivo_30(bInd1);
--            w_tot_tardivo           := w_tot_tardivo    + t_tot_imp_tot_tardivo(bInd1);
--            t_tot_imp_scadenza(bInd1)       := to_date('31122999','ddmmyyyy');
--            t_tot_imp_tot_imp_orig(bInd1)   := 0;
--            t_tot_imp_tot_imposta(bInd1)    := 0;
--            t_tot_imp_tot_tardivo_30(bInd1) := 0;
--            t_tot_imp_tot_tardivo(bInd1)    := 0;
--            t_tot_imp_tot_interessi(bInd1)  := 0;
--            t_tot_imp_note_interessi(bInd1) := chr(10)||chr(13);
--        END LOOP;
--      END LOOP;
--      bInd1 := lpad(t_ruoli_ruolo(1),10,0)||'0'||(1);
--      t_tot_imp_scadenza(bInd1)           := trunc(sysdate);
--      t_tot_imp_tot_imp_orig(bInd1)       := w_tot_imposta_originale;
--      t_tot_imp_tot_imposta(bInd1)        := w_tot_imposta;
--      t_tot_imp_tot_tardivo_30(bInd1)     := w_tot_tardivo_30;
--      t_tot_imp_tot_tardivo(bInd1)        := w_tot_tardivo;
--      t_tot_imp_tot_interessi(bInd1)      := 0;
--      w_delta_rate                        := 0;
--   elsif w_delta_rate > 0 then -- Qui non gestisco la magg tares perchè w_delta_rate è sempre 0.
-- DBMS_OUTPUT.PUT_LINE('DELTA RATE > 0');
--      w_i_ruolo := 0;
--      LOOP
--        w_i_ruolo := w_i_ruolo + 1;
--        if w_i_ruolo > w_num_ruoli then
--            exit;
--        end if;
--        i   := w_delta_rate;
--        LOOP
--            i   := i + 1;
--            bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
--            if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
--                exit;
--            end if;
--            bInd2 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||' '||(i - w_delta_rate);
--            t_tot_imp_scadenza(bInd2)       := t_tot_imp_scadenza(bInd1);
--            t_tot_imp_tot_imp_orig(bInd2)   := t_tot_imp_tot_imp_orig(bInd1);
--            t_tot_imp_tot_imposta(bInd2)    := t_tot_imp_tot_imposta(bInd1);
--            t_tot_imp_tot_tardivo_30(bInd2) := t_tot_imp_tot_tardivo_30(bInd1);
--            t_tot_imp_tot_tardivo(bInd2)    := t_tot_imp_tot_tardivo(bInd1);
--            t_tot_imp_tot_interessi(bInd2)  := t_tot_imp_tot_interessi(bInd1);
--            t_tot_imp_gg_interessi(bInd2)   := t_tot_imp_gg_interessi(bInd1);
--            t_tot_imp_scadenza(bInd1)       := to_date('31122999','ddmmyyyy');
--            t_tot_imp_tot_imp_orig(bInd1)   := 0;
--            t_tot_imp_tot_imposta(bInd1)    := 0;
--            t_tot_imp_tot_tardivo_30(bInd1) := 0;
--            t_tot_imp_tot_tardivo(bInd1)    := 0;
--            t_tot_imp_tot_interessi(bInd1)  := 0;
--            t_tot_imp_gg_interessi(bInd1)   := 0;
--        END LOOP;
--      END LOOP;
--   end if;
   w_step := 'i';
   -- dbms_output.put_line('w_step '||w_step);
--
-- Analisi dei Totali Memorizzati ed Emissione delle Sanzioni.
--
  w_i_ruolo := 0;
  LOOP
    w_i_ruolo := w_i_ruolo + 1;
    if w_i_ruolo > w_num_ruoli then
       --  or (w_num_ruoli > 1 and w_i_ruolo > 1 and w_anno < 2013 and w_cod_istat <> '001219') then -- Non Rivoli
      exit;
    end if;
    if t_ruoli_tipo_ruolo(w_i_ruolo) = 1 then
      if t_ruoli_tipo_emissione(w_i_ruolo) = 'A' then
        -- Ruolo Principale Acconto
         w_cod_base_imp := 100;
         w_cod_base_tares := 550;
         w_cod_base_tares_int := 910;
      else
        -- Ruolo Principale Saldo/Totale
        w_cod_base_imp := 600;
        w_cod_base_tares := 640;
        w_cod_base_tares_int := 920;
      end if;
    else
      -- Ruolo Suppletivo - Nota : piu' suppletivi daranno codici duplicati
      w_cod_base_imp := 700;
      w_cod_base_tares := 740;
      w_cod_base_tares_int := 930;
    end if;
    --dbms_output.put_line('INIZIO Cod. Sanz. : '||w_cod_base_imp);
    w_rate_analizzate := F_CONTA_RATE_ANALIZZATE(w_i_ruolo);
    i   := w_rate_analizzate;
    LOOP
       i := i + 1;
       bInd1 := lpad(t_ruoli_ruolo(w_i_ruolo),10,0)||'0'||(i);
       if i > t_ruoli_num_rate(w_i_ruolo) + w_rate_analizzate then
        -- or (w_num_ruoli > 1 and i > 1 and w_anno < 2013 and w_cod_istat <> '001219') then
          exit;
       end if;
       --
       w_scadenza_imp := t_tot_imp_scadenza(bInd1);
       w_scadenza_tares := t_magg_tares_scadenza(bInd1);
       --
       -- Tassa Evasa.
       --
       w_cod_sanzione := w_cod_base_imp + 1; -- Tassa evasa
       w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
       --  if  t_ruoli_tipo_ruolo(w_i_ruolo) = 1
       --  and (t_ruoli_tipo_emissione(w_i_ruolo) = 'S'
       --  or (t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
       --  and t_ruoli_esiste_acconto(w_i_ruolo) = 1)) then
       --     w_cod_sanzione := w_cod_sanzione + 40; --codici 151 a 154 per Principale saldo o totale.
       --  end if;
       --  if  t_ruoli_tipo_ruolo(w_i_ruolo) = 2 then
       --      w_cod_sanzione := w_cod_sanzione + 50; --codici 161 a 164 per suppletivo saldo o totale.
       --  end if;
       w_imposta := t_tot_imp_tot_imposta(bInd1);
       --dbms_output.put_line('Imposta evasa: '||w_cod_sanzione||' - '||w_imposta);
       if round(w_imposta,0) <> 0 then
          w_imposta := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
          w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_imp);
          BEGIN
             insert into sanzioni_pratica(pratica
                                       , cod_sanzione
                                       , tipo_tributo
                                       , percentuale
                                       , importo
                                       , riduzione
                                       , utente
                                       , data_variazione
                                       , note
                                       , sequenza_sanz
                                        )
            values(a_pratica
                 , w_cod_sanzione
                 , 'TARSU'
                 , null
                 , w_imposta
                 , null
                 , a_utente
                 , trunc(sysdate)
                 , null
                 , w_seq_sanzione
                  )
            ;
          END;
       end if;
       if w_flag_sanz_magg_tares > 0 then
          w_cod_sanzione := w_cod_base_tares + 5; -- Evasa
          w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
          w_imposta := t_magg_tares_tot_imposta(bInd1);
          -- Salta se round(0) = 0 oppure se cope e round(2) <> 0
          if (round(w_imposta,0) <> 0) or
             ((w_flag_cope <> 0) and (round(w_imposta,2) <> 0)) then
             w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_tares);
             BEGIN
                insert into sanzioni_pratica(pratica
                                          , cod_sanzione
                                          , tipo_tributo
                                          , percentuale
                                          , importo
                                          , riduzione
                                          , utente
                                          , data_variazione
                                          , note
                                          , sequenza_sanz
                                            )
               values(a_pratica
                    , w_cod_sanzione
                    , 'TARSU'
                    , null
                    , w_imposta
                    , null
                    , a_utente
                    , trunc(sysdate)
                    , null
                    , w_seq_sanzione
                    )
               ;
             END;
          end if;
       end if;
       -- (VD - 23/09/2022): se si tratta di sollecito non si emettono altre sanzioni
       --                    oltre all'imposta evasa e alle spese di notifica
       if w_tipo_pratica <> 'S' then
          --
          -- Tardivo Versamento.
          --
          w_cod_sanzione := w_cod_base_imp + 8; -- Tardivo
          w_cod_sanzione := w_cod_sanzione + to_number(substr(lpad(bInd1,12,'0'),12)-w_rate_analizzate) * 10;
         -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 1
         -- and (t_ruoli_tipo_emissione(w_i_ruolo) = 'S'
         -- or (t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
         -- and t_ruoli_esiste_acconto(w_i_ruolo) = 1)) then
         --    w_cod_sanzione := w_cod_sanzione + 40; --codici 158 per Principale saldo o totale.
         -- end if;
         -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 2 then
         --    w_cod_sanzione := w_cod_sanzione + 50; --codici 168 per suppletivo saldo o totale.
         -- end if;
          w_imposta := t_tot_imp_tot_tardivo(bInd1);
          --dbms_output.put_line('Tardivo versamento: '||w_cod_sanzione||' - '||w_imposta);
          if w_imposta > 0 then
             if w_cod_istat = '049011' then  -- Marciana Marina
                if w_flag_sanz = 'S' then
                   w_lordo := w_imposta;
                else
                   w_lordo := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
                end if;
             else
                w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
                if w_flag_sanz = 'S' then
                   w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
                end if;
             end if;
             w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_scadenza_imp,w_percentuale,w_riduzione,w_sanzione);
             if w_errore is not null then
                RAISE ERRORE;
             end if;
            -- Se la sanzione viene inserita solo se è maggiore di zero
             if round(w_sanzione,2) > 0 then
               w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_imp);
               BEGIN
                  insert into sanzioni_pratica(pratica
                                          , cod_sanzione
                                          , tipo_tributo
                                          , percentuale
                                          , importo
                                          , riduzione
                                          , utente
                                          , data_variazione
                                          , note
                                          , sequenza_sanz
                                          )
                  values(a_pratica
                    , w_cod_sanzione
                    , 'TARSU'
                    , w_percentuale
                    , w_sanzione
                    , w_riduzione
                    , a_utente
                    , trunc(sysdate)
                    , 'Base: '||round(w_lordo,2)
                    , w_seq_sanzione
                   )
                  ;
               END;
             end if;
          end if;
          if w_flag_sanz_magg_tares > 0 then
             w_cod_sanzione := w_cod_base_tares + 8; -- Tardivo
             w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
             w_imposta := t_magg_tares_tot_tardivo(bInd1);
             --dbms_output.put_line('Tardivo vers. Magg. Tares: '||w_cod_sanzione||' - '||w_imposta);
             if w_imposta > 0 then
                w_lordo := w_imposta;
                w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_scadenza_tares,w_percentuale,w_riduzione,w_sanzione);
                if w_errore is not null then
                   RAISE ERRORE;
                end if;
               -- Se la sanzione viene inserita solo se è maggiore di zero
                if round(w_sanzione,2) > 0 then
                  w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_tares);
                  BEGIN
                     insert into sanzioni_pratica(pratica
                                             , cod_sanzione
                                             , tipo_tributo
                                             , percentuale
                                             , importo
                                             , riduzione
                                             , utente
                                             , data_variazione
                                             , note
                                             , sequenza_sanz
                                             )
                     values(a_pratica
                       , w_cod_sanzione
                       , 'TARSU'
                       , w_percentuale
                       , w_sanzione
                       , w_riduzione
                       , a_utente
                       , trunc(sysdate)
                       , 'Base: '||round(w_lordo,2)
                       , w_seq_sanzione
                        )
                     ;
                  END;
                end if;
             end if;
          end if;
          w_cod_sanzione := w_cod_base_imp + 9; -- Tardivo 30gg
          w_cod_sanzione := w_cod_sanzione + to_number(substr(lpad(bInd1,12,0),12)-w_rate_analizzate) * 10;
          -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 1
          -- and (t_ruoli_tipo_emissione(w_i_ruolo) = 'S'
          --  or (t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
          -- and t_ruoli_esiste_acconto(w_i_ruolo) = 1)) then
          --    w_cod_sanzione := w_cod_sanzione + 40; --codici 159 per Principale saldo o totale.
          -- end if;
          -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 2 then
          --    w_cod_sanzione := w_cod_sanzione + 50; --codici 169 per suppletivo saldo o totale.
          -- end if;
          w_imposta := t_tot_imp_tot_tardivo_30(bInd1);
          -- dbms_output.put_line('Sanzione: '||w_cod_sanzione||' - '||w_imposta);
          if w_imposta > 0 then
            if w_cod_istat = '049011' then  -- Marciana Marina
               if w_flag_sanz = 'S' then
                  w_lordo := w_imposta;
               else
                  w_lordo := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
               end if;
            else
               w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
               if w_flag_sanz = 'S' then
                  w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
               end if;
            end if;
            w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_scadenza_imp,w_percentuale,w_riduzione,w_sanzione);
            if w_errore is not null then
               RAISE ERRORE;
            end if;
            -- Se la sanzione viene inserita solo se è maggiore di zero
            if round(w_sanzione,2) > 0 then
               w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_imp);
               BEGIN
                  insert into sanzioni_pratica(pratica
                                          , cod_sanzione
                                          , tipo_tributo
                                          , percentuale
                                          , importo
                                          , riduzione
                                          , utente
                                          , data_variazione
                                          , note
                                          , sequenza_sanz
                                          )
                  values(a_pratica
                    , w_cod_sanzione
                    , 'TARSU'
                    , w_percentuale
                    , w_sanzione
                    , w_riduzione
                    , a_utente
                    , trunc(sysdate)
                    , 'Base: '||round(w_lordo,2)
                    , w_seq_sanzione
                     )
               ;
               END;
            end if;
          end if;
          if w_flag_sanz_magg_tares > 0 then
             w_cod_sanzione := w_cod_base_tares + 9; -- Tardivo entro 30 gg
             w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
             w_imposta := t_magg_tares_tot_tardivo_30(bInd1);
         --  dbms_output.put_line(bInd1||' tardivo 30 magg tares imposta: '||w_imposta);
             if w_imposta > 0 then
                w_lordo  := w_imposta;
                w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_scadenza_tares,w_percentuale,w_riduzione,w_sanzione);
                if w_errore is not null then
                   RAISE ERRORE;
                end if;
                -- dbms_output.put_line(bInd1||' tardivo 30 magg tares w_sanzione '||w_sanzione);
                -- Se la sanzione viene inserita solo se è maggiore di zero
                if round(w_sanzione,2) > 0 then
                   w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_tares);
                   BEGIN
                      insert into sanzioni_pratica(pratica
                                              , cod_sanzione
                                              , tipo_tributo
                                              , percentuale
                                              , importo
                                              , riduzione
                                              , utente
                                              , data_variazione
                                              , note
                                              , sequenza_sanz
                                              )
                      values(a_pratica
                        , w_cod_sanzione
                        , 'TARSU'
                        , w_percentuale
                        , w_sanzione
                        , w_riduzione
                        , a_utente
                        , trunc(sysdate)
                        , 'Base: '||round(w_lordo,2)
                        , w_seq_sanzione
                        )
                   ;
                   END;
                end if;
             end if;
          end if;
          w_step := 'l';
          --dbms_output.put_line('w_step '||w_step);
          --
          -- Omesso o Parziale Versamento.
          --
          w_imposta := t_tot_imp_tot_imposta(bInd1);
          if round(w_imposta,0) > 0 then
          --
          -- Se la imposta al netto dei versamenti corrisponde alla imposta al lordo dei versamenti
          -- significa che non sono stati effettuati dei versamenti per cui si tratta di omesso,
          -- viceversa si tratta di parziale.
          --
            -- dbms_output.put_line('prima di 6 e 7 w_cod_base_imp '||w_cod_base_imp);
            if w_imposta = t_tot_imp_tot_imp_orig(bInd1) then
               w_cod_sanzione := w_cod_base_imp + 6;  -- Tardivo Versamento
               w_cod_sanzione := w_cod_sanzione + to_number(substr(lpad(bInd1,12,'0'),12)-w_rate_analizzate) * 10;
            else
               w_cod_sanzione := w_cod_base_imp + 7;  -- Parziale Versamento
               w_cod_sanzione := w_cod_sanzione + to_number(substr(lpad(bInd1,12,'0'),12)-w_rate_analizzate) * 10;
            end if;
            -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 1
            -- and (t_ruoli_tipo_emissione(w_i_ruolo) = 'S'
            --  or (t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
            -- and t_ruoli_esiste_acconto(w_i_ruolo) = 1)) then
            --    w_cod_sanzione := w_cod_sanzione + 40; --codici 156 -157 per Principale saldo o totale.
            -- end if;
            -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 2 then
            --     w_cod_sanzione := w_cod_sanzione + 50; --codici 166 - 167 per suppletivo saldo o totale.
            -- end if;
            if w_cod_istat = '049011' then -- Marciana Marina
               if w_flag_sanz = 'S' then
                  w_lordo := w_imposta;
               else
                  w_lordo := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
               end if;
            else
               w_lordo  := f_trova_netto(w_imposta,w_add_eca,w_mag_eca,w_add_pro,w_aliquota);
               if w_flag_sanz = 'S' then
                  w_lordo  := w_lordo + round(w_lordo * nvl(w_add_pro,0) / 100,2);
               end if;
            end if;
            w_errore := F_IMP_SANZ(w_cod_sanzione,w_lordo,w_scadenza_imp,w_percentuale,w_riduzione,w_sanzione);
            if w_errore is not null then
               RAISE ERRORE;
            end if;
            if round(w_sanzione,2) <> 0 then
              w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_imp);
              BEGIN
               insert into sanzioni_pratica
                     (pratica,cod_sanzione,tipo_tributo,percentuale,importo,riduzione,
                      utente,data_variazione,note,sequenza_sanz
                     )
               values(a_pratica,w_cod_sanzione,'TARSU',w_percentuale,w_sanzione,w_riduzione,
                      a_utente,trunc(sysdate),'Base: '||round(w_lordo,2),w_seq_sanzione
                     )
               ;
              END;
            end if;
          end if;
          if w_flag_sanz_magg_tares > 0 then
             w_imposta := t_magg_tares_tot_imposta(bInd1);
             -- dbms_output.put_line('t_magg_tares('||bInd1||').tot_imposta '||t_magg_tares_tot_imposta(bInd1));
             -- dbms_output.put_line('t_magg_tares('||bInd1||').tot_imposta_originale '||t_magg_tares_tot_imp_orig(bInd1));
             -- Salta se round(0) = 0 oppure se cope e round(2) <> 0
             if (round(w_imposta,0) <> 0) or
                ((w_flag_cope <> 0) and (round(w_imposta,2) <> 0)) then
                -- Se la imposta al netto dei versamenti corrisponde alla imposta al lordo dei versamenti
                -- significa che non sono stati effettuati dei versamenti per cui si tratta di omesso,
                -- viceversa si tratta di parziale.
                 if w_imposta = t_magg_tares_tot_imp_orig(bInd1) then
                   w_cod_sanzione := w_cod_base_tares + 6; -- Omesso
                   w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
                 else
                   w_cod_sanzione := w_cod_base_tares + 7; -- Parziale
                   w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate) * 10;
                 end if;
                 w_errore := F_IMP_SANZ(w_cod_sanzione,w_imposta,w_scadenza_tares,w_percentuale,w_riduzione,w_sanzione);
                 if w_errore is not null then
                    RAISE ERRORE;
                 end if;
                 if round(w_sanzione,2) <> 0 then
                    w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_tares);
                    BEGIN
                      insert into sanzioni_pratica
                            (pratica,cod_sanzione,tipo_tributo,percentuale,importo,riduzione,
                             utente,data_variazione,note,sequenza_sanz
                            )
                      values(a_pratica,w_cod_sanzione,'TARSU',w_percentuale,w_sanzione,w_riduzione,
                             a_utente,trunc(sysdate),'Base: '||round(w_imposta,2),w_seq_sanzione
                            )
                      ;
                    END;
                 end if;
             end if;
          end if;
          w_step := 'm';
          --dbms_output.put_line('w_step '||w_step);
          --dbms_output.put_line('t_tot_imp_tot_interessi(bInd1) '||t_tot_imp_tot_interessi(bInd1));
          --
          -- Interessi.
          --
          if t_tot_imp_tot_interessi(bInd1) <> 0 then
             w_cod_sanzione := w_cod_base_imp + 90; -- Interessi
             w_cod_sanzione := w_cod_sanzione + to_number(substr(lpad(bInd1,12,'0'),12)-w_rate_analizzate);
             -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 1
             -- and (t_ruoli_tipo_emissione(w_i_ruolo) = 'S'
             --  or (t_ruoli_tipo_emissione(w_i_ruolo) = 'T'
             --  and t_ruoli_esiste_acconto(w_i_ruolo) = 1)) then
             --      w_cod_sanzione := 195; --codici 195 per Principale saldo o totale.
             -- end if;
             -- if  t_ruoli_tipo_ruolo(w_i_ruolo) = 2 then
             --     w_cod_sanzione := 196; --codici 196 per suppletivo saldo o totale.
             -- end if;
             if t_tot_imp_gg_interessi(bInd1) = 0 then
                t_tot_imp_gg_interessi(bInd1) := null;
             end if;
             if round(t_tot_imp_tot_interessi(bInd1),2) <> 0 then
                w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_imp);
                BEGIN
                  insert into sanzioni_pratica
                     (pratica,cod_sanzione,tipo_tributo,percentuale,importo,riduzione,
                      giorni,utente,data_variazione,note,sequenza_sanz
                     )
                  values(a_pratica,w_cod_sanzione,'TARSU',null,t_tot_imp_tot_interessi(bInd1),null,
                      t_tot_imp_gg_interessi(bInd1),a_utente,trunc(sysdate),substr(t_tot_imp_note_interessi(bInd1),3),w_seq_sanzione
                     )
                  ;
                EXCEPTION
                  WHEN others THEN
                     w_errore := 'Errore in Inserimento Interessi Rata '||substr(to_char(bInd1),-1,1);
                     RAISE errore;
                END;
             end if;
          end if;
          if w_flag_sanz_magg_tares > 0 then
             -- dbms_output.put_line('**** t_magg_tares('||bInd1||').tot_interessi '||t_magg_tares_tot_interessi(bInd1));
             if t_magg_tares_tot_interessi(bInd1) <> 0 then
                w_cod_sanzione := w_cod_base_tares_int;
                w_cod_sanzione := w_cod_sanzione + (to_number(substr(lpad(bInd1,12,'0'),12)) - w_rate_analizzate);
                if t_magg_tares_gg_interessi(bInd1) = 0 then
                   t_magg_tares_gg_interessi(bInd1) := null;
                end if;
                if round(t_magg_tares_tot_interessi(bInd1),2) <> 0 then
                  w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_scadenza_tares);
                  BEGIN
                    insert into sanzioni_pratica
                       (pratica,cod_sanzione,tipo_tributo,percentuale,importo,riduzione,
                        giorni,utente,data_variazione,note,sequenza_sanz
                       )
                    values(a_pratica,w_cod_sanzione,'TARSU',null,t_magg_tares_tot_interessi(bInd1),null,
                        t_magg_tares_gg_interessi(bInd1),a_utente,trunc(sysdate),substr(t_magg_tares_note_interessi(bInd1),3),w_seq_sanzione
                       )
                    ;
                  EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in Inserimento Interessi Magg Tares ';
                       RAISE errore;
                  END;
                end if;
             end if;
          end if;
       end if;
    END LOOP;
  END LOOP;
--
-- Interessi.
--
/*   if w_tot_interessi <> 0 then
      w_seq_sanzione := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_data_pratica);
      BEGIN
         insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo,percentuale,importo,riduzione,
                utente,data_variazione,note,sequenza_sanz
               )
         values(a_pratica,199,'TARSU',null,round(w_tot_interessi,2),null,
                a_utente,trunc(sysdate),null,w_seq_sanzione
               )
         ;
      END;
   end if;
   */
      w_step := 'n';
  --dbms_output.put_line('w_step '||w_step);
--
-- Se il totale dell`importo delle sanzioni della pratica emesse > 0,
-- si emettono anche le spese di notifica.
--
   BEGIN
       select nvl(sum(sapr.importo),0)
         into w_imp_sanzioni
         from sanzioni_pratica sapr
        where sapr.pratica = a_pratica
       ;
       -- (VD - 23/09/2022): aggiunto test su parametro se_spese_notifica
       --                    utilizzato in emissione solleciti TARSU
       -- (AB - 20/12/2022): aggiunto la riduzione per la 197
       -- (RV - 02/02/2023): per il sollecito utilizza il codice 898,
       --                    altrimenti lo standard 197
       --
       if w_imp_sanzioni > 0 and nvl(a_se_spese_notifica,'N') = 'S' then
         if w_tipo_pratica = 'S' then
           w_cod_sanzione_spese := 898;
         else
           w_cod_sanzione_spese := 197;
         end if;
         BEGIN
            select sanz.sanzione,sanz.riduzione,sanz.sequenza
              into w_imp_sanzioni,w_riduzione,w_seq_sanzione
              from sanzioni sanz
             where sanz.cod_sanzione = w_cod_sanzione_spese
               and sanz.tipo_tributo = 'TARSU'
               and nvl(sanz.sanzione,0) > 0
               and w_data_pratica between
                   sanz.data_inizio and sanz.data_fine
            ;
            insert into sanzioni_pratica(pratica
                                       , cod_sanzione
                                       , tipo_tributo
                                       , percentuale
                                       , importo
                                       , riduzione
                                       , utente
                                       , data_variazione
                                       , note
                                       , sequenza_sanz
                                       )
            values(a_pratica
                 , w_cod_sanzione_spese
                 , 'TARSU'
                 , null
                 , w_imp_sanzioni
                 , w_riduzione--null
                 , a_utente
                 , trunc(sysdate)
                 , null
                 , w_seq_sanzione
                 )
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN null;
         END;
       end if;
  END;
  w_step := 'o';
--dbms_output.put_line('w_step '||w_step);
  --
  -- (VD - 10/12/2014): il raggruppamento delle sanzioni viene effettuato
  --                    in presenza di date per il calcolo interessi
  --
  if a_interessi_dal is not null and a_interessi_al is not null then
    RAGGRUPPA_SAPR_ACC_TARSU(a_pratica,a_utente,w_data_pratica);
  end if;
  --
  GESTIONE_RATA_UNICA(w_cod_fiscale, a_pratica, w_anno, t_ruoli_ruolo(w_num_ruoli));
  --
EXCEPTION
  WHEN FINE THEN null;
  WHEN ERRORE THEN
    rollback;
    RAISE_APPLICATION_ERROR(-20999,w_step||' '||w_errore);
  WHEN OTHERS THEN
    rollback;
    RAISE_APPLICATION_ERROR(-20999,w_step||' '||SQLERRM);
END;
/* End Procedure: CALCOLO_ACC_SANZIONI_TARSU */
/
