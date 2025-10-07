--liquibase formatted sql 
--changeset abrandolini:20250326_152429_utenze_tarsu_ftp stripComments:false runOnChange:true 
 
CREATE OR REPLACE package     UTENZE_TARSU_FTP is
/******************************************************************************
 NOME:        UTENZE_TARSU_FTP
 DESCRIZIONE: Procedure e Funzioni per estrazione dati utenze TARSU
              per comuni della regione Toscana.

 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 003   17/08/2023  AB      Gestione corretta della data_variazione per le pratriche cessate
                           utilizzando una nuova function f_data_variazione
 002   29/04/2022  AB      Gestione data di cessazione anche per le chiusure di pratiche di cessazione, non variazxione
 001   13/03/2020  VD      Modifiche per gestione lancio manuale
 000   06/02/2020  VD      Prima emissione.
******************************************************************************/

  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '3    17/08/2023';

  function VERSIONE
  return varchar2;

  --Generali
  procedure COMPOSIZIONE_NOME_FILE;

  function F_GET_ULTIMO_ID
  return number;

  function F_GET_NOME_FILE
  ( a_id_documento          IN     number
  ) return varchar2;

  procedure INSERT_FTP_LOG
  ( a_messaggio             IN     varchar2
  );

  procedure INSERT_FTP_TRASMISSIONI
  ( a_clob_file             IN     clob
  );

  procedure UPDATE_FTP_TRASMISSIONI
  ( a_clob_file             IN     clob
  );

  procedure INSERT_WRK_TRASMISSIONI
  ( a_clob_file             IN     clob
  );

  procedure ESTRAZIONE_UTENZE_TARSU
  ( a_data_rif              date
  , a_tipo_elab             varchar2
  , a_righe_estratte        OUT number
  );

  procedure ESEGUI
  ( a_utente                varchar2
  );
end UTENZE_TARSU_FTP;
/
CREATE OR REPLACE package body     UTENZE_TARSU_FTP is
/******************************************************************************
 NOME:        UTENZE_TARSU_FTP
 DESCRIZIONE: Procedure e Funzioni per estrazione dati Ecuosacco e
              trasferimento file.

 ANNOTAZIONI: -

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   06/02/2020  VD      Prima emissione.
******************************************************************************/
 p_sequenza                number;
 p_id_documento            number;
 p_utente                  varchar2(8);
 p_nome_file               varchar2(100);
 p_nome_file_parziale      varchar2(100);
 p_file_clob               clob;
 p_conta_righe             number;
 p_tipo_export             number;

function VERSIONE return varchar2
is
begin
  return s_versione||'.'||s_revisione;
end versione;

--------------------------------------------------------------------------------------------------------
--Generali
--------------------------------------------------------------------------------------------------------
procedure COMPOSIZIONE_NOME_FILE
is
/******************************************************************************
 NOME:        COMPOSIZIONE_NOME_FILE
 DESCRIZIONE: Composizione del nome del file da esportare in base ai
              parametri presenti in tipi_export.

 PARAMETRI:

 NOTE:
******************************************************************************/
  w_nome_file_parziale            varchar2(100);
  w_prefisso_nome_file            varchar2(20);
  w_suffisso_nome_file            varchar2(20);
  w_estensione_nome_file          varchar2(100);
begin
  -- Si seleziona il nome del file da tipi_export
  begin
    select tipo_export
         , nome_file
         , f_pref_nome_file(prefisso_nome_file,tipo_export)
         , f_pref_nome_file(suffisso_nome_file,tipo_export)
         , estensione_nome_file
      into p_tipo_export
         , w_nome_file_parziale
         , w_prefisso_nome_file
         , w_suffisso_nome_file
         , w_estensione_nome_file
      from tipi_export
     where nome_procedura = 'UTENZE_TARSU_FTP.ESTRAZIONE_UTENZE_TARSU';
  exception
    when no_data_found then
      p_tipo_export := to_number(null);
  end;
  --
  if p_tipo_export is null then
     p_nome_file := 'utenze_tari'||to_char(sysdate,'yyyymmddhh24miss')||'.csv';
     p_nome_file_parziale := 'utenze_tari'||'%'||'.csv';
  else
     p_nome_file := w_prefisso_nome_file||w_nome_file_parziale||
                    w_suffisso_nome_file||w_estensione_nome_file;
     p_nome_file_parziale := w_prefisso_nome_file||w_nome_file_parziale||
                             '%'||w_estensione_nome_file;
  end if;
