--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_ici_vers stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_ICI_VERS
(a_anno               in number
,a_fonte              in number
,a_scadenza_invio     in date
,a_progressivo_invio  in number
,a_dal                in date
,a_al                 in date
) is
w_errore          varchar2(200);
errore            exception;
w_progr_record    number := 1;
w_codice_ente     varchar2(4);
w_comune          varchar2(25);
w_cap             varchar2(5);
w_numero          number := 2;
w_num_record_1    number := 0;
w_num_record_3    number := 0;
w_num_record_4_5  number := 0;
w_num_record_6    number := 0;
w_num_versamenti  number := 0;
w_sum_versamenti  number := 0;
w_tipo_riscossione varchar2(1);
w_ins_anagrafica  varchar2(1);
w_sogg_tipo       number;
cursor sel_vers ( p_anno     number
                , p_dal      date
                , p_al       date
                , p_fonte    number
                ) is
select vers.data_pagamento
     , vers.cod_fiscale
     , nvl(vers.importo_versato,0)                                              importo_versato
     , nvl(vers.terreni_agricoli,0)                                             terreni_agricoli
     , nvl(vers.aree_fabbricabili,0)                                            aree_fabbricabili
     , nvl(vers.ab_principale,0)                                                ab_principale
     , nvl(vers.altri_fabbricati,0)                                             altri_fabbricati
     , nvl(vers.detrazione,0)                                                   detrazione
     , decode( nvl(vers.importo_versato,0)
             , (nvl(vers.terreni_agricoli,0)
                + nvl(vers.aree_fabbricabili,0)
                + nvl(vers.ab_principale,0)
                + nvl(vers.altri_fabbricati,0)
               ), '0'
             , '1'
             )                                                                  quadratura
     , nvl(vers.fabbricati,0)                                                   fabbricati
     , vers.tipo_versamento
     , vers.pratica
  from versamenti         vers
     , pratiche_tributo   prtr
 where vers.anno                     = p_anno
   and vers.tipo_tributo             = 'ICI'
   and vers.pratica                  = prtr.pratica (+)
   and ( vers.pratica                 is null
       or
         prtr.tipo_pratica           = 'V'
       )
   and  fonte                        = p_fonte
   and vers.data_pagamento between p_dal
                               and p_al
 order by
       vers.cod_fiscale
;
cursor sel_viol ( p_anno     number
                , p_dal      date
                , p_al       date
                , p_fonte    number
                ) is
select vers.data_pagamento
     , vers.cod_fiscale
     , nvl(vers.importo_versato,0)                                              importo_versato
     , prtr.numero
     , prtr.data
  from versamenti         vers
     , pratiche_tributo   prtr
 where vers.anno                     = p_anno
   and vers.tipo_tributo             = 'ICI'
   and vers.pratica                  = prtr.pratica
   and prtr.tipo_pratica             in ('A','L')
   and fonte                        = p_fonte
   and vers.data_pagamento between p_dal
                               and p_al
 order by
       vers.cod_fiscale
;
function F_COD_CONTROLLO_CF
(p_cod_fiscale       IN varchar2)
RETURN varchar2
IS
      TYPE validChar IS
        VARRAY(36) OF VARCHAR2(1);
      sChar            validChar := validChar ('A','B','C','D','E','F','G','H','I','J',
                                              'K','L', 'M','N','O','P','Q','R','S','T',
                                    'U','V','W','X','Y','Z','0','1','2','3',
                                    '4','5','6','7','8','9');
      TYPE Pari IS
        VARRAY(36) OF INT;
      iPari            Pari := Pari ( 00,01,02,03,04,05,06,07,08,09,10,11,
                                      12,13,14,15,16,17,18,19,20,21,22,23,
                                      24,25,00,01,02,03,04,05,06,07,08,09);
      TYPE Disp IS
        VARRAY(36) OF INT;
      iDisp            Disp := Disp ( 01,00,05,07,09,13,15,17,19,21,02,04,
                                      18,20,11,03,06,08,12,14,16,10,22,25,
                                      24,23,01,00,05,07,09,13,15,17,19,21);
      TYPE CodiceFiscale IS
        VARRAY(16) OF VARCHAR2(1);
      sCodice          CodiceFiscale := CodiceFiscale ( NULL,NULL,NULL,NULL,
                                                       NULL,NULL,NULL,NULL,
                                          NULL,NULL,NULL,NULL,
                                          NULL,NULL,NULL,NULL);
      sCodiceFiscale   VARCHAR2(16);
      dError           NUMBER;
      iIndice          NUMBER(2);
      iIndice2         NUMBER(2);
      iSomma           NUMBER;
