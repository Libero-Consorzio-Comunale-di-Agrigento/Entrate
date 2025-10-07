--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_raop_cuni stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_RAOP_CUNI
( a_pratica         in number
, a_tipo_pagam      in varchar2
, a_data_pagam      in date
, a_utente          in varchar2
, a_flag_infrazione in varchar2
, a_gruppo_tributo  in varchar2 default null
)
/******************************************************************************
  NOME:        CALCOLO_SANZIONI_RAOP_CUNI
  DESCRIZIONE: Calcola sanzioni ravvedimento operoso CUNI

  REVISIONI:
  Rev.  Data        Autore  Descrizione
  ----  ----------  ------  ----------------------------------------------------
  006   07/11/2024  DM      #75093
                            Storicizzazione sanzioni
  005   05/04/2024  RV      #54732
                            Aggiunto gestione scadenze personalizzate
  004   24/01/2024  RV      #69537
                            Aggiunto gestione gruppo_tributo
  003   28/02/2023  AB      #62651
                            Aggiunta la eliminazione sanzioni per deceduti
  002   25/02/2022  VD      Revisione dopo definizione modalita' operative
                            ravvedimento.
  001   15/02/2022  RV      Prima emissione, basato su CALCOLO_SANZIONI_RAOP_TARSU (VD)
******************************************************************************/
IS
w_errore                 varchar2(2000);
errore                   exception;
fine                     exception;
w_tipo_tributo           varchar2(5) := 'CUNI';
w_comune                 varchar2(6);
w_anno                   number;
w_anno_scadenza          number;
w_data_pratica           date;
w_rata                   number;
w_cod_fiscale            varchar2(16);
w_delta_anni             number;
w_conta                  number;
w_imposta                number;
w_versato                number;
w_scad                   date;
w_interessi              number;
w_diff_giorni            number;
w_giorni                 number;
w_giorni_anno            number;
w_data_presentazione     date;
w_data_scadenza          date;
w_cod_sanzione           number;
w_sequenza_sanz          number(4);
w_rid                    number;
w_percentuale            number;
w_riduzione              number;
w_riduzione_2            number;
w_sanzione               number;
w_tot_versato            number;
w_tot_omesso             number;
w_note_sanzione          varchar2(2000);
w_stato_sogg             number(2);
--
w_scadenza_rata_pers           date;
--
 -------------------------------------------------------------------------
 --                Determina data di scadenza da catalogo               --
 -------------------------------------------------------------------------
FUNCTION F_DATA_SCAD
(a_anno           IN    number
,a_numero_rata    IN    number
,a_tipo_scad      IN    varchar2
,a_gruppo_tributo in    varchar2
,a_data_scadenza  IN OUT date
) Return string IS
w_err                   varchar2(2000);
w_data                  date;
BEGIN
   -- Da utilizzare solo per la scadenza di presentazione (D)
   w_err := null;
   --
   -- Tentativo 1 (solo per tipo 'V') : cerca scadenza senza tipo_occupazione
   --   Se trova esce
   --   Se non trova va avanti
   --
 --dbms_output.put_line('Scad: '||a_tipo_scad||', tributo: '||a_tipo_tributo||', gruppo: '||a_gruppo_tributo||', anno: '||a_anno);
   --
   if a_tipo_scad = 'V' then
     BEGIN
        select scad.data_scadenza
          into w_data
          from scadenze scad
         where scad.tipo_tributo    = w_tipo_tributo
           and scad.anno            = a_anno
           and nvl(scad.rata,-1)    = nvl(a_numero_rata,-1)
           and scad.tipo_scadenza   = a_tipo_scad
           and (((scad.gruppo_tributo is null) and (a_gruppo_tributo is null)) or
               (scad.gruppo_tributo = a_gruppo_tributo))
           and scad.tipo_occupazione is null
        ;
        a_data_scadenza := w_data;
        Return w_err;
     EXCEPTION
        when no_data_found then
           w_err := null;
        WHEN others THEN
           w_err := to_char(SQLCODE)||' - '||SQLERRM;
           Return w_err;
     END;
   end if;
   --
   -- Tentativo 2 (Qualsiasi tipo) : cerca scadenza con tipo_occupazione null o 'P'
   --   Se trova esce
   --   Se non trova genera stringa di errore
   --
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_tributo    = w_tipo_tributo
         and scad.anno            = a_anno
         and nvl(scad.rata,-1)    = nvl(a_numero_rata,-1)
         and scad.tipo_scadenza   = a_tipo_scad
         and (((scad.gruppo_tributo is null) and (a_gruppo_tributo is null)) or
             (scad.gruppo_tributo = a_gruppo_tributo))
         and nvl(scad.tipo_occupazione,'P') = 'P'
      ;
      a_data_scadenza := w_data;
      Return w_err;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         if a_tipo_scad = 'V' then
            w_err := 'Scadenza di Versamento per Rata '||to_char(nvl(a_numero_rata,0))||' anno '||to_char(a_anno)||
                     ' Non Prevista.';
         else
            w_err := 'Scadenza di Ravvedimento per anno '||to_char(a_anno)||' Non Prevista.';
         end if;
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
END F_DATA_SCAD;
 -------------------------------------------------------------------------
 --           Determina data di scadenza personalizate da ogim          --
 -------------------------------------------------------------------------
