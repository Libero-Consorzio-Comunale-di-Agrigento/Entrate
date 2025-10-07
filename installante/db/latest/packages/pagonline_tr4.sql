create or replace package PAGONLINE_TR4 is
  /******************************************************************************
   NOME:        PAGONLINE_TR4
   DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE.

   ANNOTAZIONI: -
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   000   28/02/2019  VD      Prima emissione.
   001   13/07/2020  VD      Gestione TARSU per Castelnuovo
   002   30/07/2020  AB      TARSU: sistemazione substr(idback) per aggiornamento
                             pagamenti e Data_reg completa di orario
   003   23/07/2021  VD      Aggiunta gestione violazioni
   004   27/07/2022  VD      Aggiunta funzione DETERMINA_DOVUTI_PRATICA
   005   28/07/2022  VD      Aggiunta funzione DETERMINA_DOVUTI_IMPOSTA
   006   16/12/2022  DM      Gestione pratiche Totali
   007   10/01/2023  DM      Gruppo_tributo x imposta e Flag_depag = 'S' su pratiche
                             in inserimento_dovuti_CU
   008   13/01/2023  DM      Gestione solleciti in f_get_pref_pratica
   009   17/01/2023  AB      Aggiunte le rate recuperate da rate_imposta nella
                             determina_dovuti_pratica
   010   31/01/2023  AB      In inserimento_dovuti_ruolo aggiunta la or PO0100 x OK
   011   14/02/2023  AB      Gestito il pagamento senza pratica per i SOL e
                             recupero data_scadenza da prtr anche per i S come per i V
   012   22/02/2023  AB      Sistemato la data_scadenza e data_scadenza_Avviso per i SOL
                             Aggiornata la naz_pagatore in tutti i punti dove c'era 'IT'
   013   28/02/2023  RV      Issue#62693
                             Rivisto where clause di f_get_tipo_occupazione per
                             problemi di prestazioni
   014   02/03/2023  AB      Issue#57265
                             aggiunta la function f_get_gruppo_tributo_cod x CUNI
   015   02/03/2023  AB      Sistemato il giro di w_dati_riscossione con 9/ e articolo
   016   26/04/2023  AB      passaggio di w_importo_dovuto al f_get_bilancio
   017   18/08/2023  AB      #66387: Aggiunto il controllo anche per procedere con P0100
                             in aggiorna_dovuto_pagopa come per inserimento_dovuti_ruolo
                             cosi si procede anche se una rata è gia stata pagata e si
                             aggiornano le altre a seguito di eventuale sgravio
   018   17/10/2023  RV      #66207 : Rivisto per scomposizione degli importi
                             Aggiunta function codice_comunale_ente
                             Aggiunta function prepara_scomposizione_importi
   019   14/12/2023  RV      #54733
                             Modifiche per gestione flag_no_depag di categorie e tariffe
   020   10/01/2024  RV      #54732
                             Modifiche per gestione gruppo tributo e date scadenza personalizzate
   021   10/01/2024  AB      #69403
                             Arrotondato l'importo nel caso di Sollecito TARSU
   022   07/02/2024  RV      #66207
                             Gestione dovuto MB
   023   08/02/2024  RV      #69861
                             Aggiunta separazione quota addizionale_pro
   024   12/03/2024  RV      #55403
                             Aggiunta parametro p_max_rata a determina_dovuti_ruolo
   025   20/03/2024  AB      #69103
                             Aggiunta function aggiorna_dati_anagrafici
   026   27/03/2024  RV      #69103
                             Aggiunta function determina_dovuti_soggetto
   027   02/04/2024  AB      #69103
                             Aggiornata la data_scadenza_avviso se minore della data odierna
   028   03/04/2024  AB      #69103
                             Inserito e poi tolto pragma autonomous_transaction;
                             nella ins_log per poter inserire la commit,
                             altrimenti il trigger contribuenti_cu dava errore.
                             Però qui ci creava problemi con le altre insert e cosi l'ho
                             rimesso nella contribuenti_cu con la commit
   029   15/04/2024  AB      #69103
                             Sostituito il cf anche in rata_unica_ref, nel caso sia
                             ancora presente, altrimenti si annulla numero e rata_rif
   030   18/04/2024  RV      #54732
                             Sistemato selezione accertamento contasbile per gruppo tributo
   031   21/05/2024  RV      #70776
                             Gestione tipo occupazione per dati contabili
   032   31/05/2024  RV      #72976
                             Gestione componenti perequative TARI (come maggiorazione_tares)
   033   10/06/2024  AB      Gestione errore con nostro messaggio nel caso di aggiornamentio pagamento errato
   034   05/02/2025  RV      #78016
                             Gestione aggiornamento_pagamenti con idback doppio
   035   13/02/2025  RV      #77805
                             Rivisto per componenti perequative spalmate
   036   05/03/2025  RV      #77216
                             Gestione campo Bilancio come Netto nel caso di Quote_MB
   037   18/03/2025  RV      #78971
                             Sistemato per ruoli con eccedenze
   038   25/03/2025  DM      #77348
                             Aggiunto flag per controllo eliminazione DEPAG
   039   25/03/2025  RV      #79482
                             Sistemato conteggio versamenti in inserimento_dovuti_ruolo
                             in caso di ruolo Acconto + Saldo + Supplettivo
   040   09/05/2025  RV      #80274
                             Sistemato mancata contabilizzazione Oneri nelle singole
                             rate delle pratiche di violazione rateizzate (90)
   041   31/07/2025  RV      #82362
                             Aggiunta gestione sbilancio da Componenti Perequative in aggiorna_dovuto_pagopa
   042   29/09/2025  RV      #83103
                             Sistemato aggiorna_dovuto_pagopa per Sgravi Maggiorazione TARES
   043   21/07/2025  DM      #78699
                             Escluse spese di notifica SmartPND (codice 9000)
   044   30/07/2025  RV      #77694
                             Sistemazine computo imponibile in caso di assenza
                             Sanzione codice 9000
******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '44    29/09/2025';

  type dovuti_table is table of depag_dovuti%rowtype;
  p_tab_dovuti              dovuti_table := dovuti_table();

  function versione
  return varchar2;

  --Generali

  function f_get_collection
  return dovuti_table pipelined;

  function f_get_sigla_provincia
  ( p_cod_pro                          number
  , p_tipo_sigla                       varchar2 default null
  ) return varchar2;

  function f_get_pref_pratica
  ( p_tipo_pratica                     varchar2
  , p_tipo_evento                      varchar2
  ) return varchar2;

  function f_get_gruppo_tributo
  ( p_pratica                            number
  ) return varchar2;

  function f_get_gruppo_tributo_imposta
  ( p_tipo_tributo                  varchar2
  , p_cod_fiscale                   varchar2
  , p_anno                          number
  , p_gruppo_tributo_dich           varchar2 default null
  ) return varchar2;

  function f_get_gruppo_tributo_cod
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_gruppo_tributo                in varchar2 default null
  ) return number;

  function f_get_idback
  ( p_tipo_tributo                  in varchar2
  , p_tipo_occupazione              in varchar2
  , p_anno                          in number
  , p_pratica                       in number
  , p_cod_fiscale                   in varchar2
  , p_rata                          in number
  ) return sys_refcursor;

  function f_get_idback_rate
  ( p_cod_fiscale                   in varchar2
  ) return sys_refcursor;

  function f_get_tipo_occupazione
  ( p_pratica                 number
  ) return varchar2;

  procedure inserimento_log
  ( p_operazione                    IN varchar2
  , p_note                          IN varchar2
  );

  function descrizione_ente
  return varchar2;

  function codice_catastale_ente
  return varchar2;

  function scadenza_rata_ruolo
  ( p_ruolo                         in number
  , p_rata                          in number
  ) return date;

  function scadenza_rata_avviso
  ( p_ruolo                         in number
  , p_rata                          in number
  ) return date;

  function inserimento_dovuti
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_pratica                       in number
  , p_chk_rate                      in number
  )
  return number;

  function determina_dovuti_imposta
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_tipo_occupazione              in varchar2
  , p_rata                          in number   default null
  , p_tipo_dovuto                   in varchar2 default null
  , p_gruppo_tributo                in varchar2 default null
  , p_data_emissione                in date default null
  ) return sys_refcursor;

  function eliminazione_dovuti_ruolo
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_ruolo                         in number
  --, p_chk_rate                in number
  ) return number;

  function inserimento_dovuti_ruolo
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_ruolo                         in number
  --, p_chk_rate                    in number
  ) return number;

  function determina_dovuti_ruolo
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_ruolo                         in number
  , p_tipo_dovuto                   in varchar2 default null
  , p_max_rata                      in number default null
  ) return sys_refcursor;

  function aggiorna_dovuto_pagopa
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_ruolo                         in number
  ) return varchar2;

  function inserimento_violazioni
  ( p_pratica                       in number
  ) return number;

  function aggiorna_dovuti_pratica
  ( p_pratica                       in number
  ) return sys_refcursor;

  function determina_dovuti_pratica
  ( p_pratica                       in number
  , p_tipo_dovuto                   in varchar2 default null
  ) return sys_refcursor;

  function annullamento_dovuto
  ( p_ente                          IN varchar2
  , p_idback                        IN varchar2
  , p_utente                        IN varchar2
  ) return number;

  function aggiornamento_pagamenti
  ( p_ente                          in varchar2 default null
  , p_idback                        in varchar2 default null
  , p_iuv                           in varchar2
  , p_importo_versato               in varchar2
  , p_data_pagamento                in varchar2
  , p_utente                        in varchar2
  , p_servizio                      in varchar2 default null
  , p_quote_mb                      in varchar2 default null
  ) return number;

  function inserimento_dovuti_cu
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_pratica                 in number
  , p_chk_rate                in number
  , p_gruppo_tributo          in varchar2 default null
  )
  return number;

  function prepara_scomposizione_importi
  ( p_tipo_tributo            in varchar2
  , p_anno                    in number
  , p_anno_emissione          in number
  , p_netto                   in number
  , p_addizionali             in number
  , p_quote                   out varchar2
  , p_metadata                out varchar2
  )
  return number;

-------------------------------------------------------------------------
-- FUNZIONI NON UTILIZZATE
-------------------------------------------------------------------------
  function j_aggiornamento_pagamenti
  ( p_ente                          in varchar2 default null
  , p_idback                        in varchar2 default null
  ) return number;

  function aggiornamento_dovuto
  ( p_tipo_tributo                  in varchar2
  , p_cod_fiscale                   in varchar2
  , p_anno                          in number
  , p_dic_da_anno                   in number
  , p_eliminazione                  in varchar2
  ) return number;

  function annullamento_pagamento
  ( p_ente                          IN varchar2
  , p_idback                        IN varchar2
  ) return number;

  function set_dovuti_valori
  ( p_ente                          IN varchar2
  , p_idback                        IN varchar2
  , p_utente                        IN varchar2
  ) return number;

  function aggiorna_dati_anagrafici
  ( p_cod_fiscale_old               IN varchar2
  , p_cod_fiscale_new               IN varchar2
  , p_ni_old                        IN number
  , p_ni_new                        IN number
  ) return number;

  function determina_dovuti_soggetto
  ( p_cod_fiscale                   in varchar2
  , p_stato                         in varchar2         -- T = TUTTO, P = PAGATO, D = DA_PAGARE
  ) return sys_refcursor;

end PAGONLINE_TR4;
/
create or replace package body PAGONLINE_TR4 is
/******************************************************************************
 NOME:        PAGONLINE_TR4
 DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE.

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   28/02/2019  VD      Prima emissione.
   001   13/07/2020  VD      Gestione TARSU per Castelnuovo
   002   30/07/2020  AB      TARSU: sistemazione substr(idback) per aggiornamento
                             pagamenti e Data_reg completa di orario
   003   23/07/2021  VD      Aggiunta gestione violazioni
   004   27/07/2022  VD      Aggiunta funzione DETERMINA_DOVUTI_PRATICA
   005   28/07/2022  VD      Aggiunta funzione DETERMINA_DOVUTI_IMPOSTA
   006   16/12/2022  DM      Gestione pratiche Totali
   007   10/01/2023  DM      Gruppo_tributo x imposta e Flag_depag = 'S' su pratiche
                             in inserimento_dovuti_CU
   008   13/01/2023  DM      Gestione solleciti in f_get_pref_pratica
   009   17/01/2023  AB      Aggiunte le rate recuperate da rate_imposta nella
                             determina_dovuti_pratica
   010   31/01/2023  AB      In inserimento_dovuti_ruolo aggiunta la or PO0100 x OK
   011   14/02/2023  AB      Gestito il pagamento senza pratica per i SOL e
                             recupero data_scadenza da prtr anche per i S come per i V
   012   22/02/2023  AB      Sistemato la data_scadenza e data_scadenza_Avviso per i SOL
                             Aggiornata la naz_pagatore in tutti i punti dove c'era 'IT'
   013   28/02/2023  RV      Issue#62693
                             Rivisto where clause di f_get_tipo_occupazione per
                             problemi di prestazioni
   014   02/03/2023  AB      Issue#57265
                             aggiunta la function f_get_gruppo_tributo_cod x CUNI
   015   02/03/2023  AB      Sistemato il giro di w_dati_riscossione con 9/ e articolo
   016   26/04/2023  AB      passaggio di w_importo_dovuto al f_get_bilancio
   017   18/08/2023  AB      #66387: Aggiunto il controllo anche per procedere con P0100
                             in aggiorna_dovuto_pagopa come per inserimento_dovuti_ruolo
                             cosi si procede anche se una rata è gia stata pagata e si
                             aggiornano le altre a seguito di eventuale sgravio
   018   17/10/2023  RV      #66207 : Rivisto per scomposizione degli importi
                             Aggiunta function codice_comunale_ente
                             Aggiunta function prepara_scomposizione_importi
   019   14/12/2023  RV      #54733
                             Modifiche per gestione flag_no_depag di categorie e tariffe
   020   10/01/2024  RV      #54732
                             Modifiche per gestione gruppo tributo e date scadenza personalizzate
   021   10/01/2024  AB      #69403
                             Arrotondato l'importo nel caso di Sollecito TARSU
   022   07/02/2024  RV      #66207
                             Gestione dovuto MB
   023   08/02/2024  RV      #69861
                             Aggiunta separazione quota addizionale_pro
   024   12/03/2024  RV      #55403
                             Aggiunta parametro p_max_rata a determina_dovuti_ruolo
   025   20/03/2024  AB      #69103
                             Aggiunta function aggiorna_dati_anagrafici
   026   27/03/2024  RV      #69103
                             Aggiunta function determina_dovuti_soggetto
   027   02/04/2024  AB      #69103
                             Aggiornata la data_scadenza_avviso se minore della data odierna
   028   03/04/2024  AB      #69103
                             Inserito e poi tolto pragma autonomous_transaction;
                             nella ins_log per poter inserire la commit,
                             altrimenti il trigger contribuenti_cu dava errore.
                             Però qui ci creava problemi con le altre insert e cosi l'ho
                             rimesso nella contribuenti_cu con la commit
   029   15/04/2024  AB      #69103
                             Sostituito il cf anche in rata_unica_ref, nel caso sia
                             ancora presente, altrimenti si annulla numero e rata_rif
   030   18/04/2024  RV      #54732
                             Sistemato selezione accertamento contasbile per gruppo tributo
   031   21/05/2024  RV      #70776
                             Gestione tipo occupazione per dati contabili
   032   31/05/2024  RV      #72976
                             Gestione componenti perequative TARI (come maggiorazione_tares)
   033   10/06/2024  AB      Gestione errore con nostro messaggio nel caso di aggiornamentio pagamento errato
   034   05/02/2025  RV      #78016
                             Gestione aggiornamento_pagamenti con idback doppio
   035   13/02/2025  RV      #77805
                             Rivisto per componenti perequative spalmate
   036   05/03/2025  RV      #77216
                             Gestione campo Bilancio come Netto nel caso di Quote_MB
   037   18/03/2025  RV      #78971
                             Sistemato per ruoli con eccedenze
   038   25/03/2025  DM      #77348
                             Aggiunto flag per controllo eliminazione DEPAG
   039   25/03/2025  RV      #79482
                             Sistemato conteggio versamenti in inserimento_dovuti_ruolo
                             in caso di ruolo Acconto + Saldo + Supplettivo
   040   09/05/2025  RV      #80274
                             Sistemato mancata contabilizzazione Oneri nelle singole
                             rate delle pratiche di violazione rateizzate (90)
   041   31/07/2025  RV      #82362
                             Aggiunta gestione sbilancio da Componenti Perequative in aggiorna_dovuto_pagopa
   042   29/09/2025  RV      #83103
                             Sistemato aggiorna_dovuto_pagopa per Sgravi Maggiorazione TARES
   043   21/07/2025  DM      #78699
                             Escluse spese di notifica SmartPND (codice 9000)
   044   30/07/2025  RV      #77694
                             Sistemazine computo imponibile in caso di assenza
                             Sanzione codice 9000
******************************************************************************/
   function versione return varchar2
   is
   begin
      return s_versione||'.'||s_revisione;
   end versione;

--------------------------------------------------------------------------------------------------------
--Generali
--------------------------------------------------------------------------------------------------------
function f_get_collection
/******************************************************************************
 NOME:        F_GET_COLLECTION
 DESCRIZIONE: Restituisce un ref_cursor formato da tutti gli elementi di un
              array di record

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
******************************************************************************/
return dovuti_table pipelined
is
begin
  for i in 1..p_tab_dovuti.count loop
    pipe row(p_tab_dovuti(i));
  end loop;
  return;
end;
--------------------------------------------------------------------------------------------------------
function f_get_sigla_provincia
/******************************************************************************
 NOME:        F_GET_SIGLA_PROVINCIA
 DESCRIZIONE: Restituisce la sigla della provincia o il codice iso 3166 dello
              stato estero.

 ANNOTAZIONI: Se il codice della provincia è < 200, si tratta di provincia
              italiana, quindi se il parametro p_tipo_sigla è 'P' si restituisce
              la sigla della provincia, altrimenti si restituisce 'IT' (sigla
              stato).
              Se il codice della provincia è >= 200 (stato estero) si restituisce
              la sigla ISO 3166 dello stato.
              In entrambi i casi i valori vengono restituiti solo se sono di
              2 caratteri.

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
******************************************************************************/
( p_cod_pro                            number
, p_tipo_sigla                         varchar2 default null
) return varchar2
is
  w_sigla_prov_stato                   varchar2(2);
begin
  if p_cod_pro < 200 then
     select decode(nvl(p_tipo_sigla,'P')
                  ,'P',decode(nvl(length(ad4_provincia.get_sigla(p_cod_pro)),0)
                             ,2,ad4_provincia.get_sigla(p_cod_pro)
                             ,''
                             )
                  ,'IT'
                  )
       into w_sigla_prov_stato
       from dual;
   else
     select decode(nvl(length(ad4_stati_territori_tpk.get_sigla_iso3166_alpha2(p_cod_pro)),0)
                  ,2,ad4_stati_territori_tpk.get_sigla_iso3166_alpha2(p_cod_pro)
                    ,''
                  )
       into w_sigla_prov_stato
       from dual;
   end if;
--
   return w_sigla_prov_stato;
--
end;
--------------------------------------------------------------------------------------------------------
function f_get_pref_pratica
/******************************************************************************
 NOME:        F_GET_PREF_PRATICA
 DESCRIZIONE: Violazioni in DEPAG: compone il prefisso della pratica da
              utilizzare nella composizione dell'idback.

 ANNOTAZIONI: I valori restituiti sono i sequenti:
              - LIQP per tipo pratica = 'L' (liquidazione)
              - ACCP per tipo pratica = 'A' (accertamento)
              - ACCT per tipo pratica = 'A' e tipo evento = 'T' (pratica totale di accertamento)
              - ACCA per tipo pratica = 'A' e tipo evento = 'A' (accertamento automatico)
              - ACCU per tipo pratica = 'A' e tipo evento = 'U' (accertamento manuale)
              - SOLA per tipo pratica = 'S' e tipo evento = 'A' (sollecito automatico)

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   23/07/2021  VD      Prima emissione.
 000   13/01/2023  DM      Gestione solleciti.
******************************************************************************/
( p_tipo_pratica                       varchar2
, p_tipo_evento                        varchar2
) return varchar2
is
  w_pref_pratica                       varchar2(4) := null;

begin
--
   case p_tipo_pratica
     when 'A' then w_pref_pratica := 'ACC';
     when 'L' then w_pref_pratica := 'LIQP';
     when 'V' then w_pref_pratica := 'RAVP';
     when 'S' then w_pref_pratica := 'SOL';
     --else w_pref_pratica := 'DEN';
     else w_pref_pratica := '';
   end case;
--
   if p_tipo_pratica IN ('A', 'S') then
      w_pref_pratica := w_pref_pratica||p_tipo_evento;
   end if;
--
   return w_pref_pratica;
--
end;
--------------------------------------------------------------------------------------------------------
function f_get_gruppo_tributo
/******************************************************************************
 NOME:        F_GET_GRUPPO_TRIBUTO
 DESCRIZIONE: Canone Unico in DEPAG: ricerca l'eventuale gruppo_tributo
              per il canone mercato e altro

 ANNOTAZIONI:

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   03/03/2022  VD      Prima emissione.
******************************************************************************/
( p_pratica                            number
) return varchar2
is
  w_gruppo_tributo                     varchar2(5) := null;
  w_tipo_tributo                       varchar2(5) := null;
begin
  begin
    select prtr.tipo_tributo
      into w_tipo_tributo
      from pratiche_tributo prtr
     where prtr.pratica = p_pratica;
  exception
    when others then
      w_tipo_tributo := null;
  end;
  --
  if w_tipo_tributo = 'CUNI' then
     begin
       select min(grtr.descrizione)
         into w_gruppo_tributo
         from oggetti_pratica  ogpr
            , codici_tributo   cotr
            , gruppi_tributo   grtr
        where ogpr.pratica = p_pratica
          and ogpr.tributo = cotr.tributo
          and cotr.gruppo_tributo = grtr.gruppo_tributo
        group by pratica;
     exception
       when others then
         w_gruppo_tributo := null;
     end;
  else
     w_gruppo_tributo := w_tipo_tributo;
  end if;
--
  return nvl(w_gruppo_tributo,w_tipo_tributo);
--
end;

function f_get_gruppo_tributo_imposta
/******************************************************************************
 NOME:        F_GET_GRUPPO_TRIBUTO_IMPOSTA
 DESCRIZIONE: Canone Unico in DEPAG: ricerca l'eventuale gruppo_tributo
              per il canone mercato e altro per l'imposta

 ANNOTAZIONI:

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/07/2023  RV      Aggiunto parametro gruppo tributo dichiarato
 000   10/01/2023  DM      Prima emissione.
******************************************************************************/
( p_tipo_tributo                  in varchar2
, p_cod_fiscale                   in varchar2
, p_anno                          in number
, p_gruppo_tributo_dich           in varchar2 default null
) return varchar2
is
  w_gruppo_tributo                     varchar2(5) := null;
begin
  if p_gruppo_tributo_dich is not null then
    begin
      select grtr.descrizione gruppo_tributo
        into w_gruppo_tributo
        from gruppi_tributo grtr
       where grtr.tipo_tributo = p_tipo_tributo
         and grtr.gruppo_tributo = p_gruppo_tributo_dich;
    exception
      when others then
        w_gruppo_tributo := null;
    end;
  else
  begin
    select gruppo_tributo
      into w_gruppo_tributo
      from (SELECT grtr.descrizione gruppo_tributo
              FROM OGGETTI_PRATICA      OGPR,
                   PRATICHE_TRIBUTO     PRTR,
                   OGGETTI              OGGE,
                   OGGETTI_CONTRIBUENTE OGCO,
                   OGGETTI_IMPOSTA      OGIM,
                   CODICI_TRIBUTO       COTR,
                   CONTRIBUENTI         CONT,
                   RUOLI                RUOL,
                   gruppi_tributo       grtr
             WHERE OGPR.PRATICA = PRTR.PRATICA
               AND OGPR.OGGETTO = OGGE.OGGETTO
               AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
               AND OGCO.COD_FISCALE = CONT.COD_FISCALE
               AND OGIM.COD_FISCALE = OGCO.COD_FISCALE
               AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
               AND OGPR.TRIBUTO = COTR.TRIBUTO(+)
               AND OGIM.RUOLO = RUOL.RUOLO(+)
               and cotr.gruppo_tributo = grtr.gruppo_tributo
               AND OGIM.FLAG_CALCOLO = 'S'
               AND (PRTR.TIPO_PRATICA IN ('D', 'C') OR
                   (PRTR.TIPO_PRATICA = 'A' AND OGIM.ANNO > PRTR.ANNO AND
                   PRTR.FLAG_DENUNCIA = 'S'))
               AND OGIM.ANNO = p_anno
               and prtr.cod_fiscale = p_cod_fiscale
               AND OGIM.TIPO_TRIBUTO = p_tipo_tributo
             order by (case
                        when cotr.flag_ruolo is null then
                         0
                        else
                         1
                      end))
     where rownum = 1;
  exception
    when others then
      w_gruppo_tributo := null;
  end;
  end if;

  return nvl(w_gruppo_tributo, p_tipo_tributo);

end;

-------------------------------------------------------------------------------
function f_get_gruppo_tributo_cod
/******************************************************************************
 NOME:        F_GET_GRUPPO_TRIBUTO_COD
 DESCRIZIONE: Canone Unico in DEPAG: ricerca l'eventuale cod_tributo x gruppo_tributo
              per il canone mercato e altro

 ANNOTAZIONI:

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   18/04/2024  AB      #54732
                           Aggiunto parametro opzionale p_gruppo_tributo
 000   02/03/2023  AB      Prima emissione.
******************************************************************************/
( p_tipo_tributo                  in varchar2
, p_cod_fiscale                   in varchar2
, p_anno                          in number
, p_gruppo_tributo                in varchar2 default null
) return number
is
  w_cod_tributo                        number;
begin
  w_cod_tributo := null;
  if p_tipo_tributo = 'CUNI' then
     begin
        select cod_tributo
          into w_cod_tributo
          from (SELECT min(cotr.tributo) cod_tributo
                  FROM OGGETTI_PRATICA      OGPR,
                       PRATICHE_TRIBUTO     PRTR,
                       OGGETTI              OGGE,
                       OGGETTI_CONTRIBUENTE OGCO,
                       OGGETTI_IMPOSTA      OGIM,
                       CODICI_TRIBUTO       COTR,
                       CONTRIBUENTI         CONT,
                       RUOLI                RUOL,
                       gruppi_tributo       grtr
                 WHERE OGPR.PRATICA = PRTR.PRATICA
                   AND OGPR.OGGETTO = OGGE.OGGETTO
                   AND OGPR.OGGETTO_PRATICA = OGCO.OGGETTO_PRATICA
                   AND OGCO.COD_FISCALE = CONT.COD_FISCALE
                   AND OGIM.COD_FISCALE = OGCO.COD_FISCALE
                   AND OGPR.OGGETTO_PRATICA = OGIM.OGGETTO_PRATICA
                   AND OGPR.TRIBUTO = COTR.TRIBUTO(+)
                   AND OGIM.RUOLO = RUOL.RUOLO(+)
                   and cotr.gruppo_tributo = grtr.gruppo_tributo(+)
                   and ((p_gruppo_tributo is null) or
                       ((p_gruppo_tributo is not null) and (cotr.gruppo_tributo = p_gruppo_tributo))
                   )
                   AND OGIM.FLAG_CALCOLO = 'S'
                   AND (PRTR.TIPO_PRATICA IN ('D', 'C') OR
                       (PRTR.TIPO_PRATICA = 'A' AND OGIM.ANNO > PRTR.ANNO AND
                       PRTR.FLAG_DENUNCIA = 'S'))
                   AND OGIM.ANNO = p_anno
                   and COTR.flag_ruolo is null
                   and prtr.cod_fiscale like p_cod_fiscale
                   AND OGIM.TIPO_TRIBUTO = p_tipo_tributo
                 order by (case
                            when cotr.flag_ruolo is null then
                             0
                            else
                             1
                          end))
         where rownum = 1;
     exception
        when others then
          w_cod_tributo := null;
     end;
  end if;

  return w_cod_tributo;

end;

function f_get_idback_rate
( p_cod_fiscale                   in varchar2
) return sys_refcursor is
/*************************************************************************
 NOME:         F_GET_IDBACK_RATE
 DESCRIZIONE:  Saronno - Passaggio a DEPAG dei canoni di locazione delle
               case popolari.
               Si estrae l'elenco degli idback presenti su rate_imposta
               e provenienti dal caricamento del files MAV.

 PARAMETRI:

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   11/02/2022  VD      Prima emissione.
*************************************************************************/
  rc                       sys_refcursor;
begin
  open rc for select idback
                from rate_imposta
               where cod_fiscale = p_cod_fiscale
               order by rata;
  return rc;
