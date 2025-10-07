--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_avvisi_tari stripComments:false runOnChange:true 
 
create or replace package STAMPA_AVVISI_TARI is
/******************************************************************************
 NOME:        STAMPA_AVVISI_TARI
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   11/03/2020  VD      Versione iniziale
   001   07/06/2024  RV      #72976
                             Rivisto DATI_UTENZE per componenti perequative
   002   13/02/2025  RV      #77805
                             Rivisto per componenti perequative spalmate
   003   31/03/2025  RV      #78970
                             Rivisto per eccedenze, codici rfid, dizionari tariffe
*****************************************************************************/
  function contribuente
  ( a_ni                          number     default -1
  , a_tipo_tributo                varchar2   default ''
  , a_cod_fiscale                 varchar2   default ''
  , a_ruolo                       number     default -1
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function f_get_stringa_versamenti
  ( a_tipo_tributo                varchar2
  , a_cod_fiscale                 varchar2
  , a_ruolo                       number
  , a_anno_ruolo                  number
  , a_tipo_ruolo                  number
  , a_tipo_emissione              varchar2
  , a_modello                     number
  ) return varchar2;
  function dati_ruolo
  ( a_ruolo                       number     default -1
  , a_cod_fiscale                 varchar2   default ''
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function dati_rate
  ( a_ruolo                       number     default -1
  , a_cod_fiscale                 varchar2   default ''
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function dati_utenze
  ( a_ruolo                       number     default -1
  , a_cod_fiscale                 varchar2   default ''
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function dati_eccedenze
  ( a_ruolo                       number       default -1
  , a_cod_fiscale                 varchar2     default ''
  , a_tipo_tariffe                varchar2     default '*'    -- '*' : Tutte, 'D' : Solo Domestiche, 'ND' : Solo non Domestiche
  , a_modello                     number       default -1
  ) return sys_refcursor ;
  function f_stringa_qf
  ( a_tipo_calcolo                varchar2
  , a_flag_tariffe_ruolo          varchar2
  , a_flag_domestica              varchar2
  , a_mq                          number
  , a_perc_riduzione_pf           number
  , a_dettaglio                   varchar2
  , a_dettaglio_base              varchar2
  ) return varchar2;
  function f_stringa_qv
  ( a_tipo_calcolo                varchar2
  , a_flag_tariffe_ruolo          varchar2
  , a_flag_domestica              varchar2
  , a_mq                          number
  , a_perc_riduzione_pv           number
  , a_dettaglio                   varchar2
  , a_dettaglio_base              varchar2
  ) return varchar2;
  function f_get_componenti_perequative
  ( p_anno                        number,
    p_totale                      number
  ) return varchar2;
  function dati_familiari
  ( a_oggetto_imposta             number     default -1
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function dati_non_dom
  ( a_oggetto_imposta             number     default -1
  , a_modello                     number     default -1
  ) return sys_refcursor;
  function dati_rfid
  ( a_oggetto_imposta         number     default -1
  , a_modello                 number     default -1
  ) return sys_refcursor;
  function dizionario_tariffe_dom
  ( a_ruolo                   number       default -1
  , a_cod_fiscale             varchar2     default ''
  , a_modello                 number       default -1
  ) return sys_refcursor;
  function dizionario_tariffe_non_dom
  ( a_ruolo                   number       default -1
  , a_cod_fiscale             varchar2     default ''
  , a_modello                 number       default -1
  ) return sys_refcursor;
end STAMPA_AVVISI_TARI;
/
create or replace package body STAMPA_AVVISI_TARI is
/******************************************************************************
 NOME:        STAMPA_AVVISI_TARI
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   11/03/2020  VD      Versione iniziale
   001   07/06/2024  RV      #72976
                             Rivisto DATI_RUOLO e DATI_UTENZE per componenti perequative
   002   13/02/2025  RV      #77805
                             Rivisto per componenti perequative spalmate
   003   31/03/2025  RV      #78970
                             Rivisto per eccedenze, codici rfid, dizionari tariffe
*****************************************************************************/
function contribuente
  ( a_ni                        number     default -1
  , a_tipo_tributo              varchar2   default ''
  , a_cod_fiscale               varchar2   default ''
  , a_ruolo                     number     default -1
  , a_modello                   number     default -1
  ) return sys_refcursor is
    w_ni                        number := -1;
    w_tipo_tributo              varchar2(5) := 'TARSU';
    rc                          sys_refcursor;
begin
    rc := stampa_common.contribuenti_ente(w_ni,w_tipo_tributo,a_cod_fiscale,a_ruolo,a_modello);
return rc;
end contribuente;
--------------------------------------------------------------------
function f_get_stringa_versamenti
  ( a_tipo_tributo              varchar2
  , a_cod_fiscale               varchar2
  , a_ruolo                     number
  , a_anno_ruolo                number
  , a_tipo_ruolo                number
  , a_tipo_emissione            varchar2
  , a_modello                   number
  ) return varchar2 is
    w_note_utenza               varchar2(4000);
    w_insolvenza_min            number;
    w_numero_anni               number;
    w_stringa_vers_reg          varchar2(4000);
    w_stringa_vers_irr          varchar2(4000);
    w_stringa_anni              varchar2(100);
    w_ruolo_acconto             number;
    w_ultimo_ruolo              number;
    w_anno_rif                  number;
    w_importo_anno              number;
    w_imp_dovuto                number;
    w_imp_versato               number;
    w_imp_sgravi                number;
    w_ind                       number;
    type t_importo_anno_t       is table of number index by binary_integer;
    t_importo_anno              t_importo_anno_t;
begin
    -- Si selezionano i parametri necessari del modello
    w_note_utenza      := null;
    w_numero_anni      := nvl(to_number(f_descrizione_timp (a_modello,'ANNI_CHECK_VERS')),0);
    -- Se il numero di anni per cui controllare i versamenti è 0, la funzione
    -- restituisce una stringa nulla
    if w_numero_anni = 0 then
       return w_note_utenza;
end if;
    --
    w_insolvenza_min   := nvl(to_number(f_descrizione_timp (a_modello,'INSOLVENZA_MIN')),0);
    w_stringa_vers_reg := f_descrizione_timp (a_modello,'VERS_CORRETTI');
    w_stringa_vers_irr := f_descrizione_timp (a_modello,'VERS_MANCANTI');
    -- Se il ruolo che si sta trattando è a saldo, si verificano anche i
    -- versamenti relativi al ruolo in acconto. Se il ruolo è in acconto o
    -- totale, si verificano solo i versamenti per gli anni precedenti
    w_importo_anno := to_number(null);
    if a_tipo_emissione = 'S' then
begin
select ruolo
into w_ruolo_acconto
from ruoli
where anno_ruolo = a_anno_ruolo
  --and progr_emissione = 1
  and tipo_emissione = 'A'
  and invio_consorzio is not null;
exception
         when others then
           w_ruolo_acconto := to_number(null);
end;
       if w_ruolo_acconto is not null then
          w_importo_anno := nvl(f_importi_ruoli_tarsu(a_cod_fiscale,a_anno_ruolo,w_ruolo_acconto,to_number(null),'IMPOSTA'),0) -
                            nvl(f_importo_vers(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_importo_vers_ravv(a_cod_fiscale,'TARSU',a_anno_ruolo,to_number(null)),0) -
                            nvl(f_dovuto(0,a_anno_ruolo,'TARSU',0,-1,'S',null,a_cod_fiscale),0);
          if w_importo_anno <= w_insolvenza_min then
             w_importo_anno := to_number(null);
end if;
end if;
end if;
    -- Si esegue un loop sui 5 anni precedenti per determinare
    -- l'eventuale dovuto residuo
    t_importo_anno.delete;
    w_ind := 0;
for w_ind in 1 .. w_numero_anni
    loop
      -- Si determina l'anno di riferimento e l'ultimo ruolo totale emesso per quell'anno
      w_anno_rif := a_anno_ruolo - w_ind;
begin
        w_ultimo_ruolo := f_ruolo_totale(a_cod_fiscale
                                        ,w_anno_rif
                                        ,a_tipo_tributo
                                        ,-1
                                        );
exception
        when others then
          w_ultimo_ruolo := to_number(null);
end;
begin
select nvl(sum(nvl(ogim.imposta,0) + nvl(ogim.maggiorazione_eca,0) +
               nvl(ogim.addizionale_eca,0) + nvl(ogim.addizionale_pro,0) +
               nvl(ogim.iva,0) + nvl(ogim.maggiorazione_tares,0)),0) imp_dovuto
into w_imp_dovuto
from oggetti_imposta ogim
   ,oggetti_pratica ogpr
   ,pratiche_tributo prtr
   ,ruoli ruol
where ogim.cod_fiscale = a_cod_fiscale
  and ogim.oggetto_pratica = ogpr.oggetto_pratica
  and ogpr.pratica = prtr.pratica
  and (prtr.tipo_pratica = 'D'
    or (prtr.tipo_pratica = 'A'
        and ogim.anno > prtr.anno))
  and prtr.tipo_tributo||'' = 'TARSU'
  and nvl (ogim.ruolo, -1) =
      nvl (nvl (w_ultimo_ruolo
               ,ogim.ruolo
               )
          ,-1
          )
  and ruol.ruolo = ogim.ruolo
  and ruol.invio_consorzio is not null
  and ogim.anno = w_anno_rif
group by ogim.anno
       , prtr.tipo_tributo
;
exception
        when others then
          w_imp_dovuto := 0;
end;
begin
select f_importo_vers (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, null)
    + f_importo_vers_ravv (a_cod_fiscale, a_tipo_tributo, a_anno_ruolo - w_ind, 'U') imp_versato
     , nvl(f_dovuto(0,a_anno_ruolo - w_ind,a_tipo_tributo,0,-1,'S',null,a_cod_fiscale),0) imp_sgravi
into w_imp_versato
    , w_imp_sgravi
from dual;
exception
        when others then
          w_imp_versato := 0;
          w_imp_sgravi := 0;
end;
      t_importo_anno(w_ind) := w_imp_dovuto - w_imp_versato - w_imp_sgravi;
      if t_importo_anno(w_ind) <= w_insolvenza_min then
         t_importo_anno(w_ind) := to_number(null);
end if;
end loop;
    -- Alla fine del trattamento si verifica se occorre compilare anche la
    -- nota utenza
    w_stringa_anni := '';
    if w_importo_anno is not null then
       w_stringa_anni := 'l''anno '||a_anno_ruolo;
end if;
for w_ind in reverse 1 .. w_numero_anni
    loop
       if t_importo_anno (w_ind) is not null then
          if w_stringa_anni is null then
             w_stringa_anni := 'l''anno '||to_char(a_anno_ruolo - w_ind);
else
             w_stringa_anni := replace(w_stringa_anni,'l''anno','gli anni');
             w_stringa_anni := w_stringa_anni||', '||to_char(a_anno_ruolo - w_ind);
end if;
end if;
end loop;
     if w_stringa_anni is not null then
        w_note_utenza := replace(w_stringa_vers_irr,'XXXX',w_stringa_anni);
else
        w_note_utenza := w_stringa_vers_reg;
end if;
return w_note_utenza;
end f_get_stringa_versamenti;
--------------------------------------------------------------------
function dati_ruolo
--------------------------------------------------------------------
  -- (RV - 30/05/2024): #72976
  --                    Per gestire le componenti perequative (al momento gestite
  --                    come maggiorazione tares) è stato eliminata l'esclusione
  --                    di tali importi dai totali usata in precedenza come
  --                    differenziazione contabile
--------------------------------------------------------------------
  ( a_ruolo                     number        default -1
  , a_cod_fiscale               varchar2      default ''
  , a_modello                   number        default -1
  ) return sys_refcursor is
    a_spese_postali             number;
    a_se_vers_positivi          varchar2(1);
    rc                          sys_refcursor;
begin
    -- a_modello = -1 viene utilizzato per creare i campi unione nelle stampe
    -- Attenzione: per ora il parametro a_se_vers_positivi non viene utilizzato,
    -- perchè non è utilizzato neanche in Power Builder
    if a_modello <> -1 and nvl(f_descrizione_timp(a_modello,'VERS_POSITIVI'),'NO') = 'SI' then
       a_se_vers_positivi := '+';
     else
       a_se_vers_positivi := '';
    end if;
    -- Selezione spese postali
    begin
      select nvl(sanzione,0)
      into a_spese_postali
      from sanzioni
      where sanzioni.cod_sanzione = 115
        and sanzioni.tipo_tributo = 'TARSU'
        and sanzioni.sequenza = 1;
      exception
            when others then
              a_spese_postali := 0;
    end;
    -- Selezione dati ruolo per il contribuente
    open rc for
      select a_ruolo
           , a_cod_fiscale
           , ruoli.anno_ruolo
           , stampa_common.f_formatta_numero(a_spese_postali,'I','S') spese_postali
           , f_descrizione_titr('TARSU',ruoli.anno_ruolo) descr_tributo
           , f_descrizione_adpr(ruoli.anno_ruolo)         descr_add_pro
           , to_char(ruoli.data_emissione,'dd/mm/yyyy')   data_emissione
           , decode(ruoli.rate,0,1,null,1,ruoli.rate)     rate
           , to_char(ruoli.scadenza_prima_rata,'dd/mm/yyyy') scadenza_rata_1
           , to_char(ruoli.scadenza_rata_2,'dd/mm/yyyy') scadenza_rata_2
           , to_char(ruoli.scadenza_rata_3,'dd/mm/yyyy') scadenza_rata_3
           , to_char(ruoli.scadenza_rata_4,'dd/mm/yyyy') scadenza_rata_4
           , to_char(ruoli.scadenza_rata_unica,'dd/mm/yyyy') scadenza_rata_unica
           , to_char(ruoli.scadenza_prima_rata,'dd/mm/yyyy') ||
             decode(ruoli.scadenza_rata_2,null,'',' - '||to_char(ruoli.scadenza_rata_2,'dd/mm/yyyy')) ||
             decode(ruoli.scadenza_rata_3,null,'',' - '||to_char(ruoli.scadenza_rata_3,'dd/mm/yyyy')) ||
             decode(ruoli.scadenza_rata_4,null,'',' - '||to_char(ruoli.scadenza_rata_4,'dd/mm/yyyy'))
                                                                      stringa_scadenze
           , ruoli.anno_emissione
           , ruoli.progr_emissione
           , ruoli.descrizione
           , ruoli.specie_ruolo
           , ruoli.cod_sede
           , to_char(ruoli.data_denuncia,'dd/mm/yyyy')
           , ruoli.ruolo_rif
           , ruoli.importo_lordo
           , ruoli.a_anno_ruolo
           , ruoli.cognome_resp
           , ruoli.nome_resp
           , to_char(ruoli.data_fine_interessi, 'dd/mm/yyyy') data_fine_interessi
           , ruoli.stato_ruolo
           , ruoli.ruolo_master
           , ruoli.tipo_calcolo
           , ruoli.tipo_emissione
           , ruoli.perc_acconto
           , decode(nvl(ruoli.perc_acconto,0)
              ,0,''
              ,'Perc.Acconto: '||stampa_common.f_formatta_numero (ruoli.perc_acconto,'P')
              ) st_perc_acconto
           , ruoli.ente
           , ruoli.flag_calcolo_tariffa_base
           , ruoli.flag_tariffe_ruolo
           , ruoli.note
           , ruoli.utente
           , to_char(ruoli.data_variazione, 'dd/mm/yyyy') data_variazione
           , stampa_common.f_formatta_numero(imco.importo_lordo,'I','S') importo_lordo
           , stampa_common.f_formatta_numero(imco.importo_netto,'I','S') importo_netto
           , decode(nvl(cata.addizionale_eca,0)
              ,0,''
              ,stampa_common.f_formatta_numero(cata.addizionale_eca,'P','S'))   perc_add_eca
           , decode(nvl(cata.addizionale_eca,0)
              ,0,''
              ,stampa_common.f_formatta_numero(imco.addizionale_eca,'I','S'))   importo_add_eca
           , decode(nvl(cata.maggiorazione_eca,0)
              ,0,''
              ,stampa_common.f_formatta_numero(cata.maggiorazione_eca,'P','S')) perc_magg_eca
           , decode(nvl(cata.maggiorazione_eca,0)
              ,0,''
              ,stampa_common.f_formatta_numero(imco.maggiorazione_eca,'I','S')) importo_magg_eca
           , decode(cata.addizionale_pro
              ,null,''
              ,stampa_common.f_formatta_numero(cata.addizionale_pro,'P','S'))   perc_add_pro
           , decode(cata.addizionale_pro
              ,null,''
              ,stampa_common.f_formatta_numero(imco.addizionale_pro,'I','S'))   importo_add_pro
           , decode(cata.aliquota
              ,null,''
              ,stampa_common.f_formatta_numero(cata.aliquota,'P','S'))          aliq_iva
           , decode(cata.aliquota
              ,null,''
              ,stampa_common.f_formatta_numero(imco.iva,'I','S'))               importo_iva
           , stampa_common.f_formatta_numero(
                  round(nvl(imco.importo_lordo,0)
                  -- #72976  - nvl(imco.maggiorazione_tares,0)
                            + a_spese_postali,0)
                  - round(imco.versato_netto_tot,0)
                  - round(nvl(imco.imposta_evasa_accertata,0),0)
              ,'I','S')                                importo_totale_arr
           , stampa_common.f_formatta_numero(
                      nvl(imco.importo_lordo,0)
                  -- #72976  - nvl(imco.maggiorazione_tares,0)
                  + nvl(imco.compensazione,0) + a_spese_postali
              ,'I','S')                                importo_tot_s_no_comp
           , stampa_common.f_formatta_numero(
                  round(imco.maggiorazione_tares,0) - imco.versato_magg_tares
                  - round(nvl(imco.magg_tares_evasa_accertata,0),0)
              ,'I','S')                                magg_tares_arr
           , stampa_common.f_formatta_numero(
                  nvl(imco.importo_netto,0) - imco.versato_netto_tot
                  - nvl(imco.imposta_evasa_accertata,0)
          ,'I','S')                                importo_netto2
           , decode(nvl(ruoli.tipo_emissione, 'T')
          ,'A', 0
          ,'T', 0
          ,imco_prec.rate_ruolo_prec)                                   rate_iniz_prec
           , decode(nvl(ruoli.tipo_emissione, 'T')
          ,'A', 1
          ,'T', 0
          ,imco_prec.rate_ruolo_prec)                                   rate_prec
           , imco.giorni_ruolo
           , imco.mesi_ruolo
           , stampa_common.f_formatta_numero(nvl(imco.versato_tot,0) * -1,'I','S')               versato_tot
           , stampa_common.f_formatta_numero(nvl(imco.maggiorazione_tares,0) -
                                             imco.versato_magg_tares -
                                             nvl(imco.magg_tares_evasa_accertata,0),'I','S')     magg_tares
           , stampa_common.f_formatta_numero(nvl(imco.compensazione,0),'I','S')                  compensazione
           , stampa_common.f_formatta_numero(nvl(imco_prec.addizionale_pro_prec,0),'I','S')      addizionale_pro_prec
           , stampa_common.f_formatta_numero(nvl(imco_prec.importo_netto_prec,0),'I','S')        importo_netto_prec
           , stampa_common.f_formatta_numero(nvl(imco_prec.importo_netto_prec,0) +
                                             nvl(imco_prec.addizionale_pro_prec,0),'I','S')      importo_lordo_prec
           , stampa_common.f_formatta_numero(
              decode(ruoli.tipo_emissione
                  ,'S',nvl(sgravi_cont.sgravio_lordo,0)
                  ,(select nvl(decode(nvl(sum(sgra.importo),0)
                                   ,f_sgravio_anno_escl(a_ruolo,a_cod_fiscale,'L'),0
                                   ,-1 * sum(nvl(sgra.importo, 0))
                                   )
                               ,0)
                    from sgravi sgra
                       ,ruoli ruol
                    where sgra.motivo_sgravio != 99
                         and sgra.cod_fiscale = a_cod_fiscale
                         and sgra.ruolo = a_ruolo
                         and sgra.ruolo = ruol.ruolo
                         and nvl(substr(sgra.note,1,1),' ') <> '*'
                         group by sgra.cod_fiscale,ruol.anno_ruolo)
                                       ),'I','S')           sgravio_lordo
           , stampa_common.f_formatta_numero(
              decode(ruoli.tipo_emissione
                  ,'S',nvl(sgravi_cont.sgravio_prov,0)
                  ,(select nvl(decode(nvl(sum(sgra.addizionale_pro),0)
                                   ,f_sgravio_anno_escl(a_ruolo,a_cod_fiscale,'P'),0
                                   ,-1 * sum(nvl(sgra.addizionale_pro,0))
                                   )
                               ,0)
                    from sgravi sgra
                       ,ruoli ruol
                    where sgra.motivo_sgravio != 99
                         and sgra.cod_fiscale = a_cod_fiscale
                         and sgra.ruolo = a_ruolo
                         and sgra.ruolo = ruol.ruolo
                         and nvl(substr(sgra.note,1,1),' ') <> '*'
                         group by sgra.cod_fiscale,ruol.anno_ruolo)
                                     ),'I','S')            sgravio_prov
           , stampa_common.f_formatta_numero(
              decode(ruoli.tipo_emissione
                  ,'S',nvl(sgravi_cont.sgravio_netto,0)
                  ,(select nvl(decode(nvl(sum(sgra.importo),0)
                                   ,f_sgravio_anno_escl(a_ruolo,a_cod_fiscale,'L'),0
                                   ,-1 * sum(nvl(sgra.importo, 0)-
                                             nvl(sgra.addizionale_pro,0)-
                                             nvl(sgra.maggiorazione_tares, 0))
                                   )
                               ,0)
                    from sgravi sgra
                       ,ruoli ruol
                    where sgra.motivo_sgravio != 99
                         and sgra.cod_fiscale = a_cod_fiscale
                         and sgra.ruolo = a_ruolo
                         and sgra.ruolo = ruol.ruolo
                         and nvl(substr(sgra.note,1,1),' ') <> '*'
                         group by sgra.cod_fiscale,ruol.anno_ruolo)
                                       ),'I','S')           sgravio_netto
           , stampa_common.f_formatta_numero(nvl(imco_prec.addizionale_pro_prec,0) -
                                             nvl(sgravi_cont.sgravio_prov,0),'I','S')            residuo_acconto_prov
           , stampa_common.f_formatta_numero(nvl(imco_prec.importo_netto_prec,0) -
                                             (nvl(sgravi_cont.sgravio_lordo,0) -
                                              nvl(sgravi_cont.sgravio_prov,0)),'I','S')           residuo_acconto_netto
           , stampa_common.f_formatta_numero(nvl(imco_prec.importo_netto_prec,0) +
                                             nvl(imco_prec.addizionale_pro_prec,0) -
                                             nvl( sgravi_cont.sgravio_lordo,0),'I','S')          residuo_acconto_lordo
           , stampa_common.f_formatta_numero(imco.dovuto_netto_annuo,'I','S')                    dovuto_netto_annuo
           , stampa_common.f_formatta_numero(imco.addizionale_pro_annua,'I','S')                 addizionale_pro_annua
           , stampa_common.f_formatta_numero(imco.comp_perequative_annue,'I','S')                comp_perequative_annue
           , stampa_common.f_formatta_numero(nvl(imco.dovuto_netto_annuo,0) +
                                             nvl(imco.addizionale_pro_annua,0) +
                                             nvl(imco.comp_perequative_annue,0),'I','S')         dovuto_lordo_annuo
           , stampa_common.f_formatta_numero(imco.importo_lordo_x_rate,'I','S')                  importo_lordo_x_rate
           , stampa_common.f_formatta_numero(imco.versato_netto_tot,'I','S')                     versato_netto_tot
           , stampa_common.f_formatta_numero(imco.magg_tares_dovuta,'I','S')                     magg_tares_dovuta
           , stampa_common.f_formatta_numero(imco.versato_magg_tares,'I','S')                    versato_magg_tares
           , stampa_common.f_formatta_numero(imco.imposta_evasa_accertata,'I','S')               imposta_evasa_accertata
           , stampa_common.f_formatta_numero(imco.magg_tares_evasa_accertata,'I','S')            magg_tares_evasa_accertata
           -- (VD - 23/08/2016): aggiunte colonne per adeguamento a stampa comunicazione
           , stampa_common.f_formatta_numero(nvl(imco.dovuto_netto_annuo,0) +
                                             nvl(sgravi_cont.sgravio_netto,0),'I','S')           tares_netta_annua
           , stampa_common.f_formatta_numero(nvl(imco.addizionale_pro_annua,0) +
                                             nvl(sgravi_cont.sgravio_prov,0),'I','S')            add_prov_annua
           , stampa_common.f_formatta_numero(nvl(imco.dovuto_netto_annuo,0) +
                                             nvl(imco.addizionale_pro_annua,0) +
                                             nvl(imco.comp_perequative_annue,0) +
                                             nvl(sgravi_cont.sgravio_lordo,0),'I','S')           importo_lordo_annuo
           -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
           , stampa_common.f_formatta_numero(imco.imposta_base,'I','S')                 imposta_base
           , stampa_common.f_formatta_numero(imco.addizionale_eca_base,'I','S')         addizionale_eca_base
           , stampa_common.f_formatta_numero(imco.maggiorazione_eca_base,'I','S')       maggiorazione_eca_base
           , stampa_common.f_formatta_numero(imco.addizionale_pro_base,'I','S')         addizionale_pro_base
           , stampa_common.f_formatta_numero(imco.iva_base,'I','S')                     iva_base
           , stampa_common.f_formatta_numero(imco.importo_pf_base,'I','S')              importo_pf_base
           , stampa_common.f_formatta_numero(imco.importo_pv_base,'I','S')              importo_pv_base
           , stampa_common.f_formatta_numero(imco.importo_ruolo_base,'I','S')           importo_ruolo_base
           , stampa_common.f_formatta_numero(imco.importo_pf,'I','S')                   importo_pf
           , stampa_common.f_formatta_numero(imco.importo_pv,'I','S')                   importo_pv
           , stampa_common.f_formatta_numero(imco.importo_riduzione_pf,'I','S')         importo_riduzione_pf
           , stampa_common.f_formatta_numero(imco.importo_riduzione_pv,'I','S')         importo_riduzione_pv
           , stampa_common.f_formatta_numero(sgravi_cont.sgravio_lordo_base,'I','S')    sgravio_lordo_base
           , stampa_common.f_formatta_numero(sgravi_cont.sgravio_prov_base,'I','S')     sgravio_prov_base
           , stampa_common.f_formatta_numero(sgravi_cont.sgravio_netto_base,'I','S')    sgravio_netto_base
           -- (VD - 01/04/2021): aggiunti dati per ruoli emessi dal 2021 in avanti (gestione TEFA)
           -- (VD - 03/11/2021): eliminata doppia formattazione errata
           , stampa_common.f_formatta_numero(
                decode(nvl(ruoli.tipo_emissione, 'T')
                    --,'S',stampa_common.f_formatta_numero(f_importi_ruolo_saldo(a_cod_fiscale,a_ruolo,'N'),'I','S')
                    ,'S',f_importi_ruolo_saldo(a_cod_fiscale,a_ruolo,'N') - f_importi_ruolo_saldo(a_cod_fiscale,a_ruolo,'M')
                    ,imco.imposta_solo_tributo
                    )
                ,'I','S') a2021_tastri_imposta -- Imposto TARI
           , stampa_common.f_formatta_numero(
                decode(f_get_cata_perc(ruoli.anno_ruolo,'AP')
                    ,0,''
                    ,decode(nvl(ruoli.tipo_emissione, 'T')
                           ,'S',f_importi_ruolo_saldo(a_cod_fiscale,a_ruolo,'P')
                           ,imco.addizionale_pro
                           )
                    )
                ,'I','S') a2021_tastri_add_pro -- Importo TEFA
           , decode(nvl(ruoli.tipo_emissione,'T')
                ,'S',stampa_common.f_formatta_numero(-1 * f_sgravio_anno(a_ruolo,a_cod_fiscale,'N'),'I','S')
                --,decode(nvl(sgravi_cont.sgravio_lordo,0)
                --       ,f_sgravio_anno_escl(a_ruolo,a_cod_fiscale,'L'),stampa_common.f_formatta_numero(0,'I','S')
                ,stampa_common.f_formatta_numero((select -1 * sum(nvl(sgra.importo, 0)-
                                                                nvl(sgra.addizionale_pro,0)-
                                                                nvl(sgra.maggiorazione_tares, 0))
                                                from sgravi sgra
                                                   ,ruoli ruol
                                                where sgra.motivo_sgravio != 99
                                                   and sgra.cod_fiscale = a_cod_fiscale
                                                   and sgra.ruolo = a_ruolo
                                                   and sgra.ruolo = ruol.ruolo
                                                   and nvl(substr(sgra.note,1,1),' ') <> '*'
                                                   group by sgra.cod_fiscale,ruol.anno_ruolo),'I','S')
                --      )
                ) a2021_sgravio_imposta
           , decode(f_get_cata_perc(ruoli.anno_ruolo,'AP')
                ,0,''
                ,decode(nvl(ruoli.tipo_emissione,'T')
                            ,'S',stampa_common.f_formatta_numero(-1 * f_sgravio_anno(a_ruolo,a_cod_fiscale,'A'),'I','S')
                            ,stampa_common.f_formatta_numero((select nvl(decode(nvl(sum(sgra.addizionale_pro),0)
                                                                             ,f_sgravio_anno_escl(a_ruolo,a_cod_fiscale,'P'),0
                                                                             ,-1 * sum(nvl(sgra.addizionale_pro,0))
                                                                             )
                                                                         ,0)
                                                              from sgravi sgra
                                                                 ,ruoli ruol
                                                              where sgra.motivo_sgravio != 99
                                                                 and sgra.cod_fiscale = a_cod_fiscale
                                                                 and sgra.ruolo = a_ruolo
                                                                 and sgra.ruolo = ruol.ruolo
                                                                 and nvl(substr(sgra.note,1,1),' ') <> '*'
                                                                 group by sgra.cod_fiscale,ruol.anno_ruolo)
                                         ,'I','S')
                            )
                ) a2021_sgravio_add_pro
           , decode(nvl(ruoli.tipo_emissione,'T')
                ,'S',stampa_common.f_formatta_numero(-1 * f_sgravio_anno(a_ruolo,a_cod_fiscale,'CN'),'I','S')
                ,stampa_common.f_formatta_numero(-1 * nvl(imco.compensazione_imposta,0),'I','S')
                ) a2021_comp_imposta
           , decode(f_get_cata_perc(ruoli.anno_ruolo,'AP')
                ,0,''
                ,decode(nvl(ruoli.tipo_emissione,'T')
                              ,'S',stampa_common.f_formatta_numero(-1 * f_sgravio_anno(a_ruolo,a_cod_fiscale,'CP'),'I','S')
                              ,stampa_common.f_formatta_numero(-1 * nvl(imco.compensazione_add_pro,0),'I','S')
                              )
                ) a2021_comp_add_pro
           , stampa_common.f_formatta_numero(imco.imposta_netta,'I','S') a2021_netto_imposta
           , decode(f_get_cata_perc(ruoli.anno_ruolo,'AP')
              ,0,''
              ,stampa_common.f_formatta_numero(imco.add_pro,'I','S')) a2021_netto_add_pro
           , stampa_common.f_formatta_numero(round(imco.imposta_netta) - imco.versato_imposta,'I','S') a2021_davers_imposta
           , stampa_common.f_formatta_numero(round(imco.add_pro) - imco.versato_add_pro,'I','S') a2021_davers_add_pro
           , stampa_common.f_formatta_numero(round(imco.imposta_netta) - imco.versato_imposta +
                                             round(imco.add_pro) - imco.versato_add_pro,'I','S') a2021_davers_totale
           , stampa_common.f_formatta_numero(imco.imposta_netta_arr,'I','S') a2021_totarr_imposta
           , decode(f_get_cata_perc(ruoli.anno_ruolo,'AP')
              ,0,''
              ,stampa_common.f_formatta_numero(imco.add_pro_arr,'I','S')) a2021_totarr_add_pro
           , stampa_common.f_formatta_numero(-1 * imco.versato_imposta,'I','S') a2021_versato_imposta
           , stampa_common.f_formatta_numero(-1 * imco.versato_add_pro,'I','S') a2021_versato_add_pro
           , stampa_common.f_formatta_numero(imco.imposta_netta_arr - imco.imposta_netta,'I','S') a2021_arr_imposta
           , decode(cata.addizionale_pro
              ,null,''
              ,stampa_common.f_formatta_numero(imco.add_pro_arr - imco.add_pro,'I','S')) a2021_arr_add_pro
           , stampa_common.f_formatta_numero((imco.imposta_arr - imco.imposta) + (imco.add_pro_arr - imco.add_pro)
             ,'I','S') a2021_arr_totale
           , case when ruoli.anno_ruolo >= 2024 then
               'Componenti Perequative'
             else
               ''
             end descr_comp_per
           , case when ruoli.anno_ruolo >= 2024 then
                stampa_common.f_formatta_numero(imco.comp_perequative,'I','S')
             else
               ''
             end importo_comp_per
           , stampa_common.f_formatta_numero(nvl(imco.comp_perequative,0),'I','S') a2021_tastri_comp_per
      from ruoli
         , carichi_tarsu      cata
         , ( select
                  max(dett.ruolo) as ruolo
                , max(dett.cod_fiscale) as cod_fiscale
                , sum(dett.importo_lordo) - sum(dett.sgravio) - sum(dett.compensazione) as importo_lordo
                , round(sum(dett.importo_lordo_x_rate_nr)
                      - sum(dett.sgravio)
                      + sum(dett.sgravio_magg_tares)
                      - sum(dett.compensazione), 0) as importo_lordo_x_rate
                , sum(dett.addizionale_eca) as addizionale_eca
                , sum(dett.maggiorazione_eca) as maggiorazione_eca
                , sum(dett.addizionale_pro) as addizionale_pro
                , sum(dett.iva) as iva
                , sum(dett.importo_netto)
                      - sum(dett.sgravio)
                      + sum(dett.sgravio_magg_tares)
                      - sum(dett.compensazione) as importo_netto
                , sum(dett.maggiorazione_tares) as maggiorazione_tares
                , max(dett.giorni_ruolo) as giorni_ruolo
                , max(dett.mesi_ruolo) as mesi_ruolo
                , sum(dett.versato_tot) as versato_tot
                , sum(dett.versato_netto_tot) as versato_netto_tot
                , sum(dett.compensazione) as compensazione
                , sum(dett.compensazione_imposta) as compensazione_imposta
                , sum(dett.compensazione_add_pro) as compensazione_add_pro
                , sum(dett.sgravio_add_pro) as sgravio_add_pro
                , sum(dett.dovuto_netto_annuo) as dovuto_netto_annuo
                , sum(dett.addizionale_pro_annua) as addizionale_pro_annua
                , sum(dett.magg_tares_dovuta) as magg_tares_dovuta
                , sum(dett.comp_perequative_annue) as comp_perequative_annue
                , sum(dett.versato_magg_tares) as versato_magg_tares
                , sum(dett.imposta_evasa_accertata) as imposta_evasa_accertata
                , sum(dett.magg_tares_evasa_accertata) as magg_tares_evasa_accertata
                , sum(dett.imposta_base) as imposta_base
                , sum(dett.addizionale_eca_base) as addizionale_eca_base
                , sum(dett.maggiorazione_eca_base) as maggiorazione_eca_base
                , sum(dett.addizionale_pro_base) as addizionale_pro_base
                , sum(dett.iva_base) as iva_base
                , sum(dett.importo_pf_base) as importo_pf_base
                , sum(dett.importo_pv_base) as importo_pv_base
                , sum(dett.importo_ruolo_base) as importo_ruolo_base
                , sum(dett.importo_pf) as importo_pf
                , sum(dett.importo_pv) as importo_pv
                , sum(dett.importo_riduzione_pf) as importo_riduzione_pf
                , sum(dett.importo_riduzione_pv) as importo_riduzione_pv
                , sum(dett.imposta) as imposta
                , round(sum(dett.imposta)) as imposta_arr
                , sum(dett.imposta_netta) as imposta_netta
                , sum(dett.addizionale_pro)
                      - sum(dett.sgravio_add_pro)
                      - sum(dett.compensazione_add_pro) as add_pro
                , round(sum(dett.imposta_netta)) as imposta_netta_arr
                , round(sum(dett.addizionale_pro)
                      - sum(dett.sgravio_add_pro)
                      - sum(dett.compensazione_add_pro)) as add_pro_arr
                , sum(dett.versato_imposta) as versato_imposta
                , sum(dett.versato_add_pro) as versato_add_pro
                , sum(dett.imposta_solo_tributo) as imposta_solo_tributo
                , sum(dett.comp_perequative) as comp_perequative
            from
                ( select r.ruolo
                       , r.cod_fiscale
                       , sum(r.importo) as importo_lordo
                       , sum(r.importo)
                         -- #72976    - nvl(sum(nvl(o.maggiorazione_tares,0)),0)
                         as importo_lordo_x_rate_nr
            -- gli importi sono calcolati come importo - gli sgravi sul ruolo
            -- meno le compensazioni sul ruolo - se il ruolo è totale i versamenti su tutto l'anno
            -- per determinare l'importo lordo, non consideriamo i versamenti
                       , sum(o.addizionale_eca) addizionale_eca
                       , sum(o.maggiorazione_eca) maggiorazione_eca
                       , sum(o.addizionale_pro) addizionale_pro
                       , sum(o.iva) iva
                       , sum(o.imposta) as importo_netto
                       , sum(o.maggiorazione_tares) maggiorazione_tares
                       , max(r.giorni_ruolo) giorni_ruolo
                       , max(r.mesi_ruolo) mesi_ruolo
                       , decode(nvl(ruol.tipo_emissione, 'T')
                          ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,null
                                          ,'V') --||a_se_vers_positivi)
                          ,0) versato_tot
                       , decode(nvl(ruol.tipo_emissione, 'T')
                          ,'T', f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,null
                                          ,'VN') --||a_se_vers_positivi)
                          ,0) versato_netto_tot
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                            ,r.cod_fiscale
                            ,ruol.tipo_tributo
                            ,r.ruolo
                            ,'C') compensazione
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                            ,r.cod_fiscale
                            ,ruol.tipo_tributo
                            ,r.ruolo
                            ,'CN') compensazione_imposta
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                            ,r.cod_fiscale
                            ,ruol.tipo_tributo
                            ,r.ruolo
                            ,'CP') compensazione_add_pro
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                             ,r.cod_fiscale
                             ,ruol.tipo_tributo
                             ,r.ruolo
                             ,'S') as sgravio
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                            ,r.cod_fiscale
                            ,ruol.tipo_tributo
                            ,r.ruolo
                            ,'SP') as sgravio_add_pro
                       , f_tot_vers_cont_ruol(ruol.anno_ruolo
                            ,r.cod_fiscale
                            ,ruol.tipo_tributo
                            ,r.ruolo
                            ,'SM') as sgravio_magg_tares
                       , sum(nvl(o.imposta_dovuta,o.imposta)) dovuto_netto_annuo
                       , sum(round(nvl(o.imposta_dovuta,o.imposta) * catu.addizionale_pro / 100
                          ,2)) addizionale_pro_annua
                       , sum(o.maggiorazione_tares) magg_tares_dovuta
                       , sum(o.maggiorazione_tares) comp_perequative_annue
                       , decode(nvl(ruol.tipo_emissione, 'T')
                          ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                          ,r.cod_fiscale
                                          ,ruol.tipo_tributo
                                          ,null
                                          ,'M')
                          ,0
                          ) versato_magg_tares
                       , decode(nvl(ruol.tipo_emissione,'T')
                          ,'T',decode(ruol.tipo_ruolo
                                          ,2,F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'N')
                                          ,0
                                          )
                          ,0
                          ) imposta_evasa_accertata
                       , decode(nvl(ruol.tipo_emissione,'T')
                          ,'T',decode(ruol.tipo_ruolo
                                          ,2,F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'S')
                                          ,0
                                          )
                          ,0
                          ) magg_tares_evasa_accertata
                       -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
                       , sum(o.imposta_base)           imposta_base
                       , sum(o.addizionale_eca_base)   addizionale_eca_base
                       , sum(o.maggiorazione_eca_base) maggiorazione_eca_base
                       , sum(o.addizionale_pro_base)   addizionale_pro_base
                       , sum(o.iva_base)               iva_base
                       , sum(o.importo_pf_base)        importo_pf_base
                       , sum(o.importo_pv_base)        importo_pv_base
                       , sum(o.importo_ruolo_base)     importo_ruolo_base
                       -- (VD - 27/03/2019): aggiunti importi pf, pv e relative riduzioni
                       , sum(o.importo_pf)             importo_pf
                       , sum(o.importo_pv)             importo_pv
                       , sum(o.importo_riduzione_pf)   importo_riduzione_pf
                       , sum(o.importo_riduzione_pv)   importo_riduzione_pv
                       -- (VD - 31/03/2021): aggiunti campi per gestione TEFA 2021
                       , (sum(o.imposta)
                         + nvl(sum(nvl(o.maggiorazione_tares,0)),0)    -- #72976
                         ) imposta
                       , sum(o.imposta)
                         + nvl(sum(nvl(o.maggiorazione_tares,0)),0)    -- #72976
                        - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                 ,r.cod_fiscale
                                 ,ruol.tipo_tributo
                                 ,r.ruolo
                                 ,'SN')
                        - f_tot_vers_cont_ruol(ruol.anno_ruolo
                                 ,r.cod_fiscale
                                 ,ruol.tipo_tributo
                                 ,r.ruolo
                                 ,'CN')         imposta_netta
                       , decode(nvl(ruol.tipo_emissione, 'T')
                        ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VI')
                        ,0
                        ) versato_imposta
                       , decode(nvl(ruol.tipo_emissione, 'T')
                        ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VP')
                        ,0
                        ) versato_add_pro
                       -- Componenti perequative
                       , sum(o.imposta) imposta_solo_tributo
                       , sum(o.maggiorazione_tares) comp_perequative
                  from ruoli_contribuente r
                     , oggetti_imposta o
                     , ruoli ruol
                     , carichi_tarsu catu
                  where r.ruolo = a_ruolo
                    and r.cod_fiscale = a_cod_fiscale
                    and o.ruolo = r.ruolo
                    and r.oggetto_imposta = o.oggetto_imposta
                    and catu.anno = ruol.anno_ruolo
                    and ruol.ruolo = r.ruolo
                  group by r.ruolo
                         , r.cod_fiscale
                         , ruol.anno_ruolo
                         , ruol.tipo_tributo
                         , ruol.tipo_emissione
                         , ruol.rate
                         , ruol.tipo_ruolo
                union
                   select
                         r.ruolo
                       , r.cod_fiscale
                       , sum(r.importo_ruolo) as importo
                       , sum(r.importo_ruolo) as importo_lordo_x_rate_nr
                       , 0 as addizionale_eca
                       , 0 as maggiorazione_eca
                       , sum(r.addizionale_pro) as addizionale_pro
                       , 0 as iva
                       , sum(r.imposta) as importo_netto
                       , 0 as maggiorazione_tares
                       , 0 as giorni_ruolo
                       , 0 as mesi_ruolo
                       , 0 as versato_tot
                       , 0 as versato_netto_tot
                       , 0 as compensazione
                       , 0 as compensazione_imposta
                       , 0 as compensazione_add_pro
                       , 0 as sgravio
                       , 0 as sgravio_add_pro
                       , 0 as sgravio_magg_tares
                       , sum(r.imposta) as dovuto_netto_annuo
                       , sum(round(r.imposta * catu.addizionale_pro / 100,2)) addizionale_pro_annua
                       , 0 as magg_tares_dovuta
                       , 0 as comp_perequative_annue
                       , 0 as versato_magg_tares
                       , 0 as imposta_evasa_accertata
                       , 0 as magg_tares_evasa_accertata
                       , 0 as imposta_base
                       , 0 as addizionale_eca_base
                       , 0 as maggiorazione_eca_base
                       , 0 as addizionale_pro_base
                       , 0 as iva_base
                       , 0 as importo_pf_base
                       , 0 as importo_pv_base
                       , 0 as importo_ruolo_base
                       , 0 as importo_pf
                       , 0 as importo_pv
                       , 0 as importo_riduzione_pf
                       , 0 as importo_riduzione_pv
                       , sum(r.imposta) as imposta
                       , sum(r.imposta) as imposta_netta
                       , 0 as versato_imposta
                       , 0 as versato_add_pro
                       , sum(r.imposta) as imposta_solo_tributo
                       , 0 as comp_perequative
                   from ruoli_eccedenze r,
                        ruoli ruol,
                        carichi_tarsu catu
                  where r.ruolo = a_ruolo
                    and r.cod_fiscale = a_cod_fiscale
                    and ruol.ruolo = r.ruolo
                    and catu.anno = ruol.anno_ruolo
                  group by r.ruolo
                         , r.cod_fiscale
                         , ruol.anno_ruolo
                         , ruol.tipo_tributo
                         , ruol.tipo_emissione
                         , ruol.rate
                         , ruol.tipo_ruolo
                ) dett
           ) imco
         , -- (10/03/2025 (RV) :  Non serve contabilizzare le Eccedenze in quanto ad oggi
           --                     esse sono conteggiate solo dei Supplettivi Totali
           --                     Qui prende solo quelli in Acconto Inviati
           (select
                r.cod_fiscale
              , ruol.tipo_tributo
              , (sum(r.importo)
                - sum(f_tot_vers_cont_ruol(ruol.anno_ruolo
                      ,r.cod_fiscale
                      ,ruol.tipo_tributo
                      ,r.ruolo
                      ,'C'))
                - decode(nvl(ruol.tipo_emissione, 'T')
                         ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                  ,r.cod_fiscale
                                  ,ruol.tipo_tributo
                                  ,null
                                  ,'V'||a_se_vers_positivi)
                             + decode(ruol.tipo_ruolo
                                  ,2,round(F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                  ,0
                                  )
                       ,0)

                 ) importo_lordo_PREC
               , sum(o.addizionale_eca)    addizionale_eca_PREC
               , sum(o.maggiorazione_eca)  maggiorazione_eca_PREC
               , sum(o.addizionale_pro)    addizionale_pro_PREC
               , sum(o.iva)                iva_PREC
               , sum(o.imposta)            importo_netto_PREC
               , (sum(o.maggiorazione_tares)
                  - decode(nvl(ruol.tipo_emissione, 'T')
                       ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                ,r.cod_fiscale
                                ,ruol.tipo_tributo
                                ,null
                                ,'M')
                           + decode (ruol.tipo_ruolo
                                ,2,round(F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'S'),0)
                                ,0
                                )
                       ,0)
                  ) maggiorazione_tares_PREC
                , max(r.giorni_ruolo) giorni_ruolo_PREC
                , max(decode(ruol.rate,0,1
                    ,null,1
                    ,ruol.rate)
                  ) rate_ruolo_prec
                -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
                , sum(o.imposta_base)           imposta_base_prec
                , sum(o.addizionale_eca_base)   add_eca_base_prec
                , sum(o.maggiorazione_eca_base) magg_eca_base_prec
                , sum(o.addizionale_pro_base)   add_pro_base_prec
                , sum(o.iva_base)               iva_base_prec
                , sum(o.importo_pf_base)        importo_pf_base_prec
                , sum(o.importo_pv_base)        importo_pv_base_prec
                , sum(o.importo_ruolo_base)     importo_ruolo_base_prec
             from ruoli_contribuente r,
                  oggetti_imposta o,
                  ruoli ruol
            where ruol.ruolo in (select ruol_prec.ruolo
                                   from ruoli, ruoli ruol_prec
                                  where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
                                    and ruol_prec.invio_consorzio(+) is not null
                                    and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
                                    and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
                                    and ruoli.ruolo = a_ruolo)
              and o.ruolo = r.ruolo
              and r.oggetto_imposta = o.oggetto_imposta
              and ruol.ruolo = r.ruolo
            group by r.cod_fiscale
                   , ruol.anno_ruolo
                   , ruol.tipo_tributo
                   , ruol.tipo_emissione
                   , ruol.rate
                   , ruol.tipo_ruolo
           ) imco_prec
         , (select sum(importo) sgravio_lordo
                 , sum(addizionale_pro) sgravio_prov
                 , sum(nvl(importo,0) - nvl(addizionale_pro,0)) sgravio_netto
                 -- (VD - 13/12/2018): aggiunti dati relativi al calcolo con tariffa base
                 , sum(importo_base) sgravio_lordo_base
                 , sum(addizionale_pro_base) sgravio_prov_base
                 , sum(nvl(importo_base,0) - nvl(addizionale_pro_base,0)) sgravio_netto_base
                 , cod_fiscale
              from sgravi
             where sgravi.ruolo in (select ruol_prec.ruolo
                                   from ruoli, ruoli ruol_prec
                                   where nvl(ruol_prec.tipo_emissione(+),'T') = 'A'
                                     and ruol_prec.invio_consorzio(+) is not null
                                     and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
                                     and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
                                     and ruoli.ruolo = a_ruolo)
               and motivo_sgravio != 99
             group by cod_fiscale
           ) sgravi_cont
      where ruoli.ruolo                    = a_ruolo
        and imco.ruolo                     = ruoli.ruolo
        and cata.anno                      = ruoli.anno_ruolo
        and imco.cod_fiscale               = a_cod_fiscale
        and imco_prec.cod_fiscale (+)      = imco.cod_fiscale
        and sgravi_cont.cod_fiscale (+)    = imco.cod_fiscale
    ;
  --
  return rc;
  --
