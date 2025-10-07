--liquibase formatted sql 
--changeset abrandolini:20250326_152423_controllo_anomalie_ici stripComments:false runOnChange:true 
 
create or replace procedure CONTROLLO_ANOMALIE_ICI
(a_anno      IN   number,
 da_anomalia   IN   number,
 a_anomalia   IN    number,
 a_scarto   IN    number,
 a_rigenera_flag_ok IN varchar2)
IS
sql_errm   varchar2(2000);
w_controllo   varchar2(1);
w_errore        varchar2(200);
errore          exception;
nConta          number;
i               number;
w_mese_inizio   number;
w_mese_fine     number;
w_mesi          number;
w_stringa       varchar2(18);
--
-- pl/sql tables e relativi indici.
--
type t_perc_t         is table of number index by binary_integer;
t_perc                t_perc_t;
bind                  binary_integer;
CURSOR sel_anan (w_tipo_anomalia number) IS
       select 'x'
    from anomalie_anno
   where anno      = a_anno
     and tipo_anomalia     = w_tipo_anomalia
       ;
CURSOR sel_anic (w_tipo_anomalia number) IS
       select 'x'
    from anomalie_ici
   where anno      = a_anno
     and tipo_anomalia     = w_tipo_anomalia
       ;
--
-- Immobili con Dati Catastali Nulli.
--
CURSOR sel_anic_1 IS
       select ogge.oggetto
         from oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
       pratiche_tributo prtr
        where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogge.sezione             is null
          and ogge.foglio              is null
          and ogge.numero              is null
          and ogge.subalterno          is null
          and ogge.zona                is null
          and ogge.partita             is null
          and ogge.progr_partita       is null
          and ogge.protocollo_catasto  is null
          and ogge.anno_catasto        is null
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0       = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       ;
--
-- Immobili con uguale protocollo e anno catasto.
--
CURSOR sel_anic_2 IS
       select ogge.oggetto
         from oggetti_tributo ogtr1,
         oggetti ogge1,
         oggetti_pratica ogpr1,
         oggetti_contribuente ogco1,
       pratiche_tributo prtr1,
         oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
       pratiche_tributo prtr
        where ogtr1.tipo_tributo   = 'ICI'
     and ogtr1.tipo_oggetto   = nvl(ogpr1.tipo_oggetto,ogge1.tipo_oggetto)
          and ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogco1.anno + 0      = ogco.anno
     and ogco1.oggetto_pratica   = ogpr1.oggetto_pratica
    and prtr1.pratica             = ogpr1.pratica
     and prtr1.tipo_tributo||''    = 'ICI'
     and prtr1.tipo_pratica   = 'D'
     and ogpr1.oggetto      = ogge1.oggetto
     and ogge1.rowid          != ogge.rowid
     and ogge1.anno_catasto   = ogge.anno_catasto
     and ogge1.protocollo_catasto   = ogge.protocollo_catasto
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       ;
--
-- Immobili non posseduti al 100.
--
CURSOR sel_anic_3 IS
       select ogge.oggetto
         from oggetti_tributo ogtr,
              oggetti ogge,
              oggetti_pratica ogpr,
              oggetti_contribuente ogco,
           pratiche_tributo prtr
        where ogtr.tipo_tributo         = 'ICI'
          and ogtr.tipo_oggetto         = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
          and ogge.oggetto              = ogpr.oggetto
          and ogpr.oggetto_pratica      = ogco.oggetto_pratica
         and prtr.pratica             = ogpr.pratica
          and prtr.tipo_tributo||''    = 'ICI'
          and ogco.flag_esclusione     is null
          and ogco.anno + 0             = a_anno
          and prtr.tipo_pratica   = 'D'
        group by ogge.oggetto
       ;
