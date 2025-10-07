--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_ravvedimento_trmi stripComments:false runOnChange:true 
 
create or replace procedure CREA_RAVVEDIMENTO_TRMI
/***************************************************************************
  NOME:        CREA_RAVVEDIMENTO_TRMI
  DESCRIZIONE: Crea una pratica di ravvedimento per tributi diversi da
               ICI/IMU e TASI.
               Richiamata dalla procedure CREA_RAVVEDIMENTO.
  ANNOTAZIONI:
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  016   05/04/2024  RV      #54732
                            Aggiunto gestione scadenze personalizzate
  015   24/01/2024  RV      #69537
                            Modificato selezione scadenza per gruppo tributo
  014   23/02/2023  AB      #62651
                            Aggiunta la eliminazione sanzioni per deceduti
  013   04/05/2022  VD      Aggiunta memorizzazione data versamento in nuovo
                            campo data_scadenza di pratiche_tributo
                            La data della pratica viene sempre valorizzata
                            con la data di sistema.
  012   21/10/2021  VD      Aggiunto controllo sequenza tipi ravvedimento
                            - se tipo_versamento = 'A' non deve esistere un
                            altro ravvedimento unico
                            - se tipo_versamento = 'S' non deve esistere un
                            altro ravvedimento unico
                            - se tipo_versamento = 'U' non deve esistere un
                            altro ravvedimento in acconto o a saldo
                            La presenza di un altro ravvedimento dello stesso
                            tipo di quello che si sta creando e' gia' controllata
                            nella query successiva.
  011   12/10/2021  VD      Modificato richiamo procedures CALCOLO_IMPOSTA...
                            per gestire la presenza di ravvedimento in acconto
                            e ravvedimento a saldo.
  010   07/06/2021  VD      Modificata gestione data pratice in inserimento
                            tabella PRATICHE_TRIBUTO: ora viene inserita la più
                            piccolata tra la data di versamento e la data di
                            sistema.
                            Lo stesso valore viene utilizzato come parametro
                            nel richiamo della procedure NUMERA_PRATICHE.
  009   27/05/2021  VD      Modificata gestione data pratica su tabella
                            PRATICHE_TRIBUTO: ora viene sempre inserita la data
                            di sistema (e non la data di versamento che potrebbe
                            essere > della data di sistema e causare un errore
                            nel trigger della tabella).
  008   28/09/2020  VD      Aggiunta gestione per aggiornamento immobili: se la
                            pratica viene passata come parametro, si eliminano
                            oggetti_imposta, oggetti_pratica e sanzioni_pratica.
  007   26/08/2020  VD      Aggiunto parametro per identificare da dove e'
                            chiamata la procedure: se e' nullo, viene chiamata
                            da TributiWeb altrimenti da TR4.
  006   24/08/2020  VD      Corretto tipo_evento in inserimento pratiche_tributo:
                            ora riporta il tipo versamento (e non "U" fisso)
  005   05/05/2020  VD      Aggiunti codici sanzione relativi a ravvedimento
                            lungo nel test di esistenza della pratica di
                            ravvedimento.
  004   09/03/2020  VD      Gestione nuova tipologia di scadenza per
                            ravvedimento (tipo_scadenza = 'R')
  003   25/07/2018  VD      Si elimina la pratica creata se non contiene
                            sanzioni.
  002   27/10/2017  VD      Modificato controllo di esistenza pratica: aggiunte
                            nuove sanzioni nell'elenco dei codici controllati
  001   13/04/2015  VD      Aggiunta valorizzazione tipo_tributo in inserimento
                            CONTATTI_CONTRIBUENTE
  000   01/12/2008  --      Prima emissione
***************************************************************************/
(a_cod_fiscale      IN  VARCHAR2
,a_anno             IN  NUMBER
,a_data_versamento  IN  DATE
,a_tipo_versamento  IN  VARCHAR2
,a_flag_infrazione  IN  VARCHAR2
,a_utente           IN  VARCHAR2
,a_tipo_tributo     IN  varchar2
,a_pratica          IN OUT NUMBER
,a_provenienza      IN  varchar2 default null
,a_rata             IN  number   default null
,a_gruppo_tributo   IN  varchar2 default null
) IS
w_errore                       varchar(2000) := NULL;
errore                         exception;
--w_anno_scadenza              number;
w_comune                       varchar2(6);
w_delta_anni                   number;
--w_scadenza                   date;
w_scadenza_pres_rav            date;
w_scadenza_rata                date;
w_conta_ravv                   number;
w_conta_ogim                   number;
w_oggetto_pratica              number      := NULL;
w_numera                       varchar2(2000);
w_conta_sanzioni               number;
w_chk_rate                     number;
w_limite                       number := 0.01;
w_stato_sogg                   number(2);
--
w_scadenza_rata_pers           date;
w_scadenza_rata_pers_1         date;
w_scadenza_rata_pers_2         date;
w_scadenza_rata_pers_3         date;
w_scadenza_rata_pers_4         date;
w_num_rate_pers                number;
--
 CURSOR sel_ogge (p_anno        number
                 ,p_cod_fiscale varchar2
                 )IS
  SELECT OGGE.OGGETTO,
         OGPR.OGGETTO_PRATICA   oggetto_pratica_rif,
         OGGE.COD_VIA,
         OGGE.NUM_CIV,
         OGGE.SUFFISSO,
         OGGE.INTERNO,
         OGGE.INDIRIZZO_LOCALITA,
         ARVI.DENOM_UFF,
         OGGE.SEZIONE,
         OGGE.FOGLIO,
         OGGE.NUMERO,
         OGGE.SUBALTERNO,
         OGGE.ZONA,
         OGGE.PARTITA,
         OGGE.PROTOCOLLO_CATASTO,
         OGGE.ANNO_CATASTO,
         OGPR.TIPO_OGGETTO,
         OGPR.TRIBUTO,
         OGPR.CATEGORIA,
         OGPR.TIPO_TARIFFA,
         OGPR.CONSISTENZA,
         OGPR.CONSISTENZA_REALE,
         OGPR.NUM_CONCESSIONE,
         OGPR.DATA_CONCESSIONE,
         OGPR.INIZIO_CONCESSIONE,
         OGPR.FINE_CONCESSIONE,
         OGPR.LARGHEZZA,
         OGPR.PROFONDITA,
         OGPR.TIPO_OCCUPAZIONE,
         OGPR.QUANTITA,
         OGPR.DA_CHILOMETRO,
         OGPR.A_CHILOMETRO,
         OGPR.LATO,
         OGPR.FLAG_CONTENZIOSO,
         OGCO.INIZIO_OCCUPAZIONE,
         OGCO.FINE_OCCUPAZIONE,
         OGVA.DAL DATA_DECORRENZA, --OGCO.DATA_DECORRENZA,
         OGVA.AL DATA_CESSAZIONE, --OGCO.DATA_CESSAZIONE,
         OGCO.PERC_POSSESSO,
         OGCO.PERC_DETRAZIONE,
         OGCO.FLAG_ESCLUSIONE,
         decode( OGGE.COD_VIA, NULL, INDIRIZZO_LOCALITA, DENOM_UFF||decode( num_civ,NULL,'', ', '||num_civ )
                ||decode( suffisso,NULL,'', '/'||suffisso )) indirizzo,
         PRTR.ANNO anno_dic,
         ogpr.oggetto_pratica_rif_ap,
         ogva.tipo_pratica,
         ogim.tipo_rapporto
    FROM ARCHIVIO_VIE ARVI,
         OGGETTI OGGE,
         PRATICHE_TRIBUTO PRTR,
         OGGETTI_PRATICA OGPR,
         OGGETTI_CONTRIBUENTE OGCO,
         OGGETTI_IMPOSTA OGIM,
         oggetti_validita ogva,
         CODICI_TRIBUTO COTR
   WHERE ogge.cod_via          = arvi.cod_via (+) and
         OGCO.OGGETTO_PRATICA  = OGPR.OGGETTO_PRATICA and
         OGPR.PRATICA          = PRTR.PRATICA and
  --       PRTR.PRATICA_RIF   is null and
         PRTR.TIPO_PRATICA  in ('D','A') AND
         OGPR.OGGETTO          = OGGE.OGGETTO and
         OGCO.OGGETTO_PRATICA  = OGIM.OGGETTO_PRATICA and
         OGCO.COD_FISCALE      = OGIM.COD_FISCALE and
         OGIM.TIPO_TRIBUTO     = a_tipo_tributo and
         OGIM.ANNO             = p_anno and
         OGIM.COD_FISCALE      = p_cod_fiscale and
         OGPR.TIPO_OCCUPAZIONE = 'P' and
         OGIM.FLAG_CALCOLO     = 'S' and
         OGVA.TIPO_TRIBUTO     = a_tipo_tributo and
         OGVA.cod_fiscale      = p_cod_fiscale and
         ogva.oggetto_pratica  = ogpr.oggetto_pratica
         and to_date('01/01/'||p_anno,'dd/mm/yyyy') between ogva.dal and nvl(ogva.al,to_date('31/12/9999','dd/mm/yyyy'))
         and ogpr.tributo      = cotr.tributo
         and cotr.tipo_tributo = a_tipo_tributo
         and cotr.gruppo_tributo = a_gruppo_tributo
