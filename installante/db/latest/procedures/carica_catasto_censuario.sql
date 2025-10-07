--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_catasto_censuario stripComments:false runOnChange:true 
 
create or replace procedure CARICA_CATASTO_CENSUARIO
( a_documento_id            in     number
, a_utente                  in     varchar2
, a_messaggio               in out varchar2
)
is
/*************************************************************************
 Versione  Data        Autore    Descrizione
 4         15/07/2020  VD        Modifica e lancio del package
                                 carica_catasto_censuario_pkg.esegui
 3         05/06/2020  VD        Corretta gestione decimali: si seleziona
                                 prima il parametro di sessione
                                 NLS_NUMERIC_CHARACTERS e in base a tale
                                 parametro si decide come gestire il
                                 separatore dei decimali
 2         21/05/2020  VD        Corretta gestione decimali tenendo conto
                                 del parametro nls_language di Oracle
 1         24/11/2016  VD        Corretta gestione decimali in reddito
                                 agrario e reddito dominicale dei terreni
 0         13/03/2015  VD        Prima emissione
*************************************************************************/
begin
  -- Cambio stato in caricamento in corso per gestione Web
   update documenti_caricati
           set stato = 15
             , data_variazione = sysdate
             , utente = a_utente
         where documento_id = a_documento_id
             ;
   commit;
  carica_catasto_censuario_pkg.esegui ( a_documento_id
                                      , a_utente
                                      , a_messaggio
                                      );
exception
--  when errore then
--    rollback;
--    raise_application_error (-20999, nvl (w_errore, 'vuoto'));
  when others then
    rollback;
    raise;
    raise_application_error(-20999, substr(sqlerrm, 1, 200));
end;
/* End Procedure: CARICA_CATASTO_CENSUARIO */
/

