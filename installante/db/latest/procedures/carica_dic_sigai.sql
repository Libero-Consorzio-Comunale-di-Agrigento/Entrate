--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_dic_sigai stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DIC_SIGAI
(a_sezione_unica    IN      varchar2,
 a_anno_denuncia    IN      number,
 a_conv             IN      varchar2)
IS
w_progressivo        number;
w_elemento            number;
w_progressivo_record      number;
w_conta_anci            number;
w_num_mod            varchar2(10);
w_dati_rec3            varchar2(316);
w_dati_rec4            varchar2(437);
w_cod_fiscale         varchar2(16);
w_dep_cod_fiscale         varchar2(16)   := 'XXXXXXXXXXXXXXXX';
w_anno_denuncia         number;
CURSOR sel_int IS
       select saf.fiscale cod_fiscale,
--      presenta data_pres,
           decode(substr(saf.presenta,1,4),
            to_char(a_anno_denuncia),saf.presenta,NULL) data_pres,
              saf.cognome cognome,
              saf.nome nome,
         saf.sesso sesso,
         saf.data_nascita data_nas,
              saf.prv_nascita prov_nas,
              saf.comune_nascita com_nas,
         saf.comune_res com_res,
              saf.prv_res prov_res,
              saf.cap_res cap_res,
         saf.indirizzo_res ind_res,
              saf.fisc_denunc cod_fiscale_den,
              saf.denom_denunc denom_den,
              saf.dom_fisc_denunc domicilio_fisc_den,
              saf.cap_fisc_denunc cap_fisc_den,
              saf.com_fisc_denunc com_fisc_den,
              saf.prv_fisc_denunc prov_fisc_den,
              saf.carica_denunc carica,
              saf.tel_pref_dichiar prefisso,
              saf.tel_dichiarante telefono
         from sigai_ana_fis saf
--        where presenta = decode(a_anno_denuncia,1992,'1993-01-01',
--                                a_anno_denuncia||'-12-31')
        where exists (select 1
            from sigai_fabbricati
              where anno_fiscale = a_anno_denuncia
             and fiscale   = saf.fiscale
               union
             select 1
            from sigai_terreni
              where anno_fiscale = a_anno_denuncia
             and fiscale   = saf.fiscale)
          and saf.presenta is not null
    --      and saf.fiscale = 'BCCNTN44R18I452L'
        union
       select sag.fiscale,
--      presenta data_pres,
           decode(substr(sag.presenta,1,4),
            to_char(a_anno_denuncia),sag.presenta,NULL) data_pres,
         sag.ragione_soc,
         to_char(null),
         to_char(null),
              to_char(null),
         to_char(null),
         to_char(null),
         sag.comune_sede_leg,
         sag.prov_sede_leg,
              sag.cap_sede_leg,
         sag.ind_sede_leg,
         sag.fisc_denunc,
              sag.denom_denunc,
         sag.dom_fisc_denunc,
              sag.cap_fisc_denunc,
         sag.com_fisc_denunc,
              sag.prv_fisc_denunc,
         sag.carica_denunc,
              sag.tel_pref_dichiar,
         sag.tel_dichiarante
         from sigai_ana_giur sag
--        where presenta = decode(a_anno_denuncia,1992,'1993-01-01',
--                                a_anno_denuncia||'-12-31')
        where exists (select 1
            from sigai_fabbricati
              where anno_fiscale = a_anno_denuncia
             and fiscale   = sag.fiscale
               union
             select 1
            from sigai_terreni
              where anno_fiscale = a_anno_denuncia
             and fiscale   = sag.fiscale)
          and sag.presenta is not null
   --       and sag.fiscale = 'BCCNTN44R18I452L'
        order by 1
   ;
