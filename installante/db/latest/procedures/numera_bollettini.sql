--liquibase formatted sql 
--changeset abrandolini:20250326_152423_numera_bollettini stripComments:false runOnChange:true 
 
create or replace procedure NUMERA_BOLLETTINI
(a_titr             in varchar2
,a_anno             in  number
,a_ordinamento      in  varchar2
,a_tipo_num         in  varchar2
,a_cod_fiscale      in  varchar2
) is
--
-- Procedura limitata al solo tipo tributo ICI che non ha rateizzazioni.
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
                ,p_tipo_num    varchar2
                ) is
select decode(p_ordinamento
             ,'N',rpad(sogg.cognome,60,' ')||rpad(nvl(sogg.nome,' '),36,' ')
                 ,rpad(ogim.cod_fiscale,16,' ')
             ) ord1
      ,decode(p_ordinamento
             ,'N',rpad(ogim.cod_fiscale,16,' ')
                 ,rpad(sogg.cognome,60,' ')||rpad(nvl(sogg.nome,' '),36,' ')
             ) ord2
      ,decode(p_tipo_num,'OGIM',ogim.oggetto_imposta,0) ord3
      ,0 rata
      ,ogim.cod_fiscale
      ,sogg.cognome
      ,sogg.nome
      ,ogim.oggetto_imposta chiave
      ,'O' id_chiave
  from soggetti           sogg
      ,contribuenti       cont
      ,pratiche_tributo   prtr
      ,oggetti_pratica    ogpr
      ,oggetti_imposta    ogim
 where cont.cod_fiscale      = ogim.cod_fiscale
   and sogg.ni               = cont.ni
   and ogpr.oggetto_pratica  = ogim.oggetto_pratica
   and prtr.pratica          = ogpr.pratica
   and ogim.cod_fiscale   like p_cod_fiscale
   and ogim.anno             = p_anno
   and prtr.tipo_tributo||'' = p_titr
   and ogim.flag_calcolo     = 'S'
 order by
       1 asc
      ,2 asc
      ,3 asc
      ,4 asc
;
BEGIN
--
-- Determinazione del numero massimo di bollettino assegnato.
--
   nAnno         := a_anno;
   sTipo_Tributo := a_titr;
   nBoll_Raim    := 0;
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
   FOR rec_ogim in sel_ogim(a_titr,a_anno,a_ordinamento,a_cod_fiscale,a_tipo_num)
   LOOP
      if rec_ogim.cod_fiscale <> nvl(sCod_Fiscale_Prec,' ') then
         nBollettino := nBollettino + 1;
         sCod_Fiscale_Prec := rec_ogim.cod_fiscale;
      end if;
      update oggetti_imposta ogim
         set ogim.num_bollettino = nBollettino
       where ogim.oggetto_imposta = rec_ogim.chiave
      ;
   END LOOP;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,sErrore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: NUMERA_BOLLETTINI */
/

