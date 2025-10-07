--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_periodi_oggetto stripComments:false runOnChange:true 
 
create or replace function F_CHECK_PERIODI_OGGETTO
/*************************************************************************
 NOME:        F_CHECK_PERIODI_OGGETTO
 DESCRIZIONE: Solo per la denuncia TARSU.
              In caso di denuncia di iscrizione o variazione, verifica
              che l'oggetto che si sta inserendo non abbia periodi di
              possesso che si sovrappongono che quello che si sta
              inserendo
 RITORNA:     number              0 - controlli superati
                                  1 - controlli non superati
 NOTE:
 Rev.    Date         Author      Note
 03      28/09/2023  DM           #63407 - Corretta condizione di verifica
                                  sovrapposizione.
 02      27/09/2023   VM          #63407 - Modificato tipo ritorno della function 
                                  da number a cursore per restituire gli oggetti_validita intersecati.
                                  cursore vuoto - controlli superati
                                  cursore pieno - controlli non superati
 01      07/09/2023   VM          #63407 - Filtro cod_fiscale opzionale per
                                  confronto di periodi oggetto tra diversi contribuenti. 
 00      11/02/2021   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale            varchar2
, p_oggetto                number
, p_tipo_tributo           varchar2
, p_tipo_pratica           varchar2
, p_tipo_evento            varchar2
, p_anno                   number
, p_data_dal               date
, p_data_al                date
, p_oggetto_pratica        number
, p_old_data_dal           date
, p_old_data_al            date
, p_ins_var                varchar2
) return sys_refcursor is
  w_al                     date;
  w_dal                    date;
  w_tipo_evento            varchar2(1);
  w_conta                  number;
  w_oggetto_pratica        number;
  w_error_message          varchar2(1000);
  errore                   exception;
  result_rc                sys_refcursor;
  empty_rc                 sys_refcursor;
begin
  open empty_rc for
       select 0 from dual where 1!=1;
  -- TRATTAMENTO SOLO TARSU
  if upper(p_tipo_tributo) <> 'TARSU' then
    w_error_message := 'Tipo tributo '||p_tipo_tributo||' non valido';
    raise errore;
  end if;
  -- Caso in cui non vengono specificate le date Dal e Al (.....)
  if p_data_dal is null and
     p_data_al  is null then
     begin
       select count(*)
         into w_conta
         from oggetti_validita ogva
        where ogva.tipo_tributo||'' = p_tipo_tributo
          and ogva.tipo_pratica     = p_tipo_pratica
          and ogva.oggetto          = p_oggetto
          and (p_cod_fiscale is null 
               or (p_cod_fiscale is not null
                   and ogva.cod_fiscale = p_cod_fiscale)
          )
          and ogva.al               is null
          and ogva.oggetto_pratica  <> nvl(p_oggetto_pratica,0);
     exception
       when others then
         w_error_message := 'Impossibile eseguire query';
         raise errore;
     end;
     if p_tipo_evento = 'I' then
       open result_rc for
         select ogva.*
           from oggetti_validita ogva
          where ogva.tipo_tributo || '' = p_tipo_tributo
            and ogva.tipo_pratica = p_tipo_pratica
            and ogva.oggetto = p_oggetto
            and (p_cod_fiscale is null or (p_cod_fiscale is not null and
                ogva.cod_fiscale = p_cod_fiscale))
            and ogva.al is null
            and ogva.oggetto_pratica <> nvl(p_oggetto_pratica, 0);
       return result_rc;
     else
       if w_conta > 0 then
         return empty_rc;
       else
         w_error_message := 'Nessuna validità oggetto trovata per il tipo_evento'||p_tipo_evento;
         raise errore;
       end if;
     end if;
  end if;
  -- Eventi UNICI
  if p_tipo_evento = 'U' then
     -- Nel caso di unico a parità di contribuente, tributo, oggetto
     -- non devono esistere altre pratiche intersecanti.
     open result_rc for
       select ogva.*
         from oggetti_validita ogva
        where ogva.tipo_tributo||'' = p_tipo_tributo
          and ogva.oggetto          = p_oggetto
          and (p_cod_fiscale is null 
               or (p_cod_fiscale is not null
                   and ogva.cod_fiscale = p_cod_fiscale)
          )
          and nvl(p_data_dal,to_date('01011900','ddmmyyyy'))
                                   <= nvl(ogva.al,to_date('31122999','ddmmyyyy'))
          and nvl(p_data_al,to_date('31122999','ddmmyyyy'))
                                   >= nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
          and ogva.oggetto_pratica  <> nvl(p_oggetto_pratica,0);
     return result_rc;
  end if;
  -- Eventi di ISCRIZIONE
  if p_tipo_evento = 'I' then
     -- Nel caso di iscrizione a parità di contribuente, tributo, oggetto
     -- non deve esistere un'altra iscrizione con data Al nulla
     -- e non devono esistere pratiche di variazione con data Dal < della
     -- data Dal di iscrizione (questo può capitare solo in aggiornamento della
     -- pratica di iscrizione).
     begin
       select count(*)
         into w_conta
         from oggetti_validita ogva
        where ogva.tipo_tributo||'' = p_tipo_tributo
          and ogva.oggetto          = p_oggetto
          and (p_cod_fiscale is null 
               or (p_cod_fiscale is not null
                   and ogva.cod_fiscale = p_cod_fiscale)
          )
          and ogva.dal              is not null
          and ogva.al               is null
          and ogva.oggetto_pratica  <> nvl(p_oggetto_pratica,0);
     exception
       when others then
         w_error_message := 'Impossibile eseguire query';
         raise errore;
     end;
     if w_conta > 0 then 
       open result_rc for
         select ogva.*
           from oggetti_validita ogva
          where ogva.tipo_tributo||'' = p_tipo_tributo
            and ogva.oggetto          = p_oggetto
            and (p_cod_fiscale is null 
                 or (p_cod_fiscale is not null
                     and ogva.cod_fiscale = p_cod_fiscale)
            )
            and ogva.dal              is not null
            and ogva.al               is null
            and ogva.oggetto_pratica  <> nvl(p_oggetto_pratica,0);
       return result_rc;
     end if;
     open result_rc for
       select ogva.*
         from oggetti_validita ogva
         where ogva.tipo_tributo||'' = p_tipo_tributo
           and ogva.oggetto = p_oggetto
           and (p_cod_fiscale is null 
                or (p_cod_fiscale is not null
                    and ogva.cod_fiscale = p_cod_fiscale)
           )
           /*and p_data_dal between nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                              and nvl(ogva.al ,to_date('31122999','ddmmyyyy'))*/
           and p_data_dal <= nvl(ogva.al ,to_date('31122999','ddmmyyyy'))
               and nvl(ogva.dal,to_date('01011900','ddmmyyyy')) <= nvl(p_data_al, to_date('31122999','ddmmyyyy'))
           and ogva.oggetto_pratica  <> nvl(p_oggetto_pratica,0);
     return result_rc;
  end if;
  -- Eventi di VARIAZIONE e CESSAZIONE
  -- Nuovo Evento
  if p_ins_var = 'I' then
     -- Una cessazione non può avere la data
     -- uguale a quella di una iscrizione o variazione:
     -- su di una variazione si deve eliminare la variazione
     -- e sostituire con la cessazione;
     -- su di una iscrizione, si elimina l'iscrizione
     -- e si inserisce un unico temporaneo.
     begin
       select count(*)
         into w_conta
         from oggetti_validita ogva
        where ogva.tipo_tributo||'' = p_tipo_tributo
          and ogva.oggetto          = p_oggetto
          and (p_cod_fiscale is null 
               or (p_cod_fiscale is not null
                   and ogva.cod_fiscale = p_cod_fiscale)
          )
          and nvl(ogva.dal,to_date('01011900','ddmmyyyy')) <=
              decode(p_tipo_evento
                    ,'V',p_data_dal
                    ,nvl(p_data_al,to_date('31122999','ddmmyyyy')) - 1)
          and ogva.al               is null;
     exception
       when others then
         w_error_message := 'Impossibile eseguire query';
         raise errore;
     end;
     if w_conta = 0 then
       w_error_message := 'Nessuna validità oggetto trovata';
       raise errore;
     else
       return empty_rc;
     end if;
  end if;
  -- Variazione di Evento esistente
  -- Siccome le Cessazioni non sono evidenziate nella vista OGGETTI_VALIDITA,
  -- per esse è necessario ricavare gli estremi dell'evento che è stato cessato
  -- che è quello che, a parità di tributo, contribuente, oggetto contiene la stessa
  -- data AL.
  -- Per le variazioni questi dati sono forniti dai parametri.
  if p_tipo_evento = 'C' then
     begin
       select max(ogva.oggetto_pratica)
            , min(nvl(ogva.dal,to_date('01011900','ddmmyyyy')))
            , max(nvl(ogva.al,to_date('31122999','ddmmyyyy')))
         into w_oggetto_pratica
            , w_dal
            , w_al
         from oggetti_validita ogva
        where ogva.tipo_tributo||''  = p_tipo_tributo
          and (p_cod_fiscale is null 
               or (p_cod_fiscale is not null
                   and ogva.cod_fiscale = p_cod_fiscale)
          )
          and ogva.oggetto           = p_oggetto
          and nvl(ogva.al,to_date('31122999','ddmmyyyy')) =
              nvl(p_old_data_al,to_date('31122999','ddmmyyyy'));
     exception
       when others then
         w_error_message := 'Impossibile eseguire query';
         raise errore;
     end;
     -- Una cessazione non può avere la data
     -- uguale a quella di una iscrizione o variazione:
     -- su di una variazione si deve eliminare la variazione
     -- e sostituire con la cessazione;
     -- su di una iscrizione, si elimina l'iscrizione
     -- e si inserisce un unico temporaneo.
     if p_data_al = w_dal then
       w_error_message := 'Cessazione con data uguale a quella di iscrizione o variazione';
       raise errore;
     end if;
  else
     select p_oggetto_pratica
          , nvl(p_old_data_dal,to_date('01011900','ddmmyyyy'))
          , nvl(p_old_data_al,to_date('31122999','ddmmyyyy'))
       into w_oggetto_pratica
          , w_dal
          , w_al
       from dual;
  end if;
  -- Controllo Intersezione coi periodi precedenti.
  begin
    select count(*)
      into w_conta
      from oggetti_validita ogva
     where ogva.tipo_tributo||''  = p_tipo_tributo
       and (p_cod_fiscale is null 
            or (p_cod_fiscale is not null
                and ogva.cod_fiscale = p_cod_fiscale)
       )
       and ogva.oggetto           = p_oggetto
       and ogva.oggetto_pratica  <> w_oggetto_pratica
       and decode(p_tipo_evento,'V',p_data_dal,p_data_al) <
          (select max(nvl(ogv2.dal,to_date('01011900','ddmmyyyy')))
             from oggetti_validita ogv2
            where ogv2.tipo_tributo||''  = p_tipo_tributo
              and (p_cod_fiscale is null 
                   or (p_cod_fiscale is not null
                       and ogva.cod_fiscale = p_cod_fiscale)
              )
              and ogv2.oggetto           = p_oggetto
              and ogv2.oggetto_pratica  <> w_oggetto_pratica
              and nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))<
                  decode(p_tipo_evento,'V',w_dal,w_al)
          );
  exception
    when others then
      w_error_message := 'Impossibile eseguire query';
      raise errore;
  end;
  if w_conta > 0 then
     open result_rc for
       select ogva.*
         from oggetti_validita ogva
        where ogva.tipo_tributo || '' = p_tipo_tributo
          and (p_cod_fiscale is null or (p_cod_fiscale is not null and
              ogva.cod_fiscale = p_cod_fiscale))
          and ogva.oggetto = p_oggetto
          and ogva.oggetto_pratica <> w_oggetto_pratica
          and decode(p_tipo_evento, 'V', p_data_dal, p_data_al) <
              (select max(nvl(ogv2.dal, to_date('01011900', 'ddmmyyyy')))
                 from oggetti_validita ogv2
                where ogv2.tipo_tributo || '' = p_tipo_tributo
                  and (p_cod_fiscale is null or
                      (p_cod_fiscale is not null and
                      ogva.cod_fiscale = p_cod_fiscale))
                  and ogv2.oggetto = p_oggetto
                  and ogv2.oggetto_pratica <> w_oggetto_pratica
                  and nvl(ogv2.dal, to_date('01011900', 'ddmmyyyy')) <
                      decode(p_tipo_evento, 'V', w_dal, w_al));
     return result_rc;
  end if;
  -- Controllo Intersezione coi periodi successivi.
  open result_rc for
    select ogva.*
      from oggetti_validita ogva
     where ogva.tipo_tributo||''  = p_tipo_tributo
       and (p_cod_fiscale is null 
            or (p_cod_fiscale is not null
                and ogva.cod_fiscale = p_cod_fiscale)
       )
       and ogva.oggetto           = p_oggetto
       and ogva.oggetto_pratica  <> w_oggetto_pratica
       and decode(p_tipo_evento,'V',p_data_dal,p_data_al) >
          (select min(nvl(ogv2.dal,to_date('01011900','ddmmyyyy')))
             from oggetti_validita ogv2
            where ogv2.tipo_tributo||''  = p_tipo_tributo
              and (p_cod_fiscale is null 
                   or (p_cod_fiscale is not null
                       and ogva.cod_fiscale = p_cod_fiscale)
              )
              and ogv2.oggetto           = p_oggetto
              and ogv2.oggetto_pratica  <> w_oggetto_pratica
              and nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                         > decode(p_tipo_evento,'V',w_dal,w_al)
          );
  return result_rc;
exception
  when errore then
    open result_rc for
      select w_error_message errore from dual;
    return result_rc;
end;
/* End Function: F_CHECK_PERIODI_OGGETTO */
/
