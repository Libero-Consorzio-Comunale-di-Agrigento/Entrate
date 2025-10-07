--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_sanzione_liq stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     AGGIORNAMENTO_SANZIONE_LIQ
(a_cod_sanzione         in number
,a_tipo_tributo         in varchar2
,a_pratica              in number
,a_oggetto_pratica      in number
,a_maggiore_impo        in number
,a_impo_sanz            in number
,a_impo_sanz_ab         in number
,a_impo_sanz_ter        in number
,a_impo_sanz_aree       in number
,a_impo_sanz_altri      in number
,a_utente               in varchar2
)
IS
    w_impo_sanz        number;
    w_impo_sanz_ab     number;
    w_impo_sanz_ter    number;
    w_impo_sanz_aree   number;
    w_impo_sanz_altri  number;
    w_percentuale      number;
    w_riduzione        number;
    w_riduzione_2      number;
    w_semestri         number;
    w_sequenza_sanz    number := 1;
    w_errore           varchar2(2000);
    errore             exception;
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
      w_impo_sanz       := f_round(a_impo_sanz,0);
      w_impo_sanz_ab    := f_round(a_impo_sanz_ab,0);
      w_impo_sanz_ter   := f_round(a_impo_sanz_ter,0);
      w_impo_sanz_aree  := f_round(a_impo_sanz_aree,0);
      w_impo_sanz_altri := f_round(a_impo_sanz_altri,0);
      w_semestri  := a_maggiore_impo;
   END IF;
   IF nvl(w_impo_sanz,0) > 0 THEN
      BEGIN
         update sanzioni_pratica
            set importo         = importo + w_impo_sanz
              , ab_principale   = decode(nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                        ,0,null
                                        ,nvl(ab_principale,0) + nvl(w_impo_sanz_ab,0)
                                        )
              , terreni_comune  = decode(nvl(terreni_comune,0) + nvl(w_impo_sanz_ter,0)
                                        ,0,null
                                        ,nvl(terreni_comune,0) + nvl(w_impo_sanz_ter,0)
                                        )
              , aree_comune     = decode(nvl(aree_comune,0) + nvl(w_impo_sanz_aree,0)
                                        ,0,null
                                        ,nvl(aree_comune,0) + nvl(w_impo_sanz_aree,0)
                                        )
              , altri_comune    = decode(nvl(altri_comune,0) + nvl(w_impo_sanz_altri,0)
                                        ,0,null
                                        ,nvl(altri_comune,0) + nvl(w_impo_sanz_altri,0)
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
