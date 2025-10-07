--liquibase formatted sql 
--changeset abrandolini:20250326_152401_sgravi_oggetto stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW SGRAVI_OGGETTO AS
SELECT sgra.ruolo,
 sgra.cod_fiscale,
 sgra.sequenza,
 sgra.sequenza_sgravio,
 sgra.motivo_sgravio,
 sgra.numero_elenco,
 sgra.data_elenco,
 sgra.importo,
 sgra.importo - nvl(sgra.addizionale_eca,0)
  - nvl(sgra.maggiorazione_eca,0)
  - nvl(sgra.addizionale_pro,0)
  - nvl(sgra.iva,0)
  - nvl(sgra.maggiorazione_tares,0) NETTO_SGRAVI,
 sgra.semestri,
 sgra.addizionale_eca,
 sgra.maggiorazione_eca,
 sgra.addizionale_pro,
 sgra.iva,
 sgra.maggiorazione_tares,
 ruco.importo IMPORTO_LORDO,
 0 IMPOSTA,
 ruco.da_mese da_mese_ruco,
 ruco.a_mese  a_mese_ruco,
 sgra.da_mese da_mese_sgra,
 sgra.a_mese  a_mese_sgra,
 sgra.tipo_sgravio,
 ruco.giorni_ruolo,
 sgra.giorni_sgravio,
 sgra.importo_base,
 sgra.importo_base - nvl(sgra.addizionale_eca_base,0)
    - nvl(sgra.maggiorazione_eca_base,0)
    - nvl(sgra.addizionale_pro_base,0)
    - nvl(sgra.iva_base,0) NETTO_SGRAVI_BASE
  FROM ruoli  ruol,
 ruoli_contribuente ruco,
 sgravi sgra
 where ruol.ruolo   = ruco.ruolo
   and sgra.ruolo   = ruco.ruolo
   and sgra.cod_fiscale   = ruco.cod_fiscale
   and sgra.sequenza   = ruco.sequenza
   and ruco.oggetto_imposta is null
 UNION ALL
/* Caso di Ruoli Contribuente con Oggetto Imposta */
SELECT sgra.ruolo,
 sgra.cod_fiscale,
 sgra.sequenza,
 sgra.sequenza_sgravio,
 sgra.motivo_sgravio,
 sgra.numero_elenco,
 sgra.data_elenco,
 sgra.importo,
 sgra.importo - nvl(sgra.addizionale_eca,0)
  - nvl(sgra.maggiorazione_eca,0)
  - nvl(sgra.addizionale_pro,0)
  - nvl(sgra.iva,0)
  - nvl(sgra.maggiorazione_tares,0),
 sgra.semestri,
 sgra.addizionale_eca,
 sgra.maggiorazione_eca,
 sgra.addizionale_pro,
 sgra.iva,
 sgra.maggiorazione_tares,
 ruco.importo,
 ogim.imposta,
 ruco.da_mese da_mese_ruco,
 ruco.a_mese  a_mese_ruco,
 sgra.da_mese da_mese_sgra,
 sgra.a_mese  a_mese_sgra,
 sgra.tipo_sgravio,
 ruco.giorni_ruolo,
 sgra.giorni_sgravio,
 sgra.importo_base,
 sgra.importo_base - nvl(sgra.addizionale_eca_base,0)
    - nvl(sgra.maggiorazione_eca_base,0)
    - nvl(sgra.addizionale_pro_base,0)
    - nvl(sgra.iva_base,0) NETTO_SGRAVI_BASE
  FROM oggetti_imposta ogim,
 ruoli  ruol,
 ruoli_contribuente ruco,
 sgravi sgra
 where ruol.ruolo   = ruco.ruolo
   and sgra.ruolo   = ruco.ruolo
   and sgra.cod_fiscale   = ruco.cod_fiscale
   and sgra.sequenza   = ruco.sequenza
   and ogim.oggetto_imposta  = ruco.oggetto_imposta;
comment on table SGRAVI_OGGETTO is 'SGOG - Sgravi relativi all''oggetto';

