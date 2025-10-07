--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_versamenti_ici stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VERSAMENTI_ICI
(a_conv   IN  varchar2)
IS
w_controllo         varchar2(1);
w_notfound          boolean;
w_dep_cod_fiscale   varchar2(16) := ' ';
w_num_versamenti    number := 0;
w_conta_record      number := 0;
w_100               number;
w_pratica           number;
w_trovato           varchar2(2);
w_conta_cont        number;
w_flag_infrazione   varchar2(1);
CURSOR sel_anci_ok IS
  select decode(substr(anve.cod_fiscale,1,5),
                '00000',ltrim(substr(anve.cod_fiscale,6)),
                 ltrim(anve.cod_fiscale)) cod_fiscale,
         anve.anno_fiscale,
         decode(sign(anve.anno_fiscale - 1998)
               ,-1,decode(anve.acconto_saldo
                         ,1,'A'
                         ,2,'S'
                         ,3,'U'
                         ,decode(sign(data_versamento - scad.data_scadenza)
                                ,1,'S'
                                ,'A'
                                )
                         )
               ,decode(anve.acconto_saldo
                      ,1,'A'
                      ,2,'S'
                      ,3,'U'
                      ,decode(sign(data_versamento - scad.data_scadenza)
                             ,1,'S'
                             ,'A'
                             )
                      )
               )                  tipo_versamento,
         anve.data_versamento,
         ltrim(anve.fabbricati,0) fabbricati,
         ltrim(anve.terreni_agricoli,0) terreni_agricoli,
         ltrim(anve.aree_fabbricabili,0) aree_fabbricabili,
         ltrim(anve.ab_principale,0) ab_principale,
         ltrim(anve.altri_fabbricati,0) altri_fabbricati,
         ltrim(anve.detrazione,0) detrazione,
         ltrim(anve.importo_versato,0) importo_versato,
         anve.progr_record,
         decode(length(anve.data_reg),
                6,to_date(anve.data_reg,'yymmdd'),
                8,to_date(anve.data_reg,'yyyymmdd')) data_reg,
         nvl(anve.fonte,2) fonte,
         cont.ni ni_cont,
         anve.progr_record progr_vers,
         anve.num_provvedimento num_provvedimento,
         anve.flag_ravvedimento flag_ravvedimento,
         anve.sanzione_ravvedimento sanzione_ravvedimento
    from contribuenti cont,
         anci_ver anve,
         scadenze scad
   where scad.tipo_tributo         = 'ICI'
     and scad.tipo_scadenza        = 'V'
     and scad.tipo_versamento      = 'A'
     and scad.anno                 = anve.anno_fiscale
     and anve.tipo_anomalia   is not null
     and cont.cod_fiscale     = decode(substr(anve.cod_fiscale,1,5)
                                      ,'00000',ltrim(substr(anve.cod_fiscale,6))
                                      ,ltrim(anve.cod_fiscale)
                                      )
     and anve.tipo_record         <> 6
     ;
