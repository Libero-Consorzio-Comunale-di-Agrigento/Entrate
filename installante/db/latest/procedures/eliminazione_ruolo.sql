--liquibase formatted sql 
--changeset abrandolini:20250326_152423_eliminazione_ruolo stripComments:false runOnChange:true 
 
create or replace procedure ELIMINAZIONE_RUOLO
/******************************************************************************
 Rev. Data       Autore    Descrizione
 ---- ---------- ------    ----------------------------------------------------
 008  07/03/2025 RV        #77568
                           Aggiunta gestione Eccedenze.
 007  11/12/2020 VD        Modificata gestione flag integrazione DEPAG: ora il
                           flag è memorizzato sulla tabella ruoli e quindi
                           bisogna verificare se il ruolo è passato in DEPAG
                           per decidere se occorre eliminare i DEPAG_DOVUTI.
 006  02/12/2020 VD        Modificate condizioni per eliminazione depag_dovuti:
                           ora tratta anche i ruoli suppletivi.
 005  28/05/2020 VD        Eliminazione sanzioni addizionali da sanzioni
                           pratica (cod. 891,892,893,894)
 004  12/03/2018 VD        Pontedera - Gestione conferimenti
                           Aggiunta eliminazione righe CONFERIMENTI_CER_RUOLO
                           per il ruolo indicato
 003  17/11/2016 VD        San Donato Milanese - Sperimentazione Poasco
                           Aggiunto annullamento campi ruolo su tabella
                           CONFERIMENTI.
 002  19/01/2015 BettaT.   Realizzata proc. per eliminazione sgravi
 001  20/06/2002 Davide    Per Non andare ad interferire in altre procedure,
                           e` stata pensata una bruttura per gestire un caso
                           particolare.
                           Si tratta di quando un ruolo passa da importo lordo
                           a netto o viceversa.
                           In questo caso da maschera deve essere eliminato
                           il ruolo ad eccezione del dizionario, perche`
                           successivamente puo` venire rilanciata la emissione.
                           La bruttura consiste nel passare il parametro ruolo
                           negativo.
                           Se questi e` negativo, non si elimina il dizionario;
                           le restanti operazioni rimangono invariate.
******************************************************************************/
( a_ruolo            IN    number
, a_cf               IN    varchar2 default null)
IS
  w_ruolo                  number;
  w_tipo_tributo           varchar2(5);
  w_tipo_emissione         varchar2(1);
  w_tipo_ruolo             number;
  w_anno_ruolo             number;
  w_invio_consorzio        date;
  w_elimina_ruoli          varchar2(1);
  w_errore                 varchar2(2000);
  errore                   exception;
  w_cf_old                 varchar2(17);
-- (VD - 07/07/2020): Variabili per pagonline Castelnuovo
  w_pagonline              varchar2(1);
  w_result                 varchar2(6);
  w_cod_istat              varchar2(6);
  w_cod_castel             varchar2(6) := '108009'; --'046009';
  w_specie_ruolo           number;
CURSOR sel_ogim (p_ruolo number, p_cf varchar2) IS
    select oggetto_imposta, prtr.anno anno_prtr, prtr.tipo_pratica,ogim.cod_fiscale
      from pratiche_tributo prtr,
           oggetti_pratica ogpr,
           oggetti_imposta ogim
     where prtr.pratica         = ogpr.pratica
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and ruolo             = p_ruolo
       and decode(p_cf, null, ogim.cod_fiscale, p_cf) = ogim.cod_fiscale
    ;
