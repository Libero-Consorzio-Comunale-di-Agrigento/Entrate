--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_vers_ravv_dett stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPORTO_VERS_RAVV_DETT
/*************************************************************************
 NOME:        F_IMPORTO_VERS_RAVV_DETT

 DESCRIZIONE: Restituisce l'importo versato a secondo del tipo dettaglio
              indicato

 NOTE:        Il tipo dettaglio puo' assumere i seguenti valori:
              TOT - Importo totale
              ABP - Abitazione Principale
              RUR - Rurali
              TEC - Terreni comune
              ARC - Aree comune
              ALC - Altri comune
              FDC - Fabbricati D comune
              TEE - Terreni erariale
              ARE - Aree erariale
              ALE - Altri erariale
              FDE - Fabbricati D erariale
              FAM - Fabbricati merce

 RITORNA:     number              Importo versato

 Rev.    Date         Author      Note
 005     10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con sequenza
 004     21/09/2020   VD          Aggiunta selezione per fabbricati merce
 003     07/05/2020   VD          Revisionato test su codici sanzione:
                                  per evitare di doverlo modificare ogni
                                  volta che si inserisce un nuovo codice,
                                  ora il test viene eseguito utilizzando
                                  altri attributi della tabella, come il
                                  tipo_causale e i vari flag.
 002     18/08/2016   VD          Aggiunta gestione liquidazione
                                  mini IMU: per il 2013: nella
                                  determinazione degli importi di
                                  imposta e sanzioni dalla pratica
                                  si trattano i nuovi codici sanzione
                                  relativi alla mini IMU
                                  Gli importi vengono calcolati solo
                                  per abitazione e terreni agricoli
                                  NOTA: Allo stato attuale, la mini
                                       IMU viene trattata correttamente
                                       SOLO SE IL VERSAMENTO VIENE FATTO
                                       CON TIPO = 'U'
 001     24/03/2015   VD          Modificato per TASI: in caso di TASI
                                  si tratta sempre l'importo totale per
                                  codice tributo (es. aree_fabbricabili
                                  al posto di aree_comune), in quanto
                                  sui versamenti vengono registrati solo
                                  gli importi totali senza suddivisione
                                  tra comune ed erario.

*************************************************************************/
(a_cod_fiscale          in varchar2
,a_tipo_tributo         in varchar2
,a_anno                 in number
,a_tipo_versamento      in varchar2
,a_tipo_dettaglio       in varchar2
,a_data_a               in date
) Return number is

nImporto_versato                   number;
nAb_principale_versato             number;
nRurali_versato                    number;
nTerreni_comune_versato            number;
nAree_comune_versato               number;
nAltri_comune_versato              number;
nFabbricati_d_comune_versato       number;
nTerreni_erariale_versato          number;
nAree_erariale_versato             number;
nAltri_erariale_versato            number;
nFabbricati_d_erariale_versato     number;
nImporto_sapr                      number;
nAb_principale_sapr                number;
nRurali_sapr                       number;
nTerreni_comune_sapr               number;
nAree_comune_sapr                  number;
nAltri_comune_sapr                 number;
nFabbricati_d_comune_sapr          number;
nTerreni_erariale_sapr             number;
nAree_erariale_sapr                number;
nAltri_erariale_sapr               number;
nFabbricati_d_erariale_sapr        number;
nImporto_reale                     number;
nAb_principale_reale               number;
nRurali_reale                      number;
nTerreni_comune_reale              number;
nAree_comune_reale                 number;
nAltri_comune_reale                number;
nFabbricati_d_comune_reale         number;
nTerreni_erariale_reale            number;
nAree_erariale_reale               number;
nAltri_erariale_reale              number;
nFabbricati_d_erariale_reale       number;
nImporto                           number := 0;
nAb_principale                     number := 0;
nRurali                            number := 0;
nTerreni_comune                    number := 0;
nAree_comune                       number := 0;
nAltri_comune                      number := 0;
nFabbricati_d_comune               number := 0;
nTerreni_erariale                  number := 0;
nAree_erariale                     number := 0;
nAltri_erariale                    number := 0;
nFabbricati_d_erariale             number := 0;

