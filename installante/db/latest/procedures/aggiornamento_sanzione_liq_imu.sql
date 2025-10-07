--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_sanzione_liq_imu stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_SANZIONE_LIQ_IMU
/*************************************************************************
 Versione  Data              Autore    Descrizione
 3         14/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 2         xx/xx/2024        XX        Predisposizione gestione storica sanzione
 1         20/09/2020        VD        Aggiunta gestione fabbricati merce
 0         xx/xx/xxxx        XX        Versione iniziale
*************************************************************************/
(a_cod_sanzione         in number
,a_tipo_tributo         in varchar2
,a_pratica              in number
,a_oggetto_pratica      in number
,a_maggiore_impo        in number
,a_impo_sanz            in number
,a_impo_sanz_ab         in number
,a_impo_sanz_ter_comu   in number
,a_impo_sanz_ter_erar   in number
,a_impo_sanz_aree_comu  in number
,a_impo_sanz_aree_erar  in number
,a_impo_sanz_rur        in number
,a_impo_sanz_fab_d_comu in number
,a_impo_sanz_fab_d_erar in number
,a_impo_sanz_altri_comu in number
,a_impo_sanz_altri_erar in number
,a_impo_sanz_fabb_merce in number
,a_utente               in varchar2
,a_data_inizio          IN date default null
)
IS
  --
  w_impo_sanz             number;
  w_impo_sanz_ab          number;
  w_impo_sanz_ter_comu    number;
  w_impo_sanz_ter_erar    number;
  w_impo_sanz_aree_comu   number;
  w_impo_sanz_aree_erar   number;
  w_impo_sanz_rur          number;
  w_impo_sanz_fab_d_comu  number;
  w_impo_sanz_fab_d_erar  number;
  w_impo_sanz_altri_comu  number;
  w_impo_sanz_altri_erar  number;
  w_impo_sanz_fabb_merce  number;
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
                         ') '||'('||SQLERRM||')';
         RAISE errore;
      END IF;
   ELSE
      -- se il parametro a_impo_sanz e` non nullo allora si sa gia` l`importo da inserire,
      -- in quel caso il parametro a_maggiore_impo rappresenta il numero dei semestri
      w_impo_sanz            := f_round(a_impo_sanz,0);
      w_impo_sanz_ab         := f_round(a_impo_sanz_ab,0);
      w_impo_sanz_ter_comu   := f_round(a_impo_sanz_ter_comu,0);
      w_impo_sanz_ter_erar   := f_round(a_impo_sanz_ter_erar,0);
      w_impo_sanz_aree_comu  := f_round(a_impo_sanz_aree_comu,0);
      w_impo_sanz_aree_erar  := f_round(a_impo_sanz_aree_erar,0);
      w_impo_sanz_rur        := f_round(a_impo_sanz_rur,0);
      w_impo_sanz_fab_d_comu := f_round(a_impo_sanz_fab_d_comu,0);
      w_impo_sanz_fab_d_erar := f_round(a_impo_sanz_fab_d_erar,0);
      w_impo_sanz_altri_comu := f_round(a_impo_sanz_altri_comu,0);
      w_impo_sanz_altri_erar := f_round(a_impo_sanz_altri_erar,0);
      w_impo_sanz_fabb_merce := f_round(a_impo_sanz_fabb_merce,0);
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
            set importo         = importo + w_impo_sanz
              , ab_principale   = decode(nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                        ,0,null
                                        ,nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                        )
              , terreni_comune  = decode(nvl(terreni_comune,0) + nvl(w_impo_sanz_ter_comu,0)
                                        ,0,null
                                        ,nvl(terreni_comune,0) + nvl(w_impo_sanz_ter_comu,0)
                                        )
              , terreni_erariale  = decode(nvl(terreni_erariale,0) + nvl(w_impo_sanz_ter_erar,0)
                                          ,0,null
                                          ,nvl(terreni_erariale,0) + nvl(w_impo_sanz_ter_erar,0)
                                          )
              , aree_comune     = decode(nvl(aree_comune,0) + nvl(w_impo_sanz_aree_comu,0)
                                        ,0,null
                                        ,nvl(aree_comune,0) + nvl(w_impo_sanz_aree_comu,0)
                                        )
              , aree_erariale     = decode(nvl(aree_erariale,0) + nvl(w_impo_sanz_aree_erar,0)
                                          ,0,null
                                          ,nvl(aree_erariale,0) + nvl(w_impo_sanz_aree_erar,0)
                                          )
              , rurali   = decode(nvl(rurali,0) + nvl(w_impo_sanz_rur,0)
                                 ,0,null
                                 ,nvl(rurali,0) + nvl(w_impo_sanz_rur,0)
                                 )
              , fabbricati_d_comune    = decode(nvl(fabbricati_d_comune,0) + nvl(w_impo_sanz_fab_d_comu,0)
                                               ,0,null
                                               ,nvl(fabbricati_d_comune,0) + nvl(w_impo_sanz_fab_d_comu,0)
                                               )
              , fabbricati_d_erariale    = decode(nvl(fabbricati_d_erariale,0) + nvl(w_impo_sanz_fab_d_erar,0)
                                                 ,0,null
                                                 ,nvl(fabbricati_d_erariale,0) + nvl(w_impo_sanz_fab_d_erar,0)
                                                 )
              , altri_comune    = decode(nvl(altri_comune,0) + nvl(w_impo_sanz_altri_comu,0)
                                        ,0,null
                                        ,nvl(altri_comune,0) + nvl(w_impo_sanz_altri_comu,0)
                                        )
              , altri_erariale    = decode(nvl(altri_erariale,0) + nvl(w_impo_sanz_altri_erar,0)
                                          ,0,null
                                          ,nvl(altri_erariale,0) + nvl(w_impo_sanz_altri_erar,0)
                                          )
              , fabbricati_merce  = decode(nvl(fabbricati_merce,0) + nvl(w_impo_sanz_fabb_merce,0)
                                          ,0,null
                                          ,nvl(fabbricati_merce,0) + nvl(w_impo_sanz_fabb_merce,0)
                                          )
          where pratica       = a_pratica
            and cod_sanzione  = a_cod_sanzione
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
/* End Procedure: AGGIORNAMENTO_SANZIONE_LIQ */
/
