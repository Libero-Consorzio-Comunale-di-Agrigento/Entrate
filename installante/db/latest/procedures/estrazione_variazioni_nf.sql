--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_variazioni_nf stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_VARIAZIONI_NF
  (a_anno       in number)
/******************************************************************************
 NOME:        ESTRAZIONE_VARIAZIONI_NF
 DESCRIZIONE: Estrazione Variazione Nuclei Familiari

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   04/12/2024  RV      65968
                           Prima emissione
******************************************************************************/
IS
  --
  nProgressivo      number;
  sErrore           varchar2(200);
  errore            exception;
  --
cursor sel_var_nf(p_anno      number)
is
    select
         to_char(p_anno) as anno
       , to_char(ni) as ni
       , cod_fiscale
       , cognome_nome
       --
       , to_char(num_pratica) as num_pratica
       , to_char(anno_pratica) as anno_pratica
       , to_char(oggetto) as num_ogg
       , to_char(oggetto_pratica) as num_ogpr
       --
       , decode(flag_ab_principale,'S','S','-') as ab_principale
       --
       , to_char(faso_dal,'dd/MM/YYYY') as faso_dal
       , to_char(faso_al,'dd/MM/YYYY') as faso_al
       --
       , to_char(num_fam_faso) as num_fam_faso
       , to_char(num_fam_ogpr) as num_fam_ogpr
       , to_char(num_fam_cosu) as num_fam_cosu
    from
      (
      select distinct
          sogg.ni
        , sogg.cognome_nome
        , cont.cod_fiscale
        --
        , prtr.pratica as num_pratica
        , prtr.anno as anno_pratica
        , ogpr.oggetto
        , ogpr.oggetto_pratica
        , ogco.flag_ab_principale
        --
        , ogco.data_decorrenza
        , ogco.data_cessazione
        --
        , ogpr.numero_familiari as num_fam_ogpr
        --
        , faso.dal as faso_dal
        , faso.al as faso_al
        , faso.numero_familiari as num_fam_faso
        --
        , F_GET_NUM_FAM_COSU(ogpr.oggetto_pratica,ogco.flag_ab_principale,p_anno) as num_fam_cosu
      from
        pratiche_tributo prtr,
        oggetti_pratica ogpr,
        oggetti_contribuente ogco,
        oggetti_validita ogva,
        contribuenti cont,
        soggetti sogg,
        familiari_soggetto faso,
        categorie cate
      where
        prtr.tipo_tributo = 'TARSU' and
        prtr.cod_fiscale = cont.cod_fiscale and
        --
        not exists
        (select 'x'
          from pratiche_tributo prtr1
         where prtr1.tipo_pratica || '' = 'A'
           and prtr1.anno <= p_anno
           and prtr1.pratica = ogpr.pratica
           and (trunc(sysdate) - nvl(prtr1.data_notifica, trunc(sysdate)) < 60 and
               flag_adesione is null or prtr1.anno = p_anno)
           and prtr1.flag_denuncia = 'S') and
        nvl(prtr.stato_accertamento, 'D') = 'D' and 
        --
        cont.ni = sogg.ni and
        sogg.ni = faso.ni(+) and
        --
        prtr.pratica = ogpr.pratica and
        ogpr.oggetto_pratica = ogco.oggetto_pratica and
        ogpr.anno = ogco.anno and
        prtr.cod_fiscale = ogco.cod_fiscale and
        --
        ogva.cod_fiscale = prtr.cod_fiscale and
        ogva.tipo_tributo = prtr.tipo_tributo and
        ogva.oggetto_pratica = ogpr.oggetto_pratica
        --
        and faso.anno(+) = p_anno
        --
        and nvl(ogva.dal,to_date('0101'||p_anno,'ddMMYYYY')) <= to_date('3112'||p_anno,'ddMMYYYY')
        and nvl(ogva.al,to_date('3112'||p_anno,'ddMMYYYY')) >= to_date('0101'||p_anno,'ddMMYYYY')
        --
        and ogpr.tributo = cate.tributo
        and ogpr.categoria = cate.categoria
        and cate.flag_domestica = 'S'
        --
--      and ogpr.numero_familiari is not null and
--      and ogpr.numero_familiari <> faso.numero_familiari
     )
   order by
     cod_fiscale, oggetto, faso_dal, faso_al
;
BEGIN
  --
  sErrore := null;
  --
  SI4.SQL_EXECUTE('truncate table wrk_trasmissioni');
  --
  nProgressivo := 0;
  --
  insert into wrk_trasmissioni
         (numero,dati)
  values (0,'NI;COGNOME_NOME;COD_FISCALE;PRATICA;ANNO_PRAT;OGG;OGPR;AB_PRINC;FASO_DAL;FASO_AL;FAM_FASO;FAM_OGPR;FAM_COSU;');
  --
  FOR rec_var_nf in sel_var_nf(a_anno)
  LOOP
    nProgressivo := nProgressivo + 1;
    insert into wrk_trasmissioni
           (numero,dati)
    values (nProgressivo,rec_var_nf.ni || ';' || rec_var_nf.cognome_nome || ';' || rec_var_nf.cod_fiscale || ';' ||
                        rec_var_nf.num_pratica || ';' || rec_var_nf.anno_pratica || ';' ||
                        rec_var_nf.num_ogg || ';' || rec_var_nf.num_ogpr || ';' || rec_var_nf.ab_principale || ';' ||
                        rec_var_nf.faso_dal || ';' || rec_var_nf.faso_al || ';' ||
                        rec_var_nf.num_fam_faso || ';' || rec_var_nf.num_fam_ogpr || ';' || rec_var_nf.num_fam_cosu || ';'
    )
    ;
  END LOOP;
  --
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,sErrore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
   --
END;
/* End Procedure: ESTRAZIONE_VARIAZIONI_NF */
/
