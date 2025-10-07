--liquibase formatted sql 
--changeset abrandolini:20250326_152423_wrk_versamenti_di stripComments:false runOnChange:true 
 
create or replace procedure WRK_VERSAMENTI_DI
(a_data_pagamento   IN   date,
 a_importo_versato   IN   number,
 a_pratica          IN   number,
 a_rata             IN   number,
 a_tipo_versamento   IN   varchar2)
IS
w_data_notifica      date;
w_tipo_pratica      varchar2(1);
w_tipo_atto         number(2);
BEGIN
  IF (a_data_pagamento is null and a_importo_versato is null)  or
     (a_data_pagamento is not null and a_importo_versato is not null)
  THEN
     null;
  ELSE
     RAISE_APPLICATION_ERROR
       (-20999,'Data di pagamento e importo versato non coerenti');
  END IF;
  IF nvl(a_data_pagamento,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Data di pagamento maggiore della data odierna');
  END IF;
  IF a_pratica is not null THEN
     BEGIN
       select data_notifica,tipo_pratica,tipo_atto
         into w_data_notifica,w_tipo_pratica,w_tipo_atto
         from pratiche_tributo
        where pratica   = a_pratica
       ;
     EXCEPTION
       WHEN no_data_found THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Identificazione '||a_pratica||
         ' non presente in archivio Pratiche Tributo');
     END;
     IF nvl(a_data_pagamento,to_date('31/12/9999','dd/mm/yyyy')) <
        nvl(w_data_notifica,to_date('01/01/1800','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
     (-20999,'Data di pagamento minore della data di notifica');
     ELSIF w_data_notifica is null and w_tipo_pratica in ('A','I','L')
       and a_data_pagamento is not null THEN
        RAISE_APPLICATION_ERROR
     (-20999,'Data di notifica non presente nella pratica');
     END IF;
  END IF;
  IF a_rata is null and a_tipo_versamento is null THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Indicare rata o tipo versamento');
  END IF;
  IF a_rata not in (0,1,2,3,4,11,12,22) and a_pratica is null THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Rata indicata non corretta (Valori validi: 0,1,2,3,4,11,12,22)');
  ELSIF (a_rata not between 0 and 36) and a_pratica is not null THEN
     RAISE_APPLICATION_ERROR
       (-20999,'Rata indicata non corretta (Valori validi: Tra 0 e 36)');
  END IF;
END;
/* End Procedure: WRK_VERSAMENTI_DI */
/

