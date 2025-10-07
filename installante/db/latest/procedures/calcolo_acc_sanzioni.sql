--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_acc_sanzioni stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CALCOLO_ACC_SANZIONI
/*************************************************************************
  Rev.    Date         Author      Note
  013     20/05/2025   RV          #77609
                                   Adeguamento nuovo DL regime sanzionatorio
  012     16/12/2024   RV          #76942
                                   Ignora spese di notifica doppie su pratica recuperata
  011     20/05/2024   RV          #70776
                                   Gestione separata per pratiche 'P', 'T', e 'P' entro l'annualità
  010     08/04/2024   RV          #54732
                                   Aggiunto parametro gruppo_tributo specifico per CUNI
  009     26/03/2024   RV          #71295
                                   Modificato insert oggetti_pratiche com campi mancanti
  008     19/02/2024   RV          #69834
                                   Esclusione oggetti CUNI nati il 31/12/anno_calcolo
  007     20/04/2023   DM          Issue #61132 correzione gestione sanzione 198
  006     08/03/2023   VM          Issue #61132
                                   Aggiunto parametro a_se_spese_notifica e
                                   aggiunta condizione per inserimento sanzione spese di notifica
  005     21/02/2023   RV          Issue #62507
                                   Modifica insert oggetti_pratica x dati concessione
                                   Modificato sel_prat oggetti con imposta zero x CUNI
  004     02/02/2023   AB          Issue #48451
                                   Aggiunta la eliminazione sanzioni per deceduti
  003     10/01/2023   AB          Salvataggio anno in oggetti_pratica
  002     14/03/2022   VD          Verificato per gestione CUNI.
                                   Modificato test su codici sanzioni (ora
                                   si usa il tipo causale).
                                   Attivata gestione spese di notifica per
                                   tutti i tipi tributo.
  001     16/09/2016   VD          Gestione nuovo sanzionamento 2016
*************************************************************************/
(a_cod_fiscale           in varchar2
,a_tipo_tributo          in varchar2
,a_anno                  in number
,a_utente                in varchar2
,a_imposta_r1            in number
,a_scadenza_r1           in date
,a_stringa_vers_r1       in varchar2
,a_stringa_eccedenze_r1  in varchar2
,a_imposta_r2            in number
,a_scadenza_r2           in date
,a_stringa_vers_r2       in varchar2
,a_stringa_eccedenze_r2  in varchar2
,a_imposta_r3            in number
,a_scadenza_r3           in date
,a_stringa_vers_r3       in varchar2
,a_stringa_eccedenze_r3  in varchar2
,a_imposta_r4            in number
,a_scadenza_r4           in date
,a_stringa_vers_r4       in varchar2
,a_stringa_eccedenze_r4  in varchar2
,a_concessione_attiva    in varchar2
,a_se_spese_notifica     in varchar2 default null
,a_gruppo_tributo        in varchar2 default null
,a_pratica_da_acc        in number default null
) is
  --
    errore                   exception;
    w_errore                 varchar2(2000);
  --
    w_pratica                number;
    w_data_pratica           date;
    w_oggetto_pratica        number;
    w_cod_sanzione           number;
    w_ins_pratica            varchar2(2);
    w_interessi              number;
    w_semestri               number;
    w_rata                   number;
    w_imposta                number;
    w_scadenza               date;
    w_versato                number;
    w_tardivo                number;
    w_tardivo_30             number;
    w_omesso                 number;
    w_eccedenza              number;
    w_importo                number;
    w_tot_omesso             number;
    w_tot_interessi          number;
    w_giorni_r1              number;
    w_giorni_r2              number;
    w_giorni_r3              number;
    w_giorni_r4              number;
    w_giorni_temp            number;
    w_giorni_anno            number;
    w_tot_giorni             number;
    w_omesso_r1              number;
    w_omesso_r2              number;
    w_omesso_r3              number;
    w_omesso_r4              number;
    w_interessi_r1           number;
    w_interessi_r2           number;
    w_interessi_r3           number;
    w_interessi_r4           number;
    w_stringa_vers           varchar2(2300);
    w_stringa_eccedenze      varchar2(2300);
    w_ind_s                  number;
    w_ind                    number;
    w_tot_sanzioni           number;
    w_imp_sanzione           number;
    w_giorni_tardivo         number;
    w_cod_istat              varchar2(6);
    w_tardivo_inf_15         number;
    w_tardivo_sup_15         number;
    w_giorni_tardivo_15      number;
    w_tardivo_sup_90         number;
    w_giorni_tardivo_90      number;
    w_gg_diff                number;
    w_flag_canone            varchar2(1);
    w_stato_sogg             number(2);
    w_check                  number(1);
    w_sequenza_sanz          number;
    w_se_spese_notifica      varchar2(1);
-----------------------------------
--F_INSERT_PRAT
-----------------------------------
FUNCTION F_INSERT_PRAT (
  pp_data_pratica       in     date
, pp_cod_fiscale        in     varchar2
, pp_tipo_tributo       in     varchar2
, pp_gruppo_tributo     in     varchar2
, pp_pratica_da_acc     in     number
, pp_anno               in     number
, pp_utente             in     varchar2
, pp_conc_attiva        in     varchar2
, pp_pratica            in out number
, pp_oggetto_pratica    in out number
) RETURN string
IS
  --
  w_num_prtr              number;
  w_num_ogpr              number;
  w_num_ogim              number;
  w_ins                   varchar2(2);
  w_controllo             varchar2(1);
  w_tratta_succ           varchar2(2);
  --
  w_gruppo_tributo        varchar(100);
  w_tipo_occupazione      varchar(20);
  w_note                  varchar(2000);
  --
  w_err                   varchar2(2000);
  --