CURSOR sel_cont (w_cod_fiscale varchar2) IS
       select lpad(ltrim(scf.num_ord),3,'0')||'F' numero_ordine,
              scf.fisc_cont cod_fisc_contitolare,
              scf.perc_poss perc_possesso,
              decode(scf.abit_prin,'0','1','1','0') flag_ab_princ,
           decode(data_sit,
            '1993-01-01',to_number(ltrim(scf.impo_detraz_ab_pr,'0')) * 1000,
                     to_number(ltrim(scf.impo_detraz_ab_pr,'0'))) detrazione,
              decode(scf.flag_possesso,'0','1','1','0') flag_possesso,
           ltrim(scf.prog_mod,'0') numero_modello
         from sigai_cont_fabbricati scf
        where data_sit = decode(a_anno_denuncia,1992,'1993-01-01',
                                a_anno_denuncia||'-12-31')
          and fiscale        = w_cod_fiscale
        union
       select lpad(ltrim(sct.num_ordine),3,'0')||'T',
              sct.cf_contitolare,
              sct.per_q_poss,
           to_char(null),
           to_number(null),
           to_char(null),
           ltrim(sct.prog_mod,'0')
         from sigai_cont_terreni sct
        where data_sit = decode(a_anno_denuncia,1992,'1993-01-01',
                                a_anno_denuncia||'-12-31')
          and fiscale        = w_cod_fiscale
     order by 1
        ;
CURSOR sel_imm (w_cod_fiscale varchar2) IS
   select lpad(ltrim(st.num_ord_terr),3,'0')||'T' numero_ordine,
          decode(st.area_fab,1,'2','1') tipo_immobile,
              st.indirizzo,
          st.partita_cat partita,
          to_char(null) sezione,
          to_char(null) foglio,
          to_char(null) numero,
          to_char(null) subalterno,
          to_char(null) protocollo,
          to_number(null) anno_catasto,
          to_char(null) categoria,
          to_char(null) classe,
          to_char(null) imm_storico,
          decode(st.area_fab,
         0,to_number(st.redd_nom) * 75,
         1,to_number(st.redd_nom)) valore,
          to_char(null) provvisorio,
          st.per_poss perc_possesso,
          st.mesi_poss mesi_possesso,
          st.mesi_esc_esenzi mesi_esclusione,
          st.mesi_appl_ridu mesi_riduzione,
          to_number(null) detrazione,
          decode(st.possesso,'0','1','1','0') possesso,
          decode(st.esenzione,'0','1','1','0') esclusione,
          decode(st.riduzione,'0','1','1','0') riduzione,
          to_char(null) ab_principale,
          ltrim(st.prog_mod,'0') numero_modello
     from sigai_terreni st
--        where data_sit = decode(a_anno_denuncia,1992,'1993-01-01',
--                                a_anno_denuncia||'-12-31')
       where anno_fiscale    = a_anno_denuncia
         and fiscale        = w_cod_fiscale
   union
   select lpad(ltrim(sf.num_ord),3,'0')||'F',
          sf.caratteristica,
              sf.indirizzo,
          to_char(null),
          sf.sezione,
          ltrim(sf.foglio,'0') foglio,
          sf.numero,
          sf.subalterno,
          sf.protocollo,
          to_number(ltrim(sf.anno_de_acc,'0')),
          sf.cat_catastale,
          sf.classe,
          sf.imm_storico,
          decode(sf.caratteristica,
         4,to_number(sf.rendita),
         decode(sf.iden_rend_valore,
         0,to_number(sf.rendita),
         3,to_number(sf.rendita),
         decode(sf.cat_catastale,
                  'A10',to_number(sf.rendita) * 50,
                 'C01',to_number(sf.rendita) * 34,
                 decode(substr(sf.cat_catastale,1,1),
                'A',to_number(sf.rendita) * 100,
                'B',to_number(sf.rendita) * 100,
                'C',to_number(sf.rendita) * 100,
                'D',to_number(sf.rendita) * 50,
                    to_number(sf.rendita))))),
          sf.flag_val_prov,
          sf.perc_poss,
          sf.mesi_poss,
          sf.mesi_esc_esenzi,
          sf.mesi_appl_ridu,
          decode(anno_fiscale,
           1992,to_number(ltrim(sf.detraz_princ,'0') * 1000),
             to_number(ltrim(sf.detraz_princ,'0'))),
          decode(sf.possesso,'0','1','1','0'),
          decode(sf.escluso_esente,'0','1','1','0'),
          decode(sf.riduzione,'0','1','1','0'),
          decode(sf.abit_princ,'0','1','1','0'),
          sf.prog_mod
     from sigai_fabbricati sf
