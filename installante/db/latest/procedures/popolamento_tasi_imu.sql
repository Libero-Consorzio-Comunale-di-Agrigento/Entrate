--liquibase formatted sql 
--changeset abrandolini:20250326_152423_popolamento_tasi_imu stripComments:false runOnChange:true 
 
create or replace procedure POPOLAMENTO_TASI_IMU
/*************************************************************************
 Versione  Data              Autore    Descrizione
 5         10/02/2020        VD        Aggiunto controllo su indice array
                                       contenente pratiche da archiviare:
                                       se = 0, non si lancia l'archiviazione
 4         13/01/2020        VD        Aggiunta archiviazione denunce
                                       inserite
 3         11/12/2019        VD        Aggiunta gestione campo
                                       da_mese_possesso
 2         06/05/2016        VD        Aggiunta gestione tipo oggetto 55
 1         14/10/2014        ET        Corretto per gestione codice fiscale
                                       ed altri parametri anche fuori dal loop
 0         05/02/2014                  Prima emissione
*************************************************************************/
(a_cod_fiscale          varchar2 default '%'
,a_tipo_oggetto         number   default null
,a_fonte                number
,a_primo_popolamento    varchar2
,a_post_2013            varchar2
,a_data_wpti        out date
)
as
  w_id_wpti                      number;
  --w_data_wpti         date;
  w_anno                         number := 2014;
  w_cod_fiscale                  varchar2(16) := 'ZZZZZZZZZZZZZZZZ';
  w_cod_fiscale_da_non_trattare  varchar2(16) := 'ZZZZZZZZZZZZZZZZ';  --cf da saltare in quanto esistono pratiche TASI caricate altrimenti
  w_pratica                      number;
  w_utente                       varchar2(6)  := 'ITASI';
  w_oggetto_pratica              number;
  w_stringa_output               varchar2(32000);
  w_note                         oggetti_pratica.note%type;
  --Gestione delle eccezioni
  w_errore                       varchar2(32767);
  errore                         exception;
  -- (VD - 13/01/2020): variabili per memorizzare denunce inserite
  --                    da archiviare
  TYPE TYPE_PRATICA IS TABLE OF PRATICHE_TRIBUTO.PRATICA%TYPE INDEX BY BINARY_INTEGER;
  t_pratica                      TYPE_PRATICA;
  w_ind                          number := 0;
--
-- Cursore pratiche imu: si tratta di trovare tutti gli oggetti
-- che a fine 2013 (a_anno_rif = 2013) sono posseduti dai contribuenti, al fine
-- di creare per ognuno di essi le pratiche TASI nel 2014.
-- Si escludono quei contribuenti che hanno già pratiche TASI per la stessa fonte
-- nel 2014 (w_anno) come proprietari caricate con questa procedure
-- (w_utente = ITASI)
--
  cursor sel_ogco_pre_2014(a_anno_rif number)
  is
      select nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_oggetto
            ,ogpr.pratica pratica_ogpr
            ,ogpr.oggetto oggetto_ogpr
            ,f_dato_riog(ogco.cod_fiscale
                        ,ogco.oggetto_pratica
                        ,w_anno
                        ,'CA'
                        )
               categoria_catasto_ogpr
            ,ogpr.oggetto_pratica oggetto_pratica_ogpr
            ,ogco.anno anno_ogco
            ,ogco.cod_fiscale cod_fiscale
            ,ogco.flag_possesso
            ,ogco.perc_possesso
            ,12 mesi_possesso
            ,6  mesi_possesso_1sem
            -- (VD - 11/12/2019): nuovo campo da_mese_possesso
            ,1  da_mese_possesso
            ,ogco.flag_al_ridotta
            ,decode(ogco.flag_al_ridotta, 'S', 12, 0)
               mesi_aliquota_ridotta
            ,ogco.flag_esclusione
            ,decode(ogco.flag_esclusione, 'S', 12, 0)
               mesi_esclusione
            ,ogco.flag_riduzione
            ,decode(ogco.flag_riduzione, 'S', 12, 0)
               mesi_riduzione
            ,ogco.flag_ab_principale flag_ab_principale
            ,f_valore(nvl(f_valore_d(ogpr.oggetto_pratica, w_anno)
                         ,ogpr.valore
                         )
                     ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,prtr.anno
                     ,w_anno
                     ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                     ,prtr.tipo_pratica
                     ,ogpr.flag_valore_rivalutato
                     )
               valore
            ,f_valore(nvl(f_valore_d(ogpr.oggetto_pratica, w_anno)
                         ,ogpr.valore
                         )
                     ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,prtr.anno
                     ,w_anno
                     ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
                     ,prtr.tipo_pratica
                     ,ogpr.flag_valore_rivalutato
                     )
               valore_d
            ,decode(ogco.detrazione
                   ,'', decode(ogco.flag_ab_principale
                              ,'S', made.detrazione
                              ,''
                              )
                   ,nvl(made.detrazione, ogco.detrazione)
                   )
               detrazione
            ,ogco.detrazione detrazione_ogco
            ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
               categoria_catasto_ogge
            ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1, nvl(molt.moltiplicatore, 1)
                   ,3, decode(   nvl(ogpr.imm_storico, 'N')
                              || to_char(sign(2012 - w_anno))
                             ,'S1', 100
                             ,nvl(molt.moltiplicatore, 1)
                             )
                   ,1
                   )
               moltiplicatore
            ,ogpr.imm_storico
            ,ogpr.oggetto_pratica_rif_ap
            ,rire.aliquota aliquota_rivalutazione
            ,made.detrazione magg_detrazione
            ,prtr.tipo_pratica
            ,prtr.anno anno_titr
            ,ogpr.num_ordine
            ,ogpr.classe_catasto
            ,ogpr.categoria_catasto
            ,prtr.note note_prtr
            ,ogpr.note note_ogpr
            ,ogco.note note_ogco
            ,ogco.successione
            ,ogco.progressivo_sudv
        from rivalutazioni_rendita rire
            ,moltiplicatori molt
            ,maggiori_detrazioni made
            ,oggetti ogge
            ,pratiche_tributo prtr
            ,oggetti_pratica ogpr
            ,oggetti_contribuente ogco
       where rire.anno(+) = w_anno
         and rire.tipo_oggetto(+) = ogpr.tipo_oggetto
         and molt.anno(+) = w_anno
         and molt.categoria_catasto(+) =
               f_dato_riog(ogco.cod_fiscale
                          ,ogco.oggetto_pratica
                          ,w_anno
                          ,'CA'
                          )
         and made.anno(+) + 0 = w_anno
         and made.cod_fiscale(+) = ogco.cod_fiscale
         and made.tipo_tributo(+) = 'ICI'
         and ogco.anno || ogco.tipo_rapporto || 'S' =
               (select max(b.anno || b.tipo_rapporto || b.flag_possesso)
                  from pratiche_tributo c
                      ,oggetti_contribuente b
                      ,oggetti_pratica a
                 where (c.data_notifica is not null
                    and c.tipo_pratica || '' = 'A'
                    and nvl(c.stato_accertamento, 'D') = 'D'
                    and nvl(c.flag_denuncia, ' ') = 'S'
                    and c.anno < a_anno_rif
                     or (c.data_notifica is null
                     and c.tipo_pratica || '' = 'D'))
                   and c.anno <= a_anno_rif
                   and c.tipo_tributo || '' = prtr.tipo_tributo
                   and c.pratica = a.pratica
                   and a.oggetto_pratica = b.oggetto_pratica
                   and a.oggetto = ogpr.oggetto
                   and b.tipo_rapporto in ('C', 'D', 'E')
                   and b.cod_fiscale = ogco.cod_fiscale)
         and ogge.oggetto = ogpr.oggetto
         and prtr.tipo_tributo || '' = 'ICI'
         and nvl(prtr.stato_accertamento, 'D') = 'D'
         and prtr.pratica = ogpr.pratica
         and ogpr.oggetto_pratica = ogco.oggetto_pratica
         and ogco.flag_possesso = 'S'
