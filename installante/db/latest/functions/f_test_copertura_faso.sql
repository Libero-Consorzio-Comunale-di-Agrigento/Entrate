--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_test_copertura_faso stripComments:false runOnChange:true 
 
create or replace function F_TEST_COPERTURA_FASO
(p_ni                      number
,p_data_da                 date
,p_data_a                  date
,p_anno                    number default NULL )
return VARCHAR2
is
-- funzione per controllare che nel periodo compreso fra le date assegnate
-- il contribuente abbia sempre i familiari
-- se il periodo è corretto ritorna 'S' altrimenti 'N'
--
-- AB       - 01/06/2023  Ho aggiunto l'anno come ultimo parametro, per fare
--                        lo stesso controllo che abbiamo in emissione_ruolo
-- VDavalli - 13/03/2015: Modificata gestione data AL: se l'anno della data AL
--                        e' 9999, si considera anno = 9000, per evitare che
--                        sommando 1 alla data si verifichi l'errore Oracle
--
w_ritorno        varchar2(2);
w_data_al        date;
w_primo_giro     boolean;
begin
  w_primo_giro := true;
  w_data_al    := to_date('01/01/1900','dd/mm/yyyy');
  w_ritorno    := 'S';
  for faso in (select dal
                    , decode(faso.al,null,to_date('31/12'||faso.anno,'dd/mm/yyyy')
                            ,decode(to_number(to_char(faso.al,'yyyy'))
                                   ,9999,to_date(to_char(faso.al,'dd/mm')||9000,'dd/mm/yyyy')
                                   ,faso.al)) al
                    , numero_familiari
               from   familiari_soggetto faso
               where  ni = p_ni
               and    p_data_a >= faso.dal
               and    p_data_da <= nvl(faso.al,to_date('31/12'||faso.anno,'dd/mm/yyyy'))
               and    faso.anno = nvl(p_anno,faso.anno)
               order by dal,al) loop
    if w_primo_giro then
       if p_data_da not between faso.dal and faso.al then
          w_ritorno := 'N';
       end if;
       w_data_al := faso.al;
       w_primo_giro := false;
    elsif w_data_al + 1 = faso.dal then
       w_data_al := faso.al;
    else
       w_ritorno := 'N';
    end if;
  end loop;
  if p_data_a > w_data_al then
     w_ritorno := 'N';
  end if;
  return w_ritorno;
end;
/* End Function: F_TEST_COPERTURA_FASO */
/

