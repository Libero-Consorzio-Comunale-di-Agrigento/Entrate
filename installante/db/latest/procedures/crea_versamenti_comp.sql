--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_versamenti_comp stripComments:false runOnChange:true 
 
create or replace procedure CREA_VERSAMENTI_COMP
( a_tipo_tributo   in varchar2
 ,a_anno           in number
 ,a_cod_fiscale    in varchar2
 ,a_fonte          in number
 ,a_motivo         in number
 ,a_utente         in varchar2
 ,a_num_vers       out number
)
is
  w_data_pagamento   versamenti.data_pagamento%type;
  w_ufficio_pt       versamenti.ufficio_pt%type;
/******************************************************************************
crea i record di versamenti per le compensazioni
Il codice fiscale può essere assegnato con la %
******************************************************************************/
begin
  a_num_vers := 0;
  for comp in (select id_compensazione, cod_fiscale, tipo_tributo, anno
                    , motivo_compensazione, compensazione, note
                 from compensazioni
                where tipo_tributo = a_tipo_tributo
                  and anno = a_anno
                  and cod_fiscale like a_cod_fiscale
                  and motivo_compensazione = a_motivo) loop
    -- cancellazione versamenti già inseriti (se esistono)
    delete versamenti
     where id_compensazione = comp.id_compensazione
    ;
    -- determinazione della data di versamento come ultimo versamento
    -- dell'anno precedente la compensazione
    begin
      select ufficio_pt,nvl(data_pagamento,to_date('01/01/'||comp.anno,'dd/mm/yyyy'))
      into   w_ufficio_pt,w_data_pagamento
      from   versamenti
      where  cod_fiscale = comp.cod_fiscale
      and    anno = comp.anno -1
      and    rownum = 1
      and    data_pagamento = (select max(data_pagamento)
                               from   versamenti
                               where  cod_fiscale = comp.cod_fiscale
                               and    anno = comp.anno -1)
      ;
    exception
      when no_data_found
      then w_ufficio_pt := null;
           w_data_pagamento := to_date('01/01/'||comp.anno,'dd/mm/yyyy');
    end;
    -- inserimento versamento anno precedente
    insert into versamenti (cod_fiscale, anno, tipo_tributo, rata
                           , descrizione, data_pagamento, importo_versato
                           , ufficio_pt, fonte
                           , utente, data_variazione, note, data_reg
                           , id_compensazione)
    values (comp.cod_fiscale,comp.anno -1, comp.tipo_tributo, 0
           , 'VERSAMENTO A COMPENSAZIONE',w_data_pagamento, comp.compensazione * -1
           , w_ufficio_pt, a_fonte
           , a_utente, trunc(sysdate), comp.note, trunc(sysdate)
           , comp.id_compensazione)
    ;
    -- inserimento versamento anno corrente
    insert into versamenti (cod_fiscale, anno, tipo_tributo, rata
                           , descrizione, data_pagamento, importo_versato
                           , ufficio_pt, fonte
                           , utente, data_variazione, note, data_reg
                           , id_compensazione)
    values (comp.cod_fiscale,comp.anno, comp.tipo_tributo, 1
           , 'VERSAMENTO A COMPENSAZIONE',w_data_pagamento, comp.compensazione
           , w_ufficio_pt, a_fonte
           , a_utente, trunc(sysdate), comp.note, trunc(sysdate)
           , comp.id_compensazione)
    ;
    a_num_vers := a_num_vers + 2;
    commit;
  end loop;
END;
/* End Procedure: CREA_VERSAMENTI_COMP */
/