ORDER BY 1 ASC
    ;
 -------------------------------------------------------------------------
 --                Determina data di scadenza da catalogo               --
 -------------------------------------------------------------------------
FUNCTION F_DATA_SCAD
(a_anno           IN     number
,a_numero_rata    IN     number
,a_tipo_scad      IN     varchar2
,a_gruppo_tributo in     varchar2
,a_data_scadenza  IN OUT date
) return string
IS
w_tipo_tributo_des  varchar2(200);
w_err               varchar2(2000);
w_data              date;
BEGIN
   w_err := null;
   --
   -- Tentativo 1 (solo per tipo 'V') : cerca scadenza senza tipo_occupazione
   --   Se trova esce
   --   Se non trova va avanti
   --
 --dbms_output.put_line('Scad: '||a_tipo_scad||', tributo: '||a_tipo_tributo||', gruppo: '||a_gruppo_tributo||', anno: '||a_anno);
   --
   if a_tipo_scad = 'V' then
     BEGIN
        select scad.data_scadenza
          into w_data
          from scadenze scad
         where scad.tipo_tributo    = a_tipo_tributo
           and scad.anno            = a_anno
           and nvl(scad.rata,-1)    = nvl(a_numero_rata,-1)
           and scad.tipo_scadenza   = a_tipo_scad
           and (((scad.gruppo_tributo is null) and (a_gruppo_tributo is null)) or
               (scad.gruppo_tributo = a_gruppo_tributo))
           and scad.tipo_occupazione is null
        ;
        a_data_scadenza := w_data;
        Return w_err;
     EXCEPTION
        when no_data_found then
           w_err := null;
        WHEN others THEN
           w_err := to_char(SQLCODE)||' - '||SQLERRM;
           Return w_err;
     END;
   end if;
   --
   -- Tentativo 2 (Qualsiasi tipo) : cerca scadenza con tipo_occupazione null o 'P'
   --   Se trova esce
   --   Se non trova genera stringa di errore
   --
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_tributo    = a_tipo_tributo
         and scad.anno            = a_anno
         and nvl(scad.rata,-1)    = nvl(a_numero_rata,-1)
         and scad.tipo_scadenza   = a_tipo_scad
         and (((scad.gruppo_tributo is null) and (a_gruppo_tributo is null)) or
             (scad.gruppo_tributo = a_gruppo_tributo))
         and nvl(scad.tipo_occupazione,'P') = 'P'
      ;
      a_data_scadenza := w_data;
      Return w_err;
   EXCEPTION
      when no_data_found then
        w_tipo_tributo_des := f_descrizione_titr(a_tipo_tributo,a_anno);
        if(a_gruppo_tributo is not null) then
          w_tipo_tributo_des := w_tipo_tributo_des||' ('||a_gruppo_tributo||')';
        end if;
        if a_tipo_scad = 'V' then
            w_err := 'Scadenza di pagamento '||w_tipo_tributo_des||' rata '||a_numero_rata;
         elsif
            a_tipo_scad = 'R' then
            w_err := 'Scadenza di ravvedimento '||w_tipo_tributo_des;
         else
            w_err := 'Scadenza di presentazione denuncia '||w_tipo_tributo_des;
         end if;
         w_err := w_err||' non prevista per anno '||to_char(a_anno);
         Return w_err;
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
         Return w_err;
   END;
