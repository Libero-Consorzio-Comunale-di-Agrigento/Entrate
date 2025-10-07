--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dettaglio_imp_ici stripComments:false runOnChange:true 
 
create or replace function F_DETTAGLIO_IMP_ICI
(a_cod_fiscale varchar2
,a_anno        number
,a_tipo_vers   varchar2)
 return varchar2
 -- la funzione crea una stringa dove vengono inseriti gli importi dell'imposta
 -- utilizzati nella stampa del bollettino completo ICI
 is
 w_return             varchar2(1000);
 w_terreni            number  := 0;
 w_aree               number  := 0;
 w_ab_principale      number  := 0;
 w_altri              number  := 0;
 w_detrazione         number  := 0;
 w_importo            number  := 0;
 w_terreni_acc        number  := 0;
 w_aree_acc           number  := 0;
 w_ab_principale_acc  number  := 0;
 w_altri_acc          number  := 0;
 w_detrazione_acc     number  := 0;
 w_importo_acc        number  := 0;
 w_numero_fabbricati  number  := 0;
 w_oggetto            number  := 9999999999;
 w_detra_impo         number  := 0;
 w_detra_impo_acconto number  := 0;
cursor sel_ogpr( p_cod_fiscale varchar2, p_anno number) is
 select nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)           tipo_oggetto
      , nvl(ogpr.categoria_catasto,ogge.categoria_catasto) categoria_catasto
      , ogco.flag_ab_principale
      , nvl(ogim.imposta,0)                                imposta
      , nvl(ogim.imposta_acconto,0)                        imposta_acconto
      , nvl(ogim.detrazione,0)                             detrazione
      , nvl(ogim.detrazione_acconto,0)                     detrazione_acconto
       , nvl(ogim.detrazione_imponibile,0)                  detrazione_imponibile
       , nvl(ogim.detrazione_imponibile_acconto,0)          detrazione_imponibile_acconto
      , ogpr.oggetto
   from oggetti_imposta      ogim
      , oggetti_pratica      ogpr
      , pratiche_tributo     prtr
      , oggetti_contribuente ogco
      , oggetti              ogge
  where ogco.cod_fiscale     = ogim.cod_fiscale
    and ogco.oggetto_pratica = ogim.oggetto_pratica
    and ogpr.pratica         = prtr.pratica
    and ogpr.oggetto         = ogge.oggetto
    and ogpr.oggetto_pratica = ogim.oggetto_pratica
    and prtr.tipo_tributo    = 'ICI'
    and ogim.flag_calcolo    = 'S'
    and ogim.cod_fiscale     = p_cod_fiscale
    and ogim.anno            = p_anno
      ;
 begin
  FOR rec_ogpr in sel_ogpr (a_cod_fiscale, a_anno)
   LOOP
--Terreni
  if  rec_ogpr.tipo_oggetto = 1 then
      w_terreni     := w_terreni     + rec_ogpr.imposta;
      w_terreni_acc := w_terreni_acc + rec_ogpr.imposta_acconto;
-- Aree
  elsif rec_ogpr.tipo_oggetto = 2 then
      w_aree     := w_aree     + rec_ogpr.imposta;
      w_aree_acc := w_aree_acc + rec_ogpr.imposta_acconto;
-- Abitazioni Principali
  elsif rec_ogpr.flag_ab_principale = 'S' and substr(rec_ogpr.categoria_catasto,1,1) = 'A' then
      w_ab_principale     := w_ab_principale     + rec_ogpr.imposta;
      w_ab_principale_acc := w_ab_principale_acc + rec_ogpr.imposta_acconto;
      if w_oggetto != rec_ogpr.oggetto then
         w_numero_fabbricati := w_numero_fabbricati + 1;
      end if;
 -- Altri
  else
      w_altri     := w_altri     + rec_ogpr.imposta;
      w_altri_acc := w_altri_acc + rec_ogpr.imposta_acconto;
      if w_oggetto != rec_ogpr.oggetto then
         w_numero_fabbricati := w_numero_fabbricati + 1;
      end if;
  end if;
 w_detrazione         := w_detrazione         + rec_ogpr.detrazione;
 w_importo            := w_importo            + rec_ogpr.imposta;
 w_detrazione_acc     := w_detrazione_acc     + rec_ogpr.detrazione_acconto;
 w_importo_acc        := w_importo_acc        + rec_ogpr.imposta_acconto;
 w_detra_impo         := w_detra_impo         + rec_ogpr.detrazione_imponibile;
 w_detra_impo_acconto := w_detra_impo_acconto + rec_ogpr.detrazione_imponibile_acconto;
 w_oggetto            := rec_ogpr.oggetto;
