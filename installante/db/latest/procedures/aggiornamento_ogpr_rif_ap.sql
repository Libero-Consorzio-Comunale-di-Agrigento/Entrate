--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_ogpr_rif_ap stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_OGPR_RIF_AP
/*
Versione  Data              Autore    Descrizione
2         29/04/2021        AB        Aggiunta la no_data_found nel recupero pertinenza del ravvedimento
1         17/10/2014        VD        Se il riferimento ap non è determinabile si valorizza a null
*/
(a_oggetto_pratica         number,
 a_oggetto_pratica_rif_ap  number)
IS
errore             exception;
w_errore           varchar2(200);
w_oggetto_pratica_rif_ap  number;
w_pratica_rav             number;
w_oggetto                 number;
w_mesi_possesso           number;
w_mesi_possesso_1sem      number;
w_cod_fiscale             varchar2(16);
w_flag_possesso           varchar2(1);
w_note                    varchar2(200);
BEGIN
-- a_oggetto_pratica è l'oggetto_pratica del ravvediemnto
-- a_oggetto_pratica_rif_ap è l'oggetto_pratica_rif_ap errato ciè qullo della denuncia
   if a_oggetto_pratica_rif_ap is not null then -- questo controllo viene lasciato perche la procedura può essere lanciata da pb
      BEGIN
       w_note := '1 - ogpr:'||to_char(a_oggetto_pratica)||' - ogpr_ap:'||to_char(a_oggetto_pratica_rif_ap);
       select ogpr.pratica
            , prtr.cod_fiscale
         into w_pratica_rav
            , w_cod_fiscale
         from oggetti_pratica  ogpr
            , pratiche_tributo prtr
        where ogpr.oggetto_pratica = a_oggetto_pratica
          and ogpr.pratica  = prtr.pratica
            ;
      EXCEPTION
        WHEN others THEN
                  w_errore := 'Errore (rif_ap) in recupero pratica '||w_note;
            RAISE errore;
      END;
      BEGIN
       w_note := '2 - ogpr:'||to_char(a_oggetto_pratica)||' - ogpr_ap:'||to_char(a_oggetto_pratica_rif_ap);
       -- recupero i dati della "pertinenza di" della denuncia
       select ogpr.oggetto
            , ogco.mesi_possesso
            , ogco.mesi_possesso_1sem
            , ogco.flag_possesso
         into w_oggetto
            , w_mesi_possesso
            , w_mesi_possesso_1sem
            , w_flag_possesso
         from oggetti_pratica      ogpr
            , oggetti_contribuente ogco
        where ogpr.oggetto_pratica = ogco.oggetto_pratica
          and ogpr.oggetto_pratica = a_oggetto_pratica_rif_ap
          and ogco.cod_fiscale     = w_cod_fiscale
            ;
       w_note := '3 '||to_char(w_pratica_rav)||' '||to_char(w_oggetto)||' '||w_mesi_possesso||' ' ||nvl(w_mesi_possesso_1sem,0);
       -- recupero la "pertinenza di" (oggetto_pratica_rif_ap) del ravvediemnto
         begin
             select ogpr.oggetto_pratica
               into w_oggetto_pratica_rif_ap
               from oggetti_pratica      ogpr
                  , oggetti_contribuente ogco
              where ogpr.pratica = w_pratica_rav
                and ogpr.oggetto = w_oggetto
                and ogpr.oggetto_pratica    = ogco.oggetto_pratica
             --   and ogco.mesi_possesso      = w_mesi_possesso
             --   and nvl(ogco.mesi_possesso_1sem,0) = nvl(w_mesi_possesso_1sem,0)
                and ogco.cod_fiscale        = w_cod_fiscale
                ;
         exception
             when no_data_found then
                  w_oggetto_pratica_rif_ap := to_number(null);
             when too_many_rows then
             begin
                select ogpr.oggetto_pratica
                  into w_oggetto_pratica_rif_ap
                  from oggetti_pratica      ogpr
                     , oggetti_contribuente ogco
                 where ogpr.pratica = w_pratica_rav
                   and ogpr.oggetto = w_oggetto
                   and ogpr.oggetto_pratica    = ogco.oggetto_pratica
                   and ogco.mesi_possesso      = w_mesi_possesso
                   and nvl(ogco.mesi_possesso_1sem,0) = nvl(w_mesi_possesso_1sem,0)
                   and ogco.cod_fiscale        = w_cod_fiscale
                   and nvl(ogco.flag_possesso,' ')= nvl(w_flag_possesso,' ')
                   ;
                   exception
             when no_data_found then
                  w_oggetto_pratica_rif_ap := to_number(null);
             when too_many_rows then
                  w_oggetto_pratica_rif_ap := to_number(null);
             end;
         end;
         w_note := '4';
      EXCEPTION
        WHEN others THEN
                  w_errore := 'Errore recupero oggetto_pratica_rif_ap '||w_note;
            RAISE errore;
      END;
      BEGIN
       update oggetti_pratica
          set oggetto_pratica_rif_ap   = w_oggetto_pratica_rif_ap
        where oggetto_pratica          = a_oggetto_pratica
           ;
         EXCEPTION
       WHEN others THEN
                  w_errore := 'Errore aggiornamento oggetto_pratica_rif_ap';
            RAISE errore;
      END;
   end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore);
END;
/* End Procedure: AGGIORNAMENTO_OGPR_RIF_AP */
/

