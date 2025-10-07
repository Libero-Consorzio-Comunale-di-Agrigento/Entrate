--liquibase formatted sql 
--changeset abrandolini:20250326_152423_trasmissione_ruolo_600 stripComments:false runOnChange:true
 
CREATE OR REPLACE procedure     TRASMISSIONE_RUOLO_600
/*************************************************************************
 NOME:        TRASMISSIONE_RUOLO_600
 DESCRIZIONE: Trasmissione ruoli su file con nuovo tracciato (riga di
              600 caratteri).
 NOTE:
 Rev.    Date         Author      Note
 006     21/07/2025   MF          #81414 reso sempre maiuscoli 
                                  i campi nome, cognome e cognome_nome
 005     14/01/2025   AB          #77674 sistemato cap e zipcode per sogg recsog e recpre
                                  e sistemato controllo su recapiti_soggetto
 004     12/08/2024   AB          #74395 Controllo della lunghezza del numero nella pratica
 003     03/08/2023   AB          #66283 Sistemati i due messaggi di errore
 002     11/07/2022   VD          Eliminata rottura di controllo per
                                  contribuente: ora i dati anagrafici
                                  vengono ripetuti per ogni atto, anche se
                                  l'atto si riferisce allo stesso contribuente
                                  dell'atto precedente.
 001     20/06/2022   VD          Modificata determinazione data ultimo
                                  pagamento: ora e' la data di notifica
                                  della pratica + 90 gg.
 000     22/11/2021   VD          Prima emissione.
*************************************************************************/
( a_sessione                      IN number,
  a_nome_p                        IN varchar2,
  a_tipo_elab                     IN varchar2
) IS
  w_cod_istat                          varchar2(6);
  w_ruolo                              number;
  w_tipo_tributo                       varchar2(5);
  w_anno_ruolo                         number;
  w_anno_file                          number;
  w_flag_iciap                         number := 0;
  w_cod_ente                           varchar2(5);
  w_tipo_ufficio                       varchar2(1);
  w_cod_ufficio                        varchar2(6);
  w_dati_delibera                      varchar2(26);
  w_anno_emissione                     number;
  w_progr_file                         number := 0;
  w_progressivo                        number := 0;
  w_progr_record                       number := 0;
  w_conta_ruolo                        number := 0;
  w_tot_record_e20                     number := 0;
  w_tot_record_e23                     number := 0;
  w_tot_record_e50                     number := 0;
  w_tot_record_e60                     number := 0;
  w_tot_importo_flusso                 number := 0;
  w_ni_prec                            number;
  w_num_atto_prec                      varchar2(12);
  w_data_ultimo_pag                    date;
  w_num_partita                        number := 0;
  w_progr_articolo                     number := 0;
  w_tot_importo_atto                   number := 0;
  w_cod_fiscale                        varchar2(16);
  w_ni_presso                          number;
  w_natura_soggetto                    number;
  w_flag_rappresentante                varchar2(1);
  w_flag_coobbligati                   number;
  w_riga_600                           varchar2(600);
  w_stringa                            varchar2(600);
  w_stringa_atto                       varchar2(200);
  w_stringa_soggetto                   varchar2(338);
  errore               exception;
  w_errore             varchar2(2000);
  -- Selezione ruoli da trattare da tabella PARAMETRI
  CURSOR sel_para IS
    select valore
      from parametri
     where parametri.sessione = a_sessione
       and parametri.nome_parametro = a_nome_p;
