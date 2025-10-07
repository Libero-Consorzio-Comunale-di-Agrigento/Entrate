--liquibase formatted sql 
--changeset abrandolini:20250326_152429_inserimento_rendite_pkg stripComments:false runOnChange:true 
 
create or replace package INSERIMENTO_RENDITE_PKG is
/******************************************************************************
 NOME:        INSERIMENTO_RENDITE
 DESCRIZIONE: Procedure e Funzioni per inserimento rendite e redditi dominicali
              presenti nei dati catastali.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   24/01/2020  VD      Prima emissione.
 *****************************************************************************/
  -- Revisione del Package
  s_revisione constant afc.t_revision := 'V1.01';
  function F_RICERCA_RIOG
  ( a_oggetto                   number
  , a_data_inizio               date
  , a_data_fine                 date
  ) return number;
  function F_RICERCA_OGGETTO
  ( a_tipo_immobile             varchar2
  , a_sezione                   varchar2
  , a_foglio                    varchar2
  , a_numero                    varchar2
  , a_subalterno                varchar2
  ) return number;
  function F_CONTROLLO_RIOG
  ( a_id_immobile               number
  , a_tipo_immobile             varchar2
  , a_oggetto                   number default null
  ) return number;
  procedure RICERCA_COD_VIA
  ( a_id_immobile            number
  , a_cod_via         in out number
  , a_indirizzo       in out varchar2
  , a_num_civ         in out number
  , a_suffisso        in out varchar2
  ) ;
  procedure TRATTAMENTO_OGGETTO
  ( a_id_immobile            number
  , a_messaggio       in out varchar2
  );
  procedure AGGIORNAMENTO_OGGETTO
  ( a_messaggio       in out varchar2
  );
  procedure TRATTAMENTO_RENDITE
  ( a_oggetto                number
  , a_messaggio       in out varchar2
  );
  procedure INS_RENDITE_FABBRICATO
  ( a_id_immobile            number
  , a_messaggio       in out varchar2
  );
  procedure INS_REDDITI_TERRENO
  ( a_id_immobile            number
  , a_messaggio       in out varchar2
  );
  procedure INSERIMENTO_RENDITE
  ( a_id_immobile            number
  , a_tipo_immobile          varchar2
  , a_data_cessazione        date
  , a_flag_cessati           varchar2
  , a_utente                 varchar2
  , a_oggetto                number default null
  , a_messaggio       in out varchar2
  );
end INSERIMENTO_RENDITE_PKG;
/

create or replace package body INSERIMENTO_RENDITE_PKG is
/******************************************************************************
  NOME:        INSERIMENTO_RENDITE_PKG.
  DESCRIZIONE: Procedure e Funzioni per inserimento rendite e redditi dominicali
               presenti nei dati catastali.
  ANNOTAZIONI: .
  REVISIONI: .
  Rev.  Data        Autore  Descrizione.
  00    24/01/2020  VD      Prima emissione.
  01    16/07/2020  VD      Modifiche per nuova struttura tabella
                            CC_IDENTIFICATIVI
******************************************************************************/
  s_revisione_body   constant afc.t_revision := '001';
  p_tipo_immobile                  varchar2(1);
  p_data_cessazione                date;
  p_utente                         varchar2(8);
  p_fonte                          number;
  p_messaggio                      varchar2(32767);
  p_errore                         varchar2(32767);
  errore                           exception;
  -- Dati per inserimento tabella OGGETTI
  p_oggetto                        oggetti.oggetto%type;
  p_data_cessazione_ogge           oggetti.data_cessazione%type;
  p_sezione                        oggetti.sezione%type;
  p_foglio                         oggetti.foglio%type;
  p_numero                         oggetti.numero%type;
  p_subalterno                     oggetti.subalterno%type;
  p_estremi_catasto                oggetti.estremi_catasto%type;
  p_indirizzo_localita             varchar2(100);
  p_cod_via                        oggetti.cod_via%type;
  p_num_civ                        oggetti.num_civ%type;
  p_suffisso                       oggetti.suffisso%type;
  -- Dati specifici dei fabbricati
  p_categoria_catasto              oggetti.categoria_catasto%type;
  p_classe_catasto                 oggetti.classe_catasto%type;
  p_rendita                        number;
  -- Dati specifici dei terreni
  p_tipo_qualita                   oggetti.tipo_qualita%type;
  p_qualita                        oggetti.qualita%type;
  p_classe                         oggetti.classe_catasto%type;
  p_ettari                         oggetti.ettari%type;
  p_are                            oggetti.are%type;
  p_centiare                       oggetti.centiare%type;
  p_reddito                        number;
  -- per categoria catasto fabbricati
  type type_cat_cat  is table of riferimenti_oggetto.categoria_catasto%type index by binary_integer;
  t_cat_catasto         type_cat_cat;
  -- per classe catasto fabbricati o classe terreni
  type type_cla_cat  is table of riferimenti_oggetto.classe_catasto%type index by binary_integer;
  t_cla_catasto         type_cla_cat;
  -- per data inizio validita rendita fabbricati o reddito terreni
  type type_data_da  is table of date index by binary_integer;
  t_data_da             type_data_da;
  -- per data fine validita rendita fabbricati o reddito terreni
  type type_data_a   is table of date index by binary_integer;
  t_data_a              type_data_a;
  -- per data registrazione atti rendita fabbricati o reddito terreni
  type type_data_reg is table of date index by binary_integer;
  t_data_reg            type_data_reg;
  -- per rendita fabbricati o reddito dominicale terreni
  type type_rendita  is table of riferimenti_oggetto.rendita%type index by binary_integer;
  t_rendita             type_rendita;
  p_ind                 number;
  -- (VD - 16/07/2020): Modificato cursore per nuova struttura tabella
  --                    CC_IDENTIFICATIVI
  -- Cursore per estremi catastali fabbricati
  cursor sel_catasto_fabb (c_id_immobile number) is
  select rtrim(ltrim(ltrim(sezione,'0'))) sezione  --'0' sezione, --
       , substr(rtrim(ltrim(ltrim(foglio,'0'))),1,5) foglio
       , substr(rtrim(ltrim(ltrim(numero,'0'))),1,5) numero
       , rtrim(ltrim(ltrim(subalterno,'0'))) subalterno
       , estremi_catasto
    from cc_identificativi
   where id_immobile = c_id_immobile
     and trim(estremi_catasto) is not null;
/*cursor sel_catasto_fabb (c_id_immobile number, c_indice number) is
  select distinct
         rtrim(ltrim(ltrim(decode(c_indice,1,sezione_1
                                          ,2,sezione_2
                                          ,3,sezione_3
                                          ,4,sezione_4
                                          ,5,sezione_5
                                          ,6,sezione_6
                                          ,7,sezione_7
                                          ,8,sezione_8
                                          ,9,sezione_9
                                            ,sezione_10
                                 )
                          ,'0'))) sezione
       , substr(rtrim(ltrim(ltrim(decode(c_indice,1,foglio_1
                                                 ,2,foglio_2
                                                 ,3,foglio_3
                                                 ,4,foglio_4
                                                 ,5,foglio_5
                                                 ,6,foglio_6
                                                 ,7,foglio_7
                                                 ,8,foglio_8
                                                 ,9,foglio_9
                                                   ,foglio_10
                                        )
                                 ,'0')))
               ,1,5) foglio
       , substr(rtrim(ltrim(ltrim(decode(c_indice,1,numero_1
                                                 ,2,numero_2
                                                 ,3,numero_3
                                                 ,4,numero_4
                                                 ,5,numero_5
                                                 ,6,numero_6
                                                 ,7,numero_7
                                                 ,8,numero_8
                                                 ,9,numero_9
                                                   ,numero_10
                                        )
                                 ,'0')))
               ,1,5) numero
       , rtrim(ltrim(ltrim(decode(c_indice,1,subalterno_1
                                          ,2,subalterno_2
                                          ,3,subalterno_3
                                          ,4,subalterno_4
                                          ,5,subalterno_5
                                          ,6,subalterno_6
                                          ,7,subalterno_7
                                          ,8,subalterno_8
                                          ,9,subalterno_9
                                            ,subalterno_10
                                 )
                          ,'0'))) subalterno
    from cc_identificativi
   where id_immobile = c_id_immobile
     and trim(decode(c_indice,1,estremi_catasto
                             ,2,estremi_catasto_2
                             ,3,estremi_catasto_3
                             ,4,estremi_catasto_4
                             ,5,estremi_catasto_5
                             ,6,estremi_catasto_6
                             ,7,estremi_catasto_7
                             ,8,estremi_catasto_8
                             ,9,estremi_catasto_9
                               ,estremi_catasto_10
                    )) is not null;*/
