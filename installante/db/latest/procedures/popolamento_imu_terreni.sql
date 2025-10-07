--liquibase formatted sql 
--changeset abrandolini:20250326_152423_popolamento_imu_terreni stripComments:false runOnChange:true 
 
create or replace procedure POPOLAMENTO_IMU_TERRENI
/*************************************************************************
 Versione  Data              Autore    Descrizione
 6         19/02/2020        VD        Archiviazione ultima denuncia inserita
 5         10/01/2020        VD        Aggiunta archiviazione denunce
 4         21/10/2019        VD        Corretta composizione estremi catasto:
                                       sostituita RPAD con LPAD
 3         23/01/2015        AB        Con Betta x Malnate:
                                       Aggiunta la gestione della sezione
 2         15/01/2015        VD        Aggiunto parametro ESCLUSIONE:
                                       se è = 'S', l'oggetto viene inserito
                                       in oggetti_contribuente con
                                       mesi_esclusione = 12 e
                                       flag_esclusione = 'S''
 1         14/01/2015        VD        Aggiunta fonte in ins. soggetti
                                       e gestione RIFERIMENTI_OGGETTO
 0         09/01/2015        VD        Prima emissione
*************************************************************************/
(  a_cod_fiscale          VARCHAR2 DEFAULT '%',
   a_fonte                NUMBER,
   a_titolo               VARCHAR2 DEFAULT '%',
   a_esclusione           VARCHAR2 DEFAULT NULL)
