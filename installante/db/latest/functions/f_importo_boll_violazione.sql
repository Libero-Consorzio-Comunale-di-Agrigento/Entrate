--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_boll_violazione stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPORTO_BOLL_VIOLAZIONE
/*************************************************************************
 2       10/12/2024   AB       #76942
                               Sistemato controllo su sanz con data_inizio
 1       29/01/2015   VD       Aggiunto il valore 197 nel test sui codici sanzione
*************************************************************************/
(a_pratica           in number
,a_ridotto           in varchar2
) Return number
is
--
-- Se il parametro a_ridotto è nullo viene considerato come ridotto 'S' per mantenere la
-- compatibilita' con l'uso in maschere che chiamano la funzione con il campo nullo e l'importo
-- in uscita deve essere ridotto
--
nImporto                 number;
nRiduzione               number;
sTipo_Tributo            varchar2(5);
iAnno                    number;
nAddizionale_Pro         number;
nMaggiorazione_Eca       number;
nAddizionale_Eca         number;
nAliquota                number;
sFlag_Adesione           varchar2(1);
w_round                  varchar(1);
w_cod_istat              varchar2(6);
w_spese_notifica         number;
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
      ,nvl(sapr.importo, 0) importo
      ,nvl(sapr.riduzione,0) riduzione
	  ,nvl(sapr.riduzione,0) riduz_non_tarsu
      ,decode(sapr.tipo_tributo
             ,'TARSU',decode(nvl(ruol.importo_lordo,'N')
                            ,'N',decode(sapr.cod_sanzione
                                       ,1  ,'S'
                                       ,100,'S'
                                       ,101,'S'
                                       ,decode(nvl(sanz.tipo_causale,'*')||nvl(sanz.flag_magg_tares,'N')
                                              ,'EN','S'
                                              ,'N'
                                              )
                                       )
                                ,'N'
                            )
                     ,'N'
             ) flag_carichi
  from sanzioni_pratica sapr
      ,ruoli            ruol
      ,sanzioni         sanz
 where sapr.pratica       = p_pratica
   and ruol.ruolo     (+) = sapr.ruolo
   and sanz.tipo_tributo  = sapr.tipo_tributo
   and sanz.cod_sanzione  = sapr.cod_sanzione
   and sanz.sequenza      = sapr.sequenza_sanz
;

BEGIN

  BEGIN
    select lpad(to_char(pro_cliente), 3, '0')
        || lpad(to_char(com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali
         ;
  EXCEPTION
    WHEN others THEN
     RAISE_APPLICATION_ERROR('-20666', 'Errore in ricerca Codice Istat del Comune (' || SQLERRM || ')');
  END;

   BEGIN
      select prtr.anno
           , prtr.tipo_tributo
           , nvl(cata.addizionale_eca,0)
           , nvl(cata.maggiorazione_eca,0)
           , nvl(cata.addizionale_pro,0)
           , nvl(cata.aliquota,0)
			     , prtr.flag_adesione
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
   -- Verifica del dizionario Tipi Tributo
    begin
        select decode(prtr.tipo_tributo
                      ,'TARSU',flag_tariffa
                      ,'ICP',flag_canone
                      ,'TOSAP',flag_canone
                      ,null)
          into w_round
          from tipi_tributo      titr
             , pratiche_tributo  prtr
         where titr.tipo_tributo = prtr.tipo_tributo
           and prtr.pratica      = a_pratica
            ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_round := null;
      WHEN OTHERS THEN
         w_round := null;
    end;

   nImporto := 0;
   w_spese_notifica := 0;

   FOR rec_sapr in sel_sapr (a_pratica,sFlag_Adesione) LOOP

     if sTipo_Tributo = 'TARSU' then
       nRiduzione := rec_sapr.riduzione;
     else
       nRiduzione := rec_sapr.riduz_non_tarsu;
     end if;

     if nvl(a_ridotto,'S') <> 'S' then
       nRiduzione := 0;
     end if;

     if (w_cod_istat = '001219' and sTipo_Tributo = 'TARSU' and rec_sapr.cod_sanzione in (15,115,197,198)) then
       --Rivoli sostiene che le Spese di Notifica nn debbano essere arrotondate
       --Quindi adesso vengono memorizzate ed aggiunte all'importo dopo che è stato arrotondato
       w_spese_notifica := w_spese_notifica + rec_sapr.importo;
     else
       if rec_sapr.flag_carichi = 'S' then
         nImporto := nImporto + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAddizionale_Eca   / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nMaggiorazione_Eca / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAddizionale_Pro   / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100 * nAliquota          / 100,2)
                              + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100,2);
       else
         nImporto := nImporto + round(nvl(rec_sapr.importo,0) * (100 - nRiduzione) / 100,2) ;
       end if;
     end if;

   END LOOP;

   if w_round is null then
      nImporto := round(nImporto);
   end if;

   if (w_cod_istat = '001219' and sTipo_Tributo = 'TARSU') then
     nImporto := nImporto + w_spese_notifica;
   end if;

   Return nImporto;

END;
/* End Function: F_IMPORTO_BOLL_VIOLAZIONE */
/