-- Cursore per oggetti con estremi catastali uguali
  cursor sel_oggetti_catasto ( c_tipo_immobile   varchar2
                             , c_estremi_catasto varchar2
                             --, c_sezione       varchar2
                             --, c_foglio        varchar2
                             --, c_numero        varchar2
                             --, c_subalterno    varchar2
                             )
  is
  select oggetto
       , data_cessazione
    from oggetti
   where tipo_oggetto     = decode(c_tipo_immobile,'T',1,3)
     and estremi_catasto  = c_estremi_catasto
     --and nvl(sezione,'*') = nvl(c_sezione,'*')
     --and foglio           = c_foglio
     --and numero           = c_numero
     --and subalterno       = c_subalterno
   order by oggetto;
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
function F_RICERCA_RIOG
/******************************************************************************
  NOME:        F_RICERCA_RIOG
  DESCRIZIONE: Dato un oggetto e un periodo, si ricercano eventuali
               periodi di riferimenti_oggetto che si intersecano con
               il periodo indicato
  RITORNA:     NUMBER         0 - Non ci sono periodi intersecanti
                              1 - Ci sono periodi intersencanti
                              2 - Non ci sono dati catastali
  NOTE:
******************************************************************************/
( a_oggetto                   number
, a_data_inizio               date
, a_data_fine                 date
) return number is
  w_result                    number;
begin
  begin
    select 1
      into w_result
      from dual
     where exists (select 'x'
                     from riferimenti_oggetto riog
                    where riog.oggetto = a_oggetto
                      and riog.inizio_validita <= a_data_fine
                      and riog.fine_validita   >= a_data_inizio);
  exception
    when others then
      w_result := 0;
  end;
  --
  return w_result;
end f_ricerca_riog;
----------------------------------------------------------------------------------
function F_RICERCA_OGGETTO
/******************************************************************************
  NOME:        F_RICERCA_OGGETTO
  DESCRIZIONE: Dati sezione, foglio, numero, subalterno si verifica se esiste
               un oggetto con i dati catastali indicati
  RITORNA:     NUMBER         oggetto
  NOTE:
******************************************************************************/
( a_tipo_immobile             varchar2
, a_sezione                   varchar2
, a_foglio                    varchar2
, a_numero                    varchar2
, a_subalterno                varchar2
) return number is
  w_oggetto                   number;
begin
  begin
    select oggetto
      into w_oggetto
      from oggetti
     where tipo_oggetto        = decode(a_tipo_immobile,'T',1,3)
       and nvl(sezione,'*')    = nvl(a_sezione,'*')
       and foglio              = a_foglio
       and nvl(numero,'0')     = nvl(a_numero,'0')
       and nvl(subalterno,'0') = nvl(a_subalterno,'0')
       and oggetto             = (select max(oggetto)
                                    from oggetti
                                   where tipo_oggetto        = decode(a_tipo_immobile,'T',1,3)
                                     and nvl(sezione,'*')    = nvl(a_sezione,'*')
                                     and foglio              = a_foglio
                                     and nvl(numero,'0')     = nvl(a_numero,'0')
                                     and nvl(subalterno,'0') = nvl(a_subalterno,'0')
                                 )
    ;
  exception
    when others then
      w_oggetto := to_number(null);
  end;
--
  return w_oggetto;
end f_ricerca_oggetto;
----------------------------------------------------------------------------------
function F_CONTROLLO_RIOG
/******************************************************************************
  NOME:        F_CONTROLLO_RIOG
  DESCRIZIONE: Controllo dell'esistenza di riferimenti_oggetto con
               periodi che si intersecano con i dati catastali.
  RITORNA:     NUMBER         0 - Non ci sono periodi intersecanti
                              1 - Ci sono periodi intersencanti
                              2 - Non ci sono dati catastali
  NOTE:
******************************************************************************/
( a_id_immobile            number
, a_tipo_immobile          varchar2
, a_oggetto                number default null
) return number is
  w_data_min               date;
  w_data_max               date;
  w_result                 number;
