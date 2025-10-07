--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_pratica_tasi_da_imu stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_PRATICA_TASI_DA_IMU
/***********************************************************************
 NOME:        F_PRATICA_TASI_DA_IMU

 DESCRIZIONE: Data una pratica ICI, crea le pratiche TASI per lo stesso
              anno per il titolare ed i contitolari.

 RITORNA:     varchar2                 Stringa contenente l'elenco
                                       delle pratiche inserite.

 NOTE:        Richiamata da w_deic_apri e da POPOLAMENTO_TASI_IMU.


 Rev.    Date         Author      Note
 5       01/03/2024   AB          #70370
                                  Valorizzazione dei campi
                                  mesi_al_ridotta, mesi_riduzione e
                                  mesi_esclusione di oggetti_contribuente
                                  e aliquota ridotta in ogco
 4       26/11/2020   VD          Controllo finale sulla pratica:
                                  se e' nulla non si lancia l'archiviazione
 3       25/02/2020   VD          Aggiunta archiviazione pratica
                                  creata.
 2       11/12/2019   VD          Aggiunta gestione da_mese_possesso
 1       06/05/2016   VD          Aggiunta gestione tipo oggetto 55
 0       26/03/2015   XX          Prima emissione

************************************************************************/
( p_pratica                       number
, p_utente                        varchar2
) return varchar2
as
  w_anno              number;
  w_cod_fiscale       varchar2(16) := 'ZZZZZZZZZZZZZZZZ';
  w_pratica           number;
  w_utente            varchar2(8)  := p_utente;
  w_oggetto_pratica   number;
  w_note              oggetti_pratica.note%type;
  w_fonte             number := 4;
  w_ogpr_pratica_rif_ap number; --ogpr rif ap da mettere nella nuova pratica tasi
  w_cognome_nome      varchar2(32000);
  w_stringa_output    varchar2(32000) := 'Pratiche generate:'||chr(10)||chr(13);
  w_msg_pertinenza    varchar2(32000);
  w_tot_ogpr          number := 0;
  --Gestione delle eccezioni
  w_errore            varchar2(2000);
  errore              exception;
