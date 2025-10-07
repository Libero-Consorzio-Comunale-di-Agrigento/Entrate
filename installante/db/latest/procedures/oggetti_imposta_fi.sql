--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_imposta_fi stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_IMPOSTA_FI
(a_cod_fiscale      IN   varchar2,
 a_anno         IN    number,
 a_oggetto_pratica_old   IN   number,
 a_oggetto_pratica_new   IN   number,
 a_imposta_old      IN    number,
 a_imposta_new      IN      number,
 a_imposta_dovuta_old   IN    number,
 a_imposta_dovuta_new   IN      number)
IS
w_pratica      number;
w_imposta_totale   number;
w_imposta_dovuta_totale   number;
sql_errm      varchar2(200);
BEGIN
  BEGIN
    select prtr.pratica,nvl(imposta_totale,0),nvl(imposta_dovuta_totale,0)
      into w_pratica,w_imposta_totale,w_imposta_dovuta_totale
      from pratiche_tributo prtr,oggetti_pratica ogpr
     where prtr.pratica      = ogpr.pratica
       and prtr.tipo_pratica    in ('A','I','L','V','S')
       and prtr.anno      = a_anno
       and ogpr.oggetto_pratica   = nvl(a_oggetto_pratica_new,a_oggetto_pratica_old)
    ;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca Pratiche Tributo');
  END;
  IF w_pratica is not null THEN
    w_imposta_totale      := w_imposta_totale - nvl(a_imposta_old,0) + nvl(a_imposta_new,0);
    w_imposta_dovuta_totale   := w_imposta_dovuta_totale -
                    nvl(a_imposta_dovuta_old,nvl(a_imposta_old,0)) +
               nvl(a_imposta_dovuta_new,nvl(a_imposta_new,0));
  BEGIN
      update pratiche_tributo
         set imposta_totale      = w_imposta_totale,
        imposta_dovuta_totale   = w_imposta_dovuta_totale
       where pratica = w_pratica
      ;
    EXCEPTION
      WHEN others THEN
        sql_errm := substr(SQLERRM,12,200);
        RAISE_APPLICATION_ERROR
          (-20999,sql_errm);
    END;
  END IF;
END;
/* End Procedure: OGGETTI_IMPOSTA_FI */
/

