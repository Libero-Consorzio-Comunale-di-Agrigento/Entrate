--liquibase formatted sql 
--changeset abrandolini:20250326_152423_pratiche_tributo_di stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE PRATICHE_TRIBUTO_DI
(a_pratica      IN   number,
 a_tipo_pratica      IN   varchar2,
 a_data         IN   date,
 a_data_notifica   IN   date,
 a_flag_annullamento   IN   varchar2,
 a_note         IN   varchar2,
 a_chiamante            IN      varchar2 default NULL)
IS
w_data_pagamento date;
BEGIN
  IF INSERTING OR UPDATING or nvl(a_chiamante,'TR4') = 'WEB' THEN
     IF a_tipo_pratica in ('A','I','L') THEN
        IF nvl(a_data_notifica,to_date('31/12/9999','dd/mm/yyyy')) <
           nvl(a_data,to_date('01/01/1800','dd/mm/yyyy')) THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Data di notifica minore della data della pratica');
        END IF;
     END IF;
     IF nvl(a_data,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data della pratica maggiore della data odierna');
     END IF;
     IF nvl(a_data_notifica,to_date('01/01/1800','dd/mm/yyyy')) > sysdate THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Data notifica maggiore della data odierna');
     END IF;
     BEGIN
        select min(data_pagamento)
          into w_data_pagamento
          from versamenti
         where pratica = a_pratica
        ;
     EXCEPTION
        WHEN no_data_found THEN
          null;
        WHEN others THEN
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in ricerca versamenti');
     END;
     IF nvl(a_data_notifica,to_date('01/01/1800','dd/mm/yyyy')) >
        nvl(w_data_pagamento,to_date('31/12/9999','dd/mm/yyyy')) THEN
        RAISE_APPLICATION_ERROR
     (-20999,'Data di notifica maggiore della data di pagamento');
     ELSIF a_data_notifica is null and a_tipo_pratica in ('A','I','L')
       and w_data_pagamento is not null THEN
        RAISE_APPLICATION_ERROR
     (-20999,'Indicare la data di notifica, versamento gia'' presente');
     END IF;
   ELSIF DELETING THEN
     IF a_data_notifica is not null THEN
        RAISE_APPLICATION_ERROR
          (-20999,'Eliminazione non consentita: pratica gia'' notificata');
     END IF;
  END IF;
END;
/* End Procedure: PRATICHE_TRIBUTO_DI */
/

