--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_primo_erede stripComments:false runOnChange:true 
 
create or replace function F_PRIMO_EREDE
( A_NI        IN number
)
RETURN varchar2
is
ritorno varchar2(1000);
BEGIN
   select decode(sogg.cognome_nome,null,'',translate(sogg.cognome_nome,'/',' ')||' - ')
          ||decode(sogg.cod_via,null,sogg.denominazione_via,arvi.denom_uff)
          ||decode(sogg.num_civ,null,'',', '||sogg.num_civ)
          ||decode(sogg.suffisso,null,'','/'||sogg.suffisso )
          ||decode(comu.denominazione,null,'',' '||comu.denominazione)
          ||decode(prov.sigla
                    ,null, ''
                    ,' (' || prov.sigla
                          || decode(prov.sigla
                                   ,null, ''
                                   ,') '
                                   )
                   )
          ||decode(sogg.cod_fiscale,null,'',' C.F.: '||sogg.cod_fiscale)
          ||decode(sogg.partita_iva,null,'',' P. IVA: '|| sogg.partita_iva)
     into ritorno
     from soggetti        sogg
        , eredi_soggetto  erso
        , archivio_vie    arvi
        , ad4_comuni      comu
        , ad4_provincie   prov
    where erso.ni = a_ni
      and erso.ni_erede = sogg.ni
      and comu.provincia_stato = prov.provincia (+)
      and sogg.cod_pro_res     = comu.provincia_stato (+)
      and sogg.cod_com_res     = comu.comune (+)
      and sogg.cod_via         = arvi.cod_via (+)
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
/* End Function: F_PRIMO_EREDE */
/

