--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_primo_erede_cod_fiscale stripComments:false runOnChange:true 
 
create or replace function F_PRIMO_EREDE_COD_FISCALE
( A_NI        IN number
)
RETURN varchar2
is
ritorno varchar2(16);
BEGIN
   select nvl(sogg.cod_fiscale,sogg.partita_iva)
     into ritorno
     from soggetti        sogg
        , eredi_soggetto  erso
    where erso.ni = a_ni
      and erso.ni_erede = sogg.ni
      and lpad(to_char(erso.numero_ordine),3,'0')
        ||lpad(to_char(erso.ni_erede),11,'0') =
                               ( select min(lpad(to_char(nvl(erso2.numero_ordine,999)),3,'0')
                                          ||lpad(to_char(erso2.ni_erede),11,'0'))
                                   from eredi_soggetto erso2
                                  where erso2.ni = a_ni
                               )
    ;
   RETURN  ritorno;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RETURN null;
   WHEN OTHERS THEN
        RETURN null;
END;
/* End Function: F_PRIMO_EREDE_COD_FISCALE */
/