IS
   w_anno                 NUMBER := 2014;
   w_utente               VARCHAR2 (6) := 'CIMUT';
   w_ni                   soggetti.ni%TYPE;
   w_ni_cont              contribuenti.ni%TYPE;
   w_num_ordine           oggetti_pratica.num_ordine%TYPE := 0;
   w_cognome_nome_cata    VARCHAR2 (150);
   w_data_nas_cata        DATE;
   w_des_com_nas_cata     VARCHAR2 (40);
   w_tipo_soggetto_cata   VARCHAR2 (1);
   w_aliquota             NUMBER;
   w_cod_fiscale          VARCHAR2 (16) := 'ZZZZZZZZZZZZZZZZ';
   w_primo_oggetto        BOOLEAN;
   w_sezione              VARCHAR2 (3);
   w_foglio               VARCHAR2 (5);
   w_numero               VARCHAR2 (5);
   w_subalterno           VARCHAR2 (4);
   w_estremi_catasto      VARCHAR2 (20);
   w_oggetto              NUMBER;
   w_nuovo_oggetto        BOOLEAN;
   w_pratica              NUMBER;
   w_oggetto_pratica      NUMBER;
   w_moltiplicatore       NUMBER;
   w_categoria            VARCHAR2 (3) := 'T';
   w_controllo            VARCHAR2 (1);
   w_cod_via              VARCHAR2 (100);
   w_num_civ_numb         NUMBER;
   w_note                 VARCHAR2(2000) := 'Popolamento IMU terreni da CATASTO eseguito il '
                                            || TO_CHAR (SYSDATE, 'dd/mm/yyyy');
   w_conta_sogg           NUMBER := 0;
   w_conta_cont           NUMBER := 0;
   --Gestione delle eccezioni
   w_errore               VARCHAR2 (2000);
   errore                 EXCEPTION;
   -- Recupera i soggetti o i contribuenti presenti o da catasto
   CURSOR sel_cont
   IS
      SELECT NVL (
                NVL (cont.cod_fiscale,
                     NVL (sogg.cod_fiscale, sogg.partita_iva)),
                pcur.cod_fiscale)
                cod_fiscale,
             pcur.id_soggetto
        FROM contribuenti cont,
             soggetti sogg,
             proprietari_catasto_urbano pcur
       WHERE     cont.cod_fiscale(+) =
                    NVL (sogg.cod_fiscale, sogg.partita_iva)
             AND sogg.cod_fiscale(+) = pcur.cod_fiscale
             AND pcur.cod_fiscale LIKE a_cod_fiscale
             AND pcur.cod_titolo LIKE a_titolo
             AND pcur.tipo_immobile = 'T'
             AND NOT EXISTS
                        (SELECT 1
                           FROM pratiche_tributo prtr
                          WHERE     prtr.cod_fiscale = pcur.cod_fiscale
                                AND prtr.utente = w_utente
                                AND prtr.anno = w_anno
                                AND prtr.note like 'Popolamento IMU terreni da CATASTO eseguito il%')
      UNION
      SELECT NVL (
                NVL (cont.cod_fiscale,
                     NVL (sogg.cod_fiscale, sogg.partita_iva)),
                pcur.cod_fiscale),
             pcur.id_soggetto
        FROM contribuenti cont,
             soggetti sogg,
             proprietari_catasto_urbano pcur
       WHERE     cont.cod_fiscale(+) =
                    NVL (sogg.cod_fiscale, sogg.partita_iva)
             AND sogg.partita_iva(+) = pcur.cod_fiscale
             AND pcur.cod_fiscale LIKE a_cod_fiscale
             AND pcur.cod_titolo LIKE a_titolo
             AND pcur.tipo_immobile = 'T'
             AND NOT EXISTS
                        (SELECT 1
                           FROM pratiche_tributo prtr
                          WHERE     prtr.cod_fiscale = pcur.cod_fiscale
                                AND prtr.utente = w_utente
                                AND prtr.anno = w_anno
                                AND prtr.note like 'Popolamento IMU terreni da CATASTO eseguito il%')
      ORDER BY 1;
   --Recupera gli oggetti di un dato proprietario
   CURSOR sel_imm (
      p_id_soggetto    NUMBER)
   IS
      SELECT DISTINCT
             to_char(icur.id_immobile) id_immobile,
             icur.indirizzo indirizzo,
             icur.num_civ num_civ,
             icur.partita partita,
             icur.sezione sezione,
             icur.foglio foglio,
             icur.numero numero,
             icur.subalterno subalterno,
             icur.qualita qualita,
             icur.classe classe,
             icur.ettari ettari,
             icur.are    are,
             icur.centiare centiare,
             icur.reddito_dominicale_euro rendita,
             ROUND (
                  (  TO_NUMBER (icur.numeratore)
                   / TO_NUMBER (icur.denominatore))
                * 100,
                2)
                possesso,
             icur.data_efficacia,
             icur.data_iscrizione
        FROM immobili_catasto_terreni icur
       WHERE     icur.id_soggetto = p_id_soggetto
             AND icur.data_efficacia =
                    (SELECT MAX (icub.data_efficacia)
                       FROM immobili_catasto_terreni icub
                      WHERE     icub.id_soggetto = p_id_soggetto
                            AND NVL (icur.partita, ' ') =
                                   NVL (icub.partita, ' ')
                            AND NVL (icur.foglio, ' ') =
                                   NVL (icub.foglio, ' ')
                            AND NVL (icur.numero, ' ') =
                                   NVL (icub.numero, ' ')
                            AND NVL (icur.subalterno, ' ') =
                                   NVL (icub.subalterno, ' ')
                            AND NVL (icur.sezione, ' ') =
                                   NVL (icub.sezione, ' ')) --group by icur.indirizzo
                                                              --       , icur.num_civ
                                                              --       , icur.scala
                                                              --       , icur.piano
                                                              --       , icur.interno
                                                              --       , icur.sezione
                                                              --       , icur.foglio
                                                              --       , icur.numero
                                                              --       , icur.subalterno
                                                              --       , icur.zona
                                                              --       , icur.partita
                                                              --       , icur.categoria
                                                              --       , icur.classe
                                                              --       , icur.consistenza
                                                              --       , icur.rendita
                                                              --       , round((to_number(icur.numeratore)/to_number(icur.denominatore))* 100,2)