end composizione_nome_file;
--------------------------------------------------------------------------------
function F_GET_ULTIMO_ID
return number
is
/******************************************************************************
 NOME:        F_GET_ULTIMO_ID
 DESCRIZIONE: Restituisce l'id. documento dell'ultima riga inserita in
              FTP_TRASMISSIONI per il file che si sta trattando.

 PARAMETRI:
 RETURN:      Number      Id_documento dell'ultima riga inserita per il file
                          che si sta trattando

 NOTE:
******************************************************************************/
  w_id_documento                  number;
begin
  -- Si compone il nome del file da ricercare
  composizione_nome_file;
  select max(id_documento)
    into w_id_documento
    from ftp_trasmissioni
   where nome_file like p_nome_file_parziale;
     --and direzione = 'U';
  --
  return w_id_documento;
end f_get_ultimo_id;
--------------------------------------------------------------------------------
function F_GET_NOME_FILE
( a_id_documento                  number
) return varchar2
is
/******************************************************************************
 NOME:        F_GET_NOME_FILE
 DESCRIZIONE: Inserimento tabella di Log (FTP_LOG).

 PARAMETRI:
 RETURN:      Number      Id_documento dell'ultima riga inserita per il file
                          che si sta trattando

 NOTE:
******************************************************************************/
  w_nome_file                     varchar2(100);
begin
  -- Si compone il nome del file da ricercare
  begin
    select nome_file
      into w_nome_file
      from ftp_trasmissioni
     where id_documento = a_id_documento;
       --and direzione = 'U';
  exception
    when others then
      w_nome_file := null;
  end;
  --
  return w_nome_file;
end f_get_nome_file;
--------------------------------------------------------------------------------
procedure INSERT_FTP_LOG
( a_messaggio             IN     varchar2
) is
/******************************************************************************
 NOME:        INSERT_FTP_LOG
 DESCRIZIONE: Inserimento tabella di Log (FTP_LOG).

 PARAMETRI:   a_messaggio         Descrizione operazione eseguita.

 NOTE:
******************************************************************************/
begin
  p_sequenza := p_sequenza + 1;
  --
  -- Inserimento log
  --
  begin
    insert into ftp_log ( id_documento
                        , sequenza
                        , messaggio
                        , utente
                        , data_variazione
                        )
    values ( p_id_documento
           , p_sequenza
           , a_messaggio
           , p_utente
           , sysdate
           );
  exception
    when others then
      raise_application_error(-20999,'Errore in inserimento LOG: '||sqlerrm);
  end;
--
  COMMIT;
--
end insert_ftp_log;
--------------------------------------------------------------------------------
procedure INSERT_FTP_TRASMISSIONI
( a_clob_file             IN     clob
) is
/******************************************************************************
 NOME:        INSERT_FTP_TRASMISSIONI
 DESCRIZIONE: Inserimento tabella file da trasmettere (FTP_TRASMISSIONI).

 PARAMETRI:   a_clob_file         clob contenente il file da inviare

 NOTE:
******************************************************************************/
begin
  begin
    insert into ftp_trasmissioni ( id_documento
                                 , nome_file
                                 , clob_file
                                 , utente
                                 , data_variazione
                                 --, direzione
                                 )
    values ( p_id_documento
           , p_nome_file
           , a_clob_file
           , p_utente
           , trunc(sysdate)
           --, 'U'
           );
  exception
    when others then
      insert_ftp_log(substr('Insert FTP_TRASMISSIONI : '||sqlerrm,1,2000));
  end;
