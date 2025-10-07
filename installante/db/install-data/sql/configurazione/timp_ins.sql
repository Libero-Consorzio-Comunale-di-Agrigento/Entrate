--liquibase formatted sql
--changeset dmarotta:20250326_152438_timp_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE tipi_modello_parametri DISABLE ALL TRIGGERS;

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (1, 'ACC_ICI%', 'TOT', '01 - Totale dovuto', 73, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (2, 'ACC_ICI%', 'TOT_CONT_DOV_AR', '02 - Totale dovuto arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (3, 'ACC_ICP%', 'ACC_IMP', '01 - Accertamento imposta (Titolo)', 90, 'ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (4, 'ACC_ICP%', 'IRR_SANZ_INT', '02 - Irrogazione sanzioni e interessi (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (5, 'ACC_ICP%', 'TOT_AD_CONT', '03 - Totale con adesione formale (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (6, 'ACC_ICP%', 'TOT', '04 - Totale dovuto', 73, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (7, 'ACC_ICP%', 'TOT_CONT', '05 - Totale (Contribuente)', 48, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (8, 'ACC_TARSU%', 'ACC_IMP', '01 - Accertamento imposta (Titolo)', 90, 'ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (9, 'ACC_TARSU%', 'ACC', '02 - Accertati', 20, 'ACCERTATI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (10, 'ACC_TARSU%', 'ADD MAGG TOT', '03 - Addizionali e maggiorazioni IVA -> Totale', 70, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (11, 'ACC_TARSU%', 'ADD_MAGG', '04 - Addizionali e maggiorazioni/IVA', 90, 'ADDIZIONALI E MAGGIORAZIONI/IVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (12, 'ACC_TARSU%', 'DETT_VERS', '05 - Dettaglio versamenti cumulativo (Titolo)', 90, 'DETTAGLIO VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (13, 'ACC_TARSU%', 'DIC ACC IMP DOV', '06 - Dichiarati, accertati -> Importo dovuto', 16, 'IMPORTO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (14, 'ACC_TARSU%', 'DIFF_PRT', '07 - Differenza di imposta (Dettaglio versamenti cumulativi)', 79, 'DIFFERENZA DI IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (15, 'ACC_TARSU%', 'INTE', '08 - Intestazione (Prima riga)', 90, 'DEFAULT');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (16, 'ACC_TARSU%', 'IRR_SANZ_INT', '09 - Irrogazione sanzioni e interessi (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (17, 'ACC_TARSU%', 'IRR SAN INT TOT SANZ', '10 - Irrogazioni sanzioni e interessi -> Totali sanzioni', 49, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (18, 'ACC_TARSU%', 'RIEP_DETT_PRT', '11 - Riepilogo pratica (Titolo)', 90, 'RIEPILOGO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (19, 'ACC_TARSU%', 'RIE_SOM_DOV', '12 - Riepilogo somme divute (Titolo)', 90, 'RIEPILOGO SOMME DOVUTE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (20, 'ACC_TARSU%', 'TOT_ACC_IMP', '13 - Totale (accertamento imposta)', 49, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (21, 'ACC_TARSU%', 'TOTACCIMP', '14 - Totale accertamento imposta', 79, 'TOTALE ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (22, 'ACC_TARSU%', 'TOTADD', '15 - Totale addizionale', 79, 'TOTALE ADDIZIONALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (23, 'ACC_TARSU%', 'TOT_AD_CONT', '16 - Totale con adesione formale (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (24, 'ACC_TARSU%', 'TOT_AD', '17 - Totale con adesione formale (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (25, 'ACC_TARSU%', 'TOT_DETT_VERS_PRT', '18 - Totale dettaglio versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (26, 'ACC_TARSU%', 'TOT', '19 - Totale dovuto', 73, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (27, 'ACC_TARSU%', 'TOT_CONT', '20 - Totale dovuto (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (28, 'ACC_TARSU%', 'TOT_IMP_COMP', '21 - Totale imposta complessiva', 79, 'TOTALE IMPOSTA COMPLESSIVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (29, 'ACC_TARSU%', 'TOT_IMP_PRT', '22 - Totale imposta complessiva', 79, 'TOTALE IMPOSTA COMPLESSIVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (30, 'ACC_TARSU%', 'TOTSANZ', '23 - Totale sanzioni', 79, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (31, 'ACC_TARSU%', 'TOT_VERS', '24 - Totale versamenti', 49, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (32, 'ACC_TARSU%', 'TOT_VERS_RIEP_PRT', '25 - Totale versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (33, 'ACC_TARSU%', 'ACC_ELENCO', '26 - Visualizzazione dati accertati', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (34, 'ACC_TOSAP%', 'ACC_IMP', '01 - Accertamento imposta (Titolo)', 90, 'ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (35, 'ACC_TOSAP%', 'ACC IMP', '02 - Accertamento imposta -> Totale', 49, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (36, 'ACC_TOSAP%', 'ACC', '03 - Accertati', 20, 'ACCERTATI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (37, 'ACC_TOSAP%', 'DET_VER_PRAT', '04 - Dettaglio versamenti cumulativo (Titolo)', 90, 'DETTAGLIO VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (38, 'ACC_TOSAP%', 'DET_VER_PRT', '05 - Dettaglio versamenti oggetto (Titolo, Dettaglio versamenti cumulativi)', 90, 'DETTAGLIO VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (39, 'ACC_TOSAP%', 'DET_VER_OGIM', '06 - Dettaglio versamenti oggetto (Titolo, Dettaglio versamenti oggetto)', 49, 'DETTAGLIO VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (40, 'ACC_TOSAP%', 'DIC ACC IMP DOV', '07 - Dichiarati, accertati -> Imposta dovuta', 15, 'IMPOSTA DOVUTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (41, 'ACC_TOSAP%', 'DIFF_PRT', '08 - Differenza di imposta (Dettaglio versamenti cumulativi)', 79, 'DIFFERENZA DI IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (42, 'ACC_TOSAP%', 'DIFFERENZA', '09 - Differenza di imposta (Dettaglio versamenti oggetto)', 79, 'DIFFERENZA DI IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (43, 'ACC_TOSAP%', 'INTE', '10 - Intestazione (Prima riga)', 90, 'DEFAULT');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (44, 'ACC_TOSAP%', 'IRR_SANZ_INT', '11 - Irrogazione sanzioni e interessi (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (45, 'ACC_TOSAP%', 'IRR SAN INT TOT SANZ', '12 - Irrogazioni sanzioni e interessi -> Totali sanzioni', 49, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (46, 'ACC_TOSAP%', 'RIEP_DETT_OGIM', '13 - Riepilogo oggetto (Titolo)', 90, 'RIEPILOGO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (47, 'ACC_TOSAP%', 'RIEP_DETT_PRT', '14 - Riepilogo pratica (Titolo)', 90, 'RIEPILOGO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (48, 'ACC_TOSAP%', 'RIE_SOM_DOV', '15 - Riepilogo somme dovute (Titolo)', 90, 'RIEPILOGO SOMME DOVUTE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (49, 'ACC_TOSAP%', 'TOT_ACC_IMP', '16 - Totale accertamento imposta', 79, 'TOTALE ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (50, 'ACC_TOSAP%', 'TOT_AD_CONT', '17 - Totale con adesione formale (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (51, 'ACC_TOSAP%', 'TOT_AD', '18 - Totale con adesione formale (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (52, 'ACC_TOSAP%', 'TOT_DETT_VERS_PRT', '19 - Totale dettaglio versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (53, 'ACC_TOSAP%', 'TOT_DETT_VERS', '20 - Totale dettaglio versamenti (Dettaglio versamenti oggetto)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (54, 'ACC_TOSAP%', 'TOT', '21 - Totale dovuto', 72, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (55, 'ACC_TOSAP%', 'TOT_IMP_PRT', '22 - Totale imposta (Dettaglio versamenti cumulativi)', 79, 'TOTALE IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (56, 'ACC_TOSAP%', 'TOT_IMP', '23 - Totale imposta (Dettaglio versamenti oggetto)', 79, 'TOTALE IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (57, 'ACC_TOSAP%', 'TOT_IMP_COMP', '24 - Totale imposta complessiva', 79, 'TOTALE IMPOSTA COMPLESSIVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (58, 'ACC_TOSAP%', 'TOT_SANZ', '25 - Totale sanzioni', 79, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (59, 'ACC_TOSAP%', 'TOT_VERS', '26 - Totale versamenti', 49, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (60, 'ACC_TOSAP%', 'TOT_VERS_RIEP_PRT', '27 - Totale versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (61, 'ACC_TOSAP%', 'TOT_VERS_RIEP', '28 - Totale versamenti (Dettaglio versamenti oggetto)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (62, 'ACC_TOSAP%', 'ACC_ELENCO', '29 - Visualizzazione dati accertati', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (63, 'ACC_TOSAP%', 'TOT_CONT', '30 - Totale (Contribuente)', 48, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (64, 'ACC_ICI%', 'TOT_CONT_RIMB_AR', '03 - Totale rimborso arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO ARROTONDATO DA RIMBORSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (67, 'ACC_ICI%', 'TOT_DOV_RID_AR', '04 - Totale ridotto arrotondato (Contribuente)', 47, 'TOTALE RIDOTTO CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (68, 'LIQ_ICI%', 'INTESTAZIONE', '01 - Intestazione Accertamento (Ex Liquidazione)', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (69, 'ACC_TARSU%', 'TOT_ARR', '27 - Totale dovuto Arrotondato', 73, 'TOTALE DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (70, 'ACC_TARSU%', 'TOT_AD_ARR', '28 - Totale con adesione formale Arrotondato (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (71, 'ACC_TARSU%', 'TOT_CONT_ARR', '29 - Totale dovuto Arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (72, 'ACC_TARSU%', 'TOT_AD_CONT_ARR', '30 - Totale con adesione formale Arrotondato (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (73, 'ACC_TOSAP%', 'TOT_ARR', '31 - Totale dovuto Arrotondato', 72, 'TOTALE DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (74, 'ACC_TOSAP%', 'TOT_AD_ARR', '32 - Totale con adesione formale Arrotondato (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (75, 'ACC_TOSAP%', 'TOT_CONT_ARR', '33 - Totale Arrotondato (Contribuente)', 48, 'TOTALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (76, 'ACC_TOSAP%', 'TOT_AD_CONT_ARR', '34 - Totale con adesione formale (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (77, 'ACC_ICI%', 'INTESTAZIONE', '05 - Intestazione Imposte e Interessi', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (78, 'LIQ_ICIR%', 'INTESTAZIONE_RIMB', '01 - Intestazione Accertamento (Ex Liquidazione a Rimborso)', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (79, 'LIQ_ICI%', 'INT_IMPOSTA_INTERESSI', '02 - Intestazione Imposta e interessi', 12, 'LIQUIDAZIONE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (80, 'LIQ_ICIR%', 'INT_IMPOSTA_INTERESSI_RIMB', '02 - Intestazione Imposta e Interessi', 12, 'LIQUIDAZIONE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (81, 'LIQ_ICI%', 'NOTE_VERS_RAVV', '03 - Note del Versamento su Ravvedimento', 220, '* e'' stato rilevato un versamento su ravvedimento non corretto. L''importo indicato e'' ottenuto riproporzionando l''intero versamento su ravvedimento all''effettiva imposta dovuta, al netto di sanzioni e interessi.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (82, 'ACC_T_ICI%', 'LABEL_MOTIVAZIONE', '01 - Label Motivazione', 15, 'Motivazione:');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (83, 'ING_TRASV%', 'DESCR_LIQ_ICI', '01 - Descrizione Liquidazione ICI', 70, 'AVVISO DI LIQUIDAZIONE ICI E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (84, 'ING_TRASV%', 'DESCR_LIQ_ICIAP', '02 - Descrizione Liquidazione ICIAP', 70, 'AVVISO DI LIQUIDAZIONE ICIAP E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (85, 'ING_TRASV%', 'DESCR_ACC_ICI', '03 - Descrizione Accertamento ICI', 70, 'AVVISO DI ACCERTAMENTO ICI E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (86, 'ING_TRASV%', 'DESCR_ACC_ICIAP', '04 - Descrizione Accertamento ICIAP', 70, 'AVVISO DI ACCERTAMENTO ICIAP E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (87, 'ING_TRASV%', 'DESCR_ACC_ICP', '05 - Descrizione Accertamento ICP', 70, 'AVVISO DI ACCERTAMENTO ICP E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (88, 'ING_TRASV%', 'DESCR_ACC_TARSU', '06 - Descrizione Accertamento TARSU', 70, 'AVVISO DI ACCERTAMENTO TARSU E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (89, 'ING_TRASV%', 'DESCR_ACC_TOSAP', '07 - Descrizione Accertamento TOSAP', 70, 'AVVISO DI ACCERTAMENTO TOSAP E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (90, 'ACC_TARSU%', 'TOT_RIV', '31 - Totale (Rivoli)', 72, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (91, 'ACC_TARSU%', 'TOT_RID_RIV', '32 - Totale Ridotto (Rivoli)', 72, 'TOTALE RIDOTTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (92, 'ACC_TARSU%', 'TOT_RIV_CONT', '32 - Totale Contribuente (Rivoli)', 48, 'TOTALE COMPLESSIVO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (93, 'ACC_TARSU%', 'TOT_RID_RIV_CONT', '33 - Totale Ridotto Contribuente (Rivoli)', 48, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (95, 'ACC_ICI%', 'TOT_PRAT_DOV', '06 - Totale dovuto (per pratica)', 69, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (96, 'ACC_ICI%', 'TOT_PRAT_DOV_AR', '07 - Totale dovuto arrotondato (per pratica)', 69, 'TOTALE DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (97, 'ACC_ICI%', 'TOT_PRAT_DOV_RID', '08 - Totale con adesione formale (per pratica)', 69, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (98, 'ACC_ICI%', 'TOT_PRAT_DOV_RID_AR', '09 - Totale con adesione formale arrotondato (per pratica)', 69, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (99, 'ACC_T_ICI%', 'TIT_IMP_SAN_INT', '02 - Titolo Dettaglio Accertamento', 60, 'DETTAGLIO ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (100, 'ACC_T_ICI%', 'TOT_PRAT', '03 - Totale dovuto', 80, 'TOTALE IMPORTO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (101, 'ACC_T_ICI%', 'TOT_PRAT_ARR', '04 - Totale dovuto arrotondato', 80, 'TOTALE IMPORTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (102, 'ACC_T_ICI%', 'TIT_RID', '05 - Titolo in caso di Acquiscenza', 192, 'TOTALE IMPORTO IN CASO DI ACQUIESCENZA ALL''ACCERTAMENTO (pagamento entro 60 giorni dalla notifica dell''imposta e della sanzione con riduzione a 1/4):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (103, 'ACC_T_ICI%', 'SUF_SANZ_RID', '06 - Suffisso Sanzione Ridotta', 20, ' (RIDOTTA A 1/4)');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (104, 'ACC_T_ICI%', 'TOT_PRAT_RID', '07 - Totale dovuto Ridotto', 80, 'TOTALE IMPORTO CON ACQUIESCENZA ALL''ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (105, 'ACC_T_ICI%', 'TOT_PRAT_RID_ARR', '08 - Totale dovuto Ridotto Arrotondato', 80, 'TOTALE IMPORTO CON ACQUIESCENZA ALL''ACCERTAMENTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (106, 'ACC_T_ICI%', 'TIT_RID_2', '09 - Titolo in caso di definizione agevolata della sola sanzione', 192, 'TOTALE IMPORTO IN CASO DI DEFINIZIONE AGEVOLATA DELLA SOLA SANZIONE (pagamento entro 60 giorni dalla data di notifica del solo importo dovuto a titolo di sanzione con riduzione a 1/3):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (107, 'ACC_T_ICI%', 'DESC_SANZ_RID_2', '10 - Descrizione Sanzione Ridotta 2', 80, 'SANZIONE RIDOTTA a 1/3 ');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (108, 'ACC_T_ICI%', 'SEPARATORE_1', '11 - Separatore 1', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (109, 'ACC_T_ICI%', 'SEPARATORE_2', '12 - Separatore 2', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (110, 'ACC_T_ICI%', 'SEPARATORE_3', '13 - Separatore 3', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (111, 'ACC_ICI%', 'TIT_RID', '10 - Titolo in caso di Acquiscenza', 192, 'TOTALE IMPORTO IN CASO DI ACQUIESCENZA ALL''ACCERTAMENTO (pagamento entro 60 giorni dalla notifica dell''imposta e della sanzione con riduzione a 1/4):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (112, 'ACC_ICI%', 'SUF_SANZ_RID', '11 - Suffisso Sanzione Ridotta', 20, ' (RIDOTTA A 1/4)');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (113, 'ACC_ICI%', 'TIT_RID_2', '12 - Titolo in caso di definizione agevolata della sola sanzione', 192, 'TOTALE IMPORTO IN CASO DI DEFINIZIONE AGEVOLATA DELLA SOLA SANZIONE (pagamento entro 60 giorni dalla data di notifica del solo importo dovuto a titolo di sanzione con riduzione a 1/3):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (114, 'ACC_ICI%', 'DESC_SANZ_RID_2', '13 - Descrizione Sanzione Ridotta 2', 80, 'SANZIONE RIDOTTA a 1/3 ');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (115, 'ACC_ICI%', 'SEPARATORE_1', '14 - Separatore 1', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (116, 'ACC_ICI%', 'SEPARATORE_2', '15 - Separatore 2', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (117, 'ACC_ICI%', 'SEPARATORE_3', '16 - Separatore 3', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (118, 'COM_TARSU%', 'MAGG_TARES', '01 - STAMPA MAGGIORAZIONE TARES SI/NO', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (119, 'LIQ_IMU%', 'INTESTAZIONE', '01 - Intestazione Accertamento (Ex Liquidazione)', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (120, 'LIQ_IMU%', 'INT_IMPOSTA_INTERESSI', '02 - Intestazione Imposta e interessi', 12, 'LIQUIDAZIONE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (121, 'LIQ_IMU%', 'NOTE_VERS_RAVV', '03 - Note del Versamento su Ravvedimento', 220, '* e'' stato rilevato un versamento su ravvedimento non corretto. L''importo indicato e'' ottenuto riproporzionando l''intero versamento su ravvedimento all''effettiva imposta dovuta, al netto di sanzioni e interessi.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (122, 'LIQ_IMUR%', 'INT_IMPOSTA_INTERESSI_RIMB', '02 - Intestazione Imposta e Interessi', 12, 'LIQUIDAZIONE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (123, 'LIQ_IMUR%', 'INTESTAZIONE_RIMB', '01 - Intestazione Accertamento (Ex Liquidazione a Rimborso)', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (124, 'COM_TARSU%', 'RATA_UNICA', '02 - STAMPA RATA UNICA SI/NO', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (125, 'COM_TARSU%', 'VERS_POSITIVI', '03 - STAMPA SOLO VERSAMENTI POSITIVI SI/NO', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (126, 'ACC_TARSU%', 'DESCR_ADD', '34 - Descrizione Addizionali', 42, 'ADDIZIONALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (127, 'ACC_TARSU%', 'ACC_MAGG', '35 - Accertamento Maggiorazione (Titolo)', 90, 'ACCERTAMENTO MAGG. TARES');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (128, 'ACC_TARSU%', 'IRR_SANZ_INT_MAGG', '36 - Irrogazione sanzioni e interessi Maggiorazione (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (129, 'ACC_TARSU%', 'VIS_TOT_ARR', '37 - Visualizzazione Tot. Arr.', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (130, 'ACC_TARSU%', 'VIS_COD_TRIB', '38 - Visualizzazione Codici Tributo', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (131, 'ACC_TARSU%', 'TOT_ACC_MAG', '39 - Totale (accertamento Maggiorazione)', 49, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (132, 'ACC_TARSU%', 'IRR SAN INT TOT MAGG', '40 - Irrogazioni sanzioni e interessi -> Totali magg.', 49, 'TOTALE MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (133, 'ACC_TARSU%', 'TOTSANZMAG', '41 - Totale sanzioni Magg.', 79, 'TOTALE SANZIONI MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (134, 'ACC_TARSU%', 'TOTACCMAG', '42 - Totale accertamento Magg. Tares', 79, 'TOTALE ACCERTAMENTO MAGG. TARES');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (137, 'LIQ_TASI%', 'INTESTAZIONE', '01 - Intestazione Accertamento', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (138, 'LIQ_TASI%', 'INT_IMPOSTA_INTERESSI', '02 - Intestazione Imposta e interessi', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (139, 'LIQ_TASI%', 'NOTE_VERS_RAVV', '03 - Note del Versamento su Ravvedimento', 220, '* e'' stato rilevato un versamento su ravvedimento non corretto. L''importo indicato e'' ottenuto riproporzionando l''intero versamento su ravvedimento all''effettiva imposta dovuta, al netto di sanzioni e interessi.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (140, 'LIQ_TASIR%', 'INTESTAZIONE_RIMB', '01 - Intestazione Accertamento', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (141, 'LIQ_TASIR%', 'INT_IMPOSTA_INTERESSI_RIMB', '02 - Intestazione Imposta e Interessi', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (142, 'LIQ_TASI%', 'INT_IMPOSTA_CALC', '04 - Intestazione imposta calcolata', 60, 'IMPOSTA CALCOLATA PER L''ANNO DI RIFERIMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (143, 'LIQ_TASI%', 'DES_RIS_CAT', '05 - Descrizione Risultanze Catastali', 35, 'COME DA RISULTANZE CATASTALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (144, 'LIQ_TASI%', 'DATI_DIC', '06 - Stampa dati dichiarati', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (145, 'SGR%', 'IMPORTO_RUOLO', '01 - Importo a ruolo', 20, 'IMPORTO A RUOLO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (146, 'SGR%', 'IMPORTO_CRED', '02 - Importo a credito', 20, 'IMPORTO A CREDITO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (147, 'SGR%', 'RESIDUO_RUOLO', '04 - Residuo a Ruolo', 20, 'RESIDUO A RUOLO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (148, 'RIM_TARSU%', 'IMPORTO_RUOLO', '01 - Importo a ruolo', 20, 'IMPORTO A RUOLO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (149, 'RIM_TARSU%', 'IMPORTO_CRED', '02 - Importo a credito', 20, 'IMPORTO A CREDITO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (150, 'RIM_TARSU%', 'RESIDUO_RUOLO', '04 - Residuo a Ruolo', 20, 'RESIDUO A RUOLO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (151, 'SOL_L_ICI%', 'INTESTAZIONE', '01 - Intestazione', 20, 'LIQUIDAZIONE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (152, 'SOL_L_ICI%', 'INT_REL_ANNO', '02 - Intestazione anno', 10, 'relativa');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (153, 'SOL_L_ICI%', 'INT_NOTIFICA', '03 - Intestazione notifica', 12, 'notificata');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (154, 'SGR%', 'GIA_SGRAVATO', '03 - Gia sgravato', 20, 'GIA SGRAVATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (155, 'RIM_TARSU%', 'GIA_SGRAVATO', '03 - Gia'' sgravato', 20, 'GIA SGRAVATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (156, 'ACC_TARSU%', 'VIS_ID_OP', '43 - Visualizzazione Identificativo Operazione', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (157, 'ACC_TARSU%', 'F24_INT', '44 - Intestazione riepilogo F24', 79, 'RIEPILOGO SOMME DA VERSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (158, 'ACC_TARSU%', 'F24_TOT', '45 - Totale riepilogo F24', 79, 'TOTALE SOMME DA VERSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (159, 'ACC_T_TAR%', 'TOT_ACC_MAG', '33 - Totale (accertamento Maggiorazione)', 49, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (160, 'ACC_T_TAR%', 'IRR SAN INT TOT MAGG', '34 - Irrogazioni sanzioni e interessi (Totali magg.)', 49, 'TOTALE MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (161, 'ACC_T_TAR%', 'TOTSANZMAG', '35 - Totale sanzioni Magg.', 79, 'TOTALE SANZIONI MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (162, 'ACC_T_TAR%', 'TOTACCMAG', '36 - Totale accertamento Magg. Tares', 79, 'TOTALE ACCERTAMENTO MAGG. TARES');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (163, 'ACC_T_TAR%', 'DESCR_ADD', '28 - Descrizione Addizionali', 42, 'ADDIZIONALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (164, 'ACC_T_TAR%', 'ACC_MAGG', '29 - Accertamento Maggiorazione (Titolo)', 90, 'ACCERTAMENTO MAGG. TARES');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (165, 'ACC_T_TAR%', 'IRR_SANZ_INT_MAGG', '30 - Irrogazione sanzioni e interessi Maggiorazione (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI MAGG.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (166, 'ACC_T_TAR%', 'VIS_TOT_ARR', '31 - Visualizzazione Tot. Arr.', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (167, 'ACC_T_TAR%', 'VIS_COD_TRIB', '32 - Visualizzazione Codici Tributo', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (171, 'ACC_T_TAR%', 'TOT_ARR', '24 - Totale dovuto Arrotondato', 73, 'TOTALE DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (172, 'ACC_T_TAR%', 'TOT_AD_ARR', '25 - Totale con adesione formale Arrotondato (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (173, 'ACC_T_TAR%', 'ACC_IMP', '01 - Accertamento imposta (Titolo)', 90, 'ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (174, 'ACC_T_TAR%', 'ACC', '02 - Accertati', 20, 'ACCERTATI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (177, 'ACC_T_TAR%', 'DETT_VERS', '03 - Dettaglio versamenti cumulativo (Titolo)', 90, 'DETTAGLIO VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (178, 'ACC_T_TAR%', 'DIC ACC IMP DOV', '04 - Dichiarati, accertati (Importo dovuto)', 16, 'IMPORTO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (179, 'ACC_T_TAR%', 'DIFF_PRT', '05 - Differenza di imposta (Dettaglio versamenti cumulativi)', 79, 'DIFFERENZA DI IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (180, 'ACC_T_TAR%', 'INTE', '06 - Intestazione (Prima riga)', 90, 'DEFAULT');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (181, 'ACC_T_TAR%', 'IRR_SANZ_INT', '07 - Irrogazione sanzioni e interessi (Titolo)', 90, 'IRROGAZIONI SANZIONI E INTERESSI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (182, 'ACC_T_TAR%', 'IRR SAN INT TOT SANZ', '08 - Irrogazioni sanzioni e interessi (Totali sanzioni)', 49, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (183, 'ACC_T_TAR%', 'RIEP_DETT_PRT', '09 - Riepilogo pratica (Titolo)', 90, 'RIEPILOGO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (184, 'ACC_T_TAR%', 'RIE_SOM_DOV', '10 - Riepilogo somme divute (Titolo)', 90, 'RIEPILOGO SOMME DOVUTE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (185, 'ACC_T_TAR%', 'TOT_ACC_IMP', '11 - Totale (accertamento imposta)', 49, 'TOTALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (186, 'ACC_T_TAR%', 'TOTACCIMP', '12 - Totale accertamento imposta', 79, 'TOTALE ACCERTAMENTO IMPOSTA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (187, 'ACC_T_TAR%', 'TOTADD', '13 - Totale addizionale', 79, 'TOTALE ADDIZIONALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (188, 'ACC_T_TAR%', 'TOT_AD_CONT', '14 - Totale con adesione formale (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (189, 'ACC_T_TAR%', 'TOT_AD', '15 - Totale con adesione formale (Pratica)', 72, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (190, 'ACC_T_TAR%', 'TOT_DETT_VERS_PRT', '16 - Totale dettaglio versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (191, 'ACC_T_TAR%', 'TOT', '17 - Totale dovuto', 73, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (192, 'ACC_T_TAR%', 'TOT_CONT', '18 - Totale dovuto (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (193, 'ACC_T_TAR%', 'TOT_IMP_COMP', '19 - Totale imposta complessiva', 79, 'TOTALE IMPOSTA COMPLESSIVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (194, 'ACC_T_TAR%', 'TOT_IMP_PRT', '20 - Totale imposta complessiva', 79, 'TOTALE IMPOSTA COMPLESSIVA');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (195, 'ACC_T_TAR%', 'TOTSANZ', '21 - Totale sanzioni', 79, 'TOTALE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (197, 'ACC_T_TAR%', 'TOT_VERS_RIEP_PRT', '22 - Totale versamenti (Dettaglio versamenti cumulativi)', 79, 'TOTALE VERSAMENTI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (198, 'ACC_T_TAR%', 'ACC_ELENCO', '23 - Visualizzazione dati accertati', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (199, 'ACC_T_TAR%', 'TOT_CONT_ARR', '26 - Totale dovuto Arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (200, 'ACC_T_TAR%', 'TOT_AD_CONT_ARR', '27 - Totale con adesione formale Arrotondato (Contribuente)', 48, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (201, 'ACC_T_TAR%', 'VIS_ID_OP', '37 - Visualizzazione Identificativo Operazione', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (202, 'ACC_T_TAR%', 'F24_INT', '38 - Intestazione riepilogo F24', 79, 'RIEPILOGO SOMME DA VERSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (203, 'ACC_T_TAR%', 'F24_TOT', '39 - Totale riepilogo F24', 24, 'TOTALE SOMME DA VERSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (204, 'COM_COSAP%', 'VIS_TOT_ARR', '01 - Visualizzazione Tot. Arr.', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (205, 'COM_ICP%', 'VIS_TOT_ARR', '01 - Visualizzazione Tot. Arr.', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (206, 'ACC_T_TAR%', 'LABEL_MOTIVAZIONE', '40 - Label Motivazione', 15, 'Motivazione');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (207, 'ING_TRASV%', 'DESCR_LIQ_TASI', '08 - Descrizione Liquidazione TASI', 70, 'AVVISO DI LIQUIDAZIONE TASI E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (208, 'ING_TRASV%', 'DESCR_ACC_TASI', '09 - Descrizione Accertamento TASI', 70, 'AVVISO DI ACCERTAMENTO TASI E PROVVEDIMENTO DI IRROGAZIONE SANZIONI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (209, 'ACC_T_TAS%', 'LABEL_MOTIVAZIONE', '01 - Label Motivazione', 15, 'Motivazione:');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (210, 'ACC_T_TAS%', 'TIT_IMP_SAN_INT', '02 - Titolo Dettaglio Accertamento', 60, 'DETTAGLIO ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (211, 'ACC_T_TAS%', 'TOT_PRAT', '03 - Totale dovuto', 80, 'TOTALE IMPORTO DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (212, 'ACC_T_TAS%', 'TOT_PRAT_ARR', '04 - Totale dovuto arrotondato', 80, 'TOTALE IMPORTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (213, 'ACC_T_TAS%', 'TIT_RID', '05 - Titolo in caso di Acquiscenza', 192, 'TOTALE IMPORTO IN CASO DI ACQUIESCENZA ALL''ACCERTAMENTO (pagamento entro 60 giorni dalla notifica dell''imposta e della sanzione con riduzione a 1/4):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (214, 'ACC_T_TAS%', 'SUF_SANZ_RID', '06 - Suffisso Sanzione Ridotta', 20, ' (RIDOTTA A 1/4)');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (215, 'ACC_T_TAS%', 'TOT_PRAT_RID', '07 - Totale dovuto Ridotto', 80, 'TOTALE IMPORTO CON ACQUIESCENZA ALL''ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (216, 'ACC_T_TAS%', 'TOT_PRAT_RID_ARR', '08 - Totale dovuto Ridotto Arrotondato', 80, 'TOTALE IMPORTO CON ACQUIESCENZA ALL''ACCERTAMENTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (217, 'ACC_T_TAS%', 'TIT_RID_2', '09 - Titolo in caso di definizione agevolata della sola sanzione', 192, 'TOTALE IMPORTO IN CASO DI DEFINIZIONE AGEVOLATA DELLA SOLA SANZIONE (pagamento entro 60 giorni dalla data di notifica del solo importo dovuto a titolo di sanzione con riduzione a 1/3):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (218, 'ACC_T_TAS%', 'DESC_SANZ_RID_2', '10 - Descrizione Sanzione Ridotta 2', 80, 'SANZIONE RIDOTTA a 1/3 ');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (219, 'ACC_T_TAS%', 'SEPARATORE_1', '11 - Separatore 1', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (220, 'ACC_T_TAS%', 'SEPARATORE_2', '12 - Separatore 2', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (221, 'ACC_T_TAS%', 'SEPARATORE_3', '13 - Separatore 3', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (222, 'ACC_TASI%', 'TOT', '01 - Totale dovuto', 73, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (223, 'ACC_TASI%', 'TOT_CONT_DOV_AR', '02 - Totale dovuto arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (224, 'ACC_TASI%', 'TOT_CONT_RIMB_AR', '03 - Totale rimborso arrotondato (Contribuente)', 48, 'TOTALE COMPLESSIVO ARROTONDATO DA RIMBORSARE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (225, 'ACC_TASI%', 'TOT_DOV_RID_AR', '04 - Totale ridotto arrotondato (Contribuente)', 47, 'TOTALE RIDOTTO CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (226, 'ACC_TASI%', 'INTESTAZIONE', '05 - Intestazione Imposte e Interessi', 12, 'ACCERTAMENTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (227, 'ACC_TASI%', 'TOT_PRAT_DOV', '06 - Totale dovuto (per pratica)', 69, 'TOTALE DOVUTO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (228, 'ACC_TASI%', 'TOT_PRAT_DOV_AR', '07 - Totale dovuto arrotondato (per pratica)', 69, 'TOTALE DOVUTO ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (229, 'ACC_TASI%', 'TOT_PRAT_DOV_RID', '08 - Totale con adesione formale (per pratica)', 69, 'TOTALE CON ADESIONE FORMALE');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (230, 'ACC_TASI%', 'TOT_PRAT_DOV_RID_AR', '09 - Totale con adesione formale arrotondato (per pratica)', 69, 'TOTALE CON ADESIONE FORMALE ARROTONDATO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (231, 'ACC_TASI%', 'TIT_RID', '10 - Titolo in caso di Acquiscenza', 192, 'TOTALE IMPORTO IN CASO DI ACQUIESCENZA ALL''ACCERTAMENTO (pagamento entro 60 giorni dalla notifica dell''imposta e della sanzione con riduzione a 1/4):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (232, 'ACC_TASI%', 'SUF_SANZ_RID', '11 - Suffisso Sanzione Ridotta', 20, ' (RIDOTTA A 1/4)');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (233, 'ACC_TASI%', 'TIT_RID_2', '12 - Titolo in caso di definizione agevolata della sola sanzione', 192, 'TOTALE IMPORTO IN CASO DI DEFINIZIONE AGEVOLATA DELLA SOLA SANZIONE (pagamento entro 60 giorni dalla data di notifica del solo importo dovuto a titolo di sanzione con riduzione a 1/3):');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (234, 'ACC_TASI%', 'DESC_SANZ_RID_2', '13 - Descrizione Sanzione Ridotta 2', 80, 'SANZIONE RIDOTTA a 1/3 ');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (235, 'ACC_TASI%', 'SEPARATORE_1', '14 - Separatore 1', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (236, 'ACC_TASI%', 'SEPARATORE_2', '15 - Separatore 2', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (237, 'ACC_TASI%', 'SEPARATORE_3', '16 - Separatore 3', 97, '_________________________________________________________________________________________________');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (238, 'COM_TARSU%', 'RATE_SCADUTE', '04 - STAMPA SOLO RATE SCADUTE SI/NO', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (239, 'ACC_TOSAP%', 'VIS_TOT_ARR', '35 - Visualizzazione Tot. Arr.', 2, 'SI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (240, 'ACC_ICP%', 'VIS_TOT_ARR', '06 - Visualizzazione Tot. Arr.', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (241, 'LIQ_TASIR%', 'DES_RIS_CAT', '03 - Descrizione Risultanze Catastali', 35, 'COME DA RISULTANZE CATASTALI');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (242, 'LIQ_TASIR%', 'DATI_DIC', '04 - Stampa dati dichiarati', 2, 'NO');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (243, 'COM_TARSU%', 'INT_NUM_FAM', '05 - DATI FAMILIARI - INTESTAZIONE NUMERO FAMILIARI', 10, 'Num.Fam.');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (244, 'COM_TARSU%', 'INT_DAL', '06 - DATI FAMILIARI/UTENZE NON DOM. - INTESTAZIONE INIZIO PERIODO (DAL)', 20, 'Dal');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (245, 'COM_TARSU%', 'INT_AL', '07 - DATI FAMILIARI/UTENZE NON DOM. - INTESTAZIONE FINE PERIODO (AL)', 20, 'Al');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (246, 'COM_TARSU%', 'INT_QF', '08 - DATI FAMILIARI/UTENZE NON DOM. - INTESTAZIONE QUOTA FISSA', 30, 'Quota Fissa');

insert into tipi_modello_parametri (PARAMETRO_ID, TIPO_MODELLO, PARAMETRO, DESCRIZIONE, LUNGHEZZA_MAX, TESTO_PREDEFINITO)
values (247, 'COM_TARSU%', 'INT_QV', '09 - DATI FAMILIARI/UTENZE NON DOM. - INTESTAZIONE QUOTA VARIABILE', 30, 'Quota Variabile');

ALTER TABLE tipi_modello_parametri ENABLE ALL TRIGGERS;
