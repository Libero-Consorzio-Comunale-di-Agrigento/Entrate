--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_int_magg_tares stripComments:false runOnChange:true 

create or replace procedure INSERIMENTO_INT_MAGG_TARES
/*************************************************************************
 Descrizione :    Inserimento_interessi Magg. TARES
 
 Versione  Data              Autore    Descrizione
 1         26/05/2025        RV        #77612
                                       Adeguamento gestione sanzioni storicizzate
 0         xx/xx/xxxx        XX        Versione iniziale
*************************************************************************/
(  a_pratica           IN number,
   a_oggetto_pratica   IN number,
   a_dal               IN date,
   a_al                IN date,
   a_importo           IN number,
   a_tipo_tributo      IN varchar2,
   a_tipo_vers         IN varchar2,
   a_utente            IN varchar2,
   a_data_inizio       IN date default null
)
IS
   --
   w_errore        varchar2(2000);
   errore          exception;
   --
   w_semestri      number    := NULL;
   w_interessi     number;
   w_cod_sanzione  number(3) := 900;
   w_check         number(1);
   w_gg_anno       number;
   w_giorni        number;
   w_dal           date;
   --
   w_data_sequenza date;
   w_sequenza_sanz number;
   --
BEGIN
  w_dal := a_dal;      -- a_dal viene passato da maschera      
  w_gg_anno := 365;    -- me lo ha detto Salvatore : l'espertone!!!
  w_interessi := f_calcolo_interessi_gg_titr(a_importo
                                        ,w_dal
                                        ,a_al
                                        ,w_gg_anno
                                        ,a_tipo_tributo
                                        );
  w_giorni := a_al - w_dal + 1;
  IF w_interessi IS NULL THEN
    w_errore := 'Manca il periodo in Interessi (Magg. TARES) ';
    RAISE errore;
  ELSIF w_interessi <> 0 THEN
    if a_data_inizio is not null then
      w_data_sequenza := a_data_inizio;
    else
      w_data_sequenza := a_dal;
    end if;
    --
    begin
      select sanz.sequenza
        into w_sequenza_sanz
        from sanzioni sanz
       where sanz.cod_sanzione = w_cod_sanzione
         and sanz.TIPO_TRIBUTO = a_tipo_tributo
         and w_data_sequenza between
             sanz.data_inizio and sanz.data_fine;
    exception
      when others then
        w_errore := 'Sanzione ' || to_char(w_cod_sanzione) || ' non presente alla data '|| to_char(a_dal, 'DD/MM/YYYY') || ' '||' ('||SQLERRM||')';
        raise errore;
    end;
    --    
    w_check := f_check_sanzione(a_pratica,w_cod_sanzione,w_data_sequenza);
    IF w_check = 0 THEN
      inserimento_interesse_gg(w_cod_sanzione
                             ,a_tipo_tributo
                             ,a_pratica
                             ,w_giorni
                             ,w_interessi
                             ,w_dal
                             ,a_al
                             ,a_importo
                             ,a_utente
                             ,w_sequenza_sanz
                             );
    ELSIF w_check = 1 THEN
      aggiornamento_sanzione(a_pratica
                           ,w_cod_sanzione
                           ,w_interessi
                           ,w_giorni
                           ,w_dal
                           ,a_al
                           ,a_importo
                           ,w_sequenza_sanz
                           );
    ELSE
      w_errore := 'Errore f_check_sanzione per Sanzione: '||to_char(w_cod_sanzione)||' ('||SQLERRM||')';
    END IF;
  END IF;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,'Errore durante Inserimento Interessi Magg. TARES ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_INT_MAGG_TARES */
/
