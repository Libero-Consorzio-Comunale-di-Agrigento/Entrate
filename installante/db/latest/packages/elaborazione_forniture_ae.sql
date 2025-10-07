--liquibase formatted sql 
--changeset abrandolini:20250326_152429_elaborazione_forniture_ae stripComments:false runOnChange:true 
 
create or replace package ELABORAZIONE_FORNITURE_AE is
/******************************************************************************
 NOME:        ELABORAZIONE_FORNITURE_AE
 DESCRIZIONE: Elabora i record presenti nel file fornito dall'Agenzia delle
              Entrate, relativo ai versamenti effettuati con F24
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 007   08/05/2025  RV      #75455
                           Implementato gestione dati contabili per Codice Ente
 006   02/04/2025  RV      #79675
                           Sistemato gestione campo tipo_imposta per record 'M'
 005   10/02/2025  DM      #78468
                           Gestione date nulle in record G5
 004   05/02/2025  RV      #75644
                           Revisione per gestione Quadratura record D/M.
 003   08/10/2024  AB      Recuperato in modo corretto l'accertamento contabile
                           e ottimizzata la ricerca dello stesso
 002   26/09/2024  AB      Aggiunto il trattamento del record M per le Province
                           e aggiornato lo stato di documenti_caricati, solo per le province
 001   16/07/2024  AB      Aggiunto il trattamento del record D per le Province
 000   27/07/2021  VD      Prima emissione.
******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '6    02/04/2025';
  function VERSIONE
  return varchar2;
  function F_GET_TIPO_IMPOSTA
  ( p_tipo_tributo                varchar2
  , p_anno_rif                    number
  , p_cod_tributo                 varchar2
  ) return varchar2;
  procedure RECORD_G1
  ( p_documento_id                number
  );
  procedure RECORD_G2
  ( p_documento_id                number
  );
  procedure RECORD_G3
  ( p_documento_id                number
  );
  procedure RECORD_G4
  ( p_documento_id                number
  );
  procedure RECORD_G5
  ( p_documento_id                number
  );
  procedure RECORD_G9
  ( p_documento_id                number
  );
  procedure RECORD_D_M
  ( p_documento_id                number
  );
  function EMISSIONE_RIEPILOGO_PROVVISORI
  ( p_documento_id                number
  , p_data_fornitura              date
  , p_progr_fornitura             number
  , p_data_ripartizione           date
  , p_progr_ripartizione          number
  , p_data_bonifico               date
  , p_tipo_imposta                varchar2 default null
  ) return varchar2;
  function QUADRATURA_VERSAMENTI
  ( p_documento_id                number
  , p_data_fornitura              date
  , p_progr_fornitura             number
  , p_data_ripartizione           date
  , p_progr_ripartizione          number
  , p_data_bonifico               date
  , p_tipo_imposta                varchar2 default null
  ) return number;
  function F_EXISTS_RIEPILOGO
  ( p_documento_id                number
  , p_data_fornitura              date
  , p_progr_fornitura             number
  , p_data_ripartizione           date
  , p_progr_ripartizione          number
  , p_data_bonifico               date
  , p_tipo_imposta                varchar2 default null
  ) return number;
  function F_IMPORTI_AE_PROVVISORI
  ( p_numero_provvisorio          number
  , p_data_provvisorio            date
  ) return afc.t_ref_cursor;
  procedure ELABORA
  ( p_documento_id                number
  , p_messaggio               OUT varchar2
  );
end ELABORAZIONE_FORNITURE_AE;
/
create or replace package body ELABORAZIONE_FORNITURE_AE is
/******************************************************************************
 NOME:        ELABORAZIONE_FORNITURE_AE
 DESCRIZIONE: Elabora i record presenti nel file fornito dall'Agenzia delle
              Entrate, relativo ai versamenti effettuati con F24
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 007   08/05/2025  RV      #75455
                           Implementato gestione dati contabili per Codice Ente
 006   02/04/2025  RV      #79675
                           Sistemato gestione campo tipo_imposta per record 'M'
 005   10/02/2025  DM      #78468
                           Gestione date nulle in record G5
 004   05/02/2025  RV      #75644
                           Revisione per gestione Quadratura record D/M.
 003   08/10/2024  AB      Recuperato in modo corretto l'accertamento contabile
                           e ottimizzata la ricerca dello stesso
 002   26/09/2024  AB      Aggiunto il trattamento del record M per le Province
                           e aggiornato lo stato di documenti_caricati, solo per le province
 001   16/07/2024  AB      Aggiunto il trattamento del record D per le Province
 000   27/07/2021  VD      Prima emissione.
******************************************************************************/
  w_contatore                   number;
  w_contatore_tot               number;
  w_messaggio                   varchar2(4000);
-------------------------------------------------------------------------------
function VERSIONE return varchar2
is
begin
  return s_versione||'.'||s_revisione;
end versione;
-------------------------------------------------------------------------------------------------------------------
function F_GET_TIPO_IMPOSTA
( p_tipo_tributo                varchar2
, p_anno_rif                    number
, p_cod_tributo                 varchar2
) return varchar2 is
/******************************************************************************
 NOME:        F_GET_TIPO_IMPOSTA
 DESCRIZIONE: Determinazione del tipo imposta (O = Ordinario, V = Violazione)
              in base al codice tributo indicato nell'F24.
 PARAMETRI:   p_tipo_tributo
              p_anno_rif
              p_cod_tributo
 RETURN:      varchar2          O = Imposta ordinaria
                                V = Violazione
 NOTE:
******************************************************************************/
  w_tipo_imposta                varchar2(1);
begin
  begin
    select decode(tipo_codice
                 ,'C','O','V')
      into w_tipo_imposta
      from CODICI_F24
     where tipo_tributo     = p_tipo_tributo
       and descrizione_titr = f_descrizione_titr(p_tipo_tributo,p_anno_rif)
       and tributo_f24      = p_cod_tributo;
  exception
    when others then
      w_tipo_imposta := null;
  end;
  --
  return w_tipo_imposta;
  --
end F_GET_TIPO_IMPOSTA;
-------------------------------------------------------------------------------------------------------------------
procedure GET_DATI_PRATICA
( p_pratica                     number
, p_tipo_pratica                out varchar2
, p_data_pratica                out date
, p_stato_pratica               out varchar2
) is
/******************************************************************************
 NOME:        GET_DATI_PRATICA
 DESCRIZIONE: Restituisce i dati della pratica necessari per la determinazione
              dell'accertamento
 PARAMETRI:
 NOTE:
******************************************************************************/
  w_tipo_pratica                varchar2(1);
  w_data_pratica                date;
  w_stato_pratica               varchar2(2);
begin
  begin
    select tipo_pratica
         , data
         , stato_accertamento
      into w_tipo_pratica
         , w_data_pratica
         , w_stato_pratica
      from pratiche_tributo
     where pratica = p_pratica;
  exception
    when others then
      w_tipo_pratica  := null;
      w_data_pratica  := to_date(null);
      w_stato_pratica := null;
  end;
  --
  p_tipo_pratica  := w_tipo_pratica;
  p_data_pratica  := w_data_pratica;
  p_stato_pratica := w_stato_pratica;
end GET_DATI_PRATICA;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G1
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G1
 DESCRIZIONE: Trattamento righe con tipo record G1 (versamenti).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   04/04/2022  VD      Aggiunto parametro data ripartizione in ricerca
                           accertamento contabile.
