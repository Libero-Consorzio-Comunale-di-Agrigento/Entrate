--liquibase formatted sql 
--changeset abrandolini:20250326_152423_numera_bollettini_anno stripComments:false runOnChange:true 
 
create or replace procedure NUMERA_BOLLETTINI_ANNO
(a_titr             in varchar2
,a_anno             in  number
,a_ordinamento      in  varchar2
,a_tipo_num         in  varchar2
,a_cod_fiscale      in  varchar2
) is
--
-- Procedura per ogni tributo diverso da ICI per anno e con rateizzazioni
--
errore                  exception;
sErrore                 varchar2(2000) := null;
nBoll_ogim              number;
nBoll_raim              number;
nBollettino             number;
sCod_Fiscale_Prec       varchar2(16);
nAnno                   number;
sTipo_Tributo           varchar2(5);
nRata_Prec              number;
cursor sel_ogim (p_titr        varchar2
                ,p_anno        number
                ,p_ordinamento varchar2
                ,p_cod_fiscale varchar2
                ) is
select ogim.cod_fiscale
      ,sogg.cognome
      ,sogg.nome
      ,ogim.oggetto_imposta
      ,ogim.num_bollettino
      ,ogim.anno
      ,prtr.tipo_tributo
  from soggetti          sogg
      ,contribuenti      cont
      ,pratiche_tributo  prtr
      ,oggetti_pratica   ogpr
      ,oggetti_imposta   ogim
 where cont.cod_fiscale     = ogim.cod_fiscale
   and sogg.ni              = cont.ni
   and ogpr.oggetto_pratica = ogim.oggetto_pratica
   and prtr.anno            < ogim.anno
   and prtr.pratica         = ogpr.pratica
   and ogim.cod_fiscale     LIKE p_cod_fiscale
   and ogim.anno             = p_anno
   and prtr.tipo_tributo||'' = p_titr
   and ogim.flag_calcolo     = 'S'
 order by
       decode(p_ordinamento
             ,'N',sogg.cognome
                 ,ogim.cod_fiscale
             ) asc
      ,decode(p_ordinamento
             ,'N',sogg.nome
                 ,ogim.oggetto_imposta
             ) asc
      ,decode(p_ordinamento
             ,'N',sogg.cod_fiscale
                 ,1
             ) asc
      ,decode(p_ordinamento
             ,'N',ogim.oggetto_imposta
                 ,1
             ) asc
;
cursor sel_ogim_anno (p_titr        varchar2
                ,p_anno        number
                ,p_ordinamento varchar2
                ,p_cod_fiscale varchar2
                ) is
select ogim.cod_fiscale
      ,sogg.cognome
      ,sogg.nome
      ,ogim.oggetto_imposta
      ,ogim.num_bollettino
      ,ogim.anno
      ,prtr.tipo_tributo
  from soggetti          sogg
      ,contribuenti      cont
      ,pratiche_tributo  prtr
      ,oggetti_pratica   ogpr
      ,oggetti_imposta   ogim
 where cont.cod_fiscale     = ogim.cod_fiscale
   and sogg.ni              = cont.ni
   and ogpr.oggetto_pratica = ogim.oggetto_pratica
   and prtr.anno            = ogim.anno
   and prtr.pratica         = ogpr.pratica
   and ogim.cod_fiscale     LIKE p_cod_fiscale
   and ogim.anno             = p_anno
   and prtr.tipo_tributo||'' = p_titr
   and ogim.flag_calcolo     = 'S'
 order by
       decode(p_ordinamento
             ,'N',sogg.cognome
                 ,ogim.cod_fiscale
             ) asc
      ,decode(p_ordinamento
             ,'N',sogg.nome
                 ,ogim.oggetto_imposta
             ) asc
      ,decode(p_ordinamento
             ,'N',sogg.cod_fiscale
                 ,1
             ) asc
      ,decode(p_ordinamento
             ,'N',ogim.oggetto_imposta
                 ,1
             ) asc
;
cursor sel_raim (p_oggetto_imposta number) is
select raim.rata_imposta
      ,raim.num_bollettino
  from rate_imposta raim
 where raim.oggetto_imposta = p_oggetto_imposta
 order by
       raim.rata asc
;
cursor sel_racf (p_cod_fiscale  varchar2
                ,p_anno         number
                ,p_tipo_tributo varchar2
                ) is
select raim.rata_imposta
      ,raim.num_bollettino
      ,raim.rata
  from rate_imposta      raim
 where raim.cod_fiscale     = p_cod_fiscale
   and raim.anno            = p_anno
   and raim.tipo_tributo    = p_tipo_tributo
 order by
       raim.rata            asc
      ,raim.oggetto_imposta asc
