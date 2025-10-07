--liquibase formatted sql 
--changeset abrandolini:20250326_152429_carica_dic_anci_pk stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE     CARICA_DIC_ANCI_PK IS
/*************************************************************************
  Rev.  Date         Author   Note
  01    07/10/2024   AB       #69780
                              Utilizzo delle procedure _NR per poter utilizzare le nuove sequence
*************************************************************************/
  PROCEDURE CARICA_DIC_ANCI(a_sezione_unica IN varchar2,
                            a_conv          IN varchar2,
                            a_anno_denuncia IN OUT number);

  PROCEDURE CARICA_ANCI_VAR(A_DOCUMENTO_ID IN NUMBER);
END CARICA_DIC_ANCI_PK;
/
CREATE OR REPLACE PACKAGE BODY     CARICA_DIC_ANCI_PK IS
procedure carica_dic_anci
(a_sezione_unica    IN      varchar2,
 a_conv             IN      varchar2,
 a_anno_denuncia    IN OUT  number)
is
fine                              exception;
sql_errm                          varchar2(100);
w_dati                            varchar2(17);
w_dati_1                          varchar2(215);
w_dati_2                          varchar2(242);
w_dati_3                          varchar2(10);
w_num_ord_contitolare             varchar2(5);
w_cod_fisc_contitolare            varchar2(16);
w_indirizzo_contitolare           varchar2(40);
w_comune_contitolare              varchar2(60);
w_provincia_contitolare           varchar2(2);
w_numero_ordine                   varchar2(5);
w_tipo_oggetto_cont               number;
w_immobile                        varchar2(2);
w_indirizzo_localita              varchar2(36);
w_cod_via                         number;
w_denom_ric                       varchar2(60);
w_indirizzo_localita_1            varchar2(36);
w_partita                         varchar2(8);
w_estremi_catasto                 varchar2(20);
w_sezione                         varchar2(3);
w_foglio                          varchar2(5);
w_numero                          varchar2(5);
w_subalterno                      varchar2(4);
w_protocollo_catasto              varchar2(6);
w_anno_catasto                    number;
w_categoria                       varchar2(3);
w_classe                          varchar2(2);
w_imm_storico                     varchar2(1);
w_valore                          number;
w_provvisorio                     varchar2(1);
w_perc_possesso                   number;
w_mesi_possesso                   number;
w_mesi_esclusione                 number;
w_mesi_riduzione                  number;
w_detrazione                      number;
w_mesi_aliquota_ridotta           number;
w_possesso                        varchar2(1);
w_esclusione                      varchar2(1);
w_riduzione                       varchar2(1);
w_ab_principale                   varchar2(1);
w_aliquota_ridotta                varchar2(1);
w_acquisto                        varchar2(1);
w_cessione                        varchar2(1);
w_estremi_titolo                  varchar2(25);
w_firma                           varchar2(1);
w_modello                         number;
w_max_tipo_carica                 number;
w_cod_pro                         number;
w_cod_com                         number;
w_cap                             number;
w_cod_pro_res                     number;
w_cod_com_res                     number;
w_cap_res                         number;
w_pratica                         number;
w_oggetto_pratica                 number;
w_oggetto_pratica_cont            number;
w_oggetto                         number;
w_ni                              number;
w_max_ni                          number;
w_data_presentazione              number;
w_cod_fisc_dichiarante            varchar2(16);
w_prefisso_tel                    varchar2(4);
w_numero_tel                      number;
w_cognome_dichiarante             varchar2(60);
w_nome_dichiarante                varchar2(20);
w_sesso_dichiarante               varchar2(1);
w_indirizzo_dichiarante           varchar2(40);
w_comune_dichiarante              varchar2(60);
w_cod_fisc_rappresentante         varchar2(16);
w_carica_rappresentante           varchar2(25);
w_rappresentante                  varchar2(60);
w_indir_rappresentante            varchar2(35);
w_comune_rappresentante           varchar2(60);
w_protocollo                      varchar2(8);
w_data_nas_dichiarante            number;
w_flag_nas                        number;
w_flag_pres                       number;
w_flag_tipo_carica                number;
w_flag_cont                       number;
w_flag_contitolare                number;
w_flag_dichiarante                number;
w_flag_err_immobili               number;
w_flag_esistenza                  number;
w_dep_numero_pacco                number;
w_dep_progressivo_record          number;
w_numero_pacco                    number;
w_progressivo_record              number;
w_com_nas_dichiarante             varchar2(25);
w_sigla_nas_dichiarante           varchar2(2);
w_sigla_res_dichiarante           varchar2(2);
w_sigla                           varchar2(3);
w_catasto                         varchar2(4);
w_note                            varchar2(300);
w_des                             varchar2(30);
w_tipo_carica                     number;
w_flag_immobili                   number;
w_progr_immobile_caricato         number;
w_num_civ                         number;
w_suffisso                        varchar2(5);
w_controllo                       varchar2(1);
w_num_seq                         number;
w_anno_denuncia                   number;
w_100                             number;
w_conv                            varchar2(1);
w_valuta                          varchar2(3);
w_min_pratica                     number;
w_max_pratica                     number;
CURSOR ricerca_comuni (w_descrizione        varchar2,
                       w_sigla_provincia    varchar2,
                       w_codice_catasto     varchar2) IS
       select com.provincia_stato,com.comune,com.cap
         from ad4_provincie pro,ad4_comuni com
        where pro.sigla         = nvl(w_sigla_provincia,pro.sigla)
          and pro.provincia     = com.provincia_stato
          and com.sigla_cfis    = nvl(w_codice_catasto,com.sigla_cfis)
          and com.denominazione     like w_descrizione||'%'
       ;
CURSOR sel_var IS
       select *
         from anci_var
          order by numero_pacco,progressivo_record,
               decode(tipo_record,3,9,4,8,2)
       ;
CURSOR sel_cont_94 IS
       select rtrim(substr(w_dati_1,1,1)),
              rtrim(substr(w_dati_1,2,16)),
              null,null,null,
              rtrim(substr(w_dati_1,18,5)) / 100,
              null,
              ltrim(rtrim(substr(w_dati_1,23,6)),'0'),
              null,
              decode(substr(w_dati_1,29,1),'0','S',''),
              null,null,
              decode(substr(w_dati_1,30,1),'0','S',''),
              null,
              decode(substr(w_dati_1,31,1),'1','S',''),
              rtrim(substr(w_dati_1,127,2)),
              1
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,2,16))))
--              in (11,16)
        union
       select rtrim(substr(w_dati_1,32,1)),
              rtrim(substr(w_dati_1,33,16)),
              null,null,null,
              rtrim(substr(w_dati_1,49,5)) / 100,
              null,
              ltrim(rtrim(substr(w_dati_1,54,6)),'0'),
              null,
              decode(substr(w_dati_1,60,1),'0','S',''),
              null,null,
              decode(substr(w_dati_1,61,1),'0','S',''),
              null,
              decode(substr(w_dati_1,62,1),'1','S',''),
              rtrim(substr(w_dati_1,127,2)),
              2
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,33,16))))
--              in (11,16)
        union
       select rtrim(substr(w_dati_1,63,1)),
              rtrim(substr(w_dati_1,64,16)),
              null,null,null,
              rtrim(substr(w_dati_1,80,5)) / 100,
              null,
              ltrim(rtrim(substr(w_dati_1,85,6)),'0'),
              null,
              decode(substr(w_dati_1,91,1),'0','S',''),
              null,null,
              decode(substr(w_dati_1,92,1),'0','S',''),
              null,
              decode(substr(w_dati_1,93,1),'1','S',''),
              rtrim(substr(w_dati_1,127,2)),
              3
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,64,16))))
--              in (11,16)
        union
       select rtrim(substr(w_dati_1,94,1)),
              rtrim(substr(w_dati_1,95,16)),
              null,null,null,
              rtrim(substr(w_dati_1,111,5)) / 100,
              null,
              ltrim(rtrim(substr(w_dati_1,116,6)),'0'),
              null,
              decode(substr(w_dati_1,122,1),'0','S',''),
              null,null,
              decode(substr(w_dati_1,123,1),'0','S',''),
              null,
              decode(substr(w_dati_1,124,1),'1','S',''),
              rtrim(substr(w_dati_1,127,2)),
              4
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,95,16))))
--              in (11,16)
     order by 17
       ;
CURSOR sel_cont_95 IS
       select ltrim(ltrim(rtrim(substr(w_dati_1,1,5))),'0'),
              rtrim(substr(w_dati_1,6,16)),
              rtrim(substr(w_dati_1,22,35)),
              rtrim(substr(w_dati_1,57,25)),
              rtrim(substr(w_dati_1,82,2)),
              rtrim(substr(w_dati_1,84,5)) / 100,
              rtrim(substr(w_dati_1,89,2)),
              ltrim(rtrim(substr(w_dati_1,91,6)),'0'),
              rtrim(substr(w_dati_1,97,2)),
              decode(substr(w_dati_1,99,1),'0','S',''),
              decode(substr(w_dati_1,100,1),'0','S',''),
              decode(substr(w_dati_1,101,1),'0','S',''),
              decode(substr(w_dati_1,102,1),'0','S',''),
              decode(substr(w_dati_1,103,1),'0','S',''),
              decode(substr(w_dati_1,104,1),'1','S',''),
              rtrim(substr(w_dati_2,98,2)),
              1
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,6,16))))
--              in (11,16)
        union
       select ltrim(ltrim(rtrim(substr(w_dati_1,105,5))),'0'),
              rtrim(substr(w_dati_1,110,16)),
              rtrim(substr(w_dati_1,126,35)),
              rtrim(substr(w_dati_1,161,25)),
              rtrim(substr(w_dati_1,186,2)),
              rtrim(substr(w_dati_1,188,5)) / 100,
              rtrim(substr(w_dati_1,193,2)),
              ltrim(rtrim(substr(w_dati_1,195,6)),'0'),
              rtrim(substr(w_dati_1,201,2)),
              decode(substr(w_dati_1,203,1),'0','S',''),
              decode(substr(w_dati_1,204,1),'0','S',''),
              decode(substr(w_dati_1,205,1),'0','S',''),
              decode(substr(w_dati_1,206,1),'0','S',''),
              decode(substr(w_dati_1,207,1),'0','S',''),
              decode(substr(w_dati_1,208,1),'1','S',''),
              rtrim(substr(w_dati_2,98,2)),
              2
         from dual
--        where length(ltrim(rtrim(substr(w_dati_1,110,16))))
--              in (11,16)
        union
       select ltrim(ltrim(rtrim(substr(w_dati_1,209,5))),'0'),
              rtrim(substr(w_dati_1,214,2)||substr(w_dati_2,1,14)),
              rtrim(substr(w_dati_2,15,35)),
              rtrim(substr(w_dati_2,50,25)),
              rtrim(substr(w_dati_2,75,2)),
              rtrim(substr(w_dati_2,77,5)) / 100,
              rtrim(substr(w_dati_2,82,2)),
              ltrim(rtrim(substr(w_dati_2,84,6)),'0'),
              rtrim(substr(w_dati_2,90,2)),
              decode(substr(w_dati_2,92,1),'0','S',''),
              decode(substr(w_dati_2,93,1),'0','S',''),
              decode(substr(w_dati_2,94,1),'0','S',''),
              decode(substr(w_dati_2,95,1),'0','S',''),
              decode(substr(w_dati_2,96,1),'0','S',''),
              decode(substr(w_dati_2,97,1),'1','S',''),
              rtrim(substr(w_dati_2,98,2)),
              3
         from dual
--        where length(rtrim(substr(w_dati_1,214,2)||substr(w_dati_2,1,14)))
--              in (11,16)
     order by 17
       ;
CURSOR sel_imm_94 IS
       select ltrim(ltrim(rtrim(substr(w_dati_1,1,3))),'0'),
              decode(rtrim(substr(w_dati_1,4,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_1,4,1))
                    ),
              rtrim(substr(w_dati_1,5,35)),
              ltrim(rtrim(substr(w_dati_1,40,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_1,48,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_1,51,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,56,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,61,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,65,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,71,2)),'0')),
              rtrim(substr(w_dati_1,73,1))||
               lpad(rtrim(substr(w_dati_1,74,2)),2,'0'),
