--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione_liq_imu stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE_LIQ_IMU
/*************************************************************************
  Rev.    Date         Author      Note
  1       11/04/2025   RV          #77608
                                   Adeguamento gestione sequenza sanzioni 
  0       xx/xx/xxxx   XX          Versione inziale
*************************************************************************/
(  a_cod_sanzione         in number
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
  ,a_data_inizio          in date default to_date('01/01/1900','dd/mm/yyyy')
)
IS
--
  w_impo_sanz             number;
  w_impo_sanz_ab          number;
  w_impo_sanz_ter_comu    number;
  w_impo_sanz_ter_erar    number;
  w_impo_sanz_aree_comu   number;
  w_impo_sanz_aree_erar   number;
  w_impo_sanz_rur         number;
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
                                                w_percentuale,w_riduzione,w_riduzione_2,null,null,a_data_inizio),0);                                        
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
      w_semestri             := a_maggiore_impo;
   END IF;
   IF nvl(w_impo_sanz,0) <> 0 THEN
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
               (cod_sanzione,tipo_tributo,pratica,oggetto_pratica
               ,percentuale,importo,semestri
               ,riduzione,riduzione_2
               ,ab_principale
               ,terreni_comune,terreni_erariale
               ,aree_comune,aree_erariale
               ,rurali
               ,fabbricati_d_comune,fabbricati_d_erariale
               ,altri_comune,altri_erariale
               ,fabbricati_merce
               ,utente,data_variazione,sequenza_sanz)
        values (a_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica
               ,w_percentuale,w_impo_sanz,w_semestri
               ,w_riduzione,w_riduzione_2
               ,w_impo_sanz_ab
               ,w_impo_sanz_ter_comu,w_impo_sanz_ter_erar
               ,w_impo_sanz_aree_comu,w_impo_sanz_aree_erar
               ,w_impo_sanz_rur
               ,w_impo_sanz_fab_d_comu,w_impo_sanz_fab_d_erar
               ,w_impo_sanz_altri_comu,w_impo_sanz_altri_erar
               ,w_impo_sanz_fabb_merce
               ,a_utente,trunc(sysdate),w_sequenza_sanz)
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
/* End Procedure: INSERIMENTO_SANZIONE_LIQ_IMU */
/
