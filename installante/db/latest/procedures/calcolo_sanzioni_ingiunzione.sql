--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_ingiunzione stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_INGIUNZIONE
(a_pratica            IN number
,a_utente             IN varchar2
) is
w_errore                 varchar2(2000);
errore                   exception;
sql_errm                 varchar2(100);
w_tipo_tributo           varchar2(10);
w_data_ingiunzione       date;
w_anno                   number;
w_importo_ingiunzione    number;
w_versato_ingiunzione    number;
w_spese                  number;
w_perc_insolvenza        number;
w_insolvenza_ingiunzione number;
w_spese_istruttoria      number;
w_insolvenza_pratica     number;
w_interesse_pratica      number;
w_interessi              number := 0;
w_data_inizio_interessi  date;
w_giorni_anno            number := 365;
w_giorni_interessi       number := null;
w_giorni_interessi_tot   number := null;
w_note                   varchar2(2000) := '';
CURSOR sel_prat (p_pratica_rif number) IS
   select prtr.pratica
        , prtr.tipo_tributo
        , prtr.importo_totale
        , sapr.imposta
        , f_versato_pratica(prtr.pratica) versato
        , data_notifica
        , data
     from pratiche_tributo prtr
        , (select sapr2.pratica
                , sum(decode(sapr2.tipo_tributo
                            ,'ICI',decode(sapr2.cod_sanzione
                                         ,1,sapr2.importo
                                         ,21,sapr2.importo
                                         ,24,sapr2.importo
                                         ,31,sapr2.importo
                                         ,101,sapr2.importo
                                         ,121,sapr2.importo
                                         ,124,sapr2.importo
                                         ,131,sapr2.importo
                                         ,180,sapr2.importo
                                         ,0
                                         )
                            ,'ICIAP',decode(sapr2.cod_sanzione
                                           ,1,sapr2.importo
                                           ,101,sapr2.importo
                                           ,0
                                           )
                            ,'ICP',decode(sapr2.cod_sanzione
                                         ,1,sapr2.importo
                                         ,11,sapr2.importo
                                         ,21,sapr2.importo
                                         ,31,sapr2.importo
                                         ,41,sapr2.importo
                                         ,101,sapr2.importo
                                         ,111,sapr2.importo
                                         ,121,sapr2.importo
                                         ,131,sapr2.importo
                                         ,141,sapr2.importo
                                         ,0
                                         )
                            ,'TARSU',decode(sapr2.cod_sanzione
                                           ,1,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,9,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                            + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,100,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,101,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,109,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,111,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,121,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,131,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,141,sapr2.importo + round(sapr2.importo * nvl(cata.addizionale_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.maggiorazione_eca,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.addizionale_pro,0) / 100,2)
                                                              + round(sapr2.importo * nvl(cata.aliquota,0) / 100,2)
                                           ,0
                                           )
                            ,'TOSAP',decode(sapr2.cod_sanzione
                                           ,1,sapr2.importo
                                           ,11,sapr2.importo
                                           ,21,sapr2.importo
                                           ,31,sapr2.importo
                                           ,41,sapr2.importo
                                           ,101,sapr2.importo
                                           ,111,sapr2.importo
                                           ,121,sapr2.importo
                                           ,131,sapr2.importo
                                           ,141,sapr2.importo
                                           ,0
                                           )
                            ,0
                            )
                       )   imposta
             from sanzioni_pratica  sapr2
                , pratiche_tributo  prtr2
                , carichi_tarsu     cata
            where cata.anno  (+)         = prtr2.anno
              and prtr2.pratica        = sapr2.pratica
         group by sapr2.pratica
          ) sapr
    where prtr.pratica        = sapr.pratica (+)
      and prtr.pratica_rif    = p_pratica_rif
    ;
BEGIN
-- Recupero Dati Pratica
   begin
      select prtr.tipo_tributo
           , prtr.data
           , prtr.anno
           , f_importo_ingiunzione(prtr.pratica,'ARR')
           , f_versato_ingiunzione(prtr.pratica)
        into w_tipo_tributo
           , w_data_ingiunzione
           , w_anno
           , w_importo_ingiunzione
           , w_versato_ingiunzione
        from pratiche_tributo prtr
       where prtr.pratica = a_pratica
         and prtr.tipo_pratica = 'G'
         ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      w_errore := 'Pratica di Ingiunzione '||to_char(a_pratica)||' non trovata.';
      RAISE ERRORE;
   end;