--
  cursor sel_ogco( a_pratica number, a_anno number)
  is
      select nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_oggetto
            ,ogpr.pratica pratica_ogpr
            ,ogpr.oggetto oggetto_ogpr
            ,f_dato_riog(ogco.cod_fiscale
                        ,ogco.oggetto_pratica
                        ,prtr.anno
                        ,'CA'
                        )
               categoria_catasto_ogpr
            ,ogpr.oggetto_pratica oggetto_pratica_ogpr
            ,ogco.anno anno_ogco
            ,ogco.cod_fiscale cod_fiscale
            ,ogco.flag_possesso
            ,ogco.perc_possesso
            ,decode(ogco.anno, prtr.anno, nvl(ogco.mesi_possesso, 12), 12)
               mesi_possesso
            ,decode(ogco.anno, prtr.anno, ogco.mesi_possesso_1sem, 6)
               mesi_possesso_1sem
             -- (VD - 11/12/2019): nuovo campo da_mese_possesso
            ,decode(ogco.anno,
                    prtr.anno, nvl(ogco.da_mese_possesso,
                                   decode(nvl(ogco.mesi_possesso,12),12,1,
                                          decode(ogco.flag_possesso,'S',12 - ogco.mesi_possesso + 1,1))),
                               1)
               da_mese_possesso
            ,ogco.flag_al_ridotta
            ,decode(ogco.anno
                   ,prtr.anno, decode(ogco.flag_al_ridotta
                                      ,'S', nvl(ogco.mesi_aliquota_ridotta
                                               ,nvl(ogco.mesi_possesso, 12)
                                               )
                                      ,nvl(ogco.mesi_aliquota_ridotta, 0)
                                      )
                   ,decode(ogco.flag_al_ridotta, 'S', 12, 0)
                   )
               mesi_aliquota_ridotta
            ,ogco.flag_esclusione
            ,decode(ogco.anno
                   ,prtr.anno, decode(ogco.flag_esclusione
                                      ,'S', nvl(ogco.mesi_esclusione
                                               ,nvl(ogco.mesi_possesso, 12)
                                               )
                                      ,nvl(ogco.mesi_esclusione, 0)
                                      )
                   ,decode(ogco.flag_esclusione, 'S', 12, 0)
                   )
               mesi_esclusione
            ,ogco.flag_riduzione
            ,decode(ogco.anno
                   ,prtr.anno, decode(ogco.flag_riduzione
                                      ,'S', nvl(ogco.mesi_riduzione
                                               ,nvl(ogco.mesi_possesso, 12)
                                               )
                                      ,nvl(ogco.mesi_riduzione, 0)
                                      )
                   ,decode(ogco.flag_riduzione, 'S', 12, 0)
                   )
               mesi_riduzione
            ,ogco.flag_ab_principale flag_ab_principale
            ,ogpr.valore
            ,decode(ogco.detrazione
                   ,'', decode(ogco.flag_ab_principale
                              ,'S', made.detrazione
                              ,''
                              )
                   ,nvl(made.detrazione, ogco.detrazione)
                   )
               detrazione
            ,ogco.detrazione detrazione_ogco
            ,nvl(ogpr.categoria_catasto, ogge.categoria_catasto)
               categoria_catasto_ogge
            ,decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                   ,1, nvl(molt.moltiplicatore, 1)
                   ,3, decode(   nvl(ogpr.imm_storico, 'N')
                              || to_char(sign(2012 - prtr.anno))
                             ,'S1', 100
                             ,nvl(molt.moltiplicatore, 1)
                             )
                   ,1
                   )
               moltiplicatore
            ,ogpr.imm_storico
            ,ogpr.oggetto_pratica_rif_ap
            ,rire.aliquota aliquota_rivalutazione
            ,made.detrazione magg_detrazione
            ,prtr.tipo_pratica
            ,prtr.anno anno_titr
            ,ogpr.num_ordine
            ,ogpr.classe_catasto
            ,ogpr.categoria_catasto
            ,prtr.note note_prtr
            ,ogpr.note note_ogpr
            ,ogco.note note_ogco
            ,ogco.successione
            ,ogco.progressivo_sudv
            ,round(round(decode(nvl(ogco.mesi_possesso,12)
                            ,0,0
                            ,nvl(ogco.detrazione,0) / nvl(ogco.mesi_possesso,12) * 12
                            ),2)/ nvl(detr.detrazione_base, 0) * 100,2) perc_detrazione
            ,denunciante
            ,indirizzo_den
            ,cod_pro_den
            ,cod_com_den
            ,cod_fiscale_den
            ,ogpr.titolo
        from rivalutazioni_rendita rire
            ,moltiplicatori molt
            ,maggiori_detrazioni made
            ,oggetti ogge
            ,pratiche_tributo prtr
            ,oggetti_pratica ogpr
            ,oggetti_contribuente ogco
            ,detrazioni detr
       where detr.anno  = a_anno
         and detr.tipo_tributo = 'ICI'
         and rire.anno(+) = a_anno
         and rire.tipo_oggetto(+) = ogpr.tipo_oggetto
         and molt.anno(+) = a_anno
         and molt.categoria_catasto(+) =
               f_dato_riog(ogco.cod_fiscale
                          ,ogco.oggetto_pratica
                          ,a_anno
                          ,'CA'
                          )
         and made.anno(+) + 0 = a_anno
         and made.cod_fiscale(+) = ogco.cod_fiscale
         and made.tipo_tributo(+) = 'ICI'
         and ogge.oggetto = ogpr.oggetto
         and prtr.pratica = a_pratica
         and prtr.pratica = ogpr.pratica
         and ogpr.oggetto_pratica = ogco.oggetto_pratica
-- (VD - 06/05/2016): Aggiunto tipo_oggetto 55
         and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) in (2, 3, 4, 55)
    order by ogco.cod_fiscale
           , prtr.anno, prtr.pratica
           , oggetto_pratica_rif_ap desc --serve per copiare prima quelle con oggetto_pratica_rif_ap null
           , ogpr.oggetto_pratica
    ;
--------------------------------------------------------------------------------
PROCEDURE COMPONI_OUTPUT AS
BEGIN
  if w_cod_fiscale != 'ZZZZZZZZZZZZZZZZ' then
     w_stringa_output := w_stringa_output||w_cognome_nome||' - '||w_cod_fiscale||' inserita pratica '||w_pratica||' con '||w_tot_ogpr||' oggetti';
     if w_msg_pertinenza is not null then
        w_stringa_output :=  w_stringa_output||w_msg_pertinenza||')';
     end if;
     w_stringa_output :=  w_stringa_output||'.'||chr(10)||chr(13);
  else
     w_stringa_output := 'Inserite 0 pratiche, controllare i dizionari '||f_descrizione_titr('ICI', w_anno)||' per l''anno '||w_anno;
  end if;