END F_DATA_SCAD;
 -------------------------------------------------------------------------
 --           Determina data di scadenza personalizate da ogim          --
 -------------------------------------------------------------------------
FUNCTION F_DATA_SCAD_OGIM
(p_cod_fiscale    in     varchar2
,p_anno           in     number
,p_tipo_tributo   in     varchar2
,p_gruppo_tributo in     varchar2
,p_numero_rata    in     number
,p_data_scadenza  IN OUT date
) return date
is
  --
  w_err               varchar2(2000);
  w_data_scadenza     date;
  --
BEGIN
  --
  w_errore := null;
  w_data_scadenza := null;
  --
  BEGIN
    select min(data_scadenza) as data_scadenza
      into w_data_scadenza
      from (
        select
           min(ogim.data_scadenza) as data_scadenza
         from oggetti_imposta  ogim
            , oggetti_pratica  ogpr
            , codici_tributo   cotr
            , pratiche_tributo prtr
        where ogim.anno             = p_anno
          and ogim.cod_fiscale      = p_cod_fiscale
          and ogim.flag_calcolo     = 'S'
          and ogim.oggetto_pratica  = ogpr.oggetto_pratica
          and ogpr.pratica          = prtr.pratica
          and prtr.tipo_tributo||'' = p_tipo_tributo
          and ogpr.tributo          = cotr.tributo
          and cotr.tipo_tributo     = prtr.tipo_tributo
          and cotr.gruppo_tributo   = p_gruppo_tributo
          and p_numero_rata         = 0
        union
        select
          min(raim.data_scadenza) as data_scadenza
         from rate_imposta    raim
            , codici_tributo  cotr
        where raim.anno             = p_anno
          and raim.cod_fiscale      = p_cod_fiscale
          and raim.tipo_tributo||'' = p_tipo_tributo
          and nvl(raim.conto_corrente,-1) = nvl(cotr.conto_corrente,-1)
          and cotr.tipo_tributo = raim.tipo_tributo
          and cotr.gruppo_tributo   = p_gruppo_tributo
          and raim.rata             = p_numero_rata
          and p_numero_rata         <> 0
      );
  EXCEPTION
    when no_data_found then
      w_data_scadenza := null;
    when OTHERS then
      w_err := 'Errore ricavando scadenza personalizzata';
  END;
  --
  p_data_scadenza := w_data_scadenza;
  --
  return w_err;
END F_DATA_SCAD_OGIM;
 -------------------------------------------------------------------------
 --                    Determina numero rate da ogim                    --
 -------------------------------------------------------------------------
FUNCTION F_NUM_RATE_OGIM
(p_cod_fiscale    in     varchar2
,p_anno           in     number
,p_tipo_tributo   in     varchar2
,p_gruppo_tributo in     varchar2
) return number
is
  --
  w_num_rate          number;
  --
