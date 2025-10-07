--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_imposta_anno_titr stripComments:false runOnChange:true 
 
create or replace function F_F24_IMPOSTA_ANNO_TITR
/*************************************************************************
 NOME:        F_F24_IMPOSTA_ANNO_TITR
 DESCRIZIONE: Calcola l'imposta dovuta annuale per il contribuente e
              l'eventuale oggetto_pratica indicati.
 RITORNA:     number              Imposta annuale
 NOTE:        Utilizzata in PB per F24 TOSAP/ICP.
              Come anno di riferimento si considera l'anno della data
              di inizio occupazione (per trattare correttamente denunce
              con anno di riferimento diverso da quello della data di
              inizio occupazione).
 Rev.    Date         Author      Note
 002     25/09/2019   VD          Aggiunto calcolo imposta complessivo
                                  per l'anno, da utilizzare nella stampa
                                  dell'F24 da situazione contribuente.
                                  Passando la pratica a -1, si calcola
                                  l'imposta tenendo conto sia delle
                                  denunce dell'anno che delle denunce
                                  degli anni precedenti.
 001     08/05/2018   VD          Aggiunta gestione TARSU.
 000     14/03/2018   VD          Prima emissione.
*************************************************************************/
(a_cod_fiscale  varchar2,
 a_anno         number,
 a_titr         varchar2,
 a_ogpr         number,
 a_prat         number,
 a_tioc         varchar2
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
   IF a_titr in ('ICP','TOSAP','TARSU') THEN
      BEGIN
         select decode(w_flag_canone
                      ,'S',sum(imposta)
                          ,round(sum(imposta))
                      )
           into w_imposta
           from pratiche_tributo      prtr
               ,oggetti_pratica       ogpr
               ,oggetti_imposta       ogim
               ,oggetti_contribuente  ogco
          where ogim.cod_fiscale                 = a_cod_fiscale
            and ogim.anno                        = a_anno
            and ogim.flag_calcolo                = 'S'
            and ogim.ruolo                       is null  -- per evitare di estrarre gli oggetti a ruolo
            and prtr.tipo_tributo||''            = a_titr
            and ogpr.oggetto_pratica             = ogim.oggetto_pratica
            and ogpr.oggetto_pratica             = ogco.oggetto_pratica
            and prtr.pratica                     = ogpr.pratica
            and ogpr.tipo_occupazione            = nvl(a_tioc,ogpr.tipo_occupazione)
            and decode(nvl(a_ogpr,0),0,ogim.oggetto_pratica,a_ogpr)
                                                 = ogim.oggetto_pratica
            and ((    nvl(a_prat,0)              > 0
                  and prtr.pratica               = a_prat)
--            and (    nvl(a_prat,0)              > 0
              or (nvl(a_prat,0)                  = 0
                 and ogim.anno                   > to_number(to_char(nvl(ogco.data_decorrenza
                                                            ,to_date('01011900','ddmmyyyy'))
                                                            ,'yyyy')
                                                            )
                 )
              or (nvl(a_prat,0)                  < 0
                 and ogim.anno                   >= to_number(to_char(nvl(ogco.data_decorrenza
                                                            ,to_date('01011900','ddmmyyyy'))
                                                            ,'yyyy')
                                                            )
                 )
                )
         ;
         RETURN w_imposta;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RETURN NULL;
      END;
   ELSE
      RETURN 0;
   END IF;
END;
/* End Function: F_F24_IMPOSTA_ANNO_TITR */
/

