--liquibase formatted sql 
--changeset abrandolini:20250326_152423_trasmissione_cosap_mav stripComments:false runOnChange:true 
 
create or replace procedure TRASMISSIONE_COSAP_MAV
(
  a_anno            IN     number
, a_commissione     IN     number
, a_tot_importo     IN out number
, a_disposizioni    IN out number
, a_tot_record      IN out number
, a_tributo         IN     number
)
IS
w_data_elaborazione     number:=0;
w_numero_ord            varchar2(15);
w_numero                number:=0;
w_disposizioni          number:=0;
w_tot_importo           number:=0;
w_tot_record            number:=0;
w_numero_14             number;
w_pro_cliente           number;
w_com_cliente           number;
w_istat                 varchar2(6);
w_belfiore              varchar2(4);
w_conta_ogim            number;
w_conta_raim            number;
w_iva                   number;
w_importo               number;
w_tipo_trattam          number;
w_progressivo           number := 0;
w_supporto              varchar2(20);
w_rata                  number;
w_importo_contribuente  number;
w_rata_min              number;
w_rata_max              number;
w_denominazione_comune  varchar2(60);
w_indirizzo_ufficio_com varchar2(200);
w_descrizione_titr      varchar2(100);
w_flag_canone           varchar2(1);
w_numero_rate           number;
w_data_scadenza         date;
w_data_scadenza_0       date;
w_data_scadenza_1       date;
w_data_scadenza_2       date;
w_data_scadenza_3       date;
w_data_scadenza_4       date;
w_stringa              varchar2(37);
w_stringa_ogge         varchar2(220);
w_nome_par             varchar2(100);
CURSOR sel_cont (p_anno in number) IS
select sogg.ni                                                                  ni
      ,rpad(replace(nvl(sogg.cognome_nome,' '),'/',' '),60)                     cognome_nome
      ,decode(arvi.cod_via
                 ,null,substr(nvl(sogg.denominazione_via,' '),1,20)
                      ,substr(nvl(arvi.denom_uff,' '),1,20)
              )
       || decode(sogg.num_civ,null,to_char(null),', '||substr(sogg.num_civ,1,5))
       || decode(sogg.suffisso,null,null,'/'||substr(sogg.suffisso,1,2))
       || decode(sogg.scala,null,null,' Sc.'||sogg.scala)                       indirizzo
      ,nvl(sogg.cap,nvl(comu.cap,0))                                            cap
      ,substr(nvl(comu.denominazione,' '),1,20)||' '
       || decode(prov.sigla,null,null,'('||prov.sigla||')')                     comune
      ,cont.cod_fiscale                                                         cod_fiscale
      ,nvl(impo.imposta_ogim,0)                                                 imposta_ogim
      ,p_anno                                                                   anno_imposta
      ,impo.tributo
  from ad4_provincie       prov
      ,ad4_comuni          comu
      ,archivio_vie        arvi
      ,soggetti            sogg
      ,contribuenti        cont
      ,(select nvl(sum(nvl(ogim.imposta,0)),0)   imposta_ogim
             , ogim.cod_fiscale
             , ogpr.tributo                       tributo
          from oggetti_imposta        ogim
             , oggetti_pratica        ogpr
             , pratiche_tributo       prtr
         where  ogim.anno             = p_anno
           and ogim.oggetto_pratica   = ogpr.oggetto_pratica
           and ogpr.pratica           = prtr.pratica
           and ogpr.tributo= a_tributo
           and prtr.tipo_tributo||''  = 'TOSAP'
           and ogim.flag_calcolo      = 'S'
         group by ogim.cod_fiscale
                , ogpr.tributo
        ) impo
 where prov.provincia                        (+) = comu.provincia_stato
   and comu.comune                           (+) = sogg.cod_com_res
   and comu.provincia_stato                  (+) = sogg.cod_pro_res
   and arvi.cod_via                          (+) = sogg.cod_via
   and sogg.ni                                   = cont.ni
   and cont.cod_fiscale                          = impo.cod_fiscale
   and not exists (select 1
                     from deleghe_bancarie deba
                    where deba.cod_fiscale       (+) = cont.cod_fiscale
                      and deba.tipo_tributo      (+) = 'TOSAP'
                  )
 order by
       tributo
      ,rpad(replace(nvl(sogg.cognome_nome,' '),'/',' '),60)
      ,sogg.ni
       ;
