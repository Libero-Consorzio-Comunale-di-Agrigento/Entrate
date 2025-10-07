--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_annullamenti_f24 stripComments:false runOnChange:true 
 
create or replace procedure CARICA_ANNULLAMENTI_F24
/*************************************************************************
 NOME:        CARICA_ANNULLAMENTI_F24
 DESCRIZIONE: Carica le revoche e i ripristini presenti in un file di
              versamenti a mezzo F24 (tipo record G9)
 NOTE:
 Causali errore:       50400     Versamento già presente
                       50409     Contribuente non codificato
 Versione  Data        Autore    Descrizione
 004       16/03/2023  VM        #55165 - Aggiunto parametro a_cod_fiscale.
                                 Aggiunto filtro cod_fiscale su popolamento cursori.
 3         31/05/2018  VD        Modificata query per escludere annullamenti
                                 relativi a COSAP e ICP.
 2         16/05/2017  VD        Aggiunto raggruppamento per data versamento
                                 per gestire versamenti dello stesso tipo
                                 effettuati in date diverse
 1         05/07/2016  VD        Aggiunto parametro tipo_tributo per
                                 gestire revoche e ripristini divisi
                                 per tipo tributo
 0         16/06/2016  VD        Prima emissione
 *************************************************************************/
( a_documento_id            documenti_caricati.documento_id%type default null
, a_tipo_tributo            varchar2
, a_cod_fiscale             varchar2 default '%'
)
IS
w_progressivo        number;
w_sequenza           number;
w_conta              number;
w_conta_cont         number;
w_ni                 number;
w_pratica            number;
w_anno_pratica       number;
w_errore             varchar2(2000);
errore               exception;
-- nella prima fase faccio diventare contribuenti i titolari dei versamenti
-- per cui è stato indicato il flag_contribuente
cursor sel_ins_cont is
select wkve.tipo_tributo
      ,wkve.progressivo
      ,wkve.anno
      ,wkve.cod_fiscale
      ,wkve.importo_versato
      ,wkve.ab_principale
      ,wkve.terreni_agricoli
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_fabbricabili
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_fabbricati
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.rurali
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,wkve.fabbricati_d
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.maggiorazione_tares
      ,wkve.data_pagamento
      ,wkve.ufficio_pt
      ,wkve.data_reg
      ,wkve.flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,substr(wkve.note,1,instr(wkve.note,')',1)) note
      ,substr(wkve.note,instr(wkve.note,'-',1) + 2,1) tipo_importo
      ,wkve.documento_id
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = a_tipo_tributo
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and wkve.causale         = '50409'
   and sogg.ni          (+) = cont.ni
   and nvl(wkve.flag_contribuente,'N') = 'S'
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
   ;
--
-- Esiste una fase iniziale di bonifica di eventuali anomalie presenti nella
-- tabella intermedia wrk_versamenti. Si tenta di ri-inserire il versamento;
-- se questo va a buon fine, allora si elimina la tabella wrk, altrimenti si
-- lascia la registrazione come in precedenza. Al massimo varia il motivo di
-- errore nel qual caso si cambiano la causale e le note.
--
cursor sel_errati is
select wkve.tipo_tributo
      ,wkve.progressivo
      ,wkve.anno
      ,wkve.cod_fiscale
      ,wkve.importo_versato
      ,wkve.ab_principale
      ,wkve.terreni_agricoli
      ,wkve.terreni_erariale
      ,wkve.terreni_comune
      ,wkve.aree_fabbricabili
      ,wkve.aree_erariale
      ,wkve.aree_comune
      ,wkve.altri_fabbricati
      ,wkve.altri_erariale
      ,wkve.altri_comune
      ,wkve.rurali
      ,wkve.rurali_erariale
      ,wkve.rurali_comune
      ,wkve.fabbricati_d
      ,wkve.fabbricati_d_erariale
      ,wkve.fabbricati_d_comune
      ,wkve.maggiorazione_tares
      ,wkve.data_pagamento
      ,wkve.ufficio_pt
      ,wkve.data_reg
      ,wkve.flag_contribuente
      ,cont.cod_fiscale                  cod_fiscale_cont
      ,sogg.cognome_nome                 cognome_nome
      ,substr(wkve.note,1,instr(wkve.note,')',1)) note
      ,substr(wkve.note,instr(wkve.note,'-',1) + 2,1) tipo_importo
      ,wkve.documento_id
  from wrk_versamenti wkve
      ,contribuenti   cont
      ,soggetti       sogg
 where wkve.tipo_incasso    = 'F24'
   and wkve.tipo_tributo    = a_tipo_tributo
   and wkve.causale         in ('50400','50409')
   and cont.cod_fiscale (+) = wkve.cod_fiscale
   and sogg.ni          (+) = cont.ni
   and (cont.cod_fiscale like a_cod_fiscale or a_cod_fiscale = '%')
