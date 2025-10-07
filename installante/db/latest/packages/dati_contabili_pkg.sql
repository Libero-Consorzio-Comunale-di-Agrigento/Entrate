--liquibase formatted sql 
--changeset abrandolini:20250326_152429_dati_contabili_pkg stripComments:false runOnChange:true 
 
CREATE OR REPLACE package     DATI_CONTABILI_PKG is
/******************************************************************************
 NOME:        DATI_CONTABILI_PKG
 DESCRIZIONE: Procedure e Funzioni per recupero dati contabilita finanziaria.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 009   08/05/2025  RV      #75455
                           Implementato gestione dati contabili per Codice Ente
 008   20/12/2024  AB      #77238 
                           Sistemato per evitare problemi se descrizione_titr dovesse essere null
 007   10/12/2024  AB      #76942 
                           Sistemato controllo su sanz con data_inizio
 006   16/07/2024  AB      Prove per provincia
                           Inserita la possibilità di estrarre con f_get_acc_contabile
                           per f_descrizione_titr = 'TEFA'
 005   07/06/2024  RV      #71976
                           Modificato dati_contabili_pratica, ora tutti i tipi pratica distinguono
                           per tipo_imposta in base al tipo_causale della sanzione.
                           Prima lo faceva solo per i ravvedimenti
 004   21/05/2024  RV      #70776
                           Aggiunto gestione tipo_occupazione
 003   05/06/2023  AB      #64533 Sostituito l'anno di prtr con quello della sysdate
                           e tolto il controllo di p_rata = 0 nella prima condizione
                           di dati_contabili_pratica
 002   15/03/2023  AB      Nuova fuunction f_get_dati_riscossione e sistemazione
                           campo bilancio, anche con articolo
 001   04/04/2022  VD      Aggiunto parametro data ripartizione in ricerca
                           accertamento contabile.
 000   27/07/2021  VD      Prima emissione.
 ******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '7    10/12/2024';
  function versione
  return varchar2;
  --Generali
  function f_get_acc_contabile
  ( p_tipo_tributo            varchar2
  , p_anno                    number
  , p_tipo_imposta            varchar2
  , p_tipo_pratica            varchar2
  , p_data_emissione          date
  , p_cod_tributo_f24         varchar2
  , p_stato_pratica           varchar2
  , p_data_ripartizione       date default null
  , p_tributo                 number default null
  , p_tipo_occupazione        varchar2 default null
  , p_cod_ente_comunale       varchar2 default null
  ) return varchar2;
  function f_get_capitolo
  ( p_anno                    number
  , p_anno_acc                number
  , p_numero_acc              number
  ) return varchar2;
  function f_get_bilancio
  ( p_capitolo                varchar2
  , p_acc_contabile           varchar2
  , p_importo                 number
  ) return varchar2;
  function f_get_dati_riscossione
  ( p_capitolo                varchar2
  ) return varchar2;
  function f_get_dati_riscossione_old
  ( p_pratica                 number
  ) return varchar2;
  function f_get_accertamento
  ( p_pratica                 number
  ) return varchar2;
  function f_get_tipo_occupazione
  ( p_pratica                 number
  ) return varchar2;
  procedure dati_contabili_imposta
  ( p_tipo_tributo            varchar2
  , p_anno                    number
  , p_tipo_imposta            varchar2
  , p_tipo_pratica            varchar2
  , p_data_emissione          date
  , p_cod_tributo_f24         varchar2
  , p_stato_pratica           varchar2
  , p_importo                 number
  , p_dati_riscossione        IN OUT varchar2
  , p_accertamento            IN OUT varchar2
  , p_bilancio                IN OUT varchar2
  );
  procedure dati_contabili_pratica
  ( p_pratica                 number
  , p_rata                    number
  , p_importo                 number
  , p_dati_riscossione        IN OUT varchar2
  , p_accertamento            IN OUT varchar2
  , p_bilancio                IN OUT varchar2
  );
end DATI_CONTABILI_PKG;
/
create or replace package body DATI_CONTABILI_PKG is
/******************************************************************************
 NOME:        DATI_CONTABILI_PKG
 DESCRIZIONE: Procedure e Funzioni per recupero dati contabilita finanziaria.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 009   08/05/2025  RV      #75455
                           Implementato gestione dati contabili per Codice Ente
 008   20/12/2024  AB      #77238 
                           Sistemato per evitare problemi se descrizione_titr dovesse essere null
 007   10/12/2024  AB      #76942 
                           Sistemato controllo su sanz con data_inizio
 006   16/07/2024  AB      Prove per provincia
                           Inserita la possibilità di estrarre con f_get_acc_contabile
                           per f_descrizione_titr = 'TEFA'
 005   07/06/2024  RV      #71976
                           Modificato dati_contabili_pratica, ora tutti i tipi pratica distinguono
                           per tipo_imposta in base al tipo_causale della sanzione.
                           Prima lo faceva solo per i ravvedimenti
 004   21/05/2024  RV      #70776
                           Aggiunto gestioner tipo_occupazione
 003   05/06/2023  AB      #64533 Sostituito l'anno di prtr con quello della sysdate
                           e tolto il controllo di p_rata = 0 nella prima condizione
                           di dati_contabili_pratica
 002   15/03/2023  AB      Nuova fuunction f_get_dati_riscossione e sistemazione
                           campo bilancio, anche con articolo
 001   04/04/2022  VD      Aggiunto parametro data ripartizione in ricerca
                           accertamento contabile.
 000   27/07/2021  VD      Prima emissione.
 ******************************************************************************/
  function versione return varchar2
  is
  begin
    return s_versione||'.'||s_revisione;
  end versione;
