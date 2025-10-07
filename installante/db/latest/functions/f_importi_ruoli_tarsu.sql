--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_ruoli_tarsu stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_RUOLI_TARSU
/*************************************************************************
 NOME:        F_IMPORTI_RUOLI_TARSU
 DESCRIZIONE: Determina gli importi di imposta e addizionali di un ruolo
 PARAMETRI:   Codice fiscale
              Anno
              Ruolo
              Rata
              Tipo                Identifica il tipo di importo che si
                                  vuole ottenere dalla funzione
                                  IMPOSTA        Imposta (comprensiva di add.li)
                                  ADD_ECA        Addizionale ECA
                                  MAG_ECA        Maggiorazione ECA
                                  ECA            Add. + Magg. ECA
                                  ADD_PRO        Addizionale provinciale
                                  IVA            Iva
 RITORNA:     number              Importo della tipologia prescelta
 NOTE:
 Rev.    Date         Author      Note
 000     19/09/2011   --          Prima emissione.
 001     10/06/2016   VD          Aggiunta gestione nuovi tipi importo:
                                  NETTO          Imposta al netto delle
                                                 addizionali
                                  ECA            somma dei valori ECA
                                                 (add.+magg.)
                                  MAG_TAR        Maggiorazione TARES
*************************************************************************/
(a_cod_fiscale      in varchar2
,a_anno             in number
,a_ruolo            in number
,a_rata             in number
,a_tipo             in varchar2
) Return number
is
  cursor sel_ogim is
   select ogim.imposta
        , ogim.addizionale_eca
        , ogim.addizionale_pro
        , ogim.maggiorazione_eca
        , ogim.maggiorazione_tares
     from oggetti_imposta  ogim
    where ogim.cod_fiscale  = a_cod_fiscale
      and ogim.anno         = a_anno
      and ogim.ruolo        = a_ruolo
      ;
  cursor sel_raim is
   select raim.imposta
        , raim.addizionale_eca
        , raim.addizionale_pro
        , raim.maggiorazione_eca
     from rate_imposta raim
        , oggetti_imposta  ogim
    where ogim.oggetto_imposta = raim.oggetto_imposta
      and ogim.cod_fiscale     = a_cod_fiscale
      and ogim.anno            = a_anno
      and ogim.ruolo           = a_ruolo
      and raim.rata            = a_rata
      ;
w_addizionale_eca      number;
w_add_eca              number;
w_add_eca_tot          number := 0;
w_maggiorazione_eca    number;
w_mag_eca              number;
w_mag_eca_tot          number := 0;
w_addizionale_pro      number;
w_add_pro              number;
w_add_pro_tot          number := 0;
w_aliquota             number;
w_iva                  number;
w_iva_tot              number := 0;
w_maggiorazione_tares  number;
w_mag_tares            number;
w_mag_tares_tot        number := 0;
w_imposta              number;
w_imposta_tot          number := 0;
w_imp_netta            number;
w_imp_netta_tot        number := 0;
BEGIN
   BEGIN
      select nvl(cata.addizionale_eca,0)
            ,nvl(cata.maggiorazione_eca,0)
            ,nvl(cata.addizionale_pro,0)
            ,nvl(aliquota,0)
            ,maggiorazione_tares
        into w_addizionale_eca
            ,w_maggiorazione_eca
            ,w_addizionale_pro
            ,w_aliquota
            ,w_maggiorazione_tares
        from carichi_tarsu cata
       where cata.anno   = a_anno
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_addizionale_eca   := 0;
         w_maggiorazione_eca := 0;
         w_addizionale_pro   := 0;
         w_aliquota          := 0;
   END;
   if nvl(a_rata,0) = 0 then
      for rec_ogim in sel_ogim
      loop
         w_add_eca   := round(rec_ogim.imposta * w_addizionale_eca  / 100,2);
         w_mag_eca   := round(rec_ogim.imposta * w_maggiorazione_eca / 100,2);
         w_add_pro   := round(rec_ogim.imposta * w_addizionale_pro  / 100,2);
         w_iva       := round(rec_ogim.imposta * w_aliquota / 100,2);
         if w_maggiorazione_tares is null then
            w_mag_tares := to_number(null);
            w_mag_tares_tot := to_number(null);
         else
            w_mag_tares := nvl(rec_ogim.maggiorazione_tares,0);
            w_mag_tares_tot := w_mag_tares_tot + w_mag_tares;
         end if;
         w_imp_netta := rec_ogim.imposta;
         w_imposta   := rec_ogim.imposta + w_add_eca + w_mag_eca
                                         + w_add_pro + w_iva;
         w_add_eca_tot   := w_add_eca_tot   + w_add_eca;
         w_mag_eca_tot   := w_mag_eca_tot   + w_mag_eca;
         w_add_pro_tot   := w_add_pro_tot   + w_add_pro;
         w_iva_tot       := w_iva_tot       + w_iva;
         w_imp_netta_tot := w_imp_netta_tot + w_imp_netta;
         w_imposta_tot   := w_imposta_tot   + w_imposta;
      end loop;
   else
      for rec_raim in sel_raim
      loop
         w_add_eca   := round(rec_raim.imposta * w_addizionale_eca  / 100,2);
         w_mag_eca   := round(rec_raim.imposta * w_maggiorazione_eca / 100,2);
         w_add_pro   := round(rec_raim.imposta * w_addizionale_pro  / 100,2);
         w_iva       := round(rec_raim.imposta * w_aliquota / 100,2);
         w_imp_netta := rec_raim.imposta;
         w_imposta   := rec_raim.imposta + w_add_eca + w_mag_eca
                                         + w_add_pro + w_iva;
         w_add_eca_tot   := w_add_eca_tot   + w_add_eca;
         w_mag_eca_tot   := w_mag_eca_tot   + w_mag_eca;
         w_add_pro_tot   := w_add_pro_tot   + w_add_pro;
         w_iva_tot       := w_iva_tot       + w_iva;
         w_imp_netta_tot := w_imp_netta_tot + w_imp_netta;
         w_imposta_tot   := w_imposta_tot   + w_imposta;
      end loop;
      w_mag_tares_tot := to_number(null);
   end if;
   -- Gestione del valore d'uscita a seconda del parametro a_tipo
   if a_tipo = 'ADD_ECA' then
      Return w_add_eca_tot;
   elsif a_tipo = 'MAG_ECA' then
      Return w_mag_eca_tot;
   elsif a_tipo = 'ECA' then
      Return w_add_eca_tot + w_mag_eca_tot;
   elsif a_tipo = 'ADD_PRO' then
      Return w_add_pro_tot;
   elsif a_tipo = 'IVA' then
      Return w_iva_tot;
   elsif a_tipo = 'MAG_TAR' then
      Return w_mag_tares_tot;
   elsif a_tipo = 'IMPOSTA' then
      Return w_imposta_tot;
   elsif a_tipo = 'NETTO' then
      Return w_imp_netta_tot;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      Return 0;
END;
/* End Function: F_IMPORTI_RUOLI_TARSU */
/

