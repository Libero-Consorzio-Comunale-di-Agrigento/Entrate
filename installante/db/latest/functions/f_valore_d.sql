--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_valore_d stripComments:false runOnChange:true 
 
create or replace function F_VALORE_D
(a_oggetto_pratica    in number
,a_anno               in number
) return number
is
nValore                  number;
sCategoria_Catasto_1chr  varchar2(1);
nTipo_Oggetto            number;
nConta                   number;
cursor sel_costi is
select cost.anno
      ,cost.costo
      ,round(cost.costo * nvl(coec.coeff,1),2) rival
      ,nvl(coec.coeff,0) coeff
  from coefficienti_contabili coec
      ,costi_storici          cost
 where coec.anno          (+) = a_anno
   and coec.anno_coeff    (+) = cost.anno
   and cost.anno             <= a_anno
   and cost.oggetto_pratica   = a_oggetto_pratica
 order by
       cost.anno
;
--
-- Determinazione del Costo Storico.
-- (solo per categorie D e tipi Oggetto 4).
-- Si trattano i costi storici dell`oggetto pratica
-- indicato con anno dal 1992 (introduzione ICI)
-- all`anno di elaborazione.
-- Il Valore e` la somma dei costi rivalutati
-- del coefficiente realtivo all`anno del costo e
-- all`anno di elaborazione; in mancanza del
-- coefficiente non si rivaluta.
-- Quando si restituisce il valore null significa
-- che non e` possibile calcolare il valore storico.
--
BEGIN
   BEGIN
      select substr(nvl(ogpr.categoria_catasto,ogge.categoria_catasto),1,1)
            ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
        into sCategoria_Catasto_1chr
            ,nTipo_Oggetto
        from oggetti_pratica ogpr
            ,oggetti         ogge
       where ogpr.oggetto_pratica = a_oggetto_pratica
         and ogge.oggetto         = ogpr.oggetto
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         Return null;
   END;
   if sCategoria_Catasto_1chr = 'D' and nTipo_Oggetto = 4 then
      BEGIN
         select count(*)
           into nConta
           from costi_storici cost
          where cost.oggetto_pratica = a_oggetto_pratica
            and cost.anno           <= a_anno
         ;
         if nConta = 0 then
            Return null;
         end if;
      END;
      nValore := 0;
      for rec_costi in sel_costi
      loop
         nValore := nValore + rec_costi.rival;
      end loop;
      Return nValore;
   else
      Return null;
   end if;
END;
/* End Function: F_VALORE_D */
/