-- (VD - 21/09/2020): Variabili per fabbricati merce
nFabbricati_merce_versato          number;
nFabbricati_merce_sapr             number;
nFabbricati_merce_reale            number;
nFabbricati_merce                  number := 0;

CURSOR sel_prtr(p_cf varchar2, p_anno number, p_titr varchar2) IS
select pratica
  from pratiche_tributo prtr
 where prtr.tipo_tributo||''  = p_titr
   and prtr.anno              = p_anno
   and prtr.tipo_pratica      = 'V'
   and prtr.cod_fiscale       = p_cf
   and prtr.numero            is not null
   and nvl(prtr.stato_accertamento,'D') = 'D'
-- selezioniamo solo le pratiche che erano già presenti alla data assegnata
   and prtr.data <= nvl(a_data_a,to_date('31/12/'||a_anno,'dd/mm/yyyy'))
 order by 1
     ;
BEGIN

   FOR rec_prtr IN sel_prtr( a_cod_fiscale, a_anno, a_tipo_tributo) LOOP

      BEGIN
         select sum(importo_versato) importo_versato
               ,sum(ab_principale)
               ,sum(decode(a_tipo_tributo,'TASI',rurali,rurali_comune))
               ,sum(decode(a_tipo_tributo,'TASI',terreni_agricoli,terreni_comune))
               ,sum(decode(a_tipo_tributo,'TASI',aree_fabbricabili,aree_comune))
               ,sum(decode(a_tipo_tributo,'TASI',altri_fabbricati,altri_comune))
               ,sum(decode(a_tipo_tributo,'TASI',fabbricati_d,fabbricati_d_comune))
               ,sum(decode(a_tipo_tributo,'TASI',null,terreni_erariale))
               ,sum(decode(a_tipo_tributo,'TASI',null,aree_erariale))
               ,sum(decode(a_tipo_tributo,'TASI',null,altri_erariale))
               ,sum(decode(a_tipo_tributo,'TASI',null,fabbricati_d_erariale))
               ,sum(decode(a_tipo_tributo,'TASI',null,fabbricati_merce))
           into nImporto_versato
               ,nAb_principale_versato
               ,nRurali_versato
               ,nTerreni_comune_versato
               ,nAree_comune_versato
               ,nAltri_comune_versato
               ,nFabbricati_d_comune_versato
               ,nTerreni_erariale_versato
               ,nAree_erariale_versato
               ,nAltri_erariale_versato
               ,nFabbricati_d_erariale_versato
               ,nFabbricati_merce_versato
           from versamenti vers
          where vers.pratica = rec_prtr.pratica
            and (a_tipo_versamento = 'U'
                or (    a_tipo_versamento = 'A'
                    and nvl(vers.tipo_versamento,'U') in ('A','U')
                   )
                or (    a_tipo_versamento = 'S'
                    and nvl(vers.tipo_versamento,'U') = 'S'
                   )
                )
