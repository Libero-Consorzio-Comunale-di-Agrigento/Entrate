--liquibase formatted sql 
--changeset abrandolini:20250326_152429_popolamento_imu_catasto stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE     POPOLAMENTO_IMU_CATASTO IS
  /******************************************************************************************
   Versione  Data              Autore    Descrizione
   1         30/05/2018        DM        Prima implementazione.
   2         27/10/2022        DM        Gestione terreni.
   3         06/12/2022        AB        Gestione estremi_catasto e controllo
                                         da_mese, test categoria_catasto per T
   4         28/12/2022        AB        Aggiunta degli oggetti con data_fine_validita nulla
                                         e modificate le date di inizio e fine validita
                                         utilizzando anche la data_efficacia e fine efficacia
   5         17/10/2023        AB        sistemato il controllo di flag_ab_principale
                                         e utilizzato estremi_castasto anziche le nvl dei singoli campi
  ********************************************************************************************/
  /*************************************************************************
  a_tipo_immobile F: Fabbricati
                  T: Terreni
                  X: Fabbricati e Terreni
  *************************************************************************/
  function crea_dichiarazioni(a_cod_fiscale   varchar2 default '%',
                              a_anno          number,
                              a_fonte         number,
                              a_storico       varchar2,
                              a_tipo_immobile varchar2,
                              a_passo_commit  number default 100) return clob;
END POPOLAMENTO_IMU_CATASTO;
/
CREATE OR REPLACE package body     popolamento_imu_catasto is
  w_utente varchar2(6) := 'CIMU';
  type type_prtr is table of pratiche_tributo.pratica%type index by varchar2(4);
  t_prtr         type_prtr;
  t_empty_prtr   type_prtr;
  w_log          clob;
  w_cod_fiscale  varchar2(16);
  w_cognome_nome varchar2(100);
  cursor sel_oggetti(p_cod_fiscale varchar2, p_tipo_immobile varchar2) is
    select imm.cod_fiscale_ric,
           imm.tipo_immobile,
           imm.contatore,
           greatest(imm.data_validita,imm.data_efficacia) data_validita,
           nvl(imm.data_fine_validita,imm.data_fine_efficacia - 1) data_fine_validita,
--           imm.data_validita,
--           imm.data_fine_validita,
           imm.data_efficacia,
           imm.data_fine_efficacia,
           imm.partita,
           imm.indirizzo,
           imm.num_civ,
           imm.scala,
           imm.piano,
           case
              when afc.is_number(imm.interno ) = 0 then null
              else
              imm.interno
           end interno,
           imm.sezione,
           imm.foglio,
           imm.numero,
           imm.subalterno,
           imm.zona,
           imm.numeratore,
           imm.denominatore,
           imm.categoria,
           imm.classe,
           imm.consistenza,
           imm.rendita,
           imm.cod_titolo,
           null qualita,
           imm.estremi_catasto
      from immobili_soggetto_cc imm
     where
    -- Elimina i casi incongruenti
     nvl(imm.data_fine_validita, to_date('99990101', 'YYYYMMDD')) >
     imm.data_validita
     and imm.data_efficacia =
     (select min(icub.data_efficacia)
        from immobili_soggetto_cc icub
       where icub.cod_fiscale_ric = imm.cod_fiscale_ric
         and icub.estremi_catasto = imm.estremi_catasto
      )
     and imm.cod_fiscale_ric = p_cod_fiscale
     and p_tipo_immobile = 'F'
     and imm.progr_identificativo = 1  -- (27/12/2022) AB per evitare di trattare immobili stesso ID_IMMOBILE due volte
 union
     select imm.cod_fiscale_ric,
           imm.tipo_immobile,
           imm.contatore,
--           imm.data_validita,
           greatest(imm.data_validita,imm.data_efficacia) data_validita,
           nvl(imm.data_fine_validita,imm.data_fine_efficacia) - 1 data_fine_validita,
           imm.data_efficacia,
           imm.data_fine_efficacia,
           imm.partita,
           imm.indirizzo,
           imm.num_civ,
           imm.scala,
           imm.piano,
           case
              when afc.is_number(imm.interno ) = 0 then null
              else
              imm.interno
           end interno,
           imm.sezione,
           imm.foglio,
           imm.numero,
           imm.subalterno,
           imm.zona,
           imm.numeratore,
           imm.denominatore,
           imm.categoria,
           imm.classe,
           imm.consistenza,
           imm.rendita,
           imm.cod_titolo,
           null qualita,
           imm.estremi_catasto
      from immobili_soggetto_cc imm
     where imm.data_fine_validita is null
       and exists (select 1
                     from immobili_soggetto_cc icub
                    where icub.data_efficacia < imm.data_efficacia
      --              and icub.data_fine_efficacia is not null
           --           and icub.data_fine_validita is null
               --       and icub.data_validita = imm.data_validita
                      and icub.cod_fiscale_ric = imm.cod_fiscale_ric
                      and icub.estremi_catasto = imm.estremi_catasto)
     and imm.cod_fiscale_ric = p_cod_fiscale
     and p_tipo_immobile = 'F'
     and imm.progr_identificativo = 1  -- (27/12/2022) AB per evitare di trattare immobili stesso ID_IMMOBILE due volte
union
    select imm.cod_fiscale_ric,
           'T' tipo_immobile,
           imm.id_immobile contatore,
           greatest(imm.data_validita,imm.data_efficacia) data_validita,
           nvl(imm.data_fine_validita,imm.data_fine_efficacia - 1) data_fine_validita,
--           imm.data_validita,
--           imm.data_fine_validita,
           imm.data_efficacia,
           imm.data_fine_efficacia,
           imm.partita,
           imm.indirizzo,
           imm.num_civ,
           null scala,
           null piano,
           null interno,
           imm.sezione,
           imm.foglio,
           imm.numero,
           imm.subalterno,
           null zona,
           imm.numeratore,
           imm.denominatore,
           null categoria,
           imm.classe,
           null consistenza,
           imm.reddito_dominicale_euro rendita,
           imm.cod_titolo,
           imm.qualita,
           imm.estremi_catasto
      from immobili_catasto_terreni_cc imm
     where
    -- Elimina i casi incongruenti
     nvl(imm.data_fine_validita, to_date('99990101', 'YYYYMMDD')) >
     imm.data_validita
     and imm.data_efficacia =
     (select min(icub.data_efficacia)
        from immobili_catasto_terreni_cc icub
       where icub.cod_fiscale_ric = imm.cod_fiscale_ric
         and icub.estremi_catasto = imm.estremi_catasto
--         and nvl(imm.sezione, ' ') = nvl(icub.sezione, ' ')
--         and nvl(imm.foglio, ' ') = nvl(icub.foglio, ' ')
--         and nvl(imm.numero, ' ') = nvl(icub.numero, ' ')
--         and nvl(imm.subalterno, ' ') = nvl(icub.subalterno, ' ')
      )
     and imm.cod_fiscale_ric = p_cod_fiscale
     and p_tipo_immobile = 'T'