******************************************************************************/
  w_tipo_imposta                varchar2(1);
  w_pratica                     number;
  w_tipo_pratica                varchar2(1);
  w_data_pratica                date;
  w_stato_pratica               varchar2(2);
  w_accertamento                varchar2(10);
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    , to_date(substr(wkta.dati,13,8),'yyyymmdd')        data_ripartizione
                    , to_number(substr(wkta.dati,21,2))                 progr_ripartizione
                    , to_date(substr(wkta.dati,23,8),'yyyymmdd')        data_bonifico
                    , to_number(substr(wkta.dati,31,6))                 progr_delega
                    , to_number(substr(wkta.dati,37,2))                 progr_riga
                    , to_number(substr(wkta.dati,39,5))                 cod_ente
                    , substr(wkta.dati,44,1)                            tipo_ente
                    , to_number(substr(wkta.dati,45,5))                 cab
                    , rtrim(substr(wkta.dati,50,16))                    cod_fiscale
                    , to_number(substr(wkta.dati,66,1))                 flag_err_cod_fiscale
                    , to_date(substr(wkta.dati,67,8),'yyyymmdd')        data_riscossione
                    , substr(wkta.dati,75,4)                            cod_ente_comunale
                    , substr(wkta.dati,79,4)                            cod_tributo
                    , to_number(substr(wkta.dati,83,1))                 flag_err_cod_tributo
                    , to_number(substr(wkta.dati,84,4))                 rateazione
                    , to_number(substr(wkta.dati,88,4))                 anno_rif
                    , to_number(substr(wkta.dati,92,1))                 flag_err_anno
                    , substr(wkta.dati,93,3)                            cod_valuta
                    , to_number(substr(wkta.dati,96,15)) / 100          importo_debito
                    , to_number(substr(wkta.dati,111,15)) / 100         importo_credito
                    , to_number(substr(wkta.dati,126,1))                ravvedimento
                    , to_number(substr(wkta.dati,127,1))                immobili_variati
                    , to_number(substr(wkta.dati,128,1))                acconto
                    , to_number(substr(wkta.dati,129,1))                saldo
                    , to_number(substr(wkta.dati,130,3))                num_fabbricati
                    , to_number(substr(wkta.dati,133,1))                flag_err_dati
                    , to_number(substr(wkta.dati,134,15)) / 100         detrazione
                    , trim(substr(wkta.dati,149,39))                    cognome_denominazione
                    , trim(substr(wkta.dati,188,16))                    cod_fiscale_orig
                    , trim(substr(wkta.dati,204,20))                    nome
                    , trim(substr(wkta.dati,224,1))                     sesso
                    , decode(replace(substr(wkta.dati,225,8),' ','0'),'00000000',to_date(null)
                            ,to_date(substr(trim(wkta.dati),225,8),'yyyymmdd')) data_nas
                    , substr(wkta.dati,233,25)                          comune_stato
                    , substr(wkta.dati,258,2)                           provincia
                    , substr(wkta.dati,260,1)                           tipo_imposta
                    , substr(wkta.dati,261,16)                          cod_fiscale_2
                    , substr(wkta.dati,277,2)                           cod_identificativo_2
                    , upper(rtrim(substr(wkta.dati,279,18)))            id_operazione
                    , decode(substr(wkta.dati,260,1)
                            ,'I', 'ICI'
                            ,'O', 'TOSAP'
                            ,'T', 'TARSU'
                            ,'S', null
                            ,'R', null
                            ,'A', 'TARSU'
                            ,'U', 'TASI'
                            ,'M', null
                            ) tipo_tributo
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G1'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    w_accertamento  := null;
    dbms_output.put_line('Riga: '||w_contatore);
    -- Si determina l'accertamento contabile
    if riga.tipo_tributo is not null then
       --dbms_output.put_line('w_tipo_imposta: '||w_tipo_imposta);
       -- Se l'id_operazione non è nullo si ricerca la pratica associata
       -- per determinare correttamente l'accertamento contabile
       if riga.id_operazione is not null then
          w_pratica := f_f24_pratica ( riga.cod_fiscale
                                     , riga.id_operazione
                                     , riga.data_riscossione
                                     , riga.tipo_tributo
                                     );
          --dbms_output.put_line('w_pratica: '||w_pratica);
          if nvl(w_pratica,0) > 0 then
             elaborazione_forniture_ae.get_dati_pratica ( w_pratica
                                                        , w_tipo_pratica
                                                        , w_data_pratica
                                                        , w_stato_pratica
                                                        );
          else
             if riga.id_operazione like 'LIQ%' then
                w_tipo_pratica := 'L';
             elsif riga.id_operazione like 'ACC%' then
                w_tipo_pratica := 'A';
             elsif riga.id_operazione like 'RAV%' then
                w_tipo_pratica := 'V';
             end if;
             w_data_pratica  := to_date(null);
             w_stato_pratica := null;
          end if;
          if riga.ravvedimento = 1 then
             w_tipo_imposta := 'O';
          else
             w_tipo_imposta := 'V';
          end if;
          if w_tipo_pratica is not null then
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , w_tipo_pratica
                                                                      , w_data_pratica
                                                                      , riga.cod_tributo
                                                                      , w_stato_pratica
                                                                      , riga.data_ripartizione
                                                                      );
              --dbms_output.put_line('w_accertamento: '||w_accertamento);
          end if;
       end if;
       -- Se l'id_operazione è nullo e non si tratta di ravvedimento,
       -- oppure se la ricerca per pratica non e' andata a buon fine
       -- si considera il versamento di imposta ordinaria
       if w_accertamento is null or riga.id_operazione is null then
          --dbms_output.put_line('Tipo tributo: '||riga.tipo_tributo);
          w_tipo_imposta := elaborazione_forniture_ae.f_get_tipo_imposta( riga.tipo_tributo
                                                                        , riga.anno_rif
                                                                        , riga.cod_tributo
                                                                        );
          if riga.ravvedimento = 0 and
             w_tipo_imposta = 'O' then
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , null
                                                                      , to_date(null)
                                                                      , riga.cod_tributo
                                                                      , null
                                                                      , riga.data_ripartizione
                                                                      );
          end if;
          --dbms_output.put_line('w_accertamento: '||w_accertamento);
          if riga.ravvedimento = 1 then
             w_tipo_imposta := 'O';
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , 'V'
                                                                      , to_date(null)
                                                                      , riga.cod_tributo
                                                                      , null
                                                                      , riga.data_ripartizione
                                                                      );
          end if;
       end if;
    end if;
    -- Si inserisce la riga nella tabella forniture_ae
    --dbms_output.put_line('Progressivo: '||riga.progressivo);
    begin
      insert into forniture_ae ( documento_id, progressivo, tipo_record,
                                 data_fornitura, progr_fornitura, data_ripartizione,
                                 progr_ripartizione, data_bonifico, progr_delega,
                                 progr_riga, cod_ente, tipo_ente,
                                 cab, cod_fiscale, flag_err_cod_fiscale,
                                 data_riscossione, cod_ente_comunale, cod_tributo,
                                 flag_err_cod_tributo, rateazione, anno_rif,
                                 flag_err_anno, cod_valuta, importo_debito,
                                 importo_credito, ravvedimento, immobili_variati,
                                 acconto, saldo, num_fabbricati,
                                 flag_err_dati, detrazione, cognome_denominazione,
                                 cod_fiscale_orig, nome, sesso,
                                 data_nas, comune_stato, provincia,
                                 tipo_imposta, cod_fiscale_2, cod_identificativo_2,
                                 id_operazione, tipo_tributo, descrizione_titr,
                                 anno_acc, numero_acc, importo_lordo
                                )
      values ( p_documento_id
             , riga.progressivo  --to_number(null)
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione
             , riga.progr_ripartizione
             , riga.data_bonifico
             , riga.progr_delega
             , riga.progr_riga
             , riga.cod_ente
             , riga.tipo_ente
             , riga.cab
             , riga.cod_fiscale
             , riga.flag_err_cod_fiscale
             , riga.data_riscossione
             , riga.cod_ente_comunale
             , riga.cod_tributo
             , riga.flag_err_cod_tributo
             , riga.rateazione
             , riga.anno_rif
             , riga.flag_err_anno
             , riga.cod_valuta
             , riga.importo_debito
             , riga.importo_credito
             , riga.ravvedimento
             , riga.immobili_variati
             , riga.acconto
             , riga.saldo
             , riga.num_fabbricati
             , riga.flag_err_dati
             , riga.detrazione
             , riga.cognome_denominazione
             , riga.cod_fiscale_orig
             , riga.nome
             , riga.sesso
             , riga.data_nas
             , riga.comune_stato
             , riga.provincia
             , riga.tipo_imposta
             , riga.cod_fiscale_2
             , riga.cod_identificativo_2
             , riga.id_operazione
             , riga.tipo_tributo
             , f_descrizione_titr(riga.tipo_tributo,riga.anno_rif)
             , to_number(ltrim(substr(w_accertamento,1,4),'0'))
             , to_number(ltrim(substr(w_accertamento,6,5),'0'))
             , riga.importo_debito - riga.importo_credito
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G1 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  --
  w_messaggio := 'Versamenti (G1): '||to_char(w_contatore)||';';
end RECORD_G1;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G2
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G2
 DESCRIZIONE: Trattamento righe con tipo record G2 (accrediti disposti).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    , to_date(substr(wkta.dati,13,8),'yyyymmdd')        data_ripartizione
                    , to_number(substr(wkta.dati,21,2))                 progr_ripartizione
                    , to_date(substr(wkta.dati,23,8),'yyyymmdd')        data_bonifico
                    -- filler(7)
                    , substr(wkta.dati,38,1)                            stato
                    , substr(wkta.dati,39,4)                            cod_ente_beneficiario
                    , substr(wkta.dati,43,3)                            cod_valuta
                    , to_number(substr(wkta.dati,46,15)) / 100          importo_accredito
                    , substr(wkta.dati,61,1)                            tipo_imposta
                    , to_date(trim(substr(wkta.dati,62,8)),'yyyymmdd')  data_mandato
                    , to_number(trim(substr(wkta.dati,70,2)))           progr_mandato
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G2'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    begin
      insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , data_ripartizione
                                , progr_ripartizione
                                , data_bonifico
                                , stato
                                , cod_ente_beneficiario
                                , cod_valuta
                                , importo_accredito
                                , tipo_imposta
                                , data_mandato
                                , progr_mandato
                                )
      values ( p_documento_id
             , riga.progressivo --to_number(null)
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione
             , riga.progr_ripartizione
             , riga.data_bonifico
             , riga.stato
             , riga.cod_ente_beneficiario
             , riga.cod_valuta
             , riga.importo_accredito
             , riga.tipo_imposta
             , riga.data_mandato
             , riga.progr_mandato
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G2 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  w_messaggio := w_messaggio||chr(10)||'Accrediti disposti (G2): '||to_char(w_contatore)||';';
end RECORD_G2;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G3
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G3
 DESCRIZIONE: Trattamento righe con tipo record G3 (recupero saldi negativi).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                   progressivo
                    , substr(wkta.dati,1,2)                              tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')          data_fornitura
                    , to_number(substr(wkta.dati,11,2))                  progr_fornitura
                    , to_date(substr(wkta.dati,13,8),'yyyymmdd')         data_ripartizione
                    , to_number(substr(wkta.dati,21,2))                  progr_ripartizione
                    , decode(substr(wkta.dati,23,8)
                            ,'99999999',to_date(null)
                            ,to_date(substr(wkta.dati,23,8),'yyyymmdd')) data_bonifico
                    -- filler(8)
                    , substr(wkta.dati,39,4)                             cod_ente_comunale
                    , substr(wkta.dati,43,3)                             cod_valuta
                    , to_number(substr(wkta.dati,46,15)) / 100           importo_recupero
                    , to_number(substr(wkta.dati,61,6))                  periodo_ripartizione_orig
                    , to_number(substr(wkta.dati,67,4))                  progr_ripartizione_orig
                    , decode(substr(wkta.dati,71,8)
                            ,'00000000',to_date(null)
                            ,to_date(substr(wkta.dati,71,8),'yyyymmdd')) data_bonifico_orig
                    , substr(wkta.dati,79,1)                             tipo_imposta
                    , substr(wkta.dati,80,3)                             tipo_recupero
                    , substr(wkta.dati,83,200)                           des_recupero
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G3'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    begin
      insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , data_ripartizione
                                , progr_ripartizione
                                , data_bonifico
                                , cod_ente_comunale
                                , cod_valuta
                                , importo_recupero
                                , periodo_ripartizione_orig
                                , progr_ripartizione_orig
                                , data_bonifico_orig
                                , tipo_imposta
                                , tipo_recupero
                                , des_recupero
                                )
      values ( p_documento_id
             , riga.progressivo --to_number(null) --
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione
             , riga.progr_ripartizione
             , riga.data_bonifico
             , riga.cod_ente_comunale
             , riga.cod_valuta
             , riga.importo_recupero
             , riga.periodo_ripartizione_orig
             , riga.progr_ripartizione_orig
             , riga.data_bonifico_orig
             , riga.tipo_imposta
             , riga.tipo_recupero
             , riga.des_recupero
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G3 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  w_messaggio := w_messaggio||chr(10)||'Recuperi saldi negativi (G3): '||to_char(w_contatore)||';';
end RECORD_G3;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G4
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G4
 DESCRIZIONE: Trattamento righe con tipo record G4 (anticipo fondi di bilancio).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    , to_date(substr(wkta.dati,13,8),'yyyymmdd')        data_ripartizione
                    , to_number(substr(wkta.dati,21,2))                 progr_ripartizione
                    , to_date(substr(wkta.dati,23,8),'yyyymmdd')        data_bonifico
                    -- filler(8)
                    , substr(wkta.dati,39,4)                            cod_ente_comunale
                    , substr(wkta.dati,43,3)                            cod_valuta
                    , to_number(substr(wkta.dati,46,15)) / 100          importo_anticipazione
                    , substr(wkta.dati,61,1)                            tipo_imposta
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G4'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    begin
      insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , data_ripartizione
                                , progr_ripartizione
                                , data_bonifico
                                , cod_ente_comunale
                                , cod_valuta
                                , importo_anticipazione
                                , tipo_imposta
                                )
      values ( p_documento_id
             , riga.progressivo  --to_number(null)
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione
             , riga.progr_ripartizione
             , riga.data_bonifico
             , riga.cod_ente_comunale
             , riga.cod_valuta
             , riga.importo_anticipazione
             , riga.tipo_imposta
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G4 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  w_messaggio := w_messaggio||chr(10)||'Anticipi fondi di bilancio (G4): '||to_char(w_contatore)||'; ';
end RECORD_G4;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G5
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G5
 DESCRIZIONE: Trattamento righe con tipo record G5 (identificazione accredito).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    -- filler(25)
                    , substr(wkta.dati,38,1)                            stato
                    , substr(wkta.dati,39,4)                            cod_ente_comunale
                    , substr(wkta.dati,43,3)                            cod_valuta
                    , to_number(substr(wkta.dati,46,15)) / 100          importo_accredito
                    , to_number(substr(wkta.dati,61,11))                cro
                    , to_date(substr(wkta.dati,72,8),'yyyymmdd')        data_accreditamento
                    , to_date(substr(wkta.dati,80,8),'yyyymmdd')        data_ripartizione_orig
                    , to_number(substr(wkta.dati,88,2))                 progr_ripartizione_orig
                    , to_date(substr(wkta.dati,90,8),'yyyymmdd')        data_bonifico_orig
                    , substr(wkta.dati,98,1)                            tipo_imposta
                    , substr(wkta.dati,99,34)                           iban
                    , substr(wkta.dati,133,3)                           sezione_conto_tu
                    , to_number(substr(wkta.dati,136,6))                numero_conto_tu
                    , to_number(substr(wkta.dati,142,14))               cod_movimento
                    , substr(wkta.dati,156,45)                          des_movimento
                    , decode(replace(substr(wkta.dati,201,8),' ','0'),'00000000',to_date(null)
                            ,to_date(substr(trim(wkta.dati),201,8),'yyyymmdd')) data_storno_scarto
                    , decode(replace(substr(wkta.dati,209,8),' ','0'),'00000000',to_date(null)
                            ,to_date(substr(trim(wkta.dati),209,8),'yyyymmdd')) data_elaborazione_nuova
                    , to_number(trim(substr(wkta.dati,217,2)))          progr_elaborazione_nuova
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G5'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    begin
      insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , stato
                                , cod_ente_comunale
                                , cod_valuta
                                , importo_accredito
                                , cro
                                , data_accreditamento
                                , data_ripartizione_orig
                                , progr_ripartizione_orig
                                , data_bonifico_orig
                                , tipo_imposta
                                , iban
                                , sezione_conto_tu
                                , numero_conto_tu
                                , cod_movimento
                                , des_movimento
                                , data_storno_scarto
                                , data_elaborazione_nuova
                                , progr_elaborazione_nuova
                                )
      values ( p_documento_id
             , riga.progressivo
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.stato
             , riga.cod_ente_comunale
             , riga.cod_valuta
             , riga.importo_accredito
             , riga.cro
             , riga.data_accreditamento
             , riga.data_ripartizione_orig
             , riga.progr_ripartizione_orig
             , riga.data_bonifico_orig
             , riga.tipo_imposta
             , riga.iban
             , riga.sezione_conto_tu
             , riga.numero_conto_tu
             , riga.cod_movimento
             , riga.des_movimento
             , riga.data_storno_scarto
             , riga.data_elaborazione_nuova
             , riga.progr_elaborazione_nuova
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G5 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  w_messaggio := w_messaggio||chr(10)||'Identificazioni accrediti (G5): '||to_char(w_contatore)||';';
end RECORD_G5;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_G9
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_G9
 DESCRIZIONE: Trattamento righe con tipo record G9 (annullamento delega).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
begin
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    -- filler(26)
                    , to_date(substr(wkta.dati,39,8),'yyyymmdd')        data_ripartizione_orig
                    , to_number(substr(wkta.dati,47,2))                 progr_ripartizione_orig
                    , to_date(substr(wkta.dati,49,8),'yyyymmdd')        data_bonifico_orig
                    , to_number(substr(wkta.dati,57,5))                 cod_ente
                    -- filler(5)
                    , rtrim(substr(wkta.dati,67,16))                    cod_fiscale
                    , to_date(substr(wkta.dati,83,8),'yyyymmdd')        data_riscossione
                    , substr(wkta.dati,91,4)                            cod_ente_comunale
                    , substr(wkta.dati,95,4)                            cod_tributo
                    , to_number(substr(wkta.dati,99,4))                 anno_rif
                    , substr(wkta.dati,103,3)                           cod_valuta
                    , to_number(substr(wkta.dati,106,15)) / 100         importo_debito
                    , to_number(substr(wkta.dati,121,15)) / 100         importo_credito
                    , substr(wkta.dati,136,1)                           tipo_operazione
                    , to_date(trim(substr(wkta.dati,137,8)),'yyyymmdd') data_operazione
                    , substr(wkta.dati,145,1)                           tipo_imposta
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G9'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    begin
      insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , data_ripartizione_orig
                                , progr_ripartizione_orig
                                , data_bonifico_orig
                                , cod_ente
                                , cod_fiscale
                                , data_riscossione
                                , cod_ente_comunale
                                , cod_tributo
                                , anno_rif
                                , cod_valuta
                                , importo_debito
                                , importo_credito
                                , tipo_operazione
                                , data_operazione
                                , tipo_imposta
                                )
      values ( p_documento_id
             , riga.progressivo
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione_orig
             , riga.progr_ripartizione_orig
             , riga.data_bonifico_orig
             , riga.cod_ente
             , riga.cod_fiscale
             , riga.data_riscossione
             , riga.cod_ente_comunale
             , riga.cod_tributo
             , riga.anno_rif
             , riga.cod_valuta
             , riga.importo_debito
             , riga.importo_credito
             , riga.tipo_operazione
             , riga.data_operazione
             , riga.tipo_imposta
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G9 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  w_messaggio := w_messaggio||chr(10)||'Annullamenti deleghe (G9): '||to_char(w_contatore)||';';
end RECORD_G9;
-------------------------------------------------------------------------------------------------------------------
procedure RECORD_D_M
( p_documento_id                number
) is
/******************************************************************************
 NOME:        RECORD_D_M  Province
 DESCRIZIONE: Trattamento righe con tipo record D e M Versamenti alle province.
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   24/09/2024  AB      Trattamento tipo_record M
 001   15/07/2024  AB      Prima emissione.
******************************************************************************/
  w_tipo_imposta                varchar2(1);
  w_pratica                     number;
  w_tipo_pratica                varchar2(1);
  w_data_pratica                date;
  w_stato_pratica               varchar2(2);
  w_accertamento                varchar2(10);

-- recuperato da carica_anagrafe_esterna
  w_titolo_documento          number;
  w_documento_blob            blob;
  w_documento_clob            clob;
  dest_offset                 number := 1;
  src_offset                  number := 1;
  amount                      integer := DBMS_LOB.lobmaxsize;
  blob_csid                   number  := DBMS_LOB.default_csid;
  lang_ctx                    integer := DBMS_LOB.default_lang_ctx;
  warning                     integer;

  w_stato                     number;
  w_dimensione_file           number;
  w_contarighe                number := 0;
  w_posizione                 number;
  w_posizione_old             number;
  w_step                      number(2);

  w_riga                  varchar2 (32767);
  w_campo                 varchar2 (32767);
  w_separatore            varchar2(1) := ';';
  w_num_separatori        number;
  w_lunghezza_riga        number;
  w_inizio                number := 0;
  w_fine                  number;
  w_occorrenza            number;
  w_tipo_record           varchar2(1);
  w_data_fornitura        date;
  w_progr_fornitura       number;

  w_righe_caricate        number := 0;
  w_conta_anomalie        number := 0;

  rec_fae                 forniture_ae%rowtype;

  w_errore                varchar(2000) := NULL;
  errore                  exception;
  sql_errm                varchar2(100);
begin
/*
  w_contatore := 0;
  for riga in (select wkta.progressivo                                  progressivo
                    , substr(wkta.dati,1,2)                             tipo_record
                    , to_date(substr(wkta.dati,3,8),'yyyymmdd')         data_fornitura
                    , to_number(substr(wkta.dati,11,2))                 progr_fornitura
                    , to_date(substr(wkta.dati,13,8),'yyyymmdd')        data_ripartizione
                    , to_number(substr(wkta.dati,21,2))                 progr_ripartizione
                    , to_date(substr(wkta.dati,23,8),'yyyymmdd')        data_bonifico
                    , to_number(substr(wkta.dati,31,6))                 progr_delega
                    , to_number(substr(wkta.dati,37,2))                 progr_riga
                    , to_number(substr(wkta.dati,39,5))                 cod_ente
                    , substr(wkta.dati,44,1)                            tipo_ente
                    , to_number(substr(wkta.dati,45,5))                 cab
                    , rtrim(substr(wkta.dati,50,16))                    cod_fiscale
                    , to_number(substr(wkta.dati,66,1))                 flag_err_cod_fiscale
                    , to_date(substr(wkta.dati,67,8),'yyyymmdd')        data_riscossione
                    , substr(wkta.dati,75,4)                            cod_ente_comunale
                    , substr(wkta.dati,79,4)                            cod_tributo
                    , to_number(substr(wkta.dati,83,1))                 flag_err_cod_tributo
                    , to_number(substr(wkta.dati,84,4))                 rateazione
                    , to_number(substr(wkta.dati,88,4))                 anno_rif
                    , to_number(substr(wkta.dati,92,1))                 flag_err_anno
                    , substr(wkta.dati,93,3)                            cod_valuta
                    , to_number(substr(wkta.dati,96,15)) / 100          importo_debito
                    , to_number(substr(wkta.dati,111,15)) / 100         importo_credito
                    , to_number(substr(wkta.dati,126,1))                ravvedimento
                    , to_number(substr(wkta.dati,127,1))                immobili_variati
                    , to_number(substr(wkta.dati,128,1))                acconto
                    , to_number(substr(wkta.dati,129,1))                saldo
                    , to_number(substr(wkta.dati,130,3))                num_fabbricati
                    , to_number(substr(wkta.dati,133,1))                flag_err_dati
                    , to_number(substr(wkta.dati,134,15)) / 100         detrazione
                    , trim(substr(wkta.dati,149,39))                    cognome_denominazione
                    , trim(substr(wkta.dati,188,16))                    cod_fiscale_orig
                    , trim(substr(wkta.dati,204,20))                    nome
                    , trim(substr(wkta.dati,224,1))                     sesso
                    , decode(replace(substr(wkta.dati,225,8),' ','0'),'00000000',to_date(null)
                            ,to_date(substr(trim(wkta.dati),225,8),'yyyymmdd')) data_nas
                    , substr(wkta.dati,233,25)                          comune_stato
                    , substr(wkta.dati,258,2)                           provincia
                    , substr(wkta.dati,260,1)                           tipo_imposta
                    , substr(wkta.dati,261,16)                          cod_fiscale_2
                    , substr(wkta.dati,277,2)                           cod_identificativo_2
                    , upper(rtrim(substr(wkta.dati,279,18)))            id_operazione
                    , decode(substr(wkta.dati,260,1)
                            ,'I', 'ICI'
                            ,'O', 'TOSAP'
                            ,'T', 'TARSU'
                            ,'S', null
                            ,'R', null
                            ,'A', 'TARSU'
                            ,'U', 'TASI'
                            ,'M', null
                            ) tipo_tributo
                 from wrk_tras_anci         wkta
                where wkta.anno             = 2
                  and substr(wkta.dati,1,2) = 'G1'
                order by wkta.progressivo)
  loop
    w_contatore     := w_contatore + 1;
    w_contatore_tot := w_contatore_tot + 1;
    w_accertamento  := null;
    dbms_output.put_line('Riga: '||w_contatore);
    -- Si determina l'accertamento contabile
    if riga.tipo_tributo is not null then
       --dbms_output.put_line('w_tipo_imposta: '||w_tipo_imposta);
       -- Se l'id_operazione non è nullo si ricerca la pratica associata
       -- per determinare correttamente l'accertamento contabile
       if riga.id_operazione is not null then
          w_pratica := f_f24_pratica ( riga.cod_fiscale
                                     , riga.id_operazione
                                     , riga.data_riscossione
                                     , riga.tipo_tributo
                                     );
          --dbms_output.put_line('w_pratica: '||w_pratica);
          if nvl(w_pratica,0) > 0 then
             elaborazione_forniture_ae.get_dati_pratica ( w_pratica
                                                        , w_tipo_pratica
                                                        , w_data_pratica
                                                        , w_stato_pratica
                                                        );
          else
             if riga.id_operazione like 'LIQ%' then
                w_tipo_pratica := 'L';
             elsif riga.id_operazione like 'ACC%' then
                w_tipo_pratica := 'A';
             elsif riga.id_operazione like 'RAV%' then
                w_tipo_pratica := 'V';
             end if;
             w_data_pratica  := to_date(null);
             w_stato_pratica := null;
          end if;
          if riga.ravvedimento = 1 then
             w_tipo_imposta := 'O';
          else
             w_tipo_imposta := 'V';
          end if;
          if w_tipo_pratica is not null then
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , w_tipo_pratica
                                                                      , w_data_pratica
                                                                      , riga.cod_tributo
                                                                      , w_stato_pratica
                                                                      , riga.data_ripartizione
                                                                      );
              --dbms_output.put_line('w_accertamento: '||w_accertamento);
          end if;
       end if;
       -- Se l'id_operazione è nullo e non si tratta di ravvedimento,
       -- oppure se la ricerca per pratica non e' andata a buon fine
       -- si considera il versamento di imposta ordinaria
       if w_accertamento is null or riga.id_operazione is null then
          --dbms_output.put_line('Tipo tributo: '||riga.tipo_tributo);
          w_tipo_imposta := elaborazione_forniture_ae.f_get_tipo_imposta( riga.tipo_tributo
                                                                        , riga.anno_rif
                                                                        , riga.cod_tributo
                                                                        );
          if riga.ravvedimento = 0 and
             w_tipo_imposta = 'O' then
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , null
                                                                      , to_date(null)
                                                                      , riga.cod_tributo
                                                                      , null
                                                                      , riga.data_ripartizione
                                                                      );
          end if;
          --dbms_output.put_line('w_accertamento: '||w_accertamento);
          if riga.ravvedimento = 1 then
             w_tipo_imposta := 'O';
             w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( riga.tipo_tributo
                                                                      , riga.anno_rif
                                                                      , w_tipo_imposta
                                                                      , 'V'
                                                                      , to_date(null)
                                                                      , riga.cod_tributo
                                                                      , null
                                                                      , riga.data_ripartizione
                                                                      );
          end if;
       end if;
    end if;
*/

   begin
        select titolo_documento, contenuto, stato
          into w_titolo_documento, w_documento_blob, w_stato
          from documenti_caricati doca
         where doca.documento_id = p_documento_id
        ;
   EXCEPTION
          when others then
             raise_application_error
                 (-20999,'Errore in ricerca DOCUMENTI_CARICATI '||
                         '('||SQLERRM||')');
   end;

   if w_stato in (1,15,2) then
     -- Verifica dimensione file caricato
     w_dimensione_file:= DBMS_LOB.GETLENGTH(w_documento_blob);
--dbms_output.put_line('dentro in (1,15) - dim file '||w_dimensione_file );
     if nvl(w_dimensione_file,0) = 0 then
        w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
        raise errore;
     end if;

     -- Trasformazione in CLOB
     begin
       DBMS_LOB.createtemporary (lob_loc =>   w_documento_clob
                                ,cache =>     true
                                ,dur =>       DBMS_LOB.session
                                );
       DBMS_LOB.converttoclob (w_documento_clob
                              ,w_documento_blob
                              ,amount
                              ,dest_offset
                              ,src_offset
                              ,blob_csid
                              ,lang_ctx
                              ,warning
                              );
     exception
           when others then
             w_errore :=
               'Errore in trasformazione Blob in Clob  (' || sqlerrm || ')';
             raise errore;
     end;
         --
         w_contarighe          := 0;
         w_posizione_old       := 1;
         w_posizione           := 1;
         --
    --     a_messaggio := 'Caricate '|| to_char(w_righe_caricate) ||' righe di versamenti.';
   end if;

   IF w_titolo_documento = 38 then -- Fornitura F24 per province
        begin
            delete forniture_ae
             where documento_id = p_documento_id
            ;
        exception
               when others then
                 w_errore :=
                   'Errore in Eliminazione FORNITURE_AE (id_documento: '||p_documento_id ||') - ('|| sqlerrm || ')';
                 raise errore;
        end;

--dbms_output.put_line('dentro = 35 - dim file '||w_dimensione_file );
     w_tipo_record := null;
     while w_posizione < w_dimensione_file
     loop
       w_errore := null;
       w_posizione     := instr (w_documento_clob, chr (10), w_posizione_old);
       w_riga          := substr (w_documento_clob, w_posizione_old, w_posizione-w_posizione_old+1);
       w_posizione_old := w_posizione + 1;
--    dbms_output.put_line('w_posizione: '||w_posizione||'w_posizione_old: '||w_posizione_old||'w_riga: '||w_riga);

       -- Determinazione numero di separatori presenti nella riga
       w_num_separatori := length(w_riga) - length(replace(w_riga,w_separatore,''));
       w_lunghezza_riga := length(w_riga);
       w_inizio     := 1;
       w_occorrenza := 1;
       rec_fae      := null;
     begin
         while w_occorrenza <= w_num_separatori
         loop
           w_fine := instr(w_riga,w_separatore,w_inizio,1);
           w_campo := rtrim(substr(w_riga,w_inizio,w_fine - w_inizio));
           w_campo := replace(w_campo,'#N/D','');  -- AB 19/05/2023 c'era questo valore in un codice via a Castelfiorentino

           if w_occorrenza = 1 and w_campo not in ('A','D','M') then
              w_occorrenza := w_num_separatori;
           elsif (w_occorrenza = 1 and w_campo = 'A') or
               nvl(w_tipo_record,'A') = 'A' then
               if w_occorrenza = 1 then
                  w_tipo_record := 'A';
               elsif w_occorrenza = 2 then
                  w_data_fornitura := to_date(w_campo,'yyyymmdd');
--    dbms_output.put_line('Data fornitura.1: '||w_data_fornitura);
               elsif w_occorrenza = 3 then
                  w_progr_fornitura := to_number(w_campo);
               elsif w_occorrenza = 4 then
                  w_tipo_record := 'D';
                  w_occorrenza := w_num_separatori;
               end if;
    dbms_output.put_line('Data fornitura: '||w_data_fornitura||' w_tipo_record '||w_tipo_record||
                         ' w_progr_fornitura '|| w_progr_fornitura);
           elsif (w_occorrenza = 1 and w_campo = 'D') or  -- trattamento record D
                 (w_occorrenza > 1 and nvl(w_tipo_record,'A') = 'D') then
               if w_occorrenza = 1 then
--    dbms_output.put_line('w_contarighe: '||w_contarighe||' Data fornitura: '||w_data_fornitura||' w_tipo_record '||w_tipo_record);
                  rec_fae.tipo_record := 'D';--w_campo;
               elsif w_occorrenza = 2 then
                  rec_fae.data_ripartizione := to_date(w_campo,'yyyy-mm-dd');
               elsif w_occorrenza = 3 then
                  rec_fae.progr_ripartizione := to_number(w_campo);
               elsif w_occorrenza = 4 then
                  rec_fae.cod_provincia := w_campo;
               elsif w_occorrenza = 5 then
                  rec_fae.cod_ente := w_campo;
               elsif w_occorrenza = 6 then
                  rec_fae.data_bonifico := to_date(w_campo,'yyyy-mm-dd');
               elsif w_occorrenza = 7 then
                  null;
                  --rec_fae.progr_trasmissione := to_number(w_campo);
               elsif w_occorrenza = 8 then
                  rec_fae.progr_delega := w_campo;
               elsif w_occorrenza = 9 then
                  null;
                  --rec_fae.progr_modello := w_campo;
               elsif w_occorrenza = 10 then
                  null;
                  --rec_fae.tipo_modello := w_campo;
               elsif w_occorrenza = 11 then
                  rec_fae.cod_ente_comunale := w_campo;
               elsif w_occorrenza = 12 then
                  rec_fae.cod_tributo := w_campo;
               elsif w_occorrenza = 13 then
                  rec_fae.cod_valuta := w_campo;
               elsif w_occorrenza = 14 then
                  rec_fae.importo_debito := to_number(w_campo)/100;
               elsif w_occorrenza = 15 then
                  rec_fae.importo_credito := to_number(w_campo)/100;
               elsif w_occorrenza = 16 then
                  rec_fae.num_fabbricati := w_campo;
               elsif w_occorrenza = 17 then
                  rec_fae.rateazione  := w_campo;
               elsif w_occorrenza = 18 then
                  rec_fae.anno_rif := to_number(w_campo);
               end if;
           elsif (w_occorrenza = 1 and w_campo = 'M') or  -- trattamento record M
                 (w_occorrenza > 1 and nvl(w_tipo_record,'A') = 'M') then
               w_tipo_record := 'M';
               if w_occorrenza = 1 then
--    dbms_output.put_line('w_contarighe: '||w_contarighe||' Data fornitura: '||w_data_fornitura||' w_tipo_record '||w_tipo_record);
                  rec_fae.tipo_record := 'M';--w_campo;
               elsif w_occorrenza = 2 then
                  rec_fae.data_ripartizione := to_date(w_campo,'yyyy-mm-dd');
               elsif w_occorrenza = 3 then
                  rec_fae.progr_ripartizione := to_number(w_campo);
               elsif w_occorrenza = 4 then
                  rec_fae.data_bonifico := to_date(w_campo,'yyyy-mm-dd');
                  rec_fae.anno_rif := substr(w_campo,1,4);
               elsif w_occorrenza = 5 then
                  -- #79675 : Aggiunto NVL nel caso non sia compilato
                  rec_fae.tipo_imposta := nvl(w_campo,'TEF');
               elsif w_occorrenza = 6 then
                  rec_fae.cod_provincia := w_campo;
               elsif w_occorrenza = 7 then
                  rec_fae.numero_conto_tu := w_campo;
               elsif w_occorrenza = 8 then
                  rec_fae.cod_valuta := w_campo;
               elsif w_occorrenza = 9 then
                  rec_fae.importo_accredito := to_number(w_campo)/100;
               elsif w_occorrenza = 10 then
                  rec_fae.data_mandato := to_date(w_campo,'yyyy-mm-dd');
               elsif w_occorrenza = 11 then
                  rec_fae.cod_movimento  := w_campo;
               end if;
           end if;
           w_occorrenza := w_occorrenza + 1;
           w_inizio := instr(w_riga,w_separatore,w_inizio,1) + 1;
         end loop;
     exception
          when others then
            w_errore := substr('Riga : '||w_riga||' - '||sqlerrm,1,2000);
            raise errore;
     end;
       w_contarighe := w_contarighe + 1;
       w_contatore_tot := w_contatore_tot + 1;

/*       if w_errore is null then
          if rec_fae.idindividuo is not null then
             --
             -- Controllo esistenza record
             --
begin
select 'Dati gia'' inseriti'
into w_errore
from anamin_lac
where idindividuo = rec_fae.idindividuo;
exception
               when no_data_found then
                 w_errore := null;
when too_many_rows then
                 w_errore := 'Dati gia'' inseriti';
end;
*/
         if w_errore is null
         and rec_fae.tipo_record in ('D','M') then
            w_righe_caricate        := w_righe_caricate + 1;
            rec_fae.documento_id    := p_documento_id;
            rec_fae.progressivo     := w_righe_caricate;
            rec_fae.data_fornitura  := w_data_fornitura;
            rec_fae.progr_fornitura := w_progr_fornitura;
            rec_fae.tipo_tributo    := 'TARSU';
            if rec_fae.tipo_record != 'M' then
-- #79675 : Per i record 'M' ci serve il valore originale, altrimenti da problemi di quadratura perchè non trova i record
              rec_fae.tipo_imposta  := case
                                          when rec_fae.cod_tributo = 'TEFA' then 'TEF'
                                          else null
                                       end ;
            end if;
            rec_fae.descrizione_titr := case
                                          when rec_fae.cod_tributo = 'TEFA' then 'TEFA'
                                          else f_descrizione_titr(rec_fae.tipo_tributo ,rec_fae.anno_rif)
                                        end ;
            rec_fae.importo_lordo   := rec_fae.importo_debito - rec_fae.importo_credito;

--            w_tipo_imposta := elaborazione_forniture_ae.f_get_tipo_imposta( rec_fae.tipo_tributo
--                                                                          , rec_fae.anno_rif
--                                                                          , rec_fae.cod_tributo
--                                                                          );
            if nvl(rec_fae.tipo_imposta,'TEF') = 'TEF' and
               rec_fae.cod_tributo = 'TEFA' then
               w_tipo_imposta := 'O';
               -- 1: Cerca corrispondenza esatta per Codice Ente
               w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( rec_fae.tipo_tributo
                                                                        , rec_fae.anno_rif
                                                                        , w_tipo_imposta
                                                                        , null
                                                                        , to_date(null)
                                                                        , rec_fae.cod_tributo
                                                                        , null
                                                                        , rec_fae.data_ripartizione
                                                                        , null
                                                                        , null
                                                                        , rec_fae.cod_ente_comunale
                                                                        );
               --
               if (w_accertamento is null) or (length(w_accertamento) < 3) then
                 -- 2: Nessuna corrispondenza con Codice Ente, cerca senza
                 w_accertamento := dati_contabili_pkg.f_get_acc_contabile ( rec_fae.tipo_tributo
                                                                          , rec_fae.anno_rif
                                                                          , w_tipo_imposta
                                                                          , null
                                                                          , to_date(null)
                                                                          , rec_fae.cod_tributo
                                                                          , null
                                                                          , rec_fae.data_ripartizione
                                                                          , null
                                                                          , null
                                                                          , null
                                                                          );
               end if;
               --
               if w_accertamento = '/' then
                 w_accertamento := '';
               end if;
               --
               rec_fae.anno_acc    := to_number(ltrim(substr(w_accertamento,1,4),'0'));
               rec_fae.numero_acc  := to_number(ltrim(substr(w_accertamento,6,5),'0'));
            end if;
--    dbms_output.put_line('fuori: '||rec_fae.tipo_imposta||' '||rec_fae.cod_tributo||' w_tipo_imposta '||w_tipo_imposta||' '||rec_fae.descrizione_titr);
    --dbms_output.put_line('w_accertamnteo '||w_accertamento||' fae.tipo_imposta '||rec_fae.tipo_imposta||' w_tipo_imposta '||w_tipo_imposta||' '||rec_fae.descrizione_titr);
            begin
                insert into forniture_ae
                values rec_fae;
                exception
                  when others then
                    w_errore := substr('Ins. FORNITURE_AE: '
                             ||') - '
                             || sqlerrm,1,2000);
                    raise errore;
            end;

        end if;
     end loop;
   end if;

-- gia fatto sopra
/*
    -- Si inserisce la riga nella tabella forniture_ae
    --dbms_output.put_line('Progressivo: '||riga.progressivo);
    begin
      insert into forniture_ae ( documento_id, progressivo, tipo_record,
                                 data_fornitura, progr_fornitura, data_ripartizione,
                                 progr_ripartizione, data_bonifico, progr_delega,
                                 progr_riga, cod_ente, tipo_ente,
                                 cab, cod_fiscale, flag_err_cod_fiscale,
                                 data_riscossione, cod_ente_comunale, cod_tributo,
                                 flag_err_cod_tributo, rateazione, anno_rif,
                                 flag_err_anno, cod_valuta, importo_debito,
                                 importo_credito, ravvedimento, immobili_variati,
                                 acconto, saldo, num_fabbricati,
                                 flag_err_dati, detrazione, cognome_denominazione,
                                 cod_fiscale_orig, nome, sesso,
                                 data_nas, comune_stato, provincia,
                                 tipo_imposta, cod_fiscale_2, cod_identificativo_2,
                                 id_operazione, tipo_tributo, descrizione_titr,
                                 anno_acc, numero_acc, importo_lordo
                                )
      values ( p_documento_id
             , riga.progressivo  --to_number(null)
             , riga.tipo_record
             , riga.data_fornitura
             , riga.progr_fornitura
             , riga.data_ripartizione
             , riga.progr_ripartizione
             , riga.data_bonifico
             , riga.progr_delega
             , riga.progr_riga
             , riga.cod_ente
             , riga.tipo_ente
             , riga.cab
             , riga.cod_fiscale
             , riga.flag_err_cod_fiscale
             , riga.data_riscossione
             , riga.cod_ente_comunale
             , riga.cod_tributo
             , riga.flag_err_cod_tributo
             , riga.rateazione
             , riga.anno_rif
             , riga.flag_err_anno
             , riga.cod_valuta
             , riga.importo_debito
             , riga.importo_credito
             , riga.ravvedimento
             , riga.immobili_variati
             , riga.acconto
             , riga.saldo
             , riga.num_fabbricati
             , riga.flag_err_dati
             , riga.detrazione
             , riga.cognome_denominazione
             , riga.cod_fiscale_orig
             , riga.nome
             , riga.sesso
             , riga.data_nas
             , riga.comune_stato
             , riga.provincia
             , riga.tipo_imposta
             , riga.cod_fiscale_2
             , riga.cod_identificativo_2
             , riga.id_operazione
             , riga.tipo_tributo
             , f_descrizione_titr(riga.tipo_tributo,riga.anno_rif)
             , to_number(ltrim(substr(w_accertamento,1,4),'0'))
             , to_number(ltrim(substr(w_accertamento,6,5),'0'))
             , riga.importo_debito - riga.importo_credito
             );
    exception
      when others then
        raise_application_error(-20999,'Ins. FORNITURE_AE tipo G1 ('||p_documento_id||'/'||riga.progressivo||') - '||sqlerrm);
    end;
  end loop;
  --
*/
  w_messaggio := 'Versamenti (D e M): '||to_char(w_righe_caricate)||';';
  EXCEPTION
     WHEN ERRORE THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
     WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,'Riga: '||w_righe_caricate||' '||to_char(SQLCODE)||' - '||substr(SQLERRM,1,200));
