--liquibase formatted sql 
--changeset abrandolini:20250326_152423_archivia_denunce stripComments:false runOnChange:true 
 
create or replace procedure ARCHIVIA_DENUNCE
/*************************************************************************
 NOME:        ARCHIVIA_DENUNCE
 DESCRIZIONE: Archivia le denunce IMU e TASI negli archivi storici.
              I parametri non possono essere tutti nulli.
 PARAMETRI:   Tipo tributo        Se non indicato si trattano ICI/IMU e
                                  TASI.
              Codice fiscale      Se non indicato si trattano tutti i
                                  contribuenti.
              Pratica             Se non indicato si trattano tutte le
                                  pratiche,
 NOTE:
 Rev.    Date         Author      Note
 003     30/03/2020   VD          Aggiunta nota su sto_pratiche_tributo
                                  quando si elimina un oggetto_pratica
                                  archiviato perchè sostituito da un
                                  nuovo oggetto_pratica in un'altra denuncia
 002     24/03/2020   VD          Corretta gestione storico nel caso di
                                  eliminazione del singolo oggetto_pratica.
 001     20/10/2020   VD          Aggiunto commit
 000     08/01/2020   VD          Prima emissione.
*************************************************************************/
( p_tipo_tributo            varchar2
, p_cod_fiscale             varchar2
, p_pratica                 number
) is
  errore                    exception;
  w_conta_pratiche          number := 0;
  w_stringa_ogg_elim        varchar2(2000);
  w_stringa_cod_fiscali     varchar2(2000);
  w_pratica_sto             number;
begin
  --
  -- Si controlla che i parametri siano valorizzati.
  -- Se sono tutti nulli la procedure non viene eseguita.
  --
  if p_tipo_tributo is null and
     p_cod_fiscale is null and
     p_pratica is null then
     raise errore;
  end if;