--        where data_sit = decode(a_anno_denuncia,1992,'1993-01-01',
--                                a_anno_denuncia||'-12-31')
       where anno_fiscale    = a_anno_denuncia
         and fiscale        = w_cod_fiscale
    order by 1
   ;
BEGIN
  BEGIN
    select count(*)
      into w_conta_anci
      from anci_var
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca ANCI_VAR '||
                         '('||SQLERRM||')');
  END;
 IF w_conta_anci = 0 THEN
  w_progressivo           := 0;
  w_elemento              := 0;
  w_progressivo_record    := 0;
<< frontespizio_2 >>
  BEGIN
    FOR rec_int IN sel_int LOOP
     IF w_dep_cod_fiscale != rec_int.cod_fiscale THEN
      w_cod_fiscale := rec_int.cod_fiscale;
dbms_output.put_line ('fronte - CF '||rec_int.cod_fiscale);
      w_progressivo       := w_progressivo + 1;
      w_progressivo_record := w_progressivo_record + 1;
dbms_output.put_line ('carica '||rec_int.carica);
        BEGIN
          insert into anci_var
                 (progressivo,tipo_record,numero_pacco,
                  progressivo_record,dati,dati_1,dati_2)
          values (w_progressivo,'2',1,w_progressivo_record,
            rpad(' ',17,' '),
                  decode(rec_int.data_pres,NULL,'      ',
             to_char(to_date(rec_int.data_pres,'yyyy-mm-dd'),'ddmmyy'))||
                  rpad(nvl(rec_int.cod_fiscale,' '),16)||
                  decode(rec_int.prefisso,'',rpad(' ',4),
                         lpad(rec_int.prefisso,4,'0'))||
                  decode(rec_int.telefono,'',rpad(' ',8),
                         lpad(rec_int.telefono,8,'0'))||
                  rpad(nvl(rec_int.cognome,' '),60)||
                  rpad(nvl(rec_int.nome,' '),20)||
                  decode(rec_int.data_nas,'',rpad(' ',6),
                   decode(substr(rec_int.data_nas,1,1),'0',rpad(' ',6),
                    decode(substr(rec_int.data_nas,6,2),'00',rpad(' ',6),
                     decode(substr(rec_int.data_nas,9,2),'00',rpad(' ',6),
                            to_char(to_date(rec_int.data_nas,'yyyy-mm-dd'),'ddmmyy')
                           )
                          )
                         )
                        )||
                  decode(rec_int.sesso,'',' ',rec_int.sesso)||
                  decode(rec_int.com_nas,'',rpad(' ',25),
                         rpad(rec_int.com_nas,25,' '))||
                  decode(rec_int.prov_nas,'',rpad(' ',2),
                         rpad(rec_int.prov_nas,2,' '))||
                  decode(rec_int.ind_res,'',rpad(' ',35),
                         rpad(rec_int.ind_res,35,' '))||
                  decode(rec_int.cap_res,'',rpad(' ',5),
                         lpad(rec_int.cap_res,5,'0'))||
                  decode(rec_int.com_res,'',rpad(' ',25),
                         rpad(rec_int.com_res,25,' '))||
                  decode(rec_int.prov_res,'',rpad(' ',2),
                         rpad(rec_int.prov_res,2,' ')),
                  rpad(nvl(rec_int.cod_fiscale_den,' '),16)||
                  decode(rec_int.carica,'',rpad(' ',25),
                         rpad(rec_int.carica,25,' '))||
                  decode(rec_int.denom_den,'',rpad(' ',60),
                         rpad(rec_int.denom_den,60,' '))||
                  decode(rec_int.domicilio_fisc_den,'',rpad(' ',35),
                         rpad(rec_int.domicilio_fisc_den,35,' '))||
                  decode(rec_int.cap_fisc_den,'',rpad(' ',5),
                         lpad(rec_int.cap_fisc_den,5,'0'))||
                  decode(rec_int.com_fisc_den,'',rpad(' ',25),
                         rpad(rec_int.com_fisc_den,25,' '))||
                  decode(rec_int.prov_fisc_den,'',rpad(' ',2),
                         rpad(rec_int.prov_fisc_den,2,' '))
                 )
          ;
        EXCEPTION
          WHEN others THEN
            RAISE_APPLICATION_ERROR
              (-20999,'Errore in inserimento tipo rec. 2 '||
                      'cod.fisc: '||rec_int.cod_fiscale||
                      ' progr: '||w_progressivo||
                      ' progr_rec: '||w_progressivo_record||
                      ' data_pres: '||rec_int.data_pres||
                      ' ('||SQLERRM||')');
        END;
