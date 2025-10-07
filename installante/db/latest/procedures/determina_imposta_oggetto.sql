--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_imposta_oggetto stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_IMPOSTA_OGGETTO
/*************************************************************************
 Rev.  Data         Autore    Descrizione
 18    10/07/2025   RV        #78725
                              Modifica per popolamento dati importi parziali di oggetti_ogim
 17    04/12/2024   AB        #76723
                              aggiunta la nvl(ogpr.oggetto_pratica_rif_ap,ogpr.oggetto_pratica_rif)
                              quando si ricerca per ogog, utile nel caso di ravvedimenti
 16    09/02/2024   AB        #66356
                              Recuperate correttamente i tipi_Aliquota per le pertinenze,
                              usando la max(sequenza) anziche la min
 15    08/01/2024   AB        #66356
                              Recuperate correttamente i tipi_Aliquota per le pertinenze,
                              relative all'ab principale, controllo con da_mese_possesso
 14    04/01/2024   AB        #69241
                              Recuperata l'aliquota dell'ab primncipale nel
                              caso di Ravv e quindi senza flag_calcolo = 'S'
 13    17/02/2022   VD        Corretto test finale su tipo_aliquota/aliquota:
                              ora se aliquota null viene annullato anche il
                              tipo_aliquota.
 12    11/06/2021   VD        Valorizzato nuovo campo da_mese_posesso in
                              tabella OGGETTI_OGIM.
 11    23/10/2020   VD        Modifiche per calcolo IMU a saldo 2020
                              (D.L. 14 agosto 2020 - utilizzando il campo
                              perc_saldo presente in tabella ALIQUOTE)

 10    12/06/2019   VD        Aggiunta valorizzazione tipo tributo in
                              inserimento OGGETTI_OGIM.

 9     30/07/2018   VD        Corretta determinazione aliquota pertinenze
                              in presenza di ALIQUOTE_OGCO/OGGETTI_OGIM.

 8     18/04/2018   VD        Corretta determinazione aliquota acconto:
                              nel caso in cui per l'anno non esistesse
                              l'aliquota indicata in ALIQUOTE_OGCO
                              veniva valorizzata una variabile sbagliata.
                              Di conseguenza l'aliquota acconto rimaneva
                              nulla.

 7     18/01/2017   VD        Modifica ricerca aliquota acconto per
                              pertinenza di di un oggetto non abitazione
                              principale
                              Aggiunta selezione flag imposta e
                              importo riduzione per tipo aliquota
                              di pertinenza di

 6     14/12/2016   VD        Modificata ricerca aliquota acconto per
                              categoria: al posto di anno_rif - 1 si passa
                              il parametro p_aliquota_base = 'S' alla funzione
                              F_ALIQUOTA_ALCA per ottenere l'aliquota base
                              presente nella tabella ALIQUOTE_CATEGORIA

 5     20/05/2016   VD        Modificata selezione aliquota per pertinenze di:
                              se il tipo aliquota della pertinenza di in
                              oggetti_imposta e' nullo, significa che ci sono
                              state variazioni di aliquota nel periodo.
                              In questo caso si effettua la ricerca in
                              OGGETTI_OGIM.

 4     10/05/2016   VD        Modifiche anno 2016 - gestione flag_riduzione
                              e riduzione_imposta per concordati e comodati.

 3     08/06/2015   VD        Sostituiti gli nvl della modifica precedente
                              con decode sul tipo_aliquota di OGGETTI_IMPOSTA.
                              Questo per evitare che venga impostata
                              l'aliquota erariale anche per i tipi aliquota = 2.
                              Quindi, se esiste il tipo aliquota, le aliquote
                              vengono valorizzate con i relativi valori;
                              altrimenti si utilizzano le aliquote del tipo
                              aliquota originale.

2     09/01/2015   SC         Aggiunti gli nvl nella query della modifica
                              precedente: se per l'abitazione relativa alla
                              pertinenza non si era potuto registrare
                              l'aliquota (in quanto variata in corso d'anno),
                              allora sulla pertinenza lascia l'aliquota che
                              si è calcolato sopra.

 1     27/11/2014   VD        Modificata determinazione aliquota su
                              pertinenze altri oggetti (non abitazione
                              principale)
*************************************************************************/
(p_oggetto                    in     number
,p_anno                       in     number
,p_cod_fiscale                in     varchar2
,p_oggetto_pratica            in     number
,p_data_inizio                in     date
,p_data_fine                  in     date
,p_data_inizio_1s             in     date
,p_data_fine_1s               in     date
,p_mesi_riduzione             in     number
,p_mesi_riduzione_1s          in     number
,p_tipo_oggetto               in     number
,p_categoria                  in     varchar2
,p_moltiplicatore             in     number
,p_rivalutazione              in     number
,p_aliquota_base              in     number
,p_aliquota_affitto           in     number
,p_aliquota_non_affitto       in     number
,p_aliquota_c01               in     number
,p_aliquota_d                 in     number
,p_aliquota_d10               in     number
,p_aliquota_2_casa            in     number
,p_aliquota_base_1s           in     number
,p_aliquota_affitto_1s        in     number
,p_aliquota_non_affitto_1s    in     number
,p_aliquota_c01_1s            in     number
,p_aliquota_d_1s              in     number
,p_aliquota_d10_1s            in     number
,p_aliquota_2_casa_1s         in     number
,p_aliquota_base_erar         in     number
,p_aliquota_affitto_erar      in     number
,p_aliquota_non_affitto_erar  in     number
,p_aliquota_c01_erar          in     number
,p_aliquota_d_erar            in     number
,p_aliquota_d10_erar          in     number
,p_aliquota_2_casa_erar       in     number
,p_tipo_al_affitto            in     number
,p_tipo_al_non_affitto        in     number
,p_tipo_al_c01                in     number
,p_tipo_al_d                  in     number
,p_tipo_al_d10                in     number
,p_tipo_al_2_casa             in     number
,p_perc_acconto               in     number
,p_valore                     in     number
,p_valore_dovuto              in     number
,p_perc_possesso              in     number
,p_aliquota_base_std          in     number
,p_al_ab_principale_std       in     number
,p_al_affittato_std           in     number
,p_aliquota_non_affitto_std   in     number
,p_aliquota_2_casa_std        in     number
,p_aliquota_c01_std           in     number
,p_aliquota_d_std             in     number
,p_aliquota_d10_std           in     number
,p_al_terreni_rid_std         in     number
,p_tipo_tributo               in     varchar2
,p_imposta                    in out number
,p_imposta_dovuta             in out number
,p_imposta_1s                 in out number
,p_imposta_dovuta_1s          in out number
,p_imposta_erar               in out number
,p_imposta_erar_1s            in out number
,p_imposta_erar_dov           in out number
,p_imposta_erar_dov_1s        in out number
,p_tipo_al                    in out number
,p_aliquota                   in out number
,p_aliquota_erar              in out number
,p_imposta_std                in out number
,p_imposta_dovuta_std         in out number
,p_al_std                     in out number
,p_dettaglio_ogim             in out varchar2
) is
--
w_cod_istat           varchar2(6);
nflag_riduzione       number;
nflag_riduzione_1s    number;
nmesi_riduzione       number;
nmesi_riduzione_1s    number;
nMese                 number;
nMese_Inizio          number;
nMese_Fine            number;
nMese_Inizio_1s       number;
nMese_Fine_1s         number;
nConta_Affitti        number;
nConta_Tipo_Aliquote  number;
nConta_Aliquote       number;
nConta_Aliquote_erar  number;
sAffittato            varchar2(2);
nTipo_Utilizzo        number;
nAliquota_Aff_Sp      number;
nAliquota_Aff_Sp_1s   number;
nAliquota_Aff_Sp_b    number;
nAliquota_Aff_Sp_erar number;
sCategoria            varchar2(3);
nRendita              number;
nMoltiplicatore       number;
nValore               number;
nValoreDovuto         number;
nImposta              number;
nImposta_Dovuta       number;
nImposta_1s           number;
nImposta_Dovuta_1s    number;
nImposta_erar         number;
nImposta_erar_1s      number;
nImposta_erar_dov     number;
nImposta_erar_dov_1s  number;
nMesi                 number;
nMesi_1s              number;
nTipo_Aliquota        number;
nAliquota             number;
nAliquota_1s          number;
nAliquota_erar        number;
nTipo_Aliquota_ogco   number;
nAliquota_ogco        number;
--nAliquota_ogco_base   number;
nAliquota_ogco_1s     number;
nAliquota_ogco_erar   number;
nTotale               number;
nTotale_Dovuto        number;
nTotale_1s            number;
nTotale_Dovuto_1s     number;
nTotale_erar          number;
nTotale_erar_1s       number;
nTotale_erar_dov      number;
nTotale_erar_dov_1s   number;
--
nTotale_prec               number;
nTotale_Dovuto_prec        number;
nTotale_1s_prec            number;
nTotale_Dovuto_1s_prec     number;
nTotale_erar_prec          number;
nTotale_erar_1s_prec       number;
nTotale_erar_dov_prec      number;
nTotale_erar_dov_1s_prec   number;
--
nParziali_prec             number;
nParziali_Dovuto_prec      number;
nParziali_1s_prec          number;
nParziali_Dovuto_1s_prec   number;
nParziali_erar_prec        number;
nParziali_erar_1s_prec     number;
nParziali_erar_dov_prec    number;
nParziali_erar_dov_1s_prec number;
--
nTipo_Al              number;
nAliq                 number;
nAliq_erar            number;
sImm_Storico          varchar2(1);
nMesiPoss             number := 0;
nMesiPoss1Sem         number := 0;
nMesiRiduz            number := 0;
nMesiEsclus           number := 0;
nMesiAlRid            number := 0;
nSequenza             number := 0;
nTipo_AliquotaPrec    number;
nAliquotaPrec         number;
nAliquota_erarPrec    number;
--
nTotale_std           number;
nTotale_std_dov       number;
nAliq_std             number;
nAliquota_std         number;
nAliquota_Aff_Sp_std  number;
nAliquota_ogco_std    number;
nImposta_std          number;
nImposta_std_dov      number;
nConta_Aliquote_std   number;
nAliquota_stdPrec     number;

