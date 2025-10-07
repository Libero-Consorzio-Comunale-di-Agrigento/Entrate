--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_web_calcolo_imposta stripComments:false runOnChange:true 
 
create or replace function F_WEB_CALCOLO_IMPOSTA
/*************************************************************************
 NOME:        F_WEB_CALCOLO_IMPOSTA
 DESCRIZIONE: TributiWeb: esegue il calcolo imposta.
 PARAMETRI:
 RITORNA:     varchar2            OK se l'elaborazione si conclude senza
                                  errori.
 NOTE:
 Rev.    Date         Author      Note
 001     29/04/2021   VD          In caso di IMU o TASI e multiselezione di
                                  più contribuenti esegue le procedure
                                  CALCOLO_IMPOSTA_ICI_NOME o
                                  CALCOLO_IMPOSTA_TASI_NOME.
 000     XX/XX/XXXX   XX          Prima emissione.
*************************************************************************/
(a_anno                    number   default null
,a_cod_fiscale             varchar2 default null
,a_tipo_tributo            varchar2 default null
,a_ogpr                    number   default null
,a_utente                  varchar2 default null
,a_flag_normalizzato       char     default null
,a_flag_richiamo           varchar2 default null
,a_chk_rate                number   default null
,a_limite                  number   default null
,a_cognome_nome            varchar2 default null)
return varchar2
is
   ret                     varchar2 (2000);
begin
   ret:='OK';
   if a_cod_fiscale = '%' and
      a_cognome_nome <> '%' then
      case a_tipo_tributo
        when 'ICI' then
          CALCOLO_IMPOSTA_ICI_NOME ( a_anno, a_cognome_nome, a_utente );
        when 'TASI' then
          CALCOLO_IMPOSTA_TASI_NOME ( a_anno, a_cognome_nome, a_utente );
        else
          null;
      end case;
   else
      CALCOLO_IMPOSTA ( a_anno, a_cod_fiscale, a_tipo_tributo, a_ogpr, a_utente, a_flag_normalizzato, a_flag_richiamo, a_chk_rate, a_limite );
   end if;
   commit;
   return ret;
exception
   when others then
     raise_application_error(-20999,'Errore in calcolo imposta '|| ' ('||sqlerrm||')');
end;
/* End Function: F_WEB_CALCOLO_IMPOSTA */
/