<< contitolari_3 >>
        w_elemento   := 0;
        w_dati_rec3  := '';
        FOR rec_cont IN sel_cont (rec_int.cod_fiscale) LOOP
dbms_output.put_line ('contitolari');
          w_elemento := w_elemento + 1;
     IF w_elemento > 3 THEN
        w_dati_rec3 := rpad(w_dati_rec3,314,' ')||
                  lpad(nvl(rec_cont.numero_modello,' '),2,' ');
             w_progressivo      := w_progressivo + 1;
        BEGIN
               insert into anci_var
                      (progressivo,tipo_record,numero_pacco,
                       progressivo_record,dati,dati_1,dati_2)
               values (w_progressivo, '3', 1,
             w_progressivo_record,
             rpad(' ',17,' '),
             substr(w_dati_rec3,1,215),
             substr(w_dati_rec3,216))
          ;
        EXCEPTION
               WHEN others THEN
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in inserimento tipo rec. 3 '||
                            '('||SQLERRM||')');
        END;
        w_elemento  := 1;
        w_dati_rec3 := '';
     END IF;
     w_dati_rec3 := w_dati_rec3||
               lpad(nvl(rec_cont.numero_ordine,'0'),5,'0')||
               rpad(nvl(rec_cont.cod_fisc_contitolare,' '),16,' ')||
               rpad(' ',62,' ')||
               lpad(nvl(rec_cont.perc_possesso,'0'),5,'0')||
               '00'||
               lpad(nvl(to_char(rec_cont.detrazione),' '),6,' ')||
               '  '||
               nvl(rec_cont.flag_possesso,' ')||
               '  '||
               nvl(rec_cont.flag_ab_princ,' ')||
               '  ';
   w_num_mod := rec_cont.numero_modello;
        END LOOP;
        IF w_elemento > 0 THEN
      w_dati_rec3 := rpad(w_dati_rec3,314,' ')||
                     lpad(nvl(w_num_mod,' '),2,' ');
           w_progressivo    := w_progressivo + 1;
           BEGIN
             insert into anci_var
                    (progressivo,tipo_record,numero_pacco,
                     progressivo_record,dati,dati_1,dati_2)
             values (w_progressivo, '3', 1,
                     w_progressivo_record,
           rpad(' ',17,' '),
                     substr(w_dati_rec3,1,215),
                     substr(w_dati_rec3,216))
             ;
           EXCEPTION
             WHEN others THEN
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento tipo rec. 3 '||
                         '('||SQLERRM||')');
           END;
        END IF;
<< immobili_4 >>
        w_elemento   := 0;
        w_dati_rec4  := '';
        FOR rec_imm IN sel_imm (rec_int.cod_fiscale) LOOP
dbms_output.put_line ('immobili');
          w_elemento := w_elemento + 1;
     IF w_elemento > 3 THEN
        w_dati_rec4 := rpad(w_dati_rec4,435,' ')||
                  lpad(nvl(rec_imm.numero_modello,' '),2,' ');
          w_progressivo      := w_progressivo + 1;
        BEGIN
               insert into anci_var
                      (progressivo,tipo_record,numero_pacco,
                       progressivo_record,dati,dati_1,dati_2)
               values (w_progressivo, '4', 1,
             w_progressivo_record,
             rpad(' ',17,' '),
             substr(w_dati_rec4,1,215),
             substr(w_dati_rec4,216))
          ;
        EXCEPTION
               WHEN others THEN
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in inserimento tipo rec. 4 '||
                           ' progr: '||w_progressivo||
                           ' progr_rec: '||w_progressivo_record||
                            '('||SQLERRM||')');
        END;
        w_elemento  := 1;
        w_dati_rec4 := '';
     END IF;
