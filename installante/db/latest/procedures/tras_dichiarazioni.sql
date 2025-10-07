--liquibase formatted sql 
--changeset abrandolini:20250326_152423_tras_dichiarazioni stripComments:false runOnChange:true 
 
create or replace procedure TRAS_DICHIARAZIONI
(a_anno      IN   number)
IS
MIN_REC      CONSTANT number(1) := 2;
errore                  exception;
w_errore                varchar2(2000);
w_100                   number;
w_cod_comune      number;
w_cod_provincia      number;
w_com_pro      varchar2(6);
w_des_comune      varchar2(25);
w_sigla_provincia   varchar2(2);
w_rec_trattati          number;
w_old_prtr      number;
w_riga         varchar2(498);
w_riga_vuota      varchar2(166);
w_progressivo           number;
w_tot_record_1      number;
w_tot_record_2      number;
w_tot_record_3      number;
w_tot_record_4      number;
w_appoggio      number;
w_num_modelli      number;
w_modello      number;
w_ufficio_registro   varchar2(25);
-- Attenzione il CENTRO CONSORTILE e' impostato a '000'.
-- Attenzione il PROTOCOLLO e' associato al Campo numero della Pratica.
-- Attenzione non sappiamo a cosa corrisponde il NUMERO_PACCO quindi lo impostiamo a 6 0.
-- Attenzione la percentuale di possesso e moltiplicata * 100 ossia 99.99 diventa 9999.
w_centro_cons      varchar2(3) := '000';
w_num_pacco      varchar2(6) := '000000';
-- Dati della Pratica
CURSOR sel_dati_prtr (p_anno number) IS
      select distinct prtr.pratica, ratr.cod_fiscale,
        rpad(nvl(numero,' '),8) protocollo, decode(deic.flag_firma,'S',0,1) flag_firma,
        nvl(to_char(prtr.data,'ddmmyy'),'000000') data_presentazione,
        lpad(nvl(deic.prefisso_telefonico,0),4,'0')||lpad(nvl(deic.num_telefonico,0),8,0) num_telefonico,
        rpad(nvl(denunciante,' '),60) denunciante, rpad(nvl(cod_fiscale_den,' '),16) cod_fiscale_den,
        rpad(nvl(substr(indirizzo_den,1,35),' '),35) indirizzo_den,
        rpad(nvl(substr(tica.descrizione,1,25),' '),25) carica_den,
        rpad(nvl(substr(comu_den.denominazione,1,25),' '),25) des_den, rpad(nvl(prov_den.sigla,' '),2) sigla_pro_den,
         lpad(nvl(comu_den.cap,0),5,'0') cap_den
        from ad4_comuni comu_den, ad4_provincie prov_den,
        tipi_carica tica, denunce_ici deic,
        rapporti_tributo ratr, pratiche_tributo prtr
       where comu_den.provincia_stato   = prov_den.provincia (+)
    and prtr.cod_com_den       = comu_den.comune (+)
    and prtr.cod_pro_den      = comu_den.provincia_stato (+)
    and tica.tipo_carica(+)    = prtr.tipo_carica
    and deic.pratica       = prtr.pratica
    and ratr.tipo_rapporto      = 'D'
    and ratr.pratica      = prtr.pratica
    and prtr.tipo_tributo||''   = 'ICI'
    and prtr.tipo_pratica      = 'D'
    and prtr.anno         = p_anno
       order by prtr.pratica
      ;
