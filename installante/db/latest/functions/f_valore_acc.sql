--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_valore_acc stripComments:false runOnChange:true 
 
create or replace function F_VALORE_ACC
(a_valore            IN number
,a_tipo_ogge         IN number
,a_anno_dic          IN number
,a_anno              IN number
,a_categoria_catasto IN varchar2
,a_flag_rivalutato   IN varchar2)
RETURN number
IS
aliquota_new        NUMBER;
aliquota_dic        NUMBER;
moltiplicatore_new  NUMBER;
moltiplicatore_dic  NUMBER;
w_return            number;

BEGIN
   if a_tipo_ogge = 2 then
      RETURN a_valore;
   end if;
   aliquota_new := 0;
   BEGIN
      select aliquota
        into aliquota_new
        from rivalutazioni_rendita
       where anno = a_anno
         and tipo_oggetto = a_tipo_ogge
      ;
   EXCEPTION
      WHEN no_data_found THEN
      aliquota_new := 0;
   END;

   BEGIN
      select aliquota
        into aliquota_dic
        from rivalutazioni_rendita
       where anno = a_anno_dic
    and tipo_oggetto = a_tipo_ogge
      ;
   EXCEPTION
      WHEN no_data_found THEN
      aliquota_dic := 0;
   END;

   if nvl(a_flag_rivalutato,'N') = 'N' then
      aliquota_dic := 0;
   end if;

   w_return := (((a_valore * 100) / (100 + aliquota_dic)) * (100 + aliquota_new)) / 100;

   -- gestione immobili 'B' per anni > 2006  + 40% al valore
   -- la rivalutazione del +40% viene data solo se l'anno di denuncia è precedente al 2007
   -- e se l'anno di imposta è 2007 e successivo
--   if substr(a_categoria_catasto,1,1) = 'B' then
--      if nvl(a_anno_dic,0) < 2007 and nvl(a_anno,0) > 2006 then
--         return round(w_return * 140 / 100,2);
--      else
--         return w_return;
--      end if;
--   else
--      return w_return;
--   end if;

   BEGIN
      select moltiplicatore
        into moltiplicatore_dic
        from moltiplicatori
       where anno = a_anno_dic
         and categoria_catasto = a_categoria_catasto
      ;
   EXCEPTION
      WHEN no_data_found THEN
      moltiplicatore_dic := 1;
   END;

   BEGIN
      select moltiplicatore
        into moltiplicatore_new
        from moltiplicatori
       where anno = a_anno
         and categoria_catasto = a_categoria_catasto
      ;
   EXCEPTION
      WHEN no_data_found THEN
      moltiplicatore_new := 1;
   END;

   return round(w_return * moltiplicatore_new / moltiplicatore_dic,2);

EXCEPTION
   WHEN OTHERS THEN
        RETURN -1;
END;
/* End Function: F_VALORE */
/