--            rtrim(substr(w_dati_1,73,3)),
              rtrim(substr(w_dati_1,76,2)),
              decode(substr(w_dati_1,78,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_1,79,13))*1000,
              decode(substr(w_dati_1,92,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_1,93,5)) / 100,
              rtrim(substr(w_dati_1,98,2)),
              rtrim(substr(w_dati_1,100,2)),
              to_number(rtrim(substr(w_dati_1,102,2))),
              ltrim(rtrim(substr(w_dati_1,104,6)),'0'),
              null,
              decode(substr(w_dati_1,110,1),'0','S',to_char(null)),
              decode(substr(w_dati_1,111,1),'0','S',to_char(null)),
              decode(substr(w_dati_1,112,1),'0','S',to_char(null)),
              decode(substr(w_dati_1,113,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,242,1),'1','S',to_char(null)),
              null,null,null,null,
              rtrim(substr(w_dati_2,238,2)),
              1
         from dual
        union
       select ltrim(ltrim(rtrim(substr(w_dati_1,114,3))),'0'),
              decode(rtrim(substr(w_dati_1,117,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_1,117,1))
                    ),
              rtrim(substr(w_dati_1,118,35)),
              ltrim(rtrim(substr(w_dati_1,153,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_1,161,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_1,164,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,169,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,174,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,178,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,184,2)),'0')),
              rtrim(substr(w_dati_1,186,1))||
               lpad(rtrim(substr(w_dati_1,187,2)),2,'0'),
--            rtrim(substr(w_dati_1,186,3)),
              rtrim(substr(w_dati_1,189,2)),
              decode(substr(w_dati_1,191,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_1,192,13))*1000,
              decode(substr(w_dati_1,205,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_1,206,5)) / 100,
              rtrim(substr(w_dati_1,211,2)),
              rtrim(substr(w_dati_1,213,2)),
              to_number(rtrim(substr(w_dati_1,215,1))||
                rtrim(substr(w_dati_2,1,1))),
              ltrim(rtrim(substr(w_dati_2,2,6)),'0'),
              null,
              decode(substr(w_dati_2,8,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,9,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,10,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,11,1),'0','S',to_char(null)),
              null,null,null,null,null,
              rtrim(substr(w_dati_2,238,2)),
              2
         from dual
        where rtrim(substr(w_dati_1,117,1)) is not null
        union
       select ltrim(ltrim(rtrim(substr(w_dati_2,12,3))),'0'),
              decode(rtrim(substr(w_dati_2,15,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_2,15,1))
                    ),
              rtrim(substr(w_dati_2,16,35)),
              ltrim(rtrim(substr(w_dati_2,51,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_2,59,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_2,62,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,67,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,72,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,76,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,82,2)),'0')),
              rtrim(substr(w_dati_2,84,1))||
               lpad(rtrim(substr(w_dati_2,85,2)),2,'0'),
--            rtrim(substr(w_dati_2,84,3)),
              rtrim(substr(w_dati_2,87,2)),
              decode(substr(w_dati_2,89,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_2,90,13))*1000,
              decode(substr(w_dati_2,103,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_2,104,5)) / 100,
              rtrim(substr(w_dati_2,109,2)),
              rtrim(substr(w_dati_2,111,2)),
              to_number(rtrim(substr(w_dati_2,113,2))),
              ltrim(rtrim(substr(w_dati_2,115,6)),'0'),
              null,
              decode(substr(w_dati_2,121,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,122,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,123,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,124,1),'0','S',to_char(null)),
              null,null,null,null,null,
              rtrim(substr(w_dati_2,238,2)),
              3
         from dual
        where rtrim(substr(w_dati_2,15,1)) is not null
        union
       select ltrim(ltrim(rtrim(substr(w_dati_2,125,3))),'0'),
              decode(rtrim(substr(w_dati_2,128,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_2,128,1))
                    ),
              rtrim(substr(w_dati_2,129,35)),
              ltrim(rtrim(substr(w_dati_2,164,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_2,172,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_2,175,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,180,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,185,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,189,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,195,2)),'0')),
              rtrim(substr(w_dati_2,197,1))||
               lpad(rtrim(substr(w_dati_2,198,2)),2,'0'),
--            rtrim(substr(w_dati_2,197,3)),
              rtrim(substr(w_dati_2,200,2)),
              decode(substr(w_dati_2,202,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_2,203,13))*1000,
              decode(substr(w_dati_2,216,1),'1','S',to_char(null)),
              rtrim(substr(w_dati_2,217,5)) / 100,
              rtrim(substr(w_dati_2,222,2)),
              rtrim(substr(w_dati_2,224,2)),
              to_number(rtrim(substr(w_dati_2,226,2))),
              ltrim(rtrim(substr(w_dati_2,228,6)),'0'),
              null,
              decode(substr(w_dati_2,234,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,235,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,236,1),'0','S',to_char(null)),
              decode(substr(w_dati_2,237,1),'0','S',to_char(null)),
              null,null,null,null,null,
              rtrim(substr(w_dati_2,238,2)),
              4
         from dual
        where rtrim(substr(w_dati_2,128,1)) is not null
     order by 32
       ;
CURSOR sel_imm_95 IS
       select ltrim(ltrim(rtrim(substr(w_dati_1,1,5))),'0'),
              decode(rtrim(substr(w_dati_1,6,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_1,6,1))
                    ),
              rtrim(substr(w_dati_1,7,35)),
              ltrim(rtrim(substr(w_dati_1,42,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_1,50,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_1,53,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,58,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,63,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,67,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,73,2)),'0')),
              rtrim(substr(w_dati_1,75,1))||
               lpad(rtrim(substr(w_dati_1,76,2)),2,0),
--            rtrim(substr(w_dati_1,75,3)),
              rtrim(substr(w_dati_1,78,2)),
              decode(substr(w_dati_1,80,1),'1','S',''),
              rtrim(substr(w_dati_1,81,13)),
              decode(substr(w_dati_1,94,1),'1','S',''),
              rtrim(substr(w_dati_1,95,5)) / 100,
              rtrim(substr(w_dati_1,100,2)),
              rtrim(substr(w_dati_1,102,2)),
              rtrim(substr(w_dati_1,104,2)),
              ltrim(rtrim(substr(w_dati_1,106,6)),'0'),
              rtrim(substr(w_dati_1,112,2)),
              decode(substr(w_dati_1,114,1),'0','S',''),
              decode(substr(w_dati_1,115,1),'0','S',''),
              decode(substr(w_dati_1,116,1),'0','S',''),
              decode(substr(w_dati_1,117,1),'0','S',''),
              decode(substr(w_dati_1,118,1),'0','S',''),
              decode(substr(w_dati_1,119,1),'0','S',''),
              decode(substr(w_dati_1,120,1),'0','S',''),
              rtrim(substr(w_dati_1,121,25)),
              decode(substr(w_dati_2,225,1),'1','S',''),
              rtrim(substr(w_dati_2,221,2)),
              1
         from dual
        union
       select ltrim(ltrim(rtrim(substr(w_dati_1,146,5))),'0'),
              decode(rtrim(substr(w_dati_1,151,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_1,151,1))
                    ),
              rtrim(substr(w_dati_1,152,35)),
              ltrim(rtrim(substr(w_dati_1,187,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_1,195,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_1,198,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,203,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,208,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_1,212,4)||substr(w_dati_2,1,2)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,3,2)),'0')),
              rtrim(substr(w_dati_2,5,1))||
               lpad(rtrim(substr(w_dati_2,6,2)),2,0),
--            rtrim(substr(w_dati_2,5,3)),
              rtrim(substr(w_dati_2,8,2)),
              decode(substr(w_dati_2,10,1),'1','S',''),
              rtrim(substr(w_dati_2,11,13)),
              decode(substr(w_dati_2,24,1),'1','S',''),
              rtrim(substr(w_dati_2,25,5)) / 100,
              rtrim(substr(w_dati_2,30,2)),
              rtrim(substr(w_dati_2,32,2)),
              rtrim(substr(w_dati_2,34,2)),
              ltrim(rtrim(substr(w_dati_2,36,6)),'0'),
              rtrim(substr(w_dati_2,42,2)),
              decode(substr(w_dati_2,44,1),'0','S',''),
              decode(substr(w_dati_2,45,1),'0','S',''),
              decode(substr(w_dati_2,46,1),'0','S',''),
              decode(substr(w_dati_2,47,1),'0','S',''),
              decode(substr(w_dati_2,48,1),'0','S',''),
              decode(substr(w_dati_2,49,1),'0','S',''),
              decode(substr(w_dati_2,50,1),'0','S',''),
              rtrim(substr(w_dati_2,51,25)),
              decode(substr(w_dati_2,225,1),'1','S',''),
              rtrim(substr(w_dati_2,221,2)),
              2
         from dual
        where rtrim(substr(w_dati_1,151,1)) is not null
        union
       select ltrim(ltrim(rtrim(substr(w_dati_2,76,5))),'0'),
              decode(rtrim(substr(w_dati_2,81,1))
                    ,'5','55'
                    ,rtrim(substr(w_dati_2,81,1))
                    ),
              rtrim(substr(w_dati_2,82,35)),
              ltrim(rtrim(substr(w_dati_2,117,8))),
              decode(a_sezione_unica,'S','',
               ltrim(ltrim(rtrim(substr(w_dati_2,125,3)),'0'))),
              ltrim(ltrim(rtrim(substr(w_dati_2,128,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,133,5)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,138,4)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,142,6)),'0')),
              ltrim(ltrim(rtrim(substr(w_dati_2,148,2)),'0')),
              rtrim(substr(w_dati_2,150,1))||
               lpad(rtrim(substr(w_dati_2,151,2)),2,0),
--            rtrim(substr(w_dati_2,150,3)),
              rtrim(substr(w_dati_2,153,2)),
              decode(substr(w_dati_2,155,1),'1','S',''),
              rtrim(substr(w_dati_2,156,13)),
              decode(substr(w_dati_2,169,1),'1','S',''),
              rtrim(substr(w_dati_2,170,5)) / 100,
              rtrim(substr(w_dati_2,175,2)),
              rtrim(substr(w_dati_2,177,2)),
              rtrim(substr(w_dati_2,179,2)),
              ltrim(rtrim(substr(w_dati_2,181,6)),'0'),
              rtrim(substr(w_dati_2,187,2)),
              decode(substr(w_dati_2,189,1),'0','S',''),
              decode(substr(w_dati_2,190,1),'0','S',''),
              decode(substr(w_dati_2,191,1),'0','S',''),
              decode(substr(w_dati_2,192,1),'0','S',''),
              decode(substr(w_dati_2,193,1),'0','S',''),
              decode(substr(w_dati_2,194,1),'0','S',''),
              decode(substr(w_dati_2,195,1),'0','S',''),
              rtrim(substr(w_dati_2,196,25)),
              decode(substr(w_dati_2,225,1),'1','S',''),
              rtrim(substr(w_dati_2,221,2)),
              3
         from dual
        where rtrim(substr(w_dati_2,81,1)) is not null
     order by 32
       ;
BEGIN
  BEGIN
     select decode(fase_euro,1,1,100)
       into w_100
       from dati_generali
     ;
  EXCEPTION
    WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Dati Generali Assenti');
  END;
  w_anno_denuncia := a_anno_denuncia;
--
-- in caso di a_anno_denuncia > 5000
-- si proviene da CARICA_DIC_SIGAI
--
  IF a_anno_denuncia > 5000 THEN
     a_anno_denuncia := a_anno_denuncia - 5000;
  END IF;
