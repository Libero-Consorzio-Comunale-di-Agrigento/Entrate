--liquibase formatted sql 
--changeset abrandolini:20250326_152423_scadenze_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE SCADENZE_DI
(a_tipo_scadenza   IN   varchar2,
 a_rata         IN   number,
 a_tipo_versamento   IN    varchar2)
IS
BEGIN
  IF a_tipo_scadenza = 'D' and (a_rata is not null or a_tipo_versamento is not null)
     or
     a_tipo_scadenza in ('V','T') and a_rata is null and a_tipo_versamento is null
     or
     a_tipo_scadenza in ('V','T') and a_rata is not null and a_tipo_versamento is not null
  THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Tipo scadenza e rata-tipo versamento non coerenti');
  END IF;
END;
/* End Procedure: SCADENZE_DI */
/