;
--
-- Il cursore esegue il raggruppamento per contribuente, anno e tipo di versamento
-- perche` viene fornito un dato per ogni tipologia di oggetto.
-- Anche se in realta` i seguenti dati dovrebbero essere gli stessi, nel caso di
-- ufficio_pt, data di versamento e data di registrazione vengono presi i valori
-- massimi.
-- La eliminazione delle registrazioni di input inserite non avviene piu`
-- per progressivo (una riga alla volta), ma per raggruppamento trattato, ovvero
-- per contribuente, anno e tipo di versamento.
-- Gli importi versati e le detrazioni sono sommati per ogni raggruppamento.
--
CURSOR sel_vers IS
select rtrim(substr(wkta.dati,67,16))                    cod_fiscale_vers
      ,to_number(substr(wkta.dati,99,4))                 anno
      ,substr(wkta.dati,136,1)                           tipo_operazione
      ,decode(substr(wkta.dati,145,1),'I','ICI'
                                     ,'U','TASI'
                                     ,'TARSU')           tipo_tributo
      ,decode(substr(wkta.dati,95,4),'3906','S'
                                    ,'3907','S'
                                    ,'3923','S'
                                    ,'3924','S'
                                    ,'357E','S'
                                    ,'358E','S'
                                    ,'3962','S'
                                    ,'3963','S'
                                    ,'377E','S'
                                    ,'378E','S'
                                    ,'3945','S'
                                    ,'3946','S'
                                    ,'3921','S'
                                    ,'3922','S'
                                    ,'3951','S'
                                    ,'3952','S'
                                    ,'366E','S'
                                    ,'367E','S'
                                    ,'369E','S'
                                    ,'370E','S'
                                    ,'372E','S'
                                    ,'373E','S'
                                    ,'3956','S'
                                    ,'3957','S'
                                    ,'I')                tipo_importo
      ,to_date(substr(wkta.dati,83,8),'yyyymmdd')        data_pagamento
      ,max(cont.cod_fiscale)                             cod_fiscale
      ,max(sogg.cognome_nome)                            cognome_nome
      ,min(wkta.progressivo)                             progressivo
      ,max(decode(substr(wkta.dati,57,5)
                 ,'99999','Internet'
                 ,'07601','Poste - Codice '
                 ,decode(greatest(to_number(substr(wkta.dati,57,5)),999)
                        ,999,'Concessionario - Codice '
                            ,'Banca - ABI '))||
           decode(substr(wkta.dati,57,5),'999999','',substr(wkta.dati,57,5)))  ufficio_pt
      --,max(to_date(substr(wkta.dati,83,8),'yyyymmdd'))   data_pagamento
      ,sum((to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
           * decode(substr(wkta.dati,136,1),'A',-1,1)
          )
                                                         importo_versato
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3901',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- ICI (non piu in uso)
                 ,'3940',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- ICI
                 ,'3912',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'3958',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              ab_principale
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3913',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'350E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3959',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'374E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              rurali
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3913',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'350E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3959',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'374E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              rurali_comune
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3902',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3941',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3914',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3915',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'351E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'352E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              terreni_agricoli
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3914',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'351E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              terreni_agricoli_comune
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3915',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'352E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              terreni_agricoli_erariale
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3903',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU ICI
                 ,'3942',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- ICI
                 ,'3916',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'3917',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'353E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'354E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3960',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'375E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              aree_fabbricabili
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3916',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'353E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3960',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'375E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              aree_fabbricabili_comune
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3917',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'354E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              aree_fabbricabili_erariale
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3904',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3943',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- ICI
                 ,'3918',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'3919',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'355E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'356E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3961',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'376E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              altri_fabbricati
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3918',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'355E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'3961',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- TASI
                 ,'376E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              altri_fabbricati_comune
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3919',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'356E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              altri_fabbricati_erariale
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3925',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'3930',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'359E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'360E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              fabbricati_d
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3930',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'360E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              fabbricati_d_comune
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3925',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100  -- IMU
                 ,'359E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              fabbricati_d_erariale
      ,sum(decode(substr(wkta.dati,95,4)
                 ,'3955',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,'371E',(to_number(substr(wkta.dati,106,15)) - to_number(substr(wkta.dati,121,15))) / 100
                 ,to_number(null)
                 ) *
           decode(substr(wkta.dati,136,1),'A',-1,1)
          )                                              maggiorazione_tares
      ,max(to_date(substr(wkta.dati,3,8),'yyyymmdd'))    data_reg
      ,'VERSAMENTO IMPORTATO DA MODELLO F24'             descrizione
      ,decode(substr(wkta.dati,136,1),'A','Annullamento (G9)'
                                     ,'R','Ripristino (G9)'
                                     ,null)              note
      ,9                                                 fonte
      ,'F24'                                             utente
      ,trunc(sysdate)                                    data_variazione
  from wrk_tras_anci         wkta
      ,contribuenti          cont
      ,soggetti              sogg
 where cont.cod_fiscale     (+) = rtrim(substr(wkta.dati,67,16))
   and sogg.ni              (+) = cont.ni
   and wkta.anno                = 2
   and substr(wkta.dati,1,2)    = 'G9'                   -- Si trattano solo revoche o ripristini
   and decode(substr(wkta.dati,145,1),'I','ICI'
                                     ,'U','TASI'
                                     ,'T','TARSU'
                                     ,'A','TARSU'
                                         ,'XXX') = a_tipo_tributo
 group by rtrim(substr(wkta.dati,67,16))                 -- cod_fiscale versamento
         ,to_number(substr(wkta.dati,99,4))              -- anno
         ,substr(wkta.dati,136,1)                        -- tipo operazione
         ,decode(substr(wkta.dati,145,1),'I','ICI'
                                        ,'U','TASI'
                                        ,'TARSU')        -- tipo_tributo
         ,decode(substr(wkta.dati,95,4),'3906','S'
                                       ,'3907','S'
                                       ,'3923','S'
                                       ,'3924','S'
                                       ,'357E','S'
                                       ,'358E','S'
                                       ,'3962','S'
                                       ,'3963','S'
                                       ,'377E','S'
                                       ,'378E','S'
                                       ,'3945','S'
                                       ,'3946','S'
                                       ,'3921','S'
                                       ,'3922','S'
                                       ,'3951','S'
                                       ,'3952','S'
                                       ,'366E','S'
                                       ,'367E','S'
                                       ,'369E','S'
                                       ,'370E','S'
                                       ,'372E','S'
                                       ,'373E','S'
                                       ,'3956','S'
                                       ,'3957','S'
                                       ,'I')             -- tipo_importo
         ,to_date(substr(wkta.dati,83,8),'yyyymmdd')     -- data_pagamento
 order by min(wkta.progressivo)
;
-- se si cambia la select ricordarsi la delete in fondo
------------------------------------
-- Funzione F_SELEZIONA_PROGRESSIVO
------------------------------------
FUNCTION F_SELEZIONA_PROGRESSIVO
RETURN NUMBER
is
nProgr    number;
BEGIN
   BEGIN
      select nvl(max(progressivo),0)
        into nProgr
        from wrk_versamenti
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         nProgr := 0;
   END;
   nProgr := nProgr + 1;
   RETURN nProgr;
END F_SELEZIONA_PROGRESSIVO;
---------------------------
--  INIZIO ELABORAZIONE  --
---------------------------
BEGIN
   --
   -- Si trattano i contribuenti precedentemente scartati e successivamente
   -- confermati da operatore
   --
   FOR rec_ins_cont IN sel_ins_cont  -- gestione flag_contribuente
   LOOP
      if rec_ins_cont.cod_fiscale_cont is null then
         begin
            select count(1)
              into w_conta_cont
              from contribuenti
             where cod_fiscale = rec_ins_cont.cod_fiscale
                ;
         EXCEPTION
            WHEN others THEN
              w_conta_cont := 0;
         end;
         if w_conta_cont = 0 then
            begin
               select nvl(max(ni),0)
                 into w_ni
                 from soggetti
                where nvl(cod_fiscale,partita_iva) = rec_ins_cont.cod_fiscale
                ;
            EXCEPTION
               WHEN others THEN
                 w_ni := 0;
            end;
            if nvl(w_ni,0) > 0 then
               BEGIN
                  insert into contribuenti
                         (cod_fiscale, ni)
                  values (rec_ins_cont.cod_fiscale,w_ni)
                     ;
               EXCEPTION
                  WHEN others THEN
                      w_errore := 'Errore ins cont cf:'||rec_ins_cont.cod_fiscale||
                                 ' ni:'||to_char(w_ni)||' ('||sqlerrm||')';
                      RAISE errore;
               END;
               --
               BEGIN -- Assegnazione Numero Progressivo
                  select nvl(max(vers.sequenza),0)+1
                    into w_sequenza
                    from versamenti vers
                   where vers.cod_fiscale     = rec_ins_cont.cod_fiscale
                     and vers.anno            = rec_ins_cont.anno
                     and vers.tipo_tributo    = rec_ins_cont.tipo_tributo
                          ;
               END;
               BEGIN
                  insert into versamenti
                        (cod_fiscale
                        ,anno
                        ,tipo_tributo
                        ,tipo_versamento
                        ,sequenza
                        ,descrizione
                        ,ufficio_pt
                        ,rata
                        ,data_pagamento
                        ,importo_versato
                        ,fonte
                        ,utente
                        ,data_variazione
                        ,data_reg
                        ,ab_principale
                        ,rurali
                        ,rurali_comune
                        ,terreni_agricoli
                        ,terreni_erariale
                        ,terreni_comune
                        ,aree_fabbricabili
                        ,aree_erariale
                        ,aree_comune
                        ,altri_fabbricati
                        ,altri_erariale
                        ,altri_comune
                        ,fabbricati_d
                        ,fabbricati_d_erariale
                        ,fabbricati_d_comune
                        ,maggiorazione_tares
                        ,note
                        ,documento_id
                        )
                values (rec_ins_cont.cod_fiscale
                       ,rec_ins_cont.anno
                       ,rec_ins_cont.tipo_tributo
                       ,'U'
                       ,w_sequenza
                       ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                       ,rec_ins_cont.ufficio_pt
                       ,0
                       ,rec_ins_cont.data_pagamento
                       ,rec_ins_cont.importo_versato
                       ,9
                       ,'F24'
                       ,trunc(sysdate)
                       ,rec_ins_cont.data_reg
                       ,rec_ins_cont.ab_principale
                       ,rec_ins_cont.rurali
                       ,rec_ins_cont.rurali_comune
                       ,rec_ins_cont.terreni_agricoli
                       ,rec_ins_cont.terreni_erariale
                       ,rec_ins_cont.terreni_comune
                       ,rec_ins_cont.aree_fabbricabili
                       ,rec_ins_cont.aree_erariale
                       ,rec_ins_cont.aree_comune
                       ,rec_ins_cont.altri_fabbricati
                       ,rec_ins_cont.altri_erariale
                       ,rec_ins_cont.altri_comune
                       ,rec_ins_cont.fabbricati_d
                       ,rec_ins_cont.fabbricati_d_erariale
                       ,rec_ins_cont.fabbricati_d_comune
                       ,rec_ins_cont.maggiorazione_tares
                       ,decode(rec_ins_cont.tipo_importo,'I','Imposta - ','Sanzioni e interessi - ')||rec_ins_cont.note
                       ,rec_ins_cont.documento_id
                       )
                      ;
               EXCEPTION
                   WHEN others THEN
                       CONTRIBUENTI_CHK_DEL(rec_ins_cont.cod_fiscale,null);
                       w_errore := 'Errore in inserimento versamento bonificato'||
                                   ' di '||rec_ins_cont.cod_fiscale||' progressivo '||
                                   to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                      RAISE errore;
               END;
               BEGIN
                  delete wrk_versamenti wkve
                   where wkve.progressivo  = rec_ins_cont.progressivo
                    ;
               EXCEPTION
                   WHEN others THEN
                      w_errore := 'Errore in cancellazione wrk_versamenti '||
                                 to_char(rec_ins_cont.progressivo)||' ('||sqlerrm||')';
                      RAISE errore;
               END;
            end if;
         end if;
      end if;
   END LOOP;    -- gestione flag_contribuente
---------------------------------------------------------------
-- Trattamento versamenti con errore da tabella WRK_VERSAMENTI
---------------------------------------------------------------
   FOR rec_errati IN sel_errati
   LOOP
      if rec_errati.cod_fiscale_cont is null then
         update wrk_versamenti wkve
            set wkve.cognome_nome = rec_errati.cognome_nome
               ,wkve.causale      = '50409'
               ,wkve.note         = rec_errati.note||' - '||
                                    decode(rec_errati.tipo_importo,'I','Imposta','Sanzioni')||
                                    ': Contribuente ('||rec_errati.cod_fiscale_cont||') sconosciuto'
          where wkve.progressivo  = rec_errati.progressivo
         ;
      else
         BEGIN
            select count(*)
              into w_conta
              from versamenti vers
             where vers.cod_fiscale            = rec_errati.cod_fiscale
               and vers.anno                   = rec_errati.anno
               and vers.tipo_tributo           = rec_errati.tipo_tributo
               and vers.descrizione            = 'VERSAMENTO IMPORTATO DA MODELLO F24'
               and vers.ufficio_pt             = rec_errati.ufficio_pt
               and vers.data_pagamento         = rec_errati.data_pagamento
               and vers.importo_versato        = rec_errati.importo_versato
               and vers.note                   = decode(rec_errati.tipo_importo,'I','Imposta - ','Sanzioni e interessi - ')||rec_errati.note
            ;
         EXCEPTION
            WHEN others THEN
                 w_errore := 'Errore in conteggio'||
                             ' di '||rec_errati.cod_fiscale||' progressivo '||
                             to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                 RAISE errore;
         END;
         if w_conta > 0 then
            begin
                update wrk_versamenti wkve
                   set wkve.cognome_nome = rec_errati.cognome_nome
                      ,wkve.causale      = '50400'
                      ,wkve.note         = rec_errati.note||' - '||
                                           decode(rec_errati.tipo_importo,'I','Imposta'
                                                                         ,'S','Sanzioni e Interessi'
                                                                           ,'')||
                                           ': Versamento gia` Presente in data '||
                                           to_char(rec_errati.data_pagamento,'dd/mm/yyyy')
                      ,wkve.flag_contribuente = NULL
                 where wkve.progressivo  = rec_errati.progressivo
                ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in update wrk_versamenti'||
                              ' di '||rec_errati.cod_fiscale||' progressivo '||
                              to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            end;
         else
            BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = rec_errati.cod_fiscale
                  and vers.anno            = nvl(w_anno_pratica,rec_errati.anno)
                  and vers.tipo_tributo    = rec_errati.tipo_tributo
               ;
            END;
            BEGIN
               insert into versamenti
                     (cod_fiscale
                     ,anno
                     ,tipo_tributo
                     ,tipo_versamento
                     ,sequenza
                     ,descrizione
                     ,ufficio_pt
                     ,rata
                     ,data_pagamento
                     ,importo_versato
                     ,fonte
                     ,utente
                     ,data_variazione
                     ,data_reg
                     ,ab_principale
                     ,rurali
                     ,rurali_comune
                     ,terreni_agricoli
                     ,terreni_erariale
                     ,terreni_comune
                     ,aree_fabbricabili
                     ,aree_erariale
                     ,aree_comune
                     ,altri_fabbricati
                     ,altri_erariale
                     ,altri_comune
                     ,fabbricati_d
                     ,fabbricati_d_erariale
                     ,fabbricati_d_comune
                     ,maggiorazione_tares
                     ,note
                     ,documento_id)
              values (rec_errati.cod_fiscale
                     ,rec_errati.anno
                     ,rec_errati.tipo_tributo
                     ,'U'
                     ,w_sequenza
                     ,'VERSAMENTO IMPORTATO DA MODELLO F24'
                     ,rec_errati.ufficio_pt
                     ,0
                     ,rec_errati.data_pagamento
                     ,rec_errati.importo_versato
                     ,9
                     ,'F24'
                     ,trunc(sysdate)
                     ,rec_errati.data_reg
                     ,rec_errati.ab_principale
                     ,rec_errati.rurali
                     ,rec_errati.rurali_comune
                     ,rec_errati.terreni_agricoli
                     ,rec_errati.terreni_erariale
                     ,rec_errati.terreni_comune
                     ,rec_errati.aree_fabbricabili
                     ,rec_errati.aree_erariale
                     ,rec_errati.aree_comune
                     ,rec_errati.altri_fabbricati
                     ,rec_errati.altri_erariale
                     ,rec_errati.altri_comune
                     ,rec_errati.fabbricati_d
                     ,rec_errati.fabbricati_d_erariale
                     ,rec_errati.fabbricati_d_comune
                     ,rec_errati.maggiorazione_tares
                     ,decode(rec_errati.tipo_importo,'I','Imposta - ','Sanzioni e interessi - ')||rec_errati.note
                     ,rec_errati.documento_id
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento versamento bonificato'||
                              ' di '||rec_errati.cod_fiscale||' progressivo '||
                              to_char(rec_errati.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            END;
            delete from wrk_versamenti wkve
             where wkve.progressivo  = rec_errati.progressivo
            ;
         end if;
      end if;
   END LOOP;
------------------------------------------------------------
-- Trattamento versamenti caricati in tabella WRK_TRAS_ANCI
------------------------------------------------------------
   FOR rec_vers IN sel_vers
   LOOP
      if rec_vers.cod_fiscale is null then
         w_progressivo := F_SELEZIONA_PROGRESSIVO;
         insert into wrk_versamenti
               (progressivo
               ,tipo_tributo
               ,tipo_incasso
               ,anno
               ,cod_fiscale
               ,cognome_nome
               ,causale
               ,disposizione
               ,ufficio_pt
               ,data_variazione
               ,note
               ,data_pagamento
               ,importo_versato
               ,ab_principale
               ,terreni_agricoli
               ,terreni_erariale
               ,terreni_comune
               ,aree_fabbricabili
               ,aree_erariale
               ,aree_comune
               ,altri_fabbricati
               ,altri_erariale
               ,altri_comune
               ,rurali
               ,rurali_comune
               ,fabbricati_d
               ,fabbricati_d_erariale
               ,fabbricati_d_comune
               ,maggiorazione_tares
               ,data_reg
               ,documento_id)
        values (w_progressivo
               ,rec_vers.tipo_tributo
               ,'F24'
               ,rec_vers.anno
               ,rec_vers.cod_fiscale_vers
               ,rec_vers.cognome_nome
               ,'50409'
               ,w_progressivo
               ,rec_vers.ufficio_pt
               ,sysdate
               ,rec_vers.note||' - '||
                decode(rec_vers.tipo_importo,'I','Imposta','Sanzioni')||
                ': Contribuente ('||rec_vers.cod_fiscale_vers||') sconosciuto'
               ,rec_vers.data_pagamento
               ,rec_vers.importo_versato
               ,rec_vers.ab_principale
               ,rec_vers.terreni_agricoli
               ,rec_vers.terreni_agricoli_erariale
               ,rec_vers.terreni_agricoli_comune
               ,rec_vers.aree_fabbricabili
               ,rec_vers.aree_fabbricabili_erariale
               ,rec_vers.aree_fabbricabili_comune
               ,rec_vers.altri_fabbricati
               ,rec_vers.altri_fabbricati_erariale
               ,rec_vers.altri_fabbricati_comune
               ,rec_vers.rurali
               ,rec_vers.rurali_comune
               ,rec_vers.fabbricati_d
               ,rec_vers.fabbricati_d_erariale
               ,rec_vers.fabbricati_d_comune
               ,rec_vers.maggiorazione_tares
               ,rec_vers.data_reg
               ,a_documento_id);
      else
         BEGIN
            select count(*)
              into w_conta
              from versamenti vers
             where vers.cod_fiscale            = rec_vers.cod_fiscale
               and vers.anno                   = rec_vers.anno
               and vers.tipo_tributo           = rec_vers.tipo_tributo
               and vers.descrizione            = rec_vers.descrizione
               and vers.ufficio_pt             = rec_vers.ufficio_pt
               and vers.data_pagamento         = rec_vers.data_pagamento
               and vers.importo_versato        = rec_vers.importo_versato
               and vers.note                   = decode(rec_vers.tipo_importo,'I','Imposta - ','Sanzioni e interessi - ')||rec_vers.note
            ;
         END;
         if w_conta > 0 then
            w_progressivo := F_SELEZIONA_PROGRESSIVO;
            insert into wrk_versamenti
                  (progressivo
                  ,tipo_tributo
                  ,tipo_incasso
                  ,anno
                  ,cod_fiscale
                  ,cognome_nome
                  ,causale
                  ,disposizione
                  ,ufficio_pt
                  ,data_variazione
                  ,note
                  ,data_pagamento
                  ,importo_versato
                  ,ab_principale
                  ,terreni_agricoli
                  ,terreni_erariale
                  ,terreni_comune
                  ,aree_fabbricabili
                  ,aree_erariale
                  ,aree_comune
                  ,altri_fabbricati
                  ,altri_erariale
                  ,altri_comune
                  ,rurali
                  ,rurali_comune
                  ,fabbricati_d
                  ,fabbricati_d_erariale
                  ,fabbricati_d_comune
                  ,maggiorazione_tares
                  ,data_reg
                  ,documento_id)
           values (w_progressivo
                  ,rec_vers.tipo_tributo
                  ,'F24'
                  ,rec_vers.anno
                  ,rec_vers.cod_fiscale_vers
                  ,rec_vers.cognome_nome
                  ,'50400'
                  ,w_progressivo
                  ,rec_vers.ufficio_pt
                  ,sysdate
                  ,rec_vers.note||' - '||
                   decode(rec_vers.tipo_importo,'I','Imposta','Sanzioni')||
                   ': Versamento gia` Presente in data '||to_char(rec_vers.data_pagamento,'dd/mm/yyyy')
                  ,rec_vers.data_pagamento
                  ,rec_vers.importo_versato
                  ,rec_vers.ab_principale
                  ,rec_vers.terreni_agricoli
                  ,rec_vers.terreni_agricoli_erariale
                  ,rec_vers.terreni_agricoli_comune
                  ,rec_vers.aree_fabbricabili
                  ,rec_vers.aree_fabbricabili_erariale
                  ,rec_vers.aree_fabbricabili_comune
                  ,rec_vers.altri_fabbricati
                  ,rec_vers.altri_fabbricati_erariale
                  ,rec_vers.altri_fabbricati_comune
                  ,rec_vers.rurali
                  ,rec_vers.rurali_comune
                  ,rec_vers.fabbricati_d
                  ,rec_vers.fabbricati_d_erariale
                  ,rec_vers.fabbricati_d_comune
                  ,rec_vers.maggiorazione_tares
                  ,rec_vers.data_reg
                  ,a_documento_id
                  );
         else
            BEGIN -- Assegnazione Numero Progressivo
               select nvl(max(vers.sequenza),0)+1
                 into w_sequenza
                 from versamenti vers
                where vers.cod_fiscale     = rec_vers.cod_fiscale
                  and vers.anno            = nvl(w_anno_pratica,rec_vers.anno)
                  and vers.tipo_tributo    = rec_vers.tipo_tributo
               ;
            END;
            BEGIN
               insert into versamenti
                     (cod_fiscale
                     ,anno
                     ,tipo_tributo
                     ,tipo_versamento
                     ,sequenza
                     ,descrizione
                     ,rata
                     ,ufficio_pt
                     ,data_pagamento
                     ,importo_versato
                     ,fonte
                     ,utente
                     ,data_variazione
                     ,data_reg
                     ,ab_principale
                     ,rurali
                     ,rurali_comune
                     ,terreni_agricoli
                     ,terreni_erariale
                     ,terreni_comune
                     ,aree_fabbricabili
                     ,aree_erariale
                     ,aree_comune
                     ,altri_fabbricati
                     ,altri_erariale
                     ,altri_comune
                     ,fabbricati_d
                     ,fabbricati_d_erariale
                     ,fabbricati_d_comune
                     ,maggiorazione_tares
                     ,note
                     ,documento_id)
               select rec_vers.cod_fiscale
                     ,rec_vers.anno
                     ,rec_vers.tipo_tributo
                     ,'U'
                     ,w_sequenza
                     ,rec_vers.descrizione
                     ,0
                     ,rec_vers.ufficio_pt
                     ,rec_vers.data_pagamento
                     ,rec_vers.importo_versato
                     ,rec_vers.fonte
                     ,rec_vers.utente
                     ,rec_vers.data_variazione
                     ,rec_vers.data_reg
                     ,rec_vers.ab_principale
                     ,rec_vers.rurali
                     ,rec_vers.rurali_comune
                     ,rec_vers.terreni_agricoli
                     ,rec_vers.terreni_agricoli_erariale
                     ,rec_vers.terreni_agricoli_comune
                     ,rec_vers.aree_fabbricabili
                     ,rec_vers.aree_fabbricabili_erariale
                     ,rec_vers.aree_fabbricabili_comune
                     ,rec_vers.altri_fabbricati
                     ,rec_vers.altri_fabbricati_erariale
                     ,rec_vers.altri_fabbricati_comune
                     ,rec_vers.fabbricati_d
                     ,rec_vers.fabbricati_d_erariale
                     ,rec_vers.fabbricati_d_comune
                     ,rec_vers.maggiorazione_tares
                     ,decode(rec_vers.tipo_importo,'I','Imposta - ','Sanzioni e interessi - ')||rec_vers.note
                     ,a_documento_id
                 from dual
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento versamento'||
                              ' di '||rec_vers.cod_fiscale||' progressivo '||
                              to_char(rec_vers.progressivo)||' ('||sqlerrm||')';
                  RAISE errore;
            END;
         end if;
      end if;
      BEGIN
         delete wrk_tras_anci wkta
          where rtrim(substr(wkta.dati,67,16))    = rec_vers.cod_fiscale_vers
            and to_number(substr(wkta.dati,99,4)) = rec_vers.anno
            and wkta.anno                         = 2
            and decode(substr(wkta.dati,145,1),'I','ICI'
                                              ,'U','TASI'
                                                  ,'TARSU') = a_tipo_tributo
            and substr(wkta.dati,1,2)             = 'G9'                   -- Si trattano solo le revoche
            and substr(wkta.dati,83,8)            = to_char(rec_vers.data_pagamento,'yyyymmdd')     -- data_pagamento
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in eliminazione wrk_tras_anci'||
                        ' progressivo '||to_char(rec_vers.progressivo)||
                        ' ('||sqlerrm||')';
            RAISE errore;
      END;
   END LOOP;
EXCEPTION
   WHEN errore THEN
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CARICA_ANNULLAMENTI_F24 */
/
