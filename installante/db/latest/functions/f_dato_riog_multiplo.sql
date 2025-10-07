--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_dato_riog_multiplo stripComments:false runOnChange:true 
 
create or replace function F_DATO_RIOG_MULTIPLO
/*************************************************************************
 DESCRIZIONE: Dato un oggetto e un periodo di validità, restituisce
              un valore da RIFERIMENTI_OGGETTO tra quelli previsti
              dal parametro TIPO:
              CA - Categoria catasto
              CL - Classe catasto
              RE - Rendita
 Rev.    Date         Author      Note
 0       16/06/2003               Prima emissione
 1       08/01/2015   VD          Aggiunta gestione tipo RE - Rendita
*************************************************************************/
(a_oggetto              in     number
,a_categoria_catasto    in     varchar2
,a_classe_catasto       in     varchar2
,a_inizio_possesso      in     date
,a_fine_possesso        in     date
,a_inizio_possesso_1s   in     date
,a_fine_possesso_1s     in     date
,a_anno                 in     number
,a_tipo                 in     varchar2
) Return string is
w_cat_catasto           varchar2(3);
w_cla_catasto           varchar2(2);
w_categoria_catasto     varchar2(3);
w_classe_catasto        varchar2(2);
w_rendita               number;
w_dep_rendita           number;
w_valore                number;
w_ind                   number;
w_inizio_mese           date;
w_fine_mese             date;
BEGIN
   w_ind                   := 0;
   w_categoria_catasto     := null;
   w_classe_catasto        := null;
   LOOP
      w_ind := w_ind + 1;
      if w_ind > 12 then
         exit;
      end if;
      w_inizio_mese := to_date('01'||
                               lpad(to_char(w_ind),2,'0')||
                               lpad(to_char(a_anno),4,'0'),'ddmmyyyy'
                              );
      w_fine_mese   := last_day(w_inizio_mese);
      BEGIN
         select riog.categoria_catasto
               ,riog.classe_catasto
               ,riog.rendita
           into w_cat_catasto
               ,w_cla_catasto
               ,w_dep_rendita
           from riferimenti_oggetto riog
          where riog.oggetto           = a_oggetto
            and riog.inizio_validita  <= w_fine_mese
            and riog.fine_validita    >= w_inizio_mese
            and least(w_fine_mese,riog.fine_validita) + 1 -
                greatest(w_inizio_mese,riog.inizio_validita)
                                      >= 15
            and riog.inizio_validita   =
               (select max(rio2.inizio_validita)
                  from riferimenti_oggetto rio2
                 where rio2.oggetto           = riog.oggetto
                   and rio2.inizio_validita  <= w_fine_mese
                   and rio2.fine_validita    >= w_inizio_mese
                   and least(w_fine_mese,rio2.fine_validita) + 1 -
                       greatest(w_inizio_mese,rio2.inizio_validita)
                                             >= 15
               )
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            w_cat_catasto := null;
            w_cla_catasto := null;
      END;
      if  w_ind >= to_number(to_char(a_inizio_possesso,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso,'mm')) then
         w_categoria_catasto := w_cat_catasto;
         w_classe_catasto    := w_cla_catasto;
         w_rendita           := w_dep_rendita;
      end if;
      if  w_ind >= to_number(to_char(a_inizio_possesso_1s,'mm'))
      and w_ind <= to_number(to_char(a_fine_possesso_1s,'mm')) then
         null;
      end if;
   END LOOP;
   if w_categoria_catasto is null then
      w_categoria_catasto := a_categoria_catasto;
   end if;
   if w_classe_catasto is null then
      w_classe_catasto := a_classe_catasto;
   end if;
   if a_tipo = 'CA' then
      Return w_categoria_catasto;
   end if;
   if a_tipo = 'CL' then
      Return w_classe_catasto;
   end if;
   if a_tipo = 'RE' then
      Return to_char(w_rendita);
   end if;
   Return null;
END;
/* End Function: F_DATO_RIOG_MULTIPLO */
/

