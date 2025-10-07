--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sanzioni_addizionali stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_SANZIONI_ADDIZIONALI
/*************************************************************************
 La funzione calcola le sanzioni relative alle addizionali.
 Codici sanzione: 891, 892, 893, 894
  Rev.    Date         Author      Note
  4       10/12/2024   AB          #76942
                                   Sistemato controllo su sanz con sequenza
  3       05/10/2016   VD          Aggiunto nvl a zero degli importi
                                   per i casi di tipo tributo diverso da
                                   TARSU
  2       24/05/2016   AB          Aggiunto anche il controllo di nvl sia
                                   in tipo_causale che in Magg Tares
                                   come abbiamo in altri punti
  1       24/07/2015   VD          Modificata query su codici sanzione:
                                   invece di trattare codici fissi, tratta
                                   tutti i codici con tipo_causale = 'E'
                                   e flag maggiorazione tares nullo
*************************************************************************/
( a_pratica          number
, a_codice_sanzione  varchar2
)
RETURN number
IS
 w_add_eca        number;
 w_mag_eca        number;
 w_add_pro        number;
 w_iva            number;
 BEGIN
     select sum(nvl(f_round(CATA.ADDIZIONALE_ECA * nvl(SAPR.IMPORTO,SANZIONI.SANZIONE)/100,1),0))
          , sum(nvl(f_round(CATA.MAGGIORAZIONE_ECA * nvl(SAPR.IMPORTO,SANZIONI.SANZIONE)/100,1),0))
          , sum(nvl(f_round(CATA.ADDIZIONALE_PRO * nvl(SAPR.IMPORTO,SANZIONI.SANZIONE)/100,1),0))
          , sum(nvl(f_round(CATA.ALIQUOTA * nvl(SAPR.IMPORTO,SANZIONI.SANZIONE)/100,1),0))
       into w_add_eca
          , w_mag_eca
          , w_add_pro
          , w_iva
      from  carichi_tarsu cata,
            sanzioni_pratica sapr,
            sanzioni,
            pratiche_tributo prtr_acc
      where cata.anno                = prtr_acc.anno
        and sanzioni.tipo_tributo    = 'TARSU'
--        and sanzioni.cod_sanzione    in (1,100,101,111,121,131,141)
        and nvl(sanzioni.tipo_causale,'*') = 'E'
        and nvl(sanzioni.flag_magg_tares,'N') = 'N'
        and sanzioni.cod_sanzione    = sapr.cod_sanzione
        and sanzioni.tipo_tributo    = sapr.tipo_tributo
        and sanzioni.sequenza        = sapr.sequenza_sanz
        and sapr.pratica             = prtr_acc.pratica
        and prtr_acc.pratica         = a_pratica
    ;
    --
    -- (VD - 05/10/2015) Aggiunto nvl su valori restituiti
    -- per gestire tipo_tributo diverso da TARSU
    --
    if a_codice_sanzione = 891 then
       RETURN nvl(w_add_pro,0);
    elsif a_codice_sanzione = 892 then
       RETURN nvl(w_add_eca,0);
    elsif a_codice_sanzione = 893 then
       RETURN nvl(w_mag_eca,0);
    elsif a_codice_sanzione = 894 then
       RETURN nvl(w_iva,0);
    else
       RETURN 0;
    end if;
 EXCEPTION
    WHEN OTHERS THEN
         RETURN -1;
END;
/* End Function: F_SANZIONI_ADDIZIONALI */
/