-- Selezione dati per ruolo
  CURSOR sel_sapr IS
    select sogg.ni,
           nvl(coti.cod_entrata, sanz.tributo) cod_entrata,
           decode(sanz.tipo_causale,'E','I'
                                   ,'I','T'
                                   ,'S','A'
                                   ,'S'
                  ) tipo_entrata,
           prtr.anno,
           prtr.data               data_emissione_atto,
           prtr.numero             numero_atto,
           prtr.data_notifica      data_notifica_atto,
           -- (VD - 20/06/2022): determinazione data ultimo pagamento =
           --                    data notifica + 90 gg
           --decode(ruol.rate
           --      ,4,ruol.scadenza_rata_4
           --      ,3,ruol.scadenza_rata_3
           --      ,2,ruol.scadenza_rata_2
           --      ,ruol.scadenza_prima_rata) data_ultimo_pagamento,
           prtr.data_notifica + 90        data_ultimo_pagamento,
           sum(nvl(sapr.importo_ruolo,0)) importo,
           cont.cod_fiscale
      from soggetti             sogg,
           contribuenti         cont,
           ruoli                ruol,
           pratiche_tributo     prtr,
           sanzioni_pratica     sapr,
           sanzioni             sanz,
           codici_tributo       coti
     where sogg.ni                 = cont.ni
       and cont.cod_fiscale        = prtr.cod_fiscale
       and prtr.pratica            = sapr.pratica
       and sapr.tipo_tributo       = sanz.tipo_tributo
       and sapr.cod_sanzione       = sanz.cod_sanzione
       and sapr.sequenza_sanz      = sanz.sequenza
       and coti.tributo            = sanz.tributo
       and ruol.ruolo              = sapr.ruolo
       and sapr.ruolo              = w_ruolo
  group by sogg.ni,
           cont.cod_fiscale,
           nvl(coti.cod_entrata, sanz.tributo),
           decode(sanz.tipo_causale,'E','I'
                                   ,'I','T'
                                   ,'S','A'
                                   ,'S'
                  ),
           prtr.anno,
           prtr.data,
           prtr.numero,
           prtr.data_notifica  /*,
           decode(ruol.rate
                 ,4,ruol.scadenza_rata_4
                 ,3,ruol.scadenza_rata_3
                 ,2,ruol.scadenza_rata_2
                 ,ruol.scadenza_prima_rata) */
 having sum(nvl(sapr.importo_ruolo,0)) > 0
  order by sogg.ni,prtr.numero,nvl(coti.cod_entrata, sanz.tributo),
           decode(sanz.tipo_causale,'E','I'
                                   ,'I','T'
                                   ,'S','A'
                                   ,'S'
                 );
--------------------------------------------------------------------------------
function F_GET_IDENTIFICATIVO_ATTO
( p_cod_ente                           varchar2
, p_tipo_ufficio                       varchar2
, p_cod_ufficio                        varchar2
, p_anno_emissione                     number
, p_num_partita                        number
, p_data_emissione_atto                date
, p_numero_atto                        varchar2
, p_data_notifica_atto                 date
) return varchar2 is
  w_stringa                            varchar2(200);
begin
  w_stringa := lpad(p_cod_ente, 5, '0')
            || p_tipo_ufficio
            || rpad(p_cod_ufficio,6)
            || to_char(p_anno_emissione)
            || '005'                                    -- tipologia atto
            || lpad(p_num_partita,9,'0')
            || '001'                                    -- progr_partita
            || 'AA'                                     -- codice tipo atto
            || to_char(p_data_emissione_atto,'yyyymmdd')
            || rpad(p_numero_atto,12)
            || to_char(p_data_notifica_atto,'yyyymmdd')
            || rpad(' ',40);                             -- filler
  return w_stringa;
end;
--------------------------------------------------------------------------------
function F_GET_DATI_ANAGRAFICI
( p_ni                                 number
, p_ni_presso                          number
, p_natura_soggetto                    number
, p_flag_rappresentante                varchar2
, p_tipo_tributo                       varchar2
, p_data                               date
) return varchar2 is
  w_stringa                            varchar2(338);
  recpre                               soggetti%rowtype;
  recsog                               recapiti_soggetto%rowtype;