BEGIN
         sCodiceFiscale := p_cod_fiscale;
         -- Si trasferisce il codice in un array per poterlo analizzare
           iIndice := 0;
         WHILE iIndice < LENGTH(sCodiceFiscale) LOOP
           iIndice := iIndice + 1;
            sCodice(iIndice) := SUBSTR(sCodiceFiscale,iIndice,1);
         END LOOP;
            -- Se il Codice Fiscale e riferito ad un Omonimo, puo avere uno o piu
            -- caratteri alfabetici dove normalmente si trovano dei numeri, per
            -- cui, per eseguire correttamente il controllo, questi caratteri
            -- vengono riportati al corrispondente valore numerico che avrebbero
            -- avuto se il soggetto non fosse stato un omonimo.
            iIndice := 0;
            WHILE iIndice < 16 LOOP
               iIndice := iIndice + 1;
               IF iIndice > 6 AND iIndice < 16 AND iIndice <> 9 AND iIndice <> 12 THEN
                  IF sCodice(iIndice) = 'L' THEN
                     sCodice(iIndice) := '0';
                  END IF;
                  IF sCodice(iIndice) = 'M'THEN
                     sCodice(iIndice) := '1';
                  END IF;
                  IF sCodice(iIndice) = 'N'THEN
                     sCodice(iIndice) := '2';
                  END IF;
                  IF sCodice(iIndice) = 'P'THEN
                     sCodice(iIndice) := '3';
                  END IF;
                  IF sCodice(iIndice) = 'Q'THEN
                     sCodice(iIndice) := '4';
                  END IF;
                  IF sCodice(iIndice) = 'R'THEN
                     sCodice(iIndice) := '5';
                  END IF;
                  IF sCodice(iIndice) = 'S'THEN
                     sCodice(iIndice) := '6';
                  END IF;
                  IF sCodice(iIndice) = 'T'THEN
                     sCodice(iIndice) := '7';
                  END IF;
                  IF sCodice(iIndice) = 'U'THEN
                     sCodice(iIndice) := '8';
                  END IF;
                  IF sCodice(iIndice) = 'V'THEN
                     sCodice(iIndice) := '9';
                  END IF;
               END IF;
            END LOOP;
            iSomma   := 0;
            iIndice  := 0;
            WHILE iIndice < 15 LOOP
               iIndice := iIndice + 1;
               iIndice2 := 0;
               WHILE TRUE LOOP
                  iIndice2 := iIndice2 + 1;
                  IF sChar(iIndice2) = sCodice(iIndice) THEN
                     EXIT;
                  END IF;
               END LOOP;
               IF MOD(iIndice,2) = 0 THEN
                  iSomma := iSomma + iPari(iIndice2);
               ELSE
                  iSomma := iSomma + iDisp(iIndice2);
               END IF;
            END LOOP;
            -- Il resto della somma dei pesi divisa per 26 deve corrispondere
            -- ad un carattere della tabella Ipari il cui valore deve essere
            -- il check del Codice Fiscale (16^ carattere).
            iIndice := 0;
            WHILE TRUE LOOP
               iIndice := iIndice + 1;
               IF iPari(iIndice) = MOD(iSomma,26) THEN
                  EXIT;
               END IF;
            END LOOP;
   RETURN sChar(iIndice);
