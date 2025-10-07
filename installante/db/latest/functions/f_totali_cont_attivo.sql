--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_totali_cont_attivo stripComments:false runOnChange:true 
 
create or replace function F_TOTALI_CONT_ATTIVO
RETURN   string IS
w_attivo_ici_0     number(8) := 0;
w_attivo_iciap_0   number(8) := 0;
w_attivo_icp_0     number(8) := 0;
w_attivo_tarsu_0   number(8) := 0;
w_attivo_tosap_0   number(8) := 0;
w_attivo_0         number(8) := 0;
w_attivo_ici_1     number(8) := 0;
w_attivo_iciap_1   number(8) := 0;
w_attivo_icp_1     number(8) := 0;
w_attivo_tarsu_1   number(8) := 0;
w_attivo_tosap_1   number(8) := 0;
w_attivo_1         number(8) := 0;
w_attivo_ici_2     number(8) := 0;
w_attivo_iciap_2   number(8) := 0;
w_attivo_icp_2     number(8) := 0;
w_attivo_tarsu_2   number(8) := 0;
w_attivo_tosap_2   number(8) := 0;
w_attivo_2         number(8) := 0;
w_cessato_ici_0    number(8) := 0;
w_cessato_iciap_0  number(8) := 0;
w_cessato_icp_0    number(8) := 0;
w_cessato_tarsu_0  number(8) := 0;
w_cessato_tosap_0  number(8) := 0;
w_cessato_0        number(8) := 0;
w_cessato_ici_1    number(8) := 0;
w_cessato_iciap_1  number(8) := 0;
w_cessato_icp_1    number(8) := 0;
w_cessato_tarsu_1  number(8) := 0;
w_cessato_tosap_1  number(8) := 0;
w_cessato_1        number(8) := 0;
w_cessato_ici_2    number(8) := 0;
w_cessato_iciap_2  number(8) := 0;
w_cessato_icp_2    number(8) := 0;
w_cessato_tarsu_2  number(8) := 0;
w_cessato_tosap_2  number(8) := 0;
w_cessato_2        number(8) := 0;
w_totale_ici_0     number(8) := 0;
w_totale_iciap_0   number(8) := 0;
w_totale_icp_0     number(8) := 0;
w_totale_tarsu_0   number(8) := 0;
w_totale_tosap_0   number(8) := 0;
w_totale_0         number(8) := 0;
w_totale_ici_1     number(8) := 0;
w_totale_iciap_1   number(8) := 0;
w_totale_icp_1     number(8) := 0;
w_totale_tarsu_1   number(8) := 0;
w_totale_tosap_1   number(8) := 0;
w_totale_1         number(8) := 0;
w_totale_ici_2     number(8) := 0;
w_totale_iciap_2   number(8) := 0;
w_totale_icp_2     number(8) := 0;
w_totale_tarsu_2   number(8) := 0;
w_totale_tosap_2   number(8) := 0;
w_totale_2         number(8) := 0;
w_stringa          varchar2(500);
w_flag             number(1);
cursor sel_attivi (p_flag number) is
select distinct
       ogco.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ',prtr.tipo_tributo) tipo_tributo
  from oggetti_contribuente ogco
      ,oggetti_pratica      ogpr
      ,pratiche_tributo     prtr
      ,rapporti_tributo     ratr
      ,contribuenti         cont
      ,soggetti             sogg
 where ogco.oggetto_pratica    = ogpr.oggetto_pratica
   and ogco.cod_fiscale        = ratr.cod_fiscale
   and prtr.pratica            = ratr.pratica
   and ogpr.pratica            = prtr.pratica
   and ratr.cod_fiscale     like '%'
   and prtr.tipo_tributo||''  in ('ICP','TOSAP','TARSU')
   and prtr.tipo_pratica||''   = 'D'
   and prtr.tipo_evento||''    = 'I'
   and prtr.anno              <= to_number(to_char(sysdate,'yyyy'))
   and cont.cod_fiscale        = ratr.cod_fiscale
   and sogg.ni                 = cont.ni
   and not exists
      (select 1
         from oggetti_pratica      a
             ,oggetti_contribuente b
             ,pratiche_tributo     c
        where a.oggetto_pratica    = b.oggetto_pratica
          and c.pratica            = a.pratica
          and b.cod_fiscale        = ogco.cod_fiscale
          and c.tipo_tributo||''   = prtr.tipo_tributo
          and c.tipo_evento||''    = 'C'
          and c.tipo_pratica||''   = 'D'
          and c.anno              >= prtr.anno
          and a.oggetto_pratica_rif
                                   = ogpr.oggetto_pratica
      )
 union
