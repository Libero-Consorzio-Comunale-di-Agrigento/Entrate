--liquibase formatted sql 
--changeset abrandolini:20250326_152429_supporto_servizi_pkg stripComments:false runOnChange:true 
 
CREATE OR REPLACE package     SUPPORTO_SERVIZI_PKG is
/******************************************************************************
 NOME:        SUPPORTO_SERVIZI_PKG
 DESCRIZIONE: Contiene funzioni e procedure per creazione tabellone di lavoro.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 008   05/12/2023  AB      Sistemate alcune decode dove non veniva gestito il null e diventava 'S'
 007   25/09/2023  AB      #66112 aggiunto anno nell'order by e trattato nell'aggiornamento
                           posizioni anche in caso di utente_operativo gia assegnato
                           operativo gia ssegnato
 006   09/08/2023  AB      #66112 Gestiti tuti i nuovi parametri richiesti ai servizi
                           per l'assegnazione contribuenti
 005   06/07/2023  AB      Aggiuna la f_descrizione_titr nella segnalazione: 8
                           Prima era fisso IMU
 004   13/04/2023  AB      Sistemata la valorizzazione dell'ultima liquidazione nel caso non ci sia
                           lo stato o il tipo_atto e cambiato l'order by
 003   29/11/2022  AB      Upodate dei campi liquidazione sulla base dell'importanza
                           gestita la segnalazione ultima e nuovi campi liq2
 002   23/11/2022  AB      Sistemato il giro di update nel caso di non eliminazione record
                           Nuovi parametri di lancio: tipo_tributo ed eliminazione
 001   10/10/2022  AB      Aggiunto nell'assegnazione anche il da a della perc_minima
 000   25/07/2022  VD      Prima emissione.
 *****************************************************************************/
-- Revisione del Package
s_revisione constant afc.t_revision := 'V1.004';

