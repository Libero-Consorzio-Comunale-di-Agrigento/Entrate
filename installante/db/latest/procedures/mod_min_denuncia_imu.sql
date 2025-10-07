--liquibase formatted sql 
--changeset abrandolini:20250326_152423_mod_min_denuncia_imu stripComments:false runOnChange:true 
 
create or replace procedure MOD_MIN_DENUNCIA_IMU
(a_sessione          in number
,a_pratica           in number
) is
-- Pre-Trattamento dei dati per la stampa del modello
-- ministeriale di denuncia IMU.
--
-- Data la struttura del modello, sorge il problema
-- di individuare quanti moduli stampare per ogni denuncia.
-- Questo numero viene stabilito dal numero degli oggetti
-- della pratica o dal numero dei contitolari.
-- Ogni singolo modello riporta fino ad un massimo di 3 oggetti
-- e di 2 contitolari.
-- Si analizzano quindi i dati della denuncia e, per ogni 3 oggetti
-- e/o 2 contitolari o per il numero dei rimanenti a fine analisi
-- dei dati, si inserisce in parametri una registrazione con:
-- sessione da parametri di procedura, nome parametro = 'MODMINDENIMU'
-- che sta per Modello Ministeriale Denuncia IMU, progressivo di 1 in 1
-- a partire da 1 e valore che contiene stringati:
-- Pratica     10 caratteri con zeri a sinistra
-- Codice Fiscale del Denunciante 16 caratteri con spazi a destra
-- memorizzato dalla pratica, Numero di 1 carattere che indica
-- il destinatario del modello (per Contribuente, per Comune, ecc...)
-- di 1 carattere coi valori che vanno da 1 a 3
-- Numero di Modello 3 caratteri con zeri a sinistra
-- Numero Totale di Modelli 3 caratteri con zeri a sinistra
-- Codice Fiscale Contitolare 16 caratteri con spazi a destra
-- Oggetto Pratica Contitolare 10 caratteri con zeri a sinistra
-- Codice Fiscale Contitolare 16 caratteri con spazi a destra
-- Oggetto Pratica Contitolare 10 caratteri con zeri a sinistra
-- Oggetto Pratica 10 caratteri con zeri a sinistra
-- Oggetto Pratica 10 caratteri con zeri a sinistra
-- Oggetto Pratica 10 caratteri con zeri a sinistra
-- i dati numerici non significativi sono una stringa di zeri
-- mentre gli alfanumerici non significativi sono una stringa di spazi
cursor sel_contitolari (p_pratica in number) is
select ogco.cod_fiscale         cod_fiscale
      ,ogco.oggetto_pratica     oggetto_pratica
  from oggetti_contribuente     ogco
      ,oggetti_pratica          ogpr
      ,pratiche_tributo         prtr
      ,contribuenti             cont
      ,soggetti                 sogg
 where ogco.oggetto_pratica     = ogpr.oggetto_pratica
   and ogpr.pratica             = prtr.pratica
   and cont.cod_fiscale         = ogco.cod_fiscale
   and sogg.ni                  = cont.ni
   and prtr.pratica             = p_pratica
   and ogco.cod_fiscale        <> prtr.cod_fiscale
 order by
       decode(instr(ogpr.num_ordine,'/')
             ,0,lpad(ogpr.num_ordine,10,' ')
               ,lpad(substr(ogpr.num_ordine,1,instr(ogpr.num_ordine,'/') - 1),10,' ')||'/'||
                lpad(substr(ogpr.num_ordine,instr(ogpr.num_ordine,'/') + 1),10,' ')
             )
      ,sogg.cognome
      ,sogg.nome
      ,ogpr.oggetto_pratica
;
cursor sel_oggetti (p_pratica in number) is
select ogpr.oggetto_pratica     oggetto_pratica
  from oggetti_pratica          ogpr
      ,archivio_vie             arvi
      ,oggetti                  ogge
      ,pratiche_tributo         prtr
 where ogpr.pratica             = prtr.pratica
   and ogge.oggetto             = ogpr.oggetto
   and arvi.cod_via (+)         = ogge.cod_via
   and prtr.pratica             = p_pratica
 order by
       decode(instr(ogpr.num_ordine,'/')
             ,0,lpad(ogpr.num_ordine,10,' ')
               ,lpad(substr(ogpr.num_ordine,1,instr(ogpr.num_ordine,'/') - 1),10,' ')||'/'||
                lpad(substr(ogpr.num_ordine,instr(ogpr.num_ordine,'/') + 1),10,' ')
             )
      ,nvl(arvi.denom_uff,ogge.Indirizzo_localita)
