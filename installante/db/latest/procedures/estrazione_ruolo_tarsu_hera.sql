--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_ruolo_tarsu_hera stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_RUOLO_TARSU_HERA
( p_ruolo                   number
, p_righe_estratte      out number
) is
  w_riga                    varchar2(32000);
  w_progr_riga              number     := 1;
  --Gestione delle eccezioni
  w_errore                  varchar2(2000);
  errore                    exception;
cursor sel_ogg is
  select cont.ni                                             CodiceContribuente,
         decode(sogg.tipo,1,sogg.cognome_nome,'')            RagioneSociale,
         decode(sogg.tipo,0,sogg.cognome,'')                 Cognome,
         decode(sogg.tipo,0,sogg.nome,'')                    Nome,
         cont.cod_fiscale                                    CodiceFiscale,
         to_char(sogg.partita_iva)                           PartitaIva,
         decode(sogg.tipo,0,to_char(sogg.data_nas,'dd/mm/yyyy'),'')
                                                             DataNascita,
         ad4_comune.get_denominazione(sogg.cod_pro_nas,
                                      sogg.cod_com_nas)      LuogoNascita,
         sogg.cod_via                                        ContCodViaResidenza,
         decode(sogg.cod_via
               ,null,sogg.denominazione_via
               ,arvi_sogg.denom_uff
               )                                             ContViaResidenza,
         sogg.num_civ                                        ContNumCivResidenza,
         sogg.suffisso                                       ContBarraResidenza,
         sogg.interno                                        ContInternoResidenza,
         sogg.scala                                          ContScalaResidenza,
         sogg.piano                                          ContPianoResidenza,
         ''                                                  ContCodFrazResidenza,
         ''                                                  ContFrazResidenza,
         lpad(sogg.cap,5,'0')                                ContCapResidenza,
         ad4_comune.get_denominazione(sogg.cod_pro_res,
                                      sogg.cod_com_res)      ContComuneResidenza,
         ad4_provincia.get_sigla(sogg.cod_pro_res)           ContProvResidenza,
         ad4_stati_territori_tpk.get_denominazione(sogg.cod_pro_res) ContStatoResidenza,
         decode(sogg.ni_presso,
                null,f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'CV')||';'||  -- ContCodViaRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'DV')||';'||  -- ContViaRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'NC')||';'||  -- ContNumCivRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'SF')||';'||  -- ContBarraRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'IN')||';'||  -- ContInternoRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'SC')||';'||  -- ContScalaRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'PI')||';'||  -- ContPianoRecapito
                     ''                                                         ||';'||  -- ContCodFrazRecapito
                     ''                                                         ||';'||  -- ContFrazRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'CAP')||';'|| -- ContCapRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'CO')||';'||  -- ContComuneRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'SP')||';'||  -- ContProvRecapito
                     f_recapito(cont.ni,ruog.tipo_tributo,1,trunc(sysdate),'SE'),   -- ContStatoRecapito
                sogg_p.cod_via                                        ||';'|| -- ContCodViaResidenza,
                decode(sogg_p.cod_via
                      ,null,sogg_p.denominazione_via
                      ,arvi_sogg_p.denom_uff
                      )                                             ||';'||   -- ContViaRecapito,
                sogg_p.num_civ                                      ||';'||   -- ContNumCivRecapito,
                sogg_p.suffisso                                     ||';'||   -- ContBarraRecapito,
                sogg_p.interno                                      ||';'||   -- ContInternoRecapito,
                sogg_p.scala                                        ||';'||  -- ContScalaRecapito,
                sogg_p.piano                                        ||';'||   -- ContPianoRecapito,
                ''                                                  ||';'||   -- ContCodFrazRecapito,
                ''                                                  ||';'||   -- ContFrazRecapito,
                lpad(sogg_p.cap,5,'0')                              ||';'||   -- ContCapRecapito,
                ad4_comune.get_denominazione(sogg_p.cod_pro_res,
                                             sogg_p.cod_com_res)     ||';'||  -- ContComuneRecapito,
                ad4_provincia.get_sigla(sogg_p.cod_pro_res)          ||';'||  -- ContProvRecapito,
                ad4_stati_territori_tpk.get_denominazione(sogg_p.cod_pro_res)) -- ContStatoRecapito,
              DatiRecapito,
         lpad(dage.pro_cliente,3,'0')||lpad(dage.com_cliente,3,'0') CodIstatComune,
         ruog.oggetto_pratica                                KeyUtenza,
         ''                                                  KeyUtenzaPrincipale,
         ruog.oggetto_pratica                                CodiceUtenza,
         decode(nvl(cate.flag_domestica,'N'),
                'S','DOMESTICA',
                    'NON DOMESTICA')                         CodiceTributo,
         ogge.cod_via                                        UtenCodVia,
         decode(ogge.cod_via,'',ogge.indirizzo_localita,
                                arvi_ogge.denom_uff)         UtenVia,
         ogge.num_civ                                        UtenNumCiv,
         ogge.suffisso                                       UtenBarra,
         ogge.interno                                        UtenInterno,
         ogge.scala                                          UtenScala,
         ogge.piano                                          UtenPiano,
         ''                                                  UtenCodFraz,
         ''                                                  UtenFrazione,
         ad4_comune.get_cap(dage.pro_cliente,
                            dage.com_cliente)                UtenCap,
         ad4_comune.get_denominazione(dage.pro_cliente,
                                      dage.com_cliente)      UtenComune,
         ad4_provincia.get_sigla(dage.pro_cliente)           UtenProv,
         to_char(ogva.dal,'dd/mm/yyyy')                      UtenDataInizio,
         to_char(ogva.al,'dd/mm/yyyy')                       UtenDataFine,
         to_char(ogco.data_variazione,'dd/mm/yyyy')          UtenDataUltMod,
         ogge.oggetto                                        KeyImmobile,
         cate.categoria                                      CategoriaTia,
         ''                                                  SottoCategoriaTia,
         f_numero_familiari_al_faso(cont.ni,trunc(sysdate))  ImmNumComponenti,
         ogge.oggetto                                        ImmCodice,
         'S'                                                 IsPrincipale,
         ruog.consistenza                                    SupTotMQ,
         ruog.consistenza                                    SupImpMQ,
         ''                                                  Note,
         ogge.cod_via                                        ImmCodVia,
         decode(ogge.cod_via,'',ogge.indirizzo_localita,
                                arvi_ogge.denom_uff)         ImmVia,
         ogge.num_civ                                        ImmNumCiv,
         ogge.suffisso                                       ImmBarra,
         ogge.interno                                        ImmInterno,
         ogge.scala                                          ImmScala,
         ogge.piano                                          ImmPiano,
         ad4_comune.get_cap(dage.pro_cliente,
                            dage.com_cliente)                ImmCap,
         ''                                                  ImmCodFraz,
         ''                                                  ImmFrazione,
         ad4_comune.get_denominazione(dage.pro_cliente,
                                      dage.com_cliente)      ImmComune,
         ad4_provincia.get_sigla(dage.pro_cliente)           ImmProv,
         ad4_comune.get_sigla_cfis(dage.pro_cliente,
                                  dage.com_cliente)          CatsCodiceBelfiore,
         ''                                                  CatsCodImmobile,
         ''                                                  CatsTipoImmobile,
         ''                                                  CatsTipoUnita,
         ogge.categoria_catasto                              CatsCategoria,
         ogge.foglio                                         CatsFoglio,
         ''                                                  CatsMappale,
         ogge.sezione                                        CatsSezione,
         ogge.numero                                         CatsParticella,
         ogge.subalterno                                     CatsSubalterno,
         ogco.perc_possesso                                  CatsPercPossesso,
         to_char(ogva.dal,'dd/mm/yyyy')                      ImmDataInizio,
         to_char(ogva.al,'dd/mm/yyyy')                       ImmDataFine,
         to_char(ogco.data_variazione,'dd/mm/yyyy')          ImmDataUltMod,
         ''                                                  CodRid1,
         ''                                                  PercRidFissa1,
         ''                                                  PercRidVar1,
         ''                                                  CodRid2,
         ''                                                  PercRidFissa2,
         ''                                                  PercRidVar2,
         ''                                                  CodRid3,
         ''                                                  PercRidFissa3,
         ''                                                  PercRidVar3,
         ''                                                  GiorniPresenza,
         decode(sogg.rappresentante,'',';;;;;;;',
                replace(sogg.rappresentante,'/',' ')||';'||
                sogg.cod_fiscale_rap||';'||
                sogg.indirizzo_rap||';'||
                ''||';'||
                ad4_comune.get_denominazione(sogg.cod_pro_rap,sogg.cod_com_rap)||';'||
                ad4_provincia.get_sigla(sogg.cod_pro_rap)||';'||
                ''||';')                                     DatiRappresentante
    from DATI_GENERALI        dage,
         ARCHIVIO_VIE         arvi_ogge,
         OGGETTI              ogge,
         SOGGETTI             sogg,
         SOGGETTI             sogg_p,
         CONTRIBUENTI         cont,
         AD4_STATI_TERRITORI  stat,
         RUOLI_OGGETTO        ruog,
         OGGETTI_VALIDITA     ogva,
         ARCHIVIO_VIE         arvi_sogg,
         ARCHIVIO_VIE         arvi_sogg_p,
         OGGETTI_CONTRIBUENTE ogco,
         CATEGORIE            cate
   where arvi_ogge.cod_via     (+) = ogge.cod_via
     and sogg.ni                   = cont.ni
     and sogg.ni_presso            = sogg_p.ni (+)
     and arvi_sogg.cod_via     (+) = sogg.cod_via
     and arvi_sogg_p.cod_via   (+) = sogg_p.cod_via
     and stat.stato_territorio (+) = sogg.cod_pro_res
     and ruog.ruolo                = p_ruolo
     and ruog.cod_fiscale          = cont.cod_fiscale
     and ruog.oggetto              = ogge.oggetto
     and ogco.oggetto_pratica(+)   = ruog.oggetto_pratica
     and ogva.oggetto_pratica      = ruog.oggetto_pratica
     and nvl(ogco.cod_fiscale,cont.cod_fiscale) = cont.cod_fiscale
     and cate.tributo              = ruog.tributo
     and cate.categoria            = ruog.categoria
   order by sogg.cognome_nome;