FUNCTION F_DATA_SCAD_OGIM
(p_pratica        in     number
,p_data_scadenza  IN OUT date
) return date
is
  --
  w_err               varchar2(2000);
  w_data_scadenza     date;
  --
BEGIN
  --
  w_errore := null;
  w_data_scadenza := null;
  --
  BEGIN
    select min(data_scadenza) as data_scadenza
      into w_data_scadenza
      from (
        select
          min(ogim.data_scadenza) as data_scadenza
         from oggetti_imposta ogim
            , oggetti_pratica ogpr
        where ogim.oggetto_pratica  = ogpr.oggetto_pratica
          and ogpr.pratica          = p_pratica
      );
  EXCEPTION
    when no_data_found then
      w_data_scadenza := null;
    when OTHERS then
      w_err := 'Errore ricavando scadenza personalizzata';
  END;
  --
  p_data_scadenza := w_data_scadenza;
  --
  return w_err;
END F_DATA_SCAD_OGIM;
--
-- Funzione per il recupero della sequenza della sanzione
--
FUNCTION F_SEQUENZA_SANZIONE
(a_cod_sanzione      IN     number
,a_data_scadenza     IN     date
,a_sequenza          IN OUT number
) Return string
is
  w_err                varchar2(2000);
BEGIN
   w_err := null;
   BEGIN
      select sanz.sequenza
        into a_sequenza
        from sanzioni sanz
       where sanz.tipo_tributo = 'CUNI'
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista in data ' || to_char(a_data_scadenza,'DD/MM/YYYY');
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   return w_err;
END F_SEQUENZA_SANZIONE;
 -------------------------------------------------------------------------
 -- Funzione per Calcolo Sanzione
 -------------------------------------------------------------------------