end f_get_idback_rate;
-------------------------------------------------------------------------------
function f_get_idback
( p_tipo_tributo            varchar2
, p_tipo_occupazione        varchar2
, p_anno                    number
, p_pratica                 number
, p_cod_fiscale             varchar2
, p_rata                    number
) return sys_refcursor is
/*************************************************************************
 NOME:         F_GET_IDBACK
 DESCRIZIONE:  Composizione dell'idback standard.
 PARAMETRI:

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   11/02/2022  VD      Prima emissione.
*************************************************************************/
  w_idback_1               depag_dovuti.idback%type;
  w_idback_2               depag_dovuti.idback%type;
  w_tipo_pratica           varchar2(1);
  w_tipo_evento            varchar2(1);
  w_gruppo_tributo         varchar2(5);
  rc                       sys_refcursor;
begin
  w_idback_1 := null;
  w_idback_2 := null;
  if p_pratica is not null then
     begin
       select tipo_pratica
            , tipo_evento
         into w_tipo_pratica
            , w_tipo_evento
         from pratiche_tributo
        where pratica = p_pratica;
     exception
       when others then
         w_tipo_pratica := null;
         w_tipo_evento := null;
     end;
  end if;
--
-- (Vd - 03/03/2022): per il CUNI si seleziona il gruppo tributo per sapere se si tratta di
--                    CUNI o CUME o altro
  if p_tipo_tributo = 'CUNI' and
     p_pratica is not null then
     begin
       select min(grtr.descrizione)
         into w_gruppo_tributo
         from oggetti_pratica ogpr
            , codici_tributo cotr
            , gruppi_tributo grtr
        where ogpr.pratica = p_pratica
          and ogpr.tributo = cotr.tributo
          and cotr.tipo_tributo = p_tipo_tributo
          and cotr.tipo_tributo = grtr.tipo_tributo
          and cotr.gruppo_tributo = grtr.gruppo_tributo
        group by pratica;
     exception
       when others then
         w_gruppo_tributo := null;
     end;
  else
     w_gruppo_tributo := null;
  end if;
--
  if p_tipo_tributo = 'CUNI' and
     p_pratica is not null then
     w_idback_1 := nvl(w_gruppo_tributo,p_tipo_tributo)||p_tipo_occupazione||p_anno||
                   lpad('0',10,'0')||rpad(p_cod_fiscale,16)||p_rata;
     w_idback_2 := rpad(nvl(w_gruppo_tributo,p_tipo_tributo),5)||p_tipo_occupazione||
                   f_get_pref_pratica(w_tipo_pratica,w_tipo_evento)||p_anno||
                   lpad(nvl(p_pratica,0),10,'0')||rpad(p_cod_fiscale,16)||lpad(p_rata,2,'0');
  end if;

  open rc for select w_idback_1 idback from dual where w_idback_1 is not null
               union
              select w_idback_2 idback from dual where w_idback_2 is not null;

  return rc;

end f_get_idback;
-------------------------------------------------------------------------------
function f_get_tipo_occupazione
( p_pratica                 number
) return varchar2 is
/*************************************************************************
 NOME:         F_GET_TIPO_OCCUPAZIONE
 DESCRIZIONE:  Selezione tipo occupazione per pratiche
 PARAMETRI:

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   28/02/2023  RV      Modificato clause su numero pratica
 000   20/05/2022  VD      Prima emissione.
*************************************************************************/
 w_tipo_occupazione        varchar2(1);
begin
  begin
    select min(ogpr.tipo_occupazione)
      into w_tipo_occupazione
      from pratiche_tributo prtr,
           oggetti_pratica ogpr
     where -- nvl(prtr.pratica_rif,prtr.pratica) = p_pratica
           ((prtr.pratica_rif = p_pratica) or
            ((prtr.pratica_rif is null) and (prtr.pratica = p_pratica)))
       and prtr.pratica = ogpr.pratica;
  exception
    when others then
      w_tipo_occupazione := ' ';
  end;
  return nvl(w_tipo_occupazione,' ');
end;
--------------------------------------------------------------------------------------------------------
procedure inserimento_log
/******************************************************************************
 NOME:        INSERIMENTO_LOG
 DESCRIZIONE: Inserimento tabella di Log (PAGONLINE_LOG).

 PARAMETRI:   p_operazione         Descrizione operazione eseguita.
              p_note               Dati dell'operazione eseguita.

 NOTE:
******************************************************************************/
( p_operazione                      IN varchar2
, p_note                            IN varchar2
)
IS
  w_errore                          varchar2(4000);
  errore                            exception;

  w_id                              number;
  w_operazione_log                  varchar2(255) := 'inserimento log';
--  pragma autonomous_transaction;

begin
  begin
    select nvl(max(id),0)
      into w_id
      from pagonline_log
     where id is not null
    ;
  end;

--  SET TRANSACTION READ WRITE;
     begin
        insert into pagonline_log (id, data_ora, operazione, note)
        values (w_id + 1, sysdate, p_operazione, substr(p_note,1,4000))
        ;
     end;
COMMIT;
  exception
    when others then
         w_errore    := 'errore ('||SQLERRM||')';
         begin
           insert into pagonline_log (id, data_ora, operazione, note)
           values (w_id + 1, sysdate, w_operazione_log, w_errore)
           ;
         end;
COMMIT;
end inserimento_log;
--------------------------------------------------------------------------------------------------------
function descrizione_ente
/******************************************************************************
 NOME:        DESCRIZIONE_ENTE
 DESCRIZIONE: Definisce la descrizione dell'ente per DEPAG

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/04/2021  VD      Aggiunto parametro DEPA_ENTE in installazione_parametri:
                           se presente viene utilizzato come ente, se assente
                           l'ente viene valorizzato con la denominazione del
                           comune presente in AD4_COMUNI, sostituendo eventuali
                           spazi e apostrofi con il carattere "_".
 000   28/02/2019  VD      Prima emissione.
******************************************************************************/
return varchar2 is
  w_des_cliente               varchar2(60);
begin
  w_des_cliente := f_inpa_valore('DEPA_ENTE');
  if trim(w_des_cliente) is null then
     begin
       select translate(comu.denominazione,' ''','__') -- necessario perche' codice ente di DEPAG non prevede ci siano spazi
         into w_des_cliente
         from ad4_comuni comu
            , dati_generali dage
        where dage.pro_cliente = comu.provincia_stato
          and dage.com_cliente = comu.comune
          and rownum = 1
       ;
     exception
       when others then
         w_des_cliente := 'ENTE_NON_CODIFICATO';
     end;
  end if;

  return w_des_cliente;

end descrizione_ente;
--------------------------------------------------------------------------------------------------------
function codice_catastale_ente
/******************************************************************************
 NOME:        CODICE_COMUNALE_ENTE
 DESCRIZIONE: Definisce il coduce comunale dell'ente per DEPAG

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   31/08/2023  RV      Prima emissione.
******************************************************************************/
return varchar2 is
  w_cod_cliente               varchar2(60);
begin
  w_cod_cliente := f_inpa_valore('DEPA_CODENTE');
  if trim(w_cod_cliente) is null then
     begin
       select comu.sigla_cfis
         into w_cod_cliente
         from ad4_comuni comu
            , dati_generali dage
        where dage.pro_cliente = comu.provincia_stato
          and dage.com_cliente = comu.comune
          and rownum = 1
       ;
     exception
       when others then
         w_cod_cliente := 'Z999';
     end;
  end if;

  return w_cod_cliente;

end codice_catastale_ente;
--------------------------------------------------------------------------------------------------------
procedure versato_per_idback
( p_tipo_tributo              in varchar2
, p_cod_fiscale               in varchar2
, p_anno                      in number
, p_idback                    in varchar2  -- Maschera IDBack da conteggiare
, p_idback_escluso            in varchar2  -- Maschera IDBack da escludere dal conteggio, oppure null
, p_versato_idback            out number
, p_conta_idback              out number
) is
  w_versato_idback            number;
  w_conta_idback              number;
begin
  begin
    select nvl(sum(vers.importo_versato),0),
           count(*)
      into w_versato_idback,
           w_conta_idback
      from versamenti vers
     where vers.tipo_tributo||''   = p_tipo_tributo
       and vers.cod_fiscale        = p_cod_fiscale
       and vers.anno               = p_anno
       and vers.idback             like p_idback
       and vers.pratica            is null
       and ((p_idback_escluso is null) or
            (vers.idback not like p_idback_escluso))
     group by vers.cod_fiscale;
  exception
    when others then
      w_versato_idback := 0;
      w_conta_idback := 0;
  end;
  --
--dbms_output.put_line('Versato x IDBack: '||p_idback||', escluso: '||p_idback_escluso||' , totale: '||w_versato_idback);
  --
  p_versato_idback := w_versato_idback;
  p_conta_idback   := w_conta_idback;
  --
end versato_per_idback;
--------------------------------------------------------------------------------------------------------
procedure controllo_rate_emesse
( p_ente                           in varchar2
, p_servizio                       in depag_dovuti.servizio%type
, p_idback                         in depag_dovuti.idback%type
, p_esiste_rata_unica              out number
, p_esiste_rate                    out number
) is
  w_esiste_rata_u                  number;
  w_esiste_rate                    number;
begin
  w_esiste_rata_u := 0;
  w_esiste_rate   := 0;
  for rec_depag in DEPAG_SERVICE_PKG.dovutiPerIdbackLike(p_idback, p_ente, p_servizio)
  loop
    if nvl(rec_depag.rata_numero,-1) = 0 then
       w_esiste_rata_u := 1;
    elsif
       nvl(rec_depag.rata_numero,-1) > 0 then
       w_esiste_rate   := 1;
    end if;
  end loop;
-- Se entrambi i flag sono a zero, significa che il ruolo non e' mai stato emesso
  if w_esiste_rata_u = 0 and w_esiste_rate = 0 then
     w_esiste_rata_u := 1;
     w_esiste_rate   := 1;
  end if;
--
  p_esiste_rata_unica := w_esiste_rata_u;
  p_esiste_rate       := w_esiste_rate;
--
end controllo_rate_emesse;
--------------------------------------------------------------------------------------------------------
function scadenza_rata_ruolo
( p_ruolo                   in number
, p_rata                    in number
) return date is
w_data_scadenza             date;
begin
  begin
    select trunc(decode(p_rata,0,nvl(ruol.scadenza_rata_unica, ruol.scadenza_prima_rata)
                              ,1,ruol.scadenza_prima_rata
                              ,2,ruol.scadenza_rata_2
                              ,3,ruol.scadenza_rata_3
                              ,4,ruol.scadenza_rata_4
                       )
                 )
      into w_data_scadenza
      from ruoli ruol
     where ruol.ruolo = p_ruolo;
  exception
    when others then
      w_data_scadenza := to_date(null);
  end;
--
  return w_data_scadenza;
--
end;
--------------------------------------------------------------------------------------------------------
function scadenza_rata_avviso
( p_ruolo                   in number
, p_rata                    in number
) return date is
w_data_scadenza             date;
begin
  begin
    select trunc(decode(p_rata,0,nvl(ruol.scadenza_avviso_unico, ruol.scadenza_avviso_1)
                              ,1,ruol.scadenza_avviso_1
                              ,2,ruol.scadenza_avviso_2
                              ,3,ruol.scadenza_avviso_3
                              ,4,ruol.scadenza_avviso_4
                       )
                 )
      into w_data_scadenza
      from ruoli ruol
     where ruol.ruolo = p_ruolo;
  exception
    when others then
      w_data_scadenza := to_date(null);
  end;
--
  return w_data_scadenza;
--
end;
--------------------------------------------------------------------------------------------------------
function inserimento_dovuti
/******************************************************************************
 NOME:        INSERIMENTO_DOVUTI
 DESCRIZIONE: Carica l'elenco degli importi dovuti per PAGONLINE.
              Tributi: TOSAP e ICP.

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_pratica             Eventuale pratica su cui calcolare
                                    l'imposta
              p_chk_rate            0 - calcolo senza rateizzazione
                                    > 0 - calcolo con rateizzazione

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
 001   09/11/2020  VD      Modificata gestione sigla provincia/stato estero
 002   15/09/2021  VD      Passaggio a DEPAG_DOVUTI dei nuovi campi per
                           integrazione con contabilita' finanziaria.
                           Correzione sequenza operazioni in caso di errore
                           (prima rollback, poi inserimento log).
 003   17/12/2021  VD      Aggiunto test su flag integrazione con CFA: i
                           dati in depag_dovuti vengono inseriti solo se
                           l'integrazione e' attiva.
                           Modificata gestione segnalazioni errore.
 004   23/01/2024  RV      #66207
                           Aggiunto gestione dovuto mb
 005   27/01/2025  RV      #77216
                           Rivisto per corretta gestione Bilancio con QUOTE_MB
******************************************************************************/
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_pratica                 in number
, p_chk_rate                in number
) return number is
RetVal                      VARCHAR2(8);
w_des_cliente               varchar2(60);
--w_servizio                  varchar(40) := 'TOSAP';  -- DA DEFINIRE
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
--w_iud                     depag_dovuti.iud%TYPE;
w_iud_prec                  depag_dovuti.iud%TYPE;
w_importo_vers              number;
w_conta_vers                number;
w_return                    number:= 0;
w_operazione_log            varchar2(100) := 'inserimento_dovuti';
w_ordinamento               varchar2(1);
w_cf_prec                   varchar2(16);
w_pratica_prec              number;

w_errore                    varchar2(4000);
errore                      exception;

-- (VD - 15/09/2021): Dati per contabilita' finanziaria
w_int_cfa                   varchar2(1);
w_capitolo                  varchar2(200);
w_dati_riscossione          depag_dovuti.dati_riscossione%type;
w_accertamento              depag_dovuti.accertamento%type;
w_bilancio                  depag_dovuti.bilancio%type;

-- (RV - 23/01/2024: Dati per gestione scomposizione degli importi
w_importo_dovuto            number;
w_dovuto_netto              number;
w_importo_tefa              number;
w_dettagli_quote            depag_dovuti.quote_mb%type;
w_metadata_quote            depag_dovuti.metadata%type;
w_numero_quote              number;

-- Cursore per annullare i dovuti di tutte le denunce dell'anno
-- (in questo modo vengono eliminati anche i dovuti relativi
-- a pratiche da non trattare più)
cursor sel_pratiche_ann is
  select prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
    from pratiche_tributo prtr
        ,oggetti_pratica  ogpr
   where prtr.tipo_tributo           = p_tipo_tributo
     and prtr.anno                   = p_anno
     and prtr.cod_fiscale         like p_cod_fiscale
     and prtr.tipo_pratica           = 'D'
     and ogpr.tipo_occupazione       = 'P'
     and p_pratica is null
   group by
         prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
  union
  select p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
    from oggetti_pratica  ogpr
   where ogpr.pratica                = p_pratica
     and p_pratica is not null
   group by
         p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
   order by 1,2;
-- Cursore per selezionare l'imposta da passare a DEPAG
cursor sel_mov is
   -- Selezione per calcolo imposta senza rateizzazione (o imposta non rateizzata perche'
   -- inferiore al limite indicato)
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,p_tipo_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                   rpad(cont.cod_fiscale,16)||0 -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(p_tipo_tributo,impo.tipo_occupazione,null,impo.dovuto_mb) servizio
        , p_tipo_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||0 idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35) localita_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        , f_scadenza_rata(p_tipo_tributo, p_anno, 0)    data_scadenza
        , decode(titr.flag_canone,'S',nvl(impo.imposta,0)
                                     ,round(nvl(impo.imposta, 0))) importo_dovuto
        , impo.importo_tefa as importo_tefa
        , impo.dovuto_mb
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(p_tipo_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: UNICA'     causale_versamento
        --, null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
        , 0 rata
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , tipi_tributo     titr
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||prtr.anno,
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione) fine_occupazione,
                  sum(ogim.imposta) imposta,
                  --
                  sum(nvl(ogim.addizionale_pro,0)) importo_tefa,
                  decode(prtr.tipo_pratica||prtr.anno,'D'||p_anno,
                         f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data),
                         f_depag_dovuto_mb(ogim.tipo_tributo,p_anno,sysdate)) as dovuto_mb
                  --
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr
            where ogpr.pratica  = prtr.pratica
              --and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||prtr.anno,
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione)) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.cod_fiscale = cont.cod_fiscale
      and impo.anno = p_anno
      and (p_chk_rate = 0 or
          (p_chk_rate > 0 and not exists (select 'x' from rate_imposta raim
                                           where raim.tipo_tributo = p_tipo_tributo
                                             and raim.cod_fiscale = cont.cod_fiscale
                                             and raim.anno = p_anno
                                             and ((impo.pratica is null and raim.oggetto_imposta is null) or
                                                  (impo.pratica is not null and raim.oggetto_imposta in
                                                 (select ogim.oggetto_imposta
                                                    from oggetti_imposta ogim
                                                       , oggetti_pratica ogpr
                                                   where ogpr.pratica = impo.pratica
                                                     and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
                                          )
          ))
   union
   -- Selezione per calcolo imposta con rateizzazione
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                        ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,p_tipo_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                   rpad(cont.cod_fiscale,16)||raim.rata -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(p_tipo_tributo,impo.tipo_occupazione,null,impo.dovuto_mb) servizio
        , p_tipo_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||raim.rata idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
             ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
              localita_pagatore
        , nvl(ltrim(replace(replace(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SP'),'(',''),')',''))
             ,ad4_provincia.get_sigla(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        , f_scadenza_rata (p_tipo_tributo, p_anno, raim.rata) data_scadenza
        , decode(titr.flag_canone,'S',sum(nvl(raim.imposta,0))
                                     ,sum(nvl(raim.imposta_round, 0))) importo_dovuto
        , nvl(raim.addizionale_pro,0) as importo_tefa
        , impo.dovuto_mb
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(p_tipo_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: '||raim.rata     causale_versamento
        --, null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
        , raim.rata
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , rate_imposta     raim
        , tipi_tributo     titr
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||prtr.anno,
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione) fine_occupazione,
                  sum(ogim.imposta) imposta,
                  --
                  decode(prtr.tipo_pratica||prtr.anno,'D'||p_anno,
                         f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data),
                         f_depag_dovuto_mb(ogim.tipo_tributo,p_anno,sysdate)) as dovuto_mb
                  --
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr
            where ogpr.pratica  = prtr.pratica
              and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||prtr.anno,
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione)) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.anno = p_anno
      and impo.cod_fiscale = cont.cod_fiscale
      and raim.tipo_tributo = p_tipo_tributo
      and raim.cod_fiscale = cont.cod_fiscale
      and raim.anno = p_anno
      and ((impo.pratica is null and raim.oggetto_imposta is null) or
           (impo.pratica is not null and raim.oggetto_imposta in
           (select ogim.oggetto_imposta
              from oggetti_imposta ogim
                 , oggetti_pratica ogpr
             where ogpr.pratica = impo.pratica
               and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
      and p_chk_rate > 0
    group by cont.cod_fiscale,sogg.ni,sogg.cognome_nome,sogg.tipo_residente,sogg.tipo,
             sogg.cod_via,sogg.denominazione_via,sogg.num_civ,sogg.suffisso,sogg.interno,
             sogg.cod_pro_res,sogg.cod_com_res,arvi.denom_uff,sogg.cap,
             impo.tipo_occupazione,impo.pratica,
             impo.inizio_occupazione,impo.fine_occupazione,
             raim.rata,titr.flag_canone
    order by 1,2,3;
---------------------------------------------------------------------------------------------------
  begin
    w_des_cliente := pagonline_tr4.descrizione_ente;
    -- Si memorizza il tipo di ordinamento da utilizzare nella emissione dei dovuti
    w_ordinamento := nvl(f_inpa_valore('PAGONL_ORD'),'A');
    -- (VD - 17/12/2021): si seleziona il flag per verificare l'integrazione con CFA
    w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');
    -- (VD - 15/09/2021): nuovi dati per integrazione con contabilita' finanziaria
    -- Determinazione accertamento contabile abbinato all'imposta
    -- (da memorizzare nel campo "accertamento" di depag_dovuti)
    -- (VD - 17/12/2021): i dati si predispongono solo se l'integrazione e' attiva
    w_accertamento := null;
    w_dati_riscossione := null;
    w_capitolo := null;
    if w_int_cfa = 'S' then
       w_accertamento := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                               , p_anno
                                                               , 'O'               -- tipo_imposta
                                                               , to_char(null)     -- tipo_pratica
                                                               , trunc(sysdate)    -- data_emissione
                                                               , to_char(null)     -- cod_tributo_f24
                                                               , to_char(null)     -- stato_pratica
                                                               );
       -- Determinazione capitolo abbinato all'accertamento contabile
       -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
       if w_accertamento is not null then
          w_capitolo := dati_contabili_pkg.f_get_capitolo( p_anno
                                                         , to_number(substr(w_accertamento,1,4))
                                                         , to_number(substr(w_accertamento,6))
                                                         );
       end if;
    end if;
    -- Se si sta eseguendo un calcolo imposta generale o per contribuente, si selezionano le denunce
    -- dell'anno e per ognuna si annullano gli eventuali dovuti;
    -- se si sta eseguendo un calcolo per pratica, il risultato della select e' costituito dalla
    -- pratica stessa
    for rec_ann in sel_pratiche_ann
    loop
      --dbms_output.put_line('Pratica: '||rec_ann.pratica);
      w_idback_ann := p_tipo_tributo||rec_ann.tipo_occupazione||p_anno||lpad(rec_ann.pratica,10,'0')||
                      rec_ann.cod_fiscale||'%';
      w_operazione_log := 'Inserimento_dovuti-annulladovutilike pratica';
      pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
      --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
      RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
      if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
         pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: Retval = '||RetVal);
         w_return := w_return +1;
      else
         w_errore := w_idback_ann ||'ERRORE: Retval = '||Retval;
         raise errore;
      end if;
      --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
    end loop;

    -- Prima di elaborare, si cancellano tutti i dovuti per tributo, tipo_occupazione
    -- anno e codice fiscale indicato. Se il calcolo imposta è generale, il codice
    -- fiscale sarà '%', per cui si cancellano tutte le righe per tributo e anno.
    if p_cod_fiscale = '%' or p_pratica is null then
       w_idback_ann := p_tipo_tributo||'P'||p_anno||lpad('0',10,'0')||p_cod_fiscale||'%';
       w_operazione_log := 'Inserimento_dovuti-annulladovutilike';
       pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
       --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
       RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
       if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
          pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: Retval = '||RetVal);
          w_return := w_return +1;
       else
          w_errore := w_idback_ann ||' ERRORE: Retval = '||Retval;
          raise errore;
       end if;
       --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
    end if;
    --
    -- Creazione dovuti per imposta calcolata
    w_operazione_log := 'prima del loop';
    pagonline_tr4.inserimento_log(w_operazione_log, w_des_cliente||' ' ||p_tipo_tributo||' ' ||p_anno);
    w_cf_prec      := '*';
    w_pratica_prec := -1;
    for rec_mov in sel_mov
    loop
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', IMPORTO: '||REC_MOV.IMPORTO_dovuto);
      -- Gestione del versato: ora si verifica se esistono dei versamenti per contribuente
      -- e se esistono si attribuiscono alle varie rate a scalare
      if rec_mov.cod_fiscale <> w_cf_prec or
         nvl(rec_mov.pratica,0) <> nvl(w_pratica_prec,0) then
         w_cf_prec      := rec_mov.cod_fiscale;
         w_pratica_prec := rec_mov.pratica;
         if rec_mov.pratica is not null then
            -- Gestione del versato: si verifica se esistono dei versamenti per pratica
            -- e se esistono si attribuiscono alle varie rate a scalare
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
               --and nvl(vers.rata,0)        = rec_mov.rata
                 and vers.cod_fiscale        = rec_mov.cod_fiscale
                 and vers.anno               = p_anno
                 and vers.pratica            = rec_mov.pratica
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         else
            -- Si controlla l'esistenza di eventuali versamenti
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
                 and vers.cod_fiscale        = rec_mov.CODICE_IDENT
                 and vers.anno               = p_anno
                 and vers.pratica            is null
                 --and nvl(vers.rata,0)        = rec_mov.rata
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         end if;
       end if;
       --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', versato: '||w_importo_vers);

       if nvl(rec_mov.importo_dovuto,0) > 0 then
          if w_importo_vers < rec_mov.IMPORTO_DOVUTO then
             --dbms_output.put_line('Prima di depag_service');
             w_operazione_log := 'Inserimento_dovuti-aggiornadovuto';
             pagonline_tr4.inserimento_log(w_operazione_log, rec_mov.idback||' '||w_des_cliente);
             --
             if w_conta_vers > 0 then
               w_importo_dovuto := rec_mov.IMPORTO_DOVUTO - w_importo_vers;
             else
               w_importo_dovuto := rec_mov.IMPORTO_DOVUTO;
             end if;
             w_importo_tefa := rec_mov.importo_tefa;
             --
             -- (RV - 23/01/2024): gestione scomposizione degli importi
             --
             if nvl(rec_mov.dovuto_mb,'N') = 'S' then
               w_dovuto_netto := w_importo_dovuto - w_importo_tefa;
             --dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', dovuto : '||w_importo_dovuto||', netto : '||w_dovuto_netto||', tefa : '||w_importo_tefa);
               --
               w_numero_quote := prepara_scomposizione_importi ( p_tipo_tributo,p_anno,p_anno,
                                                                     w_dovuto_netto, w_importo_tefa,
                                                                     w_dettagli_quote, w_metadata_quote );
             else
               w_numero_quote := 0;
             end if;
             --
             if(w_numero_quote < 1) then
               w_dovuto_netto := w_importo_dovuto;
               w_dettagli_quote := null;
               w_metadata_quote := null;
             end if;
             --
             -- (VD - 15/09/2021): Dati per contabilita' finanziaria
             -- Composizione del campo "bilancio"
             -- (VD - 17/12/021): il campo "bilancio" si compone solo se l'integrazione e' attiva
             --                   e i dati riscossione e accertamento sono valorizzati
             if w_int_cfa = 'S' and
                w_capitolo is not null and
                w_accertamento is not null then
                w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_capitolo
                                                                , w_accertamento
                                                                , w_dovuto_netto
                                                                );
                w_dati_riscossione := dati_contabili_pkg.f_get_dati_riscossione (w_capitolo);
             else
                w_bilancio := null;
             end if;
             --
             RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ENTE,
                                                      rec_mov.IUD, --iud
                                                      rec_mov.SERVIZIO,
                                                      --rec_mov.idback,
                                                      case
                                                        when w_conta_vers > 0 then
                                                          rec_mov.idback||'-'||w_conta_vers
                                                        else
                                                          rec_mov.idback
                                                      end,--idback
                                                      rec_mov.BACKEND,
                                                      rec_mov.COD_IUV,
                                                      rec_mov.TIPO_IDENT,
                                                      rec_mov.CODICE_IDENT,
                                                      rec_mov.ANAG_PAGATORE,
                                                      rec_mov.INDIRIZZO_PAGATORE,
                                                      substr(rec_mov.CIVICO_PAGATORE,1,16),
                                                      rec_mov.CAP_PAGATORE,
                                                      rec_mov.LOCALITA_PAGATORE,
                                                      rec_mov.PROV_PAGATORE,
                                                      rec_mov.NAZ_PAGATORE,
                                                      rec_mov.EMAIL_PAGATORE,
                                                      rec_mov.DATA_SCADENZA,
                                                      w_importo_dovuto,
                                                      rec_mov.COMMISSIONE_CARICO_PA,
                                                      rec_mov.TIPO_DOVUTO,
                                                      rec_mov.TIPO_VERSAMENTO,
                                                      rec_mov.CAUSALE_VERSAMENTO,
                                                      --rec_mov.DATI_RISCOSSIONE,
                                                      w_dati_riscossione,
                                                      rec_mov.UTENTE_ULTIMO_AGG,
             -- (VD - 15/09/2021): Nuovi campi per integrazione con contabilita' finanziaria
                                                      to_char(null),  -- note
                                                      to_char(null),  -- dati_extra
                                                      w_accertamento, -- accertamento
                                                      w_bilancio,     -- bilancio
             -- (RV - 23/01/2024): Nuovi campi per gestione scomposizione degli importi
                                                      null,           -- scadenza avviso
                                                      null,           -- rata
                                                      null,           -- idback ref
                                                      null,           -- dicitura_scadenza
                                                      w_dettagli_quote,
                                                      w_metadata_quote
                                                      );
             --dbms_output.put_line('Dopo depag_service - retval: '||retval);
             if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
                w_return := w_return +1;
             else
                w_errore := rec_mov.idback ||' ERRORE: Retval = '||Retval;
                raise errore;
             end if;
          end if;
          if w_importo_vers < rec_mov.importo_dovuto then
             w_importo_vers := 0;
          else
             w_importo_vers := w_importo_vers - rec_mov.importo_dovuto;
          end if;
       end if;
       w_iud_prec := rec_mov.iud;
   end loop;

   -- (DM - 10/01/2023): Si aggiorna il flag_depag sulla testata della pratica
   begin
     if (p_pratica is not null) then
        update pratiche_tributo
           set flag_depag = 'S'
         where pratica = p_pratica;
     end if;
   exception
     when others then
       w_errore:='Upd. PRATICHE_TRIBUTO '||p_pratica||' - '||sqlerrm;
       raise errore;
   end;

   return w_return;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end inserimento_dovuti;
--------------------------------------------------------------------------------------------------------
function determina_dovuti_imposta
( p_tipo_tributo                  in varchar2
, p_cod_fiscale                   in varchar2
, p_anno                          in number
, p_tipo_occupazione              in varchar2
, p_rata                          in number   default null
, p_tipo_dovuto                   in varchar2 default null
, p_gruppo_tributo                in varchar2 default null
, p_data_emissione                in date default null
) return sys_refcursor is
/*************************************************************************
 NOME:         DETERMINA_DOVUTI_IMPOSTA
 DESCRIZIONE:  Restituisce un elenco di dovuti relativi all'imposta
               calcolata per un contribuente gia' passati a DEPAG per cui
               deve essere lanciato il web-service di allineamento al
               partner tecnologico oppure recuperato l'avviso AGID.

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
              p_anno                Anno di riferimento
              p_tipo_occupazione    Tipo occupazione ove prevista
              p_gruppo_tributo      Eventuale Gruppo Tributo dichiarato
                                    Se non dichiarato determina da pratiche
              p_data_emissione      Serve per determinare il flag MB. Se null usa sysdate.

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   12/01/2024  RV      #54732
                           Aggiunto gestione parametro p_gruppo_tributo dichiarato
 000   28/07/2022  VD      Prima emissione.
 *************************************************************************/
  w_operazione_log         varchar2(100):= 'determina_dovuti_imposta';
  w_errore                 varchar2(4000);
  w_ind                    number;
  w_des_cliente            varchar2(60);
  w_dep_record             depag_dovuti%rowtype;
  w_data_dovuto_mb         date;
  rc                       sys_refcursor;
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  p_tab_dovuti.delete;
  w_ind := 0;
  --
  if p_data_emissione is null then
    w_data_dovuto_mb := p_data_emissione;
  else
    w_data_dovuto_mb := sysdate;
  end if;
  --
  for sel_idback in ( select
                        distinct *
                      from
                        (select pagonline_tr4.f_get_gruppo_tributo_imposta(p_tipo_tributo,p_cod_fiscale,p_anno,cotr.gruppo_tributo)||
                               nvl(p_tipo_occupazione,' ')||p_anno||
                               lpad('0',10,'0')||rpad(p_cod_fiscale,16)||rate.rata||
                               decode(vers.nvers,null,null,'-'||vers.nvers) idback
                             , f_depag_servizio(
                               pagonline_tr4.f_get_gruppo_tributo_imposta(p_tipo_tributo,p_cod_fiscale,p_anno,cotr.gruppo_tributo)
                                               ,p_tipo_occupazione,dovuto_mb.dovuto_mb) servizio
                          from (select
                                     tipo_tributo,
                                     gruppo_tributo
                                from codici_tributo
                               where tipo_tributo = p_tipo_tributo
                               group by
                                     tipo_tributo,
                                     gruppo_tributo) cotr,
                              (select 0 rata
                                  from dual
                                 where p_rata is null
                                 union
                                select raim.rata
                                  from rate_imposta raim
                                 where tipo_tributo = p_tipo_tributo
                                   and anno = p_anno
                                   and cod_fiscale = p_cod_fiscale
                                  and rata = nvl(p_rata,rata)
                                  and ((p_gruppo_tributo is null) or
                                       (nvl(raim.conto_corrente,99990000) in (
                                            select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                                            from codici_tributo cotr
                                            where cotr.flag_ruolo is null
                                            and (cotr.gruppo_tributo = p_gruppo_tributo))
                                       )
                                  )
                               ) rate,
                               (select to_number(null) nvers
                                  from dual
                                 union
                                select rownum nvers
                                  from versamenti
                                 where tipo_tributo = p_tipo_tributo
                                   and cod_fiscale = p_cod_fiscale
                                   and anno = p_anno
                               ) vers,
                               -- Selezione speciale per servizi con dovuto_mb
                               (select distinct *
                                from
                                (select null as dovuto_mb
                                  from dual
                                 union
                                 select f_depag_dovuto_mb(p_tipo_tributo,p_anno,w_data_dovuto_mb)
                                 from dual
                                )) dovuto_mb
                           where
                               ((p_gruppo_tributo is null) or
                                (p_gruppo_tributo is not null) and (cotr.gruppo_tributo = p_gruppo_tributo)
                           )
                      )
                    order by servizio, idback
                    )
  loop
    w_dep_record := depag_service_pkg.dovuto_per_idback(sel_idback.idback, w_des_cliente, sel_idback.servizio);
    if w_dep_record.id is not null and
      (p_tipo_dovuto is null or
      (p_tipo_dovuto = 'NP' and
       w_dep_record.stato_invio_ricezione not in ('I','P','T'))) then
       p_tab_dovuti.extend;
       w_ind := w_ind + 1;
       p_tab_dovuti (w_ind) := w_dep_record;
       w_errore := 'Selezionato Idback: '||w_dep_record.idback||', Azione: '||w_dep_record.azione;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
    end if;
  end loop;

  open rc for select * from table(pagonline_tr4.f_get_collection);
  --
  return rc;
  --
end;

--------------------------------------------------------------------------------------------------------
function eliminazione_dovuti_ruolo
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
--, p_chk_rate                in number
) return number is

/*************************************************************************
 NOME:        ELIMINAZIONE_DOVUTI_RUOLO
 DESCRIZIONE: Elimina gli importi dovuti da PAGONLINE derivati da
              ruolo TARSU.

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_ruolo               Ruolo da elaborare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   07/07/2020  VD      Prima emissione.
 001   15/09/2021  VD      Correzione sequenza operazioni in caso di errore
                           (prima rollback, poi inserimento log).
 002   17/12/2021  VD      Modificata gesione segnalazioni di errore.
*************************************************************************/
RetVal                      VARCHAR2(8);
w_des_cliente               varchar2(60);
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
w_return                    number:= 0;
w_operazione_log            varchar2(100) := 'inserimento_dovuti';

w_errore                    varchar2(4000);
errore                      exception;
---------------------------------------------------------------------------------------------------
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;

  -- Si cancellano tutti i dovuti per tributo, anno, ruolo
  -- e codice fiscale indicato. Se l'eliminazione ruolo è generale, il codice
  -- fiscale sarà '%', per cui si cancellano tutte le righe per tributo, anno e ruolo.
  w_idback_ann := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||nvl(p_cod_fiscale,'%')||'%';
  w_operazione_log := 'Eliminazione_dovuti_ruolo-annulladovutilike';
  pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
  --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
  RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
  if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
     pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: Retval = '||RetVal);
     w_return := 1;
  else
     w_errore := w_idback_ann ||' ERRORE: Retval = '||Retval;
     raise errore;
  end if;
  --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
  return w_return;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end eliminazione_dovuti_ruolo;
--------------------------------------------------------------------------------------------------------
function inserimento_dovuti_ruolo
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
--, p_chk_rate                in number
) return number is