begin
  -- Se il soggetto e' assente si esce dalla function con risultato a spazio
  if p_natura_soggetto is null then
     if p_flag_rappresentante is null then
        w_stringa := rpad(' ',338);
     else
        w_stringa := rpad(' ',308);
     end if;
     return w_stringa;
  end if;
  -- Trattamento rappresentante: il flag rappresentante contiene il codice
  -- carica. Il valore 'X' indica che si tratta di un erede, quindi i dati
  -- anagrafici sono ricavati dalla tabella SOGGETTI per l'ni indicato.
  if nvl(p_flag_rappresentante,'X') <> 'X' then
     begin
       select rpad(nvl(sogg.cod_fiscale_rap,' '),16)
           || rpad(decode(instr(sogg.rappresentante,'/')
                         ,0,rtrim(substr(sogg.rappresentante,1,instr(sogg.rappresentante,' ')))
                         ,rtrim(substr(sogg.rappresentante,1,instr(sogg.rappresentante,'/')),'/')
                         )
                  ,50)
           || rpad(decode(instr(sogg.rappresentante,'/')
                               ,0,ltrim(substr(sogg.rappresentante,instr(sogg.rappresentante,' ')))
                               ,ltrim(substr(sogg.rappresentante,instr(sogg.rappresentante,'/')),'/')
                         )
                  ,40)
           || nvl(tr4_codice_fiscale.get_sesso(sogg.cod_fiscale_rap),' ')
           || nvl(to_char(tr4_codice_fiscale.get_data_nas(sogg.cod_fiscale_rap),'yyyymmdd'),'00000000')
           || nvl(substr(sogg.cod_fiscale_rap,12,4),'    ')
           || nvl(ad4_provincia.get_sigla(tr4_codice_fiscale.get_provincia_nas(sogg.cod_fiscale_rap)),'EE')
           || nvl(ad4_comune.get_sigla_cfis(sogg.cod_pro_rap,sogg.cod_com_rap),'    ')
           || rpad(nvl(ad4_comune.get_denominazione(sogg.cod_pro_rap,sogg.cod_com_rap),' '),45)
           || nvl(ad4_provincia.get_sigla(sogg.cod_pro_rap),'EE')
           || lpad(nvl(ad4_comune.get_cap(sogg.cod_pro_rap,sogg.cod_com_rap),'0'),5,'0')
           || rpad(nvl(sogg.indirizzo_rap,' '),80)
           || lpad('0',5,'0')   -- numero civico
           || '  '              -- lettera numero civico
           || lpad('0',6,'0')   -- chilometro
           || '   '             -- palazzina
           || '   '             -- scala
           || '   '             -- piano
           || '    '            -- interno
           || rpad(' ',25)      -- localita
         into w_stringa
         from soggetti sogg
        where sogg.ni = p_ni;
     exception
       when others then
         w_stringa := rpad(' ',308);
     end;
     return w_stringa;
  end if;
  -- Se si tratta un soggetto o un erede, si selezionano i dati di un eventuale
  -- "presso" oppure i dati di recapito
  if p_ni_presso is not null then
     begin
       select *
         into recpre
         from soggetti
        where ni = p_ni_presso;
     exception
       when others then
         recpre := null;
     end;
  else
     begin
       select *
         into recsog
         from recapiti_soggetto
        where ni = p_ni
          and tipo_tributo = p_tipo_tributo
          and tipo_recapito = 1
          and p_data between nvl(dal,to_date('01/01/1900','dd/mm/yyyy'))
                         and nvl(al,to_date('01/01/3900','dd/mm/yyyy'));
     exception
       when no_data_found then
         begin
           select *
             into recsog
             from recapiti_soggetto
            where ni = p_ni
              and tipo_tributo is null  -- AB 14/01/2025 c'era lo stesso contorllo della query sopra ( = p_tipo_tributo)
              and tipo_recapito = 1
              and p_data between nvl(dal,to_date('01/01/1900','dd/mm/yyyy'))
                             and nvl(al,to_date('01/01/3900','dd/mm/yyyy'));
         exception
           when others then
             recsog := null;
         end;
       when others then
         recsog := null;
     end;
  end if;
  -- Si compone la riga con i dati anagrafici
  begin
    select rpad(nvl(cont.cod_fiscale,sogg.cod_fiscale),16,' ')
        || rpad(substr(UPPER(decode(p_natura_soggetto,1,sogg.cognome,sogg.cognome_nome)),1,80),80)
        || rpad(substr(UPPER(decode(p_natura_soggetto,1,nvl(sogg.nome,' '),' ')),1,40),40)
        || decode(p_natura_soggetto,1,nvl(sogg.sesso,' '),' ')
        || decode(p_natura_soggetto,1,nvl(to_char(sogg.data_nas,'yyyymmdd'),'00000000')
                 ,'00000000')
        || decode(p_natura_soggetto
                 ,1,nvl(ad4_comune.get_sigla_cfis(sogg.cod_pro_nas,sogg.cod_com_nas)
                       ,'    ')
                 ,'    ')
        || decode(p_natura_soggetto
                 ,1,nvl(ad4_provincia.get_sigla(sogg.cod_pro_nas),'EE')
                 ,'  ')
        || decode(p_ni_presso
                 ,null,decode(recsog.id_recapito
                             ,null,ad4_comune.get_sigla_cfis(sogg.cod_pro_res,sogg.cod_com_res)
                             ,ad4_comune.get_sigla_cfis(recsog.cod_pro,recsog.cod_com))
                 ,ad4_comune.get_sigla_cfis(recpre.cod_pro_res,recpre.cod_com_res)
                 )
        || rpad(decode(p_ni_presso
                      ,null,decode(recsog.id_recapito
                                  ,null,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res)
                                  ,ad4_comune.get_denominazione(recsog.cod_pro,recsog.cod_com)
                                  )
                      ,ad4_comune.get_denominazione(recpre.cod_pro_res,recpre.cod_com_res)
                      )
               ,45)
        || nvl(decode(p_ni_presso
                 ,null,decode(recsog.id_recapito
                             ,null,ad4_provincia.get_sigla(sogg.cod_pro_res)
                             ,ad4_provincia.get_sigla(recsog.cod_pro)
                             )
                 ,ad4_provincia.get_sigla(recpre.cod_pro_res)
                 ),'EE')
        || lpad(to_char(decode(p_ni_presso
                              ,null,decode(recsog.id_recapito
                                          ,null,decode(sogg.cap,'',nvl(substr(replace(sogg.zipcode,' ',''),1,5),'0')
                                                               ,'99999',nvl(substr(replace(sogg.zipcode,' ',''),1,5),'0')
                                                               ,sogg.cap)
                                          ,decode(recsog.cap,'',nvl(substr(replace(recsog.zipcode,' ',''),1,5),'0')
                                                               ,'99999',nvl(substr(replace(recsog.zipcode,' ',''),1,5),'0')
                                                               ,recsog.cap)
                                          )
                              ,decode(recpre.cap,'',nvl(substr(replace(recpre.zipcode,' ',''),1,5),'0')
                                                               ,'99999',nvl(substr(replace(recpre.zipcode,' ',''),1,5),'0')
                                                               ,recpre.cap)
                              )
                       )
               ,5,'0'
               )
        || rpad(decode(p_ni_presso
                      ,null,decode(recsog.id_recapito
                                  ,null,decode(sogg.cod_via
                                              ,null,denominazione_via
                                              ,f_get_denominazione_via(sogg.cod_via)
                                              )
                                  ,decode(recsog.cod_via
                                         ,null,substr(recsog.descrizione,1,80)
                                         ,f_get_denominazione_via(recsog.cod_via)
                                         )
                                  )
                      ,decode(recpre.cod_via
                             ,null,recpre.denominazione_via
                             ,f_get_denominazione_via(recpre.cod_via)
                             )
                       )
               ,80
               )
        || lpad(to_char(nvl(decode(p_ni_presso
                                  ,null,decode(recsog.id_recapito
                                              ,null,sogg.num_civ
                                              ,recsog.num_civ
                                              )
                                  ,recpre.num_civ
                                  )
                           ,0
                           )
                       )
               ,5,'0'
               )
        || rpad(substr(nvl(decode(p_ni_presso
                                 ,null,decode(recsog.id_recapito
                                             ,null,sogg.suffisso
                                             ,recsog.suffisso
                                             )
                                 ,recpre.suffisso
                                 )
                          ,' '
                          )
                      ,1,2
                      )
               ,2
               )
        || lpad('0',6,'0') -- chilometro
        || rpad(' ',3)     -- palazzina
        || rpad(substr(nvl(decode(p_ni_presso
                                 ,null,decode(recsog.id_recapito
                                             ,null,sogg.scala
                                             ,recsog.scala
                                             )
                                 ,recpre.scala
                                 )
                          ,' '
                          )
                      ,1,3
                      )
               ,3
               )
        || rpad(substr(nvl(decode(p_ni_presso
                                 ,null,decode(recsog.id_recapito
                                             ,null,sogg.piano
                                             ,recsog.piano
                                             )
                                 ,recpre.piano
                                 )
                          ,' '
                          )
                      ,1,3
                      )
               ,3
               )
        || rpad(nvl(to_char(decode(p_ni_presso
                                  ,null,decode(recsog.id_recapito
                                              ,null,sogg.interno
                                              ,recsog.interno
                                              )
                                  ,recpre.interno
                                  )
                           )
                   ,' '
                   )
               ,4
               )
         || rpad(' ',25)    -- localita
      into w_stringa
      from soggetti sogg
         , contribuenti cont
     where sogg.ni = p_ni
       and sogg.ni = cont.ni (+);
  exception
    when others then
      w_stringa := lpad(' ',338);
  end;
  return w_stringa;