-- (VD - 06/05/2016: Aggiunto tipo_oggetto 55
         and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) in (2, 3, 4, 55)
--         and ogco.flag_ab_principale is null
--         and ogpr.oggetto_pratica_rif_ap is null
--         and not (ogge.categoria_catasto like 'C%'
--              and ogco.detrazione is not null)
--
--         and not exists (select 'x'
--                           from oggetti_pratica ogpr_fo
--                          where ogpr_fo.oggetto_pratica = ogco.oggetto_pratica
--                            and ogpr_fo.fonte  = a_fonte
--                            and ogpr_fo.utente = w_utente)
-- commentato il controllo errato su ogpr e inserito quello su prtr e ogpr per la fonte AB (2/4/14)
         and not exists (select 1
                           from oggetti_pratica ogpr_fo
                              , pratiche_tributo prtr_fo
                              , oggetti_contribuente ogco_fo
                          where prtr_fo.cod_fiscale = ogco.cod_fiscale
                            and prtr_fo.anno        = w_anno
                            and prtr_fo.utente      = w_utente
                            and ogpr_fo.pratica     = prtr_fo.pratica
                            and ogpr_fo.fonte       = a_fonte
                            and ogco_fo.oggetto_pratica = ogpr_fo.oggetto_pratica
                            and ogco_fo.cod_fiscale = ogco.cod_fiscale
                            and nvl(ogco_fo.tipo_rapporto,'D') = 'D')
         and ogco.cod_fiscale      like a_cod_fiscale
         and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = nvl(a_tipo_oggetto,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto))
    order by ogco.cod_fiscale, prtr.anno, prtr.pratica, ogpr.oggetto_pratica
    ;
-- cursore pratiche imu del 2014 o successivi
-- da lanciare una volta con da e a = 2014, e la successiva con
-- da = 2015 e a = 9999 .
-- In questo cursore non si applica filtro sul tipo oggetto.
--
  cursor sel_ogco(a_anno_da number, a_anno_a number)
  is
      select distinct prtr.anno
           , prtr.pratica
           , prtr.cod_fiscale
        from pratiche_tributo prtr
           , oggetti_pratica ogpr
           , oggetti_contribuente ogco
       where prtr.anno between a_anno_da and a_anno_a
         and ogco.cod_fiscale like a_cod_fiscale
         and prtr.tipo_tributo||'' = 'ICI'
         and prtr.pratica = ogpr.pratica
         and ogco.oggetto_pratica = ogpr.oggetto_pratica
         and ogco.tipo_rapporto in ('D', 'C')
        order by prtr.anno, prtr.cod_fiscale, prtr.pratica
      ;
