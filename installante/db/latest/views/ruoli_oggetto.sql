--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ruoli_oggetto stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW RUOLI_OGGETTO AS
SELECT ruoli_contribuente.ruolo, ruoli_contribuente.cod_fiscale,
 ruoli_contribuente.sequenza, ruoli_contribuente.pratica,
 ruoli.anno_ruolo, ruoli.tipo_tributo, ruoli_contribuente.tributo,
 ruoli_contribuente.consistenza, ruoli_contribuente.importo,
 ruoli_contribuente.importo_base, ruoli_contribuente.semestri,
 ruoli_contribuente.decorrenza_interessi,
 ruoli_contribuente.mesi_ruolo, ruoli_contribuente.data_cartella,
 ruoli_contribuente.numero_cartella, ruoli_contribuente.utente,
 ruoli_contribuente.data_variazione, ruoli_contribuente.note,
 oggetti_pratica.oggetto, oggetti_pratica.oggetto_pratica,
 oggetti_pratica.categoria, oggetti_pratica.tipo_tariffa,
 oggetti_imposta.oggetto_imposta, oggetti_imposta.imposta,
 oggetti_imposta.addizionale_eca, oggetti_imposta.maggiorazione_eca,
 oggetti_imposta.addizionale_pro, oggetti_imposta.iva,
 oggetti_imposta.maggiorazione_tares,
 ruoli.importo_lordo,
 ruoli_contribuente.da_mese, ruoli_contribuente.a_mese,
 ruoli_contribuente.giorni_ruolo,
 oggetti_imposta.imposta_base,
 oggetti_imposta.addizionale_eca_base, oggetti_imposta.maggiorazione_eca_base,
 oggetti_imposta.addizionale_pro_base, oggetti_imposta.iva_base
  FROM oggetti_imposta, oggetti_pratica, ruoli, ruoli_contribuente
 WHERE ruoli.ruolo = ruoli_contribuente.ruolo
   AND oggetti_imposta.oggetto_imposta = ruoli_contribuente.oggetto_imposta
   AND oggetti_imposta.oggetto_pratica = oggetti_pratica.oggetto_pratica
   UNION
   SELECT ruoli_contribuente.ruolo, ruoli_contribuente.cod_fiscale,
 ruoli_contribuente.sequenza, ruoli_contribuente.pratica,
 ruoli.anno_ruolo, ruoli.tipo_tributo, ruoli_contribuente.tributo,
 ruoli_contribuente.consistenza, ruoli_contribuente.importo,
 ruoli_contribuente.importo_base, ruoli_contribuente.semestri,
 ruoli_contribuente.decorrenza_interessi,
 ruoli_contribuente.mesi_ruolo, ruoli_contribuente.data_cartella,
 ruoli_contribuente.numero_cartella, ruoli_contribuente.utente,
 ruoli_contribuente.data_variazione, ruoli_contribuente.note,
 oggetti_pratica.oggetto, oggetti_pratica.oggetto_pratica,
 oggetti_pratica.categoria, oggetti_pratica.tipo_tariffa,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), importo_lordo,
 ruoli_contribuente.da_mese, ruoli_contribuente.a_mese,
 ruoli_contribuente.giorni_ruolo,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER ('')
  FROM oggetti_pratica, ruoli, ruoli_contribuente
 WHERE ruoli.ruolo = ruoli_contribuente.ruolo
   AND oggetti_pratica.pratica = ruoli_contribuente.pratica
   AND 1 = (SELECT COUNT (*)
  FROM oggetti_pratica ogpr
 WHERE ogpr.pratica = ruoli_contribuente.pratica)
   UNION
   SELECT ruoli_contribuente.ruolo, ruoli_contribuente.cod_fiscale,
 ruoli_contribuente.sequenza, ruoli_contribuente.pratica,
 ruoli.anno_ruolo, ruoli.tipo_tributo, ruoli_contribuente.tributo,
 ruoli_contribuente.consistenza, ruoli_contribuente.importo,
 ruoli_contribuente.importo_base, ruoli_contribuente.semestri,
 ruoli_contribuente.decorrenza_interessi,
 ruoli_contribuente.mesi_ruolo, ruoli_contribuente.data_cartella,
 ruoli_contribuente.numero_cartella, ruoli_contribuente.utente,
 ruoli_contribuente.data_variazione, ruoli_contribuente.note,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), importo_lordo,
 ruoli_contribuente.da_mese, ruoli_contribuente.a_mese,
 ruoli_contribuente.giorni_ruolo,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER ('')
  FROM oggetti_pratica, ruoli, ruoli_contribuente
 WHERE ruoli.ruolo = ruoli_contribuente.ruolo
   AND oggetti_pratica.pratica = ruoli_contribuente.pratica
   AND 1 < (SELECT COUNT (*)
  FROM oggetti_pratica ogpr
 WHERE ogpr.pratica = ruoli_contribuente.pratica)
   UNION
   SELECT ruoli_contribuente.ruolo, ruoli_contribuente.cod_fiscale,
 ruoli_contribuente.sequenza, ruoli_contribuente.pratica,
 ruoli.anno_ruolo, ruoli.tipo_tributo, ruoli_contribuente.tributo,
 ruoli_contribuente.consistenza, ruoli_contribuente.importo,
 ruoli_contribuente.importo_base, ruoli_contribuente.semestri,
 ruoli_contribuente.decorrenza_interessi,
 ruoli_contribuente.mesi_ruolo, ruoli_contribuente.data_cartella,
 ruoli_contribuente.numero_cartella, ruoli_contribuente.utente,
 ruoli_contribuente.data_variazione, ruoli_contribuente.note,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), importo_lordo,
 ruoli_contribuente.da_mese, ruoli_contribuente.a_mese,
 ruoli_contribuente.giorni_ruolo,
 TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''), TO_NUMBER (''),
 TO_NUMBER ('')
  FROM ruoli, ruoli_contribuente
 WHERE ruoli.ruolo = ruoli_contribuente.ruolo
   AND NOT EXISTS (SELECT 'X'
   FROM oggetti_pratica ogpr
  WHERE ogpr.pratica = ruoli_contribuente.pratica)
   AND NOT EXISTS (SELECT 'X'
   FROM oggetti_pratica ogpr
   , oggetti_imposta ogim
  WHERE ogpr.oggetto_pratica = ogim.oggetto_pratica
    and ruoli_contribuente.oggetto_imposta = ogim.oggetto_imposta);
comment on table RUOLI_OGGETTO is 'RUOG - Ruoli Oggetto';