/*CURSOR sel_ruol_acc (p_ruolo number) IS
  select ruol_acc.ruolo
          from ruoli ruol_acc, ruoli ruol
          where nvl(ruol_acc.tipo_emissione,'T')   = 'A'
             and ruol_acc.invio_consorzio is not null
             and ruol_acc.anno_ruolo    = ruol.anno_ruolo
             and ruol_acc.tipo_tributo||''    = ruol.tipo_tributo
             and ruol.ruolo = p_ruolo
             and nvl(ruol.tipo_emissione,'T')   = 'S'
             and not exists (select 1
                               from ruoli ruol2
                              where ruol2.ruolo != ruol.ruolo
                                and nvl(ruol2.tipo_emissione,'T')   = 'S'
                                and ruol2.invio_consorzio is not null
                                and ruol2.anno_ruolo    = ruol.anno_ruolo
                                and ruol2.tipo_ruolo = 1)
          ;
CURSOR sel_ruol_principale (p_ruolo number) IS
  select ruol_pr.ruolo
          from ruoli ruol_pr, ruoli ruol
          where ruol_pr.invio_consorzio is not null
             and ruol_pr.anno_ruolo    = ruol.anno_ruolo
             and ruol_pr.tipo_tributo||''    = ruol.tipo_tributo
             and ruol.ruolo = p_ruolo
             and ruol.tipo_ruolo = 2
             and ruol_pr.tipo_ruolo = 1
             and nvl(ruol.tipo_emissione,'T') = nvl(ruol_pr.tipo_emissione,'T')
             and nvl(ruol.tipo_emissione,'T') in ('S','T')
             and not exists (select 1
                               from ruoli ruol2
                              where ruol2.ruolo != ruol_pr.ruolo
                                and nvl(ruol2.tipo_emissione,'T') = nvl(ruol_pr.tipo_emissione,'T')
                                and ruol2.invio_consorzio is not null
                                and ruol2.anno_ruolo    = ruol_pr.anno_ruolo
                                and ruol2.tipo_ruolo = 1)
          ;*/
BEGIN
  if a_ruolo < 0 or a_cf is not null then
     w_elimina_ruoli := 'N';
  else
     w_elimina_ruoli := 'S';
  end if;
  w_ruolo := abs(a_ruolo);
  BEGIN
    select tipo_tributo
         , tipo_ruolo
         , anno_ruolo
         , invio_consorzio
         , tipo_emissione
         , flag_depag
         , specie_ruolo
      into w_tipo_tributo
         , w_tipo_ruolo
         , w_anno_ruolo
         , w_invio_consorzio
         , w_tipo_emissione
         , w_pagonline
         , w_specie_ruolo
      from ruoli
     where ruolo = w_ruolo
    ;
  EXCEPTION
    WHEN no_data_found THEN
         w_errore := 'Ruolo non presente in tabella ('||SQLERRM||')';
         RAISE errore;
    WHEN others THEN
         w_errore := 'Errore in ricerca Ruoli ('||SQLERRM||')';
         RAISE errore;
  END;
  if w_ruolo <> nvl(F_GET_ULTIMO_RUOLO(a_cf
                                      ,w_anno_ruolo
                                      ,w_tipo_tributo
                                      ,w_tipo_emissione
                                      ,'S'
                                      ,null
                                      ,w_specie_ruolo
                                      ),w_ruolo) then
     w_errore := 'Eliminazione non consentita: esistono ruoli successivi.';
     RAISE errore;
  end if;
  IF w_invio_consorzio is null THEN
     w_cf_old := rpad('z',17,'z');
     FOR rec_ogim IN sel_ogim (w_ruolo, a_cf) LOOP
       BEGIN
          update oggetti_imposta
             set ruolo              = '',
                 importo_ruolo      = '',
                 addizionale_eca    = '',
                 maggiorazione_eca  = '',
                 addizionale_pro    = '',
                 iva                = '',
                 note               = 'Ruolo eliminato n. '||w_ruolo
           where oggetto_imposta = rec_ogim.oggetto_imposta
          ;
       EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in Aggiornamento Oggetti_Imposta (ruolo) ('||SQLERRM||')';
                 RAISE errore;
       END;
       IF not(rec_ogim.tipo_pratica = 'A' AND rec_ogim.anno_prtr = w_anno_ruolo) THEN
          BEGIN
            delete ruoli_contribuente
             where oggetto_imposta = rec_ogim.oggetto_imposta
            ;
          EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in Eliminazione Ruoli Contribuente ('||SQLERRM||')';
                 RAISE errore;
          END;
          BEGIN
            delete oggetti_imposta
             where oggetto_imposta = rec_ogim.oggetto_imposta
            ;
          EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in Eliminazione Oggetti_Imposta ('||SQLERRM||')';
                 RAISE errore;
          END;
       END IF;
       if w_cf_old != rec_ogim.cod_fiscale then
          w_cf_old := rec_ogim.cod_fiscale;
          eliminazione_sgravi_ruolo(rec_ogim.cod_fiscale, a_ruolo, w_anno_ruolo, 'TARSU', w_tipo_emissione, w_tipo_ruolo);
       end if;
     END LOOP;
      -- Aggiunte le due delete che abbiamo attivato per gli sgravi automatici e le compensazioni ruolo (30/10/2013) AB
     BEGIN
       delete compensazioni_ruolo
        where ruolo = w_ruolo
          and motivo_compensazione = 99
          and flag_automatico = 'S'
          and decode(a_cf, null, cod_fiscale, a_cf) = cod_fiscale
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in Eliminazione Compensazioni Ruolo (99) ('||SQLERRM||')';
            RAISE errore;
     END;
