--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sostituzione_oggetto stripComments:false runOnChange:true 
 
create or replace procedure SOSTITUZIONE_OGGETTO
(a_cod_fiscale     varchar2,
 a_tipo_tributo    varchar2,
 a_attuale_oggetto number,
 a_nuovo_oggetto   number)
IS
w_controllo        number;
w_catastali        number;
w_partizioni       number;
w_partizioni_ok    varchar2(1);
w_riferimenti_oggetto     number;
w_riferimenti_oggetto_ok  varchar2(1);
w_utilizzi_oggetto        number;
w_utilizzi_oggetto_ok     varchar2(1);
w_catastaliICI     number;
w_tipo_oggetto     number(2);
sql_errm           varchar2(100);
CURSOR sel_1 IS
   select '1'
     from oggetti_pratica ogpr
       , oggetti_contribuente ogco
    where (ogpr.pratica,ogpr.num_ordine) in (select ogpr1.pratica,ogpr1.num_ordine
                                               from pratiche_tributo prtr1
                                                  , oggetti_pratica ogpr1
                                                  , oggetti_contribuente ogco1
                                              where prtr1.tipo_tributo    like a_tipo_tributo
                                                and prtr1.pratica         = ogpr1.pratica
                                                and ogpr1.oggetto         = a_attuale_oggetto
                                                and ogpr1.oggetto_pratica = ogco1.oggetto_pratica
                                                and ogco1.cod_fiscale     = ogco.cod_fiscale)
      and ogpr.oggetto         = a_nuovo_oggetto
      and ogpr.oggetto_pratica = ogco.oggetto_pratica
      and ogco.cod_fiscale     = a_cod_fiscale
       ;
--Liquidazioni notificati sull'oggetto attuale
CURSOR sel_2 IS
   select ogpr.oggetto
    from pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr.tipo_pratica                = 'L'
     and prtr.tipo_tributo                like a_tipo_tributo
     and prtr.pratica                     = ogpr.pratica
      and nvl(prtr.stato_accertamento,'D') = 'D'
     and ogpr.oggetto                     = a_attuale_oggetto
     and ogpr.oggetto_pratica             = ogco.oggetto_pratica
     and ogco.cod_fiscale                 = a_cod_fiscale
union
   select ogpr.oggetto
    from pratiche_tributo prtr1
       , oggetti_pratica ogpr1
       , pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr1.tipo_pratica                = 'L'
     and prtr.tipo_tributo                 like a_tipo_tributo
     and prtr1.pratica                     = ogpr1.pratica
      and nvl(prtr1.stato_accertamento,'D') = 'D'
     and ogpr1.oggetto_pratica_rif         = ogpr.oggetto_pratica
     and prtr.pratica                      = ogpr.pratica
     and ogpr.oggetto                      = a_attuale_oggetto
     and ogpr.oggetto_pratica              = ogco.oggetto_pratica
     and ogco.cod_fiscale                  = a_cod_fiscale
       ;
--Accertamenti notificati sull'oggetto attuale
CURSOR sel_3 IS
   select ogpr.oggetto
    from pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr.tipo_pratica                = 'A'
     and prtr.tipo_tributo                like a_tipo_tributo
     and prtr.pratica                     = ogpr.pratica
      and nvl(prtr.stato_accertamento,'D') = 'D'
     and ogpr.oggetto                     = a_attuale_oggetto
     and ogpr.oggetto_pratica             = ogco.oggetto_pratica
     and ogco.cod_fiscale                 = a_cod_fiscale
 union
   select ogpr.oggetto
    from pratiche_tributo prtr1
       , oggetti_pratica ogpr1
       , pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr1.tipo_pratica                = 'A'
     and prtr1.pratica                     = ogpr1.pratica
      and nvl(prtr1.stato_accertamento,'D') = 'D'
     and ogpr1.oggetto_pratica_rif         = ogpr.oggetto_pratica
     and prtr.tipo_tributo                 like a_tipo_tributo
     and prtr.pratica                      = ogpr.pratica
     and ogpr.oggetto                      = a_attuale_oggetto
     and ogpr.oggetto_pratica              = ogco.oggetto_pratica
     and ogco.cod_fiscale                  = a_cod_fiscale
       ;