end dati_ruolo;
--------------------------------------------------------------------
function dati_rate
--------------------------------------------------------------------
  -- (VD - 19/10/2021): Modifica per gestione TEFA in passaggio a DEPAG
  --                    il Depag non prevede la gestione di incassi per
  --                    più enti dallo stesso pagamento, quindi, in
  --                    presenza di TEFA per anno >= 2021, la rateizzazione
  --                    viene eseguita col vecchio metodo, arrotondando
  --                    l'importo complessivo della rata e non arrotondando
  --                    singolarmente TARI e TEFA
--------------------------------------------------------------------
  -- (RV - 30/05/2024): #72976
  --                    Per gestire le componenti perequative (al momento gestite
  --                    come maggiorazione tares) è stato eliminata l'esclusione
  --                    di tali importi dai totali usata in precedenza come
  --                    differenziazione contabile
--------------------------------------------------------------------
( a_ruolo                     number     default -1
, a_cod_fiscale               varchar2   default ''
, a_modello                   number     default -1
) return sys_refcursor
is
  --
  a_spese_postali             number;
  a_se_vers_positivi          varchar2(1);
  a_importo_totale_arr        number;
  a_importo_totale_lordo      number;
  a_importo_versato           number;
  a_importo_versato_temp      number;
  a_numero_rate               number;
  a_flag_depag                varchar2(1);
  --
  a_importo_totale_sbil       number;
  a_sbil_tares_ruolo          number;
  a_sbil_tares_rata           number;
  --
  rc                          sys_refcursor;
  --
  type t_importo_rata is table of number
  index by binary_integer;
  --
  w_importo_rata              t_importo_rata;
  w_ind                       integer;
  w_importo_rata_1            number := to_number(null);
  w_importo_rata_2            number := to_number(null);
  w_importo_rata_3            number := to_number(null);
  w_importo_rata_4            number := to_number(null);
  --
