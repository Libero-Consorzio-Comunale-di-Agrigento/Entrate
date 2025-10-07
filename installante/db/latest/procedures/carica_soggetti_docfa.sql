--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_soggetti_docfa stripComments:false runOnChange:true 
 
create or replace procedure CARICA_SOGGETTI_DOCFA
(
  a_documento_id         in     number
 ,a_documento_multi_id   in     number
 ,a_messaggio            in out varchar2
)
is
  w_conta_sogg        number;
  w_progr_sogg        number;
  w_estremi_catasto   varchar (2000) := null;
  w_errore            varchar (2000) := null;
  w_sql_errm          varchar (2000) := null;
  w_progr_oggetto_prec number;
  errore              exception;
begin
  a_messaggio := null;
  -- Loop per determinare se per ogni oggetto abbiamo i soggetti, altrimenti inserirli
  for w_ogg in (select *
                  from wrk_docfa_oggetti
                 where documento_id = a_documento_id
                   and documento_multi_id = a_documento_multi_id) loop
    -- cerchiamo l'oggetto su tr4 per vedere se lo abbiamo, se sì salviamo l'id sulla tabella
    if w_ogg.tr4_oggetto is null then
      begin
        if w_ogg.sezione || w_ogg.foglio || w_ogg.numero || w_ogg.subalterno
             is not null then
          w_estremi_catasto      :=
               lpad (ltrim (nvl (w_ogg.sezione, ' '), '0'), 3, ' ')
            || lpad (ltrim (nvl (w_ogg.foglio, ' '), '0'), 5, ' ')
            || lpad (ltrim (nvl (w_ogg.numero, ' '), '0'), 5, ' ')
            || lpad (ltrim (nvl (w_ogg.subalterno, ' '), '0'), 4, ' ')
            || lpad (' ', 3);
          begin
            select max (oggetto)
              into w_ogg.tr4_oggetto
              from oggetti ogge
             where ogge.tipo_oggetto + 0 in (3, 4, 55)
               and ogge.estremi_catasto = w_estremi_catasto
               and nvl (substr (ogge.categoria_catasto, 1, 1), ' ') =
                     nvl (substr (w_ogg.categoria, 1, 1), nvl(substr (ogge.categoria_catasto, 1, 1), ' '));
            update wrk_docfa_oggetti
               set tr4_oggetto = w_ogg.tr4_oggetto
             where documento_id = a_documento_id
               and documento_multi_id = a_documento_multi_id
               and progr_oggetto = w_ogg.progr_oggetto;
          exception
            when others then
              w_sql_errm := substr (sqlerrm, 1, 100);
              w_errore      :=
                   'Errore in controllo esistenza fabbricato'
                || ' ('
                || w_sql_errm
                || ')';
              raise errore;
          end;
        end if;
      end;
    end if;
    if w_ogg.cod_via is null then
      begin
        select cod_via
          into w_ogg.cod_via
          from denominazioni_via devi
         where w_ogg.indirizzo like
                 chr (37) || devi.descrizione || chr (37)
           and devi.descrizione is not null
           and not exists
                     (select 'x'
                        from denominazioni_via devi1
                       where w_ogg.indirizzo like
                               chr (37) || devi1.descrizione || chr (37)
                         and devi1.descrizione is not null
                         and devi1.cod_via != devi.cod_via)
           and rownum = 1
        ;
        update wrk_docfa_oggetti
           set cod_via = w_ogg.cod_via
         where documento_id = a_documento_id
           and documento_multi_id = a_documento_multi_id
           and progr_oggetto = w_ogg.progr_oggetto
        ;
      exception
        when no_data_found then null;
        when others then
          w_sql_errm := substr (sqlerrm, 1, 100);
          w_errore      :=
               'Errore in controllo esistenza indirizzo fabbricato'
            || 'indir: '
            || w_ogg.indirizzo
            || ' ('
            || w_sql_errm
            || ')';
          raise errore;
      end;
    end if;
    begin
      select count (*)
        into w_conta_sogg
        from wrk_docfa_soggetti wrds
       where documento_id = a_documento_id
         and documento_multi_id = a_documento_multi_id
         and wrds.progr_oggetto = w_ogg.progr_oggetto;
      if w_conta_sogg = 0 then
        if w_ogg.tipo_operazione = 'C' then
          w_progr_oggetto_prec := null;
          begin
            select progr_oggetto
              into w_progr_oggetto_prec
              from wrk_docfa_oggetti
             where documento_id = a_documento_id
               and documento_multi_id = a_documento_multi_id
               and progr_oggetto != w_ogg.progr_oggetto
               and tipo_operazione != 'C'
            ;
          exception
            when no_data_found
            then a_messaggio      :=
            ltrim (   a_messaggio
                   || ' '||chr(10)||'Prg: '
                   || w_ogg.progr_oggetto
                   || '; Manca l''oggetto da cui copiare i proprietari'
                  );
            when others
            then a_messaggio      :=
            ltrim (   a_messaggio
                   || ' '||chr(10)||'Prg: '
                   || w_ogg.progr_oggetto
                   || '; Impossibile determinare l''oggetto da cui copiare i proprietari'
                  );
          end;
          insert into wrk_docfa_soggetti (documento_id
                                      ,documento_multi_id
                                      ,progr_oggetto
                                      ,progr_soggetto
                                      ,denominazione
                                      ,comune_nascita
                                      ,provincia_nascita
                                      ,data_nascita
                                      ,sesso
                                      ,codice_fiscale
                                      ,cognome
                                      ,nome
                                      ,tipo
                                      ,flag_caricamento
                                      ,regime
                                      ,progressivo_int_rif
                                      ,spec_diritto
                                      ,perc_possesso
                                      ,titolo
                                      ,tr4_ni
                                      )
          select documento_id
                ,documento_multi_id
                ,w_ogg.progr_oggetto
                ,progr_soggetto
                ,denominazione
                ,comune_nascita
                ,provincia_nascita
                ,data_nascita
                ,sesso
                ,codice_fiscale
                ,cognome
                ,nome
                ,tipo
                ,flag_caricamento
                ,regime
                ,progressivo_int_rif
                ,spec_diritto
                ,perc_possesso
                ,titolo
                ,tr4_ni
            from wrk_docfa_soggetti
           where documento_id = a_documento_id
             and documento_multi_id = a_documento_multi_id
             and progr_oggetto = w_progr_oggetto_prec
          ;
        elsif w_ogg.tr4_oggetto is null then
          a_messaggio      :=
            ltrim (   a_messaggio
                   || ' '||chr(10)||'Prg: '
                   || w_ogg.progr_oggetto
                   || '; manca il fabbricato, impossibile determinare i proprietari'
                  );
        else
          w_progr_sogg := 0;
          for w_sogg
            in (select distinct
                       soggetti.cognome_nome denominazione
                      ,com_nas.denominazione comune_nascita
                      ,pro_nas.sigla provincia_nascita
                      ,soggetti.data_nas data_nascita
                      ,soggetti.sesso
                      ,contribuenti.cod_fiscale codice_fiscale
                      ,soggetti.cognome
                      ,soggetti.nome
                      ,soggetti.tipo
                      ,oggetti_contribuente.perc_possesso
                      ,attributi_ogco.cod_diritto titolo
                      ,soggetti.ni tr4_ni
                  from contribuenti
                      ,soggetti
                      ,pratiche_tributo
                      ,rapporti_tributo
                      ,oggetti_contribuente
                      ,oggetti_pratica
                      ,ad4_comuni com_nas
                      ,ad4_province pro_nas
                      ,attributi_ogco
                 where contribuenti.ni = soggetti.ni
                   and pratiche_tributo.pratica = rapporti_tributo.pratica
                   and contribuenti.cod_fiscale =
                         rapporti_tributo.cod_fiscale
                   and oggetti_contribuente.cod_fiscale =
                         contribuenti.cod_fiscale
                   and oggetti_contribuente.oggetto_pratica =
                         oggetti_pratica.oggetto_pratica
                   and oggetti_pratica.pratica = pratiche_tributo.pratica
                   and pratiche_tributo.tipo_tributo in ('ICI', 'TASI')
                   and oggetti_pratica.oggetto = w_ogg.tr4_oggetto
                   and com_nas.comune(+) = soggetti.cod_com_nas
                   and com_nas.provincia_stato(+) = soggetti.cod_pro_nas
                   and pro_nas.provincia(+) = com_nas.provincia_stato
                   and attributi_ogco.cod_fiscale(+) =
                         oggetti_contribuente.cod_fiscale
                   and attributi_ogco.oggetto_pratica(+) =
                         oggetti_contribuente.oggetto_pratica) loop
            w_progr_sogg := w_progr_sogg + 1;
            insert
              into wrk_docfa_soggetti (documento_id
                                      ,documento_multi_id
                                      ,progr_oggetto
                                      ,progr_soggetto
                                      ,denominazione
                                      ,comune_nascita
                                      ,provincia_nascita
                                      ,data_nascita
                                      ,sesso
                                      ,codice_fiscale
                                      ,cognome
                                      ,nome
                                      ,tipo
                                      ,flag_caricamento
                                      ,regime
                                      ,progressivo_int_rif
                                      ,spec_diritto
                                      ,perc_possesso
                                      ,titolo
                                      ,tr4_ni
                                      )
            values (a_documento_id
                   ,a_documento_multi_id
                   ,w_ogg.progr_oggetto
                   ,w_progr_sogg
                   ,w_sogg.denominazione
                   ,w_sogg.comune_nascita
                   ,w_sogg.provincia_nascita
                   ,w_sogg.data_nascita
                   ,w_sogg.sesso
                   ,w_sogg.codice_fiscale
                   ,w_sogg.cognome
                   ,w_sogg.nome
                   ,w_sogg.tipo
                   ,'B'
                   ,'B'
                   ,null
                   ,null
                   ,w_sogg.perc_possesso
                   ,w_sogg.titolo
                   ,w_sogg.tr4_ni
                   );
          end loop;
          if w_progr_sogg = 0 then
             a_messaggio      := ltrim (   a_messaggio
                                       || ' '||chr(10)||'Prg: '
                                       || w_ogg.progr_oggetto
                                       || '; mancano i proprietari'
                  );
          end if;
        end if;
      end if;
    end;
  end loop;
  commit;
exception
  when errore then
    rollback;
    raise_application_error (-20999, nvl (w_errore, 'vuoto'));
end;
/* End Procedure: CARICA_SOGGETTI_DOCFA */
/