--------------------------------------------------------------------------------------------------------
--Generali
--------------------------------------------------------------------------------------------------------
function f_get_acc_contabile
/******************************************************************************
 NOME:        f_get_acc_contabile
 DESCRIZIONE: Restituisce i dati dell'accertamento contabile abbinati alla
              combinazione dei parametri relativi ai tributi
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 002   21/05/2023  RV      #70776
                           Aggiunto gestione tipo_occupazione
 001   04/04/2022  VD      Aggiunto parametro data ripartizione
 000   23/07/2021  VD      Prima emissione.
******************************************************************************/
( p_tipo_tributo           varchar2
, p_anno                   number
, p_tipo_imposta           varchar2
, p_tipo_pratica           varchar2
, p_data_emissione         date
, p_cod_tributo_f24        varchar2
, p_stato_pratica          varchar2
, p_data_ripartizione      date   default null
, p_tributo                number default null
, p_tipo_occupazione       varchar2 default null
, p_cod_ente_comunale      varchar2 default null
) return varchar2
is
  w_tipo_occupazione       varchar2(10);
  w_acc_contabile          varchar2(10) := null;
begin
  -- Al momento solo CUNI gestisce il tipo_occupazione
  if p_tipo_tributo = 'CUNI' then
     w_tipo_occupazione := p_tipo_occupazione;
  else
     w_tipo_occupazione := null;
  end if;
  begin
    select lpad(to_char(anno_acc),4,'0')||'/'||
--           lpad(to_char(numero_acc),5,'0')
           numero_acc
      into w_acc_contabile
      from DATI_CONTABILI
     where tipo_tributo             = p_tipo_tributo
       and anno                     = p_anno
       and tipo_imposta             = p_tipo_imposta
       and nvl(tipo_pratica,'*')    = nvl(p_tipo_pratica,'*')
       and nvl(p_data_emissione,trunc(sysdate))
                              between nvl(emissione_dal,to_date('01011900','ddmmyyyy'))
                                  and nvl(emissione_al,to_date('31122999','ddmmyyyy'))
       and nvl(tributo,-1)          = nvl(p_tributo,-1)
       and nvl(cod_tributo_f24,'*') = nvl(p_cod_tributo_f24,'*')
       and (nvl(descrizione_titr,f_descrizione_titr(tipo_tributo,anno)) = f_descrizione_titr(p_tipo_tributo,p_anno) or
            descrizione_titr         = 'TEFA')
       and nvl(stato_pratica,'**')  = nvl(p_stato_pratica,'**')
       and ((tipo_occupazione is null) or
            (tipo_occupazione = nvl(w_tipo_occupazione,'P')))
       and (p_data_ripartizione is null or
           (p_data_ripartizione is not null and
            p_data_ripartizione between nvl(ripartizione_dal,to_date('01011900','ddmmyyyy'))
                                    and nvl(ripartizione_al,to_date('31122999','ddmmyyyy'))))
       and ((p_cod_ente_comunale is null and cod_ente_comunale is null) or
            (cod_ente_comunale = p_cod_ente_comunale))
           --tributo,
    ;
  exception
    when others then
      w_acc_contabile := null;
  end;
  --
  -- Se la ricerca per tipo pratica e codice tributo è fallita,
  -- si ricerca con tipo pratica null
  if w_acc_contabile is null then
     begin
       select lpad(to_char(anno_acc),4,'0')||'/'||
