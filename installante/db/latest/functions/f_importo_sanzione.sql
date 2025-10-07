--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_sanzione stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPORTO_SANZIONE
/*************************************************************************
 NOME:        F_IMPORTO_SANZIONE
 DESCRIZIONE: Calcolo importo sanzione per tipo tributo
 Rev.    Date         Author      Note
 4       10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con data_inizio
 3       24/07/2018   VD          Aggiunto parametro a_sanz_minima:
                                  se nullo, il calcolo della sanzione
                                  rimane invariato.
                                  Se non e' nullo, l'importo della
                                  sanzione rimane quello calcolato
                                  anche se inferiore alla sanzione
                                  minima.
 2       22/08/2017   VD          Corretta selezione data pratica per
                                  nuovo sanzionamento 2016: ora viene
                                  eseguita solo se il parametro a_pratica
                                  non e' nullo
 1       25/11/2016   VD          Gestione nuovo sanzionamento 2016
*************************************************************************/
(
  a_cod_sanzione   IN number,
  a_tipo_tributo   IN varchar2,
  a_maggiore_impo  IN number,
  a_percentuale    IN OUT number,
  a_riduzione      IN OUT number,
  a_riduzione_2    IN OUT number,
  a_pratica        IN number default null,
  a_sanz_minima    IN varchar2 default null,
  a_data_inizio    IN date default to_date('01/01/1900','dd/mm/yyyy')
  ) return number
IS
  w_impo_sanz         number;
  w_sanzione          number;
  w_sanzione_minima   number;
  w_data_pratica      date;
BEGIN -- importo_sanzione
    --
    -- (VD - 25/11/2016): si seleziona la data della pratica
    -- (VD - 22/08/2017): se il parametro a_pratica e' nullo,
    --                    significa che non si applica il nuovo sanzionamento
    --                    per i codici sanzione da 165 a 169, quindi non
    --                    occorre controllare la data della pratica.
    --                    In questo caso si considera la data di sistema,
    --                    perche' al momento i codici sanzione di cui sopra
    --                    sono presenti solo per ICP e TOSAP e quindi il
    --                    dimezzamento non viene comunque eseguito.
    --
    if a_pratica is not null then
       BEGIN
            select data
              into w_data_pratica
              from pratiche_tributo
             where pratica = a_pratica
             ;
       EXCEPTION
          WHEN others THEN
             return -1;
       END;
    else
       w_data_pratica := trunc(sysdate);
    end if;
    --
    -- (VD - 25/11/2016): se la pratica è del 2016 o anni succ.
    --                    si dimezza la percentuale della sanzione
    --                    Nota: i codici sanzione da 165 a 169 per ora
    --                    sono presenti solo per ICP e TOSAP.
    --
    BEGIN
      select sanz.sanzione_minima
           , sanz.sanzione
             , case
               when w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
                    a_cod_sanzione between 165 and 169 then
                         (sanz.percentuale/2)
               else sanz.percentuale
             end
           , sanz.riduzione
           , sanz.riduzione_2
        into w_sanzione_minima
           , w_sanzione
           , a_percentuale
           , a_riduzione
           , a_riduzione_2
        from sanzioni sanz
       where tipo_tributo   = a_tipo_tributo
         and cod_sanzione   = a_cod_sanzione
         and a_data_inizio between sanz.data_inizio and sanz.data_fine
       ;
    EXCEPTION
       WHEN others THEN
          return -1;
    END;
    IF a_percentuale is NULL THEN
       w_impo_sanz :=  w_sanzione;
    ELSE
       w_impo_sanz := (a_maggiore_impo * a_percentuale) / 100;
    END IF;
    --
    -- (VD - 24/07/2018): se il parametro a_sanz_minima e' nullo,
    --                    il calcolo rimane invariato. In caso contrario,
    --                    la funzione restituisce la sanzione calcolata,
    --                    senza considerare la sanzione minima.
    --
    if a_sanz_minima is null then
       IF (nvl(w_sanzione_minima,0) > w_impo_sanz) THEN
          w_impo_sanz := nvl(w_sanzione_minima,0);
       END IF;
    end if;
    return w_impo_sanz;
END;
/* End Function: F_IMPORTO_SANZIONE */
/
