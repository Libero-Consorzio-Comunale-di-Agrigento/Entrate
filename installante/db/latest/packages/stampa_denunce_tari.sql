--liquibase formatted sql 
--changeset abrandolini:20250326_152429_stampa_denunce_tari stripComments:false runOnChange:true 
 
create or replace package STAMPA_DENUNCE_TARI is
/******************************************************************************
 NOME:        STAMPA_DENUNCE_TARI
 DESCRIZIONE: Funzioni per stampa denunce TARI - TributiWeb.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   21/04/2021  VD      Prima emissione.
******************************************************************************/
  s_revisione constant varchar2(30) := 'V1.01';
  function VERSIONE
  return varchar2;
  function CONTRIBUENTE
  ( a_pratica                          number default -1
  ) return sys_refcursor;
  function DATI_DENUNCIA
  ( a_cod_fiscale                      varchar2 default ''
  , a_pratica                          number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function DATI_OGGETTI_PRATICA
  ( a_cod_fiscale                      varchar2 default ''
  , a_pratica                          number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function F_GET_STRINGA_QUOTA
  ( a_oggetto_pratica                  number
  , a_anno                             number
  , a_flag_domestica                   varchar2
  , a_flag_ab_princ                    varchar2
  , a_esiste_cosu                      varchar2
  , a_num_familiari                    number
  , a_tributo                          number
  , a_categoria                        number
  , a_tipo_quota                       varchar2
  ) return varchar2;
  function DATI_FAMILIARI
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function DATI_NON_DOM
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function DATI_PARTIZIONI
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function DATI_ELENCO_FAMILIARI
  ( a_pratica                          number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
  function DATI_RUOLI
  ( a_cod_fiscale                      varchar2 default ''
  , a_anno                             number default -1
  , a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor;
end STAMPA_DENUNCE_TARI;
/
create or replace package body STAMPA_DENUNCE_TARI is
/******************************************************************************
 NOME:        STAMPA_DENUNCE_TARI
 DESCRIZIONE: Funzioni per stampa denunce TARI - TributiWeb.
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   21/04/2021  VD      Prima emissione.
******************************************************************************/
  s_revisione_body constant varchar2(30) := '000';
----------------------------------------------------------------------------------
  function versione
  return varchar2 is
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
  function CONTRIBUENTE
  ( a_pratica                          number
  ) return sys_refcursor is
  /******************************************************************************
    NOME:        contribuente.
    DESCRIZIONE: Restituisce tutti i dati relativi alla pratica e al contribuente.
                 Richiama funzione standard del package STAMPA_COMMON.
    RITORNA:     ref_cursor.
    NOTE:
  ******************************************************************************/
    rc sys_refcursor;
  begin
    rc := stampa_common.contribuente(a_pratica);
    return rc;
  end contribuente;
----------------------------------------------------------------------------------
  function DATI_DENUNCIA
  ( a_cod_fiscale                      varchar2 default ''
  , a_pratica                          number default -1
  , a_modello                          number default -1
  ) return sys_refcursor is
    rc                                 sys_refcursor;
  begin
    open rc for
      select a_modello modello,
             a_cod_fiscale cod_fiscale,
             f_descrizione_titr(prtr.tipo_tributo, prtr.anno) descr_titr,
             prtr.pratica,
             prtr.anno,
             decode(prtr.tipo_evento
                   ,'I','DI ISCRIZIONE'
                   ,'V','DI VARIAZIONE'
                   ,'C','DI CESSAZIONE'
                   ,null) nome_evento,
             prtr.numero,
             prtr.data,
             prtr.indirizzo_den,
             ad4_comuni.denominazione descr_comune_den,
             prtr.tipo_carica,
             tipi_carica.descrizione descr_carica,
             prtr.cod_fiscale_den,
             prtr.cod_pro_den,
             prtr.cod_com_den,
             translate(prtr.denunciante,'/',' ') denunciante,
             decode(coalesce(prtr.cod_fiscale_den
                            ,to_char(prtr.tipo_carica)
                            ,prtr.denunciante
                            ,prtr.indirizzo_den
                            ,ad4_comuni.denominazione
                            )
                   ,null,' '
                   ,'DENUNCIANTE:') label_denunciante,
             prtr.utente,
             prtr.note,
             ad4_comuni.sigla_cfis,
             to_char(prtr.data,'dd/mm/yyyy') data_denuncia,
             decode(prtr.denunciante, null, null, rpad('Denunciante',19)||':') label_denun,
             decode(prtr.tipo_carica, null, null, rpad('Natura Carica',19)||':') label_nat_car,
             decode(prtr.cod_fiscale_den, null, null, rpad('Codice Fiscale',19)||':') label_cod_fis_den,
             decode(prtr.indirizzo_den,null, null, rpad('Domicilio Fiscale',19)||':') label_indi_den,
             decode(ad4_comuni.denominazione, null, null, rpad('Comune',19)||':') label_comune,
             decode(ad4_comuni.cap,null,'',ad4_comuni.cap||' ')||
             decode(ad4_comuni.denominazione,null,'',rtrim(ad4_comuni.denominazione)||' ')||
             decode(ad4_provincie.sigla, null,'', '('||rpad(ad4_provincie.sigla,2)||')') comune_den
        from pratiche_tributo prtr,
             rapporti_tributo,
             ad4_comuni,
             ad4_provincie,
             tipi_carica
       where ad4_comuni.provincia_stato = ad4_provincie.provincia (+)
         and prtr.cod_pro_den = ad4_comuni.provincia_stato (+)
         and prtr.cod_com_den = ad4_comuni.comune (+)
         and prtr.tipo_carica = tipi_carica.tipo_carica (+)
         and prtr.pratica = rapporti_tributo.pratica
         and rapporti_tributo.cod_fiscale = a_cod_fiscale
         and rapporti_tributo.pratica = a_pratica;
    return rc;
  end dati_denuncia;
----------------------------------------------------------------------------------
  function DATI_OGGETTI_PRATICA
  ( a_cod_fiscale                   varchar2 default ''
  , a_pratica                       number default -1
  , a_modello                       number default -1
  ) return sys_refcursor is
    rc                              sys_refcursor;
  begin
    open rc for
      select distinct
             a_modello modello,
             translate(prtr.motivo,chr(013)||chr(010),'  ') motivo,
             prtr.tipo_evento,
             prtr.anno,
             a_pratica pratica,
             decode(ogpr.tipo_occupazione
                   ,'P','PERMANENTE'
                   ,'T','TEMPORANEA'
                   ,null) tipo_occupazione,
             ogpr.tributo||' - '||nvl(cotr.descrizione, ' ') tributo,
             ogpr.categoria||' - '||nvl(categorie.descrizione, ' ') categoria,
             decode(ogge.cod_via
                   ,null,rtrim(indirizzo_localita)||' '
                   ,rtrim(denom_uff)||' '
                    ||decode( ogge.num_civ, null, '',  ', '||ogge.num_civ )
                    ||decode( ogge.suffisso, null, '', '/'||ogge.suffisso )
                    ||decode( ogge.interno, null, '', ' int. '||ogge.interno)
                   ) indirizzo,
             stampa_common.f_formatta_numero(ogpr.consistenza,'I') consistenza,
             stampa_common.f_formatta_numero(ogco.perc_possesso,'P') perc_possesso,
             'TARIFFA ' || lpad (' ', 13)
                        || ogpr.tipo_tariffa
                        || decode (tari.descrizione
                                  ,null, null
                                  ,' - ' || tari.descrizione
                                  ) tariffa_desc,
             -- (VD - 16/06/2021): la riga tariffa si compone sempre, indipendentemente dall'anno
             --                    il tipo calcolo non viene più gestito
             /*decode(sign(prtr.anno - 2012)
                   ,-1,decode(tari.tariffa
                             ,null, null
                             ,' - EUR '||stampa_common.f_formatta_numero(tari.tariffa,'T')
                             )
                       ||' per l''Anno '||prtr.anno
                   ,decode(a_tipo_calcolo
                          ,2,decode(tari.tariffa
                                   ,null,null
                                   ,' - EUR '||stampa_common.f_formatta_numero(tari.tariffa,'T')
                                   )
                             ||' per l''Anno '||prtr.anno
                          )
                       ) riga_tariffa,*/
             decode(tari.tariffa
                   ,null,null
                   ,' - EUR '||stampa_common.f_formatta_numero(tari.tariffa,'T')
                   )
             ||' per l''Anno '||prtr.anno riga_tariffa,
             decode(sign(prtr.anno-2014)
                   ,-1,decode(prtr.tipo_evento
                             ,'V', ''
                             ,stampa_common.f_formatta_numero(ogim.imposta +
                                                              decode(ogim.ruolo
                                                                    ,null,0
                                                                    ,decode(ogim.addizionale_eca
                                                                           ,null,f_round(ogim.imposta * nvl(cata.addizionale_eca,0) / 100,1)
                                                                           ,nvl(ogim.addizionale_eca,0))) +
                                                              decode(ogim.ruolo
                                                                    ,null,0
                                                                    ,decode(ogim.maggiorazione_eca
                                                                           ,null,f_round(ogim.imposta * nvl(cata.maggiorazione_eca,0) / 100,1)
                                                                           ,nvl(ogim.maggiorazione_eca,0))) +
                                                              decode(ogim.ruolo
                                                                    ,null,0
                                                                    ,decode(ogim.addizionale_pro
                                                                           ,null,f_round(ogim.imposta * nvl(cata.addizionale_pro,0) / 100,1)
                                                                           ,nvl(ogim.addizionale_pro,0))) +
                                                              decode(ogim.ruolo
                                                                    ,null,0
                                                                    ,nvl(ogim.iva,0))
                                                             ,'I')
                             )
                   ,''
                   ) imposta_totale,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.imposta,null,'', 'IMPOSTA TOTALE')),'') label_imposta_tot,
             decode(sign(prtr.anno-2014)
                   ,-1,decode(prtr.tipo_evento
                              ,'V', ''
                             ,stampa_common.f_formatta_numero(ogim.imposta ,'I')
                             )
                   ,''
                   ) imposta,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.imposta,null,'', 'IMPOSTA   ')),'') label_imposta,
             decode(sign(prtr.anno-2014)
                   ,-1,decode(prtr.tipo_evento
                              ,'V', ''
                             ,decode(ogim.ruolo
                                    ,null,''
                                    ,stampa_common.f_formatta_numero(decode(ogim.addizionale_eca,null,f_round(ogim.imposta * nvl(cata.addizionale_eca,0) / 100,1),nvl(ogim.addizionale_eca,0))
                                                                   + decode(ogim.maggiorazione_eca,null,f_round(ogim.imposta * nvl(cata.addizionale_eca,0) / 100,1),nvl(ogim.maggiorazione_eca,0 ))
                                                                    ,'I'
                                                                    )
                                    )
                             )
                   ,''
                   ) ex_eca,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.ruolo,null,'','EX ECA.   ')),'') label_ex_eca,
             decode(sign(prtr.anno-2014)
                   ,-1,decode(prtr.tipo_evento
                             ,'V', ''
                             ,decode(ogim.ruolo
                                    ,null,''
                                    ,stampa_common.f_formatta_numero(decode(ogim.addizionale_pro,null,f_round(ogim.imposta *  nvl(cata.addizionale_pro,0) / 100,1),nvl(ogim.addizionale_pro,0))
                                                                    ,'I'
                                                                    )
                                    )
                             )
                   ,''
                   ) add_pro,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.ruolo,null,'','ADD. PROV.')),'') label_add_pro,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.ruolo,null,'',ltrim(translate(to_char(ogim.iva,'9,999,999,999,990.00'),'.,',',.')))),'') iva,
             decode(sign(prtr.anno-2014),-1,decode(prtr.tipo_evento,'V', '',decode(ogim.ruolo,null,'',decode(ogim.iva,null,'', 'IVA       '))),'') label_iva,
             decode(prtr.tipo_evento,'C', 'CESSAZIONE','U','CESSAZIONE',null) cessazione,
             decode(prtr.tipo_evento,'C', null,'DECORRENZA') decorrenza,
             to_char(decode(prtr.tipo_evento
                            ,'C', ogco.data_cessazione
                           ,'U',ogco.data_cessazione
                           ,null)
                    ,'dd/mm/yyyy') data_cessazione,
             to_char(decode(prtr.tipo_evento
                           ,'I',ogco.data_decorrenza
                           ,'U',ogco.data_decorrenza
                           ,'V',ogco.data_decorrenza
                           ,null)
                    ,'dd/mm/yyyy') data_decorrenza,
             ogpr.oggetto_pratica oggetto_pratica,
             substr(decode(ogge.partita,null,'',' Partita '||ogge.partita)||
                    decode(ogge.sezione,null,'',' Sezione '||ogge.sezione)||
                    decode(ogge.foglio,null,'',' Foglio '||ogge.foglio)||
                    decode(ogge.numero,null,'',' Numero '||ogge.numero)||
                    decode(ogge.subalterno,null,'',' Sub. '||ogge.subalterno)||
                    decode(ogge.zona,null,'',' Zona '||ogge.zona),2) estremi_catasto1,
             substr(decode(ogge.protocollo_catasto,null,'',' Prot. Num. '||ogge.protocollo_catasto)||
                    decode(ogge.anno_catasto,null,'',' Prot. Anno '||to_char(ogge.anno_catasto))||
                    decode(ogpr.categoria_catasto,null,'',' Cat. '||ogpr.categoria_catasto)||
                    decode(ogpr.classe_catasto,null,'',' Classe '||ogpr.classe_catasto),2)
                                            estremi_catasto2,
             decode(ogge.partita||ogge.sezione||
                    ogge.foglio||ogge.numero||ogge.subalterno||
                    ogge.zona||ogge.protocollo_catasto||to_char(ogge.anno_catasto)||
                    ogpr.categoria_catasto||ogpr.classe_catasto
                   ,null,rpad('',31),'Dati Identificativi Catastali '||':') label_estremi,
             decode(sign(prtr.anno-2014)
                   ,-1,ruco.mesi_ruolo
                   ,null
                   ) ruoli_contribuente_mesi,
             decode(sign(prtr.anno-2014),-1,decode(ruco.mesi_ruolo,null,'','MESI      '),'') label_mesi_ruolo,
             ogim.ruolo,
             ogim.oggetto_imposta,
             -- (VD - 16/06/2021): il tipo calcolo non viene più gestito
             decode(sign(prtr.anno-2012)
                    ,-1,null
                    --decode(a_tipo_calcolo
                    --      ,1,''
                    ,f_get_familiari_ogpr(ogpr.oggetto_pratica, ogco.flag_ab_principale,
                                          prtr.anno, ogpr.tributo,ogpr.categoria,ogpr.consistenza)
                    --      )
                   ) dettagli,
             -- (VD - 16/06/2021): il tipo calcolo non viene più gestito
             decode(sign(prtr.anno-2012)
                   ,-1,null
                   --,decode(a_tipo_calcolo,1,'','DETTAGLI')
                   ,'DETTAGLI'
                   ) label_dettagli,
             nvl(ogco.flag_punto_raccolta, 'N') flag_punto_raccolta
        from archivio_vie,
             oggetti   ogge,
             categorie,
             codici_tributo cotr,
             tariffe tari,
             pratiche_tributo prtr ,
             oggetti_contribuente  ogco,
             oggetti_pratica ogpr,
             oggetti_imposta ogim,
             carichi_tarsu  cata,
             ruoli_contribuente ruco
       where ogge.cod_via                        = archivio_vie.cod_via (+)
         and ogpr.tributo                        = cotr.tributo (+)
         and ogpr.tributo                        = categorie.tributo (+)
         and ogpr.categoria                      = categorie.categoria (+)
         and ogpr.tributo                        = tari.tributo (+)
         and ogpr.tipo_tariffa                   = tari.tipo_tariffa (+)
         and ogpr.categoria                      = tari.categoria (+)
         and ogpr.anno                           = tari.anno (+)
         and ogpr.anno                           = cata.anno (+)
         and ogpr.oggetto                        = ogge.oggetto
         and ogpr.pratica                        = prtr.pratica
         and ogpr.oggetto_pratica                = ogco.oggetto_pratica
         and ogim.cod_fiscale                (+) = a_cod_fiscale
         and ogim.oggetto_pratica            (+) = ogpr.oggetto_pratica
         and ogim.anno                       (+) = ogpr.anno
         and ruco.ruolo                      (+) = ogim.ruolo
         and ruco.oggetto_imposta            (+) = ogim.oggetto_imposta
         and ( to_char(ruco.data_variazione,'yyyymmdd')||to_char(ruco.ruolo)  =
                       (select max(to_char(ruco.data_variazione,'yyyymmdd')||to_char(ruco.ruolo))
                          from ruoli_contribuente   ruco,
                               oggetti_contribuente ogco,
                               oggetti_pratica      ogpr,
                               oggetti_imposta      ogim
                         where  ogpr.oggetto_pratica          = ogco.oggetto_pratica and
                                ogim.cod_fiscale            (+) = a_cod_fiscale  and
                                ogim.oggetto_pratica        (+) = ogpr.oggetto_pratica  and
                                ogim.anno                   (+) = ogpr.anno and
                                ruco.ruolo                  (+) = ogim.ruolo  and
                                ruco.oggetto_imposta        (+) = ogim.oggetto_imposta  and
                                ogco.cod_fiscale                = a_cod_fiscale  and
                                ogpr.pratica                    = a_pratica
                        ) or
                ogim.ruolo is null
                )
         and ogco.cod_fiscale                    = a_cod_fiscale
         and ogpr.pratica                        = a_pratica;
    return rc;
  end dati_oggetti_pratica;