--              lpad(to_char(numero_acc),5,'0')
              numero_acc
         into w_acc_contabile
         from DATI_CONTABILI
        where tipo_tributo             = p_tipo_tributo
          and anno                     = p_anno
          and tipo_imposta             = p_tipo_imposta
          and tipo_pratica             is null
          and stato_pratica            is null
          and ((tipo_occupazione is null) or
               (tipo_occupazione = nvl(w_tipo_occupazione,'P')))
          and nvl(p_data_emissione,trunc(sysdate))
                                  between nvl(emissione_dal,to_date('01011900','ddmmyyyy'))
                                     and nvl(emissione_al,to_date('31122999','ddmmyyyy'))
          and nvl(tributo,-1)          = nvl(p_tributo,-1)
          and nvl(cod_tributo_f24,'*') = nvl(p_cod_tributo_f24,'*')
          and (nvl(descrizione_titr,f_descrizione_titr(tipo_tributo,anno)) = f_descrizione_titr(p_tipo_tributo,p_anno) or
               descrizione_titr         = 'TEFA')
          and (p_data_ripartizione is null or
              (p_data_ripartizione is not null and
               p_data_ripartizione between nvl(ripartizione_dal,to_date('01011900','ddmmyyyy'))
                                       and nvl(ripartizione_al,to_date('31122999','ddmmyyyy'))))
          and ((p_cod_ente_comunale is null and cod_ente_comunale is null) or
               (cod_ente_comunale = p_cod_ente_comunale))
              --tributo,
       ;
     exception
       when others then
         w_acc_contabile := null;
     end;
  end if;
  --
  -- Se la ricerca per tipo pratica null e codice tributo è fallita,
  -- si ricerca con tributo null
  if w_acc_contabile is null then
     begin
       select lpad(to_char(anno_acc),4,'0')||'/'||
--              lpad(to_char(numero_acc),5,'0')
              numero_acc
         into w_acc_contabile
         from DATI_CONTABILI
        where tipo_tributo             = p_tipo_tributo
          and anno                     = p_anno
          and tipo_imposta             = p_tipo_imposta
          and nvl(tipo_pratica,'*')    = nvl(p_tipo_pratica,'*')
          and nvl(p_data_emissione,trunc(sysdate))
                                  between nvl(emissione_dal,to_date('01011900','ddmmyyyy'))
                                     and nvl(emissione_al,to_date('31122999','ddmmyyyy'))
          and tributo                  is null
          and nvl(cod_tributo_f24,'*') = nvl(p_cod_tributo_f24,'*')
          and (nvl(descrizione_titr,f_descrizione_titr(tipo_tributo,anno)) = f_descrizione_titr(p_tipo_tributo,p_anno) or
               descrizione_titr         = 'TEFA')
          and nvl(stato_pratica,'**')  = nvl(p_stato_pratica,'**')
          and ((tipo_occupazione is null) or
               (tipo_occupazione = nvl(w_tipo_occupazione,'P')))
          and (p_data_ripartizione is null or
              (p_data_ripartizione is not null and
               p_data_ripartizione between nvl(ripartizione_dal,to_date('01011900','ddmmyyyy'))
                                       and nvl(ripartizione_al,to_date('31122999','ddmmyyyy'))))
          and ((p_cod_ente_comunale is null and cod_ente_comunale is null) or
               (cod_ente_comunale = p_cod_ente_comunale))
              --tributo,
       ;
     exception
       when others then
         w_acc_contabile := null;
     end;
  end if;
  --
  -- Se la ricerca per tipo pratica null e codice tributo è fallita,
  -- si ricerca con codice tributo F24 null
  if w_acc_contabile is null then
     begin
       select lpad(to_char(anno_acc),4,'0')||'/'||