union
    select imm.cod_fiscale_ric,
           'T' tipo_immobile,
           imm.id_immobile contatore,
           greatest(imm.data_validita,imm.data_efficacia) data_validita,
           nvl(imm.data_fine_validita,imm.data_fine_efficacia - 1) data_fine_validita,
--           imm.data_validita,
--           imm.data_fine_validita,
           imm.data_efficacia,
           imm.data_fine_efficacia,
           imm.partita,
           imm.indirizzo,
           imm.num_civ,
           null scala,
           null piano,
           null interno,
           imm.sezione,
           imm.foglio,
           imm.numero,
           imm.subalterno,
           null zona,
           imm.numeratore,
           imm.denominatore,
           null categoria,
           imm.classe,
           null consistenza,
           imm.reddito_dominicale_euro rendita,
           imm.cod_titolo,
           imm.qualita,
           imm.estremi_catasto
      from immobili_catasto_terreni_cc imm
     where imm.data_fine_validita is null
       and exists (select 1
                     from immobili_catasto_terreni_cc icub
                    where icub.data_efficacia < imm.data_efficacia
      --              and icub.data_fine_efficacia is not null
          --            and icub.data_fine_validita is null
               --       and icub.data_validita = imm.data_validita
                      and icub.cod_fiscale_ric = imm.cod_fiscale_ric
                      and icub.estremi_catasto = imm.estremi_catasto)
       and imm.cod_fiscale_ric = p_cod_fiscale
       and p_tipo_immobile = 'T'
   order by 3, 4, 5 nulls first;
  /*------------------------------------------------------------------------------------------------
  PRIVATE
  ------------------------------------------------------------------------------------------------*/
  /*******************************************************************************************************
  Aggiunge unmessaggio al log.
  *******************************************************************************************************/
  procedure aggiungi_messaggio(a_messaggio varchar2) is
  begin
    w_log := w_log || a_messaggio || chr(13);
  end;
  /*******************************************************************************************************
  Determina se una stringa è numerica
  *******************************************************************************************************/
  function is_number(a_valore varchar2) return boolean is
    w_number number(38);
  begin
    w_number := to_number(a_valore);
    return true;
  exception
    when value_error then
      return false;
  end;
  /*******************************************************************************************************
  Converte il numero civico da stringa a numero
  *******************************************************************************************************/
  function f_num_civ_str_to_numb(a_num_civ_str in varchar2) return number is
    w_i         NUMBER := 1;
    w_appoggio  varchar2(30) := null;
    w_controllo varchar2(1);
  begin
    if length(rtrim(a_num_civ_str)) > 0 then
      loop
        BEGIN
          select 'X'
            into w_controllo
            from dual
           where substr(a_num_civ_str, w_i, 1) in
                 ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
        exception
          when others then
            exit;
        end;
        w_appoggio := w_appoggio || substr(a_num_civ_str, w_i, 1);
        w_i        := w_i + 1;
      end loop;
    end if;
    return to_number(w_appoggio);
  end f_num_civ_str_to_numb;
  /*******************************************************************************************************
  Converte i codici diritto della CC_DIRITTI in CODICI_DIRITTO
  *******************************************************************************************************/
  function decodifica_codice_diritto(a_cod_diritto varchar2) return varchar2 is
  begin
    -- ai codici diritto CATASTO da 1 a 10 si aggiunge uno 0
    if (is_number(a_cod_diritto) and to_number(a_cod_diritto) between 10 and 100) then
      return substr(a_cod_diritto, 1, length(a_cod_diritto) - 1);
    end if;
    if (is_number(trim(a_cod_diritto)) and
       to_number(a_cod_diritto) between 12 and 99) then
      return trim(a_cod_diritto);
    end if;
    return a_cod_diritto;
  end;
  /*******************************************************************************************************
  Verifica che si possa procedere con la generazione delle dichiarazioni
  *******************************************************************************************************/
  function verifica(a_cod_fiscale varchar2 default '%', a_anno number)
    return varchar2 is
    ret varchar2(2000);
    -- Messaggi
    msg_pratiche_presenti constant varchar2(150) := 'Esistono pratiche ICI/IMU già presenti dal ' ||
                                                    a_anno ||
                                                    ' per il soggetto ' ||
                                                    a_cod_fiscale;
    w_n_dic_da_anno number;
  begin
--dbms_output.put_line('verifica CF: '||a_cod_fiscale);
    ret := 'OK';
    -- Presenza di dichiarazioni da A_ANNO
    select count(*)
      into w_n_dic_da_anno
      from pratiche_tributo prtr
     where prtr.tipo_tributo = 'ICI'
       and prtr.tipo_pratica = 'D'
       and prtr.cod_fiscale = a_cod_fiscale
       and prtr.anno >= nvl(a_anno, 0);
    if (w_n_dic_da_anno > 0) then
      ret := msg_pratiche_presenti;
    end if;
-- A Occhiobello 28/11/2022
--     If a_cod_fiscale in (
--        'BNZCRL66R13D548D',
--        'LBDBLF78A01Z3P0S',
--        'MNSLAI66R19Z352A',
--        'GLJMRA67D70Z140E',
--        'BRNRFL34C68D577D',
--        'TTLGCM53D23B737A',
--        'HNGHGG85T69Z210O',
--        'LTALDI31E41L049E',
--        'HJHZNB84S54Z220P',--
--        '01230250381',
--        'BVOBRN19R63F994Y',
--        'VLLRSN24D67D788X',
--        'KSTMLT83A08Z118P',
--        'MRNMRA29S24H620M',
--        'RBBGPP70D06B429E',
--        '00351310388',
--        'MGNFNC70D43D122M',
--        '00729680280',
--        'ZRBPBR14A07I953F',
--        'SRDNGS46P56I158W',
--        '02896940273',
--        'BVOGGD60B21G323R',
--        'GMBLSN52P11D548R') then
--        ret := 'CF, da non trattare';
--    end if;
    return ret;
  exception
    when others then
      raise_application_error(-20999,
                              'Check fallito. ' || ' (' || sqlerrm || ')');
  end;
  /*******************************************************************************************************
  Estrae l'anno dalla data
  *******************************************************************************************************/
  function estrai_anno(a_data date) return number is
  begin
    if (a_data is null) then
      return null;
    else
      return extract(year from a_data);
    end if;
  end;
  /*******************************************************************************************************
  Estrae il mese dalla data
  *******************************************************************************************************/
  function estrai_mese(a_data date) return number is
  begin
    if (a_data is null) then
      return null;
    else
      return extract(month from a_data);
    end if;
  end;
  /*******************************************************************************************************
  Estrae il giorno
  *******************************************************************************************************/
  function estrai_giorno(a_data date) return number is
  begin
    if (a_data is null) then
      return null;
    else
      return extract(day from a_data);
    end if;
  end;
  /*******************************************************************************************************
  Determina l'anno di imposta a partire dalla data di validità
  *******************************************************************************************************/
  function estrai_anno_imposta(a_data date) return number is
    w_anno_imposta      number(4) := 1992;
    w_anno_imposta_temp number(4);
  begin
    if (a_data is null) then
      w_anno_imposta := null;
    else
      w_anno_imposta_temp := extract(year from a_data);
      if (w_anno_imposta_temp > w_anno_imposta) then
        w_anno_imposta := w_anno_imposta_temp;
      end if;
    end if;
    return w_anno_imposta;
  end;
  /*******************************************************************************************************
  Crea la string degli estremi catastali
  *******************************************************************************************************/
  function estremi_catasto(a_oggetto sel_oggetti%rowtype) return varchar2 is
    w_estremi_catasto varchar2(20);
  begin
    w_estremi_catasto := a_oggetto.estremi_catasto;
