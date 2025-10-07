--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_possesso stripComments:false runOnChange:true 
 
create or replace function F_POSSESSO
(a_oggetto_pratica         in number
,a_cod_fiscale             in varchar2
,a_data                    in date
,a_cessato                 in varchar2
) Return string
is
--
-- Questa funzione fornisce come risposta S che ha il significato di condizione
-- verificata o N che ha il significato opposto.
-- il dato di ingresso a_cessato se = N significa posseduto, veceversa se = S ha
-- il significato di cessato.
-- Il tutto alla data fornita nel parametro a_data e relativamente all` oggetto
-- dell` oggetto pratica a_oggetto_pratica e al contribuente a_cod_fiscale.
--
nAnno                          number;
sTipo_Tributo                  varchar2(5);
nOggetto                       number;
nOggetto_Pratica               number;
nAnno_Ogco                     number;
sFlag_Possesso                 varchar2(1);
dMax_Data                      date;
BEGIN
   BEGIN
      select prtr.anno
            ,prtr.tipo_tributo
            ,ogpr.oggetto
        into nAnno
            ,sTipo_Tributo
            ,nOggetto
        from oggetti_pratica      ogpr
            ,pratiche_tributo     prtr
       where ogpr.oggetto_pratica    = a_oggetto_pratica
         and prtr.pratica            = ogpr.pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         Return 'N';
   END;
   if stipo_tributo in ('ICI','ICIAP') then
      BEGIN
         select to_number(substr(max(lpad(to_char(ogco.anno),4,'0')||
                                     nvl(ogco.tipo_rapporto,'D')   ||
                                     nvl(ogco.flag_possesso,'N')   ||
                                     lpad(to_char(ogpr.oggetto_pratica),10,'0')
                                    ),7,10
                                )
                         )
               ,to_number(substr(max(lpad(to_char(ogco.anno),4,'0')||
                                     nvl(ogco.tipo_rapporto,'D')   ||
                                     nvl(ogco.flag_possesso,'N')
                                    ),1,4
                                )
                         )
               ,substr(max(lpad(to_char(ogco.anno),4,'0')||
                           nvl(ogco.tipo_rapporto,'D')   ||
                           nvl(ogco.flag_possesso,'N')
                          ),6,1
                      )
           into nOggetto_Pratica
               ,nAnno_Ogco
               ,sFlag_Possesso
           from pratiche_tributo         prtr
               ,oggetti_contribuente     ogco
               ,oggetti_pratica          ogpr
          where prtr.anno                  <= to_number(to_char(a_data,'yyyy'))
            and prtr.pratica                = ogpr.pratica
            and ogco.oggetto_pratica        = ogpr.oggetto_pratica
            and ogpr.oggetto                = nOggetto
            and ogco.cod_fiscale            = a_cod_fiscale
            and prtr.tipo_tributo||''       = sTipo_Tributo
            and prtr.tipo_pratica          in ('D','A')
            and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                            = 'S'
            and nvl(prtr.stato_accertamento,'D')
                                            = 'D'
         ;
         if a_cessato = 'N' then
            if (nAnno_Ogco = to_number(to_char(a_data,'yyyy')) or sFlag_Possesso = 'S') and
               nOggetto_Pratica = a_oggetto_pratica then
               Return 'S';
            else
               Return 'N';
            end if;
         else
            if sFlag_Possesso = 'N' and nAnno_Ogco < to_number(to_char(a_data,'yyyy')) and
               nOggetto_Pratica = a_oggetto_pratica then
               Return 'S';
            else
               Return 'N';
            end if;
         end if;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Return 'N';
      END;
   else
      BEGIN
         select max(nvl(ogva.al,to_date('31129999','ddmmyyyy')))
               ,to_number(substr(max(to_char(nvl(ogva.al
                                                ,to_date('31129999','ddmmyyyy')
                                                ),'yyyymmdd'
                                            )||
                                     lpad(to_char(ogva.oggetto_pratica),10,'0')
                                    ),9,10
                                )
                         )
           into dMax_Data
               ,nOggetto_Pratica
           from oggetti_validita ogva
          where ogva.cod_fiscale      = a_cod_fiscale
            and ogva.oggetto          = nOggetto
            and ogva.tipo_tributo     = sTipo_Tributo
            and nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                     <= a_data
          group by
                nOggetto
         ;
         if nOggetto_Pratica <> a_oggetto_pratica then
            Return 'N';
         end if;
         if dMax_Data < a_data then
            if a_cessato = 'S' then
               Return 'S';
            else
               Return 'N';
            end if;
         else
            if a_cessato = 'N' then
               Return 'S';
            else
               Return 'N';
            end if;
         end if;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            Return 'N';
      END;
   end if;
END;
/* End Function: F_POSSESSO */
/