--              lpad(to_char(numero_acc),5,'0')
              numero_acc
         into w_acc_contabile
         from DATI_CONTABILI
        where tipo_tributo             = p_tipo_tributo
          and anno                     = p_anno
          and tipo_imposta             = p_tipo_imposta
          and nvl(tipo_pratica,'*')    = nvl(p_tipo_pratica,'*')
          and nvl(p_data_emissione,trunc(sysdate))
                                  between nvl(emissione_dal,to_date('01011900','ddmmyyyy'))
                                     and nvl(emissione_al,to_date('31122999','ddmmyyyy'))
          and nvl(tributo,-1)          = nvl(p_tributo,-1)
          and cod_tributo_f24          is null
          and (nvl(descrizione_titr,f_descrizione_titr(tipo_tributo,anno)) = f_descrizione_titr(p_tipo_tributo,p_anno) or
               descrizione_titr         = 'TEFA')
          and nvl(stato_pratica,'**')  = nvl(p_stato_pratica,'**')
          and ((tipo_occupazione is null) or
               (tipo_occupazione = nvl(w_tipo_occupazione,'P')))
          and (p_data_ripartizione is null or
              (p_data_ripartizione is not null and
               p_data_ripartizione between nvl(ripartizione_dal,to_date('01011900','ddmmyyyy'))
                                       and nvl(ripartizione_al,to_date('31122999','ddmmyyyy'))))
          and ((p_cod_ente_comunale is null and cod_ente_comunale is null) or
               (cod_ente_comunale = p_cod_ente_comunale))
              --tributo,
       ;
     exception
       when others then
         w_acc_contabile := null;
     end;
  end if;
  --
  -- Se la ricerca per tipo pratica null e codice tributo è fallita,
  -- si ricerca con tributo e codice tributo F24 nulli
  if w_acc_contabile is null then
     begin
       select lpad(to_char(anno_acc),4,'0')||'/'||
--              lpad(to_char(numero_acc),5,'0')
              numero_acc
         into w_acc_contabile
         from DATI_CONTABILI
        where tipo_tributo             = p_tipo_tributo
          and anno                     = p_anno
          and tipo_imposta             = p_tipo_imposta
          and nvl(tipo_pratica,'*')    = nvl(p_tipo_pratica,'*')
          and nvl(p_data_emissione,trunc(sysdate))
                                  between nvl(emissione_dal,to_date('01011900','ddmmyyyy'))
                                     and nvl(emissione_al,to_date('31122999','ddmmyyyy'))
          and tributo                  is null
          and cod_tributo_f24          is null
          and (nvl(descrizione_titr,f_descrizione_titr(tipo_tributo,anno)) = f_descrizione_titr(p_tipo_tributo,p_anno) or
               descrizione_titr         = 'TEFA')
          and nvl(stato_pratica,'**')  = nvl(p_stato_pratica,'**')
          and ((tipo_occupazione is null) or
               (tipo_occupazione = nvl(w_tipo_occupazione,'P')))
          and (p_data_ripartizione is null or
              (p_data_ripartizione is not null and
               p_data_ripartizione between nvl(ripartizione_dal,to_date('01011900','ddmmyyyy'))
                                       and nvl(ripartizione_al,to_date('31122999','ddmmyyyy'))))
          and ((p_cod_ente_comunale is null and cod_ente_comunale is null) or
               (cod_ente_comunale = p_cod_ente_comunale))
              --tributo,
       ;
     exception
       when others then
         w_acc_contabile := null;
     end;
  end if;
  --
  return w_acc_contabile;
--
end;
--------------------------------------------------------------------------------------------------------
function f_get_capitolo
/******************************************************************************
 NOME:        f_get_capitolo
 DESCRIZIONE: Restituisce capitolo e articolo abbinati all'accertamento
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   23/07/2021  VD      Prima emissione.
******************************************************************************/
( p_anno                   number
, p_anno_acc               number
, p_numero_acc             number
) return varchar2
is
  w_capitolo               varchar2(18) := null;
begin
  begin
    select lpad(capitolo,16,'0')||lpad(articolo,2,'0')
      into w_capitolo
      from CFA_ACC_TRIBUTI
     where anno_acc = p_anno_acc
       and numero_acc = p_numero_acc
       and esercizio = p_anno;
  exception
    when others then
      w_capitolo := null;
  end;
--
  return w_capitolo;
--
end;
--------------------------------------------------------------------------------------------------------
function f_get_bilancio
/******************************************************************************
 NOME:        F_GET_BILANCIO
 DESCRIZIONE: Restituisce il valore da inserire nel campo BILANCIO
              della tabella DEPAG_DOVUTI (capitolo/articolo).
              Caso di emissione depag per imposta: c'è un solo valore.
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   15/09/2021  VD      Prima emissione.
******************************************************************************/
( p_capitolo               varchar2
, p_acc_contabile          varchar2
, p_importo                number
) return varchar2
is
  w_bilancio               varchar2(4000);
