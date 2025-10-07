--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_duplica_denuncia stripComments:false runOnChange:true 
 
create or replace function F_DUPLICA_DENUNCIA
/***********************************************************************
 NOME:        F_DUPLICA_DENUNCIA
 DESCRIZIONE: Data una pratica ICI, crea le pratiche TASI per lo stesso
              anno per il titolare ed i contitolari.
 RITORNA:     varchar2                 Stringa contenente l'elenco
                                       delle pratiche inserite.
 NOTE:
 Rev.    Date         Author      Note
 7       30/07/2023   AB          Controlli diversi per la made (not in 97,98,99)
                                  e se det_ogco null si mette null
                                  altrimenti si fa la decode di prima
 6       06/02/2023   AB          Si recupera la perc_detrtazione cosi come è
                                  nella denuncia da cui si proviene, mentre
                                  per la detrazione si calcola tenendo conto
                                  nuovi mesi e della detrazione base dell'anno
 5       28/11/2022   DM          Se detrazione null viene valorizzata a null
                                  nella denuncia duplicata.
 4       19/09/2022   VD          Aggiunto controllo congruenza flag fine anno:
                                  se flag_possesso = 'S', solo uno tra i flag
                                  esclusione, riduzione, aliquota ridotta può
                                  essere.
                                  Corretta valorizzazione campi di cui alla
                                  rev. 3.
 3       12/09/2022   VD          Aggiunta valorizzazione campi
                                  mesi_al_ridotta, mesi_riduzione e
                                  mesi_esclusione di oggetti_contribuente
 3 ?!?   02/02/2022   DM          Conrollo per tipo_tributo.
 2       14/01/2022   DM          Il tipo evento della nuova pratica
                                  viene ora recuperato dalla pratica
                                  da duplicare.
 1       29/12/2020   VD          Corretta gestione tipi oggetto:
                                  se la nuova denuncia è per l'IMU
                                  si duplicano tutti gli oggetti, se
                                  invece si tratta di TASI si duplicano solo
                                  gli oggetti di tipo 2, 3, 4, 55
                                  (aree fabbricabili + fabbricati)
 0       06/11/2020   VD          Prima emissione
************************************************************************/
( p_pratica                       number
, p_new_tipo_tributo              varchar2
, p_new_anno                      number
, p_new_cod_fiscale               varchar2
, p_utente                        varchar2
, p_flag_duplica_cont             varchar2
) return varchar2
as
  w_anno              number;
  w_old_tipo_tributo  varchar2(5);
  w_old_cod_fiscale   varchar2(16);
  w_tipo_evento       varchar2(1);
  w_ni                number;
  w_cod_fiscale       varchar2(16) := 'ZZZZZZZZZZZZZZZZ';
  w_cod_fiscale_ins   varchar2(16);
  w_pratica           number;
  w_utente            varchar2(8)  := p_utente;
  w_oggetto_pratica   number;
  w_note              oggetti_pratica.note%type;
  w_fonte             number := 4;
  w_ogpr_pratica_rif_ap number; --ogpr rif ap da mettere nella nuova pratica tasi
  w_cognome_nome      varchar2(32000);
  w_stringa_output    varchar2(32000) := 'Pratiche generate:'||chr(10)||chr(13);
  w_msg_pertinenza    varchar2(32000);
  w_msg_pratiche      varchar2(32000);
  w_tot_ogpr          number := 0;
  w_conta             number := 0;
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
                        ,a_anno --prtr.anno
                        ,'CA'
                        )
               categoria_catasto_ogpr
            ,ogpr.oggetto_pratica oggetto_pratica_ogpr
            ,ogco.anno anno_ogco
            ,ogco.cod_fiscale cod_fiscale
            ,ogco.flag_possesso
            ,ogco.perc_possesso
            ,decode(ogco.anno, a_anno, nvl(ogco.mesi_possesso, 12), 12)
               mesi_possesso
            ,decode(ogco.anno, a_anno, ogco.mesi_possesso_1sem, 6)
               mesi_possesso_1sem
             -- (VD - 11/12/2019): nuovo campo da_mese_possesso
            ,decode(ogco.anno,
                    a_anno, nvl(ogco.da_mese_possesso,
                                decode(nvl(ogco.mesi_possesso,12),12,1,
                                       decode(ogco.flag_possesso,'S',12 - ogco.mesi_possesso + 1,1))),
                               1)
               da_mese_possesso
            ,ogco.flag_al_ridotta
            ,decode(ogco.anno
                   ,a_anno, decode(ogco.flag_al_ridotta
                                  ,'S', nvl(ogco.mesi_aliquota_ridotta
                                           ,nvl(ogco.mesi_possesso, 12)
                                           )
                                  ,ogco.mesi_aliquota_ridotta
                                  )
                   ,decode(ogco.flag_al_ridotta, 'S', 12, to_number(null))
                   )
               mesi_aliquota_ridotta
            ,decode(ogco.anno,
                    a_anno, nvl(ogco.da_mese_al_ridotta,
                                decode(nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso, 12))
                                      ,12,1
                                      ,decode(ogco.flag_possesso,'S',12 - nvl(ogco.mesi_aliquota_ridotta,nvl(ogco.mesi_possesso, 12)) + 1,1))),
                               1)
               da_mese_al_ridotta
            ,ogco.flag_esclusione
            ,decode(ogco.anno
                   ,a_anno, decode(ogco.flag_esclusione
                                  ,'S', nvl(ogco.mesi_esclusione
                                           ,nvl(ogco.mesi_possesso, 12)
                                           )
                                  ,ogco.mesi_esclusione
                                  )
                   ,decode(ogco.flag_esclusione, 'S', 12, to_number(null))
                   )
               mesi_esclusione
            ,decode(ogco.anno,
                    a_anno, nvl(ogco.da_mese_esclusione,
                                decode(nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso, 12)),12,1,
                                       decode(ogco.flag_possesso,'S',12 - nvl(ogco.mesi_esclusione,nvl(ogco.mesi_possesso, 12)) + 1,1))),
                               1)
               da_mese_esclusione
            ,ogco.flag_riduzione
            ,decode(ogco.anno
                   ,a_anno, decode(ogco.flag_riduzione
                                  ,'S', nvl(ogco.mesi_riduzione
                                           ,nvl(ogco.mesi_possesso, 12)
                                           )
                                  ,ogco.mesi_riduzione
                                  )
                   ,decode(ogco.flag_riduzione, 'S', 12, to_number(null))
                   )
               mesi_riduzione
            ,decode(ogco.anno,
                    a_anno, nvl(ogco.da_mese_riduzione,
                                decode(nvl(ogco.mesi_riduzione,nvl(ogco.mesi_possesso, 12)),12,1,
                                       decode(ogco.flag_possesso,'S',12 - ogco.mesi_possesso + 1,1))),
                               1)
               da_mese_riduzione
            ,ogco.flag_ab_principale flag_ab_principale
            ,f_valore(ogpr.valore
                     ,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,prtr.anno
                     ,a_anno
                     ,f_dato_riog(ogco.cod_fiscale
                                 ,ogco.oggetto_pratica
                                 ,a_anno --prtr.anno
                                 ,'CA'
                                 )
                     ,prtr.tipo_pratica
                     ,'N') valore
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
                              || to_char(sign(2012 - a_anno))
                             ,'S1', 100
                             ,nvl(molt.moltiplicatore, 1)
                             )
                   ,1
                   )
               moltiplicatore
            ,ogpr.imm_storico
            ,ogpr.oggetto_pratica_rif_ap
            ,rire.aliquota aliquota_rivalutazione
            ,made.detrazione detrazione_made
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
--            ,decode(ogco.detrazione,
--              null,
--              null,
--              round(round(decode(nvl(ogco.mesi_possesso, 12),
--                                 0,
--                                 0,
--                                 nvl(ogco.detrazione, 0) /
--                                 nvl(ogco.mesi_possesso, 12) * 12),
--                          2) / nvl(detr.detrazione_base, 0) * 100,
--                    2)) perc_detrazione
            ,ogco.perc_detrazione
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
         and detr.tipo_tributo = p_new_tipo_tributo
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
         and made.cod_fiscale(+) = decode(ogco.cod_fiscale,w_old_cod_fiscale,p_new_cod_fiscale,ogco.cod_fiscale)
         and made.tipo_tributo(+) = p_new_tipo_tributo
         and made.motivo_detrazione (+) not in (97,98,99)
         and ogge.oggetto = ogpr.oggetto
         and prtr.pratica = a_pratica
         and prtr.pratica = ogpr.pratica
         and ogpr.oggetto_pratica = ogco.oggetto_pratica
         and (p_new_tipo_tributo = 'ICI' or
             (p_new_tipo_tributo = 'TASI' and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) in (2, 3, 4, 55)))
         and (w_old_cod_fiscale = p_new_cod_fiscale or
             (w_old_cod_fiscale <> p_new_cod_fiscale and
              ogco.cod_fiscale <> p_new_cod_fiscale))
         and (nvl(p_flag_duplica_cont,'N') = 'S' or
             (nvl(p_flag_duplica_cont,'N') = 'N' and
              ogco.cod_fiscale = w_old_cod_fiscale))
    order by decode(ogco.cod_fiscale,w_old_cod_fiscale,1,2)
           , ogco.cod_fiscale
           , prtr.anno, prtr.pratica
           , oggetto_pratica_rif_ap desc --serve per copiare prima quelle con oggetto_pratica_rif_ap null
           , ogpr.oggetto_pratica
    ;