-- Dati Anagrafici del Dichiarante
CURSOR sel_dati_dich (p_cod_fiscale varchar2) IS
  SELECT sogg.ni, cont.cod_fiscale,
    rpad(nvl(sogg.cognome,' '),60) cognome, rpad(nvl(substr(sogg.nome,1,20),' '),20) nome,
    lpad(nvl(to_char(sogg.data_nas,'ddmmyy'),0),6,'0') data_nascita, nvl(sogg.sesso,' ') sesso,
    rpad(nvl(substr(decode(sogg.cod_via,null,sogg.denominazione_via,arvi.denom_uff),1,30),' '),30) indirizzo,
    sogg.cod_via, lpad(nvl(sogg.num_civ,0),5,'0') num_civ, rpad(nvl(sogg.suffisso,' '),5) suffisso,
         lpad(nvl(sogg.cap,0),5,'0') cap,
    rpad(nvl(sogg.rappresentante,' '),40) rappresentante, rpad(nvl(sogg.cod_fiscale_rap,' '),16) cod_fiscale_rap,
         rpad(nvl(sogg.indirizzo_rap,' '),50) indirizzo_rap, lpad(nvl(sogg.tipo_carica,0),4,'0') tipo_carica,
    rpad(nvl(comu_res.denominazione,' '),25) des_res,
    rpad(nvl(prov_res.sigla,' '),2) sigla_pro_res,
    rpad(nvl(comu_nas.denominazione,' '),25) des_nas,
    rpad(nvl(prov_nas.sigla,' '),2) sigla_pro_nas
    FROM ad4_comuni comu_res,
    ad4_provincie prov_res,
    ad4_comuni comu_nas ,
    ad4_provincie prov_nas ,
    archivio_vie arvi, soggetti sogg, contribuenti cont
   WHERE comu_res.provincia_stato   = prov_res.provincia (+)
     and sogg.cod_com_res       = comu_res.comune (+)
     and sogg.cod_pro_res      = comu_res.provincia_stato (+)
     and comu_nas.provincia_stato   = prov_nas.provincia (+)
     and sogg.cod_com_nas      = comu_nas.comune (+)
     and sogg.cod_pro_nas      = comu_nas.provincia_stato (+)
     and sogg.cod_via         = arvi.cod_via (+)
     and sogg.ni                = cont.ni
     and cont.cod_fiscale      = p_cod_fiscale
  ;
-- Dati del Contitolare
CURSOR sel_dati_cont (p_pratica number) IS
      select ratr.cod_fiscale,
        lpad(nvl(ogpr.NUM_ORDINE,0),5,'0') NUM_ORDINE,
        nvl(ogpr.MODELLO,0) MODELLO,
        lpad(round(nvl(ogco.PERC_POSSESSO,0) * 100),5,'0') PERC_POSSESSO,
        lpad(nvl(ogco.DETRAZIONE * w_100,0),6,'0') DETRAZIONE,
             lpad(nvl(ogco.MESI_ALIQUOTA_RIDOTTA,0),2,'0') MESI_AL_RIDOTTA,
        lpad(nvl(ogco.MESI_POSSESSO,0),2,'0') MESI_POSSESSO,
        decode(ogco.flag_possesso,'S',0,1) flag_possesso,
        decode(ogco.flag_esclusione,'S',0,1) flag_esclusione,
        decode(ogco.flag_riduzione,'S',0,1) flag_riduzione,
        decode(ogco.flag_ab_principale,'S',0,1) flag_ab_principale,
             decode(ogco.flag_al_ridotta,'S',0,1) flag_al_ridotta,
        rpad(nvl(substr(decode(sogg.COD_VIA,null,sogg.DENOMINAZIONE_VIA,arvi.DENOM_UFF),1,30),' '),30) indirizzo,
        lpad(nvl(sogg.num_civ,'0'),5,'0') num_civ,
        rpad(nvl(comu_res.DENOMINAZIONE,' '),25) des_res, rpad(nvl(prov_res.SIGLA,' '),2) sigla_pro_res
        from ad4_comuni comu_res, ad4_provincie prov_res,
        archivio_vie arvi, soggetti sogg,
        contribuenti cont,
        oggetti_pratica ogpr, oggetti_contribuente ogco,
        rapporti_tributo ratr, pratiche_tributo prtr
       where comu_res.provincia_stato   = prov_res.provincia (+)
    and sogg.cod_com_res       = comu_res.comune (+)
    and sogg.cod_pro_res      = comu_res.provincia_stato (+)
    and sogg.cod_via      = arvi.cod_via (+)
    and sogg.ni          = cont.ni
    and cont.cod_fiscale        = ratr.cod_fiscale
    and ogco.cod_fiscale       = ratr.cod_fiscale
    and ogco.oggetto_pratica   = ogpr.oggetto_pratica
    and ogpr.pratica      = ratr.pratica
    and ratr.tipo_rapporto      = 'C'
    and ratr.pratica      = prtr.pratica
    and prtr.pratica      = p_pratica
       order by ogpr.num_ordine desc
      ;