end insert_ftp_trasmissioni;
--------------------------------------------------------------------------------
procedure UPDATE_FTP_TRASMISSIONI
( a_clob_file             IN     clob
) is
/******************************************************************************
 NOME:        UPDATE_FTP_TRASMISSIONI
 DESCRIZIONE: Aggiornamento clob in tabella file da trasmettere
              (FTP_TRASMISSIONI).

 PARAMETRI:   p_clob_file         clob contenente il file da inviare

 NOTE:
******************************************************************************/
begin
  begin
    update ftp_trasmissioni
       set clob_file = a_clob_file
     where id_documento = p_id_documento
       and nome_file = p_nome_file;
       --and direzione = 'U';
  exception
    when others then
      insert_ftp_log(substr('Update FTP_TRASMISSIONI : '||sqlerrm,1,2000));
  end;
end update_ftp_trasmissioni;
--------------------------------------------------------------------------------
procedure INSERT_WRK_TRASMISSIONI
( a_clob_file             IN     clob
) is
/******************************************************************************
 NOME:        INSERT_WRK_TRASMISSIONI
 DESCRIZIONE: Inserimento clob nella tabella standard di esportazione dati
              (WRK_TRASMISSIONI).

 PARAMETRI:   a_clob_file         clob contenente il file da salvare

 NOTE:
******************************************************************************/
begin
  begin
    insert into wrk_trasmissioni ( numero
                                 , dati_clob
                                 )
    values ( lpad('1',15,'0')
           , a_clob_file
           );
  exception
    when others then
      raise_application_error(-20999,'Errore in inserimento WRK_TRASMISSIONI: '||sqlerrm);
  end;