/*************************************************************************
 NOME:        INSERIMENTO_DOVUTI_RUOLO
 DESCRIZIONE: Carica l'elenco degli importi dovuti per PAGONLINE
              derivati da ruolo TARSU.

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_ruolo               Ruolo da elaborare
--            p_chk_rate            0 - calcolo senza rateizzazione
--                                  > 0 - calcolo con rateizzazione

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   07/07/2020  VD      Prima emissione.
 001   09/11/2020  VD      Modificata gestione sigla provincia/stato estero
 002   15/09/2021  VD      Passaggio a DEPAG_DOVUTI dei nuovi campi per
                           integrazione con contabilita' finanziaria.
                           Correzione sequenza operazioni in caso di errore
                           (prima rollback, poi inserimento log).
 003   17/12/2021  VD      Aggiunto test su flag integrazione con CFA: i
                           dati in depag_dovuti vengono inseriti solo se
                           l'integrazione e' attiva
                           Modificata gestione segnalazioni errore.
 004   05/10/2023  RV      #66207
                           Rivisto per scomposizione degli importi
 005   13/02/2025  RV      #77805
                           Rivisto per componenti perequative spalmate
 006   13/02/2025  RV      #77216
                           Rivisto per corretta gestione Bilancio con QUOTE_MB
 007   11/03/2025  RV      #78971
                           Sistemato per ruoli con eccedenze
*************************************************************************/
RetVal                      VARCHAR2(8);
w_titolo_log                varchar2(100) := 'Inserimento_dovuti_ruolo';
w_operazione_log            varchar2(100);
w_des_cliente               varchar2(60);
w_des_titr                  varchar2(5);
w_se_tratta_versamenti      varchar2(1);
w_tipo_ruolo                varchar2(1);
w_tipo_emissione            varchar2(1);
w_numero_rate               number;
w_ultimo_ruolo              number;
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
w_idback_vers               depag_dovuti.idback%TYPE;
w_importo_vers              number;
w_conta_vers                number;
w_return                    number:= 0;
w_ordinamento               varchar2(1);
w_cf_prec                   varchar2(16);
w_rata_prec                 number;
w_importo_vers_cf           number;
w_conta_vers_cf             number;
w_versato_idback            number;
w_conta_idback              number;
w_importo_dovuto            number;
w_importo_tefa              number;
w_dovuto_netto              number;

w_errore                    varchar2(4000);
errore                      exception;

w_flag_rate                 varchar2(1);
w_esiste_rata_u             number;
w_esiste_rate               number;
w_idback_ins                depag_dovuti.idback%TYPE;
w_idback_ref                depag_dovuti.rata_unica_ref%TYPE;

-- (VD - 15/09/2021): Dati per contabilita' finanziaria
w_int_cfa                   varchar2(1);
w_capitolo                  varchar2(200);
w_dati_riscossione          depag_dovuti.dati_riscossione%type;
w_accertamento              depag_dovuti.accertamento%type;
w_bilancio                  depag_dovuti.bilancio%type;

-- (RV - 31/08/2023: Dati per gestione scomposizione degli importi
w_dettagli_quote            depag_dovuti.quote_mb%type;
w_metadata_quote            depag_dovuti.metadata%type;
w_numero_quote              number;

w_flag_elimina_depag        varchar2(1);

-- Cursore per selezionare l'imposta da passare a DEPAG
cursor sel_mov is
   -- Selezione per emissione ruolo senza rateizzazione (o imposta non rateizzata perche'
   -- inferiore al limite indicato) o scelta rate ruolo = 'T' (tutte le rate)
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                        ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||
                                   rpad(cont.cod_fiscale,16)||impo.rata
                                    -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(p_tipo_tributo,'',null,impo.dovuto_mb) servizio
        , rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||rpad(cont.cod_fiscale,16)||impo.rata idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35)                                                 localita_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res))   prov_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))                    email_pagatore
        , pagonline_tr4.scadenza_rata_ruolo (p_ruolo, impo.rata)       data_scadenza
        , impo.importo importo_dovuto
        , nvl(impo.tefa,0) importo_tefa
        , impo.dovuto_mb
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        --, decode(p_anno, to_char(sysdate,'yyyy'),'', 'SOLLECITO ')||
        , w_des_titr||
          ', ANNO: '||p_anno||' (Lista N.'||p_ruolo||')'||
          ', RATA: '||decode(impo.rata,0,'UNICA',impo.rata) causale_versamento
        --, null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
        , impo.scadenza_avviso
        , decode(w_flag_rate,'T',impo.rata,to_number(null)) rata
        , impo.numero_rate
        , ruol.anno_emissione
        , ruol.anno_ruolo
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , ruoli            ruol
        , (select
                cod_fiscale, rata, scadenza_avviso, importo, numero_rate, dovuto_mb,
                f_calcolo_rata_rc_tarsu(cod_fiscale,p_ruolo,numero_rate,rata,'P','') tefa
           from
         (select ruco.cod_fiscale
                , 0                      rata
                , nvl(ruol.scadenza_avviso_unico, ruol.scadenza_avviso_1) as scadenza_avviso
                , max(f_importo_ruolo_ruxx(ruco.cod_fiscale, ruol.ruolo, 0, 'L')) as importo
                , nvl(ruol.rate,0) as numero_rate
                , ruol.dovuto_mb
             from ruoli_contribuente ruco,
                 (select ruol.*,
                         f_depag_dovuto_mb(ruol.tipo_tributo,ruol.anno_ruolo,ruol.data_emissione) as dovuto_mb
                    from ruoli ruol
                   where ruol.ruolo = p_ruolo
                 ) ruol
            where ruol.ruolo = p_ruolo
              and ruol.ruolo = ruco.ruolo
              and ruco.cod_fiscale like p_cod_fiscale
              and (decode(nvl(ruol.rate,0),0,1,ruol.rate) = 1 or
                   w_flag_rate in ('U','T'))
            group by ruco.cod_fiscale, ruol.scadenza_avviso_unico, ruol.scadenza_avviso_1, ruol.rate, ruol.dovuto_mb
            union
           select raim.cod_fiscale
                , raim.rata
                , decode(raim.rata
                        ,1,max(ruol.scadenza_avviso_1)
                        ,2,max(ruol.scadenza_avviso_2)
                        ,3,max(ruol.scadenza_avviso_3)
                        ,4,max(ruol.scadenza_avviso_4)
                        ,to_date(null)
                        ) scadenza_avviso
                -- #77805 : sostituito vecchia logica per applicazione sbilancio
                , (f_determina_rata(ruto.totale_sbilanciato,raim.rata,ruol.rate,0) +
                   f_sbilancio_tares(ruco.cod_fiscale,ruco.ruolo,raim.rata,0,'S')) importo
               , nvl(ruol.rate,0) numero_rate
               , ruol.dovuto_mb
            from ruoli_contribuente ruco,
                 (select
                    ruol.*,
                    f_depag_dovuto_mb(ruol.tipo_tributo,ruol.anno_ruolo,ruol.data_emissione) as dovuto_mb
                  from ruoli ruol
                  where ruol.ruolo = p_ruolo
                 ) ruol,
                 rate_imposta raim,
                -- #77805 : questa parte calcola l'importo del ruolo a cui applica l'eventuale sbilancio tares
                 (select
                    ruct.ruolo,
                    ruct.cod_fiscale,
                    ruct.importo_totale - ruct.sbilancio_ruolo as totale_sbilanciato
                 from
                    (select dett.ruolo,
                            dett.cod_fiscale,
                            f_importo_ruolo_ruxx(dett.cod_fiscale,dett.ruolo,0,'L') as importo_totale,
                            f_sbilancio_tares(dett.cod_fiscale,dett.ruolo,0,0,'S') as sbilancio_ruolo
                      from
                         (
                         select ruco.ruolo,
                                ruco.cod_fiscale
                           from ruoli_contribuente ruco
                          where ruco.ruolo = p_ruolo
                            and ruco.cod_fiscale like p_cod_fiscale
                         group by
                               ruco.ruolo,
                               ruco.cod_fiscale
                         ) dett
                   ) ruct
                 ) ruto
           where ruol.ruolo = p_ruolo
             and ruol.ruolo = ruco.ruolo
             and ruco.cod_fiscale = raim.cod_fiscale
             and ruco.oggetto_imposta = raim.oggetto_imposta
             and raim.anno = p_anno
             and raim.tipo_tributo = p_tipo_tributo
             and (decode(nvl(ruol.rate,1),0,1,ruol.rate) > 1 and
                  w_flag_rate in ('R','T'))
             and ruco.cod_fiscale = ruto.cod_fiscale
             and ruco.ruolo = ruto.ruolo
           group by raim.cod_fiscale, raim.rata, ruol.rate, ruol.dovuto_mb
               , ruto.totale_sbilanciato
               , f_sbilancio_tares(ruco.cod_fiscale,ruco.ruolo,raim.rata,0,'S')
            )) impo
    where cont.cod_fiscale like p_cod_fiscale
      and ruol.ruolo = p_ruolo
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and impo.cod_fiscale = cont.cod_fiscale
    order by 1,2,6;
---------------------------------------------------------------------------------------------------
  begin
    select ruol.flag_elimina_depag
      into w_flag_elimina_depag
      from ruoli ruol
     where ruol.ruolo = p_ruolo;

    w_des_cliente := pagonline_tr4.descrizione_ente;
    w_des_titr    := f_descrizione_titr(p_tipo_tributo,p_anno);
    -- Si memorizza il tipo di ordinamento da utilizzare nella emissione dei dovuti
    w_ordinamento := nvl(f_inpa_valore('PAGONL_ORD'),'A');
    -- Si memorizza il trattamento delle rate da apposito parametro in installazione_parametri
    -- U - solo rata unica
    -- R - solo rate
    -- T - rata unica + rate
    w_flag_rate   := nvl(f_inpa_valore('DEPA_RATE'),'R');
    -- (VD - 17/12/2021): si seleziona il flag per verificare l'integrazione con CFA
    w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');

    -- Si verificano tipo emissione e tipo ruolo per determinare il trattamento dei versamenti
    -- (VD - 24/11/2020): si trattano i versamenti eseguiti anche per i suppletivi totali
    begin
      select decode(tipo_ruolo,1,'P','S')
           , tipo_emissione
           , decode(tipo_emissione,'T','S','N')
           , rate
        into w_tipo_ruolo
           , w_tipo_emissione
           , w_se_tratta_versamenti
           , w_numero_rate
        from ruoli
       where ruolo = p_ruolo
         --and tipo_ruolo = 1           -- principale
         and specie_ruolo = 0         -- NON coattivo
         --and tipo_emissione = 'T'    -- totale
         ;
    exception
      when others then
        w_tipo_ruolo           := null;
        w_tipo_emissione       := null;
        w_se_tratta_versamenti := null;
    end;
    -- Non si trattano i ruoli coattivi
    if w_tipo_ruolo is null then
       w_errore := 'Ruolo '||p_ruolo||' non esistente o di specie non prevista (coattivo)';
       w_operazione_log := 'Inserimento_dovuti_ruolo-uscita';
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       return w_errore;
    end if;
    -- (VD - 15/09/2021): nuovi dati per integrazione con contabilita' finanziaria
    -- Determinazione accertamento contabile abbinato all'imposta
    -- (da memorizzare nel campo "accertamento" di depag_dovuti)
    -- (VD - 17/12/2021): i dati si predispongono solo se l'integrazione e' attiva
    w_accertamento := null;
    w_dati_riscossione := null;
    w_capitolo := null;
    if w_int_cfa = 'S' then
       w_accertamento := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                               , p_anno
                                                               , 'O'               -- tipo_imposta
                                                               , to_char(null)     -- tipo_pratica
                                                               , trunc(sysdate)    -- data_emissione
                                                               , to_char(null)     -- cod_tributo_f24
                                                               , to_char(null)     -- stato_pratica
                                                               );
       -- Determinazione capitolo abbinato all'accertamento contabile
       -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
       if w_accertamento is not null then
          w_capitolo := dati_contabili_pkg.f_get_capitolo( p_anno
                                                         , to_number(substr(w_accertamento,1,4))
                                                         , to_number(substr(w_accertamento,6))
                                                         );
       end if;
    end if;
    -- Prima di elaborare, si cancellano tutti i dovuti per tributo, anno, ruolo
    -- e codice fiscale indicato. Se l'emissione ruolo è generale, il codice
    -- fiscale sarà '%', per cui si cancellano tutte le righe per tributo, anno e ruolo.
    w_idback_ann := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||p_cod_fiscale||'%';
    w_operazione_log := w_titolo_log||' - annulladovutilike';
    pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
    --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
    if (w_flag_elimina_depag = 'S') then
       RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
    end if;
    if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 or
       to_number(ltrim(RetVal,'PO')) = 100 then
       pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: RetVal = '||RetVal);
    else
       w_errore := w_idback_ann ||'ERRORE: RetVal = '||Retval;
       raise errore;
    end if;
    --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);

    -- Creazione dovuti per ruolo emesso
    w_operazione_log := w_titolo_log||' - inizio trattamento';
    pagonline_tr4.inserimento_log(w_operazione_log, w_des_cliente||' ' ||p_tipo_tributo||' ' ||p_anno);
    w_cf_prec         := '*';
    for rec_mov in sel_mov
    loop
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', IMPORTO: '||REC_MOV.IMPORTO_dovuto);
      if rec_mov.cod_fiscale <> w_cf_prec then
         w_cf_prec         := rec_mov.cod_fiscale;
         w_rata_prec       := rec_mov.rata;
         w_importo_vers_cf := 0;
         w_conta_vers_cf   := 0;
         w_importo_vers    := 0;
         w_conta_vers      := 0;
         w_esiste_rata_u   := 0;
         w_esiste_rate     := 0;
         w_idback_ann      := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||rec_mov.cod_fiscale||'%';
         if w_flag_rate = 'T' then
            if nvl(w_numero_rate,1) > 1 then
               pagonline_tr4.controllo_rate_emesse (w_des_cliente, rec_mov.servizio, w_idback_ann
                                                   ,w_esiste_rata_u, w_esiste_rate);
            end if;
            --dbms_output.put_line('Esiste rata unica: '||w_esiste_rata_u);
            --dbms_output.put_line('Esistono rate: '||w_esiste_rate);
         end if;
         -- Gestione del versato: ora si verifica se esistono dei versamenti per contribuente
         -- e se esistono si attribuiscono alle varie rate a scalare
         if w_se_tratta_versamenti = 'S' then
            -- Si controlla l'esistenza di eventuali versamenti
            -- (VD - 17/12/2020): si considerano solo i versamenti senza idback,
            --                    quelli con idback saranno trattati a livello
            --                    di singola rata
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
                 and vers.cod_fiscale        = rec_mov.CODICE_IDENT
                 and vers.anno               = p_anno
                 and vers.pratica            is null
                 and vers.idback             is null
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
            w_importo_vers_cf := w_importo_vers;
            w_conta_vers_cf   := w_conta_vers;
            -- Se si sta trattando un ruolo totale (principale o suppletivo), si eliminano le
            -- posizioni debitorie dell'ultimo ruolo emesso
            if w_tipo_emissione = 'T' then
               w_ultimo_ruolo := f_get_ultimo_ruolo (rec_mov.cod_fiscale,p_anno,p_tipo_tributo
                                                    ,w_tipo_emissione,w_tipo_ruolo,'S');
               if w_ultimo_ruolo is not null then
                  w_idback_ann := rpad(p_tipo_tributo,5)||p_anno||lpad(w_ultimo_ruolo,10,'0')||rec_mov.cod_fiscale||'%';
                  w_operazione_log := w_titolo_log||' - annulladovutilike ruoli prec.';
                  pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
                  --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
                  if (w_flag_elimina_depag = 'S') then
                     RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
                  end if;
                  -- (VD - 07/09/2022): se il ruolo precedente è già stato saldato va bene lo stesso (cod. PO0100),
                  --                    non bisogna dare errore
                  if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 or
                     to_number(ltrim(RetVal,'PO')) = 100 then
                     pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: RetVal = '||RetVal);
                  else
                     w_errore := w_idback_ann ||' ERRORE: RetVal = '||Retval;
                     raise errore;
                  end if;
                  --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
                  --
                  -- #79482 : In caso di ruoli precedenti conteggiamo tutti i versamenti su ruolo per l'anno,
                  --          escluso il ruolo in lavorazione, contabilizzato a parte (Vedi poi)
                  w_idback_vers := rpad(p_tipo_tributo,5)||p_anno||'%'||rec_mov.cod_fiscale||'%';
                  pagonline_tr4.versato_per_idback(p_tipo_tributo,rec_mov.cod_fiscale,p_anno,
                                                       w_idback_vers,rec_mov.idback,w_versato_idback,w_conta_idback);
                  w_importo_vers_cf := w_importo_vers_cf + w_versato_idback;
                  w_importo_vers    := w_importo_vers + w_versato_idback;
               end if;
            end if;
         end if;
      else
         if w_flag_rate = 'T' and
            rec_mov.rata > 0  and
            w_rata_prec = 0 then
            w_rata_prec := rec_mov.rata;
            w_importo_vers := w_importo_vers_cf;
            w_conta_vers   := w_conta_vers_cf;
         end if;
      end if;
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', versato: '||w_importo_vers);

      if nvl(rec_mov.importo_dovuto,0) > 0 then
         w_importo_dovuto := rec_mov.importo_dovuto;
         w_importo_tefa := rec_mov.importo_tefa;
         --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', importo dovuto (1): '||w_importo_dovuto);
         if w_flag_rate = 'T' and w_numero_rate > 1 then
            if w_esiste_rata_u = 0 and rec_mov.rata = 0 then
               w_importo_dovuto := 0;
            elsif
               w_esiste_rate = 0 and rec_mov.rata > 0 then
               w_importo_dovuto := 0;
            end if;
         end if;
         if w_importo_dovuto > 0 then
            -- Conteggia gli eventuali versamenti collegati al ruolo attuale
            pagonline_tr4.versato_per_idback(p_tipo_tributo,rec_mov.codice_ident,p_anno,
                                                  rec_mov.idback,null,w_versato_idback,w_conta_idback);
            --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', versato PER IDBACK: '||w_versato_idback);
            if w_versato_idback <= w_importo_dovuto then
               w_importo_dovuto := w_importo_dovuto - w_versato_idback;
            else
               w_importo_dovuto := 0;
            end if;
            --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', importo dovuto (2): '||w_importo_dovuto);
         end if;
         if w_importo_dovuto > 0 then
            if w_importo_vers <= w_importo_dovuto then
               w_importo_dovuto := w_importo_dovuto - w_importo_vers;
               w_importo_vers := 0;
            else
               w_importo_vers := w_importo_vers - w_importo_dovuto;
               w_importo_dovuto := 0;
            end if;
         end if;
         --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', importo dovuto (3): '||w_importo_dovuto);
         if w_importo_dovuto > 0 then
            -- Si compone l'idback tenendo conto del numero di versamenti gia' eseguiti
            -- Attenzione: in presenza di versamenti con idback e senza, potrebbero crearsi
            -- degli idback uguali. Per il momento il caso non è gestito, visto che dovrebbe
            -- essere un'ipotesi piuttosto remota
            if w_conta_idback = 0 then
               if w_conta_vers = 0 then
                  w_idback_ins := rec_mov.idback;
               else
                  w_idback_ins := rec_mov.idback||'-'||w_conta_vers;
               end if;
            else
               w_idback_ins := rec_mov.idback||'-'||w_conta_idback;
            end if;
            -- Se flag_rate = 'T' (sia rata unica che rate) e il numero di rate del ruolo e' > 1
            -- occorre valorizzare i campi di riferimento
            if w_flag_rate = 'T' and
               nvl(rec_mov.numero_rate,0) > 1 and
               w_esiste_rata_u = 1 and
               w_esiste_rate = 1 then
               if rec_mov.rata = 0 then
                  w_idback_ref := w_idback_ins;
               end if;
            else
               w_idback_ref := null;
            end if;
            --dbms_output.put_line('Idback ref: '||w_idback_ref);
            --
            --dbms_output.put_line('Prima di depag_service');
            w_operazione_log := w_titolo_log||' - aggiornadovuto';
            pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ins||' '||rec_mov.CODICE_IDENT); --w_des_cliente);
            --
            -- (RV - 31/08/2023): gestione scomposizione degli importi
            --
            if nvl(rec_mov.dovuto_mb,'N') = 'S' then
              w_dovuto_netto := w_importo_dovuto - w_importo_tefa;
            --dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', dovuto : '||w_importo_dovuto||', TEFA : '||w_importo_tefa||', netto : '||w_dovuto_netto);
              --
              w_numero_quote := prepara_scomposizione_importi ( p_tipo_tributo,p_anno,rec_mov.anno_emissione,
                                                                     w_dovuto_netto, w_importo_tefa,
                                                                     w_dettagli_quote, w_metadata_quote );
            else
              w_numero_quote := 0;
            end if;
            --
            if(w_numero_quote < 1) then
              w_dovuto_netto := w_importo_dovuto;
              w_dettagli_quote := null;
              w_metadata_quote := null;
            end if;
            --
            -- (VD - 15/09/2021): Dati per contabilita' finanziaria
            -- Composizione del campo "bilancio"
            -- (VD - 17/12/021): il campo "bilancio" si compone solo se l'integrazione e' attiva
            --                   e i dati riscossione e accertamento sono valorizzati
            if w_int_cfa = 'S' and
               w_capitolo is not null and
               w_accertamento is not null then
               w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_capitolo
                                                               , w_accertamento
                                                               , w_dovuto_netto
                                                               );
                w_dati_riscossione := dati_contabili_pkg.f_get_dati_riscossione (w_capitolo);
            else
               w_bilancio := null;
            end if;
            --
            -- Aggiorna il dovuto
            --
            RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ENTE,
                                                     rec_mov.IUD, --iud
                                                     rec_mov.SERVIZIO,
                                                     w_idback_ins,
                                                     rec_mov.BACKEND,
                                                     rec_mov.COD_IUV,
                                                     rec_mov.TIPO_IDENT,
                                                     rec_mov.CODICE_IDENT,
                                                     rec_mov.ANAG_PAGATORE,
                                                     rec_mov.INDIRIZZO_PAGATORE,
                                                     substr(rec_mov.CIVICO_PAGATORE,1,16),
                                                     rec_mov.CAP_PAGATORE,
                                                     rec_mov.LOCALITA_PAGATORE,
                                                     rec_mov.PROV_PAGATORE,
                                                     rec_mov.NAZ_PAGATORE,
                                                     rec_mov.EMAIL_PAGATORE,
                                                     rec_mov.DATA_SCADENZA,
                                                     w_importo_dovuto,
                                                     rec_mov.COMMISSIONE_CARICO_PA,
                                                     rec_mov.TIPO_DOVUTO,
                                                     rec_mov.TIPO_VERSAMENTO,
                                                     rec_mov.CAUSALE_VERSAMENTO,
                                                     --rec_mov.DATI_RISCOSSIONE,
                                                     w_dati_riscossione,
                                                     rec_mov.UTENTE_ULTIMO_AGG,
           -- (VD - 27/11/2020: nuovi campi per gestione rate
                                                     to_char(null),  -- note
                                                     to_char(null),  -- dati_extra
                                                     w_accertamento, -- accertamento
                                                     w_bilancio,     -- bilancio
                                                     rec_mov.scadenza_avviso,
                                                     case
                                                       when w_idback_ref is null then
                                                         to_number(null)
                                                       else
                                                         rec_mov.rata
                                                     end,
                                                     w_idback_ref,
           -- (RV - 31/08/2023: nuovi campi per gestione scomposizione degli importi
                                                    null,            -- dicitura_scadenza
                                                    w_dettagli_quote,
                                                    w_metadata_quote
                                                    );
            --dbms_output.put_line('Dopo depag_service - retval: '||retval);
            if RetVal is null or to_number(ltrim(retval,'PO')) < 10 then --in ('PO0100','PO0099') then
               pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ins||' OK: Retval = '||RetVal);
               w_return := w_return +1;
            else
               w_errore := 'Errore in inserimento DEPAG_DOVUTI 1 '||rec_mov.idback||' Retval = '||Retval;
               --pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
               --w_errore := null;
               raise errore;
            end if;
         end if;
      end if;
    end loop;

   return w_return;