PROCEDURE INSERT_WPTI(p_id out number, p_data in out date, p_cf varchar2) as
begin
   p_id := null;
   wrk_popolamento_tasi_imu_nr(p_id);
   insert into wrk_popolamento_tasi_imu
   (id, utente, data_elaborazione, cod_fiscale)
   values(p_id, w_utente, p_data, p_cf)
   ;
end INSERT_WPTI;
PROCEDURE UPDATE_WPTI(p_id number
                     , p_data date
                     , p_tipo number
                     , p_cf_contitolare varchar2 default null
                     , p_anno number default null
                     , p_pratica number default null
                     , p_pratica_tasi number default null
                     , p_oggetto number default null
                     , p_msg varchar2 default null) as
w_descrizione wrk_popolamento_tasi_imu.descrizione%type;
begin
    if    p_tipo = 1
            then w_descrizione := 'Pratiche TASI gia'' presenti';
    elsif p_tipo = 2
            then w_descrizione := 'Oggetto TASI gia'' presente';
    elsif p_tipo = 3   --f_pratica_tasi_da_imu ok
            then w_descrizione := substr(p_msg,1,2000);
    elsif p_tipo = 4   --f_pratica_tasi_da_imu errore
            then w_descrizione := substr(p_msg,1,2000);
    elsif p_tipo = 5   --azzeramento pratica
            then w_descrizione := 'Annullamento valori pratica TASI precedentemente popolata';
    end if;
    update wrk_popolamento_tasi_imu
       set data_elaborazione = p_data
         , tipo = p_tipo
         , cod_fiscale_contitolare = p_cf_contitolare
         , anno = p_anno
         , pratica_imu = p_pratica
         , pratica_tasi = p_pratica_tasi
         , oggetto = p_oggetto
         , descrizione = w_descrizione
     where id = p_id
    ;
end UPDATE_WPTI;
PROCEDURE MODIFICA_WPTI( p_id in out number
                       , p_data in out date
                       , p_cf varchar2
                       , p_tipo number
                       , p_cf_contitolare varchar2 default null
                       , p_anno number default null
                       , p_pratica number default null
                       , p_pratica_tasi number default null
                       , p_oggetto number default null
                       , p_msg  varchar2 default null) as
begin
   if p_data is null then
      p_data := sysdate;
   end if;
   begin
       select id
         into p_id
         from wrk_popolamento_tasi_imu
        where data_elaborazione = p_data
          and pratica_imu = p_pratica
          and nvl(pratica_tasi, 0) = nvl(p_pratica_tasi, nvl(pratica_tasi, 0))
          and nvl(anno, 0) = nvl(p_anno, nvl(anno, 0))
          and cod_fiscale = p_cf
          and nvl(cod_fiscale_contitolare, '*') = nvl(p_cf_contitolare, nvl(cod_fiscale_contitolare, '*'))
          and nvl(oggetto, 0) = nvl(p_oggetto, nvl(oggetto, 0))
          and tipo = p_tipo
       ;
   exception
   when others then
       p_id := null;
   end;
   if p_id is null then
      INSERT_WPTI(p_id, p_data, p_cf);
   end if;
   UPDATE_WPTI( p_id => p_id
              , p_data => p_data
              , p_tipo => p_tipo
              , p_cf_contitolare => p_cf_contitolare
              , p_anno => p_anno
              , p_pratica => p_pratica
              , p_pratica_tasi => p_pratica_tasi
              , p_oggetto => p_oggetto
              , p_msg => p_msg);
end MODIFICA_WPTI;
/*******************************************************************************/
/* CHECK_ESISTENZA_PRATICHE                                                    */
/* Verifica se esistono pratiche TASI nello stesso anno relative agli          */
/* stessi oggetti e contribuenti di p_pratica_imu.                             */
/* Se P_UTENTE_CREAZIONE è valorizzato, le pratiche cercate devono             */
/* essere di un utente diverso da p_utente_creazione.                          */
/*******************************************************************************/
PROCEDURE CHECK_ESISTENZA_PRATICHE( P_PRATICA_IMU NUMBER
                                  , P_ANNO_IMU NUMBER
                                  , P_CF_IMU VARCHAR2
                                  , P_UTENTE_CREAZIONE VARCHAR2) AS