begin
    -- a_modello = -1 viene utilizzato per creare i campi unione nelle stampe
    -- Attenzione: per ora il parametro a_se_vers_positivi non viene utilizzato,
    -- perchè non è utilizzato neanche in Power Builder
    if a_modello <> -1 and nvl(f_descrizione_timp(a_modello,'VERS_POSITIVI'),'NO') = 'SI' then
       a_se_vers_positivi := '+';
    else
       a_se_vers_positivi := '';
    end if;
    --
    -- Selezione spese postali
    --
    begin
      select nvl(sanzione,0)
        into a_spese_postali
        from sanzioni
       where sanzioni.cod_sanzione = 115
         and sanzioni.tipo_tributo = 'TARSU'
         and sanzioni.sequenza = 1;
    exception
      when others then
        a_spese_postali := 0;
    end;
    --
    -- Determinazione dell'importo totale del ruolo arrotondato
    --
    begin
        select round(nvl(imco.importo_lordo,0)
         -- #72976   - nvl(imco.maggiorazione_tares,0)
                     + a_spese_postali,0) -
           round(imco.versato_netto_tot,0) -
           round(nvl(imco.imposta_evasa_accertata,0),0) importo_totale_arr
         , round(nvl(imco.importo_lordo,0)
         -- #72976   - nvl(imco.maggiorazione_tares,0)
                     + a_spese_postali,0) -
           round(nvl(imco.imposta_evasa_accertata,0),0) importo_totale_lordo
         , round(imco.versato_netto_tot,0) importo_versato
         , ruoli.rate
         , nvl(ruoli.flag_depag,'N')
         , f_sbilancio_tares(imco.cod_fiscale,ruoli.ruolo,0,0,'S') as sbil_tares_ruolo
      into a_importo_totale_arr
          , a_importo_totale_lordo
          , a_importo_versato
          , a_numero_rate
          , a_flag_depag
          , a_sbil_tares_ruolo
      from ruoli
         , (select
              max(dett.ruolo) as ruolo
            , max(dett.cod_fiscale) as cod_fiscale
            , sum(dett.totale_lordo)
                - sum(dett.totale_sgravi)
                - sum(dett.totale_compensazioni) as importo_lordo
            , sum(dett.maggiorazione_tares)as maggiorazione_tares
            , sum(dett.versato_netto_tot)as versato_netto_tot
            , sum(dett.imposta_evasa_accertata)as imposta_evasa_accertata
          from
              ( select r.ruolo
                     , r.cod_fiscale
                     , sum(r.importo) as totale_lordo
                     , f_tot_vers_cont_ruol(ruol.anno_ruolo
                           ,r.cod_fiscale
                           ,ruol.tipo_tributo
                           ,r.ruolo
                           ,'S') as totale_sgravi
                     , f_tot_vers_cont_ruol(ruol.anno_ruolo
                           ,r.cod_fiscale
                           ,ruol.tipo_tributo
                           ,r.ruolo
                           ,'C') as totale_compensazioni
                     , sum(o.maggiorazione_tares) maggiorazione_tares
                     , decode(nvl(ruol.tipo_emissione, 'T')
                        ,'T',f_tot_vers_cont_ruol(ruol.anno_ruolo
                                        ,r.cod_fiscale
                                        ,ruol.tipo_tributo
                                        ,null
                                        ,'VN') --||a_se_vers_positivi)
                        ,0
                        ) versato_netto_tot
                     , decode(nvl(ruol.tipo_emissione,'T')
                        ,'T',decode(ruol.tipo_ruolo
                                        ,2,F_IMPOSTA_EVASA_ACC(r.cod_fiscale,'TARSU',ruol.anno_ruolo,'N')
                                        ,0
                                        )
                        ,0
                        ) imposta_evasa_accertata
                 from ruoli_contribuente r
                    , oggetti_imposta o
                    , ruoli ruol
                where r.ruolo           = a_ruolo
                  and r.cod_fiscale     = a_cod_fiscale
                  and o.ruolo           = r.ruolo
                  and r.oggetto_imposta = o.oggetto_imposta
                  and ruol.ruolo        = r.ruolo
                group by r.ruolo
                       , r.cod_fiscale
                       , ruol.anno_ruolo
                       , ruol.tipo_tributo
                       , ruol.tipo_emissione
                       , ruol.tipo_ruolo
             union
               select r.ruolo
                    , r.cod_fiscale
                    , sum(r.importo_ruolo) as totale_lordo
                    , 0 as totale_sgravi
                    , 0 as totale_compensazioni
                    , 0 as maggiorazione_tares
                    , 0 as versato_netto_tot
                    , 0 as imposta_evasa_accertata
                 from ruoli_eccedenze r,
                      ruoli ruol
                where r.ruolo           = a_ruolo
                  and r.cod_fiscale     = a_cod_fiscale
                  and ruol.ruolo        = r.ruolo
                group by r.ruolo
                       , r.cod_fiscale
                       , ruol.anno_ruolo
                       , ruol.tipo_tributo
                       , ruol.tipo_emissione
                       , ruol.tipo_ruolo
            ) dett
          ) imco
      where ruoli.ruolo                 = a_ruolo
        and imco.ruolo                  = ruoli.ruolo
        and imco.cod_fiscale            = a_cod_fiscale
      ;
    exception
          when others then
            a_importo_totale_arr   := 0;
            a_importo_totale_lordo := 0;
            a_importo_versato      := 0;
            a_numero_rate          := 1;
            a_flag_depag           := null;
            a_sbil_tares_ruolo     := 0;
    end;
    --
    a_importo_totale_arr := nvl(a_importo_totale_arr,0);
    --
    -- Calcolo importo rate ed applicazione eventuale sbilancio
    --
    a_importo_totale_sbil := a_importo_totale_lordo - a_sbil_tares_ruolo;
    --
    w_importo_rata.delete;
    for w_ind in 1..a_numero_rate
    loop
      a_sbil_tares_rata := f_sbilancio_tares(a_cod_fiscale,a_ruolo,w_ind,0,'S');
      w_importo_rata(w_ind) := f_determina_rata(a_importo_totale_sbil,w_ind,a_numero_rate,0) + a_sbil_tares_rata;
    --dbms_output.put_line('Sbilancio : '||a_sbil_tares_ruolo||', rata '||w_ind||': '||a_sbil_tares_rata);
    end loop;
    --
    -- Sottrazione versato
    --
    a_importo_versato_temp := a_importo_versato;
    --
    for w_ind in 1..a_numero_rate
    loop
      if a_importo_versato > 0 then
         if a_importo_versato <= w_importo_rata (w_ind) then
            w_importo_rata (w_ind) := w_importo_rata (w_ind) - a_importo_versato;
            a_importo_versato := 0;
         else
            a_importo_versato := a_importo_versato - w_importo_rata(w_ind);
            w_importo_rata (w_ind) := 0;
         end if;
      end if;
    end loop;
    --
    a_importo_versato := a_importo_versato_temp;
    --
    for w_ind in 1..a_numero_rate
    loop
      if w_ind = 1 then
         w_importo_rata_1 := w_importo_rata (1);
      elsif w_ind = 2 then
         w_importo_rata_2 := w_importo_rata (2);
      elsif w_ind = 3 then
         w_importo_rata_3 := w_importo_rata (3);
      else
         w_importo_rata_4 := w_importo_rata (4);
      end if;
    end loop;
    --
    -- Selezione dati rate per il contribuente
    --
    open rc for
    select distinct
        to_char(raim.rata) rata
                  , to_char(decode(raim.rata,1,ruol.scadenza_prima_rata
                                ,2,ruol.scadenza_rata_2
                                ,3,ruol.scadenza_rata_3
                                ,4,ruol.scadenza_rata_4
                                ,to_date(null)
                                )
        ,'dd/mm/yyyy') scadenza_rata
                  , stampa_common.f_formatta_numero(decode(raim.rata,1,w_importo_rata_1
                                                        ,2,w_importo_rata_2
                                                        ,3,w_importo_rata_3
                                                        ,4,w_importo_rata_4
                                                        )
    /*                         decode(raim.rata
                                   ,nvl(ruol.rate,1),a_importo_totale_arr -
                                                    (round(a_importo_totale_arr / ruol.rate) * (ruol.rate - 1))
                                                    ,round(a_importo_totale_arr / ruol.rate)
                                   )*/
        ,'I','S') importo_rata
                  , to_char(null) importo_rata_tari
                  , to_char(null) importo_rata_tefa
                  , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
                  , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
    from ruoli              ruol,
         ruoli_contribuente ruco,
         oggetti_imposta    ogim,
         rate_imposta       raim
    where ruol.ruolo               = a_ruolo
      and ruco.ruolo               = ruol.ruolo
      and ruco.cod_fiscale         = a_cod_fiscale
      and ogim.oggetto_imposta     = ruco.oggetto_imposta
      and raim.oggetto_imposta     = ogim.oggetto_imposta
      and (f_descrizione_timp(a_modello,'RATE_SCADUTE') = 'NO' or
           (f_descrizione_timp(a_modello,'RATE_SCADUTE') = 'SI' and
            decode(raim.rata,1,ruol.scadenza_prima_rata
                ,2,ruol.scadenza_rata_2
                ,3,ruol.scadenza_rata_3
                ,4,ruol.scadenza_rata_4) <= trunc(sysdate)))
      and (ruol.anno_ruolo < 2021 or a_flag_depag = 'S')
    union
    select 'UNICA' rata
         , to_char(nvl(ruol.scadenza_rata_unica, ruol.scadenza_prima_rata),'dd/mm/yyyy')
         , stampa_common.f_formatta_numero(a_importo_totale_arr,'I','S') importo_rata
         , to_char(null) importo_rata_tari
         , to_char(null) importo_rata_tefa
         , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
         , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
    from ruoli ruol
    where f_descrizione_timp(a_modello,'RATA_UNICA') = 'SI'
      and ruol.ruolo = a_ruolo
      and (ruol.anno_ruolo < 2021 or (a_flag_depag = 'S' and a_importo_versato = 0))
    /*     and ruol.rate = 1
           and not exists (select 'x'
                             from rate_imposta raim
                                , ruoli_contribuente ruco
                            where ruco.ruolo = ruol.ruolo
                              and ruco.cod_fiscale = a_cod_fiscale
                              and ruco.oggetto_imposta = raim.oggetto_imposta) */
    union
    select distinct
        to_char(rate.rata) rata
                  , to_char(decode(rate.rata,1,ruol.scadenza_prima_rata
                                ,2,ruol.scadenza_rata_2
                                ,3,ruol.scadenza_rata_3
                                ,4,ruol.scadenza_rata_4
                                ,to_date(null)
                                )
        ,'dd/mm/yyyy') scadenza_rata
                  , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                                        ,a_ruolo
                                                        ,a_numero_rate
                                                        ,rate.rata
                                                        ,'X',''
                                                        )
        ,'I','S') importo_rata
                  , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                                        ,a_ruolo
                                                        ,a_numero_rate
                                                        ,rate.rata
                                                        ,'Q',''
                                                        )
        ,'I','S') importo_rata_tari
                  , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                                        ,a_ruolo
                                                        ,a_numero_rate
                                                        ,rate.rata
                                                        ,'P',''
                                                        )
        ,'I','S') importo_rata_tefa
                  , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
                  , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
    from ruoli              ruol,
         ruoli_contribuente ruco,
         (select 1 rata from dual
          union
          select 2 from dual
          union
          select 3 from dual
          union
          select 4 from dual) rate
    where ruol.ruolo               = a_ruolo
      and ruco.ruolo               = ruol.ruolo
      and ruco.cod_fiscale         = a_cod_fiscale
      and rate.rata               <= a_numero_rate
      and (f_descrizione_timp(a_modello,'RATE_SCADUTE') = 'NO' or
           (f_descrizione_timp(a_modello,'RATE_SCADUTE') = 'SI' and
            decode(rate.rata,1,ruol.scadenza_prima_rata
                ,2,ruol.scadenza_rata_2
                ,3,ruol.scadenza_rata_3
                ,4,ruol.scadenza_rata_4) <= trunc(sysdate)))
      and (ruol.anno_ruolo >= 2021 and a_flag_depag = 'N')
    union
    select 'UNICA' rata
         , to_char(nvl(ruol.scadenza_rata_unica, ruol.scadenza_prima_rata),'dd/mm/yyyy')
         , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                               ,a_ruolo
                                               ,a_numero_rate
                                               ,0,'X',''
                                               )
        ,'I','S') importo_rata
         , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                               ,a_ruolo
                                               ,a_numero_rate
                                               ,0,'Q',''
                                               )
        ,'I','S') importo_rata_tari
         , stampa_common.f_formatta_numero(f_calcolo_rata_tarsu(a_cod_fiscale
                                               ,a_ruolo
                                               ,a_numero_rate
                                               ,0,'P',''
                                               )
        ,'I','S') importo_rata_tefa
         , f_descrizione_timp(a_modello,'RATA_UNICA') stampa_rata_unica
         , f_descrizione_timp(a_modello,'RATE_SCADUTE') stampa_rate_scadute
    from ruoli ruol
    where f_descrizione_timp(a_modello,'RATA_UNICA') = 'SI'
      and ruol.ruolo = a_ruolo
      and (ruol.anno_ruolo >= 2021 and a_flag_depag = 'N')
    order by 1;
   --
   return rc;
   --