end RECORD_D_M;
-------------------------------------------------------------------------------------------------------------------
function EMISSIONE_RIEPILOGO_PROVVISORI
( p_documento_id                number
, p_data_fornitura              date
, p_progr_fornitura             number
, p_data_ripartizione           date
, p_progr_ripartizione          number
, p_data_bonifico               date
, p_tipo_imposta                varchar2 default null
) return varchar2 is
/******************************************************************************
 NOME:        EMISSIONE_RIEPILOGO_PROVVISORI
 DESCRIZIONE: Inserisce righe con tipo record R2 per memorizzare gli importi
              suddivisi per sospeso contabile.
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
              p_tipo_tributo    Tipo tributo da trattare.
                                Null = tutti i tipi tributo.
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   05/02/2025  RV      #75644
                           Revisione per gestione Quadratura record D/M.
 001   20/06/2022  VD      In attesa della creazione di un apposito attributo
                           nella tabella CODICI_F24, si escludono dal trattamento
                           i codici tributo relativi all'erario
                           (IMU - 3915, 3917, 3919, 3925)
******************************************************************************/
  w_messaggio                   varchar2(2000) := '';
  w_progressivo                 number;
  errore                        exception;
begin
  -- Si eliminano le eventuali righe di riepilogo gia' enesse
  begin
    delete from forniture_ae m
     where documento_id = p_documento_id
       and tipo_record  = 'R2'
       and m.data_fornitura = nvl(p_data_fornitura,m.data_fornitura)
       and m.progr_fornitura = nvl(p_progr_fornitura,m.progr_fornitura)
       and m.data_ripartizione = nvl(p_data_ripartizione,m.data_ripartizione)
       and m.progr_ripartizione = nvl(p_progr_ripartizione,m.progr_ripartizione)
       and m.data_bonifico = nvl(p_data_bonifico,m.data_bonifico)
       and m.tipo_imposta = nvl(p_tipo_imposta,m.tipo_imposta);
  exception
    when others then
      w_messaggio := substr('Elim. FORNITURE_AE tipo R2 ('||p_documento_id||') - '||sqlerrm,1,2000);
      raise errore;
  end;
  for rec_ver in ( select data_fornitura
                        , progr_fornitura
                        , data_ripartizione
                        , progr_ripartizione
                        , data_bonifico
                        , case when m.tipo_record = 'D' and m.cod_tributo like 'TEF%'
                               then 'TEF' else m.tipo_imposta end as tipo_imposta
                        , anno_acc
                        , numero_acc
                        , data_provvisorio
                        , numero_provvisorio
                        , sum(m.importo_lordo) importo
                        , round(sum(decode(f.flag_ifel
                                           ,'S',m.importo_lordo * i.aliquota / 1000
                                          ,0
                                          )
                                   ),2) importo_ifel
                     from forniture_ae m, codici_f24 f, contributi_ifel i
                    where m.documento_id = p_documento_id
                      and m.tipo_record in ('D','G1')
                      and m.data_fornitura = nvl(p_data_fornitura,m.data_fornitura)
                      and m.progr_fornitura = nvl(p_progr_fornitura,m.progr_fornitura)
                      and m.data_ripartizione = nvl(p_data_ripartizione,m.data_ripartizione)
                      and m.progr_ripartizione = nvl(p_progr_ripartizione,m.progr_ripartizione)
                      and m.data_bonifico = nvl(p_data_bonifico,m.data_bonifico)
                      and m.tipo_imposta = nvl(p_tipo_imposta,tipo_imposta)
                      and m.tipo_tributo = f.tipo_tributo (+)
                      and m.descrizione_titr = f.descrizione_titr (+)
                      and m.cod_tributo = f.tributo_f24 (+)
                      and m.anno_rif = i.anno
                      and data_provvisorio is not null
                      and numero_provvisorio is not null
                 -- (VD 20/06/2022): esclusione IMU erariale
                      and m.cod_tributo not in ('3915','3917','3919','3925',
                                                '352E','354E','356E','359E')
                 -- (RV 04/02/2025): escludo l'imposta TARI in caso di record 'D'
                      and (m.tipo_record <> 'D' or m.cod_tributo like ('TEF%'))
                    group by data_fornitura, progr_fornitura
                           , data_ripartizione, progr_ripartizione
                           , data_bonifico
                           , case when m.tipo_record = 'D' and m.cod_tributo like ('TEF%')
                                  then 'TEF' else m.tipo_imposta end
                           , anno_acc, numero_acc
                           , data_provvisorio, numero_provvisorio
                 )
  loop
     w_progressivo := to_number(null);
     forniture_ae_nr(p_documento_id,w_progressivo);
     begin
       insert into forniture_ae ( documento_id
                                , progressivo
                                , tipo_record
                                , data_fornitura
                                , progr_fornitura
                                , data_ripartizione
                                , progr_ripartizione
                                , data_bonifico
                                , tipo_imposta
                                , anno_acc
                                , numero_acc
                                , data_provvisorio
                                , numero_provvisorio
                                , importo_netto
                                , importo_ifel
                                , importo_lordo
                                )
       values ( p_documento_id
              , w_progressivo
              , 'R2'
              , rec_ver.data_fornitura
              , rec_ver.progr_fornitura
              , rec_ver.data_ripartizione
              , rec_ver.progr_ripartizione
              , rec_ver.data_bonifico
              , rec_ver.tipo_imposta
              , rec_ver.anno_acc
              , rec_ver.numero_acc
              , rec_ver.data_provvisorio
              , rec_ver.numero_provvisorio
              , rec_ver.importo - rec_ver.importo_ifel
              , decode(rec_ver.importo_ifel,0,to_number(null),rec_ver.importo_ifel)
              , rec_ver.importo
              );
     exception
       when others then
         w_messaggio := substr('Ins. FORNITURE_AE tipo R2 ('||p_documento_id||w_progressivo||') - '||sqlerrm,1,2000);
         raise errore;
     end;
  end loop;
  return w_messaggio;
