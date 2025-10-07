--liquibase formatted sql 
--changeset rvattolo:20250715_171617_77694_2_ins_sanzioni stripComments:false runOnChange:true 

-- 
--	77694/78175 : Inserimento sanzioni 
-- 	  N° 02 : Interessi su Componenti Perequative
--            ACCONTO (911-4) + SALTO/TOTALE (921-4) + SUPPLETTIVO (931-4)
--
DECLARE
  w_tipo_tributo  varchar2(5);
  --
  w_cod_saznione  number;
  w_sequenza     number;
  --
----------------------------------------
function check_tipo_tributo(
  a_tipo_tributo in VARCHAR2
  ) return number
IS
  --
  w_contatore             number;
  --
begin
  select count(*)
    into w_contatore
    from tipi_tributo
   where tipo_tributo = a_tipo_tributo;
  --   
  if w_contatore = 0 then
    dbms_output.put_line ('Tipo tributo '||a_tipo_tributo||' non configurato.');
  else
    dbms_output.put_line ('Tipo tributo '||a_tipo_tributo||' configurato.');
  end if;
  --   
  return w_contatore;
end check_tipo_tributo;
----------------------------------------
function check_sanzione(
  a_tipo_tributo in VARCHAR2,
  a_cod_sanzione number,
  a_sequenza number
  ) return number
IS
  --
  w_contatore             number;
  --
begin
  select count(*)
    into w_contatore
    from sanzioni
   where tipo_tributo = a_tipo_tributo
     and cod_sanzione = a_cod_sanzione
     and sequenza = a_sequenza;
  --   
  if w_contatore = 0 then
    dbms_output.put_line ('Sanzione '||a_tipo_tributo||'/'||a_cod_sanzione||'-'||a_sequenza||' non configurato.');
  else
    dbms_output.put_line ('Sanzione '||a_tipo_tributo||'/'||a_cod_sanzione||'-'||a_sequenza||' già configurato.');
  end if;
  --   
  return w_contatore;
end check_sanzione;
----------------------------------------
BEGIN
  --
  w_tipo_tributo := 'TARSU';
  --
  if(check_tipo_tributo(w_tipo_tributo) > 0) then
  
	-- TOTALE -------------------------------------------------

    w_cod_saznione := 910;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE',null,null,null,null,
              null,'S',null,null,424,null,null,
              NULL,'I',NULL,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE',null,null,null,null,
              null,'S',null,null,424,null,null,
              NULL,'I',NULL,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
	-- ACCONTO -------------------------------------------------

    w_cod_saznione := 911;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',1,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',1,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 912;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',2,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',2,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;

    w_cod_saznione := 913;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',3,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',3,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 914;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',4,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              1,'I',4,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
	-- SALDO/TOTALE -------------------------------------------------

    w_cod_saznione := 921;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',1,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',1,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 922;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',2,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',2,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;

    w_cod_saznione := 923;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',3,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',3,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 924;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',4,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SALDO/TOTALE RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              2,'I',4,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
	-- SUPPLETTIVO -------------------------------------------------
	
    w_cod_saznione := 931;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',1,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 1',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',1,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 932;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',2,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 2',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',2,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;

    w_cod_saznione := 933;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',3,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 3',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',3,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;
	
    w_cod_saznione := 934;
    w_sequenza := 1;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',4,'S','3945',null,
              TO_DATE('01/01/1900','dd/MM/YYYY'),TO_DATE('31/08/2024','dd/MM/YYYY'),'#TR4',sysdate,null);
          
      commit;

    end if;

    w_sequenza := 2;
    --
    if(check_sanzione(w_tipo_tributo,w_cod_saznione,w_sequenza) < 1) then

      INSERT INTO SANZIONI
             (TIPO_TRIBUTO,COD_SANZIONE,SEQUENZA,DESCRIZIONE,PERCENTUALE,SANZIONE,SANZIONE_MINIMA,RIDUZIONE,
              FLAG_IMPOSTA,FLAG_INTERESSI,FLAG_PENA_PECUNIARIA,GRUPPO_SANZIONE,TRIBUTO,FLAG_CALCOLO_INTERESSI,RIDUZIONE_2,
              TIPOLOGIA_RUOLO,TIPO_CAUSALE,RATA,FLAG_MAGG_TARES,COD_TRIBUTO_F24,TIPO_VERSAMENTO,
              DATA_INIZIO,DATA_FINE,UTENTE,DATA_VARIAZIONE,NOTE)
      values (w_tipo_tributo,w_cod_saznione,w_sequenza,'INTERESSI COMPONENTI PEREQUATIVE SUPPLETIVO RATA 4',null,null,null,null,
              null,'S',null,null,424,null,null,
              3,'I',4,'S','3945',null,
              TO_DATE('01/09/2024','dd/MM/YYYY'),TO_DATE('31/12/9999','dd/MM/YYYY'),'#TR4',sysdate,null);
			  
      commit;

    end if;

  end if;
END;
/
