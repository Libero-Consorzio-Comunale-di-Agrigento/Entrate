--liquibase formatted sql 
--changeset abrandolini:20250326_152423_estrazione_tari_garbage stripComments:false runOnChange:true 
 
create or replace procedure ESTRAZIONE_TARI_GARBAGE
/*************************************************************************
 NOME:        ESTRAZIONE_TARI_GARBAGE
 DESCRIZIONE: Estrazione contribuenti TARI secondo il tracciato
              HARNEKINFO
 NOTE:
 Rev.    Date         Author      Note
 001     17/04/2018   VD          Modifiche per tracciato errato (vecchio).
 000     04/04/2018   VD          Prima emissione.
*************************************************************************/
( a_num_righe                     out number
) is
  w_tipo_tributo                  varchar2(5) := 'TARSU';
  w_progr_riga                    number := 0;
  w_data_inizio                   varchar2(10);
  w_data_var                      varchar2(10);
  w_componenti                    number;
  w_stringa_comp                  varchar2(20);
  --
  w_riga_wrk                      varchar2(32767);
  w_dati                          varchar2(4000);
  w_dati2                         varchar2(4000);
  w_dati3                         varchar2(4000);
  w_dati4                         varchar2(4000);
  w_dati5                         varchar2(4000);
  w_dati6                         varchar2(4000);
  w_dati7                         varchar2(4000);
  w_dati8                         varchar2(4000);
  --Gestione delle eccezioni
  w_errore                        varchar2(2000);
  errore                          exception;
