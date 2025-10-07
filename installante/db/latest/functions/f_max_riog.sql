--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_max_riog stripComments:false runOnChange:true 
 
create or replace function F_MAX_RIOG
/*************************************************************************
 NOME:        F_MAX_RIOG
 DESCRIZIONE: Dati oggetto_pratica, anno e tipo di dato da estrarre,
              restituisce il tipo dato richiesto per l'oggetto_pratica
              e l'anno indicati dalla tabella RIFERIMENTI_OGGETTO.
 RITORNA:     varchar2            dato da RIOG
 NOTE:        Il parametro p_dato può assumere i seguenti valori:
              RE - Rendita
              CA - Categoria Catasto
              CL - Classe Catasto
 Rev.    Date         Author      Note
 001     10/06/2019   VD          Corretto test su anno validita.
 000     01/12/2008               Prima emissione.
*************************************************************************/
(p_oggetto_pratica in number
,p_anno            in number
,p_dato            in varchar2
) Return String
is
w_rendita       number;
w_categoria     varchar2(3);
w_classe        varchar2(2);
BEGIN
   BEGIN
      select to_number(substr(max(to_char(rio2.inizio_validita,'yyyymmdd')||
                                  lpad(to_char(rio2.rendita * 100),15,'0')
                                 ),9,15
                             )
                      ) / 100 rendita
            ,nvl(substr(max(to_char(rio2.inizio_validita,'yyyymmdd')||
                            rio2.categoria_catasto
                           ),9,3
                       )
                ,decode(max(ogg2.tipo_oggetto)
                       ,1,nvl(nvl(max(ogp2.categoria_catasto),max(ogg2.categoria_catasto)),'T')
                       ,nvl(max(ogp2.categoria_catasto),max(ogg2.categoria_catasto))
                       )
                ) categoria_catasto
            ,nvl(substr(max(to_char(rio2.inizio_validita,'yyyymmdd')||
                            rio2.classe_catasto
                           ),9,2
                       )
                ,nvl(max(ogp2.classe_catasto)
                    ,max(ogg2.classe_catasto)
                    )
                ) classe_catasto
        into w_rendita
            ,w_categoria
            ,w_classe
        from riferimenti_oggetto   rio2
            ,oggetti_pratica       ogp2
            ,oggetti               ogg2
--       where rio2.da_anno (+)     >= p_anno
--         and rio2.a_anno  (+)     <= p_anno
       -- (VD - 10/06/2019): corretta condizione di where sull'anno.
       --                    Nella versione precedente non estraeva
       --                    mai niente
       where p_anno between rio2.da_anno (+) and rio2.a_anno (+)
         and rio2.oggetto (+)      = ogp2.oggetto
         and ogg2.oggetto          = ogp2.oggetto
         and ogp2.oggetto_pratica  = p_oggetto_pratica
         and (    p_dato           = 'RE'
              and nvl(ogp2.tipo_oggetto,0)
                                  <> 4
              or  p_dato          <> 'RE'
             )
       group by ogp2.oggetto_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_rendita      := null;
         w_categoria    := null;
         w_classe       := null;
   END;
   if p_dato = 'RE' then
      Return to_char(w_rendita);
   end if;
   if p_dato = 'CA' then
      Return w_categoria;
   end if;
   if p_dato = 'CL' then
      Return w_classe;
   end if;
   Return null;
END;
/* End Function: F_MAX_RIOG */
/

