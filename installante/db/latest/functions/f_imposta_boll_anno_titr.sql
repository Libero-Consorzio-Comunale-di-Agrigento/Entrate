--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_boll_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_IMPOSTA_BOLL_ANNO_TITR
/*************************************************************************
 NOME:        F_IMPOSTA_BOLL_ANNO_TITR
 DESCRIZIONE: Calcola l'imposta dovuta annuale per il contribuente e
              l'eventuale oggetto_pratica indicati.
 RITORNA:     number              Imposta annuale
 NOTE:        Utilizzata per stampa bollettini TOSAP/ICP.
 Rev.    Date         Author      Note
 001     14/03/2018   VD          Modificato test su anno di riferimento:
                                  al posto dell'anno della denuncia si
                                  considera l'anno della data di inizio
                                  occupazione.
 000     01/12/2008   XX          Prima emissione.
*************************************************************************/
(a_cod_fiscale  varchar2,
 a_anno         number,
 a_titr         varchar2,
 a_ogpr         number,
 a_CC           number,
 a_prat         number
) RETURN        number
IS
   w_imposta         number;
   w_flag_canone     varchar2(1);
   w_flag_tariffa    varchar2(1);
BEGIN
   BEGIN
     select nvl(titr.flag_canone,'N')
          , nvl(titr.flag_tariffa,'N')
       into w_flag_canone
          , w_flag_tariffa
       from tipi_tributo titr
      where titr.tipo_tributo  = a_titr
          ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
   END;
   IF a_titr = 'ICI' THEN
      BEGIN
         select round(sum(imposta))
           into w_imposta
           from tipi_tributo      titr
               ,pratiche_tributo  prtr
               ,oggetti_pratica   ogpr
               ,oggetti_imposta   ogim
          where nvl(titr.conto_corrente,0)    = nvl(a_cc,0)
            and titr.tipo_tributo             = prtr.tipo_tributo
            and ogim.cod_fiscale              = a_cod_fiscale
            and ogim.anno                     = a_anno
            and ogim.flag_calcolo             = 'S'
            and prtr.tipo_tributo||''         = a_titr
            and ogpr.oggetto_pratica          = ogim.oggetto_pratica
            and prtr.pratica                     = ogpr.pratica
            and decode(nvl(a_ogpr,0),0,ogim.oggetto_pratica,a_ogpr)
                                              = ogim.oggetto_pratica
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
    ELSE
      BEGIN
         select decode(a_titr
                       ,'TARSU',decode(w_flag_tariffa
                                      ,'S',sum(imposta)
                                      ,round(sum(imposta))
                                      )
                       ,decode(w_flag_canone
                              ,'S',sum(imposta)
                              ,round(sum(imposta))
                              )
                       )
           into w_imposta
           from codici_tributo    cotr
               ,tipi_tributo      titr
               ,pratiche_tributo  prtr
               ,oggetti_pratica   ogpr
               ,oggetti_imposta   ogim
               ,oggetti_contribuente ogco
          where nvl(cotr.conto_corrente,nvl(titr.conto_corrente,0))
                                                 = nvl(a_cc,0)
            and cotr.tributo                     = ogpr.tributo
            and cotr.tipo_tributo                = prtr.tipo_tributo
            and ogim.cod_fiscale                 = a_cod_fiscale
            and ogim.anno                        = a_anno
            and ogim.flag_calcolo                = 'S'
            and ogim.ruolo                       is null  -- per evitare di estrarre gli oggetti a ruolo
            and titr.tipo_tributo                = prtr.tipo_tributo
            and prtr.tipo_tributo||''            = a_titr
            and ogpr.oggetto_pratica             = ogim.oggetto_pratica
            and ogpr.oggetto_pratica             = ogco.oggetto_pratica
            and prtr.pratica                     = ogpr.pratica
            and decode(nvl(a_ogpr,0),0,ogim.oggetto_pratica,a_ogpr)
                                              = ogim.oggetto_pratica
            and (    nvl(a_prat,0)               > 0
                 or  nvl(a_prat,0)               = 0
                 -- (VD - 14/03/2018): sostituito anno denuncia con anno
                 --                    data inizio occupazione
                 --and ogim.anno                   > prtr.anno
                 and ogim.anno                   > to_number(to_char(nvl(ogco.data_decorrenza
                                                            ,to_date('01011900','ddmmyyyy'))
                                                            ,'yyyy')
                                                            )
                )
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
   END IF;
END;
/* End Function: F_IMPOSTA_BOLL_ANNO_TITR */
/