CURSOR sel_paog (p_oggetto number)  IS
   select consistenza
         , tipo_area
      from partizioni_oggetto
      where oggetto = p_oggetto
 order by consistenza
          ;
CURSOR sel_riog (p_oggetto number)  IS
   select inizio_validita
         , fine_validita
           , rendita
           , anno_rendita
           , categoria_catasto
           , classe_catasto
      from riferimenti_oggetto
      where oggetto = p_oggetto
 order by inizio_validita
          ;
CURSOR sel_utog (p_oggetto number, p_tipo_tributo varchar2)  IS
   select anno
        , tipo_utilizzo
        , mesi_affitto
      , data_scadenza
      , intestatario
      , tipo_uso
        , tipo_tributo
    from utilizzi_oggetto
   where oggetto = p_oggetto
     and tipo_tributo = p_tipo_tributo
   order by anno
        , tipo_utilizzo
        , sequenza
          ;
BEGIN
  OPEN  sel_1;
  FETCH sel_1 INTO w_controllo;
  IF sel_1%FOUND THEN
     CLOSE sel_1;
     RAISE_APPLICATION_ERROR
       (-20999,'Sostituzione non consentita: '||
          'stessa pratica e numero d''ordine');
  ELSE
     CLOSE sel_1;
  END IF;
  OPEN  sel_2;
  FETCH sel_2 INTO w_controllo;
  IF sel_2%FOUND THEN
       select count(1)
         into w_catastaliICI
        from oggetti ogg1
             , oggetti ogg2
        where ogg1.oggetto = a_attuale_oggetto
          and ogg2.oggetto = a_nuovo_oggetto
           and nvl(ogg2.sezione,' ') = nvl(nvl(ogg1.sezione,ogg2.sezione),' ')
           and nvl(ogg2.foglio,' ')  = nvl(nvl(ogg1.foglio,ogg2.foglio),' ')
           and nvl(ogg2.numero,' ')  = nvl(nvl(ogg1.numero,ogg2.numero),' ')
           and nvl(ogg2.subalterno,' ')         = nvl(nvl(ogg1.subalterno,ogg2.subalterno),' ')
           and nvl(ogg2.categoria_catasto,' ')  = nvl(nvl(ogg1.categoria_catasto,ogg2.categoria_catasto),' ')
           and nvl(ogg2.classe_catasto,' ')     = nvl(nvl(ogg1.classe_catasto,ogg2.classe_catasto),' ')
           and nvl(ogg2.partita,' ')            = nvl(nvl(ogg1.partita,ogg2.partita),' ')
           and nvl(ogg2.progr_partita,0)        = nvl(nvl(ogg1.progr_partita,ogg2.progr_partita),0)
           ;
    IF w_catastaliICI = 0 then
        CLOSE sel_2;
        RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
                  'immobile in fase di liquidazione. '||
               'Dati Catastali Incoerenti');
    ELSE
-- test dei RIFERIMENTI_OGGETTO
      w_riferimenti_oggetto_ok := 'S';
      for rec_riog in sel_riog(a_attuale_oggetto) loop
        select count(1)
          into w_riferimenti_oggetto
          from riferimenti_oggetto
          where oggetto            = a_nuovo_oggetto
            and inizio_validita    = rec_riog.inizio_validita
           and fine_validita      = rec_riog.fine_validita
             and rendita            = rec_riog.rendita
             and nvl(anno_rendita,0)       = nvl(rec_riog.anno_rendita,0)
             and nvl(categoria_catasto,' ')  = nvl(rec_riog.categoria_catasto,' ')
             and nvl(classe_catasto,' ')     = nvl(rec_riog.classe_catasto,' ')
              ;
         if w_riferimenti_oggetto = 0 then
          w_riferimenti_oggetto_ok := 'N';
       end if;
      end loop;
      if w_riferimenti_oggetto_ok = 'N' then
          CLOSE sel_2;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
                  'immobile in fase di accertamento. '||
               'Riferimenti Oggetto Incoerenti');
      end if;
