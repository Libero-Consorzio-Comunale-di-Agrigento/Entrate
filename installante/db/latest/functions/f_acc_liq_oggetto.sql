--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_acc_liq_oggetto stripComments:false runOnChange:true 
 
create or replace function F_ACC_LIQ_OGGETTO
(a_oggetto      IN number
,a_cod_fiscale  IN varchar2
,a_tipo_tributo IN varchar2)
RETURN varchar2
IS
  cursor sel_prtr (p_oggetto number, p_cod_fiscale varchar2, p_tipo_tributo varchar2) is
  select prtr.numero
       , prtr.tipo_pratica
       , prtr.tipo_tributo
      , decode(prtr.tipo_pratica,'A','Accertamento ','Liquidazione ')||
       prtr.tipo_tributo||
       ' Anno:'||to_char(prtr.anno)||
        ' del '||to_char(prtr.data,'dd/mm/yyyy')||
       decode(prtr.numero,null,'','  n°:'||prtr.numero)||
       decode(prtr.data_notifica,null,'',' Notificat'||decode(prtr.tipo_pratica,'A','o','a'))||
       decode(prtr.stato_accertamento,'A',' Annullat'||decode(prtr.tipo_pratica,'A','o','a')
                                     ,'R',' Revocat'||decode(prtr.tipo_pratica,'A','o','a')
                              ,'P',' Provvisori'||decode(prtr.tipo_pratica,'A','o','a')
                              ,'D',' Definitiv'||decode(prtr.tipo_pratica,'A','o','a')
                              ,'') testo
    from pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr.tipo_pratica          in ('A','L')
     and prtr.tipo_tributo        like p_tipo_tributo
     and prtr.pratica                = ogpr.pratica
     and ogpr.oggetto                = p_oggetto
     and ogpr.oggetto_pratica        = ogco.oggetto_pratica
     and ogco.cod_fiscale            = p_cod_fiscale
union
  select prtr1.numero
       , prtr1.tipo_pratica
      , prtr.tipo_tributo
      , decode(prtr1.tipo_pratica,'A','Accertamento ','Liquidazione ')||
       prtr.tipo_tributo||
       ' Anno:'||to_char(prtr1.anno)||
        ' del '||to_char(prtr1.data,'dd/mm/yyyy')||
       decode(prtr1.numero,null,'','  n°:'||prtr1.numero)||
                 decode(prtr1.data_notifica,null,'',' Notificat'||decode(prtr1.tipo_pratica,'A','o','a'))||
       decode(prtr1.stato_accertamento,'A',' Annullat'||decode(prtr1.tipo_pratica,'A','o','a')
                                      ,'R',' Revocat'||decode(prtr1.tipo_pratica,'A','o','a')
                               ,'P',' Provvisori'||decode(prtr1.tipo_pratica,'A','o','a')
                               ,'D',' Definitiv'||decode(prtr1.tipo_pratica,'A','o','a')
                               ,'') testo
    from pratiche_tributo prtr1
       , oggetti_pratica ogpr1
       , pratiche_tributo prtr
       , oggetti_pratica ogpr
       , oggetti_contribuente ogco
   where prtr1.tipo_pratica         in ('A','L')
     and prtr1.pratica               = ogpr1.pratica
     and ogpr1.oggetto_pratica_rif   = ogpr.oggetto_pratica
     and prtr.tipo_tributo        like p_tipo_tributo
     and prtr.pratica                = ogpr.pratica
     and ogpr.oggetto                = p_oggetto
     and ogpr.oggetto_pratica        = ogco.oggetto_pratica
     and ogco.cod_fiscale            = p_cod_fiscale
order by 3, 2, 1
       ;
w_stringa    varchar2(2000) := '';
begin
   for rec_prtr in sel_prtr(a_oggetto,a_cod_fiscale,a_tipo_tributo)
   loop
     w_stringa := w_stringa||rec_prtr.testo||chr(010);
   end loop;
 RETURN (w_stringa);
EXCEPTION
    WHEN OTHERS THEN
         RETURN null;
end;
/* End Function: F_ACC_LIQ_OGGETTO */
/

