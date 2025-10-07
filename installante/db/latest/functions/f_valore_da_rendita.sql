--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_valore_da_rendita stripComments:false runOnChange:true 
 
create or replace function F_VALORE_DA_RENDITA
( a_rendita           IN number
, a_tipo_ogge         IN number
, a_anno              IN number
, a_categoria_catasto IN varchar2
, a_imm_storico       IN varchar2)
RETURN number
IS
w_moltiplicatore NUMBER;
w_valore         NUMBER;
w_rivalutazione  number;
errore           exception;
w_errore         varchar2(2000);
BEGIN
      BEGIN
         select decode(a_tipo_ogge
                      ,1,nvl(molt.moltiplicatore,1)
                      ,3,decode(nvl(a_imm_storico,'N')||to_char(sign(2012 - a_anno))
                               ,'S1',100
                               ,nvl(molt.moltiplicatore,1)
                               )
                      ,1
                      )
           into w_moltiplicatore
           from moltiplicatori molt
          where molt.categoria_catasto = decode(a_tipo_ogge
                                               ,1,nvl(a_categoria_catasto,'T')
                                               ,a_categoria_catasto
                                               )
            and anno    = a_anno
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_moltiplicatore := 1;
         WHEN others THEN
            w_errore := 'Errore in ricerca Moltiplicatori'||
                        ' ('||SQLERRM||')';
            RAISE errore;
      END;
      BEGIN
         select aliquota
           into w_rivalutazione
           from rivalutazioni_rendita
          where anno = a_anno
            and tipo_oggetto = a_tipo_ogge
              ;
      EXCEPTION
         WHEN no_data_found THEN
             w_rivalutazione := 0;
      END;
   w_valore := round(a_rendita * w_moltiplicatore * (100 + nvl(w_rivalutazione,0)) / 100 ,2);
   RETURN w_valore ;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in calcolo valore '||
       ' ('||SQLERRM||')');
END;
/* End Function: F_VALORE_DA_RENDITA */
/