-- Determinazione degli oggetti per costituire l`accertamento.
cursor sel_prat (
  p_cod_fiscale        in varchar2
, p_tipo_trib          in varchar2
, p_gruppo_trib        in varchar2
, p_pratica_da_acc     in number
, p_anno               in number
, p_conc_attiva        in varchar2
) is
-- (RV - 21/02/2023): modificato join e clause con oggetti_imposte (ogim) dato che per
--                    CUNI ci servono tutti gli oggetti, anche quelli ad imposta zero
            select ogva.cod_fiscale
                 ,ogva.oggetto_pratica
                 ,nvl(ogva.oggetto_pratica_rif,ogva.oggetto_pratica) oggetto_pratica_rif
                 ,decode(ogva.tipo_evento,'V',ogpr.oggetto_pratica,null) oggetto_pratica_rif_v
                 ,ogva.oggetto
                 ,ogva.pratica
                 ,ogva.data
                 ,ogva.numero
                 ,ogva.anno
                 ,ogva.tipo_pratica
                 ,ogva.tipo_evento
                 ,ogva.tipo_occupazione
                 ,ogva.dal
                 ,ogva.al
                 ,nvl(ogim.imposta,0.0) imposta
            from oggetti_pratica      ogpr
               ,oggetti_contribuente  ogco
               ,oggetti_imposta       ogim
               ,oggetti_validita      ogva
               ,codici_tributo        cotr
            where ogpr.oggetto_pratica               = ogva.oggetto_pratica
              and ogco.cod_fiscale                   = ogva.cod_fiscale
              and ogco.oggetto_pratica               = ogva.oggetto_pratica
              and ogim.oggetto_pratica(+)            = ogva.oggetto_pratica
              and nvl(ogim.anno(+),p_anno)           = p_anno
              and ogva.cod_fiscale                   = p_cod_fiscale
              and ogva.tipo_tributo||''              = p_tipo_trib
              and nvl(to_number(to_char(ogva.dal,'yyyy')),0)
                <= p_anno
              and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
                >= p_anno
              and decode(ogva.tipo_pratica,'A',ogva.anno,p_anno - 1)
                <> p_anno
              and decode(ogva.tipo_pratica,'A',ogva.flag_denuncia,'S')
                = 'S'
              and ogpr.tributo = cotr.tributo(+)
-- RV (11/04/2024) : #54732 se specificato filtra per gruppo_tributo
              and ((p_gruppo_trib is null) or
                   ((p_gruppo_trib is not null) and (cotr.gruppo_tributo = p_gruppo_trib))
              )
-- RV (11/04/2024) : #70776 caso CUNI, filtra se per pratica oppure prende tutto il 'P' valido prima del 01/01/anno_calcolo
              and ((p_tipo_trib != 'CUNI') or
                   ((p_pratica_da_acc is not null) and (ogpr.pratica = p_pratica_da_acc)) or
                   ((p_pratica_da_acc is null) and
                    (ogva.tipo_occupazione||'' = 'P') and
                    (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') < lpad(to_char(a_anno),4,'0')||'0101')
                   )
              )
-- RV (19/02/2024) : #69834 caso CUNI, esclude sempre dal calcolo gli oggetti nati il 31/12/anno_calcolo
              and ((p_tipo_trib != 'CUNI') or
                   (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') <> lpad(to_char(p_anno),4,'0')||'1231')
              )
              and nvl(ogva.stato_accertamento,'D')   = 'D'
              and ((ogim.oggetto_pratica is not null) or
                   (p_tipo_trib = 'CUNI'))
              and F_CONCESSIONE_ATTIVA(ogva.cod_fiscale,p_tipo_trib,p_anno
                      ,ogva.pratica,null,null
                      )              = p_conc_attiva
              and (    ogva.tipo_occupazione||''     = 'T'
                or  ogva.tipo_occupazione||''     = 'P'
                           and not exists
                        (select 1
                         from oggetti_validita ogv2
                         where ogv2.cod_fiscale       = ogva.cod_fiscale
                           and ogv2.tipo_tributo||''  = ogva.tipo_tributo
                           and ogv2.oggetto_pratica_rif
                             = ogva.oggetto_pratica_rif
                           and decode(ogv2.tipo_pratica,'A',ogv2.anno,p_anno - 1)
                             <> p_anno
                           and decode(ogv2.tipo_pratica,'A',ogv2.flag_denuncia,'S')
                             = 'S'
                           and nvl(ogv2.stato_accertamento,'D')
                             = 'D'
                           and nvl(to_number(to_char(ogv2.dal,'yyyy')),0)
                             <= p_anno
                           and nvl(to_number(to_char(ogv2.al ,'yyyy')),9999)
                             >= p_anno
                           and (    nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                        >
                                    nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                             or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                     =
                                 nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                        and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                     >
                                            nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                             or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                     =
                                 nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                        and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                     =
                                            nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                                        and ogv2.pratica      > ogva.pratica
                             )
                        )
                )
              and not exists
                (select 1
                 from pratiche_tributo prt2
                    , sanzioni_pratica sap2
                    , sanzioni         sanz
                 where sap2.pratica               = prt2.pratica
                   and prt2.tipo_tributo          = p_tipo_trib
                   and prt2.anno                  = p_anno
                   and prt2.cod_fiscale           = ogva.cod_fiscale
                   and prt2.tipo_pratica          = 'A'
                   and nvl(prt2.stato_accertamento,'D')
                     = 'D'
                   and (   prt2.data_notifica    is not null
                     or prt2.numero           is not null
                     )
                   -- (VD - 14/03/2022): modificato controllo su sanzioni: ora si
                   --                    utilizza il tipo causale invece del codice
                   --and sap2.cod_sanzione         in (6,7,16,17,26,27,36,37,46,47,106,107,116,117,126,127,136,137,146,147
                   --                                 ,8,9,18,19,28,29,38,39,48,49,108,109,118,119,128,129,138,139,148,149
                   --                                 ,160,161,162,163,164,165,166,167,168,169
                   --                                 )
                   and sanz.tipo_tributo          = p_tipo_trib
                   and sanz.cod_sanzione          = sap2.cod_sanzione
                   and sanz.sequenza              = sap2.sequenza_sanz
                   and sanz.tipo_causale          in ('O','P','T')
                )
            order by ogva.oggetto_pratica
        ;
  BEGIN
    w_tratta_succ          := 'SI';
    w_ins                  := 'NO';
    w_err                  := null;
    --
    w_se_spese_notifica := a_se_spese_notifica;
    --
    if pp_tipo_tributo = 'CUNI' then
      --
      -- Per CUNI si cerca di riutilizzare la pratica di accertamento simile
      -- eventulamnete già generata per altre situazioni simili
      --
      -- Prima di tutto prepara le note
      --
      w_gruppo_tributo := null;
      w_tipo_occupazione := null;
      --
      if pp_gruppo_tributo is not null then
        BEGIN
          select grtr.descrizione
            into w_gruppo_tributo
           from gruppi_tributo grtr
          where grtr.tipo_tributo = pp_tipo_tributo
            and grtr.gruppo_tributo = pp_gruppo_tributo
           ;
        EXCEPTION
            WHEN no_data_found THEN
              w_gruppo_tributo := null;
            WHEN OTHERS THEN
              w_err := to_char(SQLCODE)||' - '||SQLERRM;
              Return w_err;
        END;
      end if;
      --
      if pp_pratica_da_acc is not null then
        BEGIN
          select max(ogpr.tipo_occupazione) tipo_occupazione
            into w_tipo_occupazione
            from oggetti_pratica ogpr,
                 pratiche_tributo prtr
           where ogpr.pratica = prtr.pratica
             and prtr.pratica = pp_pratica_da_acc
           ;
        EXCEPTION
            WHEN no_data_found THEN
              w_tipo_occupazione := null;
            WHEN OTHERS THEN
              w_err := to_char(SQLCODE)||' - '||SQLERRM;
              Return w_err;
        END;
        if (w_tipo_occupazione = 'P') then
          w_tipo_occupazione := 'Permanenti';
        else
          w_tipo_occupazione := 'Temporanee';
        end if;
      else
        w_tipo_occupazione := 'Permanenti';
      --w_tipo_occupazione := 'Attualità';    -- Per separare permanenti anni precedenti da annuali
      end if;
      --
      w_note := 'Accertamento '||w_tipo_occupazione;
      if w_gruppo_tributo is not null then
          w_note := w_note||' per '||w_gruppo_tributo;
      end if;
      --
      -- Poi cerca pratica da riutilizzare, solo se NON notificata e NON numerata
      --
      BEGIN
        select prtr.pratica
          into w_num_prtr
          from pratiche_tributo prtr
         where prtr.tipo_tributo||'' = pp_tipo_tributo
           and prtr.tipo_pratica     = 'A'
           and prtr.tipo_evento      = 'A'
           and prtr.cod_fiscale      = pp_cod_fiscale
           and prtr.anno             = pp_anno
           and prtr.data_notifica     is null
           and prtr.numero            is null
           and prtr.note             = w_note;
       EXCEPTION
         WHEN no_data_found THEN
           w_num_prtr := null;
         WHEN OTHERS THEN
           w_err := to_char(SQLCODE)||' - '||SQLERRM;
           Return w_err;
      END;
      if w_num_prtr is not null then
      --dbms_output.put_line('Recupero pratica: '||w_num_prtr);
        w_ins := 'SI';
        w_se_spese_notifica := null;
        pp_pratica := w_num_prtr;
      end if;
    end if;
    --
    FOR rec_prat in sel_prat (pp_cod_fiscale,pp_tipo_tributo,pp_gruppo_tributo,pp_pratica_da_acc,pp_anno,pp_conc_attiva)
        LOOP
        --
--   Se un oggetto e` gia` stato accertato si elimina la eventuale pratica inserita
--
            IF w_tratta_succ = 'SI' then
                BEGIN
                    select 'x'
                    into w_controllo
                    from pratiche_tributo prtr,
                         oggetti_pratica ogpr
                    where prtr.tipo_tributo||'' = pp_tipo_tributo
                      and prtr.tipo_pratica     = 'A'
                      and prtr.tipo_evento      = 'A'
                      and prtr.flag_denuncia    = 'S'
                      and nvl(prtr.stato_accertamento,'D')
                        = 'D'
                      and prtr.cod_fiscale      = pp_cod_fiscale
                      and prtr.anno             = pp_anno
                      and ogpr.pratica          = prtr.pratica
                      and ogpr.oggetto          = rec_prat.oggetto
                      and prtr.pratica         != nvl(pp_pratica,0);
                    RAISE too_many_rows;
                EXCEPTION
                    WHEN no_data_found THEN
                        IF w_ins = 'NO' then
                            w_ins := 'SI';
                            BEGIN
                                w_num_prtr := null;
                                pratiche_tributo_nr(w_num_prtr);
                                pp_pratica := w_num_prtr;
                                insert into PRATICHE_TRIBUTO
                                (pratica,cod_fiscale,tipo_tributo,anno,tipo_pratica,tipo_evento,
                                 data,pratica_rif,flag_adesione,utente,note
                                )
                                values(w_num_prtr,pp_cod_fiscale,pp_tipo_tributo,pp_anno,'A','A',
                                       pp_data_pratica,null,null,'#'||substr(pp_utente,1,7),w_note
                                      )
                                ;
                                insert into RAPPORTI_TRIBUTO
                                (pratica,sequenza,cod_fiscale,tipo_rapporto)
                                values(w_num_prtr,1,pp_cod_fiscale,'E')
                                ;
                            END;
                        END IF;
                        BEGIN
                            w_num_ogpr := null;
                            oggetti_pratica_nr(w_num_ogpr);
                            pp_oggetto_pratica := w_num_ogpr;
                            insert into OGGETTI_PRATICA
                            (oggetto_pratica,oggetto,pratica,consistenza,tributo,categoria,anno,
                             larghezza, profondita, consistenza_reale, quantita,
                             da_chilometro, a_chilometro, lato, fonte,
                             indirizzo_occ, cod_pro_occ, cod_com_occ, note,
                             tipo_tariffa,tipo_occupazione,data_concessione,
                             inizio_concessione,fine_concessione,num_concessione,
                             oggetto_pratica_rif,oggetto_pratica_rif_v,utente
                            )
                            select w_num_ogpr, ogpr.oggetto, w_num_prtr, ogpr.consistenza, ogpr.tributo, ogpr.categoria, pp_anno,
                                   ogpr.larghezza, ogpr.profondita, ogpr.consistenza_reale, ogpr.quantita,
                                   ogpr.da_chilometro, ogpr.a_chilometro, ogpr.lato, ogpr.fonte,
                                   ogpr.indirizzo_occ, ogpr.cod_pro_occ, ogpr.cod_com_occ, ogpr.note,
                                   ogpr.tipo_tariffa, ogpr.tipo_occupazione, ogpr.data_concessione,
                                   ogpr.inizio_concessione, ogpr.fine_concessione, ogpr.num_concessione,
                                   rec_prat.oggetto_pratica_rif, rec_prat.oggetto_pratica_rif_v, pp_utente
                            from OGGETTI_PRATICA ogpr
                            where ogpr.oggetto_pratica = rec_prat.oggetto_pratica
                            ;
                        EXCEPTION
                            WHEN OTHERS THEN
                                w_err := to_char(SQLCODE)||' - '||SQLERRM;
                                Return w_err;
                        END;
                        BEGIN
                            insert into OGGETTI_CONTRIBUENTE
                            (cod_fiscale,oggetto_pratica,anno,tipo_rapporto,
                             inizio_occupazione,fine_occupazione,data_decorrenza,data_cessazione,
                             perc_possesso,mesi_possesso,mesi_possesso_1sem,mesi_esclusione,
                             mesi_riduzione,mesi_aliquota_ridotta,detrazione,
                             flag_possesso,flag_esclusione,flag_riduzione,flag_ab_principale,
                             flag_al_ridotta,utente
                            )
                            select pp_cod_fiscale,w_num_ogpr,pp_anno,tipo_rapporto,
                                   inizio_occupazione,fine_occupazione,data_decorrenza,data_cessazione,
                                   perc_possesso,mesi_possesso,mesi_possesso_1sem,mesi_esclusione,
                                   mesi_riduzione,mesi_aliquota_ridotta,detrazione,
                                   flag_possesso,flag_esclusione,flag_riduzione,flag_ab_principale,
                                   flag_al_ridotta,pp_utente
                            from oggetti_contribuente
                            where oggetto_pratica      = rec_prat.oggetto_pratica
                              and cod_fiscale          = pp_cod_fiscale
                            ;
                        EXCEPTION
                            WHEN OTHERS THEN
                                w_err := to_char(SQLCODE)||' - '||SQLERRM;
                                Return w_err;
                        END;
                        BEGIN
                            w_num_ogim := null;
                            oggetti_imposta_nr(w_num_ogim);
                            insert into OGGETTI_IMPOSTA
                            (OGGETTO_IMPOSTA,COD_FISCALE,ANNO,OGGETTO_PRATICA,IMPOSTA,IMPOSTA_ACCONTO,
                             IMPOSTA_DOVUTA,IMPOSTA_DOVUTA_ACCONTO,TIPO_ALIQUOTA,ALIQUOTA,UTENTE,tipo_tributo
                            )
                            values(w_num_ogim,pp_cod_fiscale,pp_anno,w_num_ogpr,rec_prat.imposta,null,
                                   rec_prat.imposta,null,null,null,pp_utente,a_tipo_tributo
                                  )
                            ;
                        EXCEPTION
                            WHEN OTHERS THEN
                                w_err := to_char(SQLCODE)||' - '||SQLERRM;
                                Return w_err;
                        END;
                    WHEN too_many_rows THEN
                        w_tratta_succ := 'NO';
                        w_err    := 1;
                        IF w_ins = 'SI' THEN
                            BEGIN
                                delete pratiche_tributo
                                where pratica = pp_pratica;
                            EXCEPTION
                                WHEN others THEN
                                    w_err := to_char(SQLCODE)||' - '||SQLERRM;
                                    Return w_err;
                            END;
                        END IF;
                    WHEN others THEN
                        w_err := to_char(SQLCODE)||' - '||SQLERRM;
                        Return w_err;
                END;
            END IF;   -- End tratta_succ
        END LOOP;

    -- Gestione del caso di versamento senza oggetti attivi,
    -- viene inserita la sola pratica
    IF w_ins = 'NO' then
        --w_ins := 'SI';
        BEGIN
            w_num_prtr := null;
            pratiche_tributo_nr(w_num_prtr);
            pp_pratica := w_num_prtr;
            insert into PRATICHE_TRIBUTO
            (pratica,cod_fiscale,tipo_tributo,anno,tipo_pratica,tipo_evento,
             data,pratica_rif,flag_adesione,utente,note
            )
            values(w_num_prtr,pp_cod_fiscale,pp_tipo_tributo,pp_anno,'A','U',
                   pp_data_pratica,null,null,'#'||substr(pp_utente,1,7),w_note
                  )
            ;
            insert into RAPPORTI_TRIBUTO
            (pratica,sequenza,cod_fiscale,tipo_rapporto)
            values(w_num_prtr,1,pp_cod_fiscale,'E')
            ;
        END;
    END IF;
    RETURN w_err;
END F_INSERT_PRAT;
-------------------------------
-- F_SEQUENZA_SANZIONE
-------------------------------
FUNCTION F_SEQUENZA_SANZIONE
(   s_cod_sanzione    IN number,
    s_tipo_tributo    IN varchar2,
    s_data_inizio     in date default null
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
       and sanz.TIPO_TRIBUTO = s_tipo_tributo
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
-------------------------------
-- F_INSERIMENTO_SANZIONE
-------------------------------
FUNCTION F_INSERIMENTO_SANZIONE
/*************************************************************************
 Derivata da INSERIMENTO_SANZIONE : introduce l'aggiornamento se sanzione già esistente
*************************************************************************/
(   a_cod_sanzione    IN number,
    a_tipo_tributo    IN varchar2,
    a_pratica         IN number,
    a_oggetto_pratica IN number,
    a_maggiore_impo   IN number,
    a_impo_sanz       IN number,
    a_utente          IN varchar2,
    a_data_inizio     in date default null
)
return String
IS
  --
  w_impo_sanz     number;
  w_impo_falso    number;
  w_percentuale   number;
  w_riduzione     number;
  w_riduzione_2   number;
  w_semestri      number;
  w_check         number(1);
  --
  w_seq_sanz      number;
  --
  w_errore        varchar2(2000);
  errore          exception;
  --
BEGIN
   IF a_impo_sanz is NULL THEN
      w_impo_sanz := f_round(f_importo_sanzione(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,
                                                w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,a_data_inizio),0);
      IF w_impo_sanz < 0 THEN
         w_errore := 'Errore in Ricerca Sanzioni Pratica ('||a_cod_sanzione||
                         ') '||'('||SQLERRM||')';
         RAISE errore;
      END IF;
   ELSE
      w_impo_sanz := f_round(a_impo_sanz,0);
      w_semestri  := a_maggiore_impo;
      --
      w_impo_falso := f_importo_sanzione(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,
                                         w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,a_data_inizio);
   END IF;
   --
   IF nvl(w_impo_sanz,0) <> 0 THEN
      w_seq_sanz := f_sequenza_sanzione(a_cod_sanzione,a_tipo_tributo,a_data_inizio);
      w_check := f_check_sanzione(a_pratica,a_cod_sanzione,a_data_inizio);
      if w_check = 0 then
        BEGIN
          insert into sanzioni_pratica
                 (cod_sanzione,tipo_tributo,pratica,oggetto_pratica
                 ,percentuale,importo,semestri
                 ,riduzione,riduzione_2,utente,data_variazione
                 ,sequenza_sanz)
          values (a_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica
                 ,w_percentuale,w_impo_sanz,w_semestri
                 ,w_riduzione,w_riduzione_2,a_utente,trunc(sysdate)
                 ,w_seq_sanz)
          ;
        EXCEPTION
          WHEN others THEN
            w_errore := 'Errore in inserimento Sanzioni Pratica ('||
                                a_cod_sanzione||') '||'('||SQLERRM||')';
            RAISE errore;
        END;
      elsif w_check = 1 then
        BEGIN
          update sanzioni_pratica
             set importo       = importo + w_impo_sanz
           where pratica       = a_pratica
             and cod_sanzione  = a_cod_sanzione
             and sequenza_sanz = w_seq_sanz
            ;
        EXCEPTION
          WHEN others THEN
            w_errore := 'Errore aggiornamento Sanzione '||a_cod_sanzione||' di Pratica '||a_pratica;
            RAISE errore;
        END;
      else
         w_errore := 'Errore f_check_sanzione per sanzione: '||
                             to_char(a_cod_sanzione)||' ('||SQLERRM||')';
         RAISE errore;
      end if;
   END IF;
  --
  return w_errore;
  --
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,'Errore in F_INSERIMENTO_SANZIONE'||'('||SQLERRM||')');
  --
END F_INSERIMENTO_SANZIONE;
-------------------------------
-- F_INSERT_SANZ
-------------------------------
FUNCTION F_INSERT_SANZ
( s_rata            in number
, s_cod_sanzione    in number
, s_pratica         in number
, s_oggetto_pratica in number
, s_valore_1        in number
, s_valore_2        in number
, s_tipo_tributo    in varchar2
, s_utente          in varchar2
, s_anno            in number
, s_omesso          in number default null
, s_data_inizio     in date default null
)
RETURN string
IS
  --
  w_erro               varchar2(2000);
  w_cod_sanz           number;
  w_seq_sanz           number;
  --
  w_check              number(1);
  --
BEGIN
  w_erro     := null;
  w_cod_sanz := s_cod_sanzione;
  --
  -- Adattamento del Codice Sanzione secondo la Rata.
  -- No solo per Interessi.
  --
  if w_cod_sanz not in (91, 92, 93, 94, 99, 165, 170) then
    w_cod_sanz := w_cod_sanz + 10 * s_rata;
  end if;
  if w_cod_sanz in (165, 170) then
    -- Gestione nuove sanzioni per tardivo versamento valide dal 07/07/2011 e dal 01/01/2016
    w_cod_sanz := w_cod_sanz + s_rata;
  else
    --
    -- Nuovo Sanzionamento.
    --
    if s_anno > 1997 then
      w_cod_sanz := w_cod_sanz + 100;
    end if;
  end if;
  --
  -- Inserisce o aggiorna sanzione
  --
  if w_cod_sanz in (91, 92, 93, 94, 191, 192, 193, 194) then
    -- s_valore_1 sono i giorni di interesse sulla rata
    -- s_valore_2 è l'interesse sulla rata
    w_seq_sanz := f_sequenza_sanzione(w_cod_sanz,s_tipo_tributo,s_data_inizio);
    w_check := f_check_sanzione(s_pratica,w_cod_sanz,s_data_inizio);
    if w_check = 0 then
      inserimento_interesse_gg(w_cod_sanz,
                               s_tipo_tributo,
                               s_pratica,
                               s_valore_1,
                               s_valore_2,
                               null,
                               null,
                               s_omesso,
                               s_utente,
                               w_seq_sanz);
    elsif w_check = 1 then
       aggiornamento_sanzione(s_pratica
                             ,w_cod_sanz
                             ,s_valore_2
                             ,s_valore_1
                             ,null
                             ,null
                             ,s_omesso
                             ,w_seq_sanz
                             );
    else
       w_erro := 'Errore f_check_sanzione per sanzione: '||
                   to_char(w_cod_sanzione)||' ('||SQLERRM||')';
    end if;
  else
    w_erro := f_inserimento_sanzione(w_cod_sanz,
                         s_tipo_tributo,
                         s_pratica,
                         s_oggetto_pratica,
                         s_valore_1,
                         s_valore_2,
                         s_utente,
                         s_data_inizio
                         );
  end if;
  --
  Return w_erro;
END F_INSERT_SANZ;
-------------------------------
-- F_INSERT_SANZ_GG
-------------------------------
FUNCTION F_INSERT_SANZ_GG
( s_rata             in     number
, s_cod_sanzione     in     number
, s_pratica          in     number
, s_oggetto_pratica  in     number
, s_valore_1         in     number
, s_valore_2         in     number
, s_gg_diff          in     number
, s_tipo_tributo     in     varchar2
, s_utente           in     varchar2
, s_anno             in     number
, s_data_inizio      in     date default null
)
RETURN string
IS
  --
  w_erro         varchar2(2000);
  w_cod_sanz     number;
  --
BEGIN
  w_erro         := null;
  w_cod_sanz     := s_cod_sanzione;
  -- Gestione nuove sanzioni per tardivo versamento valide dal 07/07/2011
  if w_cod_sanz in (160) then
      w_cod_sanz := w_cod_sanz + s_rata;
  end if;
  --
  INSERIMENTO_SANZIONE_GG(w_cod_sanz
      ,s_tipo_tributo
      ,s_pratica
      ,s_oggetto_pratica
      ,s_valore_1
      ,s_valore_2
      ,s_gg_diff
      ,s_utente
      ,0
      ,s_data_inizio
      );
  --
  Return w_erro;
END F_INSERT_SANZ_GG;
--
--  C A L C O L O   A C C   S A N Z I O N I
--
BEGIN
  --
  w_tot_interessi   := 0;
  w_ins_pratica     := 'NO';
  w_ind             := 0;
  w_giorni_r1       := 0;
  w_giorni_r2       := 0;
  w_giorni_r3       := 0;
  w_giorni_r4       := 0;
  w_giorni_temp     := 0;
  w_omesso_r1       := 0;
  w_omesso_r2       := 0;
  w_omesso_r3       := 0;
  w_omesso_r4       := 0;
  w_interessi_r1    := 0;
  w_interessi_r2    := 0;
  w_interessi_r3    := 0;
  w_interessi_r4    := 0;
  w_giorni_anno     := 365;

  w_giorni_tardivo_15 := 15;
  w_giorni_tardivo_90 := 90;
  --
  w_data_pratica := trunc(sysdate);
  --
    BEGIN
        select lpad(to_char(pro_cliente),3,'0')||
               lpad(to_char(com_cliente),3,'0')
        into w_cod_istat
        from dati_generali
        ;
    EXCEPTION
        WHEN no_data_found THEN
            w_errore := 'Dati Generali non inseriti';
            RAISE errore;
        WHEN others THEN
            w_errore := 'Errore in ricerca Dati Generali';
            RAISE errore;
    END;

    BEGIN
        select nvl(flag_canone,'N')
        into w_flag_canone
        from tipi_tributo
        where tipo_tributo = a_tipo_tributo
        ;
    EXCEPTION
        WHEN others THEN
            w_errore := 'Errore in estrazione flag_canone';
            RAISE errore;
    END;

    if w_cod_istat = '050029' then  -- PONTEDERA
        w_giorni_tardivo := 15;
    else
        w_giorni_tardivo := 30;
    end if;

    LOOP
        w_ind := w_ind + 1;
        if w_ind > 4 then
            exit;
        end if;
        if    w_ind = 1 then
            w_rata                 := 1;
            w_imposta              := a_imposta_r1;
            w_scadenza             := a_scadenza_r1;
            w_stringa_vers         := a_stringa_vers_r1;
            w_stringa_eccedenze    := a_stringa_eccedenze_r1;
        elsif w_ind = 2 then
            w_rata                 := 2;
            w_imposta              := a_imposta_r2;
            w_scadenza             := a_scadenza_r2;
            w_stringa_vers         := a_stringa_vers_r2;
            w_stringa_eccedenze    := a_stringa_eccedenze_r2;
        elsif w_ind = 3 then
            w_rata                 := 3;
            w_imposta              := a_imposta_r3;
            w_scadenza             := a_scadenza_r3;
            w_stringa_vers         := a_stringa_vers_r3;
            w_stringa_eccedenze    := a_stringa_eccedenze_r3;
        else
            w_rata                 := 4;
            w_imposta              := a_imposta_r4;
            w_scadenza             := a_scadenza_r4;
            w_stringa_vers         := a_stringa_vers_r4;
            w_stringa_eccedenze    := a_stringa_eccedenze_r4;
        end if;
        --
--    TARDIVO VERSAMENTO E TOTALIZZAZIONE DEL VERSATO.
--
        w_versato    := 0;
        w_tardivo    := 0;
        w_tardivo_30 := 0;
        w_tardivo_sup_15 := 0;
        w_tardivo_inf_15 := 0;
        w_tardivo_sup_90 := 0;
        w_omesso     := 0;
        w_eccedenza  := 0;
        w_ind_s      := 0;

        if w_imposta    <> 0 then
            loop
                if nvl(length(w_stringa_vers),0) < w_ind_s * 23 + 1 then
                    exit;
                end if;
                w_versato := w_versato + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                if to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                    > w_scadenza then
                    w_gg_diff  := to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy') - w_scadenza;
                    if trunc(sysdate) < to_date('06072011','ddmmyyyy') or w_flag_canone = 'S' then
                        if to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                            > w_scadenza + w_giorni_tardivo then
                            w_tardivo     := w_tardivo
                                + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        else
                            w_tardivo_30  := w_tardivo_30
                                + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        end if;
                    else
                        if trunc(sysdate) < to_date('01012016','ddmmyyyy') then
                            if to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                                > w_scadenza + w_giorni_tardivo_15 then
                                w_tardivo_sup_15 := w_tardivo_sup_15
                                    + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                            else
                                w_tardivo_inf_15 := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                            end if;
                        else
                            if to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                                > w_scadenza + w_giorni_tardivo_90 then
                                w_tardivo_sup_90 := w_tardivo_sup_90
                                    + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                            elsif to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                                > w_scadenza + w_giorni_tardivo_15 then
                                w_tardivo_sup_15 := w_tardivo_sup_15
                                    + to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                            else
                                w_tardivo_inf_15 := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                            end if;
                        end if;
                    end if;
                    -- per il tardivo fino a 15 giorni la sanzione dipende dai giorni di ritardo del pagamento
                    -- non è corretto quindi sommare tutti i versamenti tardivi ma va gestito l'inserimento
                    -- o update della sanzione per ogni versamento tardivo entro i 15 giorni
                    --
                    --       TARDIVO ENTRO 15 GIORNI.
                    --
                    if w_tardivo_inf_15 > 0 then
                        if w_ins_pratica = 'NO' then
                            w_errore := F_INSERT_PRAT(
                                  w_data_pratica
                                , a_cod_fiscale
                                , a_tipo_tributo
                                , a_gruppo_tributo
                                , a_pratica_da_acc
                                , a_anno
                                , a_utente
                                , a_concessione_attiva
                                , w_pratica
                                , w_oggetto_pratica
                                );
                            if w_errore is not null and w_errore <> 1 then
                                RAISE ERRORE;
                            end if;
                            if w_errore is null then
                                w_ins_pratica := 'SI';
                            end if;
                        end if;
                    end if;

                    if w_errore is null then
                        if nvl(w_tardivo_inf_15,0) > 0 then
                            w_cod_sanzione := 160;
                            w_errore := F_INSERT_SANZ_GG(w_rata
                                ,w_cod_sanzione
                                ,w_pratica
                                ,null
                                ,w_tardivo_inf_15
                                ,null
                                ,w_gg_diff
                                ,a_tipo_tributo
                                ,a_utente
                                ,a_anno
                                ,w_scadenza
                                );
                            if w_errore is not null then
                                RAISE ERRORE;
                            end if;
                        end if;
                    end if;

                    if  w_ind = 1 then
                      w_importo := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_importo
                            ,w_scadenza +1
                            ,to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                            ,w_giorni_anno
                            ,a_tipo_tributo
                            );
                        w_omesso_r1 := w_omesso_r1 + w_importo;
                        w_interessi_r1 := w_interessi_r1 + w_interessi;
                        w_giorni_temp := to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy') - w_scadenza;
                        if w_giorni_r1  = 0 then
                            w_giorni_r1 := w_giorni_temp;
                        elsif w_giorni_r1 <> w_giorni_temp then
                            w_giorni_r1 := null;
                        end if;
                    elsif w_ind = 2 then
                      w_importo := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_importo
                            ,w_scadenza +1
                            ,to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                            ,w_giorni_anno
                            ,a_tipo_tributo
                            );
                        w_omesso_r2 := w_omesso_r2 + w_importo;
                        w_interessi_r2 := w_interessi_r2 + w_interessi;
                        w_giorni_temp := to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy') - w_scadenza;
                        if w_giorni_r2  = 0 then
                            w_giorni_r2 := w_giorni_temp;
                        elsif w_giorni_r2 <> w_giorni_temp then
                            w_giorni_r2 := null;
                        end if;
                    elsif w_ind = 3 then
                      w_importo := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_importo
                            ,w_scadenza +1
                            ,to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                            ,w_giorni_anno
                            ,a_tipo_tributo
                            );
                        w_omesso_r3 := w_omesso_r3 + w_importo;
                        w_interessi_r3 := w_interessi_r3 + w_interessi;
                        w_giorni_temp := to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy') - w_scadenza;
                        if w_giorni_r3  = 0 then
                            w_giorni_r3 := w_giorni_temp;
                        elsif w_giorni_r3 <> w_giorni_temp then
                            w_giorni_r3 := null;
                        end if;
                    else
                      w_importo := to_number(substr(w_stringa_vers,w_ind_s * 23 + 9,15)) / 100;
                        w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_importo
                            ,w_scadenza +1
                            ,to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy')
                            ,w_giorni_anno
                            ,a_tipo_tributo
                            );
                        w_omesso_r4 := w_omesso_r4 + w_importo;
                        w_interessi_r4 := w_interessi_r4 + w_interessi;
                        w_giorni_temp := to_date(substr(w_stringa_vers,w_ind_s * 23 + 1,8),'ddmmyyyy') - w_scadenza;
                        if w_giorni_r4  = 0 then
                            w_giorni_r4 := w_giorni_temp;
                        elsif w_giorni_r4 <> w_giorni_temp then
                            w_giorni_r4 := null;
                        end if;
                    end if;
                end if;
                w_ind_s := w_ind_s + 1;
            end loop;
            --
--    DETERMINAZIONE DELL'OMESSO.
--
            w_omesso := w_imposta - w_versato;

            if  w_ind = 1 then
                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_omesso
                    ,w_scadenza +1
                    ,trunc(sysdate)
                    ,w_giorni_anno
                    ,a_tipo_tributo
                    );
                w_omesso_r1 := w_omesso_r1 + w_omesso;
                w_interessi_r1 := w_interessi_r1 + w_interessi;
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r1  = 0 then
                    w_giorni_r1 := w_giorni_temp;
                elsif w_giorni_r1 <> w_giorni_temp then
                    w_giorni_r1 := null;
                end if;
            elsif w_ind = 2 then
                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_omesso
                    ,w_scadenza +1
                    ,trunc(sysdate)
                    ,w_giorni_anno
                    ,a_tipo_tributo
                    );
                w_omesso_r2 := w_omesso_r2 + w_omesso;
                w_interessi_r2 := w_interessi_r2 + w_interessi;
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r2  = 0 then
                    w_giorni_r2 := w_giorni_temp;
                elsif w_giorni_r2 <> w_giorni_temp then
                    w_giorni_r2 := null;
                end if;
            elsif w_ind = 3 then
                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_omesso
                    ,w_scadenza +1
                    ,trunc(sysdate)
                    ,w_giorni_anno
                    ,a_tipo_tributo
                    );
                w_omesso_r3 := w_omesso_r3 + w_omesso;
                w_interessi_r3 := w_interessi_r3 + w_interessi;
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r3  = 0 then
                    w_giorni_r3 := w_giorni_temp;
                elsif w_giorni_r3 <> w_giorni_temp then
                    w_giorni_r3 := null;
                end if;
            else
                w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_omesso
                    ,w_scadenza +1
                    ,trunc(sysdate)
                    ,w_giorni_anno
                    ,a_tipo_tributo
                    );
                w_omesso_r4 := w_omesso_r4 + w_omesso;
                w_interessi_r4 := w_interessi_r4 + w_interessi;
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r4  = 0 then
                    w_giorni_r4 := w_giorni_temp;
                elsif w_giorni_r4 <> w_giorni_temp then
                    w_giorni_r4 := null;
                end if;
            end if;

        end if; -- w_imposta    <> 0
--
--    DETERMINAZIONE DELL'ECCEDENZA.
--
--   vale anche per imposta = 0
--
        w_ind_s              := 0;
        loop
            if nvl(length(w_stringa_eccedenze),0) < w_ind_s * 23 + 1 then
                exit;
            end if;
            w_eccedenza   := w_eccedenza
                + to_number(substr(w_stringa_eccedenze,w_ind_s * 23 + 9,15)) / 100;
            w_ind_s := w_ind_s + 1;
        end loop;
        --
        if  w_ind = 1 then
            w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_eccedenza * -1
                ,w_scadenza +1
                ,trunc(sysdate)
                ,w_giorni_anno
                ,a_tipo_tributo
                );
            w_interessi_r1 := w_interessi_r1 + w_interessi;
            if w_interessi <> 0 then
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r1  = 0 then
                    w_giorni_r1 := w_giorni_temp;
                elsif w_giorni_r1 <> w_giorni_temp then
                    w_giorni_r1 := null;
                end if;
            end if;
        elsif w_ind = 2 then
            w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_eccedenza * -1
                ,w_scadenza +1
                ,trunc(sysdate)
                ,w_giorni_anno
                ,a_tipo_tributo
                );
            w_interessi_r2 := w_interessi_r2 + w_interessi;
            if w_interessi <> 0 then
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r2  = 0 then
                    w_giorni_r2 := w_giorni_temp;
                elsif w_giorni_r2 <> w_giorni_temp then
                    w_giorni_r2 := null;
                end if;
            end if;
        elsif w_ind = 3 then
            w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_eccedenza * -1
                ,w_scadenza +1
                ,trunc(sysdate)
                ,w_giorni_anno
                ,a_tipo_tributo
                );
            w_interessi_r3 := w_interessi_r3 + w_interessi;
            if w_interessi <> 0 then
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r3  = 0 then
                    w_giorni_r3 := w_giorni_temp;
                elsif w_giorni_r3 <> w_giorni_temp then
                    w_giorni_r3 := null;
                end if;
            end if;
        else
            w_interessi := F_CALCOLO_INTERESSI_GG_TITR(w_eccedenza * -1
                ,w_scadenza +1
                ,trunc(sysdate)
                ,w_giorni_anno
                ,a_tipo_tributo
                );
            w_interessi_r4 := w_interessi_r4 + w_interessi;
            if w_interessi <> 0 then
                w_giorni_temp := trunc(sysdate) - w_scadenza;
                if w_giorni_r4  = 0 then
                    w_giorni_r4 := w_giorni_temp;
                elsif w_giorni_r4 <> w_giorni_temp then
                    w_giorni_r4 := null;
                end if;
            end if;
        end if;

        if w_imposta    <> 0 then
            --
--       TARDIVO VERSAMENTO.
--
            if nvl(w_tardivo,0) > 0 or nvl(w_tardivo_30,0) > 0 or
               nvl(w_tardivo_sup_15,0) > 0 or nvl(w_tardivo_sup_90,0) > 0 then
                if w_ins_pratica = 'NO' then
                    w_errore := F_INSERT_PRAT(
                          w_data_pratica
                        , a_cod_fiscale
                        , a_tipo_tributo
                        , a_gruppo_tributo
                        , a_pratica_da_acc
                        , a_anno
                        , a_utente
                        , a_concessione_attiva
                        , w_pratica
                        , w_oggetto_pratica
                        );
                    if w_errore is not null and w_errore <> 1 then
                        RAISE ERRORE;
                    end if;
                    if w_errore is null then
                        w_ins_pratica := 'SI';
                    end if;
                end if;
            end if;
            --
--       TARDIVO OLTRE 30 GIORNI.
--
            if w_errore is null then
                if nvl(w_tardivo,0) > 0 then
                    w_cod_sanzione := 8;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica
                        , null
                        , w_tardivo
                        , null
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                end if;
            end if;
            --
--       TARDIVO ENTRO 30 GIORNI.
--
            if w_errore is null then
                if nvl(w_tardivo_30,0) > 0 then
                    if w_ins_pratica = 'NO' then
                        w_errore := F_INSERT_PRAT(
                              w_data_pratica
                            , a_cod_fiscale
                            , a_tipo_tributo
                            , a_gruppo_tributo
                            , a_pratica_da_acc
                            , a_anno
                            , a_utente
                            , a_concessione_attiva
                            , w_pratica
                            , w_oggetto_pratica
                            );
                        if w_errore is not null and w_errore <> 1 then
                            RAISE ERRORE;
                        end if;
                        if w_errore is null then
                            w_ins_pratica := 'SI';
                        end if;
                    end if;
                    w_cod_sanzione := 9;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica,null
                        , w_tardivo_30
                        , null
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                end if;
            end if;

            -- Gestione nuove sanzioni valide dal 06/07/2011 per il Tardivo versamento
--
--       TARDIVO OLTRE 15 GIORNI.
--
            if w_errore is null then
                if nvl(w_tardivo_sup_15,0) > 0 then
                    w_cod_sanzione := 165;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica
                        , null
                        , w_tardivo_sup_15
                        , null
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                end if;
            end if;

            -- Gestione nuove sanzioni valide dal 01/01/2016 per il Tardivo versamento
--
--       TARDIVO OLTRE 90 GIORNI.
--
            if w_errore is null then
                if nvl(w_tardivo_sup_90,0) > 0 then
                    w_cod_sanzione := 170;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica
                        , null
                        , w_tardivo_sup_90
                        , null
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                end if;
            end if;

            --
--       OMESSO.
--
            if w_errore is null then
                if nvl(w_omesso,0) > 0 then
                    if w_ins_pratica = 'NO' then
                        w_errore := F_INSERT_PRAT(
                              w_data_pratica
                            , a_cod_fiscale
                            , a_tipo_tributo
                            , a_gruppo_tributo
                            , a_pratica_da_acc
                            , a_anno
                            , a_utente
                            , a_concessione_attiva
                            , w_pratica
                            , w_oggetto_pratica
                            );
                        if w_errore is not null and w_errore <> 1 then
                            RAISE ERRORE;
                        end if;
                        if w_errore is null then
                            w_ins_pratica := 'SI';
                        end if;
                    end if;
                    if nvl(w_omesso,0) < nvl(w_imposta,0) then
                        w_cod_sanzione := 7;
                    else
                        w_cod_sanzione := 6;
                    end if;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica
                        , null
                        , w_omesso
                        , null
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                    w_cod_sanzione := 1;
                    w_errore := F_INSERT_SANZ(w_rata
                        , w_cod_sanzione
                        , w_Pratica
                        , null
                        , null
                        , w_omesso
                        , a_tipo_tributo
                        , a_utente
                        , a_anno
                        , null
                        , w_scadenza
                        );
                    if w_errore is not null then
                        RAISE ERRORE;
                    end if;
                end if;
            end if;
        end if;
        --
--       ECCEDENZA.
--
--   vale anche per imposta = 0
--
        if w_errore is null then
            if nvl(w_eccedenza,0) > 0 then
                if w_ins_pratica = 'NO' then
                    w_errore := F_INSERT_PRAT(
                          w_data_pratica
                        , a_cod_fiscale
                        , a_tipo_tributo
                        , a_gruppo_tributo
                        , a_pratica_da_acc
                        , a_anno
                        , a_utente
                        , a_concessione_attiva
                        , w_pratica
                        , w_oggetto_pratica
                        );
                    if w_errore is not null and w_errore <> 1 then
                        RAISE ERRORE;
                    end if;
                    if w_errore is null then
                        w_ins_pratica := 'SI';
                    end if;
                end if;
                w_cod_sanzione := 7;
                w_errore := F_INSERT_SANZ(w_rata
                    , w_cod_sanzione
                    , w_Pratica
                    , null
                    , w_eccedenza * -1
                    , null
                    , a_tipo_tributo
                    , a_utente
                    , a_anno
                    , null
                    , w_scadenza
                    );
                if w_errore is not null then
                    RAISE ERRORE;
                end if;
                w_cod_sanzione := 1;
                w_errore := F_INSERT_SANZ(w_rata
                    , w_cod_sanzione
                    , w_Pratica
                    , null
                    , null
                    , w_eccedenza * -1
                    , a_tipo_tributo
                    , a_utente
                    , a_anno
                    , null
                    , w_scadenza
                    );
                if w_errore is not null then
                    RAISE ERRORE;
                end if;
            end if;
        end if;
    END LOOP;
    --
--     INTERESSI.
--
    w_rata := 1;
    loop
        if w_rata  >  4 then
            exit;
        end if;
        if w_rata = 1 then
            w_scadenza      := a_scadenza_r1;
            w_tot_omesso    := round(w_omesso_r1,2);
            w_tot_interessi := round(w_interessi_r1,2);
            w_tot_giorni    := w_giorni_r1;
            w_cod_sanzione  := 91;
        elsif w_rata = 2 then
            w_scadenza      := a_scadenza_r2;
            w_tot_omesso    := round(w_omesso_r2,2);
            w_tot_interessi := round(w_interessi_r2,2);
            w_tot_giorni    := w_giorni_r2;
            w_cod_sanzione  := 92;
        elsif w_rata = 3 then
            w_scadenza      := a_scadenza_r3;
            w_tot_omesso    := round(w_omesso_r3,2);
            w_tot_interessi := round(w_interessi_r3,2);
            w_tot_giorni    := w_giorni_r3;
            w_cod_sanzione  := 93;
        else
            w_scadenza      := a_scadenza_r4;
            w_tot_omesso    := round(w_omesso_r4,2);
            w_tot_interessi := round(w_interessi_r4,2);
            w_tot_giorni    := w_giorni_r4;
            w_cod_sanzione  := 94;
        end if;
        if nvl(w_tot_interessi,0) <> 0 then
            if w_ins_pratica = 'NO' then
                w_errore := F_INSERT_PRAT(
                      w_data_pratica
                    , a_cod_fiscale
                    , a_tipo_tributo
                    , a_gruppo_tributo
                    , a_pratica_da_acc
                    , a_anno
                    , a_utente
                    , a_concessione_attiva
                    , w_pratica
                    , w_oggetto_pratica
                    );
                if w_errore is not null and w_errore <> 1 then
                    RAISE ERRORE;
                end if;
                if w_errore is null then
                    w_ins_pratica := 'SI';
                end if;
            end if;
            if w_errore is null then
                w_errore := F_INSERT_SANZ(w_rata
                    , w_cod_sanzione
                    , w_Pratica
                    , null
                    , w_tot_giorni
                    , w_tot_interessi
                    , a_tipo_tributo
                    , a_utente
                    , a_anno
                    , w_tot_omesso
                    , w_scadenza
                    );
                if w_errore is not null then
                    RAISE ERRORE;
                end if;
            end if;
        end if;
        w_rata := w_rata + 1;
    end loop;
    --
-- SPESE NOTIFICA
--
    if nvl(w_se_spese_notifica,'N') = 'S' then
        BEGIN
            select nvl(sum(nvl(importo,0)),0)
              into w_tot_sanzioni
              from sanzioni_pratica
             where pratica = w_pratica
            ;
            select cod_sanzione
              into w_cod_sanzione
              from (select sanz.*, rank() over(order by sanz.cod_sanzione,sanz.sequenza) as pos
                      from sanzioni sanz
                     where sanz.tipo_tributo = a_tipo_tributo
                       and sanz.tipo_causale = 'S'
                       and sanz.cod_sanzione in
                           (select 197 from dual where a_anno > 1997
                            union
                            select 198 from dual where a_anno > 1997
                            union
                            select 97 from dual where a_anno < 1997
                            union
                            select 98 from dual where a_anno < 1997)
                        and w_data_pratica between
                            sanz.data_inizio and sanz.data_fine
                   )
             where pos = 1
            ;
            --
            if w_tot_sanzioni > 0 then
              w_check := f_check_sanzione(w_pratica,w_cod_sanzione,w_data_pratica);
              if w_check = 0 then
                w_sequenza_sanz := f_sequenza_sanzione(w_cod_sanzione,a_tipo_tributo,w_data_pratica);
                BEGIN
                    select sanzione
                      into w_imp_sanzione
                      from sanzioni
                     where cod_sanzione = w_cod_sanzione
                       and tipo_tributo = a_tipo_tributo
                       and sequenza = w_sequenza_sanz
                    ;
                    if nvl(w_imp_sanzione,0) > 0 then
                        inserimento_sanzione(w_cod_sanzione
                            , a_tipo_tributo
                            , w_pratica
                            , NULL
                            , NULL
                            , w_imp_sanzione
                            , a_utente
                            , w_sequenza_sanz);
                    end if;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN null;
                END;
              end if;
            end if;
        END;
    end if;

    -- (AB - 02/02/2023): se il contribuente è deceduto, si eliminano
    --                    le sanzioni lasciando solo imposta evasa,
    --                    interessi e spese di notifica
    BEGIN
      select stato
        into w_stato_sogg
        from soggetti sogg, contribuenti cont
       where sogg.ni = cont.ni
         and cont.cod_fiscale = a_cod_fiscale
      ;
    EXCEPTION
        WHEN others THEN
            w_errore := 'Errore in ricerca Soggetti '||SQLERRM;
            RAISE errore;
    END;
    if w_stato_sogg = 50 then
        ELIMINA_SANZ_LIQ_DECEDUTI(w_pratica);
    end if;
    COMMIT;

    --end if;
--dbms_output.put_line('Tardivo 30 '||to_char(w_tardivo_30));
--dbms_output.put_line('Tardivo    '||to_char(w_tardivo));
--dbms_output.put_line('Omesso     '||to_char(w_omesso));
--dbms_output.put_line('Eccedenza  '||to_char(w_eccedenza));
--dbms_output.put_line('Interessi  '||to_char(w_interessi));
EXCEPTION
    WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,'CF = '||a_cod_fiscale||' '||w_errore);
    WHEN others THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR
            (-20999,'Errore in Calcolo Automatico Sanzioni di '||
                    a_cod_fiscale||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACC_SANZIONI */
/
