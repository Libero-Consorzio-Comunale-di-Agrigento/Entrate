--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_oggetto_cessato stripComments:false runOnChange:true 
 
create or replace function F_OGGETTO_CESSATO
(a_oggetto                 in number
,a_tipo_tributo            in varchar2
,a_data                    in date
,a_cessato                 in varchar2
) Return string
is
--
-- Questa funzione fornisce come risposta S che ha il significato di condizione
-- verificata o N che ha il significato opposto.
-- il dato di ingresso a_cessato se = N significa posseduto, in questo caso viene
-- dato come valore di risposta sempre S perche` questa funzione deve controllare
-- se un oggetto ad una certa data non e` posseduto da alcun contribuente.
--
nConta                         number;
cursor sel_1 is
select 1
  from pratiche_tributo         prtr
      ,oggetti_contribuente     ogco
      ,oggetti_pratica          ogpr
 where prtr.anno                  <= to_number(to_char(a_data,'yyyy'))
   and prtr.pratica                = ogpr.pratica
   and ogco.oggetto_pratica        = ogpr.oggetto_pratica
   and ogpr.oggetto                = a_oggetto
   and prtr.tipo_tributo||''       = a_tipo_Tributo
   and prtr.tipo_pratica          in ('D','A')
   and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                   = 'S'
   and nvl(prtr.stato_accertamento,'D')
                                   = 'D'
 group by
       ogco.cod_fiscale
having to_number(substr(max(lpad(to_char(ogco.anno),4,'0')||
                            nvl(ogco.tipo_rapporto,'D')   ||
                            nvl(ogco.flag_possesso,'N')
                           ),1,4
                       )
                )                  = to_number(to_char(a_data,'yyyy'))
    or substr(max(lpad(to_char(ogco.anno),4,'0')||
                  nvl(ogco.tipo_rapporto,'D')   ||
                  nvl(ogco.flag_possesso,'N')
                 ),6,1
             )                     = 'S'
;
BEGIN
   if a_cessato = 'N' then
      Return 'S';
   end if;
   if a_tipo_tributo in ('ICI','ICIAP') then
      open sel_1;
      fetch sel_1 into nConta;
      if sel_1%NOTFOUND then
         nConta := 0;
      else
         nConta := 1;
      end if;
   else
      BEGIN
         select count(*)
           into nConta
           from oggetti_validita ogva
          where ogva.oggetto          = a_oggetto
            and ogva.tipo_tributo     = a_tipo_Tributo
            and a_data           between nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                     and nvl(ogva.al ,to_date('31129999','ddmmyyyy'))
         ;
      END;
   end if;
   if nConta > 0 then
      Return 'N';
   else
      Return 'S';
   end if;
END;
/* End Function: F_OGGETTO_CESSATO */
/

