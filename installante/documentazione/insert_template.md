<h3>Caso in cui non c'è il tipo_tributo da testare, ma si testa solo il dato del record che si vuole inserire</h3>


```oracle
DECLARE
nConta   NUMBER := 1;
BEGIN
 SELECT COUNT (*)
   INTO nConta
   FROM FUNZIONI
  WHERE funzione = 'SUPPORTO_SERVIZI_MENU'
 ;
 IF nConta = 0 THEN
Insert into FUNZIONI
  (FUNZIONE, DESCRIZIONE)
Values
  ('SUPPORTO_SERVIZI_MENU', 'Menu per Supporto Servizi');
 END IF;

END;
/
```

<h3>Caso di test anche per tipo_tributo, che deve essere presente nella tipi_tributo, in questo caso poi si controlla l'esistenza del modello, in altri casi si controllerà la chiave univoca ella tabella dove dobbiamo fare la inseret</h3>

```oracle
DECLARE
nTipo_tributo number :=1;
nModello number :=1;
BEGIN
  select count(*)
    into nTipo_tributo
    from tipi_tributo
   where tipo_tributo = 'ICI'
  ;
  if nTipo_tributo = 1 then
    select count(*)
      into nModello
      from modelli
     where DESCRIZIONE_ORD = 'COM_ICI%'
       and DESCRIZIONE   = 'COM_IMU_DATI_RENDITE'
    ;
    if nModello = 0 then
Insert into MODELLI
  (MODELLO, TIPO_TRIBUTO, DESCRIZIONE, DESCRIZIONE_ORD, PATH,
FLAG_SOTTOMODELLO, CODICE_SOTTOMODELLO, FLAG_EDITABILE, DB_FUNCTION, FLAG_STANDARD,
FLAG_WEB)
Values
  (NULL, 'ICI', 'COM_IMU_DATI_RENDITE', 'COM_ICI%', 'COM_IMU_DATI_RENDITE',
'S', 'COM_IMU_DATI_RENDITE', 'S', 'STAMPA_COM_IMPOSTA.DATI_RENDITE', 'S',
'S');
end if;
  end if;
END;
/
```

<h3>Caso in cui si debba gestire un CLOB</h3>

```oracle
DECLARE
    nTipo_tributo       number := 1;
    nTipo_comunicazione number := 1;
BEGIN
    -- Conto il numero di record nella tabella TIPI_TRIBUTO con il valore 'CUNI'
    select count(*)
    into nTipo_tributo
    from TIPI_TRIBUTO
    where tipo_tributo = 'CUNI';
    -- Se il numero è uguale a 1, significa che il tipo di tributo esiste
    if nTipo_tributo = 1 then
        -- Conto il numero di record nella tabella COMUNICAZIONE_PARAMETRI con i valori 'CUNI' e 'ACA'
        select count(*)
        into nTipo_comunicazione
        from COMUNICAZIONE_PARAMETRI
        where TIPO_TRIBUTO = 'CUNI'
          and TIPO_COMUNICAZIONE = 'ACA';
        -- Se il numero è uguale a 0, significa che il tipo di comunicazione non esiste
        if nTipo_comunicazione = 0 then
            -- Inserisco un nuovo record nella tabella COMUNICAZIONE_PARAMETRI con i valori specificati
            Insert into COMUNICAZIONE_PARAMETRI
            (TIPO_TRIBUTO, TIPO_COMUNICAZIONE, DESCRIZIONE, FLAG_FIRMA, FLAG_PROTOCOLLO, FLAG_PEC, TIPO_DOCUMENTO,
             TITOLO_DOCUMENTO, PKG_VARIABILI, FLAG_PND)
            Values ('CUNI', 'ACA', 'Accertamento automatico', NULL, 'S', NULL, 'A', 'PROVA OGGETTO GDM',
                    'STAMPA_ACCERTAMENTI_TRMI.PRINCIPALE', NULL);

            DECLARE
                dep_clob     Clob := empty_clob();
                dep_stringa1 varchar2(32767);
            BEGIN
                dbms_lob.createTemporary(dep_clob, TRUE, dbms_lob.session);
                dep_stringa1 := '<TESTO DA INSERIRE NEL CLOB>';

                dbms_lob.writeappend(dep_clob, length(dep_stringa1), dep_stringa1);

                update COMUNICAZIONE_PARAMETRI
                set variabili_clob = dep_clob
                where TIPO_TRIBUTO = 'CUNI'
                  and TIPO_COMUNICAZIONE = 'ACA';
            END;
        end if;
    end if;
END;
```
