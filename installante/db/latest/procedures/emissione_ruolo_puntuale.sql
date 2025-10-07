--liquibase formatted sql 
--changeset abrandolini:20250326_152423_emissione_ruolo_puntuale stripComments:false runOnChange:true 
 
create or replace procedure EMISSIONE_RUOLO_PUNTUALE
/******************************************************************************
  NOME:        EMISSIONE_RUOLO_PUNTUALE
  DESCRIZIONE: Emissione ruolo supplettivo totale in caso di tariffa puntuale
  NOTA:        Richiamata da EMISSIONE_RUOLO, che fa già pulizia ed alcuni
               controlli qui non compresi.

  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  001   21/03/2025  RV      #79510
                            Manutenzioni post collaudo versione iniziale
                            Gestione nuovi campi eccedenze
  000   07/03/2025  RV      #77568
                            Versione iniziale
******************************************************************************/
(a_ruolo                 number
,a_utente                varchar2
,a_cod_fiscale           varchar2
,a_flag_richiamo         varchar2
,a_flag_iscritti_p       varchar2
,a_flag_normalizzato     varchar2
,a_tipo_limite           varchar2
,a_limite                number
)
IS
-- Tipi
type t_eccedenze_parametri is record
(
  cod_fiscale                       varchar2(16),
  ruolo                             number(10),
  anno_ruolo                        number(4),
  tributo                           number(4),
  categoria                         number(4),
  tipo_tariffa                      number(2),
  consistenza                       number(8,2),
  numero_familiari                  number(4),
  flag_domestica                    varchar2(1),
  flag_ab_principale                varchar2(1),
  oggetto                           number(10,0),
  dal_anno                          date,
  al_anno                           date,
  periodo                           number,
  da_mese_ruolo                     number,
  a_mese_ruolo                      number,
  costo_unitario                    number(10,8),
  --
  addizionale_pro                   number(4,2),
  addizionale_eca                   number(4,2),
  maggiorazione_eca                 number(4,2),
  modalita_familiari                number(1,0),
  flag_ruolo_tariffa                varchar2(1),
  flag_tariffa_base                 varchar2(1),
  --
  gg_anno                           number,   -- Giorni annualità solare
  gg_anno_ruolo                     number    -- Giorni annualità ruolo (Non necessariamente quelle effettive dell'anno)
);
--
type t_eccedenze_totali is record
(
  ruolo                             number(10,0),
  cod_fiscale                       varchar2(16),
  tributo                           number(4,0),
  categoria                         number(4,0),
  dal                               date,
  al                                date,
  numero_familiari                  number(2,0),
  domestica                         boolean,
  imposta                           number(15,2),
  addizionale_pro                   number(15,2),
  importo_ruolo                     number(15,2),
  importo_minimi                    number(11,5),
  totale_svuotamenti                number(15,2),
  superficie                        number(15,2),
  costo_unitario                    number(10,8),
  costo_svuotamento                 number(15,2),
  svuotamenti_superficie            number(15,2),
  costo_superficie                  number(15,2),
  eccedenza_svuotamenti             number(15,2),
  note                              varchar(2000)
);
--
type t_eccedenze_suotamenti is record
(
  capienza_totale          number(12,2),
  svuotamenti_minimi       number(12,2),      -- Solo D
  importo_minimi           number(11,5),      -- Solo ND
  max_familiari            number(2,0)        -- Solo D
);
--
type t_eccedenze_porzioni is record
(
  anno                     number,
  dal                      date,
  al                       date,
  gg_porz                  number,            -- Giorni di questa porzione
  gg_porz_tot              number,            -- Giorni totali di tutte le porzioni
  numero_familiari         number
);
-- Gestione error
errore                     exception;
w_errore                   varchar2(2000);
w_debug                    number := 0;
-- Dati generali e del ruolo
w_cod_istat                varchar2(6);
w_tipo_tributo             varchar2(5);
w_tipo_ruolo               number;
w_tipo_emissione           varchar2(1);
w_anno_ruolo               number;
w_anno_emissione           number;
w_progr_emissione          number;
w_data_emissione           date;
w_invio_consorzio          date;
w_ruolo_rif                number;
w_rate                     number;
w_importo_lordo            varchar2(1);
w_flag_tariffa_base        varchar2(1);
w_flag_ruolo_tariffa       varchar2(1);
-- Dati Carichi Tarsu
w_addizionale_pro          number;
w_addizionale_eca          number;
w_maggiorazione_eca        number;
w_mesi_calcolo             number;
w_maggiorazione_tares      number;
w_modalita_familiari       number;
w_tariffa_puntuale         varchar2(1);
w_costo_unitario           number;
--
w_cod_fiscale_err          varchar2(25);      -- CF come Messaggio di errore
w_cod_fiscale_corr         varchar2(16);      -- CF corrente in fase di elaborazione
w_ni_corr                  number;
w_scadenza_ruolo_p         date;
w_esiste_cosu              varchar2(1);
--
w_da_trattare              boolean;
w_chk_dovuto               number;
w_chk_eccedente            number;
w_ruolo_scaduto            boolean;
-- Calcolo Eccedenze
w_ecc_parametri            t_eccedenze_parametri;
w_ecc_totali               t_eccedenze_totali;
w_ecc_porzioni             t_eccedenze_porzioni;
w_da_mese_ruolo            number;
w_periodo                  number;
--
type t_eccedenze_table is table of t_eccedenze_totali;
w_eccedenze_table          t_eccedenze_table := t_eccedenze_table();
w_totali_table             t_eccedenze_table := t_eccedenze_table();
--
w_rc_porzioni              sys_refcursor;
--
w_ind                      binary_integer;
--
w_res                      number;
--
----------------------------------
-- Cursore per oggetti validi
----------------------------------
CURSOR sel_ogpr_validi
(a_anno              number
,a_cod_fiscale       varchar2
,a_tipo_tributo      varchar2
,a_tipo_occupazione  varchar2
,a_data_emissione    date
) IS
select ogpr.oggetto
      ,ogpr.oggetto_pratica
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.consistenza
      ,ogpr.tipo_tariffa
      ,ogpr.numero_familiari
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,tari.tariffa_quota_fissa
      ,nvl(tari.perc_riduzione,0)                   perc_riduzione
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogco.perc_possesso
      ,ogco.flag_ab_principale
      ,ogva.cod_fiscale
      ,cont.ni
      ,ogva.dal data_decorrenza
      ,ogva.al data_cessazione
      ,cotr.flag_ruolo
      ,ogva.tipo_occupazione
      ,ogva.tipo_tributo
      ,decode(ogva.anno,a_anno,ogpr.data_concessione,null) data_concessione
      ,ogva.oggetto_pratica_rif
      ,f_get_tariffa_base(ogpr.tributo,ogpr.categoria,a_anno) tipo_tariffa_base
      ,ogco.flag_punto_raccolta
      ,nvl(f_ruolo_totale(ogva.cod_fiscale,a_anno,ogva.tipo_tributo,-1),0) as ruolo_totale
      ,nvl(cate.flag_domestica,'N') as flag_domestica
      ,greatest(nvl(ogva.dal,to_date('0101'||a_anno,'ddMMYYYY')),to_date('0101'||a_anno,'ddMMYYYY')) dal_anno
      ,least(nvl(ogva.al,to_date('3112'||a_anno,'ddMMYYYY')),to_date('3112'||a_anno,'ddMMYYYY')) al_anno
  from tariffe              tari
      ,categorie            cate
      ,tipi_tributo         titr
      ,codici_tributo       cotr
      ,pratiche_tributo     prtr
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
      ,oggetti_validita     ogva
      ,contribuenti         cont
 where nvl(to_number(to_char(ogva.dal,'yyyy')),a_anno)
                               <= a_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),a_anno)
                               >= a_anno
   and nvl(ogva.data,nvl(a_data_emissione
                        ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                        )
          )                    <=
       nvl(a_data_emissione,nvl(ogva.data
                               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                               )
          )
   and not exists
      (select 'x'
         from pratiche_tributo prtr
        where prtr.tipo_pratica||''    = 'A'
          and prtr.anno               <= a_anno
          and prtr.pratica             = ogpr.pratica
          and (    trunc(sysdate) - nvl(prtr.data_notifica,trunc(sysdate))
                                       < 60
               and flag_adesione      is NULL
               or  prtr.anno           = a_anno
              )
          and prtr.flag_denuncia       = 'S'
      )
   and tari.tipo_tariffa         = ogpr.tipo_tariffa
   and tari.categoria+0          = ogpr.categoria
   and tari.tributo              = ogpr.tributo
   and cate.categoria+0          = ogpr.categoria
   and cate.tributo              = ogpr.tributo
   and nvl(tari.anno,0)          = a_anno
   and titr.tipo_tributo         = cotr.tipo_tributo
   and cotr.tipo_tributo         = ogva.tipo_tributo
   and cotr.tributo              = ogpr.tributo
   and ogpr.flag_contenzioso    is null
   and ogpr.oggetto_pratica      = ogva.oggetto_pratica
   and ogva.tipo_occupazione  like a_tipo_occupazione
   and ogva.cod_fiscale       like a_cod_fiscale
   and ogva.tipo_tributo||''     = a_tipo_tributo
   and ogco.oggetto_pratica      = ogva.oggetto_pratica
   and ogco.cod_fiscale          = ogva.cod_fiscale
   and ogva.cod_fiscale          = cont.cod_fiscale
   and prtr.pratica              = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D')
                                 = 'D'
   and (    ogva.tipo_occupazione
                                 = 'T'
        or  a_tipo_tributo      in ('TARSU','ICIAP','ICI')
        or  ogva.tipo_occupazione
                            = 'P'
   and a_tipo_tributo      in ('TOSAP','ICP')
        and not exists
           (select 1
              from oggetti_validita   ogv2
             where ogv2.cod_fiscale   = ogva.cod_fiscale
               and ogv2.oggetto_pratica_rif
                                      = ogva.oggetto_pratica_rif
               and ogv2.tipo_tributo||''
                                   = ogva.tipo_tributo
               and ogv2.tipo_occupazione
                                      = 'P'
               and nvl(to_number(to_char(ogv2.data,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.dal,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.al,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )              >= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(ogv2.data,nvl(a_data_emissione
                                    ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                    )
                      )              <=
                   nvl(a_data_emissione,nvl(ogv2.data
                                           ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                           )
                      )
               and ogv2.dal           > ogva.dal
           )
       )
 order by
       ogva.cod_fiscale
      ,ogpr.oggetto
      ,ogva.dal
;
--
----------------------------------
-- Forward references
----------------------------------
procedure calcola_lordo
  ( w_parametri   IN      t_eccedenze_parametri,
    w_eccedenza   IN OUT  t_eccedenze_totali
  );
--
----------------------------------
-- f_scadenza_ruolo
--  Determina l'ultima data di scadenza del ruolo
----------------------------------
FUNCTION f_scadenza_ruolo
 (w_ruolo               number
 )
RETURN date
IS
  w_return                       date;
BEGIN
  --
  w_return := sysdate;
  --
  select
    trunc(greatest(nvl(ruol.scadenza_rata_unica,to_date('01011900','ddMMYYYY')),
                                                          nvl(ruol.scadenza_rata_4,
                                                            nvl(ruol.scadenza_rata_3,
                                                              nvl(ruol.scadenza_rata_2,
                                                                ruol.scadenza_prima_rata))))) scadenza_ultim_rata
  into
    w_return
  from
    ruoli ruol
  where
    ruol.ruolo = w_ruolo
  ;
  --
  return w_return;
  --
EXCEPTION
   WHEN no_data_found THEN
      RETURN sysdate;
   WHEN others THEN
      RETURN sysdate;
END;
--
----------------------------------
-- f_iscritto
--  Verifica se già iscritto a ruolo (-1) oppure no (0)
----------------------------------
FUNCTION f_verifica_iscritto
  (w_anno                        number
  ,w_cf                          varchar2
  ,w_ogpr                        number
  ,w_ruolo                       number
  )
RETURN number
IS
  w_return                       number;
BEGIN
  select distinct 1
   into w_return
   from oggetti_imposta ogim
       ,oggetti_pratica ogpr
       ,oggetti_pratica ogp2
  where ogim.cod_fiscale        = w_cf
    and ogim.anno               = w_anno
    and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                =
        nvl(ogp2.oggetto_pratica_rif,ogp2.oggetto_pratica)
    and ruolo                  is not null
    and ruolo                <> w_ruolo
    and ogpr.oggetto_pratica    = ogim.oggetto_pratica
    and ogp2.oggetto_pratica    = w_ogpr
  ;
  RETURN w_return;
  --
EXCEPTION
   WHEN no_data_found THEN
      RETURN 0;
   WHEN others THEN
      RETURN -1;
END f_verifica_iscritto;
--
----------------------------------
-- f_verifica_dovuto
--  Verifica se esiste del dovuto per il tributo (-1) oppure no (0)
----------------------------------
FUNCTION f_verifica_dovuto
  (w_cf                          varchar2
  ,w_tributo                     number
  ,w_ruolo                       number
  ,w_ruolo_totale                number
  )
RETURN number
IS
  w_return                       number;
BEGIN
  select sum(ruco.importo)
    into w_return
    from ruoli_contribuente ruco
   where ruco.cod_fiscale        = w_cf
     and ruco.ruolo              in(w_ruolo, w_ruolo_totale)
     and ruco.tributo            = w_tributo
  ;
  RETURN w_return;
  --
EXCEPTION
   WHEN no_data_found THEN
      RETURN 0;
   WHEN others THEN
      RETURN -1;
END f_verifica_dovuto;
--
----------------------------------
-- Cursore per porzioni d'anno
----------------------------------
function f_porzioni_anno
( p_ni                   number,
  p_anno                 number,
  p_esiste_cosu          varchar2,
  p_ab_principale        varchar2,
  p_consistenza          number,
  p_num_fam_ogpr         number
) return sys_refcursor
/*******************************************************
 Restituisce un cursore con le eventuali porzioni di anno
 ed eventuali variazioni importanti al fine dei calcoli
*******************************************************/
is
  rc                       sys_refcursor;
begin
  --
  if p_ab_principale = 'S' then
    -- Abitaszione principale
    -- Cerca nei FASO, se non esistono per l'anno ne simula uno lungo tutto l'anno
    open rc for
      select
          faso.anno,
          faso.dal,
          faso.al,
          (faso.al - faso.dal + 1) gg_porz,
          (faso.al - faso.dal + 1) gg_porz_tot,
          p_num_fam_ogpr as numero_familiari
      from
        (
        select
          p_anno as anno,
          to_date('0101'||p_anno,'ddMMYYYY') as dal,
          to_date('3112'||p_anno,'ddMMYYYY') as al,
          p_num_fam_ogpr as numero_familiari
        from dual
        where not exists
            ( select 'x' from familiari_soggetto where anno = p_anno and ni = p_ni)
        ) faso
      union
      select
          faso.anno,
          faso.dal,
          faso.al,
          (faso.al - faso.dal + 1) gg_porz,
          sum(faso.al - faso.dal + 1)  over() as gg_porz_tot,
          faso.numero_familiari as numero_familiari
      from
        (
        select
           anno,
           numero_familiari,
           greatest(faso.dal,to_date('0101'||p_anno,'ddMMYYYY')) dal,
           least(nvl(faso.al,to_date('3112'||p_anno,'ddMMYYYY')),to_date('3112'||p_anno,'ddMMYYYY')) al
          from familiari_soggetto faso
         where faso.anno = p_anno
           and faso.ni = p_ni
        ) faso
      ;
  else
    -- Altro edificio
    if p_esiste_cosu = 'S' then
      -- Esistono COSU, determina i familiari dalla consistenza
      open rc for
        select
          cosu.anno,
          cosu.dal,
          cosu.al,
          (cosu.al - cosu.dal + 1) gg_porz,
          (cosu.al - cosu.dal + 1) gg_porz_tot,
          nvl(p_num_fam_ogpr,cosu.numero_familiari) as numero_familiari
        from
          (
          select
            cosu.anno,
            to_date('0101'||p_anno,'ddMMYYYY') as dal,
            to_date('3112'||p_anno,'ddMMYYYY') as al,
            cosu.numero_familiari as numero_familiari
           from
            componenti_superficie cosu
          where cosu.anno = p_anno
            and p_consistenza between cosu.da_consistenza and cosu.a_consistenza
         ) cosu
      ;
    else
      -- Non esistono COSU, ne simula uno lungo tutto l'anno
      open rc for
        select
          faso.anno,
          faso.dal,
          faso.al,
          (faso.al - faso.dal + 1) as gg_porz,
          gg_porz_tot,
          to_date('3112'||p_anno,'ddMMYYYY') - to_date('0101'||p_anno,'ddMMYYYY') + 1 as gg_anno,
          p_num_fam_ogpr as numero_familiari
         from
          (
          select
            p_anno as anno,
            to_date('0101'||p_anno,'ddMMYYYY') as dal,
            to_date('3112'||p_anno,'ddMMYYYY') as al,
            to_date('3112'||p_anno,'ddMMYYYY') - to_date('0101'||p_anno,'ddMMYYYY') + 1 as gg_porz_tot
          from dual
          ) faso
        ;
    end if;
  end if;
  --
  return rc;
end f_porzioni_anno;
--
----------------------------------
-- Totale svuotamenti per oggetto e CF
----------------------------------
function f_svuotamenti
  ( w_parametri       t_eccedenze_parametri
  , w_domestica       boolean
  , w_svuotamenti     IN OUT t_eccedenze_suotamenti
  )
RETURN number
IS
  w_anno_ruolo        number;
  w_cod_fiscale       varchar2(16);
  w_oggetto           number;
  w_num_familiari     number;
  --
  w_return            number;
BEGIN
  --
  w_anno_ruolo := w_parametri.anno_ruolo;
  w_cod_fiscale := w_parametri.cod_fiscale;
  w_oggetto := w_parametri.oggetto;
  --
  w_return := 1;
  --
  BEGIN
    select
      nvl(sum(quantita),0) as quantita_totale,
      0 as svuotamenti_minimi,
      0 as importo_minimi,
      0 as max_familiari
    into
      w_svuotamenti
    from
      (
      select
        sum(nvl(svuo.quantita,0)) as quantita,
        cori.unita_di_misura,
        cori.capienza
      from
        svuotamenti svuo,
        contenitori cori,
        codici_rfid corf
      where svuo.cod_fiscale = w_cod_fiscale
        and svuo.oggetto = w_oggetto
        and svuo.cod_fiscale = corf.cod_fiscale
        and svuo.oggetto = corf.oggetto
        and svuo.cod_rfid = corf.cod_rfid
        and cori.cod_contenitore = corf.cod_contenitore
        and svuo.data_svuotamento >= nvl(w_parametri.dal_anno,to_date('0101'||w_anno_ruolo,'ddMMYYYY'))       -- Dalle 00:00:00
        and svuo.data_svuotamento < (nvl(w_parametri.al_anno,to_date('3112'||w_anno_ruolo,'ddMMYYYY')) + 1)  -- Fino allle 23:59:59
      group by
        cori.unita_di_misura,
        cori.capienza
      )
    ;
  EXCEPTION
    WHEN no_data_found THEN
      w_svuotamenti.capienza_totale := 0;
      w_svuotamenti.svuotamenti_minimi := 0;
      w_svuotamenti.importo_minimi := 0;
      w_return := 0;
    WHEN others THEN
      w_errore := 'Errore determinando Svuotamenti - C.F: '||w_cod_fiscale||', oggetto : '||w_oggetto;
      RAISE errore;
  END;
  --
  if w_domestica != false then
    -- Domestica
    BEGIN
      -- Determina numero max familiari configurato
      select max(nvl(numero_familiari,0)) as max_numero_familiari
        into w_svuotamenti.max_familiari
        from tariffe_domestiche
       where anno = w_anno_ruolo;
    EXCEPTION
      WHEN no_data_found THEN
        w_svuotamenti.max_familiari := 6;
      WHEN others THEN
        w_errore := 'Errore determinando Svuotamenti Minimi - C.F: '||w_cod_fiscale||', oggetto : '||w_oggetto||', familiari: '||w_num_familiari;
        RAISE errore;
    END;
    --
    w_num_familiari := nvl(w_parametri.numero_familiari,1);
    if w_num_familiari > w_svuotamenti.max_familiari then
      w_num_familiari := w_svuotamenti.max_familiari;
    end if;
    --
    BEGIN
      -- Determina svuotamenti_minimi per il numero di familiari (oppure il massimo se non previsto)
      select nvl(svuotamenti_minimi,0)
        into w_svuotamenti.svuotamenti_minimi
        from tariffe_domestiche
       where anno = w_anno_ruolo
         and numero_familiari = w_num_familiari
      ;
    EXCEPTION
      WHEN no_data_found THEN
        w_svuotamenti.svuotamenti_minimi := 0;
        w_return := 0;
      WHEN others THEN
        w_errore := 'Errore determinando Svuotamenti Minimi - C.F: '||w_cod_fiscale||', oggetto : '||w_oggetto||', familiari: '||w_parametri.numero_familiari;
        RAISE errore;
    END;
  else
    -- Non Domestica
    BEGIN
      select nvl(importo_minimi,0)
        into w_svuotamenti.importo_minimi
        from tariffe_non_domestiche
       where anno = w_anno_ruolo
         and tributo = w_parametri.tributo
         and categoria = w_parametri.categoria
      ;
    EXCEPTION
      WHEN no_data_found THEN
        w_svuotamenti.importo_minimi := 0;
        w_return := 0;
      WHEN others THEN
        w_errore := 'Errore determinando Minimo Categoria - C.F: '||w_cod_fiscale||', oggetto : '||w_oggetto;
        RAISE errore;
    END;
  end if;
  --
  return w_return;
  --
END;
--
----------------------------------
-- Cerca eccedenza nei totali per tributo e categoria
----------------------------------
function f_cerca_eccedenza
  ( w_eccedenza   t_eccedenze_totali
  )
return binary_integer
IS
  w_count         binary_integer;
  w_index         binary_integer;
BEGIN
  --
  w_index := 0;
  --
  w_count := w_totali_table.count;
  if w_count > 0 then
    for i in w_totali_table.first..w_totali_table.last
    loop
      if w_eccedenza.domestica != false then
        -- Non Domestica, cerca esistente per tributo e categoria, dal, al, numero _familiari
        if (w_totali_table(i).tributo = w_eccedenza.tributo) and
            (w_totali_table(i).categoria = w_eccedenza.categoria) and
            (w_totali_table(i).dal = w_eccedenza.dal) and
            (w_totali_table(i).al = w_eccedenza.al) and
            (w_totali_table(i).numero_familiari = w_eccedenza.numero_familiari)
        then
          w_index := i;
          exit;
        end if;
      else
        -- Non Domestica, cerca esistente solo per tributo e categoria
        if (w_totali_table(i).tributo = w_eccedenza.tributo) and
            (w_totali_table(i).categoria = w_eccedenza.categoria)
        then
          w_index := i;
          exit;
        end if;
      end if;
    end loop;
  end if;
  --
  return w_index;
  --
END;
--
----------------------------------
-- Calcolo Eccddenze - Domestica
----------------------------------
function f_eccedenza_d
  ( w_parametri   IN      t_eccedenze_parametri,
    w_eccedenza   IN OUT  t_eccedenze_totali
  )
RETURN number
IS
  w_svuotamenti           t_eccedenze_suotamenti;
  w_svuotamenti_min_per   number;
  w_res                   number;
  --
  w_note                  varchar2(2000);
  --
  w_return                number;
BEGIN
  --
  w_return := 0;
  --
  if w_debug > 0 then
    dbms_output.put_line('Trattamento Domestica - Consistenza: '||w_parametri.consistenza||
                                            ', Ab.Princ.: '||w_parametri.flag_ab_principale||', familiari: '||w_parametri.numero_familiari);
    dbms_output.put_line('Tributo: '||w_parametri.tributo||', categoria: '||w_parametri.categoria||
                                                              ', dal: '|| w_parametri.dal_anno||', al: '|| w_parametri.al_anno);
    dbms_output.put_line('Periodo: '||w_parametri.periodo||', mese da: '|| w_parametri.da_mese_ruolo||', mese a: '|| w_parametri.a_mese_ruolo);
  end if;
  --
  w_res := f_svuotamenti(w_parametri,true,w_svuotamenti);
  --
  w_svuotamenti_min_per := round(w_svuotamenti.svuotamenti_minimi * w_parametri.periodo,2);
  if w_debug > 0 then
    dbms_output.put_line('VC: '||w_svuotamenti.capienza_totale||', SM: '||w_svuotamenti.svuotamenti_minimi||', SMP: '||w_svuotamenti_min_per||
                       ', FMax: '||w_svuotamenti.max_familiari);
  end if;
  --
  if w_svuotamenti.capienza_totale > w_svuotamenti_min_per then
    w_eccedenza.ruolo := w_parametri.ruolo;
    w_eccedenza.cod_fiscale := w_parametri.cod_fiscale;
    w_eccedenza.tributo := w_parametri.tributo;
    w_eccedenza.categoria := w_parametri.categoria;
    --
    w_eccedenza.domestica := true;
    w_eccedenza.dal := w_parametri.dal_anno;
    w_eccedenza.al := w_parametri.al_anno;
    w_eccedenza.numero_familiari := w_parametri.numero_familiari;
    --
    w_eccedenza.costo_unitario := w_parametri.costo_unitario;                                          -- CU
    --
    w_eccedenza.superficie := null;                                                                    -- ST - Non usato x D
    --
    w_eccedenza.totale_svuotamenti := w_svuotamenti.capienza_totale;                                   -- VC
    w_eccedenza.importo_minimi := w_svuotamenti_min_per * w_eccedenza.costo_unitario;                  -- CM = SM(P) * CU
    w_eccedenza.costo_svuotamento := w_svuotamenti.capienza_totale * w_eccedenza.costo_unitario;       -- CS = VC * CU
    w_eccedenza.imposta := w_eccedenza.costo_svuotamento - w_eccedenza.importo_minimi;                 -- EC = CS – CM se > 0
    --
    w_eccedenza.svuotamenti_superficie := null;                                                         -- Non usati x D
    w_eccedenza.costo_superficie := null;
    w_eccedenza.eccedenza_svuotamenti := null;
    --
    w_note := '';
    --
  --if w_parametri.periodo < 1.0 then
      if length(w_note) > 0 then
         w_note := w_note||chr(13)||chr(10);
      end if;
      w_note := w_note||
                'SM='||w_svuotamenti_min_per||' '||
                '(SM: '||w_svuotamenti.svuotamenti_minimi||' per gg: '||round(w_parametri.periodo * w_parametri.gg_anno_ruolo)||
                ' dal: '||to_char(w_parametri.dal_anno,'dd/MM/YYYY')||' al: '||to_char(w_parametri.al_anno,'dd/MM/YYYY')||')';
  --end if;
    --
    w_eccedenza.note := w_note;
    --
    calcola_lordo(w_parametri, w_eccedenza);
  else
    w_eccedenza.ruolo := 0;
  end if;
  --
  return w_return;
END;
--
----------------------------------
-- Calcolo Eccddenze - Non Domestica
----------------------------------
function f_eccedenza_nd
  ( w_parametri   t_eccedenze_parametri,
    w_eccedenza   IN OUT  t_eccedenze_totali
  )
RETURN number
IS
  w_svuotamenti   t_eccedenze_suotamenti;
  w_res           number;
  --
  w_note          varchar2(2000);
  --
  w_return        number;
BEGIN
  --
  w_return := 0;
  --
  if w_debug > 0 then
    dbms_output.put_line('Trattamento Non_Domestica - Consistenza: '||w_parametri.consistenza);
    dbms_output.put_line('Tributo: '||w_parametri.tributo||', categoria: '||w_parametri.categoria||
                                                              ', dal: '|| w_parametri.dal_anno||', al: '|| w_parametri.al_anno);
    dbms_output.put_line('Periodo: '||w_parametri.periodo||', Mese da: '|| w_parametri.da_mese_ruolo||', Mese a: '|| w_parametri.a_mese_ruolo);
  end if;
  --
  w_res := f_svuotamenti(w_parametri,false,w_svuotamenti);
  --
  if w_debug > 0 then
    dbms_output.put_line('VC: '||w_svuotamenti.capienza_totale||', ST: '||w_parametri.consistenza||', MC: '||w_svuotamenti.importo_minimi);
  end if;
  --
  -- Crea sempre, decide poi
  --
  w_eccedenza.ruolo := w_parametri.ruolo;
  w_eccedenza.cod_fiscale := w_parametri.cod_fiscale;
  w_eccedenza.tributo := w_parametri.tributo;
  w_eccedenza.categoria := w_parametri.categoria;
  --
  w_eccedenza.dal := null;
  w_eccedenza.al := null;
  w_eccedenza.numero_familiari := null;
  w_eccedenza.domestica := false;
  --
  w_eccedenza.costo_unitario := w_parametri.costo_unitario;                                                  -- CU
  --
  w_eccedenza.superficie := round((w_parametri.consistenza * w_parametri.periodo),2);                        -- ST
  --
  w_eccedenza.totale_svuotamenti := w_svuotamenti.capienza_totale;                                           -- VC
  w_eccedenza.importo_minimi := w_svuotamenti.importo_minimi;                                                -- MC
  w_eccedenza.costo_svuotamento := w_svuotamenti.capienza_totale * w_eccedenza.costo_unitario;               -- CS = VC * CU
  --
  w_eccedenza.svuotamenti_superficie := w_eccedenza.superficie * w_svuotamenti.importo_minimi;               -- SS = ST * MC
  w_eccedenza.costo_superficie := w_eccedenza.svuotamenti_superficie * w_eccedenza.costo_unitario;           -- CP = SS * CU
  w_eccedenza.eccedenza_svuotamenti := w_eccedenza.totale_svuotamenti - w_eccedenza.svuotamenti_superficie;  -- ES = VC - SS
  --
  w_eccedenza.imposta := null;         -- Li calcola dopo l'accorpamento
  w_eccedenza.addizionale_pro := 0;
  w_eccedenza.importo_ruolo := 0;
  --
--if w_parametri.periodo < 1.0 then
  w_note := 'ST='||w_eccedenza.superficie||' '||
            '(Sup: '||w_parametri.consistenza||' per gg: '||round(w_parametri.periodo * w_parametri.gg_anno_ruolo)||
            ' dal: '||to_char(w_parametri.dal_anno,'dd/MM/YYYY')||' al: '||to_char(w_parametri.al_anno,'dd/MM/YYYY')||')';
--else
--  w_note := '';
--end if;
  --
  w_eccedenza.note := w_note;
  --
  return w_return;
  --
END;
--
----------------------------------
-- Accorpa eccedenza - Domestica
----------------------------------
procedure accorpa_eccedenza_d
  ( w_eccedenza              t_eccedenze_totali
  )
IS
  w_esistente_idx            binary_integer;
  w_esistente                t_eccedenze_totali;
BEGIN
  --
  if w_debug > 0 then
    dbms_output.put_line('Accorpo Eccedenza D - Tributo: '||w_eccedenza.tributo||', categoria: '||w_eccedenza.categoria||
                         ', importo: '||w_eccedenza.imposta|| ', add: '||w_eccedenza.addizionale_pro||', lordo: '||w_eccedenza.importo_ruolo);
  end if;
  --
  w_esistente_idx := f_cerca_eccedenza(w_eccedenza);
  --
  if w_esistente_idx > 0 then
  --dbms_output.put_line('Esistente : Accorpo a '||w_esistente_idx);
    --
    w_esistente := w_totali_table(w_esistente_idx);
    --
    w_esistente.imposta := w_esistente.imposta + w_eccedenza.imposta;
    --
    w_esistente.importo_minimi := w_esistente.importo_minimi + w_eccedenza.importo_minimi;
    w_esistente.totale_svuotamenti := w_esistente.totale_svuotamenti + w_eccedenza.totale_svuotamenti;
    w_esistente.costo_svuotamento := w_esistente.costo_svuotamento + w_eccedenza.costo_svuotamento;
    --
  --w_esistente.superficie := w_esistente.superficie;              -- + w_eccedenza.superficie;
    --
    if nvl(w_esistente.note,'') = '' then
      w_esistente.note := w_eccedenza.note;
    else
      w_esistente.note := substr(w_esistente.note||chr(13)||chr(10)||w_eccedenza.note,1,2000);
    end if;
    --
    w_esistente.addizionale_pro := w_esistente.addizionale_pro + w_eccedenza.addizionale_pro;
    w_esistente.importo_ruolo := w_esistente.importo_ruolo + w_eccedenza.importo_ruolo;
    --
    w_totali_table(w_esistente_idx) := w_esistente;
  else
   --dbms_output.put_line('Nuova : Aggiungo');
     --
     w_totali_table.extend;
     w_esistente_idx := w_totali_table.last;
     w_totali_table(w_esistente_idx) := w_eccedenza;
  end if;
END;
--
----------------------------------
-- Accorpa eccedenza - Non domestica
----------------------------------
procedure accorpa_eccedenza_nd
  ( w_eccedenza              t_eccedenze_totali
  )
IS
  w_esistente_idx            binary_integer;
  w_esistente                t_eccedenze_totali;
BEGIN
  --
  if w_debug > 0 then
    dbms_output.put_line('Accorpo Eccedenza ND - Tributo: '||w_eccedenza.tributo||', categoria: '||w_eccedenza.categoria||', importo: '||w_eccedenza.imposta);
  end if;
  --
  w_esistente_idx := f_cerca_eccedenza(w_eccedenza);
  --
  if w_esistente_idx > 0 then
  --dbms_output.put_line('Esistente : Accorpo a '||w_esistente_idx);
    --
    w_esistente := w_totali_table(w_esistente_idx);
    --
  --w_esistente.imposta := ;                                                                      -- Li calcola dopo l'accorpamento
  --w_esistente.addizionale_pro := 0;
    --
    w_esistente.totale_svuotamenti := w_esistente.totale_svuotamenti + w_eccedenza.totale_svuotamenti;
    w_esistente.costo_svuotamento := w_esistente.costo_svuotamento + w_eccedenza.costo_svuotamento;
    --
    w_esistente.superficie := w_esistente.superficie + w_eccedenza.superficie;
    --
    w_esistente.svuotamenti_superficie := w_esistente.svuotamenti_superficie + w_eccedenza.svuotamenti_superficie;
    w_esistente.costo_superficie := w_esistente.costo_superficie + w_eccedenza.costo_superficie;
    w_esistente.eccedenza_svuotamenti := w_esistente.eccedenza_svuotamenti + w_eccedenza.eccedenza_svuotamenti;
    --
    if w_esistente.note is null then
      w_esistente.note := w_eccedenza.note;
    else
      w_esistente.note := substr(w_esistente.note||chr(13)||chr(10)||w_eccedenza.note,1,2000);
    end if;
    --
    w_totali_table(w_esistente_idx) := w_esistente;
  else
   --dbms_output.put_line('Nuova : Aggiungo');
     --
     w_totali_table.extend;
     w_esistente_idx := w_totali_table.last;
     w_totali_table(w_esistente_idx) := w_eccedenza;
  end if;
END;
--
----------------------------------
-- Accorpa eccedenza - Non domestica - Calcola eccedenza
----------------------------------
procedure calcola_eccedenza_nd
  ( w_parametri              t_eccedenze_parametri
  , w_eccedenza       IN OUT t_eccedenze_totali
  )
IS
  w_delta                    number;
BEGIN
  --
  if w_debug > 0 then
    dbms_output.put_line('Completo Eccedenza ND - Tributo: '||w_eccedenza.tributo||', categoria: '||w_eccedenza.categoria);
  end if;
  --
  w_delta := w_eccedenza.totale_svuotamenti - (w_eccedenza.superficie * w_eccedenza.importo_minimi);    -- DC = VC - (ST * MC)
  --
  if w_delta > 0 then
    w_eccedenza.imposta := w_delta * w_eccedenza.costo_unitario;
  else
    w_eccedenza.imposta := 0;
  end if;
  --
  calcola_lordo(w_parametri,w_eccedenza);
  --
END;
--
----------------------------------
-- Accorpa eccedenze per tributo e categoria
----------------------------------
procedure accorpa_eccedenze
  ( w_parametri       t_eccedenze_parametri
  )
IS
  w_count             binary_integer;
  --
  w_eccedenza         t_eccedenze_totali;
BEGIN
  --
  w_totali_table.delete;
  --
  -- Accorpa le eccedenze per tributo/categoria
  --
  w_count := w_eccedenze_table.count;
--dbms_output.put_line('Accorpo Eccedenze - Count: '||w_count);
  --
  if w_count > 0 then
    for i in w_eccedenze_table.first..w_eccedenze_table.last
    loop
      w_eccedenza := w_eccedenze_table(i);
      if w_eccedenza.domestica != false then
        accorpa_eccedenza_d(w_eccedenza);
      else
--w_eccedenza.ruolo := w_eccedenza.ruolo;
        accorpa_eccedenza_nd(w_eccedenza);
      end if;
    end loop;
  end if;
  --
  -- Completa calcolo eccedenze
  --
  w_count := w_totali_table.count;
--dbms_output.put_line('Completo Eccedenze - Count: '||w_count);
  --
  if w_count > 0 then
    for i in w_totali_table.first..w_totali_table.last
    loop
      w_eccedenza := w_totali_table(i);
      if w_eccedenza.domestica = false then
        calcola_eccedenza_nd(w_parametri,w_eccedenza);
      end if;
      w_totali_table(i) := w_eccedenza;
    end loop;
  end if;
  --
  w_eccedenze_table.delete;
  --
END;
--
----------------------------------
-- Calcola lordo eccedenze
----------------------------------
procedure calcola_lordo
  ( w_parametri   IN      t_eccedenze_parametri,
    w_eccedenza   IN OUT  t_eccedenze_totali
  )
IS
  w_importo               number;
  w_imp_addizionale_pro   number;
  w_imp_addizionale_eca   number;
  w_imp_maggiorazione_eca number;
BEGIN
  --
  if w_debug > 0 then
    dbms_output.put_line('Lordo Eccedenza - Tributo: '||w_eccedenza.tributo||', categoria: '||w_eccedenza.categoria||', importo: '||w_eccedenza.imposta);
  end if;
  --
  w_importo := w_eccedenza.imposta;
  --
  w_imp_addizionale_pro   := f_round(w_importo * w_parametri.addizionale_pro / 100,1);
  w_imp_addizionale_eca   := f_round(w_importo * w_parametri.addizionale_eca / 100,1);
  w_imp_maggiorazione_eca := f_round(w_importo * w_parametri.maggiorazione_eca / 100,1);
  --
  w_eccedenza.addizionale_pro := w_imp_addizionale_pro;
  w_eccedenza.importo_ruolo := w_importo + w_imp_addizionale_pro + w_imp_addizionale_eca + w_imp_maggiorazione_eca;
  --
END;
--
----------------------------------
-- Inserisce l'eccedenza nel db
----------------------------------
procedure inserisci_eccedenza
  ( w_eccedenza   t_eccedenze_totali
  , w_utente      varchar2
  )
IS
  --
  w_id_eccedenza         number(10,0);
  --
  w_flag_domestica       varchar(2);
  --
BEGIN
  --
  if w_debug > 0 then
    dbms_output.put_line('Inserisco Eccedenza - Tributo: '||w_eccedenza.tributo||', categoria: '||w_eccedenza.categoria||
                                              ', importo: '||w_eccedenza.imposta||', lordo: '||w_eccedenza.importo_ruolo);
  end if;
  --
  if w_eccedenza.importo_ruolo = 0 then
    if w_debug > 0 then
      dbms_output.put_line('Importo Zero - Ignorata !');
    end if;
    w_flag_domestica := null;
  else
    -- Importo_ruolo non zero
    BEGIN
      if w_eccedenza.domestica != false then
        w_flag_domestica := 'S';
      else
        w_flag_domestica := null;
      end if;
      --
      insert into ruoli_eccedenze
           (ruolo,cod_fiscale,
            tributo,categoria,
            dal,al,flag_domestica,numero_familiari,
            imposta,addizionale_pro,
            importo_ruolo,importo_minimi,
            totale_svuotamenti,superficie,
            costo_unitario,costo_svuotamento,
            svuotamenti_superficie,
            costo_superficie,
            eccedenza_svuotamenti,
            utente,note
           )
      values(w_eccedenza.ruolo,w_eccedenza.cod_fiscale,
             w_eccedenza.tributo,w_eccedenza.categoria,
             w_eccedenza.dal,w_eccedenza.al,w_flag_domestica,w_eccedenza.numero_familiari,
             w_eccedenza.imposta,w_eccedenza.addizionale_pro,
             w_eccedenza.importo_ruolo,w_eccedenza.importo_minimi,
             w_eccedenza.totale_svuotamenti,w_eccedenza.superficie,
             w_eccedenza.costo_unitario,w_eccedenza.costo_svuotamento,
             w_eccedenza.svuotamenti_superficie,
             w_eccedenza.costo_superficie,
             w_eccedenza.eccedenza_svuotamenti,
             w_utente,w_eccedenza.note
           )
      ;
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore inserendo eccedenza ruolo';
        RAISE errore;
    END;
  end if;     -- Importo_ruolo non zero
END;
--
----------------------------------
-- Inserisce le eccedenze accorpate
----------------------------------
procedure inserisci_eccedenze
  ( w_utente      varchar2
  )
IS
  w_count                    binary_integer;
  --
  w_eccedenza                t_eccedenze_totali;
BEGIN
  --
  w_count := w_totali_table.count;
--dbms_output.put_line('Inserisco Eccedenze - Count: '||w_count);
  --
  if w_count > 0 then
    for i in w_totali_table.first..w_totali_table.last
    loop
      w_eccedenza := w_totali_table(i);
      inserisci_eccedenza(w_eccedenza,w_utente);
    end loop;
  end if;
  --
  w_totali_table.delete;
  --
END;
--
----------------------------------
-- E M I S S I O N E   R U O L O
----------------------------------
BEGIN
  BEGIN
    select r.tipo_tributo
          ,r.tipo_ruolo
          ,r.anno_ruolo
          ,r.anno_emissione
          ,r.progr_emissione
          ,r.invio_consorzio
          ,r.data_emissione
          ,r.ruolo_rif
          ,lpad(to_char(d.pro_cliente),3,'0')||
           lpad(to_char(d.com_cliente),3,'0')
          ,r.importo_lordo
          ,nvl(r.rate,0)
          ,r.tipo_emissione
          ,nvl(r.flag_calcolo_tariffa_base,'N')
          ,nvl(r.flag_tariffe_ruolo,'N')
      into w_tipo_tributo
          ,w_tipo_ruolo
          ,w_anno_ruolo
          ,w_anno_emissione
          ,w_progr_emissione
          ,w_invio_consorzio
          ,w_data_emissione
          ,w_ruolo_rif
          ,w_cod_istat
          ,w_importo_lordo
          ,w_rate
          ,w_tipo_emissione
          ,w_flag_tariffa_base
          ,w_flag_ruolo_tariffa
      from ruoli                   r
          ,dati_generali           d
     where r.ruolo                 = a_ruolo
       and d.chiave                = 1
    ;
  EXCEPTION
    WHEN no_data_found THEN
      w_errore := 'Ruolo non presente in tabella o Dati Generali non inseriti';
      RAISE errore;
    WHEN others THEN
      w_errore := 'Errore in ricerca Ruoli o Dati Generali';
      RAISE errore;
  END;
  IF w_invio_consorzio is not null THEN
    w_errore := 'Emissione non consentita: Ruolo gia'' inviato al Consorzio';
    RAISE errore;
  END IF;
  IF w_tipo_ruolo != 2 or w_tipo_emissione != 'T' THEN
    w_errore := 'Emissione non consentita: Tariffa puntuale applicabile solo su ruoli Supplettivi Totali';
    RAISE errore;
  END IF;
  --
  w_esiste_cosu := 'N';
  BEGIN
    select decode(count(*),0,'N','S')
      into w_esiste_cosu
      from componenti_superficie
     where anno = w_anno_ruolo
    ;
  EXCEPTION
    WHEN others THEN
    w_errore := 'Errore determinando Componenti Superficie - Anno: '||w_anno_ruolo;
    RAISE errore;
  END;
  --
  BEGIN
    select nvl(addizionale_pro,0)
          ,nvl(addizionale_eca,0)
          ,nvl(maggiorazione_eca,0)
          ,maggiorazione_tares
          ,nvl(mesi_calcolo,2)
          ,modalita_familiari
          ,flag_tariffa_puntuale
          ,costo_unitario
      into w_addizionale_pro
          ,w_addizionale_eca
          ,w_maggiorazione_eca
          ,w_maggiorazione_tares
          ,w_mesi_calcolo
          ,w_modalita_familiari
          ,w_tariffa_puntuale
          ,w_costo_unitario
      from carichi_tarsu
     where anno              = w_anno_ruolo
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       w_addizionale_pro    := 0;
       w_addizionale_eca    := 0;
       w_maggiorazione_eca  := 0;
       w_tariffa_puntuale   := null;
       w_costo_unitario     := 0;
    WHEN others THEN
       w_errore := 'Errore in ricerca Carichi Tarsu';
       RAISE errore;
  END;
  --
  if w_tariffa_puntuale is null then
    w_errore := 'Tariffa puntuale non abilitata in Carichi Tarsu anno: '||w_anno_ruolo;
    RAISE errore;
  end if;
  --
  if w_mesi_calcolo != 0 then
    w_errore := 'Per le tariffe puntiali ''Mesi Calcolo'' deve essere ZERO - Anno: '||w_anno_ruolo;
    RAISE errore;
  end if;
  if w_modalita_familiari != 1 then
    w_errore := 'Per le tariffe puntiali ''Modalità Calcolo Familiari'' deve essere ''Data Evento'' - Anno: '||w_anno_ruolo;
    RAISE errore;
  end if;
  --
/******************************************************************************
******************************************************************************
-- SOLO_DEBUG
   BEGIN
      delete ruoli_eccedenze
       where ruolo            = a_ruolo
         and cod_fiscale   like a_cod_fiscale
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in eliminazione Ruoli Eccedenze '||
                     '('||SQLERRM||')';
         RAISE errore;
   END;
******************************************************************************
******************************************************************************/
  --
--w_debug := 1;
  --
  -- Supplettivo Totale - Gestione tariffa puntuale
  --
--dbms_output.put_line('Ruolo Supplettivo Totale - Tariffa puntuale');
  --
  w_cod_fiscale_err := ' ';
  w_cod_fiscale_corr := '-';
  w_ni_corr := 0;
  --
  BEGIN
    select decode(to_char(last_day(to_date('02'||w_anno_ruolo,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366)) as gg_anno_ruolo,
           to_date('3112'||w_anno_ruolo,'ddMMYYYY') - to_date('0101'||w_anno_ruolo,'ddMMYYYY') + 1 as gg_anno
      into w_ecc_parametri.gg_anno_ruolo,
           w_ecc_parametri.gg_anno
      from dati_generali
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      w_ecc_parametri.gg_anno_ruolo := 365;
      w_ecc_parametri.gg_anno := 365;
  END;
  --
  w_ecc_parametri.addizionale_pro := w_addizionale_pro;
  w_ecc_parametri.addizionale_eca := w_addizionale_eca;
  w_ecc_parametri.maggiorazione_eca := w_maggiorazione_eca;
  w_ecc_parametri.flag_tariffa_base := w_flag_tariffa_base;
  w_ecc_parametri.flag_ruolo_tariffa := w_flag_ruolo_tariffa;
  --
  w_ecc_parametri.costo_unitario := w_costo_unitario;
  --
  w_eccedenze_table.delete;         -- Dettagli di eccedenza
  w_totali_table.delete;            -- Totali delel eccedenze accorpate per tributo/categoria
  --
  FOR rec_ogpr IN sel_ogpr_validi
                  (w_anno_ruolo
                  ,a_cod_fiscale
                  ,w_tipo_tributo
                  ,'P'
                  ,w_data_emissione)
  LOOP
    --
    if w_debug > 0 then
      dbms_output.put_line('-------------------------------------------------------');
      dbms_output.put_line('Oggetto: '||rec_ogpr.oggetto||', Oggetto pratica: '||rec_ogpr.oggetto_pratica||', Oggetto pratica rif.: '||rec_ogpr.oggetto_pratica_rif);
    end if;
    --
    w_da_trattare := true;         -- Per eventuali personalizzazioni
    --
    IF w_da_trattare != false then
      IF rec_ogpr.flag_ruolo is not null THEN
        --
        -- Questo calcolo va fatto solo se risulta già scaduta l'ultima rata del ruolo principale del CF, se esistente
        --
        if w_debug > 0 then
          dbms_output.put_line('Ruolo_Totale: '||rec_ogpr.ruolo_totale);
        end if;
        if rec_ogpr.ruolo_totale > 0 then
          w_scadenza_ruolo_p := f_scadenza_ruolo(rec_ogpr.ruolo_totale);
          if w_scadenza_ruolo_p < sysdate then
            w_ruolo_scaduto := true;
          else
            w_ruolo_scaduto := false;
          end if;
        else
            w_ruolo_scaduto := true;
        end if;
        --
        IF w_ruolo_scaduto != false then
        --dbms_output.put_line('Ultima rata ruolo P scaduta il: '||w_scadenza_ruolo_p);
          --
          -- Elabora solo esiste del dovuto per il tributo cui l'eccedenza fa riferimento
          --
          -- Nota : Siccome il calcolo delle eccedenze viene fatto prima degli oggetti non possiamo falro qui.
          --        Modificato emissione_ruoli per rimuovere le eccedenze superflue.
          --
        --w_chk_dovuto := f_verifica_dovuto(rec_ogpr.cod_fiscale,rec_ogpr.tributo,a_ruolo,nvl(rec_ogpr.ruolo_totale,0));
        --IF w_chk_dovuto <> 0 THEN
            if w_debug > 0 then
              dbms_output.put_line('C.F. : '||rec_ogpr.cod_fiscale||', NI: '||rec_ogpr.ni||', dovuto tributo: '||w_chk_dovuto);
            end if;
            --
            if w_cod_fiscale_corr <> rec_ogpr.cod_fiscale then
              --
              -- Cambio C.F. - Completa elaborazione
              --
              if w_cod_fiscale_corr != '-' then
                accorpa_eccedenze(w_ecc_parametri);
                inserisci_eccedenze(a_utente);
              end if;
              --
              w_cod_fiscale_corr := rec_ogpr.cod_fiscale;
              w_ni_corr := rec_ogpr.ni;
              w_cod_fiscale_err := '(1) - '||rec_ogpr.cod_fiscale;
            end if;
            --
            -- Gestione Variazione in corso anno
            --
            w_rc_porzioni := f_porzioni_anno(rec_ogpr.ni,w_anno_ruolo,w_esiste_cosu,rec_ogpr.flag_ab_principale,
                                                                                            rec_ogpr.consistenza,rec_ogpr.numero_familiari);
            loop
              fetch w_rc_porzioni into w_ecc_porzioni;
              EXIT WHEN w_rc_porzioni%NOTFOUND;
              --
              if w_debug > 0 then
                dbms_output.put_line('Porzione '||w_ecc_porzioni.anno||', dal: '||w_ecc_porzioni.dal||', al: '||w_ecc_porzioni.al
                                                ||', gg_porz: '||w_ecc_porzioni.gg_porz||', gg_porz_tot: '||w_ecc_porzioni.gg_porz_tot
                                                ||', gg_anno: '||w_ecc_parametri.gg_anno||', n.fam: '||w_ecc_porzioni.numero_familiari);
              end if;
              --
              if w_ecc_parametri.gg_anno <> w_ecc_porzioni.gg_porz_tot then
                if w_debug > 0 then
                  dbms_output.put_line('Errore GG anno !!!!');
                end if;
              end if;
              --
              -- Verifica porzione anno interessata
              --
              if w_debug > 0 then
                dbms_output.put_line('OGPR dal: '||rec_ogpr.dal_anno||', al: '||rec_ogpr.al_anno);
                dbms_output.put_line('Porzione dal: '||w_ecc_porzioni.dal||', al: '||w_ecc_porzioni.al);
              end if;
              --
              w_chk_eccedente := 0;
              --
              if rec_ogpr.dal_anno <= w_ecc_porzioni.al and
                    rec_ogpr.al_anno >= w_ecc_porzioni.dal then
                --
                if w_debug > 0 then
                  dbms_output.put_line('+++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                  dbms_output.put_line('Esiste periodo di sovrapposizione');
                end if;
                --
                w_ecc_parametri.dal_anno := greatest(rec_ogpr.dal_anno,w_ecc_porzioni.dal);
                w_ecc_parametri.al_anno := least(rec_ogpr.al_anno,w_ecc_porzioni.al);
                --
                w_ecc_parametri.cod_fiscale := w_cod_fiscale_corr;
                w_ecc_parametri.ruolo := a_ruolo;
                w_ecc_parametri.anno_ruolo := w_anno_ruolo;
                w_ecc_parametri.consistenza := rec_ogpr.consistenza;
                w_ecc_parametri.oggetto := rec_ogpr.oggetto;
                --
                w_ecc_parametri.tributo := rec_ogpr.tributo;
                w_ecc_parametri.categoria := rec_ogpr.categoria;
                w_ecc_parametri.tipo_tariffa := rec_ogpr.tipo_tariffa;
                w_ecc_parametri.flag_domestica := rec_ogpr.flag_domestica;
                w_ecc_parametri.flag_ab_principale := rec_ogpr.flag_ab_principale;
                --
                w_ecc_parametri.numero_familiari := nvl(w_ecc_porzioni.numero_familiari,rec_ogpr.numero_familiari);
                --
                -- Per gestire correttamente i Bisestili con inpa 365 gg
                w_periodo := least(1,f_periodo(w_anno_ruolo,w_ecc_parametri.dal_anno,w_ecc_parametri.al_anno,'P',w_tipo_tributo,a_flag_normalizzato));
              --w_periodo := f_periodo(w_anno_ruolo,w_ecc_parametri.dal_anno,w_ecc_parametri.al_anno,'P',w_tipo_tributo,a_flag_normalizzato);
                --
                w_da_mese_ruolo := to_number(to_char(greatest(w_ecc_parametri.dal_anno,to_date('0101'||to_char(w_anno_ruolo),'ddmmyyyy')),'mm'));
                if a_flag_normalizzato is not null
                 and to_number(to_char(w_ecc_parametri.dal_anno,'yyyy')) = w_anno_ruolo then
                   if to_number(to_char(w_ecc_parametri.dal_anno,'dd')) > 15 and w_da_mese_ruolo < 12 then
                      w_da_mese_ruolo  := w_da_mese_ruolo + 1;
                   end if;
                end if;
                --
                w_ecc_parametri.periodo := w_periodo;
                w_ecc_parametri.da_mese_ruolo := w_da_mese_ruolo;
                w_ecc_parametri.a_mese_ruolo := greatest(least((w_da_mese_ruolo + (w_periodo * 12) - 1),12),w_da_mese_ruolo);
                --
                if w_ecc_parametri.flag_domestica = 'S' then
                  w_res := f_eccedenza_d(w_ecc_parametri,w_ecc_totali);
                else
                  w_res := f_eccedenza_nd(w_ecc_parametri,w_ecc_totali);
                end if;
                w_chk_eccedente := w_ecc_totali.ruolo;
              end if;   -- Verifica prozione anno interessata
              --
              -- Accorda eccedenza se esiste
              --
              if w_chk_eccedente != 0 then
                if w_debug > 0 then
                  dbms_output.put_line('=======================================================');
                  dbms_output.put_line('Eccedenza sul Ruolo: '||w_ecc_totali.ruolo||', importo:. '||w_ecc_totali.imposta);
                end if;
                --
                w_eccedenze_table.extend;
                w_ind := w_eccedenze_table.count;
                w_eccedenze_table(w_ind) := w_ecc_totali;
              end if;
              --
              if w_debug > 0 then
                dbms_output.put_line('#######################################################');
              end if;
              --
            end loop;  -- Gestione Variazione in corso anno
            --
            close w_rc_porzioni;
            w_rc_porzioni := null;
            --
        --ELSE
          --if w_debug > 0 then
            --dbms_output.put_line('C.F. : '||rec_ogpr.cod_fiscale||', NI: '||rec_ogpr.ni||', dovuto tributo: '||w_chk_dovuto);
          --end if;
        --END IF;  -- w_dovuto <> 0
      --ELSE     -- w_ruolo_scaduto != false
        --dbms_output.put_line('Ultima rata ruolo P NON ancora scaduta - Scade il '||w_scadenza_ruolo_p||' !');
        END IF;  -- w_ruolo_scaduto != false
      END IF;  -- rec_ogpr.flag_ruolo is not null
    END IF;  -- w_da_trattare != false
  END LOOP;
  --
  -- Ultimo C.F, - Completa elaborazione
  --
  accorpa_eccedenze(w_ecc_parametri);
  inserisci_eccedenze(a_utente);
  --
EXCEPTION
   WHEN ERRORE THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore||' - '||w_cod_fiscale_err,TRUE);
   WHEN others THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR
        (-20999,'Errore in Emissione Ruolo per '||w_cod_fiscale_err||' ('||SQLERRM||')');
END;
/* End Procedure: EMISSIONE_RUOLO_PUNTUALE */
/