begin
  w_riga_wrk := 'CodiceEsternoContribuente;CodFiscale;PartitaIVA;TipoPersona;'||
                'Denominazione1;Denominazione2;Indirizzo;NumeroCivico;Subalterno;'||
                'CAP;Comune;Prov;CodiceEsternoUtenza;ToponimoUtenza;'||
                'IndirizzoUtenza;Numero;Lettera;MqLocali;TipoUtenza;'||
                'CategoriaUtenza;DataInizio;DataFine;DataVar;'||
                'Sezione;Foglio;Numero;Estensione;Subalterno;';
  w_dati := substr(w_riga_wrk,1,4000);
  w_dati2 := substr(w_riga_wrk,4001,4000);
  w_dati3 := substr(w_riga_wrk,8001,4000);
  w_dati4 := substr(w_riga_wrk,12001,4000);
  w_dati5 := substr(w_riga_wrk,16001,4000);
  w_dati6 := substr(w_riga_wrk,20001,4000);
  w_dati7 := substr(w_riga_wrk,24001,4000);
  w_dati8 := substr(w_riga_wrk,28001,4000);
  w_progr_riga := w_progr_riga + 1;
  BEGIN
    insert into wrk_trasmissioni( numero
                                , dati
                                , dati2
                                , dati3
                                , dati4
                                , dati5
                                , dati6
                                , dati7
                                , dati8)
     values (lpad(w_progr_riga,15,'0')
           , w_dati
           , w_dati2
           , w_dati3
           , w_dati4
           , w_dati5
           , w_dati6
           , w_dati7
           , w_dati8);
  EXCEPTION
    WHEN others THEN
      w_errore := ('Errore in inserimento wrk_trasmissioni - Intestazione ' || ' (' || SQLERRM || ')' );
      raise errore;
  END;
  --
  for cont in (select cont.ni
                    , cont.cod_fiscale
                    , sogg.partita_iva
                    , decode(sogg.tipo
                            ,0,'F'
                            ,1,'G'
                              ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))  tipo_persona
                    , decode(instr(sogg.cognome_nome,'/'),0,substr(sogg.cognome_nome,1,30)
                                                           ,substr(sogg.cognome,1,30)) denominazione_1
                    , decode(instr(sogg.cognome_nome,'/'),0,substr(sogg.cognome_nome,31,30)
                                                           ,substr(sogg.nome,1,30))    denominazione_2
                    , decode(sogg.cod_via,null,sogg.denominazione_via
                                              ,arvS.denom_uff)                  indirizzo
                    , sogg.num_civ                                              numero_civico
                    , sogg.suffisso                                             subalterno
                    , sogg.cap
                    , comR.denominazione
                    , proR.sigla
                    , rpad(cont.cod_fiscale,16)||lpad(ogva.oggetto,10,'0')      utenza
                    , decode(ogge.cod_via,null,substr(ogge.indirizzo_localita,1,instr(ogge.indirizzo_localita,' ') -1)
                                              ,substr(arvO.denom_uff,1,instr(arvo.denom_uff,' ')-1)) toponimo
                    , decode(ogge.cod_via,null,substr(ogge.indirizzo_localita,instr(ogge.indirizzo_localita,' ')+1)
                                              ,substr(arvO.denom_uff,instr(arvO.denom_uff,' ') +1)) indirizzo_utenza
                    , ogge.num_civ                                              numero
                    , ogge.suffisso                                             lettera
                    , ogpr.consistenza                                          mq_locali
                    , decode(nvl(cate.flag_domestica,'N'),'S','D','S')          tipo_utenza
                    , cate.descrizione                                          categoria
                    , to_char(ogva.dal,'dd/mm/yyyy')                            data_inizio
                    , decode(ogva.al,null,to_char(null),
                                          to_char(ogva.al,'dd/mm/yyyy'))        data_fine
                    , ogva.oggetto_pratica
                    , ogva.oggetto_pratica_rif
                    , ogge.sezione                                              cat_sezione
                    , ogge.foglio                                               cat_foglio
                    , ogge.numero                                               cat_numero
                    , ogge.subalterno                                           cat_subalterno
                    , ogco.flag_ab_principale
                 from contribuenti         cont
                    , soggetti             sogg
                    , oggetti_validita     ogva
                    , oggetti              ogge
                    , oggetti_pratica      ogpr
                    , oggetti_contribuente ogco
                    , categorie            cate
                    , archivio_vie         arvS
                    , archivio_vie         arvO
                    , ad4_comuni           comR
                    , ad4_province         proR
                where cont.ni              = sogg.ni
                  and cont.cod_fiscale     = ogva.cod_fiscale
                  and ogva.tipo_tributo    = w_tipo_tributo
                  and trunc(sysdate) between nvl(ogva.dal,trunc(sysdate))
                                         and nvl(ogva.al,trunc(sysdate))
                  and ogva.oggetto         = ogge.oggetto
                  and ogva.oggetto_pratica = ogpr.oggetto_pratica
                  and ogva.oggetto_pratica = ogco.oggetto_pratica
                  and ogpr.tributo         = cate.tributo
                  and ogpr.categoria       = cate.categoria
                  and sogg.cod_via         = arvS.cod_via (+)
                  and sogg.cod_pro_res     = comR.provincia_stato (+)
                  and sogg.cod_com_res     = comR.comune (+)
                  and sogg.cod_pro_res     = proR.provincia (+)
                  and ogge.cod_via         = arvO.cod_via (+)
                order by sogg.cognome_nome
               )
  loop
    --
    -- Determinazione data iscrizione oggetto per oggetto_pratica_rif
    -- (se oggetto_pratica diverso da oggetto_pratica_rif)
    --
    if cont.oggetto_pratica <> cont.oggetto_pratica_rif then
       begin
         select to_char(ogva.dal,'dd/mm/yyyy')
           into w_data_inizio
           from oggetti_validita ogva
          where ogva.tipo_tributo    = w_tipo_tributo
            and ogva.cod_fiscale     = cont.cod_fiscale
            and oggetto_pratica      = cont.oggetto_pratica_rif;
       exception
         when no_data_found then
           w_data_inizio := to_char(null);
         when others Then
           w_errore := 'Errore in ricerca data iscrizione - C.F. ' || cont.cod_fiscale || ' (' || SQLERRM || ')';
           raise errore;
       end;
       w_data_inizio := nvl(w_data_inizio,cont.data_inizio);
    else
       w_data_inizio := cont.data_inizio;
    end if;
    --
    -- Se la data inizio e' ancora nulla, si considera il primo giorno
    -- dell'anno della pratica
    --
    if w_data_inizio is null then
       begin
         select to_char('01/01/'||prtr.anno)
           into w_data_inizio
           from oggetti_pratica  ogpr
              , pratiche_tributo prtr
          where ogpr.oggetto_pratica = cont.oggetto_pratica_rif
            and ogpr.pratica         = prtr.pratica;
       exception
         when others Then
           w_errore := 'Errore in ricerca data iscrizione (PRTR) - C.F. ' || cont.cod_fiscale || ' (' || SQLERRM || ')';
           raise errore;
       end;
    end if;
    --
    w_data_var := nvl(cont.data_inizio,w_data_inizio);
    --
    -- Determinazione del numero familiari (solo per utenze domestiche):
    -- se abitazione principale: funzione f_numero_familiari_al
    -- se lo step precedente fallisce, numero di componenti da OGPR
    -- se anche lo step precedente fallisce, funzione f_get_num_fam_cosu
    -- se fallisconto tutti, componenti = 0
    --
    if cont.tipo_utenza = 'D' then
       w_componenti := to_number(null);
       if nvl(cont.flag_ab_principale,'N') = 'S' then
          w_componenti := f_numero_familiari_al(cont.ni,trunc(sysdate));
       end if;
       --
       if nvl(w_componenti,0) <= 0 then
          begin
            select numero_familiari
              into w_componenti
              from oggetti_pratica
             where oggetto_pratica = nvl(cont.oggetto_pratica_rif,cont.oggetto_pratica);
          exception
            when others Then
              w_errore := 'Errore in ricerca numero componenti (OGPR) - C.F. ' || cont.cod_fiscale || ' (' || SQLERRM || ')';
              raise errore;
          end;
       end if;
       --
       if nvl(w_componenti,0) <= 0 then
          w_componenti := f_get_num_fam_cosu(cont.oggetto_pratica,cont.flag_ab_principale,to_number(to_char(sysdate,'yyyy')),to_number(null));
       end if;
       --
       if nvl(w_componenti,0) <= 0 then
          w_componenti := 0;
       end if;
       --
       w_stringa_comp := ' Componenti '||to_char(nvl(w_componenti,0));
    else
       w_stringa_comp := '';
    end if;
    --
    -- Composizione riga
    --
    w_riga_wrk := '';
    w_riga_wrk := cont.ni||';'||
                  cont.cod_fiscale||';'||
                  cont.partita_iva||';'||
                  cont.tipo_persona||';'||
                  cont.denominazione_1||';'||
                  cont.denominazione_2||';'||
                  cont.indirizzo||';'||
                  cont.numero_civico||';'||
                  cont.subalterno||';'||
                  cont.cap||';'||
                  cont.denominazione||';'||
                  cont.sigla||';'||
                  cont.utenza||';'||
                  cont.toponimo||';'||
                  cont.indirizzo_utenza||';'||
                  cont.numero||';'||
                  cont.lettera||';'||
                  cont.mq_locali||';'||
                  cont.tipo_utenza||';'||
                  cont.categoria||w_stringa_comp||';'||
                  w_data_inizio||';'||
                  cont.data_fine||';'||
                  w_data_var||';'||
                  cont.cat_sezione||';'||
                  cont.cat_foglio||';'||
                  cont.cat_numero||';'||
                  ';'||
                  cont.cat_subalterno||';';
    w_dati := substr(w_riga_wrk,1,4000);
    w_dati2 := substr(w_riga_wrk,4001,4000);
    w_dati3 := substr(w_riga_wrk,8001,4000);
    w_dati4 := substr(w_riga_wrk,12001,4000);
    w_dati5 := substr(w_riga_wrk,16001,4000);
    w_dati6 := substr(w_riga_wrk,20001,4000);
    w_dati7 := substr(w_riga_wrk,24001,4000);
    w_dati8 := substr(w_riga_wrk,28001,4000);
    w_progr_riga := w_progr_riga + 1;
    BEGIN
      insert into wrk_trasmissioni( numero
                                  , dati
                                  , dati2
                                  , dati3
                                  , dati4
                                  , dati5
                                  , dati6
                                  , dati7
                                  , dati8)
       values (lpad(w_progr_riga,15,'0')
             , w_dati
             , w_dati2
             , w_dati3
             , w_dati4
             , w_dati5
             , w_dati6
             , w_dati7
             , w_dati8);
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento wrk_trasmissioni - C.F. ' || cont.cod_fiscale || ' (' || SQLERRM || ')' ;
        raise errore;
    END;
  end loop;
--
  a_num_righe := w_progr_riga;
--
end;
/* End Procedure: ESTRAZIONE_TARI_GARBAGE */
/

