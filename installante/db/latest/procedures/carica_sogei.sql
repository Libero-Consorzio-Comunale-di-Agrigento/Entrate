--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_sogei stripComments:false runOnChange:true 
 
create or replace procedure carica_sogei
(a_sezione_unica   IN       varchar2)
is
sql_errm                    varchar2(100);
w_num_contrib               number;
w_dep_num_contrib           number;
w_progr_contrib             number;
w_cod_pro                   number;
w_cod_com                   number;
w_pratica                   number;
w_oggetto_pratica           number;
w_oggetto                   number;
w_ni                        number;
w_max_ni                    number;
w_estremi_catasto           varchar2(20);
w_controllo                 varchar2(1);
w_cod_fisc_dichiarante      varchar2(16);
w_cognome_dichiarante       varchar2(40);
w_nome_dichiarante          varchar2(20);
w_sesso_dichiarante         varchar2(1);
w_com_nas_dichiarante       varchar2(25);
w_sigla_pro_nas_dichiarante varchar2(2);
w_data_nas_dichiarante      number;
w_indirizzo_dichiarante     varchar2(40);
w_comune_dichiarante        varchar2(60);
w_indirizzo_localita        varchar2(36);
w_sezione                   varchar2(3);
w_foglio                    varchar2(5);
w_numero                    varchar2(5);
w_subalterno                varchar2(4);
w_protocollo_catasto        varchar2(6);
w_anno_catasto              number;
w_categoria                 varchar2(3);
w_tipo_rendita_93           number;
w_tipo_bene_93              number;
w_esenzione_93              number;
w_ab_principale             varchar2(1);
w_riduzione_93              number;
w_rendita                   number;
w_perc_possesso             number;
w_percentuale_93            number;
w_detrazione                number;
w_esclusione                varchar2(1);
w_riduzione                 varchar2(1);
w_conduzione_93             number;
w_area_fabbr_93             number;
w_cod_via                   number;
w_num_civ                   number;
w_suffisso                  varchar2(5);
w_partita                   varchar2(8);
w_reddito_dominicale        number;
w_cod_fisc_contitolare      varchar2(16);
w_cognome_contitolare       varchar2(40);
w_nome_contitolare          varchar2(20);
w_sesso_contitolare         varchar2(1);
w_data_nas_contitolare      number;
w_cod_fisc_rappresentante   varchar2(16);
w_rappresentante            varchar2(60);
w_carica_rappresentante     varchar2(25);
w_indir_rappresentante      varchar2(35);
w_comune_rappresentante     varchar2(60);
w_numero_ordine             number;
w_tipo_carica               number;
w_max_tipo_carica           number;
w_flag_cont                 number;
w_flag_nas                  number;
w_flag_immobili             number;
w_flag_tipo_carica          number;
w_progr_immobile_caricato   number;
w_denom_ric                 varchar2(60);
w_indirizzo_localita_1      varchar2(36);
w_cap                       number;
w_catasto                   varchar2(4);
w_des                       varchar2(30);
w_sigla                     varchar2(3);
w_progressivo_msg           number;
w_tipo_record_msg           varchar(1);
w_num_contrib_msg           number;
w_progr_contrib_msg         number;
w_inizio                    varchar2(1);
w_fine                      varchar2(1);
-- (VD - 10/01/2020): Variabili per memorizzare la prima e l'ultima denuncia
--                    inserite, per poi lanciare l'archiviazione
w_min_pratica               number;
w_max_pratica               number;
CURSOR ricerca_comuni (w_descrizione  varchar2,
                 w_sigla_provincia    varchar2,
                 w_codice_catasto     varchar2) IS
      select com.provincia_stato,com.comune,com.cap
        from ad4_provincie pro,ad4_comuni com
       where pro.sigla         = nvl(w_sigla_provincia,pro.sigla)
         and pro.provincia     = com.provincia_stato
         and com.sigla_cfis    = nvl(w_codice_catasto,com.sigla_cfis)
         and com.denominazione like w_descrizione||'%'
       ;
CURSOR sel_dic IS
      select *
        from sogei_dic
       where tipo_record in ('B','D','H','I','L','M','C','E','F','W','G')
       order by num_contrib,progr_contrib
       ;
BEGIN
  BEGIN
   select nvl(max(pratica),0)
     into w_pratica
     from pratiche_tributo
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca pratica'||
                ' ('||sql_errm||')');
  END;
  BEGIN
   select nvl(max(oggetto_pratica),0)
     into w_oggetto_pratica
     from oggetti_pratica
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca oggetto pratica'||
                ' ('||sql_errm||')');
  END;
  BEGIN
   select nvl(max(oggetto),0)
     into w_oggetto
     from oggetti
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca oggetti'||
                ' ('||sql_errm||')');
  END;
  BEGIN
   select nvl(max(ni),0)
     into w_max_ni
     from soggetti
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca soggetti'||
                ' ('||sql_errm||')');
  END;
  BEGIN
   select nvl(max(tipo_carica),0)
     into w_max_tipo_carica
     from tipi_carica
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca tipi carica'||
                ' ('||sql_errm||')');
  END;
    w_dep_num_contrib     := 0;
-- dbms_output.put_line ('fuori dal LOOP');
  FOR rec_dic IN sel_dic LOOP
-- dbms_output.put_line ('dentro il LOOP');
    w_progressivo_msg := rec_dic.progressivo;
    w_tipo_record_msg := rec_dic.tipo_record;
    w_num_contrib_msg := rec_dic.num_contrib;
    w_progr_contrib_msg := rec_dic.progr_contrib;