exception
  when errore then
    return w_messaggio;
  when others then
    raise;
end;
-------------------------------------------------------------------------------------------------------------------
function QUADRATURA_VERSAMENTI
( p_documento_id                number
, p_data_fornitura              date
, p_progr_fornitura             number
, p_data_ripartizione           date
, p_progr_ripartizione          number
, p_data_bonifico               date
, p_tipo_imposta                varchar2 default null
) return number is
/******************************************************************************
 NOME:        QUADRATURA_VERSAMENTI
 DESCRIZIONE: Esegue il controllo di quadratura tra il totale degli importi dei
              singoli versamenti e il totale indicato nei record riepilogativi
              (R2).
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
              p_tipo_tributo    Tipo tributo da trattare.
                                Null = tutti i tipi tributo.
 RETURN:      number            0 - Quadratura corretta
                                1 - Quadratura errata
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   05/02/2025  RV      #75644
                           Revisione per gestione Quadratura record D/M.
 001   20/06/2022  VD      In attesa della creazione di un apposito attributo
                           nella tabella CODICI_F24, si escludono dal trattamento
                           i codici tributo relativi all'erario
                           (IMU - 3915, 3917, 3919, 3925)
******************************************************************************/
  w_return                      number;
  w_importo_rip                 number;
  w_importo_netto               number;
  w_importo_ifel                number;
  w_importo_recupero            number;
