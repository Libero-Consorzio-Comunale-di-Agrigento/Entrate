--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_sanzione stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_SANZIONE
(a_pratica         number,
 a_cod_sanzione    number,
 a_importo         number,
 a_giorni          number,
 a_dal             date,
 a_al              date,
 a_base            number,
 a_sequenza_sanz   number default 1)
IS
errore             exception;
w_errore           varchar2(200);
BEGIN
 if  round(a_importo,2) <> 0 then
   BEGIN
    update sanzioni_pratica
           set importo      = importo + round(a_importo,2)
             , giorni       = null
             , note         = note
                              ||'In: '||to_char(round(a_importo,2))
                              ||' gg: '||to_char(a_giorni)
                              ||' dal: '||to_char(a_dal,'dd/mm/yyyy')
                              ||' al: '||to_char(a_al,'dd/mm/yyyy')
                              ||' base: '||to_char(a_base)
                              ||' - '
         where pratica      = a_pratica
           and cod_sanzione = a_cod_sanzione
           and sequenza_sanz = a_sequenza_sanz
        ;
      EXCEPTION
    WHEN others THEN
               w_errore := 'Errore aggiornamento Sanzioni Pratica';
         RAISE errore;
   END;
 end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
END;
/* End Procedure: AGGIORNAMENTO_SANZIONE */
/
