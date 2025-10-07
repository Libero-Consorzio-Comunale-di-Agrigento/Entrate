--liquibase formatted sql 
--changeset abrandolini:20250326_152423_popolamento_tasi_catasto stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure         POPOLAMENTO_TASI_CATASTO
/*************************************************************************
 Versione  Data              Autore    Descrizione
 5         06/11/2023        AB        Gestione di w_anno_prtr per anni diversi dal 2014
                                       per trattare anche efficaie e validata successive
 4         17/10/2023        AB        Controllo fabbricati con progr_identificativo = 1
                                       e usando anche estremi_catasto
 3         10/01/2020        VD        Aggiunta archiviazione denunce
 2         21/10/2019        VD        Corretta composizione estremi catasto:
                                       sostituita RPAD con LPAD
 1         14/01/2015        VD        Aggiunta fonte in ins. soggetti
*************************************************************************/
(  a_cod_fiscale    VARCHAR2 DEFAULT '%',
   a_fonte          NUMBER,
   a_titolo         VARCHAR2 DEFAULT '%',
   a_log            in out VARCHAR2)
IS
   w_anno                 NUMBER := 2014;
   w_utente               VARCHAR2 (6) := 'CTASI';
   w_note                 oggetti_pratica.note%TYPE;
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
   w_categoria            VARCHAR2 (3);
   w_controllo            VARCHAR2 (1);
   w_flag_ab_p            VARCHAR2 (1);
   w_cod_via              VARCHAR2 (100);
   w_num_civ_numb         NUMBER;
   w_conta_sogg           NUMBER := 0;
   w_conta_cont           NUMBER := 0;
   w_conta_prat           NUMBER := 0;
   w_n_sogg_elab          NUMBER := 0;
   w_cognome_nome         soggetti.cognome_nome%TYPE;
   w_mp                   NUMBER(2);
   w_mp_1sem              NUMBER(1);
   w_flag_possesso        VARCHAR2(1);
   w_anno_prtr            NUMBER(4);
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
                cod_fiscale
        FROM contribuenti cont,
             soggetti sogg,
             proprietari_catasto_urbano pcur
       WHERE     cont.cod_fiscale(+) =
                    NVL (sogg.cod_fiscale, sogg.partita_iva)
             AND sogg.cod_fiscale(+) = pcur.cod_fiscale
             AND pcur.cod_fiscale LIKE a_cod_fiscale
             AND pcur.cod_titolo LIKE a_titolo
             AND NOT EXISTS
                        (SELECT 1
                           FROM pratiche_tributo prtr
                          WHERE     prtr.cod_fiscale = pcur.cod_fiscale
                                AND prtr.utente = w_utente
                                AND prtr.anno = w_anno)
      UNION
      SELECT NVL (
                NVL (cont.cod_fiscale,
                     NVL (sogg.cod_fiscale, sogg.partita_iva)),
                pcur.cod_fiscale)
        FROM contribuenti cont,
             soggetti sogg,
             proprietari_catasto_urbano pcur
       WHERE     cont.cod_fiscale(+) =
                    NVL (sogg.cod_fiscale, sogg.partita_iva)
             AND sogg.partita_iva(+) = pcur.cod_fiscale
             AND pcur.cod_fiscale LIKE a_cod_fiscale
             AND pcur.cod_titolo LIKE a_titolo
             AND NOT EXISTS
                        (SELECT 1
                           FROM pratiche_tributo prtr
                          WHERE     prtr.cod_fiscale = pcur.cod_fiscale
                                AND prtr.utente = w_utente
                                AND prtr.anno = w_anno)
      ORDER BY 1;
   --Recupera gli oggetti di un dato proprietario
   CURSOR sel_imm (
      p_cod_fiscale    VARCHAR2)
   IS
      SELECT DISTINCT
             icur.indirizzo indirizzo,
             icur.num_civ num_civ,
             icur.scala scala,
             icur.piano piano,
             icur.interno interno,
             icur.sezione sezione,
             icur.foglio foglio,
             icur.numero numero,
             icur.subalterno subalterno,
             icur.zona zona,
             icur.partita partita,
             icur.categoria categoria,
             icur.classe classe,
             icur.consistenza consistenza,
             icur.rendita rendita,
             ROUND (
                  (  TO_NUMBER (icur.numeratore)
                   / TO_NUMBER (icur.denominatore))
                * 100,
                2)
                possesso,
             icur.estremi_catasto,
             icur.contatore,
             icur.data_efficacia,
             icur.data_fine_efficacia,
             icur.data_validita,
             icur.data_fine_validita,
             greatest(icur.data_validita,icur.data_efficacia) validita,
             to_char(greatest(icur.data_validita,icur.data_efficacia),'yyyy') anno_validita,
             nvl(icur.data_fine_validita,nvl(icur.data_fine_efficacia - 1, to_date('31/12/2999','dd/mm/yyyy'))) fine_validita
        FROM immobili_soggetto_cc icur
       WHERE icur.cod_fiscale_ric = p_cod_fiscale
         and icur.progr_identificativo = 1  -- (17/10/2023) AB per evitare di trattare immobili stesso ID_IMMOBILE due volte
         AND icur.data_efficacia =
                    (SELECT MAX (icub.data_efficacia)  -- qui usiamo la MAX a differenza del caricamento IMU dove c'è la MIN....
                       FROM immobili_soggetto_cc icub
                      WHERE icub.cod_fiscale_ric = p_cod_fiscale
                        and icub.estremi_catasto = icur.estremi_catasto)  --17/10/2023 AB come nel poplamento IMU per andare per indice
       order by to_char(greatest(icur.data_validita,icur.data_efficacia),'yyyy'),
                greatest(icur.data_validita,icur.data_efficacia)