begin
  w_return := 0;
  for rec_ver in ( select data_fornitura
                        , progr_fornitura
                        , data_ripartizione
                        , progr_ripartizione
                        , data_bonifico
                        , tipo_imposta
                        , sum(importo_netto) importo_netto
                        , sum(importo_ifel)  importo_ifel
                        , sum(importo_lordo) importo_lordo
                     from forniture_ae m, codici_f24 f, contributi_ifel i
                    where m.documento_id = p_documento_id
                      and m.tipo_record = 'R2'
                      and m.data_fornitura = p_data_fornitura
                      and m.progr_fornitura = p_progr_fornitura
                      and m.data_ripartizione = p_data_ripartizione
                      and m.progr_ripartizione = p_progr_ripartizione
                      and m.data_bonifico = p_data_bonifico
                      and m.tipo_imposta = nvl(p_tipo_imposta,tipo_imposta)
                      and m.tipo_tributo = f.tipo_tributo (+)
                      and m.descrizione_titr = f.descrizione_titr (+)
                      and m.cod_tributo = f.tributo_f24 (+)
                      and to_number(to_char(m.data_ripartizione,'yyyy')) = i.anno
                    group by data_fornitura
                           , progr_fornitura
                           , data_ripartizione
                           , progr_ripartizione
                           , data_bonifico
                           , tipo_imposta
                 )
  loop
  --dbms_output.put_line('REC_VER.importo_netto: '||rec_ver.importo_netto);
  --dbms_output.put_line('REC_VER.importo_IFEL: '||rec_ver.importo_ifel);
    -- Determinazione dell'importo di accredito netto e IFEL
    begin
      select sum(decode(cod_ente_beneficiario
                       ,'IFEL',0
                       ,importo_accredito
                       )
                 ) importo_netto
           , sum(decode(cod_ente_beneficiario
                       ,'IFEL',importo_accredito
                       ,0
                       )
                ) importo_ifel
        into w_importo_netto
           , w_importo_ifel
        from forniture_ae
       where documento_id = p_documento_id
         and tipo_record in ('M','G2')
         and data_fornitura     = rec_ver.data_fornitura
         and progr_fornitura    = rec_ver.progr_fornitura
         and data_ripartizione  = rec_ver.data_ripartizione
         and progr_ripartizione = rec_ver.progr_ripartizione
         and data_bonifico      = rec_ver.data_bonifico
         and tipo_imposta       = rec_ver.tipo_imposta
       group by documento_id,data_ripartizione,
                progr_ripartizione,data_bonifico,tipo_imposta;
    exception
      when others then
        w_importo_netto := to_number(null);
        w_importo_ifel  := to_number(null);
    end;
  --dbms_output.put_line('Importo netto: '||w_importo_netto);
  --dbms_output.put_line('Importo IFEL: '||w_importo_ifel);
    --
    -- Determinazione dell'eventuale importo recuperato
    begin
      select sum(nvl(importo_recupero,0))
        into w_importo_recupero
        from forniture_ae
       where documento_id = p_documento_id
         and tipo_record = 'G3'
         and data_fornitura = rec_ver.data_fornitura
         and progr_fornitura = rec_ver.progr_fornitura
         and data_ripartizione = rec_ver.data_ripartizione
         and progr_ripartizione = rec_ver.progr_ripartizione
         and (data_bonifico_orig is null or
              data_bonifico_orig = rec_ver.data_bonifico);
    exception
      when others then
        w_importo_recupero := 0;
    end;
  --dbms_output.put_line('Importo recupero: '||w_importo_recupero);
    --
    w_importo_rip := rec_ver.importo_netto;
  --dbms_output.put_line('Importo rip: '||w_importo_rip);
    --
    -- Se esiste un importo da recuperare lo si sottrae dall'importo totale netto
    if w_importo_recupero > 0 then
       if w_importo_recupero > w_importo_rip then
          w_importo_recupero := w_importo_recupero - w_importo_rip;
          w_importo_rip      := 0;
       else
          w_importo_rip   := w_importo_rip - w_importo_recupero;
          w_importo_recupero := 0;
       end if;
    end if;
  --dbms_output.put_line('Importo rip 2: '||w_importo_rip);
  --dbms_output.put_line('Importo netto 2: '||w_importo_netto);
    --
    if w_importo_rip <> w_importo_netto or
       rec_ver.importo_ifel <> w_importo_ifel then
       w_return := 1;
    end if;
  end loop;
  --
  return w_return;
