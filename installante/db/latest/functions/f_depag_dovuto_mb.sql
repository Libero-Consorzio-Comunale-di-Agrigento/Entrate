--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_depag_dovuto_mb stripComments:false runOnChange:true 
 
create or replace function F_DEPAG_DOVUTO_MB
/*************************************************************************
 NOME:        F_DEPAG_DOVUTO_MB

 DESCRIZIONE: Integrazione TR4/DEPAG.
              Dato il tipo tributo, anno e data emissione di ruolo o pratica
              determina se si tratta di dovuto MB.

 RITORNA:     string              'S' : richiede 'MB'
                                  null : non richiede 'MB'

 Rev.    Date         Author      Note
 000     22/01/2024   RV          Prima emissione
*************************************************************************/
(a_tipo_tributo            in varchar2
,a_anno                    in number
,a_data                    in date
)
RETURN varchar2
IS
 w_mb_anno           number;
 w_mb_data           date;
 --
 w_mb                varchar2(2);
 --
BEGIN
  --
  w_mb := null;
  --
  if a_tipo_tributo = 'TARSU' then
    begin
       select to_number(nvl(f_inpa_valore('MB_ANNO'),9999)),
              to_date(nvl(f_inpa_valore('MB_DATA'),'01/01/2999'),'DD/MM/YYYY')
         into w_mb_anno,w_mb_data
         from dual;
    exception
       when others then
         w_mb_anno := 9999;
         w_mb_data := TO_DATE('01/01/2099','DD/MM/YYYY');
    end;
    --
  --dbms_output.put_line('MB - Anno:'|| w_mb_anno ||', data: '|| w_mb_data);
    --
    if nvl(a_anno,1999) >= w_mb_anno then
      if nvl(a_data,to_date('01/01/1999','dd/mm/yyyy')) >= w_mb_data then
            w_mb := 'S';
      end if;
    end if;
    --
  end if ;
  --
  return w_mb;
  --
END;
/* End Function: F_DEPAG_DOVUTO_MB */
/
