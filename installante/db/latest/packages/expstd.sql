--liquibase formatted sql 
--changeset abrandolini:20250326_152429_expstd stripComments:false runOnChange:true 
 
create or replace package EXPSTD is
 /******************************************************************************
  NOME:        EXPSTD.
  DESCRIZIONE: Procedure e Funzioni di utilita' per estrazione dati da TR4
  ANNOTAZIONI: .
  REVISIONI: .
  Rev.  Data        Autore  Descrizione.
  02    19/06/2017  VD      Nuova procedure per estrare le sanzioni pratica.
  01    24/05/2017  VD      Aggiunti parametri per estrazione anagrafe.
                            Nuova procedure per estrarre i contatti
                            contribuente.
  00    09/02/2016  VD      Prima emissione.
 ******************************************************************************/
  s_revisione constant varchar2(30) := 'V1.02';
  procedure DELETE_WRK_TRASMISSIONI;
  procedure INSERT_WRK_TRASMISSIONI
  ( p_descr_chiave           varchar2
  , p_campo_chiave           varchar2
  , p_numero                 number
  , p_dati                   varchar2
  , p_dati2                  varchar2 default null
  , p_dati3                  varchar2 default null
  , p_dati4                  varchar2 default null
  , p_dati5                  varchar2 default null
  , p_dati6                  varchar2 default null
  , p_dati7                  varchar2 default null
  , p_dati8                  varchar2 default null
  );
  function CONTROLLO_TIPO_TRIBUTO
  ( p_tipo_tributo           varchar2
  ) return varchar2;
  function CONTROLLO_RIGHE_ESTRATTE
  ( p_contarighe             number
  ) return varchar2;
  procedure COMUNI
  ( p_num_record             in out number
  );
  procedure STRADARIO
  ( p_num_record             in out number
  );
  procedure ANAGRAFE
  ( p_tipo_residente         in     number
  , p_residente              in     varchar2
  , p_aire                   in     varchar2
  , p_contribuente           in     varchar2
  , p_num_record             in out number
  );
  procedure CONTATTI_CONTRIBUENTE
  ( p_tipo_tributo           in varchar2
  , p_num_record             in out number
  );
  procedure ALIQUOTE
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure CATEGORIE_CATASTO
  ( p_num_record             in out number
  );
  procedure DETRAZIONI
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure FONTI
  ( p_num_record             in out number
  );
  procedure MOLTIPLICATORI
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure MOTIVI_DETRAZIONE
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  );
  procedure RIVALUTAZIONI_RENDITA
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure TIPI_ALIQUOTA
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  );
  procedure TIPI_CARICA
  ( p_num_record             in out number
  );
  procedure TIPI_STATO
  ( p_num_record             in out number
  );
  procedure TIPI_USO
  ( p_num_record             in out number
  );
  procedure TIPI_UTILIZZO
  ( p_num_record             in out number
  );
  procedure IMMOBILI
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  );
  procedure RIFERIMENTI_IMMOBILE
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  );
  procedure UTILIZZI_IMMOBILE
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  );
  procedure DENUNCE
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure DETTAGLI_DENUNCIA
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure ALIQUOTE_IMMOBILE
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure DETRAZIONI_IMMOBILE
  ( p_tipo_tributo           varchar2
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure DETRAZIONI_FIGLI
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure MAGGIORI_DETRAZIONI
  ( p_tipo_tributo           varchar2 default null
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure PROVVEDIMENTI
  ( p_tipo_tributo           varchar2 default null
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure SANZIONI_PROVVEDIMENTO
  ( p_tipo_tributo           varchar2 default null
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
  procedure VERSAMENTI
  ( p_tipo_tributo           varchar2 default null
  , p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  );
end EXPSTD;
/

create or replace package body EXPSTD is
/******************************************************************************
  NOME:        EXPSTD.
  DESCRIZIONE: Procedure e Funzioni di utilita' per estrazione dati da TR4
  ANNOTAZIONI: .
  REVISIONI: .
  Rev.  Data        Autore  Descrizione.
  003   19/06/2017  VD      Nuova procedure per estrarre le sanzioni pratica.
  002   24/05/2017  VD      Aggiunti parametri per estrazione anagrafe.
                            Nuova procedure per estrarre i contatti
                            contribuente.
  001   15/04/2016  VD      Provvedimenti: si trattano tutti gli stati accertamento
                            presenti e le pratiche raggruppate in pratiche di
                            tipo "G" (ingiunzioni).
  000   09/02/2016  VD      Prima emissione.
******************************************************************************/
  s_revisione_body constant varchar2(30) := '003';
  w_riga                    varchar2(32767);
  w_contarighe              number := 0;
  w_errore                  varchar2(4000);
  errore                    exception;
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
  procedure DELETE_WRK_TRASMISSIONI is
  /******************************************************************************
    NOME:        DELETE_WRK_TRASMISSIONI.
    DESCRIZIONE: Elimina dalla tabella WRK_TRASMISSIONI le righe delle
                 elaborazioni precedenti.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
    delete wrk_trasmissioni;
  exception
    when others then
      raise_application_error(-20999,'Errore in pulizia tabella di lavoro '||
                                     ' ('||sqlerrm||')');
  end;
  ----------------------------------------------------------------------------------
  procedure INSERT_WRK_TRASMISSIONI
  ( p_descr_chiave     varchar2
  , p_campo_chiave     varchar2
  , p_numero           number
  , p_dati             varchar2
  , p_dati2            varchar2 default null
  , p_dati3            varchar2 default null
  , p_dati4            varchar2 default null
  , p_dati5            varchar2 default null
  , p_dati6            varchar2 default null
  , p_dati7            varchar2 default null
  , p_dati8            varchar2 default null
  ) is
  /******************************************************************************
    NOME:        INSERT_WRK_TRASMISSIONI.
    DESCRIZIONE: Inserisce la riga preparata nella tabella WRK_TRASMISSIONI.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
    insert into wrk_trasmissioni ( numero
                                 , dati
                                 , dati2
                                 , dati3
                                 , dati4
                                 , dati5
                                 , dati6
                                 , dati7
                                 , dati8
                                 )
    values ( lpad(to_char(p_numero),15,'0')
           , p_dati
           , p_dati2
           , p_dati3
           , p_dati4
           , p_dati5
           , p_dati6
           , p_dati7
           , p_dati8
           );
  exception
    when others then
      w_errore := 'Ins. WRK_TRASMISSIONI riga n. ' ||to_char(p_numero)||
                  ', '||p_descr_chiave||' '||p_campo_chiave||' - '||
                   sqlerrm;
      raise errore;
  end;
  ----------------------------------------------------------------------------------
  function CONTROLLO_TIPO_TRIBUTO
  ( p_tipo_tributo     varchar2
  ) return varchar2 is
  /******************************************************************************
    NOME:        CONTROLLO_TIPO_TRIBUTO.
    DESCRIZIONE: Verifica che il parametro TIPO_TRIBUTO sia uguale a
                 - ICI
                 - TASI
                 - ICI,TASI
                 - TASI,ICI
    RITORNA:     null                se il tipo_tributo è corretto
                 messaggio di errore se il tipo_tributo non è tra quelli previsti
    NOTE:
  ******************************************************************************/
  begin
    if upper(p_tipo_tributo) in ('ICI','TASI','ICI,TASI','TASI,ICI') then
       w_errore := null;
    else
       w_errore := 'Tipo tributo indicato non previsto (indicare ICI e/o TASI)';
    end if;
  --
    return w_errore;
  --
  end;
  ----------------------------------------------------------------------------------
  function CONTROLLO_RIGHE_ESTRATTE
  ( p_contarighe        number
  ) return varchar2 is
  /******************************************************************************
    NOME:        CONTROLLO_RIGHE_ESTRATTE.
    DESCRIZIONE: Verifica che la procedure abbia estratto almento una riga.
    RITORNA:     null:                se il numero di righe estratte è > 0
                 messaggio di errore: se il numero di righe estratte è = 0
    NOTE:
  ******************************************************************************/
  begin
    if p_contarighe > 0 then
       w_errore := null;
    else
       w_errore := 'Non esistono dati da estrarre';
    end if;
  --
    return w_errore;
  --
  end;
  ----------------------------------------------------------------------------------
  procedure COMUNI
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        COMUNI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati relativi ai comuni
                 esteri con codice diverso da codice ISTAT (provincia_stato > 200
                 e comune > 0) secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento comuni
  --
    for com in (select lpad(com1.provincia_stato,3,'0')||
                       lpad(com1.comune,3,'0') codice_comune
                     , com1.denominazione descrizione
                     , com2.denominazione descrizione_stato
                  from ad4_comuni com1
                     , ad4_comuni com2
                 where com1.provincia_stato > 200
                   and com1.comune > 0
                   and com1.provincia_stato = com2.provincia_stato
                   and com2.comune = 0
                 order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := com.codice_comune      ||';'||
                com.descrizione        ||';'||
                com.descrizione_stato  ||';';
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Comune'
                                     , com.codice_comune
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure STRADARIO
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        STRADARIO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella ARCHIVIO_VIE, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento stradario
  --
    for via in (select cod_via
                     , substr(denom_uff,1,instr(denom_uff,' ') - 1) toponimo
                     , substr(denom_uff,instr(denom_uff,' ') + 1) descr_via
                     , denom_uff
                     , utente
                     , note
                  from archivio_vie
                 order by cod_via)
    loop
      w_contarighe := w_contarighe + 1;
      if via.toponimo in ('L.GO', 'LARGO', 'P.LE', 'P.TA', 'P.ZA', 'PIAZZA', 'PIAZZALE',
                          'PIAZZETTA', 'PONTE', 'PORTA', 'ROTONDA', 'V.LE', 'V.LO',
                          'VIA', 'VIALE', 'VICOLO', 'CORSO', 'C.SO') then
         w_riga := via.cod_via            ||';'||
                   via.toponimo           ||';'||
                   via.descr_via          ||';'||
                   via.note               ||';'||
                   via.utente             ||';';
      else
         w_riga := via.cod_via            ||';'||
                   ''                     ||';'||
                   via.denom_uff          ||';'||
                   via.note               ||';'||
                   via.utente             ||';';
      end if;
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Via'
                                     , via.cod_via
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure ANAGRAFE
  ( p_tipo_residente         in     number
  , p_residente              in     varchar2
  , p_aire                   in     varchar2
  , p_contribuente           in     varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        ANAGRAFE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati anagrafici di tutti
                 i soggetti maggiorenni, secondo il tracciato previsto.
    RITORNA:
    NOTE:
    Rev.  Date        Author      Note
    01    24/05/2017  VD          Aggiunti parametri:
                                  tipo_residente - 0 solo i soggetti GSD
                                                   1 solo i soggetti non GSD
                                                   NULL tutti
                                  residente      - SI solo residenti
                                                   NO solo non residenti
                                                   NULL tutti
                                  aire           - SI solo A.I.R.E.
                                                   NO solo non A.I.R.E.
                                                   NULL tutti
                                  contribuente   - SI solo contribuenti
                                                   NO solo non contribuenti
                                                   NULL tutti
  ******************************************************************************/
  w_cod_fiscale                  varchar2(16);
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento soggetti
  --
    for sogg in (select sogg.ni
                      , nvl(cont.cod_fiscale,
                            decode(sogg.tipo,'F',sogg.cod_fiscale,sogg.partita_iva)) cod_fiscale
                      , sogg.partita_iva
                      , sogg.tipo_residente
                      , sogg.cognome
                      , sogg.nome
                      , decode(sogg.tipo_residente
                              ,0,'F'
                                ,decode(sogg.tipo
                                       ,0,'F'
                                       ,1,'G'
                                         ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo
                      , decode(sogg.tipo_residente,0,sogg.fascia,to_number(null)) fascia
                      , decode(sogg.tipo_residente,0,sogg.stato,to_number(null)) stato
                      , decode(sogg.tipo_residente
                              ,0,decode(sogg.data_ult_eve
                                       ,null,null
                                            ,to_char(sogg.data_ult_eve,'yyyymmdd'))
                                ,null) data_ultimo_evento
                      , decode(sogg.tipo_residente
                              ,0,decode(sogg.cod_pro_eve||sogg.cod_com_eve
                                       ,null,null
                                            ,lpad(sogg.cod_pro_eve,3,'0')||lpad(sogg.cod_com_eve,3,'0'))
                                ,null) comune_ultimo_evento
                      , sogg.sesso
                      , sogg.cod_fam
                      , sogg.rapporto_par
                      , sogg.sequenza_par
                      , decode(sogg.data_nas,null,null,to_char(sogg.data_nas,'yyyymmdd')) data_nas
                      , decode(sogg.cod_pro_nas||sogg.cod_com_nas
                              ,null,null
                                   ,lpad(sogg.cod_pro_nas,3,'0')||lpad(sogg.cod_com_nas,3,'0')) comune_nas
                      , decode(sogg.cod_pro_res||sogg.cod_com_res
                              ,null,null
                                   ,lpad(sogg.cod_pro_res,3,'0')||lpad(sogg.cod_com_res,3,'0')) comune_res
                      , sogg.cap
                      , sogg.zipcode
                      , decode(sogg.tipo_residente,1,sogg.denominazione_via
                                                    ,decode(nvl(sogg.fascia,0),2,sogg.denominazione_via,null)) denominazione_via
                      , decode(sogg.tipo_residente,0,decode(nvl(sogg.fascia,0),2,null,sogg.cod_via),null)   cod_via
                      , sogg.num_civ
                      , sogg.suffisso
                      , sogg.scala
                      , sogg.piano
                      , sogg.interno
                      , sogg.rappresentante
                      , sogg.indirizzo_rap
                      , decode(sogg.cod_pro_rap||sogg.cod_com_rap
                              ,null,null
                                   ,lpad(sogg.cod_pro_rap,3,'0')||lpad(sogg.cod_com_rap,3,'0')) comune_rap
                      , sogg.cod_fiscale_rap
                      , sogg.tipo_carica
                      , decode(sogg.ni_presso,null,null,sogg_p.cod_fiscale) cod_fiscale_presso
                      , sogg.note
                      , sogg.utente
                   from soggetti           sogg
                      , soggetti           sogg_p
                      , archivio_vie       arvi
                      , contribuenti       cont
                  where sogg.cod_via       = arvi.cod_via (+)
                    and sogg.ni_presso     = sogg_p.ni    (+)
                    and sogg.ni            = cont.ni      (+)
                    and add_months(nvl(sogg.data_nas,to_date('01011950','ddmmyyyy')),216) <= trunc(sysdate)
                    and (sogg.cod_fiscale is not null or sogg.partita_iva is not null)
                    and sogg.tipo_residente = nvl(p_tipo_residente,sogg.tipo_residente)
                    and decode(sogg.tipo_residente,0,
                               decode(sogg.fascia,1,'SI','NO'),'NO') =
                        nvl(p_residente,decode(sogg.tipo_residente,0,
                                               decode(sogg.fascia,1,'SI','NO'),'NO'))
                    and decode(sogg.tipo_residente,0,
                               decode(sogg.fascia,3,'SI','NO'),'NO') =
                        nvl(p_aire,decode(sogg.tipo_residente,0,
                                          decode(sogg.fascia,3,'SI','NO'),'NO'))
                    and decode(cont.ni,null,'NO','SI') =
                        nvl(p_contribuente,decode(cont.ni,null,'NO','SI'))
                  order by 5,6)
    loop
      --
      -- Verifica esistenza contribuente
      --
      /*begin
        select cod_fiscale
          into w_cod_fiscale
          from contribuenti
         where ni = sogg.ni;
      exception
        when no_data_found then
          w_cod_fiscale := null;
        when others then
          w_errore := 'Select CONTRIBUENTI ' ||to_char(sogg.ni)||
                       sqlerrm;
          raise errore;
      end;
      --
      if w_cod_fiscale is null then
         if sogg.tipo = 'F' then
            w_cod_fiscale := sogg.cod_fiscale;
         else
            w_cod_fiscale := sogg.partita_iva;
         end if;
      end if;*/
      --
      w_contarighe := w_contarighe + 1;
      w_riga := sogg.cod_fiscale           ||';'||
                sogg.tipo_residente        ||';'||
                sogg.cognome               ||';'||
                sogg.nome                  ||';'||
                sogg.tipo                  ||';'||
                sogg.fascia                ||';'||
                sogg.stato                 ||';'||
                sogg.data_ultimo_evento    ||';'||
                sogg.comune_ultimo_evento  ||';'||
                sogg.sesso                 ||';'||
                sogg.cod_fam               ||';'||
                sogg.rapporto_par          ||';'||
                sogg.sequenza_par          ||';'||
                sogg.data_nas              ||';'||
                sogg.comune_nas            ||';'||
                sogg.comune_res            ||';'||
                sogg.cap                   ||';'||
                sogg.zipcode               ||';'||
                sogg.denominazione_via     ||';'||
                sogg.cod_via               ||';'||
                sogg.num_civ               ||';'||
                sogg.suffisso              ||';'||
                sogg.scala                 ||';'||
                sogg.piano                 ||';'||
                sogg.interno               ||';'||
                sogg.rappresentante        ||';'||
                sogg.indirizzo_rap         ||';'||
                sogg.comune_rap            ||';'||
                sogg.cod_fiscale_rap       ||';'||
                sogg.tipo_carica           ||';'||
                sogg.cod_fiscale_presso    ||';'||
                sogg.note                  ||';'||
                sogg.utente                ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Cod.fiscale'
                                     , w_cod_fiscale
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure CONTATTI_CONTRIBUENTE
  ( p_tipo_tributo           in varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        CONTATTI_CONTRIBUENTE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella CONTATTI_CONTRIBUENTE, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    if p_tipo_tributo is not null then
       w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
       if w_errore is not null then
          raise errore;
       end if;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento contatti_contribuente
  --
    for coco in (select cod_fiscale
                      , sequenza
                      , to_char(data,'yyyymmdd') data
                      , numero
                      , anno
                      , tico.descrizione des_contatto
                      , tire.descrizione des_richiedente
                      , testo
                      , tipo_tributo
                   from CONTATTI_CONTRIBUENTE coco,
                        TIPI_CONTATTO         tico,
                        TIPI_RICHIEDENTE      tire
                  where upper(nvl(p_tipo_tributo,nvl(tipo_tributo,'*'))) like '%'||nvl(tipo_tributo,'*')||'%'
                    and coco.tipo_contatto    = tico.tipo_contatto
                    and coco.tipo_richiedente = tire.tipo_richiedente
                  order by cod_fiscale,sequenza)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := coco.cod_fiscale              ||';'||
                coco.sequenza                 ||';'||
                coco.data                     ||';'||
                coco.numero                   ||';'||
                coco.anno                     ||';'||
                coco.des_contatto             ||';'||
                coco.des_richiedente          ||';'||
                coco.testo                    ||';'||
                coco.tipo_tributo             ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Cod.fiscale'
                                     , coco.cod_fiscale
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure ALIQUOTE
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        ALIQUOTE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 in tabella ALIQUOTE, secondo il tracciato previsto, con
                 possibilita di selezionare il tipo tributo e un intervallo
                 di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento aliquote
  --
    for aliq in (select tipo_tributo
                      , anno
                      , tipo_aliquota
                      , aliquota
                      , nvl(flag_ab_principale,'N') flag_ab_principale
                      , nvl(flag_pertinenze,'N')    flag_pertinenze
                      , aliquota_base
                      , aliquota_erariale
  --                      , aliquota_std
  --                      , perc_saldo
  --                      , perc_occupante
                   from ALIQUOTE
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                    and anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2,3)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := aliq.tipo_tributo          ||';'||
                aliq.anno                  ||';'||
                aliq.tipo_aliquota         ||';'||
                aliq.aliquota              ||';'||
                aliq.flag_ab_principale    ||';'||
                aliq.flag_pertinenze       ||';'||
                aliq.aliquota_base         ||';'||
                aliq.aliquota_erariale     ||';';
  --              aliq.aliquota_std          ||';'||
  --              aliq.perc_saldo            ||';'||
  --              aliq.perc_occupante        ||';'
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Aliquota'
                                     , aliq.tipo_tributo||'/'||aliq.anno||'/'||aliq.tipo_aliquota
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure CATEGORIE_CATASTO
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        CATEGORIE_CATASTO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella CATEGORIE_CATASTO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento categorie catasto
  --
    for caca in (select categoria_catasto
                      , descrizione
                      , nvl(flag_reale,'N') flag_reale
  --                      , eccezione
                   from CATEGORIE_CATASTO
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := caca.categoria_catasto     ||';'||
                caca.descrizione           ||';'||
                caca.flag_reale            ||';';
  --              caca.eccezione             ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Cat.Catasto'
                                     , caca.categoria_catasto
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure DETRAZIONI
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        DETRAZIONI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 in tabella DETRAZIONI, secondo il tracciato previsto, con
                 possibilita di selezionare il tipo tributo e un intervallo
                 di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento detrazioni
  --
    for detr in (select tipo_tributo
                      , anno
                      , detrazione_base
                      , detrazione
  --                    , aliquota
  --                    , detrazione_imponibile
                      , nvl(flag_pertinenze,'N') flag_pertinenze
                      , detrazione_figlio
                      , detrazione_max_figli
                   from DETRAZIONI
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                    and anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2,3)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := detr.tipo_tributo          ||';'||
                detr.anno                  ||';'||
                detr.detrazione_base       ||';'||
                detr.detrazione            ||';'||
  --              detr.aliquota              ||';'||
  --              detr.detrazione_imponibile ||';'||
                detr.flag_pertinenze       ||';'||
                detr.detrazione_figlio     ||';'||
                detr.detrazione_max_figli  ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Detrazione'
                                     , detr.tipo_tributo||'/'||detr.anno
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure FONTI
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        FONTI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella FONTI, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento fonti
  --
    for font in (select fonte
                      , descrizione
                   from FONTI
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := font.fonte             ||';'||
                font.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Fonte'
                                     , font.fonte
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure MOLTIPLICATORI
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        MOLTIPLICATORI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella MOLTIPLICATORI, secondo il tracciato previsto,
                 con possibilita di selezionare un intervallo di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento moltiplicatori
  --
    for molt in (select anno
                      , categoria_catasto
                      , moltiplicatore
                   from MOLTIPLICATORI
                  where anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := molt.anno              ||';'||
                molt.categoria_catasto ||';'||
                molt.moltiplicatore    ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Moltiplicatore'
                                     , molt.anno||'/'||molt.categoria_catasto
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure MOTIVI_DETRAZIONE
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        MOTIVI_DETRAZIONE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella MOTIVI_DETRAZIONE, secondo il tracciato previsto,
                 con possibilita di selezionare il tipo tributo.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento motivi detrazione
  --
    for motd in (select tipo_tributo
                      , motivo_detrazione
                      , descrizione
                   from MOTIVI_DETRAZIONE
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                  order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := motd.tipo_tributo      ||';'||
                motd.motivo_detrazione ||';'||
                motd.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Motivo detrazione'
                                     , motd.tipo_tributo||'/'||motd.motivo_detrazione
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure RIVALUTAZIONI_RENDITA
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        RIVALUTAZIONI_RENDITA.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella RIVALUTAZIONI_RENDITA, secondo il tracciato
                 previsto, con possibilita di selezionare un intervallo di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento rivalutazioni rendita
  --
    for rire in (select anno
                      , decode(tipo_oggetto,55,5,tipo_oggetto) tipo_oggetto
                      , aliquota
                   from RIVALUTAZIONI_RENDITA
                  where anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := rire.anno              ||';'||
                rire.tipo_oggetto      ||';'||
                rire.aliquota          ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Riv.rendita'
                                     , rire.anno||'/'||rire.tipo_oggetto
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure TIPI_ALIQUOTA
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        TIPI_ALIQUOTA.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella TIPI_ALIQUOTA, secondo il tracciato previsto,
                 con possibilita di selezionare il tipo tributo.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento tipi aliquota
  --
    for tial in (select tipo_tributo
                      , tipo_aliquota
                      , descrizione
                   from TIPI_ALIQUOTA
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                  order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := tial.tipo_tributo      ||';'||
                tial.tipo_aliquota     ||';'||
                tial.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Tipo aliquota'
                                     , tial.tipo_tributo||'/'||tial.tipo_aliquota
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure TIPI_CARICA
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        TIPI_CARICA.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella TIPI_CARICA, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento tipi carica
  --
    for tica in (select tipo_carica
                      , descrizione
                   from tipi_carica
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := tica.tipo_carica       ||';'||
                tica.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Tipo carica'
                                     , tica.tipo_carica
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure TIPI_STATO
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        TIPI_STATO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella TIPI_STATO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento tipi stato
  --
    for tist in (select tipo_stato
                      , descrizione
                   from TIPI_STATO
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := tist.tipo_stato        ||';'||
                tist.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Tipo stato'
                                     , tist.tipo_stato
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure TIPI_USO
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        TIPI_USO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella TIPI_USO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento tipi uso
  --
    for tius in (select tipo_uso
                      , descrizione
                   from TIPI_USO
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := tius.tipo_uso          ||';'||
                tius.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Tipo uso'
                                     , tius.tipo_uso
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure TIPI_UTILIZZO
  ( p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        TIPI_UTILIZZO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella TIPI_UTILIZZO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento tipi uso
  --
    for tiut in (select tipo_utilizzo
                      , descrizione
                   from TIPI_UTILIZZO
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := tiut.tipo_utilizzo     ||';'||
                tiut.descrizione       ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Tipo utilizzo'
                                     , tiut.tipo_utilizzo
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure IMMOBILI
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        IMMOBILI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella OGGETTI, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento immobili (oggetti)
  --
    for ogge in (select distinct oggetto immobile
                      , descrizione
                      , edificio
                      , decode(ogge.tipo_oggetto,55,5,ogge.tipo_oggetto) tipo_immobile
                      , indirizzo_localita indirizzo
                      , cod_via
                      , num_civ numero_civico
                      , suffisso
                      , scala
                      , piano
                      , interno
                      , sezione
                      , foglio
                      , numero
                      , subalterno
                      , zona
                      , partita
                      , progr_partita
                      , protocollo_catasto
                      , anno_catasto
                      , categoria_catasto
                      , classe_catasto
                      , note
                      , utente
                      , cod_ecografico
                   from OGGETTI ogge
                      , OGGETTI_TRIBUTO ogtr
                  where ogge.tipo_oggetto = ogtr.tipo_oggetto
                    and upper(p_tipo_tributo) like '%'||ogtr.tipo_tributo||'%'
                  order by 1)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := ogge.immobile          ||';'||
                ogge.descrizione       ||';'||
                ogge.edificio          ||';'||
                ogge.tipo_immobile     ||';'||
                ogge.indirizzo         ||';'||
                ogge.cod_via           ||';'||
                ogge.numero_civico     ||';'||
                ogge.suffisso          ||';'||
                ogge.scala             ||';'||
                ogge.piano             ||';'||
                ogge.interno           ||';'||
                ogge.sezione           ||';'||
                ogge.foglio            ||';'||
                ogge.numero            ||';'||
                ogge.subalterno        ||';'||
                ogge.zona              ||';'||
                ogge.partita           ||';'||
                ogge.progr_partita     ||';'||
                ogge.protocollo_catasto||';'||
                ogge.anno_catasto      ||';'||
                ogge.categoria_catasto ||';'||
                ogge.classe_catasto    ||';'||
                ogge.note              ||';'||
                ogge.utente            ||';'||
                ogge.cod_ecografico    ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Immobile'
                                     , ogge.immobile
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure RIFERIMENTI_IMMOBILE
  ( p_tipo_tributo           varchar2
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        RIFERIMENTI_IMMOBILE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella RIFERIMENTI_OGGETTO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento riferimenti immobile
  --
    for riog in (select distinct riog.oggetto immobile
                      , to_number(to_char(riog.inizio_validita,'yyyymmdd')) inizio_validita
                      , to_number(to_char(riog.fine_validita,'yyyymmdd')) fine_validita
                      , riog.rendita
                      , riog.anno_rendita
                      , riog.categoria_catasto
                      , riog.classe_catasto
                      , to_number(to_char(riog.data_reg_atti,'yyyymmdd')) data_reg_atti
                   from RIFERIMENTI_OGGETTO riog
                      , OGGETTI             ogge
                      , OGGETTI_TRIBUTO     ogtr
                  where riog.oggetto = ogge.oggetto
                    and ogge.tipo_oggetto = ogtr.tipo_oggetto
                    and upper(p_tipo_tributo) like '%'||ogtr.tipo_tributo||'%'
                  order by 1,2)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := riog.immobile          ||';'||
                riog.inizio_validita   ||';'||
                riog.fine_validita     ||';'||
                riog.rendita           ||';'||
                riog.anno_rendita      ||';'||
                riog.categoria_catasto ||';'||
                riog.classe_catasto    ||';'||
                riog.data_reg_atti     ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Riferimento imm.'
                                     , riog.immobile||' '||to_char(to_date(lpad(riog.inizio_validita,8,'0'),'yyyymmdd'),'dd/mm/yyyy')
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure UTILIZZI_IMMOBILE
  ( p_tipo_tributo                   varchar2
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        UTILIZZI_IMMOBILE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella UTILIZZI_OGGETTO, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
    w_cod_fiscale              varchar2(16);
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento utilizzi immobile
  --
    for utog in (select oggetto immobile
                      , tipo_tributo
                      , anno
                      , tipo_utilizzo
                      , sequenza
                      , ni
                      , mesi_affitto
                      , to_number(to_char(data_scadenza,'yyyymmdd')) data_scadenza
                      , to_number(to_char(dal,'yyyymmdd'))           dal
                      , to_number(to_char(al,'yyyymmdd'))            al
                      , intestatario
                      , tipo_uso
                   from UTILIZZI_OGGETTO
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                  order by 1,2)
    loop
      --
      -- Selezione codice fiscale soggetto/contribuente
      --
      if utog.ni is null then
         w_cod_fiscale := null;
      else
         begin
           select nvl(cont.cod_fiscale,sogg.cod_fiscale)
             into w_cod_fiscale
             from contribuenti cont
                , soggetti     sogg
            where cont.ni (+) = sogg.ni
              and sogg.ni     = utog.ni;
         exception
           when others then
             w_cod_fiscale := null;
         end;
      end if;
      --
      w_contarighe := w_contarighe + 1;
      w_riga := utog.immobile          ||';'||
                utog.tipo_tributo      ||';'||
                utog.anno              ||';'||
                utog.tipo_utilizzo     ||';'||
                utog.sequenza            ||';'||
                w_cod_fiscale          ||';'||
                utog.mesi_affitto      ||';'||
                utog.data_scadenza     ||';'||
                utog.dal               ||';'||
                utog.al                ||';'||
                utog.intestatario      ||';'||
                utog.tipo_uso          ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Utilizzo imm.'
                                     , utog.immobile||'/'||utog.tipo_tributo||'/'||utog.anno||'/'||utog.tipo_utilizzo||'/'||utog.sequenza
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure DENUNCE
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        DENUNCE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati relativi alle denunce
                 del tipo tributo e dell'anno indicati, secondo il tracciato
                 previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento denunce
  --
    for den in (select prtr.pratica denuncia
                     , prtr.cod_fiscale
                     , prtr.tipo_tributo
                     , prtr.anno
                     , to_char(prtr.data,'yyyymmdd') data
                     , prtr.numero
                     , prtr.tipo_carica
                     , prtr.denunciante
                     , prtr.indirizzo_den
                     , lpad(prtr.cod_pro_den,3,'0')||lpad(prtr.cod_com_den,3,'0') comune_den
                     , prtr.cod_fiscale_den
                     , prtr.partita_iva_den
                     , prtr.note
                     , prtr.utente
                  from tipi_carica tica
                     , pratiche_tributo prtr
                 where tica.tipo_carica        (+) = prtr.tipo_carica
                   and upper(p_tipo_tributo) like '%'||prtr.tipo_tributo||'%'
                   and prtr.tipo_pratica||''       = 'D'
                   and prtr.anno                   between nvl(p_anno_iniz,0)
                                                       and nvl(p_anno_fine,9999)
                order by prtr.cod_fiscale
                       , prtr.pratica)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := den.denuncia           ||';'||
                den.cod_fiscale        ||';'||
                den.tipo_tributo       ||';'||
                den.anno               ||';'||
                den.data               ||';'||
                den.numero             ||';'||
                den.tipo_carica        ||';'||
                den.denunciante        ||';'||
                den.indirizzo_den      ||';'||
                den.comune_den         ||';'||
                den.cod_fiscale_den    ||';'||
                den.partita_iva_den    ||';'||
                den.note               ||';'||
                den.utente             ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Denuncia'
                                     , den.denuncia
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure DETTAGLI_DENUNCIA
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        DETTAGLI_DENUNCIA.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati relativi ai dettagli
                 delle denunce del tipo tributo e dell'anno indicati, secondo
                 il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento denunce: si selezionano prima le testate, poi per ogni
  -- testata si trattano i relativi dettagli selezionando i dati da
  -- oggetti_contribuente, in modo da trattare anche eventuali contitolari
  --
    for den in (select prtr.cod_fiscale
                     , prtr.pratica
                     , prtr.anno
                     , prtr.tipo_tributo
                     , prtr.tipo_pratica
                  from pratiche_tributo prtr
                 where upper(p_tipo_tributo) like '%'||prtr.tipo_tributo||'%'
                   and prtr.tipo_pratica||''       = 'D'
                   and prtr.anno                   between nvl(p_anno_iniz,0)
                                                       and nvl(p_anno_fine,9999)
                 order by prtr.cod_fiscale
                        , prtr.pratica)
    loop
      --
      -- Trattamento oggetti contribuente
      --
      for ogco in (select den.tipo_tributo
                        , ogco.cod_fiscale
                        , ogco.tipo_rapporto
                        , ogpr.oggetto_pratica dettaglio_denuncia
                        , ogpr.oggetto         immobile
                        , ogpr.num_ordine
                        , ogpr.categoria_catasto
                        , ogpr.classe_catasto
                        , nvl(ogpr.imm_storico,'N') imm_storico
                        , decode(sign(ogge.tipo_oggetto - 3),1,4,substr(ogge.tipo_oggetto,1,1)) tipo_oggetto
                        , ogpr.valore
                        , ogco.anno anno_ogco
                        , ogco.detrazione
                        , ogco.perc_possesso
                        , ogco.mesi_possesso
                        , ogco.mesi_possesso_1sem
                        , nvl(ogco.flag_possesso,'N') flag_possesso
                        , ogco.mesi_esclusione
                        , nvl(ogco.flag_esclusione,'N') flag_esclusione
                        , ogco.mesi_riduzione
                        , nvl(ogco.flag_riduzione,'N') flag_riduzione
                        , ogco.mesi_aliquota_ridotta mesi_al_ridotta
                        , nvl(ogco.flag_al_ridotta,'N') flag_al_ridotta
                        , nvl(ogco.flag_ab_principale,'N') flag_ab_principale
                        , ogpr.note
                        , ogpr.utente
                        , ogpr.oggetto_pratica_rif_ap pertinenza_di
                     from oggetti_pratica      ogpr
                        , oggetti_contribuente ogco
                        , oggetti              ogge
                    where ogge.oggetto         = ogpr.oggetto
                      and ogco.oggetto_pratica = ogpr.oggetto_pratica
                      and ogpr.pratica         = den.pratica
                    order by ogco.cod_fiscale
                           , ogpr.num_ordine)
      loop
        w_contarighe := w_contarighe + 1;
        w_riga := ogco.dettaglio_denuncia  ||';'||
                  den.pratica              ||';'||
                  ogco.immobile            ||';'||
                  ogco.cod_fiscale         ||';'||
                  ogco.tipo_rapporto       ||';'||
                  ogco.num_ordine          ||';'||
                  ogco.categoria_catasto   ||';'||
                  ogco.classe_catasto      ||';'||
                  ogco.imm_storico         ||';'||
                  ogco.tipo_oggetto        ||';'||
                  ogco.valore              ||';'||
                  ogco.detrazione          ||';'||
                  ogco.perc_possesso       ||';'||
                  ogco.mesi_possesso       ||';'||
                  ogco.mesi_possesso_1sem  ||';'||
                  ogco.flag_possesso       ||';'||
                  ogco.mesi_esclusione     ||';'||
                  ogco.flag_esclusione     ||';'||
                  ogco.mesi_riduzione      ||';'||
                  ogco.flag_riduzione      ||';'||
                  ogco.mesi_al_ridotta     ||';'||
                  ogco.flag_al_ridotta     ||';'||
                  ogco.flag_ab_principale  ||';'||
                  ogco.note                ||';'||
                  ogco.utente              ||';'||
                  ogco.pertinenza_di       ||';';
  --
        EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Oggetto pratica'
                                       , ogco.dettaglio_denuncia
                                       , w_contarighe
                                       , w_riga
                                       );
      end loop;
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure ALIQUOTE_IMMOBILE
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        ALIQUOTE_IMMOBILE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati relativi alle aliquote
                 oggetti contribuente delle denunce del tipo tributo e dell'anno
                 indicati, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento denunce: si selezionano prima le testate, poi per ogni
  -- testata si trattano i relativi dettagli selezionando i dati da
  -- oggetti_contribuente, in modo da trattare anche eventuali contitolari
  --
    for den in (select prtr.cod_fiscale
                     , prtr.pratica
                  from pratiche_tributo prtr
                 where upper(p_tipo_tributo) like '%'||prtr.tipo_tributo||'%'
                   and prtr.tipo_pratica||''       = 'D'
                   and prtr.anno                   between nvl(p_anno_iniz,0)
                                                       and nvl(p_anno_fine,9999)
                 order by prtr.cod_fiscale
                        , prtr.pratica)
    loop
      --
      -- Trattamento oggetti contribuente
      --
      for ogco in (select ogco.cod_fiscale
                        , ogpr.oggetto_pratica dettaglio_denuncia
                        , to_number(to_char(aloc.dal,'yyyymmdd')) dal
                        , to_number(to_char(aloc.al,'yyyymmdd')) al
                        , aloc.tipo_aliquota
                        , aloc.note
                     from oggetti_pratica      ogpr
                        , oggetti_contribuente ogco
                        , aliquote_ogco        aloc
                    where ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and ogco.cod_fiscale     = aloc.cod_fiscale
                      and ogpr.oggetto_pratica = aloc.oggetto_pratica
                      and ogpr.pratica         = den.pratica
                    order by ogco.cod_fiscale
                           , ogpr.oggetto_pratica
                           , aloc.dal)
      loop
        w_contarighe := w_contarighe + 1;
        w_riga := ogco.cod_fiscale         ||';'||
                  ogco.dettaglio_denuncia  ||';'||
                  ogco.dal                 ||';'||
                  ogco.al                  ||';'||
                  ogco.tipo_aliquota       ||';'||
                  ogco.note                ||';';
  --
        EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Oggetto pratica (aliq.)'
                                       , ogco.dettaglio_denuncia
                                       , w_contarighe
                                       , w_riga
                                       );
      end loop;
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
----------------------------------------------------------------------------------
  procedure DETRAZIONI_IMMOBILE
  ( p_tipo_tributo                   varchar2
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        DETRAZIONI_IMMOBILE.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI i dati relativi alle detrazioni
                 oggetti contribuente delle denunce del tipo tributo e dell'anno
                 indicati, secondo il tracciato previsto.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento denunce: si selezionano prima le testate, poi per ogni
  -- testata si trattano i relativi dettagli selezionando i dati da
  -- oggetti_contribuente, in modo da trattare anche eventuali contitolari
  --
    for den in (select prtr.cod_fiscale
                     , prtr.pratica
                  from pratiche_tributo prtr
                 where upper(p_tipo_tributo) like '%'||prtr.tipo_tributo||'%'
                   and prtr.tipo_pratica||''       = 'D'
                   and prtr.anno                   between nvl(p_anno_iniz,0)
                                                       and nvl(p_anno_fine,9999)
                 order by prtr.cod_fiscale
                        , prtr.pratica)
    loop
      --
      -- Trattamento oggetti contribuente
      --
      for ogco in (select ogco.cod_fiscale
                        , ogpr.oggetto_pratica dettaglio_denuncia
                        , deoc.anno
                        , deoc.motivo_detrazione
                        , deoc.detrazione
                        , deoc.detrazione_acconto
                        , deoc.note
                     from oggetti_pratica      ogpr
                        , oggetti_contribuente ogco
                        , detrazioni_ogco      deoc
                    where ogpr.oggetto_pratica = ogco.oggetto_pratica
                      and ogco.cod_fiscale     = deoc.cod_fiscale
                      and ogpr.oggetto_pratica = deoc.oggetto_pratica
                      and ogpr.pratica         = den.pratica
                    order by ogco.cod_fiscale
                           , ogpr.oggetto_pratica
                           , deoc.anno)
      loop
        w_contarighe := w_contarighe + 1;
        w_riga := ogco.cod_fiscale         ||';'||
                  ogco.dettaglio_denuncia  ||';'||
                  ogco.anno                ||';'||
                  ogco.motivo_detrazione   ||';'||
                  ogco.detrazione          ||';'||
                  ogco.detrazione_acconto  ||';'||
                  ogco.note                ||';';
  --
        EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Oggetto pratica (aliq.)'
                                       , ogco.dettaglio_denuncia
                                       , w_contarighe
                                       , w_riga
                                       );
      end loop;
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure DETRAZIONI_FIGLI
  ( p_anno_iniz              number   default null
  , p_anno_fine              number   default null
  , p_num_record             in out number
  ) is
  /******************************************************************************
    NOME:        DETRAZIONI_FIGLI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 nella tabella DETRAZIONI_FIGLI, secondo il tracciato
                 previsto, con possibilita di selezionare un intervallo di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento detrazioni figli
  --
    for defi in (select cod_fiscale
                      , anno
                      , da_mese
                      , a_mese
                      , numero_figli
                      , detrazione
                      , detrazione_acconto
                      , note
                   from DETRAZIONI_FIGLI
                  where anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2,3)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := defi.cod_fiscale           ||';'||
                defi.anno                  ||';'||
                defi.da_mese               ||';'||
                defi.a_mese                ||';'||
                defi.numero_figli          ||';'||
                defi.detrazione            ||';'||
                defi.detrazione_acconto    ||';'||
                defi.note                  ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Detrazioni figli'
                                     , defi.cod_fiscale||'/'||defi.anno||'/'||defi.da_mese
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure MAGGIORI_DETRAZIONI
  ( p_tipo_tributo                   varchar2 default null
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        MAGGIORI_DETRAZIONI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 in tabella MAGGIORI_DETRAZIONI, secondo il tracciato previsto,
                 con possibilita di selezionare il tipo tributo e un intervallo
                 di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento aliquote
  --
    for made in (select cod_fiscale
                      , tipo_tributo
                      , anno
                      , motivo_detrazione
                      , detrazione
                      , detrazione_acconto
                      , note
                   from MAGGIORI_DETRAZIONI
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                    and anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2,3)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := made.cod_fiscale           ||';'||
                made.tipo_tributo          ||';'||
                made.anno                  ||';'||
                made.motivo_detrazione     ||';'||
                made.detrazione            ||';'||
                made.detrazione_acconto    ||';'||
                made.note                  ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Magg.detrazioni'
                                     , made.cod_fiscale||'/'||made.tipo_tributo||'/'||made.anno
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure PROVVEDIMENTI
  ( p_tipo_tributo                   varchar2 default null
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        PROVVEDIMENTI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutti gli accertamenti,
                 liquidazioni e rimborsi, secondo il tracciato previsto,
                 con possibilita di selezionare il tipo tributo e un intervallo
                 di anni.
    RITORNA:
    NOTE:
    Rev.  Date        Author      Note
    01    15/04/2016  VD          Ora si trattano tutti gli stati accertamento.
                                  e le pratiche raggruppate in pratiche di
                                  tipo "G" (ingiunzioni).
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento provvedimenti
  --
    for prov in (select prtr.pratica
                      , sogg.cognome_nome
                      , cont.cod_fiscale
                      , prtr.tipo_tributo
                      , prtr.anno
                      , prtr.numero
                      , to_number(to_char(prtr.data,'yyyymmdd')) data
                      , to_number(to_char(prtr.data_notifica,'yyyymmdd')) data_notifica
                      , sogg.cognome
                      , sogg.nome
                      , prtr.stato_accertamento
                      , prtr.importo_totale
                      , prtr.importo_ridotto
                      , f_versato_pratica(prtr.pratica) importo_versato
                      , decode(prtr.tipo_pratica,'L',decode(greatest(prtr.importo_totale,0),0,'R','L')
                                                ,prtr.tipo_pratica) tipo_pratica
                      , nvl(prtr.flag_denuncia,'N') flag_denuncia
                   from PRATICHE_TRIBUTO prtr
                      , SOGGETTI         sogg
                      , CONTRIBUENTI     cont
                  where sogg.ni                          = cont.ni
                    and cont.cod_fiscale                 = prtr.cod_fiscale
                    and upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                    and prtr.tipo_pratica                in ('A','L')
                    and prtr.tipo_evento                 in ('U','T','R')
--                    and nvl(prtr.stato_accertamento,'D') = 'D'
                    and prtr.data_notifica               is not null
                    and prtr.anno                        between nvl(p_anno_iniz,0)
                                                             and nvl(p_anno_fine,9999)
                    and (prtr.pratica_rif is null or
                        (prtr.pratica_rif is not null and
                         substr(f_pratica(prtr.pratica_rif),1,1) = 'G'))
               order by 2 asc         -- cognome e nome
                      , 4 asc         -- anno
                      , 5 asc         -- data emissione
                      , 6 asc)        -- data notifica
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := prov.pratica               ||';'||
                prov.cognome_nome          ||';'||
                prov.cod_fiscale           ||';'||
                prov.tipo_tributo          ||';'||
                prov.anno                  ||';'||
                prov.numero                ||';'||
                prov.data                  ||';'||
                prov.data_notifica         ||';'||
                prov.cognome               ||';'||
                prov.nome                  ||';'||
                prov.stato_accertamento    ||';'||
                prov.importo_totale        ||';'||
                prov.importo_ridotto       ||';'||
                prov.importo_versato       ||';'||
                prov.tipo_pratica          ||';'||
                prov.flag_denuncia         ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Provvedimenti'
                                     , prov.pratica
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure SANZIONI_PROVVEDIMENTO
  ( p_tipo_tributo                   varchar2 default null
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        SANZIONI_PROVVEDIMENTO.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutti le sanzioni su
                 provvedimenti secondo il tracciato previsto, con possibilita
                 di selezionare il tipo tributo e un intervallo di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento sanzioni
  --
    for sanz in (select sapr.pratica
                      , sapr.cod_sanzione
                      , sapr.sequenza
                      , sanz.descrizione des_sanzione
                      , sapr.percentuale
                      , rtrim(ltrim(to_char(sapr.importo,'9999999999990D00','NLS_NUMERIC_CHARACTERS = ,.'))) importo
                      , sapr.riduzione
                   from SANZIONI         sanz
                      , SANZIONI_PRATICA sapr
                      , PRATICHE_TRIBUTO prtr
                  where upper(p_tipo_tributo) like '%'||prtr.tipo_tributo||'%'
                    and prtr.anno between nvl(p_anno_iniz,0)
                                      and nvl(p_anno_fine,9999)
                    and sanz.tipo_tributo = prtr.tipo_tributo
                    and sanz.cod_sanzione = sapr.cod_sanzione
                    and sapr.pratica      = prtr.pratica
               order by 1 asc         -- pratica
                      , 4 asc         -- sequenza
                      )
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := sanz.pratica               ||';'||
                sanz.cod_sanzione          ||';'||
                sanz.sequenza              ||';'||
                sanz.des_sanzione          ||';'||
                sanz.percentuale           ||';'||
                sanz.importo               ||';'||
                sanz.riduzione             ||';';
    --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Sanz. provvedimento'
                                     , sanz.pratica||'/'||sanz.cod_sanzione
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
  ----------------------------------------------------------------------------------
  procedure VERSAMENTI
  ( p_tipo_tributo                   varchar2 default null
  , p_anno_iniz                      number   default null
  , p_anno_fine                      number   default null
  , p_num_record                     in out number
  ) is
  /******************************************************************************
    NOME:        VERSAMENTI.
    DESCRIZIONE: Estrae su tabella WRK_TRASMISSIONI tutte le righe presenti
                 in tabella VERSAMENTI, secondo il tracciato previsto,
                 con possibilita di selezionare il tipo tributo e un intervallo
                 di anni.
    RITORNA:
    NOTE:
  ******************************************************************************/
  begin
  --
  -- Controllo tipo tributo
  --
    w_errore:= expstd.controllo_tipo_tributo(p_tipo_tributo);
    if w_errore is not null then
       raise errore;
    end if;
  --
  -- Eliminazione dati elaborazioni precedenti
  --
    EXPSTD.DELETE_WRK_TRASMISSIONI;
    w_contarighe := 0;
  --
  -- Trattamento versamenti
  --
    for vers in (select cod_fiscale
                      , anno
                      , tipo_tributo
                      , sequenza
                      , pratica
                      , tipo_versamento
                      , to_number(to_char(data_pagamento,'yyyymmdd')) data_pagamento
                      , importo_versato
                      , fabbricati num_fabbricati
                      , terreni_agricoli
                      , aree_fabbricabili
                      , ab_principale
                      , altri_fabbricati
                      , detrazione
                      , rurali
                      , terreni_erariale
                      , aree_erariale
                      , altri_erariale
                      , num_fabbricati_ab
                      , num_fabbricati_rurali
                      , num_fabbricati_altri
                      , terreni_comune
                      , aree_comune
                      , altri_comune
                      , num_fabbricati_terreni
                      , num_fabbricati_aree
                      , note
                      , utente
                   from VERSAMENTI
                  where upper(p_tipo_tributo) like '%'||tipo_tributo||'%'
                    and anno between nvl(p_anno_iniz,0)
                                 and nvl(p_anno_fine,9999)
                  order by 1,2,3)
    loop
      w_contarighe := w_contarighe + 1;
      w_riga := vers.cod_fiscale            ||';'||
                vers.anno                   ||';'||
                vers.tipo_tributo           ||';'||
                vers.sequenza               ||';'||
                vers.pratica                ||';'||
                vers.tipo_versamento        ||';'||
                vers.data_pagamento         ||';'||
                vers.importo_versato        ||';'||
                vers.num_fabbricati         ||';'||
                vers.terreni_agricoli       ||';'||
                vers.aree_fabbricabili      ||';'||
                vers.ab_principale          ||';'||
                vers.altri_fabbricati       ||';'||
                vers.detrazione             ||';'||
                vers.rurali                 ||';'||
                vers.terreni_erariale       ||';'||
                vers.aree_erariale          ||';'||
                vers.altri_erariale         ||';'||
                vers.num_fabbricati_ab      ||';'||
                vers.num_fabbricati_rurali  ||';'||
                vers.num_fabbricati_altri   ||';'||
                vers.terreni_comune         ||';'||
                vers.aree_comune            ||';'||
                vers.altri_comune           ||';'||
                vers.num_fabbricati_terreni   ||';'||
                vers.num_fabbricati_aree    ||';'||
                vers.note                   ||';'||
                vers.utente                 ||';';
  --
      EXPSTD.INSERT_WRK_TRASMISSIONI ( 'Versamenti'
                                     , vers.cod_fiscale||'/'||vers.anno||'/'||vers.tipo_tributo
                                     , w_contarighe
                                     , w_riga
                                     );
    end loop;
  --
    p_num_record := w_contarighe;
    w_errore := EXPSTD.CONTROLLO_RIGHE_ESTRATTE(w_contarighe);
    if w_errore is not null then
       raise errore;
    end if;
  --
  exception
    when errore then
      raise_application_error(-20999,w_errore);
    when others then
      raise;
  end;
--
end EXPSTD;
/