--------------------------------------------------------------------------------
PROCEDURE CONTROLLO_DENUNCIA
( a_tipo_tributo                   varchar2
, a_anno                           number
, a_cod_fiscale                    varchar2
) AS
  w_pratica                        number;
BEGIN
  -- Si controlla se esiste già una denuncia per i nuovi tipo tributo/anno/
  -- contribuente
  begin
    select pratica
      into w_pratica
      from pratiche_tributo
     where tipo_tributo = a_tipo_tributo
       and anno = a_anno
       and cod_fiscale = a_cod_fiscale
       and tipo_pratica = 'D';
  exception
    when too_many_rows then
      w_pratica := 0;
    when others then
      w_pratica := to_number(null);
  end;
  if w_pratica is not null then
     w_msg_pratiche := 'Attenzione: denuncia '||f_descrizione_titr(a_tipo_tributo,a_anno)||
                       ' anno '|| a_anno || ' gia'' esistente';
     if w_pratica > 0 then
        w_msg_pratiche := w_msg_pratiche||' (Pratica n.'||w_pratica||')';
     end if;
  end if;
end;
--------------------------------------------------------------------------------
PROCEDURE COMPONI_OUTPUT AS
BEGIN
  if w_cod_fiscale != 'ZZZZZZZZZZZZZZZZ' then
     w_stringa_output := w_stringa_output||w_cognome_nome||' - '||w_cod_fiscale_ins||chr(10)||chr(13);
     if w_msg_pratiche is not null then
        w_stringa_output := w_stringa_output||w_msg_pratiche||chr(10)||chr(13);
     end if;
     w_stringa_output := w_stringa_output||'Inserita pratica '||w_pratica||' con '||w_tot_ogpr||' oggetti';
     if w_msg_pertinenza is not null then
        w_stringa_output :=  w_stringa_output||w_msg_pertinenza||')';
     end if;
     w_stringa_output :=  w_stringa_output||'.'||chr(10)||chr(13);
  else
     w_stringa_output := 'Inserite 0 pratiche, controllare i dizionari '||f_descrizione_titr(p_new_tipo_tributo, w_anno)||' per l''anno '||p_new_anno;
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
     where parametro = 'FONT_DUPD'
    ;
  exception
  when others then
    w_errore := 'Parametro FONT_DUPD non presente in installazione_parametri.';
    raise errore;
  end;