end dati_rate;
--------------------------------------------------------------------
function dati_utenze
  ( a_ruolo                     number       default -1
  , a_cod_fiscale               varchar2     default ''
  , a_modello                   number     default -1
  ) return sys_refcursor is
    p_da_sostituire             varchar2(1);
    p_sostituto                 varchar2(1);
    rc                          sys_refcursor;
begin
    --
    -- (VD - 30/03/2021): Selezione del parametro NLS_NUMERIC_CHARACTERS
    --
begin
select decode(substr(value,1,1)
    ,'.',',','.')
     , substr(value,1,1)
into p_da_sostituire
    , p_sostituto
from nls_session_parameters
where parameter = 'NLS_NUMERIC_CHARACTERS';
exception
      when others then
        p_da_sostituire := ',';
        p_sostituto := '.';
end;
  open rc for
  select decode(ogge.cod_via
             , null,ogge.indirizzo_localita
             , arvi.denom_uff
             ) ||
         decode(ogge.num_civ
             , null, ''
             , ', ' || to_char(ogge.num_civ)
             ) ||
         decode(ogge.suffisso
              , null, ''
              , '/' || ogge.suffisso) indirizzo_utenza
       , decode(cate.flag_domestica,'S','UD','UND')||
                 ' Cat. '||cate.categoria||
                 decode(cate.descrizione
                      , null, ''
                      , ' - '||cate.descrizione) dati_categoria
       , decode(tari.descrizione
              , null, ''
              , tari.descrizione) dati_tariffa
      , ltrim(decode(ogge.partita,null,'',' Part.'||trim(ogge.partita))
              ||decode(ogge.sezione,null,'',' Sez.'||trim(ogge.sezione))
              ||decode(ogge.foglio,null,'',' Fg.'||trim(ogge.foglio))
              ||decode(ogge.numero,null,'',' Num.'||trim(ogge.numero))
              ||decode(ogge.subalterno,null,'',' Sub.'||trim(ogge.subalterno))
              ||decode(ogge.zona,null,'',' Zona '||trim(ogge.zona)))  estremi_catastali
      , decode(ogge.categoria_catasto,null,'','Cat.'||OGGE.categoria_catasto) categoria_catasto
      , decode(ogpr.consistenza,null,'','MQ ' || stampa_common.f_formatta_numero(ogpr.consistenza,'I','S')) superficie
      , decode(ruco.giorni_ruolo, null,'MM' || to_char(ruco.mesi_ruolo,'990')
      , 'GG' || to_char(ruco.giorni_ruolo,'990')) periodo_ruolo
      , stampa_common.f_formatta_numero(nvl(ogim.imposta_dovuta,ogim.imposta),'I','S') imposta
      , decode(nvl(ogim.maggiorazione_tares,0)
              ,0,''
              ,stampa_common.f_formatta_numero(ogim.maggiorazione_tares,'I','S')) magg_tares
       -- riepilogo importi per oggetto
      , stampa_common.f_formatta_numero(ogim.imposta
                                             + nvl(ogim.addizionale_pro,0)
                                             + nvl(ogim.maggiorazione_tares,0)
                                             + nvl(sgra.sgravio,0)
                                             + nvl(sgra.sgravio_escl,0) ,'I','S') residuo_lordo
       , stampa_common.f_formatta_numero(ogim.imposta,'I','S') imposta_netta
       , decode(nvl(cata.addizionale_pro, 0)
                ,0,''
                ,stampa_common.f_formatta_numero(decode(ruoli.importo_lordo
                                           ,'S',ogim.addizionale_pro
                                           ,round(ogim.imposta * nvl(cata.addizionale_pro,0) / 100,2)
                                           )
                    ,'I','S'
                    )
              ) add_pro
       , stampa_common.f_formatta_numero((ogim.imposta
                                           + nvl(ogim.addizionale_pro,0)
                                           + nvl(ogim.maggiorazione_tares,0)
                                           + f_sgravio_ruco_escl(a_ruolo,a_cod_fiscale,ruco.sequenza,'L')
                                         ),'I','S'
              ) imposta_lorda
       -- campi riepilogo per ruoli a saldo
       , decode(ruoli.tipo_emissione
                ,'S',stampa_common.f_formatta_numero(
                        decode(ruoli.tipo_ruolo
                            ,1,nvl(ogim.imposta_dovuta,ogim.imposta) -
                                   -- (VD - 04/04/2022): aggiunto nvl della instr. La stringa "conferimento" potrebbe non essere presente,
                                   --                    rendendo di fatto nullo l'importo dell'imposta netta annua
                               decode(nvl(instr(ogim.dettaglio_ogim,'conferimento'),0)
                                   ,0,0
                                   ,to_number(translate(substr(dettaglio_ogim,instr(dettaglio_ogim,' ',-1) + 1),p_da_sostituire,p_sostituto)))
                            ,trim(to_number(translate(substr(ogim.note,instr(ogim.note,':',1,1)+1,instr(ogim.note,'-',1,1)-2 -instr(ogim.note,':',1,1))
                            ,p_da_sostituire,p_sostituto))
                                   )
                            )
                    ,'I','S'
                    )
              ,''
              ) imposta_netta_annua
       , decode(ruoli.tipo_emissione
               ,'S',stampa_common.f_formatta_numero(
                        decode(ruoli.tipo_ruolo
                            ,1,nvl(f_importi_ruolo_acconto( a_cod_fiscale
                                       , ruoli.anno_ruolo
                                       , ruoli.progr_emissione
                                       , ogco.data_decorrenza
                                       , ogco.data_cessazione
                                       , ruoli.tipo_tributo
                                       , ogpr.oggetto
                                       , ogpr.oggetto_pratica
                                       -- (VD - 05/04/2022): segnalazione di REGGELLO. Sostituito ogpr.oggetto_pratica_rif
                                       --                    con nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                       --, ogpr.oggetto_pratica_rif
                                       , nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                       , ruoli.tipo_calcolo
                                       , 'N'
                                       , 'I'
                                       ),0) * -1,
                            -- (VD - 19/05/2022): segnalazione di ALBANO S.ALESSANDRO: invalid number perchè manca
                            --                    la conversione dei separatori di decimali e migliaia
                               to_number(translate(substr(ogim.note,instr(ogim.note,':',1,2)+1,instr(ogim.note,' ',1,8)-1 -instr(ogim.note,':',1,2))
                                   ,p_da_sostituire,p_sostituto
                                   )
                                   ) * -1
                            )
                    ,'I','S'
                    )
              ,'') imposta_netta_acconto
       , ogpr.oggetto_pratica
       , ogim.oggetto_imposta
       , ogpr.oggetto
       , cate.flag_domestica
       , ogpr.consistenza     mq
       , ltrim(regexp_replace(replace(f_get_familiari_ogim (ogim.oggetto_imposta )
                                  ,'[a_capo',' - '),'( ){2,}', ' '),' - ') stringa_familiari
       , a_modello modello
       , nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_fissa,'P','S')
            ,' ') riduzione_quota_fissa
       , nvl(stampa_common.f_formatta_numero(tari.riduzione_quota_variabile,'P','S')
            ,' ') riduzione_quota_variabile
       , decode(nvl(ogim.maggiorazione_tares,0),0,'',' + Componenti Perequative: € ') stringa_perequative
       , decode(nvl(ogim.maggiorazione_tares,0),0,''
              ,stampa_common.f_formatta_numero(ogim.maggiorazione_tares,'I','S')) componenti_perequative
       , decode(nvl(ogim.maggiorazione_tares,0),0,''
              ,f_get_componenti_perequative(ruoli.anno_ruolo, ogim.maggiorazione_tares)) dett_componenti_perequative
  from ruoli,
       ruoli_contribuente ruco,
       oggetti_imposta ogim,
       oggetti_pratica ogpr,
       oggetti_contribuente ogco,
       categorie cate,
       carichi_tarsu cata,
       tariffe tari,
       oggetti ogge,
       archivio_vie arvi,
       (select sequenza
             , sum(decode(f_stampa_com_ruolo(a_ruolo),1,
                          decode( substr(nvl(note,' '),1,1),'*', 0,
                                  nvl (importo, 0)
                              )))
               * -1
                                                          sgravio
             , sum(maggiorazione_tares) * -1 sgravio_magg
             , sum(decode(f_stampa_com_ruolo(a_ruolo),0,0,
                          decode(substr(nvl(note,' '),1,1),'*',
                                 nvl(importo,0),0)) * -1) sgravio_escl
        from sgravi
        where ruolo = a_ruolo
          and cod_fiscale = a_cod_fiscale
          and motivo_sgravio != 99
        group by sequenza) sgra
  where ruoli.ruolo          = a_ruolo
    and ruco.cod_fiscale     = a_cod_fiscale
    and ruco.ruolo           = ruoli.ruolo
    and ogim.oggetto_imposta = ruco.oggetto_imposta
    and ogpr.oggetto_pratica = ogim.oggetto_pratica
    and ogco.cod_fiscale     = a_cod_fiscale
    and ogco.oggetto_pratica = ogpr.oggetto_pratica
    and cate.tributo         = ogpr.tributo
    and cate.categoria       = ogpr.categoria
    and tari.anno            = ruoli.anno_ruolo
    and tari.tributo         = ogpr.tributo
    and tari.categoria       = ogpr.categoria
    and tari.tipo_tariffa    = ogpr.tipo_tariffa
    and ogge.oggetto         = ogpr.oggetto
    and arvi.cod_via (+)     = ogge.cod_via
    and cata.anno            = ruoli.anno_ruolo
    and sgra.sequenza(+)     = ruco.sequenza
  order by cate.categoria || ' - ' || cate.descrizione
         , tari.descrizione
         , decode(ogge.cod_via,null,ogge.indirizzo_localita
      ,arvi.denom_uff
                      || decode(ogge.num_civ, null, '', ', ' || ogge.num_civ)
                      || decode(ogge.suffisso, null, '', '/' || ogge.suffisso))
         , ogim.oggetto_imposta
  ;
  --
  return rc;