----------------------------------------------------------------------------------
  function F_GET_STRINGA_QUOTA
  ( a_oggetto_pratica                  number
  , a_anno                             number
  , a_flag_domestica                   varchar2
  , a_flag_ab_princ                    varchar2
  , a_esiste_cosu                      varchar2
  , a_num_familiari                    number
  , a_tributo                          number
  , a_categoria                        number
  , a_tipo_quota                       varchar2
  ) return varchar2
  is
    w_tari                             number;
    w_tari2                            number;
    w_coeff1                           number;
    w_coeff2                           number;
    w_max_fam_coeff                    number;
    w_stringa_quota                    varchar2(2000);
  begin
    if a_tipo_quota = 'F' then
       begin
         select decode(a_flag_domestica, 'S', tariffa_domestica, tariffa_non_domestica)
           into w_tari
           from carichi_tarsu
          where anno = a_anno;
       end;
    else
       begin
         select tari.tariffa
           into w_tari2
           from tariffe tari, oggetti_pratica ogpr
          where ogpr.oggetto_pratica = a_oggetto_pratica
            and tari.tipo_tariffa = ogpr.tipo_tariffa
            and tari.categoria + 0 = ogpr.categoria
            and tari.tributo = ogpr.tributo
            and nvl(tari.anno, 0) = a_anno;
      end;
    end if;
    if a_flag_domestica = 'S' then
       if a_esiste_cosu = 'N' then
          begin
            select decode(a_flag_ab_princ
                         ,'S', codo.coeff_adattamento
                         ,nvl(codo.coeff_adattamento_no_ap, codo.coeff_adattamento)
                         )
                  ,decode(a_flag_ab_princ
                         ,'S', codo.coeff_produttivita
                         ,nvl(codo.coeff_produttivita_no_ap, codo.coeff_produttivita)
                         )
              into w_coeff1
                 , w_coeff2
              from coefficienti_domestici codo
             where codo.anno = a_anno
               and (codo.numero_familiari = a_num_familiari
                or (codo.numero_familiari = w_max_fam_coeff
                    and not exists (select 1
                                      from coefficienti_domestici cod3
                                     where cod3.anno = a_anno
                                       and cod3.numero_familiari = a_num_familiari)));
          end;
       else
          --
          -- Contrariamente ai familiari soggetto, non ci si trova in presenza di un archivio
          -- storico per cui la query per determinare i coefficienti ha come interrogazione
          -- una unica registrazione.
          --
          begin
            select nvl(codo.coeff_adattamento_no_ap, codo.coeff_adattamento)
                  ,nvl(codo.coeff_produttivita_no_ap, codo.coeff_produttivita)
              into w_coeff1, w_coeff2
              from coefficienti_domestici codo
             where codo.anno = a_anno
               and codo.numero_familiari = a_num_familiari;
          exception
            when no_data_found then
              w_coeff1 :=   0;
              w_coeff2 :=   0;
          end;
          --dbms_output.put_line('w_coeff1 '||w_coeff1);
          --dbms_output.put_line('w_coeff2 '||w_coeff2);
       end if;
       if a_tipo_quota = 'F' then
          w_stringa_quota := 'Ka. '
                          || lpad(stampa_common.f_formatta_numero(w_coeff1, 'C'),7)
                          || ' Tariffa '
                          || lpad(stampa_common.f_formatta_numero(w_tari, 'T'),13);
       else
          w_stringa_quota := 'Kb. '
                          || lpad(stampa_common.f_formatta_numero(w_coeff2, 'C'),7)
                          || ' Tariffa '
                          || lpad(stampa_common.f_formatta_numero(w_tari2, 'T'),13);
       end if;
    else
       begin
        select coeff_potenziale, coeff_produzione
          into w_coeff1, w_coeff2
          from coefficienti_non_domestici
         where anno = a_anno
           and tributo = a_tributo
           and categoria = a_categoria;
       end;
       if a_tipo_quota = 'F' then
          w_stringa_quota := 'Kc. '
                          || lpad(stampa_common.f_formatta_numero(w_coeff1, 'C'),7)
                          || ' Tariffa '
                          || lpad(stampa_common.f_formatta_numero(w_tari, 'T'),13);
       else
          w_stringa_quota := 'Kd. '
                          || lpad(stampa_common.f_formatta_numero(w_coeff2, 'C'),7)
                          || ' Tariffa '
                          || lpad(stampa_common.f_formatta_numero(w_tari2, 'T'),13);
       end if;
    end if;
    --
    return w_stringa_quota;
    --
  end F_GET_STRINGA_QUOTA;
