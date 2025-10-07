--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_defi_cont stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_DEFI_CONT
(a_cod_fiscale in     varchar2
,a_anno        in     number
,a_utente      in     varchar2
,a_messaggio   in out varchar2
) is
a_tipo_tributo    varchar2(5);
cursor sel_ogco is
  select ogco.cod_fiscale                                                       cod_fiscale
       , ogpr.oggetto_pratica                                                   oggetto_pratica_ogpr
       , ogpr.tipo_oggetto                                                      tipo_oggetto
       , ogco.flag_ab_principale                                                flag_ab_principale
       , ogco.detrazione                                                        detrazione_ogco
       , f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno,'CA')         categoria_catasto_ogpr
       , ogpr.oggetto_pratica_rif_ap                                            oggetto_pratica_rif_ap
       , ogpr.oggetto                                                           oggetto
       , sogg.matricola                                                         matricola
       , sogg.fascia                                                            fascia
       , sogg.cod_fam                                                           cod_fam
       , sogg.tipo_residente                                                    tipo_residente
       , sogg.data_ult_eve                                                      data_ult_eve
    from pratiche_tributo     prtr
       , oggetti_pratica      ogpr
       , oggetti_contribuente ogco
       , contribuenti         cont
       , soggetti             sogg
   where cont.ni                = sogg.ni
     and cont.cod_fiscale       = ogco.cod_fiscale
     and ogco.anno||ogco.tipo_rapporto||'S' =
         (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
            from pratiche_tributo     c
               , oggetti_contribuente b
               , oggetti_pratica      a
          where (  c.data_notifica is not null and c.tipo_pratica||'' = 'A'
               and nvl(c.stato_accertamento,'D') = 'D'
               and nvl(c.flag_denuncia,' ')      = 'S'
               and c.anno                        < a_anno
                or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                 )
            and c.anno                  <= a_anno
            and c.tipo_tributo||''       = prtr.tipo_tributo
            and c.pratica                = a.pratica
            and a.oggetto_pratica        = b.oggetto_pratica
            and a.oggetto                = ogpr.oggetto
            and b.tipo_rapporto         in ('C','D','E')
            and b.cod_fiscale            = ogco.cod_fiscale
        )
     and prtr.tipo_tributo||''    = a_tipo_tributo
     and nvl(prtr.stato_accertamento,'D') = 'D'
     and prtr.pratica             = ogpr.pratica
     and ogpr.oggetto_pratica     = ogco.oggetto_pratica
     and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
     and decode(ogco.anno
               ,a_anno,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
              )                     <=
         decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
     and ogco.flag_possesso       = 'S'
     and ogco.cod_fiscale      like a_cod_fiscale
     and sogg.tipo_residente+0    = 0
union
  select ogco.cod_fiscale                                                       cod_fiscale
       , ogpr.oggetto_pratica                                                   oggetto_pratica_ogpr
       , ogpr.tipo_oggetto                                                      tipo_oggetto
       , ogco.flag_ab_principale                                                flag_ab_principale
       , ogco.detrazione                                                        detrazione_ogco
       , f_dato_riog(ogco.cod_fiscale,ogco.oggetto_pratica,a_anno,'CA')         categoria_catasto_ogpr
       , ogpr.oggetto_pratica_rif_ap                                            oggetto_pratica_rif_ap
       , ogpr.oggetto                                                           oggetto
       , sogg.matricola                                                         matricola
       , sogg.fascia                                                            fascia
       , sogg.cod_fam                                                           cod_fam
       , sogg.tipo_residente                                                    tipo_residente
       , sogg.data_ult_eve                                                      data_ult_eve
    from pratiche_tributo     prtr
       , oggetti_pratica      ogpr
       , oggetti_contribuente ogco
       , contribuenti         cont
       , soggetti             sogg
   where cont.ni                = sogg.ni
     and cont.cod_fiscale       = ogco.cod_fiscale
     and prtr.tipo_pratica||''  = 'D'
     and ogco.flag_possesso    is null
     and prtr.tipo_tributo||''       = a_tipo_tributo
     and nvl(prtr.stato_accertamento,'D') = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.oggetto_pratica        = ogco.oggetto_pratica
     and ogco.anno                   = a_anno
     and decode(ogco.anno
               ,a_anno,decode(ogco.flag_esclusione
                                 ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                     ,nvl(ogco.mesi_esclusione,0)
                                 )
                          ,decode(ogco.flag_esclusione,'S',12,0)
              )                     <=
         decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
     and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
     and ogco.cod_fiscale         like a_cod_fiscale
     and sogg.tipo_residente+0    = 0
 order by 1