end;
--------------------------------------------------------------------------------
-- PRINCIPALE
--------------------------------------------------------------------------------
BEGIN
  w_cod_fiscale := null;
  -- Estrazione dei dati del Comune
  -- per eventuali personalizzazioni (attualmente non usato)
  BEGIN
    select lpad(to_char(pro_cliente), 3, '0') ||
           lpad(to_char(com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali;
  EXCEPTION
    WHEN no_data_found THEN
        w_errore := 'Elaborazione terminata con anomalie:
                          mancano i codici ISTAT identificativi del Comune.
                          Caricare la tabella relativa ai Dati Generali dell''Ente.';
        RAISE errore;
      WHEN others THEN
        w_errore := 'Errore in ricerca Dati Generali. (1)' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
  END;
  -- Inizializzazione parametri vari
  w_dati_delibera  := nvl(f_inpa_valore('RUOLI_DELI')
                         ,rpad(' ',10)||lpad('0',8,'0')||rpad('0',8,'0'));
  w_anno_file      := extract (year from sysdate);
  w_progr_file     := f_get_progr_invio_ruoli(w_anno_file);
  w_progr_file     := w_progr_file + 1;
  FOR rec_para IN sel_para LOOP
    w_ruolo       := to_number(rec_para.valore);
    w_conta_ruolo := w_conta_ruolo + 1;
    BEGIN
      select tipo_tributo,
             anno_ruolo
        into w_tipo_tributo,
             w_anno_ruolo
        from ruoli
       where ruolo = w_ruolo;
    EXCEPTION
      WHEN no_data_found THEN
        w_errore := 'Errore in ricerca Ruoli. (1)' || ' (' || SQLERRM || ')';
        RAISE errore;
      WHEN others THEN
        null;
    END;
    --   CONTROLLO ICIAP
    BEGIN
      select 1 into w_flag_iciap from dual where w_tipo_tributo = 'ICIAP';
    EXCEPTION
      WHEN no_data_found THEN
        null;
      WHEN others THEN
        w_errore := 'Errore in controllo ICIAP.' || ' (' || SQLERRM || ')';
        RAISE errore;
    END;
    --   CONTROLLO IRL 2
    BEGIN
      select cod_ente
           , tipo_ufficio
           , cod_ufficio
        into w_cod_ente
           , w_tipo_ufficio
           , w_cod_ufficio
        from tipi_tributo
       where tipo_tributo = w_tipo_tributo;
    EXCEPTION
      WHEN no_data_found THEN
        w_cod_ente := null;
      WHEN others THEN
        w_errore := 'Errore in ricerca Tipi Tributo. (1)' || ' (' ||
                    SQLERRM || ')';
        RAISE errore;
    END;
    if w_cod_ente is null or
       w_tipo_ufficio is null or
       w_cod_ufficio is null then
       w_errore := 'Elaborazione terminata con anomalie: ' ||
                   'mancano uno o piu'' codici identificativi ' ||
                   'del Comune. Caricarli nella tabella relativa ai Tipi_Tributo.';
       RAISE errore;
    end if;
    --   IN TRATTAMENTO
    IF w_conta_ruolo = 1 THEN
       w_riga_600 := 'E00'
                  || lpad(w_cod_ente, 5, '0')
                  || w_tipo_ufficio
                  || rpad(w_cod_ufficio,6)
                  || to_char(sysdate, 'yyyymmdd')
                  || w_anno_file || '7' || lpad(w_progr_file,5,'0')
                  || rpad(' ',567);
      w_progressivo     := w_progressivo + 1;
      BEGIN
        insert into wrk_trasmissione_ruolo
          (ruolo, progressivo, dati)
        values
          (w_ruolo, w_progressivo, w_riga_600);
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in inserimento record E00' || '(' || SQLERRM || ')';
          RAISE errore;
      END;
    END IF;
    --   TRATTAMENTO RUOLO
    w_ni_prec       := -1;
    w_num_atto_prec := '*';
    FOR rec_sapr IN sel_sapr LOOP
      w_riga_600   := '';
      w_anno_emissione := extract (year from rec_sapr.data_emissione_atto);
      --
      if rec_sapr.numero_atto <> w_num_atto_prec then
         if length(rec_sapr.numero_atto) > 12 then  -- AB (12/08/2024)
            w_errore := 'Esistono pratiche di '||rec_sapr.cod_fiscale||
                        ' col numero '|| rec_sapr.numero_atto||' che ha piu'' di 12 caratteri consentiti';
            RAISE errore;
         end if;

         if w_num_atto_prec <> '*' then
            w_stringa := w_dati_delibera
                      || '3'  -- Tipologia sospensione - 3 = nessuna sospensione
                      || lpad(w_tot_importo_atto * 100,15,'0')
                      || lpad(w_progr_articolo,7,'0')
                      || to_char(w_data_ultimo_pag,'yyyymmdd')
                      || 'N'  -- Flag ente terzo - N = Non presente
                      || rpad(' ',60)  -- Denominazione ente terzo
                      || rpad(' ',371);
            w_progressivo     := w_progressivo + 1;
            w_progr_record := w_progr_record + 1;
            w_tot_record_e60  := w_tot_record_e60 + 1;
            w_riga_600 := 'E60'||lpad(w_progr_record,7,'0')
                       || w_stringa_atto || w_stringa;
            BEGIN
              insert into wrk_trasmissione_ruolo
                (ruolo, progressivo, dati)
              values
                (w_ruolo, w_progressivo, w_riga_600);
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento record E60 ' || '(' || SQLERRM || ')';
                RAISE errore;
            END;
         end if;
         w_num_atto_prec := rec_sapr.numero_atto;
         w_data_ultimo_pag := rec_sapr.data_ultimo_pagamento;
         w_num_partita := w_num_partita + 1;
         w_progr_articolo := 0;
         w_tot_importo_atto := 0;
         w_progr_record := w_progr_record + 1;
         w_stringa_atto := f_get_identificativo_atto ( w_cod_ente
                                                     , w_tipo_ufficio
                                                     , w_cod_ufficio
                                                     , w_anno_emissione
                                                     , w_num_partita
                                                     , rec_sapr.data_emissione_atto
                                                     , rec_sapr.numero_atto
                                                     , rec_sapr.data_notifica_atto
                                                     );
         w_riga_600 := 'E20'||lpad(w_progr_record,7,'0') || w_stringa_atto;
         --
         -- (VD - 08/07/2022): eliminata rottura di controllo per contribuente
         --                    Ogni atto deve essere completo di dati anagrafici
         --                    anche se relativo allo stesso contribuente
         --                    dell'atto precedente
         w_ni_prec          := rec_sapr.ni;
         begin
           select cont.cod_fiscale
                , ni_presso
                , decode(sogg.tipo_residente
                        ,0,1
                        ,decode(sogg.tipo
                               ,0,1
                               ,1,2
                               ,decode(instr(sogg.cognome_nome,'/'),0,2,1)))
                , decode(sogg.rappresentante,null,' ',nvl(tica.cod_soggetto,' '))  -- presenza ulteriori destinatari
                , decode((select count(*) from eredi_soggetto where ni = rec_sapr.ni)
                        ,0,1,2) -- presenza coobbligati
             into w_cod_fiscale
                , w_ni_presso
                , w_natura_soggetto
                , w_flag_rappresentante
                , w_flag_coobbligati
             from soggetti sogg
                , contribuenti cont
                , tipi_carica tica
            where sogg.ni = rec_sapr.ni
              and sogg.ni = cont.ni
              and sogg.tipo_carica = tica.tipo_carica(+);
         exception
           when others then
             w_natura_soggetto := to_number(null);
         end;
         w_stringa_soggetto := f_get_dati_anagrafici ( rec_sapr.ni
                                                     , w_ni_presso
                                                     , w_natura_soggetto
                                                     , ''
                                                     , w_tipo_tributo
                                                     , rec_sapr.data_notifica_atto
                                                     );
         w_riga_600 := w_riga_600||w_flag_rappresentante||w_flag_coobbligati||
                       w_natura_soggetto||w_stringa_soggetto||rpad(' ',148);
         w_progressivo     := w_progressivo + 1;
         w_tot_record_e20  := w_tot_record_e20 + 1;
         BEGIN
           insert into wrk_trasmissione_ruolo
             (ruolo, progressivo, dati)
           values
             (w_ruolo, w_progressivo, w_riga_600);
         EXCEPTION
           WHEN others THEN
             w_errore := 'Errore in inserimento record E20 principale ' || '(' || SQLERRM || ')';
             RAISE errore;
         END;
         -- Trattamento rappresentante
         if w_flag_rappresentante <> ' ' then
            w_stringa_soggetto := f_get_dati_anagrafici ( rec_sapr.ni
                                                        , w_ni_presso
                                                        , w_natura_soggetto
                                                        , w_flag_rappresentante
                                                        , w_tipo_tributo
                                                        , rec_sapr.data_notifica_atto
                                                        );
            w_progressivo  := w_progressivo + 1;
            w_progr_record := w_progr_record + 1;
            w_riga_600 := 'E23'||lpad( w_progr_record,7,'0')
                       || w_stringa_atto||rpad(w_cod_fiscale,16,' ')
                       || w_stringa_soggetto||rpad(' ',165);
            w_tot_record_e23  := w_tot_record_e23 + 1;
            BEGIN
              insert into wrk_trasmissione_ruolo
                (ruolo, progressivo, dati)
              values
                (w_ruolo, w_progressivo, w_riga_600);
            EXCEPTION
              WHEN others THEN
                w_errore := 'Errore in inserimento record E23 rappresentante ' || '(' || SQLERRM || ')';
                RAISE errore;
            END;
         end if;
         -- Trattamento erede
         if w_flag_coobbligati = 2 then
            for erede in (select ni_erede from eredi_soggetto where ni = rec_sapr.ni)
            loop
              begin
                select sogg.ni_presso
                     , decode(sogg.tipo_residente
                             ,0,1
                             ,decode(sogg.tipo
                                    ,0,1
                                    ,1,2
                                    ,decode(instr(sogg.cognome_nome,'/'),0,2,1)))
                  into w_ni_presso
                     , w_natura_soggetto
                  from soggetti sogg
                 where ni = erede.ni_erede;
              exception
                when others then
                  w_stringa_soggetto := rpad(' ',338);
              end;
              w_stringa_soggetto := f_get_dati_anagrafici( erede.ni_erede
                                                         , w_ni_presso
                                                         , w_natura_soggetto
                                                         , 'X'
                                                         , w_tipo_tributo
                                                         , rec_sapr.data_notifica_atto
                                                         );
              w_progressivo  := w_progressivo + 1;
              w_progr_record := w_progr_record + 1;
              w_riga_600 := 'E20'||lpad(w_progr_record,7,'0')
                         ||w_stringa_atto||' C'||w_natura_soggetto
                         ||w_stringa_soggetto||rpad(' ',148);
              w_tot_record_e20  := w_tot_record_e20 + 1;
              BEGIN
                insert into wrk_trasmissione_ruolo
                  (ruolo, progressivo, dati)
                values
                  (w_ruolo, w_progressivo, w_riga_600);
              EXCEPTION
                WHEN others THEN
                  w_errore := 'Errore in inserimento record E23 erede ' || '(' || SQLERRM || ')';
                  RAISE errore;
              END;
            end loop;
         end if;
      end if;
      --
      w_progressivo  := w_progressivo + 1;
      w_progr_record := w_progr_record + 1;
      w_progr_articolo := w_progr_articolo + 1;
      w_tot_record_e50  := w_tot_record_e50 + 1;
      w_tot_importo_atto := w_tot_importo_atto + rec_sapr.importo;
      w_tot_importo_flusso := w_tot_importo_flusso + rec_sapr.importo;
      w_stringa := lpad(w_progr_articolo,3,'0')
                || rec_sapr.anno
                || '99'
                || rpad(rec_sapr.cod_entrata,4)
                || nvl(rec_sapr.tipo_entrata,' ')
                || lpad(rec_sapr.importo * 100,15,'0')
                || lpad(' ',460);
      w_riga_600 := 'E50'||lpad(w_progr_record,7,'0')
                 || w_stringa_atto || w_stringa;
      BEGIN
        insert into wrk_trasmissione_ruolo
          (ruolo, progressivo, dati)
        values
          (w_ruolo, w_progressivo, w_riga_600);
      EXCEPTION
        WHEN others THEN
          w_errore := 'Errore in inserimento record N1' || '(' || SQLERRM || ')';
          RAISE errore;
      END;
    END LOOP;
    -- Inserimento riga finale del ruolo
    w_stringa := w_dati_delibera
              || '3'  -- Tipologia sospensione - 3 = nessuna sospensione
              || lpad(w_tot_importo_atto * 100,15,'0')
              || lpad(w_progr_articolo,7,'0')
              || to_char(w_data_ultimo_pag,'yyyymmdd')
              || 'N'  -- Flag ente terzo - N = Non presente
              || rpad(' ',60)  -- Denominazione ente terzo
              || rpad(' ',371);
    w_progressivo    := w_progressivo + 1;
    w_progr_record   := w_progr_record + 1;
    w_tot_record_e60 := w_tot_record_e60 + 1;
    w_riga_600 := 'E60'||lpad(w_progr_record,7,'0')
               || w_stringa_atto || w_stringa;
    BEGIN
      insert into wrk_trasmissione_ruolo
        (ruolo, progressivo, dati)
      values
        (w_ruolo, w_progressivo, w_riga_600);
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento record E60 ' || '(' || SQLERRM || ')';
        RAISE errore;
    END;
  END LOOP;
  -- Inserimento record finale del file
  if w_conta_ruolo > 0 then
     w_progressivo     := w_progressivo + 1;
     w_riga_600 := 'E99'
                || lpad(w_cod_ente, 5, '0')
                || w_tipo_ufficio
                || rpad(w_cod_ufficio,6)
                || to_char(sysdate, 'yyyymmdd')
                --|| w_anno_emissione || '7' || lpad(w_progr_file,5,'0')
                || w_anno_file || '7' || lpad(w_progr_file,5,'0')
                || lpad(w_progressivo,7,'0')
                || lpad(w_tot_record_e20,7,'0')
                || lpad(w_tot_record_e23,7,'0')
                || lpad(w_tot_record_e50,7,'0')
                || lpad(w_tot_record_e60,7,'0')
                || lpad(w_tot_importo_flusso * 100,15,'0')
                || rpad(' ',517);
     BEGIN
       insert into wrk_trasmissione_ruolo
         (ruolo, progressivo, dati)
       values
         (w_ruolo, w_progressivo, w_riga_600);
     EXCEPTION
       WHEN others THEN
         w_errore := 'Errore in inserimento record E99' || '(' || SQLERRM || ')';
         RAISE errore;
     END;
     BEGIN
       update ruoli
          set invio_consorzio = trunc(sysdate)
            , progr_invio     = w_progr_file
        where ruolo in (select valore
                          from parametri
                         where parametri.sessione = a_sessione
                           and parametri.nome_parametro = a_nome_p);
     EXCEPTION
       WHEN others THEN
         w_errore := 'Errore in aggiornamento data invio in Ruoli' || ' (' ||
                     SQLERRM || ')';
         RAISE errore;
     END;
  end if;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999, w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_cod_fiscale||' '||
                            'Errore in preparazione file per trasmissione ruolo' || ' (' ||
                            SQLERRM || ')');
END;
/* End Procedure: TRASMISSIONE_RUOLO_600 */
/