begin
  -- Si selezionano la minima data inizio e la massima data fine validita' per
  -- rendite/redditi dell'id. immobile
  if a_tipo_immobile = 'F' then
     select min(f_adatta_data(fabb.data_efficacia)) da_data,
            max(nvl(f_adatta_data(fabb.data_efficacia_2),to_date('31129999','ddmmyyyy'))) a_data
       into w_data_min,
            w_data_max
       from cc_fabbricati fabb
      where fabb.id_immobile = a_id_immobile
        and fabb.rendita_euro > 0
        and nvl(fabb.partita,'*') not in ('C','0000000')
        and nvl(f_adatta_data(fabb.data_efficacia),to_date('01011850','ddmmyyyy')) <=
            nvl(f_adatta_data(fabb.data_efficacia_2),to_date('31129999','ddmmyyyy'));
  else
     select min(f_adatta_data(part.data_efficacia)) da_data,
            max(nvl(f_adatta_data(part.data_efficacia_1),to_date('31129999','ddmmyyyy'))) a_data
       into w_data_min,
            w_data_max
       from cc_particelle part
      where part.id_immobile = a_id_immobile
        and part.reddito_dominicale_euro > 0
        and nvl(part.partita,'*') not in ('C','0000000')
        and nvl(f_adatta_data(part.data_efficacia),to_date('01011850','ddmmyyyy')) <=
            nvl(f_adatta_data(part.data_efficacia_1),to_date('31129999','ddmmyyyy'));
  end if;
  --
  -- Se le date selezionate sono nulle, significa che non esistono dati catastali,
  -- quindi la funzione restituisce 2
  --
  if w_data_min is null and
     w_data_max is null then
     return 2;
  end if;
  --
  -- Si esegue il controllo sui riferimenti_oggetto relativi agli oggetti gia'
  -- abbinati all'id. immobile oppure relativi all'oggetto passato
  --
  for ogge in (select oggetto
                 from oggetti
                where id_immobile = a_id_immobile
                  and tipo_oggetto = decode(a_tipo_immobile,'T',1,3)
                  and oggetto = nvl(a_oggetto,oggetto)
                order by oggetto)
  loop
    w_result := inserimento_rendite_pkg.f_ricerca_riog(ogge.oggetto,w_data_min,w_data_max);
    -- Se si trovano periodi intersecati si esce dal loop
    if nvl(w_result,0) = 1 then
       exit;
    end if;
  end loop;
  -- Se non esistono periodi intersecati (o non esistono oggetti abbinati all'id. immobile)
  -- si esegue lo stesso controllo selezionando gli oggetti per estremi catastali
  if nvl(w_result,0) = 0 and a_oggetto is null then
     if a_tipo_immobile = 'F' then
        -- (VD - 16/07/2020): modificata selezione da catasto per estremi catastali
        --                    per nuova struttura tabella CC_IDENTIFICATIVI
        for rec_fab in sel_catasto_fabb(a_id_immobile)
        loop
          for ogge in sel_oggetti_catasto ( a_tipo_immobile
                                          , rec_fab.estremi_catasto
                                          --, rec_fab.sezione
                                          --, rec_fab.foglio
                                          --, rec_fab.numero
                                          --, rec_fab.subalterno
                                          )
          loop
            w_result := inserimento_rendite_pkg.f_ricerca_riog(ogge.oggetto,w_data_min,w_data_max);
            -- Se si trovano periodi intersecati si esce dal loop
            if nvl(w_result,0) = 1 then
               exit;
            end if;
          end loop;
          if w_result = 1 then
             exit;
          end if;
        end loop;
/*        for w_ind in 1..10
        loop
          for rec_fab in sel_catasto_fabb(a_id_immobile,w_ind)
          loop
            for ogge in sel_oggetti_catasto ( a_tipo_immobile
                                            , rec_fab.sezione
                                            , rec_fab.foglio
                                            , rec_fab.numero
                                            , rec_fab.subalterno
                                            )
            loop
              w_result := inserimento_rendite_pkg.f_ricerca_riog(ogge.oggetto,w_data_min,w_data_max);
              -- Se si trovano periodi intersecati si esce dal loop
              if nvl(w_result,0) = 1 then
                 exit;
              end if;
            end loop;
            if w_result = 1 then
               exit;
            end if;
          end loop;
        end loop; */
     else
        select rtrim(ltrim(ltrim(part.sezione_amm,'0'))) sezione,
               substr(rtrim(ltrim(ltrim(part.foglio,'0'))),1,5) foglio,
               substr(rtrim(ltrim(ltrim(part.numero,'0'))),1,5) numero,
               rtrim(ltrim(ltrim(part.subalterno,'0'))) subalterno,
               estremi_catasto
          into p_sezione
             , p_foglio
             , p_numero
             , p_subalterno
             , p_estremi_catasto
          from cc_particelle part
         where part.id_immobile = a_id_immobile
           and part.reddito_dominicale_euro > 0
           and nvl(part.partita,'*') not in ('C','0000000')
           and nvl(f_adatta_data(part.data_efficacia),to_date('01011850','ddmmyyyy')) <
               nvl(f_adatta_data(part.data_efficacia_1),to_date('31129999','ddmmyyyy'))
           and part.progressivo = (select min(parx.progressivo)
                                     from cc_particelle parx
                                    where parx.id_immobile = part.id_immobile
                                      and parx.reddito_dominicale_euro > 0
                                      and nvl(parx.partita,'*') not in ('C','0000000')
                                      and nvl(f_adatta_data(parx.data_efficacia),to_date('01011850','ddmmyyyy')) <
                                          nvl(f_adatta_data(parx.data_efficacia_1),to_date('31129999','ddmmyyyy')));
        --w_oggetto := inserimento_rendite_pkg.f_ricerca_oggetto(a_tipo_immobile,p_sezione,p_foglio,p_numero,p_subalterno);
        for ogge in sel_oggetti_catasto ( a_tipo_immobile
                                        , p_estremi_catasto
                                        --, p_sezione
                                        --, p_foglio
                                        --, p_numero
                                        --, p_subalterno
                                        )
        loop
          w_result := inserimento_rendite_pkg.f_ricerca_riog(ogge.oggetto,w_data_min,w_data_max);
        end loop;
     end if;
  end if;
  return nvl(w_result,0);
end f_controllo_riog;
----------------------------------------------------------------------------------
procedure RICERCA_COD_VIA
/*************************************************************************
  NOME:        RICERCA_COD_VIA
  DESCRIZIONE: Determina l'indirizzo dell'oggetto da caricare.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_id_immobile                    number
, a_cod_via                 in out number
, a_indirizzo               in out varchar2
, a_num_civ                 in out number
, a_suffisso                in out varchar2
) is
  w_indirizzo_localita_1           varchar2(100);
  w_denom_ric                      denominazioni_via.descrizione%type;
begin
  -- Selezione dell'indirizzo abbinato all'id. immobile
  -- (VD - 16/07/2020): aggiornata selezione indirizzo per
  --                    modifiche struttura tabella CC_INDIRIZZI
  begin
    select indirizzo||
           decode(civico1,'','',', '||civico1||
           decode(civico2,civico1,'',
                          '','',
                             '/'||ltrim(civico2,'0'))||
           decode(civico3,civico2,'',
                          civico1,'',
                          '','',
                             '/'||ltrim(civico3,'0')))
      into p_indirizzo_localita
      from cc_indirizzi indi
     where id_immobile   = a_id_immobile
       and tipo_immobile = p_tipo_immobile
       and progressivo   = (select max(progressivo)
                              from cc_indirizzi indx
                             where indx.id_immobile = indi.id_immobile
                               and indx.tipo_immobile = indi.tipo_immobile)
    ;
/*    select indirizzo_1||
           decode(civico1_1,'','',', '||civico1_1||
           decode(civico2_1,civico1_1,'',
                            '','',
                               '/'||ltrim(civico2_1,'0'))||
           decode(civico3_1,civico2_1,'',
                            civico1_1,'',
                            '','',
                               '/'||ltrim(civico3_1,'0')))
      into p_indirizzo_localita
      from cc_indirizzi indi
     where id_immobile   = a_id_immobile
       and tipo_immobile = p_tipo_immobile
       and progressivo   = (select max(progressivo)
                              from cc_indirizzi indx
                             where indx.id_immobile = indi.id_immobile
                               and indx.tipo_immobile = indi.tipo_immobile)
    ;*/
  exception
    when others then
      p_indirizzo_localita := null;
  end;
  --
  -- Sistemazione dati indirizzo
  --
  p_num_civ            := to_number(null);
  p_suffisso           := to_char(null);
  begin
    select cod_via,descrizione,p_indirizzo_localita
      into p_cod_via,w_denom_ric,w_indirizzo_localita_1
      from denominazioni_via devi
     where p_indirizzo_localita like '%'||devi.descrizione||'%'
       and devi.descrizione is not null
       and not exists (select 'x'
                         from denominazioni_via devi1
                        where p_indirizzo_localita
                                like '%'||devi1.descrizione||'%'
                          and devi1.descrizione is not null
                          and devi1.cod_via != devi.cod_via)
       and rownum = 1
   ;
  exception
    when others then
      p_cod_via := 0;
  end;
  -- Se esiste la via in archivio_vie, si sistema l'indirizzo per ricavare il numero civico e il suffisso
  if p_cod_via != 0 then
     begin
       select substr(w_indirizzo_localita_1,
              (instr(w_indirizzo_localita_1,w_denom_ric)
               + length(w_denom_ric)))
         into w_indirizzo_localita_1
         from dual
       ;
     exception
       when no_data_found then
         null;
       when others then
         p_errore := 'Errore in decodifica indirizzo (1) - '||
                     'indir: '||p_indirizzo_localita||
                     ' ('||sqlerrm||')';
     end;
     begin
       select
        substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9'),
         decode(
         sign(4 - (
         length(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
         -
         nvl(
         length(
         ltrim(
         translate(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
         '1234567890','9999999999'),'9')),0))),-1,4,
         length(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
         -
         nvl(
         length(
         ltrim(
         translate(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
         '1234567890','9999999999'),'9')),0))
        ) num_civ,
        ltrim(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')
         +
         length(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')))
         -
         nvl(
         length(
         ltrim(
         translate(
         substr(w_indirizzo_localita_1,
         instr(translate(w_indirizzo_localita_1,'1234567890','9999999999'),'9')),
         '1234567890','9999999999'),'9')),0),
         5),
         ' /'
        ) suffisso
     into p_num_civ,p_suffisso
     from dual
     ;
     exception
       when others then
         p_num_civ  := to_number(null);
         p_suffisso := to_char(null);
     end;
  end if; -- fine controllo cod_via != 0
--
  a_cod_via := p_cod_via;
  if p_cod_via = 0 then
     a_cod_via   := to_number(null);
     a_indirizzo := substr(p_indirizzo_localita,1,36);
     a_num_civ   := to_number(null);
     a_suffisso  := null;
  else
     a_indirizzo := null;
     a_num_civ   := p_num_civ;
     a_suffisso  := p_suffisso;
  end if;
--
end RICERCA_COD_VIA;
----------------------------------------------------------------------------------
procedure RICERCA_QUALITA
/*************************************************************************
  NOME:        RICERCA_QUALITA
  DESCRIZIONE: Verifica se la qualita del terreno e' gia' presente,
               altrimenti la inserisce.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
is
begin
  if p_tipo_qualita is not null then
     -- Si controlla che esista la qualita nella tab tipi_qualita, altrimenti viene inserita
     begin
       select descrizione
         into p_qualita
         from tipi_qualita tiqu
        where tiqu.tipo_qualita = p_tipo_qualita
       ;
     exception
       when no_data_found then
         p_qualita := 'QUALITA'' DA TRASCODIFICA';
         begin
           insert into tipi_qualita
                  (tipo_qualita, descrizione)
           values (p_tipo_qualita, p_qualita)
           ;
         exception
           when others then
             raise_application_error
               (-20999,'Errore in inserimento Tipi Qualita ('||
                       p_tipo_qualita||') - '||sqlerrm);
         end;
       when others then
         raise_application_error
           (-20999,'Errore in ricerca Tipi Qualita ('||
                    p_tipo_qualita||') - '||sqlerrm);
     end;
  else
     p_qualita := null;
  end if;
end ricerca_qualita;
----------------------------------------------------------------------------------
procedure RICERCA_CAT_CATASTO
/*************************************************************************
  NOME:        RICERCA_QUALITA
  DESCRIZIONE: Verifica se la qualita del terreno e' gia' presente,
               altrimenti la inserisce.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
is
  w_controllo                      varchar2(1);
begin
  if p_categoria_catasto is not null then
     -- Si controlla che esista la categoria nella tab categoria_catasto, altrimenti si inserisce
     begin
       select 'x'
         into w_controllo
         from categorie_catasto caca
        where caca.categoria_catasto = p_categoria_catasto
       ;
     exception
       when no_data_found then
       begin
         insert into categorie_catasto
                (categoria_catasto, descrizione)
         values (p_categoria_catasto, 'CATEGORIA DA TRASCODIFICA')
         ;
       exception
         when others then
           raise_application_error
               (-20999,'Inserimento Categorie Catasto ('||
                       p_categoria_catasto||') - '||sqlerrm);
       end;
       when others then
         raise_application_error
             (-20999,'Ricerca Categorie Catasto ('||p_categoria_catasto||
                     ') - '||sqlerrm);
     end;
  end if;
end ricerca_cat_catasto;
----------------------------------------------------------------------------------
procedure TRATTAMENTO_OGGETTO
/*************************************************************************
  NOME:        TRATTAMENTO_OGGETTO
  DESCRIZIONE: Controlla l'esistenza dell'oggetto abbinato ai dati catastali
               e se non esiste lo inserisce.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_id_immobile                    number
, a_messaggio               in out varchar2
) is
  w_conta_oggetti                  number;
  w_oggetto_riog                   number;
  w_ogge_accliq                    number;
  --w_ogge_upd                       number;
begin
  if p_tipo_immobile = 'T' then
     -- Si controllo l'esistenza della qualita per i terreni
     ricerca_qualita;
  else
     -- Si controlla l'esistenza della categoria catasto per i fabbricati
     ricerca_cat_catasto;
  end if;
  -- Si verifica quanti oggetti esistono con gli stessi estremi catastali
  select count(*)
    into w_conta_oggetti
    from oggetti
   where tipo_oggetto        = decode(p_tipo_immobile,'T',1,3)
     and estremi_catasto     = p_estremi_catasto
     --and nvl(sezione,'*')    = nvl(p_sezione,'*')
     --and foglio              = p_foglio
     --and nvl(numero,'0')     = nvl(p_numero,'0')
     --and nvl(subalterno,'0') = nvl(p_subalterno,'0')
  ;
  -- Se non esistono oggetti con gli estremi indicati, se ne inserisce uno,
  -- ma prima si sistema l'eventuale indirizzo
  if w_conta_oggetti = 0 then
     begin
       ricerca_cod_via(a_id_immobile,p_cod_via,p_indirizzo_localita,p_num_civ,p_suffisso);
       oggetti_nr(w_oggetto_riog);
       p_data_cessazione_ogge := to_date(null);
       insert into oggetti
            ( oggetto, tipo_oggetto, indirizzo_localita,
              cod_via, num_civ, suffisso,
              sezione, foglio,
              numero, subalterno,
              partita, categoria_catasto, classe_catasto,
              tipo_qualita, qualita,
              ettari, are, centiare,
              fonte, utente, data_variazione,
              id_immobile)
       values ( w_oggetto_riog, decode(p_tipo_immobile,'T',1,3), p_indirizzo_localita,
                p_cod_via, p_num_civ, p_suffisso,
                p_sezione, p_foglio,
                p_numero, p_subalterno,
                null,
                decode(p_tipo_immobile,'T','T',p_categoria_catasto),
                decode(p_tipo_immobile,'T',p_classe,p_classe_catasto),
                p_tipo_qualita, p_qualita,
                p_ettari, p_are, p_centiare,
                p_fonte, p_utente, trunc(sysdate),
                a_id_immobile)
       ;
     exception
       when others then
         raise_application_error
           (-20999,'Errore in inserimento Oggetti '||
                   'Id_Immobile: '||a_id_immobile||
                   ' ('||sqlerrm||')');
     end;
  end if;
  --dbms_output.put_line('Ho ins ogge: '||w_oggetto);
  -- Se l'oggetto (o gli oggetti) esiste gia',
  -- si controlla che non sia presente in liquidazioni
  if w_conta_oggetti > 0 then
     for ogge in sel_oggetti_catasto ( p_tipo_immobile
                                     , p_estremi_catasto
                                     --, p_sezione
                                     --, p_foglio
                                     --, p_numero
                                     --, p_subalterno
                                     )
     loop
       select count(*)
         into w_ogge_accliq
         from oggetti_pratica ogpr
            , pratiche_tributo prtr
        where ogpr.pratica = prtr.pratica
          and ogpr.oggetto = ogge.oggetto
          and prtr.tipo_pratica in ('A','L')
       ;
       if w_ogge_accliq = 0 then
/*          select count(1)
            into w_ogge_upd
            from oggetti
           where oggetto               = ogge.oggetto
             and data_cessazione       is null
             and decode(p_tipo_immobile,'T',p_qualita,p_classe) is not null
          ;
          if w_ogge_upd = 1 then*/
             begin
               update oggetti
                  set tipo_qualita      = nvl(tipo_qualita,p_tipo_qualita)
                    , qualita           = nvl(qualita,p_qualita)
                    , ettari            = nvl(ettari,p_ettari)
                    , are               = nvl(are,p_are)
                    , centiare          = nvl(centiare,p_centiare)
                    , categoria_catasto = nvl(categoria_catasto,decode(p_tipo_immobile
                                                                      ,'T','T'
                                                                          ,p_categoria_catasto
                                                                      )
                                             )
                    , classe_catasto    = nvl(classe_catasto,decode(p_tipo_immobile
                                                                   ,'T',p_classe
                                                                       ,p_classe_catasto
                                                                   )
                                             )
                    , id_immobile       = nvl(id_immobile,a_id_immobile)
                    , utente            = p_utente
                where oggetto           = ogge.oggetto
                  and data_cessazione   is null
               ;
             exception
               when others then
                 raise_application_error(-20919,'Errore in agg. qualita'' e classe in oggetti '||
                                                ' oggetto '||w_oggetto_riog||
                                                ' ('||sqlerrm||')');
             end;
          --end if; -- w_ogge_upd = 1
       end if; -- w_ogge_accliq = 0
     end loop;
   end if;
  --dbms_output.put_line('Oggetto: '||w_oggetto_riog);
end trattamento_oggetto;
----------------------------------------------------------------------------------
procedure AGGIORNAMENTO_OGGETTO
/*************************************************************************
  NOME:        AGGIORNAMENTO_OGGETTO
  DESCRIZIONE: Se l'oggetto viene passato come parametro, si aggiornano
               gli eventuali dati mancanti (id_immobile, categoria_catasto,
                                            classe_catasto)
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_messaggio               in out varchar2
)is
  w_data_cessazione_ogg            date;
  w_messaggio                      varchar2(2000);
begin
  if p_tipo_immobile = 'T' then
     -- Si controllo l'esistenza della qualita per i terreni
     ricerca_qualita;
  else
     -- Si controlla l'esistenza della categoria catasto per i fabbricati
     ricerca_cat_catasto;
  end if;
  --
  begin
    select data_cessazione
      into w_data_cessazione_ogg
      from oggetti
     where oggetto = p_oggetto;
  exception
    when no_data_found then
      raise_application_error(-20919,'Selezione oggetto '||p_oggetto||
                                     ' ('||sqlerrm||')');
  end;
  if nvl(w_data_cessazione_ogg,to_date('31129999','ddmmyyyy')) >=
     p_data_cessazione then
     trattamento_rendite(p_oggetto,w_messaggio);
     if w_messaggio is not null then
        a_messaggio := w_messaggio;
        -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
        RETURN;
     end if;
     begin
       update oggetti
          set tipo_qualita      = nvl(tipo_qualita,p_tipo_qualita)
            , qualita           = nvl(qualita,p_qualita)
            , ettari            = nvl(ettari,p_ettari)
            , are               = nvl(are,p_are)
            , centiare          = nvl(centiare,p_centiare)
            , categoria_catasto = nvl(categoria_catasto,decode(p_tipo_immobile
                                                              ,'T','T'
                                                                  ,p_categoria_catasto
                                                              )
                                     )
            , classe_catasto    = nvl(classe_catasto,decode(p_tipo_immobile
                                                           ,'T',p_classe
                                                               ,p_classe_catasto
                                                           )
                                     )
            , utente            = p_utente
        where oggetto           = p_oggetto
          and data_cessazione   is null
       ;
     exception
       when others then
         raise_application_error(-20919,'Aggiornamento oggetto '||p_oggetto||
                                        ' ('||sqlerrm||')');
     end;
  end if;
end aggiornamento_oggetto;
----------------------------------------------------------------------------------
procedure INSERT_RIOG
/*************************************************************************
  NOME:        INSERT_RIOG
  DESCRIZIONE: Inserimento riga in tabella RIFERIMENTI_OGGETTO
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_oggetto                        number
, a_inizio_validita                date
, a_fine_validita                  date
, a_da_anno                        number
, a_a_anno                         number
, a_rendita                        number
, a_anno_rendita                   number
, a_categoria_catasto              varchar2
, a_classe_catasto                 varchar2
, a_data_reg                       date
, a_data_reg_atti                  date
, a_messaggio               in out varchar2
) is
begin
  begin
    insert into riferimenti_oggetto
          ( oggetto, inizio_validita, fine_validita
          , da_anno, a_anno, rendita
          , anno_rendita, categoria_catasto, classe_catasto
          , data_reg, data_reg_atti, utente, data_variazione
          , note)
    values ( a_oggetto, a_inizio_validita, a_fine_validita
           , a_da_anno, a_a_anno, a_rendita
           , a_anno_rendita, a_categoria_catasto, a_classe_catasto
           , a_data_reg, a_data_reg_atti, p_utente, trunc(sysdate)
           , 'Caricamento dati catastali del '||to_char(sysdate,'dd/mm/yyyy')||' - Utente '||p_utente)
    ;
  exception
    when others then
      a_messaggio := 'Rendita non aggiornabile automaticamente per la presenza di anomalie in catasto, '||
                     'inserire manualmente il dato';
  end;
end insert_riog;
----------------------------------------------------------------------------------
procedure TRATTAMENTO_RENDITE
/*************************************************************************
  NOME:        TRATTAMENTO_RENDITE
  DESCRIZIONE: Si trattano le rendite o i redditi dominicali memorizzati
               negli array.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_oggetto                        number
, a_messaggio               in out varchar2
) is
  w_conta_riog                     number;
  w_intersecante_2                 number;
  w_inters_no_compl_2              number;
  w_interno_2                      number;
--
  w_inizio_validita                riferimenti_oggetto.inizio_validita%type;
  w_fine_validita                  riferimenti_oggetto.fine_validita%type;
  w_da_anno                        riferimenti_oggetto.da_anno%type;
  w_a_anno                         riferimenti_oggetto.a_anno%type;
  w_rendita                        riferimenti_oggetto.rendita%type;
  w_anno_rendita                   riferimenti_oggetto.anno_rendita%type;
  w_categoria_catasto              riferimenti_oggetto.categoria_catasto%type;
  w_classe_catasto                 riferimenti_oggetto.classe_catasto%type;
  w_data_reg                       riferimenti_oggetto.data_reg%type;
  w_data_reg_atti                  riferimenti_oggetto.data_reg_atti%type;
  w_messaggio                      varchar2(2000);
--
  --w_data_inizio                    date;
  --w_data_fine                      date;
  --w_max_data_fine                  date;
begin
  -- Si controlla quanti riog esistono per l'oggetto
  begin
    select count(1)
      into w_conta_riog
      from riferimenti_oggetto
     where oggetto = a_oggetto
    ;
  end;
  --dbms_output.put_line('Conta riog: '||w_conta_riog);
  --
  if w_conta_riog = 0 then
     for p_ind in t_rendita.first .. t_rendita.last
     loop
       insert_riog ( a_oggetto, t_data_da (p_ind)
                   , least(t_data_a (p_ind),nvl(p_data_cessazione_ogge,to_date('31129999','ddmmyyyy')))
                   , nvl(to_number(to_char(t_data_da (p_ind),'yyyy')),1899)
                   , nvl(to_number(to_char(t_data_a (p_ind),'yyyy')),9999)
                   , t_rendita (p_ind)
                   , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                   , case when p_tipo_immobile = 'T'
                       then to_char(null) -- 'T'
                       else t_cat_catasto (p_ind)
                     end
                   , t_cla_catasto (p_ind)
                   , t_data_reg(p_ind)
                   , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                   , w_messaggio
                   );
        if w_messaggio is not null then
           a_messaggio := w_messaggio;
           -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
           RETURN;
        end if;
     end loop;
  else
     -- salvataggio dei dati del riog in una tabella temporanea di appoggio per eventuale ripristino
     begin
       for rec_ro in (select inizio_validita, fine_validita
                           , da_anno, a_anno
                           , rendita, anno_rendita, categoria_catasto
                           , classe_catasto, data_reg, data_reg_atti
                           , utente, data_variazione, note
                           , p_utente
                       from riferimenti_oggetto
                      where oggetto = a_oggetto)
       loop
         insert into riferimenti_oggetto_bk
                   ( oggetto, inizio_validita
                   , fine_validita, da_anno, a_anno
                   , rendita, anno_rendita, categoria_catasto
                   , classe_catasto, data_reg, data_reg_atti
                   , utente_riog, data_variazione_riog, note_riog
                   , utente, data_ora_variazione)
         values ( a_oggetto, rec_ro.inizio_validita
                , rec_ro.fine_validita, rec_ro.da_anno, rec_ro.a_anno
                , rec_ro.rendita, rec_ro.anno_rendita, rec_ro.categoria_catasto
                , rec_ro.classe_catasto, rec_ro.data_reg, rec_ro.data_reg_atti
                , rec_ro.utente, rec_ro.data_variazione, rec_ro.note
                , p_utente, sysdate )
        ;
       end loop;
     exception
       when others then
           raise_application_error
              (-20999,'Inserimento Riferimenti Oggetto Backup ('||a_oggetto||') - '||
                      sqlerrm);
     end;
     --
     for p_ind in t_rendita.first .. t_rendita.last
     loop
       --dbms_output.put_line('Inizio: '||t_data_da(p_ind));
       --dbms_output.put_line('Fine: '||t_data_a(p_ind));
       --dbms_output.put_line('Rendita: '||t_rendita(p_ind));
       -- Si verifica se esistono riog che si intersecano al dato catastale
       begin
         select count(1)
           into w_intersecante_2
           from riferimenti_oggetto
          where oggetto = a_oggetto
            and inizio_validita <= nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
            and fine_validita   >= t_data_da (p_ind)
         ;
       end;
       --dbms_output.put_line('w_intersecante_2: '||w_intersecante_2);
       -- Si verifica se esistono dei riog che si intersecano al dato catastale, non ricoperti completamente
       begin
         select count(1)
           into w_inters_no_compl_2
           from riferimenti_oggetto
          where oggetto = a_oggetto
            and ( ( inizio_validita between t_data_da (p_ind) and nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                  and fine_validita > nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                  )
               or ( fine_validita   between t_data_da (p_ind) and nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                  and inizio_validita < t_data_da (p_ind)
                  )
                )
         ;
       end;
       --dbms_output.put_line('w_inters_no_compl_2: '||w_inters_no_compl_2);
       if w_intersecante_2 = 0 then
          -- il dato catastale non si sovrappone a nessun riog
          --            |RiOg||RiOg|                  |RiOg||RiOg|
          --    |Cat|                                                |Cat|
          insert_riog ( a_oggetto, t_data_da (p_ind)
                      , least(t_data_a (p_ind),nvl(p_data_cessazione_ogge,to_date('31129999','ddmmyyyy')))
                      , nvl(to_number(to_char(t_data_da (p_ind),'yyyy')),1899)
                      , nvl(to_number(to_char(t_data_a (p_ind),'yyyy')),9999)
                      , t_rendita (p_ind)
                      , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                      , case when p_tipo_immobile = 'T'
                          then to_char(null) -- 'T'
                          else t_cat_catasto (p_ind)
                        end
                      , t_cla_catasto (p_ind)
                      , t_data_reg(p_ind)
                      , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                      , w_messaggio
                      );
          if w_messaggio is not null then
             a_messaggio := w_messaggio;
             -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
             RETURN;
          end if;
          -- w_intersecante_2 = 0
       elsif w_inters_no_compl_2 = 0 then
          -- il dato catastale si sovrappone ai riog ricoprendoli interamente, non esistono riog sovrapposti parzialmente
          --              |RiOg ||RiOg|                 |RiOg||Riog |               |RiOg||RiOg |               |RiOg||RiOg |
          --           |      Cat        |              |    Cat    |            |     Cat      |               |     Cat      |
          -- cancellazione riog sovrapposti completamente
          begin
            delete riferimenti_oggetto
             where oggetto = a_oggetto
               and inizio_validita >= t_data_da (p_ind)
               and fine_validita   <= t_data_a (p_ind)
                  ;
          exception
            when others then
              raise_application_error
                (-20999,'Eliminazione Riferimenti Oggetto ('||a_oggetto||
                        ') - '||sqlerrm);
          end;
          -- inserimento riog da dati catastali
          insert_riog ( a_oggetto, t_data_da (p_ind)
                      , least(t_data_a (p_ind),nvl(p_data_cessazione_ogge,to_date('31129999','ddmmyyyy')))
                      , nvl(to_number(to_char(t_data_da (p_ind),'yyyy')),1899)
                      , nvl(to_number(to_char(t_data_a (p_ind),'yyyy')),9999)
                      , t_rendita (p_ind)
                      , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                      , case when p_tipo_immobile = 'T'
                          then to_char(null) -- 'T'
                          else t_cat_catasto (p_ind)
                        end
                      , t_cla_catasto (p_ind)
                      , t_data_reg(p_ind)
                      , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                      , w_messaggio
                      );
          if w_messaggio is not null then
             a_messaggio := w_messaggio;
             -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
             RETURN;
          end if;
          -- w_inters_no_compl_2 = 0
/*          w_data_inizio := t_data_da (p_ind);
          w_data_fine   := t_data_a (p_ind);
          for riog in (select *
                         from riferimenti_oggetto
                        where oggetto = a_oggetto
                          and inizio_validita >= t_data_da (p_ind)
                          and fine_validita   <= t_data_a (p_ind)
                        order by inizio_validita)
          loop
            if riog.inizio_validita > w_data_inizio then
               insert_riog ( a_oggetto, w_data_inizio
                           , riog.inizio_validita - 1
                           , nvl(to_number(to_char(w_data_inizio,'yyyy')),1899)
                           , nvl(to_number(to_char(riog.inizio_validita - 1,'yyyy')),9999)
                           , t_rendita (p_ind)
                           , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                           , case when p_tipo_immobile = 'T'
                               then 'T'
                               else t_cat_catasto (p_ind)
                             end
                           , case when p_tipo_immobile = 'T'
                               then p_classe
                               else t_cla_catasto (p_ind)
                             end
                           , t_data_reg(p_ind)
                           , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                           , p_messaggio
                           );
            end if;
            w_data_inizio := riog.fine_validita + 1;
            w_max_data_fine := riog.fine_validita;
          end loop;
          if w_max_data_fine < w_fine_validita then
               insert_riog ( a_oggetto, w_max_data_fine + 1
                           , w_fine_validita
                           , nvl(to_number(to_char(w_max_data_fine + 1,'yyyy')),1899)
                           , nvl(to_number(to_char(w_fine_validita,'yyyy')),9999)
                           , t_rendita (p_ind)
                           , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                           , case when p_tipo_immobile = 'T'
                               then 'T'
                               else t_cat_catasto (p_ind)
                             end
                           , case when p_tipo_immobile = 'T'
                               then p_classe
                               else t_cla_catasto (p_ind)
                             end
                           , t_data_reg(p_ind)
                           , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                           , p_messaggio
                           );
          end if; */
       else
          -- w_inters_no_compl_2 > 0   il dato catastale NON si sovrappone ai riog ricoprendoli interamente
          -- Si verifica se esiste un unico riog che interseca il dato catastale sia a sinistra che a destra
          begin
            select count(1)
              into w_interno_2
              from riferimenti_oggetto
             where oggetto = a_oggetto
               and inizio_validita < t_data_da (p_ind)
               and fine_validita   > t_data_a (p_ind)
                 ;
          end;
          --dbms_output.put_line('w_interno_2: '||w_interno_2);
          if w_interno_2 > 0 then
             --dbms_output.put_line('w_interno_2 > 0');
             -- il dato catastale si sovrappone ad un unico riog rimanendone all'interno
             --          |     RiOg       |
             --              | Cat |
             -- estrazione dei dati del riog da sostituire
             begin
               select inizio_validita, fine_validita
                    , da_anno, a_anno, rendita
                    , anno_rendita, categoria_catasto, classe_catasto
                    , data_reg, data_reg_atti
                 into w_inizio_validita, w_fine_validita
                    , w_da_anno, w_a_anno, w_rendita
                    , w_anno_rendita, w_categoria_catasto, w_classe_catasto
                    , w_data_reg, w_data_reg_atti
                 from riferimenti_oggetto
                where oggetto = a_oggetto
                  and inizio_validita < t_data_da (p_ind)
                  and fine_validita   > nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                    ;
             exception
               when others then
                 raise_application_error
                   (-20999,'Errore in estrazione Riferimenti Oggetto (1) '||
                           'Estremi: '||a_oggetto||
                           ' inva '||to_char(t_data_da (p_ind),'dd/mm/yyyy')||
                           ' finva '||to_char(t_data_a (p_ind),'dd/mm/yyyy')||
                           ' ('||SQLERRM||')');
             end;
             --   inserimento riog  (destro)
             insert_riog ( a_oggetto, nvl(t_data_a (p_ind),to_date('30/12/9999','dd/mm/yyyy')) + 1
                         , w_fine_validita
                         , nvl(to_number(to_char(t_data_da (p_ind) + 1,'yyyy')),1899)
                         , w_a_anno
                         , w_rendita, w_anno_rendita
                         , w_categoria_catasto, w_classe_catasto
                         , w_data_reg, w_data_reg_atti
                         , w_messaggio
                         );
             if w_messaggio is not null then
                a_messaggio := w_messaggio;
                -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
                RETURN;
             end if;
             -- modifica riog  (sinistro)
             begin
               update riferimenti_oggetto riog
                  set fine_validita   = t_data_da (p_ind) - 1
                    , a_anno          = to_char(t_data_da (p_ind) - 1,'yyyy')
                    , utente          = p_utente
                where oggetto         = a_oggetto
                  and inizio_validita < t_data_da (p_ind)
                  and fine_validita   > nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                    ;
             exception
               when others then
                 raise_application_error
                   (-20999,'Aggiornamento Riferimenti Oggetto (1) '||
                           'Estremi: '||a_oggetto||
                           ' ('||sqlerrm||')');
             end;
             -- inserimento riog da dati catastali (centrale)
             insert_riog ( a_oggetto, t_data_da (p_ind)
                         , nvl(t_data_a (p_ind),to_date('31129999','ddmmyyyy'))
                         , nvl(to_number(to_char(t_data_da (p_ind) + 1,'yyyy')),1899)
                         , nvl(to_number(to_char(t_data_a (p_ind) + 1,'yyyy')),9999)
                         , t_rendita (p_ind)
                         , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                         , case when p_tipo_immobile = 'T'
                             then to_char(null) -- 'T'
                             else t_cat_catasto (p_ind)
                           end
                         , t_cla_catasto (p_ind)
                         , t_data_reg(p_ind)
                         , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                         , w_messaggio
                         );
             if w_messaggio is not null then
                a_messaggio := w_messaggio;
                -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
                RETURN;
             end if;
          else    -- w_interno_2 = 0   non c'è un solo riog che interseca sia a sinistra che a destra il dato catastale
             --dbms_output.put_line('CASO GENERALE');
             -- CASO GENERALE  --
             -- cancellazione riog sovrapposti completamente
             begin
               delete riferimenti_oggetto
                where oggetto = a_oggetto
                  and inizio_validita >= t_data_da (p_ind)
                  and fine_validita   <= nvl(t_data_a (p_ind),to_date('31/12/9999','dd/mm/yyyy'))
                    ;
             exception
               when others then
                 raise_application_error
                   (-20999,'Eliminazione Riferimenti Oggetto ('||a_oggetto||
                           ') - '||SQLERRM);
             end;
             --   modifica del riog  sovrapposto al margine sinistro del dato catastale (se presente)
             --     |RiOg||Riog|                 |RiOg||Riog|
             --             |Cat |                           |Cat |
             begin
               update riferimenti_oggetto riog
                  set fine_validita   = t_data_da (p_ind) - 1
                    , a_anno          = to_char(t_data_da (p_ind) - 1,'yyyy')
                    , utente          = p_utente
                where oggetto         = a_oggetto
                  and  inizio_validita < t_data_da (p_ind)
                  and  fine_validita   >= t_data_da (p_ind)
                    ;
               --dbms_output.put_line('update riog sinistro');
             exception
               when others then
                 raise_application_error
                   (-20999,'Aggiornamento Riferimenti Oggetto (1) '||
                           'Estremi: '||a_oggetto||
                           ' ('||sqlerrm||')');
             end;
             --   modifica del riog  sovrapposto al margine destro del dato catastale (se presente)
             --               |RiOg||Riog|                       |RiOg||Riog|
             --             |Cat |                          |Cat |
             begin
               update riferimenti_oggetto riog
                  set inizio_validita   = nvl(t_data_a (p_ind),to_date('30/12/9999','dd/mm/yyyy')) + 1
                    , a_anno            = to_char(nvl(t_data_a (p_ind),to_date('30/12/9999','dd/mm/yyyy')) + 1,'yyyy')
                    , utente            = p_utente
                where oggetto           = a_oggetto
                  and  inizio_validita <= t_data_a (p_ind)
                  and  fine_validita    > t_data_a (p_ind)
                    ;
               --dbms_output.put_line('update riog destro');
            exception
               when others then
                 raise_application_error
                   (-20999,'Errore in aggiornamento Riferimenti Oggetto (1) '||
                           'Estremi: '||a_oggetto||
                           ' ('||sqlerrm||')');
             end;
             -- inserimento riog da dati catastali (centrale)
             insert_riog ( a_oggetto, t_data_da (p_ind)
                         , t_data_a (p_ind)
                         , nvl(to_number(to_char(t_data_da (p_ind) + 1,'yyyy')),1899)
                         , case when to_number(to_char(t_data_a (p_ind),'yyyy')) = 9999
                             then 9999
                             else to_number(to_char(t_data_a (p_ind),'yyyy')) + 1
                           end
                         , t_rendita (p_ind)
                         , to_number(to_char(t_data_reg (p_ind),'yyyy'))
                         , case when p_tipo_immobile = 'T'
                             then to_char(null) -- 'T'
                             else t_cat_catasto (p_ind)
                           end
                         , t_cla_catasto (p_ind)
                         , t_data_reg(p_ind)
                         , nvl(t_data_reg(p_ind),to_date('01/01/1899','dd/mm/yyyy'))
                         , w_messaggio
                         );
             if w_messaggio is not null then
                a_messaggio := w_messaggio;
                -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
                RETURN;
             end if;
          end if; -- w_interno_2 > 0
       end if; -- w_inters_no_compl_2 = 0
     end loop;
  end if;
end trattamento_rendite;
----------------------------------------------------------------------------------
procedure INS_RENDITE_FABBRICATO
/*************************************************************************
  NOME:         INS_RENDITE_FABBRICATO
  DESCRIZIONE: Esegue il caricamento della rendita del fabbricato
               identificato dall'id. immobile.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_id_immobile                    number
, a_messaggio               in out varchar2
) is
  w_messaggio                      varchar2(2000);
begin
  w_messaggio := '';
  p_ind := 0;
  t_data_da.delete;
  t_data_a.delete;
  t_rendita.delete;
--
-- Si memorizzano in un array le rendite e i periodi di validita' dell'id.
-- immobile relativo al fabbricato da trattare
--
  for fabb in (select fabb.partita partita,
                      rtrim(ltrim(ltrim(fabb.categoria,'0'))) categoria,
                      rtrim(ltrim(ltrim(fabb.classe,'0'))) classe,
                      rendita_euro rendita,
                      f_adatta_data(fabb.data_efficacia) da_data,
                      f_adatta_data(fabb.data_efficacia_2) a_data,
                      f_adatta_data(fabb.data_registrazione_atti) data_reg
                 from cc_fabbricati fabb
                where fabb.id_immobile = a_id_immobile
                  and fabb.rendita_euro > 0
                  and nvl(fabb.partita,'*') not in ('C','0000000')
                  and nvl(f_adatta_data(fabb.data_efficacia),to_date('01011850','ddmmyyyy')) <=
                      nvl(f_adatta_data(fabb.data_efficacia_2),to_date('31129999','ddmmyyyy'))
                order by progressivo)
  loop
    -- Si memorizzano i dati del fabbricato
    p_categoria_catasto := nvl(fabb.categoria,p_categoria_catasto);
    p_classe_catasto    := nvl(fabb.classe,p_classe_catasto);
    -- Si memorizzano i dati della rendita
    if p_ind = 0 then
       p_ind := p_ind + 1;
       t_cat_catasto (p_ind) := fabb.categoria;
       t_cla_catasto (p_ind) := fabb.classe;
       t_data_da     (p_ind) := fabb.da_data;
       t_data_a      (p_ind) := fabb.a_data;
       t_data_reg    (p_ind) := fabb.data_reg;
       t_rendita     (p_ind) := fabb.rendita;
    else
       if nvl(fabb.categoria,'*') = nvl(t_cat_catasto(p_ind),'*') and
          nvl(fabb.classe,'*')    = nvl(t_cla_catasto(p_ind),'*') and
          fabb.rendita            = t_rendita (p_ind) and
          fabb.da_data            = nvl(t_data_a (p_ind), fabb.da_data) then
          t_data_a (p_ind)   := fabb.a_data;
          t_data_reg (p_ind) := nvl(fabb.data_reg,t_data_reg(p_ind));
       else
          p_ind := p_ind + 1;
          t_cat_catasto (p_ind) := fabb.categoria;
          t_cla_catasto (p_ind) := fabb.classe;
          t_data_da  (p_ind)    := fabb.da_data;
          t_data_a   (p_ind)    := fabb.a_data;
          t_data_reg (p_ind)    := fabb.data_reg;
          t_rendita  (p_ind)    := fabb.rendita;
       end if;
    end if;
--dbms_output.put_line('Indice: '||p_ind||', data da: '||to_char(t_data_da  (p_ind),'dd/mm/yyyy')||
--                     ', data a: '||to_char(t_data_a  (p_ind),'dd/mm/yyyy')||
--                     ', rendita: '||t_rendita(p_ind));
  end loop;
  -- Sistemazione date periodi validità rendita: se la data fine di un periodo
  -- coincide oppure e' maggiore della data inizio del periodo successivo,
  -- si riporta la data fine al giorno precedente alla data inizio del periodo
  -- successivo
  if p_ind > 0 then
     for p_ind in t_data_da.first .. t_data_da.last
     loop
       /*dbms_output.put_line('Dal '||to_char(t_data_da(p_ind),'dd/mm/yyyy')||
                            ' al '||to_char(t_data_da(p_ind),'dd/mm/yyyy')||
                            ' categoria '||t_cat_catasto (p_ind)||
                            ' classe '||t_cla_catasto (p_ind)||
                            ' rendita '||t_rendita  (p_ind)); */
       if p_ind < t_data_da.last then -- trattamento di tutti gli elementi dell'array tranne l'ultimo
          if t_data_a(p_ind) >= t_data_da(p_ind + 1) then
             t_data_a(p_ind) := t_data_da(p_ind + 1) - 1;
          end if;
       else
          t_data_a(p_ind) := to_date('31129999','ddmmyyyy');
       end if;
     end loop;
  --
     if p_oggetto is not null then
        aggiornamento_oggetto(w_messaggio);
        if w_messaggio is not null then
           a_messaggio := w_messaggio;
           -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
           RETURN;
        end if;
     else
        -- (VD - 16/07/2020): modificato trattamento dati catastali
        --                    per nuova struttura tabella CC_IDENTIFICATIVI
        for rec_fab in sel_catasto_fabb(a_id_immobile)
        loop
          p_sezione         := rec_fab.sezione;
          p_foglio          := rec_fab.foglio;
          p_numero          := rec_fab.numero;
          p_subalterno      := rec_fab.subalterno;
          p_estremi_catasto := rec_fab.estremi_catasto;
          trattamento_oggetto(a_id_immobile,w_messaggio);
          if w_messaggio is not null then
             a_messaggio := w_messaggio;
             -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
             RETURN;
          end if;
          for ogge in sel_oggetti_catasto ( p_tipo_immobile
                                          , p_estremi_catasto
                                          --, p_sezione
                                          --, p_foglio
                                          --, p_numero
                                          --, p_subalterno
                                          )
          loop
            if nvl(ogge.data_cessazione,to_date('31129999','ddmmyyyy')) >=
               p_data_cessazione then
               trattamento_rendite(ogge.oggetto,w_messaggio);
               if w_messaggio is not null then
                  a_messaggio := w_messaggio;
                  -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
                  RETURN;
               end if;
            end if;
          end loop;
        end loop;
        --dbms_output.put_line('Indice: '||p_ind);
        /*for w_ind in 1..10
        loop
          for rec_fab in sel_catasto_fabb(a_id_immobile,w_ind)
          loop
            p_sezione    := rec_fab.sezione;
            p_foglio     := rec_fab.foglio;
            p_numero     := rec_fab.numero;
            p_subalterno := rec_fab.subalterno;
            trattamento_oggetto(a_id_immobile,p_messaggio);
            for ogge in sel_oggetti_catasto ( p_tipo_immobile
                                            , p_sezione
                                            , p_foglio
                                            , p_numero
                                            , p_subalterno
                                            )
            loop
              if nvl(ogge.data_cessazione,to_date('31129999','ddmmyyyy')) >=
                 p_data_cessazione then
                 trattamento_rendite(ogge.oggetto,p_messaggio);
              end if;
            end loop;
          end loop;
        end loop;*/
     end if;
  else
     w_messaggio := 'Dati da caricare non esistenti o non congruenti';
  end if;
--
  a_messaggio := w_messaggio;
end;
----------------------------------------------------------------------------------
procedure INS_REDDITI_TERRENO
/*************************************************************************
  NOME:         INS_REDDITI_TERRENO
  DESCRIZIONE: Esegue il caricamento dei redditi dominicali del terreno
               identificato dall'id. immobile.
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_id_immobile                    number
, a_messaggio               in out varchar2
) is
  w_messaggio                      varchar2(2000);
begin
  p_ind := 0;
  t_data_da.delete;
  t_data_a.delete;
  t_rendita.delete;
--
-- Si trattano tutte le righe congruenti del terreno e si memorizzano i dati
-- identificativi in variabili e i periodi dei redditi in un array
--
  for terr in (select rtrim(ltrim(ltrim(part.sezione_amm,'0'))) sezione, --'0' sezione, --
                      substr(rtrim(ltrim(ltrim(part.foglio,'0'))),1,5) foglio,
                      substr(rtrim(ltrim(ltrim(part.numero,'0'))),1,5) numero,
                      rtrim(ltrim(ltrim(part.subalterno,'0'))) subalterno,
                      part.partita partita,
                      part.qualita qualita,
                      rtrim(ltrim(ltrim(part.classe,'0'))) classe,
                      reddito_dominicale_euro reddito,
                      ettari,
                      are,
                      centiare,
                      estremi_catasto,
                      id_immobile,
                      f_adatta_data(part.data_efficacia) da_data,
                      f_adatta_data(part.data_efficacia_1) a_data,
                      f_adatta_data(part.data_registrazione_atti) data_reg
                 from cc_particelle part
                where part.id_immobile = a_id_immobile
                  and part.reddito_dominicale_euro > 0
                  and nvl(part.partita,'*') not in ('C','0000000')
                  and nvl(f_adatta_data(part.data_efficacia),to_date('01011850','ddmmyyyy')) <
                      nvl(f_adatta_data(part.data_efficacia_1),to_date('31129999','ddmmyyyy'))
                order by progressivo)
  loop
    -- Si memorizzano i dati del terreno
    p_sezione         := nvl(terr.sezione,p_sezione);
    p_foglio          := nvl(terr.foglio,p_foglio);
    p_numero          := nvl(terr.numero,p_numero);
    p_subalterno      := nvl(terr.subalterno,p_subalterno);
    p_estremi_catasto := nvl(terr.estremi_catasto,p_estremi_catasto);
    p_tipo_qualita    := nvl(terr.qualita,p_tipo_qualita);
    --p_classe          := nvl(terr.classe,p_classe);
    p_ettari          := nvl(terr.ettari,p_ettari);
    p_are             := nvl(terr.are,p_are);
    p_centiare        := nvl(terr.centiare,p_centiare);
    -- Si memorizzano i dati del reddito dominicale
    if p_ind = 0 then
       p_ind := p_ind + 1;
       t_cla_catasto (p_ind) := terr.classe;
       t_data_da     (p_ind) := terr.da_data;
       t_data_a      (p_ind) := terr.a_data;
       t_data_reg    (p_ind) := terr.data_reg;
       t_rendita     (p_ind) := terr.reddito;
    else
       if nvl(terr.classe,'*') = nvl(t_cla_catasto (p_ind),'*') and
          terr.reddito = t_rendita (p_ind) and
          terr.da_data = nvl(t_data_a (p_ind), terr.da_data) then
          t_data_a (p_ind)   := terr.a_data;
          t_data_reg (p_ind) := nvl(terr.data_reg,t_data_reg(p_ind));
       else
          p_ind := p_ind + 1;
          t_cla_catasto (p_ind) := terr.classe;
          t_data_da     (p_ind) := terr.da_data;
          t_data_a      (p_ind) := terr.a_data;
          t_data_reg    (p_ind) := terr.data_reg;
          t_rendita     (p_ind) := terr.reddito;
       end if;
    end if;
  end loop;
  -- Sistemazione date periodi validità reddito: se la data fine di un periodo
  -- coincide oppure e' maggiore della data inizio del periodo successivo,
  -- si riporta la data fine al giorno precedente alla data inizio del periodo
  -- successivo
  if p_ind > 0 then
     for p_ind in t_data_da.first .. t_data_da.last
     loop
       if p_ind < t_data_da.last then  -- trattamento di tutti gli elementi dell'array tranne l'ultimo
          if t_data_a(p_ind) >= t_data_da(p_ind + 1) then
             t_data_a(p_ind) := t_data_da(p_ind + 1) - 1;
          end if;
       else
          if t_data_a(p_ind) is null then
             t_data_a(p_ind) := to_date('31129999','ddmmyyyy');
          end if;
       end if;
     end loop;
  --
     if p_oggetto is not null then
        aggiornamento_oggetto(w_messaggio);
        if w_messaggio is not null then
           a_messaggio := w_messaggio;
           -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
           RETURN;
        end if;
     else
        --dbms_output.put_line('Indice: '||p_ind);
        trattamento_oggetto(a_id_immobile,w_messaggio);
        for ogge in sel_oggetti_catasto ( p_tipo_immobile
                                        , p_estremi_catasto
                                        --, p_sezione
                                        --, p_foglio
                                        --, p_numero
                                        --, p_subalterno
                                        )
        loop
          if nvl(ogge.data_cessazione,to_date('31129999','ddmmyyyy')) >=
             p_data_cessazione then
             trattamento_rendite(ogge.oggetto,w_messaggio);
             if w_messaggio is not null then
                a_messaggio := w_messaggio;
                -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
                RETURN;
             end if;
          end if;
        end loop;
     end if;
  else
     w_messaggio := 'Dati da caricare non esistenti o non congruenti';
  end if;
--
  a_messaggio := w_messaggio;
end;
----------------------------------------------------------------------------------
procedure INSERIMENTO_RENDITE
/*************************************************************************
  NOME:         INSERIMENTO_RENDITE
  DESCRIZIONE:  Esegue il caricamento delle rendite dei fabbricati o
                dei redditi dominicali dei terreni (a seconda del tipo
                immobile passato).
  NOTE:
  Rev.    Date         Author      Note
  000     24/01/2020   VD          Prima emissione
**************************************************************************/
( a_id_immobile                    number
, a_tipo_immobile                  varchar2
, a_data_cessazione                date
, a_flag_cessati                   varchar2
, a_utente                         varchar2
, a_oggetto                        number default null
, a_messaggio               in out varchar2
) is
  w_chk_I                          varchar2(1);
  w_messaggio                      varchar2(2000);
cursor sel_riog_c is
  select oggetto
       , oggetti.id_immobile
       , fine_validita
    from oggetti,
        (select id_immobile
              , max(nvl(f_adatta_data(data_efficacia),f_adatta_data(data_registrazione_atti))) fine_validita
           from cc_fabbricati
          where partita_ric = 'C'
          group by id_immobile
          union
         select id_immobile
              , max(nvl(f_adatta_data(data_efficacia),f_adatta_data(data_registrazione_atti))) fine_validita
           from cc_particelle
          where partita = 'C'
          group by id_immobile
        ) catasto
   where oggetti.id_immobile = a_id_immobile
     and oggetti.id_immobile = catasto.id_immobile
     and not exists (select 1
                       from oggetti_pratica ogpr
                          , pratiche_tributo prtr
                      where ogpr.pratica = prtr.pratica
                        and ogpr.oggetto = oggetti.oggetto
                        and prtr.tipo_pratica in ('A','L')
                    )
   order by 1;
begin
  -- Azzeramento variabili di package per eventuale utilizzo in PB
  p_sezione           := null;
  p_foglio            := null;
  p_numero            := null;
  p_subalterno        := null;
  p_estremi_catasto   := null;
  p_categoria_catasto := null;
  p_classe_catasto    := null;
  p_rendita           := to_number(null);
  p_tipo_qualita      := to_number(null);
  p_qualita           := null;
  p_classe            := null;
  p_ettari            := to_number(null);
  p_are               := to_number(null);
  p_centiare          := to_number(null);
  p_reddito           := to_number(null);
  -- Valorizzazione variabili di package per utilizzi successivi
  p_tipo_immobile     := a_tipo_immobile;
  p_oggetto           := a_oggetto;
  -- p_data_cessazione    := nvl(a_data_cessazione,to_date('31/12/9999','dd/mm/yyyy'));
  -- Nota: la vecchia procedure di inserimento rendite viene lanciata con questa data di riferimento
  --       per la cessazione
  p_data_cessazione    := nvl(a_data_cessazione,to_date('01/01/1990','dd/mm/yyyy'));
  p_utente               := a_utente;
  w_messaggio          := '';
  -- Selezione fonte da parametri_installazione
  p_fonte              := F_INPA_VALORE('FONT_REND');
  if p_fonte is null then
     w_messaggio := 'Inserimento non eseguito - Impostare parametro FONT_REND';
     -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
     RETURN;
  else
     if p_tipo_immobile = 'F' then
        --dbms_output.put_line('fabbricati');
        INSERIMENTO_RENDITE_PKG.INS_RENDITE_FABBRICATO(a_id_immobile,w_messaggio);
     else
        INSERIMENTO_RENDITE_PKG.INS_REDDITI_TERRENO(a_id_immobile,w_messaggio);
     end if;
     if w_messaggio is not null then
        a_messaggio := w_messaggio;
        -- (VD - 04/11/2021): serve per uscire dalla procedure senza fare gli step successivi
        RETURN;
     end if;
  end if;
-- Trattamento oggetti cessati
   if a_flag_cessati = 'S' then
      for rec_riog_c in sel_riog_c
      loop
        begin
          select 'x'
            into w_chk_I
            from cc_identificativi iden, cc_fabbricati fabb
           where iden.id_immobile = fabb.id_immobile
             and iden.id_immobile = rec_riog_c.id_immobile
             and nvl(f_adatta_data(data_efficacia),
                     f_adatta_data(data_registrazione_atti)) >=
                 rec_riog_c.fine_validita
             and fabb.partita_ric != 'C';
          raise too_many_rows;
        exception
          when no_data_found then
            begin
              update riferimenti_oggetto
                 set fine_validita = rec_riog_c.fine_validita
                   , utente        = p_utente
               where oggetto = rec_riog_c.oggetto
                 and inizio_validita < rec_riog_c.fine_validita
                 and fine_validita =
                     (select min(fine_validita)
                        from riferimenti_oggetto riog2
                       where riog2.oggetto = rec_riog_c.oggetto
                         and inizio_validita <= rec_riog_c.fine_validita
                         and riog2.fine_validita >= rec_riog_c.fine_validita);
              delete riferimenti_oggetto
               where oggetto = rec_riog_c.oggetto
                 and fine_validita > rec_riog_c.fine_validita
                 and exists
               (select 'x'
                        from riferimenti_oggetto riog2
                       where riog2.oggetto = rec_riog_c.oggetto
                         and riog2.fine_validita = rec_riog_c.fine_validita);
            exception
              when others then
                raise_application_error(-20919,
                                        'Errore in trattamento riog Partita C ' ||
                                        ' oggetto ' || rec_riog_c.oggetto || ' (' ||
                                        sqlerrm || ')');
            end;
          when too_many_rows then
            null;
          when others then
            raise_application_error(-20919,
                                    'Errore in ric. reiscrizione ' || ' oggetto ' ||
                                    rec_riog_c.oggetto || ' (' || sqlerrm || ')');
        end;
      end loop;
   end if; -- a_flag_cessati = 'S'
--
  a_messaggio := w_messaggio;
end;
----------------------------------------------------------------------------------
end INSERIMENTO_RENDITE_PKG;
/