--
-- Il parametro di input a_conv indica, se = S, che si e` in valuta euro
-- ma coi dati in lire, per cui e` necessario convertire i valori.
-- Il paragrafo precedente si occupa di queste operazioni.
-- Si utilizza dati_3 come flag di conversione; se nullo, non e` ancora
-- stato trattato, viceversa e` gia` convertito.
-- Nel caso in cui la valuta sia indicata nel file devo utilizzare quella indicata
-- senza tenere conto del parametro di input s_conv, quindi controllo il primo record
-- di tipo 4 (immobili), se i dati sono in lire (e indicato 'LIT')
-- metto la variabile w_conv = 'S'  se  i dati sono in euro (e indicato 'EUR')
-- metto la variabile w_conv = 'N''se non trovo l'indicazione della valuta nel file
-- lascio tutto come era metto w_conv uguale al parametro di ingresso a_conv
-- nel caso in cui siano stati caricati file con diverse valute o file senza valuta
-- e file con valuta, non posso sapere che valuta utilizzare quindi
-- segnalo il problema ed e esco
  IF a_anno_denuncia > 1994 then
     BEGIN
       select distinct nvl(substr(dati_2,226,3),'NUL')
         into w_valuta
         from anci_var
        where tipo_record = 4
          and nvl(substr(dati_2,226,3),'NUL') in ('LIT','EUR','NUL')
       ;
     EXCEPTION
       WHEN no_data_found THEN
         w_valuta:= 'LIT';
       WHEN too_many_rows THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR
           (-20999,'Errore: caricati file con valute diverse,annullare l`import e ripeterlo');
       WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca valuta');
     END;
  else
     w_valuta:= 'LIT';
  END IF;
  if w_valuta = 'LIT' then
     w_conv := 'S';
  else if w_valuta = 'EUR' then
          w_conv := 'N';
      else
          w_conv := a_conv;
      end if;
  end if;
  if w_conv = 'S' then
     if w_anno_denuncia <= 1994 then
        update anci_var
           set dati_1 = substr(dati_1,1,78)||
                        lpad(to_char(round(to_number(substr(dati_1,79,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_1,92)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,79,13),'             ') <> '             '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,103)||
                        lpad(to_char(round(to_number(substr(dati_1,104,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,110)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,104,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,191)||
                        lpad(to_char(round(to_number(substr(dati_1,192,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_1,205)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,192,13),'             ') <> '             '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,1)||
                        lpad(to_char(round(to_number(substr(dati_2,2,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,8)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,2,6),'      ') <> '      '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,89)||
                        lpad(to_char(round(to_number(substr(dati_2,90,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_2,103)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,90,13),'             ') <> '             '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,114)||
                        lpad(to_char(round(to_number(substr(dati_2,115,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,121)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,115,6),'      ') <> '      '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,202)||
                        lpad(to_char(round(to_number(substr(dati_2,203,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_2,216)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,203,13),'             ') <> '             '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,227)||
                        lpad(to_char(round(to_number(substr(dati_2,228,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,234)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,228,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,22)||
                        lpad(to_char(round(to_number(substr(dati_1,23,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,29)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,23,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,53)||
                        lpad(to_char(round(to_number(substr(dati_1,54,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,60)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,54,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,84)||
                        lpad(to_char(round(to_number(substr(dati_1,85,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,91)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,85,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,115)||
                        lpad(to_char(round(to_number(substr(dati_1,116,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,122)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,116,6),'      ') <> '      '
        ;
     else
        update anci_var
           set dati_1 = substr(dati_1,1,80)||
                        lpad(to_char(round(to_number(substr(dati_1,81,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_1,94)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,81,13),'             ') <> '             '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,105)||
                        lpad(to_char(round(to_number(substr(dati_1,106,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,112)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,106,6),'      ') <> '      '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,10)||
                        lpad(to_char(round(to_number(substr(dati_2,11,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_2,24)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,11,13),'             ') <> '             '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,35)||
                        lpad(to_char(round(to_number(substr(dati_2,36,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,42)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,36,6),'      ') <> '      '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,155)||
                        lpad(to_char(round(to_number(substr(dati_2,156,13)) / 1936.27 , 2) * 100),13,'0')||
                        substr(dati_2,169)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,156,13),'             ') <> '             '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,180)||
                        lpad(to_char(round(to_number(substr(dati_2,181,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,187)
         where tipo_record    = 4
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,181,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,90)||
                        lpad(to_char(round(to_number(substr(dati_1,91,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,97)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,91,6),'      ') <> '      '
        ;
        update anci_var
           set dati_1 = substr(dati_1,1,194)||
                        lpad(to_char(round(to_number(substr(dati_1,195,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_1,201)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_1,195,6),'      ') <> '      '
        ;
        update anci_var
           set dati_2 = substr(dati_2,1,83)||
                        lpad(to_char(round(to_number(substr(dati_2,84,6)) / 1936.27 , 2) * 100),6,'0')||
                        substr(dati_2,90)
         where tipo_record    = 3
           and nvl(dati_3,' ') <> 'Convertito'
           and nvl(substr(dati_2,84,6),'      ') <> '      '
        ;
     end if;
     update anci_var
        set dati_3 = 'Convertito'
      where tipo_record in (3,4)
        and nvl(dati_3,' ') <> 'Convertito'
     ;
     COMMIT;
  end if;
  BEGIN
    select nvl(max(pratica),0)
      into w_pratica
      from pratiche_tributo
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      ROLLBACK;
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
      ROLLBACK;
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
      ROLLBACK;
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
      ROLLBACK;
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
      ROLLBACK;
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca tipi carica'||
                ' ('||sql_errm||')');
  END;
  BEGIN
    select 'x'
      into w_controllo
      from anomalie_anno
     where tipo_anomalia      = 10
       and anno               = a_anno_denuncia
       and data_elaborazione != trunc(sysdate)
    ;
    RAISE too_many_rows;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN too_many_rows THEN
      BEGIN
        delete anomalie_ici
         where anno          = a_anno_denuncia
           and tipo_anomalia = 10
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie ici '||
                    ' ('||sql_errm||')');
      END;
      BEGIN
        delete anomalie_anno
         where tipo_anomalia = 10
           and anno          = a_anno_denuncia
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie anno '||
                    ' ('||sql_errm||')');
      END;
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      ROLLBACK;
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in verifica esistenza anomalia anno '||
                ' ('||sql_errm||')');
  END;
  BEGIN
    select 'x'
      into w_controllo
      from anomalie_anno
     where tipo_anomalia      = 11
       and anno               = a_anno_denuncia
       and data_elaborazione != trunc(sysdate)
    ;
    RAISE too_many_rows;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN too_many_rows THEN
      BEGIN
        delete anomalie_ici
         where anno          = a_anno_denuncia
           and tipo_anomalia = 11
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie ici (11) '||
                    ' ('||sql_errm||')');
      END;
      BEGIN
        delete anomalie_anno
         where tipo_anomalia = 11
           and anno          = a_anno_denuncia
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie anno (11)'||
                    ' ('||sql_errm||')');
      END;
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      ROLLBACK;
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in verifica esistenza anomalia anno (11)'||
                ' ('||sql_errm||')');
  END;
  BEGIN
    select 'x'
      into w_controllo
      from anomalie_anno
     where tipo_anomalia      = 21
       and anno               = a_anno_denuncia
       and data_elaborazione != trunc(sysdate)
    ;
    RAISE too_many_rows;
  EXCEPTION
    WHEN no_data_found THEN
      null;
    WHEN too_many_rows THEN
      BEGIN
        delete anomalie_ici
         where anno          = a_anno_denuncia
           and tipo_anomalia = 21
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie ici (21) '||
                    ' ('||sql_errm||')');
      END;
      BEGIN
        delete anomalie_anno
         where tipo_anomalia = 21
           and anno          = a_anno_denuncia
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione anomalie anno (21) '||
                    ' ('||sql_errm||')');
      END;
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      ROLLBACK;
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in verifica esistenza anomalia anno (21) '||
                ' ('||sql_errm||')');
  END;
  w_dep_numero_pacco       := 0;
  w_dep_progressivo_record := 0;
  FOR rec_var IN sel_var LOOP
    w_dati               := rec_var.dati;
    w_dati_1             := rec_var.dati_1;
    w_dati_2             := rec_var.dati_2;
    w_dati_3             := rec_var.dati_3;
    w_numero_pacco       := rec_var.numero_pacco;
    w_progressivo_record := rec_var.progressivo_record;
<<frontespizio>>
    IF rec_var.tipo_record = '2' THEN
    -- dbms_output.put_line ('inizio trattamento pratica :'||w_pratica);
      BEGIN
        select decode(
                 translate(substr(w_dati_1,1,6),'1234567890','9999999999'),
                   '999999',ltrim(rtrim(substr(w_dati_1,1,6)),'0'),to_number(null)),
               rtrim(substr(w_dati_1,7,16)),
               decode(ltrim(substr(w_dati_1,23,4)),null,to_char(null),
                      ltrim(substr(w_dati_1,23,4))),
               rtrim(decode(ltrim(substr(w_dati_1,27,8)),null,to_number(null),
                     to_number(ltrim(substr(w_dati_1,27,8))))),
               rtrim(substr(w_dati_1,35,60)),
               rtrim(substr(w_dati_1,95,20)),
               substr(w_dati_1,121,1),
               rtrim(substr(w_dati_1,149,35)),
               decode(rtrim(substr(w_dati_1,189,25)),null,to_char(null),
                      rtrim(substr(w_dati_1,189,25))),
               rtrim(substr(w_dati_2,1,16)),
               rtrim(substr(w_dati_2,17,25)),
               rtrim(substr(w_dati_2,42,60)),
               rtrim(substr(w_dati_2,102,35)),
               decode(rtrim(substr(w_dati_2,142,25)),null,to_char(null),
                      rtrim(substr(w_dati_2,142,25))),
               rtrim(substr(w_dati,10,8)),
               decode(
                 translate(substr(w_dati_1,115,6),'1234567890','9999999999'),
                   '999999',ltrim(rtrim(substr(w_dati_1,115,6)),'0'),to_number(null)),
               rtrim(substr(w_dati_1,122,25)),
               rtrim(substr(w_dati_1,147,2)),
               rtrim(substr(w_dati_1,214,2))
          into w_data_presentazione,
               w_cod_fisc_dichiarante,
               w_prefisso_tel,
               w_numero_tel,
               w_cognome_dichiarante,
               w_nome_dichiarante,
               w_sesso_dichiarante,
               w_indirizzo_dichiarante,
               w_comune_dichiarante,
               w_cod_fisc_rappresentante,
               w_carica_rappresentante,
               w_rappresentante,
               w_indir_rappresentante,
               w_comune_rappresentante,
               w_protocollo,
               w_data_nas_dichiarante,
               w_com_nas_dichiarante,
               w_sigla_nas_dichiarante,
               w_sigla_res_dichiarante
          from dual
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in selezione tipo rec. 2'||
                    ' CF '||rtrim(substr(w_dati_1,7,16))||
                    ' ('||sql_errm||')');
      END;
      BEGIN
        delete anci_var
         where numero_pacco              = w_dep_numero_pacco
           and progressivo_record        = w_dep_progressivo_record
           and w_dep_progressivo_record != 0
        ;
      EXCEPTION
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in eliminazione dichiarazione da anci_var '||
                    ' ('||sql_errm||')');
      END;
      COMMIT;
--      w_pratica          := w_pratica + 1;

      w_pratica            := NULL;  --Nr della pratica
      pratiche_tributo_nr(w_pratica); --Assegnazione Numero Progressivo

      w_numero_ordine    := 000;
      w_flag_cont        := 0;
      w_flag_esistenza   := 0;
      w_flag_dichiarante := 0;
      w_note             := '';
      w_flag_pres        := 0;
      IF ltrim(rtrim(w_data_presentazione),'0') is not null THEN
        BEGIN
          select 1
            into w_flag_pres
            from dual
           where (substr(lpad(w_data_presentazione,6,0),1,2) = '31' and
                  substr(lpad(w_data_presentazione,6,0),3,2) in
                  ('02','04','06','09','11'))
              or (substr(lpad(w_data_presentazione,6,0),1,2) = '30' and
                  substr(lpad(w_data_presentazione,6,0),3,2) = '02')
              or (substr(lpad(w_data_presentazione,6,0),1,2) = '29' and
                  substr(lpad(w_data_presentazione,6,0),3,2) = '02' and
                  trunc(to_number(substr(
                    lpad(w_data_presentazione,6,0),5,2)) / 4) * 4 !=
                    to_number(substr(lpad(w_data_presentazione,6,0),5,2)))
              or (to_number(substr(lpad(w_data_presentazione,6,0),1,2)) > 31)
              or (to_number(substr(lpad(w_data_presentazione,6,0),1,2)) < 1)
              or (to_number(substr(lpad(w_data_presentazione,6,0),3,2)) > 12)
              or (to_number(substr(lpad(w_data_presentazione,6,0),3,2)) < 1)
          ;
        EXCEPTION
          WHEN no_data_found THEN
            null;
          WHEN others THEN
           sql_errm  := substr(SQLERRM,1,100);
           ROLLBACK;
           RAISE_APPLICATION_ERROR
           (-20999,'Errore in controllo data presentazione'||
           ' data '||w_data_presentazione||
           ' cf '||w_cod_fisc_dichiarante||
            ' ('||sql_errm||')');
        END;
      END IF;
      BEGIN
        select 1
          into w_flag_esistenza
          from pratiche_tributo prtr
         where prtr.cod_fiscale        = w_cod_fisc_dichiarante
           and prtr.tipo_tributo||''   = 'ICI'
           and prtr.anno + 0           = a_anno_denuncia
           and prtr.tipo_pratica       = 'D'
           and prtr.tipo_evento        = 'I'
--
-- Modifica del 25/03/2004 per permettere di caricare Denunce in rettifica
-- o comunque presentate in momenti diversi che altrimenti andrebbero perdute.
-- La decode utilizzata per il controllo e` la stessa utilizzata per inserire
-- la data nella pratica tributo.
--
           and nvl(prtr.data,to_date('01011900','ddmmyyyy'))
                                       =
               nvl(decode(w_data_presentazione
                         ,'',to_date('')
                            ,decode(w_flag_pres
                                   ,1,to_date('')
                                     ,to_date(substr(lpad(w_data_presentazione,6,'0'),1,4)||
                                              decode(sign(substr(lpad(w_data_presentazione,6,'0')
                                                                ,5
                                                                )-50
                                                         )
                                                    , 1,'19'
                                                       ,'20'
                                                    )||
                                              substr(lpad(w_data_presentazione,6,'0'),5)
                                             ,'ddmmyyyy'
                                             )
                                   )
                         )
                  ,to_date('01011900','ddmmyyyy')
                  )
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN too_many_rows THEN
             null;
        WHEN no_data_found THEN
             w_flag_esistenza   := 0;
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in controllo esistenza denuncia '||
                    ' ('||sql_errm||')');
      END;
-- dbms_output.put_line ('trattamento pratica(1) :'||w_pratica);
      IF nvl(length(w_cod_fisc_dichiarante),0) not in (11,16)
       OR w_flag_esistenza = 1 THEN
         w_flag_dichiarante := 1;
      ELSE
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
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                   (-20999,'Errore in inserimento contribuenti:'||
                    w_cod_fisc_dichiarante||' ni'||w_ni||
                  ' ('||sql_errm||')');
                 END;
               WHEN no_data_found THEN
                 w_max_ni        := w_max_ni + 1;
                 w_flag_nas      := 0;
                 IF ltrim(rtrim(w_data_nas_dichiarante),'0') is not null THEN
                   BEGIN
                     select 1
                       into w_flag_nas
                       from dual
                      where (substr(lpad(w_data_nas_dichiarante,6,0),1,2) = '31' and
                             substr(lpad(w_data_nas_dichiarante,6,0),3,2) in
                             ('02','04','06','09','11'))
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
                      ROLLBACK;
                      RAISE_APPLICATION_ERROR
                      (-20999,'Errore in controllo data nas. dichiarante'||
                      ' data '||w_data_nas_dichiarante||
                      ' cf '||w_cod_fisc_dichiarante||
                       ' ('||sql_errm||')');
                   END;
   -- dbms_output.put_line ('data nas dic.(1) :'||w_data_nas_dichiarante);
   -- dbms_output.put_line ('flag nas. :'||w_flag_nas);
                   BEGIN
   --                  select to_char(to_date(lpad(
   --                         w_data_nas_dichiarante,6,0),'ddmmyy'),'ddmmyyyy')
                     select to_char(to_date(substr(lpad(w_data_nas_dichiarante,6,0),1,4)||
                                            '19'||
                                            substr(lpad(w_data_nas_dichiarante,6,0),5),
                                    'ddmmyyyy'),'ddmmyyyy')
                       into w_data_nas_dichiarante
                       from dual
                      where nvl(w_flag_nas,0) != 1
                     ;
                     RAISE no_data_found;
                   EXCEPTION
                     WHEN no_data_found THEN
                       null;
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                       (-20999,'Errore in var. anno data nas. dichiarante'||
                       ' data*'||w_data_nas_dichiarante||
                       '*cf '||w_cod_fisc_dichiarante||
                       ' ('||sql_errm||')');
                   END;
   -- dbms_output.put_line ('data nas dic.(2) :'||w_data_nas_dichiarante);
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
                   EXCEPTION
                     WHEN no_data_found THEN
                       null;
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                       (-20999,'Errore in sottraz. secolo data nas. dichiarante '||
                       'Data: '||w_data_nas_dichiarante||
                       ' CF: '||w_cod_fisc_dichiarante||
                       ' ('||sql_errm||')');
                   END;
                 END IF;
                 IF w_com_nas_dichiarante is not null THEN
   -- dbms_output.put_line ('com. nas dic.:*'||w_com_nas_dichiarante||'*');
   -- dbms_output.put_line ('sigla nas dic.:*'||w_sigla_nas_dichiarante||'*');
                   BEGIN
                     w_cod_pro := '';
                     w_cod_com := '';
                     w_cap     := '';
                     w_des     := w_com_nas_dichiarante;
                     w_sigla   := w_sigla_nas_dichiarante;
                     w_catasto := '';
                     OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
                     FETCH ricerca_comuni INTO w_cod_pro,w_cod_com,w_cap;
                     IF ricerca_comuni%NOTFOUND then
                       BEGIN
                         select w_note||' '||'COM.NAS.DICH.: '||
                                w_com_nas_dichiarante
                           into w_note
                           from dual
                         ;
                       EXCEPTION
                         WHEN others THEN
                           sql_errm  := substr(SQLERRM,1,100);
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR
                           (-20999,'Errore in deposito com. nas. dichiarante '||
                           ' ('||sql_errm||')');
                       END;
                     END IF;
                     CLOSE ricerca_comuni;
                   END;
                 END IF;
                 IF w_comune_dichiarante is not null THEN
                   BEGIN
                     w_cod_pro_res := '';
                     w_cod_com_res := '';
                     w_cap         := '';
                     w_des         := w_comune_dichiarante;
                     w_sigla       := w_sigla_res_dichiarante;
                     w_catasto     := '';
                     OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
                     FETCH ricerca_comuni INTO w_cod_pro_res,w_cod_com_res,w_cap_res;
                     IF ricerca_comuni%NOTFOUND then
                       BEGIN
                         select w_note||' '||'COM.RES.DICH.: '||
                                w_comune_dichiarante
                           into w_note
                           from dual
                         ;
                       EXCEPTION
                         WHEN others THEN
                           sql_errm  := substr(SQLERRM,1,100);
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR
                           (-20999,'Errore in deposito com. res. dichiarante '||
                           ' ('||sql_errm||')');
                       END;
                     END IF;
                     CLOSE ricerca_comuni;
                   END;
                 END IF;
                 BEGIN
                   insert into soggetti
                         (ni,tipo_residente,cod_fiscale,cognome_nome,
                          denominazione_via,
                          sesso,data_nas,cod_pro_nas,cod_com_nas,
                          cod_pro_res,cod_com_res,cap,
                          partita_iva,tipo,utente,data_variazione,note)
                   values (w_max_ni,1,
                          decode(length(w_cod_fisc_dichiarante),16,
                          w_cod_fisc_dichiarante,''),
                          nvl(substr(w_cognome_dichiarante||
                          decode(w_nome_dichiarante,'','','/'||
                                 w_nome_dichiarante),1,40),
                          'DENOMINAZIONE ASSENTE'),
                          w_indirizzo_dichiarante,
                          rtrim(w_sesso_dichiarante),
                          decode(w_data_nas_dichiarante,'',to_date(''),
                           decode(w_flag_nas,1,to_date(''),
                            to_date(lpad(w_data_nas_dichiarante,8,0),
                            'ddmmyyyy'))),
                          w_cod_pro,w_cod_com,
                          w_cod_pro_res,w_cod_com_res,w_cap_res,
                          decode(length(w_cod_fisc_dichiarante),11,
                          translate(w_cod_fisc_dichiarante,'O','0'),''),
                          decode(length(w_cod_fisc_dichiarante),
                                 16,0,11,1,2),
                          'ICI',trunc(sysdate),w_note)
                    ;
                 EXCEPTION
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                       (-20999,'Errore in inserimento nuovo soggetto '||
                       'CF '||w_cod_fisc_dichiarante||
   --                    ' sesso '||w_sesso_dichiarante||
                       ' ('||sql_errm||')');
                 END;
                 BEGIN
                   insert into contribuenti (cod_fiscale,ni)
                   values (w_cod_fisc_dichiarante,w_max_ni)
                   ;
                 EXCEPTION
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento nuovo contribuente'||
                     ' cod.fisc.: '||w_cod_fisc_dichiarante||
                     ' ni: '||w_max_ni||
                     ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca soggetti'||
                         ' ('||sql_errm||')');
             END;
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             ROLLBACK;
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in selezione contribuenti'||
                       ' ('||sql_errm||')');
         END;
         w_flag_tipo_carica := 0;
         IF w_carica_rappresentante is not null THEN
           BEGIN
              select tipo_carica,1
                into w_tipo_carica,w_flag_tipo_carica
                from tipi_carica tica
               where tica.descrizione = w_carica_rappresentante
              ;
           EXCEPTION
              WHEN no_data_found THEN
                w_max_tipo_carica    := w_max_tipo_carica + 1;
                w_flag_tipo_carica   := 1;
                w_tipo_carica        := w_max_tipo_carica;
                BEGIN
                  insert into tipi_carica (tipo_carica,descrizione)
                  values (w_max_tipo_carica,w_carica_rappresentante)
                  ;
                EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserimento tipo carica'||
                              ' ('||sql_errm||')');
                END;
           END;
         END IF;
         w_note            := '';
         IF w_comune_rappresentante is not null THEN
           BEGIN
             w_cod_pro     := '';
             w_cod_com     := '';
             w_cap         := '';
             w_des         := w_comune_rappresentante;
             w_sigla       := '';
             w_catasto     := '';
             OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
             FETCH ricerca_comuni INTO w_cod_pro,w_cod_com,w_cap;
             IF ricerca_comuni%NOTFOUND then
               BEGIN
                 select w_note||' '||'COM.RAPPRESENTANTE: '||
                        w_comune_rappresentante
                   into w_note
                   from dual
                 ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                   (-20999,'Errore in deposito com. rappresentante '||
                   ' ('||sql_errm||')');
               END;
             END IF;
             CLOSE ricerca_comuni;
           END;
         END IF;
         -- dbms_output.put_line ('inserimento pratica :'||w_pratica);
         -- dbms_output.put_line('w_flag_tipo_ca '||w_flag_tipo_carica);
         -- dbms_output.put_line('w_tipo_ca '||w_tipo_carica);
         -- dbms_output.put_line('w_max_tipo_ca '||w_max_tipo_carica);
         -- (VD - 09/01/2020): Si memorizzano i numeri della prima e dell'ultima pratica inserita
         --                    per eseguire l'archiviazione alla fine del trattamento
         if w_min_pratica is null then
            w_min_pratica := w_pratica;
         end if;
         if nvl(w_max_pratica,0) < w_pratica then
            w_max_pratica := w_pratica;
         end if;
         BEGIN
           insert into pratiche_tributo
                  (pratica,cod_fiscale,tipo_tributo,
                   anno,tipo_pratica,tipo_evento,
                   data,numero,tipo_carica,denunciante,
                   indirizzo_den,cod_pro_den,cod_com_den,
                   cod_fiscale_den,partita_iva_den,
                   utente,data_variazione,note)
           values (w_pratica,w_cod_fisc_dichiarante,'ICI',
                   a_anno_denuncia,'D','I',
   --                decode(w_data_presentazione,'',to_date(''),
   --                  decode(w_flag_pres,1,to_date(''),
   --                         to_date(substr(lpad(w_data_presentazione,6,'0'),1,4)||
   --                                 '19'||
   --                     substr(lpad(w_data_presentazione,6,'0'),5),
   --                         'ddmmyyyy'))),
             decode(w_data_presentazione,'',to_date(''),
              decode(w_flag_pres,1,to_date(''),to_date(substr(lpad(w_data_presentazione,6,'0'),1,4)||
              decode(sign(substr(lpad(w_data_presentazione,6,'0'),5)-50),
                1,'19','20')
              ||substr(lpad(w_data_presentazione,6,'0'),5),
               'ddmmyyyy'))),
                   w_protocollo,
                   decode(w_flag_tipo_carica,1,w_tipo_carica,
            null),
   --         decode(w_max_tipo_carica,0,to_number(null),w_max_tipo_carica)),
                   w_rappresentante,w_indir_rappresentante,
                   w_cod_pro,w_cod_com,
                   decode(length(w_cod_fisc_rappresentante),
                          16,w_cod_fisc_rappresentante,to_char(null)),
                   decode(length(w_cod_fisc_rappresentante),
                          11,translate(w_cod_fisc_rappresentante,'O','0'),to_char(null)),
                   'ICI',trunc(sysdate),w_note)
           ;
         EXCEPTION
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             ROLLBACK;
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in inserimento nuova pratica '||
                       ' ('||sql_errm||')');
         END;
         -- dbms_output.put_line('nuova pratica caricata');
         BEGIN
           insert into rapporti_tributo
                  (pratica,cod_fiscale,tipo_rapporto)
           values (w_pratica,w_cod_fisc_dichiarante,'D')
           ;
         EXCEPTION
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             ROLLBACK;
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in inserimento rapporto tributo '||
                       ' ('||sql_errm||')');
         END;
         BEGIN
           insert into denunce_ici
                  (pratica,denuncia,fonte,utente,data_variazione)
           values (w_pratica,w_pratica,2,'ICI',trunc(sysdate))
           ;
         EXCEPTION
           WHEN others THEN
             sql_errm  := substr(SQLERRM,1,100);
             ROLLBACK;
             RAISE_APPLICATION_ERROR
               (-20999,'Errore in inserimento denuncia ici '||
                       ' ('||sql_errm||')');
         END;
      END IF;
    END IF;
    IF rec_var.tipo_record = '4' THEN
      IF w_anno_denuncia <= 1994 THEN
         OPEN sel_imm_94;
      ELSE
         OPEN sel_imm_95;
      END IF;
      LOOP
         IF w_anno_denuncia <= 1994 THEN
           FETCH sel_imm_94 INTO w_numero_ordine,w_immobile,w_indirizzo_localita,
                                 w_partita,w_sezione,w_foglio,w_numero,w_subalterno,
                                 w_protocollo_catasto,w_anno_catasto,w_categoria,
                                 w_classe,w_imm_storico,w_valore,w_provvisorio,
                                 w_perc_possesso,w_mesi_possesso,w_mesi_esclusione,
                                 w_mesi_riduzione,w_detrazione,
                                 w_mesi_aliquota_ridotta,
                                 w_possesso,w_esclusione,w_riduzione,w_ab_principale,
                                 w_aliquota_ridotta,w_acquisto,w_cessione,
                                 w_estremi_titolo,w_firma,w_modello,w_num_seq;
             IF sel_imm_94%NOTFOUND then
                exit;
             END IF;
             IF w_flag_dichiarante = 1 THEN
                exit;
             END IF;
         ELSE
           FETCH sel_imm_95 INTO w_numero_ordine,w_immobile,w_indirizzo_localita,
                                 w_partita,w_sezione,w_foglio,w_numero,w_subalterno,
                                 w_protocollo_catasto,w_anno_catasto,w_categoria,
                                 w_classe,w_imm_storico,w_valore,w_provvisorio,
                                 w_perc_possesso,w_mesi_possesso,w_mesi_esclusione,
                                 w_mesi_riduzione,w_detrazione,
                                 w_mesi_aliquota_ridotta,
                                 w_possesso,w_esclusione,w_riduzione,w_ab_principale,
                                 w_aliquota_ridotta,w_acquisto,w_cessione,
                                 w_estremi_titolo,w_firma,w_modello,w_num_seq;
             IF sel_imm_95%NOTFOUND then
                exit;
             END IF;
             IF w_flag_dichiarante = 1 THEN
                exit;
             END IF;
         END IF;
         w_flag_immobili           := 0;
         w_flag_err_immobili       := 0;
         w_progr_immobile_caricato := 0;
         w_cod_via                 := 0;
         w_num_civ                 := 0;
         w_suffisso                := '';
--         w_oggetto_pratica         := w_oggetto_pratica + 1;

         w_oggetto_pratica := null;
         oggetti_pratica_nr(w_oggetto_pratica); --Assegnazione Numero Progressivo

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
                values (w_categoria,'DA CARICAMENTO DATI ANCI')
                ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento Categorie Catasto'||
                     ' ('||sql_errm||')');
              END;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              ROLLBACK;
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in ricerca Categorie Catasto'||
                 ' ('||sql_errm||')');
           END;
         END IF; -- fine controllo categoria not null
         -- dbms_output.put_line ('trattamento oggetto pratica :'||w_oggetto_pratica);
         IF w_immobile in ('3','4','55') THEN -- inizio trattamento fabbricati
           IF w_sezione||w_foglio||w_numero||w_subalterno is not null THEN
              w_flag_immobili           := 0;
              w_estremi_catasto := lpad(ltrim(nvl(w_sezione,' '),'0'),3,' ')
                                   ||
                                   lpad(ltrim(nvl(w_foglio,' '),'0'),5,' ')
                                   ||
                                   lpad(ltrim(nvl(w_numero,' '),'0'),5,' ')
                                   ||
                                   lpad(ltrim(nvl(w_subalterno,' '),'0'),4,' ')
                                   ||
                                   lpad(' ',3);
             --dbms_output.put_line ('estremi catasto :'||w_estremi_catasto);
             --dbms_output.put_line ('categoria catasto :'||w_categoria);
              BEGIN
                select '1',max(oggetto)
                  into w_flag_immobili,w_progr_immobile_caricato
                  from oggetti ogge
                 where ogge.tipo_oggetto + 0          = w_immobile
                   and ogge.estremi_catasto          = w_estremi_catasto
                   and nvl(ogge.categoria_catasto,'   ')    = nvl(w_categoria,'   ')
                ;
                RAISE too_many_rows;
              EXCEPTION
                WHEN too_many_rows THEN
                  BEGIN
                    select '0'
                      into w_flag_immobili
                      from dual
                     where w_progr_immobile_caricato is null
                    ;
                  EXCEPTION
                   WHEN no_data_found THEN
                     null;
                    WHEN others THEN
                      sql_errm  := substr(SQLERRM,1,100);
                      ROLLBACK;
                      RAISE_APPLICATION_ERROR
                        (-20999,'Errore in azzeramento flag immobili (fabbricato)'||
                                ' ('||sql_errm||')');
                  END;
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
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
                WHEN no_data_found then
                  w_cod_via := 0;
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
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
                    ROLLBACK;
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
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in decodifica numero civico e suffisso'||
                       ' ('||sql_errm||')');
                END;
              END IF; -- fine controllo cod_via != 0
--              w_oggetto := w_oggetto + 1;

              w_oggetto := null;
              oggetti_nr(w_oggetto); --Assegnazione Numero Progressivo

              --dbms_output.put_line ('oggetto - prima');
              BEGIN
                insert into oggetti
                       (oggetto,tipo_oggetto,indirizzo_localita,
                        cod_via,num_civ,suffisso,sezione,foglio,
                        numero,subalterno,protocollo_catasto,
                        anno_catasto,
                        categoria_catasto,classe_catasto,
                        fonte,utente,data_variazione)
                values (w_oggetto,w_immobile,
                        w_indirizzo_localita,
                        decode(w_cod_via,0,'',w_cod_via),
                        decode(w_num_civ,0,'',w_num_civ),
                        w_suffisso,
                        w_sezione,w_foglio,w_numero,w_subalterno,
                        w_protocollo_catasto,w_anno_catasto,
                        w_categoria,w_classe,
                        2,'ICI',trunc(sysdate))
              ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento fabbricato '||
      --              w_oggetto||'/'||
      --               w_indirizzo_localita||'/'||w_cod_via||'/'||
      --               w_num_civ||'/'||w_suffisso||'/'||
      --              w_sezione||'/'||w_foglio||'/'||w_numero||'/'||w_subalterno||'/'||
      --              w_protocollo_catasto||'/'||w_anno_catasto||'/'||w_categoria||
                            ' ('||sql_errm||')');
              END;
           --dbms_output.put_line ('oggetto - dopo');
           END IF; -- fine controllo se immobile gia' presente
         ELSIF w_immobile in ('1','2') THEN -- inizio trattamento terreni
           w_flag_immobili           := 0;
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
            END IF;
            BEGIN
               select '1',max(oggetto)
                 into w_flag_immobili,w_progr_immobile_caricato
                 from oggetti ogge
                where ogge.tipo_oggetto + 0         = w_immobile
                  and ogge.estremi_catasto          = w_estremi_catasto
                  and lpad(nvl(ogge.partita,'0'),8,'0')       =
                      lpad(nvl(w_partita,'0'),8,'0')
               ;
               RAISE too_many_rows;
            EXCEPTION
               WHEN too_many_rows THEN
                 BEGIN
                   select '0'
                     into w_flag_immobili
                     from dual
                    where w_progr_immobile_caricato is null
                   ;
                 EXCEPTION
                   WHEN no_data_found THEN
                     null;
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                       (-20999,'Errore in azzeramento flag immobili (terreni)'||
                               ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in controllo esistenza terreni'||
                           ' ('||sql_errm||')');
            END;
            IF w_flag_immobili = 0 THEN
--               w_oggetto := w_oggetto + 1;

               w_oggetto := null;
               oggetti_nr(w_oggetto); --Assegnazione Numero Progressivo

               BEGIN
                 insert into oggetti
                        (oggetto,tipo_oggetto,indirizzo_localita,
                         partita,sezione,foglio,numero,subalterno,
                     protocollo_catasto,anno_catasto,
                         categoria_catasto,classe_catasto,
                         fonte,utente,data_variazione)
                 values (w_oggetto,w_immobile,
                         w_indirizzo_localita,
                         w_partita,w_sezione,w_foglio,w_numero,w_subalterno,
                     w_protocollo_catasto,w_anno_catasto,
                         w_categoria,w_classe,
                         2,'ICI',trunc(sysdate))
               ;
               EXCEPTION
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                     (-20999,--'Errore in inserimento terreno '||
                           --  'oggetto '||w_oggetto||' tipo_oggetto '||w_immobile||
                     '/ind/'||w_indirizzo_localita||'/part/'||w_partita||'/sez/'||
                    w_sezione||'/fog/'||w_foglio||'/num/'||w_numero||'/sub/'||w_subalterno||'/pcat/'||
                    w_protocollo_catasto||'/acat/'||w_anno_catasto||'/cate/'||w_categoria||'/clas/'||w_classe||
                             ' ('||sql_errm||')');
               END;
            END IF; -- fine controllo se immobile gia' presente
         ELSE
            w_flag_err_immobili := 1;
             BEGIN
               select 'x'
                 into w_controllo
                 from anomalie_anno
                where tipo_anomalia     = 21
                  and anno              = a_anno_denuncia
               ;
               RAISE too_many_rows;
             EXCEPTION
               WHEN too_many_rows THEN
                 null;
               WHEN no_data_found THEN
                 BEGIN
                   insert into anomalie_anno
                          (tipo_anomalia,anno,data_elaborazione)
                   values (21,a_anno_denuncia,trunc(sysdate))
                   ;
                 EXCEPTION
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                       (-20999,'Errore in inserimento anomalie anno (21)'||
                               ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in controllo anomalia 21 '||
                           ' ('||sql_errm||')');
             END;
             BEGIN
               select 'x'
                 into w_controllo
                 from anomalie_ici
                where anno              = a_anno_denuncia
                  and tipo_anomalia     = 21
                  and cod_fiscale       = w_cod_fisc_dichiarante
               ;
               RAISE too_many_rows;
             EXCEPTION
               WHEN too_many_rows THEN
                 null;
               WHEN no_data_found THEN
                 BEGIN
                   insert into anomalie_ici
                          (anno,tipo_anomalia,cod_fiscale)
                   values (a_anno_denuncia,21,w_cod_fisc_dichiarante)
                   ;
                 EXCEPTION
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                       (-20999,'Errore in inserimento anomalia ici (21)'||
                               ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in controllo anomalia ici 21 '||
                           ' ('||sql_errm||')');
             END;
         END IF; -- fine trattamento immobili
         -- dbms_output.put_line ('carica oggetto pratica :'||w_oggetto_pratica);
         -- dbms_output.put_line ('flag. imm. :'||w_flag_immobili);
         -- dbms_output.put_line ('oggetto :'||w_oggetto);
         -- dbms_output.put_line ('oggetto caricato :'||w_progr_immobile_caricato);
         --dbms_output.put_line ('numero ordine :'||w_numero_ordine);
        IF w_flag_err_immobili = 0 THEN
          BEGIN
            insert into oggetti_pratica
                   (oggetto_pratica,
                    oggetto,
                    tipo_oggetto,
                    pratica,
                    anno,
                    num_ordine,
                    imm_storico,
                    categoria_catasto,
                    classe_catasto,
                    valore,
                    flag_provvisorio,
                    flag_valore_rivalutato,
                    titolo,
                    estremi_titolo,
                    modello,
                    flag_firma,
                    fonte,utente,data_variazione)
            values (w_oggetto_pratica,
                    decode(w_flag_immobili,1,w_progr_immobile_caricato, w_oggetto),
                    w_immobile,
                    w_pratica,
                    a_anno_denuncia,
                    w_numero_ordine,
                    w_imm_storico,
                    w_categoria,
                    w_classe,
                    w_valore / w_100,
                    w_provvisorio,
                    decode(sign(1996 - a_anno_denuncia),
                           -1,'S',''),
                    decode(w_acquisto,'S','A',
                     decode(w_cessione,'S','C','')),
                    w_estremi_titolo,
                    w_modello,
                    w_firma,
                    2,'ICI',trunc(sysdate))
            ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              ROLLBACK;
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento oggetti_pratica '||
              ' Cat '||w_categoria||
   --               ' oggetto pratica '||w_oggetto_pratica||
   --               ' oggetto '||w_oggetto||
   --               ' oggetto caricato '||w_progr_immobile_caricato||
   --               ' pratica '||w_pratica||
   --               ' flag immobili '||w_flag_immobili||
   --               ' valore '||w_valore||' modello '||w_modello||
   --               ' anno '||a_anno_denuncia||
                        ' ('||sql_errm||')');
          END;
          IF nvl(w_mesi_possesso,12)
             < (nvl(w_mesi_riduzione,0) + nvl(w_mesi_esclusione,0))
            or nvl(w_mesi_possesso,12) < nvl(w_mesi_aliquota_ridotta,0) THEN
            BEGIN
              select 'x'
                into w_controllo
                from anomalie_anno
               where tipo_anomalia     = 10
                 and anno              = a_anno_denuncia
              ;
              RAISE too_many_rows;
            EXCEPTION
              WHEN too_many_rows THEN
                null;
              WHEN no_data_found THEN
                BEGIN
                  insert into anomalie_anno
                         (tipo_anomalia,anno,data_elaborazione)
                  values (10,a_anno_denuncia,trunc(sysdate))
                  ;
                EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserimento tipo carica'||
                              ' ('||sql_errm||')');
                END;
              WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in controllo anomalia 10 '||
                          ' ('||sql_errm||')');
            END;
            BEGIN
              select 'x'
                into w_controllo
                from anomalie_ici
               where anno          = a_anno_denuncia
                 and tipo_anomalia = 10
                 and cod_fiscale   = w_cod_fisc_dichiarante
                 and oggetto       = decode(w_flag_immobili,
                                      1,w_progr_immobile_caricato,w_oggetto)
              ;
              RAISE too_many_rows;
            EXCEPTION
              WHEN too_many_rows THEN
               null;
              WHEN no_data_found THEN
                BEGIN
                  insert into anomalie_ici
                         (anno,tipo_anomalia,cod_fiscale,oggetto)
                  values (a_anno_denuncia,10,w_cod_fisc_dichiarante,
                          decode(w_flag_immobili,
                                 1,w_progr_immobile_caricato, w_oggetto))
                  ;
                EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserimento anomalie ici '||
                              ' ('||sql_errm||')');
                END;
              WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in controllo esistenza anomalia 10 '||
                          ' ('||sql_errm||')');
            END;
            BEGIN
             INTEGRITYPACKAGE.NEXTNESTLEVEL;
              insert into oggetti_contribuente
                     (cod_fiscale,oggetto_pratica,
                      anno,tipo_rapporto,
                      perc_possesso,
                      mesi_possesso,mesi_esclusione,
                      mesi_riduzione,mesi_aliquota_ridotta,
                      detrazione,flag_possesso,
                      flag_esclusione,flag_riduzione,
                      flag_ab_principale,
                      flag_al_ridotta,
                      utente,
                      data_variazione)
              values (w_cod_fisc_dichiarante,w_oggetto_pratica,
                      a_anno_denuncia,'D',
                      w_perc_possesso,
                      w_mesi_possesso,w_mesi_esclusione,
                      w_mesi_riduzione,w_mesi_aliquota_ridotta,
                      w_detrazione / w_100,
                      w_possesso,
                      w_esclusione,w_riduzione,
                      w_ab_principale,w_aliquota_ridotta,
                      'ICI',trunc(sysdate))
              ;
              INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
            EXCEPTION
              WHEN others THEN
              INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in inserim. oggetti_contribuente (a) '||
                  'MP '||w_mesi_possesso||' ME '||w_mesi_esclusione||
                  ' MR '||w_mesi_riduzione||' MAR '||w_mesi_aliquota_ridotta||
                  ' Level '||INTEGRITYPACKAGE.GETNESTLEVEL||
                          ' ('||sql_errm||')');
            END;
   --     END IF;
          ELSIF w_ab_principale is not null and
            w_immobile not in (3,4,55) THEN
            BEGIN
              select 'x'
                into w_controllo
                from anomalie_anno
               where tipo_anomalia     = 11
                 and anno              = a_anno_denuncia
              ;
              RAISE too_many_rows;
            EXCEPTION
              WHEN too_many_rows THEN
                null;
              WHEN no_data_found THEN
                BEGIN
                  insert into anomalie_anno
                         (tipo_anomalia,anno,data_elaborazione)
                  values (11,a_anno_denuncia,trunc(sysdate))
                  ;
                EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserimento anomalia 11'||
                              ' ('||sql_errm||')');
                END;
              WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in controllo anomalia 11 '||
                          ' ('||sql_errm||')');
            END;
            BEGIN
              select 'x'
                into w_controllo
                from anomalie_ici
               where anno          = a_anno_denuncia
                 and tipo_anomalia = 11
                 and cod_fiscale   = w_cod_fisc_dichiarante
                 and oggetto       = decode(w_flag_immobili,
                                      1,w_progr_immobile_caricato,w_oggetto)
              ;
              RAISE too_many_rows;
            EXCEPTION
              WHEN too_many_rows THEN
               null;
              WHEN no_data_found THEN
                BEGIN
                  insert into anomalie_ici
                         (anno,tipo_anomalia,cod_fiscale,oggetto)
                  values (a_anno_denuncia,11,w_cod_fisc_dichiarante,
                          decode(w_flag_immobili,
                                 1,w_progr_immobile_caricato, w_oggetto))
                  ;
                EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserimento anomalie ici (11) '||
                              ' ('||sql_errm||')');
                END;
              WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in controllo esistenza anomalia 11 '||
                          ' ('||sql_errm||')');
            END;
            BEGIN
             INTEGRITYPACKAGE.NEXTNESTLEVEL;
              insert into oggetti_contribuente
                     (cod_fiscale,oggetto_pratica,
                      anno,tipo_rapporto,
                      perc_possesso,
                      mesi_possesso,mesi_esclusione,
                      mesi_riduzione,mesi_aliquota_ridotta,
                      detrazione,flag_possesso,
                      flag_esclusione,flag_riduzione,
                      flag_ab_principale,
                      flag_al_ridotta,
                      utente,
                      data_variazione)
              values (w_cod_fisc_dichiarante,w_oggetto_pratica,
                      a_anno_denuncia,'D',
                      w_perc_possesso,
                      w_mesi_possesso,w_mesi_esclusione,
                      w_mesi_riduzione,w_mesi_aliquota_ridotta,
                      w_detrazione / w_100,
                      w_possesso,
                      w_esclusione,w_riduzione,
                      w_ab_principale,w_aliquota_ridotta,
                      'ICI',trunc(sysdate))
              ;
              INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
            EXCEPTION
              WHEN others THEN
                INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in inserim. oggetti_contribuente (b) '||
                  'Tipo Oggetto '||w_immobile||' Ab.Principale '||w_ab_principale||
                  ' Level '||INTEGRITYPACKAGE.GETNESTLEVEL||
                          ' ('||sql_errm||')');
            END;
          --     END IF;
          ELSE
             BEGIN
             -- da gestire l'anomalia
                INTEGRITYPACKAGE.NEXTNESTLEVEL;
               insert into oggetti_contribuente
                      (cod_fiscale,oggetto_pratica,
                       anno,tipo_rapporto,
                       perc_possesso,
                       mesi_possesso,mesi_esclusione,
                       mesi_riduzione,mesi_aliquota_ridotta,
                       detrazione,flag_possesso,
                       flag_esclusione,flag_riduzione,
                       flag_ab_principale,
                       flag_al_ridotta,
                       utente,
                       data_variazione)
               values (w_cod_fisc_dichiarante,w_oggetto_pratica,
                       a_anno_denuncia,'D',
                       w_perc_possesso,
                       w_mesi_possesso,w_mesi_esclusione,
                       w_mesi_riduzione,w_mesi_aliquota_ridotta,
                       w_detrazione / w_100,
                       w_possesso,
                       w_esclusione,w_riduzione,
                       w_ab_principale,w_aliquota_ridotta,
                       'ICI',trunc(sysdate))
               ;
                 INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
             EXCEPTION
               WHEN others THEN
                 INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in inserim. oggetti_contribuente (c) '||
                   'MP '||w_mesi_possesso||' ME '||w_mesi_esclusione||
                   ' MR '||w_mesi_riduzione||' MAR '||w_mesi_aliquota_ridotta||
                           ' ('||sql_errm||')');
             END;
          END IF;
        END IF;
      END LOOP;
      IF w_anno_denuncia <= 1994 THEN
         CLOSE sel_imm_94;
      ELSE
         CLOSE sel_imm_95;
      END IF;
    END IF; -- fine trattamento record immobili
-- inizio trattamento record contitolari
    IF rec_var.tipo_record = '3' THEN
      IF w_anno_denuncia <= 1994 THEN
         OPEN sel_cont_94;
      ELSE
         OPEN sel_cont_95;
      END IF;
      LOOP
        IF w_anno_denuncia <= 1994 THEN
         FETCH sel_cont_94 INTO w_num_ord_contitolare,w_cod_fisc_contitolare,
                                w_indirizzo_contitolare,w_comune_contitolare,
                                w_provincia_contitolare,w_perc_possesso,
                                w_mesi_possesso,w_detrazione,
                                w_mesi_aliquota_ridotta,w_possesso,
                                w_esclusione,w_riduzione,
                                w_ab_principale,w_aliquota_ridotta,
                                w_firma,w_modello,w_num_seq;
           IF sel_cont_94%NOTFOUND then
             exit;
           END IF;
           IF w_flag_dichiarante = 1 THEN
             exit;
           END IF;
        ELSE
          FETCH sel_cont_95 INTO w_num_ord_contitolare,w_cod_fisc_contitolare,
                                 w_indirizzo_contitolare,w_comune_contitolare,
                                 w_provincia_contitolare,w_perc_possesso,
                                 w_mesi_possesso,w_detrazione,
                                 w_mesi_aliquota_ridotta,w_possesso,
                                 w_esclusione,w_riduzione,
                                 w_ab_principale,w_aliquota_ridotta,
                                 w_firma,w_modello,w_num_seq;
           IF sel_cont_95%NOTFOUND then
             exit;
           END IF;
           IF w_flag_dichiarante = 1 THEN
             exit;
           END IF;
        END IF;
-- dbms_output.put_line ('inizio trattamento contitolare ');
        w_oggetto_pratica_cont := 0;
        w_flag_cont            := 0;
        w_note                 := '';
        w_flag_contitolare     := 0;
       -- inizio trattamento contitolari
        IF nvl(length(ltrim(rtrim(w_cod_fisc_contitolare))),0) not in (11,16) THEN
-- dbms_output.put_line ('c.f. contitolare errato ');
          BEGIN
            select 'x'
              into w_controllo
              from anomalie_anno
             where tipo_anomalia     = 21
               and anno              = a_anno_denuncia
            ;
            RAISE too_many_rows;
          EXCEPTION
            WHEN too_many_rows THEN
              null;
            WHEN no_data_found THEN
              BEGIN
                insert into anomalie_anno
                       (tipo_anomalia,anno,data_elaborazione)
                values (21,a_anno_denuncia,trunc(sysdate))
                ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento anomalie anno (21-cont.)'||
                            ' ('||sql_errm||')');
              END;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              ROLLBACK;
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in controllo anomalia 21-cont. '||
                        ' ('||sql_errm||')');
          END;
          BEGIN
            select 'x'
              into w_controllo
              from anomalie_ici
             where anno              = a_anno_denuncia
               and tipo_anomalia     = 21
               and cod_fiscale       = w_cod_fisc_dichiarante
            ;
            RAISE too_many_rows;
          EXCEPTION
            WHEN too_many_rows THEN
              null;
            WHEN no_data_found THEN
              BEGIN
                insert into anomalie_ici
                       (anno,tipo_anomalia,cod_fiscale)
                values (a_anno_denuncia,21,w_cod_fisc_dichiarante)
                ;
              EXCEPTION
                WHEN others THEN
                  sql_errm  := substr(SQLERRM,1,100);
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento anomalia ici (21-cont.)'||
                            ' ('||sql_errm||')');
              END;
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              ROLLBACK;
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in controllo anomalia ici 21-cont. '||
                        ' ('||sql_errm||')');
          END;
      ELSE -- se cod.fisc. contitolare ok
-- dbms_output.put_line ('c.f. contitolare corretto ');
          BEGIN
             select ogpr.oggetto_pratica,
                    ogge.tipo_oggetto
               into w_oggetto_pratica_cont,
                    w_tipo_oggetto_cont
               from oggetti ogge,oggetti_pratica ogpr
              where ogpr.pratica    = w_pratica
                and ogpr.num_ordine = w_num_ord_contitolare
                and ogpr.oggetto    = ogge.oggetto
              ;
          EXCEPTION
           WHEN too_many_rows THEN
            w_flag_contitolare := 1
            ;
           WHEN no_data_found THEN
            BEGIN
              select ogpr.oggetto_pratica,
                     ogge.tipo_oggetto
                into w_oggetto_pratica_cont,
                     w_tipo_oggetto_cont
                from oggetti ogge,oggetti_pratica ogpr
               where ogpr.pratica    = w_pratica
                 and ogpr.oggetto    = ogge.oggetto
              ;
            EXCEPTION
              WHEN too_many_rows THEN
                w_flag_contitolare := 1
                ;
              WHEN no_data_found THEN
                w_flag_contitolare := 1
                ;
              WHEN others THEN
                sql_errm  := substr(SQLERRM,1,100);
                ROLLBACK;
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in ricerca ogpr (cont.) '||
                   'cf cont '||w_cod_fisc_contitolare||'n.o. '||
                   w_num_ord_contitolare||'pratica '||w_pratica||
                          ' ('||sql_errm||')');
            END;
           WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               ROLLBACK;
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca ogpr (num.ord. cont.) '||
                         ' ('||sql_errm||')');
          END;
          BEGIN
             select 'x'
               into w_controllo
               from oggetti_contribuente
              where cod_fiscale     = w_cod_fisc_contitolare
                and oggetto_pratica = w_oggetto_pratica_cont
             ;
             RAISE too_many_rows;
          EXCEPTION
             WHEN no_data_found THEN
               null;
             WHEN too_many_rows THEN
               w_flag_contitolare := 1
               ;
             WHEN others THEN
               sql_errm  := substr(SQLERRM,1,100);
               ROLLBACK;
               RAISE_APPLICATION_ERROR
                 (-20999,'Errore in controllo esistenza ogco (cont.) '||
                         ' ('||sql_errm||')');
          END;
          IF w_ab_principale          = 'S'
               and w_tipo_oggetto_cont not in (3,55)
               and w_flag_contitolare  != 1     THEN
               w_flag_contitolare := 1;
          END IF;
           IF w_flag_contitolare = 1 THEN
               BEGIN
                  insert into anomalie_contitolari
                         (anno,cod_fiscale,pratica,num_ordine,
                          indirizzo,comune,sigla_provincia,perc_possesso,
                          mesi_possesso,detrazione,mesi_aliquota_ridotta,
                          flag_possesso,flag_esclusione,flag_riduzione,
                          flag_ab_principale,flag_al_ridotta)
                  values (a_anno_denuncia,w_cod_fisc_contitolare,
                          w_pratica,
                          w_num_ord_contitolare,
                          w_indirizzo_contitolare,
                          w_comune_contitolare,
                          w_provincia_contitolare,
                          w_perc_possesso,
                          w_mesi_possesso,w_detrazione / w_100,
                          w_mesi_aliquota_ridotta,
                          w_possesso,
                          w_esclusione,w_riduzione,
                          w_ab_principale,w_aliquota_ridotta)
                  ;
               EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                    (-20999,'Errore in inserimento anomalie contitolari'||
                    ' ('||sql_errm||')');
               END;
           ELSE
              BEGIN
                  select ogco.mesi_esclusione,
                         ogco.mesi_riduzione
                    into w_mesi_esclusione,
                         w_mesi_riduzione
                    from oggetti_contribuente ogco
                   where ogco.oggetto_pratica = w_oggetto_pratica_cont
                     and ogco.tipo_rapporto   = 'D'
                  ;
              EXCEPTION
                  WHEN others THEN
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in ricerca ogco (cont.) '||
                              ' ('||sql_errm||')');
              END;
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
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                       (-20999,'Errore in inserimento contrib. contitolare:'||
                        w_cod_fisc_contitolare||' ni'||w_ni||
                      ' ('||sql_errm||')');
                     END;
                   WHEN no_data_found THEN
                     w_max_ni        := w_max_ni + 1;
                     w_flag_nas      := 0;
                     IF w_comune_contitolare is not null THEN
                       BEGIN
                         w_cod_pro_res := '';
                         w_cod_com_res := '';
                         w_cap         := '';
                         w_des         := w_comune_contitolare;
                         w_sigla       := w_provincia_contitolare;
                         w_catasto     := '';
                         OPEN ricerca_comuni (w_des,w_sigla,w_catasto);
                         FETCH ricerca_comuni INTO w_cod_pro_res,w_cod_com_res,w_cap_res;
                         IF ricerca_comuni%NOTFOUND then
                           BEGIN
                             select w_note||' '||'COM.RES.CONT.: '||
                                    w_comune_contitolare
                               into w_note
                               from dual
                             ;
                           EXCEPTION
                             WHEN others THEN
                               sql_errm  := substr(SQLERRM,1,100);
                               ROLLBACK;
                               RAISE_APPLICATION_ERROR
                               (-20999,'Errore in deposito com. res. contitolare '||
                               ' ('||sql_errm||')');
                           END;
                         END IF;
                         CLOSE ricerca_comuni;
                       END;
                     END IF;
                     BEGIN
                       insert into soggetti
                             (ni,tipo_residente,cod_fiscale,cognome_nome,
                              denominazione_via,
                              cod_pro_res,cod_com_res,cap,
                              partita_iva,tipo,utente,data_variazione,note)
                       values (w_max_ni,1,
                              decode(length(w_cod_fisc_contitolare),16,
                              w_cod_fisc_contitolare,''),
                              'CONTITOLARE ANNO '||a_anno_denuncia,
                              w_indirizzo_contitolare,
                              w_cod_pro_res,w_cod_com_res,w_cap_res,
                              decode(length(w_cod_fisc_contitolare),11,
                              translate(w_cod_fisc_contitolare,'O','0'),''),
                              decode(length(w_cod_fisc_contitolare),
                               16,0,11,1,2),
                              'ICI',trunc(sysdate),w_note)
                        ;
                     EXCEPTION
                       WHEN others THEN
                         sql_errm  := substr(SQLERRM,1,100);
                         ROLLBACK;
                         RAISE_APPLICATION_ERROR
                           (-20999,'Errore in inserimento nuovo soggetto (cont.)'||
                           ' ('||sql_errm||')');
                     END;
                     BEGIN
                       insert into contribuenti (cod_fiscale,ni)
                       values (w_cod_fisc_contitolare,w_max_ni)
                       ;
                     EXCEPTION
                       WHEN others THEN
                         sql_errm  := substr(SQLERRM,1,100);
                         ROLLBACK;
                         RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserimento nuovo contribuente (cont.)'||
                         ' c.f. '||w_cod_fisc_contitolare||
                         ' ni '||w_max_ni||
                         ' ('||sql_errm||')');
                     END;
                   WHEN others THEN
                     sql_errm  := substr(SQLERRM,1,100);
                     ROLLBACK;
                     RAISE_APPLICATION_ERROR
                     (-20999,'Errore in ricerca soggetti (cont.)'||
                             ' ('||sql_errm||')');
                 END;
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in selezione contribuenti (cont.)'||
                           ' ('||sql_errm||')');
              END;
              BEGIN
               insert into rapporti_tributo
                      (pratica,cod_fiscale,tipo_rapporto)
               values (w_pratica,w_cod_fisc_contitolare,'C')
               ;
              EXCEPTION
               WHEN others THEN
                 sql_errm  := substr(SQLERRM,1,100);
                 ROLLBACK;
                 RAISE_APPLICATION_ERROR
                   (-20999,'Errore in inserimento rapporto tributo (cont.) '||
                           ' ('||sql_errm||')');
              END;
              IF nvl(w_mesi_possesso,12)
                < (nvl(w_mesi_riduzione,0) + nvl(w_mesi_esclusione,0))
               or nvl(w_mesi_possesso,12) < nvl(w_mesi_aliquota_ridotta,0) THEN
                BEGIN
                 select 'x'
                   into w_controllo
                   from anomalie_anno
                  where tipo_anomalia     = 10
                    and anno              = a_anno_denuncia
                 ;
                 RAISE too_many_rows;
                EXCEPTION
                 WHEN too_many_rows THEN
                   null;
                 WHEN no_data_found THEN
                   BEGIN
                     insert into anomalie_anno
                            (tipo_anomalia,anno,data_elaborazione)
                     values (10,a_anno_denuncia,trunc(sysdate))
                     ;
                   EXCEPTION
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserimento tipo carica'||
                                 ' ('||sql_errm||')');
                   END;
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in controllo anomalia 10 '||
                             ' ('||sql_errm||')');
                END;
                BEGIN
                 select 'x'
                   into w_controllo
                   from anomalie_ici
                  where anno          = a_anno_denuncia
                    and tipo_anomalia = 10
                    and cod_fiscale   = w_cod_fisc_contitolare
                    and oggetto       = decode(w_flag_immobili,
                                         1,w_progr_immobile_caricato,w_oggetto)
                 ;
                 RAISE too_many_rows;
                EXCEPTION
                 WHEN too_many_rows THEN
                  null;
                 WHEN no_data_found THEN
                   BEGIN
                     insert into anomalie_ici
                            (anno,tipo_anomalia,cod_fiscale,oggetto)
                     values (a_anno_denuncia,10,w_cod_fisc_contitolare,
                             decode(w_flag_immobili,
                                    1,w_progr_immobile_caricato, w_oggetto))
                     ;
                   EXCEPTION
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserimento anomalie ici '||
                                 ' ('||sql_errm||')');
                   END;
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in controllo esistenza anomalia 10 '||
                             ' ('||sql_errm||')');
                END;
                BEGIN
                   INTEGRITYPACKAGE.NEXTNESTLEVEL;
                  insert into oggetti_contribuente
                         (cod_fiscale,oggetto_pratica,
                          anno,tipo_rapporto,
                          perc_possesso,
                          mesi_possesso,
                          mesi_esclusione,
                          mesi_riduzione,
                          mesi_aliquota_ridotta,
                          detrazione,flag_possesso,
                          flag_esclusione,flag_riduzione,
                          flag_ab_principale,
                          flag_al_ridotta,
                          utente,
                          data_variazione)
                  values (w_cod_fisc_contitolare,w_oggetto_pratica_cont,
                          a_anno_denuncia,'C',
                          w_perc_possesso,
                          w_mesi_possesso,w_mesi_esclusione,
                          w_mesi_riduzione,w_mesi_aliquota_ridotta,
                          w_detrazione / w_100,
                          w_possesso,
                          w_esclusione,w_riduzione,
                          w_ab_principale,w_aliquota_ridotta,
                          'ICI',trunc(sysdate))
                  ;
                    INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                EXCEPTION
                  WHEN others THEN
                    INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserim. oggetti_contribuente (contit.) '||
                              ' c.f. '||w_cod_fisc_contitolare||
                              ' num_ord '||w_num_ord_contitolare||
                              ' ab.princ. '||w_ab_principale||
                              ' oggetto '||w_oggetto||
         --                     ' mesi poss. '||w_mesi_possesso||
         --                     ' mesi escl. '||w_mesi_esclusione||
         --                     ' mesi rid. '||w_mesi_riduzione||
         --                     ' mesi al.rid. '||w_mesi_aliquota_ridotta||
                              ' oggetto_caricato '||w_progr_immobile_caricato||
                              ' flag_immobile '||w_flag_immobili||
                              ' oggetto_pratica '||w_oggetto_pratica_cont||
                              ' ('||sql_errm||')');
                END;
              ELSIF w_ab_principale is not null and
                w_immobile not in (3,4,55) THEN
                BEGIN
                 select 'x'
                   into w_controllo
                   from anomalie_anno
                  where tipo_anomalia     = 11
                    and anno              = a_anno_denuncia
                 ;
                 RAISE too_many_rows;
                EXCEPTION
                 WHEN too_many_rows THEN
                   null;
                 WHEN no_data_found THEN
                   BEGIN
                     insert into anomalie_anno
                            (tipo_anomalia,anno,data_elaborazione)
                     values (11,a_anno_denuncia,trunc(sysdate))
                     ;
                   EXCEPTION
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserimento anomalia 11'||
                                 ' ('||sql_errm||')');
                   END;
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in controllo anomalia 11 '||
                             ' ('||sql_errm||')');
                END;
                BEGIN
                 select 'x'
                   into w_controllo
                   from anomalie_ici
                  where anno          = a_anno_denuncia
                    and tipo_anomalia = 11
                    and cod_fiscale   = w_cod_fisc_contitolare
                    and oggetto       = decode(w_flag_immobili,
                                         1,w_progr_immobile_caricato,w_oggetto)
                 ;
                 RAISE too_many_rows;
                EXCEPTION
                 WHEN too_many_rows THEN
                  null;
                 WHEN no_data_found THEN
                   BEGIN
                     insert into anomalie_ici
                            (anno,tipo_anomalia,cod_fiscale,oggetto)
                     values (a_anno_denuncia,11,w_cod_fisc_contitolare,
                             decode(w_flag_immobili,
                                    1,w_progr_immobile_caricato, w_oggetto))
                     ;
                   EXCEPTION
                     WHEN others THEN
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserimento anomalie ici (11) '||
                                 ' ('||sql_errm||')');
                   END;
                 WHEN others THEN
                   sql_errm  := substr(SQLERRM,1,100);
                   ROLLBACK;
                   RAISE_APPLICATION_ERROR
                     (-20999,'Errore in controllo esistenza anomalia 11 '||
                             ' ('||sql_errm||')');
                END;
                BEGIN
                   INTEGRITYPACKAGE.NEXTNESTLEVEL;
                  insert into oggetti_contribuente
                         (cod_fiscale,oggetto_pratica,
                          anno,tipo_rapporto,
                          perc_possesso,
                          mesi_possesso,
                          mesi_esclusione,
                          mesi_riduzione,
                          mesi_aliquota_ridotta,
                          detrazione,flag_possesso,
                          flag_esclusione,flag_riduzione,
                          flag_ab_principale,
                          flag_al_ridotta,
                          utente,
                          data_variazione)
                  values (w_cod_fisc_contitolare,w_oggetto_pratica_cont,
                          a_anno_denuncia,'C',
                          w_perc_possesso,
                          w_mesi_possesso,w_mesi_esclusione,
                          w_mesi_riduzione,w_mesi_aliquota_ridotta,
                          w_detrazione / w_100,
                          w_possesso,
                          w_esclusione,w_riduzione,
                          w_ab_principale,w_aliquota_ridotta,
                          'ICI',trunc(sysdate))
                  ;
                    INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                EXCEPTION
                  WHEN others THEN
                    INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                    sql_errm  := substr(SQLERRM,1,100);
                    ROLLBACK;
                    RAISE_APPLICATION_ERROR
                      (-20999,'Errore in inserim. oggetti_contribuente (contit.) '||
                              ' c.f. '||w_cod_fisc_contitolare||
                              ' num_ord '||w_num_ord_contitolare||
                              ' ab.princ. '||w_ab_principale||
                              ' oggetto '||w_oggetto||
         --                     ' mesi poss. '||w_mesi_possesso||
         --                     ' mesi escl. '||w_mesi_esclusione||
         --                     ' mesi rid. '||w_mesi_riduzione||
         --                     ' mesi al.rid. '||w_mesi_aliquota_ridotta||
                              ' oggetto_caricato '||w_progr_immobile_caricato||
                              ' flag_immobile '||w_flag_immobili||
                              ' oggetto_pratica '||w_oggetto_pratica_cont||
                              ' ('||sql_errm||')');
                END;
               ELSE
                   BEGIN
                   -- da gestire l'anomalia
                      INTEGRITYPACKAGE.NEXTNESTLEVEL;
                     insert into oggetti_contribuente
                            (cod_fiscale,oggetto_pratica,
                             anno,tipo_rapporto,
                             perc_possesso,
                             mesi_possesso,
                             mesi_esclusione,
                             mesi_riduzione,
                             mesi_aliquota_ridotta,
                             detrazione,flag_possesso,
                             flag_esclusione,flag_riduzione,
                             flag_ab_principale,
                             flag_al_ridotta,
                             utente,
                             data_variazione)
                     values (w_cod_fisc_contitolare,w_oggetto_pratica_cont,
                             a_anno_denuncia,'C',
                             w_perc_possesso,
                             w_mesi_possesso,w_mesi_esclusione,
                             w_mesi_riduzione,w_mesi_aliquota_ridotta,
                             w_detrazione / w_100,
                             w_possesso,
                             w_esclusione,w_riduzione,
                             w_ab_principale,w_aliquota_ridotta,
                             'ICI',trunc(sysdate))
                     ;
                       INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                   EXCEPTION
                     WHEN others THEN
                       INTEGRITYPACKAGE.PREVIOUSNESTLEVEL;
                       sql_errm  := substr(SQLERRM,1,100);
                       ROLLBACK;
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in inserim. oggetti_contribuente (contit.) '||
                                 ' c.f. '||w_cod_fisc_contitolare||
                                 ' num_ord '||w_num_ord_contitolare||
                                 ' ab.princ. '||w_ab_principale||
                                 ' oggetto '||w_oggetto||
            --                     ' mesi poss. '||w_mesi_possesso||
            --                     ' mesi escl. '||w_mesi_esclusione||
            --                     ' mesi rid. '||w_mesi_riduzione||
            --                     ' mesi al.rid. '||w_mesi_aliquota_ridotta||
                                 ' oggetto_caricato '||w_progr_immobile_caricato||
                                 ' flag_immobile '||w_flag_immobili||
                                 ' oggetto_pratica '||w_oggetto_pratica_cont||
                                 ' ('||sql_errm||')');
                   END;
              END IF; -- fine controllo anomalie 10 e 11
           END IF; -- fine controllo se flag contitolare attivo
        END IF; -- fine controllo se c.f. contitolare corretto
      END LOOP;
      IF w_anno_denuncia <= 1994 THEN
        CLOSE sel_cont_94;
      ELSE
        CLOSE sel_cont_95;
      END IF;
    END IF; -- fine trattamento record contitolari
  w_dep_numero_pacco       := w_numero_pacco;
  w_dep_progressivo_record := w_progressivo_record;
  END LOOP;
  BEGIN
    select 'x'
      into w_controllo
      from dual
     where exists (select 'x'
                     from pratiche_tributo
                    where tipo_tributo = 'ICI'
                      and anno         = a_anno_denuncia)
    ;
    RAISE too_many_rows;
  EXCEPTION
    WHEN no_data_found THEN
         null;
    WHEN too_many_rows THEN
      BEGIN
        select 'x'
          into w_controllo
          from anci_var
        having min(numero_pacco)       = max(numero_pacco)
           and min(progressivo_record) = max(progressivo_record)
        ;
        RAISE too_many_rows;
      EXCEPTION
        WHEN no_data_found THEN
          null;
        WHEN too_many_rows THEN
          BEGIN
            delete anci_var
            ;
          EXCEPTION
            WHEN others THEN
              sql_errm  := substr(SQLERRM,1,100);
              ROLLBACK;
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in svuotamento anci_var'||
                        ' ('||sql_errm||')');
          END;
        WHEN others THEN
          sql_errm  := substr(SQLERRM,1,100);
          ROLLBACK;
          RAISE_APPLICATION_ERROR
            (-20999,'Errore in controllo situazione anci_var'||
                    ' ('||sql_errm||')');
      END;
    WHEN others THEN
      sql_errm  := substr(SQLERRM,1,100);
      ROLLBACK;
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in controllo esistenza anno '||a_anno_denuncia||
                ' ('||sql_errm||')');
  END;
  --
  -- (VD  - 09/02/2020): Aggiunta archiviazione pratiche inserite
  --
  if w_min_pratica is not null and
     w_max_pratica is not null then
     for w_pratica in w_min_pratica..w_max_pratica
     loop
       archivia_denunce('','',w_pratica);
     end loop;
  end if;
 COMMIT;
EXCEPTION
   WHEN FINE THEN null;
   WHEN OTHERS THEN
      ROLLBACK;
      sql_errm  := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR
        (-20999,'('||sql_errm||')');
END;

PROCEDURE CARICA_ANCI_VAR(A_DOCUMENTO_ID IN NUMBER) is
  w_documento_blob blob;
  w_number_temp    number;
  w_numero_righe   number;
  w_lunghezza_riga number := 500;
  w_riga           varchar2(2000);
  w_errore         varchar(2000) := NULL;
  errore           exception;
begin
  select contenuto
    into w_documento_blob
    from documenti_caricati doca
   where doca.documento_id = a_documento_id;

  w_number_temp := DBMS_LOB.GETLENGTH(w_documento_blob);

  if nvl(w_number_temp, 0) = 0 then
    w_errore := 'Attenzione File caricato Vuoto - Verificare Client Oracle';
    raise errore;
  end if;
  w_numero_righe := w_number_temp / w_lunghezza_riga;

  FOR i IN 0 .. w_numero_righe - 1 LOOP
    w_riga := utl_raw.cast_to_varchar2(dbms_lob.substr(w_documento_blob,
                                                       w_lunghezza_riga,
                                                       (w_lunghezza_riga * i) + 1));

    if (substr(w_riga, 1, 1) != '0' and substr(w_riga, 1, 1) != '1' and
       substr(w_riga, 1, 1) != '5' and substr(w_riga, 1, 1) != '6') then
      insert into anci_var
        (tipo_record,
         dati,
         numero_pacco,
         progressivo_record,
         dati_1,
         dati_2,
         dati_3)
      values
        (to_number(substr(w_riga, 1, 1)),
         substr(w_riga, 2, 17),
         to_number(substr(w_riga, 19, 7)),
         to_number(substr(w_riga, 25, 6)),
         substr(w_riga, 32, 215),
         substr(w_riga, 247, 242),
         substr(w_riga, 489, 10));
    end if;

  end LOOP;

end;
END CARICA_DIC_ANCI_PK;
/