;
nProgressivo               number;
nMax_Progressivo           number;
nConta                     number;
nConta_Modelli             number;
nTot_Modelli               number;
sStringa                   varchar2(2000);
sStringa2                  varchar2(2000);
sStringa3                  varchar2(2000);
sCod_Fiscale               varchar2(16);
fine                       exception;
BEGIN
   BEGIN
      select cod_fiscale
        into sCod_Fiscale
        from pratiche_tributo
       where pratica = a_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20999,'Non rilegge la Pratica '||to_char(a_pratica));
   END;
--
-- Eliminazione di eventuali parametri corrispondenti
-- alle caratteristiche dei parametri da inserire.
--
   BEGIN
      delete from parametri
       where sessione       = a_sessione
         and nome_parametro = 'MODMINDENIMU'
      ;
   END;
   commit;
--
-- Si contano i moduli necessari per la denuncia
-- (1 ogni 2 contitolari e/o 3 oggetti).
--
   nProgressivo     := 0;
--
-- Analisi dei contitolari.
--
   FOR rec_contitolari in sel_contitolari (a_pratica)
   LOOP
      nProgressivo := nProgressivo + 1;
   END LOOP;
   nProgressivo := ceil(nProgressivo / 2);
   nMax_Progressivo := nProgressivo;
--
   nProgressivo := 0;
--
-- Analisi degli Oggetti.
--
   FOR rec_oggetti in sel_oggetti (a_pratica)
   LOOP
      nProgressivo := nProgressivo + 1;
   END LOOP;
   nProgressivo := ceil(nProgressivo / 3);
   if nProgressivo > nMax_Progressivo then
      nMax_Progressivo := nProgressivo;
   end if;
--
-- Il Max_Progressivo contiene il numero totale
-- dei modelli da trattare.
--
   nTot_Modelli := nMax_Progressivo;
--
-- Trattamento dei singoli contitolari.
-- I codici fiscali e gli oggetti pratica vengono stringati
-- a 2 a 2 e solo al secondo contitolare viene
-- registrata la tabella parametri.
--
   nProgressivo   := 0;
   nConta         := 0;
   nConta_Modelli := 0;
   sStringa       := '';
   FOR rec_contit in sel_contitolari (a_pratica)
   LOOP
      nConta := nConta + 1;
      sStringa := sStringa||rpad(rec_contit.cod_fiscale,16,' ')||
                            lpad(to_char(rec_contit.oggetto_pratica),10,'0');
      if nConta = 2 then
         nConta         := 0;
         nConta_Modelli := nConta_Modelli + 1;
         nProgressivo   := nProgressivo + 1;
         sStringa2 := lpad(to_char(a_pratica),10,'0')||
                      rpad(sCod_Fiscale,16,' ')||'1'||
                      lpad(to_char(nConta_Modelli),3,'0')||
                      lpad(to_char(nTot_Modelli),3,'0')||
                      sStringa||'000000000000000000000000000000';
         BEGIN
            insert into parametri
                  (sessione,nome_parametro,progressivo,valore)
            values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
         END;
         sStringa2 := lpad(to_char(a_pratica),10,'0')||
                      rpad(sCod_Fiscale,16,' ')||'2'||
                      lpad(to_char(nConta_Modelli),3,'0')||
                      lpad(to_char(nTot_Modelli),3,'0')||
                      sStringa||'000000000000000000000000000000';
         nProgressivo   := nProgressivo + 1;
         BEGIN
            insert into parametri
                  (sessione,nome_parametro,progressivo,valore)
            values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
         END;
