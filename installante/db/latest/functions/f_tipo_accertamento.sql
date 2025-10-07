--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_tipo_accertamento stripComments:false runOnChange:true 
 
create or replace function F_TIPO_ACCERTAMENTO
(a_ogpr number)
 return varchar2
 is
 w_ogpr_rif number;
 w_pratica number;
 w_conta number;
 w_tipo_evento varchar2(1);
 w_return varchar2(100) :='';
 w_controllo varchar2(100) :='';
 w_cod_istat     varchar2(6); --Serve per il codice della regione e della provincia
-- la funzione dato in ingresso l'oggetto_pratica di un acceratmento mi da in uscita
-- una stringa che mi indica il tipo di accertamento
-- 16/01/2015 Betta T. Aggiunto test su tipo evento per gestire accertamenti auto
begin
  select ogpr.OGGETTO_PRATICA_RIF
       , ogpr.pratica
    into w_ogpr_rif
      , w_pratica
    from oggetti_pratica ogpr
   where ogpr.oggetto_pratica = a_ogpr
       ;
  select tipo_evento
  into   w_tipo_evento
  from   pratiche_tributo
  where  pratica = w_pratica
  ;
  if nvl(w_tipo_evento,'x') = 'A' then -- stiamo trattando un acc. auto
     return 'Atto';
  end if;
  select count(1)
    into w_conta
    from oggetti_pratica ogpr
   where ogpr.pratica = w_pratica
      ;
--  Controllo se è un accertamento con più oggetti pratica o con dati uguali alla dichiarazione
--  se è così passo null come tipo di accertamento perchè sono in un caso di accertamento multiplo
if w_conta > 1 then
   return  'Atto';
else
   begin
   select decode(ogpr_acc.tipo_occupazione||ogpr_acc.consistenza||ogpr_acc.tributo
                 ||ogpr_acc.categoria||ogpr_acc.tipo_tariffa||ogco_acc.perc_possesso,
             ogpr_dic.tipo_occupazione||ogpr_dic.consistenza||ogpr_dic.tributo
                 ||ogpr_dic.categoria||ogpr_dic.tipo_tariffa||ogco_dic.perc_possesso,'uguali','diversi')
    into w_controllo
     from oggetti_pratica ogpr_acc
       , oggetti_contribuente ogco_acc
        , oggetti_pratica ogpr_dic
      , oggetti_contribuente ogco_dic
    where ogpr_acc.oggetto_pratica = a_ogpr
     and nvl(ogpr_acc.oggetto_pratica_rif_v,ogpr_acc.oggetto_pratica_rif) = ogpr_dic.oggetto_pratica    (+)
     and ogpr_acc.oggetto_pratica = ogco_acc.oggetto_pratica
     and ogpr_dic.oggetto_pratica = ogco_dic.oggetto_pratica
        ;
   exception
     when no_data_found then
       w_controllo := ' ';
   end ;
   if w_controllo = 'uguali' then
     return 'Atto';
   end if;
end if;
if w_ogpr_rif is null then  --Niente denuncia, rif nullo
  begin
  select decode(count(*)
                       , 0, 'Accertamento per omessa presentazione della denuncia'
                                , 'Accertamento per tardiva presentazione della denuncia')
    into w_return
    from sanzioni_pratica sapr
      , oggetti_pratica ogpr
   where sapr.pratica         = ogpr.pratica
     and ogpr.oggetto_pratica = a_ogpr
     and sapr.cod_sanzione    in (5,6,105,106,305)
      ;
  exception
     when no_data_found then
       w_return := ' ';
  end ;
else --Accertamento su denuncia
  begin
  select decode (sign(prtr.DATA - scad.DATA_SCADENZA)
                                          , 1, 'Accertamento per tardiva presentazione della denuncia'
                                               , 'Accertamento per rettifica della denuncia presentata')
     into w_return
    from oggetti_pratica ogpr,
       pratiche_tributo prtr,
       scadenze scad
   where prtr.tipo_pratica || ''   = 'D'
     and prtr.pratica              = ogpr.pratica
     and ogpr.oggetto_pratica      = w_ogpr_rif
     and scad.tipo_tributo         = prtr.tipo_tributo
    and scad.anno                 = prtr.anno
    and scad.tipo_scadenza        = 'D'
       ;
  exception
     when no_data_found then
       w_return := 'Accertamento per rettifica della denuncia presentata';
  end ;
end if;
--Rivoli vuole una scritta diversa
BEGIN
     select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
       into w_cod_istat
       from dati_generali
    ;
  if w_cod_istat ='001219'
  and w_return = 'Accertamento per tardiva presentazione della denuncia' then
      w_return := 'Denuncia presentata oltre i termini di legge';
  end if;
EXCEPTION
  WHEN no_data_found THEN
       null;
  WHEN others THEN
       RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Codice Istat del Comune ' ||
                   ' ('||SQLERRM||')');
END;
return w_return;
end;
/* End Function: F_TIPO_ACCERTAMENTO */
/

