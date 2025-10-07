--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_tot_vers_cont stripComments:false runOnChange:true 
 
create or replace function F_TOT_VERS_CONT
(p_anno     number
,p_cf       varchar2
,p_titr     varchar2
,p_calcolo  varchar2
)
return number
IS
w_tot_cont        number;
/* Questa funzione calcola il versato totale a livello  */
/* di Contribuente, Tipo Tributo (ICP - TARSU - TOSAP)  */
/* e Anno. Inoltre calcola il tardivo versamento sulla  */
/* base delle scadenze delle rate, se indicate, oppure  */
/* della scadenza con rata minore, se non indicata.     */
/* Inoltre calcola anche gli sgravi per quei ruoli che  */
/* non sono inviati a consorzio.                        */
/* Il parametro di ingresso indica che dato deve essere */
/* trattato.                                            */
BEGIN
   if p_calcolo = 'V' then
/* Versato Totale                                       */
      BEGIN
         select nvl(sum(vers.importo_versato),0)
           into w_tot_cont
           from versamenti       vers
              , pratiche_tributo prtr
          where vers.tipo_tributo||''          = p_titr
            and vers.cod_fiscale               = p_cf
            and vers.anno                      = p_anno
            and vers.pratica                   = prtr.pratica  (+)
            and (vers.pratica                   is null
                or prtr.tipo_pratica   =  'V')
          group by
                vers.cod_fiscale
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   elsif p_calcolo = 'T' then
/* Versato Tardivo    */
      if p_titr = 'TARSU' then
         BEGIN
            select nvl(sum(decode(sign(vers.data_pagamento
                                       - nvl(decode(vers.rata
                                                   ,0,ruol.scadenza_prima_rata
                                                   ,1,ruol.scadenza_prima_rata
                                                   ,2,ruol.scadenza_rata_2
                                                   ,3,ruol.scadenza_rata_3
                                                   ,4,ruol.scadenza_rata_4
                                                   )
                                            ,sysdate
                                            )
                                      )
                                 ,1,vers.importo_versato
                                 ,0
                                 )
                          ),0
                      )
              into w_tot_cont
              from versamenti       vers
                 , pratiche_tributo prtr
                 , ruoli            ruol
             where vers.tipo_tributo||''           = p_titr
               and vers.cod_fiscale                = p_cf
               and vers.anno                       = p_anno
               and (vers.pratica                   is null
                   or prtr.tipo_pratica   =  'V')
               and vers.pratica                    = prtr.pratica  (+)
               and ruol.ruolo                      = vers.ruolo
             group by
                   vers.cod_fiscale
            ;
         EXCEPTION
            WHEN no_data_found THEN
               w_tot_cont := 0;
         END;
      else
         BEGIN
            select nvl(sum(decode(sign(vers.data_pagamento - scad.data_scadenza)
                                 ,1,vers.importo_versato
                                   ,0
                                 )
                          ),0
                      )
              into w_tot_cont
              from scadenze   scad
                 , versamenti vers
                 , pratiche_tributo prtr
             where vers.tipo_tributo||''           = p_titr
               and vers.cod_fiscale                = p_cf
               and vers.anno                       = p_anno
               and (vers.pratica                   is null
                   or prtr.tipo_pratica   =  'V')
               and vers.pratica                    = prtr.pratica  (+)
               and scad.tipo_tributo               = p_titr
               and scad.anno                       = p_anno
               and scad.tipo_scadenza              = 'V'
               and (    nvl(vers.rata,0)           > 0
                    and vers.rata                  = scad.rata
                    or  nvl(vers.rata,0)           = 0
                    and scad.rata                  =
                       (select to_number(substr(min(to_char(sca2.data_scadenza,'yyyymmdd')||
                                                    lpad(to_char(sca2.rata),2,'0')
                                                   ),9,2
                                               )
                                        )
                          from scadenze sca2
                         where sca2.tipo_tributo    = p_titr
                           and sca2.anno            = p_anno
                           and sca2.tipo_scadenza   = 'V'
                       )
                   )
             group by
                   vers.cod_fiscale
            ;
         EXCEPTION
            WHEN no_data_found THEN
               w_tot_cont := 0;
         END;
      end if;
   elsif p_calcolo = 'S' then
/* Sgravi */
      BEGIN
         select nvl(sum(nvl(sgra.importo,0)),0)
           into w_tot_cont
           from sgravi sgra
               ,ruoli  ruol
          where ruol.ruolo                       = sgra.ruolo
            and ruol.invio_consorzio            is not null
            and ruol.anno_ruolo                  = p_anno
            and ruol.tipo_tributo                = p_titr
            and sgra.cod_fiscale                 = p_cf
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_tot_cont := 0;
      END;
   else
      w_tot_cont := 0;
   end if;
   RETURN w_tot_cont;
EXCEPTION
   WHEN others THEN
      RETURN NULL;
END;
/* End Function: F_TOT_VERS_CONT */
/