exception
  when errore then
       ROLLBACK;
     --dbms_output.put_line('Errore : ' || w_errore);
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
     --dbms_output.put_line(w_errore);
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end inserimento_dovuti_ruolo;
--------------------------------------------------------------------------------------------------------
function determina_dovuti_ruolo
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
, p_tipo_dovuto             in varchar2 default null
, p_max_rata                in number default null
) return sys_refcursor is
/*************************************************************************
 NOME:         DETERMINA_DOVUTI_RUOLO
 DESCRIZIONE:  Restituisce un elenco di dovuti gia' passati a DEPAG
               per cui deve essere lanciato il web-service di allineamento
               al partner tecnologico

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
              p_anno                Anno di riferimento
              p_ruolo               Ruolo da elaborare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   27/02/2024  RV      #55403
                           Aggiunta parametro p_max_rata a determina_dovuti_ruolo
 001   23/01/2024  RV      #66207
                           Aggiunto gestione flag dovuto mb
 000   08/09/2020  VD      Prima emissione.
*************************************************************************/
  w_operazione_log         varchar2(100):= 'determina_dovuti_ruolo';
  w_errore                 varchar2(4000);
  w_ind                    number;
  w_des_cliente            varchar2(60);
  w_numero_rate            number;
  w_dep_record             depag_dovuti%rowtype;
  rc                       sys_refcursor;

begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  --
  if p_max_rata is not null and p_max_rata >= 0 and p_max_rata <= 4 then
     -- Usa il numero di rate passato alla procedure
     w_numero_rate := p_max_rata;
  else
    -- Selezione numero rate da ruolo
    begin
      select ruol.rate
        into w_numero_rate
        from ruoli ruol
       where ruolo = p_ruolo;
    exception
      when others then
        w_numero_rate := 0;
    end;
  end if;
  --
  p_tab_dovuti.delete;
  w_ind := 0;
  --
  for sel_idback in (select distinct
                            f_depag_servizio(p_tipo_tributo,'',null,dovuto_mb) servizio,
                            rpad(p_tipo_tributo,5)||
                            p_anno||
                            lpad(p_ruolo,10,'0')||
                            rpad(p_cod_fiscale,16)||
                            rate.rata||
                            decode(vers.nvers,null,null,'-'||vers.nvers) idback
                       from (select level-1 rata
                               from dual
                            connect by level <= w_numero_rate + 1
                            ) rate,
                            (select to_number(null) nvers
                               from dual
                              union
                             select rownum nvers
                               from versamenti
                              where tipo_tributo = p_tipo_tributo
                                and cod_fiscale = p_cod_fiscale
                                and anno = p_anno
                            ) vers,
                           (select null as dovuto_mb from dual
                            union
                            select 'S' from dual) dovuto_mb
                        order by 1
                     )
  loop
    w_dep_record := depag_service_pkg.dovuto_per_idback(sel_idback.idback, w_des_cliente, sel_idback.servizio);
    if w_dep_record.id is not null and
      (p_tipo_dovuto is null or
      (p_tipo_dovuto = 'NP' and
       w_dep_record.stato_invio_ricezione not in ('I','P','T'))) then
       p_tab_dovuti.extend;
       w_ind := w_ind + 1;
       p_tab_dovuti (w_ind) := w_dep_record;
       w_errore := 'Selezionato Idback: '||w_dep_record.idback||', Azione: '||w_dep_record.azione;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
    end if;
  end loop;

  open rc for select * from table(pagonline_tr4.f_get_collection);
  --
  return rc;
  --
end;
-------------------------------------------------------------------------------
function aggiorna_dovuto_pagopa
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
) return varchar2 is
/******************************************************************************
 NOME:         AGGIORNA_DOVUTO_PAGOPA
 DESCRIZIONE:  Esegue l'aggiornamento degli importi dovuti gia' passati
               a PagoPA, tenendo conto di sgravi e compensazioni

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
              p_anno                Anno di riferimento
              p_ruolo               Ruolo da elaborare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/09/2020  VD      Prima emissione.
 001   09/11/2020  VD      Modificata gestione sigla provincia/stato estero
 002   15/09/2021  VD      Passaggio a DEPAG_DOVUTI dei nuovi campi per
                           integrazione con contabilita' finanziaria.
                           Correzione sequenza operazioni in caso di errore
                           (prima rollback, poi inserimento log).
 003   17/12/2021  VD      Aggiunto test su flag integrazione con CFA: i
                           dati in depag_dovuti vengono inseriti solo se
                           l'integrazione e' attiva
                           Modificata gestione segnalazioni errore.
 004   05/10/2023  RV      #66207 : Rivisto per scomposizione degli importi
 005   24/11/2023  VM      #66207: Corretto calcolo importo_netto e importo_tefa
                           su rata unica per scomposizione degli importi
 006   31/05/2024  RV      #72976
                           Soppresso rimozione Maggiorazioni Tares da importi
                           al fine di gestire le Componenti Perequative
 007   29/01/2025  RV      #77216
                           Rivisto per corretta gestione Bilancio con QUOTE_MB
 008   31/07/2025  RV      #82362
                           Aggiunta gestione sbilancio da Componenti Perequative
 009   29/09/2025  RV      #83103
                           Sistemato aggiorna_dovuto_pagopa per Sgravi Maggiorazione TARES
******************************************************************************/
  w_utente_ultimo_agg      varchar(8)   := 'TRIBUTI';
  w_titolo_log             varchar2(100) := 'Aggiorna_dovuto_pagopa';
  w_operazione_log         varchar2(100);
  w_errore                 varchar2(4000);
  w_des_cliente            varchar2(60);
  w_des_titr               varchar2(5);
  w_flag_rate              varchar2(1);
  w_specie_ruolo           number;
  w_numero_rate            number;
  w_dovuto_mb              varchar(2);
  w_servizio               depag_dovuti.servizio%type;
  w_idback_ann             depag_dovuti.idback%TYPE;
  w_idback                 depag_dovuti.idback%TYPE;
  w_idback_ref             depag_dovuti.rata_unica_ref%TYPE;
  w_esiste_rata_u          number;
  w_esiste_rate            number;
  w_messaggio              varchar2(2000);
  retval                   varchar2(6);
  errore                   exception;

-- (VD - 15/09/2021): Dati per contabilita' finanziaria
  w_int_cfa                   varchar2(1);
  w_capitolo                  varchar2(200);
  w_dati_riscossione          depag_dovuti.dati_riscossione%type;
  w_accertamento              depag_dovuti.accertamento%type;
  w_bilancio                  depag_dovuti.bilancio%type;

-- (RV - 01/09/2023: Dati per gestione scomposizione degli importi
  w_dettagli_quote            depag_dovuti.quote_mb%type;
  w_metadata_quote            depag_dovuti.metadata%type;
  w_numero_quote              number;
  w_dovuto_netto              number;

  cursor sel_mov is
    select cont.cod_fiscale cod_fiscale
         , w_des_cliente ente
         , null iud
         , f_depag_servizio(p_tipo_tributo,'',null,ruol.dovuto_mb) servizio
         , null backend
         , null cod_iuv
         , decode(sogg.tipo_residente
                 ,0,'F'
                   ,decode(sogg.tipo
                          ,0,'F'
                          ,1,'G'
                            ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
         , cont.cod_fiscale codice_ident
         , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
         , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                 ,null,decode(sogg.cod_via
                             ,null,sogg.denominazione_via
                                  ,arvi.denom_uff)
                      ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
         , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                 ,null,to_char(sogg.num_civ)||
                       decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                       decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                      ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                       decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                             ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                       decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                             ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                 ) civico_pagatore
         , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                 ,null,lpad(sogg.cap,5,'0')
                      ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
         , substr(nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
                     ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                 ,1,35) localita_pagatore
         , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SPS')
              ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
--         , 'IT'                                                       naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
         , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
               f_recapito(sogg.ni,p_tipo_tributo,2))                  email_pagatore
         , pagonline_tr4.scadenza_rata_ruolo (p_ruolo, rate.rata)     data_scadenza
         , pagonline_tr4.scadenza_rata_avviso (p_ruolo, rate.rata)    data_scadenza_avviso
         , decode(sign(rate.rata - tares.rate_versate)
                 ,1, decode (rate.rata
                            ,tares.rate, importo_ultima_rata + rate.sbilancio
                            ,tares.importo_tares + rate.sbilancio
                            )
                 ,0, decode (rate.rata
                            ,tares.rate, (tares.importo_tares * (rate.rata-1)) + importo_ultima_rata + rate.sbilancio_rate
                            ,(tares.importo_tares * rate.rata) + rate.sbilancio_rate
                            )
                     - round (tares.versato)
                 ,0
                 ) importo_dovuto
         , f_calcolo_rata_rc_tarsu(cont.cod_fiscale,p_ruolo,tares.rate,rate.rata,'P','') importo_tefa
         , null commissione_carico_pa
         ,'TRIBUTO' tipo_dovuto
         , null tipo_versamento
         --, decode(p_anno, to_char(sysdate,'yyyy'),'', 'SOLLECITO ')||w_des_titr||
         , w_des_titr||
           ', ANNO: '||p_anno||' (Lista N.'||p_ruolo||')'||
           ', RATA: '||decode(tares.rata_stampa,0,'UNICA',rate.rata) causale_versamento
         --, null dati_riscossione
         , w_utente_ultimo_agg utente_ultimo_agg
         , rate.rata rata
         , tares.conta_vers
         , round(tares.importo_tot) importo_tot
         , f_calcolo_rata_rc_tarsu(cont.cod_fiscale,p_ruolo,tares.rate,0,'P','') importo_tefa_tot
         , ruol.anno_emissione
         , ruol.dovuto_mb
      from archivio_vie arvi
         , soggetti sogg
         , contribuenti cont
         , (select ruol.*,
            f_depag_dovuto_mb(ruol.tipo_tributo,ruol.anno_ruolo,ruol.data_emissione) as dovuto_mb
           from ruoli ruol
           where ruol.ruolo = p_ruolo) ruol
         , (select max(decode(ruol_prec.rate,0,1,null,1,ruol_prec.rate)) rate
              from ruoli ruol_prec, ruoli ruol, parametri param
             where nvl (ruol_prec.tipo_emissione(+), 'T') = 'A'
               and ruol_prec.invio_consorzio(+) is not null
               and ruol_prec.anno_ruolo(+) = ruol.anno_ruolo
               and ruol_prec.tipo_tributo(+) || '' = ruol.tipo_tributo
               and ruol.ruolo = p_ruolo
           ) ruol_prec
         , (select imco1.importo_rata importo_tares
                  ,imco1.versato
                  ,imco1.importo_tot
                  ,imco1.num_fab_tares
                  ,imco1.rate
                  ,imco1.rata_stampa
                  ,imco1.conta_vers
                  ,imco1.ruolo
                  ,imco1.cod_fiscale
                  ,imco1.maggiorazione_tares
                  ,decode(imco1.importo_rata
                         ,0,0
                         ,decode(sign(ceil (imco1.versato / imco1.importo_rata) - imco1.rate)
                                ,0,imco1.rate
                                ,1,imco1.rate
                                ,ceil (imco1.versato / imco1.importo_rata)
                                )
                         ) rate_versate
                  ,decode(imco1.importo_rata
                         ,0,imco1.importo_tot
                         ,round (imco1.importo_tot
                                 - imco1.sbilancio_tot
                                 - ((imco1.importo_rata - (imco1.versato - (imco1.importo_rata *
                                     decode(trunc(imco1.versato / imco1.importo_rata),
                                            ceil(imco1.versato / imco1.importo_rata),
                                            trunc(imco1.versato / imco1.importo_rata) - 1,
                                            trunc(imco1.versato / imco1.importo_rata)))))
                                 + (imco1.importo_rata * (imco1.rate - ceil (imco1.versato / imco1.importo_rata)-1))))
                         ) importo_ultima_rata
              from (select round((round((nvl(sum(ruog.importo),0)
                              -- #72976     - nvl(sum(ogim.maggiorazione_tares),0)
                                            )
                                              - ruog.sbilancio_tot
                                              + nvl (max (eccedenze.importo), 0)
                                              + nvl (max (sanzioni.sanzione), 0)
                                              - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                     ,ruog.cod_fiscale
                                                                     ,ruol.tipo_tributo
                                                                     ,ruog.ruolo
                                                                     ,'S'
                                                                     )
                              -- #83103     + f_tot_vers_cont_ruol (ruol.anno_ruolo
                              --                                     ,ruog.cod_fiscale
                              --                                     ,ruol.tipo_tributo
                              --                                     ,ruog.ruolo
                              --                                     ,'SM'
                              --                                     )
                                              - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                     ,ruog.cod_fiscale
                                                                     ,ruol.tipo_tributo
                                                                     ,ruog.ruolo
                                                                     ,'C'
                                                                     )
                                             ,0
                                             ))
                                    / decode (ruol.rate
                                             ,null, 1
                                             ,0, 1
                                             ,ruol.rate
                                             )
                                   ,0
                                   )
                               importo_rata
                            ,decode (nvl (ruol.tipo_emissione, 'T')
                                    ,'T',f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                              ,ruog.cod_fiscale
                                                              ,ruol.tipo_tributo
                                                              ,null
                                                              ,'VN'
                                                              )
                                         + decode (ruol.tipo_ruolo
                                                  ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                                  ,0
                                                  )
                                    ,0)
                               versato
                            , (( nvl(sum(ruog.importo),0)
                         -- #72976    - nvl (sum (ogim.maggiorazione_tares), 0)
                               )
                               + nvl (max (eccedenze.importo), 0)
                               + nvl (max (sanzioni.sanzione), 0)
                               - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                      ,ruog.cod_fiscale
                                                      ,ruol.tipo_tributo
                                                      ,ruog.ruolo
                                                      ,'S'
                                                      )
                  -- #83103    + f_tot_vers_cont_ruol (ruol.anno_ruolo
                  --                                  ,ruog.cod_fiscale
                  --                                  ,ruol.tipo_tributo
                  --                                  ,ruog.ruolo
                  --                                  ,'SM'
                  --                                  )
                               - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                      ,ruog.cod_fiscale
                                                      ,ruol.tipo_tributo
                                                      ,ruog.ruolo
                                                      ,'C'
                                                      )
                               - decode (nvl (ruol.tipo_emissione, 'T')
                                        ,'T', f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                              ,ruog.cod_fiscale
                                                                              ,ruol.tipo_tributo
                                                                              ,null
                                                                              ,'VN'
                                                                              )
                                             + decode (ruol.tipo_ruolo
                                                      ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'N'),0)
                                                      ,0
                                                      )
                                        ,0
                                        ))
                               importo_tot
                            ,  greatest(0,sum (ogim.maggiorazione_tares)
                             - decode (nvl (ruol.tipo_emissione, 'T')
                                      ,'T', f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                                 ,ruog.cod_fiscale
                                                                 ,ruol.tipo_tributo
                                                                 ,null
                                                                 ,'M'
                                                                 )
                                           + decode (ruol.tipo_ruolo
                                                    ,2, round(F_IMPOSTA_EVASA_ACC(ruog.cod_fiscale,'TARSU',ruol.anno_ruolo,'S'),0)
                                                    ,0
                                                    )
                                      ,0
                                      )
                             - f_tot_vers_cont_ruol (ruol.anno_ruolo
                                                    ,ruog.cod_fiscale
                                                    ,ruol.tipo_tributo
                                                    ,ruog.ruolo
                                                    ,'SM'
                                                    ))
                               maggiorazione_tares
                            ,count (1) num_fab_tares
                            ,decode (ruol.rate,  null, 1,  0, 1,  ruol.rate) rate
                            ,decode(nvl(ruol.rate,1),1,0,ruol.rate) rata_stampa -- per stampa "rata unica"
                            ,ruog.ruolo
                            ,ruog.cod_fiscale
                            ,(select count(*)
                                from versamenti vers
                               where vers.tipo_tributo||''   = p_tipo_tributo
                                 and vers.cod_fiscale        = ruog.cod_fiscale
                                 and vers.anno               = p_anno
                                 and vers.pratica            is null
                                 and nvl(ruol.tipo_emissione,'T') = 'T') conta_vers
                             ,ruog.sbilancio_tot
                        from oggetti_imposta ogim
                            ,(select ruog.*,
                                     f_sbilancio_tares(ruog.cod_fiscale,ruog.ruolo,0,0,'S') as sbilancio_tot
                                from ruoli_contribuente ruog
                               where ruog.ruolo = p_ruolo
                                 and ruog.cod_fiscale = p_cod_fiscale
                             ) ruog
                            ,ruoli ruol
                            ,sanzioni
                            ,(select sum(importo_ruolo) as importo
                                from ruoli_eccedenze ruec
                               where ruec.ruolo = p_ruolo
                                 and ruec.cod_fiscale = p_cod_fiscale
                             ) eccedenze
                       where ruog.ruolo = ruol.ruolo
                         and ruog.oggetto_imposta = ogim.oggetto_imposta
                         and ruog.cod_fiscale like p_cod_fiscale
                         and ruol.ruolo = p_ruolo
                         and sanzioni.cod_sanzione(+) = 115
                         and sanzioni.tipo_tributo(+) = ruol.tipo_tributo
                         and sanzioni.sequenza = 1
                    group by ruog.ruolo
                            ,ruog.cod_fiscale
                            ,ruol.rate
                            ,ruol.tipo_emissione
                            ,ruol.anno_ruolo
                            ,ruol.tipo_tributo
                            ,ruol.tipo_ruolo
                            ,ruog.sbilancio_tot) imco1) tares
          ,(select rats.rata,
                    rats.sbilancio,
                    sum(rats.sbilancio) over(ORDER BY rats.rata ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as sbilancio_rate
               from (select ratn.rata,
                            f_sbilancio_tares(p_cod_fiscale,p_ruolo,ratn.rata,0,'S') as sbilancio
                       from (select 1 rata from dual
                             union all
                             select 2 rata from dual
                             union all
                             select 3 rata from dual
                             union all
                             select 4 rata from dual
                             union all
                             select 5 rata from dual
                            ) ratn
                    ) rats
            ) rate
      where cont.cod_fiscale = p_cod_fiscale -- l'operazione viene eseguita per un singolo c.f.
        and cont.ni = sogg.ni
        and sogg.cod_via = arvi.cod_via (+)
        and rate.rata <= tares.rate
        and ruol.ruolo = p_ruolo
        and tares.cod_fiscale = cont.cod_fiscale
        and tares.ruolo = ruol.ruolo
        and (tares.importo_tot > 0.49
          or nvl (tares.maggiorazione_tares, 0) > 0.49)
        and (decode (sign (rate.rata - tares.rate_versate)
                  ,1, decode (rate.rata
                             ,tares.rate, importo_ultima_rata + rate.sbilancio
                             ,tares.importo_tares + rate.sbilancio
                             )
                  ,0,   decode (rate.rata
                               ,tares.rate, (tares.importo_tares * (rate.rata-1)) + importo_ultima_rata + rate.sbilancio_rate
                               , (tares.importo_tares * rate.rata) + rate.sbilancio_rate
                               )
                      - round (tares.versato)
                  ,0
                  ) > 0
          OR  (      decode (rate.rata
                               ,tares.rate,decode (sign (rate.rata - tares.rate_versate)
                  ,1, nvl (tares.maggiorazione_tares, 0)
                  ,0,   nvl (tares.maggiorazione_tares, 0)
                  ,nvl (tares.maggiorazione_tares, 0)),0)
                  > 0   )  )
      order by rate.rata;
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  w_des_titr    := f_descrizione_titr(p_tipo_tributo,p_anno);
  -- Si memorizza il trattamento delle rate da apposito parametro in installazione_parametri
  -- U - solo rata unica
  -- R - solo rate
  -- T - rata unica + rate
  w_flag_rate   := nvl(f_inpa_valore('DEPA_RATE'),'R');
  -- (VD - 17/12/2021): si seleziona il flag per verificare l'integrazione con CFA
  w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');
  -- (VD - 12/10/2020): Verifica tipo ruolo. Se ruolo suppletivo non si esegue nessuna operazione
  -- (VD - 02/12/2020): Eliminato controllo su tipo_ruolo: ora si trattano anche i suppletivi
  --                    Aggiunta selezione numero rate per gestione rata unica/solo rate/tutte
  begin
    select ruol.specie_ruolo
         , nvl(ruol.rate,0)
         , f_depag_dovuto_mb(ruol.tipo_tributo,ruol.anno_ruolo,ruol.data_emissione)
      into w_specie_ruolo
         , w_numero_rate
         , w_dovuto_mb
      from ruoli ruol
     where ruolo = p_ruolo
       and specie_ruolo = 0; -- NON coattivo
  exception
    when others then
      w_specie_ruolo := to_number(null);
      w_numero_rate  := to_number(null);
      w_dovuto_mb    := null;
  end;
  --
  w_servizio    := f_depag_servizio(p_tipo_tributo,'',null,w_dovuto_mb);
  --
  if w_specie_ruolo is null then
     w_messaggio := 'Ruolo '||p_ruolo||' non esistente o di specie non prevista (coattivo)';
     w_operazione_log := w_titolo_log||' - uscita';
     pagonline_tr4.inserimento_log(w_operazione_log, w_messaggio);
     return w_messaggio;
  end if;
  -- (VD - 04/12/2020): in caso di rate = 'T' (Tutte), prima di eliminare il depag si verifica
  --                    quali rate sono ancora esistenti (se la rata unica oppure le singole rate)
  --                    In base alle rate rimaste si decide poi quali rate ripassare a DEPAG
  --
  w_esiste_rata_u := 0;
  w_esiste_rate   := 0;
  w_idback_ref    := to_char(null);
  if w_flag_rate = 'T' and w_numero_rate > 1 then
     w_idback_ann := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||p_cod_fiscale||'%';
     controllo_rate_emesse (w_des_cliente, w_servizio, w_idback_ann
                           ,w_esiste_rata_u, w_esiste_rate);
     --dbms_output.put_line('Esiste rata unica: '||w_esiste_rata_u);
     --dbms_output.put_line('Esistono rate: '||w_esiste_rate);
  end if;
  -- Si eliminano tutti i dovuti per tributo, anno, ruolo
  -- e codice fiscale indicato.
  w_idback_ann := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||p_cod_fiscale||'%';
  w_operazione_log := w_titolo_log||' - annulladovutilike';
  pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente);
--dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
  RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
--  if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
  if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 or
     to_number(ltrim(RetVal,'PO')) = 100 then
     pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: RetVal = '||RetVal);
  else
     w_errore := w_idback_ann ||'ERRORE: RetVal = '||Retval;
     raise errore;
  end if;
--dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
  -- (VD - 15/09/2021): nuovi dati per integrazione con contabilita' finanziaria
  -- Determinazione accertamento contabile abbinato all'imposta
  -- (da memorizzare nel campo "accertamento" di depag_dovuti)
  -- (VD - 17/12/2021): i dati si predispongono solo se l'integrazione e' attiva
  w_accertamento := null;
  w_dati_riscossione := null;
  w_capitolo := null;
  if w_int_cfa = 'S' then
     w_accertamento := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                             , p_anno
                                                             , 'O'               -- tipo_imposta
                                                             , to_char(null)     -- tipo_pratica
                                                             , trunc(sysdate)    -- data_emissione
                                                             , to_char(null)     -- cod_tributo_f24
                                                             , to_char(null)     -- stato_pratica
                                                             );
     -- Determinazione capitolo abbinato all'accertamento contabile
     -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
     if w_accertamento is not null then
        w_capitolo := dati_contabili_pkg.f_get_capitolo( p_anno
                                                               , to_number(substr(w_accertamento,1,4))
                                                               , to_number(substr(w_accertamento,6))
                                                               );
     end if;
  end if;
  -- Emissione nuovi dovuti
  for rec_mov in sel_mov
  loop
    if w_flag_rate = 'T' and
       w_numero_rate > 1 and
       rec_mov.rata = 1 and
       w_esiste_rata_u = 1 then
       w_idback := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||
                   rpad(rec_mov.cod_fiscale,16)||'0';
       if nvl(rec_mov.conta_vers,0) > 0 then
          w_idback:= w_idback||'-'||rec_mov.conta_vers;
       end if;
       if w_esiste_rate = 1 then
          if w_idback_ref is null then
             w_idback_ref := w_idback;
          end if;
       end if;
       w_operazione_log := w_titolo_log||' - aggiornadovuto rata unica';
       pagonline_tr4.inserimento_log(w_operazione_log, w_idback||' '||w_des_cliente);
       --
       -- (RV - 01/09/2023): gestione scomposizione degli importi
       --
       if nvl(rec_mov.dovuto_mb,'N') = 'S' then
         w_dovuto_netto := rec_mov.importo_tot - rec_mov.importo_tefa_tot;
         dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', dovuto : '||rec_mov.importo_tot||', netto : '||w_dovuto_netto||', tefa : '||rec_mov.importo_tefa_tot);
         --
         w_numero_quote := prepara_scomposizione_importi ( p_tipo_tributo,p_anno,rec_mov.anno_emissione,
                                                           w_dovuto_netto, rec_mov.importo_tefa_tot,
                                                           w_dettagli_quote, w_metadata_quote );
       else
         w_numero_quote := 0;
       end if;
       --
       if(w_numero_quote < 1) then
         w_dovuto_netto := rec_mov.importo_tot;
         w_dettagli_quote := null;
         w_metadata_quote := null;
       end if;
       --
       -- (VD - 15/09/2021): Dati per contabilita' finanziaria
       -- Composizione del campo "bilancio"
       -- (VD - 17/12/021): il campo "bilancio" si compone solo se l'integrazione e' attiva
       --                   e i dati riscossione e accertamento sono valorizzati
       if w_int_cfa = 'S' and
          w_capitolo is not null and
          w_accertamento is not null then
          w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_capitolo
                                                          , w_accertamento
                                                          , w_dovuto_netto
                                                          );
          w_dati_riscossione := dati_contabili_pkg.f_get_dati_riscossione (w_capitolo);
       else
          w_bilancio := null;
       end if;
       --
       -- Aggiorna il dovuto
       --
       RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ente,
                                                rec_mov.iud, --iud
                                                rec_mov.servizio,
                                                w_idback,
                                                rec_mov.backend,
                                                rec_mov.cod_iuv,
                                                rec_mov.tipo_ident,
                                                rec_mov.codice_ident,
                                                rec_mov.anag_pagatore,
                                                rec_mov.indirizzo_pagatore,
                                                substr(rec_mov.civico_pagatore,1,16),
                                                rec_mov.cap_pagatore,
                                                rec_mov.localita_pagatore,
                                                rec_mov.prov_pagatore,
                                                rec_mov.naz_pagatore,
                                                rec_mov.email_pagatore,
                                                rec_mov.data_scadenza,
                                                rec_mov.importo_tot,
                                                rec_mov.commissione_carico_pa,
                                                rec_mov.tipo_dovuto,
                                                rec_mov.tipo_versamento,
                                                replace(rec_mov.causale_versamento,'RATA: 1','RATA: UNICA'),
                                                --rec_mov.dati_riscossione,
                                                w_dati_riscossione,
                                                rec_mov.utente_ultimo_agg,
      -- (VD - 27/11/2020): nuovi campi per gestione rate
                                                to_char(null),  -- note
                                                to_char(null),  -- dati_extra
                                                w_accertamento, -- accertamento
                                                w_bilancio,     -- bilancio
                                                scadenza_rata_avviso(p_ruolo,0),
                                                case when
                                                  w_idback_ref is null then
                                                    to_number(null)
                                                else
                                                    0
                                                end,             -- numero rata
                                                w_idback_ref,
       -- (RV - 31/08/2023: nuovi campi per gestione scomposizione degli importi
                                                null,            -- dicitura_scadenza
                                                w_dettagli_quote,
                                                w_metadata_quote
                                               );
