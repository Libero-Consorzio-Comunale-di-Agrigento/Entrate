--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_violazione stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_VIOLAZIONE
(a_pratica           in number
,a_ridotto           in varchar2
) Return number
is
--
-- Se il parametro a_ridotto è nullo viene considerato come ridotto 'S' per mantenere la
-- compatibilita' con l'uso in maschere che chiamano la funzione con il campo nullo e l'importo
-- in uscita deve essere ridotto
--
nImporto                number;
nRiduzione              number;
sTipo_Tributo           varchar2(5);
iAnno                   number;
nAddizionale_Pro        number;
nMaggiorazione_Eca      number;
nAddizionale_Eca        number;
nAliquota               number;
sFlag_Adesione      varchar2(1);
/*
    Il flag_carichi viene posto = S quando bisogna trattare i carichi tarsu
    e = N nel caso contrario. Il flag carichi va settatoa S se si tratta il
    tipo tributo TARSU limitatamente alle sanzioni pratica a ruolo non lordo
    (per ora si fa fare il ruolo anche in riscossione diretta e se il ruolo
    deve essere trattato come lordo le addizionali sono comprese nel valore
    calcolato) e aventi i codici che interessano il recupero imposta.
*/
cursor sel_sapr (p_pratica number, p_Flag_Adesione varchar2) is
select sapr.cod_sanzione
      ,sapr.importo
      ,decode(sFlag_Adesione,'S',nvl(sapr.riduzione,0),0) riduzione
     ,nvl(sapr.riduzione,0) riduz_non_tarsu
      ,decode(sapr.tipo_tributo
             ,'TARSU',decode(nvl(ruol.importo_lordo,'N')
                            ,'N',decode(sapr.cod_sanzione
                                       ,1  ,'S'
                                       ,100,'S'
                                       ,101,'S'
                                       ,111,'S'
                                       ,121,'S'
                                       ,131,'S'
                                       ,141,'S'
                                           ,'N'
                                       )
                                ,'N'
                            )
                     ,'N'
             ) flag_carichi
  from sanzioni_pratica sapr
      ,ruoli            ruol
 where sapr.pratica       = p_pratica
   and ruol.ruolo     (+) = sapr.ruolo
;
BEGIN
   BEGIN
      select prtr.anno
            ,prtr.tipo_tributo
            ,nvl(cata.addizionale_eca,0)
            ,nvl(cata.maggiorazione_eca,0)
            ,nvl(cata.addizionale_pro,0)
            ,nvl(cata.aliquota,0)
         ,prtr.flag_adesione
        into iAnno
            ,sTipo_Tributo
            ,nAddizionale_eca
            ,nMaggiorazione_eca
            ,nAddizionale_pro
            ,nAliquota
         ,sFlag_Adesione
        from carichi_tarsu     cata
            ,pratiche_tributo  prtr
       where cata.anno (+)     = prtr.anno
         and prtr.pratica      = a_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         Return 0;
   END;
   nImporto := 0;
   FOR rec_sapr in sel_sapr (a_pratica,sFlag_Adesione)
   LOOP
     if sTipo_Tributo = 'TARSU' then
         nRiduzione := rec_sapr.riduzione;
    else
        nRiduzione := rec_sapr.riduz_non_tarsu;
    end if;
      if nvl(a_ridotto,'S') <> 'S' then
         nRiduzione := 0;
     end if;
      if rec_sapr.flag_carichi = 'S' then
         nImporto := nImporto + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAddizionale_Eca   / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nMaggiorazione_Eca / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAddizionale_Pro   / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAliquota          / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100,2);
      else
         nImporto := nImporto + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100,2) ;
      end if;
   END LOOP;
   Return nImporto;
END;
/* End Function: F_IMPORTO_VIOLAZIONE */
/