begin
  -- Composizione campo "bilancio" da memorizzare in depag_dovuti
  w_bilancio := '9|'||ltrim(substr(p_capitolo,1,16),'0')||'/'||
                ltrim(substr(p_capitolo,17,1),'0')||substr(p_capitolo,18)||'|'||
                ltrim(substr(p_acc_contabile,1,4),'0')||'/'||
                ltrim(substr(p_acc_contabile,6),'0')||'|'||
                replace(to_char(p_importo),',','.');
  return w_bilancio;
end;
--------------------------------------------------------------------------------------------------------
function f_get_dati_riscossione
/******************************************************************************
 NOME:        F_GET_DATI_RISCOSSIONE
 DESCRIZIONE: Restituisce il valore da inserire nel campo DATI_RISCOSSIONE
              della tabella DEPAG_DOVUTI (capitolo/articolo).
              Se per il pagamento ci sono più capitoli/articoli diversi oppure
              uno o più dei capitoli/articoli determinati sono nulli, restituisce
              null.
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   16/03/2023  AB      Prima emissione.
******************************************************************************/
( p_capitolo               varchar2
) return varchar2
is
  w_dati_riscossione       varchar2(18);
begin
  -- Composizione campo "Dati_riscossione" da memorizzare in depag_dovuti
  if p_capitolo is null then
     w_dati_riscossione := null;
  elsif substr(p_capitolo,1,2) = '9/' then
     w_dati_riscossione := w_dati_riscossione;
  else
     w_dati_riscossione := '9/'||ltrim(substr(p_capitolo,1,16),'0')||'/'||
                           ltrim(substr(p_capitolo,17,1),'0')||substr(p_capitolo,18);
  end if;
  return w_dati_riscossione;
end;
--------------------------------------------------------------------------------------------------------
function f_get_dati_riscossione_old
/******************************************************************************
 NOME:        F_GET_DATI_RISCOSSIONE
 DESCRIZIONE: Restituisce il valore da inserire nel campo DATI_RISCOSSIONE
              della tabella DEPAG_DOVUTI (capitolo/articolo).
              Se per il pagamento ci sono più capitoli/articoli diversi oppure
              uno o più dei capitoli/articoli determinati sono nulli, restituisce
              null.
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   23/07/2021  VD      Prima emissione.
******************************************************************************/
( p_pratica                number
) return varchar2
is
  w_capitolo               varchar2(18);
  w_capitolo_prec          varchar2(18);
  w_conta_cap              number;
begin
  w_capitolo := null;
  w_capitolo_prec := null;
  w_conta_cap := 0;
  for dett in (select sanz.tributo
                    , sanz.cod_tributo_f24
                    , prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , decode(sanz.tipo_causale
                                                                    ,'E','O','V')
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , sanz.cod_tributo_f24
                                                            , prtr.stato_accertamento
                                                            ) acc_contabile
                 from pratiche_tributo prtr
                    , sanzioni_pratica sapr
                    , sanzioni         sanz
                where prtr.pratica = p_pratica
                  and prtr.pratica = sapr.pratica
                  and sapr.cod_sanzione  = sanz.cod_sanzione
                  and sapr.sequenza_sanz = sanz.sequenza
                  and prtr.tipo_tributo  = sanz.tipo_tributo
                group by sanz.tributo, sanz.cod_tributo_f24
                       , prtr.tipo_tributo, prtr.anno
                       , prtr.tipo_pratica, prtr.data )
  loop
    w_conta_cap := w_conta_cap + 1;
    if dett.acc_contabile is null then
       w_capitolo := null;
    else
       w_capitolo  := dati_contabili_pkg.f_get_capitolo( dett.anno
                                                       , to_number(substr(dett.acc_contabile,1,4))
                                                       , to_number(substr(dett.acc_contabile,6,5))
                                                       );
    end if;
    if w_capitolo is null then
       exit;
    end if;
    if w_conta_cap = 1 then
       w_capitolo_prec := w_capitolo;
    else
       if w_capitolo <> w_capitolo_prec then
          w_capitolo := null;
          exit;
       end if;
    end if;
  end loop;
--
  if w_capitolo is not null then
     w_capitolo := '9'||ltrim(substr(w_capitolo,1,16),'0');
  end if;
--
  return w_capitolo;
