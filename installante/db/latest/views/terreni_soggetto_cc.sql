--liquibase formatted sql 
--changeset abrandolini:20250326_152401_terreni_soggetto_cc stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW TERRENI_SOGGETTO_CC AS
SELECT   DISTINCT
   sogg.cod_fiscale_ric,
   sogg.cognome || sogg.nome congome_nome,
   tito.codice_diritto cod_titolo,
   diri.descrizione des_diritto,
   diri.descrizione des_titolo,
   part.id_immobile contatore,
   sogg.id_soggetto,
   part.partita partita,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.sezione_amm, '0'))), 1, 1) sezione,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.foglio, '0'))), 1, 5) foglio,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.numero, '0'))), 1, 5) numero,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.subalterno, '0'))), 1, 4)
   subalterno,
   part.edificialita,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.qualita, '0'))), 1, 3) qualita,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.classe, '0'))), 1, 2) classe,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.ettari, '0'))), 1, 5) ettari,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.are, '0'))), 1, 2) are,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.centiare, '0'))), 1, 2)
   centiare,
   RTRIM (LTRIM (LTRIM (tito.quota_numeratore, '0'))) numeratore,
   RTRIM (LTRIM (LTRIM (tito.quota_denominatore, '0'))) denominatore,
   part.flag_reddito,
   part.flag_porzione,
   part.flag_deduzioni,
   SUBSTR (
   RTRIM (LTRIM (LTRIM (part.reddito_dominicale_lire, '0'))),
   1,
   12
   )
   reddito_dominicale_lire,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.reddito_agrario_lire, '0'))),
  1,
  11)
   reddito_agrario_lire,
   SUBSTR (
   RTRIM (LTRIM (LTRIM (part.reddito_dominicale_euro, '0'))),
   1,
   9
   )
   reddito_dominicale_euro,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.reddito_agrario_euro, '0'))),
  1,
  8)
   reddito_agrario_euro,
   f_adatta_data (part.data_efficacia) data_efficacia,
   f_adatta_data (part.data_registrazione_atti) data_iscrizione,
   f_adatta_data (part.data_efficacia_1) data_fine_efficacia,
   f_adatta_data (tito.data_validita) data_validita,
   f_adatta_data (tito.data_validita_2) data_fine_validita,
   part.tipo_nota,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.numero_nota, '0'))), 1, 6)
   numero_nota,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.progressivo_nota, '0'))), 1, 3)
   progressivo_nota,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.anno_nota, '0'))), 1, 4)
   anno_nota,
   f_adatta_data (part.data_efficacia_1) data_efficacia_1,
   f_adatta_data (part.data_registrazione_atti_1) data_iscrizione_1,
   part.tipo_nota_1,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.numero_nota_1, '0'))), 1, 6)
   numero_nota_1,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.progressivo_nota_1, '0'))),
  1,
  3)
   progressivo_nota_1,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.anno_nota_1, '0'))), 1, 4)
   anno_nota_1,
   SUBSTR (RTRIM (LTRIM (LTRIM (part.partita, '0'))), 1, 7)
   partita_terreno,
   SUBSTR (RTRIM (LTRIM (part.annotazione)), 1, 200)
   || DECODE (LTRIM (LTRIM (part.sezione_amm, '0')),
  '', '',
  ' Sezione: ' || part.sezione_amm)
   annotazione,
   part.sezione_ric sezione_ric,
   part.foglio_ric foglio_ric,
   part.numero_ric numero_ric,
   part.subalterno_ric subalterno_ric,
   part.estremi_catasto
  FROM   (SELECT   * FROM cc_particelle) part,
   (SELECT   * FROM cc_TITOLARITA) tito,
   cc_soggetti sogg,
   cc_diritti diri
 WHERE tito.id_soggetto = sogg.id_soggetto_ric
   AND tito.id_immobile = part.id_immobile
   AND diri.codice_diritto(+) = tito.codice_diritto;
comment on table TERRENI_SOGGETTO_CC is 'TESo - Terreni Soggetto';

