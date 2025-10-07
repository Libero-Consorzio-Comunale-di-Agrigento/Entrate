--liquibase formatted sql 
--changeset abrandolini:20250326_152423_oggetti_imposta_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE OGGETTI_IMPOSTA_DI
(a_tipo_aliquota   IN   number,
 a_aliquota        IN   number,
 a_oggetto_pratica IN   number,
 a_tipo_tributo    IN OUT  varchar2)
IS
BEGIN
  IF (a_tipo_aliquota is null and a_aliquota is null)  or
     (a_tipo_aliquota is not null and a_aliquota is not null)
  THEN
     null;
  ELSE
     RAISE_APPLICATION_ERROR
       (-20999,'Tipo aliquota e aliquota non coerenti');
  END IF;
  IF a_tipo_tributo is not null
  THEN
     null;
  ELSE
    begin
      select tipo_tributo
        into a_tipo_tributo
        from pratiche_tributo prtr
       where prtr.pratica = (select ogpr.pratica
                               from oggetti_pratica ogpr
                              where ogpr.oggetto_pratica = a_oggetto_pratica)
      ;
    exception
      when others then
--        dbms_output.put_line('Errore su oggetto imposta: '||rec_ogim.oggetto_imposta||' ');
        RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Tipo tributo');
    end;
  END IF;
END;
/* End Procedure: OGGETTI_IMPOSTA_DI */
/