FUNCTION F_IMP_SANZ
(a_cod_sanzione      IN     number
,a_importo           IN     number
,a_rid               IN     number
,a_data_scadenza     IN     date
,a_percentuale       IN OUT number
,a_riduzione         IN OUT number
,a_riduzione_2       IN OUT number
,a_sanzione          IN OUT number
,a_sequenza_sanz     IN OUT number
) Return string is
w_err                varchar2(2000);
w_impo_sanz          number;
w_sanzione           number;
w_sanzione_minima    number;
BEGIN
   w_err := null;
   BEGIN
      select round(sanz.sanzione_minima / a_rid,2)
            ,sanz.sanzione
            ,round(sanz.percentuale / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
            ,sequenza
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
            ,a_sequenza_sanz
        from sanzioni sanz
       where sanz.tipo_tributo = w_tipo_tributo
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine         
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista.';
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   w_impo_sanz := a_importo * nvl(a_percentuale,0) / 100;
   if nvl(w_sanzione_minima,0) > w_impo_sanz then
      w_impo_sanz := w_sanzione_minima;
   end if;
   a_sanzione := w_impo_sanz;
   Return w_err;
END F_IMP_SANZ;
 -------------------------------------------------------------------------
 -- Funzione per Calcolo Sanzione basata sui giorni
 -------------------------------------------------------------------------
FUNCTION F_IMP_SANZ_GG
(a_cod_sanzione      IN     number
,a_importo           IN     number
,a_rid               IN     number
,a_diff_gg           IN     number
,a_data_scadenza     IN     date
,a_percentuale       IN OUT number
,a_riduzione         IN OUT number
,a_riduzione_2       IN OUT number
,a_sanzione          IN OUT number
,a_sequenza_sanz     IN OUT number
) Return string is
w_err                varchar2(2000);
w_impo_sanz          number;
w_sanzione           number;
w_sanzione_minima    number;
BEGIN
   w_err := null;
   BEGIN
      select round(sanz.sanzione_minima / a_rid,2)
            ,sanz.sanzione
            ,round(sanz.percentuale * a_diff_gg / a_rid,2)
            ,sanz.riduzione
            ,sanz.riduzione_2
            ,sanz.sequenza
        into w_sanzione_minima
            ,w_sanzione
            ,a_percentuale
            ,a_riduzione
            ,a_riduzione_2
            ,a_sequenza_sanz
        from sanzioni sanz
       where sanz.tipo_tributo = w_tipo_tributo
         and sanz.cod_sanzione = a_cod_sanzione
         and a_data_scadenza between sanz.data_inizio and sanz.data_fine         
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_err := 'Sanzione '||to_char(a_cod_sanzione)||' Non Prevista.';
         Return w_err;
      WHEN OTHERS THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
   w_impo_sanz := a_importo * nvl(a_percentuale,0) / 100;
   if nvl(w_sanzione_minima,0) > w_impo_sanz then
      w_impo_sanz := w_sanzione_minima;
   end if;
   a_sanzione := w_impo_sanz;
   Return w_err;
END F_IMP_SANZ_GG;
 -------------------------------------------------------------------------
 -- Funzione per Calcolo Interessi
 -------------------------------------------------------------------------
function F_CALCOLO_INTERESSI
(a_importo          in     number
,a_dal              in     date
,a_al               in     date
,a_gg_anno          in     number
,a_interessi        in out number
,a_note             in out varchar2
) Return varchar2 is

w_interessi         number;
w_interesse_singolo number;
w_note              varchar2(2000);
w_note_singolo      varchar2(2000);
w_err               varchar2(2000);

  cursor sel_periodo (p_dal date,p_al date) is
  select inte.aliquota
        ,greatest(inte.data_inizio,p_dal) dal
        ,least(inte.data_fine,p_al) al
    from interessi inte
   where inte.tipo_tributo      = w_tipo_tributo
     and inte.data_inizio      <= p_al
     and inte.data_fine        >= p_dal
     and inte.tipo_interesse    = 'L'
   order by dal
  ;
begin
  w_interessi := 0;
  w_interesse_singolo := 0;
  w_err := 'OK';
  begin
    for rec_periodo IN sel_periodo(a_dal,a_al)
    loop
      w_interesse_singolo := f_round(nvl(a_importo,0) * nvl(rec_periodo.aliquota,0) / 100 *
                                     (rec_periodo.al - rec_periodo.dal + 1) / a_gg_anno,0
                                    );
      w_interessi := w_interessi + w_interesse_singolo;
      w_note_singolo := 'Int: '||ltrim(to_char(w_interesse_singolo,'999G990D00','NLS_NUMERIC_CHARACTERS = '',.'''))
                     ||' gg: '||to_char((rec_periodo.al - rec_periodo.dal + 1))
                     ||' dal: '||to_char(rec_periodo.dal,'dd/mm/yyyy')
                     ||' al: '||to_char(rec_periodo.al,'dd/mm/yyyy')
                     ||' tasso: '||ltrim(to_char(nvl(rec_periodo.aliquota,0),'990D00','NLS_NUMERIC_CHARACTERS = '',.'''))
                     ||' base di calcolo: '||ltrim(to_char(nvl(a_importo,0),'999G999G990D00','NLS_NUMERIC_CHARACTERS = '',.'''))
                     ||' - ';
      w_note := w_note || w_note_singolo;
    end loop;
    a_interessi := f_round(w_interessi,0);
    a_note := substr(rtrim(w_note,' - '),1,2000);
  exception
     WHEN others THEN
        w_err := to_char(SQLCODE)||' - '||SQLERRM;
        Return w_err;
  end;
  Return w_err;
end F_CALCOLO_INTERESSI;
--
-- ======================================= --
-- R A V V E D I M E N T O   O P E R O S O --
-- ======================================= --
--
BEGIN
   w_errore := null;
--
-- Si memorizza il codice del comune per eventuali personalizzazioni.
--
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
        into w_comune
        from dati_generali
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Dati generali Non presenti.';
         RAISE ERRORE;
   END;
   BEGIN
      select prtr.data
            ,prtr.anno
            ,prtr.cod_fiscale
            ,to_number(prtr.tipo_evento)
        into w_data_pratica
            ,w_anno
            ,w_cod_fiscale
            ,w_rata
        from pratiche_tributo prtr
       where prtr.pratica = a_pratica
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_errore := 'Pratica '||to_char(a_pratica)||' Assente.';
         RAISE ERRORE;
   END;
   if w_anno < 1998 then
      w_errore := 'Gestione Non Prevista per Anni col Vecchio Sanzionamento';
      RAISE ERRORE;
   end if;
   w_delta_anni := 0;
--
-- Si seleziona la data di scadenza prevista per il ravvedimento
--
   w_errore := F_DATA_SCAD(w_anno + w_delta_anni,to_number(null),'R',null,w_data_presentazione);
   if w_errore is not null then
      RAISE ERRORE;
   end if;
   if a_data_pagam > w_data_presentazione then
      w_errore := 'La data di Pagamento '||to_char(a_data_pagam,'dd/mm/yyyy')||' e` > della scadenza '||
                  to_char(w_data_presentazione,'dd/mm/yyyy')||' per ravvedersi.';
      RAISE ERRORE;
   end if;
--
-- Cerca l'eventuiale data di scadenza personalizzata per la rata
--
  w_scadenza_rata_pers := null;
  w_errore := F_DATA_SCAD_OGIM(a_pratica,w_scadenza_rata_pers);
  if w_errore is not null then
    RAISE ERRORE;
  end if;
--dbms_output.put_line('Scadenza personalizzata: '||w_scadenza_rata_pers);
--
-- Carica la data di scadenza della rata oggetto del ravvedimento e sistema se esiste personalizzata
--
   if w_scadenza_rata_pers is null then
     w_errore := F_DATA_SCAD(w_anno + w_delta_anni,w_rata,'V',a_gruppo_tributo,w_data_scadenza);
     if w_errore is not null then
        RAISE ERRORE;
     end if;
   else
     w_data_scadenza := w_scadenza_rata_pers;
   end if;
   --
   if a_data_pagam < w_data_scadenza then
      w_errore := 'La data di Pagamento '||to_char(a_data_pagam,'dd/mm/yyyy')||' e` < della scadenza '||
                  to_char(w_data_scadenza,'dd/mm/yyyy')||'della rata '||w_rata;
      RAISE ERRORE;
   end if;
   --
   BEGIN
      select to_date('0101'||lpad(to_char(w_anno + 1),4,'0'),'ddmmyyyy') -
             to_date('0101'||lpad(to_char(w_anno),4,'0'),'ddmmyyyy')
            ,to_number(to_char(w_data_scadenza,'yyyy'))
        into w_giorni_anno
            ,w_anno_scadenza
        from dual
      ;
   END;
--
-- Pulizia Sanzioni Precedenti.
--
   BEGIN
      delete from sanzioni_pratica sapr
       where sapr.pratica = a_pratica
      ;
   END;
--
-- Memorizzazione del Versato con relativa Data di Pagamento e Rata.
--
   begin
     select nvl(sum(importo_versato),0)
       into w_tot_versato
       from versamenti vers
      where vers.cod_fiscale        = w_cod_fiscale
        and vers.anno               = w_anno
        and vers.tipo_tributo       = w_tipo_tributo
        and vers.pratica            is null
        and vers.rata               = w_rata;
   exception
     when others then
       w_tot_versato := 0;
   end;
--
-- Determinazione della Imposta
--
   w_tot_omesso := 0;
   begin
     select nvl(sum(ogim.imposta),0)
       into w_imposta
       from oggetti_imposta ogim
          , oggetti_pratica ogpr
      where ogpr.pratica = a_pratica
        and ogpr.oggetto_pratica = ogim.oggetto_pratica;
   exception
     when others then
       w_imposta := 0;
   end;
   w_tot_omesso := w_imposta - w_tot_versato;
--
-- Tassa Evasa.
--
   if w_tot_omesso > 0 then
      w_cod_sanzione := 101 + (w_rata * 10);
      
      w_errore := F_SEQUENZA_SANZIONE(w_cod_sanzione,w_data_scadenza,w_sequenza_sanz);
      if w_errore is not null then
           RAISE ERRORE;
      end if;
      
      w_imposta := w_tot_omesso;
      BEGIN
         insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo
               ,percentuale,importo,riduzione,riduzione_2
               ,utente,data_variazione,note,sequenza_sanz
               )
         values(a_pratica,w_cod_sanzione,w_tipo_tributo
               ,null,w_imposta,null,null
               ,a_utente,trunc(sysdate),null,w_sequenza_sanz
               )
         ;
      END;