;
   FUNCTION f_num_civ_str_to_numb (a_num_civ_str IN VARCHAR2)
      RETURN NUMBER
   IS
      w_i              NUMBER;
      w_appoggio       VARCHAR2 (30) := NULL;
      w_controllo      VARCHAR2 (1);
      w_num_civ_numb   NUMBER;
   BEGIN
      IF LENGTH (RTRIM (a_num_civ_str)) > 0
      THEN
         LOOP
            BEGIN
               SELECT 'X'
                 INTO w_controllo
                 FROM DUAL
                WHERE SUBSTR (a_num_civ_str, w_i, 1) IN ('0',
                                                         '1',
                                                         '2',
                                                         '3',
                                                         '4',
                                                         '5',
                                                         '6',
                                                         '7',
                                                         '8',
                                                         '9');
            EXCEPTION
               WHEN OTHERS
               THEN
                  EXIT;
            END;
            w_appoggio := w_appoggio || SUBSTR (a_num_civ_str, w_i, 1);
         END LOOP;
      END IF;
      --dbms_output.put_line(appoggio);
      RETURN TO_NUMBER (w_appoggio);
   END f_num_civ_str_to_numb;
   FUNCTION f_get_oggetto (a_id_immobile       IN     VARCHAR2,
                           a_is_nuovo             OUT BOOLEAN)
      RETURN NUMBER
   IS
      d_contatore   NUMBER;
      d_oggetto     NUMBER;
   BEGIN
      a_is_nuovo := FALSE;
      BEGIN
         SELECT ogge.oggetto
           INTO d_oggetto
           FROM oggetti ogge
          WHERE     ogge.tipo_oggetto + 0 in (1,2)
                AND ogge.cod_ecografico = a_id_immobile
                AND ROWNUM = 1;
      --se arrivo qui l'oggetto esiste
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            d_oggetto := NULL;
         WHEN OTHERS
         THEN
            raise_application_error (
               -20999,
                  'POPOLAMENTO_IMU_TERRENI - Fallita verifica base esistenza oggetto con estremi '
               || w_estremi_catasto);
      END;
      IF d_oggetto IS NULL
      THEN
         a_is_nuovo := TRUE;
         oggetti_nr (d_oggetto);
      END IF;
      RETURN d_oggetto;
   END /*f_get_oggetto*/;
-------------------------
-- INIZIO ELABORAZIONE --
-------------------------
BEGIN
   -- dbms_output.put_line ('PRIMO');
   BEGIN
      SELECT aliquota
        INTO w_aliquota
        FROM rivalutazioni_rendita
       WHERE anno = w_anno AND tipo_oggetto = 1;
   -- dbms_output.put_line ('RIVALUTAZIONI RENDITA');
   EXCEPTION
      WHEN OTHERS
      THEN
         w_errore :=
            (   'Errore nella ricerca dell''aliquota in rivalutazioni rendita'
             || ' ('
             || SQLERRM
             || ')');
         RAISE errore;
   END;
   FOR rec_cont IN sel_cont
   LOOP
      IF rec_cont.cod_fiscale != w_cod_fiscale
      THEN
         if w_pratica is not null then
            ARCHIVIA_DENUNCE('','',w_pratica);
         end if;
         COMMIT;
         w_cod_fiscale := rec_cont.cod_fiscale;
         w_primo_oggetto := TRUE;
         w_num_ordine := 0;
         w_ni := NULL;
         w_ni_cont := NULL;
         w_cognome_nome_cata := NULL;
         w_data_nas_cata := NULL;
         w_des_com_nas_cata := NULL;
         w_tipo_soggetto_cata := NULL;
      END IF;
      --dbms_output.put_line('CF: ' || w_cod_fiscale);
      IF w_ni_cont IS NULL
      THEN
         BEGIN
            SELECT cont.ni
              INTO w_ni_cont
              FROM contribuenti cont
             WHERE cont.cod_fiscale = w_cod_fiscale;
         EXCEPTION
            WHEN OTHERS
            THEN
               w_ni_cont := NULL;
         END;
      END IF;
      IF w_ni IS NULL
      THEN
         BEGIN
            SELECT sogg.ni
              INTO w_ni
              FROM soggetti sogg
             WHERE NVL (sogg.cod_fiscale(+), sogg.partita_iva(+)) =
                      w_cod_fiscale;
         EXCEPTION
            WHEN OTHERS
            THEN
               w_ni := NULL;
         END;
      END IF;
      IF w_ni IS NULL
      THEN
         BEGIN
            SELECT SUBSTR (cognome_nome, 1, 60),
                   data_nas,
                   des_com_nas,
                   tipo_soggetto
              INTO w_cognome_nome_cata,
                   w_data_nas_cata,
                   w_des_com_nas_cata,
                   w_tipo_soggetto_cata
              FROM proprietari_catasto_urbano
             WHERE cod_fiscale = w_cod_fiscale AND ROWNUM = 1;
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  ('Errore in lettura dati catasto' || ' (' || SQLERRM || ')');
               RAISE errore;
         END;
         SOGGETTI_NR (w_ni);
         BEGIN
            INSERT INTO soggetti (ni,
                                  cognome_nome,
                                  data_nas,
                                  cod_pro_nas,
                                  cod_com_nas,
                                  cod_fiscale,
                                  partita_iva,
                                  tipo_residente,
                                  tipo,
                                  fonte,
                                  utente)
                    VALUES (
                              w_ni,
                              w_cognome_nome_cata,
                              w_data_nas_cata,
                              f_get_campo_ad4_com (NULL,
                                                   NULL,
                                                   w_des_com_nas_cata,
                                                   'S',
                                                   NULL,
                                                   'S',
                                                   NULL,
                                                   'COD_PROVINCIA'),
                              f_get_campo_ad4_com (NULL,
                                                   NULL,
                                                   w_des_com_nas_cata,
                                                   'S',
                                                   NULL,
                                                   'S',
                                                   NULL,
                                                   'COD_COMUNE'),
                              DECODE (LENGTH (w_cod_fiscale),
                                      16, w_cod_fiscale,
                                      ''),
                              DECODE (LENGTH (w_cod_fiscale),
                                      11, w_cod_fiscale,
                                      ''),
                              1,
                              DECODE (w_tipo_soggetto_cata,
                                      'P', 0,
                                      'G', 1,
                                      2),
                              a_fonte,
                              w_utente);
         --dbms_output.put_line('Insert in soggetto. '||w_cod_fiscale||' ');
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in inserimento soggetto '
                   || w_cod_fiscale
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
         w_conta_sogg := w_conta_sogg + 1;
      END IF;
      IF w_ni_cont IS NULL
      THEN
         BEGIN
            INSERT INTO contribuenti (ni, cod_fiscale)
                 VALUES (w_ni, w_cod_fiscale);
         --dbms_output.put_line('Insert in contribuenti. '||w_cod_fiscale||' ');
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in inserimento contribuente '
                   || w_cod_fiscale
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
         w_conta_cont := w_conta_cont + 1;
      END IF;
      FOR rec_imm IN sel_imm (rec_cont.id_soggetto)
      LOOP
         --Controlla se l'oggetto è già presente in Oggetti
         --dbms_output.put_line ('SONO DENTRO');
         w_sezione := rec_imm.SEZIONE;
         w_foglio := rec_imm.foglio;
         w_numero := rec_imm.numero;
         w_subalterno := rec_imm.subalterno;
         w_num_civ_numb := f_num_civ_str_to_numb (rec_imm.num_civ);
         --dbms_output.put_line('dopo la rec_imm.');
         IF w_sezione || w_foglio || w_numero || w_subalterno IS NOT NULL
         THEN
            w_estremi_catasto :=
                  LPAD (LTRIM (NVL (w_sezione, ' '), '0'), 3, ' ')
               || LPAD (LTRIM (NVL (w_foglio, ' '), '0'), 5, ' ')
               || LPAD (LTRIM (NVL (w_numero, ' '), '0'), 5, ' ')
               || LPAD (LTRIM (NVL (w_subalterno, ' '), '0'), 4, ' ')
               || LPAD (' ', 3);
            w_oggetto :=
               f_get_oggetto (rec_imm.id_immobile,
                              w_nuovo_oggetto);
         END IF;
         IF w_primo_oggetto
         THEN
            --Si sta trattando il primo oggetto del contribuente, quindi bisogna inserire:
            --pratiche_tributo e...
            w_pratica := null;
            pratiche_tributo_nr (w_pratica);