BEGIN
  --
  w_num_rate := 0;
  --
  BEGIN
    select num_rate
      into w_num_rate
      from (
        select
          max(nvl(raim.rata,0)) as num_rate
         from rate_imposta    raim
            , codici_tributo  cotr
        where raim.anno             = p_anno
          and raim.cod_fiscale      = p_cod_fiscale
          and raim.tipo_tributo||'' = p_tipo_tributo
          and nvl(raim.conto_corrente,-1) = nvl(cotr.conto_corrente,-1)
          and cotr.tipo_tributo = raim.tipo_tributo
          and cotr.gruppo_tributo   = p_gruppo_tributo
          and raim.data_scadenza    is not null
      );
  EXCEPTION
    when no_data_found then
      w_num_rate := 0;
    when OTHERS then
      w_errore := 'Errore ricavando numero scadenze personalizzate';
      raise errore;
  END;
  --
  return w_num_rate;
  --
END F_NUM_RATE_OGIM;
 -------------------------------------------------------------------------
 --                               INIZIO                                --
 -------------------------------------------------------------------------
BEGIN
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into w_comune
        from dati_generali
           ;
   END;
 --w_anno_scadenza := to_number(to_char(a_data_versamento,'yyyy'));
   -- (VD - 24/02/2022): se la rata da ravvedere e' uguale a zero, il
   --                    check rate e' settato al valore NO_RATE
   --                    altirmenti e' settato al valore SINGOLO_OGIM,
   --                    per avere rate_imposta di ogni oggetto_imposta
   if a_rata = 0 then
      w_chk_rate := TR4PACKAGE.NO_RATE;
      w_num_rate_pers := 0;
   else
      w_chk_rate := TR4PACKAGE.RATE_SINGOLO_OGIM;
      w_num_rate_pers := F_NUM_RATE_OGIM(a_cod_fiscale,a_anno,a_tipo_tributo,a_gruppo_tributo);
   end if;
--dbms_output.put_line('w_chk_rate: '||w_chk_rate);
 -------------------------------------------------------------------------
 -- Controlli prima della creazione---------------------------------------
 -------------------------------------------------------------------------
--DBMS_OUTPUT.Put_Line('1 - Controlli prima della creazione');
--DBMS_OUTPUT.Put_Line('2 - Controllo dell''anno della pratica');
   -- (VD - 28/09/2020): i seguenti controlli vengono eseguiti solo nel
   --                    caso di creazione di una nuova pratica
   -- Controllo dell'anno della pratica
   if a_pratica is null then
      if a_anno < 1998 then
         w_errore  := 'Gestione Non Prevista per Anni con Vecchio sanzionamento';
      end if;
      -- Cerca data di scadenza personalizzata
      if w_errore is null then
        w_errore := F_DATA_SCAD_OGIM(a_cod_fiscale,a_anno,a_tipo_tributo,a_gruppo_tributo,a_rata,w_scadenza_rata_pers);
      --dbms_output.put_line('Scadenza personalizzata: ('||w_num_rate_pers||') - '||w_scadenza_rata_pers);
      end if;
      -- Cerca data di scadenza standard
      if w_errore is null then
         -- Correttivo per Scadenze (personalizzazioni).
         w_delta_anni := 0;
         -- Lumezzane
         if w_comune = '017096' then
            w_delta_anni := 1;
         end if;
         w_errore := F_DATA_SCAD(a_anno,a_rata,'V',a_gruppo_tributo,w_scadenza_rata);
         -- Va bene pure se non c'è scadenza nei dizionari ma esiste una personalizzata
         if (w_errore is not null) and (w_scadenza_rata_pers is not null) then
           w_errore := null;
         end if;
      end if;
      -- Controllo su data ravvedimento rispetto a data scadenza versamento rata
      -- eventualmente corretta dalla personalizzata se trovata
      if w_errore is null then
        if w_scadenza_rata_pers is not null then
          w_scadenza_rata := w_scadenza_rata_pers;
        end if;
        if a_data_versamento <= w_scadenza_rata then
          w_errore := 'La data del ravvedimento ('||to_char(a_data_versamento,'dd/mm/yyyy')||
                      ') è inferiore alla data di scadenza della rata '||a_rata ||' ('||
                      to_char(w_scadenza_rata,'dd/mm/yyyy')||') - Ravvedimento non possibile';
        end if;
      end if;