--    w_estremi_catasto := lpad(ltrim(nvl(a_oggetto.sezione, ' '), '0'),
--                              3,
--                              ' ') ||
--                         lpad(ltrim(nvl(a_oggetto.foglio, ' '), '0'),
--                              5,
--                              ' ') ||
--                         lpad(ltrim(nvl(a_oggetto.numero, ' '), '0'),
--                              5,
--                              ' ') ||
--                         lpad(ltrim(nvl(a_oggetto.subalterno, ' '), '0'),
--                              4,
--                              ' ') || lpad(' ', 3);
    return w_estremi_catasto;
  end;
  /*******************************************************************************************************
  Determina se abitazione pricipale
  (VD - 14/01/2021): modificato test in caso di valori nulli: se cod_via e num_civ del soggetto sono nulli
                     e cod_via e num_civ dell'oggetto sono nulli, non possono essere considerati uguali.
                     Corretta anche lunghezza campo cod_via: è di 4 crt (e non di 6)
  *******************************************************************************************************/
  function abitazione_principale(a_ni        number,
                                 a_anno      number,
                                 a_cod_via   number,
                                 a_num_civ   varchar2,
                                 a_categoria varchar2) return varchar2 is
  w_num_civ varchar2(6);
  begin
--        raise_application_error(-20999,
--                                'anno '||a_anno||' cod_via '||a_cod_via||' num_civ '||a_num_civ);
    if a_cod_via is null then
       w_num_civ := null;
    else
       w_num_civ := a_num_civ;
    end if;
    if f_indirizzo_ni_al(a_ni, to_date('31/12/' || a_anno, 'dd/mm/yyyy')) =
       nvl(lpad(a_cod_via, 6, '0'), '      ') ||
       nvl(lpad(w_num_civ, 6, '0'), '      ') and
       a_categoria in ('A01',
                       'A02',
                       'A03',
                       'A04',
                       'A05',
                       'A06',
                       'A07',
                       'A08',
                       'A09',
                       'A11') then
      return 'S';
    else
      return null;
    end if;
  end;
  /*******************************************************************************************************
  Determina il possesso al 31/12
  *******************************************************************************************************/
  function possesso_31_12(a_oggetto sel_oggetti%rowtype) return varchar2 is
    w_anno_inizio number;
    w_anno_fine   number;
  begin
    w_anno_inizio := estrai_anno_imposta(a_oggetto.data_validita);
    w_anno_fine   := estrai_anno(a_oggetto.data_fine_validita);
    if (w_anno_fine is null or w_anno_inizio != w_anno_fine) then
      return 'S';
    else
      return null;
    end if;
  end;
  /*******************************************************************************************************
  Calcola la percentuale di opossesso
  *******************************************************************************************************/
  function calcola_perc_possesso(a_oggetto sel_oggetti%rowtype) return number is
  begin
    return round((a_oggetto.numeratore / a_oggetto.denominatore) * 100, 2);
  end;
  /*******************************************************************************************************
  Calcolo dei mesi di possesso
  *******************************************************************************************************/
  procedure calcola_mp(a_oggetto          in sel_oggetti%rowtype,
                       a_mp               out number,
                       a_mp_1s            out number,
                       a_da_mese_possesso out number) is
    w_data_inizio date;
    w_data_fine   date;
  begin
    if estrai_anno(a_oggetto.data_validita) < 1992 then
      w_data_inizio := to_date('19920101', 'yyyymmdd');
    else
      w_data_inizio := a_oggetto.data_validita;
    end if;
    w_data_fine := a_oggetto.data_fine_validita;
    -- Se data inizio e fine sono nello stesso anno
    if (w_data_fine is not null and
       estrai_anno(w_data_fine) = estrai_anno(w_data_inizio)) then
      a_mp := estrai_mese(w_data_fine) - estrai_mese(w_data_inizio) + 1;
      -- Calcolo MP
      if estrai_giorno(w_data_inizio) > 15 then
        a_mp := a_mp - 1;
      end if;
      if estrai_giorno(w_data_fine) <= 15 then
        a_mp := a_mp - 1;
      end if;
      -- Calcolo MP 1S
      -- Se l'immobile è posseduto solo nei primi 6 mesi
      if estrai_mese(w_data_fine) <= 6 then
        a_mp_1s := a_mp;
      else
        if estrai_mese(w_data_inizio) <= 6 then
          a_mp_1s := 7 - estrai_mese(w_data_inizio);
          if estrai_giorno(w_data_inizio) > 15 then
            a_mp_1s := a_mp_1s - 1;
          end if;
        else
          a_mp_1s := 0;
        end if;
      end if;
    else
      -- Inizio e fine possesso in anni diversi
      -- Calcolo MP
      a_mp := 13 - estrai_mese(w_data_inizio);
      if estrai_giorno(w_data_inizio) > 15 then
        a_mp := a_mp - 1;
      end if;
      -- Calcolo MP 1S
      if estrai_mese(w_data_inizio) <= 6 then
        a_mp_1s := 7 - estrai_mese(w_data_inizio);
        if estrai_giorno(w_data_inizio) > 15 then
          a_mp_1s := a_mp_1s - 1;
        end if;
      else
        a_mp_1s := 0;
      end if;
    end if;
    -- Mese di inizio possesso
    a_da_mese_possesso := estrai_mese(w_data_inizio)
    ;
    if estrai_giorno(w_data_inizio) > 15 then
       a_da_mese_possesso := a_da_mese_possesso + 1;
    end if;
  end;
  /*******************************************************************************************************
  Recupera, se presente, il codice della via
  *******************************************************************************************************/
  function get_cod_via(a_oggetto sel_oggetti%rowtype) return varchar2 is
    w_cod_via varchar2(100);
  begin
    begin
      select distinct devi.cod_via
        into w_cod_via
        from denominazioni_via devi
       where devi.descrizione like a_oggetto.indirizzo || '%';
    exception
      when no_data_found then
        begin
            select distinct devi.cod_via
            into w_cod_via
            from denominazioni_via devi
            where a_oggetto.indirizzo  like '%' || devi.descrizione|| '%';
        exception
            when no_data_found then
                w_cod_via := '';
            when too_many_rows then
                w_cod_via := '';
            when others then
                raise_application_error(-20999,
                                        'Errore in ricerca cod_via' || ' (' ||
                                        sqlerrm || ')');
                end;
      when too_many_rows then
        w_cod_via := '';
      when others then
        raise_application_error(-20999,
                                'Errore in ricerca cod_via' || ' (' ||
                                sqlerrm || ')');
    end;
    return w_cod_via;
  end;
  /*******************************************************************************************************
  Gestione pratiche
  *******************************************************************************************************/
  function crea_oggetto(a_oggetto sel_oggetti%rowtype, a_fonte number)
    return number is
    w_oggetto         number;
    w_cod_via         varchar2(100);
    w_check_categoria number;
    w_estremi_catasto varchar2(20);
    w_num_civ_number  number;
  begin
    w_estremi_catasto := estremi_catasto(a_oggetto);