end QUADRATURA_VERSAMENTI;
-------------------------------------------------------------------------------------------------------------------
function F_EXISTS_RIEPILOGO
( p_documento_id                number
, p_data_fornitura              date
, p_progr_fornitura             number
, p_data_ripartizione           date
, p_progr_ripartizione          number
, p_data_bonifico               date
, p_tipo_imposta                varchar2 default null
) return number is
/******************************************************************************
 NOME:        F_EXISTS_RIEPILOGO
 DESCRIZIONE: Verifica l'esistenza delle righe di riepilogo per i dati
              indicati
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
              p_tipo_tributo    Tipo tributo da trattare.
                                Null = tutti i tipi tributo.
 RETURN:      number            0 - Riepilogo esistente
                                1 - Riepilogo NON esistente
 NOTE:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   05/02/2025  RV      #75644
                           Revisione per gestione Quadratura record D/M.
 000   27/07/2021  VD      Prima emissione.
******************************************************************************/
  w_result                      number;
begin
  begin
    select count(*)
      into w_result
      from forniture_ae m
     where m.documento_id = p_documento_id
       and m.tipo_record = 'R2'
       and m.data_fornitura = p_data_fornitura
       and m.progr_fornitura = p_progr_fornitura
       and m.data_ripartizione = p_data_ripartizione
       and m.progr_ripartizione = p_progr_ripartizione
       and m.data_bonifico = p_data_bonifico
       and m.tipo_imposta = nvl(p_tipo_imposta,tipo_imposta)
     group by m.data_fornitura
            , m.progr_fornitura
            , m.data_ripartizione
            , m.progr_ripartizione
            , m.data_bonifico
      --    , m.tipo_imposta    -- #75644 : Tolto in guanto può creare più righe, che porta ad una eccezione
      ;
  exception
    when others then
      w_result := 0;
  end;
  --
  if w_result = 0 then
     return 1;
  else
     return 0;
  end if;
  --