--dbms_output.put_line('Dopo depag_service - retval: '||retval);
       if RetVal is null or to_number(ltrim(retval,'PO')) < 10 then
          w_operazione_log := w_titolo_log||' - aggiornadovuto-fine';
          pagonline_tr4.inserimento_log(w_operazione_log, w_idback||' RetVal = '||RetVal);
       else
          -- (VD - 13/12/2021): modificata gestione errori. In caso di aggiornamento fallito
          --                    si blocca l'esecuzione e si esegue il rollback nella
          --                    exception
          w_errore := 'Errore in inserimento DEPAG_DOVUTI '||w_idback||' RetVal = '||Retval;
          --pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
          --w_messaggio := w_messaggio||' - '||w_errore;
          --w_errore := null;
          raise errore;
       end if;
    end if;

    if w_flag_rate <> 'T' or
      (w_flag_rate = 'T' and
      (w_esiste_rata_u = 0 and w_esiste_rate = 0) or
      (w_esiste_rate = 1 and rec_mov.rata > 0)) then
       w_idback := rpad(p_tipo_tributo,5)||p_anno||lpad(p_ruolo,10,'0')||
                   rpad(rec_mov.cod_fiscale,16)||rec_mov.rata;
       if nvl(rec_mov.conta_vers,0) > 0 then
          w_idback:= w_idback||'-'||rec_mov.conta_vers;
       end if;
       --
--dbms_output.put_line('Loop Id.Back: '||w_idback);
       w_operazione_log := 'aggiorna_dovuto_pagopa-aggiornadovuto rate';
       pagonline_tr4.inserimento_log(w_operazione_log, w_idback||' '||w_des_cliente);
       --
       -- (RV - 01/09/2023): gestione scomposizione degli importi
       --
       if nvl(rec_mov.dovuto_mb,'N') = 'S' then
          w_dovuto_netto := rec_mov.importo_dovuto - rec_mov.importo_tefa;
        --dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', dovuto : '||rec_mov.importo_dovuto||', netto : '||w_dovuto_netto||', tefa : '||rec_mov.importo_tefa);
          --
          w_numero_quote := prepara_scomposizione_importi ( p_tipo_tributo,p_anno,rec_mov.anno_emissione,
                                                             w_dovuto_netto, rec_mov.importo_tefa,
                                                             w_dettagli_quote, w_metadata_quote );
       else
         w_numero_quote := 0;
       end if;
       --
       if(w_numero_quote < 1) then
         w_dovuto_netto := rec_mov.importo_dovuto;
         w_dettagli_quote := null;
         w_metadata_quote := null;
       end if;
       --
       -- (VD - 15/09/2021): Dati per contabilita' finanziaria
       -- Composizione del campo "bilancio"
       -- (VD - 17/12/021): il campo "bilancio" si compone solo se l'integrazione e' attiva
       --                   e i dati riscossione e accertamento sono valorizzati
       if w_int_cfa = 'S' and
          w_capitolo is not null and
          w_accertamento is not null then
          w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_capitolo
                                                          , w_accertamento
                                                          , w_dovuto_netto
                                                          );
          w_dati_riscossione := dati_contabili_pkg.f_get_dati_riscossione (w_capitolo);
       else
          w_bilancio := null;
       end if;
       --
     --dbms_output.put_line('importo_dovuto: '||rec_mov.importo_dovuto);
     --dbms_output.put_line('importo_tefa: '||rec_mov.importo_tefa);
     --dbms_output.put_line('w_dovuto_netto: '||w_dovuto_netto);
     --dbms_output.put_line('w_dati_riscossione: '||w_dati_riscossione);
     --dbms_output.put_line('w_accertamento: '||w_accertamento);
     --dbms_output.put_line('w_bilancio: '||w_bilancio);
     --dbms_output.put_line('w_dettagli_quote: '||w_dettagli_quote);
       --
       RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ente,
                                                rec_mov.iud, --iud
                                                rec_mov.servizio,
                                                w_idback,
                                                rec_mov.backend,
                                                rec_mov.cod_iuv,
                                                rec_mov.tipo_ident,
                                                rec_mov.codice_ident,
                                                rec_mov.anag_pagatore,
                                                rec_mov.indirizzo_pagatore,
                                                substr(rec_mov.civico_pagatore,1,16),
                                                rec_mov.cap_pagatore,
                                                rec_mov.localita_pagatore,
                                                rec_mov.prov_pagatore,
                                                rec_mov.naz_pagatore,
                                                rec_mov.email_pagatore,
                                                rec_mov.data_scadenza,
                                                rec_mov.importo_dovuto,
                                                rec_mov.commissione_carico_pa,
                                                rec_mov.tipo_dovuto,
                                                rec_mov.tipo_versamento,
                                                rec_mov.causale_versamento,
                                                --rec_mov.dati_riscossione,
                                                w_dati_riscossione,
                                                rec_mov.utente_ultimo_agg,
       -- (VD - 27/11/2020: nuovi campi per gestione rate
                                                to_char(null),  -- note
                                                to_char(null),  -- dati_extra
                                                w_accertamento, -- accertamento
                                                w_bilancio,     -- bilancio
                                                scadenza_rata_avviso(p_ruolo,rec_mov.rata),
                                                case
                                                  when w_idback_ref is null then
                                                    to_number(null)
                                                  else
                                                    rec_mov.rata
                                                end,
                                                w_idback_ref,
       -- (RV - 31/08/2023: nuovi campi per gestione scomposizione degli importi
                                                null,            -- dicitura_scadenza
                                                w_dettagli_quote,
                                                w_metadata_quote
                                               );
--dbms_output.put_line('Dopo depag_service - retval: '||retval);
       if RetVal is null or to_number(ltrim(retval,'PO')) < 10 then
          w_operazione_log := 'aggiorna_dovuto_pagopa-aggiornadovuto-fine';
          pagonline_tr4.inserimento_log(w_operazione_log, w_idback||' RetVal = '||RetVal);
       else
          -- (VD - 13/12/2021): modificata gestione errori. In caso di aggiornamento fallito
          --                    si blocca l'esecuzione e si esegue il rollback nella
          --                    exception
          w_errore := 'Errore in inserimento DEPAG_DOVUTI '||w_idback||' - Codice: '||Retval;
          --pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
          --w_messaggio := w_messaggio||' - '||w_errore;
          --w_errore := null;
          raise errore;
       end if;
    end if;
  end loop;
  --
  return w_messaggio;
  --
exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_messaggio := 'Si e'' verificato un errore in fase di aggiornamento PagoPA - verificare log';
       return w_messaggio;
  when others then
       ROLLBACK;
       w_errore := 'Errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_messaggio := 'Aggiornamento dovuto PagoPA - '||w_errore;
       return w_messaggio;
end;
--------------------------------------------------------------------------------------------------------
function inserimento_violazioni
( p_pratica                 in number
) return number is

/******************************************************************************
 NOME:        INSERIMENTO_VIOLAZIONI
 DESCRIZIONE: Carica l'importo dovuto di una pratica per violazione
              in PAGONLINE.
              Tributi: TOSAP e ICP.

 PARAMETRI:   p_pratica             Pratica da trattare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
 001   09/11/2020  VD      Modificata gestione sigla provincia/stato estero
 002   10/01/2022  VD      Modifiche per gestione pratiche totali
 003   20/05/2022  VD      Modificata selezione importo da rate_pratica:
                           oltre a capitale e interessi si aggiungono anche
                           aggi e dilazione
 004   21/09/2022  VD      Corretta determinazione data scadenza per pratiche
                           rateizzate: la data scadenza deve coincidere con
                           la scadenza della rata (senza considerare i 60 gg
                           dalla data di notifica).
 005   23/01/2024  RV      #66207
                           Gestione dobuto mb
 006   29/01/2025  RV      #77216
                           Rivisto per corretta gestione Bilancio con QUOTE_MB
 008   09/05/2025  RV      #80274
                           Sistemato mancata contabilizzazione Oneri nelle singole
                           rate delle pratiche di violazione rateizzate (90)
******************************************************************************/
RetVal                      VARCHAR2(8);
w_des_cliente               varchar2(60);
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
w_importo_vers              number;
w_conta_vers                number;
w_return                    number:= 0;
w_operazione_log            varchar2(100) := 'INSERIMENTO_VIOLAZIONI';

-- Dati per contabilita' finanziaria
w_dati_riscossione          depag_dovuti.dati_riscossione%type;
w_accertamento              depag_dovuti.accertamento%type;
w_bilancio                  depag_dovuti.bilancio%type;

w_importo_dovuto            number;
w_dovuto_netto              number;
w_importo_tefa              number;

-- (RV - 23/01/2024: Dati per gestione scomposizione degli importi
w_dettagli_quote            depag_dovuti.quote_mb%type;
w_metadata_quote            depag_dovuti.metadata%type;
w_numero_quote              number;

w_errore                    varchar2(4000);
errore                      exception;

-- Cursore per annullare i dovuti della pratica gia' emessi
cursor sel_pratiche_ann is
/*  select prtr.tipo_tributo,
         prtr.anno,
         prtr.cod_fiscale,
         prtr.pratica,
         pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
         nvl(min(ogpr.tipo_occupazione),' ') tipo_occupazione
    from oggetti_pratica ogpr,
         pratiche_tributo prtr
   where nvl(prtr.pratica_rif,prtr.pratica) = p_pratica
     and ogpr.pratica  = prtr.pratica
     --and prtr.data_notifica is not null
   group by prtr.tipo_tributo,prtr.anno,prtr.cod_fiscale,
         prtr.pratica,prtr.tipo_pratica,prtr.tipo_evento; */
  select prtr.tipo_tributo,
         prtr.anno,
         prtr.cod_fiscale,
         prtr.pratica,
         pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
         nvl(min(ogpr.tipo_occupazione),' ') tipo_occupazione
    from pratiche_tributo prtr,
         (select nvl(prto.pratica_rif,prto.pratica) pratica,
                 ogpt.tipo_occupazione
            from pratiche_tributo prto,
                 oggetti_pratica  ogpt
           where nvl(prto.pratica_rif,prto.pratica) = p_pratica
             and prto.pratica = ogpt.pratica) ogpr
   where prtr.pratica = p_pratica
     and ogpr.pratica = prtr.pratica
   group by prtr.tipo_tributo,prtr.anno,prtr.cod_fiscale,
         prtr.pratica,prtr.tipo_pratica,prtr.tipo_evento;
-- Cursore per selezionare l'imposta da passare a DEPAG
cursor sel_mov is
   select cont.cod_fiscale
        , impo.pratica
        , impo.rata
        , impo.tipo_tributo
        , impo.anno
        , extract(year from sysdate) anno_attuale
        , w_des_cliente ente
        , null iud
        -- (VD - 30/11/2021): aggiunto flag per selezionare servizio per violazioni
        , f_depag_servizio(impo.tipo_tributo,impo.tipo_occupazione,'S',impo.dovuto_mb) servizio
        , rpad(impo.tipo_tributo,5,' ')||impo.tipo_occupazione||impo.pref_pratica||
          impo.anno||lpad(nvl(impo.pratica,0),10,'0')||rpad(cont.cod_fiscale,16)||
          lpad(impo.rata,2,'0') idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35) localita_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,3),
              f_recapito(sogg.ni,impo.tipo_tributo,2))   email_pagatore
        , decode(impo.data_scadenza
                ,null,trunc(sysdate) + f_depag_gg_violazioni(impo.tipo_tributo)
                ,decode(impo.rata
                       ,0,impo.data_scadenza + 60
                       ,impo.data_scadenza
                       )
                )                data_scadenza
        , decode(impo.data_scadenza
                ,null,trunc(sysdate) + f_depag_gg_violazioni(impo.tipo_tributo)
                ,impo.data_scadenza + f_depag_gg_violazioni(impo.tipo_tributo)
                )                data_scadenza_avviso
        , impo.importo_dovuto
        , impo.dovuto_mb
        , impo.importo_tefa
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , 'ACCERTAMENTO '||f_descrizione_titr(impo.tipo_tributo,impo.anno)||
          ' NUMERO '||impo.numero||' DEL '||to_char(impo.data,'dd/mm/yyyy')||
          ' - ANNO '||impo.anno||
          decode(impo.rata,0,'',' RATA: '||impo.rata) causale_versamento
        , decode(impo.data_scadenza
                ,to_date(null),'Da pagare entro 60 giorni'
                ,null) dicitura_scadenza
        , w_utente_ultimo_agg utente_ultimo_agg
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , (select prtr.tipo_tributo,
                  prtr.anno,
                  prtr.cod_fiscale,
                  prtr.pratica,
                  prtr.numero,
                  prtr.data,
                  pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                  prtr.data_notifica data_scadenza,
                  nvl(min(ogpr.tipo_occupazione),' ') tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione) fine_occupazione,
                  prtr.importo_ridotto importo_dovuto,
                  F_TOTALE_ADDIZIONALI(prtr.pratica) importo_tefa,
                  f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data) as dovuto_mb
             from pratiche_tributo prtr,
                  (select nvl(prto.pratica_rif,prto.pratica) pratica,
                          ogpr.tipo_occupazione,
                          ogco.inizio_occupazione,
                          ogco.fine_occupazione
                     from pratiche_tributo prto,
                          oggetti_pratica ogpr,
                          oggetti_contribuente ogco
                    where nvl(prto.pratica_rif,prto.pratica) = p_pratica
                      and prto.pratica = ogpr.pratica
                      and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and prto.cod_fiscale = ogco.cod_fiscale) ogpr
            where prtr.pratica = p_pratica
              and ogpr.pratica = prtr.pratica
              and nvl(prtr.tipo_atto,-1) <> 90
            group by prtr.tipo_tributo,prtr.anno,prtr.cod_fiscale,
                  prtr.pratica,prtr.numero,prtr.data,
                  prtr.tipo_pratica,prtr.tipo_evento,prtr.data_notifica,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione),
                  prtr.importo_ridotto
           union
           select prtr.tipo_tributo,
                  prtr.anno,
                  prtr.cod_fiscale,
                  prtr.pratica,
                  prtr.numero,
                  prtr.data,
                  pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                  rapr.data_scadenza,
                  nvl(min(ogpr.tipo_occupazione),' ') tipo_occupazione,
                  rapr.rata rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione) fine_occupazione,
                  -- (VD - 20/02/2022): aggiunti nuovi valori della tabella rate_pratica
                  nvl(rapr.importo_arr
                     ,rapr.importo_capitale + nvl(rapr.importo_interessi,0) + nvl(rapr.oneri,0) +
                      coalesce(rapr.aggio_rimodulato,rapr.aggio,0) +
                      coalesce(rapr.dilazione_rimodulata,rapr.dilazione,0)
                  ) importo_dovuto,
                  nvl(rapr.quota_tefa,0) importo_tefa,
                  f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data) as dovuto_mb
             from pratiche_tributo prtr,
                  rate_pratica rapr,
                  (select nvl(prto.pratica_rif,prto.pratica) pratica,
                          ogpr.tipo_occupazione,
                          ogco.inizio_occupazione,
                          ogco.fine_occupazione
                     from pratiche_tributo prto,
                          oggetti_pratica ogpr,
                          oggetti_contribuente ogco
                    where nvl(prto.pratica_rif,prto.pratica) = p_pratica
                      and prto.pratica = ogpr.pratica
                      and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and prto.cod_fiscale = ogco.cod_fiscale) ogpr
            where prtr.pratica = p_pratica
              and rapr.pratica = prtr.pratica
              and ogpr.pratica = prtr.pratica
              and nvl(prtr.tipo_atto,-1) = 90
            group by prtr.tipo_tributo,prtr.anno,prtr.cod_fiscale,
                  prtr.pratica,prtr.numero,prtr.data,
                  prtr.tipo_pratica,prtr.tipo_evento,
                  rapr.data_scadenza,rapr.rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione),
                  nvl(rapr.importo_arr
                     ,rapr.importo_capitale + nvl(rapr.importo_interessi,0) + nvl(rapr.oneri,0) +
                      coalesce(rapr.aggio_rimodulato,rapr.aggio,0) +
                      coalesce(rapr.dilazione_rimodulata,rapr.dilazione,0)
                  ),
                  rapr.quota_tefa
          ) impo
    where cont.cod_fiscale = impo.cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
    order by 1,2,3;
---------------------------------------------------------------------------------------------------
  begin
    w_des_cliente := pagonline_tr4.descrizione_ente;
    w_operazione_log := 'Inserimento violazioni';
    for rec_ann in sel_pratiche_ann
    loop
      --dbms_output.put_line('Pratica: '||rec_ann.pratica);
      w_idback_ann := rpad(rec_ann.tipo_tributo,5,' ')||rec_ann.tipo_occupazione||rec_ann.pref_pratica||
                      rec_ann.anno||lpad(rec_ann.pratica,10,'0')||rec_ann.cod_fiscale||'%';
      pagonline_tr4.inserimento_log(w_operazione_log||'-annulladovutilike pratica',
                                    w_idback_ann||' '||w_des_cliente);
      --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
      RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann, w_utente_ultimo_agg);
      --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
    end loop;

    for rec_mov in sel_mov
    loop
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', IMPORTO: '||REC_MOV.IMPORTO_dovuto);
      -- Gestione del versato: si verifica se esistono dei versamenti per pratica
      -- e se esistono si attribuiscono alle varie rate a scalare
      begin
        select nvl(sum(vers.importo_versato),0),
               count(*)
          into w_importo_vers,
               w_conta_vers
          from versamenti vers
         where vers.tipo_tributo||''   = rec_mov.tipo_tributo
           and nvl(vers.rata,0)        = rec_mov.rata
           and vers.cod_fiscale        = rec_mov.cod_fiscale
           and vers.anno               = rec_mov.anno
           and vers.pratica            = rec_mov.pratica
         group by vers.cod_fiscale;
      exception
        when others then
          w_importo_vers := 0;
          w_conta_vers := 0;
      end;
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', versato: '||w_importo_vers);

      if nvl(rec_mov.importo_dovuto,0) > 0 then
         if w_importo_vers < rec_mov.IMPORTO_DOVUTO then
            --dbms_output.put_line('Prima di depag_service');
            pagonline_tr4.inserimento_log(w_operazione_log||'-aggiornadovuto',
                                          rec_mov.idback||' '||w_des_cliente);
            --
            if w_conta_vers > 0 then
               w_importo_dovuto := rec_mov.IMPORTO_DOVUTO - w_importo_vers;
            else
               w_importo_dovuto := rec_mov.IMPORTO_DOVUTO;
            end if;
            --
            if(nvl(rec_mov.dovuto_mb,'N') = 'S') then
              w_dovuto_netto := w_importo_dovuto - w_importo_tefa;
            --dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', dovuto : '||w_importo_dovuto||', netto : '||w_dovuto_netto||', tefa : '||w_importo_tefa);
              --
              w_numero_quote := prepara_scomposizione_importi ( rec_mov.tipo_tributo,rec_mov.anno,rec_mov.anno_attuale,
                                                                     w_dovuto_netto, w_importo_tefa,
                                                                     w_dettagli_quote, w_metadata_quote );
            else
              w_numero_quote := 0;
            end if;
            --
            if(w_numero_quote < 1) then
              w_dovuto_netto := w_importo_dovuto;
              w_dettagli_quote := null;
              w_metadata_quote := null;
            end if;
            --
            --dbms_output.put_line('Prima di dati contabili');
            dati_contabili_pkg.dati_contabili_pratica( rec_mov.pratica
                                                     , rec_mov.rata
                                                     , w_dovuto_netto
                                                     , w_dati_riscossione
                                                     , w_accertamento
                                                     , w_bilancio);
            --dbms_output.put_line('Dopo dati contabili');
            --dbms_output.put_line('w_dati_riscossione: '||w_dati_riscossione);
            --dbms_output.put_line('w_accertamento: '||w_accertamento);
            --dbms_output.put_line('w_bilancio: '||w_bilancio);
            --
            RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ENTE,
                                                     rec_mov.IUD, --iud
                                                     rec_mov.SERVIZIO,
                                                     --rec_mov.idback,
                                                     case
                                                       when w_conta_vers > 0 then
                                                         rec_mov.idback||'-'||w_conta_vers
                                                       else
                                                         rec_mov.idback
                                                     end,--idback
                                                     rec_mov.BACKEND,
                                                     rec_mov.COD_IUV,
                                                     rec_mov.TIPO_IDENT,
                                                     rec_mov.CODICE_IDENT,
                                                     rec_mov.ANAG_PAGATORE,
                                                     rec_mov.INDIRIZZO_PAGATORE,
                                                     substr(rec_mov.CIVICO_PAGATORE,1,16),
                                                     rec_mov.CAP_PAGATORE,
                                                     rec_mov.LOCALITA_PAGATORE,
                                                     rec_mov.PROV_PAGATORE,
                                                     rec_mov.NAZ_PAGATORE,
                                                     rec_mov.EMAIL_PAGATORE,
                                                     rec_mov.DATA_SCADENZA,
                                                     w_importo_dovuto,
                                                     rec_mov.COMMISSIONE_CARICO_PA,
                                                     rec_mov.TIPO_DOVUTO,
                                                     rec_mov.TIPO_VERSAMENTO,
                                                     rec_mov.CAUSALE_VERSAMENTO,
                                                     --rec_mov.DATI_RISCOSSIONE,
                                                     w_dati_riscossione,
                                                     rec_mov.UTENTE_ULTIMO_AGG,
            -- Nuovi campi per integrazione con contabilita' finanziaria
                                                     to_char(null),   -- note
                                                     to_char(null),   -- dati_extra
                                                     w_accertamento,  -- accertamento
                                                     w_bilancio,      -- bilancio
                                                     rec_mov.data_scadenza_avviso,   -- data_scadenza_avviso
                                                     to_number(null), -- rata_numero
                                                     to_char(null),   -- rata_unica_ref
                                                     rec_mov.dicitura_scadenza,
                                                     w_dettagli_quote,
                                                     w_metadata_quote
                                                     );
            --dbms_output.put_line('Dopo depag_service - retval: '||retval);
            if RetVal is null or to_number(ltrim(retval,'PO')) < 10 then --in ('PO0100','PO0099') then
               pagonline_tr4.inserimento_log(w_operazione_log||'-Fine aggiornadovuto',
                                             rec_mov.idback||' '||w_des_cliente);
               w_return := w_return +1;
            else
               w_errore := 'Errore in inserimento DEPAG_DOVUTI 1 '||rec_mov.idback||' '||Retval;
               --pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
               --w_errore := null;
               raise errore;
            end if;
         end if;
         if w_importo_vers < rec_mov.importo_dovuto then
            w_importo_vers := 0;
         else
            w_importo_vers := w_importo_vers - rec_mov.importo_dovuto;
         end if;
      end if;
   end loop;
   -- (VD - 30/11/2021): Si aggiorna il flag_depag sulla testata della pratica
   begin
     update pratiche_tributo
        set flag_depag = 'S'
      where pratica = p_pratica;
   exception
     when others then
       w_errore:='Upd. PRATICHE_TRIBUTO '||p_pratica||' - '||sqlerrm;
       raise errore;
   end;
   --
   return w_return;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end inserimento_violazioni;
--------------------------------------------------------------------------------------------------------
function aggiorna_dovuti_pratica
( p_pratica                 in number
) return sys_refcursor is
/*************************************************************************
 NOME:         AGGIORNA_DOVUTI_PRATICA
 DESCRIZIONE:  Restituisce un elenco di dovuti gia' passati a DEPAG
               per cui deve essere lanciato il web-service di allineamento
               al partner tecnologico

 PARAMETRI:   p_pratica             Pratica da elaborare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   08/09/2020  VD      Prima emissione.
 001   17/12/2021  VD      Aggiunto test su flag integrazione con CFA: i
                           dati in depag_dovuti vengono inseriti solo se
                           l'integrazione e' attiva
                           Modificata gestione segnalazioni errore.
 003   20/05/2022  VD      Modificata selezione importo da rate_pratica:
                           oltre a capitale e interessi si aggiungono anche
                           aggi e dilazione
 004   21/09/2022  VD      Corretta determinazione data scadenza per pratiche
                           rateizzate: la data scadenza deve coincidere con
                           la scadenza della rata (senza considerare i 60 gg
                           dalla data di notifica).
 005   09/02/2023  AB      Gestitata causale per i solleciti.
 006   16/10/2023  RV      #66207 : Rivisto per scomposizione degli importi
 007   20/02/2024  RV      #66207 : Gestione quota versato TEFA
 008   12/03/2024  RV      #55403 : modificato gestione date scadenza per Rav. TARSU
 009   29/01/2025  RV      #77216
                           Rivisto per corretta gestione Bilancio con QUOTE_MB
 010   09/05/2025  RV      #80274
                           Sistemato mancata contabilizzazione Oneri nelle singole
                           rate delle pratiche di violazione rateizzate (90)
*************************************************************************/
  w_operazione_log         varchar2(100):= 'aggiorna_dovuti_pratica';
  w_errore                 varchar2(4000);
  w_ind                    number;
  w_des_cliente            varchar2(60);
  w_utente_ultimo_agg      varchar(8)  := 'TRIBUTI';
  w_importo_dovuto         number;
  w_importo_vers           number;
  w_tefa_dovuto            number;
  w_tefa_vers              number;
  w_conta_vers             number;
  w_dep_record             depag_dovuti%rowtype;
  rc                       sys_refcursor;

-- Dati per contabilita' finanziaria
  w_int_cfa                varchar2(1);
  w_dati_riscossione       depag_dovuti.dati_riscossione%type;
  w_accertamento           depag_dovuti.accertamento%type;
  w_bilancio               depag_dovuti.bilancio%type;