begin
  -- Pulizia tabella di lavoro
  begin
     delete wrk_trasmissioni;
  exception
     when others then
        RAISE_APPLICATION_ERROR (-20666,'Errore nella pulizia della tabella di lavoro (' || SQLERRM || ')');
  end;
  -- Intestazione
  w_riga := 'CodiceContribuente;RagioneSociale;Cognome;Nome;'||
            'CodiceFiscale;PartitaIva;DataNascita;LuogoNascita;'||
            'ContribuenteCodiceViaResidenza;ContribuenteViaResidenza;'||
            'ContribuenteNumeroCivicoResidenza;ContribuenteBarraResidenza;'||
            'ContribuenteInternoResidenza;ContribuenteScalaResidenza;'||
            'ContribuentePianoResidenza;ContribuenteCodiceFrazioneResidenza;'||
            'ContribuenteFrazioneResidenza;ContribuenteCAPResidenza;'||
            'ContribuenteComuneResidenza;ContribuenteProvinciaResidenza;'||
            'ContribuenteStatoResidenza;ContribuenteCodiceViaRecapito;'||
            'ContribuenteViaRecapito;ContribuenteNumeroCivicoRecapito;'||
            'ContribuenteBarraRecapito;ContribuenteInternoRecapito;'||
            'ContribuenteScalaRecapito;ContribuentePianoRecapito;'||
            'ContribuenteReapitoCodiceFrazione;ContribuenteRecapitoFrazione;'||
            'ContribuenteCAPRecapito;ContribuenteComuneRecapito;'||
            'ContribuenteProvinciaRecapito;ContribuenteStatoRecapito;'||
            'CodIstatComune;KeyUtenza;KeyUtenzaPrincipale;'||
            'CodiceUtenza;CodiceTributo;utenzaCodiceVia;'||
            'utenzaVia;utenzaNumeroCivico;utenzaBarra;'||
            'utenzaInterno;utenzaScala;utenzaPiano;'||
            'utenzaCodiceFrazione;utenzaDescrizioneFrazione;'||
            'utenzaCAP;utenzaComune;utenzaProvincia;'||
            'DataInizioUtenza;DataFineUtenza;DataUltimaModificaUtenza;'||
            'KeyImmobile;CodiceCategoriaTia;CodiceSottoCategoriaTia;'||
            'ImmobileNrComponenti;codiceImmobile;IsPrincipale;'||
            'SuperficieTotaleMq;SuperficieImponibileMq;Note;'||
            'ImmobileCodiceVia;ImmobileVia;ImmobileNumeroCivico;'||
            'ImmobileBarra;ImmobileInterno;ImmobileScala;'||
            'ImmobilePiano;ImmobileCAP;ImmobileCodiceFrazione;ImmobileFrazione;'||
            'ImmobileComune;ImmobileProvincia;CatsCodiceBelfComune;'||
            'CatsCodiceImmobile;CatsTipoImmobile;CatsTipoUnita;'||
            'CatsCategoria;CatsFoglio;CatsMappale;CatsSezione;CatsParticella;CatsSubalterno;'||
            'CatsPercentualePossesso;DataInizioImmobile;DataFineImmobile;DataUltimaModificaImmobile;'||
            'CodiceRiduzione1;PercentualeRiduzioneFissa1;PercentualeRiduzioneVariabile1;'||
            'CodiceRiduzione2;PercentualeRiduzioneFissa2;PercentualeRiduzioneVariabile2;'||
            'CodiceRiduzione3;PercentualeRiduzioneFissa3;PercentualeRiduzioneVariabile3;'||
            'Giorni Presenza;'||
            'CognomeNomeLegaleRappresentante;CodiceFiscaleLegaleRappresentante;'||
            'DescrizioneViaLegaleRappresentante;NumeroCivicoLegaleRappresentante;'||
            'ComuneLegaleRappresentante;ProvinciaLegaleRappresentante;'||
            'StatoLegaleRappresentante;';
  --
  BEGIN
    insert into wrk_trasmissioni( numero
                                , dati
                                , dati2
                                , dati3
                                , dati4
                                , dati5
                                , dati6
                                , dati7
                                , dati8
                                )
     values ( lpad(w_progr_riga,15,'0')
            , substr(w_riga,1,4000)
            , substr(w_riga,4001,4000)
            , substr(w_riga,8001,4000)
            , substr(w_riga,12001,4000)
            , substr(w_riga,16001,4000)
            , substr(w_riga,20001,4000)
            , substr(w_riga,24001,4000)
            , substr(w_riga,28001,4000)
            );
  EXCEPTION
    WHEN others THEN
      w_errore := ('Errore in inserimento wrk_trasmissioni - Riga n. ' ||
                  w_progr_riga || ' (' || SQLERRM || ')' );
      raise errore;
  END;
  for rec_ogg in sel_ogg
  loop
    w_riga := rec_ogg.CodiceContribuente||';'||
              rec_ogg.RagioneSociale||';'||
              rec_ogg.Cognome||';'||
              rec_ogg.Nome||';'||
              rec_ogg.CodiceFiscale||';'||
              rec_ogg.PartitaIva||';'||
              rec_ogg.DataNascita||';'||
              rec_ogg.LuogoNascita||';'||
              rec_ogg.ContCodViaResidenza||';'||
              rec_ogg.ContViaResidenza||';'||
              rec_ogg.ContNumCivResidenza||';'||
              rec_ogg.ContBarraResidenza||';'||
              rec_ogg.ContInternoResidenza||';'||
              rec_ogg.ContScalaResidenza||';'||
              rec_ogg.ContPianoResidenza||';'||
              rec_ogg.ContCodFrazResidenza||';'||
              rec_ogg.ContFrazResidenza||';'||
              rec_ogg.ContCapResidenza||';'||
              rec_ogg.ContComuneResidenza||';'||
              rec_ogg.ContProvResidenza||';'||
              rec_ogg.ContStatoResidenza||';'||
              rec_ogg.DatiRecapito||';'||
              rec_ogg.CodIstatComune||';'||
              rec_ogg.KeyUtenza||';'||
              rec_ogg.KeyUtenzaPrincipale||';'||
              rec_ogg.CodiceUtenza||';'||
              rec_ogg.CodiceTributo||';'||
              rec_ogg.UtenCodVia||';'||
              rec_ogg.UtenVia||';'||
              rec_ogg.UtenNumCiv||';'||
              rec_ogg.UtenBarra||';'||
              rec_ogg.UtenInterno||';'||
              rec_ogg.UtenScala||';'||
              rec_ogg.UtenPiano||';'||
              rec_ogg.UtenCodFraz||';'||
              rec_ogg.UtenFrazione||';'||
              rec_ogg.UtenCap||';'||
              rec_ogg.UtenComune||';'||
              rec_ogg.UtenProv||';'||
              rec_ogg.UtenDataInizio||';'||
              rec_ogg.UtenDataFine||';'||
              rec_ogg.UtenDataUltMod||';'||
              rec_ogg.KeyImmobile||';'||
              rec_ogg.CategoriaTia||';'||
              rec_ogg.SottoCategoriaTia||';'||
              rec_ogg.ImmNumComponenti||';'||
              rec_ogg.ImmCodice||';'||
              rec_ogg.IsPrincipale||';'||
              rec_ogg.SupTotMQ||';'||
              rec_ogg.SupImpMQ||';'||
              rec_ogg.Note||';'||
              rec_ogg.ImmCodVia||';'||
              rec_ogg.ImmVia||';'||
              rec_ogg.ImmNumCiv||';'||
              rec_ogg.ImmBarra||';'||
              rec_ogg.ImmInterno||';'||
              rec_ogg.ImmScala||';'||
              rec_ogg.ImmPiano||';'||
              rec_ogg.ImmCap||';'||
              rec_ogg.ImmCodFraz||';'||
              rec_ogg.ImmFrazione||';'||
              rec_ogg.ImmComune||';'||
              rec_ogg.ImmProv||';'||
              rec_ogg.CatsCodiceBelfiore||';'||
              rec_ogg.CatsCodImmobile||';'||
              rec_ogg.CatsTipoImmobile||';'||
              rec_ogg.CatsTipoUnita||';'||
              rec_ogg.CatsCategoria||';'||
              rec_ogg.CatsFoglio||';'||
              rec_ogg.CatsMappale||';'||
              rec_ogg.CatsSezione||';'||
              rec_ogg.CatsParticella||';'||
              rec_ogg.CatsSubalterno||';'||
              rec_ogg.CatsPercPossesso||';'||
              rec_ogg.ImmDataInizio||';'||
              rec_ogg.ImmDataFine||';'||
              rec_ogg.ImmDataUltMod||';'||
              rec_ogg.CodRid1||';'||
              rec_ogg.PercRidFissa1||';'||
              rec_ogg.PercRidVar1||';'||
              rec_ogg.CodRid2||';'||
              rec_ogg.PercRidFissa2||';'||
              rec_ogg.PercRidVar2||';'||
              rec_ogg.CodRid3||';'||
              rec_ogg.PercRidFissa3||';'||
              rec_ogg.PercRidVar3||';'||
              rec_ogg.GiorniPresenza||';'||
              rec_ogg.DatiRappresentante;
    w_progr_riga := w_progr_riga + 1;
    --
    BEGIN
      insert into wrk_trasmissioni( numero
                                  , dati
                                  , dati2
                                  , dati3
                                  , dati4
                                  , dati5
                                  , dati6
                                  , dati7
                                  , dati8
                                  )
       values ( lpad(w_progr_riga,15,'0')
              , substr(w_riga,1,4000)
              , substr(w_riga,4001,4000)
              , substr(w_riga,8001,4000)
              , substr(w_riga,12001,4000)
              , substr(w_riga,16001,4000)
              , substr(w_riga,20001,4000)
              , substr(w_riga,24001,4000)
              , substr(w_riga,28001,4000)
              );
    EXCEPTION
      WHEN others THEN
        w_errore := ('Errore in inserimento wrk_trasmissioni - Riga n. ' ||
                    w_progr_riga || ' (' || SQLERRM || ')' );
        raise errore;
    END;
  end loop;
  --
  p_righe_estratte := w_progr_riga;
  --
end;
/* End Procedure: ESTRAZIONE_RUOLO_TARSU_HERA */
/

