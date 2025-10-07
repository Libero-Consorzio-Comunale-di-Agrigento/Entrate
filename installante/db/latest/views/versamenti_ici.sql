--liquibase formatted sql 
--changeset abrandolini:20250326_152401_versamenti_ici stripComments:false runOnChange:true 
 
create or replace force view versamenti_ici as
select vers.cod_fiscale,
       max(vers.anno) anno,
       nvl(sum(vers.importo_versato),0) importo_versato,
       nvl(sum(decode(vers.tipo_versamento,
                      'A',vers.importo_versato,
                      'U',vers.importo_versato,
                          decode(sign(vers.data_pagamento - scad.data_scadenza),
                                 1,0,
             vers.importo_versato))),
            0) importo_versato_acconto
   from scadenze scad,versamenti vers
  where scad.tipo_tributo      = vers.tipo_tributo
    and scad.anno       = vers.anno
    and scad.tipo_scadenza    = 'V'
    and scad.tipo_versamento    = 'A'
    and vers.pratica      is null
    and vers.tipo_tributo||''    = 'ICI'
  group by vers.cod_fiscale;
comment on table VERSAMENTI_ICI is 'VEIC - Versamenti ICI per Contribuente';

