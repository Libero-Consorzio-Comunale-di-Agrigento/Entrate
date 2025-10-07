--liquibase formatted sql 
--changeset abrandolini:20250326_152423_emissione_fattura stripComments:false runOnChange:true 
 
create or replace procedure EMISSIONE_FATTURA
( a_anno             in  number
, a_ruolo            in  number
, a_num_fattura      in  number
, a_data_emissione   in  date
, a_utente           in  varchar2
) is
errore                  exception;
sErrore                 varchar2(2000) := null;
nNuovo                  number;
nFattura                number;
nNumFattura             number;
w_importo_totale        number := 0;
w_iva_totale            number := 0;
w_add_prov_totale       number := 0;
w_num_ogim              number := 0;
w_addizionale_pro       number := 0;
w_flag_delega           varchar2(1);
w_stato_ruolo           varchar2(100) := null;
cursor sel_cont(p_ruolo    varchar2)
    is
select ruog.cod_fiscale        cod_fiscale
     , ruol.tipo_tributo       tipo_tributo
     , ruol.data_emissione     data_emissione
  from oggetti_imposta         ogim
     , ruoli_contribuente      ruog
     , ruoli                   ruol
 where ruog.oggetto_imposta  = ogim.oggetto_imposta
   and ruog.ruolo            = ruol.ruolo
   and ruol.ruolo            = p_ruolo
   and ogim.fattura          is null
   group by ruog.cod_fiscale
          , ruol.tipo_tributo
          , ruol.data_emissione
     ;
cursor sel_ruog (p_cod_fiscale varchar2
                ,p_ruolo    varchar2
                ) is
select ruog.oggetto_imposta    oggetto_imposta
  from oggetti_imposta         ogim
     , ruoli_contribuente      ruog
 where ruog.oggetto_imposta  = ogim.oggetto_imposta
   and ruog.cod_fiscale      = p_cod_fiscale
   and ruog.ruolo            = p_ruolo
   and ogim.fattura          is null
;
cursor sel_ogim (p_cod_fiscale varchar2
                ,p_ruolo    varchar2
                ) is
select sum(nvl(ogim.imposta,0))  sum_imposta
      ,ogim.aliquota_iva      aliquota_iva
  from oggetti_imposta    ogim
     , ruoli_contribuente ruog
 where ruog.oggetto_imposta  = ogim.oggetto_imposta
   and ruog.cod_fiscale      = p_cod_fiscale
   and ruog.ruolo            = p_ruolo
   and ogim.fattura          is null