end insert_wrk_trasmissioni;
--------------------------------------------------------------------------------
procedure ESTRAZIONE_UTENZE_TARSU
( a_data_rif                date
, a_tipo_elab               varchar2
, a_righe_estratte          OUT number
) is
/*************************************************************************
 NOME:        ESTRAZIONE_TARSU_TARSU

 DESCRIZIONE: Estrazione dati utenze TARSU con invio via FTP
              per i comuni della regione TOSCANA

 NOTE:

 Rev.    Date         Author      Note
 000     07/02/2020   VD          Prima emissione.

*************************************************************************/
  w_tipo_tributo                  varchar2(5) := 'TARSU';
  w_separatore                    varchar2(1) := ';';
  w_riga                          varchar2(32000);

  cursor sel_ute is
  -- Situazione iniziale: se la data_rif è 01/01/2015, si estraggono tutte le utenze
  -- valide a oggi e quelle cessate dal 01/01/2015 a oggi
  select
       upper(replace(sogg.cognome,' ','')) cognome_ord
     , upper(replace(sogg.nome,' ',''))    nome_ord
     , cont.cod_fiscale                   cod_contribuente
     , ogva.oggetto                       cod_utenza
     , decode(nvl(cate.flag_domestica,'N'),'S','UD','UND')  tipo_utenza
     , cont.cod_fiscale                   cod_fiscale
     , sogg.partita_iva                   partita_iva
     , sogg.cognome                       cognome
     , sogg.nome                          nome
     , ad4_comune.get_denominazione(dage.pro_cliente,dage.com_cliente) comune_ute
     , decode(ogge.cod_via,null,null
                               ,ogge.indirizzo_localita) localita_ute
     , decode(ogge.cod_via
             ,null,ogge.indirizzo_localita
                  ,arvi_ogge.denom_uff)   indirizzo_ute
     , ogge.cod_via                       cod_via_ute
     , ogge.num_civ                       num_civ_ute
     , ogge.suffisso                      suffisso_ute
     , ad4_provincia.get_sigla(dage.pro_cliente) prov_ute
     , ''                                 cap_ute
     , ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res) comune_res
     , ''                                 localita_res
     , decode(sogg.cod_via
             ,null,sogg.denominazione_via
                  ,arvi_sogg.denom_uff)   indirizzo_res
     , sogg.cod_via                       cod_via_res
     , sogg.num_civ                       num_civ_res
     , sogg.suffisso                      suffisso_res
     , ad4_provincia.get_sigla(sogg.cod_pro_res) prov_res
     , lpad(sogg.cap, 5, '0')         cap_res
     , decode(ogco.flag_ab_principale
             ,null,nvl(ogpr.numero_familiari, cosu.numero_familiari)
                  ,f_numero_familiari_al (cont.ni, trunc(sysdate))) num_componenti
     , ogpr.categoria categoria
     , cate.descrizione des_categoria
     , ogpr.consistenza superficie
     , to_char(ogva.dal,'yyyymmddhh24miss') data_att_ute
     , to_char(ogva.al,'yyyymmddhh24miss')  data_cess_ute
     , '' cod_zona
     , '' coord_lat_ute
     , '' coord_long_ute
     , '' comune_catasto
     , decode(afc.is_numeric(ogge.foglio),1,ogge.foglio,to_number(null)) foglio_catasto
     , ogge.sezione sez_catasto
     , decode(afc.is_numeric(ogge.numero),1,ogge.numero,to_number(null)) part_catasto
     , decode(afc.is_numeric(ogge.subalterno),1,ogge.subalterno,to_number(null)) sub_catasto
  from pratiche_tributo prtr
     , oggetti_pratica ogpr
     , oggetti_contribuente ogco
     , oggetti_validita ogva
     , soggetti sogg
     , contribuenti cont
     , archivio_vie arvi_ogge
     , oggetti ogge
     , archivio_vie arvi_sogg
     , componenti_superficie cosu
     , dati_generali dage
     , categorie cate
 where ogpr.flag_contenzioso is null
   and ogpr.oggetto_pratica = ogva.oggetto_pratica
   and ogco.oggetto_pratica = ogva.oggetto_pratica
   and ogco.cod_fiscale = ogva.cod_fiscale
   and prtr.pratica = ogpr.pratica
   and nvl(prtr.stato_accertamento, 'D') = 'D'
   and sogg.ni = cont.ni
   and cont.cod_fiscale = ogva.cod_fiscale
   and arvi_ogge.cod_via(+) = ogge.cod_via
   and ogge.oggetto(+) = ogpr.oggetto
   and arvi_sogg.cod_via(+) = sogg.cod_via
   and to_number(to_char(sysdate,'yyyy')) = cosu.anno (+)
   and ogpr.consistenza between cosu.da_consistenza(+)
                            and cosu.a_consistenza(+)
   and cate.categoria(+) = ogpr.categoria
   and cate.tributo (+) = ogpr.tributo
   and ogva.tipo_tributo = w_tipo_tributo
   and a_data_rif = to_date('01/01/2015','dd/mm/yyyy')
   and ( ogva.al is null or
       ( ogva.al > a_data_rif
         and not exists (select 'x' from oggetti_validita ogvx
                          where ogvx.tipo_tributo = w_tipo_tributo
                            and ogvx.cod_fiscale = cont.cod_fiscale
                            and ogvx.oggetto = ogva.oggetto
                            and nvl(ogvx.dal,to_date('01011950','ddmmyyyy')) >
                                nvl(ogva.dal,to_date('01011950','ddmmyyyy')))
       )
       )
 union
  select
       upper(replace(sogg.cognome,' ','')) cognome_ord
     , upper(replace(sogg.nome,' ',''))    nome_ord
     , cont.cod_fiscale                   cod_contribuente
     , ogva.oggetto                       cod_utenza
     , decode(nvl(cate.flag_domestica,'N'),'S','UD','UND')  tipo_utenza
     , cont.cod_fiscale                   cod_fiscale
     , sogg.partita_iva                   partita_iva
     , sogg.cognome                       cognome
     , sogg.nome                          nome
     , ad4_comune.get_denominazione(dage.pro_cliente,dage.com_cliente) comune_ute
     , decode(ogge.cod_via,null,null
                               ,ogge.indirizzo_localita) localita_ute
     , decode(ogge.cod_via
             ,null,ogge.indirizzo_localita
                  ,arvi_ogge.denom_uff)   indirizzo_ute
     , ogge.cod_via                       cod_via_ute
     , ogge.num_civ                       num_civ_ute
     , ogge.suffisso                      suffisso_ute
     , ad4_provincia.get_sigla(dage.pro_cliente) prov_ute
     , ''                                 cap_ute
     , ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res) comune_res
     , ''                                 localita_res
     , decode(sogg.cod_via
             ,null,sogg.denominazione_via
                  ,arvi_sogg.denom_uff)   indirizzo_res
     , sogg.cod_via                       cod_via_res
     , sogg.num_civ                       num_civ_res
     , sogg.suffisso                      suffisso_res
     , ad4_provincia.get_sigla(sogg.cod_pro_res) prov_res
     , lpad(sogg.cap, 5, '0')         cap_res
     , decode(ogco.flag_ab_principale
             ,null,nvl(ogpr.numero_familiari, cosu.numero_familiari)
                  ,f_numero_familiari_al (cont.ni, trunc(sysdate))) num_componenti
     , ogpr.categoria categoria
     , cate.descrizione des_categoria
     , ogpr.consistenza superficie
     , to_char(ogva.dal,'yyyymmddhh24miss') data_att_ute
     , to_char(ogva.al,'yyyymmddhh24miss')  data_cess_ute  -- 29/04/2022 AB inserita la sola data di cessazione in caso di chiusura utenza, non se si tratta di variazione
