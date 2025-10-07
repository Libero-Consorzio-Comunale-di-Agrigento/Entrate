--liquibase formatted sql 
--changeset abrandolini:20250326_152423_eliminazione_sgravi_ruolo stripComments:false runOnChange:true 
 
create or replace procedure ELIMINAZIONE_SGRAVI_RUOLO
( p_cf                varchar2
, p_ruolo             number
, p_anno              number
, p_titr              varchar2
, p_tipo_emissione    varchar2
, p_tipo_ruolo        number
, p_se_emissione      varchar2 default null -- indica se richiamato da emissione ruolo
)
IS
/******************************************************************************
 Rev. Data       Autore    Descrizione
 ---- ---------- ------    ----------------------------------------------------
 2    06/07/2015 VD        Aggiunta eliminazione compensazioni se ruolo
                           suppletivo ulteriore
 1    20/01/2015 Betta T.  Se emissione del ruolo cancella tutti gli sgravi
                           perchè poi vengono riemessi tutti
                           Se eliminazione togliamo solo gli sgravi dal ruolo
                           immediatamente precedente.
 0    19/01/2015 Betta T.  Creata procedure che dato un ruolo ed un codice
                           fiscale elimina gli sgravi di quel ruolo
******************************************************************************/
 w_anno               number;
 w_titr               ruoli.tipo_tributo%type;
 w_tipo_emissione     varchar2(1);
 w_tipo_emissione_prec varchar2(1);
 w_tipo_ruolo         number;
 w_ruolo_prec         number;
 cursor sel_ruolo
 is
     select ruoli.ruolo
       from ruoli, ruoli_contribuente ruco
      where nvl(ruoli.tipo_emissione, 'T') = w_tipo_emissione_prec
        and ruoli.ruolo = ruco.ruolo
        and ruco.cod_fiscale = p_cf
        and ruoli.anno_ruolo = p_anno
        and ruoli.invio_consorzio is not null
        and ruoli.ruolo != p_ruolo
   order by ruoli.data_emissione desc
 ;
BEGIN
  if p_anno is null then -- se non abbiamo i dati del ruolo li rileggiamo
     select anno_ruolo,tipo_tributo,tipo_emissione,tipo_ruolo
     into   w_anno,w_titr,w_tipo_emissione,w_tipo_ruolo
     from   ruoli
     where  ruolo = p_ruolo
     ;
  else
     w_anno := p_anno;
     w_titr := p_titr;
     w_tipo_emissione := p_tipo_emissione;
     w_tipo_ruolo := p_tipo_ruolo;
  end if;
  if w_tipo_emissione = 'T' then -- Per i ruoli totali dobbiamo sempre cercare un ruolo totale
     w_tipo_emissione_prec := 'T';
  elsif w_tipo_ruolo = 1 then -- Per i ruoli principali a saldo cerchiamo gli sgravi fatti sul ruolo di acconto
     w_tipo_emissione_prec := 'A';
  else  -- Per i ruoli suppletivi a saldo cerchiamo gli sgravi fatti sul principale a saldo
     w_tipo_emissione_prec := 'S';
  end if;
  if p_se_emissione = 'S' then -- emissione del ruolo
     w_ruolo_prec := null;
  else -- eliminazione del ruolo
    /* ho bisogno di estrarre solo l ultimo ruolo emesso prima del mio.
       Per questo ho usato un cursore da cui leggo solo la prima
       riga, in questo modo evito una subquery per estrarre la max data
    */
    w_ruolo_prec := -1;
    open sel_ruolo;
    fetch sel_ruolo into w_ruolo_prec;
    close sel_ruolo;
  end if;
  delete sgravi
   where cod_fiscale = p_cf
     and motivo_sgravio = 99
     and flag_automatico = 'S'
     and ruolo in (select ruolo
                     from ruoli
                    where anno_ruolo = w_anno
                      and tipo_tributo = w_titr
                      and invio_consorzio is not null
                      and tipo_emissione = w_tipo_emissione_prec
                      and ruolo != p_ruolo
                      and ruolo = nvl(w_ruolo_prec,ruolo))
  ;
--
-- (VD - 06/07/2015): trattamento compensazioni su ruoli suppletivi.
--                    Se il ruolo che si sta trattando è un suppletivo
--                    ulteriore, si eliminano anche le eventuali compensazioni
--                    emesse dal suppletivo precedente
--
  if p_se_emissione = 'S' and
     p_tipo_ruolo = 2 and
     p_tipo_emissione = 'S' then
     w_ruolo_prec := -1;
     for rec_ruolo in (select ruoli.ruolo
                         from ruoli, ruoli_contribuente ruco
                        where nvl(ruoli.tipo_emissione, 'T') = 'S'
                          and ruoli.tipo_ruolo = 2
                          and ruoli.ruolo = ruco.ruolo
                          and ruco.cod_fiscale = p_cf
                          and ruoli.anno_ruolo = p_anno
                          and ruoli.invio_consorzio is not null
                          and ruoli.ruolo != p_ruolo
                     order by ruoli.data_emissione desc)
     loop
       w_ruolo_prec := rec_ruolo.ruolo;
       exit;
     end loop;
--
     if nvl(w_ruolo_prec,-1) <> -1 then
        delete compensazioni_ruolo
         where cod_fiscale = p_cf
            and ruolo = w_ruolo_prec
            and motivo_compensazione = 99
            and flag_automatico = 'S'
           ;
     end if;
  end if;
END;
/* End Procedure: ELIMINAZIONE_SGRAVI_RUOLO */
/

