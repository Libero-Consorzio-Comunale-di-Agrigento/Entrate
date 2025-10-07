--liquibase formatted sql
--changeset dmarotta:20250326_152438_PAGONLINE_TR4_NULL stripComments:false context:!DEPAG
--validCheckSum: 1:any

create or replace package PAGONLINE_TR4 is
  /******************************************************************************
   NOME:        PAGONLINE_TR4
   DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE.

   ANNOTAZIONI: -
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   000   28/02/2019  VD      Prima emissione.
  ******************************************************************************/

  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '0    28/02/2019';

  function versione
  return varchar2;

  --Generali
  function inserimento_dovuti
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_pratica                 in number
  , p_chk_rate                in number
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
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_ruolo                   in number
  ) return number;

  function inserimento_dovuti_ruolo
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_ruolo                   in number
  ) return number;

  function determina_dovuti_ruolo
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_ruolo                   in number
  , p_tipo_dovuto             in varchar2 default null
  ) return sys_refcursor;

  function aggiorna_dovuto_pagopa
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_ruolo                   in number
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
  ( p_ente                    in varchar2 default null
  , p_idback                  in varchar2 default null
  , p_iuv                     in varchar2
  , p_importo_versato         in varchar2
  , p_data_pagamento          in varchar2
  , p_utente                  in varchar2
  , p_servizio                in varchar2 default null
  , p_quote_mb                in varchar2 default null
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

  function aggiornamento_dovuto
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_dic_da_anno             in number
  , p_eliminazione            in varchar2
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
******************************************************************************/
   function versione return varchar2
   is
   begin
      return s_versione||'.'||s_revisione;
   end versione;

--------------------------------------------------------------------------------------------------------
--Generali
--------------------------------------------------------------------------------------------------------

function inserimento_dovuti
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_pratica                 in number
, p_chk_rate                in number
) return number is

/*************************************************************************
 NOME:        INSERIMENTO_DOVUTI
 DESCRIZIONE: Carica l'elenco degli importi dovuti per PAGONLINE.

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
*************************************************************************/
Begin
  return to_number(null);
End;

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
  rc                       sys_refcursor;
begin
  return rc;
end;

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
*************************************************************************/
begin
  return to_number(null);
end;

function inserimento_dovuti_ruolo
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
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
--              p_chk_rate            0 - calcolo senza rateizzazione
--                                    > 0 - calcolo con rateizzazione

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   07/07/2020  VD      Prima emissione.
*************************************************************************/
begin
  return to_number(null);
end;

function determina_dovuti_ruolo
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
, p_tipo_dovuto             in varchar2 default null
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
 000   08/09/2020  VD      Prima emissione.
*************************************************************************/
  rc                       sys_refcursor;
begin
  return rc;
end;

function aggiorna_dovuto_pagopa
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_ruolo                   in number
) return varchar2 is
/*************************************************************************
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
*************************************************************************/
begin
  return to_number(null);
end;

  function inserimento_violazioni
  ( p_pratica                       in number
  ) return number is
begin
  return to_number(null);
end;

  function aggiorna_dovuti_pratica
  ( p_pratica                       in number
  ) return sys_refcursor is
  rc                       sys_refcursor;
begin
  return rc;
end;

  function determina_dovuti_pratica
  ( p_pratica                       in number
  , p_tipo_dovuto                   in varchar2 default null
  ) return sys_refcursor is
  rc                       sys_refcursor;
begin
  return rc;
end;

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
*************************************************************************/
begin
  return to_number(null);
end;
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
******************************************************************************/
begin
  return to_number(null);
end;

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
begin
  return to_number(null);
end;

  function annullamento_dovuto
  ( p_ente                          IN varchar2
  , p_idback                        IN varchar2
  , p_utente                        IN varchar2
  ) return number is
begin
  return to_number(null);
end;

  function aggiorna_dati_anagrafici
  ( p_cod_fiscale_old               IN varchar2
  , p_cod_fiscale_new               IN varchar2
  , p_ni_old                        IN number
  , p_ni_new                        IN number
  ) return number is

begin
  return to_number(null);
end;

--------------------------------------------------------------------------------------------------------
function determina_dovuti_soggetto
( p_cod_fiscale                   in varchar2
, p_stato                         in varchar2
) return sys_refcursor is

  rc                       sys_refcursor;

begin
  return rc;
end;

end PAGONLINE_TR4;
/