--     , '' data_cess_ute                     -- data cessazione nulla in presenza di variazioni successive
     , '' cod_zona
     , '' coord_lat_ute
     , '' coord_long_ute
     , '' comune_catasto
     , decode(afc.is_numeric(ogge.foglio),1,ogge.foglio,to_number(null)) foglio_catasto
     , ogge.sezione sez_catasto
     , decode(afc.is_numeric(ogge.numero),1,ogge.numero,to_number(null)) part_catasto
     , decode(afc.is_numeric(ogge.subalterno),1,ogge.subalterno,to_number(null)) sub_catasto
  from pratiche_tributo prtr
     , oggetti_pratica ogpr
     , oggetti_contribuente ogco
     , oggetti_validita ogva
     , soggetti sogg
     , contribuenti cont
     , archivio_vie arvi_ogge
     , oggetti ogge
     , archivio_vie arvi_sogg
     , componenti_superficie cosu
     , dati_generali dage
     , categorie cate
 where ogpr.flag_contenzioso is null
   and ogpr.oggetto_pratica = ogva.oggetto_pratica
   and ogco.oggetto_pratica = ogva.oggetto_pratica
   and ogco.cod_fiscale = ogva.cod_fiscale
   and prtr.pratica = ogpr.pratica
   and nvl(prtr.stato_accertamento, 'D') = 'D'
   and sogg.ni = cont.ni
   and cont.cod_fiscale = ogva.cod_fiscale
   and arvi_ogge.cod_via(+) = ogge.cod_via
   and ogge.oggetto(+) = ogpr.oggetto
   and arvi_sogg.cod_via(+) = sogg.cod_via
   and to_number(to_char(sysdate,'yyyy')) = cosu.anno (+)
   and ogpr.consistenza between cosu.da_consistenza(+)
                            and cosu.a_consistenza(+)
   and cate.categoria(+) = ogpr.categoria
   and cate.tributo (+) = ogpr.tributo
   and ogva.tipo_tributo = w_tipo_tributo
   and a_data_rif > to_date('01/01/2015','dd/mm/yyyy')
--   and ogco.data_variazione
   and f_data_variazione(ogva.cod_fiscale, ogva.oggetto_pratica,ogva.oggetto_pratica_rif,ogva.al)
                            between a_data_rif
                                and trunc(sysdate)
   and ( ogva.al is null or
       ( ogva.al > a_data_rif  -- 29/04/2022 AB inserita il controllo per estrarre anche quelli con data di cessazione in caso di chiusura utenza, non se si tratta di variazione
         and not exists (select 'x' from oggetti_validita ogvx
                          where ogvx.tipo_tributo = w_tipo_tributo
                            and ogvx.cod_fiscale = cont.cod_fiscale
                            and ogvx.oggetto = ogva.oggetto
                            and nvl(ogvx.dal,to_date('01011950','ddmmyyyy')) >
                                nvl(ogva.dal,to_date('01011950','ddmmyyyy')))
       )
       )
   order by 1,2,3;