CURSOR sel_ogge (p_anno in number, p_cod_fiscale in varchar2) IS
select ogim.num_bollettino                                      num_bollettino
      ,ogim.imposta                                             imposta
      ,ogim.oggetto_imposta                                     oggetto_imposta
      ,decode(arv2.cod_via
             ,null,substr(nvl(ogge.indirizzo_localita,' '),1,20)
                  ,substr(nvl(arv2.denom_uff,' '),1,20)
             )
    || decode(ogge.num_civ,null,to_char(null),', '||substr(ogge.num_civ,1,5))
    || decode(ogge.suffisso,null,null,'/'||substr(ogge.suffisso,1,2))
                                                                indirizzo_ogge
      ,ogpr.consistenza                                         consistenza
      ,tari.tariffa                                             tariffa
      ,tari.descrizione                                         desc_tariffa
      ,cate.descrizione                                         desc_categoria
  from oggetti_imposta                           ogim
      ,oggetti_pratica                           ogpr
      ,pratiche_tributo                          prtr
      ,oggetti                                   ogge
      ,archivio_vie                              arv2
      ,tariffe                                   tari
      ,categorie                                 cate
 where arv2.cod_via                          (+) = ogge.cod_via
   and ogpr.oggetto_pratica                      = ogim.oggetto_pratica
   and ogpr.pratica                              = prtr.pratica
   and prtr.tipo_tributo||''                     = 'TOSAP'
   and ogge.oggetto                              = ogpr.oggetto
   and cate.tributo                              = ogpr.tributo
   and cate.categoria                            = ogpr.categoria
   and tari.tributo                              = ogpr.tributo
   and tari.categoria                            = ogpr.categoria
   and tari.anno                                 = ogim.anno
   and tari.tipo_tariffa                         = ogpr.tipo_tariffa
   and ogim.cod_fiscale                          = p_cod_fiscale
   and ogim.anno                                 = p_anno
   and ogim.flag_calcolo                         = 'S'
   and ogpr.tributo= a_tributo
 order by
       ogge.oggetto
       ;