--
-- Determinazione codice sanzione applicabile
--
      w_diff_giorni   := a_data_pagam - w_data_scadenza;
      w_cod_sanzione  := to_number(null);
      if w_diff_giorni > 0 then
         -- Ravvedimento operoso lungo
         if w_diff_giorni > 730 then
            w_cod_sanzione := 206 + (w_rata * 10);
            w_rid := 6;
         elsif
            w_diff_giorni > 365 then
            w_cod_sanzione := 205 + (w_rata * 10);
            w_rid := 7;
         elsif
            w_diff_giorni > 90 then
            w_cod_sanzione := 204 + (w_rata * 10);
            w_rid := 8;
         elsif
            w_diff_giorni > 30 then
            w_cod_sanzione := 203 + (w_rata * 10);
            w_rid := 9;
         elsif
            w_diff_giorni > 15 then
            w_cod_sanzione := 202 + (w_rata * 10);
            w_rid := 10;
         else
            w_cod_sanzione := 201 + (w_rata * 10);
            w_rid := 15;
         end if;
         --
         -- (VD - 18/01/2016): Se la pratica e' del 2016 e il versamento e'
         --                    stato effettuato entro 90 gg dalla scadenza,
         --                    la sanzione viene dimezzata (la riduzione
         --                    viene raddoppiata)
         if w_data_pratica >= to_date('01/01/2016','dd/mm/yyyy') and
            w_diff_giorni <= 90 then
            w_rid := w_rid * 2;
         end if;