group by ogim.aliquota_iva
;
BEGIN
   BEGIN
    select max(nvl(fattura,0))
      into nFattura
      from fatture
      ;
   EXCEPTION
     WHEN no_data_found THEN
          nFattura := 0;
     WHEN others THEN
          sErrore := 'Errore in estrazione fattura massima '
                     ||'('||SQLERRM||')';
          RAISE errore;
   END;
    nFattura    := nvl(nFattura,0);
    nNumFattura := a_num_fattura - 1;
      BEGIN
        select addizionale_pro
          into w_addizionale_pro
          from carichi_tarsu
         where anno = a_anno
             ;
     EXCEPTION
          WHEN others THEN
                sErrore := 'Errore in estrazione Carichi TARSU ('
                          ||to_char(a_anno)||') '||'('||SQLERRM||')';
               RAISE errore;
     END;
   FOR rec_cont in sel_cont(a_ruolo)
   LOOP
      w_importo_totale := 0;
      w_iva_totale     := 0;
      w_num_ogim       := 0;
      FOR rec_ogim in sel_ogim(rec_cont.cod_fiscale,a_ruolo)
      LOOP
         w_importo_totale := w_importo_totale + rec_ogim.sum_imposta;
         w_iva_totale := w_iva_totale + round((rec_ogim.sum_imposta * nvl(rec_ogim.aliquota_iva,0) / 100),2);
         w_num_ogim := w_num_ogim +1 ;
      END LOOP;
      w_add_prov_totale := round((w_importo_totale * nvl(w_addizionale_pro,0) / 100),2);
      w_importo_totale := w_importo_totale + w_iva_totale + w_add_prov_totale;
   -- l'inserimento della fattura viene fatto solo se ho almeno un ogim
      if w_importo_totale > 0 then  --
         nFattura    := nFattura + 1;
         nNumFattura := nNumFattura + 1;
        BEGIN
          select count(1)
            into nNuovo
            from numerazione_fatture
           where anno = a_anno
               ;
          if nNuovo = 0 Then
             BEGIN
                insert into numerazione_fatture
                         (ANNO, NUMERO, DATA_EMISSIONE )
                  values (a_anno, nNumFattura, a_data_emissione )
                       ;
             EXCEPTION
                WHEN others THEN
                     sErrore := 'Errore in Inserimento numerazione fatture ('
                                 ||'anno: '||to_char(a_anno)||') '||'('||SQLERRM||')';
                     RAISE errore;
             END;
          else
             BEGIN
                update numerazione_fatture
                   set NUMERO          = nNumFattura
                     , DATA_EMISSIONE = a_data_emissione
                 where ANNO           = a_anno
                     ;
             EXCEPTION
                WHEN others THEN
                     sErrore := 'Errore in Aggiornamento numerazione fatture ('
                                 ||'anno: '||to_char(a_anno)||') '||'('||SQLERRM||')';
                     RAISE errore;
             END;
          end if;
        END;
         w_flag_delega := '';
         -- verifica delega bancaria
         begin
            select 'S'
              into w_flag_delega
              from deleghe_bancarie deba
             where deba.cod_fiscale  = rec_cont.cod_fiscale
               and deba.tipo_tributo = rec_cont.tipo_tributo
               and decode(deba.flag_delega_cessata
                         ,'S', nvl(deba.data_ritiro_delega,to_date('01011900','ddmmyyyy'))
                         ,to_date('31122999','ddmmyyyy')
                         )                                  > rec_cont.data_emissione
                ;
         EXCEPTION
            WHEN no_data_found THEN
                 w_flag_delega := '';
            WHEN others THEN
                 sErrore := 'Errore in Verifica Deleghe ('
                              ||'cf: '||rec_cont.cod_fiscale||') '||'('||SQLERRM||')';
                 RAISE errore;
         end;
         if w_flag_delega = 'S' and w_stato_ruolo is null then
            w_stato_ruolo := 'RID_EMESSI';
         end if;
         BEGIN
            insert into fatture
                  (fattura,anno,numero,cod_fiscale
                  ,data_emissione
                  ,importo_totale,utente,data_variazione
                  ,flag_delega)
           values (nfattura,a_anno,nNumFattura,rec_cont.cod_fiscale
                  ,a_data_emissione
                  ,w_importo_totale,a_utente,trunc(sysdate)
                  ,w_flag_delega)
           ;
         EXCEPTION
             WHEN others THEN
                   sErrore := 'Errore in inserimento Fatture ('
                             ||rec_cont.cod_fiscale||') '||'('||SQLERRM||')';
                  RAISE errore;
         END;
         FOR rec_ruog in sel_ruog(rec_cont.cod_fiscale,a_ruolo)
         LOOP
            BEGIN
              update oggetti_imposta ogim
                 set ogim.fattura = nFattura
               where ogim.oggetto_imposta = rec_ruog.oggetto_imposta
                ;
            EXCEPTION
               WHEN others THEN
                   sErrore := 'Errore in Aggiornamento oggetti_imposta ('
                             ||rec_ruog.oggetto_imposta||') '||'('||SQLERRM||')';
                  RAISE errore;
            END;
         END LOOP;
      end if;    -- w_num_ogim > 0
   END LOOP;
   -- Aggiornamento Stato Ruolo
   if w_stato_ruolo is not null then
      begin
         update ruoli
            set stato_ruolo = w_stato_ruolo
          where ruolo = a_ruolo
          ;
      EXCEPTION
         WHEN others THEN
             sErrore := 'Errore in Aggiornamento stato_ruolo '
                       ||'('||SQLERRM||')';
            RAISE errore;
      end;
   end if;
EXCEPTION
   WHEN ERRORE THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,sErrore);
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: EMISSIONE_FATTURA */
/

