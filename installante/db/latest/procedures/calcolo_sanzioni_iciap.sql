--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_iciap stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_ICIAP
(a_anno         IN number,
 a_data_accertamento   IN date,
 a_pratica      IN number,
 a_oggetto_pratica   IN number,
 a_imposta      IN number,
 a_imposta_dichiarata   IN number,
 a_importo_versato   IN number,
 a_nuovo_sanzionamento   IN varchar2,
 a_utente      IN varchar2
)
IS
 C_TIPO_TRIBUTO      CONSTANT varchar2(5) := 'ICIAP';
 C_TASSA_EVASA      CONSTANT number := 1;
 C_OMESSA_DEN      CONSTANT number := 32;
 C_INFEDELE_DEN      CONSTANT number := 34;
 C_OMESSO_INF_VER   CONSTANT number := 33;
 C_INTERESSI      CONSTANT number := 99;
 C_NUOVO      CONSTANT number := 100;
 w_data_scadenza   date;
 w_cod_sanzione      number;
 w_maggiore_imposta   number;
 w_importo      number;
 w_num_giorni      number;
 w_num_anni      number;
 w_errore      varchar2(2000);
 errore         exception;
 CURSOR sel_periodo (p_titr varchar2, p_dal date, p_al date)
 IS
     SELECT ALIQUOTA, GREATEST(data_inizio,p_dal) DAL, LEAST(data_fine,p_al) AL
       FROM INTERESSI
      WHERE TIPO_TRIBUTO = p_titr
   AND DATA_INIZIO <= p_dal
   AND DATA_FINE    > p_dal
     UNION
     SELECT ALIQUOTA, GREATEST(data_inizio,p_dal) DAL, LEAST(data_fine,p_al) AL
       FROM INTERESSI
      WHERE TIPO_TRIBUTO = p_titr
   AND DATA_INIZIO  < p_al
   AND DATA_FINE   >= p_al
     UNION
     SELECT ALIQUOTA, GREATEST(data_inizio,p_dal) DAL, LEAST(data_fine,p_al) AL
       FROM INTERESSI
      WHERE TIPO_TRIBUTO = p_titr
   AND DATA_INIZIO  > p_dal
   AND DATA_FINE    < p_al
      ORDER BY 2,3
     ;
 PROCEDURE data_scadenza_vers
    ( p_anno IN number,
      p_tipo_trib IN varchar2,
      p_tipo_vers IN varchar2,
      p_data_scad IN OUT date)
 IS
 BEGIN
    select data_scadenza
          into p_data_scad
     from scadenze
    where anno      = p_anno
      and tipo_tributo   = p_tipo_trib
      and tipo_versamento   = p_tipo_vers
      and tipo_scadenza   = 'V'
        ;
 EXCEPTION
    WHEN no_data_found THEN
           IF p_tipo_vers = 'U' THEN
      w_errore := 'Manca la data scadenza versamento unico per l''anno indicato ('||SQLERRM||')';
           ELSIF p_tipo_vers = 'A' THEN
      w_errore := 'Manca la data scadenza dell''acconto per l''anno indicato ('||SQLERRM||')';
           ELSE
      w_errore := 'Manca la data scadenza del saldo per l''anno indicato ('||SQLERRM||')';
           END IF;
           RAISE errore;
    WHEN others THEN
           IF p_tipo_vers = 'U' THEN
      w_errore := 'Errore in ricerca Scadenze (Unico) ('||SQLERRM||')';
           ELSIF p_tipo_vers = 'A' THEN
      w_errore := 'Errore in ricerca Scadenze (Acconto) ('||SQLERRM||')';
           ELSE
      w_errore := 'Errore in ricerca Scadenze (Saldo) ('||SQLERRM||')';
           END IF;
           RAISE errore;
 END data_scadenza_vers;
BEGIN   --CALCOLO_SANZIONI_ICIAP
  BEGIN
    delete sanzioni_pratica
     where pratica         = a_pratica
    ;
  EXCEPTION
    WHEN others THEN
        RAISE_APPLICATION_ERROR
      (-20999,'Errore in cancellazione Sanzioni Pratica');
  END;
  IF a_imposta < nvl(a_imposta_dichiarata,0) THEN
     w_errore := 'Importo accertato minore rispetto a quello dichiarato';
     RAISE errore;
  END IF;
  w_maggiore_imposta := a_imposta - nvl(nvl(a_importo_versato,a_imposta_dichiarata),0);
  w_cod_sanzione := C_TASSA_EVASA;
  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente);
  w_cod_sanzione := C_TASSA_EVASA + C_NUOVO;
  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente);
  IF nvl(a_imposta_dichiarata,0) = 0 THEN
  --Omessa
    w_cod_sanzione := C_OMESSA_DEN;
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
    w_cod_sanzione := C_OMESSA_DEN + C_NUOVO;
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
  ELSE
  --Infedele
    w_cod_sanzione := C_INFEDELE_DEN;
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
    w_cod_sanzione := C_INFEDELE_DEN + C_NUOVO;
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
  END IF;
  w_maggiore_imposta := a_imposta - nvl(a_importo_versato,0);
  IF w_maggiore_imposta > 0 THEN
     w_cod_sanzione := C_OMESSO_INF_VER;
     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
     w_cod_sanzione := w_cod_sanzione + C_NUOVO;
     inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
  END IF;
  IF w_maggiore_imposta = 0 THEN
      w_importo := a_imposta;
  ELSE
      w_importo := w_maggiore_imposta;
  END IF;
  data_scadenza_vers(a_anno,C_TIPO_TRIBUTO,'U',w_data_scadenza);
  w_maggiore_imposta := 0;
  FOR rec_periodo IN sel_periodo (C_TIPO_TRIBUTO, w_data_scadenza, a_data_accertamento)
  LOOP
-- Per avere l'importo degli interessi occorre dividere i giorni su cui effettuare i calcolo
-- per tutti i gioni degli anni coperti dal periodo d'interesse e moltiplicare il risultato
-- per il numero di anno compresi nel periodo.
-- Ad Es. sia il periodo dal 12/5/95 a 15/8/97 allora avremo 827 giorni su cui effetuare il calcolo;
-- il numero di giorni costituenti gli anni interessati ( 1/1/95 - 31/12/97) sono 1096 (il '96 e' bisestile)
-- Quindi per avere il giusto conteggio degli interessi per ogni anno occorre fare 827/1096 * 3
-- Dove 3 e' il numero degli anni compresi nel periodo
      w_num_anni   := to_char(rec_periodo.al,'yyyy') - to_char(rec_periodo.dal,'yyyy') + 1;
      w_num_giorni := to_date('3112'||to_char(rec_periodo.al,'yyyy'),'ddmmyyyy')
          - to_date('0101'||to_char(rec_periodo.dal,'yyyy'),'ddmmyyyy') + 1;
      w_maggiore_imposta    := f_round((w_importo * (rec_periodo.al - rec_periodo.dal + 1) * rec_periodo.aliquota / 100)
               * w_num_anni / w_num_giorni,0)
                          + nvl(w_maggiore_imposta,0);
  END LOOP;
  w_cod_sanzione := C_INTERESSI;
  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente);
  w_cod_sanzione := w_cod_sanzione + C_NUOVO;
  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente);
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,w_errore,TRUE);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,'Errore durante il Calcolo Sanzioni '||'('||SQLERRM||')',TRUE);
END;
/* End Procedure: CALCOLO_SANZIONI_ICIAP */
/