--
  for den in (select prtr.pratica
                   , prtr.cod_fiscale
                from pratiche_tributo prtr
               where prtr.tipo_tributo = nvl(p_tipo_tributo,prtr.tipo_tributo)
                 and prtr.cod_fiscale = nvl(p_cod_fiscale,prtr.cod_fiscale)
                 and prtr.pratica = nvl(p_pratica,prtr.pratica)
                 and prtr.tipo_pratica = 'D'
                 and prtr.tipo_tributo in ('ICI','TASI')
                 and not exists (select 'x' from sto_pratiche_tributo stpt
                                  where stpt.pratica = prtr.pratica)
               order by tipo_tributo,pratica)
  loop
    w_conta_pratiche := w_conta_pratiche + 1;
    --
    -- Trattamento pratiche_tributo (la data di storicizzazione viene
    -- gestita da trigger)
    --
    begin
      insert into sto_pratiche_tributo
           ( pratica, cod_fiscale, tipo_tributo,
             anno, tipo_pratica, tipo_evento,
             data, numero, tipo_carica,
             denunciante, indirizzo_den, cod_pro_den,
             cod_com_den, cod_fiscale_den, partita_iva_den,
             data_notifica, imposta_totale, importo_totale,
             importo_ridotto, stato_accertamento, motivo,
             pratica_rif, utente, data_variazione,
             note, flag_adesione, imposta_dovuta_totale,
             flag_denuncia, flag_annullamento, importo_ridotto_2,
             tipo_atto, documento_id, documento_multi_id,
             tipo_calcolo, ente, data_rateazione,
             mora, rate, tipologia_rate,
             importo_rate, aliquota_rate, versato_pre_rate
           )
      select pratica, cod_fiscale, tipo_tributo,
             anno, tipo_pratica, tipo_evento,
             data, numero, tipo_carica,
             denunciante, indirizzo_den, cod_pro_den,
             cod_com_den, cod_fiscale_den, partita_iva_den,
             data_notifica, imposta_totale, importo_totale,
             importo_ridotto, stato_accertamento, motivo,
             pratica_rif, utente, data_variazione,
             note, flag_adesione, imposta_dovuta_totale,
             flag_denuncia, flag_annullamento, importo_ridotto_2,
             tipo_atto, documento_id, documento_multi_id,
             tipo_calcolo, ente, data_rateazione,
             mora, rate, tipologia_rate,
             importo_rate, aliquota_rate, versato_pre_rate
        from pratiche_tributo
       where pratica = den.pratica;
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_PRATICHE_TRIBUTO ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento rapporti_tributo
    --
    begin
      insert into sto_rapporti_tributo
           ( pratica, sequenza, cod_fiscale,
             tipo_rapporto
           )
      select pratica, sequenza, cod_fiscale,
             tipo_rapporto
        from rapporti_tributo
       where pratica = den.pratica;
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_RAPPORTI_TRIBUTO ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento denunce_ici
    --
    begin
      insert into sto_denunce_ici
           ( pratica, denuncia, prefisso_telefonico,
             num_telefonico, flag_cf, flag_firma,
             flag_denunciante, progr_anci, fonte,
             utente, data_variazione, note
           )
      select pratica, denuncia, prefisso_telefonico,
             num_telefonico, flag_cf, flag_firma,
             flag_denunciante, progr_anci, fonte,
             utente, data_variazione, note
        from denunce_ici
       where pratica = den.pratica;
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_DENUNCE_ICI ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento denunce_tasi
    --
    begin
      insert into sto_denunce_tasi
           ( pratica, denuncia, prefisso_telefonico,
             num_telefonico, flag_cf, flag_firma,
             flag_denunciante, progr_anci, fonte,
             utente, data_variazione, note
           )
      select pratica, denuncia, prefisso_telefonico,
             num_telefonico, flag_cf, flag_firma,
             flag_denunciante, progr_anci, fonte,
             utente, data_variazione, note
        from denunce_tasi
       where pratica = den.pratica;
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_DENUNCE_TASI ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento oggetti
    --
    begin
      insert into sto_oggetti
           ( oggetto, descrizione, edificio,
             tipo_oggetto, indirizzo_localita, cod_via,
             num_civ, suffisso, scala,
             piano, interno, sezione,
             foglio, numero, subalterno,
             zona, estremi_catasto, partita,
             progr_partita, protocollo_catasto, anno_catasto,
             categoria_catasto, classe_catasto, tipo_uso,
             consistenza, vani, qualita,
             ettari, are, centiare,
             flag_sostituito, flag_costruito_ente, fonte,
             utente, data_variazione, note,
             cod_ecografico, tipo_qualita, data_cessazione,
             superficie, id_immobile, ente
           )
      select oggetto, descrizione, edificio,
             tipo_oggetto, indirizzo_localita, cod_via,
             num_civ, suffisso, scala,
             piano, interno, sezione,
             foglio, numero, subalterno,
             zona, estremi_catasto, partita,
             progr_partita, protocollo_catasto, anno_catasto,
             categoria_catasto, classe_catasto, tipo_uso,
             consistenza, vani, qualita,
             ettari, are, centiare,
             flag_sostituito, flag_costruito_ente, fonte,
             utente, data_variazione, note,
             cod_ecografico, tipo_qualita, data_cessazione,
             superficie, id_immobile, ente
        from oggetti ogge
       where ogge.oggetto in (select distinct oggetto
                                from oggetti_pratica
                               where pratica = den.pratica)
         and not exists (select 'x'
                           from sto_oggetti stog
                          where stog.oggetto = ogge.oggetto);
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_OGGETTI ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento civici_oggetto
    --
    begin
      insert into sto_civici_oggetto
           ( oggetto, sequenza, indirizzo_localita,
             cod_via, num_civ, suffisso
           )
      select oggetto, sequenza, indirizzo_localita,
             cod_via, num_civ, suffisso
        from civici_oggetto ciog
       where ciog.oggetto in (select distinct oggetto
                                from oggetti_pratica
                               where pratica = den.pratica)
         and not exists (select 'x'
                           from sto_civici_oggetto stco
                          where stco.oggetto = ciog.oggetto
                            and stco.sequenza = ciog.sequenza);
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_CIVICI_OGGETTO ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento oggetti_pratica
    --
    -- (VD - 24/03/2020): prima di inserire le righe di oggetti_pratica, si
    --                    controlla se esistono record storicizzati inseriti e
    --                    poi cancellati in altre denunce. Se sì, si eliminano.
    -- (VD - 30/03/2020): gli oggetti eliminati vengono memorizza prima in una
    --                    stringa poi nel campo note di sto_pratiche_tributo
    --
    w_stringa_cod_fiscali  := '';
    for ogp in (select oggetto_pratica
                  from oggetti_pratica ogpr
                 where pratica = den.pratica
                   and exists (select 'x' from sto_oggetti_pratica opst
                                where opst.oggetto_pratica = ogpr.oggetto_pratica
                                  and opst.pratica <> den.pratica)
                 order by 1)
    loop
      -- Si selezionano dalle pratiche storicizzati gli eventuali codici
      -- fiscali dei contitolari e si memorizzano in una stringa
      for sto in (select opst.pratica
                       , ocst.cod_fiscale
                    from sto_oggetti_pratica opst
                       , sto_oggetti_contribuente ocst
                   where opst.oggetto_pratica = ogp.oggetto_pratica
                     and opst.oggetto_pratica = ocst.oggetto_pratica
                     and opst.pratica        <> den.pratica
                   order by 1,2)
      loop
        w_pratica_sto         := sto.pratica;
        if sto.cod_fiscale <> den.cod_fiscale then
           w_stringa_cod_fiscali := w_stringa_cod_fiscali||','||sto.cod_fiscale;
        end if;
      end loop;
      -- Se il contitolare è uno solo si toglie la virgola iniziale
      if w_stringa_cod_fiscali is not null and
         instr(w_stringa_cod_fiscali,',',1,2) = 0 then
         w_stringa_cod_fiscali := ltrim(w_stringa_cod_fiscali,',');
      end if;
      -- Si elimina l'oggetto_pratica storicizzato
      begin
        delete from sto_oggetti_pratica
         where oggetto_pratica = ogp.oggetto_pratica
           and pratica = w_pratica_sto;
      exception
        when others then
            raise_application_error(-20999,'Del. STO_OGGETTI_PRATICA ('||ogp.oggetto_pratica||
                                       ') - '||sqlerrm);
      end;
      -- Si aggiorna la testata della denuncia aggiungendo nelle note i dati
      -- degli oggetti_pratica eliminati
      begin
        update sto_pratiche_tributo
           set note = decode(note
                            ,null,'Eliminati OGPR: '
                                 ,decode(instr(note,'Eliminati OGPR: ')
                                        ,0,note||' - Eliminati OGPR: '
                                          ,note||','
                                        )
                            )||
                      ogp.oggetto_pratica||
                      decode(w_stringa_cod_fiscali
                            ,null,''
                                 ,' per CF: '||w_stringa_cod_fiscali
                            )
         where pratica = w_pratica_sto;
      exception
        when others then
            raise_application_error(-20999,'Upd. STO_PRATICHE_TRIBUTO ('||w_pratica_sto||
                                       ') - '||sqlerrm);
      end;
    end loop;
    --
    begin
      insert into sto_oggetti_pratica
           ( oggetto_pratica, oggetto, pratica,
             tributo, categoria, anno,
             tipo_tariffa, num_ordine, imm_storico,
             categoria_catasto, classe_catasto, valore,
             flag_provvisorio, flag_valore_rivalutato, titolo,
             estremi_titolo, modello, flag_firma,
             fonte, consistenza_reale, consistenza,
             locale, coperta, scoperta,
             settore, flag_uip_principale, reddito,
             classe_sup, imposta_base, imposta_dovuta,
             flag_domicilio_fiscale, num_concessione, data_concessione,
             inizio_concessione, fine_concessione, larghezza,
             profondita, cod_pro_occ, cod_com_occ,
             indirizzo_occ, da_chilometro, a_chilometro,
             lato, tipo_occupazione, flag_contenzioso,
             oggetto_pratica_rif, utente, data_variazione,
             note, oggetto_pratica_rif_v, tipo_qualita,
             qualita, tipo_oggetto, oggetto_pratica_rif_ap,
             quantita, titolo_occupazione, natura_occupazione,
             destinazione_uso, assenza_estremi_catasto, data_anagrafe_tributaria,
             numero_familiari
           )
      select oggetto_pratica, oggetto, pratica,
             tributo, categoria, anno,
             tipo_tariffa, num_ordine, imm_storico,
             categoria_catasto, classe_catasto, valore,
             flag_provvisorio, flag_valore_rivalutato, titolo,
             estremi_titolo, modello, flag_firma,
             fonte, consistenza_reale, consistenza,
             locale, coperta, scoperta,
             settore, flag_uip_principale, reddito,
             classe_sup, imposta_base, imposta_dovuta,
             flag_domicilio_fiscale, num_concessione, data_concessione,
             inizio_concessione, fine_concessione, larghezza,
             profondita, cod_pro_occ, cod_com_occ,
             indirizzo_occ, da_chilometro, a_chilometro,
             lato, tipo_occupazione, flag_contenzioso,
             oggetto_pratica_rif, utente, data_variazione,
             note, oggetto_pratica_rif_v, tipo_qualita,
             qualita, tipo_oggetto, oggetto_pratica_rif_ap,
             quantita, titolo_occupazione, natura_occupazione,
             destinazione_uso, assenza_estremi_catasto, data_anagrafe_tributaria,
             numero_familiari
        from oggetti_pratica
       where pratica = den.pratica;
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_OGGETTI_PRATICA ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- Trattamento oggetti_contribuente
    --
    begin
      insert into sto_oggetti_contribuente
           ( cod_fiscale, oggetto_pratica, anno,
             tipo_rapporto, inizio_occupazione, fine_occupazione,
             data_decorrenza, data_cessazione, perc_possesso,
             mesi_possesso, mesi_possesso_1sem, mesi_esclusione,
             mesi_riduzione, mesi_aliquota_ridotta, detrazione,
             flag_possesso, flag_esclusione, flag_riduzione,
             flag_ab_principale, flag_al_ridotta, utente,
             data_variazione, note, successione,
             progressivo_sudv, tipo_rapporto_k, perc_detrazione,
             mesi_occupato, mesi_occupato_1sem, da_mese_possesso,
             da_mese_esclusione, da_mese_riduzione, da_mese_al_ridotta
           )
      select cod_fiscale, oggetto_pratica, anno,
             tipo_rapporto, inizio_occupazione, fine_occupazione,
             data_decorrenza, data_cessazione, perc_possesso,
             mesi_possesso, mesi_possesso_1sem, mesi_esclusione,
             mesi_riduzione, mesi_aliquota_ridotta, detrazione,
             flag_possesso, flag_esclusione, flag_riduzione,
             flag_ab_principale, flag_al_ridotta, utente,
             data_variazione, note, successione,
             progressivo_sudv, tipo_rapporto_k, perc_detrazione,
             mesi_occupato, mesi_occupato_1sem, da_mese_possesso,
             da_mese_esclusione, da_mese_riduzione, da_mese_al_ridotta
        from oggetti_contribuente
       where oggetto_pratica in (select oggetto_pratica
                                   from oggetti_pratica
                                  where pratica = den.pratica);
    exception
      when others then
        raise_application_error(-20999,'Ins. STO_OGGETTI_CONTRIBUENTE ('||den.pratica||
                                       ') - '||sqlerrm);
    end;
    --
    -- (VD - 20/01/2020): si esegue il commit ogni 1000 pratiche trattate
    --
    if p_pratica is null then
       if mod(w_conta_pratiche,1000) = 0 then
          commit;
       end if;
    end if;
  end loop;
  --
  -- (VD - 20/01/2020): commit finale
  --
  if p_pratica is null then
     commit;
  end if;
  --
exception
  when errore then
    raise_application_error(-20999,'Inserire almeno un parametro');
--  when others then
--    raise;
end;
/* End Procedure: ARCHIVIA_DENUNCE */
/