BEGIN
   BEGIN
      select '1'
            ,to_char(sysdate,'ddmmyy')
            ,dage.pro_cliente
            ,dage.com_cliente
            ,lpad(to_char(dage.pro_cliente),3,'0')||
             lpad(to_char(dage.com_cliente),3,'0')
            ,comu.sigla_cfis
            ,comu.denominazione
            ,titr.indirizzo_ufficio
            ,titr.descrizione
            ,titr.flag_canone
        into w_numero_ord
            ,w_data_elaborazione
            ,w_pro_cliente
            ,w_com_cliente
            ,w_istat
            ,w_belfiore
            ,w_denominazione_comune
            ,w_indirizzo_ufficio_com
            ,w_descrizione_titr
            ,w_flag_canone
        from dati_generali dage
           , ad4_comuni    comu
           , tipi_tributo  titr
       where dage.pro_cliente  = comu.provincia_stato
         and dage.com_cliente  = comu.comune
         and titr.tipo_tributo = 'TOSAP'
      ;
   EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore in estrazione Dati Ente '||
                                        ' ('||SQLERRM||')');
   END;
   BEGIN
      select max(scad.rata)
        into w_numero_rate
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
      ;
   EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore in estrazione Numero Rate '||
                                        ' ('||SQLERRM||')');
   END;
   BEGIN
      select scad.data_scadenza
        into w_data_scadenza_0
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
         and scad.rata          = 0
      ;
   EXCEPTION
      WHEN others THEN
         w_data_scadenza_0 := null;
   END;
   BEGIN
      select scad.data_scadenza
        into w_data_scadenza_1
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
         and scad.rata          = 1
      ;
   EXCEPTION
      WHEN others THEN
         w_data_scadenza_1 := null;
   END;
   BEGIN
      select scad.data_scadenza
        into w_data_scadenza_2
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
         and scad.rata          = 2
      ;
   EXCEPTION
      WHEN others THEN
         w_data_scadenza_2 := null;
   END;
   BEGIN
      select scad.data_scadenza
        into w_data_scadenza_3
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
         and scad.rata          = 3
      ;
   EXCEPTION
      WHEN others THEN
         w_data_scadenza_3 := null;
   END;
   BEGIN
      select scad.data_scadenza
        into w_data_scadenza_4
        from scadenze  scad
       where scad.anno          = a_anno
         and scad.tipo_tributo  = 'TOSAP'
         and scad.tipo_scadenza = 'V'
         and scad.rata          = 4
      ;
   EXCEPTION
      WHEN others THEN
         w_data_scadenza_4 := null;
   END;
   BEGIN
      si4.sql_execute('truncate table wrk_tras_anci');
   EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore in pulizia tabella di lavoro '||
                                        ' ('||SQLERRM||')');
   END;
   w_progressivo := w_progressivo + 1;
   w_supporto := w_belfiore||'_COSAP_MAV.txt';
   BEGIN
      insert into wrk_tras_anci
            (anno,progressivo,dati)
      values(0
            ,w_progressivo
            ,' '
          || 'IM'
          || 'AVRVE'
          || '05584'
          || lpad(w_data_elaborazione,6,'0')
          || rpad(w_supporto,20,' ')
          || rpad(' ',6,' ')
          || rpad(' ',68,' ')
          || 'E'
          || rpad(' ',6,' ')
            )
      ;
   EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record IM) ' ||
                                        ' ('||SQLERRM||')');
   END;
   w_tot_record := w_tot_record + 1;