;
cursor sel_figl (p_cod_fam         number
                ,p_fascia          number
                ,p_tipo_residente  number
                ,p_matricola       number
                ) is
   select sogg.matricola
        , ana.matricola_pd
        , ana.matricola_md
     from soggetti  sogg
        , anaana    ana
    where sogg.cod_fam         = p_cod_fam
      and sogg.tipo_residente  = p_tipo_residente
      and sogg.matricola       = ana.matricola
      and sogg.fascia             in (1,3)
      and sogg.data_ult_eve  < to_date('0101'||to_char(a_anno),'ddmmyyyy')
      and Floor(Months_Between(to_date('0101'||to_char(a_anno),'ddmmyyyy'),sogg.data_nas)/12)
                                       < nvl(to_number(F_INPA_VALORE('IMU_ETA_FG')),26)
      and Floor(Months_Between(to_date('0101'||to_char(a_anno),'ddmmyyyy'),sogg.data_nas)/12) >= 0
      and sogg.matricola      <> p_matricola
      union
   select sogg.matricola
        , ana.matricola_pd
        , ana.matricola_md
     from soggetti  sogg
        , anaana    ana
    where sogg.cod_fam         = p_cod_fam
      and sogg.tipo_residente  = p_tipo_residente
      and sogg.matricola       = ana.matricola
      and sogg.fascia             in (2,4)
      and sogg.data_ult_eve >= to_date('0101'||to_char(a_anno),'ddmmyyyy')
      and Floor(Months_Between(to_date('0101'||to_char(a_anno),'ddmmyyyy'),sogg.data_nas)/12)
                                       < nvl(to_number(F_INPA_VALORE('IMU_ETA_FG')),26)
      and Floor(Months_Between(to_date('0101'||to_char(a_anno),'ddmmyyyy'),sogg.data_nas)/12) >= 0
      and sogg.matricola      <> p_matricola
       ;
