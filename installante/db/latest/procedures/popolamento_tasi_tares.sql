--liquibase formatted sql 
--changeset abrandolini:20250326_152423_popolamento_tasi_tares stripComments:false runOnChange:true 
 
create or replace procedure POPOLAMENTO_TASI_TARES
/*************************************************************************
 Versione  Data              Autore    Descrizione
 1         10/01/2020        VD        Aggiunta archiviazione denunce
 0         26/03/2014        XX        Prima emissione
*************************************************************************/
(a_cod_fiscale  varchar2 DEFAULT '%'
,a_fonte        number
)
as
  w_anno              number := 2014;
  w_cod_fiscale       varchar2(16) := 'ZZZZZZZZZZZZZZZZ';
  w_pratica           number;
  w_utente            varchar2(6)  := 'TTASI';
  w_oggetto_pratica   number;
  w_note              oggetti_pratica.note%type;
  w_oggetto            number;
  w_num_ordine_num     number := 0;
  w_num_ordine         varchar2(5);
  w_categoria_catasto  varchar2(3);
  w_classe_catasto     varchar2(2);
  w_valore             number;
  w_tipo_oggetto       number;
  w_UTOG               varchar2(1) := 'S';
  w_conta_pratiche     number := 0;
  --Gestione delle eccezioni
  w_errore            varchar2(2000);
  errore              exception;
  cursor sel_ogco(a_anno_rif number)
  is
      select ogva.cod_fiscale cod_fiscale
           , prtr.anno anno_titr
           , prtr.pratica
           , ogpr.oggetto_pratica
           , ogge.oggetto
           , ogge.tipo_oggetto
           , ogge.categoria_catasto
           , ogge.foglio
           , ogge.numero
           , ogge.subalterno
           , ogge.estremi_catasto
        from oggetti ogge
           , pratiche_tributo prtr
           , oggetti_pratica ogpr
           , oggetti_validita ogva
       where ogge.oggetto = ogpr.oggetto
         and prtr.tipo_tributo || '' = 'TARSU'
         and nvl(prtr.stato_accertamento, 'D') = 'D'
         and prtr.pratica = ogpr.pratica
         and ogpr.oggetto_pratica = ogva.oggetto_pratica
         and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) in (3,5)
         and not exists (select 1
                           from pratiche_tributo prtr_tasi
                          where prtr_tasi.cod_fiscale = ogva.cod_fiscale
                            and prtr_tasi.utente      = w_utente
                            and prtr_tasi.anno        = w_anno)
         and ogva.cod_fiscale      like a_cod_fiscale
      --   and nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) = nvl(a_tipo_oggetto,nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto))
         and to_date('01/01/2014','dd/mm/yyyy') between nvl(ogva.dal, to_date('01/01/1900','dd/mm/yyyy'))
                                                    and nvl(ogva.al, to_date('31/12/2999','dd/mm/yyyy'))
  union
      select cont.cod_fiscale
           , null
           , null
           , null
           , utog.oggetto
           , ogge.tipo_oggetto
           , ogge.categoria_catasto
           , ogge.foglio
           , ogge.numero
           , ogge.subalterno
           , estremi_catasto
        from contribuenti      cont
           , utilizzi_oggetto  utog
           , oggetti           ogge
       where utog.ni = cont.ni
         and cont.cod_fiscale like a_cod_fiscale
         and ogge.oggetto = utog.oggetto
         and ogge.tipo_oggetto = 3
         and nvl(utog.tipo_tributo,'ICI') = 'ICI'
         and nvl(utog.data_scadenza,to_date('31/12/2999','dd/mm/yyyy')) >= to_date('01/01/2014','dd/mm/yyyy')
         and not exists (select 1
                           from pratiche_tributo prtr_tasi
                          where prtr_tasi.cod_fiscale = cont.cod_fiscale
                            and prtr_tasi.utente      = w_utente
                            and prtr_tasi.anno        = w_anno
                        )
         -- l'oggetto deve essere in una denuncia TASI di un Proprietario,
         -- non ho verificato la validità perchè gli oggetti denunciati con la TASI sono tutti validi
         and exists ( select 2
                        from pratiche_tributo prtr2
                           , oggetti_pratica  ogpr2
                           , oggetti_contribuente ogco2
                       where prtr2.pratica = ogpr2.pratica
                         and ogpr2.oggetto_pratica = ogco2.oggetto_pratica
                         and ogco2.tipo_rapporto = 'D'
                         and prtr2.tipo_pratica||'' = 'TASI'
                         and ogpr2.oggetto = ogge.oggetto
                         and prtr2.anno = 2014
                         and ogco2.cod_fiscale <> cont.cod_fiscale
                    )
         -- L'oggetto non deve essere giaà stato estratto dalla prima query della union
         and not exists (  select 3
                             from oggetti              ogge3
                                , pratiche_tributo     prtr3
                                , oggetti_pratica      ogpr3
                                , oggetti_validita     ogva3
                            where ogge3.oggetto = ogpr3.oggetto
                              and prtr3.tipo_tributo || '' = 'TARSU'
                              and nvl(prtr3.stato_accertamento, 'D') = 'D'
                              and prtr3.pratica = ogpr3.pratica
                              and ogpr3.oggetto_pratica = ogva3.oggetto_pratica
                              and nvl(ogpr3.tipo_oggetto,ogge3.tipo_oggetto) in (3,5)
                              and not exists (select 1
                                                from pratiche_tributo prtr_tasi3
                                               where prtr_tasi3.cod_fiscale = ogva3.cod_fiscale
                                                 and prtr_tasi3.utente      = w_utente
                                                 and prtr_tasi3.anno        = w_anno)
                              and ogva3.cod_fiscale = cont.cod_fiscale
                              and ogge3.oggetto     = ogge.oggetto
                          --    and nvl(ogpr3.tipo_oggetto,ogge3.tipo_oggetto) = nvl(a_tipo_oggetto,nvl(ogpr3.tipo_oggetto,ogge3.tipo_oggetto))
                              and to_date('01/01/2014','dd/mm/yyyy') between nvl(ogva3.dal, to_date('01/01/1900','dd/mm/yyyy'))
                                                                         and nvl(ogva3.al, to_date('31/12/2999','dd/mm/yyyy'))
                        )
         and w_UTOG = 'S'
         and utog.tipo_utilizzo in (1,2,3,4)
    order by 1,2,3,4,5
    ;