-- In questo test  si fa riferimento  con quanto concordato  con San Lazzaro  che a sua volta
-- fa riferimento alla circolare applicativa  184/E del 2001  in cui si dice che se nell`anno
-- del ravvedimento esistono denunce  dell`anno stesso con data  della pratica > alla data di
-- scadenza registrata  nei parametri  di input, la data di scadenza  entro cui ravvedersi e`
-- la data di scadenza  della presentazione  della denuncia  dell`anno successivo, altrimenti
-- e` la data di scadenza dell`anno del ravvedimento  in quanto trattasi di omesso o parziale
-- o tardivo pagamento a fronte di una denuncia senza alcuna variazione.
-- La circolare  in particolare  recita  "bisogna assumere  il termine di presentazione della
-- dichiarazione e non l`altro di un anno dall`omissione o dall`errore"  poiche` il regime di
-- autotassazione in materia di ICI e` analogo a quello previsto  per le imposte erariali sui
-- redditi.
-- Dall`indicatore  a_flag_infrazione  si sa se si e` in un caso o in un altro  poiche` viene
-- settato  solo in presenza  di denunce nell`anno con data superiore alla data di scadenza e
-- in questi casi puo` assumere solo i valore I = Infedele oppure O = Omessa.
-- In definitiva, se questo flag e` nullo non si aggiunge un anno alla data di scadenza della
-- presentazione della denuncia.
--
-- Si seleziona la nuova tipologia di scadenza 'R'
--
      if w_errore is null then
         if a_flag_infrazione is null then
            w_errore := F_DATA_SCAD(a_anno + w_delta_anni,to_number(null),'R',null,w_scadenza_pres_rav);
         else
            w_errore := F_DATA_SCAD(a_anno + w_delta_anni + 1,to_number(null),'R',null,w_scadenza_pres_rav);
         end if;
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('7 - La Data del Ravvedimento e` > alla Scadenza per Ravvedersi');
         if a_data_versamento > w_scadenza_pres_rav then
            w_errore := 'La Data del Ravvedimento '||to_char(a_data_versamento,'dd/mm/yyyy')||
                     ' e` > della Scadenza per Ravvedersi '||to_char(w_scadenza_pres_rav,'dd/mm/yyyy') ||
                     '('||a_cod_fiscale||')';
         end if;
      end if;
      -- Si controlla che:
      -- - se il ravvedimento è relativo a una rata non esista un ravvedimento
      --   relativo alla rata unica
      -- - se il ravvedimento è relativo alla rata unica, non esista un
      --   ravvedimento relativo a una rata
      if w_errore is null then
         BEGIN
            select count(*)
              into w_conta_ravv
              from pratiche_tributo prtr,
                   oggetti_pratica  ogpr,
                   codici_tributo   cotr
             where prtr.cod_fiscale                  = a_cod_fiscale
               and prtr.anno                         = a_anno
               and prtr.tipo_tributo||''             = a_tipo_tributo
               and nvl(prtr.stato_accertamento,'D')  = 'D'
               and prtr.tipo_pratica                 = 'V'
               and prtr.pratica                      = ogpr.pratica
               and ogpr.tributo                      = cotr.tributo
               and cotr.tipo_tributo                 = prtr.tipo_tributo
               and cotr.gruppo_tributo               = a_gruppo_tributo
               and ((prtr.tipo_evento = '0' and a_rata <> 0) or
                    (prtr.tipo_evento <> '0' and a_rata = 0))
                  ;
            if w_conta_ravv > 0 then
               w_errore := 'Numero rata indicato non compatibile con ravvedimento gia'' presente ('||a_cod_fiscale||')';
            end if;
         END;
      end if;
      if w_errore is null then
         --DBMS_OUTPUT.Put_Line('8 - Esistono altre Pratiche di Ravvedimento per questo Pagamento');
         BEGIN
            select count(*)
              into w_conta_ravv
              from sanzioni_pratica sapr
                  ,oggetti_pratica  ogpr
                  ,codici_tributo   cotr
                  ,pratiche_tributo prtr
             where sapr.pratica                      = prtr.pratica
               and prtr.cod_fiscale                  = a_cod_fiscale
               and prtr.anno                         = a_anno
               and prtr.tipo_tributo||''             = a_tipo_tributo
               and nvl(prtr.stato_accertamento,'D')  ='D'
               and prtr.tipo_pratica                 = 'V'
               and prtr.tipo_evento                  = to_char(a_rata)
               and prtr.pratica                      = ogpr.pratica
               and ogpr.tributo                      = cotr.tributo
               and cotr.tipo_tributo                 = prtr.tipo_tributo
               and cotr.gruppo_tributo               = a_gruppo_tributo
                  ;
            if w_conta_ravv > 0 then
               w_errore := 'Esistono altre Pratiche di Ravvedimento per questo Pagamento ('||a_cod_fiscale||')';
            end if;
         END;
      end if;
      if w_errore is null then
         select count (1)
           into w_conta_ogim
           from oggetti_imposta  ogim
              , oggetti_pratica  ogpr
              , codici_tributo   cotr
              , pratiche_tributo prtr
          where ogim.anno             = a_anno
            and ogim.cod_fiscale      = a_cod_fiscale
            and ogim.flag_calcolo     = 'S'
            and ogim.oggetto_pratica  = ogpr.oggetto_pratica
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = a_tipo_tributo
            and ogpr.tributo          = cotr.tributo
            and cotr.tipo_tributo     = prtr.tipo_tributo
            and cotr.gruppo_tributo   = a_gruppo_tributo
              ;
         if w_conta_ogim = 0 then
            w_errore := 'Il contribuente '||a_cod_fiscale||' non ha oggetti '||a_tipo_tributo||' validi per l''anno '||to_char(a_anno);
         end if;
      end if;
      -- Controllo esistenza rata per cui ravvedersi
      if w_errore is null then
         select count(*)
           into w_conta_ogim
           from oggetti_imposta  ogim
              , oggetti_pratica  ogpr
              , codici_tributo   cotr
              , pratiche_tributo prtr
          where ogim.anno             = a_anno
            and ogim.cod_fiscale      = a_cod_fiscale
            and ogim.flag_calcolo     = 'S'
            and ogim.oggetto_pratica  = ogpr.oggetto_pratica
            and ogpr.pratica          = prtr.pratica
            and prtr.tipo_tributo||'' = a_tipo_tributo
            and ogpr.tributo          = cotr.tributo
            and prtr.tipo_tributo     = cotr.tipo_tributo
            and cotr.gruppo_tributo   = a_gruppo_tributo
            and ((a_rata = 0 and exists (select 'x'
                                           from rate_imposta raim
                                          where raim.tipo_tributo  = a_tipo_tributo
                                              and raim.cod_fiscale = a_cod_fiscale
                                              and raim.anno        = a_anno
                                              and nvl(raim.conto_corrente,99999900) = a_gruppo_tributo))
             or  (a_rata <> 0 and not exists (select 'x'
                                                from rate_imposta raim
                                               where raim.tipo_tributo  = a_tipo_tributo
                                                 and raim.cod_fiscale   = a_cod_fiscale
                                                 and raim.anno          = a_anno
                                                 and nvl(raim.conto_corrente,99999900) = a_gruppo_tributo
                                                 and raim.rata          = a_rata))
                 )
              ;
         if w_conta_ogim > 0 then
            w_errore := 'Non esiste la rata '||a_rata||' per cui ravvedersi';
         end if;
      end if;
      if w_errore is null then
         -----------------------------------------------------------------------------------------------
         -- Inserimento della pratica                                                                 --
         -----------------------------------------------------------------------------------------------
         a_pratica := null;
         PRATICHE_TRIBUTO_NR(a_pratica);
         --DBMS_OUTPUT.Put_Line('11 - Inserimento della pratica; '||a_pratica);
         begin
            Insert into PRATICHE_TRIBUTO
                ( PRATICA
                , COD_FISCALE
                , TIPO_TRIBUTO
                , ANNO
                , TIPO_PRATICA
                , TIPO_EVENTO
                , DATA
                , UTENTE
                , DATA_VARIAZIONE
                , TIPO_RAVVEDIMENTO
                , DATA_SCADENZA
                , DATA_RIF_RAVVEDIMENTO
                )
            Values
                ( a_pratica
                , a_cod_fiscale
                , a_tipo_tributo
                , a_anno
                , 'V'
                , to_char(a_rata)
                , trunc(sysdate)
                , a_utente
                , trunc(sysdate)
                , decode(a_flag_infrazione,'','D',a_flag_infrazione)
                , a_data_versamento
                , a_data_versamento
                )
                ;
         EXCEPTION
             WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento pratica per '||a_cod_fiscale;
                  raise errore;
         end;
         begin
            Insert into RAPPORTI_TRIBUTO
                ( PRATICA
                , COD_FISCALE
                , TIPO_RAPPORTO)
            Values
                ( a_pratica
                , a_cod_fiscale
                , NULL)
                ;
         EXCEPTION
             WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento ratr per '||a_cod_fiscale;
                  raise errore;
         end;
         begin
            Insert into contatti_contribuente
                ( cod_fiscale
                , data
                , numero
                , anno
                , tipo_contatto
                , tipo_richiedente
                , testo
                , tipo_tributo)
            Values
                ( a_cod_fiscale
                , trunc(sysdate)
                , NULL
                , a_anno
                , 10
                , 2
                , NULL
                , a_tipo_tributo)
                ;
         EXCEPTION
             WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento CONTATTI_CONTRIBUENTE per '||a_cod_fiscale;
                  raise errore;
         end;
      end if;
      if w_errore is not null then
         raise ERRORE;
      end if;
   end if;
   -- In caso di aggiornamento oggetti, si eliminano oggetti_imposta,
   -- oggetti_pratica e sanzioni_pratica
   if a_pratica is not null then
      begin
        delete sanzioni_pratica
         where pratica = a_pratica;
        delete oggetti_imposta
         where oggetto_pratica in (select oggetto_pratica from oggetti_pratica
                                    where pratica = a_pratica);
        delete oggetti_pratica
         where pratica = a_pratica;
      EXCEPTION
          WHEN OTHERS THEN
               w_errore := 'Errore in eliminazione dati pratica '||a_cod_fiscale;
               raise errore;
      end;
   end if;
   if w_errore is null then
      ----------------------------------------------------
      --- Inserimento degli oggetti-----------------------
      ----------------------------------------------------
      FOR rec_ogge in sel_ogge(a_anno,a_cod_fiscale)
      LOOP
         -- Inserimento Oggetto_Pratica
         w_oggetto_pratica:= null;
         OGGETTI_PRATICA_NR(w_oggetto_pratica);
         --DBMS_OUTPUT.Put_Line('12 - Inserimento Oggetto_Pratica: '||w_oggetto_pratica);
         begin
            Insert into OGGETTI_PRATICA
              ( OGGETTO_PRATICA, OGGETTO, PRATICA
              , ANNO, TRIBUTO, CATEGORIA, TIPO_TARIFFA
              , CONSISTENZA, CONSISTENZA_REALE
              , NUM_CONCESSIONE, DATA_CONCESSIONE
              , INIZIO_CONCESSIONE, FINE_CONCESSIONE
              , LARGHEZZA, PROFONDITA
              , DA_CHILOMETRO, A_CHILOMETRO, LATO
              , TIPO_OCCUPAZIONE, QUANTITA
              , FLAG_CONTENZIOSO
              , OGGETTO_PRATICA_RIF, UTENTE, DATA_VARIAZIONE
              , NOTE, TIPO_OGGETTO)
            Values
              ( w_oggetto_pratica, rec_ogge.oggetto, a_pratica
              , a_anno, rec_ogge.tributo, rec_ogge.categoria, rec_ogge.tipo_tariffa
              , rec_ogge.consistenza, rec_ogge.consistenza_reale
              , rec_ogge.num_concessione, rec_ogge.data_concessione
              , rec_ogge.inizio_concessione, rec_ogge.fine_concessione
              , rec_ogge.larghezza, rec_ogge.profondita
              , rec_ogge.da_chilometro, rec_ogge.a_chilometro, rec_ogge.lato
              , rec_ogge.tipo_occupazione, rec_ogge.quantita
              , rec_ogge.flag_contenzioso
              , rec_ogge.oggetto_pratica_rif, a_utente, trunc(sysdate)
              , decode(a_provenienza, null, 'Ravvedimento Manuale',
                                            'Ravvedimento Automatico'), rec_ogge.tipo_oggetto)
                ;
         EXCEPTION
             WHEN OTHERS THEN
                   w_errore := 'Ins. OGGETTI_PRATICA ( '||a_cod_fiscale
                               ||' '||to_char(nvl(w_oggetto_pratica,0))||' '||to_char(nvl(a_pratica,0))
                               ||' - '||sqlerrm
                               ;
                   raise errore;
         end;
         --DBMS_OUTPUT.Put_Line('13 - Inserimento Oggetto_Contribuente');
         -- Inserimento Oggetto_Contribuente
         begin
             insert into OGGETTI_CONTRIBUENTE
               ( COD_FISCALE, OGGETTO_PRATICA, ANNO
               , TIPO_RAPPORTO
               , INIZIO_OCCUPAZIONE, FINE_OCCUPAZIONE
               , DATA_DECORRENZA, DATA_CESSAZIONE
               , PERC_POSSESSO, PERC_DETRAZIONE
               , UTENTE )
             values
               ( a_cod_fiscale, w_oggetto_pratica, a_anno
               , rec_ogge.tipo_rapporto
               , rec_ogge.inizio_occupazione, rec_ogge.fine_occupazione
               , rec_ogge.data_decorrenza, rec_ogge.data_cessazione
               , rec_ogge.perc_possesso, rec_ogge.perc_detrazione
               , a_utente )
                ;
         EXCEPTION
             WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento oggetto_contribuente per '||a_cod_fiscale;
                   raise errore;
         end;
         --DBMS_OUTPUT.Put_Line('16 - Inserimento Oggetto_Imposta');
         -- Inserimento Oggetto_Imposta
         begin
            insert into OGGETTI_IMPOSTA
                  ( COD_FISCALE, OGGETTO_PRATICA, ANNO
                  , IMPOSTA, IMPOSTA_ACCONTO, IMPOSTA_DOVUTA
                  , IMPOSTA_DOVUTA_ACCONTO, DETRAZIONE, DETRAZIONE_ACCONTO
                  , FLAG_CALCOLO, UTENTE, NOTE, TIPO_TRIBUTO, TIPO_RAPPORTO )
           values ( a_cod_fiscale, w_oggetto_pratica, a_anno
                  , 0, NULL, NULL
                  , NULL, NULL, NULL
                  , NULL, a_utente, NULL, a_tipo_tributo, rec_ogge.tipo_rapporto )
                  ;
         EXCEPTION
            WHEN OTHERS THEN
                  w_errore := 'Errore in inserimento oggetto imposta per '||a_cod_fiscale;
                  raise errore;
         end;
      END LOOP;
      --
      if w_oggetto_pratica is null then
         w_errore := 'Per il contribuente non esistono oggetti per cui ravvedersi'||a_cod_fiscale;
         raise errore;
      end if;
   -------------------------------------------------------------------------
   -- Calcoli --------------------------------------------------------------
   -------------------------------------------------------------------------
      -- Calcolo Imposta
    --dbms_output.put_line('Pratica: '||a_pratica);
      if a_tipo_tributo = 'CUNI' then
        -- Prima di tutto prepara le scadenze personalizzate, se necessario
        w_scadenza_rata_pers_1 := null;
        w_scadenza_rata_pers_2 := null;
        w_scadenza_rata_pers_3 := null;
        w_scadenza_rata_pers_4 := null;
        --
        if w_scadenza_rata_pers is not null then
          w_scadenza_rata_pers_1 := w_scadenza_rata_pers;     --- Unica o rata 1
          if w_num_rate_pers >= 2 then
            w_scadenza_rata_pers_2 := w_scadenza_rata_pers;
          end if;
          if w_num_rate_pers >= 3 then
            w_scadenza_rata_pers_3 := w_scadenza_rata_pers;
          end if;
          if w_num_rate_pers >= 4 then
            w_scadenza_rata_pers_4 := w_scadenza_rata_pers;
          end if;
        end if;
        --
      --dbms_output.put_line('Scadenza 1: '||w_scadenza_rata_pers_1);
      --dbms_output.put_line('Scadenza 2: '||w_scadenza_rata_pers_2);
      --dbms_output.put_line('Scadenza 3: '||w_scadenza_rata_pers_3);
      --dbms_output.put_line('Scadenza 4: '||w_scadenza_rata_pers_4);
        --
      --dbms_output.put_line('Calcolo imposta, pratica: '||a_pratica);
        CALCOLO_IMPOSTA_CU(a_anno, a_cod_fiscale, a_tipo_tributo, to_number(null),
                            a_utente, null, null, w_chk_rate, w_limite, a_pratica, 'S', null,
                            w_scadenza_rata_pers_1, w_scadenza_rata_pers_2, w_scadenza_rata_pers_3, w_scadenza_rata_pers_4);
        -- (VD - 24/02/2022): una volta calcolata l'imposta, se il ravvedimento
        --                    riguarda la rata unica (rata = 0) significa che
        --                    il ravvedimento e' relativo all'intera imposta e
        --                    non si fa più nulla.
        --                    In caso contrario, si aggiornano gli importi
        --                    di oggetti_imposta con quelli presenti nella rata
        --                    per cui ravvedersi e si eliminano le altre rate.
        if a_rata > 0 then
            for rata in (select raim.oggetto_imposta
                              , raim.imposta
                              , raim.data_scadenza
                           from rate_imposta raim
                              , oggetti_imposta ogim
                              , oggetti_pratica ogpr
                          where ogpr.pratica = a_pratica
                            and ogpr.oggetto_pratica = ogim.oggetto_pratica
                            and ogim.oggetto_imposta = raim.oggetto_imposta
                            and raim.rata = a_rata
                        )
            loop
            --dbms_output.put_line('Oggetto imposta: '||rata.oggetto_imposta||', Imposta: '||rata.imposta);
              begin
                update oggetti_imposta
                   set imposta = rata.imposta,
                       data_scadenza = rata.data_scadenza
                 where oggetto_imposta = rata.oggetto_imposta;
              exception
                when others then
                  w_errore := 'Errore in upd. OGGETTI_IMPOSTA ('||rata.oggetto_imposta||') - '||sqlerrm;
                  raise errore;
              end;
            end loop;
            --dbms_output.put_line('Eliminazione rate');
            begin
              delete from rate_imposta raim
               where raim.rata <> a_rata
                 and raim.oggetto_imposta in (select ogim.oggetto_imposta
                                                from oggetti_imposta ogim
                                                   , oggetti_pratica ogpr
                                               where ogpr.pratica = a_pratica
                                                 and ogpr.oggetto_pratica = ogim.oggetto_pratica);
            exception
              when others then
                w_errore := 'Errore in del. RATE_IMPOSTA ('||a_pratica||') - '||sqlerrm;
                raise errore;
            end;
         end if;
        -- Calcolo Sanzioni
      --dbms_output.put_line('Calcolo sanzioni');
        CALCOLO_SANZIONI_RAOP_CUNI(a_pratica, a_tipo_versamento, a_data_versamento, a_utente,
                                                                        a_flag_infrazione, a_gruppo_tributo);
      end if;
   end if;
   --
   -- Se la pratica appena inserita non contiene sanzioni viene cancellata,
   -- non si esegue la numerazione e si restituisce null
   --
 --dbms_output.put_line('Conteggio Sanzioni');
   begin
     select count(*)
       into w_conta_sanzioni
       from sanzioni_pratica
      where pratica = a_pratica
      group by pratica;
   exception
     when others then
       w_conta_sanzioni := 0;
   end;
   --
   if w_conta_sanzioni = 0 then
      begin
        delete from pratiche_tributo
         where pratica = a_pratica;
      exception
        when others then
          w_errore := substr('Eliminazione pratica ravv. priva di sanzioni per '||a_cod_fiscale||
                      ' ('||sqlerrm||')',1,2000);
          raise errore;
      end;
      a_pratica := to_number(null);
   else
      -- Numerazione pratica
      begin
        select valore
          into w_numera
          from installazione_parametri
         where parametro = 'N_AUTO_RAV'
        ;
      EXCEPTION
        WHEN OTHERS THEN
           w_numera := 'N';
      end;
      if w_numera = 'S' then
         numera_pratiche( a_tipo_tributo, 'V', null, a_cod_fiscale, a_anno, a_anno
                        , least(trunc(sysdate),a_data_versamento)
                        , least(trunc(sysdate),a_data_versamento));
      end if;
        -- (AB - 23/02/2023): se il contribuente è deceduto, si eliminano
        --                    le sanzioni lasciando solo imposta evasa,
        --                    interessi e spese di notifica
       BEGIN
          select stato
            into w_stato_sogg
            from soggetti sogg, contribuenti cont
           where sogg.ni = cont.ni
             and cont.cod_fiscale = a_cod_fiscale
          ;
       EXCEPTION
          WHEN others THEN
             w_errore := 'Errore in ricerca SOGGETTI '||SQLERRM;
             RAISE errore;
       END;
       if w_stato_sogg = 50 then
          ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
       end if;
   end if;
   if w_errore is not null then
      a_pratica := null;
      raise errore;
   end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CREA_RAVVEDIMENTO_TRMI */
/