--            dbms_output.put_line('prima della pratica.');
            BEGIN
               INSERT INTO pratiche_tributo (pratica,
                                             cod_fiscale,
                                             tipo_tributo,
                                             anno,
                                             tipo_pratica,
                                             tipo_evento,
                                             data,
                                             utente,
                                             data_variazione,
                                             note)
                       VALUES (
                                 w_pratica,
                                 w_cod_fiscale,
                                 'ICI',
                                 w_anno,
                                 'D',
                                 'I',
                                 TRUNC (SYSDATE),
                                 w_utente,
                                 TRUNC (SYSDATE),
                                 w_note
                              );
--            dbms_output.put_line('Insert in pratiche_tributo. '||w_pratica);
            EXCEPTION
               WHEN OTHERS
               THEN
                  w_errore :=
                     (   'Errore in in inserimento nuova pratica x cf: '
                      || w_cod_fiscale
                      || ' ('
                      || SQLERRM
                      || ')');
                  RAISE errore;
            END;
            -- DENUNCE ICI (IMU)
            BEGIN
               INSERT INTO denunce_ici (pratica,
                                        denuncia,
                                        fonte,
                                        utente,
                                        data_variazione,
                                        note)
                       VALUES (
                                 w_pratica,
                                 w_pratica,
                                 a_fonte,
                                 w_utente,
                                 SYSDATE,
                                 w_note
                              );
