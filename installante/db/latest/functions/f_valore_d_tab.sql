--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_valore_d_tab stripComments:false runOnChange:true 
 
create or replace function F_VALORE_D_TAB
(a_oggetto_pratica      in number
,a_anno                 in number
,a_anno_costo           in number
,a_riv                  in varchar2
,a_group_by             in varchar2
) return number
is
nValore                 number;
BEGIN
   if a_group_by = 'S' then
      BEGIN
         select round(nvl(cost.costo,0) * decode(a_riv,'S',nvl(coec.coeff,0),1),2)
           into nValore
           from coefficienti_contabili    coec
               ,costi_storici             cost
          where coec.anno_coeff       (+)    = cost.anno
            and coec.anno             (+)    = a_anno
            and cost.oggetto_pratica         = a_oggetto_pratica
            and cost.anno                    = a_anno_costo
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nValore := null;
      END;
   else
      BEGIN
         select sum(round(nvl(cost.costo,0) * decode(a_riv,'S',nvl(coec.coeff,0),1),2))
           into nValore
           from coefficienti_contabili    coec
               ,costi_storici             cost
          where coec.anno_coeff       (+)    = cost.anno
            and coec.anno             (+)    = a_anno
            and cost.oggetto_pratica         = a_oggetto_pratica
            and cost.anno                    < a_anno
          group by
                cost.oggetto_pratica
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nValore := null;
      END;
   end if;
   Return nValore;
END;
/* End Function: F_VALORE_D_TAB */
/