end dati_utenze;
--------------------------------------------------------------------
function dati_eccedenze
  ( a_ruolo                   number       default -1
  , a_cod_fiscale             varchar2     default ''
  , a_tipo_tariffe            varchar2     default '*'    -- '*' : Tutte, 'D' : Solo Domestiche, 'ND' : Solo non Domestiche
  , a_modello                 number       default -1
  ) return sys_refcursor
is
  --
  rc                          sys_refcursor;
  --
begin
  --
  open rc for
    select to_char(ruec.id_eccedenza) as id_eccedenza,
           to_char(ruec.tributo) as cod_tributo,
           cotr.descrizione as des_tributo,
           to_char(ruec.categoria) as cod_categoria,
           cate.descrizione as des_categoria,
           to_char(ruec.sequenza) as dequenza,
           decode(ruec.flag_domestica,'S','D','ND') as cod_tipo_utenza,
           decode(ruec.flag_domestica,'S','Domestica','Non Domestica') as des_tipo_utenza,
           to_char(ruec.dal,'dd/MM/YYYY') as data_dal,
           to_char(ruec.al,'dd/MM/YYYY') as data_al,
           to_char(numero_familiari) as numero_familiari,
           stampa_common.f_formatta_numero(ruec.importo_ruolo,'I','S') as importo,
           stampa_common.f_formatta_numero(ruec.imposta,'I','S') as imposta,
           stampa_common.f_formatta_numero(ruec.addizionale_pro,'I','S') as add_pro,
           trim(to_char(ruec.importo_minimi,'90D00000','NLS_NUMERIC_CHARACTERS = '',.''')) as importo_minimi,
           stampa_common.f_formatta_numero(ruec.totale_svuotamenti,'I','S') as totale_svuotamenti,
           stampa_common.f_formatta_numero(ruec.superficie,'I','N') as superficie,
           trim(to_char(ruec.costo_unitario,'90D00000000','NLS_NUMERIC_CHARACTERS = '',.''')) as costo_unitario,
           stampa_common.f_formatta_numero(ruec.costo_svuotamento,'I','S') as costo_svuotamento,
           stampa_common.f_formatta_numero(ruec.svuotamenti_superficie,'I','N') as svuotamenti_superficie,
           stampa_common.f_formatta_numero(ruec.costo_superficie,'I','N') as costo_superficie,
           stampa_common.f_formatta_numero(ruec.eccedenza_svuotamenti,'I','N') as eccedenza_svuotamenti,
           note,
           --
           stampa_common.f_formatta_numero(sum(nvl(ruec.importo_ruolo,0)) over(),'I','S') as tot_importo,
           stampa_common.f_formatta_numero(sum(nvl(ruec.imposta,0)) over(),'I','S') as tot_imposta,
           stampa_common.f_formatta_numero(sum(nvl(ruec.addizionale_pro,0)) over(),'I','S') as tot_add_pro,
           stampa_common.f_formatta_numero(sum(nvl(ruec.costo_svuotamento,0)) over(),'I','S') as tot_costo_svuotamento,
           stampa_common.f_formatta_numero(sum(nvl(ruec.costo_superficie,0)) over(),'I','S') as tot_costo_superficie
      from ruoli_eccedenze ruec,
           codici_tributo cotr,
           categorie cate
     where ruec.tributo = cotr.tributo
       and cotr.tributo = cate.tributo
       and ruec.categoria = cate.categoria
       and ruec.ruolo = a_ruolo
       and ruec.cod_fiscale||'' = a_cod_fiscale
       and (
           (a_tipo_tariffe = 'D') and (nvl(ruec.flag_domestica,'N') = 'S')
           or
           (a_tipo_tariffe = 'ND') and (nvl(ruec.flag_domestica,'N') = 'N')
           or
           (nvl(a_tipo_tariffe,'*') = '*')
           )
     order by
           ruec.tributo,
           ruec.categoria,
           ruec.dal,
           ruec.al,
           ruec.numero_familiari
    ;
  --
  return rc;