select distinct
       ogco.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ','ICI') tipo_tributo
  from oggetti_contribuente ogco
      ,oggetti_pratica      ogpr
      ,pratiche_tributo     prtr
      ,rapporti_tributo     ratr
      ,contribuenti         cont
      ,soggetti             sogg
 where ogco.anno||ogco.tipo_rapporto||'S' =
      (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
         from pratiche_tributo     c
             ,oggetti_contribuente b
             ,oggetti_pratica      a
        where c.data_notifica         is null
          and c.tipo_pratica||''       = 'D'
          and c.anno                  <= to_number(to_char(sysdate,'yyyy'))
          and c.tipo_tributo||''       = prtr.tipo_tributo
          and c.pratica                = a.pratica
          and a.oggetto_pratica        = b.oggetto_pratica
          and a.oggetto                = ogpr.oggetto
          and b.tipo_rapporto         in ('C','D','E')
          and b.cod_fiscale            = cont.cod_fiscale
          and c.cod_fiscale            = cont.cod_fiscale
          and c.tipo_tributo||''       = prtr.tipo_tributo
      )
   and ogco.oggetto_pratica            = ogpr.oggetto_pratica
   and ogpr.pratica                    = prtr.pratica
   and prtr.pratica                    = ratr.pratica
   and ogco.cod_fiscale                = ratr.cod_fiscale
   and prtr.anno                      <= to_number(to_char(sysdate,'yyyy'))
   and ogco.tipo_rapporto             in ('C','D','E')
   and prtr.tipo_pratica||''           = 'D'
   and ogco.flag_possesso              = 'S'
   and ogco.flag_esclusione           is null
   and ratr.cod_fiscale             like '%'
   and prtr.tipo_tributo||''           = 'ICI'
   and cont.cod_fiscale                = ratr.cod_fiscale
   and sogg.ni                         = cont.ni
 union
select distinct
       ogco.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ','ICI') tipo_tributo
  from oggetti_contribuente ogco
      ,oggetti_pratica      ogpr
      ,pratiche_tributo     prtr
      ,rapporti_tributo     ratr
      ,contribuenti         cont
      ,soggetti             sogg
 where ogco.anno||ogco.tipo_rapporto||'S' =
      (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
         from pratiche_tributo     c
             ,oggetti_contribuente b
             ,oggetti_pratica      a
        where c.data_notifica         is not null
          and c.tipo_pratica||''       = 'A'
          and nvl(c.stato_accertamento,'D')
                                       = 'D'
          and nvl(c.flag_denuncia,' ') = 'S'
          and c.anno                   < to_number(to_char(sysdate,'yyyy'))
          and c.tipo_tributo||''       = prtr.tipo_tributo
          and c.pratica                = a.pratica
          and a.oggetto_pratica        = b.oggetto_pratica
          and a.oggetto                = ogpr.oggetto
          and b.tipo_rapporto         in ('C','D','E')
          and b.cod_fiscale            = cont.cod_fiscale
          and c.cod_fiscale            = cont.cod_fiscale
          and c.tipo_tributo||''       = prtr.tipo_tributo
      )
   and ogco.oggetto_pratica            = ogpr.oggetto_pratica
   and ogpr.pratica                    = prtr.pratica
   and prtr.pratica                    = ratr.pratica
   and ogco.cod_fiscale                = ratr.cod_fiscale
   and ogco.flag_possesso              = 'S'
   and ogco.flag_esclusione           is null
   and prtr.anno                       < to_number(to_char(sysdate,'yyyy'))
   and ogco.tipo_rapporto             in ('C','D','E')
   and prtr.tipo_pratica||''           = 'A'
   and nvl(prtr.stato_accertamento,' ')
                                       = 'D'
   and ratr.cod_fiscale             like '%'
   and prtr.tipo_tributo||''           = 'ICI'
   and cont.cod_fiscale                = ratr.cod_fiscale
   and sogg.ni                         = cont.ni
 union
select distinct
       ogco.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ','ICI') tipo_tributo
  from pratiche_tributo     prtr
      ,contribuenti         cont
      ,soggetti             sogg
      ,rapporti_tributo     ratr
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
 where prtr.tipo_pratica||''       = 'D'
   and prtr.tipo_tributo||''       = 'ICI'
   and ogco.cod_fiscale            = ratr.cod_fiscale
   and prtr.pratica                = ratr.pratica
   and ogco.oggetto_pratica        = ogpr.oggetto_pratica
   and ogpr.pratica                = prtr.pratica
   and ogco.flag_possesso         is null
   and ogco.flag_esclusione       is null
   and ogco.anno                   = to_number(to_char(sysdate,'yyyy'))
   and ratr.cod_fiscale         like '%'
   and cont.cod_fiscale            = ratr.cod_fiscale
   and sogg.ni                     = cont.ni
 union