--DBMS_OUTPUT.PUT_LINE('FONTE: '||w_fonte);
  select anno
       , tipo_tributo
       , cod_fiscale
       , tipo_evento
    into w_anno
       , w_old_tipo_tributo
       , w_old_cod_fiscale
       , w_tipo_evento
    from pratiche_tributo
   where pratica = p_pratica;
   -- Si controlla che il tipo_tributo sia UMI o TASI
   if (w_old_tipo_tributo not in ('ICI', 'TASI')) then
     w_errore := 'Duplica denuncia non possibile per il tributo ' || f_descrizione_titr(w_old_tipo_tributo, w_anno);
     raise errore;
   end if;
  -- (VD - 19/09/2022): si verifica la correttezza dei flag di fine anno sui
  --                    dettagli della denuncia.
  --                    Se il flag_possesso è 'S', solo uno dei flag tra
  --                    esclusione, riduzione e aliquota_ridotta puo' essere
  --                    attivo
  begin
    select count(*)
      into w_conta
      from oggetti_contribuente ogco
         , oggetti_pratica      ogpr
     where ogpr.pratica = p_pratica
       and ogpr.oggetto_pratica = ogco.oggetto_pratica
       and ((ogco.flag_possesso = 'S' and
             ogco.flag_esclusione||ogco.flag_riduzione||ogco.flag_al_ridotta like 'SS%')
        or  (ogco.flag_possesso is null and
             ogco.flag_esclusione||ogco.flag_riduzione||ogco.flag_al_ridotta like 'S%'))
     group by pratica;
  exception
    when others then
      w_conta := 0;
  end;
  if w_conta > 0 then
     w_errore := 'Incongruenza flag possesso/esclusione/riduzione/al.ridotta - Verificare i dettagli della denuncia';
     raise errore;
   end if;
  -- Se il nuovo codice fiscale e' diverso da quello della denuncia da
  -- duplicare, si verifica se è gia' contribuente