----------------------------------------------------------------------------------
  function DATI_FAMILIARI
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  )
  return sys_refcursor
  is
    w_ni                               number;
    w_flag_ab_princ                    varchar2(1);
    w_anno                             number;
    w_tributo                          number;
    w_categoria                        number;
    w_consistenza                      number;
    w_esiste_cosu                      varchar2(1);
    w_fdom                             varchar2(1);
    w_dal                              date;
    w_al                               date;
    w_fam_coeff                        number;
    w_max_fam_coeff                    number;
    rc                                 sys_refcursor;
  begin
    -- Selezione NI contribuente
    begin
      select ni
        into w_ni
        from contribuenti
       where cod_fiscale = (select cod_fiscale
                              from oggetti_contribuente ogco
                             where ogco.oggetto_pratica = a_oggetto_pratica);
    exception
      when others then
        w_ni := to_number(null);
    end;
    -- Selezione dati oggetto
    begin
      select prtr.anno
           , ogco.flag_ab_principale
           , ogpr.categoria
           , ogpr.consistenza
           , cate.flag_domestica
        into w_anno
           , w_flag_ab_princ
           , w_categoria
           , w_consistenza
           , w_fdom
        from pratiche_tributo     prtr
           , oggetti_pratica ogpr
           , oggetti_contribuente ogco
           , categorie cate
       where prtr.pratica         = ogpr.pratica
         and ogpr.oggetto_pratica = a_oggetto_pratica
         and ogpr.oggetto_pratica = ogco.oggetto_pratica
         and ogpr.tributo         = cate.tributo
         and ogpr.categoria       = cate.categoria;
    exception
      when others then
        w_flag_ab_princ := null;
    end;
    --
    if w_flag_ab_princ = 'S' then
       w_esiste_cosu :=   'N';
    else
       begin
         select decode(count(1), 0, 'N', 'S')
           into w_esiste_cosu
           from componenti_superficie
          where anno = w_anno;
       end;
    end if;
    if w_fdom = 'S' then   -- tariffa domestica
       if w_esiste_cosu = 'S' then   -- Esistono componenti per superficie
          --
          -- Caso di presenza di componenti per superficie.
          -- Analogamente a quanto fatto per i familiari soggetto, se non esiste una registrazione
          -- per componenti superficie relativa alla consistenza dell`oggetto in esame, si fa
          -- riferimento al numero massimo dei familiari previsto per l`anno.
          --
          select nvl(numero_familiari,0)
            into w_fam_coeff
            from oggetti_pratica
           where oggetto_pratica = a_oggetto_pratica;
          if w_fam_coeff = 0 then
             begin
               select max(cosu.numero_familiari)
                 into w_max_fam_coeff
                 from componenti_superficie cosu
                where cosu.anno = w_anno
                group by 1;
             -- dbms_output.put_line('Trovato Massimo '||to_char(w_max_fam_coeff));
             exception
               when no_data_found then
                 -- dbms_output.put_line('Non Trovato Nulla');
                 w_max_fam_coeff :=   0;
             end;
             --dbms_output.put_line('w_max_fam_coeff '||w_max_fam_coeff);
             begin
               select max(cosu.numero_familiari)
                 into w_fam_coeff
                 from componenti_superficie cosu
                where w_consistenza between nvl(cosu.da_consistenza, 0)
                                        and nvl(cosu.a_consistenza, 9999999)
                  and cosu.anno = w_anno
                group by 1;
                --dbms_output.put_line(' 1 w_fam_coeff '||w_fam_coeff);
                --dbms_output.put_line('Trovato '||to_char(w_max_fam_coeff));
             exception
               when no_data_found then
                 -- dbms_output.put_line('Non Trovato');
                 w_fam_coeff :=   w_max_fam_coeff;
             end;
          end if;
          --dbms_output.put_line('w_fam_coeff '||w_fam_coeff);
          w_dal      :=
           greatest(nvl(to_date('01/01/' || w_anno, 'dd/mm/yyyy')
                       ,to_date('2222222', 'j')
                       )
                   ,to_date('0101' || lpad(to_char(w_anno), 4, '0'), 'ddmmyyyy')
                   );
          w_al      :=
           least(nvl(to_date('31/12/' || w_anno, 'dd/mm/yyyy')
                    ,to_date('3333333', 'j')
                    )
                ,to_date('3112' || lpad(to_char(w_anno), 4, '0'), 'ddmmyyyy')
                );
       end if;
    end if;
    --
    open rc for
      select a_modello modello
            ,to_char(greatest(faso.dal
                     ,to_date('0101' || lpad(to_char(w_anno), 4, '0')
                             ,'ddmmyyyy'
                             )
                     ),'dd/mm/yyyy')
               dal
            ,to_char(least(nvl(faso.al, to_date('31129999', 'ddmmyyyy'))
                  ,to_date('3112' || lpad(to_char(w_anno), 4, '0'), 'ddmmyyyy')
                  ),'dd/mm/yyyy')
               al
            ,faso.numero_familiari numero_familiari
            ,f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , faso.numero_familiari
                                 , w_tributo
                                 , w_categoria
                                 , 'F'
                                 ) stringa_quota_fissa
            ,f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , faso.numero_familiari
                                 , w_tributo
                                 , w_categoria
                                 , 'V'
                                 ) stringa_quota_var
        from familiari_soggetto faso
       where faso.dal <= to_date('3112' || lpad(to_char(w_anno), 4, '0'), 'ddmmyyyy')
         and nvl(faso.al, to_date('3112' || lpad(to_char(w_anno), 4, '0'), 'ddmmyyyy')) >=
             to_date('0101' || lpad(to_char(w_anno), 4, '0'),'ddmmyyyy')
         and faso.anno = w_anno
         -- Riga aggiunta per non considerare dei periodi dell'anno precedente
         and nvl(to_number(to_char(faso.al, 'yyyy')), 9999) >= w_anno
         and faso.ni = w_ni
         and w_fdom = 'S'                   -- tariffa domestica
         and w_esiste_cosu = 'N'            -- non esistono componenti per superficie
         --and a_tipo_calcolo = 2           -- solo per calcolo normalizzato
                                            -- (VD - 16/06/2021): tipo calcolo non più gestito
      union
      select a_modello modello
           , to_char(w_dal,'dd/mm/yyyy')
           , to_char(w_al,'dd/mm/yyyy')
           , w_fam_coeff
           , f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , w_fam_coeff
                                 , w_tributo
                                 , w_categoria
                                 , 'F'
                                 ) stringa_quota_fissa
           , f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , w_fam_coeff
                                 , w_tributo
                                 , w_categoria
                                 , 'V'
                                 ) stringa_quota_var
        from dual
       where w_fdom = 'S'                   -- tariffa domestica
         and w_esiste_cosu = 'S'            -- esistono componenti per superficie
         -- and a_tipo_calcolo = 2          -- (VD - 16/06/2021): tipo calcolo non più gestito
       order by 1;
    return rc;
  end DATI_FAMILIARI;