--
--   TRATTAMENTO
--
   FOR rec_cont IN sel_cont(a_anno)
   LOOP
      if w_flag_canone = 'S' then
         w_importo_contribuente := rec_cont.imposta_ogim;
      else
         w_importo_contribuente := round(rec_cont.imposta_ogim,0);
      end if;
      if rec_cont.imposta_ogim > 248 then
         w_rata_min := 1;
         w_rata_max := w_numero_rate;
      else
         w_rata_min := 0;
         w_rata_max := 0;
      end if;
      FOR w_rata IN  w_rata_min..w_rata_max
      LOOP
         if w_rata = 0 then
            w_data_scadenza := nvl(w_data_scadenza_0,w_data_scadenza_1);
         elsif w_rata = 1 then
            w_data_scadenza := w_data_scadenza_1;
         elsif w_rata = 2 then
            w_data_scadenza := w_data_scadenza_2;
         elsif w_rata = 3 then
            w_data_scadenza := w_data_scadenza_3;
         elsif w_rata = 4 then
            w_data_scadenza := w_data_scadenza_4;
         else
            w_data_scadenza := w_data_scadenza_0;
         end if;
         if w_rata = 0 then
            w_importo := w_importo_contribuente;
         else
            if w_flag_canone = 'S' then
               if w_rata = w_rata_max then
                  w_importo := w_importo_contribuente - (w_rata_max - 1) * (w_importo_contribuente / w_rata_max);
               else
                  w_importo := (w_importo_contribuente / w_rata_max);
               end if;
            else
               if w_rata = w_rata_max then
                  w_importo := w_importo_contribuente - (w_rata_max - 1) * round(w_importo_contribuente / w_rata_max,0);
               else
                  w_importo := round(w_importo_contribuente / w_rata_max,0);
               end if;
            end if;
         end if;
         w_numero_ord        := to_char(to_number(w_numero_ord) + 1);
         w_numero            := w_numero + 1;
         w_progressivo       := w_progressivo + 1;
         -- Gestione Coimmissione - Aggiunta all'importo
         if nvl(a_commissione,0) > 0 then
            w_importo := w_importo + a_commissione;
         end if;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            select 0
                  ,w_progressivo
                  ,' '
                || '14'
                || lpad(to_char(w_numero),7,'0')
                || rpad(' ',12,' ')
                || lpad(nvl(to_char(w_data_scadenza,'ddmmyy'),'0'),6,'0')
                || '07000'
                || lpad(to_char(nvl(w_importo,0) * 100),13,'0')
                || '-'
                || '0558433030'
                || rpad('000000002077',34,' ')
                || 'AVRVE'
                || '4'
                || 'CO'||lpad(rec_cont.tributo,4,'0')
                      ||lpad(rec_cont.ni,7,'0')
                      ||substr(to_char(rec_cont.anno_imposta),3,2)
                      ||to_char(w_rata)
                || rpad(' ',6,' ')
                || 'E'
              from dual
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 14) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
         w_numero_14 := w_numero;
         w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
         w_progressivo := w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
                  ,' '
                || '20'
                || lpad(to_char(w_numero),7,'0')
                || substr(rpad('COMUNE DI '||w_denominazione_comune||'   '||Upper(w_indirizzo_ufficio_com)
                              ,96,' ')
                         ,1,96)
                || rpad(' ',14,' ')
                  )
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 20) '||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
         w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
         w_progressivo := w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
                  ,' '
                || '30'
                || lpad(to_char(w_numero),7,'0')
                || rpad(rec_cont.cognome_nome,60,' ')
                || rpad(rec_cont.cod_fiscale,16,' ')
                || rpad(' ',34,' ')
                  )
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 30) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
         w_numero_ord := to_char(to_number(w_numero_ord) + 1);
         w_progressivo:= w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
                  ,' '
                || '40'
                || lpad(to_char(w_numero),7,'0')
                || rpad(substr(rec_cont.indirizzo,1,30),30,' ')
                || lpad(rec_cont.cap,5,'0')
                || rpad(rec_cont.comune,25,' ')
                || rpad(nvl(substr(rec_cont.indirizzo,31,28),' '),28,' ')
                || rpad(' ',2,' ')
                || rpad(' ',20,' ')
                  )
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 40) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
         w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
         w_progressivo := w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            select 0
                  ,w_progressivo
                  ,' '
                || '51'
                || lpad(to_char(w_numero),7,'0')
                || substr(to_char(rec_cont.anno_imposta),3,2)
                || lpad(to_char(w_rata),2,'0')
                || lpad(to_char(rec_cont.ni),6,'0')
                || rpad(' ',54,' ')
                || substr(to_char(rec_cont.anno_imposta),3,2)
                || lpad(to_char(w_rata),1,'0')
                || lpad(substr(rec_cont.tributo,1,3),3,'0')
                || lpad(to_char(rec_cont.ni),6,'0')
                || rpad(' ',34,' ')
              from dual
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 51) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
         w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
         w_progressivo := w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
                  ,' '
                || '59'
                || lpad(to_char(w_numero),7,'0')
                || rpad(substr('Comune di '||INITCAP(w_denominazione_comune)
                               ||' - '||w_descrizione_titr||' '||to_char(rec_cont.anno_imposta)
                               ||' - '||decode(w_rata
                                              ,0,'Unica Soluzione'
                                              ,'Rata '||to_char(w_rata)
                                              )
                              ,1,110)
                       ,110,' ')
                  )
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 59-01) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record   := w_tot_record + 1;
          --
          --   TRATTAMENTO OGGETTI
          --
         FOR REC_ogge in SEL_ogge (a_anno, rec_cont.cod_fiscale)
         LOOP
            BEGIN
               select rpad(substr(rec_ogge.indirizzo_ogge
                                  ||' - '||rec_ogge.desc_categoria
                                 ,1,110)
                          ,110,' ')
                   ||rec_ogge.desc_tariffa
                   ||' - '
                   || 'Sup. mq '
                   || to_char(rec_ogge.consistenza)
                   || '  Tariffa '
                   || decode(substr(rec_ogge.tariffa,1,1),
                     '.','0'||to_char(rec_ogge.tariffa),
                         to_char(rec_ogge.tariffa))
                  into w_stringa_ogge
                 from dual
               ;
            END;
            w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_tras_anci
                     (anno,progressivo,dati)
               values(0
                     ,w_progressivo
                     ,' '
                   || '59'
                   || lpad(to_char(w_numero),7,'0')
                   || rpad(substr(w_stringa_ogge,1,110),110,' ')
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 59-1) ' ||
                                                 ' ('||SQLERRM||')');
            END;
            w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_tras_anci
                     (anno,progressivo,dati)
               values(0
                     ,w_progressivo
                     ,' '
                   || '59'
                   || lpad(to_char(w_numero),7,'0')
                   || rpad(substr(w_stringa_ogge,111,110),110,' ')
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 59-2) ' ||
                                                 ' ('||SQLERRM||')');
            END;
            w_tot_record  := w_tot_record + 2;
         END LOOP;
         -- Gestione Commissione - Descrizione
         if nvl(a_commissione,0) > 0 then
            w_progressivo := w_progressivo + 1;
            BEGIN
               insert into wrk_tras_anci
                     (anno,progressivo,dati)
               values(0
                     ,w_progressivo
                     ,' '
                   || '59'
                   || lpad(to_char(w_numero),7,'0')
                   || rpad('Commissione MAV: '||to_char(a_commissione)||' euro',110,' ')
                     )
               ;
            EXCEPTION
               WHEN others THEN
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 59-3) ' ||
                                                 ' ('||SQLERRM||')');
            END;
            w_tot_record  := w_tot_record + 1;
         end if;
         w_numero_ord  := to_char(to_number(w_numero_ord) + 1);
         w_progressivo := w_progressivo + 1;
         BEGIN
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
                  ,' '
                || '70'
                || lpad(to_char(w_numero),7,'0')
                || rpad(' ',110,' ')
                  )
            ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 70) ' ||
                                              ' ('||SQLERRM||')');
         END;
         w_tot_record  := w_tot_record + 1;
         w_tot_importo := w_tot_importo + w_importo;
      END LOOP;
   END LOOP;
   w_disposizioni := w_numero;
   w_numero_ord   := to_char(to_number(w_numero_ord) + 1);
   w_tot_record   := w_tot_record + 1;
   w_progressivo  := w_progressivo + 1;
   BEGIN
      insert into wrk_tras_anci
            (anno,progressivo,dati)
      values(0
            ,w_progressivo
            ,' '
          || 'EF'
          || 'AVRVE'
          || '05584'
          || lpad(w_data_elaborazione,6,'0')
          || rpad(w_supporto,20,' ')
          || rpad(' ',6,' ')
          || lpad(to_char(w_disposizioni),7,'0')
          || lpad(to_char(w_tot_importo * 100),15,'0')
          || rpad('0',15,'0')
          || lpad(to_char(w_tot_record),7,'0')
          || rpad(' ',24,' ')
          || 'E'
          || rpad(' ',6,' ')
            )
      ;
   EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record EF) ' ||
                                        ' ('||SQLERRM||')');
   END;
   a_tot_importo  := w_tot_importo;
   a_disposizioni := w_disposizioni;
   a_tot_record   := w_tot_record;
EXCEPTION
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Errore in Trasmissione MAV' ||
                                     ' ('||SQLERRM||')');
END;
/* End Procedure: TRASMISSIONE_COSAP_MAV */
/