<<rec_dic_fis>>
    IF rec_dic.tipo_record = 'B' THEN
       BEGIN
        select rtrim(substr(rec_dic.dati,1,16)),
               rtrim(substr(rec_dic.dati,18,24)),
               rtrim(substr(rec_dic.dati,42,20)),
               rtrim(substr(rec_dic.dati,68,1)),
               rtrim(substr(rec_dic.dati,69,25)),
               rtrim(substr(rec_dic.dati,94,2)),
               decode(translate(substr(rec_dic.dati,62,6),'1234567890',
                      '9999999999'),'999999',substr(rec_dic.dati,62,6),''),
                      rec_dic.num_contrib,rec_dic.progr_contrib
          into w_cod_fisc_dichiarante,
               w_cognome_dichiarante,
               w_nome_dichiarante,
               w_sesso_dichiarante,
               w_com_nas_dichiarante,
               w_sigla_pro_nas_dichiarante,
               w_data_nas_dichiarante,
               w_num_contrib,
               w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. B'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         delete sogei_dic
          where num_contrib = w_dep_num_contrib
            and w_dep_num_contrib != 0
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in eliminazione contribuente da sogei_dic (B)'||
                     ' ('||sql_errm||')');
       END;
     COMMIT;
       w_pratica       := w_pratica + 1;
       -- (VD - 10/01/2020): si memorizzano la prima e l'ultima pratica
       --                    inserite
       if w_min_pratica is null then
          w_min_pratica := w_pratica;
       end if;
       if w_pratica > nvl(w_max_pratica,0) then
          w_max_pratica := w_pratica;
       end if;
       w_numero_ordine := 000;
       w_flag_cont     := 0;
       BEGIN
        select 1
          into w_flag_cont
          from contribuenti cont
         where cont.cod_fiscale = w_cod_fisc_dichiarante
         ;
         RAISE too_many_rows;
       EXCEPTION
         WHEN too_many_rows THEN
              null;
         WHEN no_data_found THEN
         BEGIN
           select max(sogg.ni),1
             into w_ni,w_flag_cont
             from soggetti sogg
            where sogg.cod_fiscale = w_cod_fisc_dichiarante
           having max(sogg.ni) is not null
                 ;
           RAISE too_many_rows;
         EXCEPTION
           WHEN too_many_rows THEN
             BEGIN
               insert into contribuenti (cod_fiscale,ni)
               values (w_cod_fisc_dichiarante,w_ni)
                    ;
             EXCEPTION
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento contribuenti:'||
                  w_cod_fisc_dichiarante||' ni'||w_ni||
                  ' ('||sql_errm||')');
             END;
           WHEN no_data_found THEN
              w_max_ni        := w_max_ni + 1;
              w_flag_nas      := 0;
              IF w_data_nas_dichiarante is not null THEN
                 BEGIN
                   select 1
                     into w_flag_nas
                     from dual
                    where (substr(lpad(w_data_nas_dichiarante,6,0),1,2) = '31' and
                           substr(lpad(w_data_nas_dichiarante,6,0),3,2) in ('02','04','06','09','11'))
                       or (substr(lpad(w_data_nas_dichiarante,6,0),1,2) = '30' and
                           substr(lpad(w_data_nas_dichiarante,6,0),3,2) = '02')
                       or (substr(lpad(w_data_nas_dichiarante,6,0),1,2) = '29' and
                           substr(lpad(w_data_nas_dichiarante,6,0),3,2) = '02' and
                           trunc(to_number(substr(
                                  lpad(w_data_nas_dichiarante,6,0),5,2)) / 4) * 4 !=
                               to_number(substr(lpad(w_data_nas_dichiarante,6,0),5,2)))
                       or (to_number(substr(lpad(w_data_nas_dichiarante,6,0),1,2)) > 31)
                       or (to_number(substr(lpad(w_data_nas_dichiarante,6,0),1,2)) < 1)
                       or (to_number(substr(lpad(w_data_nas_dichiarante,6,0),3,2)) > 12)
                       or (to_number(substr(lpad(w_data_nas_dichiarante,6,0),3,2)) < 1)
                       or (to_number(substr(lpad(w_data_nas_dichiarante,6,0),5,2)) < 0)
                   ;
                 EXCEPTION
                   WHEN no_data_found THEN
                     null;
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     RAISE_APPLICATION_ERROR
                     (-20999,'Errore in controllo data nas. dichiarante'||
                             ' data '||w_data_nas_dichiarante||
                             ' cf '||w_cod_fisc_dichiarante||
                             ' ('||sql_errm||')');
                 END;
                 BEGIN
                   --select to_char(to_date(lpad(w_data_nas_dichiarante,6,0),'ddmmyy'),'ddmmyyyy')
                   select to_char(to_date(substr(lpad(w_data_nas_dichiarante,6,0),1,4)||
                                          '19'||
                                          substr(lpad(w_data_nas_dichiarante,6,0),5),
                                  'ddmmyyyy'),'ddmmyyyy')
                     into w_data_nas_dichiarante
                     from dual
                    where w_flag_nas != 1
                   ;
                   RAISE no_data_found;
                 EXCEPTION
                   WHEN no_data_found THEN
                     null;
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     RAISE_APPLICATION_ERROR
                      (-20999,'Errore in var. anno data nas. dichiarante'||
                              ' data '||w_data_nas_dichiarante||
                              ' cf '||w_cod_fisc_dichiarante||
                              ' ('||sql_errm||')');
                 END;
-- dbms_output.put_line ('data nas dic. :'||w_data_nas_dichiarante);
                 BEGIN
                   select substr(lpad(w_data_nas_dichiarante,8,0),1,4)||
                          to_number(substr(lpad(w_data_nas_dichiarante,8,0),5,4)) - 100
                     into w_data_nas_dichiarante
                     from dual
                    where w_flag_nas != 1
                      and to_char(add_months(to_date(lpad(w_data_nas_dichiarante,8,0),
                          'ddmmyyyy'),120),'j') > to_char(sysdate,'j')
                 ;
                   RAISE no_data_found;
 -- dbms_output.put_line ('data nas dic. :'||w_data_nas_dichiarante);
                 EXCEPTION
                   WHEN no_data_found THEN
                     null;
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     RAISE_APPLICATION_ERROR
                      (-20999,'Errore in sottraz. secolo data nas. dichiarante'||
                              ' data '||w_data_nas_dichiarante||
                              ' cf '||w_cod_fisc_dichiarante||
                              ' ('||sql_errm||')');
                 END;
              END IF;
              BEGIN
-- dbms_output.put_line ('1.prima :'||w_cod_pro||' com :'||w_cod_com||' cap :'||w_cap);
                w_cod_pro := '';
                w_cod_com := '';
                w_cap     := '';
                w_des     := w_com_nas_dichiarante;
                w_sigla   := w_sigla_pro_nas_dichiarante;
                w_catasto := '';
                OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
                FETCH ricerca_comuni INTO w_cod_pro,w_cod_com,w_cap;
                CLOSE ricerca_comuni;
-- dbms_output.put_line ('1.pro :'||w_cod_pro||' com :'||w_cod_com||' cap :'||w_cap);
              END;