--
         if w_cod_sanzione = 201 + (w_rata * 10) then
            -- Gestione della sanzione con percentuale che dipende dai giorni di interesse
            if F_IMP_SANZ_GG(w_cod_sanzione
                            ,w_imposta
                            ,w_rid
                            ,w_diff_giorni
                            ,w_data_scadenza
                            ,w_percentuale
                            ,w_riduzione
                            ,w_riduzione_2
                            ,w_sanzione
                            ,w_sequenza_sanz
                            ) is not null then
               w_errore := 'Errore in Determinazione Sanzione CANONE UNICO per Codice '||
                           to_char(w_cod_sanzione);
               RAISE ERRORE;
            end if;
         else
            if F_IMP_SANZ( w_cod_sanzione
                         , w_imposta
                         , w_rid
                         , w_data_scadenza
                         , w_percentuale
                         , w_riduzione
                         , w_riduzione_2
                         , w_sanzione
                         , w_sequenza_sanz
                         ) is not null then
               w_errore := 'Errore in Determinazione Sanzione CANONE UNICO per Codice '||
                           to_char(w_cod_sanzione);
               RAISE ERRORE;
            end if;
         end if;
         BEGIN
            insert into sanzioni_pratica
                  (pratica,cod_sanzione,tipo_tributo
                  ,percentuale,importo,riduzione,riduzione_2
                  ,utente,data_variazione,note,sequenza_sanz
                  )
            values(a_pratica,w_cod_sanzione,w_tipo_tributo
                  ,w_percentuale,w_sanzione,w_riduzione,w_riduzione_2
                  ,a_utente,trunc(sysdate),'Riduzione a 1/'||w_rid||' per Ravvedimento Operoso.'
                  ,w_sequenza_sanz
                  )
            ;
         END;
      end if;