-- (RV - 18/09/2023: Dati per gestione scomposizione degli importi
  w_dettagli_quote            depag_dovuti.quote_mb%type;
  w_metadata_quote            depag_dovuti.metadata%type;
  w_numero_quote              number;
  w_dovuto_netto              number;

-- Cursore per selezionare l'imposta da passare a DEPAG
  cursor sel_mov is
   select cont.cod_fiscale
        , impo.pratica
        , impo.rata
        , impo.tipo_tributo
        , impo.anno
        , extract(year from sysdate) anno_attuale
        , w_des_cliente ente
        , null iud
        -- (VD - 30/11/2021): aggiunto flag per selezionare servizio per violazioni
        -- (RV - 23/01/2024): aggiunto flag per selezionare servizio per dovuto mb
        , f_depag_servizio(nvl(impo.gruppo_tributo,impo.tipo_tributo),impo.tipo_occupazione,'S',impo.dovuto_mb) servizio
        , rpad(nvl(impo.gruppo_tributo,impo.tipo_tributo),5,' ')||impo.tipo_occupazione||impo.pref_pratica||
          impo.anno||lpad(nvl(impo.pratica,0),10,'0')||rpad(cont.cod_fiscale,16)||
          lpad(impo.rata,2,'0') idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35) localita_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,impo.tipo_tributo,3),
              f_recapito(sogg.ni,impo.tipo_tributo,2))   email_pagatore
        , decode(impo.pref_pratica
                ,'RAVP',nvl(impo.data_scadenza,trunc(sysdate))
                ,'SOLA',nvl(impo.data_scadenza,trunc(sysdate))
                ,decode(impo.data_scadenza
                       ,null,trunc(sysdate) + f_depag_gg_violazioni(impo.tipo_tributo)
                       ,decode(impo.rata
                              ,0,impo.data_scadenza + 60
                              ,impo.data_scadenza
                              )
                       )
                ) as data_scadenza
        , decode(impo.pref_pratica
                ,'RAVP',nvl(impo.data_scadenza_avviso,impo.data_scadenza)
                ,'SOLA',decode(impo.data_scadenza
                       ,null,trunc(sysdate) + f_depag_gg_solleciti(impo.tipo_tributo)
                       ,impo.data_scadenza + f_depag_gg_solleciti(impo.tipo_tributo)
                       )
                ,decode(impo.data_scadenza
                       ,null,trunc(sysdate) + f_depag_gg_violazioni(impo.tipo_tributo)
                       ,impo.data_scadenza + f_depag_gg_violazioni(impo.tipo_tributo)
                       )
                ) as data_scadenza_avviso
        , impo.importo_dovuto
        , impo.importo_tefa
        , impo.dovuto_mb
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , case
            when impo.pref_pratica = 'RAVP' then
              'RAVVEDIMENTO '
            when impo.pref_pratica = 'SOLA' then
              'SOLLECITO '
            else
              'ACCERTAMENTO '
          end ||
          f_descrizione_titr(nvl(impo.gruppo_tributo,impo.tipo_tributo),impo.anno)||
          decode(impo.pref_pratica,'RAVP','',' NUMERO '||impo.numero)||
          ' DEL '||to_char(impo.data,'dd/mm/yyyy')||
          ' - ANNO '||impo.anno||
          decode(impo.rata
                ,0,decode(impo.pref_pratica,'RAVP',' RATA UNICA','')
                ,' RATA: '||impo.rata) causale_versamento
        , decode(impo.pref_pratica
                ,'RAVP',null
                ,decode(impo.data_scadenza
                       ,to_date(null),'Da pagare entro 60 giorni'
                       ,null)
                ) dicitura_scadenza
        , decode(impo.pref_pratica
                ,'RAVP',greatest(impo.data,trunc(sysdate))
                ,to_date(null)
                ) data_scadenza_pt
        , w_utente_ultimo_agg utente_ultimo_agg
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , (select prtr.tipo_tributo,
                  prtr.anno,
                  prtr.cod_fiscale,
                  prtr.pratica,
                  prtr.numero,
                  prtr.data,
                  pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                  nvl(f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data),'N') as dovuto_mb,
                  decode(prtr.tipo_pratica
                        ,'S',nvl(prtr.data_scadenza,prtr.data)
                        ,'V',nvl(prtr.data_rif_ravvedimento,prtr.data)
                        ,prtr.data_notifica
                        ) as data_scadenza,
                  case when prtr.tipo_tributo = 'TARSU' and prtr.tipo_pratica = 'V' then
                    prtr.data_scadenza
                  else
                    null
                  end as data_scadenza_avviso,
                  pagonline_tr4.f_get_tipo_occupazione(p_pratica) tipo_occupazione,
                  decode(prtr.tipo_pratica,'V',to_number(prtr.tipo_evento),0) rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione) fine_occupazione,
                  -- (VD - 11/05/2022): per la TARSU l'importo viene ricalcolato con l'apposita funzione
                  --                    utilizzata anche per l'F24
                  --prtr.importo_ridotto importo_dovuto,
                  -- (AB - 10/01/2023); per la TARSU cambiata la funztione perchè altrimenti si moltiplicava
                  -- tutto l'importo comprese le sanzioni per recuperare le addizionali e veniva un importo errato
                  -- ora agggiungo all'importo ridotto la somma delle addizionali
                  -- AB 10/01/2024 per i Solleciti TARSU fatto arrtondamento
                  (case when prtr.tipo_tributo = 'TARSU' and prtr.tipo_pratica = 'S' then
                       round(prtr.importo_ridotto + F_TOTALE_ADDIZIONALI(prtr.pratica),0)
                   else
                      decode(prtr.tipo_tributo,
        --                    'TARSU',round(F_IMPORTO_F24_VIOL(prtr.importo_ridotto,to_number(null),'N',prtr.tipo_tributo,prtr.anno,'E','N')),
                            'TARSU',prtr.importo_ridotto + F_TOTALE_ADDIZIONALI(prtr.pratica),
                            prtr.importo_ridotto)
                   end
                   - (select nvl(sum(nvl(sapr.importo, 0)),0)
                        from sanzioni_pratica sapr
                       where sapr.pratica = prtr.pratica
                         and sapr.cod_sanzione = 9000)
                  ) importo_dovuto,
                  F_TOTALE_ADDIZIONALI(prtr.pratica) importo_tefa,
                  decode(prtr.tipo_tributo
                        ,'CUNI',pagonline_tr4.f_get_gruppo_tributo(prtr.pratica)
                        ,null) gruppo_tributo
             from pratiche_tributo prtr,
                  (select nvl(prto.pratica_rif,prto.pratica) pratica,
                          ogpr.tipo_occupazione,
                          ogco.inizio_occupazione,
                          ogco.fine_occupazione
                     from pratiche_tributo prto,
                          oggetti_pratica ogpr,
                          oggetti_contribuente ogco
                    where nvl(prto.pratica_rif,prto.pratica) = p_pratica
                      and prto.pratica = ogpr.pratica
                      and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and prto.cod_fiscale = ogco.cod_fiscale) ogpr
            where prtr.pratica = p_pratica
              and ogpr.pratica (+) = prtr.pratica
              and nvl(prtr.tipo_atto,-1) <> 90
           union
           select prtr.tipo_tributo,
                  prtr.anno,
                  prtr.cod_fiscale,
                  prtr.pratica,
                  prtr.numero,
                  prtr.data,
                  pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                  nvl(f_depag_dovuto_mb(prtr.tipo_tributo,prtr.anno,prtr.data),'N') as dovuto_mb,
                  rapr.data_scadenza,
                  null as data_scadenza_avviso,
                  pagonline_tr4.f_get_tipo_occupazione(p_pratica) tipo_occupazione,
                  rapr.rata rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogpr.fine_occupazione) fine_occupazione,
                  -- (VD - 20/02/2022): aggiunti nuovi valori della tabella rate_pratica
                  nvl(rapr.importo_arr
                     ,rapr.importo_capitale + nvl(rapr.importo_interessi,0) + nvl(rapr.oneri,0) +
                      coalesce(rapr.aggio_rimodulato,rapr.aggio,0) +
                      coalesce(rapr.dilazione_rimodulata,rapr.dilazione,0)
                     ) importo_dovuto,
                  nvl(rapr.quota_tefa,0) importo_tefa,
                  decode(prtr.tipo_tributo
                        ,'CUNI',pagonline_tr4.f_get_gruppo_tributo(prtr.pratica)
                        ,null) gruppo_tributo
             from pratiche_tributo prtr,
                  rate_pratica rapr,
                  (select nvl(prto.pratica_rif,prto.pratica) pratica,
                          ogpr.tipo_occupazione,
                          ogco.inizio_occupazione,
                          ogco.fine_occupazione
                     from pratiche_tributo prto,
                          oggetti_pratica ogpr,
                          oggetti_contribuente ogco
                    where nvl(prto.pratica_rif,prto.pratica) = p_pratica
                      and prto.pratica = ogpr.pratica
                      and ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and prto.cod_fiscale = ogco.cod_fiscale) ogpr
            where prtr.pratica = p_pratica
              and rapr.pratica = prtr.pratica
              and ogpr.pratica (+) = prtr.pratica
              and nvl(prtr.tipo_atto,-1) = 90
          ) impo
    where cont.cod_fiscale = impo.cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
    order by 1,2,3;
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  -- (VD - 17/12/2021): si seleziona il flag per verificare l'integrazione con CFA
  w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');
  --
  p_tab_dovuti.delete;
  w_ind := 0;
  --
  for rec_mov in sel_mov
  loop
    -- Gestione del versato: si verifica se esistono dei versamenti per pratica
    -- e se esistono si attribuiscono alle varie rate a scalare
    if rec_mov.tipo_tributo = 'TARSU' then
      -- Per TARSU, se non specificata, la TEFA viene stimata usando i carichi_tarsu
      begin
        select nvl(sum(vers.importo_versato),0),
               nvl(sum(vers.versato_tefa),0),
               count(*)
          into w_importo_vers,
               w_tefa_vers,
               w_conta_vers
          from (
            select
              vers.cod_fiscale,
              vers.importo_versato,
              case when vers.addizionale_pro is null then
                round(((vers.importo_versato / (100.0 + nvl(cata.addizionale_pro,0))) * nvl(cata.addizionale_pro,0)),2)
              else
               vers.addizionale_pro
              end as versato_tefa
            from
              versamenti vers,
              carichi_tarsu cata
            where vers.tipo_tributo||''   = rec_mov.tipo_tributo
              and nvl(vers.rata,0)        = rec_mov.rata
              and vers.cod_fiscale        = rec_mov.cod_fiscale
              and vers.anno               = rec_mov.anno
              and vers.pratica            = rec_mov.pratica
              and vers.anno               = cata.anno (+)
             ) vers
          group by vers.cod_fiscale;
      exception
        when others then
          w_importo_vers := 0;
          w_conta_vers := 0;
          w_tefa_vers := 0;
      end;
    else
      begin
        select nvl(sum(vers.importo_versato),0),
               0,
               count(*)
          into w_importo_vers,
               w_tefa_vers,
               w_conta_vers
          from versamenti vers
         where vers.tipo_tributo||''   = rec_mov.tipo_tributo
           and nvl(vers.rata,0)        = rec_mov.rata
           and vers.cod_fiscale        = rec_mov.cod_fiscale
           and vers.anno               = rec_mov.anno
           and vers.pratica            = rec_mov.pratica
         group by vers.cod_fiscale;
      exception
        when others then
          w_importo_vers := 0;
          w_tefa_vers := 0;
          w_conta_vers := 0;
      end;
    end if;
    --
  --dbms_output.put_line('Versamenti: '||w_conta_vers||', totale versato: '||w_importo_vers||', di cui TEFA: '||w_tefa_vers);
    --
    if nvl(rec_mov.importo_dovuto,0) > 0 then
       if w_importo_vers < rec_mov.IMPORTO_DOVUTO then
          pagonline_tr4.inserimento_log(w_operazione_log||'-aggiorna_dovuti_pratica',
                                        rec_mov.idback||' '||w_des_cliente);
          --
          -- Gestione del versato su dovuto e sulla porzione TEFA
          --
          w_importo_dovuto := rec_mov.IMPORTO_DOVUTO;
          w_tefa_dovuto := rec_mov.importo_tefa;
        --dbms_output.put_line('C.F.: '||rec_mov.cod_fiscale||', dovuto: '||w_importo_dovuto||', netto : '||w_dovuto_netto||', TEFA: '||w_tefa_dovuto);
          --
          if w_conta_vers > 0 then
             w_importo_dovuto := rec_mov.IMPORTO_DOVUTO - w_importo_vers;
             w_tefa_dovuto := w_tefa_dovuto - w_tefa_vers;
          -- Gestisce il caso negativo e di qualche centesimo figlio di arrotondamenti
             if w_tefa_dovuto < 0.02 then
               w_tefa_dovuto := 0;
             end if;
          end if;
          --
          w_dovuto_netto := w_importo_dovuto - w_tefa_dovuto;
          dbms_output.put_line('C.F.: '||rec_mov.cod_fiscale||', da versare: '||w_importo_dovuto||', netto : '||w_dovuto_netto||', TEFA: '||w_tefa_dovuto);
          --
          -- (RV - 22/01/2024): gestione scomposizione degli importi
          --
          if nvl(rec_mov.dovuto_mb,'N') = 'S' then
            w_numero_quote := prepara_scomposizione_importi ( rec_mov.tipo_tributo, rec_mov.anno, rec_mov.anno_attuale,
                                                                   w_dovuto_netto, w_tefa_dovuto,
                                                                   w_dettagli_quote, w_metadata_quote );
          else
            w_numero_quote := 0;
          end if;
          --
          if(w_numero_quote < 1) then
            w_dovuto_netto := w_importo_dovuto;
            w_dettagli_quote := null;
            w_metadata_quote := null;
          end if;
          --
        --dbms_output.put_line('Prima di dati contabili');
          if w_int_cfa = 'S' then
             dati_contabili_pkg.dati_contabili_pratica( rec_mov.pratica
                                                      , rec_mov.rata
                                                      , w_dovuto_netto
                                                      , w_dati_riscossione
                                                      , w_accertamento
                                                      , w_bilancio);
          else
             w_dati_riscossione := null;
             w_accertamento     := null;
             w_bilancio         := null;
          end if;
        --dbms_output.put_line('Dopo dati contabili');
        --dbms_output.put_line('w_dati_riscossione: '||w_dati_riscossione);
        --dbms_output.put_line('w_accertamento: '||w_accertamento);
        --dbms_output.put_line('w_bilancio: '||w_bilancio);
          --
          w_dep_record := null;
          w_dep_record.ente := rec_mov.ENTE;
          w_dep_record.iud := rec_mov.IUD; --iud
          w_dep_record.servizio := rec_mov.SERVIZIO;
          if w_conta_vers > 0 then
             w_dep_record.idback := rec_mov.idback||'-'||w_conta_vers;
          else
             w_dep_record.idback := rec_mov.idback;
          end if;
          w_dep_record.importo_dovuto := w_importo_dovuto;
          w_dep_record.backend := rec_mov.BACKEND;
          w_dep_record.cod_iuv := rec_mov.COD_IUV;
          w_dep_record.tipo_ident_pagatore := rec_mov.TIPO_IDENT;
          w_dep_record.codice_ident_pagatore := rec_mov.CODICE_IDENT;
          w_dep_record.anag_pagatore := rec_mov.ANAG_PAGATORE;
          w_dep_record.indirizzo_pagatore := rec_mov.INDIRIZZO_PAGATORE;
          w_dep_record.civico_pagatore := substr(rec_mov.CIVICO_PAGATORE,1,16);
          w_dep_record.cap_pagatore := rec_mov.CAP_PAGATORE;
          w_dep_record.localita_pagatore := rec_mov.LOCALITA_PAGATORE;
          w_dep_record.prov_pagatore := rec_mov.PROV_PAGATORE;
          w_dep_record.naz_pagatore := rec_mov.NAZ_PAGATORE;
          w_dep_record.email_pagatore := rec_mov.EMAIL_PAGATORE;
          w_dep_record.data_scadenza := rec_mov.DATA_SCADENZA;
          w_dep_record.data_scadenza_pt := rec_mov.DATA_SCADENZA_PT;
          w_dep_record.commissione_carico_pa := rec_mov.COMMISSIONE_CARICO_PA;
          w_dep_record.tipo_dovuto := rec_mov.TIPO_DOVUTO;
          w_dep_record.tipo_versamento := rec_mov.TIPO_VERSAMENTO;
          w_dep_record.causale_versamento := rec_mov.CAUSALE_VERSAMENTO;
          w_dep_record.dati_riscossione := w_dati_riscossione;
          w_dep_record.utente_ultimo_agg := rec_mov.UTENTE_ULTIMO_AGG;
          -- Nuovi campi per integrazione con contabilita' finanziaria
          w_dep_record.note := to_char(null);                     -- note
          w_dep_record.dati_extra := to_char(null);               -- dati_extra
          w_dep_record.accertamento := w_accertamento;            -- accertamento
          w_dep_record.bilancio := w_bilancio;                    -- bilancio
          w_dep_record.data_scadenza_avviso := rec_mov.data_scadenza_avviso;   -- data_scadenza_avviso
          w_dep_record.rata_numero := to_number(null);            -- rata_numero
          w_dep_record.rata_unica_ref := to_char(null);           -- rata_unica_ref
          w_dep_record.dicitura_scadenza := rec_mov.dicitura_scadenza;
       -- (RV - 31/08/2023: nuovi campi per gestione scomposizione degli importi
          w_dep_record.quote_mb := w_dettagli_quote;
          w_dep_record.metadata := w_metadata_quote;
          --
          -- Si memorizza la riga per il ref_cursor finale
          p_tab_dovuti.extend;
          w_ind := w_ind + 1;
          p_tab_dovuti (w_ind) := w_dep_record;
          w_errore := 'Selezionato Idback: '||w_dep_record.idback||', Azione: '||w_dep_record.azione;
          pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
        --dbms_output.put_line('tab_dati_riscossione: '||w_dep_record.dati_riscossione);
       end if;
       if w_importo_vers < rec_mov.importo_dovuto then
          w_importo_vers := 0;
       else
          w_importo_vers := w_importo_vers - rec_mov.importo_dovuto;
       end if;
    end if;
  end loop;

  open rc for select * from table(f_get_collection);
  --
  return rc;
  --
end;
--------------------------------------------------------------------------------------------------------
function determina_dovuti_pratica
( p_pratica                 in number
, p_tipo_dovuto             in varchar2 default null
) return sys_refcursor is
/*************************************************************************
 NOME:         DETERMINA_DOVUTI_PRATICA
 DESCRIZIONE:  Restituisce un elenco di dovuti relativi a una pratica di
               violazione oppure a un calcolo imposta su pratica gia'
               passati a DEPAG per cui deve essere lanciato il web-service
               di allineamento al partner tecnologico oppure recuperato
               l'avviso AGID

 PARAMETRI:    p_pratica             Pratica da elaborare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   27/07/2022  VD      Prima emissione.
 001   10/01/2023  DM      Si tiene conto del tipo pratica nella
                           determinazione del servizio.
 002   23/01/2024  RV      #66207
                           Implementata logica per dovuto mb
*************************************************************************/
  w_operazione_log         varchar2(100):= 'determina_dovuti_pratica';
  w_errore                 varchar2(4000);
  w_ind                    number;
  w_des_cliente            varchar2(60);
  w_dep_record             depag_dovuti%rowtype;
  rc                       sys_refcursor;
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  p_tab_dovuti.delete;
  w_ind := 0;

  for sel_idback in
    ( select distinct
             decode(impo.pref_pratica,
                    null,nvl(impo.gruppo_tributo,impo.tipo_tributo),
                    rpad(nvl(impo.gruppo_tributo,impo.tipo_tributo),5,' '))||
             impo.tipo_occupazione||impo.pref_pratica||
             impo.anno||lpad(nvl(impo.pratica,0),10,'0')||rpad(impo.cod_fiscale,16)||
             decode(impo.pref_pratica,
                    null,to_char(impo.rata),
                    lpad(to_char(impo.rata),2,'0'))||
             decode(vers.nvers,null,null,'-'||vers.nvers) idback,
             f_depag_servizio(nvl(impo.gruppo_tributo,impo.tipo_tributo),impo.tipo_occupazione,
                                                 decode(impo.tipo_pratica,'D',null,'S'),dovuto_mb) servizio
        from (select prtr.tipo_pratica,
                     prtr.tipo_tributo,
                     prtr.anno,
                     prtr.cod_fiscale,
                     prtr.pratica,
                     pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                     pagonline_tr4.f_get_tipo_occupazione(prtr.pratica) tipo_occupazione,
                     dovuto_mb.dovuto_mb,
                     decode(prtr.tipo_tributo
                           ,'CUNI',pagonline_tr4.f_get_gruppo_tributo(prtr.pratica)
                           ,null) gruppo_tributo,
                     0 rata
                from pratiche_tributo prtr,
                     (select null as dovuto_mb from dual
                      union
                      select 'S' from dual) dovuto_mb
               where prtr.pratica = p_pratica
                 and nvl(prtr.tipo_atto,-1) <> 90
                 and not exists (select 1
                                   from oggetti_pratica ogpr,
                                        oggetti_imposta ogim,
                                        rate_imposta raim
                                  where raim.oggetto_imposta = ogim.oggetto_imposta
                                    and ogim.oggetto_pratica = ogpr.oggetto_pratica
                                    and ogpr.pratica = prtr.pratica)
               union
              select prtr.tipo_pratica,
                     prtr.tipo_tributo,
                     prtr.anno,
                     prtr.cod_fiscale,
                     prtr.pratica,
                     pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                     pagonline_tr4.f_get_tipo_occupazione(prtr.pratica) tipo_occupazione,
                     dovuto_mb.dovuto_mb,
                     decode(prtr.tipo_tributo
                           ,'CUNI',pagonline_tr4.f_get_gruppo_tributo(prtr.pratica)
                           ,null) gruppo_tributo,
                     rapr.rata rata
                from pratiche_tributo prtr,
                     rate_pratica rapr,
                     (select null as dovuto_mb from dual
                      union
                      select 'S' from dual) dovuto_mb
               where prtr.pratica = p_pratica
                 and rapr.pratica = prtr.pratica
                 and nvl(prtr.tipo_atto,-1) = 90
              union   -- AB 17/01/2023 aggiunte le eventuali rate_imposta sulla pratica
              select prtr.tipo_pratica,
                     prtr.tipo_tributo,
                     prtr.anno,
                     prtr.cod_fiscale,
                     prtr.pratica,
                     pagonline_tr4.f_get_pref_pratica(prtr.tipo_pratica,prtr.tipo_evento) pref_pratica,
                     pagonline_tr4.f_get_tipo_occupazione(prtr.pratica) tipo_occupazione,
                     dovuto_mb.dovuto_mb,
                     decode(prtr.tipo_tributo
                           ,'CUNI',pagonline_tr4.f_get_gruppo_tributo(prtr.pratica)
                           ,null) gruppo_tributo,
                     raim.rata
                from pratiche_tributo prtr,
                     oggetti_pratica ogpr,
                     oggetti_imposta ogim,
                     rate_imposta raim,
                     (select null as dovuto_mb  from dual
                      union
                      select 'S' from dual) dovuto_mb
               where raim.oggetto_imposta = ogim.oggetto_imposta
                 and ogim.oggetto_pratica = ogpr.oggetto_pratica
                 and ogpr.pratica = prtr.pratica
                 and prtr.pratica = p_pratica
                 and nvl(prtr.tipo_atto,-1) <> 90) impo,
             (select to_number(null) nvers
                from dual
               union
              select rownum nvers
                from versamenti
               where pratica = p_pratica
             ) vers
    where impo.pratica = p_pratica
    order by 1)
  loop
    w_dep_record := depag_service_pkg.dovuto_per_idback(sel_idback.idback, w_des_cliente, sel_idback.servizio);
    if w_dep_record.id is not null and
      (p_tipo_dovuto is null or
      (p_tipo_dovuto = 'NP' and
       w_dep_record.stato_invio_ricezione not in ('I','P','T'))) then
       p_tab_dovuti.extend;
       w_ind := w_ind + 1;
       p_tab_dovuti (w_ind) := w_dep_record;
       w_errore := 'Selezionato Idback: '||w_dep_record.idback||', Azione: '||w_dep_record.azione;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
    end if;
  end loop;

  open rc for select * from table(f_get_collection);
  --
  return rc;
  --
end;
-------------------------------------------------------------------------------
function annullamento_dovuto
( p_ente                IN varchar2
, p_idback              IN varchar2
, p_utente              IN varchar2
)
 return number IS
/*************************************************************************
 NOME:         ANNULLAMENTO_DOVUTO
 DESCRIZIONE:  Annulla pagamenti gia' passati a PAGONLINE.

 PARAMETRI:    p_ente            Identificativo dell'ente
               p_idback          Identificativo del pagamento da annullare
               p_utente          Utente che effettua l'operazione

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
*************************************************************************/

 RetVal                      VARCHAR2(8);
 w_des_cliente               varchar2(60);
 w_idback_ann                depag_dovuti.idback%TYPE;

 w_return number             :=1;
 w_operazione_log            varchar2(100) := 'Annullamento_dovuto-annulladovutilike';
 w_errore                    varchar2(1000);
 errore                      exception;

begin
  if p_ente is null then
     w_des_cliente := pagonline_tr4.descrizione_ente;
  else
     w_des_cliente := p_ente;
  end if;
  w_idback_ann  := p_idback;

  pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' '||w_des_cliente||' '||p_utente);
  RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , p_utente);
  if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
     pagonline_tr4.inserimento_log(w_operazione_log, w_idback_ann||' OK: Retval = '||RetVal);
     w_return := 1;
  else
     w_errore := w_idback_ann ||' ERRORE: Retval = '||Retval;
     raise errore;
  end if;

  return w_return;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end annullamento_dovuto;
-------------------------------------------------------------------------------
function aggiornamento_pagamenti
( p_ente                    in varchar2 default null
, p_idback                  in varchar2 default null
, p_iuv                     in varchar2
, p_importo_versato         in varchar2
, p_data_pagamento          in varchar2
, p_utente                  in varchar2
, p_servizio                in varchar2 default null
, p_quote_mb                in varchar2 default null
) return number is
/*************************************************************************
 NOME:         AGGIORNAMENTO_PAGAMENTI
 DESCRIZIONE:

 PARAMETRI:

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
 001   16/05/2022  VD      Aggiunta gestione versamenti CUNI per unificare
                           la codifica.
 002   17/05/2022  VD      Aggiunta gestione idback di ritorno per violazioni
                           TARSU.
 003   08/02/2024  RV      #69861
                           Aggiunta separaszione quota addizionale_pro
*************************************************************************/
  w_servizio                depag_dovuti.servizio%type;
  w_importo_pag             number;
  w_operazione_log          varchar2(100) := 'aggiornamento_pagamenti';

  w_errore                  varchar2(4000);
  errore                    exception;
  w_dep_record              depag_dovuti%rowtype;

  w_fonte                   number;
  w_tipo_tributo            varchar2(5);
  w_tipo_violaz             varchar2(4);  -- Tipo Violazione (ACC%, SOL%, RAV%)
  w_tipo_violaz_sto         varchar2(4);  -- Tipo Violazione senza tipo occupazione/evento
  w_anno                    number;
  w_pratica                 number;
  w_cod_fiscale             varchar2(16);
  w_rata                    number;
  w_sequenza                number;
  w_data_pagamento          date;
  w_ruolo                   number;

  w_add_prov_s             varchar2(2000);
  w_add_prov                number;
  w_imposta                 number;
  w_quota_add_prov          number;

  w_contatore               number;

  -- Variabili per gestione separatore decimali
  -- a seconda dell'impostazione NLS_NUMERIC
  -- di Oracle
  w_da_sostituire            varchar2(1);
  w_sostituto                varchar2(1);