CURSOR sel_perc_poss (w_oggetto number) IS
       select ogco1.perc_possesso perc_possesso
             ,ogco1.cod_fiscale cod_fiscale
             ,ogco1.oggetto_pratica
         from pratiche_tributo prtr1,
              oggetti_contribuente ogco1,
              oggetti_pratica ogpr1
     where (ogco1.cod_fiscale,ogco1.anno||decode(ogco1.anno, a_anno,'S',ogco1.flag_possesso)) in
              (select ogco2.cod_fiscale,
                      max(ogco2.anno||'S')
                 from pratiche_tributo prtr2,
                      oggetti_contribuente ogco2,
                      oggetti_pratica ogpr2
                where prtr2.anno               <= a_anno
                  and prtr2.tipo_pratica        = 'D'
                  and prtr2.pratica             = ogpr2.pratica
                  and ogco2.oggetto_pratica     = ogpr2.oggetto_pratica
                  and ogpr2.oggetto             = ogpr1.oggetto
                  and prtr2.tipo_tributo||''    = 'ICI'
              and prtr2.tipo_pratica   = 'D'
                group by ogco2.cod_fiscale)
          and prtr1.tipo_pratica        = 'D'
          and prtr1.pratica             = ogpr1.pratica
          and prtr1.tipo_tributo||''    = 'ICI'
            and prtr1.tipo_pratica   = 'D'
          and ogco1.oggetto_pratica     = ogpr1.oggetto_pratica
          and decode(ogco1.anno, a_anno,'S',ogco1.flag_possesso)       = 'S'
          and ogpr1.oggetto      = w_oggetto
       ;
--
-- Individui piu volte proprietari dello stesso immobile.
--
CURSOR sel_anic_4 IS
  select ogge.oggetto,ogco.cod_fiscale
    from oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
         oggetti_contribuente ogco,
       pratiche_tributo prtr
   where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogge.oggetto      = ogpr.oggetto
     and exists (select 'x'
         from oggetti_pratica ogpr1,
                   oggetti_contribuente ogco1,
              pratiche_tributo prtr1
             where ogpr1.rowid     != ogpr.rowid
            and ogpr1.oggetto      = ogpr.oggetto
          and ogpr1.oggetto_pratica = ogco1.oggetto_pratica
          and ogco1.cod_fiscale      = ogco.cod_fiscale
          and ogco1.anno + 0      = ogco.anno
          and prtr1.pratica = ogpr1.pratica
          and prtr1.tipo_tributo||'' = 'ICI'
          and prtr1.tipo_pratica   = 'D'
          and ogco1.flag_possesso = 'S'
          )
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0       = a_anno
     and prtr.tipo_pratica   = 'D'
     and ogco.flag_possesso = 'S'
   group by ogge.oggetto,ogco.cod_fiscale
       ;
--
-- Immobili con indirizzo non codificato.
--
CURSOR sel_anic_5 IS
   select ogge.oggetto
     from oggetti_tributo ogtr,
          oggetti ogge,
          oggetti_pratica ogpr,
          pratiche_tributo prtr
         where ogtr.tipo_tributo   = 'ICI'
      and ogtr.tipo_oggetto   = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
      and ogge.cod_via            is null
      and ogge.oggetto      = ogpr.oggetto
      and ogpr.pratica      = prtr.pratica
      and prtr.tipo_tributo    = 'ICI'
           and prtr.tipo_pratica   = 'D'
      and prtr.anno      = a_anno
      and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       ;