EXCEPTION
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,'Codice Fiscale '||p_cod_fiscale);
END;
function F_COD_CONTROLLO_P_IVA
(p_partita_iva  IN varchar2)
RETURN varchar2
IS
   i         NUMBER(3);
   iIndice   NUMBER(3);
   iSomma    number(3) := 0;
   sCodiceFiscale varchar2(16)  := '';
   TYPE CodiceFiscale IS VARRAY(16) OF VARCHAR2(1);
   sCodice        CodiceFiscale := CodiceFiscale ( NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL,
                                                   NULL,NULL,NULL,NULL);
BEGIN
   sCodiceFiscale := p_partita_iva;
   -- Si trasferisce il codice in un array per poterlo analizzare
     iIndice := 0;
   WHILE iIndice < LENGTH(sCodiceFiscale) LOOP
     iIndice := iIndice + 1;
      sCodice(iIndice) := SUBSTR(sCodiceFiscale,iIndice,1);
   END LOOP;
   -- Routine per la determinazione del "Peso" relativo ai primi 10 caratteri
   -- della Partita IVA.
   iSomma := 0;
   iIndice := 0;
   WHILE iIndice < 10 LOOP
       iIndice := iIndice + 1;
      IF MOD(iIndice,2) = 0 THEN
         IF sCodice(iIndice) < '5' THEN
            iSomma := iSomma + TO_NUMBER(sCodice(iIndice)) * 2;
         ELSE
            iSomma := iSomma + TO_NUMBER(sCodice(iIndice)) * 2 + 1;
         END IF;
      ELSE
         iSomma := iSomma + TO_NUMBER(sCodice(iIndice));
      END IF;
   END LOOP;
   RETURN MOD(10 - MOD(iSomma,10),10);