end F_EXISTS_RIEPILOGO;
-------------------------------------------------------------------------------------------------------------------
function F_IMPORTI_AE_PROVVISORI
( p_numero_provvisorio          number
, p_data_provvisorio            date
) return afc.t_ref_cursor is
/******************************************************************************
 NOME:        ESTRAZIONE_PROVVISORIO
 DESCRIZIONE: Estrae un ref_cursor contenente l'elenco dei versamenti
              raggruppati per accertamento.
 PARAMETRI:   p_numero_provvisorio      Numero provvisorio di contabilità da
                                        trattare
              p_data_provvisorio        Data provvisorio di contabilita da
                                        trattare.
 RETURN:      afc.t_ref_cursor
 NOTE:
******************************************************************************/
  p_ref_cursor                          afc.t_ref_cursor;
begin
  open p_ref_cursor for
       select fae.numero_acc
            , fae.anno_acc
            , sum(fae.importo_netto) importo_netto
         from forniture_ae fae
        where tipo_record = 'R2'
          and fae.numero_provvisorio = p_numero_provvisorio
          and fae.data_provvisorio = p_data_provvisorio
        group by fae.numero_acc, fae.anno_acc;
  return p_ref_cursor;
end;
-------------------------------------------------------------------------------------------------------------------
procedure ELABORA
( p_documento_id             number
, p_messaggio                OUT varchar2
) is
/******************************************************************************
 NOME:        ELABORA
 DESCRIZIONE: Esegue in sequenza le procedures di caricamento dei vari tipi
              record. Restituisce un messaggio con il numero delle righe
              trattate.
 PARAMETRI:   p_documento_id    Id. della riga di DOCUMENTI_CARICATI contenente
                                il file da trattare.
 NOTE:
******************************************************************************/
  w_flag_provincia           varchar2(1);