CURSOR sel_anci_52s IS
  select decode(substr(anve.cod_fiscale,1,5)
             ,'00000',ltrim(substr(anve.cod_fiscale,6))
             ,ltrim(anve.cod_fiscale)
             )                                                    cod_fiscale
       , anve.anno_fiscale
       , decode(sign(anve.anno_fiscale-1998)
               ,-1,decode(anve.acconto_saldo
                         ,1,'A'
                         ,2,'S'
                         ,3,'U'
                         ,decode(sign(data_versamento - scad.data_scadenza)
                                ,1,'S'
                                ,'A'
                                )
                         )
               ,decode(anve.acconto_saldo
                      ,1,'A'
                      ,2,'S'
                      ,3,'U'
                      ,decode(sign(data_versamento - scad.data_scadenza)
                             ,1,'S'
                             ,'A'
                             )
                      )
               )                                                  tipo_versamento
       , anve.data_versamento
       , ltrim(anve.fabbricati,0)                                 fabbricati
       , ltrim(anve.terreni_agricoli,0)                           terreni_agricoli
       , ltrim(anve.aree_fabbricabili,0)                          aree_fabbricabili
       ,        ltrim(anve.ab_principale,0)                       ab_principale
       , ltrim(anve.altri_fabbricati,0)                           altri_fabbricati
       , ltrim(anve.detrazione,0)                                 detrazione
       , ltrim(anve.importo_versato,0)                            importo_versato
       , anve.progr_record
       , decode(length(anve.data_reg)
               ,6,to_date(anve.data_reg,'yymmdd')
               ,8,to_date(anve.data_reg,'yyyymmdd')
               )                                                  data_reg
       , nvl(anve.fonte,2)                                        fonte
       , sogg.ni                                                  ni_sogg
       , anve.progr_record                                        progr_vers
       , anve.num_provvedimento                                   num_provvedimento
       , anve.flag_ravvedimento                                   flag_ravvedimento
    from soggetti sogg,
         anci_ver anve,
         scadenze scad
   where scad.tipo_tributo      = 'ICI'
     and scad.tipo_scadenza     = 'V'
     and scad.tipo_versamento   = 'A'
     and scad.anno              = anve.anno_fiscale
     and anve.tipo_anomalia     = 52
     and anve.flag_ravvedimento <> 1
     and nvl(anve.flag_contribuente,'N')        = 'S'
     and (  sogg.cod_fiscale = decode(substr(anve.cod_fiscale,1,5)
                                     ,'00000',ltrim(substr(anve.cod_fiscale,6))
                                     ,ltrim(anve.cod_fiscale)
                                     )
         or sogg.cod_fiscale = decode(substr(anve.cod_fiscale,1,5)
                                     ,'00000',ltrim(substr(anve.cod_fiscale,6))
                                     ,ltrim(anve.cod_fiscale)
                                     )
         )
     and anve.tipo_record     <> 6
order by anve.anno_fiscale asc
       , anve.progr_record asc
       , sogg.ni desc
     ;
CURSOR sel_anci_93 IS
       select progr_record,
              decode(substr(anve.cod_fiscale,1,5),
              '00000',ltrim(substr(anve.cod_fiscale,6)),
              ltrim(anve.cod_fiscale)) cod_fiscale,
              data_versamento
         from anci_ver anve
        where ltrim(anve.cod_fiscale)    is not null
          and anno_fiscale               = 1993
          and anve.tipo_record       <> 6
          and nvl(flag_ravvedimento,0) = 0
     order by decode(substr(anve.cod_fiscale,1,5),
              '00000',ltrim(substr(anve.cod_fiscale,6)),
              ltrim(anve.cod_fiscale)), data_versamento
       ;
CURSOR sel_anci IS
       select decode(substr(anve.cod_fiscale,1,5)
                    ,'00000',ltrim(substr(anve.cod_fiscale,6))
                    ,ltrim(anve.cod_fiscale)
                    )                          cod_fiscale,
              anve.anno_fiscale,
              decode(sign(anve.anno_fiscale-98)
                    ,-1,decode(anve.acconto_saldo
                              ,1,'A'
                              ,2,'S'
                              ,3,'U'
                              ,decode(sign(data_versamento - scad.data_scadenza)
                                     ,1,'S'
                                     ,'A'
                                     )
                              )
                    , decode(anve.acconto_saldo
                            ,1,'A'
                            ,2,'S'
                            ,3,'U'
                            ,decode(sign(data_versamento - scad.data_scadenza)
                                   ,1,'S','A'
                                   )
                            )
                    )                                 tipo_versamento,
              data_versamento,
              ltrim(fabbricati,0) fabbricati,
              ltrim(terreni_agricoli,0) terreni_agricoli,
              ltrim(aree_fabbricabili,0) aree_fabbricabili,
              ltrim(ab_principale,0) ab_principale,
              ltrim(altri_fabbricati,0) altri_fabbricati,
              ltrim(detrazione,0) detrazione,
              ltrim(importo_versato,0) importo_versato,
              anve.progr_record,
              decode(length(data_reg)
                    ,6,to_date(data_reg,'yymmdd')
                    ,8,to_date(data_reg,'yyyymmdd')
                    )                                  data_reg,
             nvl(anve.fonte,2) fonte,
             cont.ni ni_cont,
             anan.progr_record progr_anan,
             anso.progr_record progr_anso,
             scad.data_scadenza,
             anve.num_provvedimento num_provvedimento,
             anve.flag_ravvedimento flag_ravvedimento,
             anve.sanzione_ravvedimento sanzione_ravvedimento
        from contribuenti cont,
             anci_ana anan,
             anci_soc anso,
             anci_ver anve,
             scadenze scad
       where cont.cod_fiscale     (+) = decode(substr(anve.cod_fiscale,1,5),
                                               '00000',ltrim(substr(anve.cod_fiscale,6)),
                                               ltrim(anve.cod_fiscale))
         and anan.anno_fiscale    (+) = anve.anno_fiscale
         and anan.progr_record    (+) = anve.progr_record
         and anso.anno_fiscale    (+) = anve.anno_fiscale
         and anso.progr_record    (+) = anve.progr_record
         and scad.tipo_tributo    (+) = 'ICI'
         and scad.tipo_scadenza   (+) = 'V'
         and scad.tipo_versamento (+) = 'A'
         and scad.anno            (+) = anve.anno_fiscale
         and anve.tipo_anomalia       is null
         and anve.tipo_record         <> 6
       ;
