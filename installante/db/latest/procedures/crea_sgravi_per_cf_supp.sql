--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_sgravi_per_cf_supp stripComments:false runOnChange:true 
 
create or replace procedure CREA_SGRAVI_PER_CF_SUPP
/*************************************************************************
 NOME:        CREA_SGRAVI_PER_CF_SUPP
 DESCRIZIONE: Calcolo e inserimento sgravi su ruoli suppletivi
 NOTE:
 Rev.    Date         Author      Note
 001     24/10/2018   VD          Aggiunta gestione importi calcolati
                                  con tariffa base
 000     11/02/2014   XX          Prima emissione.
*************************************************************************/
( p_cf                VARCHAR2,
  p_ruolo             NUMBER,
  p_anno              NUMBER,
  p_titr              VARCHAR2
)
IS
  CURSOR sel_ruco IS
    SELECT ruco.ruolo, ruco.cod_fiscale, ruco.sequenza,
           99 motivo_sgravio,
           ruco.importo - NVL (sgra.importo, 0) importo,
           ruco.mesi_ruolo,
           ruco.giorni_ruolo, ruol.importo_lordo,
           ogim.maggiorazione_tares
               - NVL (sgra.maggiorazione_tares, 0) maggiorazione_tares,
           ogim.maggiorazione_eca
               - NVL (sgra.maggiorazione_eca, 0) maggiorazione_eca,
           ogim.addizionale_eca
               - NVL (sgra.addizionale_eca, 0) addizionale_eca,
           ogim.addizionale_pro
               - NVL (sgra.addizionale_pro, 0) addizionale_pro,
           ogim.iva - NVL (sgra.iva, 0) iva,
           ruco.importo_base - NVL (sgra.importo, 0) importo_base,
           ogim.maggiorazione_eca_base - NVL (sgra.maggiorazione_eca_base, 0) maggiorazione_eca_base,
           ogim.addizionale_eca_base - NVL (sgra.addizionale_eca_base, 0) addizionale_eca_base,
           ogim.addizionale_pro_base - NVL (sgra.addizionale_pro_base, 0) addizionale_pro_base,
           ogim.iva_base - NVL (sgra.iva_base, 0) iva_base
      FROM ruoli_contribuente ruco,
           ruoli ruol,
           oggetti_imposta ogim,
           (SELECT ruolo, cod_fiscale, sequenza,
                   SUM (NVL (importo, 0)) importo,
                   SUM (NVL (maggiorazione_tares, 0)) maggiorazione_tares,
                   SUM (NVL (maggiorazione_eca, 0)) maggiorazione_eca,
                   SUM (NVL (addizionale_eca, 0)) addizionale_eca,
                   SUM (NVL (addizionale_pro, 0)) addizionale_pro,
                   SUM (NVL (iva, 0)) iva,
                   SUM (NVL (importo_base, 0)) importo_base,
                   SUM (NVL (maggiorazione_eca_base, 0)) maggiorazione_eca_base,
                   SUM (NVL (addizionale_eca_base, 0)) addizionale_eca_base,
                   SUM (NVL (addizionale_pro_base, 0)) addizionale_pro_base,
                   SUM (NVL (iva_base, 0)) iva_base
              FROM sgravi
             WHERE ruolo != p_ruolo AND cod_fiscale = p_cf
          GROUP BY ruolo, cod_fiscale, sequenza) sgra
     WHERE ruol.ruolo = ruco.ruolo
       AND ruol.ruolo != p_ruolo
       AND ogim.oggetto_imposta = ruco.oggetto_imposta
       AND ogim.cod_fiscale = p_cf
       AND ruco.ruolo = ogim.ruolo
       AND ruol.invio_consorzio IS NOT NULL
       AND NVL (ruol.tipo_emissione, 'T') = 'T'
       AND ruol.anno_ruolo = p_anno
       AND ruco.cod_fiscale = p_cf
       AND ruol.tipo_tributo || '' = p_titr
       AND sgra.ruolo(+) = ruco.ruolo
       AND sgra.cod_fiscale(+) = ruco.cod_fiscale
       AND sgra.sequenza(+) = ruco.sequenza
  ORDER BY 1, 2, 3;
BEGIN
   BEGIN
      INSERT INTO motivi_sgravio
         SELECT 99, 'ECCEDENZA DI GETTITO'
           FROM DUAL
          WHERE NOT EXISTS (SELECT 'x'
                              FROM motivi_sgravio
                             WHERE motivo_sgravio = 99);
   END;
   FOR rec_ruco IN sel_ruco
   LOOP
      BEGIN
         INSERT INTO sgravi
                     (ruolo, cod_fiscale,
                      sequenza, sequenza_sgravio, motivo_sgravio,
                      importo, addizionale_eca,
                      maggiorazione_tares,
                      maggiorazione_eca, addizionale_pro,
                      iva, mesi_sgravio,
                      giorni_sgravio, flag_automatico, tipo_sgravio,
                      note, ruolo_inserimento,
                      importo_base, addizionale_eca_base,
                      maggiorazione_eca_base,
                      addizionale_pro_base, iva_base
                     )
              VALUES (rec_ruco.ruolo, rec_ruco.cod_fiscale,
                      rec_ruco.sequenza, NULL, rec_ruco.motivo_sgravio,
                      rec_ruco.importo, rec_ruco.addizionale_eca,
                      rec_ruco.maggiorazione_tares,
                      rec_ruco.maggiorazione_eca, rec_ruco.addizionale_pro,
                      rec_ruco.iva, rec_ruco.mesi_ruolo,
                      rec_ruco.giorni_ruolo, 'S', 'D',
                      'Inserito da ruolo: '||p_ruolo, p_ruolo,
                      rec_ruco.importo_base, rec_ruco.addizionale_eca_base,
                      rec_ruco.maggiorazione_eca_base,
                      rec_ruco.addizionale_pro_base, rec_ruco.iva_base
                     );
      EXCEPTION
         WHEN OTHERS
         THEN
            raise_application_error (-20919,
                                        'Errore in inserimento sgravio '
                                     || ' cod_fiscale '
                                     || rec_ruco.cod_fiscale
                                     || ' sequenza '
                                     || rec_ruco.sequenza
                                     || ' ('
                                     || SQLERRM
                                     || ')'
                                    );
      END;
   END LOOP;
END;
/* End Procedure: CREA_SGRAVI_PER_CF_SUPP */
/