--       Insert per terzo modulo che non esiste nella denuncia IMU
--         sStringa2 := lpad(to_char(a_pratica),10,'0')||
--                      rpad(sCod_Fiscale,16,' ')||'3'||
--                      lpad(to_char(nConta_Modelli),3,'0')||
--                      lpad(to_char(nTot_Modelli),3,'0')||
--                      sStringa||'000000000000000000000000000000';
--         nProgressivo   := nProgressivo + 1;
--         BEGIN
--            insert into parametri
--                  (sessione,nome_parametro,progressivo,valore)
--            values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
--         END;
         sStringa := '';
      end if;
   END LOOP;
   if nConta > 0 then
      sStringa := sStringa||'                0000000000';
      if nConta = 1 then
         sStringa := sStringa||'                0000000000';
      end if;
      nConta         := 0;
      nConta_Modelli := nConta_Modelli + 1;
      nProgressivo   := nProgressivo + 1;
      sStringa2 := lpad(to_char(a_pratica),10,'0')||
                   rpad(sCod_Fiscale,16,' ')||'1'||
                   lpad(to_char(nConta_Modelli),3,'0')||
                   lpad(to_char(nTot_Modelli),3,'0')||
                   sStringa||'000000000000000000000000000000';
      BEGIN
         insert into parametri
               (sessione,nome_parametro,progressivo,valore)
         values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
      END;
      sStringa2 := lpad(to_char(a_pratica),10,'0')||
                   rpad(sCod_Fiscale,16,' ')||'2'||
                   lpad(to_char(nConta_Modelli),3,'0')||
                   lpad(to_char(nTot_Modelli),3,'0')||
                   sStringa||'000000000000000000000000000000';
      nProgressivo   := nProgressivo + 1;
      BEGIN
         insert into parametri
               (sessione,nome_parametro,progressivo,valore)
         values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
      END;
--       Insert per terzo modulo che non esiste nella denuncia IMU
--      sStringa2 := lpad(to_char(a_pratica),10,'0')||
--                   rpad(sCod_Fiscale,16,' ')||'3'||
--                   lpad(to_char(nConta_Modelli),3,'0')||
--                   lpad(to_char(nTot_Modelli),3,'0')||
--                   sStringa||'000000000000000000000000000000';
--      nProgressivo   := nProgressivo + 1;
--      BEGIN
--         insert into parametri
--               (sessione,nome_parametro,progressivo,valore)
--         values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
--      END;
      sStringa := '';
   end if;
--   RAISE FINE;
--
-- Trattamento dei singoli oggetti.
-- Gli oggetti pratica vengono stringati
-- a 3 a 3 e solo al terzo oggetto pratica viene
-- registrata la tabella parametri.
--
   nProgressivo   := 0;
   nConta         := 0;
   nConta_Modelli := 0;
   sStringa       := '';
   FOR rec_ogge in sel_oggetti (a_pratica)
   LOOP
      nConta := nConta + 1;
      sStringa := sStringa||lpad(to_char(rec_ogge.oggetto_pratica),10,'0');
      if nConta = 3 then
         nConta         := 0;
         nConta_Modelli := nConta_Modelli + 1;
         nProgressivo   := nProgressivo + 1;
         BEGIN
            select para.valore
              into sStringa3
              from parametri para
             where para.sessione         = a_sessione
               and para.nome_parametro   = 'MODMINDENIMU'
               and para.progressivo      = nProgressivo
            ;
            sStringa2 := substr(sStringa3,1,26)||'1'||
                         substr(sStringa3,28,84)||sStringa;
            BEGIN
               update parametri
                  set valore             = sStringa2
                where sessione           = a_sessione
                  and nome_parametro     = 'MODMINDENIMU'
                  and progressivo        = nProgressivo
               ;
            END;
            sStringa2 := substr(sStringa3,1,26)||'2'||
                         substr(sStringa3,28,84)||sStringa;
            nProgressivo := nProgressivo + 1;
            BEGIN
               update parametri
                  set valore             = sStringa2
                where sessione           = a_sessione
                  and nome_parametro     = 'MODMINDENIMU'
                  and progressivo        = nProgressivo
               ;
            END;
--            sStringa2 := substr(sStringa3,1,26)||'3'||
--                         substr(sStringa3,28,84)||sStringa;
--            nProgressivo := nProgressivo + 1;
--            BEGIN
--               update parametri
--                  set valore             = sStringa2
--                where sessione           = a_sessione
--                  and nome_parametro     = 'MODMINDENIMU'
--                  and progressivo        = nProgressivo
--               ;
--            END;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               sStringa2 := lpad(to_char(a_pratica),10,'0')||
                            rpad(sCod_Fiscale,16,' ')||'1'||
                            lpad(to_char(nConta_Modelli),3,'0')||
                            lpad(to_char(nTot_Modelli),3,'0')||
                            '                0000000000'||
                            '                0000000000'||
                            '                0000000000'||sStringa;
               BEGIN
                  insert into parametri
                        (sessione,nome_parametro,progressivo,valore)
                  values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
               END;
               sStringa2 := lpad(to_char(a_pratica),10,'0')||
                            rpad(sCod_Fiscale,16,' ')||'2'||
                            lpad(to_char(nConta_Modelli),3,'0')||
                            lpad(to_char(nTot_Modelli),3,'0')||
                            '                0000000000'||
                            '                0000000000'||
                            '                0000000000'||sStringa;
               nProgressivo := nProgressivo + 1;
               BEGIN
                  insert into parametri
                        (sessione,nome_parametro,progressivo,valore)
                  values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
               END;