-- Dati dell'Oggetto Pratica
CURSOR sel_dati_ogpr (p_pratica number, p_cod_fiscale varchar2) IS
      select lpad(nvl(ogpr.NUM_ORDINE,0),5,'0') NUM_ORDINE,
        nvl(ogpr.MODELLO,0) MODELLO,
        lpad(nvl(ogpr.VALORE * w_100,0),13,'0') VALORE,
        decode(ogpr.imm_storico,'S',1,0) imm_storico,
        decode(ogpr.flag_provvisorio,'S',1,0) flag_provvisorio,
        decode(ogpr.titolo,'A',0,'C',1,2) acquisto, decode(ogpr.titolo,'C',0,'A',1,2) cessione,
        rpad(nvl(substr(estremi_titolo, 1, 25),' '),25) ufficio_registro,
        lpad(round(nvl(ogco.PERC_POSSESSO,0) * 100),5,'0') PERC_POSSESSO,
        lpad(nvl(ogco.DETRAZIONE * w_100,0),6,'0') DETRAZIONE,
             lpad(nvl(ogco.MESI_ALIQUOTA_RIDOTTA,0),2,'0') MESI_AL_RIDOTTA,
        lpad(nvl(ogco.MESI_POSSESSO,0),2,'0') MESI_POSSESSO,
        lpad(nvl(ogco.MESI_RIDUZIONE,0),2,'0') MESI_RIDUZIONE,
        lpad(nvl(ogco.MESI_ESCLUSIONE,0),2,'0') MESI_ESCLUSIONE,
        decode(ogco.flag_possesso,'S',0,1) flag_possesso,
        decode(ogco.flag_esclusione,'S',0,1) flag_esclusione,
        decode(ogco.flag_riduzione,'S',0,1) flag_riduzione,
        decode(ogco.flag_ab_principale,'S',0,1) flag_ab_principale,
             decode(ogco.flag_al_ridotta,'S',0,1) flag_al_ridotta,
        decode(oggetti.tipo_oggetto
              ,55,5
              ,decode(sign(oggetti.tipo_oggetto - 3)
                     ,1,4
                     ,substr(oggetti.tipo_oggetto,1,1)
                     )
              ) tipo_oggetto,
        rpad(nvl(decode(oggetti.cod_via, null, oggetti.indirizzo_localita, archivio_vie.denom_uff),' '),30) indirizzo,
        lpad(nvl(num_civ,0),5,'0') num_civ,
        rpad(nvl(partita,' '),8) partita,
        rpad(nvl(sezione,' '),3) sezione,
        rpad(nvl(foglio,' '),5) foglio,
        rpad(nvl(numero,' '),5) numero,
        rpad(nvl(subalterno,0),4,' ') subalterno,
        rpad(nvl(protocollo_catasto,' '),6) protocollo,
        rpad(nvl(substr(anno_catasto,3,2),0),2,'0') anno_catasto,
        rpad(nvl(ogpr.categoria_catasto, ' '),3) categoria,
        rpad(nvl(ogpr.classe_catasto,' '),2) classe
   FROM oggetti_contribuente ogco, oggetti_pratica ogpr,
        archivio_vie, oggetti
       WHERE oggetti.cod_via   = archivio_vie.cod_via (+)
    and oggetti.oggetto   = ogpr.oggetto
    and ogco.cod_fiscale    = p_cod_fiscale
    and ogco.oggetto_pratica   = ogpr.oggetto_pratica
    and ogpr.pratica      = p_pratica
       ORDER BY NUM_ORDINE
  ;
