--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dettaglio_riog stripComments:false runOnChange:true 
 
create or replace function F_DETTAGLIO_RIOG
(a_oggetto           number
,a_anno              number
,a_tipo_oggetto      number
,a_categoria_catasto varchar2)
 return  varchar2
 is
 w_return        varchar2(4000);
 w_valore        varchar2(20);
cursor sel_riog( p_oggetto number, p_anno number) is
 select greatest(riog.inizio_validita,to_date('0101'||to_char(p_anno),'ddmmyyyy')) inizio_validita
      , least(riog.fine_validita,to_date('3112'||to_char(p_anno),'ddmmyyyy'))      fine_validita
      , ltrim(translate(to_char(riog.rendita,'9,999,999,999,990.00'),'.,',',.'))   rendita
      , decode(riog.categoria_catasto,null,'',' Cat: '||riog.categoria_catasto)    categoria_catasto
      , decode(riog.classe_catasto,null,'',' Cl: '||riog.classe_catasto)       classe_catasto
      , riog.categoria_catasto                                                     categoria_catasto_val
      , riog.rendita                                                               rendita_val
   from riferimenti_oggetto riog
  where riog.oggetto     = p_oggetto
    and riog.inizio_validita < to_date('3112'||to_char(p_anno),'ddmmyyyy')
    and nvl(riog.fine_validita,to_date('0101'||to_char(p_anno),'ddmmyyyy'))
                             > to_date('0101'||to_char(p_anno),'ddmmyyyy')
 order by 1
      ;
 begin
  w_return := null;
  w_valore := '';
  FOR rec_riog in sel_riog (a_oggetto, a_anno)
   LOOP
            BEGIN
            select ltrim(translate(to_char(
                                       round(rec_riog.rendita_val * decode(a_tipo_oggetto
                                                                          ,1,nvl(molt.moltiplicatore,1)
                                                                          ,3,nvl(molt.moltiplicatore,1)
                                                                          ,1
                                                                          )
                                                                  * (100 + nvl(rire.aliquota,0)) / 100
                                            ,2
                                            )
                                           ,'9,999,999,999,990.00'),'.,',',.'))
              into w_valore
              from moltiplicatori        molt
                 , rivalutazioni_rendita rire
             where molt.categoria_catasto (+) = nvl(rec_riog.categoria_catasto_val,a_categoria_catasto)
               and molt.anno              (+) = a_anno
               and rire.anno              (+) = a_anno
               and rire.tipo_oggetto      (+) = a_tipo_oggetto
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_valore := 0;
         END;
   w_return := w_return||'[a_capo'
                       ||'Dal '||to_char(rec_riog.inizio_validita,'dd/mm/yyyy')
                       ||' al '||to_char(rec_riog.fine_validita,'dd/mm/yyyy')
                       ||' Rendita: '||rec_riog.rendita
                       ||' Valore: '||w_valore
                       ||rec_riog.categoria_catasto
                       ||rec_riog.classe_catasto
                       ;
  END LOOP;
     return w_return;
  exception
      when no_data_found then
        return NULL;
END;
/* End Function: F_DETTAGLIO_RIOG */
/