begin
  for rec_ogco in sel_ogco(w_anno) loop
     w_oggetto            := null;
     w_categoria_catasto  := null;
     w_classe_catasto     := null;
     w_valore             := null;
     w_tipo_oggetto       := null;
      -- Verifica se l'oggetto è presente in una denuncia TASI
      begin
         select ogge.oggetto
              , ogpr.categoria_catasto
              , ogpr.classe_catasto
              , nvl(f_valore_da_rendita(f_rendita_anno_riog(ogge.oggetto, w_anno), ogge.tipo_oggetto, w_anno, ogge.categoria_catasto, 'N')
                   ,ogpr.valore) valore
              , ogge.tipo_oggetto
           into w_oggetto
              , w_categoria_catasto
              , w_classe_catasto
              , w_valore
              , w_tipo_oggetto
           from pratiche_tributo  prtr
              , oggetti_pratica   ogpr
              , oggetti_contribuente  ogco
              , oggetti               ogge
          where prtr.pratica = ogpr.pratica
            and ogpr.oggetto_pratica = ogco.oggetto_pratica
            and ogco.cod_fiscale <> rec_ogco.cod_fiscale
            and ogpr.oggetto = ogge.oggetto
            and prtr.tipo_tributo||'' = 'TASI'
            and ogpr.oggetto = rec_ogco.oggetto
            and prtr.tipo_pratica = 'D'
            ;
      exception
        when no_data_found then
           w_oggetto := null;
        when too_many_rows then
