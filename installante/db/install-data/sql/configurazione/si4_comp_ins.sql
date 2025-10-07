--liquibase formatted sql
--changeset dmarotta:20250326_152438_si4_comp_ins stripComments:false endDelimiter:/
--validCheckSum: 1:any

INSERT INTO SI4_TIPI_ABILITAZIONE ( ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE )
 VALUES (1, 'L', 'Lettura')
 /
INSERT INTO SI4_TIPI_ABILITAZIONE ( ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE )
 VALUES (2, 'W', 'Scrittura')
 /
INSERT INTO SI4_TIPI_ABILITAZIONE ( ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE )
 VALUES (3, 'D', 'Cancellazione')
 /
INSERT INTO SI4_TIPI_ABILITAZIONE ( ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE )
 VALUES (4, 'C', 'Creazione')
 /
INSERT INTO SI4_TIPI_ABILITAZIONE ( ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE )
 VALUES (5, 'A', 'Aggiornamento')
/

INSERT INTO SI4_TIPI_OGGETTO ( ID_TIPO_OGGETTO, TIPO_OGGETTO, DESCRIZIONE )
 VALUES (1, 'FILE', 'File')
/
INSERT INTO SI4_TIPI_OGGETTO ( ID_TIPO_OGGETTO, TIPO_OGGETTO, DESCRIZIONE )
 VALUES (2, 'DIRECTORY', 'Directory')
/
INSERT INTO SI4_TIPI_OGGETTO ( ID_TIPO_OGGETTO, TIPO_OGGETTO, DESCRIZIONE )
 VALUES (3, 'TIPI TRIBUTO', 'Tipi Tributo')
/
INSERT INTO SI4_TIPI_OGGETTO ( ID_TIPO_OGGETTO, TIPO_OGGETTO, DESCRIZIONE )
 VALUES (4, 'FUNZIONI', 'Funzioni')
/

INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (1, 1, 2)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (2, 2, 3)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (3, 1, 1)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (4, 1, 3)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (5, 2, 4)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (6, 3, 1)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (7, 3, 5)
/
INSERT INTO SI4_ABILITAZIONI ( ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE )
 VALUES (8, 4, 5)
/
Insert into SI4_TIPI_ABILITAZIONE
   (ID_TIPO_ABILITAZIONE, TIPO_ABILITAZIONE, DESCRIZIONE)
select 6, 'AA', 'Appartenenza Amministrazione'
  from dual
 where not exists (select 1
                     from SI4_TIPI_ABILITAZIONE
                    where id_tipo_abilitazione = 6)
/
Insert into SI4_TIPI_OGGETTO
   (ID_TIPO_OGGETTO, TIPO_OGGETTO, DESCRIZIONE)
select 5, 'FAKE_AMMINISTRAZIONE', 'Fake Amministrazione '
  from dual
 where not exists (select 1
                     from SI4_TIPI_OGGETTO
                    where id_tipo_oggetto = 5)
/
Insert into SI4_ABILITAZIONI
   (ID_ABILITAZIONE, ID_TIPO_OGGETTO, ID_TIPO_ABILITAZIONE)
select 9, 5, 6
  from dual
 where not exists (select 1
                     from SI4_ABILITAZIONI
                    where id_abilitazione = 9)
/
insert into si4_competenze (id_abilitazione,utente,oggetto,accesso)
select 9,'TR4','ENTE','S'
  from dual
 where not exists (select 1
                     from si4_competenze
                    where id_abilitazione = 9
                      and utente = 'TR4')
/

DECLARE
  v_prefix VARCHAR2(20);
BEGIN
  IF '${province}' = 'S' THEN
    v_prefix := 'Provincia di ';
  ELSE
    v_prefix := 'Comune di ';
  END IF;

  Insert into AS4_V_SOGGETTI_CORRENTI
     (NI, CAP_RES, COGNOME, COMUNE_RES, DAL, PROVINCIA_RES)
  select
     1 ni, cap, v_prefix || denominazione cognome, comune, trunc(sysdate) dal, provincia_stato
    from ad4_comuni,dati_generali
   Where provincia_stato (+) = pro_cliente
     and comune (+)          = com_cliente
     and not exists (select 1
                       from AS4_V_SOGGETTI_CORRENTI
                      where ni = 1);
END;
/

declare
   d_esiste number;
