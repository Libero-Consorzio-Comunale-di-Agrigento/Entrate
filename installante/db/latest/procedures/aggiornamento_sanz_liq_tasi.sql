--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_sanz_liq_tasi stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_SANZ_LIQ_TASI
/*************************************************************************
 Versione  Data              Autore    Descrizione 
 3         14/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 3         02/12/2015        VD        Eliminata gestione fabbricati "D"
                                       e importi suddivisi per comune/erario 
 2         13/08/2015        SC        Tolto il sqlerrm dal messaggio di 
                                       errore quando non ha senso perchè 
                                       è in normal successful completion.
 1         26/01/2015        VD        Prima emissione 
*************************************************************************/
(a_cod_sanzione         in number
,a_tipo_tributo         in varchar2
,a_pratica              in number
,a_oggetto_pratica      in number
,a_maggiore_impo        in number
,a_impo_sanz            in number
,a_impo_sanz_ab         in number
,a_impo_sanz_ter        in number
,a_impo_sanz_aree       in number
,a_impo_sanz_rur        in number
,a_impo_sanz_altri      in number
,a_utente               in varchar2
,a_data_inizio          IN date default null
)
IS
  --
  w_impo_sanz             number;
  w_impo_sanz_ab          number;
  w_impo_sanz_ter         number;
  w_impo_sanz_aree        number;
  w_impo_sanz_rur         number;
  w_impo_sanz_altri       number;
  w_percentuale           number;
  w_riduzione             number;
  w_riduzione_2           number;
  w_semestri              number;
  --
  w_sequenza_sanz         number;
  --
  w_errore                varchar2(2000);
  errore                  exception;
  --
BEGIN
   IF a_impo_sanz is NULL THEN
      w_impo_sanz := f_round(f_importo_sanzione(a_cod_sanzione,a_tipo_tributo,a_maggiore_impo,
                                                w_percentuale,w_riduzione,w_riduzione_2),0);
      IF w_impo_sanz < 0 THEN
         w_errore := 'Errore in Ricerca Sanzioni Pratica ('||a_cod_sanzione||
                         ') '; 
-- 13/08/2015        SC        Tolto il sqlerrm                          
         if sqlcode != '00000' then
             w_errore := w_errore||'('||SQLERRM||')';  
         end if;
         RAISE errore;
      END IF;
   ELSE
      -- se il parametro a_impo_sanz e` non nullo allora si sa gia` l`importo da inserire,
      -- in quel caso il parametro a_maggiore_impo rappresenta il numero dei semestri
      w_impo_sanz            := f_round(a_impo_sanz,0);
      w_impo_sanz_ab         := f_round(a_impo_sanz_ab,0);
      w_impo_sanz_ter        := f_round(a_impo_sanz_ter,0);
      w_impo_sanz_aree       := f_round(a_impo_sanz_aree,0);
      w_impo_sanz_rur        := f_round(a_impo_sanz_rur,0);
      w_impo_sanz_altri      := f_round(a_impo_sanz_altri,0);
      w_semestri  := a_maggiore_impo;
   END IF;
   IF nvl(w_impo_sanz,0) > 0 THEN
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
        w_sequenza_sanz := 1;
      end if;
      --
      BEGIN
         update sanzioni_pratica
            set importo           = importo + w_impo_sanz
              , ab_principale     = decode(nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                          ,0,null
                                          ,nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                          )
              , terreni_comune    = decode(nvl(terreni_comune,0) + nvl(w_impo_sanz_ter,0)
                                          ,0,null
                                          ,nvl(terreni_comune,0) + nvl(w_impo_sanz_ter,0)
                                          )
              , terreni_erariale  = to_number(null)
              , aree_comune       = decode(nvl(aree_comune,0) + nvl(w_impo_sanz_aree,0)
                                          ,0,null
                                          ,nvl(aree_comune,0) + nvl(w_impo_sanz_aree,0)
                                          )
              , aree_erariale     = to_number(null)
              , rurali            = decode(nvl(rurali,0) + nvl(w_impo_sanz_rur,0)
                                          ,0,null
                                          ,nvl(rurali,0) + nvl(w_impo_sanz_rur,0)
                                          )
              , fabbricati_d_comune    = to_number(null)
              , fabbricati_d_erariale  = to_number(null)
              , altri_comune           = decode(nvl(altri_comune,0) + nvl(w_impo_sanz_altri,0)
                                               ,0,null
                                               ,nvl(altri_comune,0) + nvl(w_impo_sanz_altri,0)
                                               )
              , altri_erariale         = to_number(null)
          where pratica      = a_pratica
            and cod_sanzione = a_cod_sanzione
            and sequenza_sanz = w_sequenza_sanz
         ;
      EXCEPTION
          WHEN others THEN
                w_errore := 'Errore in aggiornamento Sanzioni Pratica ('
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
     (-20999,'Errore in update_sanzione'||'('||SQLERRM||')');
END;
/* End Procedure: AGGIORNAMENTO_SANZ_LIQ_TASI */
/