--
-- Immobili dichiarati con rendita molto elevata.
--
CURSOR sel_anic_6 IS
       select ogge.oggetto
         from moltiplicatori molt,
         oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco,
         dati_generali dage
        where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
          and ((nvl(ogpr.valore / nvl(molt.moltiplicatore,1),0) >= decode(dage.fase_euro,1,10000000,5164.56899) and
           ogpr.categoria_catasto not in ('A04','A05','A06','C06'))
          or
               (nvl(ogpr.valore / nvl(molt.moltiplicatore,1),0) >= decode(dage.fase_euro,1,6,1000000,516.45690) and
                ogpr.categoria_catasto in ('A04','A05','A06','C06')))
     and molt.anno             = a_anno
     and molt.categoria_catasto   = 'T'
     and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = 1
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       union
       select ogge.oggetto
         from moltiplicatori molt,
         oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco,
         dati_generali dage
        where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
          and ((nvl(ogpr.valore / nvl(molt.moltiplicatore,1),0) >= decode(dage.fase_euro,1,10000000,5164.56899) and
           ogpr.categoria_catasto not in ('A04','A05','A06','C06'))
          or
               (nvl(ogpr.valore / nvl(molt.moltiplicatore,1),0) >= decode(dage.fase_euro,1,1000000,516.45690) and
                ogpr.categoria_catasto in ('A04','A05','A06','C06')))
     and molt.anno          (+)   = a_anno
     and molt.categoria_catasto(+)   = ogpr.categoria_catasto
     and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) != 1
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       ;
--
-- Immobili dichiarati con Tipologie diverse.
--
CURSOR sel_anic_7 IS
 SELECT OGGE.OGGETTO
   FROM OGGETTI_CONTRIBUENTE OGCO,
        OGGETTI_PRATICA      OGPR,
        OGGETTI              OGGE,
        PRATICHE_TRIBUTO     PRTR
  WHERE OGCO.OGGETTO_PRATICA = OGPR.OGGETTO_PRATICA
    AND OGPR.OGGETTO = OGGE.OGGETTO
    AND OGPR.PRATICA = PRTR.PRATICA
    AND OGCO.TIPO_RAPPORTO IN ('D', 'C')
    AND PRTR.TIPO_PRATICA = 'D'
    AND PRTR.TIPO_TRIBUTO = 'ICI'
    AND (OGCO.ANNO = A_ANNO OR
        (OGCO.ANNO < A_ANNO AND OGCO.FLAG_POSSESSO = 'S' AND NOT EXISTS
         (SELECT OGCO_.PERC_POSSESSO AS Y0_
             FROM OGGETTI_CONTRIBUENTE OGCO_,
                  OGGETTI_PRATICA  OGPR1X1_,
                  PRATICHE_TRIBUTO     PRTR1X2_
            WHERE OGCO_.OGGETTO_PRATICA = OGPR1X1_.OGGETTO_PRATICA
              AND OGPR1X1_.PRATICA = PRTR1X2_.PRATICA
              AND PRTR1X2_.ANNO <= A_ANNO
              AND PRTR1X2_.ANNO > OGCO.ANNO
              AND OGPR1X1_.OGGETTO = OGPR.OGGETTO
              AND OGCO_.COD_FISCALE = OGCO.COD_FISCALE
              AND PRTR1X2_.TIPO_TRIBUTO = 'ICI'
              AND PRTR1X2_.TIPO_PRATICA = 'D')))
    AND OGGE.TIPO_OGGETTO IN (1, 2, 3, 4, 55)
    AND OGGE.TIPO_OGGETTO <> OGPR.TIPO_OGGETTO
  GROUP BY OGGE.OGGETTO
       ;
--
-- Immobili dichiarati con rendite diverse.
--
CURSOR sel_anic_8 IS
       select ogge.oggetto
         from oggetti_tributo ogtr,
              oggetti ogge,
              oggetti_pratica ogpr,
            pratiche_tributo prtr,
              oggetti_contribuente ogco
        where ogtr.tipo_tributo      = 'ICI'
       and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogge.oggetto      = ogpr.oggetto
     and exists (select 'x'
                        from oggetti_contribuente ogco1,
              oggetti_pratica ogpr1,
              pratiche_tributo prtr1
                       where ogco1.anno + 0       = ogco.anno
          and prtr1.pratica = ogpr1.pratica
          and prtr1.tipo_tributo||'' = 'ICI'
          and prtr1.tipo_pratica   = 'D'
          and ogco1.oggetto_pratica  = ogpr1.oggetto_pratica
          and ogpr1.valore   not between ogpr.valore - a_scarto
                                     and ogpr.valore + a_scarto
                         and ogpr1.oggetto        = ogpr.oggetto)
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto
       ;