-- dbms_output.put_line ('data nas dic. dopo sottr. :'||w_data_nas_dichiarante);
              BEGIN
                insert into soggetti
                       (ni,tipo_residente,cod_fiscale,cognome_nome,
                        sesso,data_nas,cod_pro_nas,cod_com_nas,
                        partita_iva,tipo,utente,data_variazione)
                values (w_max_ni,1,
                        decode(length(w_cod_fisc_dichiarante),16,
                        w_cod_fisc_dichiarante,''),
                        nvl(substr(w_cognome_dichiarante||
                        decode(w_nome_dichiarante,'','','/'||
                               w_nome_dichiarante),1,40),
                        'DENOMINAZIONE ASSENTE'),
                        w_sesso_dichiarante,
                        decode(w_data_nas_dichiarante,'',to_date(''),
                           decode(w_flag_nas,1,to_date(''),
                              to_date(lpad(w_data_nas_dichiarante,8,0),
                                 'ddmmyyyy'))),
                        w_cod_pro,w_cod_com,
                        decode(length(w_cod_fisc_dichiarante),11,
                           translate(w_cod_fisc_dichiarante,'O','0'),''),
                        decode(length(w_cod_fisc_dichiarante),
                           16,0,11,1,2),
                        'ICI',to_date(sysdate))
                    ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento nuovo soggetto'||
                            ' ('||sql_errm||')');
              END;
              BEGIN
                insert into contribuenti (cod_fiscale,ni)
                values (w_cod_fisc_dichiarante,w_max_ni)
                     ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo contribuente'||
                             ' ('||sql_errm||')');
              END;
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in ricerca soggetti'||
                       ' ('||sql_errm||')');
         END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione contribuenti'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into pratiche_tributo (pratica,cod_fiscale,tipo_tributo,
                     anno,tipo_pratica,tipo_evento,
                    utente,data_variazione)
         values (w_pratica,w_cod_fisc_dichiarante,'ICI',1992,'D','I',
                 'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento nuova pratica (dic.fis.)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into rapporti_tributo (pratica,cod_fiscale,tipo_rapporto)
         values (w_pratica,w_cod_fisc_dichiarante,'D')
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento rapporto tributo (dic.fis.)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into denunce_ici (pratica,denuncia,fonte,utente,data_variazione)
         values (w_pratica,w_pratica,1,'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento denuncia ici (dic.fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_dic_non_fis>>
    IF rec_dic.tipo_record = 'D' THEN
       BEGIN
        select substr(rec_dic.dati,1,11),
               rtrim(substr(rec_dic.dati,13,40)),
               '','','','','',
                rec_dic.num_contrib,rec_dic.progr_contrib
          into w_cod_fisc_dichiarante,
               w_cognome_dichiarante,
               w_nome_dichiarante,
               w_sesso_dichiarante,
          w_com_nas_dichiarante,
          w_sigla_pro_nas_dichiarante,
               w_data_nas_dichiarante,
          w_num_contrib,
          w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. D'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         delete sogei_dic
          where num_contrib = w_dep_num_contrib
            and w_dep_num_contrib != 0
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in eliminazione contribuente da sogei_dic (D)'||
                     ' ('||sql_errm||')');
       END;
     COMMIT;
       w_pratica       := w_pratica + 1;
       if w_min_pratica is null then
          w_min_pratica := w_pratica;
       end if;
       if w_pratica > nvl(w_max_pratica,0) then
          w_max_pratica := w_pratica;
       end if;
       w_numero_ordine := 000;
       w_flag_cont     := 0;
       BEGIN
         select 1
           into w_flag_cont
           from contribuenti cont
          where cont.cod_fiscale = w_cod_fisc_dichiarante
         ;
         RAISE too_many_rows;
       EXCEPTION
         WHEN too_many_rows THEN
           null;
         WHEN no_data_found THEN
           BEGIN
             select max(sogg.ni),1
               into w_ni,w_flag_cont
               from soggetti sogg
              where sogg.cod_fiscale = w_cod_fisc_dichiarante
             having max(sogg.ni) is not null
                 ;
             RAISE too_many_rows;
           EXCEPTION
             WHEN too_many_rows THEN
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_dichiarante,w_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento contribuenti'||
                             ' ('||sql_errm||')');
               END;
             WHEN no_data_found THEN
               w_max_ni        := w_max_ni + 1;
               w_flag_nas      := 0;
               BEGIN
                 insert into soggetti
                            (ni,tipo_residente,cod_fiscale,cognome_nome,
                             sesso,data_nas,cod_pro_nas,cod_com_nas,
                             partita_iva,tipo,utente,data_variazione)
                 values (w_max_ni,1,
                         decode(length(w_cod_fisc_dichiarante),16,
                                w_cod_fisc_dichiarante,''),
                         nvl(substr(w_cognome_dichiarante||
                             decode(w_nome_dichiarante,'','','/'||
                                    w_nome_dichiarante),1,40),
                            'DENOMINAZIONE ASSENTE'),
                         w_sesso_dichiarante,'','','',
                         decode(length(w_cod_fisc_dichiarante),11,
                         translate(w_cod_fisc_dichiarante,'O','0'),''),
                         decode(length(w_cod_fisc_dichiarante),
                                16,0,11,1,2),
                         'ICI',to_date(sysdate))
                          ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo soggetto'||
                             ' ('||sql_errm||')');
               END;
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_dichiarante,w_max_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo contribuente'||
                             ' ('||sql_errm||')');
               END;
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca soggetti'||
                         ' ('||sql_errm||')');
           END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione contribuenti'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into pratiche_tributo (pratica,cod_fiscale,tipo_tributo,
                     anno,tipo_pratica,tipo_evento,
                     utente,data_variazione)
         values (w_pratica,w_cod_fisc_dichiarante,'ICI',1992,'D','I',
                 'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento nuova pratica (dic. non fis.)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
        insert into rapporti_tributo (pratica,cod_fiscale,tipo_rapporto)
        values (w_pratica,w_cod_fisc_dichiarante,'D')
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento rapporto tributo (dic. non fis.)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into denunce_ici (pratica,denuncia,fonte,utente,data_variazione)
         values (w_pratica,w_pratica,1,'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento denuncia ici (dic. non fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_res_dichiaranti>>
    IF rec_dic.tipo_record in ('C','E') THEN
-- dbms_output.put_line ('tipo record C');
       w_inizio := 'S';
       BEGIN
        select substr(rec_dic.dati,33,35),
               decode(rtrim(substr(rec_dic.dati,1,25)),'','',
                      rtrim(substr(rec_dic.dati,1,25))),
               rec_dic.num_contrib,rec_dic.progr_contrib
          into w_indirizzo_dichiarante,
               w_comune_dichiarante,
               w_num_contrib,
               w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. C-E'||
                     ' ('||sql_errm||')');
       END;
       IF w_flag_cont = 0 THEN
          BEGIN
            w_cod_pro := '';
            w_cod_com := '';
            w_cap     := '';
            w_des     := w_comune_dichiarante;
            w_sigla   := '';
            w_catasto := '';
            OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
            FETCH ricerca_comuni INTO w_cod_pro,w_cod_com,w_cap;
            CLOSE ricerca_comuni;
-- dbms_output.put_line ('2.pro :'||w_cod_pro||' com :'||w_cod_com||' cap :'||w_cap);
          END;
          BEGIN
            update soggetti
               set denominazione_via = w_indirizzo_dichiarante,
                   cod_pro_res       = w_cod_pro,
                   cod_com_res       = w_cod_com,
                   cap               = w_cap,
                   note              = decode(w_cod_pro,'',
                     substr(note||' COM. DICH. '||w_comune_dichiarante,1,60),'')
             where ni                = w_max_ni
            ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in aggiornamento soggetti tipo rec. C-E'||
                        ' ('||sql_errm||')');
         END;
      END IF;
      w_fine := 'S';
    END IF;
<<rec_fabbricati>>
    IF rec_dic.tipo_record = 'I' THEN
       BEGIN
         select rtrim(substr(rec_dic.dati,1,36)),
                decode(a_sezione_unica,'S','',
                   decode(substr(rec_dic.dati,37,3),
                      '000','',
                      '   ','',rtrim(substr(rec_dic.dati,37,3)))),
                decode(substr(rec_dic.dati,40,5),
                   '00000','',
                   '     ','',rtrim(substr(rec_dic.dati,40,5))),
                decode(substr(rec_dic.dati,45,5),
                   '00000','',
                   '     ','',rtrim(substr(rec_dic.dati,45,5))),
                decode(substr(rec_dic.dati,50,4),
                   '0000','',
                   '    ','',rtrim(substr(rec_dic.dati,50,4))),
                decode(substr(rec_dic.dati,54,6),
                   '000000','',
                   '      ','',rtrim(substr(rec_dic.dati,54,6))),
                decode(substr(rec_dic.dati,60,2),
                   '00','',
                        '  ','','19'||rtrim(substr(rec_dic.dati,60,2))),
                rtrim(substr(rec_dic.dati,62,3)),
                substr(rec_dic.dati,65,1),
                substr(rec_dic.dati,66,1),
                substr(rec_dic.dati,67,1),
                decode(substr(rec_dic.dati,68,6),'000000','','S'),
                substr(rec_dic.dati,74,1),
                rtrim(substr(rec_dic.dati,75,13)),
                rtrim(substr(rec_dic.dati,88,5)) / 100,
                substr(rec_dic.dati,93,1),
                rtrim(substr(rec_dic.dati,68,6)),
                decode(substr(rec_dic.dati,67,1),'1','S','2','S',''),
                decode(substr(rec_dic.dati,74,1),'1','S',''),
                '','','','','','',
                rec_dic.num_contrib,rec_dic.progr_contrib
           into w_indirizzo_localita,
                w_sezione,
                w_foglio,
                w_numero,
                w_subalterno,
                w_protocollo_catasto,
                w_anno_catasto,
                w_categoria,
                w_tipo_rendita_93,
                w_tipo_bene_93,
                w_esenzione_93,
                w_ab_principale,
                w_riduzione_93,
                w_rendita,
                w_perc_possesso,
                w_percentuale_93,
                w_detrazione,
                w_esclusione,
                w_riduzione,
                w_conduzione_93,
                w_area_fabbr_93,
                w_cod_via,
                w_num_civ,
                w_suffisso,
                w_reddito_dominicale,
                w_num_contrib,
                w_progr_contrib
           from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. I'||
                     ' ('||sql_errm||')');
       END;
       w_flag_immobili           := 0;
       w_progr_immobile_caricato := 0;
       w_cod_via                 := 0;
       w_num_civ                 := 0;
       w_suffisso                := '';
       w_numero_ordine           := w_numero_ordine + 1;
       w_oggetto_pratica         := w_oggetto_pratica + 1;
       IF w_sezione||w_foglio||w_numero||w_subalterno is not null THEN
          w_estremi_catasto := lpad(ltrim(nvl(w_sezione,' '),'0'),3,' ')
                              ||
                              lpad(ltrim(nvl(w_foglio,' '),'0'),5,' ')
                              ||
                              lpad(ltrim(nvl(w_numero,' '),'0'),5,' ')
                              ||
                              lpad(ltrim(nvl(w_subalterno,' '),'0'),4,' ')
                              ||
                              lpad(' ',3);