/*     FOR rec_ruol_acc IN sel_ruol_acc(w_ruolo) LOOP
         BEGIN
            delete sgravi
             where ruolo = rec_ruol_acc.ruolo
               and motivo_sgravio = 99
               and flag_automatico = 'S'
               and decode(a_cf, null, cod_fiscale, a_cf) = cod_fiscale
            ;
         EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in Eliminazione Sgravi Automatici (99) ('||SQLERRM||')';
                 RAISE errore;
         END;
     END LOOP;
     FOR rec_ruol_principale IN sel_ruol_principale(w_ruolo) LOOP
         BEGIN
              delete sgravi
               where ruolo = rec_ruol_principale.ruolo
                 and motivo_sgravio = 99
                 and flag_automatico = 'S'
                 and decode(a_cf, null, cod_fiscale, a_cf) = cod_fiscale
              ;
         EXCEPTION
              WHEN others THEN
                   w_errore := 'Errore in Eliminazione Sgravi Automatici (99) ('||SQLERRM||')';
                   RAISE errore;
         END;
     END LOOP;*/
     -- (VD - 28/05/2020): si eliminano le sanzioni relative alle addizionali
     BEGIN
       delete sanzioni_pratica
        where ruolo = w_ruolo
          and cod_sanzione in (891,892,893,894)
          and exists (select 1
                        from pratiche_tributo prtr
                       where decode(a_cf, null, prtr.cod_fiscale, a_cf) = prtr.cod_fiscale
                         and prtr.pratica            = sanzioni_pratica.pratica)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in eliminazione Sanzioni Pratica ('||SQLERRM||')';
            RAISE errore;
     END;
     BEGIN
       update sanzioni_pratica
             set ruolo         = '',
                 importo_ruolo = '',
                 note          = 'Ruolo eliminato n. '||w_ruolo
           where ruolo = w_ruolo
             and exists (select 1
                           from pratiche_tributo prtr
                          where decode(a_cf, null, prtr.cod_fiscale, a_cf) = prtr.cod_fiscale
                            and prtr.pratica            = sanzioni_pratica.pratica)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in aggiornamento Sanzioni Pratica ('||SQLERRM||')';
            RAISE errore;
     END;
     BEGIN
       delete ruoli_contribuente
        where ruolo = w_ruolo
          and decode(a_cf, null, cod_fiscale, a_cf) = cod_fiscale
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in eliminazione Ruoli Contribuente ('||SQLERRM||')';
            RAISE errore;
     END;
     BEGIN
       delete ruoli_eccedenze
        where ruolo = w_ruolo
          and decode(a_cf, null, cod_fiscale, a_cf) = cod_fiscale
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in eliminazione Ruoli Eccedenze ('||SQLERRM||')';
            RAISE errore;
     END;
     --
     -- (VD - 17/11/2016) - Sperimentazione Poasco
     --                     Aggiunto annullamento dati ruolo
     --                     su tabella CONFERIMENTI
     --
     BEGIN
       update conferimenti
          set ruolo = null
            , importo_scalato = null
        where ruolo = w_ruolo
          and cod_fiscale = decode(a_cf, null, cod_fiscale, a_cf)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in aggiornamento CONFERIMENTI ('||SQLERRM||')';
            RAISE errore;
     END;
     --
     -- (VD - 12/03/2018) - Pontedera - Gestione conferimenti
     --                     Aggiunta eliminazione righe da
     --                     tabella CONFERIMENTI_CER_RUOLO
     --
     BEGIN
       delete conferimenti_cer_ruolo
        where ruolo = w_ruolo
          and cod_fiscale = decode(a_cf, null, cod_fiscale, a_cf)
       ;
     EXCEPTION
       WHEN others THEN
            w_errore := 'Errore in eliminazione CONFERIMENTI_CER_RUOLO ('||SQLERRM||')';
            RAISE errore;
     END;
     --
     -- (VD - 07/07/2020): Castelnuovo Garfagnana - Eliminazione dovuti in DEPAG
     -- (VD - 11/12/2020): Eliminati controlli per Castelnuovo Garfagnana
     --                    Ora l'integrazioe e' possibile per tutti i clienti
     --
     /*w_pagonline := F_INPA_VALORE('PAGONLINE');
     begin
       select lpad(pro_cliente,3,'0')||lpad(com_cliente,3,'0')
         into w_cod_istat
         from dati_generali;
     exception
       when others then
         w_errore := 'Errore in selezione DATI_GENERALI ('||SQLERRM||')';
         RAISE errore;
     end; */
     -- (VD - 02/12/2020): eliminato controllo su ruoli suppletivi
     if w_pagonline = 'S' and
        --w_cod_istat = w_cod_castel and
        --w_tipo_emissione = 'T' and
        --w_tipo_ruolo = 1 and
        w_tipo_tributo = 'TARSU' then
        w_result := pagonline_tr4.eliminazione_dovuti_ruolo ( w_tipo_tributo
                                                            , a_cf
                                                            , w_anno_ruolo
                                                            , w_ruolo
                                                            );
        if w_result = -1 then
           w_errore:= 'Si e'' verificato un errore in fase di preparazione dati per PAGONLINE - verificare log';
           raise errore;
        end if;
     end if;
     --15/12/2014 SC: se sto eliminando per un unico cf,
     --non si cancella il ruolo.
     if a_cf is not null then
        w_elimina_ruoli := 'N';
        -- select decode(count(*), 0, 'S', 'N')
        --   into w_elimina_ruoli
        --   from ruoli_contribuente
        --  where ruolo = w_ruolo
        -- ;
     end if;
     if w_elimina_ruoli = 'S' then
        BEGIN
          delete ruoli
           where ruolo = w_ruolo
          ;
        EXCEPTION
         WHEN others THEN
              w_errore := 'Errore in eliminazione Ruoli ('||SQLERRM||')';
              RAISE errore;
        END;
     end if;
  ELSE
     w_errore := 'Eliminazione non consentita: Ruolo gia'' inviato al Consorzio';
     RAISE errore;
  END IF;
EXCEPTION
    WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR
      (-20999,w_errore);
    WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in Eliminazione Ruolo '||
         '('||SQLERRM||')');
END;
/* End Procedure: ELIMINAZIONE_RUOLO */
/