--
-- Immobili con dati castali uguali e rendite diverse.
--
CURSOR sel_anic_9 IS
       select distinct
              ogge.oggetto,
              ogge.categoria_catasto,
              ogge.sezione,
              ogge.foglio,
              ogge.numero,
              ogge.subalterno,
              ogge.zona,
              ogge.protocollo_catasto,
              ogge.anno_catasto
    from oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco
   where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and (ogge.sezione             is not null or
          ogge.foglio              is not null or
          ogge.numero              is not null or
          ogge.subalterno          is not null or
          ogge.zona                is not null or
          ogge.protocollo_catasto  is not null or
          ogge.anno_catasto        is not null)
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
;
--
-- Mesi possesso, riduzione, esclusione, al ridotta incoerenti.
--
CURSOR sel_anic_10 IS
       select ogge.oggetto,ogco.cod_fiscale
    from oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco,
         oggetti_tributo ogtr
   where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
          and (nvl(ogco.mesi_possesso,12) <
                  (nvl(ogco.mesi_riduzione,0) + nvl(ogco.mesi_esclusione,0))
               or
               nvl(ogco.mesi_possesso,12) <
                   nvl(ogco.mesi_aliquota_ridotta,0))
     and ogco.anno + 0      = a_anno
     and prtr.tipo_pratica   = 'D'
   group by ogge.oggetto,ogco.cod_fiscale
       ;
--
-- Tipo oggetto e indicazione di abitazione principale incoerenti.
--
CURSOR sel_anic_11 IS
       select ogge.oggetto,ogco.cod_fiscale
    from oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco,
         oggetti_tributo ogtr
   where ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
        and ogco.anno + 0      = a_anno
          and (ogco.flag_ab_principale is not null
           and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) not in (3,4,55))
        and prtr.tipo_pratica   = 'D'
      group by ogge.oggetto,ogco.cod_fiscale
       ;
--
-- Oggetti con stessi estremi catastali.
--
CURSOR sel_anic_12 IS
       select ogge.oggetto
         from oggetti_tributo ogtr1,
         oggetti ogge1,
         oggetti_pratica ogpr1,
       pratiche_tributo prtr1,
         oggetti_contribuente ogco1,
         oggetti_tributo ogtr,
         oggetti ogge,
         oggetti_pratica ogpr,
       pratiche_tributo prtr,
         oggetti_contribuente ogco
        where ogtr1.tipo_tributo   = 'ICI'
     and ogtr1.tipo_oggetto   = nvl(ogpr1.tipo_oggetto,ogge1.tipo_oggetto)
          and ogtr.tipo_tributo      = 'ICI'
     and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
     and ogco1.anno + 0      = ogco.anno
     and ogco1.oggetto_pratica   = ogpr1.oggetto_pratica
    and prtr1.pratica             = ogpr1.pratica
     and prtr1.tipo_tributo||''    = 'ICI'
     and prtr1.tipo_pratica   = 'D'
     and ogpr1.oggetto      = ogge1.oggetto
     and ogge1.rowid          != ogge.rowid
     and ogge1.estremi_catasto   = ogge.estremi_catasto
     and ltrim(rtrim(ogge.estremi_catasto)) is not null
     and nvl(ogge1.sezione,' ')   = nvl(ogge.sezione,' ')
     and ogge.oggetto      = ogpr.oggetto
     and ogpr.oggetto_pratica   = ogco.oggetto_pratica
    and prtr.pratica             = ogpr.pratica
     and prtr.tipo_tributo||''    = 'ICI'
     and prtr.tipo_pratica   = 'D'
     and ogco.anno + 0      = a_anno
   group by ogge.oggetto
       ;
--
-- Oggetti con estremi catastali parziali.
--
CURSOR sel_anic_13 IS
       select ogge.oggetto
         from oggetti_tributo ogtr,
           oggetti ogge,
           oggetti_pratica ogpr,
         pratiche_tributo prtr,
           oggetti_contribuente ogco
        where ogtr.tipo_tributo      = 'ICI'
       and ogtr.tipo_oggetto      = nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
       and ltrim(ogge.estremi_catasto)   is not null
          and (ogge.foglio              is null or
               ogge.numero              is null or
                 ogge.subalterno          is null)
       and ogge.oggetto      = ogpr.oggetto
       and ogpr.oggetto_pratica   = ogco.oggetto_pratica
      and prtr.pratica             = ogpr.pratica
       and prtr.tipo_tributo||''    = 'ICI'
       and ogco.anno + 0       = a_anno
     and prtr.tipo_pratica   = 'D'
     group by ogge.oggetto
       ;