-- Cancellazione Sanzioni calcolate precedentemente (297,299)
   begin
      delete sanzioni_pratica
       where pratica = a_pratica
         and cod_sanzione in (297,299)
           ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      w_errore := 'Errore in Cancellazione Sanzioni calcolate precedentemente (297,299).';
      RAISE ERRORE;
   end;
-- Inserimento Spese Istruttoria (297)
   w_insolvenza_ingiunzione := nvl(w_importo_ingiunzione,0) - nvl(w_versato_ingiunzione,0);
   begin
      select spis.spese
           , spis.perc_insolvenza
        into w_spese
           , w_perc_insolvenza
        from spese_istruttoria spis
       where spis.anno = w_anno
         and spis.tipo_tributo = w_tipo_tributo
         and w_insolvenza_ingiunzione between spis.da_importo
                                          and nvl(spis.a_importo,9999999999)
         ;
   EXCEPTION
      WHEN others THEN
      w_errore := 'Errore in Recupero Spese Istruttoria';
      RAISE ERRORE;
   end;
   if w_perc_insolvenza is null then
      w_spese_istruttoria := w_spese;
   else
      w_spese_istruttoria := round(w_insolvenza_ingiunzione * w_perc_insolvenza / 100,2);
   end if;
   BEGIN
      insert into sanzioni_pratica
            (pratica,cod_sanzione,tipo_tributo
            ,importo,utente,data_variazione)
     values (a_pratica,297,w_tipo_tributo
            ,w_spese_istruttoria,a_utente,trunc(sysdate))
             ;
   EXCEPTION
      WHEN others THEN
         sql_errm := substr(SQLERRM,1,100);
         RAISE_APPLICATION_ERROR
         (-20999,'Errore in inserimento Sanzioni Pratica (297) '||
                  '('||sql_errm||')');
   END;
-- Inserimento Interessi (299)
   FOR rec_prat IN sel_prat(a_pratica) LOOP
      w_insolvenza_pratica := nvl(rec_prat.imposta,0)  - nvl(rec_prat.versato,0);
      if w_insolvenza_pratica < 0 then
         w_insolvenza_pratica := 0;
      end if;
      if rec_prat.tipo_tributo = 'ICI' and rec_prat.data <= to_date('31/12/2006','dd/mm/yyyy') then
         w_data_inizio_interessi := rec_prat.data_notifica + 91;
      else
         w_data_inizio_interessi := rec_prat.data_notifica + 61;
      end if;
      w_interesse_pratica := F_CALCOLO_INTERESSI_GG_TITR(w_insolvenza_pratica
                                                        ,w_data_inizio_interessi
                                                        ,w_data_ingiunzione
                                                        ,w_giorni_anno
                                                        ,rec_prat.tipo_tributo
                                                        );
     w_giorni_interessi := w_data_ingiunzione - w_data_inizio_interessi + 1;
      if w_giorni_interessi_tot is null then
         w_giorni_interessi_tot := w_giorni_interessi;
      else
         w_giorni_interessi_tot := 0;
      end if;
      w_note := w_note||'Pratica '||to_char(rec_prat.pratica)
                      ||': '||round(w_interesse_pratica,2)
                      ||' per '||to_char(w_giorni_interessi)||' - ';
      w_interessi := w_interessi + round(w_interesse_pratica,2);
   END LOOP;
   if w_interessi > 0 then
      if w_giorni_interessi_tot = 0 then
         w_giorni_interessi_tot := null;
      end if;
      BEGIN
         insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo
               ,giorni,note
               ,importo,utente,data_variazione)
        values (a_pratica,299,w_tipo_tributo
               ,w_giorni_interessi_tot,w_note
               ,w_interessi,a_utente,trunc(sysdate))
                ;
      EXCEPTION
         WHEN others THEN
            sql_errm := substr(SQLERRM,1,100);
            RAISE_APPLICATION_ERROR
           (-20999,'Errore in inserimento Sanzioni Pratica (299) '||
                     '('||sql_errm||')');
      END;
   end if;
   commit;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: CALCOLO_SANZIONI_INGIUNZIONE */
/