----------------------------------------------------------------------------------
  function DATI_NON_DOM
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  )
  return sys_refcursor
  is
    w_flag_ab_princ                    varchar2(1);
    w_anno                             number;
    w_tributo                          number;
    w_categoria                        number;
    w_consistenza                      number;
    w_esiste_cosu                      varchar2(1);
    w_fdom                             char;
    w_dal                              date;
    w_al                               date;
    w_fam_coeff                        number;
    rc                                 sys_refcursor;
  begin
    -- Selezione dati oggetto
    begin
      select ogco.flag_ab_principale
           , ogco.anno
           , ogpr.tributo
           , ogpr.categoria
           , ogpr.consistenza
           , cate.flag_domestica
        into w_flag_ab_princ
           , w_anno
           , w_tributo
           , w_categoria
           , w_consistenza
           , w_fdom
        from oggetti_pratica ogpr
           , oggetti_contribuente ogco
           , categorie cate
       where ogpr.oggetto_pratica = a_oggetto_pratica
         and ogpr.oggetto_pratica = ogco.oggetto_pratica
         and ogpr.tributo         = cate.tributo
         and ogpr.categoria       = cate.categoria;
    exception
      when others then
        w_fdom := '*';
    end;
    if w_fdom is null then   -- tariffa non domestica
       w_dal      := to_date('01/01/' || w_anno, 'dd/mm/yyyy');
       w_al       := to_date('31/12/' || w_anno, 'dd/mm/yyyy');
    end if;
    --
    open rc for
      select a_modello modello
           , w_dal data_inizio_validita
           , w_al data_fine_validita
           , f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , w_fam_coeff
                                 , w_tributo
                                 , w_categoria
                                 , 'F'
                                 ) stringa_quota_fissa
           , f_get_stringa_quota ( a_oggetto_pratica
                                 , w_anno
                                 , w_fdom
                                 , w_flag_ab_princ
                                 , w_esiste_cosu
                                 , w_fam_coeff
                                 , w_tributo
                                 , w_categoria
                                 , 'V'
                                 ) stringa_quota_var
        from dual
       where w_fdom is null                 -- tariffa non domestica
         --and a_tipo_calcolo = 2           -- (VD - 16/06/2021): tipo calcolo non più gestito
       order by 1;
    return rc;
  end DATI_NON_DOM;
