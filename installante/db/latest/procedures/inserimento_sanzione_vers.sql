--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione_vers stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE_VERS
(   a_cod_fiscale         IN varchar2,
    a_anno                IN number,
    a_pratica             IN number,
    a_oggetto_pratica     IN number,
    a_imposta             IN number,
    a_imposta_dichiarata  IN number,
    a_anno_denuncia       IN number,
    a_data_concessione    IN date,
    a_tipo_tributo        IN varchar2,
    a_utente              IN varchar2
)
is
    C_OMESSO_VER       CONSTANT number := 6;
    C_INFEDELE_VER     CONSTANT number := 7;
    C_TARD_VER_INF_30  CONSTANT number := 8;
    C_TARD_VER_SUP_30  CONSTANT number := 9;
    C_NUOVO            CONSTANT number := 100;
    C_DIFF_GIORNI      CONSTANT number := 30;
    w_maggiore_imposta          number;
    w_rata                      number;
    w_num_sanz_inf_lim          number;
    w_num_sanz_sup_lim          number;
    w_impo_sanz                 number;
    w_percentuale               number;
    w_sanzione                  number;
    w_sanzione_minima           number;
    w_riduzione                 number;
    w_riduzione_2               number;
    w_cod_sanzione              number;
    w_data_scadenza             date;
    w_data_versamento           date;
    w_impo_versamento           number;
    w_num_versamenti            number;
    w_return                    number;
    w_errore                    varchar2(2000);
    errore                      exception;
  FUNCTION dati_versamento(
     p_cod_fiscale      IN varchar2,
     p_anno             IN number,
     p_rata             IN number,
     p_ogg_pratica      IN number,
     p_tipo_tributo     IN varchar2,
     p_data_versamento  IN OUT date,
     p_impo_versamento  IN OUT number) return number
    IS
    w_importo   number;
    BEGIN   -- dati_versamento
      BEGIN
        select max(vers.data_pagamento),sum(vers.importo_versato)
          into p_data_versamento, w_importo
          from versamenti vers
             , oggetti_imposta ogim
         where ogim.cod_fiscale         = p_cod_fiscale
           and ogim.anno                = p_anno
           and ogim.oggetto_pratica     = p_ogg_pratica
           and ( vers.oggetto_imposta     = ogim.oggetto_imposta
               or vers.oggetto_imposta  is NULL )
           and vers.pratica           is NULL
           and vers.rata                = p_rata
           and vers.anno                = p_anno
           and vers.cod_fiscale         = p_cod_fiscale
           and vers.tipo_tributo        = p_tipo_tributo
      group by 1
        union
        select max(vers.data_pagamento),sum(vers.importo_versato)
          from versamenti vers
             , oggetti_imposta ogim
             , rate_imposta raim
         where ogim.cod_fiscale         = p_cod_fiscale
           and ogim.anno                = p_anno
           and ogim.oggetto_pratica     = p_ogg_pratica
           and raim.cod_fiscale         = p_cod_fiscale
           and raim.anno                = p_anno
           and raim.oggetto_imposta     = ogim.oggetto_imposta
           and ( vers.rata_imposta     = raim.rata_imposta
               or vers.rata_imposta  is NULL )
           and vers.pratica           is NULL
           and vers.rata                = p_rata
           and vers.anno                = p_anno
           and vers.cod_fiscale         = p_cod_fiscale
           and vers.tipo_tributo        = p_tipo_tributo
      group by 1    ;
      EXCEPTION
         WHEN no_data_found THEN
           p_impo_versamento := NULL;
           p_data_versamento := NULL;
              RETURN NULL;
         WHEN others THEN
              RETURN -1;
       END;
       p_impo_versamento := p_impo_versamento + w_importo;
       return 0;
    END dati_versamento;
