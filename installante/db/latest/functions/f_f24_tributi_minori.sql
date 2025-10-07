--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_tributi_minori stripComments:false runOnChange:true 
 
create or replace function F_F24_TRIBUTI_MINORI
/*************************************************************************
 NOME:        F_F24_TRIBUTI_MINORI
 DESCRIZIONE: Stampa modello F24: compone le righe per codice tributo
              relativamente a TOSAP e ICP
 RITORNA:     varchar2             Stringa concatenata codice tributo e
                                   importo in formato stampabile
 NOTE:        Utilizzata in PB per F24 TOSAP/ICP (tributi minori).
              Parametro a_tioc: tipo occupazione.
                                Vale 'P' per permanente
                                     'T' per temporanea
              Parametro a_tiim: tipo_importo.
                                Vale 'T' per importo totale
                                     'R' per importo rata
 Rev.    Date         Author      Note
 001     08/05/2018   VD          Aggiunta gestione TARSU.
 000     14/03/2018   VD          Prima emissione.
*************************************************************************/
(a_riga                number
,a_tipo_tributo        varchar2
,a_cod_fiscale         varchar2
,a_anno                number
,a_ogpr                number
,a_prat                number
,a_tioc                varchar2
,a_tiim                varchar2
,a_importo             number
,a_rata                number default null
)
return varchar2
is
w_occ_perm             varchar2(14);
w_occ_temp             varchar2(14);
w_importo_perm         number := 0;
w_importo_temp         number := 0;
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   if nvl(a_tioc,'P') = 'P' then
      if a_tiim = 'T' then
         w_importo_perm := F_F24_IMPOSTA_ANNO_TITR(a_cod_fiscale
                                                  ,a_anno
                                                  ,a_tipo_tributo
                                                  ,a_ogpr
                                                  ,a_prat
                                                  ,nvl(a_tioc,'P')
                                                  );
      else
         w_importo_perm := a_importo;
      end if;
   end if;
   if nvl(a_tioc,'T') = 'T' then
      if a_tiim = 'T' then
         w_importo_temp := F_F24_IMPOSTA_ANNO_TITR(a_cod_fiscale
                                                  ,a_anno
                                                  ,a_tipo_tributo
                                                  ,a_ogpr
                                                  ,a_prat
                                                  ,nvl(a_tioc,'T')
                                                  );
      else
         w_importo_temp := a_importo;
      end if;
   end if;
   if a_tipo_tributo = 'TOSAP' then
      w_occ_perm  := '3931'||to_char(round(w_importo_perm,0),'999999990');
      w_occ_temp  := '3932'||to_char(round(w_importo_temp,0),'999999990');
      if nvl(w_importo_perm,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_perm;
         i := i+1;
      end if;
      if nvl(w_importo_temp,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_temp;
         i := i+1;
      end if;
   end if;
   if a_tipo_tributo = 'ICP' then
      w_occ_perm  := '3964'||to_char(round(w_importo_perm,0),'999999990');
      w_occ_temp  := '3964'||to_char(round(w_importo_temp,0),'999999990');
      if nvl(w_importo_perm,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_perm;
         i := i+1;
      end if;
      if nvl(w_importo_temp,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_temp;
         i := i+1;
      end if;
   end if;
   if a_tipo_tributo = 'TARSU' then
      w_occ_perm  := '3944'||to_char(round(w_importo_perm,0),'999999990');
      w_occ_temp  := '3944'||to_char(round(w_importo_temp,0),'999999990');
      if nvl(w_importo_perm,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_perm;
         i := i+1;
      end if;
      if nvl(w_importo_temp,0) > 0.49 then
         t_riga(to_char(i)) := w_occ_temp;
         i := i+1;
      end if;
   end if;
   if a_riga > i then
      return null;
   else
      return t_riga(to_char(a_riga));
   end if;
end;
/* End Function: F_F24_TRIBUTI_MINORI */
/