-- dbms_output.put_line ('estremi: '||w_estremi_catasto);
          BEGIN
            select '1',oggetto
              into w_flag_immobili,w_progr_immobile_caricato
              from oggetti
             where w_estremi_catasto            = estremi_catasto
               and nvl(categoria_catasto,'   ') = nvl(w_categoria,'   ')
           ;
         EXCEPTION
           WHEN no_data_found THEN
             null;
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in controllo esistenza fabbricato'||
                       ' ('||sql_errm||')');
         END;
       END IF;
       IF w_flag_immobili = 0 THEN
          BEGIN
            select cod_via,descrizione,w_indirizzo_localita
              into w_cod_via,w_denom_ric,w_indirizzo_localita_1
              from denominazioni_via devi
             where w_indirizzo_localita like '%'||devi.descrizione||'%'
               and devi.descrizione is not null
               and not exists (select 'x'
                                 from denominazioni_via devi1
                                where w_indirizzo_localita
                                      like '%'||devi1.descrizione||'%'
                                  and devi1.descrizione is not null
                                  and devi1.cod_via != devi.cod_via)
               and rownum = 1
           ;
          EXCEPTION
            -- WHEN too_many_rows then
            --   w_cod_via := 0;
            WHEN no_data_found then
              w_cod_via := 0;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in controllo esistenza indirizzo fabbricato'||
                        'indir: '||w_indirizzo_localita||
                        ' ('||sql_errm||')');
          END;
          IF w_cod_via != 0 THEN
             BEGIN
               select substr(w_indirizzo_localita_1,
                            (instr(w_indirizzo_localita_1,w_denom_ric)
                             + length(w_denom_ric)))
                 into w_indirizzo_localita_1
                 from dual
              ;
             EXCEPTION
               WHEN no_data_found THEN
                 null;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in decodifica indirizzo (1)'||
                           ' ('||sql_errm||')');
             END;
             BEGIN
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
                ),
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
                )
                 into w_num_civ,w_suffisso
                 from dual
              ;
             EXCEPTION
               WHEN no_data_found THEN
                 null;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in decodifica numero civico e suffisso'||
                           ' ('||sql_errm||')');
             END;
          END IF;
          w_oggetto := w_oggetto + 1;
          IF w_categoria is not null THEN
             BEGIN
               select 'x'
                 into w_controllo
                 from categorie_catasto
                where categoria_catasto = w_categoria
                ;
             EXCEPTION
               WHEN no_data_found THEN
                 BEGIN
                   insert into categorie_catasto
                         (categoria_catasto,descrizione)
                   values (w_categoria,'DA CARICAMENTO DATI SOGEI')
                  ;
                 EXCEPTION
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     RAISE_APPLICATION_ERROR
                       (-20999,'Errore in inserimento Categorie Catasto'||
                               ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in ricerca Categorie Catasto'||
                           ' ('||sql_errm||')');
             END;
          END IF;
          BEGIN
            insert into oggetti
                  (oggetto,tipo_oggetto,indirizzo_localita,
                   cod_via,num_civ,suffisso,sezione,foglio,
                   numero,subalterno,protocollo_catasto,
                   anno_catasto,categoria_catasto,
                   fonte,utente,data_variazione)
            values (w_oggetto,decode(w_tipo_rendita_93,3,4,3),
                    w_indirizzo_localita,
                    decode(w_cod_via,0,'',w_cod_via),
                    decode(w_num_civ,0,'',w_num_civ),
                    w_suffisso,
                    ltrim(w_sezione,'0'),
                    ltrim(w_foglio,'0'),
                    ltrim(w_numero,'0'),
                    ltrim(w_subalterno,'0'),
                    ltrim(w_protocollo_catasto,'0'),
                    w_anno_catasto,w_categoria,
                    1,'ICI',to_date(sysdate))
               ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento fabbricato '||
                --w_oggetto||'/'||
                --w_indirizzo_localita||'/'||w_cod_via||'/'||
                --w_num_civ||'/'||w_suffisso||'/'||
                --w_sezione||'/'||w_foglio||'/'||w_numero||'/'||w_subalterno||'/'||
                --w_protocollo_catasto||'/'||w_anno_catasto||'/'||w_categoria||
                        ' ('||sql_errm||')');
          END;
       END IF;
       BEGIN
         select w_rendita * 50
           into w_rendita
           from dual
          where decode(w_tipo_rendita_93,3,4,3) = 3
            and (w_categoria   = 'A10' or
                 w_categoria  like 'D%')
         ;
       EXCEPTION
         WHEN no_data_found THEN
           null;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in calcolo rendita (A10)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         select w_rendita * 34
           into w_rendita
           from dual
          where decode(w_tipo_rendita_93,3,4,3) = 3
            and w_categoria                  = 'C01'
         ;
       EXCEPTION
         WHEN no_data_found THEN
           null;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
           (-20999,'Errore in calcolo rendita (C01)'||
                   ' ('||sql_errm||')');
       END;
       BEGIN
         select w_rendita * 100
           into w_rendita
           from dual
          where decode(w_tipo_rendita_93,3,4,3) = 3
            and (w_categoria  like 'A%' or
                 w_categoria  like 'B%' or
            w_categoria  like 'C%')
            and w_categoria  not in ('C01','A10')
         ;
       EXCEPTION
         WHEN no_data_found THEN
           null;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in calcolo rendita (!= C01,A10)'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into oggetti_pratica
               (oggetto_pratica,oggetto,pratica,anno,
                num_ordine,categoria_catasto,
                flag_provvisorio,
                valore,fonte,utente,data_variazione)
         values (w_oggetto_pratica,
                 decode(w_flag_immobili,1,w_progr_immobile_caricato, w_oggetto),
                 w_pratica,1992,w_numero_ordine,w_categoria,
                 decode(w_tipo_rendita_93,2,'S',''),
                 w_rendita,1,'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento oggetti_pratica (I) '||
                     ' ('||sql_errm||')');
       END;
-- dbms_output.put_line ('cf: '||w_cod_fisc_dichiarante);
-- dbms_output.put_line ('op: '||w_oggetto_pratica);
      BEGIN
        insert into oggetti_contribuente
              (cod_fiscale,oggetto_pratica,
               anno,tipo_rapporto,
               perc_possesso,detrazione,flag_possesso,
               flag_esclusione,flag_riduzione,
               flag_ab_principale,utente,
               data_variazione)
        values (w_cod_fisc_dichiarante,w_oggetto_pratica,1992,'D',
                w_perc_possesso,
                w_detrazione,'S',w_esclusione,w_riduzione,w_ab_principale,
                'ICI',to_date(sysdate))
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in inserimento oggetti_contribuente (I) '||
                    ' ('||sql_errm||')');
      END;
      BEGIN
        insert into oggetti_ici_93
              (oggetto_pratica,tipo_rendita_93,tipo_bene_93,
               esenzione_93,riduzione_93,percentuale_93,
               conduzione_93,area_fabbr_93)
        values (w_oggetto_pratica,w_tipo_rendita_93,w_tipo_bene_93,
                w_esenzione_93,w_riduzione_93,w_percentuale_93,
                w_conduzione_93,w_area_fabbr_93)
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in inserimento oggetti_ici_93 (I) '||
                    ' ('||sql_errm||')');
      END;
    END IF;