--            dbms_output.put_line('Insert in denunce_ici.');
            EXCEPTION
               WHEN OTHERS
               THEN
                  w_errore :=
                     (   'Errore in in inserimento nuova denuncia IMU'
                      || ' ('
                      || SQLERRM
                      || ')');
                  RAISE errore;
            END;
            -- ...rapporti_tributo
            BEGIN
               INSERT
                 INTO rapporti_tributo (pratica, cod_fiscale, tipo_rapporto)
               VALUES (w_pratica, w_cod_fiscale, 'D');
--            dbms_output.put_line('Insert in rapporti_tributo.');
            EXCEPTION
               WHEN OTHERS
               THEN
                  w_errore :=
                     (   'Errore in in inserimento rapporto tributo'
                      || ' ('
                      || SQLERRM
                      || ')');
                  RAISE errore;
            END;
            w_primo_oggetto := FALSE;
         END IF;
         IF w_nuovo_oggetto
         THEN
            --Occorre inserire il nuovo oggetto in Oggetti
            --dbms_output.put_line('Nuovo oggetto per il contribuente: ' || w_cod_fiscale || ' (' || w_estremi_catasto || ')');
            --Recupero del cod_via
            BEGIN
               SELECT DISTINCT devi.cod_via
                 INTO w_cod_via
                 FROM denominazioni_via devi
                WHERE devi.descrizione LIKE rec_imm.indirizzo || '%';
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  w_cod_via := '';
               WHEN TOO_MANY_ROWS
               THEN
                  w_cod_via := '';
               WHEN OTHERS
               THEN
                  w_errore :=
                     ('Errore in ricerca cod_via' || ' (' || SQLERRM || ')');
                  RAISE errore;
            END;
            --Inserimento nuovo oggetto
            BEGIN
               INSERT INTO oggetti (oggetto,
                                    tipo_oggetto,
                                    indirizzo_localita,
                                    cod_via,
                                    num_civ,
                                    sezione,
                                    foglio,
                                    numero,
                                    subalterno,
                                    estremi_catasto,
                                    partita,
                                    categoria_catasto,
                                    classe_catasto,
                                    qualita,
                                    ettari,
                                    are,
                                    centiare,
                                    cod_ecografico,
                                    fonte,
                                    utente,
                                    data_variazione,
                                    note)
                       VALUES (
                                 w_oggetto,
                                 1,
                                 SUBSTR (
                                       rec_imm.indirizzo
                                    || ' '
                                    || rec_imm.num_civ,
                                    1,
                                    36),
                                 w_cod_via,
                                 w_num_civ_numb,
                                 w_sezione,
                                 w_foglio,
                                 w_numero,
                                 w_subalterno,
                                 w_estremi_catasto,
                                 rec_imm.partita,
                                 w_categoria,
                                 rec_imm.classe,
                                 rec_imm.qualita,
                                 rec_imm.ettari,
                                 rec_imm.are,
                                 rec_imm.centiare,
                                 rec_imm.id_immobile,
                                 a_fonte,
                                 w_utente,
                                 TRUNC (SYSDATE),
                                 w_note
                              );
            --dbms_output.put_line('Nuovo oggetto inserito per il contribuente: ' || w_cod_fiscale || ' (' || w_estremi_catasto || ')');
            EXCEPTION
               WHEN OTHERS
               THEN
                  --dbms_output.put_line('Nuovo oggetto per il contribuente: ' || w_cod_fiscale || ' (' || w_estremi_catasto || ')');
                  w_errore :=
                     (   'Errore in inserimento oggetto'
                      || ' ('
                      || SQLERRM
                      || ')');
                  RAISE errore;
            END;
            --Inserimento nuovo record in riferimenti_oggetto
            --(solo se la rendita non è nulla)
            if rec_imm.rendita is not null then
               BEGIN
                  INSERT INTO riferimenti_oggetto ( oggetto,
                                                    inizio_validita,
                                                    fine_validita,
                                                    da_anno,
                                                    a_anno,
                                                    rendita,
                                                    anno_rendita,
                                                    categoria_catasto,
                                                    classe_catasto,
                                                    data_reg,
                                                    data_reg_atti,
                                                    utente,
                                                    data_variazione,
                                                    note )
                  VALUES ( w_oggetto,
                           rec_imm.data_efficacia,
                           to_date('31/12/9999','dd/mm/yyyy'),
                           to_number(to_char(rec_imm.data_efficacia,'yyyy')),
                           9999,
                           rec_imm.rendita,
                           to_number(to_char(rec_imm.data_iscrizione,'yyyy')),
                           w_categoria,
                           rec_imm.classe,
                           rec_imm.data_iscrizione,
                           rec_imm.data_iscrizione,
                           w_utente,
                           TRUNC (SYSDATE),
                           w_note );
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     w_errore :=
                        (   'Errore in inserimento riferimento oggetto'
                         || ' ('
                         || SQLERRM
                         || ')');
                     RAISE errore;
               END;
            end if;
         END IF;
         --Inserimento dati in oggetti_pratica
         BEGIN
            SELECT moltiplicatore
              INTO w_moltiplicatore
              FROM moltiplicatori molti
             WHERE     molti.anno = w_anno
                   AND molti.categoria_catasto = w_categoria;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               w_moltiplicatore := 1;
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in ricerca moltiplicatore'
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
         w_num_ordine := w_num_ordine + 1;
         BEGIN
            w_oggetto_pratica := null;
            oggetti_pratica_nr (w_oggetto_pratica);
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in ricerca oggetto_pratica'
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
--         dbms_output.put_line(' nuovo w_oggetto_pratica '||w_oggetto_pratica);
         BEGIN
            INSERT INTO oggetti_pratica (oggetto_pratica,
                                         oggetto,
                                         pratica,
                                         anno,
                                         num_ordine,
                                         categoria_catasto,
                                         classe_catasto,
                                         valore,
                                         fonte,
                                         utente,
                                         data_variazione,
                                         note,
                                         tipo_oggetto)
                    VALUES (
                              w_oggetto_pratica,
                              w_oggetto,
                              w_pratica,
                              w_anno,
                              LPAD (w_num_ordine, 5, '0'),
                              w_categoria,
                              rec_imm.classe,
                              ROUND (
                                   (  (rec_imm.rendita * w_moltiplicatore)
                                    * (100 + w_aliquota))
                                 / 100,
                                 2),
                              a_fonte,
                              w_utente,
                              TRUNC (SYSDATE),
                              w_note,
                              1);