END;
--------------------------------------------------------------------------------
PROCEDURE COMPONI_MSG_PERTINENZA(p_num_ordine VARCHAR2, p_oggetto NUMBER) AS
BEGIN
    if w_msg_pertinenza is null then
       w_msg_pertinenza := ' ( pertinenza di non duplicato per: '||chr(10)||chr(13);
    else
       w_msg_pertinenza := w_msg_pertinenza||chr(10)||chr(13);
    end if;
    w_msg_pertinenza := w_msg_pertinenza||' - numero ordine '||p_num_ordine||' oggetto '||p_oggetto;
END;
------------------------------------------------------------------------------
--                         I N I Z I O                                      --
------------------------------------------------------------------------------
begin
  begin
    select valore
      into w_fonte
      from installazione_parametri
     where parametro = 'FONT_DTASI'
    ;
  exception
  when others then
    w_errore := 'Parametro FONT_DTASI non presente in installazione_parametri.';
    raise errore;
  end;
  select anno
    into w_anno
    from pratiche_tributo
   where pratica = p_pratica;
  for rec_ogco in sel_ogco(p_pratica, w_anno) loop
    w_ogpr_pratica_rif_ap := null;
    w_anno := rec_ogco.anno_titr;
    if rec_ogco.cod_fiscale != w_cod_fiscale then
    --prima di cambiare contribuente sistemo le detrazioni per quello
    --appena processato
      if w_cod_fiscale != 'ZZZZZZZZZZZZZZZZ' then
         COMPONI_OUTPUT;
         -- (VD - 25/02/2020): Aggiunta archiviazione denuncia
         ARCHIVIA_DENUNCE('','',w_pratica);
         w_msg_pertinenza := null;
         w_tot_ogpr := 0;
      end if;
     -- commit;
      w_cod_fiscale :=   rec_ogco.cod_fiscale;
      select SOGG.COGNOME_NOME
        into w_cognome_nome
        from soggetti sogg, contribuenti cont
       where cont.cod_fiscale = w_cod_fiscale
         and cont.ni = sogg.ni
      ;
      -- inserisci pratica
      begin
        w_pratica :=   null;
        pratiche_tributo_nr(w_pratica);
      exception
        when others then
          w_errore      :=
            ('Errore in ricerca numero di pratica' || ' (' || sqlerrm || ')');
          raise errore;
      end;
      begin
        insert
          into pratiche_tributo(pratica
                               ,cod_fiscale
                               ,tipo_tributo
                               ,anno
                               ,tipo_pratica
                               ,tipo_evento
                               ,data
                               ,utente
                               ,data_variazione
                               ,note
                               ,denunciante
                               ,indirizzo_den
                               ,cod_pro_den
                               ,cod_com_den
                               ,cod_fiscale_den
                               )
        values (
                w_pratica
               ,rec_ogco.cod_fiscale
               ,'TASI'
               ,w_anno
               ,'D'
               ,'I'
               ,trunc(sysdate)
               ,w_utente
               ,trunc(sysdate)
               ,rec_ogco.note_prtr||' Duplica pratica TASI da IMU eseguito il '
                || to_char(sysdate, 'dd/mm/yyyy')
               ,rec_ogco.denunciante
               ,rec_ogco.indirizzo_den
               ,rec_ogco.cod_pro_den
               ,rec_ogco.cod_com_den
               ,rec_ogco.cod_fiscale_den
               );
      --   dbms_output.put_line('Insert in pratiche_tributo.');
      exception
        when others then
          w_errore      :=
            ('Errore in inserimento nuova pratica' || ' (' || sqlerrm || ')');
          raise errore;
      end;
      -- DENUNCE TASI
      begin
        insert
          into denunce_tasi(pratica
                          ,denuncia
                          ,fonte
                          ,utente
                          ,data_variazione
                          ,note
                          )
        values (
                w_pratica
               ,w_pratica
               ,w_fonte
               ,w_utente
               ,sysdate
               ,   'Duplica pratica TASI da IMU eseguito il'
                || to_char(sysdate, 'dd/mm/yyyy')
               );
      --  dbms_output.put_line('Insert in denunce_ici.');
      exception
        when others then
          w_errore      :=
            (   'Errore in inserimento nuova denuncia tasi'
             || ' ('
             || sqlerrm
             || ')');
          raise errore;
      end;
      -- ...rapporti_tributo
      begin
        insert into rapporti_tributo(pratica, cod_fiscale, tipo_rapporto)
             values (w_pratica, rec_ogco.cod_fiscale, 'D');
      --  dbms_output.put_line('Insert in rapporti_tributo.');
      exception
        when others then
          w_errore      :=
            (   'Errore in inserimento rapporto tributo'
             || ' ('
             || sqlerrm
             || ')');
          raise errore;
      end;
    end if;
    --inserisci oggetto
    --Inserimento dati in oggetti_pratica
    w_oggetto_pratica :=   null;
    oggetti_pratica_nr(w_oggetto_pratica);
    if rec_ogco.note_ogpr is null then
      w_note      :=
           'Anno: '
        || rec_ogco.anno_titr
        || ' Pratica: '
        || rec_ogco.pratica_ogpr
        || ' Ogpr: '
        || rec_ogco.oggetto_pratica_ogpr;
    else
      w_note      :=
           rec_ogco.note_ogpr
        || ' - Anno: '
        || rec_ogco.anno_titr
        || ' Pratica: '
        || rec_ogco.pratica_ogpr
        || ' Ogpr: '
        || rec_ogco.oggetto_pratica_ogpr;
    end if;
    begin
      if rec_ogco.oggetto_pratica_rif_ap is not null then
         declare
            w_num_ordine_ap oggetti_pratica.num_ordine%type;
            w_oggetto_ap number;
         begin
            select num_ordine, oggetto
              into w_num_ordine_ap, w_oggetto_ap
              from oggetti_pratica
             where oggetto_pratica =  rec_ogco.oggetto_pratica_rif_ap
               and pratica =  rec_ogco.pratica_ogpr
            ;