<<rec_terreni>>
    IF rec_dic.tipo_record = 'H' THEN
       BEGIN
         select rtrim(substr(rec_dic.dati,1,8)),
                substr(rec_dic.dati,9,1),
                substr(rec_dic.dati,10,1),
                rtrim(substr(rec_dic.dati,11,11)),
                rtrim(substr(rec_dic.dati,22,5)) / 100,
                substr(rec_dic.dati,27,1),
                substr(rec_dic.dati,28,1),
                rtrim(substr(rec_dic.dati,30,32)),
                decode(substr(rec_dic.dati,28,1),'1','S','2','S',''),
                decode(substr(rec_dic.dati,9,1),'1','S',''),
                '','','','','','',
                 rec_dic.num_contrib,rec_dic.progr_contrib
           into w_partita,
                w_conduzione_93,
                w_area_fabbr_93,
                w_reddito_dominicale,
                w_perc_possesso,
                w_percentuale_93,
                w_esenzione_93,
                w_indirizzo_localita,
                w_esclusione,
                w_riduzione,
                w_tipo_rendita_93,
                w_tipo_bene_93,
                w_riduzione_93,
                w_ab_principale,
                w_detrazione,
                w_rendita,
              w_num_contrib,
              w_progr_contrib
           from dual
          ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. H'||
                     ' ('||sql_errm||')');
       END;
       w_flag_immobili           := 0;
       w_progr_immobile_caricato := 0;
       w_cod_via                 := 0;
       w_num_civ                 := 0;
       w_suffisso                := '';
       w_numero_ordine           := w_numero_ordine + 1;
       w_oggetto_pratica         := w_oggetto_pratica + 1;
       BEGIN
         select '1',oggetto
           into w_flag_immobili,w_progr_immobile_caricato
           from oggetti
          where lpad(partita,8,'0') = lpad(w_partita,8,'0')
            and tipo_oggetto        = decode(w_area_fabbr_93,1,2,1)
         ;
       EXCEPTION
         WHEN no_data_found THEN
           null;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in controllo esistenza terreno'||
                     ' ('||sql_errm||')');
       END;
       IF w_flag_immobili = 0 THEN
          w_oggetto := w_oggetto + 1;
          BEGIN
             insert into oggetti (oggetto,tipo_oggetto,indirizzo_localita,
                                  partita,fonte,utente,data_variazione)
             values (w_oggetto,decode(w_area_fabbr_93,1,2,1),
                     w_indirizzo_localita,w_partita,
                     1,'ICI',to_date(sysdate))
            ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento terreno '||
                        ' ('||sql_errm||')');
          END;
       END IF;
       BEGIN
         insert into oggetti_pratica
               (oggetto_pratica,oggetto,pratica,anno,
                num_ordine,categoria_catasto,
                flag_provvisorio,
                valore,fonte,utente,data_variazione)
         values (w_oggetto_pratica,
                 decode(w_flag_immobili,1,w_progr_immobile_caricato,
                                          w_oggetto),
                 w_pratica,1992,w_numero_ordine,w_categoria,
                 decode(w_tipo_rendita_93,2,'S',''),
                 w_reddito_dominicale * decode(w_area_fabbr_93,1,1,75),
                 1,'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento oggetti_pratica (H) '||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into oggetti_contribuente
               (cod_fiscale,oggetto_pratica,
                anno,tipo_rapporto,
                perc_possesso,detrazione,flag_possesso,
                flag_esclusione,flag_riduzione,
                flag_ab_principale,utente,
                data_variazione)
         values (w_cod_fisc_dichiarante,w_oggetto_pratica,1992,'D',
                 w_perc_possesso,
                 w_detrazione,'S',w_esclusione,w_riduzione,w_ab_principale,
                 'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento oggetti_contribuente (H) '||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into oggetti_ici_93 (oggetto_pratica,tipo_rendita_93,tipo_bene_93,
                                     esenzione_93,riduzione_93,percentuale_93,
                                     conduzione_93,area_fabbr_93)
         values (w_oggetto_pratica,w_tipo_rendita_93,w_tipo_bene_93,
                 w_esenzione_93,w_riduzione_93,w_percentuale_93,
                 w_conduzione_93,w_area_fabbr_93)
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento oggetti_ici_93 (H) '||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_contit_fis>>
    IF rec_dic.tipo_record = 'L' THEN
       BEGIN
         select rtrim(substr(rec_dic.dati,1,16)),
                rtrim(substr(rec_dic.dati,18,24)),
                rtrim(substr(rec_dic.dati,42,20)),
                rtrim(substr(rec_dic.dati,96,5)) / 100,
                decode(substr(rec_dic.dati,101,1),'1','S',''),
                rtrim(substr(rec_dic.dati,68,1)),
                decode(translate(substr(rec_dic.dati,62,6),'1234567890',
                      '9999999999'),'999999',
                      substr(rec_dic.dati,66,2)||
                      substr(rec_dic.dati,64,2)||
                      substr(rec_dic.dati,62,2),''),
                rec_dic.num_contrib,rec_dic.progr_contrib
           into w_cod_fisc_contitolare,
                w_cognome_contitolare,
                w_nome_contitolare,
                w_perc_possesso,
                w_ab_principale,
                w_sesso_contitolare,
                w_data_nas_contitolare,
                w_num_contrib,
                w_progr_contrib
           from dual
          ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. L'||
                     ' ('||sql_errm||')');
       END;
       w_flag_nas      := 0;
       IF w_data_nas_contitolare is not null THEN
          BEGIN
            select 1
              into w_flag_nas
              from dual
             where (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '31'
                    and substr(lpad(w_data_nas_contitolare,6,0),3,2) in
                         ('02','04','06','09','11'))
                or (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '30'
                    and substr(lpad(w_data_nas_contitolare,6,0),3,2) = '02')
                or (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '29'
                    and substr(lpad(w_data_nas_contitolare,6,0),3,2) = '02'
                    and trunc(to_number(substr(
                               lpad(w_data_nas_contitolare,6,0),5,2)) / 4) * 4 !=
                              to_number(substr(lpad(w_data_nas_contitolare,6,0),5,2)))
                or (to_number(substr(lpad(w_data_nas_contitolare,6,0),1,2)) > 31)
                or (to_number(substr(lpad(w_data_nas_contitolare,6,0),1,2)) < 1)
                or (to_number(substr(lpad(w_data_nas_contitolare,6,0),3,2)) > 12)
                or (to_number(substr(lpad(w_data_nas_contitolare,6,0),3,2)) < 1)
                or (to_number(substr(lpad(w_data_nas_contitolare,6,0),5,2)) < 0)
             ;
          EXCEPTION
            WHEN no_data_found THEN
              null;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in controllo data nas. contitolare (L)'||
                        ' ('||sql_errm||')');
          END;
          BEGIN
            --select to_char(to_date(lpad(w_data_nas_contitolare,6,0),'ddmmyy'),'ddmmyyyy')
            select to_char(to_date(substr(lpad(w_data_nas_contitolare,6,0),1,4)||
                                   '19'||
                                   substr(lpad(w_data_nas_contitolare,6,0),5),
                           'ddmmyyyy'),'ddmmyyyy')
              into w_data_nas_contitolare
              from dual
             where w_flag_nas != 1
            ;
            RAISE no_data_found;
          EXCEPTION
            WHEN no_data_found THEN
              null;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in var. anno data nas. contitolare'||
                        ' data '||w_data_nas_contitolare||
                        ' cf '||w_cod_fisc_contitolare||
                        ' ('||sql_errm||')');
          END;
          BEGIN
            select substr(lpad(w_data_nas_contitolare,8,0),1,4)||
                   to_number(substr(lpad(w_data_nas_contitolare,8,0),5,4)) - 100
              into w_data_nas_contitolare
              from dual
             where w_flag_nas != 1
               and to_char(add_months(to_date(lpad(w_data_nas_contitolare,8,0),
                   'ddmmyyyy'),120),'j') > to_char(sysdate,'j')
          ;
            RAISE no_data_found;
          EXCEPTION
            WHEN no_data_found THEN
              null;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
               (-20999,'Errore in sottraz. secolo data nas. contitolare'||
                       ' data '||w_data_nas_contitolare||
                       ' cf '||w_cod_fisc_contitolare||
                       ' ('||sql_errm||')');
          END;
       END IF;
       w_flag_cont     := 0;
       BEGIN
         select 1
           into w_flag_cont
           from contribuenti cont
          where cont.cod_fiscale = w_cod_fisc_contitolare
         ;
         RAISE too_many_rows;
       EXCEPTION
         WHEN too_many_rows THEN
           null;
         WHEN no_data_found THEN
           BEGIN
             select max(sogg.ni),1
               into w_ni,w_flag_cont
               from soggetti sogg
              where sogg.cod_fiscale = w_cod_fisc_contitolare
             having max(sogg.ni) is not null
                ;
              RAISE too_many_rows;
           EXCEPTION
             WHEN too_many_rows THEN
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_contitolare,w_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento contrib. contit.'||
                             ' ('||sql_errm||')');
               END;
             WHEN no_data_found THEN
               w_max_ni        := w_max_ni + 1;
               w_flag_nas      := 0;
               IF w_data_nas_contitolare is not null THEN
                  BEGIN
                    select 1
                      into w_flag_nas
                      from dual
                     where (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '31'
                            and substr(lpad(w_data_nas_contitolare,6,0),3,2) in
                                 ('02','04','06','09','11'))
                        or (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '30'
                            and substr(lpad(w_data_nas_contitolare,6,0),3,2) = '02')
                        or (substr(lpad(w_data_nas_contitolare,6,0),1,2) = '29'
                            and substr(lpad(w_data_nas_contitolare,6,0),3,2) = '02'
                            and trunc(to_number(substr(
                                 lpad(w_data_nas_contitolare,6,0),5,2)) / 4) * 4 !=
                                to_number(substr(lpad(w_data_nas_contitolare,6,0),5,2)))
                        or (to_number(substr(lpad(w_data_nas_contitolare,6,0),1,2)) > 31)
                        or (to_number(substr(lpad(w_data_nas_contitolare,6,0),1,2)) < 1)
                        or (to_number(substr(lpad(w_data_nas_contitolare,6,0),3,2)) > 12)
                        or (to_number(substr(lpad(w_data_nas_contitolare,6,0),3,2)) < 1)
                        or (to_number(substr(lpad(w_data_nas_contitolare,6,0),5,2)) < 0)
                    ;
                  EXCEPTION
                    WHEN no_data_found THEN
                      null;
                    WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      RAISE_APPLICATION_ERROR
                        (-20999,'Errore in controllo data nas. contitolare'||
                                ' ('||sql_errm||')');
                  END;
                  BEGIN
                    --select to_char(to_date(lpad(w_data_nas_contitolare,6,0),
                    --       'ddmmyy'),'ddmmyyyy')
                    select to_char(to_date(substr(lpad(w_data_nas_contitolare,6,0),1,4)||
                                         '19'||
                                         substr(lpad(w_data_nas_contitolare,6,0),5),
                                 'ddmmyyyy'),'ddmmyyyy')
                      into w_data_nas_contitolare
                      from dual
                     where w_flag_nas != 1
                    ;
                    RAISE no_data_found;
                  EXCEPTION
                    WHEN no_data_found THEN
                      null;
                    WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      RAISE_APPLICATION_ERROR
                        (-20999,'Errore in var. anno data nas. contitolare'||
                                ' data '||w_data_nas_contitolare||
                                ' cf '||w_cod_fisc_contitolare||
                                ' ('||sql_errm||')');
                  END;
                  BEGIN
                    select substr(lpad(w_data_nas_contitolare,8,0),1,4)||
                            to_number(substr(lpad(w_data_nas_contitolare,8,0),5,4)) - 100
                      into w_data_nas_contitolare
                      from dual
                     where w_flag_nas != 1
                       and to_char(add_months(to_date(lpad(w_data_nas_contitolare,8,0),
                           'ddmmyyyy'),120),'j') > to_char(sysdate,'j')
                    ;
                    RAISE no_data_found;
                  EXCEPTION
                    WHEN no_data_found THEN
                      null;
                    WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      RAISE_APPLICATION_ERROR
                       (-20999,'Errore in sottraz. secolo data nas. contitolare'||
                               ' data '||w_data_nas_contitolare||
                               ' cf '||w_cod_fisc_contitolare||
                               ' ('||sql_errm||')');
                  END;
               END IF;
               BEGIN
                 insert into soggetti
                       (ni,tipo_residente,cod_fiscale,cognome_nome,
                        sesso,data_nas,partita_iva,
                        tipo,utente,data_variazione)
                 values (w_max_ni,1,
                         decode(length(w_cod_fisc_contitolare),16,
                                w_cod_fisc_contitolare,''),
                         nvl(substr(w_cognome_contitolare||
                             decode(w_nome_contitolare,'','','/'||
                                    w_nome_contitolare),1,40),
                             'DENOMINAZIONE ASSENTE'),
                         w_sesso_contitolare,
                         decode(w_data_nas_contitolare,'',to_date(''),
                            decode(w_flag_nas,1,to_date(''),
                               to_date(lpad(w_data_nas_contitolare,8,0),
                               'ddmmyyyy'))),
                         decode(length(w_cod_fisc_contitolare),11,
                            translate(w_cod_fisc_contitolare,'O','0'),''),
                         decode(length(w_cod_fisc_contitolare),
                                16,0,11,1,2),
                         'ICI',to_date(sysdate))
                  ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo soggetto contit.'||
                             ' ('||sql_errm||')');
               END;
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_contitolare,w_max_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo contribuente contit.'||
                             ' ('||sql_errm||')');
               END;
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca soggetti contit.'||
                         ' ('||sql_errm||')');
           END;
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in selezione contribuenti contit.'||
                    ' ('||sql_errm||')');
       END;
       BEGIN
         select 'x'
           into w_controllo
           from oggetti_contribuente ogco
          where ogco.cod_fiscale     = w_cod_fisc_contitolare
            and ogco.oggetto_pratica = w_oggetto_pratica
            and ogco.tipo_rapporto   = 'C'
         ;
         RAISE too_many_rows;
       EXCEPTION
         WHEN no_data_found THEN
           BEGIN
             insert into oggetti_contribuente
                   (cod_fiscale,oggetto_pratica,
                    anno,tipo_rapporto,
                    perc_possesso,flag_possesso,
                    flag_ab_principale,utente,
                    data_variazione)
             values (w_cod_fisc_contitolare,w_oggetto_pratica,1992,'C',
                     w_perc_possesso,
                     'S',w_ab_principale,'ICI',to_date(sysdate))
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento oggetti_contribuente (L) '||
                         'c.f.: '||w_cod_fisc_contitolare||' ogpr: '||w_oggetto_pratica||
                         'num./pr.contr: '||w_num_contrib||'/'||w_progr_contrib||
                         ' ('||sql_errm||')');
           END;