begin
   begin
      SELECT 1
        INTO d_esiste
        FROM AD4_UTENTI
       WHERE UTENTE = 'TR4ACAMM'
      ;
   exception
      when no_data_found then
         d_esiste := 0;
   end;
   if d_esiste = 0 then
      INSERT INTO AD4_UTENTI (UTENTE, NOMINATIVO, TIPO_UTENTE)
      VALUES('TR4ACAMM','Gruppo Accesso Amministratori TributiWeb', 'G');
   end if;
end;
/

declare
   d_esiste number;
begin
   begin
      SELECT 1
        INTO d_esiste
        FROM AD4_UTENTI
       WHERE UTENTE = 'TR4ACTRI'
      ;
   exception
      when no_data_found then
         d_esiste := 0;
   end;
   if d_esiste = 0 then
      INSERT INTO AD4_UTENTI (UTENTE, NOMINATIVO, TIPO_UTENTE)
      VALUES('TR4ACTRI','Gruppo Accesso Uff.Tributi TributiWeb', 'G');
   end if;
end;
/

insert into si4_competenze (id_abilitazione,utente,oggetto,accesso)
select 9,'TR4ACAMM','ENTE','S'
  from dual
 where not exists (select 1
                     from si4_competenze
                    where id_abilitazione = 9
                      and utente = 'TR4ACAMM')
/

insert into si4_competenze (id_abilitazione,utente,oggetto,accesso)
select 9,'TR4ACTRI','ENTE','S'
  from dual
 where not exists (select 1
                     from si4_competenze
                    where id_abilitazione = 9
                      and utente = 'TR4ACTRI')
/

INSERT INTO AD4_RUOLI
           (RUOLO, DESCRIZIONE, PROGETTO, MODULO, STATO,
            GRUPPO_LAVORO, GRUPPO_SO, INCARICO, RESPONSABILITA)
SELECT 'TRIB', 'Ufficio Tributi', 'TR4', 'TR4', 'U',
       'N', 'N', 'N', 'N'
  FROM DUAL
 WHERE NOT EXISTS
(SELECT 1
   FROM AD4_RUOLI
  WHERE RUOLO = 'TRIB'
)
/

INSERT INTO AD4_DIRITTI_ACCESSO (UTENTE, MODULO, ISTANZA, RUOLO)
SELECT 'TR4ACAMM', modulo, istanza, 'AMM'
  FROM AD4_DIRITTI_ACCESSO DIAC
 WHERE UTENTE = 'TR4'
   AND MODULO = 'TR4'
   AND NOT EXISTS
(SELECT 1
   FROM AD4_DIRITTI_ACCESSO DIAC2
  WHERE UTENTE = 'TR4ACAMM'
    AND DIAC2.MODULO = DIAC.MODULO
    AND DIAC2.ISTANZA = DIAC2.ISTANZA
)
/

INSERT INTO AD4_DIRITTI_ACCESSO (UTENTE, MODULO, ISTANZA, RUOLO)
SELECT 'TR4ACTRI', modulo, istanza, 'TRIB'
  FROM AD4_DIRITTI_ACCESSO DIAC
 WHERE UTENTE = 'TR4'
   AND MODULO = 'TR4'
   AND NOT EXISTS
(SELECT 1
   FROM AD4_DIRITTI_ACCESSO DIAC2
  WHERE UTENTE = 'TR4ACTRI'
    AND DIAC2.MODULO = DIAC.MODULO
    AND DIAC2.ISTANZA = DIAC2.ISTANZA
)
/

declare
    w_trattati number           := 0;
    w_istanza  varchar2(100)    := '${istanza}';

    cursor sel_diac is
        select uten.utente
          from ad4_utenti uten,ad4_diritti_accesso diac
         where uten.stato   = 'U'
           and uten.utente  = diac.utente
           and diac.modulo  = 'TR4'
           and diac.istanza = w_istanza
           and diac.ruolo   = 'AMM'
           and not exists (select 1
                             from si4_competenze comp
                            where comp.utente     = diac.utente
                              and id_abilitazione = 9);
begin
   for rec_diac in sel_diac loop
       w_trattati := w_trattati + 1;
       begin
          insert into si4_competenze (id_abilitazione,utente,oggetto,accesso)
          values (9,rec_diac.utente,'ENTE','S');
       exception
          when others then
               raise_application_error(-20999,'Errore in inserimento si4_competenze, utente: '||rec_diac.utente||' ('||SQLERRM||')');
       end;
   end loop;
end;
/