BEGIN
    FOR pratiche_tasi IN (SELECT prtr.anno
                               , prtr.pratica
                               , prtr.cod_fiscale
                               , ogpr.oggetto
                            FROM oggetti_pratica ogpr
                               , pratiche_tributo prtr
                               , oggetti_contribuente ogco
                           WHERE ( prtr.anno
                                 , ogco.cod_fiscale
                                 , tipo_tributo
                                 , tipo_pratica
                                 , ogpr.oggetto) IN (SELECT prtr_ici.anno
                                                          , ogco_ici.cod_fiscale
                                                          , 'TASI'
                                                          , 'D'
                                                          , ogpr_ici.oggetto
                                                       FROM pratiche_tributo prtr_ici
                                                          , oggetti_pratica ogpr_ici
                                                          , oggetti_contribuente ogco_ici
                                                      WHERE prtr_ici.pratica = p_pratica_imu
                                                        AND prtr_ici.pratica = ogpr_ici.pratica
                                                        AND ogco_ici.oggetto_pratica = ogpr_ici.oggetto_pratica
                                                        AND ogco_ici.tipo_rapporto= 'D')
                              AND ogpr.pratica = prtr.pratica
                              AND ogco.oggetto_pratica = ogpr.oggetto_pratica
                              AND (p_utente_creazione is null
                                   or prtr.utente != p_utente_creazione)) LOOP
        MODIFICA_WPTI( p_id =>  w_id_wpti
                     , p_data => a_data_wpti
                     , p_cf => P_CF_IMU
                     , p_tipo => 2
                     , p_cf_contitolare => null
                     , p_anno =>  P_ANNO_IMU
                     , p_pratica => P_PRATICA_IMU
                     , p_pratica_tasi => pratiche_tasi.pratica
                     , p_oggetto => pratiche_tasi.oggetto);
    END LOOP;
-- CONTITOLARI
    FOR pratiche_tasi IN (SELECT prtr.anno
                               , prtr.pratica
                               , prtr.cod_fiscale
                               , ogpr.oggetto
                            FROM oggetti_pratica ogpr
                               , pratiche_tributo prtr
                               , oggetti_contribuente ogco
                           WHERE ( prtr.anno
                                 , ogco.cod_fiscale
                                 , tipo_tributo
                                 , tipo_pratica
                                 , ogpr.oggetto) IN (SELECT prtr_ici.anno
                                                          , ogco_ici.cod_fiscale
                                                          , 'TASI'
                                                          , 'D'
                                                          , ogpr_ici.oggetto
                                                       FROM pratiche_tributo prtr_ici
                                                          , oggetti_pratica ogpr_ici
                                                          , oggetti_contribuente ogco_ici
                                                      WHERE prtr_ici.pratica = p_pratica_imu
                                                        AND prtr_ici.pratica = ogpr_ici.pratica
                                                        AND ogco_ici.oggetto_pratica = ogpr_ici.oggetto_pratica
                                                        AND ogco_ici.tipo_rapporto= 'C')
                              AND ogpr.pratica = prtr.pratica
                              AND ogco.oggetto_pratica = ogpr.oggetto_pratica
                              AND (p_utente_creazione is null
                                   or prtr.utente != p_utente_creazione)) LOOP
        MODIFICA_WPTI( p_id =>  w_id_wpti
                     , p_data => a_data_wpti
                     , p_cf => P_CF_IMU
                     , p_tipo => 2
                     , p_cf_contitolare => pratiche_tasi.cod_fiscale
                     , p_anno => P_ANNO_IMU
                     , p_pratica => P_PRATICA_IMU
                     , p_pratica_tasi => pratiche_tasi.pratica
                     , p_oggetto => pratiche_tasi.oggetto);
    END LOOP;
END;
/******************************************************************************/
/*AZZERAMENTO_PRATICHE                                                        */
/*Se esistono pratiche TASI nello stesso anno relative agli                   */
/*stessi oggetti e contribuenti di p_pratica_imu,                             */
/*ne azzera i valori di possesso.                                             */
/******************************************************************************/
PROCEDURE AZZERAMENTO_PRATICHE(P_PRATICA_IMU NUMBER, P_ANNO_IMU NUMBER, P_CF_IMU VARCHAR2) AS
BEGIN
--TITOLARE
            FOR pratiche_tasi IN (SELECT prtr.anno
                                       , prtr.pratica
                                       , prtr.cod_fiscale
                                       , ogpr.oggetto
                                    FROM oggetti_pratica ogpr
                                       , pratiche_tributo prtr
                                       , oggetti_contribuente ogco
                                   WHERE ( prtr.anno
                                         , ogco.cod_fiscale
                                         , tipo_tributo
                                         , tipo_pratica
                                         , ogpr.oggetto) IN (SELECT prtr_ici.anno
                                                                  , ogco_ici.cod_fiscale
                                                                  , 'TASI'
                                                                  , 'D'
                                                                  , ogpr_ici.oggetto
                                                               FROM pratiche_tributo prtr_ici
                                                                  , oggetti_pratica ogpr_ici
                                                                  , oggetti_contribuente ogco_ici
                                                              WHERE prtr_ici.pratica = P_PRATICA_IMU
                                                                AND prtr_ici.pratica = ogpr_ici.pratica
                                                                AND ogco_ici.oggetto_pratica = ogpr_ici.oggetto_pratica
                                                                AND ogco_ici.tipo_rapporto= 'D')
                                      AND ogpr.pratica = prtr.pratica
                                      AND ogco.oggetto_pratica = ogpr.oggetto_pratica
                                      AND prtr.utente = w_utente) LOOP
                update oggetti_contribuente
                   set mesi_possesso = 0
                     , mesi_possesso_1sem = 0
                     -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                     , da_mese_possesso = 0
                     , flag_possesso = null
                 where cod_fiscale = pratiche_tasi.cod_fiscale
                   and oggetto_pratica in (select oggetto_pratica
                                             from oggetti_pratica
                                            where pratica = pratiche_tasi.pratica
                                              and oggetto = pratiche_tasi.oggetto)
                ;
                MODIFICA_WPTI( p_id =>  w_id_wpti
                     , p_data => a_data_wpti
                     , p_cf => P_CF_IMU
                     , p_tipo => 5
                     , p_cf_contitolare => null
                     , p_anno =>  P_ANNO_IMU
                     , p_pratica => P_PRATICA_IMU
                     , p_pratica_tasi => pratiche_tasi.pratica
                     , p_oggetto => pratiche_tasi.oggetto);
            END LOOP;