--dbms_output.put_line('crea oggetto: '||a_oggetto.contatore||' imm ' ||a_oggetto.tipo_immobile||' estremi: '||w_estremi_catasto||' ctg: '||a_oggetto.categoria);
    w_num_civ_number  := f_num_civ_str_to_numb(a_oggetto.num_civ);
    oggetti_nr(w_oggetto);
    w_cod_via := get_cod_via(a_oggetto);
    -- Si crea la categoria se non esiste
    select count(*)
      into w_check_categoria
      from categorie_catasto caca
     where caca.categoria_catasto is not null
       and caca.categoria_catasto = a_oggetto.categoria;
    if (w_check_categoria = 0 and a_oggetto.categoria is not null) then
      insert into categorie_catasto
        (categoria_catasto, descrizione)
      values
        (a_oggetto.categoria, 'DA POPOLAMENTO IMU CATASTO');
      aggiungi_messaggio('Per il contribuente ' || w_cognome_nome || ' - ' ||
                         w_cod_fiscale || ' è stato inserito oggetto ' ||
                         w_oggetto || ' con categoria ' ||
                         a_oggetto.categoria || ' e con valore = rendita.');
    end if;
    -- Si inserisce l'oggetto
    begin
      insert into oggetti
        (oggetto,
         tipo_oggetto,
         indirizzo_localita,
         cod_via,
         num_civ,
         scala,
         piano,
         interno,
         sezione,
         foglio,
         numero,
         subalterno,
         zona,
         estremi_catasto,
         partita,
         categoria_catasto,
         classe_catasto,
         consistenza,
         fonte,
         utente,
         data_variazione,
         note,
         id_immobile)
      values
        (w_oggetto,
         decode(a_oggetto.tipo_immobile, 'F', 3, 'T', 1),
         decode(w_cod_via, '', substr(a_oggetto.indirizzo, 1, 36), ''),
         decode(w_cod_via, '', null, w_cod_via),
         w_num_civ_number,
         a_oggetto.scala,
         substr(a_oggetto.piano, 1, 5),
         a_oggetto.interno,
         a_oggetto.sezione,
         a_oggetto.foglio,
         a_oggetto.numero,
         a_oggetto.subalterno,
         a_oggetto.zona,
         w_estremi_catasto,
         a_oggetto.partita,
         a_oggetto.categoria,
         trim(a_oggetto.classe),
         a_oggetto.consistenza,
         a_fonte,
         w_utente,
         trunc(sysdate),
         'Popolamento IMU da CATASTO eseguito il ' ||
         to_char(sysdate, 'dd/mm/yyyy'),
         a_oggetto.contatore);
    exception
      when others then
        raise_application_error(-20999,
                                'Errore in inserimento oggetto' || ' ( ogge ' ||
                                w_oggetto ||' cod_via '||
                                w_cod_via||' num_civ '||
                                w_num_civ_number||' intern '||
                                a_oggetto.interno||' cons '||
                                a_oggetto.consistenza  ||
                                sqlerrm || ' )');
    end;
    return w_oggetto;
  end;
  /*******************************************************************************************************
  Recupera l'oggetto
  *******************************************************************************************************/
  function get_oggetto(a_oggetto            sel_oggetti%rowtype,
                       a_fonte              number,
                       a_crea_se_non_esiste boolean default false)
    return number is
    w_contatore       number;
    w_oggetto         number;
    w_estremi_catasto varchar2(20);
  begin
    w_estremi_catasto := estremi_catasto(a_oggetto);
    begin
      select ogge.oggetto
        into w_oggetto
        from oggetti ogge
      --where ogge.tipo_oggetto + 0 = 3
       where ogge.tipo_oggetto + 0 =
             decode(a_oggetto.tipo_immobile, 'F', 3, 1)
         and ogge.estremi_catasto = w_estremi_catasto
         and decode(a_oggetto.tipo_immobile, 'F', nvl(ogge.categoria_catasto, ' '), nvl(ogge.categoria_catasto,'T')) =
             decode(a_oggetto.tipo_immobile, 'F', nvl(a_oggetto.categoria, ' '), nvl(a_oggetto.categoria,'T'))
         and rownum = 1;
      --se arrivo qui l'oggetto esiste
    exception
      when no_data_found then
        w_oggetto := null;
      when others then
        raise_application_error(-20999,
                                'POPOLAMENTO_IMU_CATASTO - Fallita verifica base esistenza oggetto con estremi ' ||
                                w_estremi_catasto);
    end;
--dbms_output.put_line('get oggetto1: '||w_oggetto||' imm ' ||a_oggetto.tipo_immobile||' estremi: '||w_estremi_catasto||' ctg: '||a_oggetto.categoria);
    -- non c'è un oggetto con quegli estremi,
    -- ma potrebbe esserci un altro oggetto
    -- con estremi diversi ma stesso contatore (graffato)
    if w_oggetto is null and a_crea_se_non_esiste then
      select nvl(min(contatore), 0)
        into w_contatore
        from immobili_catasto_urbano
       where estremi_catasto = w_estremi_catasto;
      for i in (select estremi_catasto
                  from immobili_catasto_urbano
                 where contatore = w_contatore) loop
        begin
          select min(oggetto)
            into w_oggetto
            from oggetti ogge
           where estremi_catasto = i.estremi_catasto
             and decode(a_oggetto.tipo_immobile, 'F', nvl(ogge.categoria_catasto, ' '), nvl(ogge.categoria_catasto,'T')) =
                 decode(a_oggetto.tipo_immobile, 'F', nvl(a_oggetto.categoria, ' '), nvl(a_oggetto.categoria,'T'))
             and ogge.tipo_oggetto + 0 =
                 decode(a_oggetto.tipo_immobile, 'F', 3, 1);
           if w_oggetto is not null then
            exit;
          end if;
        end;
      end loop;
    end if;