--                            AND NVL (icur.sezione, ' ') =
--                                   NVL (icub.sezione, ' ')
--                            AND NVL (icur.foglio, ' ') =
--                                   NVL (icub.foglio, ' ')
--                            AND NVL (icur.numero, ' ') =
--                                   NVL (icub.numero, ' ')
--                            AND NVL (icur.subalterno, ' ') =
--                                   NVL (icub.subalterno, ' ')) --group by icur.indirizzo
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
   FUNCTION f_get_oggetto (a_estremi_catasto   IN     VARCHAR2,
                           a_categoria         IN     VARCHAR2,
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
          WHERE     ogge.tipo_oggetto + 0 = 3
                AND ogge.estremi_catasto = a_estremi_catasto
                AND NVL (ogge.categoria_catasto, ' ') =
                       NVL (w_categoria, ' ')
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
                  'POPOLAMENTO_TASI_CATASTO - Fallita verifica base esistenza oggetto con estremi '
               || w_estremi_catasto);
      END;
      -- non c'è un oggetto con quegli estremi,
      -- ma potrebbe esserci un altro oggetto
      -- con estremi diversi ma stesso contatore (graffato)
      IF d_oggetto IS NULL
      THEN
         SELECT NVL (MIN (contatore), 0)
           INTO d_contatore
           FROM immobili_catasto_urbano
          WHERE estremi_catasto = a_estremi_catasto;
         FOR i IN (SELECT estremi_catasto
                     FROM immobili_catasto_urbano
                    WHERE contatore = d_contatore)
         LOOP
            BEGIN
               SELECT MIN (oggetto)
                 INTO d_oggetto
                 FROM oggetti
                WHERE     estremi_catasto = i.estremi_catasto
                      AND NVL (categoria_catasto, ' ') =
                             NVL (w_categoria, ' ');
               IF d_oggetto IS NOT NULL
               THEN
                  EXIT;
               END IF;
            END;
         END LOOP;
      END IF;
      IF d_oggetto IS NULL
      THEN
         a_is_nuovo := TRUE;
         oggetti_nr (d_oggetto);
      END IF;
      RETURN d_oggetto;
   END /*f_get_oggetto*/;