--             w_errore      :=
--               ('Trovato lo stsso oggetto più di una volta ' || ' (ogg: ' || to_char(rec_ogco.oggetto) || ')');
--             raise errore;
           w_oggetto            := rec_ogco.oggetto;
           w_categoria_catasto  := rec_ogco.categoria_catasto;
           w_classe_catasto     := null;
           w_valore             := nvl(f_valore_da_rendita(f_rendita_anno_riog(rec_ogco.oggetto, w_anno), rec_ogco.tipo_oggetto, w_anno, rec_ogco.categoria_catasto, 'N')
                                      ,0);
           w_tipo_oggetto       := rec_ogco.tipo_oggetto;
      end;
      -- Verifica se esiste un oggetto con gli stessi dati catastali su una denuncia TASI
     if w_oggetto is null then
        begin
            select ogge.oggetto
                 , ogpr.categoria_catasto
                 , ogpr.classe_catasto
                 , nvl(f_valore_da_rendita(f_rendita_anno_riog(ogge.oggetto, w_anno), ogge.tipo_oggetto, w_anno, ogge.categoria_catasto, 'N')
                      ,ogpr.valore) valore
                 , ogge.tipo_oggetto
              into w_oggetto
                 , w_categoria_catasto
                 , w_classe_catasto
                 , w_valore
                 , w_tipo_oggetto
              from pratiche_tributo  prtr
                 , oggetti_pratica   ogpr
                 , oggetti_contribuente  ogco
                 , oggetti               ogge
             where prtr.pratica = ogpr.pratica
               and ogpr.oggetto_pratica = ogco.oggetto_pratica
               and ogco.cod_fiscale <> rec_ogco.cod_fiscale
               and ogpr.oggetto = ogge.oggetto
               and prtr.tipo_tributo||'' = 'TASI'
               and prtr.tipo_pratica = 'D'
               and ogge.estremi_catasto = rec_ogco.estremi_catasto
               and ogge.foglio is not null
               and ogge.numero is not null
               and ogge.subalterno is not null
               and substr(ogge.categoria_catasto,1,1) = substr(rec_ogco.categoria_catasto,1,1)
               ;
        exception
           when no_data_found then
              w_oggetto := null;
           when too_many_rows then
