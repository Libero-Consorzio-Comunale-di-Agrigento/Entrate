--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_contribuente_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_CONTRIBUENTE_DI
(a_oggetto_pratica      IN    number,
 a_data_decorrenza      IN   date,
 a_data_cessazione      IN   date,
 a_mesi_possesso      IN   number,
 a_mesi_esclusione      IN   number,
 a_mesi_riduzione      IN    number,
 a_mesi_aliquota_ridotta   IN    number,
 a_flag_ab_principale      IN   varchar2
)
IS
w_tipo_oggetto      number;
BEGIN
  BEGIN
    select nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
      into w_tipo_oggetto
      from oggetti ogge,oggetti_pratica ogpr
     where ogge.oggetto           = ogpr.oggetto
       and ogpr.oggetto_pratica = a_oggetto_pratica
    ;
  EXCEPTION
    WHEN others THEN
         RAISE_APPLICATION_ERROR (-20999,'Errore in ricerca Oggetti');
  END;
  IF IntegrityPackage.GetNestLevel = 0 then
     IF a_flag_ab_principale is not null and
        w_tipo_oggetto not in (3,4,5,6) THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Abitazione principale e tipo oggetto non coerenti');
     END IF;
  END IF;
  IF a_data_cessazione < a_data_decorrenza THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Data di cessazione minore della data di decorrenza');
  END IF;
  IF IntegrityPackage.GetNestLevel = 0 then
     IF nvl(a_mesi_possesso,12)
          < (nvl(a_mesi_riduzione,0) + nvl(a_mesi_esclusione,0))
     or
        nvl(a_mesi_possesso,12)
          < nvl(a_mesi_aliquota_ridotta,0)
     THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Mesi possesso non corretti');
     END IF;
  END IF;
END;
/* End Procedure: OGGETTI_CONTRIBUENTE_DI */
/