--CONTITOLARI
            FOR pratiche_tasi IN (SELECT prtr.anno
                                       , prtr.pratica
                                       , prtr.cod_fiscale
                                       , ogpr.oggetto
                                    FROM oggetti_pratica ogpr
                                       , pratiche_tributo prtr
                                       , oggetti_contribuente ogco
                                   WHERE ( prtr.anno
                                         , ogco.cod_fiscale
                                         , tipo_tributo
                                         , tipo_pratica
                                         , ogpr.oggetto) IN (SELECT prtr_ici.anno
                                                                  , ogco_ici.cod_fiscale
                                                                  , 'TASI'
                                                                  , 'D'
                                                                  , ogpr_ici.oggetto
                                                               FROM pratiche_tributo prtr_ici
                                                                  , oggetti_pratica ogpr_ici
                                                                  , oggetti_contribuente ogco_ici
                                                              WHERE prtr_ici.pratica = P_PRATICA_IMU
                                                                AND prtr_ici.pratica = ogpr_ici.pratica
                                                                AND ogco_ici.oggetto_pratica = ogpr_ici.oggetto_pratica
                                                                AND ogco_ici.tipo_rapporto= 'C')
                                      AND ogpr.pratica = prtr.pratica
                                      AND ogco.oggetto_pratica = ogpr.oggetto_pratica
                                      AND prtr.utente = w_utente) LOOP
                update oggetti_contribuente
                   set mesi_possesso = 0
                     , mesi_possesso_1sem = 0
                     -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                     , da_mese_possesso = 0
                     , flag_possesso = null
                 where cod_fiscale = pratiche_tasi.cod_fiscale
                   and oggetto_pratica in (select oggetto_pratica
                                             from oggetti_pratica
                                            where pratica = pratiche_tasi.pratica
                                              and oggetto = pratiche_tasi.oggetto)
                ;
                MODIFICA_WPTI( p_id =>  w_id_wpti
                     , p_data => a_data_wpti
                     , p_cf => P_CF_IMU
                     , p_tipo => 5
                     , p_cf_contitolare => pratiche_tasi.cod_fiscale
                     , p_anno =>  P_ANNO_IMU
                     , p_pratica => P_PRATICA_IMU
                     , p_pratica_tasi => pratiche_tasi.pratica
                     , p_oggetto => pratiche_tasi.oggetto);
            END LOOP;