function F_SERV_TOT_VERS
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_CATA
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_CATA_TERR
( p_anno                     varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_NO_CATA
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_NO_CATA_TERR
( p_anno                     varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_OGGE_CATA
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_TERRE_CATA
( p_anno                     varchar2
, p_cf                       varchar2
) return number;

function F_SERV_NUM_PRAT
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return number;

function F_SERV_MAX_PRAT
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2;

function F_SERV_NUM_PRAT_ADS
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2;

function F_SERV_NUM_ITER_ADS
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2;

function F_SERV_CONT_CATA_CTR
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_CONT_NO_CATA_CONTROLLO
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number;

function F_SERV_OGGE_PRTR_DOPPIO
( p_pratica                  varchar2
, p_cf                       varchar2
) return number;

function F_SERV_IMPOSTA_VERSATO
( a_cod_fiscale               varchar2
, da_anno                     number
, a_anno                      number
, a_titr                      varchar2
) return number;

function F_SERV_CATA_NO_CONT
( p_anno                      varchar2
, p_cf                        varchar2
) return number;

function F_SERV_CATA_NO_CONT_TERR
( p_anno                      varchar2
, p_cf                        varchar2
) return number;

procedure POPOLA_DA_VISTE
( p_tipo_tributo             varchar2
, p_anno_iniz                number
, p_anno_fine                number
, p_eliminazione             varchar2
, p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
);

procedure POPOLA_TABELLONE
( p_tipo_tributo             varchar2
, p_anno_iniz                number
, p_anno_fine                number
, p_eliminazione             varchar2
, p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
);

procedure ASSEGNA_CONTRIBUENTI
( p_tipo_tributo             varchar2
, p_utente                   varchar2
, p_numero_casi              number
, p_num_oggetti_da           number
, p_num_oggetti_a            number
, p_da_perc_possesso         number
, p_a_perc_possesso          number
, p_liq_non_notificate       varchar2
, p_fabbricati               varchar2
, p_terreni                  varchar2
, p_aree                     varchar2
, p_contitolari              varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
);

procedure AGGIORNA_ASSEGNAZIONE
( p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
);
end SUPPORTO_SERVIZI_PKG;
/
CREATE OR REPLACE package body     SUPPORTO_SERVIZI_PKG is
/******************************************************************************
 NOME:        SUPPORTO_SERVIZI_PKG
 DESCRIZIONE: Contiene funzioni e procedure per creazione tabellone di lavoro.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   25/07/2022  VD      Prima emissione.
 *****************************************************************************/
  s_revisione_body   constant afc.t_revision := '000';
----------------------------------------------------------------------------------
function versione return varchar2 is
/******************************************************************************
  NOME:        versione.
  DESCRIZIONE: Restituisce versione e revisione di distribuzione del package.
  RITORNA:     VARCHAR2 stringa contenente versione e revisione.
  NOTE:        Primo numero  : versione compatibilita del Package.
               Secondo numero: revisione del Package specification.
               Terzo numero  : revisione del Package body.
******************************************************************************/
begin
   return s_revisione || '.' || s_revisione_body;
end versione;
----------------------------------------------------------------------------------
function F_SERV_TOT_VERS
/******************************************************************************
  NOME:        F_SERV_TOT_VERS.
  DESCRIZIONE: Restituisce il totale versato del contribuente per anno e
               tipo tributo.
  RITORNA:     NUMBER          totale versato.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  s_vers                     number;
begin
  begin
    select nvl(sum(versamenti.importo_versato),0) +
           f_importo_vers_ravv(versamenti.cod_fiscale
                              ,versamenti.tipo_tributo
                              ,versamenti.anno
                              ,'U'
                              )
           /*decode (tipo_tributo,
                        'ICI', F_IMPORTO_VERS_RAVV (COD_FISCALE,
                                                TIPO_TRIBUTO,
                                                ANNO,
                                                'U'),
                        'TASI',F_IMPORTO_VERS_RAVV (COD_FISCALE,
                                                TIPO_TRIBUTO,
                                                ANNO,
                                                'U'))*/
      into s_vers
      from VERSAMENTI
     where versamenti.tipo_tributo ||'' = p_tipo_tributo
       and versamenti.anno              = p_anno
       and versamenti.cod_fiscale       = p_cf
       and versamenti.pratica is null
     group by versamenti.cod_fiscale,
              versamenti.anno,
              versamenti.tipo_tributo
  ;
  exception
    when no_data_found then
         s_vers := 0;
  end;

  return s_vers;
end F_SERV_TOT_VERS;
----------------------------------------------------------------------------------
function F_SERV_CONT_CATA
/******************************************************************************
  NOME:        F_SERV_CONT_CATA.
  DESCRIZIONE: Restituisce l'oggetto (fabbricato) con codice più alto tra
               quelli di contribuente e tipo tributo indicati per cui
               - il contribuente non esiste a catasto
               oppure
               - l'oggetto non esiste a catasto
               oppure
               - l'oggetto e il contribuente esistono a catasto ma con
               categoria diversa e/o percentuale di possesso diversa e/o
               rendita catastale diversa.
  RITORNA:     NUMBER          oggetto.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
begin
  begin
    select max(ogpr.oggetto) oggetto
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.cod_fiscale        = p_cf
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = p_tipo_tributo
       and prtr.tipo_tributo ||''  = p_tipo_tributo
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3  -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONI DI VERIFICA CATASTO
       and
       (not exists    (select 'c'  --- MANCA IL CONTRIBUENTE A CATASTO
                         from IMMOBILI_SOGGETTO_CC
                        where cod_fiscale_ric = ogim.cod_fiscale
                      )
       or
        not exists    (select 'x'  --- MANCA L'OGGETTO A CATASTO
                         from IMMOBILI_SOGGETTO_CC a
                        where a.tipo_immobile   = 'F'
                          and a.cod_fiscale_ric = ogim.cod_fiscale
                          and nvl(a.rendita,0)  > 0
                          and a.categoria not like 'F%'
                          and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                          and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                              to_date('31/12/'||p_anno,'dd/mm/yyyy')
                          and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                              to_date('01/01/'||p_anno,'dd/mm/yyyy')
                          and a.data_efficacia = (select max(b.data_efficacia)
                                                    from IMMOBILI_SOGGETTO_CC b
                                                   where b.contatore = a.contatore
                                                     and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                         to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                     and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                         to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                 )
                          and (ogge.estremi_catasto = a.estremi_catasto
                               or nvl(ogge.id_immobile,0) = a.contatore)
                      )
       or
        exists        (select 'x'  --- abbinato ma rendita diversa o % diversa o categoria diversa
                         from IMMOBILI_SOGGETTO_CC a
                        where a.tipo_immobile   = 'F'
                          and a.cod_fiscale_ric = ogim.cod_fiscale
                          and nvl(a.rendita,0)  > 0
                          and a.categoria not like 'F%'
                          and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                          and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                              to_date('31/12/'||p_anno,'dd/mm/yyyy')
                          and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                              to_date('01/01/'||p_anno,'dd/mm/yyyy')
                          and a.data_efficacia = (select max(b.data_efficacia)
                                                    from IMMOBILI_SOGGETTO_CC b
                                                   where b.contatore = a.contatore
                                                     and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                         to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                     and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                         to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                 )
                          and (ogge.estremi_catasto = a.estremi_catasto
                               or nvl(ogge.id_immobile,0) = a.contatore)
                          and (round(a.rendita,0) !=
                               round(f_rendita_data_riog(ogge.oggetto,to_date('31/12/'||p_anno,'dd/mm/yyyy')),0)
                               or
                               round(ogco.perc_possesso,0) !=
                               round(to_number(nvl(numeratore,100) / nvl(denominatore,100))*100,0)
                               or
                               nvl(ogpr.categoria_catasto,ogge.categoria_catasto) != a.categoria_ric
                              )
                      )
       )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_CATA;
----------------------------------------------------------------------------------
function F_SERV_CONT_CATA_TERR
/******************************************************************************
  NOME:        F_SERV_CONT_CATA_TERR.
  DESCRIZIONE: Restituisce l'oggetto (terreno) con codice più alto tra
               quelli del contribuente per tipo tributo ICI per cui
               - il contribuente non esiste a catasto
               oppure
               - l'oggetto non esiste a catasto
               oppure
               - l'oggetto e il contribuente esistono a catasto ma con
               categoria diversa e/o percentuale di possesso diversa e/o
               rendita catastale diversa.
  RITORNA:     NUMBER          oggetto.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_cf                       varchar2
) return number is
  conta                      number;

begin
  begin
    select max(ogpr.oggetto) oggetto
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.cod_fiscale        = p_cf
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = 'ICI'
       and prtr.tipo_tributo ||''  = 'ICI'
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1 -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONIDI VERIFICA CATASTO
       and
       (not exists    (select 'c'  --- MANCA IL CONTRIBUENTE A CATASTO
                         from TERRENI_SOGGETTO_CC
                        where cod_fiscale_ric = ogim.cod_fiscale
                      )
       or
        not exists    (select 'x'  --- MANCA L'OGGETTO A CATASTO
                         from TERRENI_SOGGETTO_CC a
                        where a.cod_fiscale_ric = ogim.cod_fiscale
                          and nvl(a.reddito_dominicale_euro,0) > 0
                          and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                          and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                              to_date('31/12/'||p_anno,'dd/mm/yyyy')
                          and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                              to_date('01/01/'||p_anno,'dd/mm/yyyy')
                          and a.data_efficacia = (select max(b.data_efficacia)
                                                    from TERRENI_SOGGETTO_CC b
                                                   where b.contatore = a.contatore
                                                     and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                         to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                     and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                         to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                 )
                          and ogge.estremi_catasto = a.estremi_catasto
                      )
       or
        exists    ( select 'x'     --- abbinato ma rendita diversa o % diversa
                      from TERRENI_SOGGETTO_CC a
                     where a.cod_fiscale_ric =  ogim.cod_fiscale
                       and nvl(a.reddito_dominicale_euro,0) > 0
                       and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                       and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                           to_date('31/12/'||p_anno,'dd/mm/yyyy')
                       and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                           to_date('01/01/'||p_anno,'dd/mm/yyyy')
                       and a.data_efficacia = (select max(b.data_efficacia)
                                                 from TERRENI_SOGGETTO_CC b
                                                where b.contatore = a.contatore
                                                  and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                      to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                  and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                      to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                              )
                       and ogge.estremi_catasto = a.estremi_catasto
                       and (round(a.reddito_dominicale_euro,0) !=
                            round(F_RENDITA_DATA_RIOG(ogge.oggetto,to_date('31/12/'||p_anno,'dd/mm/yyyy')),0)
                            or
                            round(ogco.perc_possesso,0) !=
                            round(to_number(nvl(numeratore,100) / nvl(denominatore,100))*100,0)
                           )
                  )
       )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_CATA_TERR;
----------------------------------------------------------------------------------
function F_SERV_CONT_NO_CATA
/******************************************************************************
  NOME:        F_SERV_CONT_NO_CATA.
  DESCRIZIONE: Restituisce il numero di oggetti (fabbricati) tra
               quelli di contribuente e tipo tributo indicati che non
               esistono a catasto
  RITORNA:     NUMBER          numero fabbricati.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
begin
  begin
    select count(*)
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = p_tipo_tributo
       and prtr.tipo_tributo ||''  = p_tipo_tributo
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogim.cod_fiscale        = p_cf
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3  -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONIDI VERIFICA CATASTO
       and not exists    (select 'x'--- MANCA L'OGGETTO A CATASTO
                            from IMMOBILI_SOGGETTO_CC
                           where tipo_immobile = 'F'
                             and cod_fiscale_ric = ogim.cod_fiscale
                             and nvl(rendita,0) > 0
                             and categoria not like 'F%'
                             --and categoria not in ('F03','F04')
                             and upper(nvl(cod_titolo,0)) not in ('20','2S')
                             and nvl(data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and nvl(data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and (ogge.estremi_catasto=immobili_soggetto_cc.estremi_catasto
                                  or nvl(ogge.id_immobile,0)=immobili_soggetto_cc.contatore)
                          )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_NO_CATA;
----------------------------------------------------------------------------------
function F_SERV_CONT_NO_CATA_TERR
/******************************************************************************
  NOME:        F_SERV_CONT_NO_CATA_TERR.
  DESCRIZIONE: Restituisce il numero di oggetti (terreni) tra
               quelli del contribuente per tipo tributo ICI che non
               esistono a catasto
  RITORNA:     NUMBER          numero terreni.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
begin
  begin
    select count(*)
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = 'ICI'
       and prtr.tipo_tributo ||''  = 'ICI'
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogim.cod_fiscale        = p_cf
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 1  -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONIDI VERIFICA CATASTO
       and not exists    (select 'x'--- MANCA L'OGGETTO A CATASTO
                            from TERRENI_SOGGETTO_CC
                           where cod_fiscale_ric = ogim.cod_fiscale
                             and nvl(reddito_dominicale_euro,0) > 0
                             and upper(nvl(cod_titolo,0)) not in ('20','2S')
                             and nvl(data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and nvl(data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and ogge.estremi_catasto = terreni_soggetto_cc.estremi_catasto
                         )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_NO_CATA_TERR;
----------------------------------------------------------------------------------
function F_SERV_CONT_OGGE_CATA
/******************************************************************************
  NOME:        F_SERV_CONT_OGGE_CATA.
  DESCRIZIONE: Restituisce il numero di oggetti (fabbricati) tra
               quelli di contribuente e tipo tributo indicati presenti a
               catasto ma non in applicativo (TR4/Tributiweb).
  RITORNA:     NUMBER          numero fabbricati.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  Ncata_no_tr4               number;
begin
  begin
    select count(*) --, cod_fiscale_ric cod_fiscale
      into Ncata_no_tr4
      from IMMOBILI_SOGGETTO_CC cata
     where tipo_immobile             = 'F'
       and nvl(rendita,0)            > 0
       and categoria                 not like 'F%'
       and cod_fiscale_ric           = p_cf
       and upper(nvl(cod_titolo,0))  not in ('20','2S')
       and nvl(data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
           to_date('01/01'||to_number(p_anno),'dd/mm/yyyy')
       and nvl(data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
           to_date('31/12'||to_number(p_anno),'dd/mm/yyyy')
       and data_efficacia = (select max(b.data_efficacia)
                              from IMMOBILI_SOGGETTO_CC b
                             where b.contatore = cata.contatore
                               and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                   to_date('31/12/'||to_number(p_anno),'dd/mm/yyyy')
                               and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                   to_date('31/12/'||to_number(p_anno),'dd/mm/yyyy')
                            )
       and not exists       (select 'x'
                               from OGGETTI_IMPOSTA OGIM,
                                    OGGETTI_PRATICA OGPR,
                                    OGGETTI OGGE
                              where ogim.cod_fiscale      = cata.cod_fiscale_ric
                                and ogim.anno             = p_anno
                                and flag_calcolo          = 'S'
                                and ogim.tipo_tributo||'' = p_tipo_tributo
                                and ogim.oggetto_pratica  = ogpr.oggetto_pratica
                                and ogpr.oggetto          = ogge.oggetto
                                and (ogge.estremi_catasto = cata.estremi_catasto
                                     or nvl(ogge.id_immobile,0) = cata.contatore)
                            )
   ;
  exception
    when no_data_found then
         Ncata_no_tr4 := 0;
  end;

  return Ncata_no_tr4;
end F_SERV_CONT_OGGE_CATA;
----------------------------------------------------------------------------------
function F_SERV_CONT_TERRE_CATA
/******************************************************************************
  NOME:        F_SERV_CONT_TERRE_CATA.
  DESCRIZIONE: Restituisce il numero di oggetti (terreni) tra
               quelli del contribuente per tipo tributo ICI presenti a
               catasto ma non in applicativo (TR4/Tributiweb).
  RITORNA:     NUMBER          numero terreni.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_cf                       varchar2
) return number is
  Ncata_no_tr4_terr          number;
begin
  begin
    select count(*)
      into Ncata_no_tr4_terr
      from TERRENI_SOGGETTO_CC cata
     where nvl(reddito_agrario_euro,0)            >    0
       and cod_fiscale_ric            = p_cf
       and upper(nvl(cod_titolo,0))   not in ('20','2S')
       and nvl(data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
           to_date('01/01'||to_number(p_anno),'dd/mm/yyyy')
       and nvl(data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
           to_date('31/12'||to_number(p_anno),'dd/mm/yyyy')
       and data_efficacia = (select max(b.data_efficacia)
                               from TERRENI_SOGGETTO_CC b
                              where b.contatore = cata.contatore
                                and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                    to_date('31/12/'||to_number(p_anno),'dd/mm/yyyy')
                                and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                    to_date('31/12/'||to_number(p_anno),'dd/mm/yyyy')
                            )
       and not exists       (select 'x'
                               from OGGETTI_IMPOSTA OGIM,
                                    OGGETTI_PRATICA OGPR,
                                    OGGETTI OGGE
                              where ogim.cod_fiscale      = cata.cod_fiscale_ric
                                and ogim.anno             = p_anno
                                and flag_calcolo          = 'S'
                                and ogim.tipo_tributo||'' = 'ICI'
                                and ogim.oggetto_pratica  = ogpr.oggetto_pratica
                                and ogpr.oggetto          = ogge.oggetto
                                and ogge.estremi_catasto  = cata.estremi_catasto
                                and ogge.tipo_oggetto     = 1
                            )
   ;
  exception
    when no_data_found then
         Ncata_no_tr4_terr := 0;
  end;

  return Ncata_no_tr4_terr;
end F_SERV_CONT_TERRE_CATA;
----------------------------------------------------------------------------------
function F_SERV_NUM_PRAT
/******************************************************************************
  NOME:        F_SERV_NUM_PRAT.
  DESCRIZIONE: Restituisce il numero di pratiche per contribuente, anno, tipo
               tributo e tipo pratica indicati.
  RITORNA:     NUMBER          numero pratiche.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return number is
  nconta                     number;
begin
  begin
    select count(*)
      into nconta
      from PRATICHE_TRIBUTO PRTR
     where prtr.tipo_tributo||'' = p_tipo_tributo
       and prtr.tipo_pratica     = p_tipo_pratica
       and prtr.anno             = p_anno
       and cod_fiscale           = p_cf
   ;
  exception
    when no_data_found then
         nconta := 0;
  end;

  return nconta;
end F_SERV_NUM_PRAT;
----------------------------------------------------------------------------------
function F_SERV_MAX_PRAT
/******************************************************************************
  NOME:        F_SERV_MAX_PRAT.
  DESCRIZIONE: Restituisce una stringa contenente l'utente e il tipo atto
               della ultima pratica inserita per contribuente, anno,
               tipo tributo e tipo pratica indicati.
  RITORNA:     VARCHAR2          utente || tipo atto.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2 is
  nconta                     varchar2(255);
  w_conta                    number;
begin
  begin
    select count(*)
      into w_conta
      from PRATICHE_TRIBUTO PRTR
     where prtr.tipo_tributo||'' = p_tipo_tributo
       and prtr.tipo_pratica     = p_tipo_pratica
       and prtr.anno             = p_anno
       and cod_fiscale           = p_cf
   ;
  exception
    when no_data_found then
         w_conta := 0;
  end;

  if w_conta = 1 then
      begin
        select 'Utente: '||rpad(prtr.utente,8,' ')||
               decode(tist.descrizione,'','',
                      ' - Stato: ('||rpad(nvl(prtr.stato_accertamento,'D'),2,' ')||') '||tist.descrizione)||
               decode(tiat.descrizione,'','',
                      ' - Tipo Atto: ('||rpad(prtr.tipo_atto,2,' ')||') '||tiat.descrizione)||
               ' Numero: ('||rpad(nvl(prtr.numero,' '),15,' ')||
               ') del '||to_char(data,'dd/mm/yyyy')||
               decode(prtr.data_notifica,'','',' Notificata il '||to_char(prtr.data_notifica,'dd/mm/yyyy'))
          into nconta
          from PRATICHE_TRIBUTO PRTR,
               TIPI_STATO TIST,
               TIPI_ATTO TIAT,
               AD4_UTENTI UTEN
         where prtr.tipo_tributo||'' = p_tipo_tributo
           and prtr.tipo_pratica     = p_tipo_pratica
           and prtr.anno             = p_anno
           and cod_fiscale           = p_cf
           and nvl(prtr.stato_accertamento,'D') = tist.tipo_stato (+)
           and prtr.tipo_atto        = tiat.tipo_atto (+)
           and prtr.utente           = uten.utente
           and nvl(uten.importanza,decode(substr(prtr.utente,1,3),'ADS',10,0)) != 10
         ;
      exception
        when others then
             nconta := ' ';
      end;
  elsif w_conta > 1 then
      begin
        select 'Utente: '||rpad(prtr.utente,8,' ')||
               decode(tist.descrizione,'','',
                      ' - Stato: ('||rpad(nvl(prtr.stato_accertamento,'D'),2,' ')||') '||tist.descrizione)||
               decode(tiat.descrizione,'','',
                      ' - Tipo Atto: ('||rpad(prtr.tipo_atto,2,' ')||') '||tiat.descrizione)||
               ' Numero: ('||rpad(nvl(prtr.numero,' '),15,' ')||
               ') del '||to_char(data,'dd/mm/yyyy')||
               decode(prtr.data_notifica,'','',' Notificata il '||to_char(prtr.data_notifica,'dd/mm/yyyy'))
          into nconta
          from PRATICHE_TRIBUTO PRTR,
               TIPI_STATO TIST,
               TIPI_ATTO TIAT,
               AD4_UTENTI UTEN
         where prtr.tipo_tributo||'' = p_tipo_tributo
           and prtr.tipo_pratica     = p_tipo_pratica
           and prtr.anno             = p_anno
           and cod_fiscale           = p_cf
           and nvl(prtr.stato_accertamento,'D') = tist.tipo_stato (+)
           and prtr.tipo_atto        = tiat.tipo_atto (+)
           and prtr.utente           = uten.utente
           and prtr.data = (select max(prtx.data)
                              from pratiche_tributo prtx
                             where prtx.tipo_tributo = prtr.tipo_tributo
                               and prtx.anno = prtr.anno
                               and prtx.cod_fiscale = prtr.cod_fiscale
                               and prtx.tipo_pratica in p_tipo_pratica
                           )
           and rownum = 1
         ;
      exception
        when others then
             nconta := ' ';
      end;

  end if;

  return nconta;
end F_SERV_MAX_PRAT;
----------------------------------------------------------------------------------
function F_SERV_NUM_PRAT_ADS
/******************************************************************************
  NOME:        F_SERV_NUM_PRAT_ADS.
  DESCRIZIONE: Restituisce una stringa contenente l'utente e il tipo atto
               della eventuale pratica inserita dai verificatori ADS
               per contribuente, anno, tipo tributo e tipo pratica indicati.
  RITORNA:     VARCHAR2          utente || tipo atto.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2 is
  nconta                     varchar2(255);
  w_conta                    number;
begin
  begin
    select count(*)
      into w_conta
      from PRATICHE_TRIBUTO PRTR,
           TIPI_ATTO TIAT,
           AD4_UTENTI UTEN
     where prtr.tipo_tributo||'' = p_tipo_tributo
       and prtr.tipo_pratica     = p_tipo_pratica
       and prtr.anno             = p_anno
       and cod_fiscale           = p_cf
       and prtr.tipo_atto        = tiat.tipo_atto (+)
       and prtr.utente           = uten.utente
       and nvl(uten.importanza,decode(substr(prtr.utente,1,3),'ADS',10,0)) = 10
   ;
  exception
    when no_data_found then
         w_conta := 0;
  end;

  if w_conta = 1 then
     begin
        select 'Utente: '||rpad(prtr.utente,8,' ')||
               decode(tist.descrizione,'','',
                      ' - Stato: ('||rpad(nvl(prtr.stato_accertamento,'D'),2,' ')||') '||tist.descrizione)||
               decode(tiat.descrizione,'','',
                      ' - Tipo Atto: ('||rpad(prtr.tipo_atto,2,' ')||') '||tiat.descrizione)||
               ' Numero: ('||rpad(nvl(prtr.numero,' '),15,' ')||
               ') del '||to_char(prtr.data,'dd/mm/yyyy')||
               decode(prtr.data_notifica,'','',' Notificata il '||to_char(prtr.data_notifica,'dd/mm/yyyy'))
          into nconta
          from PRATICHE_TRIBUTO PRTR,
               TIPI_STATO TIST,
               TIPI_ATTO TIAT,
               AD4_UTENTI UTEN
         where prtr.tipo_tributo||'' = p_tipo_tributo
           and prtr.tipo_pratica     = p_tipo_pratica
           and prtr.anno             = p_anno
           and cod_fiscale           = p_cf
           and nvl(prtr.stato_accertamento,'D') = tist.tipo_stato (+)
           and prtr.tipo_atto        = tiat.tipo_atto (+)
           and prtr.utente           = uten.utente
           and nvl(uten.importanza,decode(substr(prtr.utente,1,3),'ADS',10,0)) = 10
       ;
     exception
        when no_data_found then
             nconta := ' ';
     end;
  elsif w_conta > 1 then
     begin
        select max('Utente: '||rpad(prtr.utente,8,' ')||
               decode(tist.descrizione,'','',
                      ' - Stato: ('||rpad(nvl(prtr.stato_accertamento,'D'),2,' ')||') '||tist.descrizione)||
               decode(tiat.descrizione,'','',
                      ' - Tipo Atto: ('||rpad(prtr.tipo_atto,2,' ')||') '||tiat.descrizione))||
               ' (Tot.Pratiche: '||count(prtr.pratica)||')'
          into nconta
          from PRATICHE_TRIBUTO PRTR,
               TIPI_STATO TIST,
               TIPI_ATTO TIAT,
               AD4_UTENTI UTEN
         where prtr.tipo_tributo||'' = p_tipo_tributo
           and prtr.tipo_pratica     = p_tipo_pratica
           and prtr.anno             = p_anno
           and cod_fiscale           = p_cf
           and nvl(prtr.stato_accertamento,'D') = tist.tipo_stato (+)
           and prtr.tipo_atto        = tiat.tipo_atto (+)
           and prtr.utente           = uten.utente
           and nvl(uten.importanza,decode(substr(prtr.utente,1,3),'ADS',10,0)) = 10
       ;
     exception
        when no_data_found then
             nconta := ' ';
     end;
  end if;

  return nconta;
end F_SERV_NUM_PRAT_ADS;
----------------------------------------------------------------------------------
function F_SERV_NUM_ITER_ADS
/******************************************************************************
  NOME:        F_SERV_NUM_ITER_ADS.
  DESCRIZIONE: Restituisce una stringa contenente il minimo e il massimo
               utente dell'iter relativo alla eventuale pratica inserita dai
               verificatori ADS per contribuente, anno, tipo tributo e tipo
               pratica indicati.
  RITORNA:     VARCHAR2          min(utente) || max(utente).
  NOTE:        Rispetto alla funzione utilizzata nelle viste dei servizi, ho
               eliminato l'outer join con iter_pratica. Questo perche' se non
               esiste l'iter, gli utenti verrebbero comunque nulli
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
, p_tipo_pratica             varchar2
) return varchar2 is
  nconta                     varchar2(255);
  begin
    begin
     select max(iter.utente)||'-'||min(iter.utente)
       into nconta
       from PRATICHE_TRIBUTO PRTR,
            TIPI_ATTO TIAT,
            ITER_PRATICA ITER,
            AD4_UTENTI UTEN
      where prtr.tipo_tributo||'' = p_tipo_tributo
        and prtr.tipo_pratica     = p_tipo_pratica
        and prtr.anno             = p_anno
        and cod_fiscale           = p_cf
        and prtr.tipo_atto        = tiat.tipo_atto   (+)
        --and iter.pratica  (+)     = prtr.pratica
        and iter.pratica          = prtr.pratica
        and iter.utente           = uten.utente
        and nvl(uten.importanza,decode(substr(uten.utente,1,3),'ADS',10,0)) = 10
     ;
    exception
      when no_data_found then
           nconta := ' ';
    end;

    return nconta;
  end F_SERV_NUM_ITER_ADS;
----------------------------------------------------------------------------------
function F_SERV_CONT_CATA_CTR
/******************************************************************************
  NOME:        F_SERV_CONT_CATA_CTR.
  DESCRIZIONE: Restituisce l'oggetto (fabbricato) con codice più alto tra
               quelli di contribuente e tipo tributo indicati per cui
               - il contribuente non esiste a catasto
               oppure
               - l'oggetto non esiste a catasto
               oppure
               - l'oggetto e il contribuente esistono a catasto ma con
               categoria diversa e/o percentuale di possesso diversa e/o
               rendita catastale diversa
               e non esistono variazioni in corso d'anno.
  RITORNA:     NUMBER          oggetto.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
begin
  begin
    select max(ogpr.oggetto) oggetto
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.cod_fiscale        = p_cf
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = p_tipo_tributo
       and prtr.tipo_tributo ||''  = p_tipo_tributo
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3  -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONIDI VERIFICA CATASTO
       and
       (not exists    (select 'c'   --- MANCA IL CONTRIBUENTE A CATASTO
                         from IMMOBILI_SOGGETTO_CC
                        where cod_fiscale_ric = ogim.cod_fiscale
                      )
       or
        not exists    (select 'x'   --- MANCA L'OGGETTO A CATASTO
                         from IMMOBILI_SOGGETTO_CC a
                        where a.tipo_immobile = 'F'
                          and a.cod_fiscale_ric = ogim.cod_fiscale
                          and nvl(a.rendita,0) > 0
                          and a.categoria not like 'F%'
                          and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                          and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                              to_date('31/12/'||p_anno,'dd/mm/yyyy')
                          and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                              to_date('01/01/'||p_anno,'dd/mm/yyyy')
                          and a.data_efficacia = (select max(b.data_efficacia)
                                                    from IMMOBILI_SOGGETTO_CC b
                                                   where b.contatore = a.contatore
                                                     and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                         to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                     and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                         to_date('01/01/'||p_anno,'dd/mm/yyyy') )
                          and (ogge.estremi_catasto = a.estremi_catasto
                               or nvl(ogge.id_immobile,0)=a.contatore)
                      )
       or
        exists        ( select 'x'  --- abbinato ma rendita diversa o % diversa
                          from IMMOBILI_SOGGETTO_CC a
                         where a.tipo_immobile = 'F'
                           and a.cod_fiscale_ric =  ogim.cod_fiscale
                           and nvl(a.rendita,0) > 0
                           and a.categoria not like 'F%'
                           and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                           and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                               to_date('31/12/'||p_anno,'dd/mm/yyyy')
                           and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                               to_date('01/01/'||p_anno,'dd/mm/yyyy')
                           and a.data_efficacia = (select max(data_efficacia)
                                                     from IMMOBILI_SOGGETTO_CC b
                                                    where b.contatore=a.contatore
                                                      and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                          to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                      and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                                          to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                      and nvl(b.data_efficacia,to_date('01/01/1900','dd/mm/yyyy')) <=
                                                          to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                                 --   and a.COD_FISCALE_RIC=b.cod_fiscale_ric )-- aggiunta in funzione ctr
                                                  )
                           and (ogge.estremi_catasto = a.estremi_catasto
                                or nvl(ogge.id_immobile,0)=a.contatore)
                           and (round(a.rendita,0) !=
                                round(F_RENDITA_DATA_RIOG(ogge.oggetto, to_date('31/12/'||p_anno,'dd/mm/yyyy')),0)
                                or
                                round(ogco.perc_possesso,0) !=
                                round(to_number(nvl(numeratore,100) / nvl(denominatore,100)) * 100,0)
                                or
                                nvl(ogge.categoria_catasto,ogpr.categoria_catasto) != a.CATEGORIA_RIC
                               )
                      )
       )
       and not exists    ( select 'x'  --- variazione nell'anno COME CONDIZIONE ESCLUSIVA
                             from IMMOBILI_SOGGETTO_CC a
                            where a.tipo_immobile = 'F'
                              and a.cod_fiscale_ric =  ogim.cod_fiscale
                              and nvl(a.rendita,0) > 0
                    --        and a.categoria not like 'F%'
                    --        and a.categoria not in ('F03','F04')
                    --        and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
                              and (nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) between to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                                                               and to_date('31/12/'||p_anno,'dd/mm/yyyy')
                              or nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) between to_date('01/01/'||p_anno,'dd/mm/yyyy')
                                                                                                  and to_date('31/12/'||p_anno,'dd/mm/yyyy'))
                              and (ogge.estremi_catasto = a.estremi_catasto
                                   or nvl(ogge.id_immobile,0) = a.contatore)
                         )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_CATA_CTR;
----------------------------------------------------------------------------------
function F_SERV_CONT_NO_CATA_CONTROLLO
/******************************************************************************
  NOME:        F_SERV_CONT_NO_CATA_CONTROLLO.
  DESCRIZIONE: Restituisce il numero di oggetti (fabbricati) tra
               quelli di contribuente e tipo tributo indicati che non
               esistono a catasto per anni diversi da quello che si sta
               trattando.
  RITORNA:     NUMBER          numero fabbricati.
  NOTE:
******************************************************************************/
( p_anno                     varchar2
, p_tipo_tributo             varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
begin
  begin
    select count(*)
      into conta
      from OGGETTI_IMPOSTA OGIM,
           OGGETTI_PRATICA OGPR,
           PRATICHE_TRIBUTO PRTR,
           OGGETTI_CONTRIBUENTE OGCO,
           OGGETTI OGGE
     where prtr.pratica            = ogpr.pratica
       and ogim.oggetto_pratica    = ogpr.oggetto_pratica
       and ogim.anno               = p_anno -- da togliere
       and ogim.flag_calcolo       = 'S'
       and ogim.tipo_tributo ||''  = p_tipo_tributo
       and prtr.tipo_tributo ||''  = p_tipo_tributo
       and ogpr.oggetto            = ogge.oggetto
       and ogco.cod_fiscale        = ogim.cod_fiscale
       and ogim.cod_fiscale        = p_cf
       and ogco.oggetto_pratica    = ogpr.oggetto_pratica
       and prtr.anno               <> p_anno
       AND nvl(ogpr.tipo_oggetto, ogge.tipo_oggetto) = 3  -- VEDERE SE VA AGGIUNTA IN TUTTE LE CONDIZIONIDI VERIFICA CATASTO
       and not exists    (select 'x'   --- MANCA L'OGGETTO A CATASTO
                            from IMMOBILI_SOGGETTO_CC
                           where tipo_immobile = 'F'
                             and cod_fiscale_ric = ogim.cod_fiscale
                             and nvl(rendita,0) > 0
                             and categoria not like 'F%'
                             --and categoria not in ('F03','F04')
                             and upper(nvl(cod_titolo,0)) not in ('20','2S')
                             and nvl(data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and nvl(data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                 to_date('31/12/'||p_anno,'dd/mm/yyyy')
                             and (ogge.estremi_catasto=immobili_soggetto_cc.estremi_catasto
                                  or nvl(ogge.id_immobile,0)=immobili_soggetto_cc.contatore)
                         )
     group by ogim.cod_fiscale, ogim.tipo_tributo, ogim.anno
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CONT_NO_CATA_CONTROLLO;
----------------------------------------------------------------------------------
function F_SERV_OGGE_PRTR_DOPPIO
/******************************************************************************
  NOME:        F_SERV_OGGE_PRTR_DOPPIO.
  DESCRIZIONE: Verifica se lo stesso oggetto e' presente piu' volte nella
               stessa pratica.
  RITORNA:     NUMBER          numero oggetti doppi.
  NOTE:
******************************************************************************/
( p_pratica                  varchar2
, p_cf                       varchar2
) return number is
  conta                      number;
  oggetto                    number;
  pratica                    number;
  cod_fiscale                varchar2(16);
  mesi_possesso              number;
  tipo_tributo               varchar2(5);
  anno                       number;
begin
  for ogpr_rif in (select oggetto_pratica
                     from oggetti_pratica
                    where pratica = p_pratica)
  loop
    begin
      select count(*)
           , ogpr.oggetto
           , prtr.pratica
           , prtr.cod_fiscale
           , mesi_possesso
           , prtr.tipo_tributo
           , prtr.anno
        into conta
           , oggetto
           , pratica
           , cod_fiscale
           , mesi_possesso
           , tipo_tributo
           , anno
        from OGGETTI_PRATICA OGPR,
             PRATICHE_TRIBUTO PRTR,
             OGGETTI_CONTRIBUENTE OGCO,
             OGGETTI OGGE
       where prtr.pratica            = ogpr.pratica
         and ogco.oggetto_pratica    = ogpr.oggetto_pratica
         and ogpr.oggetto            = ogge.oggetto
         and prtr.pratica            = p_pratica
         and prtr.cod_fiscale        = p_cf
         and mesi_possesso           = 12
   --    and tipo_atto is not null
         and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 3
       group by ogpr.oggetto
              , prtr.pratica
              , prtr.cod_fiscale
              , mesi_possesso
              , prtr.tipo_tributo
              , prtr.anno
      having count(*) > 1
          ;
    exception
      when others then
        conta := 0;
    end;
    if conta > 0 then
       conta := conta + 1;
    else
       conta := conta;
    end if;
  end loop;
--
  return conta;
--
end F_SERV_OGGE_PRTR_DOPPIO;
----------------------------------------------------------------------------------
function F_SERV_IMPOSTA_VERSATO
/******************************************************************************
  NOME:        F_SERV_IMPOSTA_VERSATO.
  DESCRIZIONE: Determina l'importo totale versato per codice fiscale, tipo
               tributo e intervallo di anni indicati.
  RITORNA:     NUMBER          importo versato.
  NOTE:
******************************************************************************/
( a_cod_fiscale               varchar2
, da_anno                     number
, a_anno                      number
, a_titr                      varchar2
) return number is
  w_versato                   number:=0;
begin
  begin
    select sum(importo_versato)
      into w_versato
      from VERSAMENTI vers
     where vers.cod_fiscale      = a_cod_fiscale
       and vers.anno             between da_anno and a_anno
       and vers.tipo_tributo||'' = a_titr
    ;
  exception
     when no_data_found then
          w_versato:=0;
  end;
  return w_versato;
 end F_SERV_IMPOSTA_VERSATO;
----------------------------------------------------------------------------------
function F_SERV_CATA_NO_CONT
/******************************************************************************
  NOME:        F_SERV_CATA_NO_CONT.
  DESCRIZIONE: Determina quanti oggetti (fabbricati) sono a catasto per il
               contribuente e l'anno indicati.
  RITORNA:     NUMBER          importo versato.
  NOTE:
******************************************************************************/
( p_anno                      varchar2
, p_cf                        varchar2
) return number is
  conta                       number;
begin
  begin
    select count(*)
      into conta
      from IMMOBILI_SOGGETTO_CC a
     where a.cod_fiscale_ric = p_cf
       and a.tipo_immobile = 'F'
       and nvl(a.rendita,0) > 0
       and a.categoria not like 'F%'
       and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
       and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
           to_date('31/12/'||p_anno,'dd/mm/yyyy')
       and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
           to_date('01/01/'||p_anno,'dd/mm/yyyy')
       and a.data_efficacia = (select max(b.data_efficacia)
                                 from IMMOBILI_SOGGETTO_CC b
                                where b.contatore=a.contatore
                                  and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                      to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                  and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                      to_date('01/01/'||p_anno,'dd/mm/yyyy')
                              )
     group by a.cod_fiscale_ric
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CATA_NO_CONT;
----------------------------------------------------------------------------------
function F_SERV_CATA_NO_CONT_TERR
/******************************************************************************
  NOME:        F_SERV_CATA_NO_CONT_TERR.
  DESCRIZIONE: Determina quanti oggetti (terreni) sono a catasto per il
               contribuente e l'anno indicati.
  RITORNA:     NUMBER          importo versato.
  NOTE:
******************************************************************************/
( p_anno                      varchar2
, p_cf                        varchar2
) return number is
   conta      number;
begin
  begin
    select count(*)
      into conta
      from TERRENI_SOGGETTO_CC a
     where cod_fiscale_ric = p_cf
       and nvl(reddito_dominicale_euro,0) > 0
       and upper(nvl(a.cod_titolo,0)) not in ('20','2S')
       and nvl(a.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
           to_date('31/12/'||p_anno,'dd/mm/yyyy')
       and nvl(a.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
           to_date('01/01/'||p_anno,'dd/mm/yyyy')
       and a.data_efficacia = (select max(b.data_efficacia)
                                 from TERRENI_SOGGETTO_CC b
                                where b.contatore=a.contatore
                                  and nvl(b.data_validita,to_date('01/01/1900','dd/mm/yyyy')) <=
                                      to_date('31/12/'||p_anno,'dd/mm/yyyy')
                                  and nvl(b.data_fine_validita,to_date('31/12/9999','dd/mm/yyyy')) >=
                                      to_date('01/01/'||p_anno,'dd/mm/yyyy')
                              )
     group by a.cod_fiscale_ric
  ;
  exception
    when no_data_found then
         conta := 0;
  end;

  return conta;
end F_SERV_CATA_NO_CONT_TERR;
----------------------------------------------------------------------------------
procedure UPDATE_SUPPORTO_SERVIZI
/******************************************************************************
  NOME:        UPDATE_SUPPORTO_SERVIZI.
  DESCRIZIONE: Aggiorna l'utente di assegnazione sulla riga con l'identificativo
               indicato.
  NOTE:
******************************************************************************/
( p_id                       number
, p_utente                   varchar2
, p_messaggio                OUT varchar2
) is
  w_messaggio                varchar2(4000);
begin
  begin
    update SUPPORTO_SERVIZI
       set utente_assegnato = p_utente
     where id = p_id;
  exception
    when others then
      w_messaggio := substr('Update SUPPORTO_SERVIZI (Id. '||p_id||') - '||sqlerrm,1,4000);
  end;

  p_messaggio := w_messaggio;
end UPDATE_SUPPORTO_SERVIZI;
----------------------------------------------------------------------------------
procedure POPOLA_DA_VISTE
/******************************************************************************
  NOME:        POPOLA_DA_VISTE.
  DESCRIZIONE: Inserisce nella tabella SUPPORTO_SERVIZI i dati delle viste
               SERVIZI_DV, SERVIZI_CTR relativi all'intervallo di anni indicato.
  NOTE:
******************************************************************************/
( p_tipo_tributo             varchar2
, p_anno_iniz                number
, p_anno_fine                number
, p_eliminazione             varchar2
, p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
) is
  w_result                   number := 0;
  w_messaggio                varchar2(4000);
  w_conta_righe              number := 0;
  w_conta_update             number := 0;
  w_conta_record             number := 0;
  errore                     exception;
cursor sel_DV is
  select replace(FONTE,'SERVIZI_','') FONTE,
         case
            when trim(LIQUIDAZIONE_ADS) is not null then
                'Liquidazioni Emesse (Ver e Imp=10)'
            else
                case
                    when LIQUIDAZIONE_ACCERTAMENTO > 0 then
                        'Liquidazioni Emesse dall''Ente'
                else
                    case
                        when (DIFFERENZA_OGGETTI_CATASTO+DIFFERENZA_TERRENI_CATASTO+OGGETTI_NON_CATASTO+CATA_NO_TR4) = 0 then
                             case
                                 when abs(differenza_imposta) < 12 then
                                      '1 - Quadra con Catasto Contribuente OK'
                                 else
                                      '2 - Quadra con Catasto anomalia dovuto versato'
                             end
                        else
                             case
                                 when abs(differenza_imposta) < 12 then
                                      '3 - Non coerenti con il catasto ma senza differenza D/V'
                                 else
                                      '3bis - Non coerenti con il catasto ma CON differenza D/V'
                             end
                    end
                end

         end segnalazione,
         ragionesociale,
         codicefiscale,
         anno,
         numoggetti,
         numfabbricati,
         numterreni,
         numaree,
         differenza_imposta,
         res_storico_gsd_inizio_anno,
         res_storico_gsd_fine_anno,
         residente_dal,
         personafisica,
         data_nascita,
         aire_storico_gsd_inizio_anno,
         aire_storico_gsd_fine_anno,
         deceduto,
         datadecesso,
         xxcontribuente_da_fare,
         min_max_perc_possesso,
         differenza_oggetti_catasto,
         differenza_terreni_catasto,
         oggetti_non_catasto,
         terreni_non_catasto,
         cata_no_tr4,
         cata_no_tr4_terreni,
         liquidazione_accertamento,
         liquidazione_ads,
         iter_ads,
         ravvedimento_imu,
         tipo_tributo,
         versato,
         dovuto,
         dovuto_comunale,
         dovuto_erariale,
         dovuto_acconto,
         dovuto_comunale_acconto,
         dovuto_erariale_acconto,
         diff_tot_contr,
         denunce_imu,
         codice_attivita_cont,
         residente_oggi,
         ab_pr,
         pert,
         altri_fabbricati,
         fabbricati_d,
         terreni,
         terreni_ridotti,
         aree,
         abitativo,
         commercialiartigianali,
         rurali,
         decode(liquidazione_ads,'0','',' ','',
               rtrim(substr(liquidazione_ads,instr(liquidazione_ads,'Utente')+8,8))) utente_operativo,
         decode(liquidazione_ads,'0','',' ','',
               rtrim(substr(liquidazione_ads,instr(liquidazione_ads,'Stato')+8,2))) stato,
         decode(liquidazione_ads,'0','',' ','',
               decode(instr(liquidazione_ads,'Tipo Atto'),0,'',
                      rtrim(substr(liquidazione_ads,instr(liquidazione_ads,'Tipo Atto')+12,2)))) tipo_atto,
         decode(liquidazione_ads,'0','',' ','',
               rtrim(rtrim(substr(liquidazione_ads,decode(instr(liquidazione_ads,'Numero'),
                                                          0,instr(liquidazione_ads,'Tot.Pratiche'),
                                                            instr(liquidazione_ads,'Numero')+9),15)),')')) numero,
         decode(liquidazione_ads,'0','',' ','',
--               substr(liquidazione_ads,decode(instr(liquidazione_ads,'del'),
--                                              0,'',
--                                                instr(liquidazione_ads,'del')+4),10)) data_prtr,
               decode(instr(liquidazione_ads,'del'),0,'',
                      substr(liquidazione_ads,instr(liquidazione_ads,'del')+4,10))) data_prtr,
         decode(liquidazione_ads,'0','',' ','',
--               substr(liquidazione_ads,decode(instr(liquidazione_ads,'Notificata'),
--                                              0,'',
--                                                instr(liquidazione_ads,'Notificata')+14),10)) data_notifica,
               decode(instr(liquidazione_ads,'Notificata'),0,'',
                      substr(liquidazione_ads,instr(liquidazione_ads,'Notificata')+14,10))) data_notifica,
         decode(ultima_liquidazione,'0','',' ','',
               rtrim(substr(ultima_liquidazione,instr(ultima_liquidazione,'Utente')+8,8))) liq2_utente,
         decode(ultima_liquidazione,'0','',' ','',
               decode(instr(ultima_liquidazione,'Stato'),0,'',
                      rtrim(substr(ultima_liquidazione,instr(ultima_liquidazione,'Stato')+8,2)))) liq2_stato,
         decode(ultima_liquidazione,'0','',' ','',
               decode(instr(ultima_liquidazione,'Tipo Atto'),0,'',
                      rtrim(substr(ultima_liquidazione,instr(ultima_liquidazione,'Tipo Atto')+12,2)))) liq2_tipo_atto,
         decode(ultima_liquidazione,'0','',' ','',
               rtrim(substr(ultima_liquidazione,instr(ultima_liquidazione,'Numero')+9,15))) liq2_numero,
         decode(ultima_liquidazione,'0','',' ','',
--               substr(ultima_liquidazione,decode(instr(ultima_liquidazione,'del'),
--                                              0,'',
--                                                instr(ultima_liquidazione,'del')+4),10)) liq2_data
               decode(instr(ultima_liquidazione,'del'),0,'',
                      substr(ultima_liquidazione,instr(ultima_liquidazione,'del')+4,10))) liq2_data,
         decode(ultima_liquidazione,'0','',' ','',
--               substr(ultima_liquidazione,decode(instr(ultima_liquidazione,'del'),
--                                              0,'',
--                                                instr(ultima_liquidazione,'del')+4),10)) liq2_data
               decode(instr(ultima_liquidazione,'Notificata'),0,'',
                      substr(ultima_liquidazione,instr(ultima_liquidazione,'Notificata')+14,10))) liq2_data_notifica
    from SERVIZI_DV
   where anno between nvl(p_anno_iniz,0)
                  and nvl(p_anno_fine,9999)
     and tipo_tributo||'' like p_tipo_tributo
   union all
  select replace(FONTE,'SERVIZI_','') fonte
       , decode(nvl(cata_no_tr4,0) + nvl(cata_no_tr4_terreni,0)
               ,0,'9 - Contribuenti con solo versamenti TR4 e sconosciuti a catasto'
               ,'4 - Contribuenti non coerenti con il catasto e con  differenza D/V  (solo versamenti)'
               ) segnalazione
       , ragionesociale
       , codicefiscale
       , anno
       , numoggetti
       , numfabbricati
       , numterreni
       , numaree
       , differenza_imposta
       , res_storico_gsd_inizio_anno
       , res_storico_gsd_fine_anno
       , residente_dal
       , personafisica
       , data_nascita
       , aire_storico_gsd_inizio_anno
       , aire_storico_gsd_fine_anno
       , deceduto
       , datadecesso
       , xxcontribuente_da_fare
       , min_max_perc_possesso
       , differenza_oggetti_catasto
       , differenza_terreni_catasto
       , oggetti_non_catasto
       , terreni_non_catasto
       , cata_no_tr4
       , cata_no_tr4_terreni
       , liquidazione_accertamento
       , liquidazione_ads
       , iter_ads
       , ravvedimento_imu
       , tipo_tributo
       , versato
       , dovuto
       , dovuto_comunale
       , dovuto_erariale
       , dovuto_acconto
       , dovuto_comunale_acconto
       , dovuto_erariale_acconto
       , 0 -
         supporto_servizi_pkg.f_serv_imposta_versato(servizi_ctr.codicefiscale
                                                     ,nvl(p_anno_iniz,0)
                                                     ,nvl(p_anno_fine,9999)
                                                     ,servizi_ctr.tipo_tributo
                                                     )
         diff_tot_contr
       , denunce_imu
       , codice_attivita_cont
       , residente_oggi
       , ab_pr
       , pert
       , altri_fabbricati
       , fabbricati_d
       , terreni
       , terreni_ridotti
       , aree
       , abitativo
       , commercialiartigianali
       , rurali
       , '' utente_operativo
       , '' stato
       , '' tipo_atto
       , '' numero
       , '' data_prtr
       , '' data_notifics
       , '' liq2_utente
       , '' liq2_stato
       , '' liq2_tipo_atto
       , '' liq2_numero
       , '' liq2_data
       , '' liq2_data_notifics
    from SERVIZI_CTR
   where anno between nvl(p_anno_iniz,0)
                  and nvl(p_anno_fine,9999)
     and tipo_tributo||'' like p_tipo_tributo
union all
  select replace(FONTE,'SERVIZI_','') fonte
       , '8 - Soggetti presenti in catasto con CF ma sconosciuti in '||
         f_descrizione_titr(tipo_tributo, anno) segnalazione
       , ragionesociale
       , codicefiscale
       , anno
       , numoggetti
       , numfabbricati
       , numterreni
       , numaree
       , differenza_imposta
       , res_storico_gsd_inizio_anno
       , res_storico_gsd_fine_anno
       , residente_dal
       , personafisica
       , data_nascita
       , aire_storico_gsd_inizio_anno
       , aire_storico_gsd_fine_anno
       , deceduto
       , datadecesso
       , xxcontribuente_da_fare
       , min_max_perc_possesso
       , differenza_oggetti_catasto
       , differenza_terreni_catasto
       , oggetti_non_catasto
       , terreni_non_catasto
       , cata_no_tr4
       , cata_no_tr4_terreni
       , liquidazione_accertamento
       , liquidazione_ads
       , iter_ads
       , ravvedimento_imu
       , tipo_tributo
       , versato
       , dovuto
       , dovuto_comunale
       , dovuto_erariale
       , dovuto_acconto
       , dovuto_comunale_acconto
       , dovuto_erariale_acconto
       , diff_tot_contr
       , denunce_imu
       , codice_attivita_cont
       , residente_oggi
       , ab_pr
       , pert
       , altri_fabbricati
       , fabbricati_d
       , terreni
       , terreni_ridotti
       , aree
       , abitativo
       , commercialiartigianali
       , rurali
       , '' utente_operativo
       , '' stato
       , '' tipo_atto
       , '' numero
       , '' data_prtr
       , '' data_notifics
       , '' liq2_utente
       , '' liq2_stato
       , '' liq2_tipo_atto
       , '' liq2_numero
       , '' liq2_data
       , '' liq2_data_notifics
    from SERVIZI_CC
   where anno between nvl(p_anno_iniz,0)
                  and nvl(p_anno_fine,9999)
     and tipo_tributo||'' like p_tipo_tributo
        ;
begin
  -- Si eliminano le righe di eventuali popolamenti precedenti
  begin
    delete from SUPPORTO_SERVIZI
     where anno between nvl(p_anno_iniz,0)
                    and nvl(p_anno_fine,9999)
       and tipo_tributo||'' like p_tipo_tributo
       and nvl(p_eliminazione,'N') = 'S'
    ;
  exception
    when others then
      w_result    := 1;
      w_messaggio := substr('Delete SUPPORTO_SERVIZI - '||sqlerrm,1,4000);
      raise errore;
  end;
  commit;
  --
  for rec_dv in sel_dv
  loop
--  dbms_output.put_line('dentro loop');
    begin
      select count(*)
        into w_conta_record
        from supporto_servizi
       where tipo_tributo = rec_dv.tipo_tributo
         and anno         = rec_dv.anno
         and cognome_nome = rec_dv.ragionesociale
         and cod_fiscale  = rec_dv.codicefiscale
       ;
    exception
      when others then
        w_result    := 1;
        w_messaggio := substr('Errore conteggio record Unici in SUPPORTO_SERVIZI per: '||rec_dv.codicefiscale||
                             ', Anno: '||rec_dv.anno||', Tipo Tributo: '||rec_dv.tipo_tributo||
                             ') - '||SQLERRM,1,4000);
      raise errore;
    end;

    if nvl(p_eliminazione,'N') = 'S' or w_conta_record = 0 then

      if afc.is_number(rec_dv.DIFFERENZA_IMPOSTA) = 0
        or afc.is_number(rec_dv.VERSATO) = 0
        or afc.is_number(rec_dv.DOVUTO) = 0
        or afc.is_number(rec_dv.DOVUTO_COMUNALE) = 0
        or afc.is_number(rec_dv.DOVUTO_ERARIALE) = 0
        or afc.is_number(rec_dv.DOVUTO_ACCONTO ) = 0
        or afc.is_number(rec_dv.DOVUTO_COMUNALE_ACCONTO) = 0
        or afc.is_number(rec_dv.DOVUTO_ERARIALE_ACCONTO ) = 0
        or afc.is_number(rec_dv.DIFF_TOT_CONTR    ) = 0
        or afc.is_number(rec_dv.TIPO_ATTO    ) = 0
        or afc.is_number(rec_dv.LIQ2_TIPO_ATTO) = 0
        or afc.is_number(rec_dv.ANNO   ) = 0
        or afc.is_number(rec_dv.RESIDENTE_DAl) = 0
        or afc.is_number(substr(rec_dv.min_max_perc_possesso,1,instr(rec_dv.min_max_perc_possesso,'-')-1)) = 0
        or afc.is_number(substr(rec_dv.min_max_perc_possesso,instr(rec_dv.min_max_perc_possesso,'-')+1)) = 0
        or afc.is_number(rec_dv.NUMOGGETTI   ) = 0
        or afc.is_number(rec_dv.NUMFABBRICATI ) = 0
        or afc.is_number(rec_dv.NUMTERRENI    ) = 0
        or afc.is_number(rec_dv.NUMAREE   ) = 0
        or afc.is_number(rec_dv.oggetti_NON_CATASTO) = 0
        or afc.is_number(rec_dv.TERRENI_NON_CATASTO   ) = 0
        or afc.is_number(rec_dv.CATA_NO_TR4) = 0
        or afc.is_number(rec_dv.CATA_NO_TR4_TERRENI   ) = 0
        or afc.is_number(rec_dv.DENUNCE_IMU   ) = 0
        or afc.is_number(rec_dv.AB_PR  ) = 0
        or afc.is_number(rec_dv.PERT    ) = 0
        or afc.is_number(rec_dv.ALTRI_FABBRICATI) = 0
        or afc.is_number(rec_dv.FABBRICATI_D  ) = 0
        or afc.is_number(rec_dv.TERRENI   ) = 0
        or afc.is_number(rec_dv.TERRENI_RIDOTTI) = 0
        or afc.is_number(rec_dv.AREE    ) = 0
        or afc.is_number(rec_dv.ABITATIVO) = 0
        or afc.is_number(rec_dv.COMMERCIALIARTIGIANALI) = 0
        or afc.is_number(rec_dv.RURALI    ) = 0 then
               w_result    := 1;
               w_messaggio := substr('Errore controllo numeri: '||rec_dv.codicefiscale||
                                     ', Anno: '||rec_dv.anno||', Tipo Tributo: '||rec_dv.tipo_tributo||
                                     ') - '||SQLERRM,1,4000);
               raise errore;
      end if;

       begin
          insert into SUPPORTO_SERVIZI
               ( tipologia
               , segnalazione_iniziale
               , segnalazione_ultima
               , cognome_nome
               , cod_fiscale
               , anno
               , num_oggetti
               , num_fabbricati
               , num_terreni
               , num_aree
               , differenza_imposta
               , res_storico_gsd_inizio_anno
               , res_storico_gsd_fine_anno
               , residente_da_anno
               , tipo_persona
               , data_nas
               , aire_storico_gsd_inizio_anno
               , aire_storico_gsd_fine_anno
               , flag_deceduto
               , data_decesso
               , contribuente_da_fare
               , min_perc_possesso
               , max_perc_possesso
               , flag_diff_fabbricati_catasto
               , flag_diff_terreni_catasto
               , fabbricati_non_catasto
               , terreni_non_catasto
               , catasto_non_tr4_fabbricati
               , catasto_non_tr4_terreni
               , flag_liq_acc
               , liquidazione_ads
               , iter_ads
               , flag_ravvedimento
               , tipo_tributo
               , versato
               , dovuto
               , dovuto_comunale
               , dovuto_erariale
               , dovuto_acconto
               , dovuto_comunale_acconto
               , dovuto_erariale_acconto
               , diff_tot_contr
               , denunce_imu
               , codice_attivita_cont
               , residente_oggi
               , ab_principali
               , pertinenze
               , altri_fabbricati
               , fabbricati_d
               , terreni
               , terreni_ridotti
               , aree
               , abitativo
               , commerciali_artigianali
               , rurali
               , utente_operativo
               , stato
               , tipo_atto
               , numero
               , data
               , liq2_utente
               , liq2_stato
               , liq2_tipo_atto
               , liq2_numero
               , liq2_data
               , data_notifica
               , liq2_data_notifica
               , utente
               , note)
          values (
                rec_dv.fonte,
                rec_dv.segnalazione,
                '',
                rec_dv.ragionesociale,
                rec_dv.codicefiscale,
                rec_dv.anno,
                rec_dv.numoggetti,
                rec_dv.numfabbricati,
                rec_dv.numterreni,
                rec_dv.numaree,
                rec_dv.differenza_imposta,
                rec_dv.res_storico_gsd_inizio_anno,
                rec_dv.res_storico_gsd_fine_anno,
                rec_dv.residente_dal,
                rec_dv.personafisica,
                rec_dv.data_nascita,
                rec_dv.aire_storico_gsd_inizio_anno,
                rec_dv.aire_storico_gsd_fine_anno,
                decode(rec_dv.deceduto,'','','S'),
                rec_dv.datadecesso,
                rec_dv.xxcontribuente_da_fare,
                substr(rec_dv.min_max_perc_possesso,1,instr(rec_dv.min_max_perc_possesso,'-')-1),
                substr(rec_dv.min_max_perc_possesso,instr(rec_dv.min_max_perc_possesso,'-')+1),
                decode(rec_dv.differenza_oggetti_catasto,0,'','','','S'),
                decode(rec_dv.differenza_terreni_catasto,0,'','','','S'),
                rec_dv.oggetti_non_catasto,
                rec_dv.terreni_non_catasto,
                rec_dv.cata_no_tr4,
                rec_dv.cata_no_tr4_terreni,
                decode(rec_dv.liquidazione_accertamento,0,'','','','S'),
                decode(rec_dv.liquidazione_ads,'0','',rec_dv.liquidazione_ads),
                rec_dv.iter_ads,
                decode(rec_dv.ravvedimento_imu,0,'','','','S'),
                rec_dv.tipo_tributo,
                rec_dv.versato,
                rec_dv.dovuto,
                rec_dv.dovuto_comunale,
                rec_dv.dovuto_erariale,
                rec_dv.dovuto_acconto,
                rec_dv.dovuto_comunale_acconto,
                rec_dv.dovuto_erariale_acconto,
                rec_dv.diff_tot_contr,
                rec_dv.denunce_imu,
                rec_dv.codice_attivita_cont,
                rec_dv.residente_oggi,
                rec_dv.ab_pr,
                rec_dv.pert,
                rec_dv.altri_fabbricati,
                rec_dv.fabbricati_d,
                rec_dv.terreni,
                rec_dv.terreni_ridotti,
                rec_dv.aree,
                rec_dv.abitativo,
                rec_dv.commercialiartigianali,
                rec_dv.rurali,
                rec_dv.utente_operativo,
                rec_dv.stato,
                rec_dv.tipo_atto,
                rec_dv.numero,
                to_date(rec_dv.data_prtr,'dd/mm/yyyy'),
                rec_dv.liq2_utente,
                rec_dv.liq2_stato,
                rec_dv.liq2_tipo_atto,
                rec_dv.liq2_numero,
                to_date(rec_dv.liq2_data,'dd/mm/yyyy'),
                to_date(rec_dv.data_notifica,'dd/mm/yyyy'),
                to_date(rec_dv.liq2_data_notifica,'dd/mm/yyyy'),
                p_utente,
                'Popolamento iniziale del '||to_char(sysdate,'dd/mm/yyyy')
                );
           exception
             when others then
               w_result    := 1;
               w_messaggio := substr('Inserimento SUPPORTO_SERVIZI (Fonte: '||rec_dv.fonte||', Cod.fiscale: '||rec_dv.codicefiscale||
                                     ', Anno: '||rec_dv.anno||', Tipo Tributo: '||rec_dv.tipo_tributo||
                                     ') - '||SQLERRM,1,4000);
               raise errore;
           end;
       w_conta_righe := w_conta_righe + 1;
    else
       begin
          update supporto_servizi
             set tipologia                      = rec_dv.fonte
--               , segnalazione_iniziale
               , segnalazione_ultima            = rec_dv.segnalazione
               , cognome_nome                   = rec_dv.ragionesociale
               , cod_fiscale                    = rec_dv.codicefiscale
               , anno                           = rec_dv.anno
               , num_oggetti                    = rec_dv.numoggetti
               , num_fabbricati                 = rec_dv.numfabbricati
               , num_terreni                    = rec_dv.numterreni
               , num_aree                       = rec_dv.numaree
               , differenza_imposta             = rec_dv.differenza_imposta
               , res_storico_gsd_inizio_anno    = rec_dv.res_storico_gsd_inizio_anno
               , res_storico_gsd_fine_anno      = rec_dv.res_storico_gsd_fine_anno
               , residente_da_anno              = rec_dv.residente_dal
               , tipo_persona                   = rec_dv.personafisica
               , data_nas                       = rec_dv.data_nascita
               , aire_storico_gsd_inizio_anno   = rec_dv.aire_storico_gsd_inizio_anno
               , aire_storico_gsd_fine_anno     = rec_dv.aire_storico_gsd_fine_anno
               , flag_deceduto                  = decode(rec_dv.deceduto,'','','S')
               , data_decesso                   = rec_dv.datadecesso
               , contribuente_da_fare           = rec_dv.xxcontribuente_da_fare
               , min_perc_possesso              = substr(rec_dv.min_max_perc_possesso,1,instr(rec_dv.min_max_perc_possesso,'-')-1)
               , max_perc_possesso              = substr(rec_dv.min_max_perc_possesso,instr(rec_dv.min_max_perc_possesso,'-')+1)
               , flag_diff_fabbricati_catasto   = decode(rec_dv.differenza_oggetti_catasto,0,'','','','S')
               , flag_diff_terreni_catasto      = decode(rec_dv.differenza_terreni_catasto,0,'','','','S')
               , fabbricati_non_catasto         = rec_dv.oggetti_non_catasto
               , terreni_non_catasto            = rec_dv.terreni_non_catasto
               , catasto_non_tr4_fabbricati     = rec_dv.cata_no_tr4
               , catasto_non_tr4_terreni        = rec_dv.cata_no_tr4_terreni
               , flag_liq_acc                   = decode(rec_dv.liquidazione_accertamento,0,'','','','S')
               , liquidazione_ads               = decode(rec_dv.liquidazione_ads,'0','',rec_dv.liquidazione_ads)
               , iter_ads                       = rec_dv.iter_ads
               , flag_ravvedimento              = decode(rec_dv.ravvedimento_imu,0,'','','','S')
               , tipo_tributo                   = rec_dv.tipo_tributo
               , versato                        = rec_dv.versato
               , dovuto                         = rec_dv.dovuto
               , dovuto_comunale                = rec_dv.dovuto_comunale
               , dovuto_erariale                = rec_dv.dovuto_erariale
               , dovuto_acconto                 = rec_dv.dovuto_acconto
               , dovuto_comunale_acconto        = rec_dv.dovuto_comunale_acconto
               , dovuto_erariale_acconto        = rec_dv.dovuto_erariale_acconto
               , diff_tot_contr                 = rec_dv.diff_tot_contr
               , denunce_imu                    = rec_dv.denunce_imu
               , codice_attivita_cont           = rec_dv.codice_attivita_cont
               , residente_oggi                 = rec_dv.residente_oggi
               , ab_principali                  = rec_dv.ab_pr
               , pertinenze                     = rec_dv.pert
               , altri_fabbricati               = rec_dv.altri_fabbricati
               , fabbricati_d                   = rec_dv.fabbricati_d
               , terreni                        = rec_dv.terreni
               , terreni_ridotti                = rec_dv.terreni_ridotti
               , aree                           = rec_dv.aree
               , abitativo                      = rec_dv.abitativo
               , commerciali_artigianali        = rec_dv.commercialiartigianali
               , rurali                         = rec_dv.rurali
               , utente_operativo               = rec_dv.utente_operativo
               , stato                          = rec_dv.stato
               , tipo_atto                      = rec_dv.tipo_atto
               , numero                         = rec_dv.numero
               , data                           = to_date(rec_dv.data_prtr,'dd/mm/yyyy')
               , liq2_utente                    = rec_dv.liq2_utente
               , liq2_stato                     = rec_dv.liq2_stato
               , liq2_tipo_atto                 = rec_dv.liq2_tipo_atto
               , liq2_numero                    = rec_dv.liq2_numero
               , liq2_data                      = to_date(rec_dv.liq2_data,'dd/mm/yyyy')
               , utente                         = p_utente
--               , note
           where tipo_tributo = rec_dv.tipo_tributo
             and anno         = rec_dv.anno
             and cognome_nome = rec_dv.ragionesociale
             and cod_fiscale  = rec_dv.codicefiscale
          ;
       exception
         when others then
           w_result    := 1;
           w_messaggio := substr('Aggiornamento SUPPORTO_SERVIZI (Cod.fiscale: '||rec_dv.codicefiscale||
                                 ', Anno: '||rec_dv.anno||', Tipo Tributo: '||rec_dv.tipo_tributo||
                                 ') - '||SQLERRM,1,4000);
           raise errore;
       end;

       w_conta_update := w_conta_update + 1;
    end if;

    if mod(w_conta_righe+w_conta_update,10) = 0 then
       commit;
    end if;
  end loop;
  commit;
  --
  w_messaggio := 'Elaborazione terminata - Righe inserite: '||w_conta_righe||' - Righe aggiornate: '||w_conta_update;
  p_result    := w_result;
  p_messaggio := w_messaggio;

exception
  when errore then
    p_result    := w_result;
    p_messaggio := w_messaggio;
    rollback;
end POPOLA_DA_VISTE;
----------------------------------------------------------------------------------
procedure POPOLA_TABELLONE
/******************************************************************************
  NOME:        POPOLAMENTO_TABELLONE.
  DESCRIZIONE: Esegue il popolamento della tabella SUPPORTO_SERVIZI con i dati
               presenti nelle vari viste (SERVIZI_DV, SERVIZI_CTR, SERVIZI_CC).
  NOTE:
******************************************************************************/
( p_tipo_tributo             varchar2
, p_anno_iniz                number
, p_anno_fine                number
, p_eliminazione             varchar2
, p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
) is
  w_result                   number := 0;
  w_messaggio                varchar2(4000);
begin
  supporto_servizi_pkg.popola_da_viste(p_tipo_tributo, p_anno_iniz, p_anno_fine, p_eliminazione, p_utente, w_result, w_messaggio);
  p_result    := w_result;
  p_messaggio := w_messaggio;
end POPOLA_TABELLONE;
----------------------------------------------------------------------------------
procedure ASSEGNA_CONTRIBUENTI
/******************************************************************************
  NOME:        ASSEGNA_CONTRIBUENTI.
  DESCRIZIONE: Assegnazione dei contribuenti da trattare all'utente indicato.
  NOTE:
******************************************************************************/
( p_tipo_tributo             varchar2
, p_utente                   varchar2
, p_numero_casi              number
, p_num_oggetti_da           number
, p_num_oggetti_a            number
, p_da_perc_possesso         number
, p_a_perc_possesso          number
, p_liq_non_notificate       varchar2
, p_fabbricati               varchar2
, p_terreni                  varchar2
, p_aree                     varchar2
, p_contitolari              varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
) is
  w_conta_casi               number := 0;
  w_casi_totali              number := 0;
  w_id                       number;
  w_messaggio                varchar2(4000);
  errore                     exception;

  cursor sel_oggetti ( a_anno         number
                     , a_tipo_tributo varchar2
                     , a_cod_fiscale  varchar2
                     )
  is
    select distinct oggetto
      from contribuenti_oggetto_anno
     where anno = a_anno
       and tipo_tributo = a_tipo_tributo
       and cod_fiscale = a_cod_fiscale
     order by 1;

  cursor sel_contitolari ( a_anno         number
                         , a_tipo_tributo varchar2
                         , a_oggetto      number
                         , a_cod_fiscale  varchar2
                         )
  is
    select distinct cod_fiscale
      from contribuenti_oggetto_anno
     where anno = a_anno
       and tipo_tributo = a_tipo_tributo
       and oggetto = a_oggetto
       and cod_fiscale <> a_cod_fiscale;

begin
--       w_messaggio := 'p_liq_non_notificate '||p_liq_non_notificate||' p_fabbricati '||p_fabbricati||
--                      ' p_terreni '||p_terreni||' p_aree '||p_aree||' p_contitolari '||p_contitolari;
--             raise errore;
  for uten in (select uten.utente
                 from ad4_utenti uten
                    , ad4_diritti_accesso diac
                where uten.utente = diac.utente
                  and diac.istanza like 'TR4%'
                  and ((p_utente <> 'Tutti' and uten.utente = p_utente) or
                       (p_utente = 'Tutti' and
                       (uten.utente like 'ADS%' or uten.importanza = 10)))
                order by 1)
  loop
    w_conta_casi := 0;
    for cont in (select id
                      , anno
                      , cod_fiscale
                   from supporto_servizi
                  where utente_assegnato is null
                    and tipo_tributo = p_tipo_tributo
                    and nvl(num_oggetti,0) between nvl(p_num_oggetti_da,0)
                                               and nvl(p_num_oggetti_a,9999)
                    and ((p_liq_non_notificate is null and liquidazione_ads is null)  or
                         (p_liq_non_notificate = 'T' and data_notifica is null) or
                         (p_liq_non_notificate = 'S' and liquidazione_ads is not null and numero is null))
                    and ((p_liq_non_notificate is null and liq2_utente is null)  or
                         (p_liq_non_notificate = 'T' and liq2_data_notifica is null) or
                         (p_liq_non_notificate = 'S' and liq2_utente is not null and liq2_numero is null))
--                        liquidazione_ads is null
--                    and liq2_utente is null
                    and ((p_fabbricati is null) or
                         (p_fabbricati = 'S' and nvl(num_fabbricati,0) > 0) or
                         (p_fabbricati = 'N' and nvl(num_fabbricati,0) = 0))
                    and ((p_terreni is null) or
                         (p_terreni = 'S' and nvl(num_terreni,0) > 0) or
                         (p_terreni = 'N' and nvl(num_terreni,0) = 0))
                    and ((p_aree is null) or
                         (p_aree = 'S' and nvl(num_aree,0) > 0) or
                         (p_aree = 'N' and nvl(num_aree,0) = 0))
--                    and (p_tipologia is null or
--                        (p_tipologia = 'F' and num_fabbricati > 0) or
--                        (p_tipologia = 'T' and num_terreni > 0))
                    and nvl(min_perc_possesso,0) between nvl(p_da_perc_possesso,0)
                                                     and nvl(p_a_perc_possesso,9999)
                  order by anno, differenza_imposta desc   --1
                )
    loop
      -- Si rilegge la riga per controllare che non sia gia' stata trattata
      -- come contitolare
      begin
        select id
          into w_id
          from supporto_servizi
         where id = cont.id
           and utente_assegnato is null;
      exception
        when others then
          w_id := to_number(null);
      end;
      if w_id is not null then
         UPDATE_SUPPORTO_SERVIZI(cont.id,uten.utente,w_messaggio);
         if w_messaggio is not null then
            raise errore;
         end if;
         w_conta_casi := w_conta_casi + 1;
         -- Primo livello: si controlla se gli oggetti del contribuente hanno contitolari
         for ogge in sel_oggetti (cont.anno, p_tipo_tributo, cont.cod_fiscale)
         loop
           -- Ogni contitolare dell'oggetto viene assegnato allo stesso utente
           for ctit in sel_contitolari (cont.anno, p_tipo_tributo, ogge.oggetto, cont.cod_fiscale)
           loop
             begin
               select id
                 into w_id
                 from SUPPORTO_SERVIZI
                where utente_assegnato is null
                  and tipo_tributo = p_tipo_tributo
                  and nvl(num_oggetti,0) between nvl(p_num_oggetti_da,0)
                                             and nvl(p_num_oggetti_a,9999)
                  and ((nvl(p_contitolari,'S') = 'S' and   -- se si sceglie di applicare gli stessi filtri anche ai contitolari
                           ((p_liq_non_notificate is null and liquidazione_ads is null)  or
                            (p_liq_non_notificate = 'T' and data_notifica is null) or
                            (p_liq_non_notificate = 'S' and liquidazione_ads is not null and numero is null))
                       and ((p_liq_non_notificate is null and liq2_utente is null)  or
                            (p_liq_non_notificate = 'T' and liq2_data_notifica is null) or
                            (p_liq_non_notificate = 'S' and liq2_utente is not null and liq2_numero is null))
                       and ((p_fabbricati is null) or
                            (p_fabbricati = 'S' and nvl(num_fabbricati,0) > 0) or
                            (p_fabbricati = 'N' and nvl(num_fabbricati,0) = 0))
                       and ((p_terreni is null) or
                            (p_terreni = 'S' and nvl(num_terreni,0) > 0) or
                            (p_terreni = 'N' and nvl(num_terreni,0) = 0))
                       and ((p_aree is null) or
                            (p_aree = 'S' and nvl(num_aree,0) > 0) or
                            (p_aree = 'N' and nvl(num_aree,0) = 0))) or
                       nvl(p_contitolari,'S') = 'N')
                  and nvl(min_perc_possesso,0) between nvl(p_da_perc_possesso,0)
                                                   and nvl(p_a_perc_possesso,9999)
                  and anno = cont.anno
                  and cod_fiscale = ctit.cod_fiscale;
             exception
               when others then
                 w_id := to_number(null);
             end;
             if w_id is not null then
                UPDATE_SUPPORTO_SERVIZI(w_id,uten.utente,w_messaggio);
                if w_messaggio is not null then
                   raise errore;
                end if;
                w_conta_casi := w_conta_casi + 1;
             end if;
           end loop;
         end loop;
         -- Secondo livello: si controllano i contitolari dei contitolari
         for ogge in sel_oggetti (cont.anno, p_tipo_tributo, cont.cod_fiscale)
         loop
           -- Per ogni oggetto del contribuente principale si trattano i contitolari
           for ctit in sel_contitolari (cont.anno, p_tipo_tributo, ogge.oggetto, cont.cod_fiscale)
           loop
             -- Per ogni contitolare si trattano tutti gli oggetti
             --for ogg2 in sel_oggetti (cont.anno, p_tipo_tributo, ctit.cod_fiscale)
             for ogg2 in (select distinct oggetto
                            from contribuenti_oggetto_anno
                           where anno = cont.anno
                             and tipo_tributo = p_tipo_tributo
                             and cod_fiscale = ctit.cod_fiscale
                           order by 1)
             loop
               for cti2 in (select distinct cod_fiscale
                              from contribuenti_oggetto_anno
                             where anno = cont.anno
                               and tipo_tributo = p_tipo_tributo
                               and oggetto = ogg2.oggetto
                               and cod_fiscale <> ctit.cod_fiscale)
               loop
                 begin
                   select id
                     into w_id
                     from SUPPORTO_SERVIZI
                    where utente_assegnato is null
                      and tipo_tributo = p_tipo_tributo
                      and nvl(num_oggetti,0) between nvl(p_num_oggetti_da,0)
                                                 and nvl(p_num_oggetti_a,9999)
                      and ((nvl(p_contitolari,'S') = 'S' and
                               ((p_liq_non_notificate is null and liquidazione_ads is null)  or
                                (p_liq_non_notificate = 'T' and data_notifica is null) or
                                (p_liq_non_notificate = 'S' and liquidazione_ads is not null and numero is null))
                           and ((p_liq_non_notificate is null and liq2_utente is null)  or
                                (p_liq_non_notificate = 'T' and liq2_data_notifica is null) or
                                (p_liq_non_notificate = 'S' and liq2_utente is not null and liq2_numero is null))
                           and ((p_fabbricati is null) or
                                (p_fabbricati = 'S' and nvl(num_fabbricati,0) > 0) or
                                (p_fabbricati = 'N' and nvl(num_fabbricati,0) = 0))
                           and ((p_terreni is null) or
                                (p_terreni = 'S' and nvl(num_terreni,0) > 0) or
                                (p_terreni = 'N' and nvl(num_terreni,0) = 0))
                           and ((p_aree is null) or
                                (p_aree = 'S' and nvl(num_aree,0) > 0) or
                                (p_aree = 'N' and nvl(num_aree,0) = 0))) or
                           nvl(p_contitolari,'S') = 'N')
                      and nvl(min_perc_possesso,0) between nvl(p_da_perc_possesso,0)
                                                       and nvl(p_a_perc_possesso,9999)
                      and anno = cont.anno
                      and cod_fiscale = cti2.cod_fiscale;
                 exception
                   when others then
                     w_id := to_number(null);
                 end;
                 if w_id is not null then
                    UPDATE_SUPPORTO_SERVIZI(w_id,uten.utente,w_messaggio);
                    if w_messaggio is not null then
                       raise errore;
                    end if;
                    w_conta_casi := w_conta_casi + 1;
                 end if;
               end loop;
             end loop;
           end loop;
         end loop;
      end if;
      if w_conta_casi >= p_numero_casi then
         exit;
      end if;
    end loop;
    w_casi_totali := w_casi_totali + w_conta_casi;
    commit;
  end loop;

  p_result    := 0;
  p_messaggio := 'Elaborazione terminata - Casi trattati: '||w_casi_totali;
exception
  when errore then
    rollback;
    p_result    := 1;
    p_messaggio := w_messaggio;
end ASSEGNA_CONTRIBUENTI;
----------------------------------------------------------------------------------
procedure AGGIORNA_ASSEGNAZIONE
/******************************************************************************
  NOME:        AGGIORNA_ASSEGNAZIONE.
  DESCRIZIONE: Aggiorna l'utente operativo sulla riga e riporta le informazioni
               dell'eventuale pratica emessa.
  NOTE:
******************************************************************************/
( p_utente                   varchar2
, p_result                   OUT number
, p_messaggio                OUT varchar2
) is
  w_conta_casi               number := 0;
  w_pratica                  number;
  w_numero                   varchar2(15);
  w_data_pratica             date;
  w_tipo_pratica             varchar2(1);
  w_tipo_atto                number;
  w_stato                    varchar2(2);
  w_des_tipo_atto            varchar2(60);
  w_utente                   varchar2(8);
  w_messaggio                varchar2(4000);
  w_importanza               number;
  errore                     exception;
begin
  for uten in (select p_utente utente
                 from dual
                where p_utente <> 'Tutti'
               union
               select distinct utente_assegnato utente
                 from supporto_servizi
                where utente_assegnato is not null
-- AB 25/09/2023 si permette l'aggiornamento della posizione anche se utente operativo valorizzato
--                  and utente_operativo is null
                order by 1)
  loop
    for cont in (select id
                      , tipo_tributo
                      , anno
                      , cod_fiscale
                      , utente_operativo
                   from supporto_servizi
                  where utente_assegnato = uten.utente
-- AB 25/09/2023 si permette l'aggiornamento della posizione anche se utente operativo valorizzato
--                     and utente_operativo is null
                  order by id)
    loop
      -- Si controlla se per il contribuente e' stato emesso un atto
      begin
        select prtr.pratica
             , prtr.numero
             , prtr.data
             , prtr.tipo_pratica
             , prtr.tipo_atto
             , prtr.stato_accertamento
             , tiat.descrizione
             , prtr.utente
             , nvl(uten.importanza,decode(substr(prtr.utente,1,3),'ADS',10,0))
          into w_pratica
             , w_numero
             , w_data_pratica
             , w_tipo_pratica
             , w_tipo_atto
             , w_stato
             , w_des_tipo_atto
             , w_utente
             , w_importanza
          from pratiche_tributo prtr
             , tipi_atto tiat
             , ad4_utenti uten
         where prtr.tipo_tributo = cont.tipo_tributo
           and prtr.anno = cont.anno
           and prtr.cod_fiscale = cont.cod_fiscale
           and prtr.tipo_pratica in ('L','A')
           and prtr.tipo_atto = tiat.tipo_atto (+)
           and prtr.utente           = uten.utente
           and prtr.data = (select max(prtx.data)
                              from pratiche_tributo prtx
                             where prtx.tipo_tributo = prtr.tipo_tributo
                               and prtx.anno = prtr.anno
                               and prtx.cod_fiscale = prtr.cod_fiscale
                               and prtx.tipo_pratica in ('L','A')
                           );
      exception
        when others then
          w_pratica      := to_number(null);
          w_numero       := null;
          w_data_pratica := to_date(null);
          w_tipo_pratica := null;
          w_tipo_atto    := to_number(null);
          w_stato        := null;
      end;
      -- Se esiste un atto si aggiorna la riga di supporto_servizi
      if w_pratica is not null then
         w_conta_casi := w_conta_casi + 1;
         begin
           update supporto_servizi
              set utente_operativo  = decode(cont.utente_operativo,'',w_utente,cont.utente_operativo)
--                , liquidazione_ads = decode(w_des_tipo_atto
--                                           ,null,null
--                                           ,w_des_tipo_atto||' ')||
--                                     decode(w_numero
--                                           ,null,to_char(w_data_pratica,'dd/mm/yyyy')
--                                           ,w_numero||' del '||to_char(w_data_pratica,'dd/mm/yyyy')
--                                           )
                , flag_liq_acc      = 'S'
                , numero            = decode(w_importanza,10,w_numero,numero)
                , data              = decode(w_importanza,10,w_data_pratica,data)
                , stato             = decode(w_importanza,10,w_stato,stato)
                , tipo_atto         = decode(w_importanza,10,w_tipo_atto,tipo_atto)
                , liq2_utente       = decode(w_importanza,10,liq2_utente,w_utente)
                , liq2_numero       = decode(w_importanza,10,liq2_numero,w_numero)
                , liq2_data         = decode(w_importanza,10,liq2_data,w_data_pratica)
                , liq2_stato        = decode(w_importanza,10,liq2_stato,w_stato)
                , liq2_tipo_atto    = decode(w_importanza,10,liq2_tipo_atto,w_tipo_atto)
                , segnalazione_ultima = decode(w_tipo_pratica
                                              ,'L','Liquidazione emessa'
                                              ,'A','Accertamento emesso'
                                              ,null
                                              )
            where id = cont.id;
         exception
           when others then
             w_messaggio := substr('Update SUPPORTO_SERVIZI (Id. '||cont.id||') - '||sqlerrm,1,4000);
             raise errore;
         end;
      end if;
    end loop;
    commit;
  end loop;

  p_result    := 0;
  p_messaggio := 'Elaborazione terminata - Casi trattati: '||w_conta_casi;
exception
  when errore then
    rollback;
    p_result    := 1;
    p_messaggio := w_messaggio;
end AGGIORNA_ASSEGNAZIONE;

end SUPPORTO_SERVIZI_PKG;
/