-- carica esattamente come fa adesso
         WHEN too_many_rows THEN
           w_oggetto_pratica         := w_oggetto_pratica + 1;
           BEGIN
             insert into oggetti_pratica
                   (oggetto_pratica,oggetto,pratica,anno,
                    num_ordine,categoria_catasto,
                    flag_provvisorio,
                    valore,fonte,utente,data_variazione)
             select w_oggetto_pratica,oggetto,pratica,anno,
                    num_ordine,categoria_catasto,
                    flag_provvisorio,
                    valore,fonte,utente,data_variazione
               from oggetti_pratica
              where oggetto_pratica = w_oggetto_pratica - 1
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ins. oggetto pratica contribuenti contit. (L) '||
                         ' ('||sql_errm||')');
           END;
           BEGIN
             insert into oggetti_contribuente
                   (cod_fiscale,oggetto_pratica,
                    anno,tipo_rapporto,
                    perc_possesso,flag_possesso,
                    flag_ab_principale,utente,
                    data_variazione)
             values (w_cod_fisc_contitolare,w_oggetto_pratica,1992,'C',
                     w_perc_possesso,
                     'S',w_ab_principale,'ICI',to_date(sysdate))
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento oggetti_contribuente (L) '||
                         'c.f.: '||w_cod_fisc_contitolare||' ogpr: '||w_oggetto_pratica||
                         'num./pr.contr: '||w_num_contrib||'/'||w_progr_contrib||
                         ' ('||sql_errm||')');
           END;
