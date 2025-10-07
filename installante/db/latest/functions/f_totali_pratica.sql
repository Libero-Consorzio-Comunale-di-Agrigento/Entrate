--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_totali_pratica stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_TOTALI_PRATICA
(a_pratica    IN    number
, a_tipo      IN    varchar2
) RETURN number
IS
totale number;
BEGIN
if upper(a_tipo) = 'I' then
   select nvl(sum(decode(SANZ.FLAG_IMPOSTA
                        ,'S',f_round(SAPR.IMPORTO *
                                     (100 - nvl(SAPR.RIDUZIONE,0)) / 100,0
                                    ) +
                             decode(rpad(PRTR.TIPO_TRIBUTO,5,' ')||decode(RUOL.RUOLO
                                                                         ,null,nvl(CATA.FLAG_LORDO,'N')
                                                                              ,nvl(RUOL.IMPORTO_LORDO,'N')
                                                                         )
                                   ,'TARSUS',f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100
                                                                  * nvl(CATA.ADDIZIONALE_ECA,0) / 100,0) +
                                             f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100
                                                                  * nvl(CATA.MAGGIORAZIONE_ECA,0) / 100,0) +
                                             f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100
                                                                  * nvl(CATA.ADDIZIONALE_PRO,0) / 100,0) +
                                             f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100
                                                                  * nvl(CATA.ALIQUOTA,0) / 100,0)
                                            ,0
                                   )
                            ,0
                        )
                 ),0
             )
     into totale
     from SANZIONI         SANZ
         ,SANZIONI_PRATICA SAPR
         ,PRATICHE_TRIBUTO PRTR
         ,CARICHI_TARSU    CATA
         ,RUOLI            RUOL
    where SANZ.TIPO_TRIBUTO       = SAPR.TIPO_TRIBUTO
      and SANZ.COD_SANZIONE       = SAPR.COD_SANZIONE
      and SANZ.SEQUENZA           = SAPR.SEQUENZA_SANZ
      and SAPR.PRATICA            = a_pratica
      and PRTR.PRATICA            = a_pratica
      and RUOL.RUOLO         (+)  = SAPR.RUOLO
      and CATA.ANNO          (+)  = decode(PRTR.TIPO_TRIBUTO,'TARSU',PRTR.ANNO,0)
      and SANZ.COD_SANZIONE NOT IN (888,889)
   ;
elsif upper(a_tipo) = 'S' then
   select nvl(sum(decode(SANZ.FLAG_IMPOSTA
                        ,'',decode(SANZ.FLAG_PENA_PECUNIARIA
                                  ,'',decode(SANZ.FLAG_INTERESSI
                                            ,'',decode(SAPR.COD_SANZIONE
                                                      ,24,0
                                                         ,f_round(SAPR.IMPORTO * (100 -
                                                                  nvl(SAPR.RIDUZIONE,0))
                                                                  / 100,0
                                                                 )
                                                      )
                                               ,0
                                            )
                                     ,0
                                  )
                           ,0
                        )
                 ),0
             )
     into totale
     from SANZIONI         SANZ
         ,SANZIONI_PRATICA SAPR
    where SANZ.TIPO_TRIBUTO       = SAPR.TIPO_TRIBUTO
      and SANZ.COD_SANZIONE       = SAPR.COD_SANZIONE
      and SANZ.SEQUENZA           = SAPR.SEQUENZA_SANZ
      and SAPR.PRATICA            = a_pratica
      and SANZ.COD_SANZIONE NOT IN (888,889)
   ;
elsif upper(a_tipo) = 'P' then
   select nvl(sum(decode(SANZ.FLAG_PENA_PECUNIARIA
                        ,'S',f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100,0)
                            ,0
                        )
                 ),0
             )
     into totale
     from SANZIONi         SANZ
         ,SANZIONI_PRATICA SAPR
    where SANZ.TIPO_TRIBUTO       = SAPR.TIPO_TRIBUTO
      and SANZ.COD_SANZIONE       = SAPR.COD_SANZIONE
      and SANZ.SEQUENZA           = SAPR.SEQUENZA_SANZ
      and SAPR.PRATICA            = a_pratica
      and SANZ.COD_SANZIONE NOT IN (888,889)
   ;
elsif upper(a_tipo) = 'T' then
   select nvl(sum(decode(SANZ.FLAG_INTERESSI
                        ,'S',f_round(SAPR.IMPORTO * (100 - nvl(SAPR.RIDUZIONE,0)) / 100,0)
                            ,0
                        )
                 ),0
             )
     into totale
     from SANZIONI         SANZ
         ,SANZIONI_PRATICA SAPR
    where SANZ.TIPO_TRIBUTO       = SAPR.TIPO_TRIBUTO
      and SANZ.COD_SANZIONE       = SAPR.COD_SANZIONE
      and SANZ.SEQUENZA           = SAPR.SEQUENZA_SANZ
      and SAPR.PRATICA            = a_pratica
      and SANZ.COD_SANZIONE NOT IN (888,889)
   ;
elsif upper(a_tipo) = 'V' then
   select nvl(sum(VERS.IMPORTO_VERSATO),0)
     into totale
     from VERSAMENTI VERS
    where VERS.PRATICA = a_pratica
   ;
end if;
RETURN totale;
EXCEPTION
   WHEN OTHERS THEN
      RETURN -1;
END;
/* End Function: F_TOTALI_PRATICA */
/