select distinct
       vers.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ','ICI') tipo_tributo
  from versamenti       vers
      ,contribuenti     cont
      ,soggetti         sogg
 where cont.cod_fiscale         like '%'
   and vers.tipo_tributo||''       = 'ICI'
   and cont.cod_fiscale            = vers.cod_fiscale
   and sogg.ni                     = cont.ni
   and vers.anno                   = to_number(to_char(sysdate,'yyyy'))
;
cursor sel_totali (p_flag number) is
select distinct
       cont.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ',prtr.tipo_tributo) tipo_tributo
  from contribuenti     cont
      ,soggetti         sogg
      ,rapporti_tributo ratr
      ,pratiche_tributo prtr
 where cont.cod_fiscale            = ratr.cod_fiscale
   and prtr.pratica                = ratr.pratica
   and sogg.ni                     = cont.ni
   and prtr.anno                  <= to_number(to_char(sysdate,'yyyy'))
   and prtr.tipo_pratica          in ('L','I','D','A')
   and ratr.cod_fiscale         like '%'
 union
select distinct
       cont.cod_fiscale
      ,nvl(sogg.tipo,0) tipo_soggetto
      ,decode(p_flag,0,' ','ICI') tipo_tributo
  from contribuenti     cont
      ,soggetti         sogg
      ,versamenti       vers
 where vers.cod_fiscale            = cont.cod_fiscale
   and sogg.ni                     = cont.ni
   and vers.anno                   = to_number(to_char(sysdate,'yyyy'))
   and vers.tipo_tributo           = 'ICI'
   and cont.cod_fiscale         like '%'
;
BEGIN
/*
   Contribuenti Totali.
*/
   w_flag := 0;
   FOR rec_attivi IN sel_attivi (w_flag)
   LOOP
      if rec_attivi.tipo_soggetto = 0 then
         w_attivo_0 := w_attivo_0 + 1;
      end if;
      if rec_attivi.tipo_soggetto = 1 then
         w_attivo_1 := w_attivo_1 + 1;
      end if;
      if rec_attivi.tipo_soggetto = 2 then
         w_attivo_2 := w_attivo_2 + 1;
      end if;
   END LOOP;
   FOR rec_totali IN sel_totali (w_flag)
   LOOP
      if rec_totali.tipo_soggetto = 0 then
         w_totale_0 := w_totale_0 + 1;
      end if;
      if rec_totali.tipo_soggetto = 1 then
         w_totale_1 := w_totale_1 + 1;
      end if;
      if rec_totali.tipo_soggetto = 2 then
         w_totale_2 := w_totale_2 + 1;
      end if;
   END LOOP;
   w_cessato_0 := w_totale_0 - w_attivo_0;
   w_cessato_1 := w_totale_1 - w_attivo_1;
   w_cessato_2 := w_totale_2 - w_attivo_2;