-- carica un altro oggetto_pratica, oggetto_contribuente,rapporto_trib.
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in controllo contribuenti contit. (L) '||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         select 'x'
           into w_controllo
           from rapporti_tributo ratr
          where ratr.pratica       = w_pratica
            and ratr.cod_fiscale   = w_cod_fisc_contitolare
            and ratr.tipo_rapporto = 'C'
          ;
       EXCEPTION
         WHEN no_data_found THEN
           BEGIN
             insert into rapporti_tributo (pratica,cod_fiscale,tipo_rapporto)
             values (w_pratica,w_cod_fisc_contitolare,'C')
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento rapporto tributo (cont.fis.)'||
                         ' ('||sql_errm||')');
           END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in verifica rapporto tributo (cont.fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_contit_non_fis>>
    IF rec_dic.tipo_record = 'M' THEN
       BEGIN
        select substr(rec_dic.dati,1,11),
               rtrim(substr(rec_dic.dati,13,40)),
               rtrim(substr(rec_dic.dati,73,5)) / 100,
               decode(substr(rec_dic.dati,78,1),'1','S',''),
               '',
               rec_dic.num_contrib,rec_dic.progr_contrib
          into w_cod_fisc_contitolare,
               w_cognome_contitolare,
               w_perc_possesso,
               w_ab_principale,
               w_sesso_contitolare,
               w_num_contrib,
               w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. M'||
                     ' ('||sql_errm||')');
       END;
       w_flag_cont     := 0;
       BEGIN
         select 1
           into w_flag_cont
           from contribuenti cont
          where cont.cod_fiscale = w_cod_fisc_contitolare
         ;
         RAISE too_many_rows;
       EXCEPTION
         WHEN too_many_rows THEN
           null;
         WHEN no_data_found THEN
           BEGIN
             select max(sogg.ni),1
               into w_ni,w_flag_cont
               from soggetti sogg
              where sogg.cod_fiscale = w_cod_fisc_contitolare
             having max(sogg.ni) is not null
             ;
             RAISE too_many_rows;
           EXCEPTION
             WHEN too_many_rows THEN
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_contitolare,w_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento contr.'||
                             ' cont. non fis.'||
                             ' ('||sql_errm||')');
               END;
             WHEN no_data_found THEN
               w_max_ni        := w_max_ni + 1;
               w_flag_nas      := 0;
               BEGIN
                 insert into soggetti
                            (ni,tipo_residente,cod_fiscale,cognome_nome,
                             sesso,partita_iva,tipo,utente,data_variazione)
                 values (w_max_ni,1,
                         decode(length(w_cod_fisc_contitolare),16,
                                w_cod_fisc_contitolare,''),
                         nvl(substr(w_cognome_contitolare||
                             decode(w_nome_contitolare,'','','/'||
                                    w_nome_contitolare),1,40),
                             'DENOMINAZIONE ASSENTE'),
                         w_sesso_contitolare,
                         decode(length(w_cod_fisc_contitolare),11,
                                translate(w_cod_fisc_contitolare,'O','0'),''),
                         decode(length(w_cod_fisc_contitolare),
                                16,0,11,1,2),
                         'ICI',to_date(sysdate))
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo soggetto'||
                             ' cont. non fis.'||
                             ' ('||sql_errm||')');
               END;
               BEGIN
                 insert into contribuenti (cod_fiscale,ni)
                 values (w_cod_fisc_contitolare,w_max_ni)
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in ins. nuovo contrib.'||
                             ' cont. non fis.'||
                             ' ('||sql_errm||')');
               END;
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca soggetti cont non fis.'||
                         ' ('||sql_errm||')');
           END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione contribuenti cont non fis.'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         insert into oggetti_contribuente
               (cod_fiscale,oggetto_pratica,
                anno,tipo_rapporto,
                perc_possesso,flag_possesso,
                flag_ab_principale,utente,
                data_variazione)
         values (w_cod_fisc_contitolare,w_oggetto_pratica,1992,'C',
                 w_perc_possesso,
                'S',w_ab_principale,'ICI',to_date(sysdate))
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in inserimento oggetti_contribuente (M) '||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         select 'x'
           into w_controllo
           from rapporti_tributo ratr
          where ratr.pratica       = w_pratica
            and ratr.cod_fiscale   = w_cod_fisc_contitolare
            and ratr.tipo_rapporto = 'C'
            ;
       EXCEPTION
         WHEN no_data_found THEN
           BEGIN
             insert into rapporti_tributo
                   (pratica,cod_fiscale,tipo_rapporto)
             values (w_pratica,w_cod_fisc_contitolare,'C')
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento rapporto tributo '||
                         '(cont. non fis.)'||
                         ' ('||sql_errm||')');
           END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in verifica rapporto tributo '||
                     '(cont. non fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_rappr_fis>>
    IF rec_dic.tipo_record = 'F' THEN
       BEGIN
         select rtrim(substr(rec_dic.dati,1,16)),
                rtrim(substr(rec_dic.dati,18,24))||
                decode(rtrim(substr(rec_dic.dati,18,24)),'','','/')||
                rtrim(substr(rec_dic.dati,42,20)),
                decode(substr(rec_dic.dati,96,1),
                       '1','RAPPRESENTANTE LEGALE',
                       '2','CURATORE FALLIMENTARE',
                       '3','RAPPR. DI SOC. SEDE EST.',
                       '4','LIQUIDATORE',
                       '5','CURAT. EREDITA'' GIACENTE',
                           substr(rec_dic.dati,96,1)),
                rec_dic.num_contrib,rec_dic.progr_contrib
           into w_cod_fisc_rappresentante,
                w_rappresentante,
                w_carica_rappresentante,
                w_num_contrib,
                w_progr_contrib
           from dual
          ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. F'||
                     ' ('||sql_errm||')');
       END;
       w_flag_tipo_carica := 0;
       BEGIN
         select tipo_carica,1
           into w_tipo_carica,w_flag_tipo_carica
           from tipi_carica tica
          where tica.descrizione = w_carica_rappresentante
         ;
       EXCEPTION
         WHEN no_data_found THEN
           w_max_tipo_carica := w_max_tipo_carica + 1;
           BEGIN
             insert into tipi_carica (tipo_carica,descrizione)
             values (w_max_tipo_carica,w_carica_rappresentante)
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento tipo carica'||
                         ' ('||sql_errm||')');
           END;
       END;
       BEGIN
         update pratiche_tributo
            set tipo_carica      = decode(w_flag_tipo_carica,1,w_tipo_carica,
                                          w_max_tipo_carica),
                 denunciante     = w_rappresentante,
                 cod_fiscale_den = decode(length(w_cod_fisc_rappresentante),
                                    16,w_cod_fisc_rappresentante,''),
                 partita_iva_den = decode(length(w_cod_fisc_rappresentante),
                                    11,translate(w_cod_fisc_rappresentante,'O','0'),'')
           where pratica = w_pratica
          ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in aggiornamento pratica '||
                     '(tipo carica pers. fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_rappr_non_fis>>
    IF rec_dic.tipo_record = 'W' THEN
       BEGIN
        select substr(rec_dic.dati,1,11),
               rtrim(substr(rec_dic.dati,13,60)),
               decode(substr(rec_dic.dati,97,1),
                      '1','RAPPRESENTANTE LEGALE',
                      '2','CURATORE FALLIMENTARE',
                      '3','RAPPR. DI SOC. SEDE EST.',
                      '4','LIQUIDATORE',
                      '5','CURAT. EREDITA'' GIACENTE',
                          substr(rec_dic.dati,97,1)),
               rec_dic.num_contrib,rec_dic.progr_contrib
          into w_cod_fisc_rappresentante,
               w_rappresentante,
               w_carica_rappresentante,
               w_num_contrib,
               w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. W'||
                     ' ('||sql_errm||')');
       END;
       w_flag_tipo_carica := 0;
       BEGIN
         select tipo_carica,1
           into w_tipo_carica,w_flag_tipo_carica
           from tipi_carica tica
          where tica.descrizione = w_carica_rappresentante
         ;
       EXCEPTION
         WHEN no_data_found THEN
           w_max_tipo_carica := w_max_tipo_carica + 1;
           BEGIN
             insert into tipi_carica (tipo_carica,descrizione)
             values (w_max_tipo_carica,w_carica_rappresentante)
             ;
           EXCEPTION
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento tipo carica'||
                         ' ('||sql_errm||')');
           END;
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in ricerca tipi carica '||
                     '('||sql_errm||')');
       END;
       BEGIN
         update pratiche_tributo
            set tipo_carica     = decode(w_flag_tipo_carica,1,w_tipo_carica,
                                    w_max_tipo_carica),
                denunciante     = w_rappresentante,
                cod_fiscale_den = decode(length(w_cod_fisc_rappresentante),
                                   16,w_cod_fisc_rappresentante,''),
                partita_iva_den = decode(length(w_cod_fisc_rappresentante),
                                   11,translate(w_cod_fisc_rappresentante,'O','0'),'')
          where pratica = w_pratica
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in aggiornamento pratica'||
                     ' (tipo carica pers. non fis.)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