--dbms_output.put_line('get oggetto2: '||w_oggetto||' estremi: '||w_estremi_catasto||' ctg: '||a_oggetto.categoria);
    -- Se non l'oggetto non esiste si crea.
    if (w_oggetto is null) then
      w_oggetto := crea_oggetto(a_oggetto, a_fonte);
    end if;
    return w_oggetto;
  end;
  /*******************************************************************************************************
  Inserisce un messaggio nel log se sono presenti variazioni con stessi:
  CONTATORE, DATA_EFFICACIA, DATA_VALIDITA, DATA_FINE_VALIDITA
  *******************************************************************************************************/
  procedure variazioni_uguali(a_cod_fiscale varchar2, a_pratica number) is
    w_variazioni_simili number;
  begin
    select count(*)
      into w_variazioni_simili
      from (select imm.contatore
               from immobili_soggetto_cc imm
              where
             -- Elimina i casi incongruenti
              nvl(imm.data_fine_validita, to_date('99990101', 'YYYYMMDD')) >
              imm.data_validita
           and imm.data_efficacia =
              (select max(icub.data_efficacia)
                 from immobili_soggetto_cc icub
                where icub.cod_fiscale_ric = imm.cod_fiscale_ric
                  and icub.estremi_catasto = imm.estremi_catasto)
--                  and nvl(imm.sezione, ' ') = nvl(icub.sezione, ' ')
--                  and nvl(imm.foglio, ' ') = nvl(icub.foglio, ' ')
--                  and nvl(imm.numero, ' ') = nvl(icub.numero, ' ')
--                  and nvl(imm.subalterno, ' ') = nvl(icub.subalterno, ' '))
           and imm.cod_fiscale_ric = a_cod_fiscale
              group by imm.contatore,
                       imm.data_efficacia || '-' || imm.data_validita || '-' ||
                       imm.data_fine_validita
             having count(imm.data_efficacia || '-' || imm.data_validita || '-' || imm.data_fine_validita) > 1);
    if (w_variazioni_simili > 0) then
      aggiungi_messaggio('Esistono oggetti con le stesse caratteristiche nella pratica ' ||
                         a_pratica || ' del contribuente ' ||
                         w_cognome_nome || ' - ' || w_cod_fiscale);
    end if;
  end;
  /*******************************************************************************************************
   1. Nel caso in cui ci sia un immobile con codice_diritto non presente in codici_diritto del TR4
      si controlla anche la presenza in cc_diritti e se presente lo si inserisce anche in codici_diritto prelevando le info da cc_diritti
      e lo si tratta.
   2. Se invece quel codice_diritto non è presente neppure in cc_diritti lo si inserisce SOLO in codici_diritto con descrizione
      'DA POPOLAMENTO IMU CATASTO', e lo si tratta ugualmente.
  *******************************************************************************************************/
  function gestione_codice_diritto(a_codice_diritto varchar2) return number is
    w_codi                     codici_diritto%rowtype;
    w_diri                     cc_diritti%rowtype;
    w_cod_diritto_decodificato varchar2(4);
    w_ordinamento              number(4);
    w_ret                      number(1) := 0;
  begin
    begin
      -- Si cerca il codice diritto
      select *
        into w_codi
        from codici_diritto
       where cod_diritto = a_codice_diritto ;
    exception
      when no_data_found then
           w_cod_diritto_decodificato := decodifica_codice_diritto(a_codice_diritto);
        begin
          select *
            into w_codi
            from codici_diritto
           where cod_diritto = w_cod_diritto_decodificato;
        exception
          when no_data_found then
            w_ret := 1;
            select (max(codi.ordinamento) + 1)
              into w_ordinamento
              from codici_diritto codi;
            -- Si cerca il codice diritto nella cc_diritti
            begin
              select *
                into w_diri
                from cc_diritti diri
               where diri.codice_diritto = a_codice_diritto;
              -- 1. Se esiste si crea una CODI con i dati presi dalla DIRI
              insert into codici_diritto
                (cod_diritto, ordinamento, descrizione)
              values
                (a_codice_diritto, w_ordinamento, w_diri.descrizione);
            exception
              when no_data_found then
                w_ret := 2;
                -- Altrimenti si crea una CODI con il nuovo codice diritto
                begin
                  insert into codici_diritto
                    (cod_diritto, ordinamento, descrizione)
                  values
                    (a_codice_diritto,
                     w_ordinamento,
                     'DA POPOLAMENTO IMU CATASTO');
                end;
            end;
        end;
    end;
    return w_ret;
  end;
  /*******************************************************************************************************
  Analizza categoria catastale e codice diritto per determinare se sia da trattare o meno
  (VD _ 29/09/2022): Aggiunto parametro tipo immobile.
                     Il controllo sulla categoria catasto deve essere eseguito solo per i fabbricati.
  *******************************************************************************************************/
  function da_trattare(a_categoria_catasto varchar2,
                       a_codice_diritto    varchar2,
                       a_tipo_immobile     varchar2 default 'F')
    return varchar2 is
    w_eccezione_caca           varchar2(1);
    w_eccezione_codi           varchar2(1);
    w_cod_diritto_decodificato varchar2(4);
    w_da_trattare              varchar2(1) := 'S';
  begin
    -- Eccezione per categoria
    -- (VD - 29/09/2022): il test sulle categorie catasto da escludere va eseguito solo
    --                    per i fabbricati
    if a_tipo_immobile = 'F' then
      begin
        select eccezione
          into w_eccezione_caca
          from categorie_catasto
         where categoria_catasto = a_categoria_catasto;
        if (w_eccezione_caca is not null) then
          return w_eccezione_caca;
        end if;
      exception
        -- Se la categoria non è presente si considera l'oggetto come da trattare.
        when no_data_found then
          begin
            return 'S';
          end;
        when others then
          raise_application_error(-20999,
                                  'Errore in estrazione eccezione (CATE) ' ||
                                  a_categoria_catasto || ' (' || sqlerrm || ')');
      end;
    end if;
    -- Eccezione per codice diritto
    begin
      w_cod_diritto_decodificato := decodifica_codice_diritto(a_codice_diritto);
      select eccezione
        into w_eccezione_codi
        from codici_diritto
       where cod_diritto = w_cod_diritto_decodificato;
      if (w_eccezione_codi is not null) then
        return w_eccezione_codi;
      end if;
    exception
      when no_data_found then
        begin
          return 'S';
        end;
      when others then
        raise_application_error(-20999,
                                'Errore in estrazione eccezione (CODI) ' ||
                                a_categoria_catasto || ' (' || sqlerrm || ')');
    end;
    return w_da_trattare;
  end;
  /*******************************************************************************************************
  Recupera l'id del soggetto a catasto e se non esiste crea la SOGGETTI
  *******************************************************************************************************/
  procedure elabora_soggetto(a_cod_fiscale in varchar2,
                             a_ni_cont     out number,
                             a_fonte       number) is
    w_ni                 number;
    w_cognome_nome_cata  varchar2(150);
    w_data_nas_cata      date;
    w_des_com_nas_cata   varchar2(40);
    w_tipo_soggetto_cata varchar2(1);
  begin
    -- Recupero NI della soggetti
    begin
      select sogg.ni
        into w_ni
        from soggetti sogg
       where nvl(sogg.cod_fiscale(+), sogg.partita_iva(+)) = a_cod_fiscale;
    exception
      when no_data_found then
           w_ni := null;
      when too_many_rows then
           begin
             select max(sogg.ni)
               into w_ni
               from soggetti sogg
              where nvl(sogg.cod_fiscale(+), sogg.partita_iva(+)) = a_cod_fiscale;
           exception
             when others then
                  raise_application_error(-20999,
                                        ' ERRORE IN Ricerca Soggetto per max(ni) cod_fiscale: ' ||
                                        w_cod_fiscale||
                                        ' (' || sqlerrm || ') ');
           end;
      when others then
           raise_application_error(-20999,
                                ' ERRORE IN Ricerca Soggetto (ni) cod_fiscale: ' ||
                                w_cod_fiscale||
                                ' (' || sqlerrm || ') ');
    end;
    -- Recupero NI contribuente
    begin
      select cont.ni
        into a_ni_cont
        from contribuenti cont
       where cont.cod_fiscale = a_cod_fiscale;
    exception
      when others then
           a_ni_cont := null;
    end;