begin
  pagonline_tr4.inserimento_log(w_operazione_log, 'Gestione movimenti per ente '||p_ente||' idback: '||p_idback);
  --
  -- Selezione del parametro NLS_NUMERIC_CHARACTERS
  --
  begin
    select decode(substr(value,1,1)
                 ,'.',',','.')
         , substr(value,1,1)
      into w_da_sostituire
         , w_sostituto
      from nls_session_parameters
     where parameter = 'NLS_NUMERIC_CHARACTERS';
  exception
    when others then
      w_da_sostituire := ',';
      w_sostituto := '.';
  end;
  -- (VD - 17/12/2020): se il servizio è null, si ricerca il valore su depag_dovuti
  if p_servizio is null then
     w_dep_record := depag_service_pkg.dovuto_per_iuv(p_iuv,p_ente,null);
     if w_dep_record.servizio is not null then
        w_servizio := w_dep_record.servizio;
     else
        w_errore:= 'Impossibile determinare il servizio - IUV: '||p_iuv||', id.Back: '||p_idback;
        pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
        return 0;
     end if;
  else
     w_servizio := p_servizio;
  end if;
  --
  begin
    select count(*)
      into w_contatore
      from versamenti
     where servizio = w_servizio
       and idback = p_idback;
  exception
    when others then
      w_contatore := 0;
  end;
  if w_contatore > 0 then
    w_errore:= 'Versamento con stesso servizio / idback già presente in banca dati: '||p_servizio||' / '||p_idback||', IUV: '||p_iuv;
    pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
    return 0;
  end if;
  --
  w_fonte          := f_inpa_valore('FONT_DEPAG');
  w_data_pagamento := trunc(to_date(p_data_pagamento,'dd/mm/yyyy hh24.mi.ss'));
  w_ruolo          := to_number(null);
  w_pratica        := to_number(null);
  w_tipo_violaz    := '';
  w_tipo_violaz_sto:= '';

  if rtrim(substr(p_idback,1,5)) in ('TOSAP','ICP') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,5));
     -- (VD - 23/07/2021): se i quattro caratteri a partire dalla posizione 7
     --                    dell'idback sono numerici, significa che si sta
     --                    trattando un versamento d'imposta.
     --                    In caso contrario si tratta di versamento su
     --                    violazione (LIQ%, ACC%, RAV%) quindi la pratica
     --                    inizia alla posizione 15.
     if afc.is_numeric(substr(p_idback,7,4)) = 1 then
        w_anno           := to_number(substr(p_idback,7,4));
        w_pratica        := to_number(substr(p_idback,11,10));
        w_cod_fiscale    := rtrim(substr(p_idback,21,16));
        w_rata           := to_number(substr(p_idback,37,1));
     else
        w_anno           := to_number(substr(p_idback,11,4));
        w_pratica        := to_number(substr(p_idback,15,10));
        w_cod_fiscale    := rtrim(substr(p_idback,25,16));
        w_rata           := to_number(substr(p_idback,41,1));
     end if;
  elsif
     -- (VD - 23/07/2021): questa opzione serve perche' la prima
     --                    versione di emissione DEPAG per imposta
     --                    non formattava il tipo tributo a 5 caratteri
     --                    quindi su vecchi idback ci potrebbe essere
     --                    un formato del tipo 'ICPAAAA0000000000...'
     substr(p_idback,1,3) in ('ICP') then
     w_tipo_tributo   := substr(p_idback,1,3);
     w_anno           := to_number(substr(p_idback,5,4));
     w_pratica        := to_number(substr(p_idback,9,10));
     w_cod_fiscale    := rtrim(substr(p_idback,19,16));
     w_rata           := to_number(substr(p_idback,35,1));
  elsif
     rtrim(substr(p_idback,1,5)) = 'TARSU' then
     w_tipo_tributo   := rtrim(substr(p_idback,1,5));
     -- (VD - 17/05/2022): gestione violazioni TARSU
     --                    se i quattro caratteri a partire dalla posizione 6
     --                    dell'idback sono numerici, significa che si sta
     --                    trattando un versamento d'imposta.
     --                    In caso contrario si tratta di versamento su
     --                    violazione (LIQ%, ACC%, RAV%) quindi la pratica
     --                    inizia alla posizione 15.
     if afc.is_numeric(substr(p_idback,6,4)) = 1 then
        w_anno           := to_number(substr(p_idback,6,4));
        w_ruolo          := to_number(substr(p_idback,10,10));
        w_cod_fiscale    := rtrim(substr(p_idback,20,16));
        w_rata           := to_number(substr(p_idback,36,1));
     else
        w_tipo_violaz    := substr(p_idback,7,4);
        w_tipo_violaz_sto:= substr(p_idback,7,3);
        w_anno           := to_number(substr(p_idback,11,4));
        w_pratica        := to_number(substr(p_idback,15,10));
        w_cod_fiscale    := rtrim(substr(p_idback,25,16));
        w_rata           := to_number(substr(p_idback,41,1));
     end if;
  elsif
     -- (VD - 09/03/2022): trattamento CUNI/CUME.
     --                    L'emissione dei dovuti su calcolo imposta non
     --                    formatta il tipo tributo a 5 caratteri
     --                    Quindi gli idback senza spazio tra CUNI/CUME e
     --                    tipo occupazione sono relativi al calcolo imposta
     rtrim(substr(p_idback,1,5)) in('CUNIP','CUNIT','CUMEP','CUMET') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,4));
     w_anno           := to_number(substr(p_idback,6,4));
     w_pratica        := to_number(substr(p_idback,10,10));
     w_cod_fiscale    := rtrim(substr(p_idback,20,16));
     w_rata           := to_number(substr(p_idback,36,1));
  elsif
     -- (VD - 09/03/2022): trattamento CUNI/CUME.
     --                    L'emissione dei dovuti su pratiche di violazione
     --                    formatta il tipo tributo a 5 caratteri
     --                    Quindi gli idback con spazio tra CUNI/CUME e
     --                    tipo occupazione sono relativi a versamenti su
     --                    pratica
     substr(p_idback,1,6) in ('CUNI P','CUNI T','CUME P','CUME T') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,4));
     w_anno           := to_number(substr(p_idback,11,4));
     w_pratica        := to_number(substr(p_idback,15,10));
     w_cod_fiscale    := rtrim(substr(p_idback,25,16));
     w_rata           := to_number(substr(p_idback,41,2));
  elsif
     -- (RV - 20/10/2023): trattamento ICI/IMU/TASI.
     --                    L'emissione dei dovuti su pratiche di violazione
     --                    formatta il tipo tributo a 5 caratteri,
     --                    come richiesto ignora il tipo occupazione
     rtrim(substr(p_idback,1,5)) in ('ICI','TASI') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,5));
     w_anno           := to_number(substr(p_idback,11,4));
     w_pratica        := to_number(substr(p_idback,15,10));
     w_cod_fiscale    := rtrim(substr(p_idback,25,16));
     w_rata           := to_number(substr(p_idback,41,2));
  else
     w_errore := 'Tipo tributo non previsto'||rtrim(substr(p_idback,1,5))||
                 ', idback '||p_idback;
     RAISE errore;
  end if;
  if w_tipo_tributo = 'CUME' then
     w_tipo_tributo := 'CUNI';
  end if;
  --
  -- Conversione importo a seconda del parametro NLS_NUMERIC di Oracle
  w_importo_pag := to_number(translate(p_importo_versato,w_da_sostituire,w_sostituto));
  --dbms_output.put_line('Importo: '||p_importo_versato||', '||w_importo_pag);

  --
  w_imposta := null;
  w_add_prov := null;
  --
  -- Per TARSU proviamo a scomporre l'importo TEFA
  --
  if w_tipo_tributo = 'TARSU' then
    if p_quote_mb is not null then
      --
      -- Ci sono le quote, prendiamo la TEFA da li
      --
      begin
        select extractvalue(xmltype(p_quote_mb),
               '/QUOTE_MB/QUOTA[CAUSALE[contains(text(), "TEFA")]]/IMPORTO') as importo
        into
          w_add_prov_s
        from dual;
      exception
        when others then
          w_errore := 'Errore in inserimento versamento'||' di '||w_cod_fiscale||' ('||sqlerrm||')';
          RAISE errore;
      end;
      if w_add_prov_s is not null then
        w_add_prov := to_number(translate(w_add_prov_s,w_da_sostituire,w_sostituto));
        w_imposta := w_importo_pag - w_add_prov ;
      end if;
    else
      --
      -- Non ci sono le quote, calcoliamo usando il valore in carichi_tarsu per l'anno del versamento
      -- 20240315 (RV) : Questo calcolo lo si fa solo se NON ACC e RAV
      --
      if w_tipo_violaz_sto not in ('ACC', 'RAV') then
        begin
          select cata.addizionale_pro
            into w_quota_add_prov
            from carichi_tarsu cata
           where cata.anno = w_anno;
        exception
          when others then
            w_quota_add_prov := null;
        end;
        if nvl(w_quota_add_prov,0) > 0 then
          w_add_prov := round(((w_importo_pag / (100.0 + w_quota_add_prov)) * w_quota_add_prov),2);
          w_imposta := w_importo_pag - w_add_prov ;
        end if;
      end if;
    end if;
  end if;
  --
  BEGIN -- Assegnazione Numero Progressivo
    select nvl(max(vers.sequenza),0)+1
      into w_sequenza
      from versamenti vers
     where vers.cod_fiscale     = w_cod_fiscale
       and vers.anno            = w_anno
       and vers.tipo_tributo    = w_tipo_tributo
    ;
  END;
  --
--dbms_output.put_line('Versamento su CF: '||w_cod_fiscale||', Anno: '||w_anno||', Tributo: '||impo.tipo_tributo);
--dbms_output.put_line('Pratica: '||w_pratica||', Viol: '||w_tipo_violaz||', Importo: '||w_importo_pag||', TEFA: '||w_add_prov||', Rata: '||w_rata||', Sequenza: '||w_sequenza);
  --
  BEGIN
    insert into versamenti
           (cod_fiscale
           ,anno
           ,pratica
           ,tipo_tributo
           ,sequenza
           ,descrizione
           ,ufficio_pt
           ,data_pagamento
           ,importo_versato
           ,imposta
           ,addizionale_pro
           ,fonte
           ,utente
           ,data_variazione
           ,data_reg
           ,ruolo
           ,rata
           ,note
           ,servizio
           ,idback)
     select w_cod_fiscale
           ,w_anno
           -- AB 14/02/2023 aggiunta la seconda decode per trattare i versamenti su Sollecito scollegati da pratica
           ,decode(w_pratica,0,to_number(null),
                   decode(substr(p_idback,7,3),'SOL',to_number(null),w_pratica))
           ,w_tipo_tributo
           ,w_sequenza
           ,'VERSAMENTO IMPORTATO DA PAGONLINE'
           ,'' --rec_vers.ufficio_pt
           ,w_data_pagamento
           ,w_importo_pag
           ,w_imposta
           ,w_add_prov
           ,w_fonte
           ,p_utente
           ,trunc(sysdate)
           ,sysdate
           ,w_ruolo
           ,w_rata
           ,'IUV: '||p_iuv
           ,w_servizio
           ,p_idback
       from dual
     ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in inserimento versamento'||
                  ' di '||w_cod_fiscale||' progressivo '||
                  to_char(w_sequenza)||' ('||sqlerrm||')';
      --
     --bms_output.put_line('Errore: '||w_errore);
      --
      RAISE errore;
  END;
  return 1;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       return 0||'|'||w_errore;
  when others then
       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       return 0||'|'||w_errore;

end aggiornamento_pagamenti;
--------------------------------------------------------------------------------------------------------
function inserimento_dovuti_cu
( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_pratica                 in number
  , p_chk_rate                in number
  , p_gruppo_tributo          in varchar2 default null
) return number is

/******************************************************************************
 NOME:        INSERIMENTO_DOVUTI_CU
 DESCRIZIONE: Carica l'elenco degli importi dovuti per PAGONLINE.
              Tributi: Solo CUNI

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_pratica             Eventuale pratica su cui calcolare
                                    l'imposta
              p_chk_rate            0 - calcolo senza rateizzazione
                                    > 0 - calcolo con rateizzazione
              p_gruppo_tributo      Gruppo tributo del Tipo Tributo da elaborare
                                    (null = tutti i gruppi tributo)

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 004   19/03/2021  RV      Prima emissione, basato su medesima funzione di PAGONLINE_TR4
                           Revisione 003 (VD)
 005   03/05/2021  RV      Rivisto selezione IDBack da eliminare su calcolo totale,
                           integrato per gestione separata CUNI/CUME
 006   02/05/2022  VD      Corretta selezione Idback da eliminare su calcolo totale:
                           occorre trattare le denunce con anno <= anno imposta
                           Aggiunto inserimento dati contabili per integrazione
                           con CFA
 007   14/12/2023  RV      #54733
                           Aggiunto filtro per flag_no_depag di categoria e tariffe
                           Modificato select movimenti per più temporanee in unica pratica
 008   11/01/2024  RV      #54732
                           Modifiche per gestione gruppo tributo e date scadenza personalizzate
 009   21/05/2024  RV      #70776
                           Aggiunto gestione dati contabili per tipo occupazione
******************************************************************************/
RetVal                      VARCHAR2(8);
w_des_cliente               varchar2(60);
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
w_iud_prec                  depag_dovuti.iud%TYPE;
w_importo_vers              number;
w_conta_vers                number;
w_return                    number:= 0;
w_operazione_log            varchar2(100) := 'Inserimento dovuti CU';
w_ordinamento               varchar2(1);
w_tipo_occupazione          varchar2(10);
w_cf_prec                   varchar2(16);
w_pratica_prec              number;

w_errore                    varchar2(4000);
errore                      exception;

-- (VD - 06/05/2022): Dati per contabilita' finanziaria
w_int_cfa                   varchar2(1);
w_capitolo                  varchar2(200);
w_dati_riscossione          depag_dovuti.dati_riscossione%type;
w_accertamento              depag_dovuti.accertamento%type;
w_bilancio                  depag_dovuti.bilancio%type;

-- Cursore per annullare i dovuti di tutte le denunce dell'anno
-- (in questo modo vengono eliminati anche i dovuti relativi
-- a pratiche da non trattare più)
cursor sel_pratiche_ann is
  select prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from pratiche_tributo prtr
        ,oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where (
       ((p_tipo_tributo <> 'CUNI') and (prtr.tipo_tributo = p_tipo_tributo)) or
       ((p_tipo_tributo = 'CUNI') and (prtr.tipo_tributo in ('ICP','TOSAP','CUNI')))
     )
     and prtr.anno                   = p_anno
     and prtr.cod_fiscale         like p_cod_fiscale
     and prtr.tipo_pratica           = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.tipo_occupazione       = 'P'
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and p_pratica is null
     -- RV 2024/04/04 : annulla solo le pratiche con almeno un oggetto nato prima del 01/01 dell'anno di calcolo
     and exists (select 1 from oggetti_validita ogva
                 where ogva.cod_fiscale = prtr.cod_fiscale
                   and ogva.tipo_tributo = prtr.tipo_tributo
                   and ogva.pratica = prtr.pratica
                   and (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') < lpad(to_char(p_anno),4,'0')||'0101')
     )
   group by
         prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo)
  union
  select p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where ogpr.pratica                = p_pratica
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and p_pratica is not null
   group by
         p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo)
   order by 1,2;

-- Cursore per annullare i dovuti totali dell'anno relativi a denunce degli anni precedenti
cursor sel_pratiche_totali_ann is
  select prtr.cod_fiscale
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from pratiche_tributo prtr
        ,oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where (
       ((p_tipo_tributo <> 'CUNI') and (prtr.tipo_tributo = p_tipo_tributo)) or
       ((p_tipo_tributo = 'CUNI') and (prtr.tipo_tributo in ('ICP','TOSAP','CUNI')))
     )
     -- (VD - 02/05/2022): corretta selezione pratiche. L'anno deve essere
     --                    <= dell'anno di imposta, altrimenti si annullano solo i
     --                    dovuti relativi alle denunce dell'anno
     --and prtr.anno                   = p_anno
     and prtr.anno                   <= p_anno
     and prtr.cod_fiscale         like p_cod_fiscale
     and prtr.tipo_pratica           = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.tipo_occupazione       = 'P'
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and ((p_gruppo_tributo is null) or
         ((p_gruppo_tributo is not null) and (cotr.gruppo_tributo = p_gruppo_tributo))
     )
     and p_pratica is null
   group by
         prtr.cod_fiscale
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo);