--DBMS_OUTPUT.PUT_LINE('ANNO OLD: '||w_anno);
--DBMS_OUTPUT.PUT_LINE('TIPO TRIBUTO OLD: '||w_old_tipo_tributo);
--DBMS_OUTPUT.PUT_LINE('COD.FISCALE OLD: '||w_old_cod_fiscale);
  if w_old_cod_fiscale <> p_new_cod_fiscale then
     begin
       select ni
         into w_ni
         from contribuenti
        where cod_fiscale = p_new_cod_fiscale;
     exception
       when no_data_found then
         w_ni := to_number(null);
       when others then
         w_ni := 0;
     end;
     if w_ni is null then
        begin
          insert into contribuenti ( cod_fiscale, ni )
          select p_new_cod_fiscale, max(sogg.ni)
            from soggetti sogg
           where sogg.cod_fiscale = p_new_cod_fiscale;
        exception
          when others then
            w_errore := 'Ins. Contribuenti '||p_new_cod_fiscale||' - '||sqlerrm;
            raise errore;
        end;
     end if;
  end if;
  --
  for rec_ogco in sel_ogco(p_pratica,p_new_anno)
  loop
    w_ogpr_pratica_rif_ap := null;
    --w_anno := rec_ogco.anno_titr;
    if rec_ogco.cod_fiscale != w_cod_fiscale then
    --DBMS_OUTPUT.PUT_LINE('w_cod_fiscale: '||w_cod_fiscale);
    --DBMS_OUTPUT.PUT_LINE('w_cod_fiscale: '||rec_ogco.cod_fiscale);
      if w_cod_fiscale != 'ZZZZZZZZZZZZZZZZ' then
         COMPONI_OUTPUT;
         -- (VD - 25/02/2020): Aggiunta archiviazione denuncia
         ARCHIVIA_DENUNCE('','',w_pratica);
         w_msg_pertinenza := null;
         w_msg_pratiche   := null;
         w_tot_ogpr := 0;
      end if;
     -- commit;
      if rec_ogco.cod_fiscale = w_old_cod_fiscale then
         w_cod_fiscale_ins := p_new_cod_fiscale;
      else
         w_cod_fiscale_ins := rec_ogco.cod_fiscale;
      end if;
      w_cod_fiscale := rec_ogco.cod_fiscale;
      select SOGG.COGNOME_NOME
        into w_cognome_nome
        from soggetti sogg, contribuenti cont
       where cont.cod_fiscale = w_cod_fiscale_ins
         and cont.ni = sogg.ni
      ;
      -- A cambio codice fiscale si controlla se esiste gia' una denuncia
      -- analoga a quella che si deve inserire (stessi tipo tributo, anno e
      -- codice fiscale). Nel caso si stia trattando il contribuente di cui
      -- si sta duplicando la denuncia), il controllo viene fatto con
      -- l'eventuale nuovo codice fiscale (gia' determinato nella select).
      controllo_denuncia(p_new_tipo_tributo,p_new_anno,w_cod_fiscale_ins);
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
               ,w_cod_fiscale_ins
               ,p_new_tipo_tributo
               ,p_new_anno
               ,'D'
               ,w_tipo_evento
               ,trunc(sysdate)
               ,w_utente
               ,trunc(sysdate)
               ,ltrim(rec_ogco.note_prtr||' Duplica denuncia '||f_descrizione_titr(w_old_tipo_tributo,w_anno)
                                        ||' '||w_anno||' di '||w_old_cod_fiscale||' eseguita il '
                                        ||to_char(sysdate, 'dd/mm/yyyy'))
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
      -- DENUNCE IMU/TASI
      if p_new_tipo_tributo = 'ICI' then
         begin
           insert
             into denunce_ici(pratica
                             ,denuncia
                             ,fonte
                             ,utente
                             ,data_variazione
                             ,note
                             )
           values (w_pratica
                  ,w_pratica
                  ,w_fonte
                  ,w_utente
                  ,sysdate
                  ,'Duplica denuncia '||f_descrizione_titr(w_old_tipo_tributo,w_anno)||
                   ' '||w_anno||' di '||w_old_cod_fiscale||' eseguita il '||
                   to_char(sysdate, 'dd/mm/yyyy')
                  );
         --  dbms_output.put_line('Insert in denunce_ici.');
         exception
           when others then
             w_errore      :=
               (   'Errore in inserimento nuova denuncia ICI'
                || ' ('
                || sqlerrm
                || ')');
             raise errore;
         end;
      else
         begin
           insert
             into denunce_tasi(pratica
                              ,denuncia
                              ,fonte
                              ,utente
                              ,data_variazione
                              ,note
                              )
           values (w_pratica
                  ,w_pratica
                  ,w_fonte
                  ,w_utente
                  ,sysdate
                  ,'Duplica denuncia '||f_descrizione_titr(w_old_tipo_tributo,w_anno)||
                   ' '||w_anno||' di '||w_old_cod_fiscale||
                   ' eseguita il '|| to_char(sysdate, 'dd/mm/yyyy')
                  );
         --  dbms_output.put_line('Insert in denunce_ici.');
         exception
           when others then
             w_errore      :=
               (   'Errore in inserimento nuova denuncia TASI'
                || ' ('
                || sqlerrm
                || ')');
             raise errore;
         end;
      end if;
      -- ...rapporti_tributo
      begin
        insert into rapporti_tributo(pratica, cod_fiscale, tipo_rapporto)
             values (w_pratica, w_cod_fiscale_ins, 'D');
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
    if rec_ogco.note_ogpr is not null then
       w_note      := rec_ogco.note_ogpr || ' - ';
    else
       w_note      := null;
    end if;
    w_note      := w_note
                || 'Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
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
             ,p_new_anno
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
    if rec_ogco.note_ogco is not null then
       w_note      := rec_ogco.note_ogco|| ' - ';
    else
       w_note      := null;
    end if;
    w_note      := w_note
                || 'Anno: '
                || rec_ogco.anno_titr
                || ' Pratica: '
                || rec_ogco.pratica_ogpr
                || ' Ogpr: '
                || rec_ogco.oggetto_pratica_ogpr;
    declare
       w_detrazione number;
    begin
       begin
        select round((round(detr.detrazione_base * nvl(rec_ogco.perc_detrazione,100) / 100,2)/12)*rec_ogco.mesi_possesso,2)
          into w_detrazione
          from detrazioni  detr
         where anno = p_new_anno
           and tipo_tributo = p_new_tipo_tributo;
       exception
       when no_data_found then
          w_detrazione := null;
       end;