-- test dei UTILIZZI_OGGETTO
      w_utilizzi_oggetto_ok := 'S';
      for rec_utog in sel_utog(a_attuale_oggetto, a_tipo_tributo) loop
        select count(1)
          into w_utilizzi_oggetto
          from utilizzi_oggetto
          where oggetto          = a_nuovo_oggetto
            and anno             = rec_utog.anno
             and tipo_utilizzo    = rec_utog.tipo_utilizzo
              and tipo_tributo     = rec_utog.tipo_tributo
           and nvl(mesi_affitto,0)     = nvl(rec_utog.mesi_affitto,0)
           and nvl(data_scadenza,to_date('31/12/9999','dd/mm/yyyy'))    = nvl(rec_utog.data_scadenza,to_date('31/12/9999','dd/mm/yyyy'))
           and nvl(intestatario,' ')     = nvl(rec_utog.intestatario,' ')
           and nvl(tipo_uso,0)         = nvl(rec_utog.tipo_uso,0)
              ;
         if w_utilizzi_oggetto = 0 then
          w_utilizzi_oggetto_ok := 'N';
       end if;
      end loop;
      if w_utilizzi_oggetto_ok = 'N' then
          CLOSE sel_2;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
                  'immobile in fase di accertamento. '||
               'Utilizzi Oggetto Incoerenti');
      end if;
      CLOSE sel_2;
    END IF;
  ELSE
     CLOSE sel_2;
  END IF;
  --sel_3
  OPEN  sel_3;
  FETCH sel_3 INTO w_controllo;
  IF sel_3%FOUND THEN
    if a_tipo_tributo = 'ICI' or a_tipo_tributo = '%'  then
       select count(1)
         into w_catastaliICI
        from oggetti ogg1
            , oggetti ogg2
      where ogg1.oggetto = a_attuale_oggetto
        and ogg2.oggetto = a_nuovo_oggetto
         and nvl(ogg2.sezione,' ') = nvl(nvl(ogg1.sezione,ogg2.sezione),' ')
        and nvl(ogg2.foglio,' ')  = nvl(nvl(ogg1.foglio,ogg2.foglio),' ')
         and nvl(ogg2.numero,' ')  = nvl(nvl(ogg1.numero,ogg2.numero),' ')
         and nvl(ogg2.subalterno,' ')         = nvl(nvl(ogg1.subalterno,ogg2.subalterno),' ')
         and nvl(ogg2.categoria_catasto,' ')  = nvl(nvl(ogg1.categoria_catasto,ogg2.categoria_catasto),' ')
         and nvl(ogg2.classe_catasto,' ')     = nvl(nvl(ogg1.classe_catasto,ogg2.classe_catasto),' ')
         and nvl(ogg2.partita,' ')            = nvl(nvl(ogg1.partita,ogg2.partita),' ')
         and nvl(ogg2.progr_partita,0)        = nvl(nvl(ogg1.progr_partita,ogg2.progr_partita),0)
         ;
      if  w_catastaliICI = 0 then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
            (-20999,'Sostituzione non consentita: '||
                    'immobile in fase di accertamento. '||
                 'Dati Catastali Incoerenti');
      end if;
   end if;
   if  a_tipo_tributo <> 'ICI'  or a_tipo_tributo = '%'  then
--     test dell'Indirizzo
       select count(1)
         into w_catastali
        from oggetti ogg1
            , oggetti ogg2
      where ogg1.oggetto = a_attuale_oggetto
        and ogg2.oggetto = a_nuovo_oggetto
         and ( nvl(ogg2.cod_via,0) = nvl(ogg1.cod_via,0)
             or nvl(ogg2.indirizzo_localita,' ') = nvl(ogg1.indirizzo_localita,' ') )
         and nvl(ogg2.num_civ,0) = nvl(ogg1.num_civ,0)
         ;
      if w_catastali = 0 then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
            (-20999,'Sostituzione non consentita: '||
                    'immobile in fase di accertamento. '||
                 'Indirizzo Incoerente');
      end if;