nAliquota_rif_ap      number;
nAliquota_base_rif_ap number;
nAliquota_1s_rif_ap   number;
nAliquota_erar_rif_ap number;
nAliquota_std_rif_ap  number;
nTipo_Aliquota_rif_ap number;

w_flag_riduzione      varchar2(1);
w_riduzione_imp       number(6,2);
w_flag_rid_prec       varchar2(1);
w_rid_imp_prec        number(6,2);
w_dettaglio_ogim      varchar2(2000) := '';
--
nMesiRifAp            number;
--
w_perc_saldo          number;
w_imposta_saldo       number;
w_imposta_saldo_erar  number;
--
w_note_saldo          varchar2(200);
--
BEGIN
  --
  --dbms_output.put_line('Oggetto pratica: '||p_oggetto_pratica);
  --dbms_output.put_line('Tipo tributo: '||p_tipo_tributo);
  --dbms_output.put_line('Inizio possesso: '||to_char(p_data_inizio,'dd/mm/yyyy'));
  --dbms_output.put_line('Fine possesso: '||to_char(p_data_fine,'dd/mm/yyyy'));
  --
   nmesi_riduzione    := p_mesi_riduzione;
   nmesi_riduzione_1s := p_mesi_riduzione_1s;
   nTotale            := 0;
   nTotale_Dovuto     := 0;
   nTotale_1s         := 0;
   nTotale_Dovuto_1s  := 0;
   nTotale_erar       := 0;
   nTotale_erar_1s    := 0;
   nTotale_erar_dov    := 0;
   nTotale_erar_dov_1s := 0;
   nTipo_Al           := null;
   nAliq              := null;
   nAliq_erar         := null;
   nConta_Tipo_Aliquote := 0;
   nConta_Aliquote      := 0;
   nConta_Aliquote_erar := 0;
   nMese_Inizio       := to_number(to_char(p_data_inizio,'mm'));
   nMese_Fine         := to_number(to_char(p_data_fine,'mm'));
   nMesi              := nMese_Fine - nMese_Inizio + 1;
   if p_data_inizio_1s is not null then
      nMese_Inizio_1s := to_number(to_char(p_data_inizio_1s,'mm'));
      nMese_Fine_1s   := to_number(to_char(p_data_fine_1s,'mm'));
      nMesi_1s        := nMese_Fine_1s - nMese_Inizio_1s + 1;
   else
      nMese_Inizio_1s := null;
      nMese_Fine_1s   := null;
      nMesi_1s        := 0;
   end if;

   nTotale_std         := 0;
   nTotale_std_dov     := 0;
   nAliq_std           := null;
   nConta_Aliquote_std := 0;
   --
   -- Estrazione dei dati del Comune
   -- Serve per caso speciale : Sassuolo (036040)
   --
   BEGIN
     select lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
       into w_cod_istat
       from dati_generali
       ;
   EXCEPTION
     WHEN no_data_found THEN
       w_cod_istat := '';
     WHEN others THEN
       w_cod_istat := '';
   END;
   BEGIN
      select count(*)
        into nConta_Affitti
        from utilizzi_oggetto utog
       where utog.oggetto                = p_oggetto
         and utog.data_scadenza         >= p_data_inizio
         and utog.tipo_tributo           = p_tipo_tributo
         and decode(utog.anno
                   ,to_number(to_char(utog.data_scadenza,'yyyy'))
                   ,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
                   ,add_months(to_date('3112'||lpad(to_char(utog.anno),4,'0'),'ddmmyyyy') + 1,utog.mesi_affitto * -1)
                   )                    <= p_data_fine
        and utog.anno                   <= p_anno
        and (   utog.tipo_utilizzo       = 1
             or utog.tipo_utilizzo between 61 and 99
            )
        and nvl(utog.mesi_affitto,0)     > 0
      ;

   END;
   --
   -- Totali sequenza precedente
   --
   nTotale_prec               := 0;
   nTotale_Dovuto_prec        := 0;
   nTotale_1s_prec            := 0;
   nTotale_Dovuto_1s_prec     := 0;
   nTotale_erar_prec          := 0;
   nTotale_erar_1s_prec       := 0;
   nTotale_erar_dov_prec      := 0;
   nTotale_erar_dov_1s_prec   := 0;
   --
   -- Somma dei parziali sequenze n - 1 proporzionate a % possesso e % acconto
   --
   nParziali_prec             := 0;
   nParziali_Dovuto_prec      := 0;
   nParziali_1s_prec          := 0;
   nParziali_Dovuto_1s_prec   := 0;
   nParziali_erar_prec        := 0;
   nParziali_erar_1s_prec     := 0;
   nParziali_erar_dov_prec    := 0;
   nParziali_erar_dov_1s_prec := 0;
   --
   -- nValore è arrotondato all'euro, quindi arrotondiamo pure questo altrimenti
   -- possono emergere difformkità di alcuni centesimi sul dovuto.
   --
   nValoreDovuto := round(p_valore_dovuto,0);
   --
   -- Calcola ogni singola mensilità e determina i vari totali
   --
   nMese := nMese_Inizio - 1;
   LOOP
      nMese := nMese + 1;
