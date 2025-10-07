--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_rendita stripComments:false runOnChange:true 
 
create or replace function F_RENDITA
/*************************************************************************
 Versione  Data              Autore    Descrizione
 1         26/11/2015        VD        Modificata selezione moltiplicatore
                                       per terreni con categoria catasto
                                       diversa da "T"
*************************************************************************/
( a_valore            IN number,
  a_tipo_ogge         IN number,
  a_anno_dic          IN number,
  a_categoria_catasto IN varchar2)
return number
is
  w_aliquota_rire  number;
  w_moltiplicatore number;
  w_rendita        number;
  errore           exception;
  w_errore         varchar2(2000);
begin
  begin
     select rire.aliquota
       into w_aliquota_rire
       from rivalutazioni_rendita rire
      where anno         = a_anno_dic
        and tipo_oggetto = a_tipo_ogge
     ;
  exception
     when no_data_found then
        w_aliquota_rire := 0;
     when others then
        w_errore := 'Errore in ricerca Rivalutazioni Rendita'||
                    ' ('||sqlerrm||')';
        raise errore;
  end;
--
  w_rendita := f_round(a_valore / (100 + nvl(w_aliquota_rire,0)) * 100 , 3);
--
  begin
     select nvl(molt.moltiplicatore,1)
       into w_moltiplicatore
       from moltiplicatori molt
  --          where (   (categoria_catasto = 'T' and a_tipo_ogge = 1)
  --                 or (categoria_catasto =  a_categoria_catasto and
  --                     a_tipo_ogge = 3)
  --                )
      where molt.categoria_catasto = decode(a_tipo_ogge
                                           ,1,nvl(a_categoria_catasto,'T')
                                           ,a_categoria_catasto
                                           )
        and anno    = a_anno_dic
     ;
  exception
     when no_data_found then
        w_moltiplicatore := 1;
     when others then
        w_errore := 'Errore in ricerca Moltiplicatori'||
                    ' ('||sqlerrm||')';
        raise errore;
  end;
  if a_tipo_ogge <> 2 then -- Per le Aree non si usa il moltiplicatore
     w_rendita := f_round(w_rendita / nvl(w_moltiplicatore,1),3);
  end if;
  return w_rendita ;
exception
  when errore then
       rollback;
       raise_application_error
    (-20999,w_errore);
  when others then
       rollback;
       raise_application_error
    (-20999,'Errore in calcolo rendita '||
       ' ('||sqlerrm||')');
end;
/* End Function: F_RENDITA */
/