/*
   Contribuenti per Tipo Tributo.
*/
   w_flag := 1;
   FOR rec_attivi IN sel_attivi (w_flag)
   LOOP
      if rec_attivi.tipo_tributo = 'ICI'   then
         if rec_attivi.tipo_soggetto = 0   then
            w_attivo_ici_0   := w_attivo_ici_0   + 1;
         end if;
         if rec_attivi.tipo_soggetto = 1   then
            w_attivo_ici_1   := w_attivo_ici_1   + 1;
         end if;
         if rec_attivi.tipo_soggetto = 2   then
            w_attivo_ici_2   := w_attivo_ici_2   + 1;
         end if;
      end if;
      if rec_attivi.tipo_tributo = 'ICP'   then
         if rec_attivi.tipo_soggetto = 0   then
            w_attivo_icp_0   := w_attivo_icp_0   + 1;
         end if;
         if rec_attivi.tipo_soggetto = 1   then
            w_attivo_icp_1   := w_attivo_icp_1   + 1;
         end if;
         if rec_attivi.tipo_soggetto = 2   then
            w_attivo_icp_2   := w_attivo_icp_2   + 1;
         end if;
      end if;
      if rec_attivi.tipo_tributo = 'TARSU' then
         if rec_attivi.tipo_soggetto = 0   then
            w_attivo_tarsu_0 := w_attivo_tarsu_0 + 1;
         end if;
         if rec_attivi.tipo_soggetto = 1   then
            w_attivo_tarsu_1 := w_attivo_tarsu_1 + 1;
         end if;
         if rec_attivi.tipo_soggetto = 2   then
            w_attivo_tarsu_2 := w_attivo_tarsu_2 + 1;
         end if;
      end if;
      if rec_attivi.tipo_tributo = 'TOSAP' then
         if rec_attivi.tipo_soggetto = 0   then
            w_attivo_tosap_0 := w_attivo_tosap_0 + 1;
         end if;
         if rec_attivi.tipo_soggetto = 1   then
            w_attivo_tosap_1 := w_attivo_tosap_1 + 1;
         end if;
         if rec_attivi.tipo_soggetto = 2   then
            w_attivo_tosap_2 := w_attivo_tosap_2 + 1;
         end if;
      end if;
   END LOOP;
   FOR rec_totali IN sel_totali (w_flag)
   LOOP
      if rec_totali.tipo_tributo = 'ICI'   then
         if rec_totali.tipo_soggetto = 0   then
            w_totale_ici_0   := w_totale_ici_0   + 1;
         end if;
         if rec_totali.tipo_soggetto = 1   then
            w_totale_ici_1   := w_totale_ici_1   + 1;
         end if;
         if rec_totali.tipo_soggetto = 2   then
            w_totale_ici_2   := w_totale_ici_2   + 1;
         end if;
      end if;
      if rec_totali.tipo_tributo = 'ICP'   then
         if rec_totali.tipo_soggetto = 0   then
            w_totale_icp_0   := w_totale_icp_0   + 1;
         end if;
         if rec_totali.tipo_soggetto = 1   then
            w_totale_icp_1   := w_totale_icp_1   + 1;
         end if;
         if rec_totali.tipo_soggetto = 2   then
            w_totale_icp_2   := w_totale_icp_2   + 1;
         end if;
      end if;
      if rec_totali.tipo_tributo = 'ICIAP' then
         if rec_totali.tipo_soggetto = 0   then
            w_totale_iciap_0 := w_totale_iciap_0 + 1;
         end if;
         if rec_totali.tipo_soggetto = 1   then
            w_totale_iciap_1 := w_totale_iciap_1 + 1;
         end if;
         if rec_totali.tipo_soggetto = 2   then
            w_totale_iciap_2 := w_totale_iciap_2 + 1;
         end if;
      end if;
      if rec_totali.tipo_tributo = 'TARSU' then
         if rec_totali.tipo_soggetto = 0   then
            w_totale_tarsu_0 := w_totale_tarsu_0 + 1;
         end if;
         if rec_totali.tipo_soggetto = 1   then
            w_totale_tarsu_1 := w_totale_tarsu_1 + 1;
         end if;
         if rec_totali.tipo_soggetto = 2   then
            w_totale_tarsu_2 := w_totale_tarsu_2 + 1;
         end if;
      end if;
      if rec_totali.tipo_tributo = 'TOSAP' then
         if rec_totali.tipo_soggetto = 0   then
            w_totale_tosap_0 := w_totale_tosap_0 + 1;
         end if;
         if rec_totali.tipo_soggetto = 1   then
            w_totale_tosap_1 := w_totale_tosap_1 + 1;
         end if;
         if rec_totali.tipo_soggetto = 2   then
            w_totale_tosap_2 := w_totale_tosap_2 + 1;
         end if;
      end if;
   END LOOP;
   w_cessato_ici_0   := w_totale_ici_0   - w_attivo_ici_0  ;
   w_cessato_ici_1   := w_totale_ici_1   - w_attivo_ici_1  ;
   w_cessato_ici_2   := w_totale_ici_2   - w_attivo_ici_2  ;
   w_cessato_icp_0   := w_totale_icp_0   - w_attivo_icp_0  ;
   w_cessato_icp_1   := w_totale_icp_1   - w_attivo_icp_1  ;
   w_cessato_icp_2   := w_totale_icp_2   - w_attivo_icp_2  ;
   w_cessato_iciap_0 := w_totale_iciap_0 - w_attivo_iciap_0;
   w_cessato_iciap_1 := w_totale_iciap_1 - w_attivo_iciap_1;
   w_cessato_iciap_2 := w_totale_iciap_2 - w_attivo_iciap_2;
   w_cessato_tarsu_0 := w_totale_tarsu_0 - w_attivo_tarsu_0;
   w_cessato_tarsu_1 := w_totale_tarsu_1 - w_attivo_tarsu_1;
   w_cessato_tarsu_2 := w_totale_tarsu_2 - w_attivo_tarsu_2;
   w_cessato_tosap_0 := w_totale_tosap_0 - w_attivo_tosap_0;
   w_cessato_tosap_1 := w_totale_tosap_1 - w_attivo_tosap_1;
   w_cessato_tosap_2 := w_totale_tosap_2 - w_attivo_tosap_2;
   w_stringa := 'ICI  '||lpad(to_char(w_attivo_ici_0   ),8,'0')
                       ||lpad(to_char(w_cessato_ici_0  ),8,'0')
                       ||lpad(to_char(w_totale_ici_0   ),8,'0')
                       ||lpad(to_char(w_attivo_ici_1   ),8,'0')
                       ||lpad(to_char(w_cessato_ici_1  ),8,'0')
                       ||lpad(to_char(w_totale_ici_1   ),8,'0')
                       ||lpad(to_char(w_attivo_ici_2   ),8,'0')
                       ||lpad(to_char(w_cessato_ici_2  ),8,'0')
                       ||lpad(to_char(w_totale_ici_2   ),8,'0')
              ||'ICIAP'||lpad(to_char(w_attivo_iciap_0 ),8,'0')
                       ||lpad(to_char(w_cessato_iciap_0),8,'0')
                       ||lpad(to_char(w_totale_iciap_0 ),8,'0')
                       ||lpad(to_char(w_attivo_iciap_1 ),8,'0')
                       ||lpad(to_char(w_cessato_iciap_1),8,'0')
                       ||lpad(to_char(w_totale_iciap_1 ),8,'0')
                       ||lpad(to_char(w_attivo_iciap_2 ),8,'0')
                       ||lpad(to_char(w_cessato_iciap_2),8,'0')
                       ||lpad(to_char(w_totale_iciap_2 ),8,'0')
              ||'ICP  '||lpad(to_char(w_attivo_icp_0   ),8,'0')
                       ||lpad(to_char(w_cessato_icp_0  ),8,'0')
                       ||lpad(to_char(w_totale_icp_0   ),8,'0')
                       ||lpad(to_char(w_attivo_icp_1   ),8,'0')
                       ||lpad(to_char(w_cessato_icp_1  ),8,'0')
                       ||lpad(to_char(w_totale_icp_1   ),8,'0')
                       ||lpad(to_char(w_attivo_icp_2   ),8,'0')
                       ||lpad(to_char(w_cessato_icp_2  ),8,'0')
                       ||lpad(to_char(w_totale_icp_2   ),8,'0')
              ||'TARSU'||lpad(to_char(w_attivo_tarsu_0 ),8,'0')
                       ||lpad(to_char(w_cessato_tarsu_0),8,'0')
                       ||lpad(to_char(w_totale_tarsu_0 ),8,'0')
                       ||lpad(to_char(w_attivo_tarsu_1 ),8,'0')
                       ||lpad(to_char(w_cessato_tarsu_1),8,'0')
                       ||lpad(to_char(w_totale_tarsu_1 ),8,'0')
                       ||lpad(to_char(w_attivo_tarsu_2 ),8,'0')
                       ||lpad(to_char(w_cessato_tarsu_2),8,'0')
                       ||lpad(to_char(w_totale_tarsu_2 ),8,'0')
              ||'TOSAP'||lpad(to_char(w_attivo_tosap_0 ),8,'0')
                       ||lpad(to_char(w_cessato_tosap_0),8,'0')
                       ||lpad(to_char(w_totale_tosap_0 ),8,'0')
                       ||lpad(to_char(w_attivo_tosap_1 ),8,'0')
                       ||lpad(to_char(w_cessato_tosap_1),8,'0')
                       ||lpad(to_char(w_totale_tosap_1 ),8,'0')
                       ||lpad(to_char(w_attivo_tosap_2 ),8,'0')
                       ||lpad(to_char(w_cessato_tosap_2),8,'0')
                       ||lpad(to_char(w_totale_tosap_2 ),8,'0')
              ||'     '||lpad(to_char(w_attivo_0       ),8,'0')
                       ||lpad(to_char(w_cessato_0      ),8,'0')
                       ||lpad(to_char(w_totale_0       ),8,'0')
                       ||lpad(to_char(w_attivo_1       ),8,'0')
                       ||lpad(to_char(w_cessato_1      ),8,'0')
                       ||lpad(to_char(w_totale_1       ),8,'0')
                       ||lpad(to_char(w_attivo_2       ),8,'0')
                       ||lpad(to_char(w_cessato_2      ),8,'0')
                       ||lpad(to_char(w_totale_2       ),8,'0');
   Return w_stringa;
END;
/* End Function: F_TOTALI_CONT_ATTIVO */
/

