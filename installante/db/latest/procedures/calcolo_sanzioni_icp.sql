--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_icp stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_ICP
(a_cod_fiscale          IN varchar2,
 a_anno                 IN number,
 a_pratica              IN number,
 a_oggetto_pratica      IN number,
 a_imposta              IN number,
 a_anno_denuncia        IN number,
 a_data_denuncia        IN date,
 a_imposta_dichiarata   IN number,
 a_importo_versato      IN number,
 a_nuovo_sanzionamento  IN varchar2,
 a_utente               IN varchar2,
 a_interessi_dal        IN date,
 a_interessi_al         IN date,
 a_gestione_versamenti  IN varchar2)
IS
C_TIPO_TRIBUTO     CONSTANT varchar2(3) := 'ICP';
C_TASSA_EVASA      CONSTANT number := 1;
C_OMESSA_DEN       CONSTANT number := 2;
C_INFEDELE_DEN     CONSTANT number := 3;
C_TARD_DEN_INF_30  CONSTANT number := 4;
C_TARD_DEN_SUP_30  CONSTANT number := 5;
C_NUOVO            CONSTANT number := 100;
w_data_scadenza    date;
w_cod_sanzione     number;
w_maggiore_imposta number;
w_importo          number;
w_importo_min      number := 500000;
w_return           number;
w_errore           varchar2(2000);
errore             exception;
BEGIN    --CALCOLO_SANZIONI_ICP
  BEGIN
    delete sanzioni_pratica
     where pratica          = a_pratica
       and oggetto_pratica    = a_oggetto_pratica
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
  IF a_anno = a_anno_denuncia THEN
     w_data_scadenza := f_scadenza_denuncia(C_TIPO_TRIBUTO,a_anno_denuncia);
     IF to_number(a_data_denuncia - w_data_scadenza) > 60 THEN
           w_cod_sanzione := C_TARD_DEN_SUP_30;
           inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
           w_cod_sanzione := C_TARD_DEN_SUP_30 + C_NUOVO;
           inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
     ELSIF to_number(a_data_denuncia - w_data_scadenza) > 30 THEN
           w_cod_sanzione := C_TARD_DEN_INF_30;
           inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
           w_cod_sanzione := C_TARD_DEN_INF_30 + C_NUOVO;
           inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente);
     END IF;
  END IF;
  if a_gestione_versamenti = 'S' then
     inserimento_sanzione_vers(a_cod_fiscale,a_anno,a_pratica, a_oggetto_pratica, a_imposta,
                               a_imposta_dichiarata, a_anno_denuncia, NULL,C_TIPO_TRIBUTO, a_utente);
  end if;
  IF a_interessi_dal is not null THEN
    IF w_maggiore_imposta = 0 THEN
        w_importo := a_imposta;
    ELSE
        w_importo := w_maggiore_imposta;
    END IF;
      inserimento_interessi(a_pratica,a_oggetto_pratica,a_interessi_dal,a_interessi_al,w_importo,C_TIPO_TRIBUTO,'S',a_utente);
  END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
     (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
     (-20999,'Errore durante il Calcolo Sanzioni '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_SANZIONI_ICP */
/