--
end;
--------------------------------------------------------------------------------------------------------
function f_get_accertamento
/******************************************************************************
 NOME:        F_GET_ACCERTAMENTO
 DESCRIZIONE: Restituisce il valore da inserire nel campo ACCERTAMENTO della
              tabella DEPAG_DOVUTI.
              Se per il pagamento sono previsti accertamenti diversi oppure
              uno o più degli accertamenti determinati sono nulli, restituisce
              null.
 ANNOTAZIONI:
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/05/2022  RV      #70776
                           Aggiunto gestione tipo_occupazione
 000   23/07/2021  VD      Prima emissione.
******************************************************************************/
( p_pratica                number
) return varchar2
is
  w_accertamento           varchar2(10) := null;
  w_accertamento_prec      varchar2(10);
  w_conta_acc              number;
begin
  w_accertamento := null;
  w_accertamento_prec := null;
  w_conta_acc := 0;
  for dett in (select sanz.tributo
                    , sanz.cod_tributo_f24
                    , prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , decode(sanz.tipo_causale
                                                                    ,'E','O','V')
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , sanz.cod_tributo_f24
                                                            , prtr.stato_accertamento
                                                            , f_get_tipo_occupazione(prtr.pratica)
                                                            ) acc_contabile
                 from pratiche_tributo prtr
                    , sanzioni_pratica sapr
                    , sanzioni         sanz
                where prtr.pratica = p_pratica
                  and prtr.pratica = sapr.pratica
                  and sapr.cod_sanzione  = sanz.cod_sanzione
                  and sapr.sequenza_sanz = sanz.sequenza
                  and prtr.tipo_tributo  = sanz.tipo_tributo
                group by sanz.tributo, sanz.cod_tributo_f24
                       , prtr.tipo_tributo, prtr.anno
                       , prtr.tipo_pratica, prtr.data
                       , sanz.tipo_causale
                       , prtr.stato_accertamento )
  loop
    w_conta_acc := w_conta_acc + 1;
    if dett.acc_contabile is null then
       w_accertamento := null;
       exit;
    end if;
    if w_conta_acc = 1 then
       w_accertamento_prec := w_accertamento;
    else
       if w_accertamento <> w_accertamento_prec then
          w_accertamento := null;
          exit;
       end if;
    end if;
  end loop;
--
  return w_accertamento;
--
end;
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
 000   21/05/2024  RV      Prima emissione.
*************************************************************************/
 w_tipo_occupazione        varchar2(1);
begin
  begin
    select min(ogpr.tipo_occupazione)
      into w_tipo_occupazione
      from pratiche_tributo prtr,
           oggetti_pratica ogpr
     where prtr.pratica = p_pratica
       and prtr.pratica = ogpr.pratica;
  exception
    when others then
      w_tipo_occupazione := ' ';
  end;
  return nvl(w_tipo_occupazione,' ');
end;
--------------------------------------------------------------------------------------------------------
procedure dati_contabili_imposta
/******************************************************************************
 NOME:        DATI_CONTABILI_IMPOSTA
 DESCRIZIONE: Valorizza i dati della contabilita finanziaria da registrare in
              DEPAG_DOVUTI per l'imposta da versare.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   20/05/2024  RV      #70776
                           Modificato Group BY non corretto
 000   15/09/2021  VD      Prima emissione.
******************************************************************************/
( p_tipo_tributo           varchar2
, p_anno                   number
, p_tipo_imposta           varchar2
, p_tipo_pratica           varchar2
, p_data_emissione         date
, p_cod_tributo_f24        varchar2
, p_stato_pratica          varchar2
, p_importo                number
, p_dati_riscossione       IN OUT varchar2
, p_accertamento           IN OUT varchar2
, p_bilancio               IN OUT varchar2
) is
  w_acc_contabile          varchar2(10) := null;
  w_capitolo               varchar2(18);
  w_bilancio               varchar2(4000);
  w_dati_riscossione       varchar2(200);