;
BEGIN
--
-- Determinazione del numero massimo di bollettino assegnato
-- come il maggiore tra i massimi di oggetti imposta e rate imposta.
--
   BEGIN
      select nvl(max(raim.num_bollettino),0)
        into nboll_raim
        from rate_imposta    raim
       where raim.num_bollettino is not null
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nboll_raim := 0;
   END;
   BEGIN
      select nvl(max(ogim.num_bollettino),0)
        into nboll_ogim
        from oggetti_imposta ogim
       where ogim.num_bollettino is not null
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nboll_ogim := 0;
   END;
   nBollettino := greatest(nboll_ogim,nboll_raim);
   sCod_Fiscale_Prec     := null;
   nAnno                 := null;
   sTipo_Tributo         := null;
   FOR rec_ogim in sel_ogim(a_titr,a_anno,a_ordinamento,a_cod_fiscale)
   LOOP
      if nAnno is null then
         nAnno         := rec_ogim.anno;
         sTipo_Tributo := rec_ogim.tipo_tributo;
      end if;
--
-- Le rate, in caso di numerazione per contribuente, vanno numerate
-- subito dopo gli oggetti imposta del contribuente.
-- Siccome la routine seguente esegue tale numerazione a cambio
-- contribuente, diventa necessario eseguirla prima della gestione
-- dell`oggetto imposta del contribuente successivo.
-- Per il primo cintribuente non si esegue la routine (se cf prec = null).
--
      if  rec_ogim.cod_fiscale <> nvl(sCod_Fiscale_Prec,' ')
      and sCod_Fiscale_Prec    is not null
      and a_tipo_num            = 'CONT' then
         nRata_Prec := -1;
         FOR rec_racf in sel_racf (sCod_Fiscale_Prec,nAnno,sTipo_Tributo)
         LOOP
            if rec_racf.num_bollettino is null then
               if rec_racf.rata <> nRata_Prec then
                  nBollettino := nBollettino + 1;
               end if;
               update rate_imposta raim
                  set raim.num_bollettino  = nBollettino
                where raim.rata_imposta    = rec_racf.rata_imposta
                  and raim.oggetto_imposta is null
               ;
               nRata_Prec := rec_racf.rata;
            end if;
         END LOOP;
      end if;
      if rec_ogim.num_bollettino is null then
         if  a_tipo_num = 'OGIM'
         or  a_tipo_num = 'CONT'
         and rec_ogim.cod_fiscale <> nvl(sCod_Fiscale_Prec,' ') then
            nBollettino := nBollettino + 1;
         end if;
         update oggetti_imposta ogim
            set ogim.num_bollettino  = nBollettino
          where ogim.oggetto_imposta = rec_ogim.oggetto_imposta
         ;
      end if;
--
-- Nel caso di numerazione per oggetto imposta, le rate seguono
-- immediatamente l`oggetto imposta appena numerato.
--
      if a_tipo_num = 'OGIM' then
         FOR rec_raim in sel_raim(rec_ogim.oggetto_imposta)
         LOOP
            if rec_raim.num_bollettino is null then
               nBollettino := nBollettino + 1;
               update rate_imposta raim
                  set raim.num_bollettino  = nBollettino
                where raim.rata_imposta    = rec_raim.rata_imposta
               ;
            end if;
         END LOOP;
      end if;
      sCod_Fiscale_Prec := rec_ogim.cod_fiscale;
   END LOOP;
--
-- Numerazione rate dell`ultimo contribuente in caso
-- di numerazione per contribuente.
-- Il test su cf prec nullo, serve per sapere se sono
-- stati trattati degli oggetti imposta, altrimenti
-- non si deve eseguire alcuna operazione nemmeno sulle rate.
--
   if  a_tipo_num         = 'CONT'
   and sCod_Fiscale_Prec is not null then
      nRata_Prec := -1;
      FOR rec_racf in sel_racf (sCod_Fiscale_Prec,nAnno,sTipo_Tributo)
      LOOP
         if rec_racf.num_bollettino is null then
            if rec_racf.rata <> nRata_Prec then
               nBollettino := nBollettino + 1;
            end if;
            update rate_imposta raim
               set raim.num_bollettino  = nBollettino
             where raim.rata_imposta    = rec_racf.rata_imposta
               and raim.oggetto_imposta is null
            ;
            nRata_Prec := rec_racf.rata;
         end if;
      END LOOP;
   end if;
--
-- Novità del 4/12/2008
-- Trattamento degli OGIM relativi alle denunce emesse nell'anno dell'imposta
--
   FOR rec_ogim in sel_ogim_anno(a_titr,a_anno,a_ordinamento,a_cod_fiscale)
   LOOP
--
-- Si numera subito l'ogim e poi le rate
--
      if rec_ogim.num_bollettino is null then
         nBollettino := nBollettino + 1;
         update oggetti_imposta ogim
            set ogim.num_bollettino  = nBollettino
          where ogim.oggetto_imposta = rec_ogim.oggetto_imposta
         ;
      end if;
--
-- Nel caso di pratiche relative all'anno di imposta si esegue sempre la numerazione
-- sulla singola rata
--
         FOR rec_raim in sel_raim(rec_ogim.oggetto_imposta)
         LOOP
            if rec_raim.num_bollettino is null then
               nBollettino := nBollettino + 1;
               update rate_imposta raim
                  set raim.num_bollettino  = nBollettino
                where raim.rata_imposta    = rec_raim.rata_imposta
               ;
            end if;
         END LOOP;
   END LOOP;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,sErrore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: NUMERA_BOLLETTINI_ANNO */
/