--               sStringa2 := lpad(to_char(a_pratica),10,'0')||
--                            rpad(sCod_Fiscale,16,' ')||'3'||
--                            lpad(to_char(nConta_Modelli),3,'0')||
--                            lpad(to_char(nTot_Modelli),3,'0')||
--                            '                0000000000'||
--                            '                0000000000'||
--                            '                0000000000'||sStringa;
--               nProgressivo := nProgressivo + 1;
--               BEGIN
--                  insert into parametri
--                        (sessione,nome_parametro,progressivo,valore)
--                  values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
--               END;
         END;
         sStringa := '';
      end if;
   END LOOP;
   if nConta > 0 then
      sStringa := sStringa||'0000000000';
      if nConta = 1 then
         sStringa := sStringa||'0000000000';
      end if;
      nConta         := 0;
      nConta_Modelli := nConta_Modelli + 1;
      nProgressivo   := nProgressivo + 1;
      BEGIN
         select para.valore
           into sStringa3
           from parametri para
          where para.sessione         = a_sessione
            and para.nome_parametro   = 'MODMINDENIMU'
            and para.progressivo      = nProgressivo
         ;
         sStringa2 := substr(sStringa3,1,26)||'1'||
                      substr(sStringa3,28,84)||sStringa;
         BEGIN
            update parametri
               set valore             = sStringa2
             where sessione           = a_sessione
               and nome_parametro     = 'MODMINDENIMU'
               and progressivo        = nProgressivo
            ;
         END;
         sStringa2 := substr(sStringa3,1,26)||'2'||
                      substr(sStringa3,28,84)||sStringa;
         nProgressivo := nProgressivo + 1;
         BEGIN
            update parametri
               set valore             = sStringa2
             where sessione           = a_sessione
               and nome_parametro     = 'MODMINDENIMU'
               and progressivo        = nProgressivo
            ;
         END;
--         sStringa2 := substr(sStringa3,1,26)||'3'||
--                      substr(sStringa3,28,84)||sStringa;
--         nProgressivo := nProgressivo + 1;
--         BEGIN
--            update parametri
--               set valore             = sStringa2
--             where sessione           = a_sessione
--               and nome_parametro     = 'MODMINDENIMU'
--               and progressivo        = nProgressivo
--            ;
--         END;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            sStringa2 := lpad(to_char(a_pratica),10,'0')||
                         rpad(sCod_Fiscale,16,' ')||'1'||
                         lpad(to_char(nConta_Modelli),3,'0')||
                         lpad(to_char(nTot_Modelli),3,'0')||
                         '                0000000000'||
                         '                0000000000'||
                         '                0000000000'||sStringa;
            BEGIN
               insert into parametri
                     (sessione,nome_parametro,progressivo,valore)
               values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
            END;
            sStringa2 := lpad(to_char(a_pratica),10,'0')||
                         rpad(sCod_Fiscale,16,' ')||'2'||
                         lpad(to_char(nConta_Modelli),3,'0')||
                         lpad(to_char(nTot_Modelli),3,'0')||
                         '                0000000000'||
                         '                0000000000'||
                         '                0000000000'||sStringa;
            nProgressivo := nProgressivo + 1;
            BEGIN
               insert into parametri
                     (sessione,nome_parametro,progressivo,valore)
               values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
            END;
--            sStringa2 := lpad(to_char(a_pratica),10,'0')||
--                         rpad(sCod_Fiscale,16,' ')||'3'||
--                         lpad(to_char(nConta_Modelli),3,'0')||
--                         lpad(to_char(nTot_Modelli),3,'0')||
--                         '                0000000000'||
--                         '                0000000000'||
--                         '                0000000000'||sStringa;
--            nProgressivo := nProgressivo + 1;
--            BEGIN
--               insert into parametri
--                     (sessione,nome_parametro,progressivo,valore)
--               values(a_sessione,'MODMINDENIMU',nProgressivo,sStringa2);
--            END;
      END;
      sStringa := '';
   end if;
   commit;
EXCEPTION
   WHEN FINE THEN
      commit;
END;
/* End Procedure: MOD_MIN_DENUNCIA_IMU */
/

