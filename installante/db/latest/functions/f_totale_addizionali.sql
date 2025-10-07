--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_totale_addizionali stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_TOTALE_ADDIZIONALI
/*************************************************************************
 NOME:        F_TOTALE_ADDIZIONALI

 DESCRIZIONE: Sulla base della pratica viene rilasciata la somma delle
              addizionali ECa e provinciale

 NOTE:

 Rev.    Date         Author      Note
 000     22/03/2000               Prima emissione.
 001     10/01/2023   AB          Gestione del tipo_causale anziche i codici
                                  specifici e utilizzata nel pagonline_tr4 per
								  recuperate l'importo toale diu una pratica TARSU
 002     17/03/2023   AB          Aggiunta la sum per ogni addizionale, altrimenti
                                  usciva con -1
 003     10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con sequenza
*************************************************************************/
(a_pratica         number
)
RETURN number
IS
 w_add_eca        number;
 w_mag_eca        number;
 w_add_pro        number;
 w_iva            number;
 BEGIN
     select nvl(sum(f_round(CATA.ADDIZIONALE_ECA * nvl(SAPR.IMPORTO,SANZ.SANZIONE)/100,1)),0)
          , nvl(sum(f_round(CATA.MAGGIORAZIONE_ECA * nvl(SAPR.IMPORTO,SANZ.SANZIONE)/100,1)),0)
          , nvl(sum(f_round(CATA.ADDIZIONALE_PRO * nvl(SAPR.IMPORTO,SANZ.SANZIONE)/100,1)),0)
          , nvl(sum(f_round(CATA.ALIQUOTA * nvl(SAPR.IMPORTO,SANZ.SANZIONE)/100,1)),0)
       into w_add_eca, w_mag_eca, w_add_pro, w_iva
      from  carichi_tarsu cata,
            sanzioni_pratica sapr,
            sanzioni sanz,
            pratiche_tributo prtr_acc
      where cata.anno               = prtr_acc.anno
        and sanz.tipo_tributo       = 'TARSU'
        and nvl(sanz.tipo_causale,'*')  = 'E'
        and nvl(flag_magg_tares,'N') = 'N'
--        and sanzioni.cod_sanzione    in (1,100,101,111,121,131,141)
        and sanz.cod_sanzione       = sapr.cod_sanzione
        and sanz.sequenza           = sapr.sequenza_sanz
        and sapr.pratica            = prtr_acc.pratica
        and prtr_acc.pratica        = a_pratica
    ;
    RETURN w_add_eca + w_mag_eca + w_add_pro + w_iva;
 EXCEPTION
    WHEN OTHERS THEN
         RETURN -1;
END;
/* End Function: F_TOTALE_ADDIZIONALI */
/