FUNCTION num_modelli_prtr (p_pratica number)
return number
IS
w_return number;
BEGIN
   BEGIN
      select decode(fase_euro,1,1,100)
        into w_100
        from dati_generali
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_100 := 100;
   END;
   BEGIN
   select ceil(count(1)/3)
     into w_return
     from oggetti_pratica
    where pratica = p_pratica
   ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
   WHEN OTHERS THEN
      RETURN -1;
   END;
   RETURN w_return;
END;
BEGIN  -- TRASMISSIONE_DIC_ANCI
  IF a_anno < 1998 THEN
     w_errore := 'Non e'' possibile effettuare la trasmissione per anni precedenti il 1998';
     RAISE errore;
  END IF;
  -- CONTROLLO DATI COMUNE
  BEGIN
     select com_cliente, pro_cliente
           into w_cod_comune, w_cod_provincia
           from dati_generali
   ;
   IF w_cod_comune is NULL OR w_cod_provincia is NULL THEN
        w_errore := 'Elaborazione terminata con anomalie:
                     mancano i codici identificativi del Comune.
                     Caricare la tabella relativa. ('||SQLERRM||')';
        RAISE errore;
   END IF;
  EXCEPTION
     WHEN no_data_found THEN
-- ATTENZIONE e'' giusto cosi?
          null;
     WHEN others THEN
          w_errore := 'Errore in ricerca Dati Generali. (1) ('||SQLERRM||')';
          RAISE errore;
  END;
  BEGIN
     select rpad(nvl(substr(comu.denominazione,1,25),' '),25), rpad(nvl(sigla,' '),2)
             into w_des_comune, w_sigla_provincia
       from ad4_comuni comu, ad4_provincie prov
      where provincia      = provincia_stato
        and comune         = w_cod_comune
        and provincia_stato   = w_cod_provincia
         ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore in ricerca dati Comune ('||SQLERRM||')';
        RAISE errore;
  END;
-- w_rec_trattati parte da MIN_REC perche i primi due record (tipo 0 e 1) vengono inseriti in fondo
  w_rec_trattati := MIN_REC;
  w_progressivo    := 0;
  w_old_prtr    := 0;
  w_tot_record_1 := 0;
  w_tot_record_2 := 0;
  w_tot_record_3 := 0;
  w_tot_record_4 := 0;
  w_com_pro    := lpad(w_cod_comune,3,'0')||lpad(w_cod_provincia,3,'0');
  FOR rec_prtr IN sel_dati_prtr(a_anno) LOOP
      IF w_old_prtr <> rec_prtr.pratica THEN
          w_old_prtr   := rec_prtr.pratica;
          w_progressivo   := w_progressivo + 1;
      END IF;
      w_num_modelli := num_modelli_prtr (rec_prtr.pratica);
-- TIPO RECORD  2
      FOR rec_dich IN sel_dati_dich (rec_prtr.cod_fiscale) LOOP
          w_tot_record_2 := w_tot_record_2 + 1;
          w_riga := '2'||w_centro_cons||w_com_pro||rec_prtr.protocollo||w_num_pacco
      ||lpad(w_progressivo,7,'0')||rec_prtr.data_presentazione;
          -- Dati Contribuente
          w_riga := w_riga||rpad(rec_dich.cod_fiscale,16)||rec_prtr.num_telefonico
                 ||rec_dich.cognome||rec_dich.nome||rec_dich.data_nascita||rec_dich.sesso
                 ||rec_dich.des_nas||rec_dich.sigla_pro_nas||rec_dich.indirizzo||rec_dich.num_civ
                 ||rec_dich.cap||rec_dich.des_res||rec_dich.sigla_pro_res;
          -- Dati Denunciante
          w_riga := w_riga||rpad(rec_prtr.cod_fiscale_den,16)||rec_prtr.carica_den||rec_prtr.denunciante
                 ||rec_prtr.indirizzo_den||rec_prtr.cap_den||rec_prtr.des_den
                 ||rec_prtr.sigla_pro_den||lpad(' ',84);
          BEGIN
             w_rec_trattati := w_rec_trattati + 1;
             insert into WRK_TRAS_ANCI
          (anno,progressivo,dati)
             values (a_anno,w_rec_trattati,w_riga)
             ;
          EXCEPTION
             WHEN others THEN
                w_errore := 'Errore in inserimento record tipo 2 ('||SQLERRM||')';
         RAISE errore;
          END;
      END LOOP;  -- rec_dich