--    test delle PARTIZIONI
      w_partizioni_ok := 'S';
      for rec_paog in sel_paog(a_attuale_oggetto) loop
        select count(1)
          into w_partizioni
          from partizioni_oggetto
          where oggetto     = a_nuovo_oggetto
            and consistenza = rec_paog.consistenza
            and tipo_area   = rec_paog.tipo_area
              ;
         if w_partizioni = 0 then
          w_partizioni_ok := 'N';
       end if;
      end loop;
      if w_partizioni_ok = 'N' then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
                  'immobile in fase di accertamento. '||
               'Partizioni Incoerenti');
      end if;
   end if;
  ELSE
-- anche se non ci sono accertamenti testo la correttezza dei RIOG utilizzi e
-- dati catastali per l'ICI e delle partizioni e dell'indirizzo per i non ICI
-- Controlli non bloccanti effettuati da f_check_no_bloc_sost_ogg
--e gestiti da PB w_sostituzione_oggetti_response, evento clicked di cb_ok
   /* if a_tipo_tributo = 'ICI' or a_tipo_tributo = '%'  then
-- test dei RIFERIMENTI_OGGETTO
      w_riferimenti_oggetto_ok := 'S';
      for rec_riog in sel_riog(a_attuale_oggetto) loop
        select count(1)
          into w_riferimenti_oggetto
          from riferimenti_oggetto
        where oggetto            = a_nuovo_oggetto
          and inizio_validita    = rec_riog.inizio_validita
           and fine_validita      = rec_riog.fine_validita
         and rendita            = rec_riog.rendita
         and nvl(anno_rendita,0)       = nvl(rec_riog.anno_rendita,0)
         and nvl(categoria_catasto,' ')  = nvl(rec_riog.categoria_catasto,' ')
         and nvl(classe_catasto,' ')     = nvl(rec_riog.classe_catasto,' ')
            ;
         if w_riferimenti_oggetto = 0 then
          w_riferimenti_oggetto_ok := 'N';
       end if;
      end loop;
      if w_riferimenti_oggetto_ok = 'N' then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
               'Riferimenti Oggetto Incoerenti');
      end if;
-- test dei UTILIZZI_OGGETTO
      w_utilizzi_oggetto_ok := 'S';
      for rec_utog in sel_utog(a_attuale_oggetto) loop
        select count(1)
          into w_utilizzi_oggetto
          from utilizzi_oggetto
        where oggetto          = a_nuovo_oggetto
          and anno             = rec_utog.anno
           and tipo_utilizzo    = rec_utog.tipo_utilizzo
         and nvl(mesi_affitto,0)     = nvl(rec_utog.mesi_affitto,0)
         and nvl(data_scadenza,to_date('31/12/9999','dd/mm/yyyy'))    = nvl(rec_utog.data_scadenza,to_date('31/12/9999','dd/mm/yyyy'))
         and nvl(intestatario,' ')     = nvl(rec_utog.intestatario,' ')
         and nvl(tipo_uso,0)         = nvl(rec_utog.tipo_uso,0)
            ;
         if w_utilizzi_oggetto = 0 then
          w_utilizzi_oggetto_ok := 'N';
       end if;
      end loop;
      if w_utilizzi_oggetto_ok = 'N' then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
               'Utilizzi Oggetto Incoerenti');
      end if;
-- test dei dati Catastali (ICI)
     select count(1)
       into w_catastaliICI
        from oggetti ogg1
         , oggetti ogg2
      where ogg1.oggetto = a_attuale_oggetto
        and ogg2.oggetto = a_nuovo_oggetto
       and nvl(ogg2.sezione,' ') = nvl(nvl(ogg1.sezione,ogg2.sezione),' ')
       and nvl(ogg2.foglio,' ')  = nvl(nvl(ogg1.foglio,ogg2.foglio),' ')
       and nvl(ogg2.numero,' ')  = nvl(nvl(ogg1.numero,ogg2.numero),' ')
       and nvl(ogg2.subalterno,' ')         = nvl(nvl(ogg1.subalterno,ogg2.subalterno),' ')
       and nvl(ogg2.categoria_catasto,' ')  = nvl(nvl(ogg1.categoria_catasto,ogg2.categoria_catasto),' ')
       and nvl(ogg2.classe_catasto,' ')     = nvl(nvl(ogg1.classe_catasto,ogg2.classe_catasto),' ')
       and nvl(ogg2.partita,' ')            = nvl(nvl(ogg1.partita,ogg2.partita),' ')
       and nvl(ogg2.progr_partita,0)        = nvl(nvl(ogg1.progr_partita,ogg2.progr_partita),0)
           ;
      if w_catastaliICI = 0 then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
            (-20999,'Sostituzione non consentita: '||
                 'Dati Catastali Incoerenti');
      end if;
   end if;-- if a_tipo_tributo = 'ICI' or a_tipo_tributo = '%'  then
   if  a_tipo_tributo <> 'ICI'  or a_tipo_tributo = '%'  then
-- test dell'indirizzo  (non ICI )
       select count(1)
       into w_catastali
        from oggetti ogg1
         , oggetti ogg2
      where ogg1.oggetto = a_attuale_oggetto
        and ogg2.oggetto = a_nuovo_oggetto
       and (  nvl(ogg2.cod_via,0) = nvl(ogg1.cod_via,0)
           or nvl(ogg2.indirizzo_localita,' ') = nvl(ogg1.indirizzo_localita,' ') )
       and nvl(ogg2.num_civ,0) = nvl(ogg1.num_civ,0)
           ;
      if w_catastali  = 0 then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
            (-20999,'Sostituzione non consentita: '||
                   'Indirizzo Incoerente');
      end if;
--    test delle PARTIZIONI
      w_partizioni_ok := 'S';
      for rec_paog in sel_paog(a_attuale_oggetto) loop
        select count(1)
          into w_partizioni
          from partizioni_oggetto
        where oggetto     = a_nuovo_oggetto
          and consistenza = rec_paog.consistenza
          and tipo_area   = rec_paog.tipo_area
            ;
         if w_partizioni = 0 then
          w_partizioni_ok := 'N';
       end if;
      end loop;
      if w_partizioni_ok = 'N' then
          CLOSE sel_3;
          RAISE_APPLICATION_ERROR
          (-20999,'Sostituzione non consentita: '||
               'Partizioni Incoerenti');
      end if;
   end if;*/
    CLOSE sel_3;
  END IF; --IF sel_3%FOUND THEN
  BEGIN
    if (a_tipo_tributo = 'TARSU') then
      select ogge.tipo_oggetto
        into w_tipo_oggetto
      from oggetti ogge
        where ogge.oggetto = a_nuovo_oggetto;
    else
      w_tipo_oggetto := null;
    end if;
    update oggetti_pratica ogpr
       set oggetto      = a_nuovo_oggetto,
           tipo_oggetto = nvl(w_tipo_oggetto, ogpr.tipo_oggetto)
     where ogpr.oggetto_pratica in (select ogco.oggetto_pratica
                                      from pratiche_tributo prtr
                                         , oggetti_pratica ogpr
                                         , oggetti_contribuente ogco
                                     where prtr.tipo_tributo   like a_tipo_tributo
                                       and prtr.pratica      = ogpr.pratica
                                       and ogpr.oggetto_pratica = ogco.oggetto_pratica
                                       and ogco.cod_fiscale    = a_cod_fiscale)
          and ogpr.oggetto = a_attuale_oggetto
            ;
  EXCEPTION
    WHEN others THEN
        sql_errm := substr(SQLERRM,1,100);
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Oggetti Pratica '||
         '('||sql_errm||')');
  END;
END;
/* End Procedure: SOSTITUZIONE_OGGETTO */
/