END LOOP;
if a_tipo_vers = 'T' then
   w_return :=  lpad(to_char(round(w_importo,0) * 100),15,' ');           -- Importo
   w_return :=  w_return || lpad(to_char(w_terreni * 100),15,' ');        -- Terreni
   w_return :=  w_return || lpad(to_char(w_aree * 100),15,' ');           -- Aree
   w_return :=  w_return || lpad(to_char(w_ab_principale * 100),15,' ');  -- Abitazione Principale
   w_return :=  w_return || lpad(to_char(w_altri * 100),15,' ');          -- Altri
   w_return :=  w_return || lpad(to_char(w_detrazione * 100),15,' ');     -- Detrazioni
   w_return :=  w_return || lpad(to_char(w_numero_fabbricati),4,' ');     -- Numero Fabbricati
   w_return :=  w_return || lpad(to_char(w_detra_impo * 100),15,' ');     -- Detrazione Imponibile
elsif a_tipo_vers = 'A' then
   w_return :=  lpad(to_char(round(w_importo_acc,0) * 100),15,' ');           -- Importo Acconto
   w_return :=  w_return || lpad(to_char(w_terreni_acc * 100),15,' ');        -- Terreni Acconto
   w_return :=  w_return || lpad(to_char(w_aree_acc * 100),15,' ');           -- Aree Acconto
   w_return :=  w_return || lpad(to_char(w_ab_principale_acc * 100),15,' ');  -- Abitazione Principale Acconto
   w_return :=  w_return || lpad(to_char(w_altri_acc * 100),15,' ');          -- Altri Acconto
   w_return :=  w_return || lpad(to_char(w_detrazione_acc * 100),15,' ');     -- Detrazioni Acconto
   w_return :=  w_return || lpad(to_char(w_numero_fabbricati),4,' ');         -- Numero Fabbricati
   w_return :=  w_return || lpad(to_char(w_detra_impo_acconto * 100),15,' '); -- Detrazioni Imponibile Acconto
elsif a_tipo_vers = 'S' then
   w_return :=  lpad(to_char((round(w_importo) - round(w_importo_acc)) * 100),15,' ');            -- Importo Saldo
   w_return :=  w_return || lpad(to_char((w_terreni - w_terreni_acc) * 100),15,' ');              -- Terreni Saldo
   w_return :=  w_return || lpad(to_char((w_aree - w_aree_acc) * 100),15,' ');                    -- Aree Saldo
   w_return :=  w_return || lpad(to_char((w_ab_principale - w_ab_principale_acc) * 100),15,' ');  -- Abitazione Principale Saldo
   w_return :=  w_return || lpad(to_char((w_altri - w_altri_acc) * 100),15,' ');                  -- Altri Saldo
   w_return :=  w_return || lpad(to_char((w_detrazione - w_detrazione_acc) * 100),15,' ');        -- Detrazioni Saldo
   w_return :=  w_return || lpad(to_char(w_numero_fabbricati),4,' ');                             -- Numero Fabbricati Saldo
   w_return :=  w_return || lpad(to_char((w_detra_impo - w_detra_impo_acconto) * 100),15,' ');    -- Detrazioni Imponibile Saldo
else
   w_return :='';
end if;
  return w_return;
  exception
      when no_data_found then
        return NULL;
END;
/* End Function: F_DETTAGLIO_IMP_ICI */
/