BEGIN
   -- dbms_output.put_line ('PRIMO');
   FOR rec_cont IN sel_cont
   LOOP
      IF rec_cont.cod_fiscale != w_cod_fiscale
      THEN
         AGGIORNA_DA_MESE_POSSESSO(w_cod_fiscale);
         -- (VD - 10/01/2020): Archiviazione denuncia appena inserita
         if w_pratica is not null then
            ARCHIVIA_DENUNCE('','',w_pratica);
         end if;
         COMMIT;
         w_cod_fiscale := rec_cont.cod_fiscale;
         w_primo_oggetto := TRUE;
         w_num_ordine := 0;
         w_anno_prtr := w_anno;
         w_ni := NULL;
         w_ni_cont := NULL;
         w_cognome_nome_cata := NULL;
         w_data_nas_cata := NULL;
         w_des_com_nas_cata := NULL;
         w_tipo_soggetto_cata := NULL;
         w_cognome_nome := NULL;
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
                                                   'COD_COMUNE') --                   ,case
                                                                --                      when length(w_cod_fiscale) = 16 then w_cod_fiscale
                                                                --                    end
                                                                --                   ,case
                                                                --                      when length(w_cod_fiscale) = 11 then w_cod_fiscale
                                                                --                    end
                              ,
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
      BEGIN
          SELECT sogg.cognome_nome
          INTO   w_cognome_nome
          FROM contribuenti cont,
               soggetti sogg
          WHERE
               cont.ni = sogg.ni
               and cont.cod_fiscale = w_cod_fiscale;
      END;
      w_n_sogg_elab := w_n_sogg_elab + 1;
      a_log := a_log || '---------------------------------------------------------------------------------' || chr(13);
      a_log := a_log || 'Elaborazione soggetto ' || w_cognome_nome || ' - ' || w_cod_fiscale || chr(13);

      FOR rec_imm IN sel_imm (w_cod_fiscale)
      LOOP
         --Controlla se l'oggetto è già presente in Oggetti
         --dbms_output.put_line ('SONO DENTRO');
         if not w_primo_oggetto
         and w_anno_prtr < rec_imm.anno_validita then
            w_primo_oggetto := TRUE;
            w_num_ordine := 0;
            w_anno_prtr := rec_imm.anno_validita;
         end if;
         w_sezione := rec_imm.sezione;
         w_foglio := rec_imm.foglio;
         w_numero := rec_imm.numero;
         w_subalterno := rec_imm.subalterno;
         w_categoria := rec_imm.categoria;
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
               f_get_oggetto (w_estremi_catasto,
                              w_categoria,
                              w_nuovo_oggetto);
         END IF;
         IF w_primo_oggetto
         THEN
            --Si sta trattando il primo oggetto di un anno per il contribuente, quindi bisogna inserire:
            --pratiche_tributo e...
            w_conta_prat := w_conta_prat + 1;
            w_pratica := null;
            pratiche_tributo_nr (w_pratica);
            dbms_output.put_line('prima della pratica.');

            if w_anno_prtr < rec_imm.anno_validita then
               w_anno_prtr := rec_imm.anno_validita;
            end if;

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
                                 'TASI',
                                 w_anno_prtr,
                                 'D',
                                 'I',
                                 TRUNC (SYSDATE),
                                 w_utente,
                                 TRUNC (SYSDATE),
                                    'Popolamento TASI da CATASTO eseguito il '
                                 || TO_CHAR (SYSDATE, 'dd/mm/yyyy'));
            dbms_output.put_line('Insert in pratiche_tributo. '||w_pratica);
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
            -- DENUNCE TASI
            BEGIN
               INSERT INTO denunce_tasi (pratica,
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
                                    'Popolamento TASI da CATASTO eseguito il '
                                 || TO_CHAR (SYSDATE, 'dd/mm/yyyy'));
            dbms_output.put_line('Insert in denunce_tasi.');
            EXCEPTION
               WHEN OTHERS
               THEN
                  w_errore :=
                     (   'Errore in in inserimento nuova denuncia tasi'
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
            dbms_output.put_line('Insert in rapporti_tributo.');
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
            --Reucpero del cod_via
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
            IF w_categoria IS NOT NULL
            THEN
               BEGIN
                  SELECT 'x'
                    INTO w_controllo
                    FROM categorie_catasto
                   WHERE categoria_catasto = w_categoria;
               EXCEPTION
                  WHEN NO_DATA_FOUND
                  THEN
                     BEGIN
                        INSERT
                          INTO categorie_catasto (categoria_catasto,
                                                  descrizione)
                        VALUES (w_categoria, 'DA POPOLAMENTO TASI CATASTO');
                        a_log := a_log || 'Inserito oggetto ' ||
                                          w_oggetto || ' con categoria ' ||
                                          w_categoria || ' e con valore = rendita.' || chr(13);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           RAISE_APPLICATION_ERROR (
                              -20999,
                                 'Errore in inserimento Categorie Catasto'
                              || ' ('
                              || SQLERRM
                              || ')');
                     END;
                  WHEN OTHERS
                  THEN
                     RAISE_APPLICATION_ERROR (
                        -20999,
                           'Errore in ricerca Categorie Catasto'
                        || ' ('
                        || SQLERRM
                        || ')');
               END;
            END IF;
            BEGIN
               INSERT INTO oggetti (oggetto,
                                    tipo_oggetto,
                                    indirizzo_localita,
                                    cod_via,
                                    num_civ,
                                    scala,
                                    piano,
                                    interno,
                                    sezione,
                                    foglio,
                                    numero,
                                    subalterno,
                                    zona,
                                    estremi_catasto,
                                    partita,
                                    categoria_catasto,
                                    classe_catasto,
                                    consistenza,
                                    fonte,
                                    utente,
                                    data_variazione,
                                    note)
                       VALUES (
                                 w_oggetto,
                                 3,
                                 SUBSTR (
                                       rec_imm.indirizzo
                                    || ' '
                                    || rec_imm.num_civ
                                    || ' '
                                    || rec_imm.scala
                                    || ' '
                                    || rec_imm.piano
                                    || ' '
                                    || rec_imm.interno,
                                    1,
                                    36),
                                 w_cod_via,
                                 w_num_civ_numb,
                                 rec_imm.scala,
                                 SUBSTR (rec_imm.piano, 1, 5),
                                 DECODE (afc.is_numeric (rec_imm.interno),
                                         0, NULL,
                                         SUBSTR (rec_imm.interno, 1, 2)),
                                 w_sezione,
                                 w_foglio,
                                 w_numero,
                                 w_subalterno,
                                 rec_imm.zona,
                                 w_estremi_catasto,
                                 rec_imm.partita,
                                 w_categoria,
                                 rec_imm.classe,
                                 rec_imm.consistenza,
                                 a_fonte,
                                 w_utente,
                                 TRUNC (SYSDATE),
                                    'Popolamento TASI da CATASTO eseguito il '
                                 || TO_CHAR (SYSDATE, 'dd/mm/yyyy'));
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
         END IF;
         --Se nn presente si inserisce la categoria in categorie_catasto
         IF w_categoria IS NOT NULL
         THEN
            BEGIN
               SELECT 'x'
                 INTO w_controllo
                 FROM categorie_catasto
                WHERE categoria_catasto = w_categoria;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     INSERT
                       INTO categorie_catasto (categoria_catasto,
                                               descrizione)
                        VALUES (
                                  w_categoria,
                                  'Inserita automaticamente da Versamenti');
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        w_errore :=
                           (   'Errore in inserimento Categorie Catasto'
                            || ' ('
                            || SQLERRM
                            || ')');
                        RAISE errore;
                  END;
               WHEN OTHERS
               THEN
                  w_errore :=
                     (   'Errore in ricerca Categorie Catasto'
                      || ' ('
                      || SQLERRM
                      || ')');
                  RAISE errore;
            END;
         END IF;
         --Inserimento dati in oggetti_pratica
         BEGIN
            SELECT aliquota
              INTO w_aliquota
              FROM rivalutazioni_rendita
             WHERE anno = w_anno_prtr AND tipo_oggetto = 3;
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
         BEGIN
            SELECT moltiplicatore
              INTO w_moltiplicatore
              FROM moltiplicatori molti
             WHERE molti.anno = w_anno_prtr
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
         dbms_output.put_line(' nuovo w_oggetto_pratica '||w_oggetto_pratica);
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
                              w_anno_prtr,
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
                                 'Popolamento TASI da CATASTO eseguito il '
                              || TO_CHAR (SYSDATE, 'dd/mm/yyyy'),
                              3);
         dbms_output.put_line('Insert in oggetti_pratica.');
         a_log := a_log || 'Inserito oggetto ' ||
                         w_oggetto || chr(13);
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
         ---- CONTROLLO RESIDENZA
         IF     f_indirizzo_ni_al (
                   w_ni,
                   TO_DATE ('31/12/' || w_anno_prtr, 'dd/mm/yyyy')) =
                      NVL (LPAD (w_cod_via, 6, '0'), '      ')
                   || NVL (LPAD (w_num_civ_numb, 6, '0'), '      ')
            AND w_categoria IN ('A01',
                                'A02',
                                'A03',
                                'A04',
                                'A05',
                                'A06',
                                'A07',
                                'A08',
                                'A09',
                                'A11')
         THEN
            w_flag_ab_p := 'S';
         ELSE
            w_flag_ab_p := NULL;
         END IF;
         begin  -- 06/11/2023 per recuperare i mesi corretti per annio successivi
            select f_get_mesi_possesso('TASI', w_cod_fiscale, w_anno_prtr, w_oggetto, rec_imm.validita, rec_imm.fine_validita),
                   f_get_mesi_possesso_1sem(rec_imm.validita, rec_imm.fine_validita),
                   case
                      when rec_imm.fine_validita < to_date('15/12/'||w_anno_prtr,'dd/mm/yyyy') then
                           null
                      else
                           'S'
                   end case
              into w_mp,
                   w_mp_1sem,
                   w_flag_possesso
              from dual;
         end;