END;
begin
/***********ELABORAZIONE 2013 SU 2014**************************/
--cursore per copia da 2013 (e precedenti) a 2014
  t_pratica.delete;
  if a_primo_popolamento = 'S' then
      for rec_ogco in sel_ogco_pre_2014(2013) loop
      -- al cambio di cf committo quanto fatto e creo una nuova pratica TASI
        if rec_ogco.cod_fiscale != w_cod_fiscale then
          commit;
          w_id_wpti     := null;
          --w_data_wpti   := null;
          w_cod_fiscale :=   rec_ogco.cod_fiscale;
          if w_cod_fiscale !=   w_cod_fiscale_da_non_trattare then
        --21/04/2015 SC CR456427: se esiste TASI 2014 come proprietario
        -- caricata da utente != da ITASI devo fermare elaborazione
        -- per quel CF.
        -- In caso di lancio massivo registro su tabella e passo ad altro cf,
        -- in caso di lancio singolo esco con segnalazione da dare a video.
              declare
                w_esiste_tasi number;
              begin
                select count(*)
                  into w_esiste_tasi
                  from pratiche_tributo prtr, rapporti_tributo ratr
                 where prtr.anno = w_anno
                   and prtr.tipo_tributo||'' = 'TASI'
                   and prtr.pratica = ratr.pratica
                   and ratr.tipo_rapporto = 'D'
                   and prtr.utente != w_utente
                   and prtr.cod_fiscale = w_cod_fiscale
                ;
                if w_esiste_tasi > 0 then
                   --dbms_output.put_line('Controllo esiste_tasi.');
                   w_cod_fiscale_da_non_trattare := w_cod_fiscale;
                   modifica_wpti( p_id =>w_id_wpti
                                , p_data => a_data_wpti
                                , p_cf => w_cod_fiscale_da_non_trattare
                                , p_anno => w_anno
                                , p_tipo => 1);
                end if;
              exception
              when others then
                w_errore      :=
                    ('Errore in inserimento in WRK_POPOLAMENTO_TASI_IMU ' || ' (' || sqlerrm || ')');
                  raise errore;
              end;
              -- inserisci pratica
             begin
                w_pratica :=   null;
                pratiche_tributo_nr(w_pratica);
                w_ind     := w_ind + 1;
                t_pratica (w_ind) := w_pratica;
             exception
             when others then
                  w_errore      :=
                    substr(('Errore in ricerca numero di pratica' || ' (' || sqlerrm || ')'),1,2000);
                  raise errore;
             end;
             begin
                insert
                  into pratiche_tributo(pratica
                                       ,cod_fiscale
                                       ,tipo_tributo
                                       ,anno
                                       ,tipo_pratica
                                       ,tipo_evento
                                       ,data
                                       ,utente
                                       ,data_variazione
                                       ,note
                                       )
                values (
                        w_pratica
                       ,rec_ogco.cod_fiscale
                       ,'TASI'
                       ,w_anno
                       ,'D'
                       ,'I'
                       ,trunc(sysdate)
                       ,w_utente
                       ,trunc(sysdate)
                       ,rec_ogco.note_prtr||' Popolamento TASI da IMU eseguito il '
                        || to_char(sysdate, 'dd/mm/yyyy')
                       );
                 --dbms_output.put_line('Insert in pratiche_tributo.');
             exception
                when others then
                  w_errore      :=
                    ('Errore in inserimento nuova pratica' || ' (' || sqlerrm || ')');
                  raise errore;
             end;
              -- DENUNCE TASI
             begin
                insert
                  into denunce_tasi(pratica
                                  ,denuncia
                                  ,fonte
                                  ,utente
                                  ,data_variazione
                                  ,note
                                  )
                values (
                        w_pratica
                       ,w_pratica
                       ,a_fonte
                       ,w_utente
                       ,sysdate
                       ,   'Popolamento TASI da IMU eseguito il'
                        || to_char(sysdate, 'dd/mm/yyyy')
                       );
                --dbms_output.put_line('Insert in denunce_ici.');
             exception
                when others then
                  w_errore      :=
                    (   'Errore in inserimento nuova denuncia tasi'
                     || ' ('
                     || sqlerrm
                     || ')');
                  raise errore;
             end;
              -- ...rapporti_tributo
             begin
                insert into rapporti_tributo(pratica, cod_fiscale, tipo_rapporto)
                     values (w_pratica, rec_ogco.cod_fiscale, 'D');
                --dbms_output.put_line('Insert in rapporti_tributo.');
             exception
                when others then
                  w_errore      :=
                    (   'Errore in inserimento rapporto tributo'
                     || ' ('
                     || sqlerrm
                     || ')');
                  raise errore;
             end;
          end if;
        end if;
        --
        if w_cod_fiscale !=   w_cod_fiscale_da_non_trattare then
        --inserisci oggetto
        --Inserimento dati in oggetti_pratica
                 --dbms_output.put_line('Insert in oggetti_pratica. w_cod_cf '||w_cod_fiscale||' w_cf_non '||w_cod_fiscale_da_non_trattare);
            w_oggetto_pratica :=   null;
            oggetti_pratica_nr(w_oggetto_pratica);
            if rec_ogco.note_ogpr is null then
              w_note      :=
                   'Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
            else
              w_note      :=
                   rec_ogco.note_ogpr
                || ' - Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
            end if;
            begin
              insert
                into oggetti_pratica(oggetto_pratica
                                    ,oggetto
                                    ,pratica
                                    ,anno
                                    ,num_ordine
                                    ,categoria_catasto
                                    ,classe_catasto
                                    ,valore
                                    ,fonte
                                    ,utente
                                    ,data_variazione
                                    ,note
                                    ,tipo_oggetto
                                    ,imm_storico
                                    ,oggetto_pratica_rif_ap
                                    )
              values (
                      w_oggetto_pratica
                     ,rec_ogco.oggetto_ogpr
                     ,w_pratica
                     ,w_anno
                     ,rec_ogco.num_ordine
                     ,rec_ogco.categoria_catasto
                     ,rec_ogco.classe_catasto
                     ,rec_ogco.valore
                     ,a_fonte
                     ,w_utente
                     ,sysdate
                     ,w_note
                     ,rec_ogco.tipo_oggetto
                     ,rec_ogco.imm_storico
                     ,null
                     );
             --dbms_output.put_line('Insert in oggetti_pratica.');
            exception
              when others then
                w_errore      :=
                  ('Errore in inserimento Oggetto Pratica' || ' (' || sqlerrm || ')');
                raise errore;
            end;
            --Inserimento dati in oggetti_contribuente
            if rec_ogco.note_ogco is null then
              w_note      :=
                   'Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
            else
              w_note      :=
                   rec_ogco.note_ogco
                || ' - Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
            end if;
            begin
              insert
                into oggetti_contribuente(cod_fiscale
                                         ,oggetto_pratica
                                         ,anno
                                         ,tipo_rapporto
                                         ,perc_possesso
                                         ,mesi_possesso
                                         ,mesi_possesso_1sem
                                          -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                                         ,da_mese_possesso
                                         ,detrazione
                                         ,flag_possesso
                                         ,flag_esclusione
                                         ,flag_riduzione
                                         ,flag_ab_principale
                                         ,successione
                                         ,progressivo_sudv
                                         ,utente
                                         ,data_variazione
                                         ,note
                                         )
              values (
                      rec_ogco.cod_fiscale
                     ,w_oggetto_pratica
                     ,w_anno
                     ,'D'
                     ,rec_ogco.perc_possesso
                     ,rec_ogco.mesi_possesso
                     ,rec_ogco.mesi_possesso_1sem
                      -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                     ,rec_ogco.da_mese_possesso
                     ,rec_ogco.detrazione
                     ,rec_ogco.flag_possesso
                     ,rec_ogco.flag_esclusione
                     ,rec_ogco.flag_riduzione
                     ,rec_ogco.flag_ab_principale
                     ,rec_ogco.successione
                     ,rec_ogco.progressivo_sudv
                     ,w_utente
                     ,sysdate
                     ,w_note
                     );
               --dbms_output.put_line('Insert in oggetti_contribuente.');
            exception
              when others then
                w_errore      :=
                  (   'Errore in inserimento Oggetto Contribuente'
                   || ' ('
                   || sqlerrm
                   || ')');
                raise errore;
            end;
            insert into aliquote_ogco(cod_fiscale
                                     ,oggetto_pratica
                                     ,dal
                                     ,al
                                     ,tipo_tributo
                                     ,tipo_aliquota
                                     ,note
                                     )
              select rec_ogco.cod_fiscale
                    ,w_oggetto_pratica
                    ,greatest(to_date('01/01/' || w_anno, 'dd/mm/yyyy'), dal)
                    ,al
                    ,'TASI'
                    ,tipo_aliquota
                    ,note
                from aliquote_ogco alog
               where alog.cod_fiscale = rec_ogco.cod_fiscale
                 and alog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                 and greatest(to_date('01/01/' || w_anno, 'dd/mm/yyyy'), dal) <= al;
            insert into detrazioni_ogco(cod_fiscale
                                       ,oggetto_pratica
                                       ,anno
                                       ,motivo_detrazione
                                       ,detrazione
                                       ,note
                                       ,detrazione_acconto
                                       ,tipo_tributo
                                       )
              select rec_ogco.cod_fiscale
                    ,w_oggetto_pratica
                    ,anno
                    ,motivo_detrazione
                    ,detrazione
                    ,note
                    ,detrazione_acconto
                    ,'TASI'
                from detrazioni_ogco deog
               where deog.cod_fiscale = rec_ogco.cod_fiscale
                 and deog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                 and anno >= w_anno;
            insert into costi_storici(oggetto_pratica
                                     ,anno
                                     ,costo
                                     ,utente
                                     ,data_variazione
                                     ,note
                                     )
              select w_oggetto_pratica, anno, costo, w_utente, sysdate, note
                from costi_storici cost
               where cost.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
                 and cost.anno >= w_anno;
        end if;
      end loop;
    -- Questa parte riguarda ancora la copia da 2013 (e precedenti) a 2014
    -- si tratta di calcolare la perc_detrazione TASI in base alla detrazione nella pratica IMU
    -- ai mesi di possesso e alla percentuale di possesso
    -- (lo fa AGGIORNA_PERC_DETRAZIONE) e poi ricalcolare la detrazione sulle pratiche TASI in base
    -- alla perc_detrazione così trovata.
    -- Eseguo sempre fidandomi del fatto che ad ogni lancio venga modificata la fonte,
    -- e quindi che ricalcolo sempre su pratiche TASI nuove.
      BEGIN -- per recuperare la perc_detrazione da mettere nei nuovi ogco TASI
        AGGIORNA_PERC_DETRAZIONE(a_cod_fiscale,a_tipo_oggetto,a_fonte);
      END;
      begin
        update oggetti_contribuente  ogco
           set ogco.detrazione = (select round(detr.detrazione_base * ogco.perc_detrazione / 100,2)
                                    from detrazioni  detr
                                   where anno = w_anno
                                     and tipo_tributo = 'TASI')
         where ogco.perc_detrazione is not null
           and exists (select 1
                         from detrazioni  detr
                        where anno = w_anno
                          and tipo_tributo = 'TASI')
           and instr(ogco.note,'Pratica:') >0
           and ogco.utente = w_utente
           and ogco.detrazione is not null
           and ogco.cod_fiscale      like a_cod_fiscale
           and exists (select 'x'
                         from oggetti_pratica ogpr,
                              pratiche_tributo prtr,
                              oggetti ogge
                        where ogpr.oggetto_pratica = ogco.oggetto_pratica
                        and ogpr.pratica = prtr.pratica
                        and prtr.tipo_tributo||'' = 'TASI'
                        and prtr.anno = w_anno
                        and ogpr.fonte            = a_fonte
                        and ogpr.oggetto          = ogge.oggetto
                        and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                            = nvl(a_tipo_oggetto,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)))
        ;
      exception
          when others then
            w_errore      :=
              (   'Errore in aggiornamento Oggetti Contribuente per la detrazione'
               || ' ('
               || sqlerrm
               || ')');
            raise errore;
      end;
  end if;