--         dbms_output.put_line('Insert in oggetti_pratica.');
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in in inserimento oggetto pratica'
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
         --Inserimento dati in oggetti_contribuente
         BEGIN
            INSERT INTO oggetti_contribuente (cod_fiscale,
                                              oggetto_pratica,
                                              anno,
                                              tipo_rapporto,
                                              perc_possesso,
                                              mesi_possesso,
                                              mesi_possesso_1sem,
                                              mesi_esclusione,
                                              detrazione,
                                              flag_possesso,
                                              flag_esclusione,
                                              flag_riduzione,
                                              flag_ab_principale,
                                              utente,
                                              data_variazione,
                                              note)
                    VALUES (
                              w_cod_fiscale,
                              w_oggetto_pratica,
                              w_anno,
                              'D',                                -- tipo_rapporto
                              NVL (rec_imm.possesso, 0),
                              12,                                 -- mesi_possesso
                              6,                                  -- mesi_possesso_1sem
                              null,                               -- mesi_esclusione
                              NULL,                               -- detrazione
                              'S',                                -- flag_possesso
                              decode(a_esclusione,'S','S',null),  -- flag_esclusione
                              NULL,                               -- flag_riduzione
                              NULL,                               -- flag_ab_principale
                              w_utente,
                              TRUNC (SYSDATE),
                              w_note
                           );
--         dbms_output.put_line('Insert in oggetti_contribuente.');
         EXCEPTION
            WHEN OTHERS
            THEN
               w_errore :=
                  (   'Errore in in inserimento oggetto contribuente'
                   || ' ('
                   || SQLERRM
                   || ')');
               RAISE errore;
         END;
      END LOOP;
   END LOOP;
   -- (VD - 19/02/2020): Archiviazione ultima denuncia inserita
   if w_pratica is not null then
      ARCHIVIA_DENUNCE('','',w_pratica);
   end if;
   DBMS_OUTPUT.put_line ('Soggetti inseriti: ' || w_conta_sogg || ' ');
   DBMS_OUTPUT.put_line ('Contribuenti inseriti: ' || w_conta_cont || ' ');
   COMMIT;
EXCEPTION
   WHEN errore
   THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR (-20999, w_errore);
   WHEN OTHERS
   THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR (
         -20999,
            'Errore in POPOLAMENTO_IMU_TERRENI cf:'
         || w_cod_fiscale
         || ' ('
         || SQLERRM
         || ')');
END;
/* End Procedure: POPOLAMENTO_IMU_TERRENI */
/