BEGIN   -- inserimento_sanz_su_vers
  w_num_sanz_inf_lim := 0;
  w_num_sanz_sup_lim := 0;
  w_num_versamenti  := 0;
  w_impo_versamento := 0;
  w_return := dati_versamento(a_cod_fiscale,a_anno,0,a_oggetto_pratica,a_tipo_tributo,
                              w_data_versamento,w_impo_versamento);
   IF w_return < 0 THEN
     w_errore := 'Errore in ricerca Versamenti per rata 0 ('||SQLERRM||')';
     RAISE errore;
   ELSIF w_return = 0 THEN
   -- Il versamento non e' rateizzato
     w_num_versamenti := 1;
     IF (a_anno = a_anno_denuncia) and (a_data_concessione is not NUll) THEN
      w_data_scadenza := a_data_concessione + C_DIFF_GIORNI;
     ELSE
        w_data_scadenza := f_scadenza_rata(a_tipo_tributo,a_anno,0);
     END IF;
     IF (w_data_versamento - w_data_scadenza) > C_DIFF_GIORNI  THEN
           w_num_sanz_sup_lim := 1;
     ELSIF (w_data_versamento - w_data_scadenza) > 0  THEN
           w_num_sanz_inf_lim := 1;
     END IF;
   ELSE
    -- Il versamento e' rateizzato
     FOR w_rata IN 1..4 LOOP
         w_return := dati_versamento(a_cod_fiscale,a_anno,w_rata,a_oggetto_pratica,a_tipo_tributo,
                                     w_data_versamento,w_impo_versamento);
            IF w_return < 0 THEN
               w_errore := 'Errore in ricerca Versamenti per rata '||w_rata||' ('||SQLERRM||')';
            RAISE errore;
          ELSIF w_return = 0 THEN
            w_num_versamenti := w_num_versamenti + 1;
            w_data_scadenza := f_scadenza_rata(a_tipo_tributo,a_anno,w_rata);
            IF (w_data_versamento - w_data_scadenza) > C_DIFF_GIORNI  THEN
                 w_num_sanz_sup_lim := w_num_sanz_sup_lim + 1;
            ELSIF (w_data_versamento - w_data_scadenza) > 0  THEN
                 w_num_sanz_inf_lim := w_num_sanz_inf_lim + 1;
            END IF;
          END IF;
     END LOOP;
   END IF;
   IF w_num_versamenti = 0 THEN
     w_cod_sanzione := C_OMESSO_VER;
     inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,a_imposta,Null,a_utente);
     w_cod_sanzione := C_OMESSO_VER + C_NUOVO;
     inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,a_imposta,Null,a_utente);
   ELSE
     w_maggiore_imposta := a_imposta - a_imposta_dichiarata;
      IF w_impo_versamento < a_imposta_dichiarata THEN
         w_cod_sanzione := C_INFEDELE_VER;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_inf_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
         w_cod_sanzione := C_INFEDELE_VER  + C_NUOVO;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_inf_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
      END IF;
      IF w_num_sanz_inf_lim > 0 THEN
         w_cod_sanzione := C_TARD_VER_INF_30;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_inf_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
         w_cod_sanzione := C_TARD_VER_INF_30  + C_NUOVO;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_inf_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
      END IF;
      IF w_num_sanz_sup_lim > 0 THEN
         w_cod_sanzione := C_TARD_VER_SUP_30;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_sup_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
         w_cod_sanzione := C_TARD_VER_SUP_30  + C_NUOVO;
         w_impo_sanz := f_importo_sanzione(w_cod_sanzione,a_tipo_tributo,w_maggiore_imposta,w_percentuale,w_riduzione,w_riduzione_2);
         IF w_impo_sanz > 0 THEN
            w_impo_sanz := w_impo_sanz * w_num_sanz_sup_lim;
            inserimento_sanzione(w_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,NULL,w_impo_sanz,a_utente);
         END IF;
      END IF;
   END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,'Errore durante l''inserimento di Sanzioni su Versamento'||'('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_SANZIONE_VERS */
/