CURSOR sel_vers (w_cod_fiscale     varchar2,
                 w_pratica         number,
                 w_anno_fiscale    number,
                 w_tipo_versamento varchar2,
                 w_data_pagamento  date,
                 w_importo_versato number) IS
      select 'x'
        from versamenti vers
       where vers.cod_fiscale     = w_cod_fiscale
         and nvl(vers.pratica,0)  = nvl(w_pratica,0)
         and vers.anno + 0        = w_anno_fiscale
         and vers.tipo_versamento = w_tipo_versamento
         and vers.data_pagamento  = w_data_pagamento
         and vers.importo_versato = w_importo_versato
         ;
CURSOR sel_anan IS
  select distinct anve.anno_fiscale,anve.tipo_anomalia,
         anan.data_elaborazione data_anan
    from anomalie_anno anan,anci_ver anve
   where anan.anno          (+) = anve.anno_fiscale
     and anan.tipo_anomalia (+) = anve.tipo_anomalia
     and anve.anno_fiscale      is not null
     and anve.tipo_anomalia     is not null
       ;
BEGIN
  begin
     select decode(fase_euro,1,1,100)
       into w_100
       from dati_generali
     ;
  exception
     when no_data_found then
        w_100 := 1;
  end;
--
-- Se il parametro di input a_conv ha valore S, significa che
-- si e` in valuta euro, ma che i dati passati sono in lire,
-- per cui, prima di procedere all`elaborazione, e` necessario
-- effettuare la conversione in euro e moltiplicare per 100.
-- I record trattati sono soltanto quelli senza anomalia, perche`
-- gli altri sono gia` stati trattati da precedenti elaborazioni.
-- IN questa sede si trattano anche i records con tipo = 6 che
-- sono oggetto del caricamento delle violazioni (fase a parte
-- lanciata a fine trattamento).
--
  if a_conv = 'S' then
     update anci_ver
        set importo_versato      = round(importo_versato      / 1936.27 , 2) * 100
           ,terreni_agricoli     = round(terreni_agricoli     / 1936.27 , 2) * 100
           ,aree_fabbricabili    = round(aree_fabbricabili    / 1936.27 , 2) * 100
           ,ab_principale        = round(ab_principale        / 1936.27 , 2) * 100
           ,altri_fabbricati     = round(altri_fabbricati     / 1936.27 , 2) * 100
           ,detrazione           = round(detrazione           / 1936.27 , 2) * 100
           ,detrazione_effettiva = round(detrazione_effettiva / 1936.27 , 2) * 100
           ,imposta_calcolata    = round(imposta_calcolata    / 1936.27 , 2) * 100
           ,imposta              = round(imposta              / 1936.27 , 2) * 100
           ,sanzioni_1           = round(sanzioni_1           / 1936.27 , 2) * 100
           ,sanzioni_2           = round(sanzioni_2           / 1936.27 , 2) * 100
           ,interessi            = round(interessi            / 1936.27 , 2) * 100
      where tipo_anomalia is null
     ;
  end if;
--
-- Gestione dei Versamenti con Anomalia 52 con flag_contribuente attivo
-- Se tali versamenti sono collegati ad un soggetto, il soggetto viene fatto diventare
-- contribuente e il versameto viene inserito.
--
  FOR rec_anci_52s IN sel_anci_52s LOOP
      begin
         select count(1)
           into w_conta_cont
           from contribuenti
          where ni = rec_anci_52s.ni_sogg
          ;
      EXCEPTION
          WHEN others THEN
          w_conta_cont := 0;
      end;
      if w_conta_cont = 0 then
        OPEN sel_vers (rec_anci_52s.cod_fiscale, null, rec_anci_52s.anno_fiscale,
              rec_anci_52s.tipo_versamento, rec_anci_52s.data_versamento,
              rec_anci_52s.importo_versato / w_100);
         FETCH sel_vers INTO w_controllo;
         w_notfound := sel_vers%NOTFOUND;
         CLOSE sel_vers;
         IF w_notfound THEN
         -- Occorre verificare che il versamento sia corretto, altrimenti non viene fatto nulla
            BEGIN
              insert into contribuenti
                     (cod_fiscale, ni)
              values (rec_anci_52s.cod_fiscale,rec_anci_52s.ni_sogg)
              ;
            END;
            BEGIN
              insert into versamenti
                (cod_fiscale,pratica,anno,tipo_tributo,tipo_versamento,
                 data_pagamento, fabbricati,terreni_agricoli,
                 aree_fabbricabili, ab_principale,altri_fabbricati,
                 detrazione, importo_versato,progr_anci,utente,
                 data_variazione,fonte)
              values (rec_anci_52s.cod_fiscale,null,rec_anci_52s.anno_fiscale, 'ICI',
                      rec_anci_52s.tipo_versamento,rec_anci_52s.data_versamento,
                      rec_anci_52s.fabbricati,rec_anci_52s.terreni_agricoli / w_100,
                      rec_anci_52s.aree_fabbricabili / w_100,rec_anci_52s.ab_principale / w_100,
                      rec_anci_52s.altri_fabbricati / w_100,rec_anci_52s.detrazione / w_100,
                      rec_anci_52s.importo_versato / w_100,rec_anci_52s.progr_record,
                      'TR4',rec_anci_52s.data_reg,rec_anci_52s.fonte)
                      ;
                BEGIN
                  delete anci_ver
                   where progr_record   = rec_anci_52s.progr_record
                     and anno_fiscale   = rec_anci_52s.anno_fiscale
                       ;
                EXCEPTION
                     WHEN others THEN
                        RAISE_APPLICATION_ERROR
                           (-20999,'Errore in cancellazione Anci Ver '||
                                   '('||SQLERRM||')');
                END;
            EXCEPTION
                WHEN others THEN
                 CONTRIBUENTI_CHK_DEL(rec_anci_52s.cod_fiscale,null);
            END;
         END IF;
      end if;
  END LOOP;
--
-- Vengono selezionati tutti i record di Anci Ver gia' identificati
-- come anomali (TIPO_ANOMALIA IS NOT NULL), per i quali, adesso,esista
-- una corrispondenza in Contribuenti.
-- Se questi sono gia' presenti in Versamenti allora viene cancellato
-- il record di Anci Ver, altrimenti si inserisce in Versamenti.
--
  FOR rec_anci_ok IN sel_anci_ok LOOP
      if rec_anci_ok.flag_ravvedimento = 1 then
         BEGIN
            select to_number(substr(max(to_char(prtr.data,'yyyymmdd')||
                                        lpad(to_char(prtr.pratica),10,'0')
                                       ),9,10
                                   )
                            )
              into w_pratica
              from pratiche_tributo      prtr
                  ,sanzioni_pratica      sapr
             where prtr.tipo_tributo||''    = 'ICI'
               and prtr.tipo_pratica        = 'V'
               and prtr.anno                = rec_anci_ok.anno_fiscale
               and prtr.cod_fiscale         = rec_anci_ok.cod_fiscale
               and sapr.pratica             = prtr.pratica
               and (    rec_anci_ok.tipo_versamento
                                            = 'A'
                    and sapr.cod_sanzione  in (1,4,5,6,7,98,101,104,105,106,107,
                                               136,151,152,155,161,162,198
                                              )
                    or  rec_anci_ok.tipo_versamento
                                            = 'S'
                    and sapr.cod_sanzione  in (8,9,21,22,23,99,108,109,121,122,
                                               123,137,153,154,156,163,164,199
                                              )
                    or  rec_anci_ok.tipo_versamento
                                            = 'U'
                   )
                   ;
            if w_pratica is not null then
               w_trovato := 'SI';
            else
               if rec_anci_ok.sanzione_ravvedimento is not null then
                  if rec_anci_ok.sanzione_ravvedimento = 'N' then
                     w_flag_infrazione := NULL;
                  else
                     w_flag_infrazione := rec_anci_ok.sanzione_ravvedimento;
                  end if;
                  CREA_RAVVEDIMENTO(rec_anci_ok.cod_fiscale
                                   ,rec_anci_ok.anno_fiscale
                                   ,rec_anci_ok.data_versamento
                                   ,rec_anci_ok.tipo_versamento
                                   ,w_flag_infrazione
                                   ,'TR4'
                                   ,'ICI'
                                   ,w_pratica
                                   );
                  if w_pratica is null then
                     RAISE NO_DATA_FOUND;
                  end if;
                  w_trovato := 'SI';
               else
                  RAISE NO_DATA_FOUND;
               end if;
            end if;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  w_trovato := 'NO';
              BEGIN
                 update anci_ver
                    set tipo_anomalia = 54
                  where progr_record   = rec_anci_ok.progr_record
                    and anno_fiscale   = rec_anci_ok.anno_fiscale
                     ;
              EXCEPTION
                WHEN others THEN
                  RAISE_APPLICATION_ERROR
                    (-20999,'Errore in aggiornamento Anci Ver (54) '||
                            '('||SQLERRM||')');
              END;
         END;
      else
         w_trovato := 'SI';
         w_pratica := null;
      end if;
      if w_trovato = 'SI' then
         OPEN sel_vers (rec_anci_ok.cod_fiscale, w_pratica, rec_anci_ok.anno_fiscale,
                        rec_anci_ok.tipo_versamento, rec_anci_ok.data_versamento,
                        rec_anci_ok.importo_versato / w_100);
         FETCH sel_vers INTO w_controllo;
         w_notfound := sel_vers%NOTFOUND;
         CLOSE sel_vers;
         IF w_notfound THEN
            BEGIN
               insert into versamenti
                     (cod_fiscale, pratica, anno, tipo_tributo, tipo_versamento,
                      data_pagamento, fabbricati, terreni_agricoli,
                      aree_fabbricabili, ab_principale, altri_fabbricati,
                      detrazione, importo_versato, progr_anci, utente,
                      data_variazione, fonte)
              values (rec_anci_ok.cod_fiscale, w_pratica, rec_anci_ok.anno_fiscale, 'ICI',
                      rec_anci_ok.tipo_versamento, rec_anci_ok.data_versamento,
                      rec_anci_ok.fabbricati, rec_anci_ok.terreni_agricoli / w_100,
                      rec_anci_ok.aree_fabbricabili / w_100, rec_anci_ok.ab_principale / w_100,
                      rec_anci_ok.altri_fabbricati / w_100, rec_anci_ok.detrazione / w_100,
                      rec_anci_ok.importo_versato / w_100, rec_anci_ok.progr_record,
                      'TR4', rec_anci_ok.data_reg, rec_anci_ok.fonte)
                      ;
                 BEGIN
                    delete anci_ver
                     where progr_record   = rec_anci_ok.progr_record
                       and anno_fiscale   = rec_anci_ok.anno_fiscale
                         ;
                 EXCEPTION
                    WHEN others THEN
                        RAISE_APPLICATION_ERROR
                            (-20999,'Errore in cancellazione Anci Ver '||
                                    '('||SQLERRM||')');
                 END;
            EXCEPTION
               WHEN others THEN
                  BEGIN
                     update anci_ver
                        set tipo_anomalia  = 54
                      where progr_record   = rec_anci_ok.progr_record
                        and anno_fiscale   = rec_anci_ok.anno_fiscale
                          ;
                  EXCEPTION
                     WHEN others THEN
                       RAISE_APPLICATION_ERROR
                         (-20999,'Errore in aggiornamento Anci Ver (54) '||
                                 '('||SQLERRM||')');
                   END;
             END;
         else
         -- Se è già presente su versamenti il record di anci_ver viene cancellato.
            BEGIN
              delete anci_ver
               where progr_record   = rec_anci_ok.progr_record
                 and anno_fiscale   = rec_anci_ok.anno_fiscale
                 and tipo_anomalia   is not null
                   ;
            EXCEPTION
              WHEN others THEN
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in cancellazione Anci Ver '||
                    '('||SQLERRM||')');
            END;
         END IF;
      end if;
  COMMIT;
  END LOOP;
  BEGIN
    update anci_ver
       set anno_fiscale = decode(sign(anno_fiscale - 92),1,to_number('19'||anno_fiscale),
                                                           to_number('20'||lpad(anno_fiscale,2,'0'))),
           data_reg     = nvl(ltrim(data_reg,0),to_char(sysdate,'yyyymmdd'))
     where anno_fiscale < 100
       and tipo_record  <> 6
    ;
  EXCEPTION
    WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Anci Ver (Anno_fiscale) '||
         '('||SQLERRM||')');
  END;
  BEGIN
    update anci_ver
       set data_versamento = to_date(
                 lpad(to_char(data_versamento,'ddmm')||
                   to_number(to_char(data_versamento,'yyyy')-100),8,'0'),
                   'ddmmyyyy')
     where data_versamento > sysdate
    ;
  EXCEPTION
    WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Anci Ver (Data_versamento) '||
         '('||SQLERRM||')');
  END;
--
-- Selezione di tutti i versamenti del 1993 (ANNO_FISCALE = 1993) per
-- valorizzare ACCONTO_SALDO (1-ACCONTO, 2-SALDO, 3-UNICO).
--
  FOR rec_anci_93 IN sel_anci_93 LOOP
      IF rec_anci_93.cod_fiscale  != w_dep_cod_fiscale THEN
         BEGIN
           select count(*)
             into w_num_versamenti
             from anci_ver
            where anno_fiscale         = 1993
              and decode(substr(cod_fiscale,1,5),
                    '00000',ltrim(substr(cod_fiscale,6)),
                    ltrim(cod_fiscale)) = rec_anci_93.cod_fiscale
                ;
           EXCEPTION
             WHEN others THEN
             RAISE_APPLICATION_ERROR
                (-20999,'Errore in ricerca Anci Ver (93) '||
                 '('||SQLERRM||')');
         END;
         w_conta_record := 0;
      END IF;
      w_conta_record := w_conta_record + 1;
      BEGIN
          update anci_ver
             set acconto_saldo  = decode(w_num_versamenti,1,3,
                                      decode(w_conta_record,1,1,2))
           where anno_fiscale       = 1993
             and decode(substr(cod_fiscale,1,5),
                        '00000',ltrim(substr(cod_fiscale,6)),
                         ltrim(cod_fiscale))  = rec_anci_93.cod_fiscale
             and progr_record     = rec_anci_93.progr_record
               ;
      EXCEPTION
           WHEN others THEN
             RAISE_APPLICATION_ERROR
                (-20999,'Errore in aggiornamento Anci Ver (93) '||
                     '('||SQLERRM||')');
      END;
      w_dep_cod_fiscale := rec_anci_93.cod_fiscale;
  END LOOP;
--
-- Aggiornamento di Anci Ana per valorizzare ANNO_FISCALE.
-- Il valore viene recuperato dal record corrispondente
-- di Anci Ver per quel PROGR_RECORD e TIPO_ANOMALIA IS NULL.
--
  BEGIN
    update anci_ana anan
       set anno_fiscale = (select anno_fiscale
              from anci_ver anve
             where anve.tipo_anomalia is null
               and anve.progr_record  = anan.progr_record)
     where anno_fiscale = 0
       and exists (select 1
                     from anci_ver anve
                    where anve.tipo_anomalia is null
                      and anve.progr_record  = anan.progr_record)
    ;
  EXCEPTION
    WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Anci Ana (96-97) '||
         '('||SQLERRM||')');
  END;
--
-- Aggiornamento di Anci Soc per valorizzare ANNO_FISCALE. Il valore
-- viene recuperato dal record corrispondente in Anci Ver per quel
-- PROGR_RECORD e TIPO_ANOMALIA IS NULL.
--
  BEGIN
    update anci_soc anso
       set anno_fiscale = (select anno_fiscale
              from anci_ver anve
             where anve.tipo_anomalia is null
               and anve.progr_record  = anso.progr_record)
     where anno_fiscale = 0
       and exists (select 1
                     from anci_ver anve
                    where anve.tipo_anomalia is null
                      and anve.progr_record  = anso.progr_record)
    ;
  EXCEPTION
    WHEN others THEN
    RAISE_APPLICATION_ERROR
      (-20999,'Errore in aggiornamento Anci Soc (96-97) '||
         '('||SQLERRM||')');
  END;
--
-- I record presenti in Anci Ver vengono inseriti in Versamenti
-- se c'e' corrispondenza con l'archivio Contribuenti, altrimenti
-- vengono flag-ati con due anomalie:
-- 51: Versamenti con Codice Fiscale errato
-- 52: Versamenti di non contribuenti
-- in base all'esistenza o meno del record corrispondente in
-- Anci Ana o Anci Soc.
--
  FOR rec_anci IN sel_anci LOOP
      if rec_anci.data_scadenza is null then
         ROLLBACK;
              BEGIN
                   update anci_ver
                       set tipo_anomalia = 54
                    where anno_fiscale = rec_anci.anno_fiscale
                    ;
              EXCEPTION
               WHEN others THEN
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in aggiornamento Anci Ver (54) '||
                          '('||SQLERRM||')');
              END;
         RAISE_APPLICATION_ERROR(-20999,'Manca Data di Scadenza');
      end if;
      IF rec_anci.ni_cont is null THEN
         IF rec_anci.progr_anan is not null or
            rec_anci.progr_anso is not null
           THEN
             BEGIN
               update anci_ver
                  set tipo_anomalia = 51
                where anno_fiscale  = rec_anci.anno_fiscale
                  and progr_record  = rec_anci.progr_record
                  ;
             EXCEPTION
                WHEN others THEN
                   RAISE_APPLICATION_ERROR
                    (-20999,'Errore in aggiornamento Anci Ver (51) '||
                            '('||SQLERRM||')');
             END;
         ELSE
            BEGIN
              update anci_ver
                 set tipo_anomalia = 52
               where anno_fiscale  = rec_anci.anno_fiscale
                 and progr_record  = rec_anci.progr_record
                   ;
            EXCEPTION
               WHEN others THEN
                  RAISE_APPLICATION_ERROR
                   (-20999,'Errore in aggiornamento Anci Ver (52) '||
                           '('||SQLERRM||')');
            END;
         END IF;
      ELSE
        if rec_anci.flag_ravvedimento = 1 then
          BEGIN
            select to_number(substr(max(to_char(prtr.data,'yyyymmdd')||
                                        lpad(to_char(prtr.pratica),10,'0')
                                       ),9,10
                                   )
                            )
              into w_pratica
              from pratiche_tributo      prtr
                  ,sanzioni_pratica      sapr
             where prtr.tipo_tributo||''    = 'ICI'
               and prtr.tipo_pratica        = 'V'
               and prtr.anno                = rec_anci.anno_fiscale
               and prtr.cod_fiscale         = rec_anci.cod_fiscale
               and sapr.pratica             = prtr.pratica
               and (    rec_anci.tipo_versamento
                                            = 'A'
                    and sapr.cod_sanzione  in (1,4,5,6,7,98,101,104,105,106,107,
                                               136,151,152,155,161,162,198
                                              )
                    or  rec_anci.tipo_versamento
                                            = 'S'
                    and sapr.cod_sanzione  in (8,9,21,22,23,99,108,109,121,122,
                                               123,137,153,154,156,163,164,199
                                              )
                    or  rec_anci.tipo_versamento
                                            = 'U'
                   )
            ;
            if w_pratica is not null then
               w_trovato := 'SI';
            else
               if rec_anci.sanzione_ravvedimento is not null then
                  if rec_anci.sanzione_ravvedimento = 'N' then
                     w_flag_infrazione := NULL;
                  else
                     w_flag_infrazione := rec_anci.sanzione_ravvedimento;
                  end if;
                  CREA_RAVVEDIMENTO(rec_anci.cod_fiscale
                                   ,rec_anci.anno_fiscale
                                   ,rec_anci.data_versamento
                                   ,rec_anci.tipo_versamento
                                   ,w_flag_infrazione
                                   ,'TR4'
                                   ,'ICI'
                                   ,w_pratica
                                   );
                  if w_pratica is null then
                     RAISE NO_DATA_FOUND;
                  end if;
                  w_trovato := 'SI';
               else
                  RAISE NO_DATA_FOUND;
               end if;
            end if;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  w_trovato := 'NO';
              BEGIN
                 update anci_ver
                    set tipo_anomalia = 54
                  where progr_record   = rec_anci.progr_record
                    and anno_fiscale   = rec_anci.anno_fiscale
                    ;
              EXCEPTION
               WHEN others THEN
                RAISE_APPLICATION_ERROR
                  (-20999,'Errore in aggiornamento Anci Ver (54) '||
                          '('||SQLERRM||')');
              END;
          END;
        else
         w_trovato := 'SI';
         w_pratica := null;
        end if;
        if w_trovato = 'SI' then
           OPEN sel_vers (rec_anci.cod_fiscale, w_pratica, rec_anci.anno_fiscale,
                rec_anci.tipo_versamento, rec_anci.data_versamento,
                rec_anci.importo_versato / w_100);
           FETCH sel_vers INTO w_controllo;
           w_notfound := sel_vers%NOTFOUND;
           CLOSE sel_vers;
           IF w_notfound THEN
              BEGIN
                insert into versamenti
                  (cod_fiscale,pratica,anno,tipo_tributo,tipo_versamento,
                   data_pagamento, fabbricati,terreni_agricoli,
                   aree_fabbricabili, ab_principale,altri_fabbricati,
                   detrazione, importo_versato,progr_anci,utente,
                   data_variazione,fonte)
                values (rec_anci.cod_fiscale,w_pratica,rec_anci.anno_fiscale, 'ICI',
                        rec_anci.tipo_versamento,rec_anci.data_versamento,
                        rec_anci.fabbricati,rec_anci.terreni_agricoli / w_100,
                        rec_anci.aree_fabbricabili / w_100,rec_anci.ab_principale / w_100,
                        rec_anci.altri_fabbricati / w_100,rec_anci.detrazione / w_100,
                        rec_anci.importo_versato / w_100,rec_anci.progr_record,
                        'TR4',rec_anci.data_reg,rec_anci.fonte)
                        ;
              EXCEPTION
                WHEN others THEN
                   BEGIN
                     update anci_ver
                        set tipo_anomalia = 54
                      where progr_record   = rec_anci.progr_record
                        and anno_fiscale   = rec_anci.anno_fiscale
                        ;
                   EXCEPTION
                WHEN others THEN
                  RAISE_APPLICATION_ERROR
                     (-20999,'Errore in aggiornamento Anci Ver (54) '||
                             '('||SQLERRM||')');
                END;
              END;
           END IF;
        end if;
        -- Se è già presente su versamenti il record di anci_ver viene cancellato.
         BEGIN
           delete anci_ver
            where progr_record   = rec_anci.progr_record
              and anno_fiscale   = rec_anci.anno_fiscale
              and tipo_anomalia is null
                ;
         EXCEPTION
          WHEN others THEN
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in cancellazione Anci Ver '||
                '('||SQLERRM||')');
         END;
      END IF;
  COMMIT;
  END LOOP;
  FOR rec_anan IN sel_anan LOOP
      IF rec_anan.data_anan is null THEN
         BEGIN
            insert into anomalie_anno (tipo_anomalia,anno,data_elaborazione)
            values (rec_anan.tipo_anomalia,rec_anan.anno_fiscale,
                    to_date(sysdate))
            ;
         EXCEPTION
            WHEN others THEN
              RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento Anomalie Anno '||
                        '('||SQLERRM||')');
          END;
      ELSE
          BEGIN
             update anomalie_anno
                set data_elaborazione = to_date(sysdate)
              where tipo_anomalia     = rec_anan.tipo_anomalia
                and anno              = rec_anan.anno_fiscale
                  ;
          EXCEPTION
             WHEN others THEN
               RAISE_APPLICATION_ERROR
                    (-20999,'Errore in aggiornamento Anomalie Anno '||
                            '('||SQLERRM||')');
          END;
      END IF;
  END LOOP;
  COMMIT;
  BEGIN
     CARICA_VIOLAZIONI_ICI('%', '%');
  END;
END;
/* End Procedure: CARICA_VERSAMENTI_ICI */
/