--
-- Interessi.
--
--DBMS_OUTPUT.PUT_LINE('CALCOLO INTERESSI');
--DBMS_OUTPUT.PUT_LINE('Imposta: '||w_imposta);
--DBMS_OUTPUT.PUT_LINE('Scadenza versamento: '||to_char(w_data_scadenza,'dd/mm/yyyy'));
--DBMS_OUTPUT.PUT_LINE('Data pagamento: '||to_char(a_data_pagam,'dd/mm/yyyy'));
--DBMS_OUTPUT.PUT_LINE('Giorni anno: '||w_giorni_anno);
      w_errore := F_CALCOLO_INTERESSI(w_imposta,w_data_scadenza +1,a_data_pagam,
                                      w_giorni_anno,w_interessi,w_note_sanzione);
      if w_errore <> 'OK' then
         w_errore := 'Errore in Determinazione Interessi '
                     ||w_errore;
         RAISE ERRORE;
      end if;
--DBMS_OUTPUT.PUT_LINE('FINE CALCOLO INTERESSI');
--DBMS_OUTPUT.PUT_LINE('Interessi: '||w_interessi);
      w_cod_sanzione := 301 + (w_rata * 10);
      w_giorni := a_data_pagam - w_data_scadenza;
      if w_interessi > 0 then
         BEGIN
            insert into sanzioni_pratica
                  (pratica,cod_sanzione,tipo_tributo,giorni
                  ,percentuale,importo,riduzione,riduzione_2
                  ,utente,data_variazione,note,sequenza_sanz
                  )
            values(a_pratica,w_cod_sanzione,w_tipo_tributo,w_giorni
                  ,null,round(w_interessi,2),null,null
                  ,a_utente,trunc(sysdate)
                  ,w_note_sanzione,w_sequenza_sanz
                  )
            ;
         END;
      end if;
   end if;
    -- (AB - 28/02/2023): se il contribuente è deceduto, si eliminano
    --                    le sanzioni lasciando solo imposta evasa,
    --                    interessi e spese di notifica
   BEGIN
      select stato
        into w_stato_sogg
        from soggetti sogg, contribuenti cont
       where sogg.ni = cont.ni
         and cont.cod_fiscale = w_cod_fiscale
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca sOGGETTI '||SQLERRM;
         RAISE errore;
   END;
   if w_stato_sogg = 50 then
      ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
   end if;
   COMMIT;
EXCEPTION
   WHEN FINE THEN null;
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: CALCOLO_SANZIONI_RAOP_CUNI */
/
