--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_ruolo_saldo stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_RUOLO_SALDO
/*************************************************************************
 NOME:        F_IMPORTI_RUOLO_SALDO
 DESCRIZIONE: Determina gli importi di imposta e addizionali di un ruolo
              a saldo, comprensivi di sgravi emessi su ruolo di acconto
              Utilizzata nella stampa della comunicazione a ruolo TARSU
 PARAMETRI:   Codice fiscale
              Anno
              Ruolo
              Tipo                Identifica il tipo di importo che si
                                  vuole ottenere dalla funzione
                                  L - Lordo (imposta + addizionali)
                                  N - Netto (imposta)
                                  E - Addizionale ECA + maggiorazione ECA
                                  P - Addizionale Provinciale
                                  M - Maggiorazione Tares
                                  I - Iva
 RITORNA:     number              Importo della tipologia prescelta
 NOTE:
 Rev.    Date         Author      Note
 001     17/01/2022   VD          Corretto calcolo in presenza di sgravi.
 000     19/10/2017   VD          Prima emissione.
*************************************************************************/
(a_cod_fiscale      in varchar2
,a_ruolo            in number
,a_tipo             in varchar2
) Return number
is
w_imposta_tot          number := 0;
w_add_eca_tot          number := 0;
w_add_pro_tot          number := 0;
w_mag_eca_tot          number := 0;
w_mag_tares_tot        number := 0;
w_iva_tot              number := 0;
w_compensazione_tot    number := 0;
w_comp_add_pro_tot     number := 0;
w_comp_netta_tot       number := 0;
BEGIN
   select sum(nvl(ogim.imposta,0))
        , sum(nvl(ogim.addizionale_eca,0))
        , sum(nvl(ogim.addizionale_pro,0))
        , sum(nvl(ogim.maggiorazione_eca,0))
        , sum(nvl(ogim.maggiorazione_tares,0))
        , sum(nvl(ogim.iva,0))
     into w_imposta_tot
        , w_add_eca_tot
        , w_add_pro_tot
        , w_mag_eca_tot
        , w_mag_tares_tot
        , w_iva_tot
     from oggetti_imposta  ogim
    where ogim.cod_fiscale  = a_cod_fiscale
      and ogim.ruolo        in (select ruol_prec.ruolo
                                  from ruoli, ruoli ruol_prec
                                 where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
                                   and ruol_prec.invio_consorzio(+) is not null
                                   and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
                                   and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
                                   and ruoli.ruolo = a_ruolo
                                   and nvl(ruoli.tipo_emissione, 'T') = 'S'
                                   and ruol_prec.ruolo != ruoli.ruolo
                                 union
                                select a_ruolo from dual);
    -- (VD - 17/01/2021) - Selezione di eventuali sgravi
    select f_sgravio_anno(a_ruolo,a_cod_fiscale,'C')
         , f_sgravio_anno(a_ruolo,a_cod_fiscale,'CN')
         , f_sgravio_anno(a_ruolo,a_cod_fiscale,'CP')
      into w_compensazione_tot
         , w_comp_add_pro_tot
         , w_comp_netta_tot
      from dual;
    -- Gestione del valore d'uscita a seconda del parametro a_tipo
   if a_tipo = 'E' then
      Return w_add_eca_tot + w_mag_eca_tot;
   elsif a_tipo = 'P' then
      Return w_add_pro_tot - nvl(w_comp_add_pro_tot,0);
   elsif a_tipo = 'I' then
      Return w_iva_tot;
   elsif a_tipo = 'M' then
      Return w_mag_tares_tot;
   elsif a_tipo = 'N' then
      Return w_imposta_tot - nvl(w_comp_netta_tot,0);
   elsif a_tipo = 'L' then
      Return w_imposta_tot + w_add_eca_tot + w_mag_eca_tot +
             w_add_pro_tot + w_iva_tot + w_mag_tares_tot -
             nvl(w_compensazione_tot,0);
   end if;
EXCEPTION
   WHEN OTHERS THEN
      Return 0;
END;
/* End Function: F_IMPORTI_RUOLO_SALDO */
/