--dbms_output.put_line(' OGPR : '||p_oggetto_pratica||', mese '||nmese||', mese_inizio' ||nmese_inizio||', mese_fine' ||nmese_fine);
      if nMese > nMese_Fine then
         exit;
      end if;
      if nmesi_riduzione > 0 then
         nflag_riduzione :=2;
      else
         nflag_riduzione :=1;
      end if;
      if nmesi_riduzione_1s > 0 then
         nflag_riduzione_1s :=2;
      else
         nflag_riduzione_1s :=1;
      end if;
      nmesi_riduzione := nmesi_riduzione - 1;
      nmesi_riduzione_1s := nmesi_riduzione_1s - 1;
      BEGIN
         select to_number(substr(max(
               lpad(to_char(utog.anno),4,'0')
               ||to_char(utog.data_scadenza,'yyyymmdd')
               ||lpad(to_char(utog.tipo_utilizzo),2,'0')
                               )
                         ,13,2)
                     )
          into nTipo_Utilizzo
          from utilizzi_oggetto utog
         where utog.oggetto                = p_oggetto
           and utog.tipo_tributo           = p_tipo_tributo
           and utog.data_scadenza         >= to_date('01'||
                                                      lpad(to_char(nMese),2,'0')||
                                                      lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                     )
           and decode(utog.anno
                      ,to_number(to_char(utog.data_scadenza,'yyyy'))
                      ,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
                      ,add_months(to_date('3112'||lpad(to_char(utog.anno),4,'0'),'ddmmyyyy') + 1,utog.mesi_affitto * -1)
                      )                    <= last_day(to_date('01'||
                                                               lpad(to_char(nMese),2,'0')||
                                                               lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                              )
                                               )
           and utog.anno                   <= p_anno
           and (   utog.tipo_utilizzo       = 1
                or utog.tipo_utilizzo between 61 and 99
               )
           and nvl(utog.mesi_affitto,0)     > 0
           and decode(w_cod_istat,'036040'
                   ,decode(lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0')
                        ,to_char(utog.data_scadenza,'mmyyyy')
                      ,to_number(to_char(utog.data_scadenza,'dd'))
                      ,30)
                ,30)  >= 15
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
              null;  -- AB Non uscira mai da qui perche ce la max
      END;

      IF ltrim(nTipo_Utilizzo) is null THEN
         BEGIN
             select to_number(substr(max(
                   lpad(to_char(utog.anno),4,'0')
                   ||to_char(utog.data_scadenza,'yyyymmdd')
                   ||lpad(to_char(utog.tipo_utilizzo),2,'0')
                                   )
                             ,13,2)
                         )
              into nTipo_Utilizzo
              from oggetti_pratica ogpr_rif
                 , oggetti_pratica ogpr
                 , utilizzi_oggetto utog
             where utog.oggetto                = ogpr_rif.oggetto
               and ogpr_rif.oggetto_pratica    = ogpr.oggetto_pratica_rif_ap
               and ogpr.oggetto_pratica        = p_oggetto_pratica
               and utog.tipo_tributo           = p_tipo_tributo
               and utog.data_scadenza         >= to_date('01'||
                                                          lpad(to_char(nMese),2,'0')||
                                                          lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                         )
               and decode(utog.anno
                          ,to_number(to_char(utog.data_scadenza,'yyyy'))
                          ,add_months(last_day(utog.data_scadenza) + 1,utog.mesi_affitto * -1)
                          ,add_months(to_date('3112'||lpad(to_char(utog.anno),4,'0'),'ddmmyyyy') + 1,utog.mesi_affitto * -1)
                          )                    <= last_day(to_date('01'||
                                                                   lpad(to_char(nMese),2,'0')||
                                                                   lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                                  )
                                                   )
               and utog.anno                   <= p_anno
               and (   utog.tipo_utilizzo       = 1
                    or utog.tipo_utilizzo between 61 and 99
                   )
               and nvl(utog.mesi_affitto,0)     > 0
               and decode(w_cod_istat,'036040'
                       ,decode(lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0')
                            ,to_char(utog.data_scadenza,'mmyyyy')
                          ,to_number(to_char(utog.data_scadenza,'dd'))
                          ,30)
                    ,30)  >= 15
             ;

         EXCEPTION
         WHEN NO_DATA_FOUND THEN
            --sAffittato           := 'NO';
            nTipo_Utilizzo       := null;
         END;
      END IF;

      -- AB 20/5/2016 Aggiunto fuori sotto if quello che era in no_data_found

      IF ltrim(nTipo_Utilizzo) is null THEN
         --sAffittato           := 'NO';
         nTipo_Utilizzo       := null;
      END IF;

      if nTipo_Utilizzo is null then
         sAffittato     := 'NO';
      else
         sAffittato     := 'SI';
      end if;

      if nvl(nTipo_Utilizzo,100) = 100 then
         nAliquota_Aff_Sp        := null;
         nAliquota_Aff_Sp_1s     := null;
         nAliquota_Aff_Sp_erar   := null;
         nAliquota_Aff_Sp_std    := null;
         nTipo_Aliquota          := p_tipo_al_affitto;
         w_flag_riduzione        := null;
         w_riduzione_imp         := 100;
      else
         --
         -- (VD - 10/05/2016): aggiunta selezione flag_imposta e
         --                    riduzione imposta per tipo_aliquota
         --
         BEGIN
            select aliq.aliquota
                 , aliq.aliquota_base
                 , aliq.aliquota_erariale
                 , aliq.aliquota_std
                 , aliq.flag_riduzione
                 , nvl(aliq.riduzione_imposta,100)
              into nAliquota_Aff_Sp
                 , nAliquota_Aff_Sp_b
                 , nAliquota_Aff_Sp_erar
                 , nAliquota_Aff_Sp_std
                 , w_flag_riduzione
                 , w_riduzione_imp
              from aliquote aliq
             where aliq.anno          = p_anno
               and aliq.tipo_aliquota = nTipo_Utilizzo
               and aliq.tipo_tributo  = p_tipo_tributo
            ;
            nTipo_Aliquota       := nTipo_Utilizzo;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               nAliquota_Aff_Sp      := null;
               nAliquota_Aff_Sp_b    := null;
               nAliquota_Aff_Sp_erar := null;
               nAliquota_Aff_Sp_std  := null;
               nTipo_Aliquota        := p_tipo_al_affitto;
               w_flag_riduzione      := null;
               w_riduzione_imp       := 100;
         END;
         nAliquota_Aff_Sp_1s := nAliquota_Aff_Sp;
      end if;

      if nvl(nTipo_Utilizzo,100) = 1 then
         --
         -- (VD - 10/05/2016): aggiunta selezione flag_imposta e
         --                    riduzione imposta per tipo_aliquota
         --
         BEGIN
            select aliq.aliquota
                 , aliq.aliquota_base
                 , aliq.aliquota_erariale
                 , aliq.aliquota_std
                 , aliq.flag_riduzione
                 , nvl(aliq.riduzione_imposta,100)
              into nAliquota_Aff_Sp
                 , nAliquota_Aff_Sp_b
                 , nAliquota_Aff_Sp_erar
                 , nAliquota_Aff_Sp_std
                 , w_flag_riduzione
                 , w_riduzione_imp
              from aliquote aliq
             where aliq.anno          = p_anno
               and aliq.tipo_aliquota = 3
               and aliq.tipo_tributo  = p_tipo_tributo
            ;
            nTipo_Aliquota       := 3;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               nAliquota_Aff_Sp      := null;
               nAliquota_Aff_Sp_b    := null;
               nAliquota_Aff_Sp_erar := null;
               nAliquota_Aff_Sp_std  := null;
               nTipo_Aliquota        := p_tipo_al_affitto;
               w_flag_riduzione      := null;
               w_riduzione_imp       := 100;
         END;
         if p_anno > 2000 and p_anno < 2012 then
            BEGIN
               select aliq.aliquota
                 into nAliquota_Aff_Sp_1s
                 from aliquote aliq
                where aliq.anno          = p_anno - 1
                  and aliq.tipo_aliquota = 3
                  and aliq.tipo_tributo  = p_tipo_tributo
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  nAliquota_Aff_Sp_1s  := null;
            END;
         else
            nAliquota_Aff_Sp_1s  := nAliquota_Aff_Sp;
         end if;
         nAliquota_Aff_Sp_1s := nvl(nAliquota_Aff_Sp_b,nAliquota_Aff_Sp_1s);
      end if;

      BEGIN
         select nvl(ogpr.imm_storico,'N')
           into sImm_Storico
           from oggetti_pratica ogpr
          where ogpr.oggetto_pratica = p_oggetto_pratica
            ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            sImm_Storico := 'N';
      END;

      if p_tipo_oggetto = 4 then
         nValore := p_valore;
         -- aggiunta per Cinisello
         sCategoria := p_categoria;
      else
         BEGIN
            select nvl(riog.rendita,0)
                  ,riog.categoria_catasto
              into nRendita
                  ,sCategoria
              from riferimenti_oggetto riog
             where riog.oggetto                = p_oggetto
               and riog.fine_validita         >= to_date('01'||
                                                         lpad(to_char(nMese),2,'0')||
                                                         lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                        )
               and riog.inizio_validita       <= last_day(to_date('01'||
                                                                  lpad(to_char(nMese),2,'0')||
                                                                  lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                                 )
                                                  )
            and least(last_day(to_date('01'||lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                         )
                  ),riog.fine_validita) + 1 -
                   greatest(to_date('01'||lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                   ),riog.inizio_validita)
                                         >= 15
               and riog.inizio_validita   =
                  (select max(rio2.inizio_validita)
                     from riferimenti_oggetto rio2
                    where rio2.oggetto           = riog.oggetto
                      and rio2.inizio_validita  <= last_day(to_date('01'||
                                                                    lpad(to_char(nMese),2,'0')||
                                                                    lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                                   )
                                                   )
                      and rio2.fine_validita    >= to_date('01'||
                                                           lpad(to_char(nMese),2,'0')||
                                                           lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                                          )
                   and least(last_day(to_date('01'||lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                        )
                         ),rio2.fine_validita) + 1 -
                          greatest(to_date('01'||lpad(to_char(nMese),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'
                                           ),rio2.inizio_validita)
                                                  >= 15
                )
            ;

            sCategoria := nvl(sCategoria,p_categoria);

            if sImm_Storico = 'S' and p_anno < 2012 then
               nMoltiplicatore := 100;
            else
               if sCategoria = p_categoria then
                  nMoltiplicatore := p_moltiplicatore;
               else
                  BEGIN
                     select nvl(molt.moltiplicatore,1)
                       into nMoltiplicatore
                       from moltiplicatori molt
                      where molt.anno                 = p_anno
                        and molt.categoria_catasto    = sCategoria
                          ;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        nMoltiplicatore := 1;
                  END;
               end if;
            end if;
            nValore := round(nRendita * nMoltiplicatore * (100 + nvl(p_rivalutazione,0)) / 100);

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               sCategoria := p_categoria;
               nValore    := p_valore;
         END;
      end if;

      if sAffittato = 'SI' then
         nAliquota            := nvl(nAliquota_Aff_Sp,p_aliquota_affitto);
         nAliquota_1s         := nvl(nAliquota_Aff_Sp_1s,p_aliquota_affitto_1s);
         nAliquota_erar       := nAliquota_Aff_Sp_erar; -- nvl(nAliquota_Aff_Sp_erar,p_aliquota_affitto_erar);
         nAliquota_std        := nAliquota_Aff_Sp_std;
      else
         if sCategoria in ('A01','A02','A03','A04','A05','A06','A07','A08','A09') then
            if nConta_Affitti = 0 then
               nAliquota      := p_aliquota_2_casa;
               nAliquota_1s   := p_aliquota_2_casa_1s;
               nAliquota_erar := p_aliquota_2_casa_erar;
               nAliquota_std  := p_aliquota_2_casa_std;
               nTipo_Aliquota := p_tipo_al_2_casa;
            else
               nAliquota      := p_aliquota_non_affitto;
               nAliquota_1s   := p_aliquota_non_affitto_1s;
               nAliquota_erar := p_aliquota_non_affitto_erar;
               nAliquota_std  := p_aliquota_non_affitto_std;
               nTipo_Aliquota := p_tipo_al_non_affitto;
            end if;
         elsif sCategoria = 'C01' then
            nAliquota         := p_aliquota_c01;
            nAliquota_1s      := p_aliquota_c01_1s;
            nAliquota_erar    := p_aliquota_c01_erar;
            nAliquota_std     := p_aliquota_c01_std;
            nTipo_Aliquota    := p_tipo_al_c01;
         elsif sCategoria in ('D12','D11','D09','D08','D07','D06','D05',
                              'D04','D03','D02','D01') then
            nAliquota         := p_aliquota_d;
            nAliquota_1s      := p_aliquota_d_1s;
            nAliquota_erar    := p_aliquota_d_erar;
            nAliquota_std     := p_aliquota_d_std;
            nTipo_Aliquota    := p_tipo_al_d;
         elsif sCategoria ='D10' then
            nAliquota         := p_aliquota_d10;
            nAliquota_1s      := p_aliquota_d10_1s;
            nAliquota_erar    := p_aliquota_d10_erar;
            nAliquota_std     := p_aliquota_d10_std;
            nTipo_Aliquota    := p_tipo_al_d10;
         else
            nAliquota         := p_aliquota_base;
            nAliquota_1s      := p_aliquota_base_1s;
            nAliquota_erar    := p_aliquota_base_erar;
            nAliquota_std     := p_aliquota_base_std;
            nTipo_Aliquota    := 1;
         end if;
      end if;
      -- (PM/VD - 27/11/2014): Si verifica se l'oggetto e' "pertinenza di"
      -- e se sì, si seleziona la relativa aliquota
      -- SC 09/01/2015: aggiunti gli nvl: se per l'abitazione relativa
      -- alla pertinenza non si era potuto registrare l'aliquota (in quanto
      -- variata in corso d'anno), allora sulla pertinenza lascia
      -- l'aliquota che si è calcolato sopra.
      -- AB e VD 08/06/2015: si utilizza la decode di tipo aliquota di OGIM
      -- per evitare che venga impostata l'aliquota erariale anche per
      -- i tipi aliquota 2.
      --
      BEGIN
        select ogim_rif.aliquota
             , aliq.aliquota_base
             , ogim_rif.aliquota_erariale
             , ogim_rif.aliquota_std
             , ogim_rif.tipo_aliquota
             , aliq.flag_riduzione
             , nvl(aliq.riduzione_imposta,100)
          into nAliquota_rif_ap
             , nAliquota_base_rif_ap
             , nAliquota_erar_rif_ap
             , nAliquota_std_rif_ap
             , nTipo_Aliquota_rif_ap
             , w_flag_riduzione
             , w_riduzione_imp
          from oggetti_imposta ogim_rif
             , oggetti_pratica ogpr
             , aliquote        aliq
         where ogpr.oggetto_pratica = p_oggetto_pratica
           and ogim_rif.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
           and ogim_rif.anno = p_anno
           and ogim_rif.cod_fiscale = p_cod_fiscale
           and nvl(ogim_rif.flag_calcolo,'N') = 'S'
           and aliq.anno = p_anno
           and aliq.tipo_tributo = p_tipo_tributo
           and aliq.tipo_aliquota = ogim_rif.tipo_aliquota
           ;
      EXCEPTION
        when no_data_found then
          nTipo_Aliquota_rif_ap := null;
      END;
      -- (AB - 04/01/2024): Nel caso di Ravvedimento si ricerca per rif_ap anche senza flag_calcolo = 'S'
      --                    perchè sarà sempre null, cosi si prende l'aliquota determinata per l'oggetto
      --                    principale di ravvedimento
      --
      BEGIN
        select ogim_rif.aliquota
             , aliq.aliquota_base
             , ogim_rif.aliquota_erariale
             , ogim_rif.aliquota_std
             , ogim_rif.tipo_aliquota
             , aliq.flag_riduzione
             , nvl(aliq.riduzione_imposta,100)
          into nAliquota_rif_ap
             , nAliquota_base_rif_ap
             , nAliquota_erar_rif_ap
             , nAliquota_std_rif_ap
             , nTipo_Aliquota_rif_ap
             , w_flag_riduzione
             , w_riduzione_imp
          from oggetti_imposta ogim_rif
             , oggetti_pratica ogpr
             , aliquote        aliq
         where ogpr.oggetto_pratica = p_oggetto_pratica
           and ogim_rif.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
           and ogim_rif.anno = p_anno
           and ogim_rif.cod_fiscale = p_cod_fiscale
     --      and nvl(ogim_rif.flag_calcolo,'N') = 'S'   AB 04/01/2024
           and aliq.anno = p_anno
           and aliq.tipo_tributo = p_tipo_tributo
           and aliq.tipo_aliquota = ogim_rif.tipo_aliquota
           ;
      EXCEPTION
        when no_data_found then
          nTipo_Aliquota_rif_ap := null;
      END;
      -- (VD - 20/05/2016): se il tipo_aliquota selezionato per la pertinenza di
      --                    e' nullo, potrebbero esserci delle aliquote in
      --                    oggetti_ogim
      -- (AB - 03/12/2024): aggiunta nvl(oggetto_pratica_rif_ap, oggetto_pratica_rif) per gestire nel caso di ravvedimento
      --                    le situazioni pregresse
      --
      if nTipo_Aliquota_rif_ap is null then
         BEGIN
           select ogog.aliquota
                , aliq.aliquota_base
                , ogog.aliquota_erariale
                , ogog.aliquota_std
                , ogog.tipo_aliquota
                , aliq.flag_riduzione
                , nvl(aliq.riduzione_imposta,100)
             into nAliquota_rif_ap
                , nAliquota_base_rif_ap
                , nAliquota_erar_rif_ap
                , nAliquota_std_rif_ap
                , nTipo_Aliquota_rif_ap
                , w_flag_riduzione
                , w_riduzione_imp
             from oggetti_ogim    ogog
                , oggetti_pratica ogpr
                , aliquote        aliq
            where ogpr.oggetto_pratica = p_oggetto_pratica
              and ogog.oggetto_pratica = nvl(ogpr.oggetto_pratica_rif_ap,ogpr.oggetto_pratica_rif)
              and ogog.anno = p_anno
              and ogog.cod_fiscale = p_cod_fiscale
              -- and ogog.sequenza = (select min(ogog2.sequenza)
              --                        from oggetti_ogim ogog2
              --                       where ogog2.oggetto_pratica = ogpr.oggetto_pratica_rif_ap
              --                         and ogog2.anno = p_anno
              --                         and ogog2.cod_fiscale = p_cod_fiscale
              --                         and ogog2.sequenza > nSequenza)
              --
              -- (VD - 30/07/2018): modificata ricerca riga di OGGETTI_OGIM
              --                    la ricerca per sequenza non va bene,
              --                    perchè la registrazione di oggetti_ogim
              --                    avviene solo se cambia l'aliquota e al
              --                    primo cambio non c'è nessuna riga di
              --                    oggetti_ogim per la pertinenza (quindi
              --                    la variabile nSequenza è nulla).
              --                    Si ricerca invece la riga per periodo
              --                    di competenza, sommando i mesi possesso
              --                    dei periodi precedenti per verificare
              --                    in che periodo ricade il mese che si sta
              --                    trattando.
              --
              and ogog.sequenza = (select max(ogog3.sequenza)
                                     from (select ogog2.oggetto_pratica
                                                , ogog2.sequenza
                                            --    , sum(mesi_possesso) over (partition by cod_fiscale,anno,oggetto_pratica,sequenza order by sequenza
                                            --      range unbounded preceding)
                                                , ogog2.mesi_possesso
                                                , ogog2.da_mese_possesso
                                             from oggetti_ogim ogog2
                                            where ogog2.anno = p_anno
                                              and ogog2.cod_fiscale = p_cod_fiscale) ogog3
                                    where ogog3.oggetto_pratica = nvl(ogpr.oggetto_pratica_rif_ap,ogpr.oggetto_pratica_rif)
                                      and nMese >= ogog3.da_mese_possesso)   --08/01/2024 utilizzato il da_mese_possesso
              and aliq.anno = p_anno
              and aliq.tipo_tributo = p_tipo_tributo
              and aliq.tipo_aliquota = ogog.tipo_aliquota;
         EXCEPTION
           when no_data_found then
             nTipo_Aliquota_rif_ap := null;
         END;
      end if;
      --
      -- (VD - 18/01/2017): determinazione aliquota acconto di pertinenza di
      --                    con lo stesso criterio degli altri casi
      --
      if nTipo_Aliquota_rif_ap is not null then
         if p_anno > 2000 and p_anno < 2012 then
            begin
              select aliquota
                into nAliquota_1s_rif_ap
                from aliquote aliq
               where aliq.tipo_aliquota   = nTipo_Aliquota_rif_ap
                 and aliq.anno            = p_anno - 1
                 and aliq.tipo_tributo    = p_tipo_tributo;
            exception
              when others then
                nAliquota_1s_rif_ap := to_number(null);
            end;
         elsif p_anno >= 2012 then
            begin
              select aliquota_base
                into nAliquota_1s_rif_ap
                from aliquote aliq
               where aliq.tipo_aliquota   = nTipo_Aliquota_rif_ap
                 and aliq.anno            = p_anno
                 and aliq.tipo_tributo    = p_tipo_tributo;
            exception
              when others then
                nAliquota_1s_rif_ap := to_number(null);
            end;
         else
            nAliquota_1s_rif_ap := nAliquota_rif_ap;
         end if;
         nAliquota_1s_rif_ap := nvl(nAliquota_base_rif_ap,nAliquota_1s_rif_ap);
      end if;
      --
      -- Sostituzione dati aliquota con quelli relativi alla pertinenza di
      --
      select decode(nTipo_Aliquota_rif_ap, null, nAliquota, nAliquota_rif_ap)
           , decode(nTipo_Aliquota_rif_ap, null, nAliquota_1s, nAliquota_1s_rif_ap)
           , decode(nTipo_Aliquota_rif_ap, null, nAliquota_erar, nAliquota_erar_rif_ap)
           , decode(nTipo_Aliquota_rif_ap, null, nAliquota_std, nAliquota_std_rif_ap)
           , decode(nTipo_Aliquota_rif_ap, null, nTipo_Aliquota, nTipo_Aliquota_rif_ap)
        into nAliquota
           , nAliquota_1s
           , nAliquota_erar
           , nAliquota_std
           , nTipo_Aliquota
        from dual;

      -- Gestione delle Aliquote Oggetto
      BEGIN
       select alogu.tipo_aliquota
         into nTipo_Aliquota_ogco
        from (
       select alog.tipo_aliquota
         from aliquote_ogco alog
        where alog.cod_fiscale     = p_cod_fiscale
          and alog.oggetto_pratica = p_oggetto_pratica
          and alog.tipo_tributo    = p_tipo_tributo
          and to_date('15'||lpad(to_char(nMese),2,'0')||to_char(p_anno),'ddmmyyyy') between alog.dal and alog.al
       union
       select alog2.tipo_aliquota
         from aliquote_ogco alog2
            , oggetti_pratica ogpr2
        where alog2.cod_fiscale     = p_cod_fiscale
          and alog2.oggetto_pratica = ogpr2.oggetto_pratica_rif_ap
          and alog2.tipo_tributo    = p_tipo_tributo
          and ogpr2.oggetto_pratica = p_oggetto_pratica
          and to_date('15'||lpad(to_char(nMese),2,'0')||to_char(p_anno),'ddmmyyyy') between alog2.dal and alog2.al
             ) alogu
          ;
      EXCEPTION
         WHEN others THEN
             nTipo_Aliquota_ogco := null;
      END;

      if nTipo_Aliquota_ogco is not null then
         --
         -- (VD - 18/04/2018): selezione aliquota acconto in
         --                    variabile corretta (nAliquota_ogco_1s)
         --
         -- (VD - 10/05/2016): aggiunta selezione flag_imposta e
         --                    riduzione imposta per tipo_aliquota
         --
         BEGIN
           select aliq.aliquota
                , nvl(aliq.aliquota_base,aliq.aliquota)
                , aliq.aliquota_erariale
                , aliq.aliquota_std
                , aliq.flag_riduzione
                , nvl(aliq.riduzione_imposta,100)
             into nAliquota_ogco
                --, nAliquota_ogco_base
                , nAliquota_ogco_1s
                , nAliquota_ogco_erar
                , nAliquota_ogco_std
                , w_flag_riduzione
                , w_riduzione_imp
             from aliquote      aliq
            where aliq.tipo_aliquota   = nTipo_Aliquota_ogco
              and aliq.anno            = p_anno
              and aliq.tipo_tributo    = p_tipo_tributo
             ;
         EXCEPTION
           WHEN others THEN
            nAliquota_ogco       := p_aliquota_base;
            nTipo_Aliquota_ogco  := 1;
            nAliquota_ogco_1s    := p_aliquota_base_1s;
            nAliquota_ogco_erar  := p_aliquota_base_erar;
            nAliquota_ogco_std   := p_aliquota_base_std;
         END;
         nTipo_Aliquota := nTipo_Aliquota_ogco;
         nAliquota      := nAliquota_ogco;
         nAliquota_1s   := nAliquota_ogco_1s;
         nAliquota_erar := nAliquota_ogco_erar;
         nAliquota_std  := nAliquota_ogco_std;
         -- Perche' questo pezzo e' commentato?
         -- Quando c'e' Aliquota_OGCO non si usa la riduzione ???
--         if nflag_riduzione = 2 then
--            nflag_riduzione := 1;
--            nmesi_riduzione := nmesi_riduzione + 1;
--         end if;
--         if nflag_riduzione_1s = 2 then
--            nflag_riduzione_1s := 1;
--            nmesi_riduzione_1s := nmesi_riduzione_1s + 1;
--         end if;
      end if;
      --
      -- Gestione Immobili storici dal 2012 in poi
      --
      if nvl(sImm_Storico,'N') = 'S' and p_anno >= 2012 then
         nflag_riduzione := 2;
         nflag_riduzione_1s := 2;
      end if;
      --
      -- (VD - 10/05/2016): se il tipo aliquota selezionato prevede la
      --                    riduzione, si attivano i relativi flag
      --
      if nvl(w_flag_riduzione,'N') = 'S' then
         nflag_riduzione := 2;
         nflag_riduzione_1s := 2;
      end if;
      --
      nAliquota      := F_ALIQUOTA_ALCA(p_anno,nTipo_Aliquota
                                       ,sCategoria,nAliquota
                                       ,p_oggetto_pratica,p_cod_fiscale,p_tipo_tributo);
      --
      -- (VD - 14/12/2016): aggiunto parametro p_aliquota_base = 'S' per
      --                    ottenere l'aliquota base della categoria e
      --                    sostituito p_anno - 1 con p_anno
      --
      nAliquota_1s   := F_ALIQUOTA_ALCA(p_anno,nTipo_Aliquota
                                       ,sCategoria,nAliquota_1s
                                       ,p_oggetto_pratica,p_cod_fiscale
                                       ,p_tipo_tributo,'S');
      --
      -- (VD - 10/05/2016): si applica l'eventuale riduzione imposta alle imposte calcolate
      --
      nImposta              := nValore / 12 * nAliquota / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      nImposta_Dovuta       := nValoreDovuto / 12 * nAliquota / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      nImposta_erar         := nValore / 12 * nAliquota_erar / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      nImposta_erar_dov     := nValoreDovuto / 12 * nAliquota_erar / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      nImposta_std          := nValore / 12 * nAliquota_std / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      nImposta_std_dov      := nValoreDovuto / 12 * nAliquota_std / 1000 / nflag_riduzione * w_riduzione_imp / 100;
      if nMese between nMese_Inizio_1s and nMese_Fine_1s then
         nImposta_1s          := nValore / 12 * nAliquota_1s / 1000 / nflag_riduzione_1s * w_riduzione_imp / 100;
         nImposta_Dovuta_1s   := nValoreDovuto / 12 * nAliquota_1s / 1000 / nflag_riduzione_1s * w_riduzione_imp / 100;
         nImposta_erar_1s     := nValore / 12 * nAliquota_erar / 1000 / nflag_riduzione_1s * w_riduzione_imp / 100;
         nImposta_erar_dov_1s := nValoreDovuto / 12 * nAliquota_erar / 1000 / nflag_riduzione_1s * w_riduzione_imp / 100;
      else
         nImposta_1s           := 0;
         nImposta_Dovuta_1s    := 0;
         nImposta_erar_1s      := 0;
         nImposta_erar_dov_1s  := 0;
      end if;
      -- (VD - 23/10/2020): calcolo imposta a saldo (D.L. 14 agosto 2020)
      if p_tipo_tributo = 'ICI' then
         calcolo_imu_saldo ( p_tipo_tributo
                           , p_anno
                           , nTipo_Aliquota
                           , nvl(nImposta,0)
                           , nvl(nImposta_1s,0)
                           , nvl(nImposta_erar,0)
                           , nvl(nImposta_erar_1s,0)
                           , w_perc_saldo
                           , w_imposta_saldo
                           , w_imposta_saldo_erar
                           , w_note_saldo
                           );
         if w_perc_saldo is not null then
            nImposta      := w_imposta_saldo;
            nImposta_erar := w_imposta_saldo_erar;
            if w_dettaglio_ogim is not null then
               w_dettaglio_ogim := w_dettaglio_ogim||'; ';
            end if;
            w_dettaglio_ogim := w_dettaglio_ogim||w_note_saldo;
         end if;
      end if;
      --
      -- Somma ai totali sequenza gli importi della mensilità in esame
      --
      nTotale               := nTotale              + nImposta;
      nTotale_Dovuto        := nTotale_Dovuto       + nImposta_Dovuta;
      nTotale_1s            := nTotale_1s           + nImposta_1s;
      nTotale_Dovuto_1s     := nTotale_Dovuto_1s    + nImposta_Dovuta_1s;
      nTotale_erar          := nTotale_erar         + nvl(nImposta_erar,0);
      nTotale_erar_1s       := nTotale_erar_1s      + nvl(nImposta_erar_1s,0);
      nTotale_erar_dov      := nTotale_erar_dov     + nvl(nImposta_erar_dov,0);
      nTotale_erar_dov_1s   := nTotale_erar_dov_1s  + nvl(nImposta_erar_dov_1s,0);
      --
      nTotale_std           := nTotale_std          + nvl(nImposta_std,0);
      nTotale_std_dov       := nTotale_std_dov      + nvl(nImposta_std_dov,0);
      --
      if nTipo_Al is null and nConta_Tipo_Aliquote = 0 then
         nTipo_Al     := nTipo_Aliquota;
         nConta_Tipo_Aliquote := nConta_Tipo_Aliquote + 1;
      elsif nTipo_Aliquota <> nTipo_Al then
         nConta_Tipo_Aliquote := nConta_Tipo_Aliquote + 1;
         nTipo_Al     := null;
      end if;

      if nAliq is null and nConta_Aliquote = 0 then
         nAliq        := nAliquota;
         nCOnta_Aliquote := nConta_Aliquote + 1;
      elsif nAliq <> nAliquota then
         nConta_Aliquote := nConta_Aliquote + 1;
         nAliq        := null;
      end if;

      if nAliq_erar is null and nConta_Aliquote_erar = 0 then
         nAliq_erar        := nAliquota_erar;
         nConta_Aliquote_erar := nConta_Aliquote_erar + 1;
      elsif nvl(nAliq_erar,-1) <> nvl(nAliquota_erar,-1) then
         nConta_Aliquote_erar := nConta_Aliquote_erar + 1;
         nAliq_erar        := null;
      end if;

      if nAliq_std is null and nConta_Aliquote_std = 0 then
         nAliq_std            := nAliquota_std;
         nConta_Aliquote_std := nConta_Aliquote_std + 1;
      elsif nvl(nAliq_std,-1) <> nvl(nAliquota_std,-1) then
         nConta_Aliquote_std := nConta_Aliquote_std + 1;
         nAliq_std        := null;
      end if;

      if nTipo_AliquotaPrec <> nTipo_Aliquota
         or nAliquotaPrec <> nAliquota then
         --
         -- Cambio di aliquota, crea una nuova sequenza
         --
         nSequenza := nSequenza + 1;
         --
         -- Proporziona totali sequenza in base a % di possesso e % acconto
         --
         nTotale_prec               := round(nTotale_prec * p_perc_possesso / 100,2);
         nTotale_Dovuto_prec        := round(nTotale_Dovuto_prec * p_perc_possesso / 100,2);
         nTotale_1s_prec            := round(nTotale_1s_prec * p_perc_possesso / 100 * p_perc_acconto / 100,2);
         nTotale_Dovuto_1s_prec     := round(nTotale_Dovuto_1s_prec * p_perc_possesso / 100 * p_perc_acconto / 100,2);
         nTotale_erar_prec          := round(nTotale_erar_prec * p_perc_possesso / 100,2);
         nTotale_erar_1s_prec       := round(nTotale_erar_1s_prec * p_perc_possesso / 100,2);
         nTotale_erar_dov_prec      := round(nTotale_erar_dov_prec * p_perc_possesso / 100,2);
         nTotale_erar_dov_1s_prec   := round(nTotale_erar_dov_1s_prec * p_perc_possesso / 100,2);
         --
         insert into oggetti_ogim
                (cod_fiscale, anno, oggetto_pratica
                ,sequenza, tipo_aliquota, aliquota
                ,aliquota_erariale ,mesi_possesso, mesi_possesso_1sem
                ,da_mese_possesso
                ,aliquota_std,tipo_tributo
                ,imposta,imposta_acconto,imposta_erariale,imposta_erariale_acconto
                ,imposta_dovuta,imposta_dovuta_acconto,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
                ,mesi_riduzione,mesi_esclusione,mesi_aliquota_ridotta
         )
         values (p_cod_fiscale, p_anno, p_oggetto_pratica
                ,nSequenza, nTipo_AliquotaPrec, nAliquotaPrec
                ,nAliquota_erarPrec, nMesiPoss, nMesiPoss1Sem
                ,nMese_inizio
                ,nAliquota_stdPrec,p_tipo_tributo
                ,nTotale_prec,nTotale_1s_prec
                ,nTotale_erar_prec,nTotale_erar_1s_prec
                ,nTotale_Dovuto_prec,nTotale_Dovuto_1s_prec,nTotale_erar_dov_prec,nTotale_erar_dov_1s_prec
                ,nMesiRiduz,nMesiEsclus,nMesiAlRid
         );
         --
         -- Reimposta tutto per nuova sequenza
         --
         nMese_inizio  := nMese_inizio + nMesiPoss;
         nMesiPoss     := 0;
         nMesiPoss1Sem := 0;
         nMesiRiduz    := 0;
         nMesiEsclus   := 0;
         nMesiAlRid    := 0;
         --
         -- Aggiorna i parziali come somma delle sequenze n - 1
         --
         nParziali_prec             := nParziali_prec               + nTotale_prec;
         nParziali_Dovuto_prec      := nParziali_Dovuto_prec        + nTotale_Dovuto_prec;
         nParziali_1s_prec          := nParziali_1s_prec            + nTotale_1s_prec;
         nParziali_Dovuto_1s_prec   := nParziali_Dovuto_1s_prec     + nTotale_Dovuto_1s_prec;
         nParziali_erar_prec        := nParziali_erar_prec          + nTotale_erar_prec;
         nParziali_erar_1s_prec     := nParziali_erar_1s_prec       + nTotale_erar_1s_prec;
         nParziali_erar_dov_prec    := nParziali_erar_dov_prec      + nTotale_erar_dov_prec;
         nParziali_erar_dov_1s_prec := nParziali_erar_dov_1s_prec   + nTotale_erar_dov_1s_prec;
         --
         -- Azzera totali precedenti per prossima sequenza
         --
         nTotale_prec               := 0;
         nTotale_Dovuto_prec        := 0;
         nTotale_1s_prec            := 0;
         nTotale_Dovuto_1s_prec     := 0;
         nTotale_erar_prec          := 0;
         nTotale_erar_1s_prec       := 0;
         nTotale_erar_dov_prec      := 0;
         nTotale_erar_dov_1s_prec   := 0;
         --
         -- (VD - 12/05/2016): Se viene applicata una riduzione per concordato
         --                    o comodato, si memorizzano i riferimenti nel
         --                    campo dettaglio_ogim di oggetti_imposta
         --
         if nvl(w_flag_rid_prec,'N') = 'S' then
            if w_dettaglio_ogim is not null then
               w_dettaglio_ogim := w_dettaglio_ogim||'; ';
            end if;
            w_dettaglio_ogim := w_dettaglio_ogim||'Tipo Aliquota '||to_char(nTipo_AliquotaPrec)||
                      ', Flag riduzione = ''S''';
         end if;
         if w_rid_imp_prec <> 100 then
            if w_dettaglio_ogim is not null then
               w_dettaglio_ogim := w_dettaglio_ogim||'; ';
            end if;
            w_dettaglio_ogim := w_dettaglio_ogim||'Tipo Aliquota '||to_char(nTipo_AliquotaPrec)||
                      ', riduzione al '||to_char(w_rid_imp_prec,'999D99','NLS_NUMERIC_CHARACTERS = '',.''')||'%';
         end if;
      end if;
      --
      -- Somma importi mensilità a totale sequenza
      --
      nTotale_prec               := nTotale_prec                 + nImposta;
      nTotale_Dovuto_prec        := nTotale_Dovuto_prec          + nImposta_Dovuta;
      nTotale_1s_prec            := nTotale_1s_prec              + nImposta_1s;
      nTotale_Dovuto_1s_prec     := nTotale_Dovuto_1s_prec       + nImposta_Dovuta_1s;
      nTotale_erar_prec          := nTotale_erar_prec            + nvl(nImposta_erar,0);
      nTotale_erar_1s_prec       := nTotale_erar_1s_prec         + nvl(nImposta_erar_1s,0);
      nTotale_erar_dov_prec      := nTotale_erar_dov_prec        + nvl(nImposta_erar_dov,0);
      nTotale_erar_dov_1s_prec   := nTotale_erar_dov_1s_prec     + nvl(nImposta_erar_dov_1s,0);
      --
      -- Prepara e reimposta per calcolo prossima mensilità
      --
      nMesiPoss := nMesiPoss + 1;
      if nMese between 1 and 6 then
         nMesiPoss1Sem := nMesiPoss1Sem + 1;
      end if;
      --
      if nflag_riduzione > 1 then
         nMesiRiduz := nMesiRiduz + 1;
      end if;
--    nMesiEsclus := nMesiEsclus + 1;
--    nMesiAlRid := nMesiAlRid + 1;
      --
      nTipo_AliquotaPrec := nTipo_Aliquota;
      nAliquotaPrec      := nAliquota;
      nAliquota_erarPrec := nAliquota_erar;
      nAliquota_stdPrec  := nAliquota_std;
      w_flag_rid_prec    := w_flag_riduzione;
      w_rid_imp_prec     := w_riduzione_imp;
   END LOOP;
   --
   -- Proporziona totale in base a % di possesso e % acconto
   --
   nTotale               := round(nTotale * p_perc_possesso / 100,2);
   nTotale_Dovuto        := round(nTotale_Dovuto * p_perc_possesso / 100,2);
   nTotale_1s            := round(nTotale_1s * p_perc_possesso / 100 * p_perc_acconto / 100,2);
   nTotale_Dovuto_1s     := round(nTotale_Dovuto_1s * p_perc_possesso / 100 * p_perc_acconto / 100,2);
   nTotale_erar          := round(nTotale_erar * p_perc_possesso / 100,2);
   nTotale_erar_1s       := round(nTotale_erar_1s * p_perc_possesso / 100,2);
   nTotale_erar_dov      := round(nTotale_erar_dov * p_perc_possesso / 100,2);
   nTotale_erar_dov_1s   := round(nTotale_erar_dov_1s * p_perc_possesso / 100,2);
   --
   -- Se almeno una sequenza ne crea un'altra di chiusura annualità
   --
   if nSequenza > 0 then
      --
      -- Determina importi ultima sequenza con la differenza tra totale finale ed somma parziali precedenti sequenze
      --
      nTotale_prec               := nTotale                 - nParziali_prec;
      nTotale_Dovuto_prec        := nTotale_Dovuto          - nParziali_Dovuto_prec;
      nTotale_1s_prec            := nTotale_1s              - nParziali_1s_prec;
      nTotale_Dovuto_1s_prec     := nTotale_Dovuto_1s       - nParziali_Dovuto_1s_prec;
      nTotale_erar_prec          := nTotale_erar            - nParziali_erar_prec;
      nTotale_erar_1s_prec       := nTotale_erar_1s         - nParziali_erar_1s_prec;
      nTotale_erar_dov_prec      := nTotale_erar_dov        - nParziali_erar_dov_prec;
      nTotale_erar_dov_1s_prec   := nTotale_erar_dov_1s     - nParziali_erar_dov_1s_prec;
      --
      nSequenza := nSequenza + 1;
      --
      insert into oggetti_ogim
             (cod_fiscale, anno, oggetto_pratica
             ,sequenza, tipo_aliquota, aliquota
             ,aliquota_erariale, mesi_possesso, mesi_possesso_1sem
             ,da_mese_possesso
             ,aliquota_std,tipo_tributo
             ,imposta,imposta_acconto,imposta_erariale,imposta_erariale_acconto
             ,imposta_dovuta,imposta_dovuta_acconto,imposta_erariale_dovuta,imposta_erariale_dovuta_acc
             ,mesi_riduzione,mesi_esclusione,mesi_aliquota_ridotta
      )
      values (p_cod_fiscale, p_anno, p_oggetto_pratica
             ,nSequenza, nTipo_AliquotaPrec, nAliquotaPrec
             ,nAliquota_erarPrec, nMesiPoss, nMesiPoss1Sem
             ,nMese_inizio
             ,nAliquota_stdPrec,p_tipo_tributo
             ,nTotale_prec,nTotale_1s_prec,nTotale_erar_prec,nTotale_erar_1s_prec
             ,nTotale_Dovuto_prec,nTotale_Dovuto_1s_prec,nTotale_erar_dov_prec,nTotale_erar_dov_1s_prec
             ,nMesiRiduz,nMesiEsclus,nMesiAlRid
      );
   end if;
   --
   -- (VD - 12/05/2016): Se viene applicata una riduzione per concordato
   --                    o comodato, si memorizzano i riferimenti nel
   --                    campo dettaglio_ogim di oggetti_imposta
   --
   if nvl(w_flag_rid_prec,'N') = 'S' then
      if w_dettaglio_ogim is not null then
         w_dettaglio_ogim := w_dettaglio_ogim||'; ';
      end if;
      w_dettaglio_ogim := w_dettaglio_ogim||'Tipo Aliquota '||to_char(nTipo_AliquotaPrec)||
                ', Flag riduzione = ''S''';
   end if;
   if w_rid_imp_prec <> 100 then
      if w_dettaglio_ogim is not null then
         w_dettaglio_ogim := w_dettaglio_ogim||'; ';
      end if;
      w_dettaglio_ogim := w_dettaglio_ogim||'Tipo Aliquota '||to_char(nTipo_AliquotaPrec)||
                ', riduzione al '||to_char(w_rid_imp_prec,'999D99','NLS_NUMERIC_CHARACTERS = '',.''')||'%';
   end if;

   if nTipo_Al is null then
      nAliq := null;
   elsif
      nAliq is null then
      nTipo_Al := null;
   end if;
   --
   -- Predispone parametri in uscita
   --
   p_imposta             := nTotale;
   p_imposta_dovuta      := nTotale_Dovuto;
   p_imposta_1s          := nTotale_1s;
   p_imposta_dovuta_1s   := nTotale_Dovuto_1s;
   p_imposta_erar        := nTotale_erar;
   p_imposta_erar_1s     := nTotale_erar_1s;
   p_imposta_erar_dov    := nTotale_erar_dov;
   p_imposta_erar_dov_1s := nTotale_erar_dov_1s;
   p_tipo_al             := nTipo_Al;
   p_aliquota            := nAliq;
   p_aliquota_erar       := nAliq_erar;
   --
   if nTotale_std = 0 then
      p_imposta_std        := null;
   else
      p_imposta_std        := nTotale_std;
   end if;

   if nTotale_std_dov = 0 then
      p_imposta_dovuta_std := null;
   else
      p_imposta_dovuta_std := nTotale_std_dov;
   end if;

   p_al_std             := nAliq_std;
   p_dettaglio_ogim     := w_dettaglio_ogim;
END;
/* End Procedure: DETERMINA_IMPOSTA_OGGETTO */
/
