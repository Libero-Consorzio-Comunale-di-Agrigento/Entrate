--liquibase formatted sql 
--changeset abrandolini:20250326_152401_ruoli_elenco stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW RUOLI_ELENCO AS
SELECT ruol.tipo_ruolo,
       ruol.anno_ruolo,
       ruol.anno_emissione,
       ruol.progr_emissione,
       ruol.data_emissione,
       impo.tributo,
       ruol.ruolo,
       ruol.tipo_tributo,
       (ruol.tipo_tributo || ' - ' || titr.descrizione) AS rutr_desc,
       ruol.scadenza_prima_rata,
       ruol.specie_ruolo,
       ruol.importo_lordo,
       ruol.ruolo_master AS ruolo_master,
       f_is_ruolo_master(ruol.ruolo) AS is_ruolo_master,
       ruol.tipo_calcolo,
       ruol.tipo_emissione,
       ruol.flag_calcolo_tariffa_base,
       ruol.flag_tariffe_ruolo,
       ruol.flag_depag,
       NVL(ruol.invio_consorzio, TO_DATE(NULL)) AS invio_consorzio,
       impo.importo + NVL(eccd.importo_ruolo, 0) AS importo,
       impo.importo_base + NVL(eccd.importo_ruolo, 0) AS importo_base,
       impo.imposta,
       NVL(eccd.imposta, 0) AS eccedenze,
       impo.add_pro + NVL(eccd.add_pro, 0) AS add_pro,
       impo.add_magg_eca,
       impo.iva,
       impo.maggiorazione_tares,
       impo.imposta_base,
       impo.add_magg_eca_base,
       impo.add_pro_base,
       impo.iva_base,
       impo.sgravio + NVL(eccd.sgravio, 0) AS sgravio,
       impo.importo AS importo_imp,
       impo.importo_base AS importo_base_imp,
       impo.add_pro AS add_pro_imp,
       impo.sgravio AS sgravio_imp,
       NVL(eccd.importo_ruolo, 0) AS importo_ecc,
       NVL(eccd.add_pro, 0) AS add_pro_ecc,
       NVL(eccd.sgravio, 0) AS sgravio_ecc
  FROM ruoli ruol
  JOIN tipi_tributo titr
    ON ruol.tipo_tributo = titr.tipo_tributo
  LEFT JOIN (SELECT ruco.ruolo,
                    ruco.tributo,
                    SUM(NVL(ruco.importo, 0)) AS importo,
                    SUM(NVL(ruco.importo_base, 0)) AS importo_base,
                    SUM(NVL(ogim.imposta, 0)) AS imposta,
                    SUM(NVL(ogim.addizionale_eca, 0) +
                        NVL(ogim.maggiorazione_eca, 0)) AS add_magg_eca,
                    SUM(NVL(ogim.addizionale_pro, 0)) AS add_pro,
                    SUM(NVL(ogim.iva, 0)) AS iva,
                    SUM(NVL(ogim.maggiorazione_tares, 0)) AS maggiorazione_tares,
                    SUM(NVL(ogim.imposta_base, 0)) AS imposta_base,
                    SUM(NVL(ogim.addizionale_eca_base, 0) +
                        NVL(ogim.maggiorazione_eca_base, 0)) AS add_magg_eca_base,
                    SUM(NVL(ogim.addizionale_pro_base, 0)) AS add_pro_base,
                    SUM(NVL(ogim.iva_base, 0)) AS iva_base,
                    SUM(f_totale_sgravi(ruco.ruolo,
                                        ruco.cod_fiscale,
                                        ruco.sequenza,
                                        0)) AS sgravio
               FROM ruoli_contribuente ruco
               LEFT JOIN oggetti_imposta ogim
                 ON ruco.oggetto_imposta = ogim.oggetto_imposta
              GROUP BY ruco.ruolo, ruco.tributo) impo
    ON ruol.ruolo = impo.ruolo
  LEFT JOIN (SELECT ruec.ruolo,
                    ruec.tributo,
                    SUM(NVL(ruec.importo_ruolo, 0)) AS importo_ruolo,
                    SUM(NVL(ruec.imposta, 0)) AS imposta,
                    SUM(NVL(ruec.addizionale_pro, 0)) AS add_pro,
                    NULL AS sgravio
               FROM ruoli_eccedenze ruec
              GROUP BY ruec.ruolo, ruec.tributo) eccd
    ON impo.ruolo = eccd.ruolo
   AND impo.tributo = eccd.tributo;
