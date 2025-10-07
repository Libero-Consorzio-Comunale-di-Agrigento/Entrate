--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_rateazione stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_RATEAZIONE
/*************************************************************************
 NOME:        CALCOLO_RATEAZIONE
 DESCRIZIONE: Calcolo rateazione per liquidazioni e accertamenti
 NOTE:        Prima versione: registra solo le righe nella tabella
              RATE_IMPOSTA
 Rev.    Date         Author      Note
 006     30/01/2023   AB          Evitata la ricerca del codice f24 per il CUNI
 005     22/11/2018   VD          Aggiunta gestione scadenza rate a fine mese:
                                  se il parametro RATE_FIME presente in tabella
                                  INSTALLAZIONE_PARAMETRI e' uguale a 'S', la
                                  data di scadenza della rata viene portata
                                  all'ultimo giorno del mese.
 004     08/11/2018   VD          Modificato controllo esistenza codici
                                  tributo
 003     17/10/2018   VD          Aggiunto trattamento TARSU:
                                  se per l'anno sono previste le
                                  maggiorazioni, si ricalcola l'importo
                                  totale.
 002     05/07/2018   VD          Aggiunto controllo presenza tipo
                                  rateazione.
 001     06/06/2018   VD          Aggiunto calcolo rateazione secondo
                                  il metodo francese.
 000     19/03/2018   VD          Prima emissione.
*************************************************************************/
( a_pratica                       in number
, a_utente                        in varchar2
) is
  w_importo                       number;
  w_importo_totale                number;
  w_importo_capitale              number;
  w_importo_interessi             number;
  w_prima_quota_cap               number;
  w_quota_capitale                number;
  w_quota_interessi               number;
  w_data_rateazione               date;
  w_numero_rate                   number;
  w_numero_periodi                number;
  w_numero_mesi                   number;
  w_importo_rata                  number;
  w_aliquota_rata                 number;
  w_anno                          number;
  w_tipo_tributo                  varchar2(5);
  w_rate_fime                     varchar2(1);
--
  w_cod_tributo_int               number;
  w_cod_tributo_cap               number;
--
  w_errore                        varchar2(2000);
  errore                          exception;
begin
  --
  -- Si selezionano i dati per l'emissione delle rate
  --
  begin
    select decode(prtr.tipo_tributo,
                 'TARSU',decode(nvl(cata.flag_lordo,'N'),
                               'S',F_IMPORTI_ACC(PRTR.PRATICA,'N','LORDO'),
                                   F_IMPORTI_ACC(PRTR.PRATICA,'N','NETTO')
                               ),
                         F_ROUND(prtr.importo_totale,1)
                 ) + nvl(mora,0) - nvl(versato_pre_rate,0)
         , prtr.data_rateazione
         , prtr.rate
         , to_number(decode(prtr.tipologia_rate,'M',12
                                ,'B',6
                                ,'T',4
                                ,'Q',3
                                ,'S',2
                                ,'A',1))   -- numero di rate da pagare nell'anno
         , to_number(decode(prtr.tipologia_rate,'M',1
                                ,'B',2
                                ,'T',3
                                ,'Q',4
                                ,'S',6
                                ,'A',12))  -- numero mesi da sommare alla data per determinare le scadenze
         , prtr.importo_rate
         , round(prtr.aliquota_rate / 100,4)
         , prtr.anno
         , prtr.tipo_tributo
         , f_inpa_valore('RATE_FIME')
      into w_importo
         , w_data_rateazione
         , w_numero_rate
         , w_numero_periodi
         , w_numero_mesi
         , w_importo_rata
         , w_aliquota_rata
         , w_anno
         , w_tipo_tributo
         , w_rate_fime
      from PRATICHE_TRIBUTO prtr
         , CARICHI_TARSU    cata
     where prtr.pratica = a_pratica
       and prtr.anno    = cata.anno (+);
  exception
    when no_data_found then
      w_errore:= 'Pratica non presente in archivio';
      raise errore;
  end;
  --
  -- Si controlla che siano presenti tutti i dati necessari al
  -- calcolo della rateazione
  --
  if nvl(w_importo,0)          = 0 or
     nvl(w_data_rateazione,to_date('01011950','ddmmyyyy')) = to_date('01011950','ddmmyyyy') or
     nvl(w_numero_rate,0)      = 0 or
     nvl(w_numero_periodi,0)   = 0 or
     nvl(w_numero_mesi,0)      = 0 or
     --nvl(w_importo_rata,0)     = 0 or
     nvl(w_aliquota_rata,0)    = 0 then
     w_errore := 'Indicare tutti i dati necessari al calcolo della rateazione';
     raise errore;
  end if;
  --
  -- Si impostano i codici tributo a seconda del tipo_tributo che si sta
  -- trattando
  --
  if w_tipo_tributo = 'CUNI' then
      w_cod_tributo_int := to_number(null);
      w_cod_tributo_cap := to_number(null);
  else
      begin
        select tributo_f24
          into w_cod_tributo_int
          from codici_f24
         where tipo_tributo = w_tipo_tributo
           and descrizione_titr = f_descrizione_titr(w_tipo_tributo,w_anno)
           and tipo_codice = 'I';
      exception
        when no_data_found then
          w_errore := 'Codice tributo interessi per '||f_descrizione_titr(w_tipo_tributo,w_anno)||' non previsto - Contattare assistenza';
          raise errore;
        when others then
          w_errore := 'Errore in selezione codice tributo interessi ('||sqlerrm||')';
          raise errore;
      end;
      begin
        select tributo_f24
          into w_cod_tributo_cap
          from codici_f24
         where tipo_tributo = w_tipo_tributo
           and descrizione_titr = f_descrizione_titr(w_tipo_tributo,w_anno)
           and tipo_codice = 'S';
      exception
        when no_data_found then
          w_errore := 'Codice tributo capitale per '||f_descrizione_titr(w_tipo_tributo,w_anno)||' non previsto - Contattare assistenza';
          raise errore;
        when others then
          w_errore := 'Errore in selezione codice tributo capitale ('||sqlerrm||')';
          raise errore;
      end;
  end if;
  --
  -- Si calcola l'importo della rata (nota: l'aliquota rata si considera
  -- espressa in decimali e non in percentuale)
  --
  begin
    /*select trunc(w_importo *
                 (w_aliquota_rata / w_numero_periodi) /
                 (1 - (1 / power(1 + (w_aliquota_rata / w_numero_periodi),w_numero_rate))),
                 2)*/
    select w_importo *
          (w_aliquota_rata / w_numero_periodi) /
          (1 - (1 / power(1 + (w_aliquota_rata / w_numero_periodi),w_numero_rate)))
      into w_importo_rata
      from dual;
  exception
    when others then
      w_errore := 'Errore in calcolo importo rata ('||sqlerrm||')';
      raise errore;
  end;
  --
  -- Si aggiorna l'importo rata presente nella tabella PRATICHE_TRIBUTO
  --
  begin
    update pratiche_tributo
       set importo_rate = w_importo_rata
     where pratica = a_pratica;
  exception
    when others then
      w_errore := 'Errore in aggiornamento PRATICHE_TRIBUTO ('||sqlerrm||')';
      raise errore;
  end;
  --
  w_importo_totale := w_importo_rata * w_numero_rate;
  w_importo_capitale := w_importo;
  w_importo_interessi := w_importo_totale - w_importo_capitale;