-- Cursore per selezionare l'imposta da passare a DEPAG
cursor sel_mov is
    select
      impo.ordinamento,
      impo.cod_fiscale,
      impo.pratica,
      impo.rata,
      impo.ente,
      impo.iud,
      impo.servizio,
      impo.idback,
      impo.backend,
      impo.cod_iuv,
      impo.tipo_ident,
      impo.codice_ident,
      impo.anag_pagatore,
      impo.indirizzo_pagatore,
      impo.civico_pagatore,
      impo.cap_pagatore,
      impo.localita_pagatore,
      impo.prov_pagatore,
      impo.naz_pagatore,
      impo.email_pagatore,
      min(impo.data_scadenza) data_scadenza,
      sum(impo.importo_dovuto) importo_dovuto,
      impo.commissione_carico_pa,
      impo.tipo_dovuto,
      impo.tipo_versamento,
      --
      case when sum(impo.causale_contatore) <= 1 then
        max(impo.causale_versamento)
      else
        max(impo.causale_occupazsione) || ', ' ||
        to_char(sum(impo.causale_contatore)) || ' CANONI' ||
        decode(min(inizio_occupazione),null,'',
              ' DAL: ' || to_char(min(inizio_occupazione),'dd/mm/yyyy'))||
        decode(max(fine_occupazione),null,'',
              ' AL: ' || to_char(max(fine_occupazione),'dd/mm/yyyy'))||
        max(impo.causale_rata)
      end as causale_versamento,
      --
      impo.dati_riscossione,
      impo.utente_ultimo_agg
    from
    (
    -------------------------------------------------------------------
   -- Selezione per calcolo imposta senza rateizzazione (o imposta non rateizzata perche'
   -- inferiore al limite indicato)
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,impo.cotr_tributo||impo.tipo_occupazione||
                                                           p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                                                            rpad(cont.cod_fiscale,16)||0 -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , 0 rata
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(impo.cotr_tributo,impo.tipo_occupazione,null,null) servizio
        , impo.cotr_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||0 idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35) localita_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        ,case
          -- Data scadenza : se c'è prende la scadenza dagli ogim;
          --                 se non c'è cerca quella della pratica (solo se calcolo per pratica);
          --                 altrimenti la prende da Scadenze tramite f_scadenza_rata.
          when impo.scadenza_ogim < to_date('31129999','ddmmyyyy') then
               impo.scadenza_ogim
          when impo.pratica is not null and impo.scadenza_pratica < to_date('31129999','ddmmyyyy') then
               impo.scadenza_pratica
          else f_scadenza_rata(p_tipo_tributo,p_anno,0,p_gruppo_tributo,impo.tipo_occupazione)
         end as data_scadenza
        , decode(titr.flag_canone,'S',nvl(impo.imposta,0)
                                     ,round(nvl(impo.imposta, 0))) importo_dovuto
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: UNICA'     causale_versamento
        --
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA') as causale_occupazsione
        , decode(impo.tipo_occupazione,'T',impo.inizio_occupazione,null) as inizio_occupazione
        , decode(impo.tipo_occupazione,'T',impo.fine_occupazione,null) as fine_occupazione
        , ', RATA: UNICA' as causale_rata
        , 1 as causale_contatore
        --
        , null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , tipi_tributo     titr
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione) fine_occupazione,
                  nvl(cotr.conto_corrente,99999900) as cc_riferimento,
                  nvl(cotr.descrizione_cc,p_tipo_tributo) as cotr_tributo,
                  sum(ogim.imposta) imposta,
                  min(nvl(prtr.data_scadenza,to_date('31129999','ddmmyyyy'))) as scadenza_pratica,
                  min(nvl(ogim.data_scadenza,to_date('31129999','ddmmyyyy'))) as scadenza_ogim
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr,
                  codici_tributo cotr,
                  categorie cate,
                  tariffe tari
            where ogpr.pratica  = prtr.pratica
              --and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
              and cotr.tributo = ogpr.tributo
              and ((p_gruppo_tributo is null) or
                   ((p_gruppo_tributo is not null) and (cotr.gruppo_tributo = p_gruppo_tributo))
              )
              and cate.tributo = ogpr.tributo
              and cate.categoria = ogpr.categoria
              and tari.tributo = ogpr.tributo
              and tari.categoria = ogpr.categoria
              and tari.tipo_tariffa = ogpr.tipo_tariffa
              and tari.anno = p_anno
              and nvl(tari.flag_no_depag,nvl(cate.flag_no_depag,'N')) <> 'S'
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione),
                  nvl(cotr.conto_corrente,99999900),
                  cotr.descrizione_cc,
                  nvl(prtr.data_scadenza,to_date('31129999','ddmmyyyy'))
                  ) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.cod_fiscale = cont.cod_fiscale
      and impo.anno = p_anno
      and (p_chk_rate = 0 or
          (p_chk_rate > 0 and not exists
            (select 'x' from rate_imposta raim
                                           where raim.tipo_tributo = p_tipo_tributo
                                             and raim.cod_fiscale = cont.cod_fiscale
                                             and raim.anno = p_anno
                 and nvl(raim.conto_corrente,99990000) = impo.cc_riferimento
                                             and ((impo.pratica is null and raim.oggetto_imposta is null) or
                                                  (impo.pratica is not null and raim.oggetto_imposta in
                                                 (select ogim.oggetto_imposta
                                                    from oggetti_imposta ogim
                                                       , oggetti_pratica ogpr
                                                   where ogpr.pratica = impo.pratica
                                                     and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
                                          )
          ))
   union
   -------------------------------------------------------------------
   -- Selezione per calcolo imposta con rateizzazione
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                        ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,impo.cotr_tributo||impo.tipo_occupazione||
                                                                p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                                                             rpad(cont.cod_fiscale,16)||raim.rata -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , raim.rata
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(impo.cotr_tributo,impo.tipo_occupazione,null,null) servizio
        , impo.cotr_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||raim.rata idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
             ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
              localita_pagatore
        , nvl(ltrim(replace(replace(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SP'),'(',''),')',''))
             ,ad4_provincia.get_sigla(sogg.cod_pro_res)) prov_pagatore
--        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SS2')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        , raim.data_scadenza
        , decode(titr.flag_canone,'S',sum(nvl(raim.imposta,0))
                                     ,sum(nvl(raim.imposta_round, 0))) importo_dovuto
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: '||raim.rata     causale_versamento
        --
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA') as causale_occupazsione
        , decode(impo.tipo_occupazione,'T',impo.inizio_occupazione,null) as inizio_occupazione
        , decode(impo.tipo_occupazione,'T',impo.fine_occupazione,null) as fine_occupazione
        , ', RATA: '||raim.rata as causale_rata
        , 1 as causale_contatore
        --
        , null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , tipi_tributo     titr
        , (select tipo_tributo,
                  cod_fiscale,
                  anno,
                  rata,
                  conto_corrente,
                  oggetto_imposta,
                  imposta,
                  imposta_round,
                  nvl(data_scadenza,f_scadenza_rata (p_tipo_tributo, p_anno, rata)) data_scadenza
             from rate_imposta raim
            where tipo_tributo = p_tipo_tributo
              and cod_fiscale like p_cod_fiscale
              and anno = p_anno
              and nvl(raim.conto_corrente,99990000) in (
                 select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                 from codici_tributo cotr
                 where cotr.flag_ruolo is null
                   and ((p_gruppo_tributo is null) or
                       ((p_gruppo_tributo is not null) and (cotr.gruppo_tributo = p_gruppo_tributo))
                   )
              )
              and nvl(instr(nvl(note,'-'),'[NoDePag]'),0) = 0
                  ) raim
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  min(decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione)) inizio_occupazione,
                  max(decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione)) fine_occupazione,
                  nvl(cotr.conto_corrente,99999900) as cc_riferimento,
                  nvl(cotr.descrizione_cc,p_tipo_tributo) as cotr_tributo,
                  sum(ogim.imposta) imposta
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr,
                  codici_tributo cotr,
                  categorie cate,
                  tariffe tari
            where ogpr.pratica  = prtr.pratica
              and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
              and cotr.tributo = ogpr.tributo
              and cate.tributo = ogpr.tributo
              and cate.categoria = ogpr.categoria
              and tari.tributo = ogpr.tributo
              and tari.categoria = ogpr.categoria
              and tari.tipo_tariffa = ogpr.tipo_tariffa
              and tari.anno = p_anno
              and nvl(tari.flag_no_depag,nvl(cate.flag_no_depag,'N')) <> 'S'
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione),
                  nvl(cotr.conto_corrente,99999900),
                  cotr.descrizione_cc
                  ) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.anno = p_anno
      and impo.cod_fiscale = cont.cod_fiscale
      and raim.tipo_tributo = p_tipo_tributo
      and raim.cod_fiscale = cont.cod_fiscale
      and raim.anno = p_anno
      and nvl(raim.conto_corrente,99999900) = impo.cc_riferimento
      and ((impo.pratica is null and raim.oggetto_imposta is null) or
           (impo.pratica is not null and raim.oggetto_imposta in
           (select ogim.oggetto_imposta
              from oggetti_imposta ogim
                 , oggetti_pratica ogpr
             where ogpr.pratica = impo.pratica
               and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
      and p_chk_rate > 0
    group by cont.cod_fiscale,sogg.ni,sogg.cognome_nome,sogg.tipo_residente,sogg.tipo,
             sogg.cod_via,sogg.denominazione_via,sogg.num_civ,sogg.suffisso,sogg.interno,
             sogg.cod_pro_res,sogg.cod_com_res,arvi.denom_uff,sogg.cap,
             impo.cc_riferimento,
             impo.cotr_tributo,
             impo.tipo_occupazione,impo.pratica,
             impo.inizio_occupazione,impo.fine_occupazione,
             raim.rata,raim.data_scadenza,
             titr.flag_canone
    -------------------------------------------------------------------
    ) impo
    group by
      impo.ordinamento,
      impo.cod_fiscale,
      impo.pratica,
      impo.rata,
      impo.ente,
      impo.iud,
      impo.servizio,
      impo.idback,
      impo.backend,
      impo.cod_iuv,
      impo.tipo_ident,
      impo.codice_ident,
      impo.anag_pagatore,
      impo.indirizzo_pagatore,
      impo.civico_pagatore,
      impo.cap_pagatore,
      impo.localita_pagatore,
      impo.prov_pagatore,
      impo.naz_pagatore,
      impo.email_pagatore,
      impo.commissione_carico_pa,
      impo.tipo_dovuto,
      impo.tipo_versamento,
      impo.dati_riscossione,
      impo.utente_ultimo_agg
    order by 1,2,3,4;
---------------------------------------------------------------------------------------------------
  begin
    w_des_cliente := pagonline_tr4.descrizione_ente;
    -- Si memorizza il tipo di ordinamento da utilizzare nella emissione dei dovuti
    w_ordinamento := nvl(f_inpa_valore('PAGONL_ORD'),'A');
    pagonline_tr4.inserimento_log(w_operazione_log||' - Inizio', w_des_cliente);
    -- (VD - 06/05/2022): nuovi dati per integrazione con contabilita' finanziaria
    -- Si seleziona il flag per verificare l'integrazione con CFA
    w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');
    -- Determinazione accertamento contabile abbinato all'imposta
    -- (da memorizzare nel campo "accertamento" di depag_dovuti)
    w_accertamento := null;
    w_dati_riscossione := null;
    w_capitolo := null;
    if w_int_cfa = 'S' then
       if p_pratica is not null then
         w_tipo_occupazione := dati_contabili_pkg.f_get_tipo_occupazione(p_pratica);
       else
         w_tipo_occupazione := 'P';
       end if;
       w_accertamento := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                               , p_anno
                                                               , 'O'               -- tipo_imposta
                                                               , to_char(null)     -- tipo_pratica
                                                               , trunc(sysdate)    -- data_emissione
                                                               , to_char(null)     -- cod_tributo_f24
                                                               , to_char(null)     -- stato_pratica
                                                               , to_char(null)     -- data_ripartizione
                                                               , pagonline_tr4.f_get_gruppo_tributo_cod(p_tipo_tributo,p_cod_fiscale,p_anno,p_gruppo_tributo) --cod_tributo
                                                               , w_tipo_occupazione
                                                               );
       -- Determinazione capitolo abbinato all'accertamento contabile
       -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
       if w_accertamento is not null then
          w_capitolo := dati_contabili_pkg.f_get_capitolo( p_anno
                                                                 , to_number(substr(w_accertamento,1,4))
                                                                 , to_number(substr(w_accertamento,6))
                                                                 );
       end if;
    end if;
    --
    --dbms_output.put_line('Dopo ricerca fuori loop '||w_int_cfa||' r '||w_capitolo||' a '||w_accertamento);
    --
    -- Se si sta eseguendo un calcolo imposta generale o per contribuente, si selezionano le denunce
    -- dell'anno e per ognuna si annullano gli eventuali dovuti;
    -- se si sta eseguendo un calcolo per pratica, il risultato della select e' costituito dalla
    -- pratica stessa
    for rec_ann in sel_pratiche_ann
    loop
    --dbms_output.put_line('Annullo Pratica: '||rec_ann.pratica);
      w_idback_ann := rec_ann.cotr_tributo||rec_ann.tipo_occupazione||p_anno||lpad(rec_ann.pratica,10,'0')||
                      rec_ann.cod_fiscale||'%';
      pagonline_tr4.inserimento_log(w_operazione_log||' - annulladovutilike pratica', w_idback_ann);
      --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
      RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
      --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
    end loop;

    -- Prima di elaborare, si cancellano tutti i dovuti per tributo, tipo_occupazione
    -- anno e codice fiscale indicato. Se il calcolo imposta è generale, il codice
    -- fiscale sarà '%', per cui si cancellano tutte le righe per tributo e anno.
    if p_cod_fiscale = '%' or p_pratica is null then
      for rec_ann in sel_pratiche_totali_ann
      loop
        --dbms_output.put_line('Tributo: '||rec_ann.cotr_tributo);
        w_idback_ann := rec_ann.cotr_tributo||rec_ann.tipo_occupazione||p_anno||lpad('0',10,'0')||
                        rec_ann.cod_fiscale||'%';
        pagonline_tr4.inserimento_log(w_operazione_log||' - annulladovutilike totale', w_idback_ann);
        --dbms_output.put_line('Prima di annulladovutilike - ('||w_idback_ann);
        RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
        --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
      end loop;
    end if;
    --
    -- RetVal > 0 indica che è stato trovato almeno un record in DEPAG_DOVUTI
    -- ed è stato trattato dalla for .. loop
    -- Creazione dovuti per imposta calcolata
    pagonline_tr4.inserimento_log(w_operazione_log||' - prima del loop', w_des_cliente||' ' ||p_tipo_tributo||' ' ||p_anno);
    w_cf_prec      := '*';
    w_pratica_prec := -1;
    for rec_mov in sel_mov
    loop
      --
    --dbms_output.put_line('CF: '||rec_mov.cod_fiscale||', Importo: '||rec_mov.importo_dovuto||', Scadenza: '||rec_mov.data_scadenza);
      --
      -- Gestione del versato: ora si verifica se esistono dei versamenti per contribuente
      -- e se esistono si attribuiscono alle varie rate a scalare
      if rec_mov.cod_fiscale <> w_cf_prec or
         nvl(rec_mov.pratica,0) <> nvl(w_pratica_prec,0) then
         w_cf_prec      := rec_mov.cod_fiscale;
         w_pratica_prec := rec_mov.pratica;
         --
       --dbms_output.put_line('Pratica: '||rec_mov.pratica||'CF: '||rec_mov.cod_fiscale||', Rata: '||rec_mov.rata||', Dovuto: '||rec_mov.importo_dovuto||', Servizio: '||rec_mov.servizio);
         --
         if rec_mov.pratica is not null then
            -- Gestione del versato: si verifica se esistono dei versamenti per pratica
            -- e se esistono si attribuiscono alle varie rate a scalare
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
               --and nvl(vers.rata,0)        = rec_mov.rata
                 and vers.cod_fiscale        = rec_mov.cod_fiscale
                 and vers.anno               = p_anno
                 and vers.pratica            = rec_mov.pratica
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         else
            -- Si controlla l'esistenza di eventuali versamenti
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
                 and vers.cod_fiscale        = rec_mov.CODICE_IDENT
                 and vers.anno               = p_anno
                 and vers.pratica            is null
                 and ((vers.servizio is null) or
                     ((p_gruppo_tributo is null) or
                      ((p_gruppo_tributo is not null) and (vers.servizio = rec_mov.servizio))
                     )
                 )
                 --and nvl(vers.rata,0)        = rec_mov.rata
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         end if;
       end if;
       --
     --dbms_output.put_line('Versato: '||w_importo_vers);
       --
       if nvl(rec_mov.importo_dovuto,0) > 0 then
          if w_importo_vers < rec_mov.IMPORTO_DOVUTO then
           --dbms_output.put_line('Aggiorna Dovuto di: '||rec_mov.idback);
             pagonline_tr4.inserimento_log(w_operazione_log||' - aggiornadovuto', rec_mov.idback);

             -- (VD - 06/05/2022): Dati per contabilita' finanziaria
             -- Composizione del campo "bilancio"
       --      dbms_output.put_line(w_int_cfa||' r '||w_dati_riscossione||' a '||w_accertamento);
             if w_int_cfa = 'S' and
                w_capitolo is not null and
                w_accertamento is not null then
                w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_capitolo
                                                                , w_accertamento
                                                                , rec_mov.IMPORTO_DOVUTO - w_importo_vers
                                                                );
                w_dati_riscossione := dati_contabili_pkg.f_get_dati_riscossione (w_capitolo);
             else
                w_bilancio := null;
             end if;
             RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ENTE,
                                                      rec_mov.IUD, --iud
                                                      rec_mov.SERVIZIO,
                                                      --rec_mov.idback,
                                                      case
                                                        when w_conta_vers > 0 then
                                                          rec_mov.idback||'-'||w_conta_vers
                                                        else
                                                          rec_mov.idback
                                                      end,--idback
                                                      rec_mov.BACKEND,
                                                      rec_mov.COD_IUV,
                                                      rec_mov.TIPO_IDENT,
                                                      rec_mov.CODICE_IDENT,
                                                      rec_mov.ANAG_PAGATORE,
                                                      rec_mov.INDIRIZZO_PAGATORE,
                                                      substr(rec_mov.CIVICO_PAGATORE,1,16),
                                                      rec_mov.CAP_PAGATORE,
                                                      rec_mov.LOCALITA_PAGATORE,
                                                      rec_mov.PROV_PAGATORE,
                                                      rec_mov.NAZ_PAGATORE,
                                                      rec_mov.EMAIL_PAGATORE,
                                                      rec_mov.DATA_SCADENZA,
                                                      --rec_mov.IMPORTO_DOVUTO,
                                                      case
                                                        when w_conta_vers > 0 then
                                                          rec_mov.IMPORTO_DOVUTO - w_importo_vers
                                                        else
                                                          rec_mov.IMPORTO_DOVUTO
                                                      end, -- importo dovuto
                                                      rec_mov.COMMISSIONE_CARICO_PA,
                                                      rec_mov.TIPO_DOVUTO,
                                                      rec_mov.TIPO_VERSAMENTO,
                                                      rec_mov.CAUSALE_VERSAMENTO,
                                                     --rec_mov.DATI_RISCOSSIONE,
                                                      w_dati_riscossione,
                                                      rec_mov.UTENTE_ULTIMO_AGG,
             -- (VD - 06/05/2022): Nuovi campi per integrazione con contabilita' finanziaria
                                                      to_char(null),  -- note
                                                      to_char(null),  -- dati_extra
                                                      w_accertamento, -- accertamento
                                                      w_bilancio      -- bilancio
                                                     );
             --
             --dbms_output.put_line('Dopo depag_service - retval: '||retval);
             --
             if retval in ('PO0100','PO0099') then
                w_errore := 'Errore in inserimento DEPAG_DOVUTI 1 '||rec_mov.idback||' '||Retval;
                pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
                w_errore := null;
             else
                w_return := w_return +1;
             end if;
          end if;
          if w_importo_vers < rec_mov.importo_dovuto then
             w_importo_vers := 0;
          else
             w_importo_vers := w_importo_vers - rec_mov.importo_dovuto;
          end if;
       end if;
       w_iud_prec := rec_mov.iud;
   end loop;

   pagonline_tr4.inserimento_log(w_operazione_log||' - Fine', w_des_cliente);

   -- (DM - 10/01/2023): Si aggiorna il flag_depag sulla testata della pratica
   begin
     if (p_pratica is not null) then
        update pratiche_tributo
           set flag_depag = 'S'
         where pratica = p_pratica;
     end if;
   exception
     when others then
       w_errore:='Upd. PRATICHE_TRIBUTO '||p_pratica||' - '||sqlerrm;
       raise errore;
   end;

   return w_return;

exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       --
     --dbms_output.put_line('Errore durante operazione : '||w_errore);
       --
       w_return := -1;
       return w_return;
  when others then
       ROLLBACK;
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       --
     --dbms_output.put_line('Errore durante operazione : '||w_errore);
       --
       w_return := -1;
       return w_return;

end inserimento_dovuti_cu;
--------------------------------------------------------------------------------------------------------
function prepara_scomposizione_importi
  ( p_tipo_tributo            in varchar2
  , p_anno                    in number
  , p_anno_emissione          in number
  , p_netto                   in number
  , p_addizionali             in number
  , p_quote                   out varchar2
  , p_metadata                out varchar2
  )
/******************************************************************************
 NOME:        PREPARA_SCOMPOSIZIONE_IMPORTI
 DESCRIZIONE: Prepara stringhe scomposizione importi

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   05/10/2023  RV      Prima emissione.
******************************************************************************/
  return number
is
  w_operazione_log         varchar2(100) := 'prepara_scomposizione_importi';
  --
  w_errore        varchar2(2000);
  errore          exception;
--
  w_contatore     number;
  w_stringa       varchar2(2000);
  w_quote         varchar2(2000);
  w_metadata      varchar2(2000);
--
cursor sel_dati_ben is
  select
      to_char(p_anno) anno,
      betr.tributo_f24,
      betr.cod_fiscale,
      betr.intestatario,
      betr.iban,
      case when p_anno != p_anno_emissione then
        betr.tassonomia_anni_prec
      else
        betr.tassonomia
      end tassonomia,
      pagonline_tr4.codice_catastale_ente() as codice_ente,
      replace(betr.causale_quota,'{ANNO}',to_char(p_anno)) as causale_quota,
      decode(betr.tributo_f24,
        'TEFA',p_addizionali,
        p_netto) importo_quota,
      betr.des_metadata as key_md,
      to_char(rownum) ordine
  from
      codici_f24 co24,
      beneficiari_tributo betr
  where
       co24.tributo_f24 = betr.tributo_f24
   and co24.tipo_tributo = p_tipo_tributo
  order by
       to_number(nvl(regexp_substr(betr.tributo_f24,'[0-9]+'),10000)),
       betr.tributo_f24
;
--
begin
  w_contatore := 0;
  --
  if((p_netto < 0.01) or (p_addizionali < 0.01)) then
       w_errore := 'Quote non vaslide - netto: '||p_netto||', addizionali: '||p_addizionali;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
  end if;
  --
  p_quote := null;
  p_metadata := null;
  --
  w_quote := '<QUOTE_MB>';
  w_metadata := '<metadata>';
  --
  begin
    for rec_ben in sel_dati_ben
    loop
      --
      -- 16/10/2023  RV : Lo fa sempre, anche per importo zero, senno fallisce l'invio a DePAG
      -- Ad esempio pratiche tipo 'A' pre 2021
      --
--    if rec_ben.importo_quota <> 0 then
    --  dbms_output.put_line('Tributo: '||rec_ben.tributo_f24);
        --
        w_stringa := '<QUOTA>';
        w_stringa := w_stringa || '<NUM>' || rec_ben.ordine || '</NUM>';
        w_stringa := w_stringa || '<CF>' || rec_ben.cod_fiscale || '</CF>';
        w_stringa := w_stringa || '<IMPORTO>' ||
                     trim(to_char(rec_ben.importo_quota,'99999999990D00','NLS_NUMERIC_CHARACTERS = ''.,''')) ||
                                                                                                   '</IMPORTO>';
        w_stringa := w_stringa || '<CAUSALE>' || rec_ben.causale_quota || '</CAUSALE>';
        w_stringa := w_stringa || '<IBAN>' || rec_ben.iban || '</IBAN>';
        w_stringa := w_stringa || '<TASSONOMIA>' || rec_ben.tassonomia || '</TASSONOMIA>';
        w_stringa := w_stringa || '</QUOTA>';
        --
    --  dbms_output.put_line('Quota : '||w_stringa);
        w_quote := substr(concat(w_quote,w_stringa),1,2000);
        --
        w_stringa := '<mapEntry>';
        w_stringa := w_stringa || '<key>' || rec_ben.key_md || '</key>';
        w_stringa := w_stringa || '<value>' || rec_ben.codice_ente || '|' ||
                               rec_ben.anno || '|' || rec_ben.tributo_f24 || '</value>';
        w_stringa := w_stringa || '</mapEntry>';
    --  dbms_output.put_line('Metadata : '||w_stringa);
        w_metadata := substr(w_metadata||w_stringa,1,2000);
        --
        w_contatore := w_contatore + 1;
--    end if;
    end loop;
    --
    w_stringa := '</QUOTE_MB>';
    w_quote := substr(concat(w_quote,w_stringa),1,2000);
    w_stringa := '</metadata>';
    w_metadata := substr(w_metadata||w_stringa,1,2000);
    --
    p_quote := w_quote;
    p_metadata := w_metadata;
    --
  exception
    when NO_DATA_FOUND then
      dbms_output.put_line('Nessun beneficiario '||p_tipo_tributo);
      w_contatore := 0;
    when others then
      w_errore := 'Prep. scomposizione importi '||p_tipo_tributo||' - '||sqlerrm;
      dbms_output.put_line(w_errore);
      raise;
  end;
  --
  return w_contatore;

end prepara_scomposizione_importi;
--------------------------------------------------------------------------------------------------------
--            FUNZIONI NON UTILIZZATE
--------------------------------------------------------------------------------------------------------
function j_aggiornamento_pagamenti
( p_ente                    in varchar2 default null
, p_idback                  in varchar2 default null
) return number
is
/******************************************************************************
 NOME:        J_AGGIORNAMENTO_PAGAMENTI
 DESCRIZIONE: Caricamento job.

 PARAMETRI:   p_operazione         Descrizione operazione eseguita.
              p_note               Dati dell'operazione eseguita.

 NOTE:
******************************************************************************/  job_number  number;
begin
  dbms_job.submit(job_number
                 ,'declare dummy number; BEGIN dummy := pagonline_tr4.aggiornamento_pagamenti(''' || p_ente ||
                  ''','''||p_idback||'''); END;'
                 ,sysdate + 1 / 5760);
  commit;
  return job_number;
end;
--------------------------------------------------------------------------------------------------------
function aggiornamento_dovuto
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_dic_da_anno             in number
, p_eliminazione            in varchar2
) return number is

/*************************************************************************
 NOME:         AGGIORNAMENTO_DOVUTO
 DESCRIZIONE:  Aggiorna pagamenti gia' passati a PAGONLINE.

 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_dic_da_anno         Anno da cui considerare le dichiarazioni

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
*************************************************************************/
RetVal                     varchar2(8);
w_des_cliente              varchar2(60);
w_utente_ultimo_agg        varchar(8)  := 'TRIBUTI';   -- DA DEFINIRE
w_idback_ann               depag_dovuti.idback%TYPE;
w_iud                      depag_dovuti.iud%TYPE;
w_iud_prec                 depag_dovuti.iud%TYPE;
w_conta_Pag                number;
w_importo_pag              number;
w_return                   number:= 0;
w_operazione_log           varchar2(100) := 'aggiornamento_dovuto';

w_errore                   varchar2(4000);
errore                     exception;

begin

  null;

  return w_return;

exception
  when errore then
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       w_return := -1;
       return w_return;
  when others then
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       w_return := -1;
       return w_return;
end aggiornamento_dovuto;
--------------------------------------------------------------------------------------------------------
function annullamento_pagamento
( p_ente                    IN varchar2
 ,p_idback                  IN varchar2
 )
 return number IS
/*************************************************************************
 NOME:         ANNULLAMENTO_PAGAMENTO
 DESCRIZIONE:

 PARAMETRI:    p_ente            Identificativo dell'ente
               p_idback          Identificativo del pagamento da annullare

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   28/02/2019  VD      Prima emissione.
*************************************************************************/
 RetVal              VARCHAR2(8);
 w_des_cliente       varchar2(60);
 w_parziale          number := 0;

 w_return number :=1;
 w_operazione_log    varchar2(100) := 'annullamento_pagamento';
 w_errore            varchar2(4000);
 errore              exception;

 d_anno              number(4);
 d_periodo           number(2);
 d_tipo_calcolo      varchar2(1);
 d_progressivo       number(10);

 w_data_pagamento    date;
 w_importo_pagato    number;

begin
  w_des_cliente       := pagonline_tr4.descrizione_ente;
  d_anno              := to_number(substr(p_idback,3,4));
  d_periodo           := to_number(substr(p_idback,7,2));
  d_tipo_calcolo      := substr(p_idback,9,1);
  d_progressivo       := to_number(substr(p_idback,10,10));

  pagonline_tr4.inserimento_log(w_operazione_log, p_idback);

  NULL;

  return 1;

exception
  when errore then
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       return 0;
  when others then
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       return 0;

end annullamento_pagamento;
--------------------------------------------------------------------------------------------------------
function set_dovuti_valori
( p_ente                    IN varchar2
, p_idback                  IN varchar2
, p_utente                  IN varchar2
)
   return number IS
    RetVal                     varchar2(8);

  w_return number :=1;
  w_operazione_log             varchar2(100) := 'set_dovuti_valori';
  w_errore                     varchar2(4000);
  errore                       exception;

  w_des_cliente                varchar2(60);

  w_tipo_servizio              varchar2(2);
  w_anno                       number;
  w_periodo                    number;
  w_progressivo                number;

  w_clob                       clob;
  w_record                     varchar2(2000);
  w_record_length              number;
  w_posizione                  number;
  w_inizio                     number;
  w_flag_note20                number;
  w_ind                        number;
  w_nome_campo                 varchar2(200);

  type t_nome_campo_t          is table of varchar2(20) index by binary_integer;
  t_nome_campo                 t_nome_campo_t;
  type t_valore_campo_t        is table of varchar2(200) index by binary_integer;
  t_valore_campo               t_valore_campo_t;

begin
--  dbms_output.put_line('Inizio');
  w_des_cliente     := pagonline_tr4.descrizione_ente;

  w_tipo_servizio   := substr(p_idback,1,2);
  w_anno            := to_number(substr(p_idback,3,4));
  w_periodo         := to_number(substr(p_idback,7,2));
  w_progressivo     := to_number(substr(p_idback,10,10));

  -- INSERIRE SELEZIONE RECORD
--
  w_record_length := length(w_record);
  w_posizione     := instr(w_record,'VAR01D');
  w_inizio        := w_posizione - length(replace(substr(w_record,1,w_posizione),';'));
  w_ind           := 0;
  w_flag_note20   := 0;
  t_nome_campo.delete;

  while w_posizione < w_record_length
  loop
    w_nome_campo := substr(w_record,w_posizione,instr(w_record,';',w_posizione) - w_posizione);
    w_posizione := w_posizione + length(w_nome_campo) + 1;
    if w_flag_note20 = 0 then
       w_ind := w_ind + 1;
       t_nome_campo (w_ind) := w_nome_campo;
       if w_nome_campo = 'NOTE20' then
          w_flag_note20 := 1;
       end if;
    end if;
  end loop;

  -- INSERIRE SELEZIONE RECORD

  w_record_length := length(w_record);
  w_posizione     := instr(w_record,';',1,w_inizio) + 1;
  w_ind           := 0;
  t_valore_campo.delete;
--  dbms_output.put_line('Lunghezza record: '||w_record_length);
--  dbms_output.put_line('Posizione: '||w_posizione);

  w_clob := '<?xml version="1.0" encoding="utf-8"?>'||chr(10)||'<VALORI>'||chr(10);

  while w_posizione < w_record_length
  loop
    w_nome_campo := substr(w_record,w_posizione,instr(w_record,';',w_posizione) - w_posizione);
    w_posizione := w_posizione + nvl(length(w_nome_campo),0) + 1;
    if w_ind < t_nome_campo.last then
       w_ind := w_ind + 1;
       t_valore_campo (w_ind) := w_nome_campo;
    end if;
  end loop;

  if t_nome_campo.last <> t_valore_campo.last then
     dbms_output.put_line('Errore in composizione array tag e valori');
  end if;

--  dbms_output.put_line('Array nome campo: '||t_nome_campo.last);
--  dbms_output.put_line('Array valore campo: '||t_valore_campo.last);

  for w_ind in t_valore_campo.first .. t_valore_campo.last
  loop
    if t_valore_campo (w_ind) is not null then
       w_clob := w_clob || '    <'||t_nome_campo(w_ind)||'>' ||
                 t_valore_campo(w_ind) ||
                 '</'||t_nome_campo(w_ind)||'>'||chr(10);
    end if;
  end loop;

  w_clob := w_clob||'</VALORI>';

  pagonline_tr4.inserimento_log(w_operazione_log, p_idback||' '||w_des_cliente||' '||p_utente);
  --RetVal := DEPAG_SERVICE_PKG.SET_DOVUTI_VALORI  (w_des_cliente, p_idback , w_tipo_servizio, w_clob, p_utente);
  pagonline_tr4.inserimento_log(w_operazione_log, p_idback||' '||w_des_cliente||' '||RetVal);
  if RetVal = 'PO0100' then -- non posso eliminare perchè già pagata
     w_return := 0;
  else
     w_return := 1;
  end if;

  return w_return;

--  dbms_output.put_line('Clob: '||w_clob);
--  dbms_output.put_line('Fine');
end set_dovuti_valori;
--------------------------------------------------------------------------------------------------------
function aggiorna_dati_anagrafici
  ( p_cod_fiscale_old               IN varchar2
  , p_cod_fiscale_new               IN varchar2
  , p_ni_old                        IN number
  , p_ni_new                        IN number
 )
 return number IS
/*************************************************************************
 NOME:         AGGIORNA_DATI_ANAGRAFICI
 DESCRIZIONE:

 PARAMETRI:    p_cod_fiscale_old          cod_fiscale precedente e da sostituire
               p_cod_fiscale_new          nuovo cod_fiscale

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   20/03/2024  AB      Prima emissione.
*************************************************************************/
 RetVal              VARCHAR2(8);
 w_des_cliente       varchar2(60);
 w_utente_ultimo_agg varchar(8)  := 'TRIBUTI';
 w_servizio          depag_dovuti.servizio%type;
 w_tipo_tributo      varchar2(100);
 w_parziale          number := 0;

 w_return            number :=1;
 w_operazione_log    varchar2(100) := 'aggiornamento_dati_anagrafici';
 w_errore            varchar2(4000);
 errore              exception;

 w_dep_record        depag_dovuti%rowtype;
 w_dep_record_ref    depag_dovuti%rowtype;

-- rc                  sys_refcursor;
 w_idback                   depag_dovuti.idback%TYPE;
 w_tipo_ident_pagatore      depag_dovuti.tipo_ident_pagatore%TYPE;
 w_codice_ident_pagatore    depag_dovuti.codice_ident_pagatore%TYPE;
 w_anag_pagatore            depag_dovuti.anag_pagatore%TYPE;
 w_indirizzo_pagatore       depag_dovuti.indirizzo_pagatore%TYPE;
 w_civico_pagatore          depag_dovuti.civico_pagatore%TYPE;
 w_cap_pagatore             depag_dovuti.cap_pagatore%TYPE;
 w_localita_pagatore        depag_dovuti.localita_pagatore%TYPE;
 w_prov_pagatore            depag_dovuti.prov_pagatore%TYPE;
 w_naz_pagatore             depag_dovuti.naz_pagatore%TYPE;
 w_email_pagatore           depag_dovuti.email_pagatore%TYPE;
 w_data_scadenza_avviso     depag_dovuti.data_scadenza_avviso%TYPE;
 w_rata_numero              depag_dovuti.rata_numero%TYPE;
 w_rata_unica_ref           depag_dovuti.rata_unica_ref%TYPE;
 w_rata_unica_ref_new       depag_dovuti.rata_unica_ref%TYPE;

begin

  w_des_cliente := pagonline_tr4.descrizione_ente;
--  rc := depag_service_pkg.dovutiPerIdentPagatoreLike(w_des_cliente, '%', p_cod_fiscale_old, 'TRIBUTO', 'D' );
--dbms_output.put_line('ingresso ');

  for w_dep_record in depag_service_pkg.dovutiPerIdentPagatoreLike(w_des_cliente, '%', p_cod_fiscale_old, 'TRIBUTO', 'D' ) loop
    w_idback := replace(w_dep_record.idback,p_cod_fiscale_old,p_cod_fiscale_new);

    w_tipo_tributo := f_depag_tipo_tributo(w_dep_record.servizio);

    begin
       select decode(sogg.tipo_residente
                    ,0,'F'
                      ,decode(sogg.tipo
                             ,0,'F'
                             ,1,'G'
                               ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
            , p_cod_fiscale_new codice_ident
            , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
            , decode(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'DV')
                    ,null,decode(sogg.cod_via
                                ,null,sogg.denominazione_via
                                     ,arvi.denom_uff)
                         ,f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
            , decode(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'DV')
                    ,null,to_char(sogg.num_civ)||
                          decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                          decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                         ,f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'NC')||
                          decode(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'SF')
                                ,null,'','/'||f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'SF'))||
                          decode(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'IN')
                                ,null,'',' Int.'||f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'IN'))
                    ) civico_pagatore
            , decode(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'DV')
                    ,null,lpad(sogg.cap,5,'0')
                         ,f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
            , substr(nvl(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'CO')
                        ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                    ,1,35) localita_pagatore
            , nvl(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'SPS')
                 ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
    --        , 'IT'                                           naz_pagatore
            , nvl(f_recapito(sogg.ni,w_tipo_tributo,1,trunc(sysdate),'SS2')
                 ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res,'S'))   naz_pagatore
            , nvl(f_recapito(sogg.ni,w_tipo_tributo,3),
                  f_recapito(sogg.ni,w_tipo_tributo,2))   email_pagatore
       into w_tipo_ident_pagatore
          , w_codice_ident_pagatore
          , w_anag_pagatore
          , w_indirizzo_pagatore
          , w_civico_pagatore
          , w_cap_pagatore
          , w_localita_pagatore
          , w_prov_pagatore
          , w_naz_pagatore
          , w_email_pagatore
       from archivio_vie arvi, soggetti sogg
      where arvi.cod_via (+) = sogg.cod_via
        and sogg.ni          = p_ni_new
    ;
    end;

    if nvl(w_dep_record.data_scadenza_avviso,nvl(w_dep_record.data_scadenza_pt,w_dep_record.data_scadenza)) <= sysdate then
       w_data_scadenza_avviso := trunc(sysdate + 365);
    else
       w_data_scadenza_avviso := nvl(w_dep_record.data_scadenza_avviso,nvl(w_dep_record.data_scadenza_pt,w_dep_record.data_scadenza));
    end if;

      w_operazione_log := 'aggiornamento_dati_anagrafici-annulladovutilike';
--      pagonline_tr4.inserimento_log(w_operazione_log, w_dep_record.idback||' '||w_des_cliente);
      --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
      RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_dep_record.idback, w_utente_ultimo_agg);
      if RetVal is null or to_number(ltrim(RetVal,'PO')) < 10 then
         pagonline_tr4.inserimento_log(w_operazione_log, w_dep_record.idback||' OK: Retval = '||RetVal);
         w_return := w_return +1;
      else
         w_errore := w_dep_record.idback ||'ERRORE: Retval = '||Retval;
         raise errore;
      end if;

--dbms_output.put_line('fuori ref: '||w_dep_record.rata_unica_ref||' '||w_dep_record.rata_numero);
      w_rata_numero    := null;
      w_rata_unica_ref := null;
      for w_dep_record_ref in DEPAG_SERVICE_PKG.dovutiPerIdbackLike(w_dep_record.rata_unica_ref, w_dep_record.ente, w_dep_record.servizio) loop
--dbms_output.put_line('entro a ref: '||w_dep_record.rata_unica_ref||' '||w_dep_record.rata_numero);
          w_rata_numero    := w_dep_record.rata_numero;
          w_rata_unica_ref := replace(w_dep_record.rata_unica_ref,p_cod_fiscale_old,p_cod_fiscale_new);
--dbms_output.put_line('entro a ref mod: '||w_rata_unica_ref||' '||w_rata_numero);
      end loop;
      If w_rata_unica_ref is null then  -- viene fatto un altro giro di ricerca nel caso la rata unica sia gia stata modificata
         w_rata_unica_ref_new := replace(w_dep_record.rata_unica_ref,p_cod_fiscale_old,p_cod_fiscale_new);
          for w_dep_record_ref in DEPAG_SERVICE_PKG.dovutiPerIdbackLike(w_rata_unica_ref_new, w_dep_record.ente, w_dep_record.servizio) loop
              w_rata_numero    := w_dep_record.rata_numero;
              w_rata_unica_ref := w_rata_unica_ref_new;
--    dbms_output.put_line('entro a ref mod new: '||w_rata_unica_ref||' '||w_rata_numero);
          end loop;

      end if;

--dbms_output.put_line('fuori loop: '||w_rata_unica_ref||' '||w_rata_numero);
    RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(
            w_dep_record.ente,
            w_dep_record.iud,
            w_dep_record.servizio,
            w_idback,                   --  w_dep_record.idback,
            w_dep_record.backend,
            w_dep_record.cod_iuv,

            w_tipo_ident_pagatore,
            w_codice_ident_pagatore,
            w_anag_pagatore,
            w_indirizzo_pagatore,
            w_civico_pagatore,
            w_cap_pagatore,
            w_localita_pagatore,
            w_prov_pagatore,
            w_naz_pagatore,
            w_email_pagatore,
    /*
            w_dep_record.tipo_ident_pagatore     := xxx
            rec.codice_ident_pagatore
            rec.anag_pagatore
            rec.indirizzo_pagatore
            rec.civico_pagatore
            rec.carec.pagatore
            rec.localita_pagatore
            rec.prov_pagatore
            rec.naz_pagatore
            rec.email_pagatore
    */
            w_dep_record.data_scadenza,
            w_dep_record.importo_dovuto,
            w_dep_record.commissione_carico_pa,
            w_dep_record.tipo_dovuto,
            w_dep_record.tipo_versamento,
            w_dep_record.causale_versamento,
            w_dep_record.dati_riscossione,
            w_dep_record.utente_ultimo_agg,
            w_dep_record.note,
            w_dep_record.dati_extra,
            w_dep_record.accertamento,
            w_dep_record.bilancio,
            w_data_scadenza_avviso, -- w_dep_record.data_scadenza_avviso,
            w_rata_numero,          -- w_dep_record.rata_numero,
            w_rata_unica_ref,       -- w_dep_record.rata_unica_ref,
            w_dep_record.dicitura_scadenza,
            w_dep_record.quote_mb,
            w_dep_record.metadata);

            w_operazione_log := 'aggiornamento_dati_anagrafici-aggiornadovuto';

            if RetVal is null or to_number(ltrim(retval,'PO')) < 10 then --in ('PO0100','PO0099') then
               pagonline_tr4.inserimento_log(w_operazione_log, w_idback||' OK: Retval = '||RetVal);
               w_return := w_return +1;
            else
               w_errore := 'Errore in inserimento DEPAG_DOVUTI 1 '||w_idback||' Retval = '||Retval;
               pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
               w_errore := null;
--               raise errore;
            end if;

  end loop;
/*
  open rc for select * from table(f_get_collection);
  --
  return rc;
  --
*/
return w_return;

exception
  when errore then
--       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;
  when others then
--       ROLLBACK;
       w_errore := 'Errore non previsto: '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       w_return := -1;
       return w_return;

end aggiorna_dati_anagrafici;
--------------------------------------------------------------------------------------------------------
function determina_dovuti_soggetto
( p_cod_fiscale                   in varchar2
, p_stato                         in varchar2
) return sys_refcursor is
/*************************************************************************
 NOME:         DETERMINA_DOVUTI_SOGGETTO
 DESCRIZIONE:

 PARAMETRI:    p_cod_fiscale         cod_fiscale soggetto
               p_stato               stato dei dovuti da riportare
                                     T = TUTTO, P = PAGATO, D = DA_PAGARE

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   27/03/2024  RV      Prima emissione.
*************************************************************************/
  w_operazione_log         varchar2(100) := 'determina_dovuti_soggetto';
  w_errore                 varchar2(4000);
  --
  w_ind                    number;
  w_des_cliente            varchar2(60);
  w_dep_record             depag_dovuti%rowtype;
  --
  rc                       sys_refcursor;
  --
begin
  w_des_cliente := pagonline_tr4.descrizione_ente;
  p_tab_dovuti.delete;
  w_ind := 0;
  --
  for w_dep_record in depag_service_pkg.dovutiPerIdentPagatoreLike(w_des_cliente, '%', p_cod_fiscale, 'TRIBUTO', p_stato )
  loop
    if w_dep_record.id is not null then
       p_tab_dovuti.extend;
       w_ind := w_ind + 1;
       p_tab_dovuti(w_ind) := w_dep_record;
    end if;
  end loop;
  --
  w_errore := 'C.F.: '||p_cod_fiscale||', trovato '|| w_ind||' dovuti';
  pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
  --
  open rc for select * from table(f_get_collection);
  --
  return rc;
  --
end determina_dovuti_soggetto;
--------------------------------------------------------------------------------------------------------
end PAGONLINE_TR4;
/