end;
--------------------------------------------------------------------
function f_stringa_qf
  ( a_tipo_calcolo                varchar2
  , a_flag_tariffe_ruolo          varchar2
  , a_flag_domestica              varchar2
  , a_mq                          number
  , a_perc_riduzione_pf           number
  , a_dettaglio                   varchar2
  , a_dettaglio_base              varchar2
  ) return varchar2
  is
  w_str_fam_ogim               varchar2(4000) := '';
  w_coeff_fissa                varchar2(8);
  w_str_mq_fissa               varchar2(10);
begin
    if a_tipo_calcolo != 'T' then -- estrae i dettagli da OGIM altrimenti null
       w_str_mq_fissa := 'Mq '||ltrim(to_char(round(a_mq),'B99999'));
       if a_flag_domestica is null then
          if a_flag_tariffe_ruolo = 'S' then
             w_coeff_fissa := 'Euro/Mq ';
else
             w_coeff_fissa := 'Kc.';
end if;
else
          if a_flag_tariffe_ruolo = 'S' then
             w_coeff_fissa := 'Euro/Mq ';
else
             w_coeff_fissa := 'Ka.';
end if;
end if;
       if a_flag_tariffe_ruolo = 'S' then
          w_str_fam_ogim := '('||w_coeff_fissa||ltrim(substr(a_dettaglio,9,13))||' * '||w_str_mq_fissa;
          if ltrim(substr(a_dettaglio,27,14)) <> '0,00' then
             w_str_fam_ogim := w_str_fam_ogim||
                               --' '||ltrim(substr(a_dettaglio_base,62,14))||
                               ' Rid. '||
                               ltrim(translate(to_char(a_perc_riduzione_pf,'9999990.00'), ',.', '.,'))||'% -'||
                               ltrim(substr(a_dettaglio,27,14));
