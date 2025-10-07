--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE
/*************************************************************************
  Rev.    Date         Author      Note
  4       11/04/2025   RV          #77608
                                   Adeguamento gestione sequenza sanzioni 
  3       30/01/2025   DM          Introdotta la gestione della sequenza
                                   settata ad 1 per retrocompatibilità
  2       26/07/2018   VD          Gestione importo sanzione gia' calcolato:
                                   si lancia comunque F_IMPORTO_SANZIONE
                                   per determinare percentuale, riduzione
                                   e riduzione_2 da inserire in
                                   SANZIONI_PRATICA.
  1       25/11/2016   VD          Gestione nuovo sanzionamento 2016
**************************************************************************
  NOTA:  1) Se la sanzione pratica esiste viene aggiornata.
         2) Se non esiste viene creata, usando a_sequenza o a_data_inizio
            per determinare la sequenza:
            - a_data_inizio is null: viene usato a_sequenza;
            - a_data_inizio is not null: la sequenza viene determinata 
              interrogando il dizionario sanzioni per data.
              In questi casi a_sequenza viene ignorato.
*************************************************************************/
(   a_cod_sanzione    IN number,
    a_tipo_tributo    IN varchar2,
    a_pratica         IN number,
    a_oggetto_pratica IN number,
    a_maggiore_impo   IN number,
    a_impo_sanz       IN number,
    a_utente          IN varchar2,
    a_sequenza        IN number DEFAULT 1,
    a_data_inizio     IN date default null
)
IS
    w_impo_sanz       number;
    w_impo_falso      number;
    w_percentuale     number;
    w_riduzione       number;
    w_riduzione_2     number;
    w_semestri        number;
    --
    w_data_sanzione   date;
    w_sequenza_sanz   number;
    --
    w_errore          varchar2(2000);
    errore            exception;
BEGIN
  if a_data_inizio is null then
    -- Se non specificata determina una data di inizio valida per la sequenza di sanzione
    BEGIN
      select sanz.data_inizio
        into w_data_sanzione
        from sanzioni sanz
       where sanz.tipo_tributo = a_tipo_tributo
         and sanz.cod_sanzione = a_cod_sanzione
         and sanz.sequenza =     a_sequenza
      ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        w_data_sanzione := to_date('01/01/1900','dd/mm/yyyy');
      WHEN others THEN
        w_errore := 'Errore ricerca Data Inizio Sanzione ('
                 ||a_cod_sanzione||') '||'('||SQLERRM||')';
        RAISE errore;
    END;
  else
    w_data_sanzione := a_data_inizio;
  end if;
  --
   IF a_impo_sanz is NULL THEN
      --
      -- (VD - 25/11/2016): aggiunto parametro pratica per eventuale riduzione
      --                    sanzione
      --
      w_impo_sanz := f_round(f_importo_sanzione(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,
                                                w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,w_data_sanzione),0);
      IF w_impo_sanz < 0 THEN
         w_errore := 'Errore in Ricerca Sanzioni Pratica ('||a_cod_sanzione||
                         ') '||'('||SQLERRM||')';
         RAISE errore;
      END IF;
   ELSE
      -- se il parametro a_impo_sanz e` non nullo allora si sa gia` l`importo da inserire,
      -- in quel caso il parametro a_maggiore_impo rappresenta il numero dei semestri
      w_impo_sanz := f_round(a_impo_sanz,0);
      w_semestri  := a_maggiore_impo;
      --
      -- (VD - 26/07/2018): si lancia comunque la funzione F_IMPORTO_SANZIONE perche' 
      --                    valorizza anche percentuale, riduzione e riduzione_2 da 
      --                    memorizzare sulla tabella SANZIONI_PRATICA
      --
      w_impo_falso := f_importo_sanzione(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,
                                                w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,w_data_sanzione);
   END IF;
   IF nvl(w_impo_sanz,0) <> 0 THEN
    if a_data_inizio is not null then
      -- Se specificata la data inizio determina la sequenza sanzione da essa, ignorando quindi parametro a_sequenza
      BEGIN
        select sanz.sequenza
          into w_sequenza_sanz
          from sanzioni sanz
         where sanz.tipo_tributo = a_tipo_tributo
           and sanz.cod_sanzione = a_cod_sanzione
           and a_data_inizio between sanz.data_inizio and sanz.data_fine
        ;        
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          w_sequenza_sanz := 1;
        WHEN others THEN
          w_errore := 'Errore ricerca sequenza Sanzioni Pratica ('
                   ||a_cod_sanzione||') '||'('||SQLERRM||')';
          RAISE errore;
      END;
    else
      w_sequenza_sanz := a_sequenza;
    end if;
    --
      BEGIN
         insert into sanzioni_pratica
               (cod_sanzione,tipo_tributo,pratica,oggetto_pratica
               ,percentuale,importo,semestri
               ,riduzione,riduzione_2,utente,data_variazione,sequenza_sanz)
        values (a_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica
               ,w_percentuale,w_impo_sanz,w_semestri
               ,w_riduzione,w_riduzione_2,a_utente,trunc(sysdate),w_sequenza_sanz)
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
     (-20999,'Errore in Insert_sanzione'||'('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_SANZIONE */
/
