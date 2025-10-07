--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_cont_anno_titr_as stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_CONT_ANNO_TITR_AS
/*************************************************************************
 NOME:        F_IMPOSTA_CONT_ANNO_TITR_AS
 DESCRIZIONE: Restituisce il totale imposta dovuto per l'anno e il tipo
              tributo indicato, in acconto, a saldo o totale.
           UTILIZZATA NELLA FUNZIONE CHECK_RAVVEDIMENTO che serve a
           determinare lo scostamento tra il versato su ravvedimento
           e l'imposta dovuta.
 PARAMETRI:   a_cod_fiscale       Codice fiscale del contribuente da
                                  trattare
              a_anno              Anno di riferimento
              a_tipo_tributo      Tipo tributo da trattare
              a_tipo_imposta      Tipo imposta da calcolare:
                                  A - Acconto
                                  S - Saldo
                                  Null - Totale annuo
              a_oggetto_pratica   Facoltativo - da indicare solo se il
                                  calcolo deve essere eseguito per un solo
                                  oggetto_pratica
 RITORNA:     number              Imposta dovuta per l'anno a seconda
                                  del tipo richiesto (A/S/null)
 NOTE:
 Rev.    Date         Author      Note
 000     11/05/2020   VD          Prima emissione.
*************************************************************************/
 ( a_cod_fiscale                  varchar2
 , a_anno                         number
 , a_tipo_tributo                 varchar2
 , a_tipo_imposta                 varchar2
 , a_oggetto_pratica              number     default null
) return number
is
   w_imposta                      number;
   w_imposta_acc                  number;
   w_oggetto                      number;
   w_flag_ruolo                   varchar2(1);
   w_flag_occupazione             varchar2(1);
BEGIN
   IF a_tipo_tributo in ('TASI', 'ICI') THEN
      begin
        select sum(imposta)
             , sum(imposta_acconto)
          into w_imposta
             , w_imposta_acc
          from PRATICHE_TRIBUTO prtr
             , OGGETTI_PRATICA ogpr
             , OGGETTI_IMPOSTA ogim
         where ogim.cod_fiscale      = a_cod_fiscale
           and ogim.anno             = a_anno
           and ogim.flag_calcolo     = 'S'
           and prtr.tipo_tributo||'' = a_tipo_tributo
           and ogpr.oggetto_pratica  = ogim.oggetto_pratica
           and prtr.pratica          = ogpr.pratica
           and nvl(a_oggetto_pratica,ogim.oggetto_pratica)
                                     = ogim.oggetto_pratica
             ;
      exception
        when no_data_found then
          return to_number(null);
      end;
   elsif a_tipo_tributo = 'TARSU' then
      begin
         select ogpr.oggetto
              , nvl(ogpr.tipo_occupazione,'P')
              , cotr.flag_ruolo
           into w_oggetto
              , w_flag_occupazione
              , w_flag_ruolo
           from codici_tributo cotr
              , oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_oggetto_pratica
            and cotr.tributo         = ogpr.tributo
         ;
      exception
         when no_data_found then
           return to_number(null);
      end;
      begin
        select sum(imposta)
          into w_imposta
          from PRATICHE_TRIBUTO prtr
             , OGGETTI_PRATICA ogpr
             , OGGETTI_IMPOSTA ogim
             , RUOLI ruol
         where ogim.cod_fiscale      = a_cod_fiscale
           and ogim.anno             = a_anno
           and ogim.flag_calcolo     = 'S'
           and prtr.tipo_tributo||'' = a_tipo_tributo
           and ogpr.oggetto_pratica  = ogim.oggetto_pratica
           and prtr.pratica          = ogpr.pratica
           and nvl(a_oggetto_pratica,ogim.oggetto_pratica)
                                     = ogim.oggetto_pratica
           and ruol.ruolo (+)        = ogim.ruolo
           and (    w_flag_occupazione||w_flag_ruolo = 'PS'
                and ogim.ruolo     is not null
                and ruol.anno_ruolo = a_anno
                and ruol.invio_consorzio is not null --SC 14/01/2015 senza questo sbaglia il calcolo delle sanzioni in fase di replica accertamento
                or  w_flag_occupazione||w_flag_ruolo <> 'PS'
                and ogim.ruolo     is null
               )
          ;
        return w_imposta;
      exception
        when no_data_found then
          return null;
      end;
   else
      --   Utilizziamo TARSU_2 per poter gestire velocemente la somma delle imposte
      --   per contribuente tipo_tributo e tributo perche'' da Dettaglio_imposte non
      --   viene passato il oggetto_pratica
      begin
         select sum(imposta)
           into w_imposta
           from PRATICHE_TRIBUTO prtr
              , OGGETTI_PRATICA ogpr
              , OGGETTI_IMPOSTA ogim
          where ogim.cod_fiscale      = a_cod_fiscale
            and ogim.anno             = a_anno
            and ogim.flag_calcolo     = 'S'
            and prtr.tipo_tributo||'' = decode(a_tipo_tributo,'TARSU_2','TARSU',a_tipo_tributo)
            and ogpr.oggetto_pratica  = ogim.oggetto_pratica
            and prtr.pratica          = ogpr.pratica
            and nvl(a_oggetto_pratica,ogim.oggetto_pratica)
                                      = ogim.oggetto_pratica
         ;
         return w_imposta;
      exception
        when no_data_found then
          return to_number(null);
      end;
   end if;
   --
   if a_tipo_imposta = 'A' then
      return w_imposta_acc;
   elsif
      a_tipo_imposta = 'S' then
      if w_imposta is not null or
         w_imposta_acc is not null then
         return nvl(w_imposta,0) - nvl(w_imposta_acc,0);
      else
         return to_number(null);
      end if;
   else
      return w_imposta;
   end if;
end;
/* End Function: F_IMPOSTA_CONT_ANNO_TITR_AS */
/