--                w_errore      :=
--                  ('Trovato lo stsso oggetto più di una volta '
--                  || ' (foglio: ' || rec_ogco.foglio
--                  || ' - num: ' || rec_ogco.numero
--                  || ' - sub: ' || rec_ogco.subalterno
--                  || ' - cat: ' || substr(rec_ogco.categoria_catasto,1,1)
--                  || ')');
--                raise errore;
               select ogge.oggetto
                    , ogpr.categoria_catasto
                    , ogpr.classe_catasto
                    , nvl(f_valore_da_rendita(f_rendita_anno_riog(ogge.oggetto, w_anno), ogge.tipo_oggetto, w_anno, ogge.categoria_catasto, 'N')
                         ,ogpr.valore) valore
                    , ogge.tipo_oggetto
                 into w_oggetto
                    , w_categoria_catasto
                    , w_classe_catasto
                    , w_valore
                    , w_tipo_oggetto
                 from pratiche_tributo  prtr
                    , oggetti_pratica   ogpr
                    , oggetti_contribuente  ogco
                    , oggetti               ogge
                where prtr.pratica = ogpr.pratica
                  and ogpr.oggetto_pratica = ogco.oggetto_pratica
                  and ogco.cod_fiscale <> rec_ogco.cod_fiscale
                  and ogpr.oggetto = ogge.oggetto
                  and prtr.tipo_tributo||'' = 'TASI'
                  and prtr.tipo_pratica = 'D'
                  and ogge.estremi_catasto = rec_ogco.estremi_catasto
                  and ogge.foglio is not null
                  and ogge.numero is not null
                  and ogge.subalterno is not null
                  and substr(ogge.categoria_catasto,1,1) = substr(rec_ogco.categoria_catasto,1,1)
                  and rownum = 1
                  ;
        end;
     end if;
     if w_oggetto is not null then
       if rec_ogco.cod_fiscale != w_cod_fiscale then
       --  commit;
         -- (VD - 13/01/2020): Aggiunta archiviazione denuncia appena inserita
         if w_pratica is not null then
            archivia_denunce('','',w_pratica);
         end if;
         w_cod_fiscale :=   rec_ogco.cod_fiscale;
         w_num_ordine_num := 0;
         -- inserisci pratica
         begin
           w_conta_pratiche := w_conta_pratiche + 1;
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
                                  )
           values (
                   w_pratica
                  ,w_cod_fiscale
                  ,'TASI'
                  ,w_anno
                  ,'D'
                  ,'I'
                  ,trunc(sysdate)
                  ,w_utente
                  ,trunc(sysdate)
                  ,' Popolamento TASI da TARES '
                  ||decode(w_UTOG,'S',' e Utilizzi Oggetto ','')
                  ||'eseguito il '
                  || to_char(sysdate, 'dd/mm/yyyy')
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
                  ,a_fonte
                  ,w_utente
                  ,sysdate
                  ,' Popolamento TASI da TARES '
                  ||decode(w_UTOG,'S',' e Utilizzi Oggetto ','')
                  ||'eseguito il '
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
                values (w_pratica, w_cod_fiscale, 'A');
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
       --Inserimento dati in oggetti_pratica
       w_oggetto_pratica :=   null;
       oggetti_pratica_nr(w_oggetto_pratica);
       if rec_ogco.anno_titr is null then
         w_note := 'Utilizzi Oggetto';
       else
         w_note      :=
              'Anno: '
           || rec_ogco.anno_titr
           || ' Pratica: '
           || rec_ogco.pratica
           || ' Ogpr: '
           || rec_ogco.oggetto_pratica;
       end if;
       w_num_ordine_num := w_num_ordine_num + 1;
       begin
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
                               )
         values (
                 w_oggetto_pratica
                ,w_oggetto
                ,w_pratica
                ,w_anno
                ,lpad(to_char(w_num_ordine_num),3,'0')
                ,w_categoria_catasto
                ,w_classe_catasto
                ,w_valore
                ,a_fonte
                ,w_utente
                ,sysdate
                ,w_note
                ,w_tipo_oggetto
                ,null
                ,null
                );
       -- dbms_output.put_line('Insert in oggetti_pratica.');
       exception
         when others then
           w_errore      :=
             ('Errore in inserimento Oggetto Pratica' || ' (' || sqlerrm || ')');
           raise errore;
       end;
       --Inserimento dati in oggetti_contribuente
       if rec_ogco.anno_titr is null then
          w_note := 'Utilizzi Oggetto';
       else
         w_note      :=
              'Anno: '
           || rec_ogco.anno_titr
           || ' Pratica: '
           || rec_ogco.pratica
           || ' Ogpr: '
           || rec_ogco.oggetto_pratica;
        end if;
       begin
         insert
           into oggetti_contribuente(cod_fiscale
                                    ,oggetto_pratica
                                    ,anno
                                    ,tipo_rapporto
                                    ,perc_possesso
                                    ,mesi_possesso
                                    ,mesi_possesso_1sem
                                    ,detrazione
                                    ,flag_possesso
                                    ,flag_esclusione
                                    ,flag_riduzione
                                    ,flag_ab_principale
                                    ,utente
                                    ,data_variazione
                                    ,note
                                    )
         values (
                 w_cod_fiscale
                ,w_oggetto_pratica
                ,w_anno
                ,'A'
                ,100
                ,12
                ,6
                ,null
                ,'S'
                ,null
                ,null
                ,null
                ,w_utente
                ,sysdate
                ,w_note
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
     end if;
  end loop;
  -- (VD - 13/01/2020): Aggiunta archiviazione ultima denuncia inserita
  if w_pratica is not null then
     archivia_denunce('','',w_pratica);
  end if;
  dbms_output.put_line('Pratiche inserite: '||w_conta_pratiche);
  --commit;
exception
  when errore then
    rollback;
    raise_application_error(-20999, w_errore);
  when others then
    rollback;
    raise_application_error(-20999
                           ,   ' Errore in POPOLAMENTO_TASI_TARES '
                            || '('
                            || sqlerrm
                            || ')'
                           );
end;
/* End Procedure: POPOLAMENTO_TASI_TARES */
/

