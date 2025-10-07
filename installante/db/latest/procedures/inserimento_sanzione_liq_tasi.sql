--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_sanzione_liq_tasi stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_SANZIONE_LIQ_TASI
/*************************************************************************
 Versione  Data              Autore    Descrizione 
 3         11/04/2025        RV        #77608
                                       Adeguamento gestione sequenza sanzioni 
 2         02/12/2015        VD        Eliminata gestione importi divisi 
                                       per comune/erario 
 1         26/01/2015        VD        Prima emissione 
*************************************************************************/
(  a_cod_sanzione         in number
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
  ,a_data_inizio          in date default to_date('01/01/1900','dd/mm/yyyy')
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
      w_impo_sanz_ter        := f_round(a_impo_sanz_ter,0);
      w_impo_sanz_aree       := f_round(a_impo_sanz_aree,0);
      w_impo_sanz_rur        := f_round(a_impo_sanz_rur,0);
      w_impo_sanz_altri      := f_round(a_impo_sanz_altri,0);
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
               ,utente,data_variazione,sequenza_sanz)
        values (a_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica
               ,w_percentuale,w_impo_sanz,w_semestri
               ,w_riduzione,w_riduzione_2
               ,w_impo_sanz_ab
               ,w_impo_sanz_ter,to_number(null)
               ,w_impo_sanz_aree,to_number(null)
               ,w_impo_sanz_rur
               ,to_number(null),to_number(null)
               ,w_impo_sanz_altri,to_number(null)
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
/* End Procedure: INSERIMENTO_SANZIONE_LIQ_TASI*/ 
/