-- se il riferimento della pertinenza è nella stessa pratica, allora cerco nella
-- mia pratica TASI l'ogpr dello stesso oggetto
            begin
                select oggetto_pratica
                  into w_ogpr_pratica_rif_ap
                  from oggetti_pratica
                 where pratica = w_pratica
                   and oggetto = w_oggetto_ap
                   and num_ordine = w_num_ordine_ap
                ;
            exception
            when no_data_found then
               COMPONI_MSG_PERTINENZA(rec_ogco.num_ordine, rec_ogco.oggetto_ogpr);
            end;
         exception
         when no_data_found then
            COMPONI_MSG_PERTINENZA(rec_ogco.num_ordine, rec_ogco.oggetto_ogpr);
         when others then
            null;
         end;
      end if;
      insert
        into oggetti_pratica(oggetto_pratica
                            ,oggetto
                            ,pratica
                            ,anno
                            ,num_ordine
                            ,categoria_catasto
                            ,classe_catasto
                            ,valore
                            ,fonte
                            ,utente
                            ,data_variazione
                            ,note
                            ,tipo_oggetto
                            ,imm_storico
                            ,oggetto_pratica_rif_ap
                            ,titolo
                            )
      values (
              w_oggetto_pratica
             ,rec_ogco.oggetto_ogpr
             ,w_pratica
             ,w_anno
             ,rec_ogco.num_ordine
             ,rec_ogco.categoria_catasto
             ,rec_ogco.classe_catasto
             ,rec_ogco.valore
             ,w_fonte
             ,w_utente
             ,sysdate
             ,w_note
             ,rec_ogco.tipo_oggetto
             ,rec_ogco.imm_storico
             ,w_ogpr_pratica_rif_ap
             ,rec_ogco.titolo
             );
      w_tot_ogpr := w_tot_ogpr + 1;
    -- dbms_output.put_line('Insert in oggetti_pratica.');
    exception
      when others then
        w_errore      :=
          ('Errore in inserimento Oggetto Pratica' || ' (' || sqlerrm || ')');
        raise errore;
    end;
    --Inserimento dati in oggetti_contribuente
    if rec_ogco.note_ogco is null then
      w_note      :=
           'Anno: '
        || rec_ogco.anno_titr
        || ' Pratica: '
        || rec_ogco.pratica_ogpr
        || ' Ogpr: '
        || rec_ogco.oggetto_pratica_ogpr;
    else
      w_note      :=
           rec_ogco.note_ogco
        || ' - Anno: '
        || rec_ogco.anno_titr
        || ' Pratica: '
        || rec_ogco.pratica_ogpr
        || ' Ogpr: '
        || rec_ogco.oggetto_pratica_ogpr;
    end if;
    declare
       w_detrazione number;
    begin
       begin
        select round((round(detr.detrazione_base * rec_ogco.perc_detrazione / 100,2)/12)*rec_ogco.mesi_possesso,2)
          into w_detrazione
          from detrazioni  detr
         where anno = w_anno
           and tipo_tributo = 'TASI';
       exception
       when no_data_found then
          w_detrazione := 0;
       end;
      insert
        into oggetti_contribuente(cod_fiscale
                                 ,oggetto_pratica
                                 ,anno
                                 ,tipo_rapporto
                                 ,perc_possesso
                                 ,mesi_possesso
                                 ,mesi_possesso_1sem
                                  -- (AB - 01/03/2024): nuovo campo mesi_esclusione e altri
                                 ,mesi_esclusione
                                 ,mesi_riduzione
                                 ,mesi_aliquota_ridotta
                                  -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                                 ,da_mese_possesso
                                 ,detrazione
                                 ,flag_possesso
                                 ,flag_esclusione
                                 ,flag_riduzione
                                 ,flag_ab_principale
                                 ,successione
                                 ,progressivo_sudv
                                 ,utente
                                 ,data_variazione
                                 ,note
                                 ,perc_detrazione
                                 )
      values (
              rec_ogco.cod_fiscale
             ,w_oggetto_pratica
             ,w_anno
             ,'D'
             ,rec_ogco.perc_possesso
             ,rec_ogco.mesi_possesso
             ,rec_ogco.mesi_possesso_1sem
              -- (AB - 01/03/2024): nuovo campo mesi_esclusione e altri
             ,rec_ogco.mesi_esclusione
             ,rec_ogco.mesi_riduzione
             ,rec_ogco.mesi_aliquota_ridotta
              -- (VD - 11/12/2019): nuovo campo da_mese_possesso
             ,rec_ogco.da_mese_possesso
             ,decode(w_detrazione,0,null,w_detrazione)
             ,rec_ogco.flag_possesso
             ,rec_ogco.flag_esclusione
             ,rec_ogco.flag_riduzione
             ,rec_ogco.flag_ab_principale
             ,rec_ogco.successione
             ,rec_ogco.progressivo_sudv
             ,w_utente
             ,sysdate
             ,w_note
             ,rec_ogco.perc_detrazione
             );
    --   dbms_output.put_line('Insert in oggetti_uniaribuente.');
    exception
      when others then
        w_errore      :=
          (   'Errore in inserimento Oggetto Contribuente'
           || ' ('
           || sqlerrm
           || ')');
        raise errore;
    end;
    insert into aliquote_ogco(cod_fiscale
                             ,oggetto_pratica
                             ,dal
                             ,al
                             ,tipo_tributo
                             ,tipo_aliquota
                             ,note
                             )
      select rec_ogco.cod_fiscale
            ,w_oggetto_pratica
            ,greatest(to_date('01/01/' || w_anno, 'dd/mm/yyyy'), dal)
            ,al
            ,'TASI'
            ,tipo_aliquota
            ,note
        from aliquote_ogco alog
       where alog.cod_fiscale = rec_ogco.cod_fiscale
         and alog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
         and greatest(to_date('01/01/' || w_anno, 'dd/mm/yyyy'), dal) <= al;
    insert into detrazioni_ogco(cod_fiscale
                               ,oggetto_pratica
                               ,anno
                               ,motivo_detrazione
                               ,detrazione
                               ,note
                               ,detrazione_acconto
                               ,tipo_tributo
                               )
      select rec_ogco.cod_fiscale
            ,w_oggetto_pratica
            ,anno
            ,motivo_detrazione
            ,detrazione
            ,note
            ,detrazione_acconto
            ,'TASI'
        from detrazioni_ogco deog
       where deog.cod_fiscale = rec_ogco.cod_fiscale
         and deog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
         and anno >= w_anno;
    insert into costi_storici(oggetto_pratica
                             ,anno
                             ,costo
                             ,utente
                             ,data_variazione
                             ,note
                             )
      select w_oggetto_pratica, anno, costo, w_utente, sysdate, note
        from costi_storici cost
       where cost.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
         and cost.anno >= w_anno;
  end loop;
  COMPONI_OUTPUT;
  -- (VD - 25/02/2020): Aggiunta archiviazione denuncia
  if w_pratica is not null then
     ARCHIVIA_DENUNCE('','',w_pratica);
  end if;
  RETURN    w_stringa_output;
--commit;
exception
  when errore then
  --  rollback;
    raise_application_error(-20999, w_errore);
  when others then
  --  rollback;
    raise_application_error(-20999
                           ,   ' Errore in PRATICA_TASI_DA_IMU '
                            || '('
                            || sqlerrm
                            || ')'
                           );
end;
/* End Function: F_PRATICA_TASI_DA_IMU */
/