--dbms_output.put_line('w_ni 1 : '||w_ni||' elabora CF: '||a_cod_fiscale);
    -- Inserimento soggetto
    if w_ni is null then
      begin
        select substr(cognome_nome, 1, 60),
               data_nas,
               des_com_nas,
               tipo_soggetto
          into w_cognome_nome_cata,
               w_data_nas_cata,
               w_des_com_nas_cata,
               w_tipo_soggetto_cata
          from proprietari_catasto_urbano
         where cod_fiscale = a_cod_fiscale
           and rownum = 1;
      exception
        when others then
          raise_application_error(-20999,
                                  'Errore in lettura dati catasto' || ' (' ||
                                  sqlerrm || ')');
      end;
      soggetti_nr(w_ni);
      begin
        insert into soggetti
          (ni,
           cognome_nome,
           data_nas,
           cod_pro_nas,
           cod_com_nas,
           cod_fiscale,
           partita_iva,
           tipo_residente,
           tipo,
           fonte,
           utente)
        values
          (w_ni,
           w_cognome_nome_cata,
           w_data_nas_cata,
           f_get_campo_ad4_com(null,
                               null,
                               w_des_com_nas_cata,
                               'S',
                               null,
                               'S',
                               null,
                               'COD_PROVINCIA'),
           f_get_campo_ad4_com(null,
                               null,
                               w_des_com_nas_cata,
                               'S',
                               null,
                               'S',
                               null,
                               'COD_COMUNE'),
           decode(length(a_cod_fiscale), 16, a_cod_fiscale, ''),
           decode(length(a_cod_fiscale), 11, a_cod_fiscale, ''),
           1,
           decode(w_tipo_soggetto_cata, 'P', 0, 'G', 1, 2),
           a_fonte,
           w_utente);
      exception
        when others then
          raise_application_error(-20999,
                                  'Errore in inserimento soggetto ' ||
                                  a_cod_fiscale || ' (' || sqlerrm || ')');
      end;
    end if;