end if;
          w_str_fam_ogim := w_str_fam_ogim || ') QF: '||ltrim(substr(a_dettaglio,52,14));
else
          w_str_fam_ogim := replace('('||w_coeff_fissa || substr(a_dettaglio, 8 , 58)
                                   ,'Imposta QF'
                                   ,w_str_mq_fissa || ') QF:'
                                   );
end if;
else
       w_str_fam_ogim := to_char(null);
end if;
return w_str_fam_ogim;
end f_stringa_qf;
--------------------------------------------------------------------
function f_stringa_qv
  ( a_tipo_calcolo                varchar2
  , a_flag_tariffe_ruolo          varchar2
  , a_flag_domestica              varchar2
  , a_mq                          number
  , a_perc_riduzione_pv           number
  , a_dettaglio                   varchar2
  , a_dettaglio_base              varchar2
  ) return varchar2
  is
  w_str_fam_ogim               varchar2(4000) := '';
  w_coeff_var                  varchar2(8);
  w_str_mq_var                 varchar2(10);
begin
    if a_tipo_calcolo != 'T' then -- estrae i dettagli da OGIM altrimenti null
       if a_flag_domestica is null then
          w_str_mq_var := 'Mq '||ltrim(to_char(round(a_mq),'B99999'));
          if a_flag_tariffe_ruolo = 'S' then
             w_coeff_var   := 'Euro/Mq ';
else
             w_coeff_var := 'Kd.';
end if;
else
          w_str_mq_var := '';
          if a_flag_tariffe_ruolo = 'S' then
             w_coeff_var   := 'Euro   ';
else
             w_coeff_var := 'Kb.';
end if;
end if;
       if a_flag_tariffe_ruolo = 'S' then
          w_str_fam_ogim := '('||w_coeff_var||ltrim(substr(a_dettaglio,74,13));
          if w_str_mq_var is null then
             w_str_fam_ogim := w_str_fam_ogim||' ';
else
             w_str_fam_ogim := w_str_fam_ogim||' * ';
end if;
          w_str_fam_ogim :=w_str_fam_ogim||w_str_mq_var;
          if ltrim(substr(a_dettaglio,92,14)) <> '0,00' then
             w_str_fam_ogim := w_str_fam_ogim||
                               --' '||ltrim(substr(a_dettaglio_base,137,14))||
                               ' Rid. '||
                               ltrim(translate(to_char(a_perc_riduzione_pv,'9999990.00'), ',.', '.,'))||'% -'||
                               ltrim(substr(a_dettaglio,92,14));
end if;
          w_str_fam_ogim := w_str_fam_ogim||') QV: '||ltrim(substr(a_dettaglio,117,14));
else
          w_str_fam_ogim := replace(replace(substr(a_dettaglio, 67)
                                           ,'Coeff.'
                                           ,'('||w_coeff_var
                                           )
                                   ,'Imposta QV'
                                   ,w_str_mq_var || ') QV:'
                                   );
end if;
else
       w_str_fam_ogim := to_char(null);
end if;
return w_str_fam_ogim;
end f_stringa_qv;
--------------------------------------------------------------------
function f_get_componenti_perequative
  ( p_anno                        number,
    p_totale                      number
  ) return varchar2 is
  w_quota                         number;
  w_importo                       number;
  w_totale                        number;
  w_residuo                       number;
  --
  w_componente                    varchar2(200);
  w_componenti                    varchar2(2000);
begin
  w_componenti := '';
  ---
  w_residuo := nvl(p_totale,0);
  --
  for rec_cp in (select
                  anno, componente, descrizione, importo, sum(importo) over() as totale, rownum, count(importo) over() as rowcount
                from
                  componenti_perequative
                where anno = p_anno)
  loop
    w_totale := greatest(nvl(rec_cp.totale,0),0.01);
    w_importo := nvl(rec_cp.importo,0);
    --
    w_quota := round((w_importo * (p_totale / w_totale)),2);
    --
    if rec_cp.rownum = rec_cp.rowcount then
      dbms_output.put_line('Ultimo');
      w_importo := w_residuo;
    else
      dbms_output.put_line('Any');
      w_residuo := w_residuo - w_quota;
      w_importo := w_quota;
    end if;
    --
    w_componente := rec_cp.componente || ' - ' || rec_cp.descrizione|| ' ';
    w_componente := w_componente || '€ ' || stampa_common.f_formatta_numero(w_importo,'I','S');
    --
    if length(w_componenti) > 0 then
      w_componenti := w_componenti || CHR(13) || CHR(10);
    end if;
    w_componenti := w_componenti || w_componente;
  end loop;
  ---
  return w_componenti;
end;
--------------------------------------------------------------------
function dati_familiari
  ( a_oggetto_imposta           number
  , a_modello                   number     default -1
  ) return sys_refcursor is
    rc                          sys_refcursor;
begin
open rc for
select to_number(to_char(decode(faog.numero_familiari
                             ,null,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                             ,faog.dal)
    ,'j')) progressivo  -- serve per l'ordinamento delle righe
     , to_char(nvl(faog.numero_familiari,ogpr.numero_familiari)) num_familiari
     , to_char(decode(faog.numero_familiari
                   ,null,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                   ,faog.dal),'dd/mm/yyyy') dal
     , to_char(decode(faog.numero_familiari
                   ,null,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                   ,faog.al),'dd/mm/yyyy') al
     , cate.flag_domestica
     , 'Mq'||to_char(round(ogpr.consistenza),'B99999') mq_fissa
     , decode(cate.flag_domestica
    ,null,'Mq'||to_char(round(ogpr.consistenza),'B99999')
    ,null) mq_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S','Euro/Mq'
    ,decode(cate.flag_domestica
                  ,null,'Kc.'
                  ,'Ka.')
    ) int_coeff_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',''
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),8,8))
    ) coeff_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),9,13))
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),24,13))
    ) tariffa_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),52,14)
    ,substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),49,14)
    ) quota_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',decode(cate.flag_domestica
                  ,null,'Euro/Mq'
                  ,'Euro')
    ,decode(cate.flag_domestica
                  ,null,'Kd.'
                  ,'Kb.')
    ) int_coeff_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',''
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),67,8))
    ) coeff_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),74,13))
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),89,13))
    ) tariffa_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),117,14)
    ,substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),113,14)
    ) quota_var
     , decode(ruol.flag_tariffe_ruolo,'S','QUOTA FISSA: ','QF: ') int_qf
     , decode(ruol.flag_tariffe_ruolo,'S','QUOTA VAR: ','QV: ') int_qv
     , f_stringa_qf( nvl(ruol.tipo_calcolo,'T')
    , ruol.flag_tariffe_ruolo
    , cate.flag_domestica
    , round(ogpr.consistenza)
    , ogim.perc_riduzione_pf
    , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131)
    , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151)
    ) stringa_quota_fissa
     , f_stringa_qv( nvl(ruol.tipo_calcolo,'T')
    , ruol.flag_tariffe_ruolo
    , cate.flag_domestica
    , round(ogpr.consistenza)
    , ogim.perc_riduzione_pv
    , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131)
    , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151)
    ) stringa_quota_var
     , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131) dettaglio
     , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151) dettaglio_base
     , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,1)   flag_tipo_riga
     , rtrim(ltrim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),152)))  sconto_conf
     , ogim.perc_riduzione_pf
     , ogim.perc_riduzione_pv
     , tado.tariffa_dom_quota_fissa
     , tado.tariffa_dom_quota_variabile
     , tado.tariffa_dom_quota_fissa_no_ap
     , tado.tariffa_dom_quota_var_no_ap
from oggetti_pratica  ogpr
   ,oggetti_imposta  ogim
   ,familiari_ogim   faog
   ,oggetti_validita ogva
   ,categorie        cate
   ,ruoli            ruol
   ,(select ruol1.ruolo,
               nvl(stampa_common.f_formatta_numero(tado1.tariffa_quota_fissa,
                                                   'T',
                                                   'S'),
                   ' ') tariffa_dom_quota_fissa,
               nvl(stampa_common.f_formatta_numero(tado1.tariffa_quota_variabile,
                                                   'T',
                                                   'S'),
                   ' ') tariffa_dom_quota_variabile,
               nvl(stampa_common.f_formatta_numero(tado1.tariffa_quota_fissa_no_ap,
                                                   'T',
                                                   'S'),
                   ' ') tariffa_dom_quota_fissa_no_ap,
               nvl(stampa_common.f_formatta_numero(tado1.tariffa_quota_variabile_no_ap,
                                                   'T',
                                                   'S'),
                   ' ') tariffa_dom_quota_var_no_ap
          from tariffe_domestiche tado1,
               ruoli              ruol1,
               contribuenti       cont1,
               oggetti_imposta    ogim1
         where tado1.anno = ruol1.anno_ruolo
           and ruol1.ruolo = ogim1.ruolo
           and ogim1.cod_fiscale = cont1.cod_fiscale
           and f_ultimo_faso(cont1.ni, ruol1.anno_ruolo) =
               tado1.numero_familiari
           and ogim1.oggetto_imposta = a_oggetto_imposta) tado
where ogim.oggetto_imposta = a_oggetto_imposta
  and ogim.ruolo = ruol.ruolo
  and ogpr.oggetto_pratica = ogim.oggetto_pratica
  and faog.oggetto_imposta(+) = ogim.oggetto_imposta
  and ogpr.oggetto_pratica = ogva.oggetto_pratica
  and cate.tributo         = ogpr.tributo
  and cate.categoria       = ogpr.categoria
  and nvl(cate.flag_domestica,'N') = 'S'
  and tado.ruolo (+) = ruol.ruolo
union
select 1 progressivo
     , f_descrizione_timp(a_modello,'INT_NUM_FAM') num_familiari
     , f_descrizione_timp(a_modello,'INT_DAL') dal
     , f_descrizione_timp(a_modello,'INT_AL') al
     , '' flag_domestica
     , '' mq_fissa
     , '' mq_var
     , '' int_coeff_fissa
     , '' coeff_fissa
     , '' tariffa_fissa
     , '' quota_fissa
     , '' int_coeff_var
     , '' coeff_var
     , '' tariffa_var
     , '' quota_var
     , '' int_qf
     , '' int_qv
     , f_descrizione_timp(a_modello,'INT_QF') stringa_quota_fissa
     , f_descrizione_timp(a_modello,'INT_QV') stringa_quota_var
     , '' dettaglio
     , '' dettaglio_base
     , '' flag_tipo_riga
     , '' sconto_conf
     , to_number(null) perc_riduzione_pf
     , to_number(null) perc_riduzione_pv
     , '' tariffa_dom_quota_fissa
     , '' tariffa_dom_quota_variabile
     , '' tariffa_dom_quota_fissa_no_ap
     , '' tariffa_dom_quota_var_no_ap
from oggetti_pratica  ogpr
   ,oggetti_imposta  ogim
   ,categorie        cate
where ogim.oggetto_imposta = a_oggetto_imposta
  and ogpr.oggetto_pratica = ogim.oggetto_pratica
  and cate.tributo         = ogpr.tributo
  and cate.categoria       = ogpr.categoria
  and nvl(cate.flag_domestica,'N') = 'S'
/*     union
    select to_number(null) progressivo
         , '' num_familiari
         , '' dal
         , '' al
         , '' flag_domestica
         , '' mq_fissa
         , '' mq_var
         , '' int_coeff_fissa
         , '' coeff_fissa
         , '' tariffa_fissa
         , '' quota_fissa
         , '' int_coeff_var
         , '' coeff_var
         , '' tariffa_var
         , '' quota_var
         , '' int_qf
         , '' int_qv
         , '' stringa_quota_fissa
         , '' stringa_quota_var
         , '' dettaglio
         , '' dettaglio_base
         , '' flag_tipo_riga
         , '' sconto_conf
         , to_number(null) perc_riduzione_pf
         , to_number(null) perc_riduzione_pv
      from oggetti_pratica  ogpr
          ,oggetti_imposta  ogim
          ,categorie        cate
     where ogim.oggetto_imposta = a_oggetto_imposta
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and cate.tributo         = ogpr.tributo
       and cate.categoria       = ogpr.categoria
       and nvl(cate.flag_domestica,'N') = 'N' */