dDetrazioneFiglio             number;
dDetrazione                   number;
dDetrazioneAcconto            number;
sCodFiscale                   varchar2(16);
nNumeroFigli                  number;
nContaDefi                    number;
w_esiste_det_ogco             varchar2(1);
w_rif_ap_ab_principale        varchar2(1);
w_flag_pertinenze             varchar2(1);
w_conta_rif_ap_ab_principale  number;
w_matricola_pd                number;
w_matricola_md                number;
w_altro_genitore_proprietario number;
nTrattati                     number := 0;
sMessagggio                   varchar2(2000);
BEGIN
   sMessagggio := null;
   nTrattati   := 0;
   BEGIN
   -- le detrazioni figli TASI o IMU sono mutualmente esclusive quindi
   -- selezioniamo il tipo tributo da detrazioni per l anno dove la
   -- detrazione figli è attiva
     select tipo_tributo
       into a_tipo_tributo
        from detrazioni dete
       where dete.anno = a_anno
         and nvl(dete.detrazione_figlio,0) > 0
     ;
   EXCEPTION
     WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        raise_application_error(-20999,'Errore in Ricerca Tipo Tributo da Detrazioni');
   END;
   BEGIN
     select flag_pertinenze
       into w_flag_pertinenze
       from aliquote
      where flag_ab_principale = 'S'
        and anno = a_anno
        and tipo_tributo = a_tipo_tributo
     ;
   EXCEPTION
     WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        raise_application_error(-20999,'Errore in Ricerca Flag Pertinenze');
   END;
   begin
      select dete.detrazione_figlio
        into dDetrazioneFiglio
        from detrazioni dete
       where dete.anno = a_anno
         and tipo_tributo = a_tipo_tributo
           ;
   EXCEPTION
      WHEN OTHERS THEN
         dDetrazioneFiglio := null;
   end;
   if nvl(dDetrazioneFiglio,0) <= 0 then
      raise_application_error(-20999,'Attenzione: Verificare la Detrazione Figlio '||
                                     'per l''anno '||to_char(a_anno));
   end if;
   FOR rec_ogco in sel_ogco
   LOOP
      if ( rec_ogco.fascia  in (1,3) and rec_ogco.data_ult_eve  < to_date('0101'||to_char(a_anno),'ddmmyyyy') )
        or
         ( rec_ogco.fascia  in (2,4) and rec_ogco.data_ult_eve >= to_date('0101'||to_char(a_anno),'ddmmyyyy') )
        then
         sCodFiscale         := rec_ogco.cod_fiscale;
         nNumeroFigli        := 0;
         dDetrazione         := 0;
         dDetrazioneAcconto  := 0;
         -- Verifica se non esistono detrazioni_figli per l'anno
         begin
            select count(1)
              into nContaDefi
              from detrazioni_figli  defi
             where defi.cod_fiscale = sCodFiscale
               and anno = a_anno
                 ;
         EXCEPTION
            WHEN OTHERS THEN
               nContaDefi := 0;
         end;
         if rec_ogco.tipo_oggetto = 3 then
            BEGIN
               select detraz.det
                 into w_esiste_det_ogco
                from (
                    select 'S' det
                        from detrazioni_ogco deog
                  where deog.cod_fiscale     = sCodFiscale
                    and deog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                    and deog.anno            = a_anno
                    and deog.tipo_tributo    = a_tipo_tributo
                    and not exists (select 'S'
                                      from aliquote_ogco alog
                                     where alog.cod_fiscale  = sCodFiscale
                                       and alog.tipo_tributo = a_tipo_tributo
                                       and alog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                                       and a_anno between to_number(to_char(alog.dal,'yyyy'))
                                                      and to_number(to_char(alog.al,'yyyy'))
                                    )
                  union
                      select 'S'
                        from detrazioni_ogco deog2
                           , oggetti_pratica ogpr2
                       where deog2.cod_fiscale     = sCodFiscale
                         and deog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
                         and deog2.anno            = a_anno
                         and deog2.tipo_tributo    = a_tipo_tributo
                         and ogpr2.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                         and not exists (select 'S'
                                           from aliquote_ogco alog
                                          where alog.cod_fiscale  = sCodFiscale
                                            and alog.tipo_tributo = a_tipo_tributo
                                            and alog.oggetto_pratica = deog2.oggetto_pratica
                                            and a_anno between to_number(to_char(alog.dal,'yyyy'))
                                                           and to_number(to_char(alog.al,'yyyy'))
                                    )
                    ) detraz
                    ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_esiste_det_ogco := 'N';
            END;
         end if;
         -- Verifico se l'ogpr a cui la pertinenza è collegata è abitazione principale
         if rec_ogco.tipo_oggetto = 3
            and rec_ogco.categoria_catasto_ogpr like 'C%'
            and rec_ogco.oggetto_pratica_rif_ap is not null then
            begin
                select count(1)
                  into w_conta_rif_ap_ab_principale
                  from oggetti_pratica      ogpr
                     , oggetti_contribuente ogco
                 where ogpr.oggetto_pratica = ogco.oggetto_pratica
                   and ogpr.oggetto_pratica = rec_ogco.oggetto_pratica_rif_ap
                   and (  ogco.flag_ab_principale = 'S'
                       or ogco.detrazione is not null
                         and ogco.anno = a_anno
                       )
                     ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 w_conta_rif_ap_ab_principale := 0;
            END;
            if w_conta_rif_ap_ab_principale > 0 then
               w_rif_ap_ab_principale := 'S';
            else
               w_rif_ap_ab_principale := 'N';
            end if;
         else
              w_rif_ap_ab_principale := 'N';
         end if;
         if nContaDefi = 0 then
            -- Verifico se l'oggetto è abitazione principale
            if rec_ogco.tipo_oggetto = 3 and
                  (rec_ogco.flag_ab_principale = 'S' or
                   rec_ogco.detrazione_ogco is not null or
                   w_esiste_det_ogco = 'S'
                     or
                   w_rif_ap_ab_principale = 'S'  -- Serve per gestire le pertinenze con pertinenza_di
                  ) and
                  (w_flag_pertinenze = 'S' or
                   (w_flag_pertinenze is null and rec_ogco.categoria_catasto_ogpr like 'A%')
                )   THEN
               FOR rec_figl in sel_figl(rec_ogco.cod_fam, rec_ogco.fascia, rec_ogco.tipo_residente, rec_ogco.matricola)
               LOOP
                  --dbms_output.put_line('cf: '||sCodFiscale||' - Matr: '||to_char(rec_ogco.matricola)||' - OGPR: '||to_char(rec_ogco.oggetto_pratica_ogpr) );
                  w_altro_genitore_proprietario := 0;
                  w_matricola_pd := nvl(nvl(rec_figl.matricola_pd,f_matricola_pd(rec_figl.matricola)),0);
                  w_matricola_md := nvl(nvl(rec_figl.matricola_md,f_matricola_md(rec_figl.matricola)),0);
                  --dbms_output.put_line('Figlio: '||to_char(rec_figl.matricola) );
                  --dbms_output.put_line('Padre: '||to_char(w_matricola_pd) );
                  --dbms_output.put_line('Madre: '||to_char(w_matricola_md) );
                  if w_matricola_pd = rec_ogco.matricola then
                     nNumeroFigli := nNumeroFigli + 1;
                     -- verifico se la madre appartiene allo stesso nucleo
                     begin
                        select count(1)
                          into w_altro_genitore_proprietario
                          from (select 'a'
                                  from soggetti  sogg
                                 where sogg.cod_fam         = rec_ogco.cod_fam
                                   and sogg.tipo_residente  = rec_ogco.tipo_residente
                                   and sogg.matricola       = w_matricola_md
                                   and sogg.fascia         in (1,3)
                                   and sogg.data_ult_eve    < to_date('0101'||to_char(a_anno),'ddmmyyyy')
                                 union
                                select 'a'
                                  from soggetti  sogg
                                 where sogg.cod_fam         = rec_ogco.cod_fam
                                   and sogg.tipo_residente  = rec_ogco.tipo_residente
                                   and sogg.matricola       = w_matricola_md
                                   and sogg.fascia         in (2,4)
                                   and sogg.data_ult_eve   >= to_date('0101'||to_char(a_anno),'ddmmyyyy')
                               )
                             ;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          w_altro_genitore_proprietario := 0;
                     end;
                     -- Verifico se la madre è proprietario dell'oggetto
                     if w_altro_genitore_proprietario > 0 then
                        begin
                           select count(1)
                             into w_altro_genitore_proprietario
                             from (
                                 select ogpr.oggetto
                                   from soggetti              sogg
                                      , contribuenti          cont
                                      , oggetti_contribuente  ogco
                                      , oggetti_pratica       ogpr
                                      , pratiche_tributo      prtr
                                  where cont.ni                = sogg.ni
                                    and sogg.matricola         = w_matricola_md
                                    and sogg.tipo_residente +0 = rec_ogco.tipo_residente
                                    and ogco.anno||ogco.tipo_rapporto||'S' =
                                       (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                                          from pratiche_tributo     c
                                             , oggetti_contribuente b
                                             , oggetti_pratica      a
                                        where (  c.data_notifica is not null and c.tipo_pratica||'' = 'A'
                                             and nvl(c.stato_accertamento,'D') = 'D'
                                             and nvl(c.flag_denuncia,' ')      = 'S'
                                             and c.anno                        < a_anno
                                              or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                                               )
                                          and c.anno                  <= a_anno
                                          and c.tipo_tributo||''       = prtr.tipo_tributo
                                          and c.pratica                = a.pratica
                                          and a.oggetto_pratica        = b.oggetto_pratica
                                          and a.oggetto                = ogpr.oggetto
                                          and b.tipo_rapporto         in ('C','D','E')
                                          and b.cod_fiscale            = ogco.cod_fiscale
                                      )
                                    and prtr.tipo_tributo||''    = a_tipo_tributo
                                    and nvl(prtr.stato_accertamento,'D') = 'D'
                                    and prtr.pratica             = ogpr.pratica
                                    and ogpr.oggetto_pratica     = ogco.oggetto_pratica
                                    and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                                    and decode(ogco.anno
                                              ,a_anno,decode(ogco.flag_esclusione
                                                            ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                                            ,nvl(ogco.mesi_esclusione,0)
                                                            )
                                              ,decode(ogco.flag_esclusione,'S',12,0)
                                              )                     <=
                                        decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
                                    and ogco.flag_possesso       = 'S'
                                    and ogco.cod_fiscale         = cont.cod_fiscale
                                    and ogpr.oggetto             = rec_ogco.oggetto
                              union
                                 select ogpr.oggetto
                                   from soggetti              sogg
                                      , contribuenti          cont
                                      , oggetti_contribuente  ogco
                                      , oggetti_pratica       ogpr
                                      , pratiche_tributo      prtr
                                  where cont.ni                = sogg.ni
                                    and sogg.matricola         = w_matricola_md
                                    and sogg.tipo_residente +0 = rec_ogco.tipo_residente
                                    and prtr.tipo_pratica||''  = 'D'
                                    and ogco.flag_possesso    is null
                                    and prtr.tipo_tributo||''       = a_tipo_tributo
                                    and nvl(prtr.stato_accertamento,'D') = 'D'
                                    and prtr.pratica                = ogpr.pratica
                                    and ogpr.oggetto_pratica        = ogco.oggetto_pratica
                                    and ogco.anno                   = a_anno
                                    and decode(ogco.anno
                                              ,a_anno,decode(ogco.flag_esclusione
                                                            ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                                            ,nvl(ogco.mesi_esclusione,0)
                                                            )
                                              ,decode(ogco.flag_esclusione,'S',12,0)
                                              )                     <=
                                        decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
                                    and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                                    and ogco.cod_fiscale         = cont.cod_fiscale
                                    and ogpr.oggetto             = rec_ogco.oggetto
                                  )
                              ;
                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                             w_altro_genitore_proprietario := 0;
                        end;
                     end if;
                     --dbms_output.put_line('AltroGenPropr: '||w_altro_genitore_proprietario );
                     if w_altro_genitore_proprietario > 0 then
                        dDetrazione := dDetrazione + (dDetrazioneFiglio/2);
                        dDetrazioneAcconto := dDetrazioneAcconto + (dDetrazioneFiglio/4);
                     else
                        dDetrazione := dDetrazione + dDetrazioneFiglio;
                        dDetrazioneAcconto := dDetrazioneAcconto + (dDetrazioneFiglio/2);
                     end if;
                  elsif w_matricola_md = rec_ogco.matricola then
                     nNumeroFigli := nNumeroFigli + 1;
                     -- verifico se il padre appartiene allo stesso nucleo
                     begin
                        select count(1)
                          into w_altro_genitore_proprietario
                          from (select 'a'
                                  from soggetti  sogg
                                 where sogg.cod_fam         = rec_ogco.cod_fam
                                   and sogg.tipo_residente  = rec_ogco.tipo_residente
                                   and sogg.matricola       = w_matricola_pd
                                   and sogg.fascia         in (1,3)
                                   and sogg.data_ult_eve    < to_date('0101'||to_char(a_anno),'ddmmyyyy')
                                 union
                                select 'a'
                                  from soggetti  sogg
                                 where sogg.cod_fam         = rec_ogco.cod_fam
                                   and sogg.tipo_residente  = rec_ogco.tipo_residente
                                   and sogg.matricola       = w_matricola_pd
                                   and sogg.fascia         in (2,4)
                                   and sogg.data_ult_eve   >= to_date('0101'||to_char(a_anno),'ddmmyyyy')
                               )
                             ;
                     EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                          w_altro_genitore_proprietario := 0;
                     end;
                     -- Verifico se il padre è proprietario dell'oggetto
                     if w_altro_genitore_proprietario > 0 then
                        begin
                           select count(1)
                             into w_altro_genitore_proprietario
                             from (
                                 select ogpr.oggetto
                                   from soggetti              sogg
                                      , contribuenti          cont
                                      , oggetti_contribuente  ogco
                                      , oggetti_pratica       ogpr
                                      , pratiche_tributo      prtr
                                  where cont.ni                = sogg.ni
                                    and sogg.matricola         = w_matricola_pd
                                    and sogg.tipo_residente +0 = rec_ogco.tipo_residente
                                    and ogco.anno||ogco.tipo_rapporto||'S' =
                                       (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
                                          from pratiche_tributo     c
                                             , oggetti_contribuente b
                                             , oggetti_pratica      a
                                        where (  c.data_notifica is not null and c.tipo_pratica||'' = 'A'
                                             and nvl(c.stato_accertamento,'D') = 'D'
                                             and nvl(c.flag_denuncia,' ')      = 'S'
                                             and c.anno                        < a_anno
                                              or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                                               )
                                          and c.anno                  <= a_anno
                                          and c.tipo_tributo||''       = prtr.tipo_tributo
                                          and c.pratica                = a.pratica
                                          and a.oggetto_pratica        = b.oggetto_pratica
                                          and a.oggetto                = ogpr.oggetto
                                          and b.tipo_rapporto         in ('C','D','E')
                                          and b.cod_fiscale            = ogco.cod_fiscale
                                      )
                                    and prtr.tipo_tributo||''    = a_tipo_tributo
                                    and nvl(prtr.stato_accertamento,'D') = 'D'
                                    and prtr.pratica             = ogpr.pratica
                                    and ogpr.oggetto_pratica     = ogco.oggetto_pratica
                                    and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                                    and decode(ogco.anno
                                              ,a_anno,decode(ogco.flag_esclusione
                                                            ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                                            ,nvl(ogco.mesi_esclusione,0)
                                                            )
                                              ,decode(ogco.flag_esclusione,'S',12,0)
                                              )                     <=
                                        decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
                                    and ogco.flag_possesso       = 'S'
                                    and ogco.cod_fiscale         = cont.cod_fiscale
                                    and ogpr.oggetto             = rec_ogco.oggetto
                              union
                                 select ogpr.oggetto
                                   from soggetti              sogg
                                      , contribuenti          cont
                                      , oggetti_contribuente  ogco
                                      , oggetti_pratica       ogpr
                                      , pratiche_tributo      prtr
                                  where cont.ni                = sogg.ni
                                    and sogg.matricola         = w_matricola_pd
                                    and sogg.tipo_residente +0 = rec_ogco.tipo_residente
                                    and prtr.tipo_pratica||''  = 'D'
                                    and ogco.flag_possesso    is null
                                    and prtr.tipo_tributo||''       = a_tipo_tributo
                                    and nvl(prtr.stato_accertamento,'D') = 'D'
                                    and prtr.pratica                = ogpr.pratica
                                    and ogpr.oggetto_pratica        = ogco.oggetto_pratica
                                    and ogco.anno                   = a_anno
                                    and decode(ogco.anno
                                              ,a_anno,decode(ogco.flag_esclusione
                                                            ,'S',nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso,12))
                                                            ,nvl(ogco.mesi_esclusione,0)
                                                            )
                                              ,decode(ogco.flag_esclusione,'S',12,0)
                                              )                     <=
                                        decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12)
                                    and decode(ogco.anno,a_anno,nvl(ogco.mesi_possesso,12),12) >= 0
                                    and ogco.cod_fiscale         = cont.cod_fiscale
                                    and ogpr.oggetto             = rec_ogco.oggetto
                                  )
                                  ;
                        EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                             w_altro_genitore_proprietario := 0;
                        end;
                     end if;
                     --dbms_output.put_line('AltroGenPropr: '||w_altro_genitore_proprietario );
                     if w_altro_genitore_proprietario > 0 then
                        dDetrazione := dDetrazione + (dDetrazioneFiglio/2);
                        dDetrazioneAcconto := dDetrazioneAcconto + (dDetrazioneFiglio/4);
                     else
                        dDetrazione := dDetrazione + dDetrazioneFiglio;
                        dDetrazioneAcconto := dDetrazioneAcconto + (dDetrazioneFiglio/2);
                     end if;
                  end if;
               end loop;
               if nNumeroFigli > 0 then
                  BEGIN
                     --dbms_output.put_line('Ins defi '||sCodFiscale||' - Figli: '||to_char(nNumeroFigli));
                     --dbms_output.put_line('Detrazione '||to_char(dDetrazione)||' - Detrazione Acc: '||to_char(dDetrazioneAcconto));
                     insert into detrazioni_figli
                           ( cod_fiscale
                           , anno
                           , da_mese
                           , a_mese
                           , numero_figli
                           , detrazione
                           , detrazione_acconto
                           , utente
                           )
                     values( sCodFiscale
                           , a_anno
                           , 1
                           , 12
                           , nNumeroFigli
                           , dDetrazione
                           , dDetrazioneAcconto
                           , a_utente
                           )
                     ;
                  END;
                  nTrattati := nTrattati + 1;
               end if;
            end if;
         end if;
      end if;
   END LOOP;
   if nTrattati = 0 then
      sMessagggio := 'Nessuna Detrazione Figlio Inserita';
   else
      sMessagggio := 'Detrazione Figlio inserita su '||to_char(nTrattati)||' contribuenti';
   end if;
   a_messaggio := sMessagggio;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20999,sCodFiscale||' - '||SQLERRM);
END;
/* End Procedure: INSERIMENTO_DEFI_CONT */
/