--dbms_output.put_line('w_ni ' || w_ni||' a_ni_cont 1 : '||a_ni_cont||' elabora CF: '||a_cod_fiscale);
    -- Inserimento contribuente
    if a_ni_cont is null then
      begin
        insert into contribuenti
          (ni, cod_fiscale)
        values
          (w_ni, a_cod_fiscale);
      exception
        when others then
          raise_application_error(-20999,
                                  'Errore in inserimento contribuente ' ||
                                  a_cod_fiscale || ' (' || sqlerrm || ')');
      end;
      a_ni_cont := w_ni;
    end if;
  end;
  /*******************************************************************************************************
  Gestione pratiche
  *******************************************************************************************************/
  function crea_prtr(a_anno number, a_cod_fiscale varchar2, a_fonte number)
    return number is
    w_prtr number;
  begin
    if (t_prtr.exists(a_anno)) then
      return t_prtr(a_anno);
    end if;
    -- Si crea la nuova pratica per l'anno
    begin
      pratiche_tributo_nr(w_prtr);
      variazioni_uguali(a_cod_fiscale, w_prtr);
      t_prtr(a_anno) := w_prtr;
      insert into pratiche_tributo
        (pratica,
         cod_fiscale,
         tipo_tributo,
         anno,
         tipo_pratica,
         tipo_evento,
         data,
         utente,
         data_variazione,
         note)
      values
        (w_prtr,
         a_cod_fiscale,
         'ICI',
         a_anno,
         'D',
         'I',
         trunc(sysdate),
         w_utente,
         trunc(sysdate),
         'Popolamento IMU da CATASTO eseguito il ' ||
         to_char(sysdate, 'dd/mm/yyyy'));
    exception
      when others then
        raise_application_error(-20999,
                                'Errore in in inserimento nuova pratica x cf: ' ||
                                a_cod_fiscale || ' (' || sqlerrm || ')');
    end;
    -- DENUNCE IMU
    begin
      insert into denunce_ici
        (pratica, denuncia, fonte, utente, data_variazione, note)
      values
        (w_prtr,
         w_prtr,
         a_fonte,
         w_utente,
         sysdate,
         'Popolamento IMU da CATASTO eseguito il ' ||
         to_char(sysdate, 'dd/mm/yyyy'));
    exception
      when others then
        raise_application_error(-20999,
                                'Errore in in inserimento nuova denuncia IMU' || ' (' ||
                                sqlerrm || ')');
    end;
    -- Rapporti_tributo
    begin
      insert into rapporti_tributo
        (pratica, cod_fiscale, tipo_rapporto)
      values
        (w_prtr, a_cod_fiscale, 'D');
    exception
      when others then
        raise_application_error(-20999,
                                'Errore in in inserimento rapporto tributo' || ' (' ||
                                sqlerrm || ')');
    end;
    return w_prtr;
  end;
  /*******************************************************************************************************
  Gestione oggetti pratica
  *******************************************************************************************************/
  function crea_ogpr(a_oggetto sel_oggetti%rowtype,
                     a_pratica number,
                     a_anno    number,
                     a_fonte   number) return number is
    w_oggetto         number;
    w_oggetto_pratica number;
    w_num_ordine      number := 1; -- Implementare calcolo del numero d'ordine
    w_valore          number;
    w_gestione_codi   number(1);
  begin
    w_oggetto := get_oggetto(a_oggetto, a_fonte, true);
    oggetti_pratica_nr(w_oggetto_pratica);
    -- Categoria non valorizzata
    if (a_oggetto.tipo_immobile = 'F' and a_oggetto.categoria is not null) then
      w_valore := f_valore_da_rendita(a_rendita           => a_oggetto.rendita,
                                      a_tipo_ogge         => 3,
                                      a_anno              => a_anno,
                                      a_categoria_catasto => a_oggetto.categoria,
                                      a_imm_storico       => null);
    elsif a_oggetto.tipo_immobile = 'T' then
      w_valore := f_valore_da_rendita(a_rendita           => a_oggetto.rendita,
                                      a_tipo_ogge         => 1,
                                      a_anno              => a_anno,
                                      a_categoria_catasto => a_oggetto.categoria,
                                      a_imm_storico       => null);
    else
      w_valore := a_oggetto.rendita;
      aggiungi_messaggio('Per il contribuente ' || w_cognome_nome || ' - ' ||
                         w_cod_fiscale || ' è stato inserito oggetto ' ||
                         w_oggetto ||
                         ' senza categoria e con valore = rendita.');
    end if;
    -- Gestione dei codici diritto
    w_gestione_codi := gestione_codice_diritto(a_oggetto.cod_titolo);
    if (w_gestione_codi = 1) then
      aggiungi_messaggio('Per il contribuente ' || w_cognome_nome || ' - ' ||
                         w_cod_fiscale || ' è stato inserito oggetto ' ||
                         w_oggetto || ' con codice diritto ' ||
                         a_oggetto.cod_titolo ||
                         ' inserito in tabella codici_diritto.');
    elsif (w_gestione_codi = 2) then
      aggiungi_messaggio('Per il contribuente ' || w_cognome_nome || ' - ' ||
                         w_cod_fiscale || ' è stato inserito oggetto ' ||
                         w_oggetto || ' con codice diritto ' ||
                         a_oggetto.cod_titolo ||
                         ' inserito in tabella codici_diritto, anche se non presente nelle tabelle catastali.');
    end if;
    begin
      insert into oggetti_pratica
        (oggetto_pratica,
         oggetto,
         pratica,
         anno,
         num_ordine,
         categoria_catasto,
         classe_catasto,
         valore,
         fonte,
         utente,
         data_variazione,
         note,
         tipo_oggetto)
      values
        (w_oggetto_pratica,
         w_oggetto,
         a_pratica,
         a_anno,
         lpad(w_num_ordine, 5, '0'),
         a_oggetto.categoria,
         a_oggetto.classe,
         round(w_valore, 2),
         a_fonte,
         w_utente,
         trunc(sysdate),
         'Popolamento IMU da CATASTO eseguito il ' ||
         to_char(sysdate, 'dd/mm/yyyy'),
         decode(a_oggetto.tipo_immobile, 'F', 3, 'T', 1));
    exception
      when others then
        raise_application_error(-20999,
                                ' ERRORE IN IN INSERIMENTO
             OGGETTO PRATICA ' || '(' ||
                                sqlerrm || ') ');
    end;
    return w_oggetto_pratica;
  end;
  /*******************************************************************************************************
  Gestione oggetti contribuente
  *******************************************************************************************************/
  procedure crea_ogco(a_oggetto         sel_oggetti%rowtype,
                      a_ni              number,
                      a_cod_fiscale     varchar2,
                      a_oggetto_pratica number,
                      a_da_trattare     varchar2) is
    w_anno_imposta     number(4);
    w_flag_possesso    varchar2(1);
    w_flag_abi_pri     varchar2(1);
    w_mp               number(2);
    w_mp_1s            number(1);
    w_perc_poss        number(5, 2);
    w_da_mese_possesso number(2);
    w_mesi_esclusione  number(2);
    w_flag_escluso     varchar2(1);
  begin
    calcola_mp(a_oggetto, w_mp, w_mp_1s, w_da_mese_possesso);
    w_anno_imposta  := estrai_anno_imposta(a_oggetto.data_validita);
    w_flag_possesso := possesso_31_12(a_oggetto);
    w_flag_abi_pri  := abitazione_principale(a_ni,
                                             w_anno_imposta,
                                             get_cod_via(a_oggetto),
                                             a_oggetto.num_civ,
                                             a_oggetto.categoria);
    w_perc_poss     := calcola_perc_possesso(a_oggetto);
    -- Gestione esclusione
--dbms_output.put_line (a_da_trattare);
    if (a_da_trattare = 'E') then
      w_mesi_esclusione := w_mp;
      w_flag_escluso    := w_flag_possesso;
      w_mp_1s           := null;
    end if;
    begin
      insert into oggetti_contribuente
        (cod_fiscale,
         oggetto_pratica,
         anno,
         tipo_rapporto,
         perc_possesso,
         mesi_possesso,
         mesi_possesso_1sem,
         flag_possesso,
         flag_ab_principale,
         da_mese_possesso,
         mesi_esclusione,
         flag_esclusione,
         utente,
         data_variazione,
         note)
      values
        (a_cod_fiscale,
         a_oggetto_pratica,
         w_anno_imposta,
         'D',
         w_perc_poss,
         w_mp,
         w_mp_1s,
         w_flag_possesso,
         w_flag_abi_pri,
         w_da_mese_possesso,
         w_mesi_esclusione,
         w_flag_escluso,
         w_utente,
         trunc(sysdate),
         ' POPOLAMENTO IMU DA CATASTO ESEGUITO IL ' ||
         to_char(sysdate, ' DD / MM / YYYY '));
    exception
      when others then
        raise_application_error(-20999,
                                ' ERRORE IN IN INSERIMENTO
             OGGETTO CONTRIBUENTE
             ' || '(' || sqlerrm || ') ');
    end;
  end;
  /*******************************************************************************************************
  Crea la pratica
  *******************************************************************************************************/
  procedure crea_pratica(a_oggetto     sel_oggetti%rowtype,
                         a_fonte       number,
                         a_ni          number,
                         a_storico     varchar2,
                         a_da_trattare varchar2,
                         a_anno        number) is
    w_prtr        pratiche_tributo.pratica%type;
    w_ogpr        oggetti_pratica.oggetto_pratica%type;
    w_anno_inizio number(4);
    w_oggetto     sel_oggetti%rowtype := a_oggetto;
  begin
    -- Se A_ANNO > dell'anno di fine della variazione, questa non viene trattata.
    if (a_anno > nvl(estrai_anno(w_oggetto.data_fine_validita), 9999)) then
      goto no_op;
    end if;
    -- Se A_ANNO > dell'anno di inizio variazione si crea la dicihiarazione/quadri solo se è richiesto lo storico o
    -- esiste la data fine validità
    if (a_anno > estrai_anno(w_oggetto.data_validita) and
       nvl(a_storico, 'N') != 'S' and a_oggetto.data_fine_validita is null) then
      goto no_op;
    end if;
    -- Se A_ANNO > dell'anno di inizio validità della variazione:
    -- 1. Verrà trattata a partire da 01/01/A_ANNO in caso di storico
    -- 2. Verrà trattata a partire da 01/01/ANNO_FINE_ALIDITA in caso di variazione chiusa
    if (a_anno > estrai_anno(w_oggetto.data_validita)) then
      -- 1
      if (nvl(a_storico, 'N') = 'S') then
        w_oggetto.data_validita := to_date(a_anno || '0101', 'YYYYMMDD');
        -- 2
      elsif (a_oggetto.data_fine_validita is not null) then
        w_oggetto.data_validita := to_date(estrai_anno(a_oggetto.data_fine_validita) ||
                                           '0101',
                                           'YYYYMMDD');
      end if;
    end if;
    -- Recupero dell'anno di inizio
    w_anno_inizio := estrai_anno_imposta(w_oggetto.data_validita);
    -- Creazione o recupero della PRTR
    w_prtr := crea_prtr(w_anno_inizio, w_oggetto.cod_fiscale_ric, a_fonte);
    -- Creazione OGPR
    w_ogpr := crea_ogpr(w_oggetto, w_prtr, w_anno_inizio, a_fonte);
    -- Creazione OGCO
--dbms_output.put_line('ogPR '||w_ogpr);
    crea_ogco(w_oggetto,
              a_ni,
              w_oggetto.cod_fiscale_ric,
              w_ogpr,
              a_da_trattare);
    -- Se è valorizzata la data di fine validità e data inizio e fine non ricadono nello stesso anno, si crea il quadro di chiusura.
    if (w_oggetto.data_fine_validita is not null and
       estrai_anno(w_oggetto.data_fine_validita) !=
       estrai_anno(w_oggetto.data_validita)) then
      w_oggetto.data_fine_validita := w_oggetto.data_fine_validita;
      w_oggetto.data_validita      := to_date(estrai_anno(w_oggetto.data_fine_validita) ||
                                              '0101',
                                              'YYYYMMDD');
      crea_pratica(w_oggetto,
                   a_fonte,
                   a_ni,
                   a_storico,
                   a_da_trattare,
                   a_anno);
    end if;
    aggiungi_messaggio('Per l''oggetto '|| get_oggetto(w_oggetto, a_fonte) || ' elaborata pratica ' || w_prtr);
    <<no_op>>
    null; -- NOOP, nulla da fare.
  end;
  procedure popola(a_cod_fiscale   varchar2 default '%',
                   a_anno          number,
                   a_fonte         number,
                   a_storico       varchar2,
                   a_tipo_immobile varchar2) is
    w_ni          number;
    w_da_trattare varchar2(1);
    w_messaggio   varchar2(2000) := null;
    w_categoria   varchar2(3);
  begin
    -- Recupera l'id del soggetto
    elabora_soggetto(a_cod_fiscale, w_ni, a_fonte);
    -- Codice fiscale e nome utilizzati nel log
    w_cod_fiscale := a_cod_fiscale;
--dbms_output.put_line('w_ni: '||w_ni||' elabora CF: '||a_cod_fiscale);
    begin
        select sogg.cognome_nome
          into w_cognome_nome
          from soggetti sogg
         where ni = w_ni   --nvl(sogg.cod_fiscale, sogg.partita_iva) = w_cod_fiscale  24/11/2022 AB
        ;
    exception
      when others then
        raise_application_error(-20999,
                                ' ERRORE IN Ricerca Soggetto per ni: ' ||
                                w_ni || 'Cod Fiscale: '||w_cod_fiscale||
                                ' (' || sqlerrm || ') ');
    end;
    -- Loop sugli oggetti/terreni del soggetto
    for rec_ogg in sel_oggetti(a_cod_fiscale, a_tipo_immobile) loop
      -- Trattamento dei fabbricati
      if (a_tipo_immobile = 'F') then
        w_categoria := rec_ogg.categoria;
      end if;
      -- Se l'immobile è da elaborare
      w_da_trattare := da_trattare(w_categoria,
                                   rec_ogg.cod_titolo,
                                   a_tipo_immobile);
      if (w_da_trattare in ('S', 'E')) then
        -- Crea la dichiarazione o i quadri.
        crea_pratica(rec_ogg,
                     a_fonte,
                     w_ni,
                     a_storico,
                     w_da_trattare,
                     a_anno);
        -- (VD - 27/10/2020): sostituita procedure con relativa procedure
        --                    del package INSERIMENTO_RENDITE_PKG per
        --                    gestione nuove tabelle catasto
--dbms_output.put_line('passo da qui per inserimento rendite per oggetto '||rec_ogg.contatore);
        inserimento_rendite_pkg.inserimento_rendite(rec_ogg.contatore,
                                                    a_tipo_immobile, -- tipo immobile
                                                    to_date('19900101',
                                                            'YYYYMMDD'), -- data cessazione ver.
                                                    'S', -- flag cessato
                                                    w_utente, -- utente
                                                    to_number(null), -- oggetto
                                                    w_messaggio -- messaggio in uscita
                                                    );
      end if;
    end loop;
  exception
    when others then
      raise_application_error(-20999,
                              'Errore in popolamento IMU da catasto ' || ' (' ||
                              sqlerrm || ')');
  end;
  /*------------------------------------------------------------------------------------------------
  PUBLIC
  ------------------------------------------------------------------------------------------------*/
  function crea_dichiarazioni(a_cod_fiscale   varchar2 default '%',
                              a_anno          number,
                              a_fonte         number,
                              a_storico       varchar2,
                              a_tipo_immobile varchar2,
                              a_passo_commit  number default 100) return clob is
    cursor sel_soggetti(p_tipo_immobile varchar2) is
      select distinct prop.cod_fiscale, prop.cognome_nome
--      select distinct prop.cod_fiscale
        from proprietari_catasto_urbano prop
       where prop.tipo_immobile =
             decode(a_tipo_immobile,
                    'X',
                    prop.tipo_immobile,
                    a_tipo_immobile)
         and prop.cod_fiscale_ric like a_cod_fiscale
       order by 1;
    w_anno       number(4);
    w_check      varchar2(4000);
    w_prtr       number;
    w_n_pratiche number(10) := 0;
  begin
    if (a_tipo_immobile not in ('F', 'T', 'X') or a_tipo_immobile is null) then
      raise_application_error(-20999,
                              'POPOLAMENTO_IMU_CATASTO - tipo immobile non valido, può assunere i valori ' ||
                              'F: Fabbricati - ' || 'T: Terreni - ' ||
                              'X: Fabbricati e Terreni');
    end if;
    -- Inizializzazione LOG
    dbms_lob.createtemporary(w_log, true);
    for rec_sogg in sel_soggetti(a_tipo_immobile) loop
--    dbms_output.put_line('verifica CF: '||rec_sogg.cod_fiscale);
      w_n_pratiche := w_n_pratiche + 1;
      aggiungi_messaggio('---------------------------------------------------------------------------------');
      aggiungi_messaggio('Elaborazione soggetto '|| rec_sogg.cognome_nome || ' - ' || rec_sogg.cod_fiscale);
--      aggiungi_messaggio('Elaborazione soggetto ' || rec_sogg.cod_fiscale);
      t_prtr := t_empty_prtr;
      w_anno := nvl(a_anno, 1992);
      -- Se non sono stati superati i controlli si restituisce la descrizione dell'errore.
      w_check := verifica(rec_sogg.cod_fiscale, w_anno);
--dbms_output.put_line('Dopo verifica check: '||w_check);
      if (w_check != 'OK') then
        aggiungi_messaggio(w_check);
      else
        if (a_tipo_immobile in ('F', 'X')) then
          popola(rec_sogg.cod_fiscale, a_anno, a_fonte, a_storico, 'F');
        end if;
--dbms_output.put_line('Dopo i F CF: '||rec_sogg.cod_fiscale);
        if (a_tipo_immobile in ('T', 'X')) then
          popola(rec_sogg.cod_fiscale, a_anno, a_fonte, a_storico, 'T');
        end if;
--dbms_output.put_line('Dopo i T CF: '||rec_sogg.cod_fiscale);
        -- (VD - 09/01/2020): Aggiunta archiviazione della denuncia
        if t_prtr.count > 0 then
          for i in t_prtr.first .. t_prtr.last loop
            if t_prtr.exists(i) then
              w_prtr := t_prtr(i);
              archivia_denunce('', '', w_prtr);
            end if;
          end loop;
        end if;
      end if;
      if (w_n_pratiche mod a_passo_commit = 0) then
        commit;
      end if;
    end loop;
    aggiungi_messaggio('---------------------------------------------------------------------------------');
    aggiungi_messaggio('Elaborati ' || w_n_pratiche || ' soggetti.');
    return w_log;
  exception
    when others then
      raise_application_error(-20999,
                              'Errore in popolamento IMU da catasto ' || ' (' ||
                              sqlerrm || ')');
  end;
end popolamento_imu_catasto;
/
