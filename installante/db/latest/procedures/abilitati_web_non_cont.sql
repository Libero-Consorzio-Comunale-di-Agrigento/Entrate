--liquibase formatted sql 
--changeset abrandolini:20250326_152423_abilitati_web_non_cont stripComments:false runOnChange:true 
 
create or replace procedure ABILITATI_WEB_NON_CONT
(a_titr                    in varchar2
,a_anno                    in number
) is
cursor sel_abil is
  select abil.cod_fiscale
       , ad4_soggetto.get_nome(ad4_utente.get_soggetto(ute.utente))    nome
       , abil.username
       , ute.nominativo
    from tr4web_abilitazioni      abil
       , ad4_utenti               ute
   where ute.utente = abil.username
 minus
  select abil.cod_fiscale
       , ad4_soggetto.get_nome(ad4_utente.get_soggetto(ute.utente))    nome
       , abil.username
       , ute.nominativo
    from tr4web_abilitazioni      abil
       , ad4_utenti               ute
   where ute.utente = abil.username
     and F_CONT_ATTIVO_anno(a_titr,abil.cod_fiscale,a_anno) = 'SI'
 order by 2
  ;
separatore        varchar2(1)  := ';';
w_progr_rec       number       := 0;
w_cod_fiscale     varchar2(16) := '';
BEGIN
   --Cancello la tabella di lavoro
   begin
      delete wrk_trasmissioni;
   exception
      when others then
        RAISE_APPLICATION_ERROR (-20666,'Errore nella pulizia della tabella di lavoro (' || SQLERRM || ')');
   end;
   -- inserimento intestazione
   w_progr_rec := w_progr_rec + 1;
   begin
       insert into wrk_trasmissioni
         (numero,dati)
        values ( lpad(to_char(w_progr_rec),15,'0')
               ,'Codice Fiscale'||separatore
               ||'Cognome Nome'||separatore
                ||'Username'||separatore
               )
       ;
   EXCEPTION
      WHEN others THEN
        RAISE_APPLICATION_ERROR(-20919,'Errore in inserimento wrk_trasmissioni record intestazione '||
                                       ' ('||sqlerrm||')');
   END;
   FOR rec_abil IN sel_abil LOOP
      w_cod_fiscale := rec_abil.cod_fiscale;
      w_progr_rec   := w_progr_rec + 1;
      begin
          insert into wrk_trasmissioni
            (numero,dati)
           values ( lpad(to_char(w_progr_rec),15,'0')
                  , rec_abil.cod_fiscale||separatore
                   ||rec_abil.nome||separatore
                   ||rec_abil.nominativo||separatore
                  )
          ;
      EXCEPTION
         WHEN others THEN
           RAISE_APPLICATION_ERROR(-20919,'Errore in inserimento wrk_trasmissioni '||
                                          'cf: '||rec_abil.cod_fiscale||
                                          ' ('||sqlerrm||')');
      END;
   end loop;
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR(-20919,'Errore generico '||
                                   ' ('||sqlerrm||')');
END;
/* End Procedure: ABILITATI_WEB_NON_CONT */
/