--
-- Immobili non posseduti per 12 mesi.
--
-- Cursor sel_anic_14 IS
-- Per questa anomalia si sfruttano i cursori della anomlia 3
--Contiene gli oggetti che hanno 2 righe in anomalie_ici, una con flag_ok valorizzato e l'altra no
CURSOR sel_flag_ok(w_tipo_anomalia number) IS
   select anomalia anom
     from anomalie_ici anic
    where anic.anno = a_anno
      and anic.tipo_anomalia = w_tipo_anomalia
      and anic.flag_ok is null
      and exists (select *
                    from anomalie_ici anic2
                       where anic.oggetto = anic2.oggetto
                     and anic2.anno = a_anno
                        and anic2.tipo_anomalia = w_tipo_anomalia
                     and anic2.flag_ok is not null)
                     ;
BEGIN
  FOR i IN da_anomalia..a_anomalia LOOP
      OPEN  sel_anan (i);
      FETCH sel_anan INTO w_controllo;
      IF sel_anan%NOTFOUND THEN
    BEGIN
      insert into anomalie_anno
        (tipo_anomalia,anno,data_elaborazione,scarto)
      values (i,a_anno,trunc(sysdate),a_scarto)
      ;
    EXCEPTION
      WHEN others THEN
              w_errore := 'Errore in inserimento Anomalie Anno';
           RAISE ERRORE;
    END;
      ELSE
    BEGIN
      update anomalie_anno
         set data_elaborazione   = trunc(sysdate),
        scarto      = a_scarto
       where anno         = a_anno
         and tipo_anomalia      = i
      ;
    EXCEPTION
      WHEN others THEN
           w_errore := 'Errore in aggiornamento Anomalie Anno';
           RAISE ERRORE;
         END;
      END IF;
      CLOSE sel_anan;
      OPEN  sel_anic (i);
      FETCH sel_anic INTO w_controllo;
      IF sel_anic%FOUND THEN
    BEGIN
      delete anomalie_ici
       where anno      = a_anno
         and tipo_anomalia = i
         and flag_ok is null
      ;
    EXCEPTION
      WHEN others THEN
              w_errore := 'Errore in cancellazione Anomalie Ici';
           RAISE ERRORE;
    END;
      END IF;
      CLOSE sel_anic;
      IF i = 1 THEN
    FOR rec_anic_1 IN sel_anic_1 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,1,rec_anic_1.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
               sql_errm := substr(SQLERRM,1,100);
          w_errore := 'Errore in inserimento Anomalie Ici (1)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 2 THEN
    FOR rec_anic_2 IN sel_anic_2 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,2,rec_anic_2.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (2)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 3 THEN
    FOR rec_anic_3 IN sel_anic_3 LOOP
--
-- Si pone a null ogni elemento della tabella delle percentuali di possesso
-- di ogni mese dell`anno.
--
        FOR bInd in 1 .. 12
        LOOP
           t_perc(bInd) := null;
        END LOOP;
--
-- Si selezionano tutti i contribuenti sull`oggetto (comproprietari) per l`anno.
--
           FOR rec_perc_poss IN sel_perc_poss (rec_anic_3.oggetto) LOOP
--
-- F_DATO_RIOG col parametro PT restituisce una stringa composta da:
-- Numero di Mesi di Possesso (caratteri 1 e 2)
-- Data di Inizio Possesso (caratteri 3 e 4 = giorno, caratteri 5 e 6 = mese, caratteri 7,8,9 e 10 = anno)
-- Data di Fine Possesso (caratteri 11 e 12 = giorno, caratteri 13 e 14 = mese, caratteri 15,16,17 e 18 = anno)
-- Se il numero dei mesi e` 0 le date contengono il valore 00000000
--
              w_stringa := F_DATO_RIOG(rec_perc_poss.cod_fiscale,rec_perc_poss.oggetto_pratica,a_anno,'PT');
              w_mese_inizio := to_number(substr(w_stringa,5,2));
              w_mese_fine := to_number(substr(w_stringa,13,2));
              w_mesi := to_number(substr(w_stringa,1,2));
              if w_mesi > 0 then
--
-- Se c`e` possesso, per ogni mese del periodo si incrementa la tabella della percentuale.
--
                 FOR bInd in w_mese_inizio .. w_mese_fine
                 LOOP
                    t_perc(bInd) := nvl(t_perc(bInd),0) + nvl(rec_perc_poss.perc_possesso,0);
                 END LOOP;
              end if;
           END LOOP;
