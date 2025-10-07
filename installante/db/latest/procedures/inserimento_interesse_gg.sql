--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_interesse_gg stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_INTERESSE_GG
(   a_cod_sanzione  IN number,
    a_tipo_tributo  IN varchar2,
    a_pratica       IN number,
    a_giorni        IN number,
    a_interessi     IN number,
    a_dal           IN date,
    a_al            IN date,
    a_base          IN number,
    a_utente        IN varchar2,
    a_sequenza_sanz IN number default 1
)
IS
    w_interessi     number;
    w_giorni        number;
    w_errore        varchar2(2000);
    errore          exception;
BEGIN
      w_interessi := round(a_interessi,2);
      w_giorni    := a_giorni;
   IF nvl(w_interessi,0) <> 0 THEN
      BEGIN
         insert into sanzioni_pratica
               (cod_sanzione
               ,tipo_tributo
               ,pratica
               ,importo
               ,giorni
               ,note
               ,utente
               ,data_variazione
               ,sequenza_sanz
               )
        values (a_cod_sanzione
               ,a_tipo_tributo
               ,a_pratica
               ,w_interessi
               ,w_giorni
               ,'In: '||to_char(w_interessi)
               ||' gg: '||to_char(w_giorni)
               ||' dal: '||to_char(a_dal,'dd/mm/yyyy')
               ||' al: '||to_char(a_al,'dd/mm/yyyy')
               ||' base: '||to_char(a_base)
               ||' - '
               ,a_utente
               ,trunc(sysdate)
               ,a_sequenza_sanz
               )
        ;
      EXCEPTION
          WHEN others THEN
                w_errore := 'Errore in inserimento Sanzioni Pratica ('
                          ||a_cod_sanzione||') '||'('||SQLERRM||')';
               RAISE errore;
      END;
   END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
      (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
         (-20999,'Errore in Inserimento Interessi GG'||'('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_INTERESSE_GG */
/
