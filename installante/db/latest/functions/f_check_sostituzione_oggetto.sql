--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_sostituzione_oggetto stripComments:false runOnChange:true 
 
create or replace function F_CHECK_SOSTITUZIONE_OGGETTO
( a_tipo_tributo    varchar2
, a_attuale_oggetto number
, a_nuovo_oggetto   number
, a_domanda varchar2 default null)
return varchar2
is
w_catastali              number;
w_partizioni             number;
w_partizioni_ok          varchar2(1);
w_riferimenti_oggetto    number;
w_riferimenti_oggetto_ok varchar2(1);
w_utilizzi_oggetto       number;
w_utilizzi_oggetto_ok    varchar2(1);
w_catastaliICI           number;
w_num_anomalie           number;
w_messaggio              varchar2(2000);
cursor sel_riog (p_oggetto number) is
   select inizio_validita
         , fine_validita
           , rendita
           , anno_rendita
           , categoria_catasto
           , classe_catasto
      from riferimenti_oggetto
      where oggetto = p_oggetto
 order by inizio_validita
          ;
cursor sel_utog (p_oggetto number) is
   select anno
         , tipo_utilizzo
           , mesi_affitto
           , data_scadenza
           , intestatario
           , tipo_uso
      from utilizzi_oggetto
       where oggetto = p_oggetto
                  and tipo_tributo = a_tipo_tributo
 order by anno
        , tipo_utilizzo
        , sequenza
          ;
cursor sel_paog (p_oggetto number) is
   select consistenza
         , tipo_area
      from partizioni_oggetto
    where oggetto = p_oggetto
 order by consistenza
          ;
begin
w_messaggio := '';
w_num_anomalie := 0;
if a_tipo_tributo = 'ICI' or a_tipo_tributo = '%'  then
   -- test dei RIFERIMENTI_OGGETTO
   w_riferimenti_oggetto_ok := 'S';
   for rec_riog in sel_riog(a_attuale_oggetto) loop
      select count(1)
        into w_riferimenti_oggetto
        from riferimenti_oggetto
       where oggetto                    = a_nuovo_oggetto
         and inizio_validita            = rec_riog.inizio_validita
         and fine_validita              = rec_riog.fine_validita
         and rendita                    = rec_riog.rendita
         and nvl(anno_rendita,0)        = nvl(rec_riog.anno_rendita,0)
         and nvl(categoria_catasto,' ') = nvl(rec_riog.categoria_catasto,' ')
         and nvl(classe_catasto,' ')    = nvl(rec_riog.classe_catasto,' ')
           ;
      if w_riferimenti_oggetto = 0 then
         --i dati nn sn coerenti
          w_riferimenti_oggetto_ok := 'N';
       end if;
    end loop;
   if w_riferimenti_oggetto_ok = 'N' then
      w_messaggio := w_messaggio || 'Riferimenti Oggetto Incoerenti.' || chr(010);
      w_num_anomalie := w_num_anomalie + 1;
    end if;
   -- test dei UTILIZZI_OGGETTO
    w_utilizzi_oggetto_ok := 'S';
   for rec_utog in sel_utog(a_attuale_oggetto) loop
       select count(1)
         into w_utilizzi_oggetto
         from utilizzi_oggetto
        where oggetto                                               = a_nuovo_oggetto
          and anno                                                  = rec_utog.anno
          and tipo_utilizzo                                         = rec_utog.tipo_utilizzo
          and nvl(mesi_affitto,0)                                   = nvl(rec_utog.mesi_affitto,0)
          and nvl(data_scadenza,to_date('31/12/9999','dd/mm/yyyy')) = nvl(rec_utog.data_scadenza,to_date('31/12/9999','dd/mm/yyyy'))
          and nvl(intestatario,' ')                                 = nvl(rec_utog.intestatario,' ')
          and nvl(tipo_uso,0)                                       = nvl(rec_utog.tipo_uso,0)
            ;
      if w_utilizzi_oggetto = 0 then
           w_utilizzi_oggetto_ok := 'N';
        end if;
   end loop;
   if w_utilizzi_oggetto_ok = 'N' then
      w_messaggio := w_messaggio || 'Utilizzi Oggetto Incoerenti.' || chr(010);
      w_num_anomalie := w_num_anomalie + 1;
   end if;
   -- test dei dati Catastali (ICI)
    select count(1)
      into w_catastaliICI
     from oggetti ogg1
         , oggetti ogg2
     where ogg1.oggetto = a_attuale_oggetto
       and ogg2.oggetto = a_nuovo_oggetto
       and nvl(ogg2.sezione,' ')           = nvl(nvl(ogg1.sezione,ogg2.sezione),' ')
       and nvl(ogg2.foglio,' ')            = nvl(nvl(ogg1.foglio,ogg2.foglio),' ')
        and nvl(ogg2.numero,' ')            = nvl(nvl(ogg1.numero,ogg2.numero),' ')
        and nvl(ogg2.subalterno,' ')        = nvl(nvl(ogg1.subalterno,ogg2.subalterno),' ')
        and nvl(ogg2.categoria_catasto,' ') = nvl(nvl(ogg1.categoria_catasto,ogg2.categoria_catasto),' ')
        and nvl(ogg2.classe_catasto,' ')    = nvl(nvl(ogg1.classe_catasto,ogg2.classe_catasto),' ')
        and nvl(ogg2.partita,' ')           = nvl(nvl(ogg1.partita,ogg2.partita),' ')
        and nvl(ogg2.progr_partita,0)       = nvl(nvl(ogg1.progr_partita,ogg2.progr_partita),0)
        ;
   if w_catastaliICI = 0 then
      w_messaggio := w_messaggio || 'Dati Catastali Incoerenti.' || chr(010);
      w_num_anomalie := w_num_anomalie + 1;
   end if;