--
-- Si analizza la tabella delle percentuali mese per mese scartando gli elementi nulli
-- che non sono stati interessati da nessun periodo di possesso (caso diverso da 0%).
--
           FOR bInd in 1 .. 12
           LOOP
              IF t_perc(bInd) is not null then
--
-- Appena si trova un mese con percentuale fuori dalla tolleranza indicata dagli scarti,
-- si registra l`anomalia e si interrompe l`analisi della tabella dei possessi.
--
                 IF t_perc(bInd) not between (100 - a_scarto) and (100 + a_scarto) then
                    BEGIN
                      insert into anomalie_ici
                        (anno,tipo_anomalia,oggetto)
                         values (a_anno,3,rec_anic_3.oggetto)
                      ;
                    EXCEPTION
                      WHEN others THEN
                      w_errore := 'Errore in inserimento Anomalie Ici (3)';
                           RAISE ERRORE;
                    END;
                    exit;
                 END IF;
              END IF;
          END LOOP;
    END LOOP;
      END IF;
      IF i = 4 THEN
    FOR rec_anic_4 IN sel_anic_4 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,cod_fiscale,oggetto)
          values (a_anno,4,rec_anic_4.cod_fiscale,rec_anic_4.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (4)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 5 THEN
    FOR rec_anic_5 IN sel_anic_5 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,5,rec_anic_5.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (5)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 6 THEN
    FOR rec_anic_6 IN sel_anic_6 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,6,rec_anic_6.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (6)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 7 THEN
    FOR rec_anic_7 IN sel_anic_7 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,7,rec_anic_7.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (7)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 8 THEN
    FOR rec_anic_8 IN sel_anic_8 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,8,rec_anic_8.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (8)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 9 THEN
    FOR rec_anic_9 IN sel_anic_9 LOOP
        select count(*)
          into nConta
          from oggetti_tributo                      ogtr,
               oggetti                              ogge,
               pratiche_tributo                     prtr,
               oggetti_pratica                      ogpr,
               oggetti_contribuente                 ogco
         where ogtr.tipo_tributo                       = 'ICI'
           and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = ogtr.tipo_oggetto+0
           and ogpr.oggetto_pratica+0                  = ogco.oggetto_pratica
           and ogge.oggetto+0                          = ogpr.oggetto
           and prtr.pratica                            = ogpr.pratica
           and prtr.tipo_tributo||''                   = 'ICI'
           and prtr.tipo_pratica                = 'D'
           and ogco.anno+0                             = a_anno
           and nvl(rec_anic_9.categoria_catasto,' ')  != nvl(ogpr.categoria_catasto
                                                            ,nvl(ogge.categoria_catasto,' ')
                                                            )
           and nvl(rec_anic_9.sezione,' ')             = nvl(ogge.sezione,' ')
           and nvl(rec_anic_9.foglio,' ')              = nvl(ogge.foglio,' ')
           and nvl(rec_anic_9.numero,' ')              = nvl(ogge.numero,' ')
           and nvl(rec_anic_9.subalterno,' ')          = nvl(ogge.subalterno,' ')
           and nvl(rec_anic_9.zona,' ')                = nvl(ogge.zona,' ')
           and nvl(rec_anic_9.protocollo_catasto,' ')  = nvl(ogge.protocollo_catasto,' ')
           and nvl(rec_anic_9.anno_catasto,0)          = nvl(ogge.anno_catasto,0)
           and ogge.oggetto                            = rec_anic_9.oggetto
        ;
        IF nConta > 0 then
          BEGIN
            insert into anomalie_ici
              (anno,tipo_anomalia,oggetto)
            values (a_anno,9,rec_anic_9.oggetto)
            ;
          EXCEPTION
            WHEN others THEN
            w_errore := 'Errore in inserimento Anomalie Ici (9)';
                 RAISE ERRORE;
          END;
        END IF;
    END LOOP;
      END IF;
      IF i = 10 THEN
    FOR rec_anic_10 IN sel_anic_10 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,cod_fiscale,oggetto)
          values (a_anno,10,rec_anic_10.cod_fiscale,rec_anic_10.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (10)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
   IF i = 11 THEN
    FOR rec_anic_11 IN sel_anic_11 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,cod_fiscale,oggetto)
          values (a_anno,11,rec_anic_11.cod_fiscale,rec_anic_11.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (11)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 12 THEN
    FOR rec_anic_12 IN sel_anic_12 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,12,rec_anic_12.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (12)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 13 THEN
    FOR rec_anic_13 IN sel_anic_13 LOOP
        BEGIN
          insert into anomalie_ici
            (anno,tipo_anomalia,oggetto)
          values (a_anno,13,rec_anic_13.oggetto)
          ;
        EXCEPTION
          WHEN others THEN
          w_errore := 'Errore in inserimento Anomalie Ici (13)';
               RAISE ERRORE;
        END;
    END LOOP;
      END IF;
      IF i = 14 THEN
    FOR rec_anic_3 IN sel_anic_3 LOOP
--
-- Si pone a null ogni elemento della tabella delle percentuali di possesso
-- di ogni mese dell`anno.
--
        FOR bInd in 1 .. 12
        LOOP
           t_perc(bInd) := null;
        END LOOP;
--
-- Si selezionano tutti i contribuenti sull`oggetto (comproprietari) per l`anno.
--
           FOR rec_perc_poss IN sel_perc_poss (rec_anic_3.oggetto) LOOP
--
-- F_DATO_RIOG col parametro PT restituisce una stringa composta da:
-- Numero di Mesi di Possesso (caratteri 1 e 2)
-- Data di Inizio Possesso (caratteri 3 e 4 = giorno, caratteri 5 e 6 = mese, caratteri 7,8,9 e 10 = anno)
-- Data di Fine Possesso (caratteri 11 e 12 = giorno, caratteri 13 e 14 = mese, caratteri 15,16,17 e 18 = anno)
-- Se il numero dei mesi e` 0 le date contengono il valore 00000000
--
              w_stringa := F_DATO_RIOG(rec_perc_poss.cod_fiscale,rec_perc_poss.oggetto_pratica,a_anno,'PT');
              w_mese_inizio := to_number(substr(w_stringa,5,2));
              w_mese_fine := to_number(substr(w_stringa,13,2));
              w_mesi := to_number(substr(w_stringa,1,2));
              if w_mesi > 0 then
--
-- Se c`e` possesso, per ogni mese del periodo si incrementa la tabella della percentuale.
--
                 FOR bInd in w_mese_inizio .. w_mese_fine
                 LOOP
                    t_perc(bInd) := nvl(t_perc(bInd),0) + nvl(rec_perc_poss.perc_possesso,0);
                 END LOOP;
              end if;
           END LOOP;
--
-- Si analizza la tabella delle percentuali mese per mese considerando gli elementi nulli
-- che non sono stati interessati da nessun periodo di possesso trattandoli come percentuale 0.
--
           FOR bInd in 1 .. 12
           LOOP
--
-- Appena si trova un mese con percentuale fuori dalla tolleranza indicata dagli scarti,
-- si registra l`anomalia e si interrompe l`analisi della tabella dei possessi.
--
                 IF nvl(t_perc(bInd),0) not between (100 - a_scarto) and (100 + a_scarto) then
                    BEGIN
                      insert into anomalie_ici
                        (anno,tipo_anomalia,oggetto)
                         values (a_anno,14,rec_anic_3.oggetto)
                      ;
                    EXCEPTION
                      WHEN others THEN
                      w_errore := 'Errore in inserimento Anomalie Ici (14)';
                           RAISE ERRORE;
                    END;
                    exit;
                 END IF;
          END LOOP;
    END LOOP;
      END IF;
  --Gestisce le rigenerazione totale
  IF a_rigenera_flag_ok != 'S' THEN
  --vanno rigenerate tutte le anomalie, anche quelle con flag_ok valorizzato
     FOR rec_flag_ok IN sel_flag_ok(i) LOOP
        delete anomalie_ici
         where anomalia = rec_flag_ok.anom
         ;
     END LOOP;
   END IF;
  END LOOP;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
END;
/* End Procedure: CONTROLLO_ANOMALIE_ICI */
/