EXCEPTION
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,'Partita IVA '||p_partita_iva);
END;
--------------------------------------------------------------------------------
--  Inizio  --------------------------------------------------------------------
--------------------------------------------------------------------------------
BEGIN
   w_errore := null;
   -- Cancellazione Tabella temporanea
   begin
     delete wrk_trasmissioni;
   exception
     when others then
         w_errore := 'Errore nella cancellazione della tabella temporanea (' || SQLERRM || ')';
         raise errore;
   end;
   -- Esrazione dati Ente
   begin
      select comu.sigla_cfis
           , rpad(substr(comu.denominazione,1,25),25,' ')
           , rpad(comu.cap,5,' ')
        into w_codice_ente
           , w_comune
           , w_cap
        from dati_generali dage
           , ad4_comuni    comu
       where dage.com_cliente = comu.comune
         and dage.pro_cliente = comu.provincia_stato
      ;
   exception
     when others then
         w_errore := 'Errore nel recupero dei dati del Ente (' || SQLERRM || ')';
         raise errore;
   end;
   -----------------------------------------------------------------------------
   -- Inserimento Record Iniziale ----------------------------------------------
   -----------------------------------------------------------------------------
   begin
      insert into wrk_trasmissioni
            ( numero
            , dati
            )
      values( lpad('1',12,'0')
            , 'ICI0'
            ||'001'
            ||to_char(a_anno)
            ||to_char(a_scadenza_invio,'yyyymmdd')
            ||lpad(to_char(a_progressivo_invio),2,'0')
            ||'00'
            ||'00'
            ||rpad('0',175,'0')
            )
            ;
   exception
     when others then
         w_errore := 'Errore Inserimento Record Iniziale (' || SQLERRM || ')';
         raise errore;
   end;
   -----------------------------------------------------------------------------
   -- Inserimento Record Riscossione Contabile (3) -----------------------------
   -----------------------------------------------------------------------------
   FOR rec_vers in sel_vers(a_anno, a_dal, a_al, a_fonte)
   LOOP
      w_numero := w_numero + 1;
      w_progr_record := w_progr_record + 1;
      begin
         insert into wrk_trasmissioni
               ( numero
               , dati
               )
         values( lpad(to_char(w_numero),12,'0')
               , '001'                                                          -- Codice concessione
               ||w_codice_ente                                                  -- Codice ente
               ||lpad('0',10,'0')                                               -- Numero quietanza
               ||lpad(to_char(w_progr_record),8,'0')                            -- Progressivo record
               ||'3'                                                            -- Tipo record
               ||to_char(rec_vers.data_pagamento,'yyyymmdd')                    -- Data versamento
               ||lpad(rec_vers.cod_fiscale,16,' ')                              -- Codice fiscale
               ||substr(to_char(a_anno),3,2)                                    -- Anno imposta
               ||lpad('0',11,'0')                                               -- Numero riferimento quietanza
               ||lpad(to_char(rec_vers.importo_versato * 100),11,'0')           -- Importo versato dal contribuente
               ||lpad(to_char(rec_vers.terreni_agricoli * 100),10,'0')          -- Importo terreni agricoli
               ||lpad(to_char(rec_vers.aree_fabbricabili * 100),10,'0')         -- Importo aree fabbricabili
               ||lpad(to_char(rec_vers.ab_principale * 100),10,'0')             -- Importo abitazione principale
               ||lpad(to_char(rec_vers.altri_fabbricati * 100),10,'0')          -- Importo altri fabbricati
               ||lpad(to_char(rec_vers.detrazione * 100),8,'0')                 -- Importo detrazione
               ||rec_vers.quadratura                                            -- Flag quadratura
               ||'0'                                                            -- Flag reperibilita
               ||'0'                                                            -- Tipo versamento
               ||lpad('0',8,'0')                                                -- Data di registrazione
               ||'0'                                                            -- Flag di competenza del versamento
               ||w_comune                                                       -- Comune
               ||w_cap                                                          -- CAP
               ||lpad(to_char(rec_vers.fabbricati),4,'0')                       -- Numero fabbricati
               ||decode(rec_vers.tipo_versamento
                       ,'A','1'
                       ,'S','2'
                       ,'U','3'
                       ,'0'
                       )                                                        -- Flag acconto/saldo
               ||'0'                                                            -- Flag identificazione
               ||to_char(a_anno)                                                -- Periodo di riferimento del versamento
               ||decode(rec_vers.pratica,null,'0','1')                          -- Ravvedimento
               ||rpad('0',25,'0')                                               -- Filler
               )
               ;
      exception
        when others then
            w_errore := 'Errore Inserimento Record Riscossione contabile (3) (' || SQLERRM || ')';
            raise errore;
      end;
      w_num_record_3 := w_num_record_3 + 1;
      w_sum_versamenti := w_sum_versamenti + rec_vers.importo_versato;
      w_num_versamenti := w_num_versamenti + 1;
      -- Verifica per inserimento record anagrafica
      if length(rec_vers.cod_fiscale) = 16 then
         if substr(rec_vers.cod_fiscale,16,1) <> F_COD_CONTROLLO_CF(rec_vers.cod_fiscale) then
            w_ins_anagrafica := 'S';
         else
            w_ins_anagrafica := 'N';
         end if;
      elsif length(rec_vers.cod_fiscale) = 11 then
         if substr(rec_vers.cod_fiscale,11,1) <> F_COD_CONTROLLO_P_IVA(rec_vers.cod_fiscale) then
            w_ins_anagrafica := 'S';
         else
            w_ins_anagrafica := 'N';
         end if;
      else
         w_ins_anagrafica := 'S';
      end if;
      if w_ins_anagrafica = 'S' then
         -- Recupero tipo soggetto
         begin
            select nvl(sogg.tipo,2)
              into w_sogg_tipo
              from soggetti     sogg
                 , contribuenti cont
             where cont.ni = sogg.ni
               and cont.cod_fiscale = rec_vers.cod_fiscale
                 ;
         exception
           when others then
               w_errore := 'Errore recupero tipo soggetto  (' || SQLERRM || ')';
               raise errore;
         end;
         if w_sogg_tipo = 0
            or w_sogg_tipo = 2 and length(rec_vers.cod_fiscale) = 16 then
            -- Inserimento Record anagrafica persone fisiche
            w_numero := w_numero + 1;
            begin
               insert into wrk_trasmissioni
                     ( numero
                     , dati
                     )
               select lpad(to_char(w_numero),12,'0')
                     , '001'                                                       -- Codice concessione
                     ||w_codice_ente                                               -- Codice ente
                     ||lpad('0',10,'0')                                            -- Numero quietanza
                     ||lpad(to_char(w_progr_record),8,'0')                         -- Progressivo record
                     ||'4'                                                         -- Tipo record
                     ||rpad(substr(sogg.cognome,1,24),24,' ')                      -- Cognome
                     ||rpad(substr(sogg.nome,1,20),20,' ')                         -- Nome
                     ||rpad(substr(nvl(comu.denominazione,' '),1,25),25,' ')       -- Comune del domicilio fiscale
                     ||rpad('0',105,'0')                                           -- Filler
                 from contribuenti cont
                    , soggetti     sogg
                    , ad4_comuni   comu
                where cont.ni = sogg.ni
                  and sogg.cod_com_res = comu.comune (+)
                  and sogg.cod_pro_res = comu.provincia_stato (+)
                  and cont.cod_fiscale = rec_vers.cod_fiscale
                    ;
            exception
               when others then
                  w_errore := 'Errore Inserimento Record anagrafica persone fisiche (4) (' || SQLERRM || ')';
                  raise errore;
            end;
            w_num_record_4_5 := w_num_record_4_5 + 1;
         else
            -- Inserimento Record anagrafica persone giuridiche
            w_numero := w_numero + 1;
            begin
               insert into wrk_trasmissioni
                     ( numero
                     , dati
                     )
               select lpad(to_char(w_numero),12,'0')
                     , '001'                                                       -- Codice concessione
                     ||w_codice_ente                                               -- Codice ente
                     ||lpad('0',10,'0')                                            -- Numero quietanza
                     ||lpad(to_char(w_progr_record),8,'0')                         -- Progressivo record
                     ||'5'                                                         -- Tipo record
                     ||rpad(substr(sogg.cognome_nome,1,60),60,' ')                 -- Ragione sociale o denominazione
                     ||rpad(substr(nvl(comu.denominazione,' '),1,25),25,' ')       -- Comune del domicilio fiscale
                     ||rpad('0',89,'0')                                            -- Filler
                 from contribuenti cont
                    , soggetti     sogg
                    , ad4_comuni   comu
                where cont.ni = sogg.ni
                  and sogg.cod_com_res = comu.comune (+)
                  and sogg.cod_pro_res = comu.provincia_stato (+)
                  and cont.cod_fiscale = rec_vers.cod_fiscale
                    ;
            exception
               when others then
                  w_errore := 'Errore Inserimento Record anagrafica persone giuridiche (5) (' || SQLERRM || ')';
                  raise errore;
            end;
            w_num_record_4_5 := w_num_record_4_5 + 1;
         end if;
      end if;  -- w_ins_anagrafica = 'S'
   END LOOP;
   -----------------------------------------------------------------------------
   -- Inserimento Record Violazioni (6) ----------------------------------------
   -----------------------------------------------------------------------------
   FOR rec_viol in sel_viol(a_anno, a_dal, a_al, a_fonte)
   LOOP
      w_numero := w_numero + 1;
      w_progr_record := w_progr_record + 1;
      begin
         insert into wrk_trasmissioni
               ( numero
               , dati
               )
         values( lpad(to_char(w_numero),12,'0')
               , '001'                                                          -- Codice concessione
               ||w_codice_ente                                                  -- Codice ente
               ||lpad('0',10,'0')                                               -- Numero quietanza
               ||lpad(to_char(w_progr_record),8,'0')                            -- Progressivo record
               ||'6'                                                            -- Tipo record
               ||to_char(rec_viol.data_pagamento,'yyyymmdd')                    -- Data versamento
               ||lpad(rec_viol.cod_fiscale,16,' ')                              -- Codice fiscale
               ||lpad('0',2,'0')                                                -- Filler
               ||lpad('0',11,'0')                                               -- Numero riferimento quietanza
               ||lpad(to_char(rec_viol.importo_versato * 100),11,'0')           -- Importo versato dal contribuente
               ||lpad('0',48,'0')                                               -- Filler
               ||'1'                                                            -- Flag quadratura
               ||'0'                                                            -- Flag reperibilita
               ||'0'                                                            -- Tipo versamento
               ||lpad('0',8,'0')                                                -- Data di registrazione
               ||'0'                                                            -- Flag di competenza del versamento
               ||w_comune                                                       -- Comune
               ||w_cap                                                          -- CAP
               ||lpad('0',5,'0')                                                -- Filler
               ||'0'                                                            -- Flag identificazione
               ||'1'                                                            -- Flag tipo imposta
               ||lpad(rec_viol.numero,9,'0')                                    -- Numero provvedimento di liquidazione
               ||to_char(rec_viol.data,'ddmmyyyy')                              -- data provvedimento di liquidazione
               ||rpad('0',12,'0')                                               -- Filler
               )
               ;
      exception
        when others then
            w_errore := 'Errore Inserimento Record Violazioni (6) (' || SQLERRM || ')';
            raise errore;
      end;
      w_num_record_6 := w_num_record_6 + 1;
      w_sum_versamenti := w_sum_versamenti + rec_viol.importo_versato;
      w_num_versamenti := w_num_versamenti + 1;
      -- Verifica per inserimento record anagrafica
      if length(rec_viol.cod_fiscale) = 16 then
         if substr(rec_viol.cod_fiscale,16,1) <> F_COD_CONTROLLO_CF(rec_viol.cod_fiscale) then
            w_ins_anagrafica := 'S';
         else
            w_ins_anagrafica := 'N';
         end if;
      elsif length(rec_viol.cod_fiscale) = 11 then
         if substr(rec_viol.cod_fiscale,11,1) <> F_COD_CONTROLLO_P_IVA(rec_viol.cod_fiscale) then
            w_ins_anagrafica := 'S';
         else
            w_ins_anagrafica := 'N';
         end if;
      else
         w_ins_anagrafica := 'S';
      end if;
      if w_ins_anagrafica = 'S' then
         -- Recupero tipo soggetto
         begin
            select nvl(sogg.tipo,2)
              into w_sogg_tipo
              from soggetti     sogg
                 , contribuenti cont
             where cont.ni = sogg.ni
               and cont.cod_fiscale = rec_viol.cod_fiscale
                 ;
         exception
           when others then
               w_errore := 'Errore recupero tipo soggetto  (' || SQLERRM || ')';
               raise errore;
         end;
         if w_sogg_tipo = 0
            or w_sogg_tipo = 2 and length(rec_viol.cod_fiscale) = 16 then
            -- Inserimento Record anagrafica persone fisiche
            w_numero := w_numero + 1;
            begin
               insert into wrk_trasmissioni
                     ( numero
                     , dati
                     )
               select lpad(to_char(w_numero),12,'0')
                     , '001'                                                       -- Codice concessione
                     ||w_codice_ente                                               -- Codice ente
                     ||lpad('0',10,'0')                                            -- Numero quietanza
                     ||lpad(to_char(w_progr_record),8,'0')                         -- Progressivo record
                     ||'4'                                                         -- Tipo record
                     ||rpad(substr(sogg.cognome,1,24),24,' ')                      -- Cognome
                     ||rpad(substr(sogg.nome,1,20),20,' ')                         -- Nome
                     ||rpad(substr(nvl(comu.denominazione,' '),1,25),25,' ')       -- Comune del domicilio fiscale
                     ||rpad('0',105,'0')                                           -- Filler
                 from contribuenti cont
                    , soggetti     sogg
                    , ad4_comuni   comu
                where cont.ni = sogg.ni
                  and sogg.cod_com_res = comu.comune (+)
                  and sogg.cod_pro_res = comu.provincia_stato (+)
                  and cont.cod_fiscale = rec_viol.cod_fiscale
                    ;
            exception
               when others then
                  w_errore := 'Errore Inserimento Record anagrafica persone fisiche (4) (' || SQLERRM || ')';
                  raise errore;
            end;
            w_num_record_4_5 := w_num_record_4_5 + 1;
         else
            -- Inserimento Record anagrafica persone giuridiche
            w_numero := w_numero + 1;
            begin
               insert into wrk_trasmissioni
                     ( numero
                     , dati
                     )
               select lpad(to_char(w_numero),12,'0')
                     , '001'                                                       -- Codice concessione
                     ||w_codice_ente                                               -- Codice ente
                     ||lpad('0',10,'0')                                            -- Numero quietanza
                     ||lpad(to_char(w_progr_record),8,'0')                         -- Progressivo record
                     ||'5'                                                         -- Tipo record
                     ||rpad(substr(sogg.cognome_nome,1,60),60,' ')                 -- Ragione sociale o denominazione
                     ||rpad(substr(nvl(comu.denominazione,' '),1,25),25,' ')       -- Comune del domicilio fiscale
                     ||rpad('0',89,'0')                                            -- Filler
                 from contribuenti cont
                    , soggetti     sogg
                    , ad4_comuni   comu
                where cont.ni = sogg.ni
                  and sogg.cod_com_res = comu.comune (+)
                  and sogg.cod_pro_res = comu.provincia_stato (+)
                  and cont.cod_fiscale = rec_viol.cod_fiscale
                    ;
            exception
               when others then
                  w_errore := 'Errore Inserimento Record anagrafica persone giuridiche (5) (' || SQLERRM || ')';
                  raise errore;
            end;
            w_num_record_4_5 := w_num_record_4_5 + 1;
         end if;
      end if;  -- w_ins_anagrafica = 'S'
   END LOOP;
   -----------------------------------------------------------------------------
   -- Inserimento Record Riversamento ------------------------------------------
   -----------------------------------------------------------------------------
   if w_num_record_3 > 0 then
      if w_num_record_6 > 0 then
         w_tipo_riscossione := 'M';
      else
         w_tipo_riscossione := 'O';
      end if;
   else
      if w_num_record_6 > 0 then
         w_tipo_riscossione := 'V';
      else
         w_tipo_riscossione := 'X'; -- nessun versamento estratto
      end if;
   end if;
   if w_tipo_riscossione <> 'X' then
      begin
         insert into wrk_trasmissioni
               ( numero
               , dati
               )
         values( lpad('2',12,'0')
               , '001'                                                             -- Codice concessione
               ||w_codice_ente                                                     -- Codice ente
               ||lpad('0',10,'0')                                                  -- Numero quietanza
               ||lpad('1',8,'0')                                                   -- Progressivo record
               ||'1'                                                               -- Tipo record
               ||lpad('0',8,'0')                                                   -- Data riversamento
               ||lpad('0',3,'0')                                                   -- Codice tesoreria
               ||lpad(to_char(w_sum_versamenti * 100),13,'0')                      -- Importo riversato
               ||lpad('0',10,'0')                                                  -- Commissione
               ||lpad(to_char(w_num_versamenti),6,'0')                             -- Numero riscossioni
               ||'0'                                                               -- Flag tipo riversamento
               ||w_tipo_riscossione                                                -- Tipologia di riscossioni riversate
               ||rpad('0',132,'0')                                                 -- Filler
               )
               ;
      exception
        when others then
            w_errore := 'Errore Inserimento Record Riversamento (1) (' || SQLERRM || ')';
            raise errore;
      end;
      w_num_record_1 := w_num_record_1 + 1;
   end if;
   -----------------------------------------------------------------------------
   -- Inserimento Record Finale ------------------------------------------------
   -----------------------------------------------------------------------------
   w_numero := w_numero + 1;
   begin
      insert into wrk_trasmissioni
            ( numero
            , dati
            )
      values( lpad(to_char(w_numero),12,'0')
            , 'ICI9'
            ||'001'
            ||to_char(a_anno)
            ||to_char(a_scadenza_invio,'yyyymmdd')
            ||lpad(to_char(a_progressivo_invio),2,'0')
            ||lpad(to_char(w_num_record_1),10,'0')
            ||lpad(to_char(w_num_record_3),10,'0')
            ||lpad(to_char(w_num_record_4_5),10,'0')
            ||lpad(to_char(w_num_record_6),10,'0')
            ||rpad('0',139,'0')
            )
            ;
   exception
     when others then
         w_errore := 'Errore Inserimento Record Iniziale (' || SQLERRM || ')';
         raise errore;
   end;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: ESTRAZIONE_ICI_VERS */
/

