--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_interessi stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_INTERESSI
/*************************************************************************
 Versione  Data              Autore    Descrizione
 4         11/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 3         07/11/2024        DM        #75095
                                       Storicizzazione sanzioni
 2         08/07/2016        VD        Aggiunta gestione interessi su
                                       mini IMU
                                       Per mini IMU tipo_vers = 'M'
                                       e codice sanzione non incrementato
                                       di 100
 1         30/03/2015        VD        Si controlla l'esistenza dei codici
                                       vecchi (< 100) nel dizionario
                                       SANZIONI: se non esistono non si
                                       registra la riga di interessi
 00        12/09/2000                  Esportazione calcolo interessi
                                       (F_CALCOLO_INTERESSI)
 0         14/06/2000                  Inserito gestione acconto/saldo
**************************************************************************
  NOTA: la sequenza sanzione viene determinata da :
        - dizionario sanzioni mediante a_data_iniziom se is not null
        - dal valore di a_dal se a_data_inizio is null,
          solo e specificatamente per i casi previsti al fine di mantenere
          la compatibilità per le casistiche non verificate.
          Altrimenti utilizza sempre sequenza 1.
          Vedere nel codice per le casistiche specifiche.
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
   C_INTERESSI_ACC     CONSTANT number := 198;
   C_INTERESSI_SAL     CONSTANT number := 199;
--
   w_errore        varchar2(2000);
   errore          exception;
   w_semestri      number          := NULL;
   w_interessi     number;
   w_cod_sanzione  number(3);
   w_sequenza_sanz number(4);
   w_check         number(1);
   w_cod_istat     varchar2(6);
   w_tardiva       number;
   w_gg_anno       number;
   w_giorni        number;
   w_dal           date;
   --
   w_data_sequenza date;
   -- Ripristinare per la gestione della #75091
   w_tipo_tributo_temp varchar2(5);
   w_tipo_pratica_temp varchar2(1);
   --

--
-- Variabili per utilizzo funzione F_IMPORTO_SANZIONE:
-- non usate nel calcolo degli interessi
--
   f_percentuale    number;
   f_riduzione      number;
   f_riduzione_2    number;
   f_impo_sanz      number;
--
BEGIN   -- inserimento_interessi
  BEGIN
    select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
      into w_cod_istat
      from dati_generali
    ;
  EXCEPTION
  WHEN no_data_found THEN
       null;
  WHEN others THEN
       w_errore := 'Errore in ricerca Codice Istat del Comune ' ||
                   ' ('||SQLERRM||')';
       RAISE errore;
  END;
  --
  if a_tipo_tributo = 'ICI' then
    w_dal := a_dal + 1;  -- a_dal e' la data di scadenza
  else
    w_dal := a_dal;      -- a_dal viene passato da maschera
  end if;
  --
  w_gg_anno   := 365;    -- me lo ha detto Salvatore : l'espertone!!!
  w_interessi := f_calcolo_interessi_gg_titr(a_importo
                                     ,w_dal
                                     ,a_al
                                     ,w_gg_anno
                                     ,a_tipo_tributo
                                     );
  w_giorni := a_al - w_dal + 1;
  --
  IF w_interessi IS NULL THEN
     w_errore := 'Manca il periodo in Interessi';
     RAISE errore;
  ELSIF w_interessi <> 0 THEN
    IF a_tipo_vers = 'A' THEN
      w_cod_sanzione := C_INTERESSI_ACC;
    ELSIF
      a_tipo_vers = 'S' THEN
      w_cod_sanzione := C_INTERESSI_SAL;
    END IF;
    --
    if a_data_inizio is not null then
      -- #77608 : Determina la sequenza dalla data_inizio specificata
      w_data_sequenza := a_data_inizio;
      --
      begin
        select sanz.sequenza
          into w_sequenza_sanz
          from sanzioni sanz
         where sanz.cod_sanzione = w_cod_sanzione
           and sanz.tipo_tributo = a_tipo_tributo
           and a_data_inizio between sanz.data_inizio and sanz.data_fine
        ;
      exception
        when others then
          w_errore := 'Sanzione '||to_char(w_cod_sanzione)||' non presente alla data '||to_char(a_data_inizio,'DD/MM/YYYY')||' '||' ('||SQLERRM||')';
          raise errore;
      end;
    else
      w_data_sequenza := a_dal;
      --
       -- Ripristinare per la gestione della #75091
       /*
          Con la gestione delle sanzioni storicizzate per tutte le pratiche si dovrà eliminare completamente l'IF e tenere la query
       */
       select prtr.tipo_tributo, prtr.tipo_pratica
         into w_tipo_tributo_temp, w_tipo_pratica_temp
         from pratiche_tributo prtr
        where prtr.pratica = a_pratica;
       --
       if (w_tipo_pratica_temp != 'V') then
         w_sequenza_sanz := 1;
       else
         begin
           select sanz.sequenza
             into w_sequenza_sanz
             from sanzioni sanz
            where sanz.cod_sanzione = w_cod_sanzione
              and sanz.TIPO_TRIBUTO = a_tipo_tributo
              and a_dal between
                  sanz.data_inizio and sanz.data_fine;
           exception
             when others then
                w_errore := 'Sanzione ' || to_char(w_cod_sanzione) || ' non presente alla data '|| to_char(a_dal, 'DD/MM/YYYY') || ' '
                          ||' ('||SQLERRM||')';

                raise errore;
           end;
      end if;
    end if;
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
      w_errore := 'Errore f_check_sanzione per sanzione: '||
                  to_char(w_cod_sanzione)||' ('||SQLERRM||')';
    END IF;
  END IF;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR(-20999,'Errore durante Inserimento Interessi ('||
                                      SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_INTERESSI */
/
