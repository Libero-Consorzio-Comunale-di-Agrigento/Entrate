--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione_ici stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE_ICI
/*************************************************************************
 Versione  Data              Autore    Descrizione
 5         11/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 4         10/12/2024        AB        #76942 
                                       Sistemato controllo su sanz con data_inizio
 3         20/07/2016        VD        Aggiunto dimezzamento sanzione per
                                       codice 505 (mini IMU)
 2         12/07/2016        AB        Controllo della data pratica
                                       (relativi a pratiche dal 2016) per
                                       il dimezzamento della sanzione
                                       207 e 209
 1         26/01/2015        VD        Gestione segnalazioni errore con
                                       parametro a_tipo_tributo
*************************************************************************/
(   a_cod_sanzione   IN number,
    a_tipo_tributo   IN varchar2,
    a_pratica        IN number,
    a_impo_base      IN number,
    a_utente         IN varchar2,
    a_data_inizio    IN date default to_date('01/01/1900','dd/mm/yyyy')
)
IS
--
  w_impo_sanz     number;
  w_percentuale   number;
  w_riduzione     number;
  w_riduzione_2   number;
  w_semestri      number;
  --
  w_sequenza_sanz number;
  --
  w_errore        varchar2(2000);
  errore          exception;
--
function f_importo_sanzione_ici
(
  p_pratica        IN number,
  p_cod_sanzione   IN number,
  p_tipo_tributo   IN varchar2,
  p_imposta_base   IN number,
  p_data_inizio    IN date,
  p_percentuale    IN OUT number,
  p_riduzione      IN OUT number,
  p_riduzione_2    IN OUT number
) return number
IS
  --
  w_impo_sanz         number;
  w_sanzione          number;
  w_sanzione_minima   number;
  w_data_pratica      date;
  --
BEGIN
  BEGIN
      select data
        into w_data_pratica
        from pratiche_tributo
       where pratica = p_pratica
       ;
  EXCEPTION
     WHEN others THEN
       w_errore := 'Errore in Ricerca Data Pratica '||p_pratica||
                           ') '||'('||SQLERRM||')';
       RAISE errore;
  END;
  --
  BEGIN
    select sanz.sanzione_minima
         , sanz.sanzione
         , case
             when w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and p_cod_sanzione in (207,209,505) then
               (sanz.percentuale/2)
           else
              sanz.percentuale
           end
         , sanz.riduzione
         , sanz.riduzione_2
      into w_sanzione_minima, 
           w_sanzione,
           p_percentuale,
           p_riduzione,
           p_riduzione_2
      from sanzioni sanz
     where tipo_tributo   = p_tipo_tributo
       and cod_sanzione   = p_cod_sanzione
       and p_data_inizio between sanz.data_inizio and sanz.data_fine
     ;
  EXCEPTION
     WHEN others THEN
        return -1;
  END;
  --
  w_impo_sanz := (p_imposta_base * p_percentuale) / 100;
  IF (nvl(w_sanzione_minima,0) > w_impo_sanz) THEN
     w_impo_sanz := w_sanzione_minima;
  END IF;
  --
  return w_impo_sanz;
END f_importo_sanzione_ici;
--------------------------------------------------------
BEGIN
   w_impo_sanz := f_round(f_importo_sanzione_ici(a_pratica,a_cod_sanzione,a_tipo_tributo,a_impo_base,a_data_inizio,
                                                                                w_percentuale,w_riduzione,w_riduzione_2),0);
   IF w_impo_sanz < 0 THEN
     w_errore := 'Errore in Ricerca Sanzioni Pratica '||a_tipo_tributo||' ('||a_cod_sanzione||
                         ') '||'('||SQLERRM||')';
         RAISE errore;
   ELSIF nvl(w_impo_sanz,0) > 0 THEN
      -- Usa la data inizio per determinare la sequenza sanzione da usare
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
      BEGIN
        insert into sanzioni_pratica
               (cod_sanzione,tipo_tributo,pratica,oggetto_pratica,
                percentuale,importo,
                semestri,riduzione,riduzione_2,utente,data_variazione,sequenza_sanz)
        values (a_cod_sanzione,a_tipo_tributo,a_pratica,NULL,
                w_percentuale,w_impo_sanz,
                w_semestri,w_riduzione,w_riduzione_2,a_utente,trunc(sysdate),w_sequenza_sanz)
        ;
      EXCEPTION
          WHEN others THEN
                w_errore := 'Errore in inserimento Sanzioni Pratica '||a_tipo_tributo||' ('
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
/* End Procedure: INSERIMENTO_SANZIONE_ICI */
/