--         dbms_output.put_line('prima di ins_ogco: ab '||rec_ogco.flag_ab_principale||' og '||rec_ogco.oggetto_ogpr||
--          ' ogco_det '||rec_ogco.detrazione||' made_det '||rec_ogco.detrazione_made||' det'||w_detrazione);
insert
        into oggetti_contribuente(cod_fiscale
                                 ,oggetto_pratica
                                 ,anno
                                 ,tipo_rapporto
                                 ,perc_possesso
                                 ,mesi_possesso
                                 ,mesi_possesso_1sem
                                  -- (VD - 12/09/2022): aggiunti mesi_esclusione e vari
                                 ,mesi_esclusione
                                 ,mesi_riduzione
                                 ,mesi_aliquota_ridotta
                                  -- (VD - 11/12/2019): nuovo campo da_mese_possesso
                                 ,da_mese_possesso
                                 ,da_mese_esclusione
                                 ,da_mese_riduzione
                                 ,da_mese_al_ridotta
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
      values (w_cod_fiscale_ins
             ,w_oggetto_pratica
             ,p_new_anno
             ,'D'
             ,rec_ogco.perc_possesso
             ,rec_ogco.mesi_possesso
             ,rec_ogco.mesi_possesso_1sem
              -- (VD - 12/09/2022): aggiunti mesi_esclusione e vari
             ,rec_ogco.mesi_esclusione
             ,rec_ogco.mesi_riduzione
             ,rec_ogco.mesi_aliquota_ridotta
              -- (VD - 11/12/2019): nuovo campo da_mese_possesso
             ,rec_ogco.da_mese_possesso
             ,rec_ogco.da_mese_esclusione
             ,rec_ogco.da_mese_riduzione
             ,rec_ogco.da_mese_al_ridotta
             -- Se la detrazione di partenza è null deve essere settata a null in quella di arrivo
             -- modifica AB del 31/01/2023 manteniamo la w_detrazione determinata con la perc_detrazione di ogco, se made is null
             ,decode(rec_ogco.detrazione,'','',
                     decode(rec_ogco.detrazione,rec_ogco.detrazione_made,rec_ogco.detrazione_made,w_detrazione))
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
      select w_cod_fiscale_ins
            ,w_oggetto_pratica
            ,greatest(to_date('01/01/' || p_new_anno, 'dd/mm/yyyy'), dal)
            ,al
            ,p_new_tipo_tributo
            ,tipo_aliquota
            ,note
        from aliquote_ogco alog
       where alog.cod_fiscale = rec_ogco.cod_fiscale
         and alog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
         and greatest(to_date('01/01/' || p_new_anno, 'dd/mm/yyyy'), dal) <= al;
    insert into detrazioni_ogco(cod_fiscale
                               ,oggetto_pratica
                               ,anno
                               ,motivo_detrazione
                               ,detrazione
                               ,note
                               ,detrazione_acconto
                               ,tipo_tributo
                               )
      select w_cod_fiscale_ins
            ,w_oggetto_pratica
            ,anno
            ,motivo_detrazione
            ,detrazione
            ,note
            ,detrazione_acconto
            ,p_new_tipo_tributo
        from detrazioni_ogco deog
       where deog.cod_fiscale = rec_ogco.cod_fiscale
         and deog.oggetto_pratica = rec_ogco.oggetto_pratica_ogpr
         and anno >= p_new_anno;
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
         and cost.anno >= p_new_anno;
  end loop;
  if w_cod_fiscale <> 'ZZZZZZZZZZZZZZZZ' and
     w_pratica is not null then
     -- (VD - 25/02/2020): Aggiunta archiviazione denuncia
     ARCHIVIA_DENUNCE('','',w_pratica);
  end if;
  COMPONI_OUTPUT;
  RETURN    w_stringa_output;
--commit;
exception
  when errore then
  --  rollback;
    raise_application_error(-20999, w_errore);
  when others then
  --  rollback;
    raise_application_error(-20999
                           ,   ' Errore in DUPLICA_DENUNCIA '
                            || '('
                            || sqlerrm
                            || ')'
                           );
end;
/* End Function: F_DUPLICA_DENUNCIA */
/