-- selezioniamo solo i versamenti effettuati prima della data assegnata
            and vers.data_pagamento <= nvl(a_data_a,to_date('31/12/'||a_anno,'dd/mm/yyyy'))
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nImporto_versato  := 0;
         WHEN others THEN
            nImporto_versato := 0;
      END;

      nImporto_versato := nvl(nImporto_versato,0);
      nAb_principale_versato := nvl(nAb_principale_versato,0);
      nRurali_versato := nvl(nRurali_versato,0);
      nTerreni_comune_versato := nvl(nTerreni_comune_versato,0);
      nAree_comune_versato := nvl(nAree_comune_versato,0);
      nAltri_comune_versato := nvl(nAltri_comune_versato,0);
      nFabbricati_d_comune_versato := nvl(nFabbricati_d_comune_versato,0);
      nTerreni_erariale_versato := nvl(nTerreni_erariale_versato,0);
      nAree_erariale_versato := nvl(nAree_erariale_versato,0);
      nAltri_erariale_versato := nvl(nAltri_erariale_versato,0);
      nFabbricati_d_erariale_versato := nvl(nFabbricati_d_erariale_versato,0);
      nFabbricati_merce_versato := nvl(nFabbricati_merce_versato,0);

      BEGIN
         /*select decode(a_tipo_versamento
                      ,'U',sum(IMPORTO)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,importo
                                     ,101,importo
                                     ,151,importo
                                     ,152,importo
                                     ,155,importo
                                     ,198,importo
                                     ,132,importo
                                     ,134,importo
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,importo
                                     ,121,importo
                                     ,153,importo
                                     ,154,importo
                                     ,156,importo
                                     ,199,importo
                                     ,132,importo
                                     ,134,importo
                                     ,0
                                     )
                              )
                       ) importo_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(ab_principale)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,ab_principale
                                     ,101,ab_principale
                                     ,151,ab_principale
                                     ,152,ab_principale
                                     ,155,ab_principale
                                     ,198,ab_principale
                                     ,132,ab_principale
                                     ,134,ab_principale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,ab_principale
                                     ,121,ab_principale
                                     ,153,ab_principale
                                     ,154,ab_principale
                                     ,156,ab_principale
                                     ,199,ab_principale
                                     ,132,ab_principale
                                     ,134,ab_principale
                                     ,0
                                     )
                              )
                       ) ab_principale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(rurali)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,rurali
                                     ,101,rurali
                                     ,151,rurali
                                     ,152,rurali
                                     ,155,rurali
                                     ,198,rurali
                                     ,132,rurali
                                     ,134,rurali
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,rurali
                                     ,121,rurali
                                     ,153,rurali
                                     ,154,rurali
                                     ,156,rurali
                                     ,199,rurali
                                     ,132,rurali
                                     ,134,rurali
                                     ,0
                                     )
                              )
                       ) rurali_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(terreni_comune)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,terreni_comune
                                     ,101,terreni_comune
                                     ,151,terreni_comune
                                     ,152,terreni_comune
                                     ,155,terreni_comune
                                     ,198,terreni_comune
                                     ,132,terreni_comune
                                     ,134,terreni_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,terreni_comune
                                     ,121,terreni_comune
                                     ,153,terreni_comune
                                     ,154,terreni_comune
                                     ,156,terreni_comune
                                     ,199,terreni_comune
                                     ,132,terreni_comune
                                     ,134,terreni_comune
                                     ,0
                                     )
                              )
                       ) terreni_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(aree_comune)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,aree_comune
                                     ,101,aree_comune
                                     ,151,aree_comune
                                     ,152,aree_comune
                                     ,155,aree_comune
                                     ,198,aree_comune
                                     ,132,aree_comune
                                     ,134,aree_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,aree_comune
                                     ,121,aree_comune
                                     ,153,aree_comune
                                     ,154,aree_comune
                                     ,156,aree_comune
                                     ,199,aree_comune
                                     ,132,aree_comune
                                     ,134,aree_comune
                                     ,0
                                     )
                              )
                       ) aree_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(altri_comune)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,altri_comune
                                     ,101,altri_comune
                                     ,151,altri_comune
                                     ,152,altri_comune
                                     ,155,altri_comune
                                     ,198,altri_comune
                                     ,132,altri_comune
                                     ,134,altri_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,altri_comune
                                     ,121,altri_comune
                                     ,153,altri_comune
                                     ,154,altri_comune
                                     ,156,altri_comune
                                     ,199,altri_comune
                                     ,132,altri_comune
                                     ,134,altri_comune
                                     ,0
                                     )
                              )
                       ) altri_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(fabbricati_d_comune)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_comune
                                     ,101,fabbricati_d_comune
                                     ,151,fabbricati_d_comune
                                     ,152,fabbricati_d_comune
                                     ,155,fabbricati_d_comune
                                     ,198,fabbricati_d_comune
                                     ,132,fabbricati_d_comune
                                     ,134,fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,fabbricati_d_comune
                                     ,121,fabbricati_d_comune
                                     ,153,fabbricati_d_comune
                                     ,154,fabbricati_d_comune
                                     ,156,fabbricati_d_comune
                                     ,199,fabbricati_d_comune
                                     ,132,fabbricati_d_comune
                                     ,134,fabbricati_d_comune
                                     ,0
                                     )
                              )
                       ) fabbricati_d_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(terreni_erariale)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,terreni_erariale
                                     ,101,terreni_erariale
                                     ,151,terreni_erariale
                                     ,152,terreni_erariale
                                     ,155,terreni_erariale
                                     ,198,terreni_erariale
                                     ,132,terreni_erariale
                                     ,134,terreni_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,terreni_erariale
                                     ,121,terreni_erariale
                                     ,153,terreni_erariale
                                     ,154,terreni_erariale
                                     ,156,terreni_erariale
                                     ,199,terreni_erariale
                                     ,132,terreni_erariale
                                     ,134,terreni_erariale
                                     ,0
                                     )
                              )
                       ) terreni_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(aree_erariale)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,aree_erariale
                                     ,101,aree_erariale
                                     ,151,aree_erariale
                                     ,152,aree_erariale
                                     ,155,aree_erariale
                                     ,198,aree_erariale
                                     ,132,aree_erariale
                                     ,134,aree_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,aree_erariale
                                     ,121,aree_erariale
                                     ,153,aree_erariale
                                     ,154,aree_erariale
                                     ,156,aree_erariale
                                     ,199,aree_erariale
                                     ,132,aree_erariale
                                     ,134,aree_erariale
                                     ,0
                                     )
                              )
                       ) aree_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(altri_erariale)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,altri_erariale
                                     ,101,altri_erariale
                                     ,151,altri_erariale
                                     ,152,altri_erariale
                                     ,155,altri_erariale
                                     ,198,altri_erariale
                                     ,132,altri_erariale
                                     ,134,altri_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,altri_erariale
                                     ,121,altri_erariale
                                     ,153,altri_erariale
                                     ,154,altri_erariale
                                     ,156,altri_erariale
                                     ,199,altri_erariale
                                     ,132,altri_erariale
                                     ,134,altri_erariale
                                     ,0
                                     )
                              )
                       ) altri_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(fabbricati_d_erariale)
                      ,'A',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_erariale
                                     ,101,fabbricati_d_erariale
                                     ,151,fabbricati_d_erariale
                                     ,152,fabbricati_d_erariale
                                     ,155,fabbricati_d_erariale
                                     ,198,fabbricati_d_erariale
                                     ,132,fabbricati_d_erariale
                                     ,134,fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,fabbricati_d_erariale
                                     ,121,fabbricati_d_erariale
                                     ,153,fabbricati_d_erariale
                                     ,154,fabbricati_d_erariale
                                     ,156,fabbricati_d_erariale
                                     ,199,fabbricati_d_erariale
                                     ,132,fabbricati_d_erariale
                                     ,134,fabbricati_d_erariale
                                     ,0
                                     )
                              )
                       ) fabbricati_d_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,importo
                                     ,21,importo
                                     ,101,importo
                                     ,121,importo
                                     ,501,importo
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,importo
                                     ,101,importo
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,importo
                                     ,121,importo
                                     ,0
                                     )
                              )
                      ) importo_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,ab_principale
                                     ,21,ab_principale
                                     ,101,ab_principale
                                     ,121,ab_principale
                                     ,501,ab_principale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,ab_principale
                                     ,101,ab_principale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,ab_principale
                                     ,121,ab_principale
                                     ,0
                                     )
                              )
                      ) ab_principale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,rurali
                                     ,21,rurali
                                     ,101,rurali
                                     ,121,rurali
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,rurali
                                     ,101,rurali
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,rurali
                                     ,121,rurali
                                     ,0
                                     )
                              )
                      ) rurali_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,terreni_comune
                                     ,21,terreni_comune
                                     ,101,terreni_comune
                                     ,121,terreni_comune
                                     ,501,terreni_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,terreni_comune
                                     ,101,terreni_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,terreni_comune
                                     ,121,terreni_comune
                                     ,0
                                     )
                              )
                      ) terreni_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,aree_comune
                                     ,21,aree_comune
                                     ,101,aree_comune
                                     ,121,aree_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,aree_comune
                                     ,101,aree_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,aree_comune
                                     ,121,aree_comune
                                     ,0
                                     )
                              )
                      ) aree_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,altri_comune
                                     ,21,altri_comune
                                     ,101,altri_comune
                                     ,121,altri_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,altri_comune
                                     ,101,altri_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,altri_comune
                                     ,121,altri_comune
                                     ,0
                                     )
                              )
                      ) altri_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_comune
                                     ,21,fabbricati_d_comune
                                     ,101,fabbricati_d_comune
                                     ,121,fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_comune
                                     ,101,fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,fabbricati_d_comune
                                     ,121,fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ) fabbricati_d_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,terreni_erariale
                                     ,21,terreni_erariale
                                     ,101,terreni_erariale
                                     ,121,terreni_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,terreni_erariale
                                     ,101,terreni_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,terreni_erariale
                                     ,121,terreni_erariale
                                     ,0
                                     )
                              )
                      ) terreni_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,aree_erariale
                                     ,21,aree_erariale
                                     ,101,aree_erariale
                                     ,121,aree_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,aree_erariale
                                     ,101,aree_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,aree_erariale
                                     ,121,aree_erariale
                                     ,0
                                     )
                              )
                      ) aree_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,altri_erariale
                                     ,21,altri_erariale
                                     ,101,altri_erariale
                                     ,121,altri_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,altri_erariale
                                     ,101,altri_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,altri_erariale
                                     ,121,altri_erariale
                                     ,0
                                     )
                              )
                      ) altri_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_erariale
                                     ,21,fabbricati_d_erariale
                                     ,101,fabbricati_d_erariale
                                     ,121,fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(cod_sanzione
                                     ,1,fabbricati_d_erariale
                                     ,101,fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(cod_sanzione
                                     ,21,fabbricati_d_erariale
                                     ,121,fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ) fabbricati_d_erariale_reale
           into nImporto_sapr
                , nAb_principale_sapr
                , nRurali_sapr
                , nTerreni_comune_sapr
                , nAree_comune_sapr
                , nAltri_comune_sapr
                , nFabbricati_d_comune_sapr
                , nTerreni_erariale_sapr
                , nAree_erariale_sapr
                , nAltri_erariale_sapr
                , nFabbricati_d_erariale_sapr
                , nImporto_reale
                , nAb_principale_reale
                , nRurali_reale
                , nTerreni_comune_reale
                , nAree_comune_reale
                , nAltri_comune_reale
                , nFabbricati_d_comune_reale
                , nTerreni_erariale_reale
                , nAree_erariale_reale
                , nAltri_erariale_reale
                , nFabbricati_d_erariale_reale
           from sanzioni_pratica
          where pratica = rec_prtr.pratica
              ; */
         select decode(a_tipo_versamento
                      ,'U',sum(importo)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',importo
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',importo
                                     ,0
                                     )
                              )
                       ) importo_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(ab_principale)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',ab_principale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',ab_principale
                                     ,0
                                     )
                              )
                       ) ab_principale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(rurali)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',rurali
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',rurali
                                     ,0
                                     )
                              )
                       ) rurali_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(terreni_comune)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',terreni_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',terreni_comune
                                     ,0
                                     )
                              )
                       ) terreni_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(aree_comune)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',aree_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',aree_comune
                                     ,0
                                     )
                              )
                       ) aree_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(altri_comune)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',altri_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',altri_comune
                                     ,0
                                     )
                              )
                       ) altri_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(fabbricati_d_comune)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',fabbricati_d_comune
                                     ,0
                                     )
                              )
                       ) fabbricati_d_comune_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(terreni_erariale)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',terreni_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',terreni_erariale
                                     ,0
                                     )
                              )
                       ) terreni_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(aree_erariale)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',aree_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',aree_erariale
                                     ,0
                                     )
                              )
                       ) aree_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(altri_erariale)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',altri_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',altri_erariale
                                     ,0
                                     )
                              )
                       ) altri_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(fabbricati_d_erariale)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',fabbricati_d_erariale
                                     ,0
                                     )
                              )
                       ) fabbricati_d_erariale_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(fabbricati_merce)
                      ,'A',sum(decode(sanz.tipo_versamento
                                     ,'A',fabbricati_merce
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_versamento
                                     ,'S',fabbricati_merce
                                     ,0
                                     )
                              )
                       ) nFabbricati_merce_sapr
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',importo
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',importo
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',importo
                                     ,0
                                     )
                              )
                      ) importo_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',ab_principale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',ab_principale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',ab_principale
                                     ,0
                                     )
                              )
                      ) ab_principale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',rurali
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',rurali
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',rurali
                                     ,0
                                     )
                              )
                      ) rurali_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',terreni_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',terreni_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',terreni_comune
                                     ,0
                                     )
                              )
                      ) terreni_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',aree_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',aree_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',aree_comune
                                     ,0
                                     )
                              )
                      ) aree_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',altri_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',altri_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',altri_comune
                                     ,0
                                     )
                              )
                      ) altri_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',fabbricati_d_comune
                                     ,0
                                     )
                              )
                      ) fabbricati_d_comune_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',terreni_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',terreni_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',terreni_erariale
                                     ,0
                                     )
                              )
                      ) terreni_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',aree_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',aree_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',aree_erariale
                                     ,0
                                     )
                              )
                      ) aree_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',altri_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',altri_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',altri_erariale
                                     ,0
                                     )
                              )
                      ) altri_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',fabbricati_d_erariale
                                     ,0
                                     )
                              )
                      ) fabbricati_d_erariale_reale
              , decode(a_tipo_versamento
                      ,'U',sum(decode(sanz.tipo_causale
                                     ,'E',fabbricati_merce
                                     ,0
                                     )
                              )
                      ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'EA',fabbricati_merce
                                     ,0
                                     )
                              )
                      ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                     ,'ES',fabbricati_merce
                                     ,0
                                     )
                              )
                      ) fabbricati_merce_reale
           into nImporto_sapr
                , nAb_principale_sapr
                , nRurali_sapr
                , nTerreni_comune_sapr
                , nAree_comune_sapr
                , nAltri_comune_sapr
                , nFabbricati_d_comune_sapr
                , nTerreni_erariale_sapr
                , nAree_erariale_sapr
                , nAltri_erariale_sapr
                , nFabbricati_d_erariale_sapr
                , nFabbricati_merce_sapr
                , nImporto_reale
                , nAb_principale_reale
                , nRurali_reale
                , nTerreni_comune_reale
                , nAree_comune_reale
                , nAltri_comune_reale
                , nFabbricati_d_comune_reale
                , nTerreni_erariale_reale
                , nAree_erariale_reale
                , nAltri_erariale_reale
                , nFabbricati_d_erariale_reale
                , nFabbricati_merce_reale
           from sanzioni_pratica sapr
              , sanzioni         sanz
          where sapr.pratica = rec_prtr.pratica
            and sapr.tipo_tributo  = sanz.tipo_tributo
            and sapr.cod_sanzione  = sanz.cod_sanzione
            and sapr.sequenza_sanz = sanz.sequenza
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nImporto_sapr   := 0;
            nImporto_reale  := 0;
         WHEN others THEN
            nImporto_sapr   := 0;
            nImporto_reale  := 0;
      END;

      nImporto_sapr  := nvl(nImporto_sapr,0);
      nAb_principale_sapr := nvl(nAb_principale_sapr,0);
      nRurali_sapr := nvl(nRurali_sapr,0);
      nTerreni_comune_sapr := nvl(nTerreni_comune_sapr,0);
      nAree_comune_sapr := nvl(nAree_comune_sapr,0);
      nAltri_comune_sapr := nvl(nAltri_comune_sapr,0);
      nFabbricati_d_comune_sapr := nvl(nFabbricati_d_comune_sapr,0);
      nTerreni_erariale_sapr := nvl(nTerreni_erariale_sapr,0);
      nAree_erariale_sapr := nvl(nAree_erariale_sapr,0);
      nAltri_erariale_sapr := nvl(nAltri_erariale_sapr,0);
      nFabbricati_d_erariale_sapr := nvl(nFabbricati_d_erariale_sapr,0);
      nFabbricati_merce_sapr := nvl(nFabbricati_merce_sapr,0);

      nImporto_reale := nvl(nImporto_reale,0);
      nAb_principale_reale := nvl(nAb_principale_reale,0);
      nRurali_reale := nvl(nRurali_reale,0);
      nTerreni_comune_reale := nvl(nTerreni_comune_reale,0);
      nAree_comune_reale := nvl(nAree_comune_reale,0);
      nAltri_comune_reale := nvl(nAltri_comune_reale,0);
      nFabbricati_d_comune_reale := nvl(nFabbricati_d_comune_reale,0);
      nTerreni_erariale_reale := nvl(nTerreni_erariale_reale,0);
      nAree_erariale_reale := nvl(nAree_erariale_reale,0);
      nAltri_erariale_reale := nvl(nAltri_erariale_reale,0);
      nFabbricati_d_erariale_reale := nvl(nFabbricati_d_erariale_reale,0);
      nFabbricati_merce_reale := nvl(nFabbricati_merce_reale,0);

     -- RAISE_APPLICATION_ERROR (-20999,'nImporto_reale: '||to_char(nImporto_reale));

      if nImporto_versato > 0 then

         -- Gestione Arrotondamenti
         -- if a_anno >= 2007 then
         --    nImporto_sapr  := round(nImporto_sapr,0);
         --    nImporto_reale := round(nImporto_reale,0);
         -- end if;

         if nImporto_versato >= nImporto_sapr then
            nImporto := nImporto +  nImporto_reale + nImporto_versato - nImporto_sapr;
            nAb_principale := nAb_principale +  nAb_principale_reale + nAb_principale_versato - nAb_principale_sapr;
            nRurali := nRurali +  nRurali_reale + nRurali_versato - nRurali_sapr;
            nTerreni_comune := nTerreni_comune +  nTerreni_comune_reale + nTerreni_comune_versato - nTerreni_comune_sapr;
            nAree_comune := nAree_comune +  nAree_comune_reale + nAree_comune_versato - nAree_comune_sapr;
            nAltri_comune := nAltri_comune +  nAltri_comune_reale + nAltri_comune_versato - nAltri_comune_sapr;
            nFabbricati_d_comune := nFabbricati_d_comune +  nFabbricati_d_comune_reale + nFabbricati_d_comune_versato - nFabbricati_d_comune_sapr;
            nTerreni_erariale := nTerreni_erariale +  nTerreni_erariale_reale + nTerreni_erariale_versato - nTerreni_erariale_sapr;
            nAree_erariale := nAree_erariale +  nAree_erariale_reale + nAree_erariale_versato - nAree_erariale_sapr;
            nAltri_erariale := nAltri_erariale +  nAltri_erariale_reale + nAltri_erariale_versato - nAltri_erariale_sapr;
            nFabbricati_d_erariale := nFabbricati_d_erariale +  nFabbricati_d_erariale_reale + nFabbricati_d_erariale_versato - nFabbricati_d_erariale_sapr;
            nFabbricati_merce := nFabbricati_merce + nFabbricati_merce_reale + nFabbricati_merce_versato - nFabbricati_merce_sapr;
         else
            nImporto := nImporto + round( nImporto_reale * ( nImporto_versato / nImporto_sapr),2);
            if nAb_principale_sapr != 0 then
               nAb_principale := nAb_principale + round( nAb_principale_reale * ( nAb_principale_versato / nAb_principale_sapr),2);
            else
               nAb_principale := nAb_principale + round( nAb_principale_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nRurali_sapr != 0 then
               nRurali := nRurali + round( nRurali_reale * ( nRurali_versato / nRurali_sapr),2);
            else
               nRurali := nRurali + round( nRurali_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nTerreni_comune_sapr != 0 then
               nTerreni_comune := nTerreni_comune + round( nTerreni_comune_reale * ( nTerreni_comune_versato / nTerreni_comune_sapr),2);
            else
               nTerreni_comune := nTerreni_comune + round( nTerreni_comune_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nAree_comune_sapr != 0 then
               nAree_comune := nAree_comune + round( nAree_comune_reale * ( nAree_comune_versato / nAree_comune_sapr),2);
            else
               nAree_comune := nAree_comune + round( nAree_comune_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nAltri_comune_sapr != 0 then
               nAltri_comune := nAltri_comune + round( nAltri_comune_reale * ( nAltri_comune_versato / nAltri_comune_sapr),2);
            else
               nAltri_comune := nAltri_comune + round( nAltri_comune_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nFabbricati_d_comune_sapr != 0 then
               nFabbricati_d_comune := nFabbricati_d_comune + round( nFabbricati_d_comune_reale * ( nFabbricati_d_comune_versato / nFabbricati_d_comune_sapr),2);
            else
               nFabbricati_d_comune := nFabbricati_d_comune + round( nFabbricati_d_comune_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nTerreni_erariale_sapr != 0 then
               nTerreni_erariale := nTerreni_erariale + round( nTerreni_erariale_reale * ( nTerreni_erariale_versato / nTerreni_erariale_sapr),2);
            else
               nTerreni_erariale := nTerreni_erariale + round( nTerreni_erariale_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nAree_erariale_sapr != 0 then
               nAree_erariale := nAree_erariale + round( nAree_erariale_reale * ( nAree_erariale_versato / nAree_erariale_sapr),2);
            else
               nAree_erariale := nAree_erariale + round( nAree_erariale_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nAltri_erariale_sapr != 0 then
               nAltri_erariale := nAltri_erariale + round( nAltri_erariale_reale * ( nAltri_erariale_versato / nAltri_erariale_sapr),2);
            else
               nAltri_erariale := nAltri_erariale + round( nAltri_erariale_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nFabbricati_d_erariale_sapr != 0 then
               nFabbricati_d_erariale := nFabbricati_d_erariale + round( nFabbricati_d_erariale_reale * ( nFabbricati_d_erariale_versato / nFabbricati_d_erariale_sapr),2);
            else
               nFabbricati_d_erariale := nFabbricati_d_erariale + round( nFabbricati_d_erariale_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
            if nFabbricati_merce_sapr != 0 then
               nFabbricati_merce := nFabbricati_merce + round( nFabbricati_merce_reale * ( nFabbricati_merce_versato / nFabbricati_merce_sapr),2);
            else
               nFabbricati_merce := nFabbricati_merce + round( nFabbricati_merce_reale * ( nImporto_versato / nImporto_sapr),2);
            end if;
         end if;

      end if;

   END LOOP;

--   Return nImporto;
   if a_tipo_dettaglio = 'TOT' -- Totale
   then return nImporto;
   elsif a_tipo_dettaglio = 'ABP' -- Abitazione Principale
   then return nAb_principale;
   elsif a_tipo_dettaglio = 'RUR' -- Rurali
   then return nRurali;
   elsif a_tipo_dettaglio = 'TEC' -- Terreni comune
   then return nTerreni_comune;
   elsif a_tipo_dettaglio = 'ARC' -- Aree comune
   then return nAree_comune;
   elsif a_tipo_dettaglio = 'ALC' -- Altri comune
   then return nAltri_comune;
   elsif a_tipo_dettaglio = 'FDC' -- Fabbricati D comune
   then return nFabbricati_d_comune;
   elsif a_tipo_dettaglio = 'TEE' -- Terreni erariale
   then return nTerreni_erariale;
   elsif a_tipo_dettaglio = 'ARE' -- Aree erariale
   then return nAree_erariale;
   elsif a_tipo_dettaglio = 'ALE' -- Altri erariale
   then return nAltri_erariale;
   elsif a_tipo_dettaglio = 'FDE' -- Fabbricati D erariale
   then return nFabbricati_d_erariale;
   elsif a_tipo_dettaglio = 'FAM'
   then return nFabbricati_merce;
   end if;

EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR (-20999,'Errore in Calcolo Importo Versamenti Ravv Dett'||'('||SQLERRM||')');
END;
/* End Function: F_IMPORTO_VERS_RAVV_DETT */
/