<<rec_ind_rappr>>
    IF rec_dic.tipo_record = 'G' THEN
       BEGIN
        select rtrim(substr(rec_dic.dati,33,35)),
               rtrim(substr(rec_dic.dati,1,25)),
               rec_dic.num_contrib,rec_dic.progr_contrib
          into w_indir_rappresentante,
               w_comune_rappresentante,
               w_num_contrib,
               w_progr_contrib
          from dual
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in selezione tipo rec. G'||
                     ' ('||sql_errm||')');
       END;
       BEGIN
         w_cod_pro := '';
         w_cod_com := '';
         w_cap     := '';
         w_des     := w_comune_rappresentante;
         w_sigla   := '';
         w_catasto := '';
         OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
           FETCH ricerca_comuni INTO w_cod_pro,w_cod_com,w_cap;
         CLOSE ricerca_comuni;
 -- dbms_output.put_line ('3.pro :'||w_cod_pro||' com :'||w_cod_com||' cap :'||w_cap);
       END;
       BEGIN
         update pratiche_tributo
            set indirizzo_den = w_indir_rappresentante,
                cod_pro_den   = w_cod_pro,
                cod_com_den   = w_cod_com
          where pratica       = w_pratica
         ;
       EXCEPTION
         WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in aggiornamento pratica'||
                     ' (indirizzo rappresentante)'||
                     ' ('||sql_errm||')');
       END;
    END IF;
    w_dep_num_contrib := rec_dic.num_contrib;
  END LOOP;
-- dbms_output.put_line ('finito il loop');
  BEGIN
-- dbms_output.put_line ('controllo 1992');
    select 'x'
      into w_controllo
      from dual
     where exists (select 'x'
                     from pratiche_tributo
                    where tipo_tributo = 'ICI'
                      and anno         = 1992)
    ;
    RAISE too_many_rows;
  EXCEPTION
    WHEN no_data_found THEN
-- dbms_output.put_line ('no data found');
      null;
    WHEN too_many_rows THEN
-- dbms_output.put_line ('others');
      BEGIN
        select 'x'
          into w_controllo
          from sogei_dic
        having min(num_contrib) = max(num_contrib)
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN no_data_found THEN
          null;
        WHEN too_many_rows THEN
          BEGIN
            delete sogei_dic
            ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in svuotamento sogei_dic'||
                        ' ('||sql_errm||')');
          END;
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in controllo situazione sogei_dic'||
                    ' ('||sql_errm||')');
      END;
-- dbms_output.put_line ('prima di pulizia zeri');
      BEGIN
        update oggetti
           set sezione            = ltrim(sezione,'0'),
               foglio             = ltrim(foglio,'0'),
               numero             = ltrim(numero,'0'),
               subalterno         = ltrim(subalterno,'0'),
               zona               = ltrim(zona,'0'),
               partita            = ltrim(partita,'0'),
               progr_partita      = ltrim(progr_partita,'0'),
               protocollo_catasto = ltrim(protocollo_catasto,'0'),
               classe_catasto     = ltrim(classe_catasto,'0')
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione zeri non significativi (oggetti)'||
                    ' ('||sql_errm||')');
      END;
-- dbms_output.put_line ('dopo pulizia zeri');
      BEGIN
        update oggetti_contribuente
           set detrazione = ltrim(detrazione,'0')
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione zeri non significativi (ogco)'||
                    ' ('||sql_errm||')');
      END;
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in controllo esistenza anno 1992'||
                ' ('||sql_errm||')');
  END;
  -- (VD - 10/01/2020): a fine caricamento si archiviano tutte le denunce
  --                    inserite
  if w_min_pratica is not null and
     w_max_pratica is not null then
     for w_pratica in w_min_pratica..w_max_pratica
     loop
       archivia_denunce('','',w_pratica);
     end loop;
  end if;
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR
         (-20999,'Errore durante il caricamento dati SOGEI'||
                 ' progr. : '||w_progressivo_msg||
                 ' tipo record : '||w_tipo_record_msg||
                 ' num.contrib. : '||w_num_contrib_msg||
                 ' progr.contrib. : '||w_progr_contrib_msg||
                 --  ' w_des : '||w_des||
                 --  ' w_sigla : '||w_sigla||
                 --  ' w_catasto : '||w_catasto||
                 --  ' w_pro : '||w_cod_pro||
                 --  ' w_com : '||w_cod_com||
                 --  ' w_cap : '||w_cap||
                 --  ' ni : '||w_max_ni||
                 --       ' indir. : '||w_indirizzo_dichiarante||
                 --       ' com.dich. : '||w_comune_dichiarante||
                 --       ' w_inizio : '||w_inizio||
                 --       ' w_fine : '||w_fine||
                 --  ' w_cf_dich : '||w_cod_fisc_dichiarante||
                 --  ' w_cf_cont : '||w_cod_fisc_contitolare||
                 --       ' w_ogpr : '||w_oggetto_pratica||
                 ' ('||SQLERRM||')');
END;
/