begin
  -- Determinazione accertamento contabile abbinato all'imposta
  -- (da memorizzare nel campo "accertamento" di depag_dovuti)
  w_acc_contabile := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                           , p_anno
                                                           , p_tipo_imposta
                                                           , p_tipo_pratica
                                                           , p_data_emissione
                                                           , p_cod_tributo_f24
                                                           , p_stato_pratica
                                                           );
  -- Determinazione capitolo abbinato all'accertamento contabile
  -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
  if w_acc_contabile is not null then
     w_capitolo  := dati_contabili_pkg.f_get_capitolo( p_anno
                                                     , to_number(substr(w_acc_contabile,1,4))
                                                     , to_number(substr(w_acc_contabile,6))
                                                     );
  end if;
  -- Composizione campo "bilancio" e "dati_riscossione" da memorizzare in depag_dovuti
  if w_acc_contabile is not null and
     w_capitolo      is not null then
     w_bilancio := '9|'||ltrim(substr(w_capitolo,1,16),'0')||'/'||
                   ltrim(substr(w_capitolo,17,1),'0')||substr(w_capitolo,18)||'|'||
                   ltrim(substr(w_acc_contabile,1,4),'0')||'/'||
                   ltrim(substr(w_acc_contabile,6),'0')||'|'||
                   replace(to_char(p_importo),',','.');
     w_dati_riscossione := '9/'||ltrim(substr(w_capitolo,1,16),'0')||'/'||
                           ltrim(substr(w_capitolo,17,1),'0')||substr(w_capitolo,18);
  end if;
  --
  p_dati_riscossione := w_dati_riscossione;
  p_accertamento := w_acc_contabile;
  p_bilancio := w_bilancio;
end;
--------------------------------------------------------------------------------------------------------
procedure dati_contabili_pratica
/******************************************************************************
 NOME:        DATI_CONTABILI_PRATICA
 DESCRIZIONE: Valorizza i dati della contabilita finanziaria da registrare in
              DEPAG_DOVUTI per le pratiche di violazione.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 003   21/05/2023  RV      #70776
                           Aggiunto gestione tipo_occupazione
 002   05/06/2023  AB      #60533 Sostituito l'anno di prtr con quello della sysdate
                           e tolto il controllo di p_rata = 0 nella prima condizione
                           di dati_contabili_pratica
 001   20/05/2022  VD      Modificata selezione importi per pratiche rateizzate
                           aggiunti aggio (quota capitale) e dilazione (quota
                           interessi).
 000   27/07/2021  VD      Prima emissione.
******************************************************************************/
( p_pratica                number
, p_rata                   number
, p_importo                number
, p_dati_riscossione       IN OUT varchar2
, p_accertamento           IN OUT varchar2
, p_bilancio               IN OUT varchar2
) is
  w_capitolo               varchar2(18);
  w_capitolo_prec          varchar2(18);
  w_accertamento           varchar2(10);
  w_accertamento_prec      varchar2(10);
  w_bilancio               varchar2(4000);
  w_dati_riscossione       varchar2(200);
  w_conta_cap              number;
  w_conta_acc              number;
  w_flag_cap               number;
  w_flag_acc               number;
  w_flag_null              number;
  w_importo_tot            number;
  w_ultimo_importo         number;
begin
  w_conta_cap := 0;
  w_conta_acc := 0;
  w_flag_cap := 0;
  w_flag_acc := 0;
  w_flag_null := 0;
  w_importo_tot := 0;
  -- Si selezionano gli importi della pratica suddivisi per accertamento contabile
  for dett in (select to_char(sysdate,'yyyy') anno--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                        --  , decode(prtr.tipo_pratica
                                                        --          , 'V'
                                                                    , decode(sanz.tipo_causale,'E','O','V')  -- #71976
                                                        --          , 'V'
                                                        --          )
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , sanz.cod_tributo_f24
                                                            , prtr.stato_accertamento
                                                            , to_date(null)
                                                            , sanz.tributo
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            ) acc_contabile
                    , sum(f_round((nvl(sapr.importo,0) * (100 - nvl(sapr.riduzione,0)) /100),0)) importo
                 from pratiche_tributo prtr
                    , sanzioni_pratica sapr
                    , sanzioni         sanz
                where prtr.pratica = p_pratica
                  and prtr.pratica = sapr.pratica
                  and sapr.cod_sanzione  = sanz.cod_sanzione
                  and sapr.sequenza_sanz = sanz.sequenza
                  and prtr.tipo_tributo  = sanz.tipo_tributo
                  and nvl(prtr.tipo_atto,-1) <> 90