begin
  -- (VD - 13/03/2020): spostato svuotamento variabile clob (di package) per eventuali
  --                    utilizzi in PB (o per lanci consecutivi)
  if p_nome_file is null then
     composizione_nome_file;
  end if;
  p_file_clob := '';
  p_conta_righe := 0;
  -- Estrazione per FTP:
  -- assegnazione id. per inserimento ftp_log e ftp_trasmissioni
  -- per estrazione utenze
  -- Inserimento riga in tabella ftp_trasmissioni per reference a ftp_log
  -- Inserimento inizio elaborazione in tabella FTP_LOG
  -- (VD - 13/03/2020): si e' deciso di inserire in FTP_TRASMISSIONI anche gli
  --                    eventuali file estratti manualmente da PB
  --if p_tipo_elab = 'F' then
     p_id_documento := to_number(null);
     ftp_trasmissioni_nr(p_id_documento);
     p_sequenza := 0;
     insert_ftp_trasmissioni(p_file_clob);
     insert_ftp_log('Inizio estrazione utenze: '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss'));
     commit;
  --end if;

  for rec_ute in sel_ute
  loop
    -- Se si sta trattando la prima riga, si inserisce prima l'intestazione
    if p_conta_righe = 0 then
       w_riga := 'COD_CONTRIBUENTE;COD_UTENZA;TIPO_UTENZA;COD_FISCALE;PARTITA_IVA;'||
                 'COGNOME/RAG_SOG;NOME;COMUNE_UTENZA;LOCALITA_UTENZA;INDIRIZZO_UTENZA;'||
                 'COD_VIA_UTENZA;NUM_CIV_UTENZA;BARRATO_UTENZA;PROVINCIA_UTENZA;'||
                 'CAP_UTENZA;COMUNE_RES;LOCALITA_RES;INDIRIZZO_RES;COD_VIA_RES;'||
                 'NUM_CIV_RES;BARRATO_RES;PROVINCIA_RES;CAP_RES;'||
                 'NUM_COMPONENTI;COD_CATEGORIA;DES_CATEGORIA;SUPERFICIE;'||
                 'DATA_ATT_UTENZA;DATA_CESS_UTENZA;COD_ZONA;COORD_LAT_UTENZA;'||
                 'COORD_LONG_UTENZA;COMUNE_CATASTO;FOGLIO_CATASTO;SEZIONE_CATASTO;'||
                 'PARTICELLA_CATASTO;SUBALTERNO_CATASTO;';
       p_conta_righe := p_conta_righe + 1;
       p_file_clob := p_file_clob||w_riga||chr(13)||chr(10);
    end if;
    -- Composizione riga
    w_riga := rec_ute.cod_contribuente||w_separatore||
              rec_ute.cod_utenza      ||w_separatore||
              rec_ute.tipo_utenza     ||w_separatore||
              rec_ute.cod_fiscale     ||w_separatore||
              rec_ute.partita_iva     ||w_separatore||
              rec_ute.cognome         ||w_separatore||
              rec_ute.nome            ||w_separatore||
              rec_ute.comune_ute      ||w_separatore||
              rec_ute.localita_ute    ||w_separatore||
              rec_ute.indirizzo_ute   ||w_separatore||
              rec_ute.cod_via_ute     ||w_separatore||
              rec_ute.num_civ_ute     ||w_separatore||
              rec_ute.suffisso_ute    ||w_separatore||
              rec_ute.prov_ute        ||w_separatore||
              rec_ute.cap_ute         ||w_separatore||
              rec_ute.comune_res      ||w_separatore||
              rec_ute.localita_res    ||w_separatore||
              rec_ute.indirizzo_res   ||w_separatore||
              rec_ute.cod_via_res     ||w_separatore||
              rec_ute.num_civ_res     ||w_separatore||
              rec_ute.suffisso_res    ||w_separatore||
              rec_ute.prov_res        ||w_separatore||
              rec_ute.cap_res         ||w_separatore||
              rec_ute.num_componenti  ||w_separatore||
              rec_ute.categoria       ||w_separatore||
              rec_ute.des_categoria   ||w_separatore||
              rec_ute.superficie      ||w_separatore||
              rec_ute.data_att_ute    ||w_separatore||
              rec_ute.data_cess_ute   ||w_separatore||
              rec_ute.cod_zona        ||w_separatore||
              rec_ute.coord_lat_ute   ||w_separatore||
              rec_ute.coord_long_ute  ||w_separatore||
              rec_ute.comune_catasto  ||w_separatore||
              rec_ute.foglio_catasto  ||w_separatore||
              rec_ute.sez_catasto     ||w_separatore||
              rec_ute.part_catasto    ||w_separatore||
              rec_ute.sub_catasto     ||w_separatore;

    -- Si aggiunge la riga al file clob
    p_conta_righe := p_conta_righe + 1;
    p_file_clob := p_file_clob||w_riga||chr(13)||chr(10);
  end loop;
--
  a_righe_estratte := p_conta_righe;
  -- Registrazione file in clob: se tipo_elab = 'F' nella tabella ftp_trasmissioni
  -- altrimenti nella tabella wrk_trasmissioni
  -- (VD - 13/03/2020): si e' deciso di inserire in FTP_TRASMISSIONI anche gli
  --                    eventuali file estratti manualmente da PB
  --if a_tipo_elab = 'F' then
     update_ftp_trasmissioni(p_file_clob);
     insert_ftp_log('Fine estrazione utenze: '||to_char(sysdate,'dd/mm/yyyy hh24.mi.ss')||
                    ', Righe inserite '||p_conta_righe);
  -- (VD - 13/03/2020): si aggiorna il parametro di export "data riferimento"
  --                    in modo che, in caso di lancio manuale, proponga la data
  --                    dell'ultima elaborazione
  if a_tipo_elab = 'F' then
     begin
       update parametri_export
          set ultimo_valore = decode(ultimo_valore,null,null,
                                     to_char(greatest(to_date(ultimo_valore,'dd/mm/yyyy'),
                                                      trunc(sysdate)),
                                             'dd/mm/yyyy')
                                    )
        where tipo_export = p_tipo_export
          and nome_parametro = 'Data riferimento';
     exception
       when others then
         insert_ftp_log(substr('Update PARAMETRI_EXPORT : '||sqlerrm,1,2000));
     end;
     commit;
  else
     insert_wrk_trasmissioni(p_file_clob);
  end if;
end estrazione_utenze_tarsu;

--------------------------------------------------------------------------------

procedure ESEGUI
( a_utente                        varchar2
) is
/*************************************************************************
 NOME:        ESEGUI

 DESCRIZIONE: Esegue la procedure per estrarre il file.

 NOTE:

 Rev.    Date         Author      Note
 000     06/02/2020   VD          Prima emissione.

*************************************************************************/
  w_tipo_elab                     varchar2(1) := 'F';
  w_data_rif                      date;
begin
  p_utente := a_utente;
  composizione_nome_file;
  -- Si seleziona la data dell'ultima estrazione eseguita
  --
  begin
    select max(trunc(data_variazione))
      into w_data_rif
      from ftp_trasmissioni
     where nome_file like p_nome_file_parziale
       and data_variazione != to_date('17/08/2023','dd/mm/yyyy');
       -- and direzione = 'U';
  exception
    when others then
      w_data_rif := to_date(null);
  end;
  w_data_rif := nvl(w_data_rif,to_date('01/01/2015','dd/mm/yyyy'));
--  w_data_rif := to_date('01/01/2015','dd/mm/yyyy'); 18/05/2022 AB: forzatura per poter eseguire l'estrazione completa
--  w_data_rif := to_date('01/05/2022','dd/mm/yyyy'); -- 17/08/2023 AB: forzatura per poter eseguire l'estrazione dell'ultimo anno
  estrazione_utenze_tarsu(w_data_rif,w_tipo_elab,p_conta_righe);
end esegui;

end UTENZE_TARSU_FTP;
/