dbms_output.put_line('imm - elemento '||w_elemento);
dbms_output.put_line('imm - num.ord. '||rec_imm.numero_ordine);
dbms_output.put_line('imm - tipo imm. '||rec_imm.tipo_immobile);
--dbms_output.put_line('imm - w_dati_rec4 - prima '||w_dati_rec4);
dbms_output.put_line('imm - len(w...)'||length(w_dati_rec4));
     w_dati_rec4 := nvl(w_dati_rec4,to_char(null))||
              lpad(nvl(rec_imm.numero_ordine,' '),5,' ')||
          rec_imm.tipo_immobile||
            rpad(nvl(rec_imm.indirizzo,' '),35,' ')||
          lpad(nvl(rec_imm.partita,' '),8,' ')||
          lpad(nvl(rec_imm.sezione,'0'),3,'0')||
          lpad(nvl(rec_imm.foglio,'0'),5,'0')||
          lpad(nvl(rec_imm.numero,'0'),5,'0')||
          lpad(nvl(rec_imm.subalterno,'0'),4,'0')||
          lpad(nvl(rec_imm.protocollo,' '),6,' ')||
          lpad(nvl(substr(rec_imm.anno_catasto,3,2),' '),2,' ')||
          rpad(nvl(rec_imm.categoria,' '),3,' ')||
          lpad(nvl(rec_imm.classe,' '),2,' ')||
            nvl(rec_imm.imm_storico,' ')||
          lpad(nvl(rec_imm.valore,'0'),13,'0')||
          nvl(rec_imm.provvisorio,' ')||
          lpad(nvl(rec_imm.perc_possesso,'0'),5,'0')||
          lpad(nvl(rec_imm.mesi_possesso,' '),2,' ')||
          lpad(nvl(rec_imm.mesi_esclusione,' '),2,' ')||
          lpad(nvl(rec_imm.mesi_riduzione,' '),2,' ')||
          lpad(nvl(rec_imm.detrazione,'0'),6,'0')||
          '  '||
          nvl(rec_imm.possesso,' ')||
          nvl(rec_imm.esclusione,' ')||
          nvl(rec_imm.riduzione,' ')||
          nvl(rec_imm.ab_principale,' ')||
          '   '||
          rpad(' ',25,' ');
dbms_output.put_line('imm - w_dati_rec4 - dopo');
--dbms_output.put_line('imm - w_dati_rec4 '||w_dati_rec4);
   w_num_mod := rec_imm.numero_modello;
        END LOOP;
        IF w_elemento > 0 THEN
      w_dati_rec4 := rpad(w_dati_rec4,435,' ')||
                     lpad(nvl(w_num_mod,' '),2,' ');
        w_progressivo    := w_progressivo + 1;
           BEGIN
             insert into anci_var
                    (progressivo,tipo_record,numero_pacco,
                     progressivo_record,dati,dati_1,dati_2)
             values (w_progressivo, '4', 1,
                     w_progressivo_record,
           rpad(' ',17,' '),
                     substr(w_dati_rec4,1,215),
                     substr(w_dati_rec4,216))
             ;
           EXCEPTION
             WHEN others THEN
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento tipo rec. 4 '||
                         ' progr: '||w_progressivo||
                         ' progr_rec: '||w_progressivo_record||
                         '('||SQLERRM||')');
           END;
        END IF;
     END IF;   --      IF w_dep_cod_fiscale != rec_int.cod_fiscale THEN
    END LOOP;
  END;
  BEGIN
    select count(*)
      into w_conta_anci
      from anci_var
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca ANCI_VAR '||
                         '('||SQLERRM||')');
  END;
-- COMMIT;
  IF w_conta_anci > 0 THEN
     w_anno_denuncia := a_anno_denuncia + 5000;
     CARICA_DIC_ANCI (a_sezione_unica,a_conv,w_anno_denuncia);
  END IF;
 ELSE
  RAISE_APPLICATION_ERROR
    (-20999,'Impossibile eseguire il caricamento. '||
            'ANCI_VAR non e'' vuota.');
 END IF;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in Caricamento dati SIGAI '||
          'CF: '||w_cod_fiscale||' '||
                         '('||SQLERRM||')');
END;
/* End Procedure: CARICA_DIC_SIGAI */
/

