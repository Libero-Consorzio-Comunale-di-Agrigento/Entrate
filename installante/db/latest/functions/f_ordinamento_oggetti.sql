--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ordinamento_oggetti stripComments:false runOnChange:true 
 
create or replace function F_ORDINAMENTO_OGGETTI
( p_oggetto                   number,
  p_oggetto_pratica           number,
  p_oggetto_pratica_rif_ap    number,
  p_flag_ab_principale        varchar2,
  p_flag_possesso             varchar2,
  p_mesi_possesso_1sem        number,
  p_categoria_catasto         varchar2 default null
)
  return varchar2
/*************************************************************************
 Function utilizzata in CALCOLO_IMPOSTA_ICI e CALCOLO_IMPOSTA_TASI
 per determinare l'ordinamento corretto degli oggetti del contribuente
  Rev.    Date         Author      Note
  1       20/09/2016   AB          Aggiunta la prima lettera della categoria catasto
                                   per risolvere l'ordinamento nei casi di mini imu
                                   in alcune stuazioni venivano prima i C degli A,
                                   perche andava per OGPR, e il C era precedente all'A
  0       11/05/2016   VD          Prima emissione
*************************************************************************/
AS
   w_rottura   varchar2(12);
   w_lettera_catasto varchar2(1);
BEGIN
   --
   -- Prima ci devono essere i periodi con flag_possesso null, in quanto
   -- sono relativi alla prima parte dell'anno
   --
--   w_rottura := lpad(p_oggetto,10,'0')||nvl(p_flag_possesso,'N');
   w_rottura := nvl(p_flag_possesso,'N');
   --
   -- Nell'ambito dei periodi con flag_possesso null, i periodi con mesi
   -- primo semestre valorizzati (se ce ne sono piu' di uno l'ordinamento
   -- e' casuale)
   --
   begin
      select substr(nvl(p_categoria_catasto,'X'),1,1)
        into w_lettera_catasto
        from dual;
   end;
   if nvl(p_mesi_possesso_1sem,0) = 0 then
      w_rottura := w_rottura||'9';
   else
      w_rottura := w_rottura||p_mesi_possesso_1sem;
   end if;
   w_rottura := w_rottura||w_lettera_catasto;
   IF p_flag_ab_principale = 'S'
   THEN
      RETURN w_rottura||lpad(nvl(p_oggetto_pratica_rif_ap,p_oggetto_pratica),10,'0');
   END IF;
   IF p_oggetto_pratica_rif_ap IS NOT NULL
   THEN
      RETURN w_rottura||lpad(p_oggetto_pratica_rif_ap,10,'0');
   ELSE
      RETURN w_rottura||lpad(p_oggetto_pratica,10,'0');
   END IF;
END;
/* End Function: F_ORDINAMENTO_OGGETTI */
/