end if;--if a_tipo_tributo = 'ICI' or a_tipo_tributo = '%'
if  a_tipo_tributo <> 'ICI'  or a_tipo_tributo = '%'  then
   -- test dell'indirizzo  (non ICI )
   select count(1)
      into w_catastali
     from oggetti ogg1
          , oggetti ogg2
     where ogg1.oggetto = a_attuale_oggetto
       and ogg2.oggetto = a_nuovo_oggetto
        and (nvl(ogg2.cod_via,0) = nvl(ogg1.cod_via,0)
             or nvl(ogg2.indirizzo_localita,' ') = nvl(ogg1.indirizzo_localita,' ') )
        and nvl(ogg2.num_civ,0) = nvl(ogg1.num_civ,0)
        ;
   if w_catastali  = 0 then
      w_messaggio := w_messaggio || 'Indirizzo Incoerente.' || chr(010);
      w_num_anomalie := w_num_anomalie + 1;
    end if;
   -- test delle PARTIZIONI
    w_partizioni_ok := 'S';
    for rec_paog in sel_paog(a_attuale_oggetto) loop
       select count(1)
         into w_partizioni
         from partizioni_oggetto
         where oggetto     = a_nuovo_oggetto
           and consistenza = rec_paog.consistenza
           and tipo_area   = rec_paog.tipo_area
             ;
      if w_partizioni = 0 then
           w_partizioni_ok := 'N';
        end if;
   end loop;
   if w_partizioni_ok = 'N' then
      w_messaggio := w_messaggio || 'Partizioni Incoerenti.' || chr(010);
      w_num_anomalie := w_num_anomalie + 1;
   end if;
end if; --a_tipo_tributo <> 'ICI'  or a_tipo_tributo = '%'
if w_messaggio is not null then
   if w_num_anomalie = 1 and a_domanda is null then
      w_messaggio := 'E'' stata rilevata la seguente anomalia:'
               || chr(010)
               || w_messaggio
               || chr(010)
               || 'Si desidera procedere ugualmente con la sostituzione dell''oggetto?';
   elsif a_domanda is null then
      w_messaggio := 'Sono state rilevate le seguenti anomalie:'
               || chr(010)
               || w_messaggio
               || chr(010)
               || 'Si desidera procedere ugualmente con la sostituzione dell''oggetto?';
   end if;
   /*if (a_domanda is null) then
     w_messaggio := w_messaggio
                    || chr(010)
                    || 'Si desidera procedere ugualmente con la sostituzione dell''oggetto?';
   end if;*/
end if;
return(w_messaggio);
end;
/* End Function: F_CHECK_SOSTITUZIONE_OGGETTO */
/

