--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione_gg stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE_GG
/*************************************************************************
  Rev.    Date         Author      Note 
  3       11/04/2025   RV          #77608
                                   Adeguamento gestione sequenza sanzioni 
  2       12/12/2024   AB          Gestione preliminare sequenza sanzioni
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
    a_gg_diff         IN number,
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
    w_semestri         number;
    --
    w_data_sanzione   date;
    w_esiste_sanzione number;
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
      -- (VD - 25/11/2016): aggiunto parametro pratica per eventuale riduzione sanzione 
      --
      w_impo_sanz := f_round(f_importo_sanzione_gg(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,a_gg_diff,
                                                       w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,w_data_sanzione),0);
      IF w_impo_sanz < 0 THEN
         w_errore := 'Errore in Ricerca Sanzioni Pratica ('||a_cod_sanzione||
                         ') '||'('||SQLERRM||')';
         RAISE errore;
      END IF;
   ELSE
      -- Se il parametro a_impo_sanz e` non nullo allora si sa gia` l`importo da inserire,
      -- in quel caso il parametro a_maggiore_impo rappresenta il numero dei semestri
      w_impo_sanz := f_round(a_impo_sanz,0);
      w_semestri  := a_maggiore_impo;
      --
      -- (VD - 26/07/2018): si lancia comunque la funzione F_IMPORTO_SANZIONE perche' 
      --                    valorizza anche percentuale, riduzione e riduzione_2 da 
      --                    memorizzare sulla tabella SANZIONI_PRATICA
      --
      w_impo_falso := f_importo_sanzione_gg(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,a_gg_diff,
                                                       w_percentuale,w_riduzione,w_riduzione_2,a_pratica,null,w_data_sanzione);
   END IF;
   --
   IF nvl(w_impo_sanz,0) <> 0 THEN
      -- Verifico se già esiste una sanzione di questo tipo 
      begin
         select count(1),
                max(sequenza_sanz)
           into w_esiste_sanzione,
                w_sequenza_sanz
           from sanzioni_pratica sapr
          where sapr.pratica      = a_pratica
            and sapr.cod_sanzione = a_cod_sanzione
            and sapr.tipo_tributo = a_tipo_tributo
         ;
      EXCEPTION
        WHEN others THEN
              w_errore := 'Errore in verifica presenza Sanzioni Pratica ('
                        ||a_cod_sanzione||') '||'('||SQLERRM||')';
             RAISE errore;
      end;
      --
      if w_esiste_sanzione > 0 then
         BEGIN
            update sanzioni_pratica
               set importo      = importo + w_impo_sanz
                 , percentuale  = decode(percentuale      
                                        ,w_percentuale,w_percentuale
                                        ,null
                                        )
             where cod_sanzione = a_cod_sanzione
               and tipo_tributo = a_tipo_tributo
               and pratica      = a_pratica
               and sequenza_sanz = w_sequenza_sanz
            ;
         EXCEPTION
             WHEN others THEN
                   w_errore := 'Errore in update Sanzioni Pratica ('
                             ||a_cod_sanzione||') '||'('||SQLERRM||')';
                  RAISE errore;
         END;
      else
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
      end if;
   END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
      (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
     (-20999,'Errore in Insert_sanzione_gg'||'('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_SANZIONE_GG */
/