/*  w_prima_quota_cap := trunc(w_importo_rata /
                             power(1 + (w_aliquota_rata / w_numero_periodi),w_numero_rate),
                             2); */
  w_prima_quota_cap := w_importo_rata /
                             power(1 + (w_aliquota_rata / w_numero_periodi),w_numero_rate);
  --
  -- Si registrano le righe di rate_pratica
  --
  for w_rata in 1..w_numero_rate
  loop
    w_data_rateazione   := add_months(w_data_rateazione,w_numero_mesi);
    --
    -- (VD - 22/11/2018): aggiunta gestione scadenza rate fine mese
    if nvl(upper(w_rate_fime),'N') = 'S' then
       w_data_rateazione := last_day(w_data_rateazione);
    end if;
    --
    -- L'ultima rata viene calcolata per differenza, per evitare problemi
    -- di arrotondamento
    --
    if w_rata = w_numero_rate then
       w_quota_capitale := w_importo_capitale;
    else
       w_quota_capitale    := round (w_prima_quota_cap *
                                    power(1 + (w_aliquota_rata / w_numero_periodi),
                                               w_rata -1),
                                    2);
    end if;
    w_quota_interessi  := w_importo_rata - w_quota_capitale;
    if w_quota_interessi > w_importo_interessi then
       w_quota_interessi := w_importo_interessi;
       w_quota_capitale := w_importo_rata - w_importo_interessi;
    end if;
    --
    w_importo_capitale := w_importo_capitale - w_quota_capitale;
    w_importo_interessi := w_importo_interessi - w_quota_interessi;
    --
    begin
      insert into RATE_PRATICA ( rata_pratica
                               , pratica
                               , rata
                               , data_scadenza
                               , anno
                               , tributo_capitale_f24
                               , importo_capitale
                               , tributo_interessi_f24
                               , importo_interessi
                               , residuo_capitale
                               , residuo_interessi
                               , utente
                               , data_variazione
                               , note
                               )
      values ( to_number(null)
             , a_pratica
             , w_rata
             , w_data_rateazione
             , to_number(to_char(w_data_rateazione,'yyyy'))
             , w_cod_tributo_cap
             , w_quota_capitale
             , w_cod_tributo_int
             , w_quota_interessi
             , w_importo_capitale
             , w_importo_interessi
             , a_utente
             , trunc(sysdate)
             , ''
             );
    exception
      when others then
        w_errore := 'Errore in inserimento RATE_PRATICA ('||sqlerrm||')';
        raise errore;
    end;
  end loop;
  --
  --commit;
  --
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Pratica: '||a_pratica||' '||w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Calcolo Automatico Rateazione della Pratica '||
              a_pratica||' ('||SQLERRM||')');
end;
/* End Procedure: CALCOLO_RATEAZIONE */
/