order by 1;
return rc;
end dati_familiari;
--------------------------------------------------------------------
function dati_non_dom
  ( a_oggetto_imposta           number
  , a_modello                   number     default -1
  ) return sys_refcursor is
    rc                          sys_refcursor;
begin
open rc for
select to_number(to_char(decode(faog.numero_familiari
                             ,null,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                             ,faog.dal)
    ,'j')) progressivo  -- serve per l'ordinamento delle righe
     , to_char(decode(faog.numero_familiari
                   ,null,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                   ,faog.dal),'dd/mm/yyyy') dal
     , to_char(decode(faog.numero_familiari
                   ,null,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                   ,faog.al),'dd/mm/yyyy') al
     , cate.flag_domestica
     , 'Mq'||to_char(round(ogpr.consistenza),'B99999') mq_fissa
     , decode(cate.flag_domestica
    ,null,'Mq'||to_char(round(ogpr.consistenza),'B99999')
    ,null) mq_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S','Euro/Mq'
    ,decode(cate.flag_domestica
                  ,null,'Kc.'
                  ,'Ka.')
    ) int_coeff_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',''
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),8,8))
    ) coeff_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),9,13))
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),24,13))
    ) tariffa_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),52,14)
    ,substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),49,14)
    ) quota_fissa
     , decode(ruol.flag_tariffe_ruolo
    ,'S',decode(cate.flag_domestica
                  ,null,'Euro/Mq'
                  ,'Euro')
    ,decode(cate.flag_domestica
                  ,null,'Kd.'
                  ,'Kb.')
    ) int_coeff_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',''
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),67,8))
    ) coeff_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),74,13))
    ,trim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),89,13))
    ) tariffa_var
     , decode(ruol.flag_tariffe_ruolo
    ,'S',substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),117,14)
    ,substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),113,14)
    ) quota_var
     , decode(ruol.flag_tariffe_ruolo,'S','QUOTA FISSA: ','QF: ') int_qf
     , decode(ruol.flag_tariffe_ruolo,'S','QUOTA VAR: ','QV: ') int_qv
     , f_stringa_qf( nvl(ruol.tipo_calcolo,'T')
    , ruol.flag_tariffe_ruolo
    , cate.flag_domestica
    , round(ogpr.consistenza)
    , ogim.perc_riduzione_pf
    , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131)
    , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151)
    ) stringa_quota_fissa
     , f_stringa_qv( nvl(ruol.tipo_calcolo,'T')
    , ruol.flag_tariffe_ruolo
    , cate.flag_domestica
    , round(ogpr.consistenza)
    , ogim.perc_riduzione_pv
    , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131)
    , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151)
    ) stringa_quota_var
     , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131) dettaglio
     , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151) dettaglio_base
     , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,1)   flag_tipo_riga
     , rtrim(ltrim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),152)))  sconto_conf
     , ogim.perc_riduzione_pf
     , ogim.perc_riduzione_pv
     , tand.tariffa_nondom_quota_fissa
     , tand.tariffa_nondom_quota_variabile
from oggetti_pratica  ogpr
   ,oggetti_imposta  ogim
   ,familiari_ogim   faog
   ,oggetti_validita ogva
   ,categorie        cate
   ,ruoli            ruol
   ,(select ruol1.ruolo,
            nvl(stampa_common.f_formatta_numero(tand1.tariffa_quota_fissa,
                                                'T',
                                                'S'),
                ' ') tariffa_nondom_quota_fissa,
            nvl(stampa_common.f_formatta_numero(tand1.tariffa_quota_variabile,
                                                'T',
                                                'S'),
                ' ') tariffa_nondom_quota_variabile
       from tariffe_non_domestiche tand1,
            oggetti_pratica        ogpr1,
            oggetti_imposta        ogim1,
            ruoli                  ruol1
      where ogim1.oggetto_imposta = a_oggetto_imposta
        and ogim1.ruolo = ruol1.ruolo
        and ogpr1.oggetto_pratica = ogim1.oggetto_pratica
        and tand1.categoria = nvl(ogpr1.categoria, 0)
        and tand1.tributo = ogpr1.tributo
        and tand1.anno = ruol1.anno_ruolo
   ) tand
where ogim.oggetto_imposta    = a_oggetto_imposta
  and ogim.ruolo              = ruol.ruolo
  and ogpr.oggetto_pratica    = ogim.oggetto_pratica
  and faog.oggetto_imposta(+) = ogim.oggetto_imposta
  and ogpr.oggetto_pratica    = ogva.oggetto_pratica
  and cate.tributo            = ogpr.tributo
  and cate.categoria          = ogpr.categoria
  and nvl(cate.flag_domestica,'N') = 'N'
  and tand.ruolo (+)              = ruol.ruolo
union
select 1 progressivo
     , f_descrizione_timp(a_modello,'INT_DAL') dal
     , f_descrizione_timp(a_modello,'INT_AL') al
     , '' flag_domestica
     , '' mq_fissa
     , '' mq_var
     , '' int_coeff_fissa
     , '' coeff_fissa
     , '' tariffa_fissa
     , '' quota_fissa
     , '' int_coeff_var
     , '' coeff_var
     , '' tariffa_var
     , '' quota_var
     , '' int_qf
     , '' int_qv
     , f_descrizione_timp(a_modello,'INT_QF') stringa_quota_fissa
     , f_descrizione_timp(a_modello,'INT_QV') stringa_quota_var
     , '' dettaglio
     , '' dettaglio_base
     , '' flag_tipo_riga
     , '' sconto_conf
     , to_number(null) perc_riduzione_pf
     , to_number(null) perc_riduzione_pv
     , '' tariffa_nondom_quota_fissa
     , '' tariffa_nondom_quota_variabile
from oggetti_pratica  ogpr
   ,oggetti_imposta  ogim
   ,categorie        cate
where ogim.oggetto_imposta = a_oggetto_imposta
  and ogpr.oggetto_pratica = ogim.oggetto_pratica
  and cate.tributo         = ogpr.tributo
  and cate.categoria       = ogpr.categoria
  and nvl(cate.flag_domestica,'N') = 'N'
/*     union
    select to_number(null) progressivo
         , '' dal
         , '' al
         , '' flag_domestica
         , '' mq_fissa
         , '' mq_var
         , '' int_coeff_fissa
         , '' coeff_fissa
         , '' tariffa_fissa
         , '' quota_fissa
         , '' int_coeff_var
         , '' coeff_var
         , '' tariffa_var
         , '' quota_var
         , '' int_qf
         , '' int_qv
         , '' stringa_quota_fissa
         , '' stringa_quota_var
         , '' dettaglio
         , '' dettaglio_base
         , '' flag_tipo_riga
         , '' sconto_conf
         , to_number(null) perc_riduzione_pf
         , to_number(null) perc_riduzione_pv
      from oggetti_pratica  ogpr
          ,oggetti_imposta  ogim
          ,categorie        cate
     where ogim.oggetto_imposta = a_oggetto_imposta
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and cate.tributo         = ogpr.tributo
       and cate.categoria       = ogpr.categoria
       and nvl(cate.flag_domestica,'N') = 'S' */
order by 1;
return rc;
end dati_non_dom;
--------------------------------------------------------------------
function dati_rfid
  ( a_oggetto_imposta         number
  , a_modello                 number     default -1
  ) return sys_refcursor
is
  --
  rc                          sys_refcursor;
  --
begin
  --
  open rc for
    select corf.cod_fiscale,
           to_char(corf.oggetto) as oggetto,
           to_char(corf.cod_contenitore) as cod_contenitore,
           corf.cod_rfid,
           decode(corf.data_consegna,null,'',to_char(corf.data_consegna,'dd/MM/YYYY')) as data_consegna,
           decode(corf.data_restituzione,null,'',to_char(corf.data_restituzione,'dd/MM/YYYY')) as data_restituzione,
           cori.descrizione,
           stampa_common.f_formatta_numero(cori.capienza,'I','S') capienza,
           cori.unita_di_misura,
           stampa_common.f_formatta_numero(cori.capienza,'I','S')||decode(cori.unita_di_misura,null,'',' '||cori.unita_di_misura) as des_capienza,
           corf.note
      from oggetti_imposta ogim,
           oggetti_pratica ogpr,
           codici_rfid corf,
           contenitori cori
     where corf.cod_contenitore = cori.cod_contenitore
       and ogim.oggetto_pratica = ogpr.oggetto_pratica
       and ogim.cod_fiscale = corf.cod_fiscale
       and corf.oggetto = ogpr.oggetto
       and ogim.oggetto_imposta = a_oggetto_imposta
  ;
  --
  return rc;
end dati_rfid;
--------------------------------------------------------------------
function dizionario_tariffe_dom
  ( a_ruolo                   number       default -1
  , a_cod_fiscale             varchar2     default ''
  , a_modello                 number       default -1
  ) return sys_refcursor
is
  --
  rc                          sys_refcursor;
  --
begin
  --
  open rc for
    select to_char(tari.anno)||'00000000'||lpad(tari.numero_familiari,4,'0') as id_tariffa,
           'D' as cod_tipo_utenza,
           'Domestica' as des_tipo_utenza,
           tari.numero_familiari as numero_familiari,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_fissa,'T','S'),' ') tar_quota_fissa,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_variabile,'T','S'),' ') tar_quota_variabile,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_fissa,'T','S'),' ') tar_quota_fissa_no_ap,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_variabile,'T','S'),' ') tar_quota_variabile_no_ap,
           nvl(stampa_common.f_formatta_numero(tari.svuotamenti_minimi,'I','S'),' ') svuotamenti_minimi,
           --
           nvl(stampa_common.f_formatta_numero(cope.imp_ur1,'I','N'),' ') imp_cope_ur1,
           nvl(stampa_common.f_formatta_numero(cope.imp_ur2,'I','N'),' ') imp_cope_ur2,
           cope.des_ur1 as des_cope_ur1,
           cope.des_ur2 as des_cope_ur2
      from tariffe_domestiche tari,
           ruoli ruol,
           (select
              cope.anno,
              max(cope.imp_ur1) as imp_ur1,
              max(cope.des_ur1) as des_ur1,
              max(cope.imp_ur2) as imp_ur2,
              max(cope.des_ur2) as des_ur2
            from
              (select
                cope.anno,
                decode(cope.componente,'UR1',cope.importo,0) as imp_ur1,
                decode(cope.componente,'UR2',cope.importo,0) as imp_ur2,
                decode(cope.componente,'UR1',cope.descrizione,null) as des_ur1,
                decode(cope.componente,'UR2',cope.descrizione,null) as des_ur2
              from
                componenti_perequative cope
              ) cope
            group by anno
           ) cope
     where tari.anno = ruol.anno_ruolo
       and ruol.anno_ruolo = cope.anno(+)
       and ruol.ruolo = a_ruolo
  ;
  --
  return rc;
end;
--------------------------------------------------------------------
function dizionario_tariffe_non_dom
  ( a_ruolo                   number       default -1
  , a_cod_fiscale             varchar2     default ''
  , a_modello                 number       default -1
  ) return sys_refcursor
is
  --
  rc                          sys_refcursor;
  --
begin
  --
  open rc for
    select to_char(tari.anno)||cate.id_categoria||lpad(tari.categoria,4,'0') as id_tariffa,
           to_char(tari.tributo) as cod_tributo,
           cotr.descrizione as des_tributo,
           to_char(tari.categoria) as cod_categoria,
           cate.descrizione as des_categoria,
           'ND' as cod_tipo_utenza,
           'Non Domestica' as des_tipo_utenza,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_fissa,'T','S'),' ') tar_quota_fissa,
           nvl(stampa_common.f_formatta_numero(tari.tariffa_quota_variabile,'T','S'),' ') tar_quota_variabile,
           trim(to_char(tari.importo_minimi,'90D00000','NLS_NUMERIC_CHARACTERS = '',.''')) as importo_minimi,
           --
           nvl(stampa_common.f_formatta_numero(cope.imp_ur1,'I','N'),' ') imp_cope_ur1,
           nvl(stampa_common.f_formatta_numero(cope.imp_ur2,'I','N'),' ') imp_cope_ur2,
           cope.des_ur1 as des_cope_ur1,
           cope.des_ur2 as des_cope_ur2
      from tariffe_non_domestiche tari,
           ruoli ruol,
           codici_tributo cotr,
           categorie cate,
           (select
              cope.anno,
              max(cope.imp_ur1) as imp_ur1,
              max(cope.des_ur1) as des_ur1,
              max(cope.imp_ur2) as imp_ur2,
              max(cope.des_ur2) as des_ur2
            from
              (select
                cope.anno,
                decode(cope.componente,'UR1',cope.importo,0) as imp_ur1,
                decode(cope.componente,'UR2',cope.importo,0) as imp_ur2,
                decode(cope.componente,'UR1',cope.descrizione,null) as des_ur1,
                decode(cope.componente,'UR2',cope.descrizione,null) as des_ur2
              from
                componenti_perequative cope
              ) cope
            group by anno
           ) cope
     where tari.anno = ruol.anno_ruolo
       and tari.tributo = cotr.tributo
       and cotr.tributo = cate.tributo
       and tari.categoria = cate.categoria
       and ruol.anno_ruolo = cope.anno(+)
       and ruol.ruolo = a_ruolo
     order by
           tari.tributo,
           tari.categoria
  ;
  --
  return rc;
end;
--------------------------------------------------------------------
end STAMPA_AVVISI_TARI;
/