--            raise_application_error (
--               -20999,
--                  'anno '||w_anno_prtr||' mesi_pos '||w_mp||' mesi 1s '||w_mp_1sem||' flag '||w_flag_possesso||' date '
--                  ||rec_imm.validita||' fine '||rec_imm.fine_validita);
--         w_mp       := 12;
--         w_mp_1sem  := 6;
--         w_flag_possesso := 'S';

         BEGIN
            INSERT INTO oggetti_contribuente (cod_fiscale,
                                              oggetto_pratica,
                                              anno,
                                              tipo_rapporto,
                                              perc_possesso,
                                              mesi_possesso,
                                              mesi_possesso_1sem,
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
                              w_anno_prtr,
                              'D',
                              NVL (rec_imm.possesso, 0),
                              w_mp,--12,
                              w_mp_1sem,--6,
                              NULL,
                              w_flag_possesso,--'S',
                              NULL,
                              NULL,
                              w_flag_ab_p,
                              w_utente,
                              TRUNC (SYSDATE),
                                 'Popolamento TASI da CATASTO eseguito il '
                              || TO_CHAR (SYSDATE, 'dd/mm/yyyy'));
         dbms_output.put_line('Insert in oggetti_contribuente.');
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
         a_log := a_log || 'Per l''oggetto '|| w_oggetto || ' elaborata pratica ' || w_pratica || chr(13);
      END LOOP;
   END LOOP;
   -- (VD - 10/01/2020): Archiviazione ultima denuncia inserita
   if w_pratica is not null then
      ARCHIVIA_DENUNCE('','',w_pratica);
   end if;
   AGGIORNA_DA_MESE_POSSESSO(w_cod_fiscale);
   DBMS_OUTPUT.put_line ('Soggetti inseriti: ' || w_conta_sogg || ' ');
   DBMS_OUTPUT.put_line ('Contribuenti inseriti: ' || w_conta_cont || ' ');
   DBMS_OUTPUT.put_line ('Pratiche inserite: ' || w_conta_prat || ' ');

   a_log := a_log || '---------------------------------------------------------------------------------' || chr(13);
   a_log := a_log || 'Elaborati ' || w_n_sogg_elab || ' soggetti.' || chr(13);
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
            'Errore in POPOLAMENTO_TASI_CATASTO cf:'
         || w_cod_fiscale
         || ' ('
         || SQLERRM
         || ')');
END;
/* End Procedure: POPOLAMENTO_TASI_CATASTO */
/