-- TIPO RECORD  3
      w_riga := '';
      w_appoggio := 0;
      FOR rec_cont IN sel_dati_cont (rec_prtr.pratica) LOOP
      -- Dati Contitolare
          w_appoggio := w_appoggio + 1;
          w_riga := w_riga||rec_cont.num_ordine||rpad(rec_cont.cod_fiscale,16)||rec_cont.indirizzo||rec_cont.num_civ
             ||rec_cont.des_res||rec_cont.sigla_pro_res
             ||rec_cont.perc_possesso||rec_cont.mesi_possesso
                ||rec_cont.detrazione||rec_cont.mesi_al_ridotta
             ||rec_cont.flag_possesso||rec_cont.flag_esclusione
             ||rec_cont.flag_riduzione||rec_cont.flag_ab_principale
             ||rec_cont.flag_al_ridotta
                ||'0';  -- Non viene gestito il flag_firma nei dati del Contitolare = '0'
          w_modello := rec_cont.modello;
          IF w_appoggio = 3 THEN
             -- I contitolari vengono inseriti 3 alla volta
             w_tot_record_3 := w_tot_record_3 + 1;
             w_riga := '3'||w_centro_cons||w_com_pro||rec_prtr.protocollo||w_num_pacco
      ||lpad(w_progressivo,7,'0')||w_riga;
             w_riga := w_riga||lpad(rec_cont.modello,2,'0')||lpad(w_num_modelli,2,'0');
             w_riga := w_riga||'EUR'||lpad(' ',148);
             BEGIN
                w_rec_trattati := w_rec_trattati + 1;
                insert into WRK_TRAS_ANCI
                       (anno,progressivo,dati)
                values (a_anno,w_rec_trattati,w_riga)
                ;
             EXCEPTION
                WHEN others THEN
                     w_errore := 'Errore in inserimento record tipo 3 ('||SQLERRM||')';
                     RAISE errore;
             END;
             w_riga := '';
             w_appoggio := 0;
          END IF;
      END LOOP;  -- rec_cont
      IF w_appoggio > 0 AND w_appoggio < 3 THEN
         -- Bisogna completare il record con delle stringe vuote
         w_tot_record_3 := w_tot_record_3 + 1;
         w_riga := '3'||w_centro_cons||w_com_pro||rec_prtr.protocollo||w_num_pacco
      ||lpad(w_progressivo,7,'0')||w_riga;
         w_riga_vuota := lpad('0',5,'0')||lpad(' ',16)||lpad(' ',62)||lpad('0',5,'0')||lpad('0',2,'0')
         ||lpad('0',6,'0')||lpad(' ',2)||'0000'||' '||'0';
         w_riga := w_riga||w_riga_vuota;
         IF w_appoggio = 1 THEN
         -- Se ho SOLO un contitolare devo aggingere un altro record vuoto
            w_riga := w_riga||w_riga_vuota;
         END IF;
         w_riga := w_riga||lpad(w_modello,2,'0')||lpad(w_num_modelli,2,'0');
         w_riga := w_riga||'EUR'||lpad(' ',148);
         BEGIN
            w_rec_trattati := w_rec_trattati + 1;
            insert into WRK_TRAS_ANCI
         (anno,progressivo,dati)
                values (a_anno,w_rec_trattati,w_riga)
             ;
         EXCEPTION
            WHEN others THEN
       w_errore := 'Errore in inserimento record tipo 3 ('||SQLERRM||')';
       RAISE errore;
         END;
      END IF;