--                  and p_rata = 0   AB 06/05/2023 verificato a Belluno
                group by to_char(sysdate,'yyyy')--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                       --   , decode(prtr.tipo_pratica
                                                       --           , 'V'
                                                                    , decode(sanz.tipo_causale,'E','O','V')  -- #71976
                                                       --           , 'V'
                                                       --           )
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , sanz.cod_tributo_f24
                                                            , prtr.stato_accertamento
                                                            , to_date(null)
                                                            , sanz.tributo
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            )
                union
               select to_char(sysdate,'yyyy')--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , 'V'
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , rapr.tributo_capitale_f24
                                                            , prtr.stato_accertamento
                                                            , null
                                                            , null
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            ) acc_contabile
                    , sum(rapr.importo_capitale + nvl(oneri,0) +
                          nvl(rapr.aggio_rimodulato,rapr.aggio)
                         ) importo
                 from pratiche_tributo prtr
                    , rate_pratica     rapr
                where prtr.pratica = p_pratica
                  and prtr.pratica = rapr.pratica
                  and nvl(prtr.tipo_atto,-1) = 90
                  and rapr.rata = p_rata
                group by to_char(sysdate,'yyyy')--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , 'V'
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , rapr.tributo_capitale_f24
                                                            , prtr.stato_accertamento
                                                            , null
                                                            , null
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            )
                union
               select to_char(sysdate,'yyyy')--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , 'V'
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , rapr.tributo_interessi_f24
                                                            , prtr.stato_accertamento
                                                            , null
                                                            , null
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            ) acc_contabile
                    , sum(rapr.importo_interessi +
                          nvl(rapr.dilazione_rimodulata,rapr.dilazione)
                         ) importo
                 from pratiche_tributo prtr
                    , rate_pratica     rapr
                where prtr.pratica = p_pratica
                  and prtr.pratica = rapr.pratica
                  and nvl(prtr.tipo_atto,-1) = 90
                  and rapr.rata = p_rata
                group by to_char(sysdate,'yyyy')--prtr.anno
                    , dati_contabili_pkg.f_get_acc_contabile( prtr.tipo_tributo
                                                            , prtr.anno
                                                            , 'V'
                                                            , prtr.tipo_pratica
                                                            , prtr.data
                                                            , rapr.tributo_interessi_f24
                                                            , prtr.stato_accertamento
                                                            , null
                                                            , null
                                                            , dati_contabili_pkg.f_get_tipo_occupazione(prtr.pratica)
                                                            )
                order by 2
              )
  loop
    w_importo_tot    := w_importo_tot + dett.importo;
    w_ultimo_importo := dett.importo;
    if dett.acc_contabile is null then
       w_flag_acc    := 1;
       w_flag_cap    := 1;
       w_flag_null   := 1;
    else
       w_conta_acc    := w_conta_acc + 1;
       w_accertamento := dett.acc_contabile;
       w_capitolo     := dati_contabili_pkg.f_get_capitolo( dett.anno
                                                          , to_number(substr(w_accertamento,1,4))
                                                          , to_number(substr(w_accertamento,6,5))
                                                          );
       if w_capitolo is null then
          w_flag_cap := 1;
          w_flag_null := 1;
       else
          w_conta_cap := w_conta_cap + 1;
          if w_conta_cap = 1 then
             w_capitolo_prec := w_capitolo;
          else
             if w_capitolo <> w_capitolo_prec then
                w_flag_cap := 1;
             end if;
          end if;
          if w_bilancio is not null then
             w_bilancio := w_bilancio||'#';
          end if;
          w_bilancio := w_bilancio||'9|'||ltrim(substr(w_capitolo,1,16),'0')||'/'||
                        ltrim(substr(w_capitolo,17,1),'0')||substr(w_capitolo,18)||'|'||
                        ltrim(substr(w_accertamento,1,4),'0')||'/'||
                        ltrim(substr(w_accertamento,6),'0')||'|'||
                        replace(to_char(dett.importo),',','.');
       end if;
       if w_conta_acc = 1 then
          w_accertamento_prec := w_accertamento;
       else
          if w_accertamento <> w_accertamento_prec then
             w_flag_acc := 1;
          end if;
       end if;
    end if;
  end loop;
  --
  if w_flag_cap = 1 then
     p_dati_riscossione := null;
  else
     w_dati_riscossione := '9/'||ltrim(substr(w_capitolo,1,16),'0')||'/'||
                           ltrim(substr(w_capitolo,17,1),'0')||substr(w_capitolo,18);
     p_dati_riscossione := w_dati_riscossione;
  end if;
  --
  if w_flag_acc = 1 then
     p_accertamento := null;
  else
     p_accertamento := w_accertamento;
  end if;
  --
  if w_flag_null = 1 then
     p_bilancio := null;
  else
     if w_importo_tot <> p_importo then
        w_ultimo_importo := w_ultimo_importo + (p_importo - w_importo_tot);
        w_bilancio := substr(w_bilancio,1,instr(w_bilancio,'|',-1))||
                      replace(to_char(w_ultimo_importo),',','.');
     end if;
     p_bilancio := w_bilancio;
  end if;
end;
end DATI_CONTABILI_PKG;
/