commit;
/***********FINE ELABORAZIONE 2013 SU 2014**************************/
/***********ELABORAZIONE 2014 SU 2014*******************************/
if a_post_2013 = 'S' then
    for rec_ogco_2014 in sel_ogco(2014, 2014) loop
    --controllo se esistono pratiche tasi con utente != ITASI
    -- per lo stesso anno per il titolare o i contitolari per l'oggetto
        CHECK_ESISTENZA_PRATICHE(rec_ogco_2014.pratica, rec_ogco_2014.anno, rec_ogco_2014.cod_fiscale, w_utente);
    --se anche un solo oggetto della pratica imu è in wrk_popolamento_tasi_imu
    -- salto la pratica
        declare
        w_esiste_tasi number := 0;
        begin
            select count(*)
              into w_esiste_tasi
              from wrk_popolamento_tasi_imu
             where data_elaborazione = a_data_wpti
               and pratica_imu = rec_ogco_2014.pratica
            ;
            if  w_esiste_tasi = 0 then
    --verifico se ci sono oggetti TASI di cui annullare i valori
    -- mesi_possesso = 0, mesi_possesso_1s = 0 e flag_possesso = null
                AZZERAMENTO_PRATICHE(rec_ogco_2014.pratica, rec_ogco_2014.anno, rec_ogco_2014.cod_fiscale);
                begin
                    w_stringa_output := f_pratica_tasi_da_imu( rec_ogco_2014.pratica
                                         , w_utente);
                    MODIFICA_WPTI( p_id =>  w_id_wpti
                                 , p_data => a_data_wpti
                                 , p_cf => rec_ogco_2014.cod_fiscale
                                 , p_tipo => 3
                                 , p_cf_contitolare => null
                                 , p_anno => rec_ogco_2014.anno
                                 , p_pratica => rec_ogco_2014.pratica
                                 , p_pratica_tasi => null
                                 , p_oggetto => null
                                 , p_msg => w_stringa_output);
                exception
                when others then
                    MODIFICA_WPTI( p_id =>  w_id_wpti
                                 , p_data => a_data_wpti
                                 , p_cf => rec_ogco_2014.cod_fiscale
                                 , p_tipo => 4
                                 , p_cf_contitolare => null
                                 , p_anno => rec_ogco_2014.anno
                                 , p_pratica => rec_ogco_2014.pratica
                                 , p_pratica_tasi => null
                                 , p_oggetto => null
                                 , p_msg => sqlerrm);
                end;
            end if;
        end;
        commit;
    end loop;
    /***********FINE ELABORAZIONE 2014 SU 2014**************************/
    /***********ELABORAZIONE 2015 e successici SU stesso anno***********/
    for rec_ogco_post_2014 in sel_ogco(2015, 9999) loop
    --controllo se esistono pratiche tasi con utente != ITASI
    -- per lo stesso anno per il titolare o i contitolari per l'oggetto
        CHECK_ESISTENZA_PRATICHE(rec_ogco_post_2014.pratica, rec_ogco_post_2014.anno, rec_ogco_post_2014.cod_fiscale, null);
    --se anche un solo oggetto della pratica imu è in wrk_popolamento_tasi_imu
    -- salto la pratica
        declare
        w_esiste_tasi number := 0;
        begin
            select count(*)
              into w_esiste_tasi
              from wrk_popolamento_tasi_imu
             where data_elaborazione = a_data_wpti
               and pratica_imu = rec_ogco_post_2014.pratica
            ;
            if  w_esiste_tasi = 0 then
                begin
                    w_stringa_output := f_pratica_tasi_da_imu( rec_ogco_post_2014.pratica
                                         , w_utente);
                    MODIFICA_WPTI( p_id =>  w_id_wpti
                                 , p_data => a_data_wpti
                                 , p_cf => rec_ogco_post_2014.cod_fiscale
                                 , p_tipo => 3
                                 , p_cf_contitolare => null
                                 , p_anno => rec_ogco_post_2014.anno
                                 , p_pratica => rec_ogco_post_2014.pratica
                                 , p_pratica_tasi => null
                                 , p_oggetto => null
                                 , p_msg => w_stringa_output);
                exception
                when others then
                    MODIFICA_WPTI( p_id =>  w_id_wpti
                                 , p_data => a_data_wpti
                                 , p_cf => rec_ogco_post_2014.cod_fiscale
                                 , p_tipo => 4
                                 , p_cf_contitolare => null
                                 , p_anno => rec_ogco_post_2014.anno
                                 , p_pratica => rec_ogco_post_2014.pratica
                                 , p_pratica_tasi => null
                                 , p_oggetto => null
                                 , p_msg => sqlerrm);
                end;
            end if;
        end;
        commit;
    end loop;
    -- (VD - 13/01/2020): archiviazione pratiche inserite
    if w_ind > 0 then
       for w_ind in t_pratica.first .. t_pratica.last
       loop
         if t_pratica (w_ind) is not null then
            archivia_denunce('','',t_pratica(w_ind));
         end if;
       end loop;
    end if;
    commit;
end if;
/***********FINE ELABORAZIONE 2015 e successici SU stesso anno******/
exception
  when errore then
    rollback;
    raise_application_error(-20999, w_errore);
  when others then
    rollback;
    raise_application_error(-20999
                           ,   ' Errore in POPOLAMENTO_TASI_IMU '
                            || '('
                            || sqlerrm
                            || ')'
                           );
end;
/* End Procedure: POPOLAMENTO_TASI_IMU */
/