-- TIPO RECORD  4
      w_riga := '';
      w_appoggio := 0;
      FOR rec_ogpr IN sel_dati_ogpr (rec_prtr.pratica, rec_prtr.cod_fiscale) LOOP
          w_appoggio := w_appoggio + 1;
          w_riga := w_riga||rec_ogpr.num_ordine||rec_ogpr.tipo_oggetto||rec_ogpr.indirizzo||rec_ogpr.num_civ
               ||rec_ogpr.partita||rec_ogpr.sezione||rec_ogpr.foglio||rec_ogpr.numero||rec_ogpr.subalterno
         ||rec_ogpr.protocollo||rec_ogpr.anno_catasto||rec_ogpr.categoria||rec_ogpr.classe
         ||rec_ogpr.imm_storico||rec_ogpr.valore||rec_ogpr.flag_provvisorio
         ||rec_ogpr.perc_possesso||rec_ogpr.mesi_possesso
         ||rec_ogpr.mesi_esclusione||rec_ogpr.mesi_riduzione
         ||rec_ogpr.detrazione||rec_ogpr.mesi_al_ridotta
                ||rec_ogpr.flag_possesso||rec_ogpr.flag_esclusione
                ||rec_ogpr.flag_riduzione||rec_ogpr.flag_ab_principale
                ||rec_ogpr.flag_al_ridotta||rec_ogpr.acquisto||rec_ogpr.cessione
                ||rec_ogpr.ufficio_registro;
          w_modello := nvl(rec_ogpr.modello,0);
          w_ufficio_registro := rec_ogpr.ufficio_registro;
          IF w_appoggio = 3 THEN
             -- Gli oggettii vengono inseriti 3 alla volta
             w_tot_record_4 := w_tot_record_4 + 1;
             w_riga := '4'||w_centro_cons||w_com_pro||rec_prtr.protocollo||w_num_pacco
      ||lpad(w_progressivo,7,'0')||w_riga;
             w_riga := w_riga||lpad(w_modello,2,'0')||lpad(w_num_modelli,2,'0')||rec_prtr.flag_firma;
             w_riga := w_riga||'EUR'||lpad(' ',24);
             BEGIN
            w_rec_trattati := w_rec_trattati + 1;
            insert into WRK_TRAS_ANCI
         (anno,progressivo,dati)
                 values (a_anno,w_rec_trattati,w_riga)
            ;
             EXCEPTION
                       WHEN others THEN
             w_errore := 'Errore in inserimento record tipo 4 ('||SQLERRM||')';
             RAISE errore;
             END;
             w_riga := '';
             w_appoggio := 0;
          END IF;
      END LOOP;
      IF w_appoggio > 0 AND w_appoggio < 3 THEN
          w_tot_record_4 := w_tot_record_4 + 1;
          w_riga := '4'||w_centro_cons||w_com_pro||rec_prtr.protocollo||w_num_pacco
      ||lpad(w_progressivo,7,'0')||w_riga;
          w_riga_vuota := lpad('0',5,'0')||' '||lpad(' ',35)||lpad(' ',8)||lpad(' ',3)
                   ||lpad(' ',5)||lpad(' ',5)||lpad('0',4,'0')||lpad(' ',6)||'00'
                   ||lpad(' ',3)||lpad(' ',2)||'0'||lpad('0',13,'0')||'0'||lpad('0',5,'0')
                   ||lpad('0',2,'0')||lpad('0',2,'0')||lpad('0',2,'0')
                   ||lpad('0',6,'0')||lpad(' ',2)||'0000'||' '||'22'
                   ||lpad(' ',25);
          w_riga := w_riga||w_riga_vuota;
          IF w_appoggio = 1 THEN
          -- Se ho SOLO un oggetto devo aggingere un altro record vuoto
             w_riga := w_riga||w_riga_vuota;
          END IF;
          w_riga := w_riga||lpad(w_modello,2,'0')||lpad(w_num_modelli,2,'0')||rec_prtr.flag_firma;
          w_riga := w_riga||'EUR'||lpad(' ',24);
          BEGIN
               w_rec_trattati := w_rec_trattati + 1;
               insert into WRK_TRAS_ANCI
                     (anno,progressivo,dati)
                        values (a_anno,w_rec_trattati,w_riga)
               ;
          EXCEPTION
              WHEN others THEN
           w_errore := 'Errore in inserimento record tipo 4 ('||SQLERRM||')';
           RAISE errore;
          END;
      END IF;  -- w_appoggio < w_tot_record_4
  END LOOP;  -- rec_prtr
  IF w_rec_trattati = MIN_REC THEN
     w_errore := 'Non ci sono variazioni da Trasmettere. ('||SQLERRM||')';
     RAISE errore;
  ELSE
       -- CREAZIONE TIPO RECORD 0
        w_riga := '0'||'000'||lpad(' ',26)||'Variazioni dichiarazioni ICI'||substr(a_anno,-2)
        ||w_des_comune||'000'||to_char(sysdate,'ddmmyy')||'EUR'||lpad(' ',401);
        BEGIN
           insert into WRK_TRAS_ANCI (anno,progressivo,dati)
                  values (a_anno,1,w_riga)
      ;
        EXCEPTION
           WHEN others THEN
      w_errore := 'Errore in inserimento record di testa 0 ('||SQLERRM||')';
      RAISE errore;
        END;
      -- CREAZIONE TIPO RECORD 1
        w_riga := '1'||lpad(' ',26)||w_des_comune||w_sigla_provincia||'EUR'||lpad(' ',441);
        BEGIN
      insert into WRK_TRAS_ANCI (anno,progressivo,dati)
                  values (a_anno,2,w_riga)
      ;
        EXCEPTION
           WHEN others THEN
      w_errore := 'Errore in inserimento record di testa 1 ('||SQLERRM||')';
      RAISE errore;
   END;
      -- CREAZIONE TIPO RECORD 5
        w_riga := '5'||lpad(' ',26)||w_des_comune||w_sigla_provincia||lpad(w_rec_trattati+2,13,'0')
        ||lpad(w_tot_record_2,13,'0')||lpad(w_tot_record_3,13,'0')||lpad(w_tot_record_4,13,'0')
        ||'EUR'||lpad(' ',389);
        BEGIN
      insert into WRK_TRAS_ANCI (anno,progressivo,dati)
                  values (a_anno,w_rec_trattati+1,w_riga)
      ;
        EXCEPTION
           WHEN others THEN
      w_errore := 'Errore in inserimento record di coda 5 ('||SQLERRM||')';
      RAISE errore;
   END;
        -- CREAZIONE TIPO RECORD 6
        w_riga := '6'||lpad(' ',26)||'Variazioni dichiarazioni ICI'||substr(a_anno,-2)
        ||w_des_comune||'000'
        ||lpad(w_tot_record_2,13,'0')||lpad(w_tot_record_3,13,'0')||lpad(w_tot_record_4,13,'0')
        ||lpad(1,13,'0')||'EUR'||lpad(' ',358);
        BEGIN
      insert into WRK_TRAS_ANCI (anno,progressivo,dati)
                  values (a_anno,w_rec_trattati+2,w_riga)
      ;
        EXCEPTION
           WHEN others THEN
      w_errore := 'Errore in inserimento record di coda 6 ('||SQLERRM||')';
      RAISE errore;
   END;
  END IF;  -- w_rec_trattati = MIN_REC
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN others THEN
        ROLLBACK;
   RAISE_APPLICATION_ERROR
          (-20999,'Errore in Trasmissione Dichiarazioni ANCI su supporto magnetico ('||SQLERRM||')');
END;
/* End Procedure: TRAS_DICHIARAZIONI */
/