----------------------------------------------------------------------------------
  function DATI_PARTIZIONI
  ( a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor is
    rc                                 sys_refcursor;
  begin
    open rc for
      select a_modello modello,
             paop.tipo_area,
             decode(paop.numero, null, lpad(' ', 6), lpad(paop.numero,6)) numero,
             decode(paop.consistenza_reale
                   ,null,lpad(' ', 12)
                   ,stampa_common.f_formatta_numero(paop.consistenza_reale,'I')
                   ) consistenza_reale,
             decode(paop.consistenza
                   ,null,lpad(' ', 10)
                   ,stampa_common.f_formatta_numero(paop.consistenza,'I')
                   ) consistenza,
             nvl(paop.flag_esenzione, 'N') esenzione,
             paop.tipo_area||'-'||tiar.descrizione descr_tipo_area
        from tipi_area tiar,
             partizioni_oggetto_pratica paop
       where tiar.tipo_area = paop.tipo_area
         and paop.oggetto_pratica = a_oggetto_pratica;
    return rc;
  end DATI_PARTIZIONI;
----------------------------------------------------------------------------------
  function DATI_ELENCO_FAMILIARI
  ( a_pratica                          number default -1
  , a_modello                          number default -1
  ) return sys_refcursor is
    rc                                 sys_refcursor;
  begin
    open rc for
      select a_modello modello,
             fapr.rapporto_par,
             decode(fapr.rapporto_par,null,null,'Rapporto par.: ') int_rapporto_par,
             fapr.ni,
             fapr.pratica,
             soggetti.cod_fiscale,
             decode(soggetti.cod_fiscale,null,null,'Codice Fiscale: ') int_cod_fiscale,
             translate(soggetti.cognome_nome,'/',' ') cognome_nome,
             to_char(soggetti.data_nas,'dd/mm/yyyy') data_nascita,
             soggetti.sesso,
             soggetti.stato,
             ad4_comuni.denominazione||
             decode(ad4_provincie.sigla, null, '', ' '||ad4_provincie.sigla) comune_nas
        from familiari_pratica fapr,
             soggetti,
             ad4_provincie,
             ad4_comuni
       where soggetti.cod_com_nas = ad4_comuni.comune (+)
         and soggetti.cod_pro_nas = ad4_comuni.provincia_stato (+)
         and ad4_comuni.provincia_stato = ad4_provincie.provincia (+)
         and fapr.ni = soggetti.ni
         and fapr.pratica = a_pratica;
    return rc;
  end DATI_ELENCO_FAMILIARI;
----------------------------------------------------------------------------------
  function DATI_RUOLI
  ( a_cod_fiscale                      varchar2 default ''
  , a_anno                             number default -1
  , a_oggetto_pratica                  number default -1
  , a_modello                          number default -1
  ) return sys_refcursor is
    rc                                 sys_refcursor;
  begin
    open rc for
      select a_modello modello,
             ruoli_oggetto.tributo,
             ruoli_oggetto.categoria,
             ruoli_oggetto.tipo_tariffa,
             ruoli.anno_ruolo,
             stampa_common.f_formatta_numero(ruoli_oggetto.consistenza,'I') consistenza,
             ruoli_oggetto.mesi_ruolo,
             stampa_common.f_formatta_numero(ruoli_oggetto.importo,'I') importo,
             stampa_common.f_formatta_numero(sum(sgravi.importo),'I') sgravio,
             decode(sum(sgravi.importo), null, '', 'Sgravio     :') int_sgravio,
             sgravi.motivo_sgravio,
             decode(sgravi.motivo_sgravio, null, '', 'Motivo :') int_motivo_sgravio
        from ruoli,
             sgravi,
             ruoli_oggetto
       where ruoli_oggetto.ruolo = sgravi.ruolo (+)
         and ruoli_oggetto.cod_fiscale = sgravi.cod_fiscale (+)
         and ruoli_oggetto.sequenza = sgravi.sequenza (+)
         and ruoli.ruolo = ruoli_oggetto.ruolo
         and ruoli.tipo_tributo = 'TARSU'
         and ruoli.invio_consorzio is not null
         and ruoli.anno_ruolo = a_anno
         and ruoli_oggetto.cod_fiscale = a_cod_fiscale
         and ruoli_oggetto.oggetto_pratica = a_oggetto_pratica
  group by ruoli_oggetto.tributo,
           ruoli_oggetto.categoria,
           ruoli_oggetto.tipo_tariffa,
           ruoli_oggetto.consistenza,
           ruoli_oggetto.mesi_ruolo,
           ruoli.anno_ruolo,
           ruoli_oggetto.importo,
           ruoli_oggetto.pratica,
           ruoli_oggetto.oggetto_pratica,
           ruoli_oggetto.oggetto,
           sgravi.motivo_sgravio,
           decode(sgravi.motivo_sgravio, null, '', 'Motivi :')
           ;
    return rc;
  end DATI_RUOLI;
end STAMPA_DENUNCE_TARI;
/