begin
  w_contatore_tot            := 0;
  w_messaggio                := null;
  begin
     select flag_provincia
       into w_flag_provincia
       from dati_generali
     ;
  end;
  if w_flag_provincia = 'S' then
      dbms_output.put_line('Record D e M');  -- per le province
      elaborazione_forniture_ae.record_d_m(p_documento_id);
       -- Aggiornamento Stato
       begin
          update documenti_caricati
             set stato = 2
               , data_variazione = sysdate
--               , utente = a_utente
               , note =  'Fine elaborazione - Righe trattate: '||to_char(w_contatore_tot)||';'||chr(10)||w_messaggio
               --w_riepilogo || CASE WHEN w_log_documento IS NULL THEN '' ELSE (chr(13)||chr(10)|| w_log_documento) END
           where documento_id = p_documento_id
               ;
       EXCEPTION
          WHEN others THEN
--             sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR(-20999,'Errore in Aggiornamento Stato del documento '||
                                        ' ('||SQLERRM||')');
       end;
  else
      dbms_output.put_line('Record G1');
      elaborazione_forniture_ae.record_g1(p_documento_id);
      dbms_output.put_line('Record G2');
      elaborazione_forniture_ae.record_g2(p_documento_id);
      dbms_output.put_line('Record G3');
      elaborazione_forniture_ae.record_g3(p_documento_id);
      dbms_output.put_line('Record G4');
      elaborazione_forniture_ae.record_g4(p_documento_id);
      dbms_output.put_line('Record G5');
      elaborazione_forniture_ae.record_g5(p_documento_id);
      dbms_output.put_line('Record G9');
      elaborazione_forniture_ae.record_g9(p_documento_id);
  end if;

  w_messaggio := 'Fine elaborazione - Righe trattate: '||to_char(w_contatore_tot)||';'||chr(10)||w_messaggio;
  p_messaggio := w_messaggio;
  delete from wrk_tras_anci;
end ELABORA;
end ELABORAZIONE_FORNITURE_AE;
/
