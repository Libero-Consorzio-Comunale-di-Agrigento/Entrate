--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_imposta_evasa_acc stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPOSTA_EVASA_ACC
/*************************************************************************
 NOME:        F_IMPOSTA_EVASA_ACC

 DESCRIZIONE: Dati codice fiscale, tipo tributo, anno determina l'imposta
              evasa accertata.
              Se il flag_magg_tares è 'S', determina la maggiorazione tares
              accertata.

 RITORNA:     number          Imposta evasa accertata.

 NOTE:        Valori previsti per flag_magg_tares:
              'N' - si calcola l'imposta evasa accertata comprensiva di
                    addizionali
              'S' - si calcola la sola maggiorazione tares evasa accertata
              'P' - si calcola l'addizionale provinciale evasa accertata


 Rev.    Date         Author      Note
 01      04/03/2021   VD          Aggiunto calcolo addizionale provinciale
                                  evasa accertata.
                                  Per fare questo si utilizza un nuovo
                                  valore del flag_magg_tares (fa schifo ma
                                  al momento non ci sono altre possibilita')
 00      XX/XX/XXXX   XX          Prima emissione.
*************************************************************************/
( a_cod_fiscale          in varchar2
, a_tipo_tributo         in varchar2
, a_anno                 in number
, a_flag_magg_tares      in varchar2
) Return number is
  nImporto                   number;
BEGIN
  if a_flag_magg_tares in ('N','S') then
     BEGIN
       select nvl(sum(nvl(sapr.importo,sanz.sanzione)
                      + (decode(sanz.cod_sanzione,1,1,100,1,101,1
                              ,decode(nvl(sanz.flag_magg_tares,'N'),'N',1,0)
                              )
                        * F_CATA(a_anno, sanz.tributo, nvl(sapr.importo,sanz.sanzione),'T'))
                     ),0)
         into nImporto
         from sanzioni_pratica       sapr
            , pratiche_tributo       prtr
            , sanzioni               sanz
        where sapr.pratica         = prtr.pratica
          and prtr.cod_fiscale     = a_cod_fiscale
          and prtr.tipo_tributo    = a_tipo_tributo
          and prtr.anno            = a_anno
          and sanz.cod_sanzione    = sapr.cod_sanzione
          and sanz.sequenza        = sapr.sequenza_sanz
          and sanz.tipo_tributo    = prtr.tipo_tributo
          and nvl(sanz.flag_magg_tares,'N') = a_flag_magg_tares
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and sanz.tipo_causale    = 'E'
          and prtr.data_notifica   is not null
          and prtr.tipo_evento     = 'A'
          and prtr.tipo_pratica    = 'A'
          and decode(prtr.flag_adesione
                    ,'S',to_date('01011900','ddmmyyyy')
                    ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
                    )         <  trunc(sysdate)
       ;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         nImporto := 0;
     END;
  else
     BEGIN
       select nvl(sum(nvl(sapr.importo,sanz.sanzione)),0)
         into nImporto
         from sanzioni_pratica       sapr
            , pratiche_tributo       prtr
            , sanzioni               sanz
        where sapr.pratica         = prtr.pratica
          and prtr.cod_fiscale     = a_cod_fiscale
          and prtr.tipo_tributo    = a_tipo_tributo
          and prtr.anno            = a_anno
          and a_anno              >= 2021
          and sanz.cod_sanzione    = sapr.cod_sanzione
          and sanz.sequenza        = sapr.sequenza_sanz
          and sanz.tipo_tributo    = prtr.tipo_tributo
          and nvl(prtr.stato_accertamento,'D') = 'D'
          and sanz.tipo_causale    = 'AP'
          and prtr.data_notifica   is not null
          and prtr.tipo_evento     = 'A'
          and prtr.tipo_pratica    = 'A'
          and decode(prtr.flag_adesione
                    ,'S',to_date('01011900','ddmmyyyy')
                    ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
                    )         <  trunc(sysdate)
       ;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         nImporto := 0;
     END;
  end if;
  Return nImporto;
END;
/* End Function: F_IMPOSTA_EVASA_ACC */
/
