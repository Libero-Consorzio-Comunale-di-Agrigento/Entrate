--liquibase formatted sql 
--changeset abrandolini:20250326_152423_ricalcolo_interessi stripComments:false runOnChange:true 
 
create or replace procedure RICALCOLO_INTERESSI
/*************************************************************************
 NOME:        RICALCOLO_INTERESSI
 DESCRIZIONE: Ricalcolo interessi su pratiche di liquidazione non ancora
              notificate.
 NOTE:
 Rev.    Date         Author      Note
 001     17/12/2021   VD          Modificata selezione pratica da trattare:
                                  deve essere non notificata (data_notifica
                                  null) e non con stato null.
 000     XX/XX/XXXX   XX          Prima emissione
*************************************************************************/
(a_pratica     in number)
IS
errore                  exception;
w_errore                varchar2(200);
w_data_scad_acconto     date; --Data scadenza acconto
w_data_scad_saldo       date; --Data scadenza saldo
w_importo               number;
w_utente                varchar2(8);
w_tipo_tributo          varchar2(10);
w_anno                  number(4);
w_cod_fiscale           varchar2(16);
p_data_rif_interessi    date := trunc(sysdate);
BEGIN
  begin
    select prtr.tipo_tributo
         , prtr.anno
         , prtr.cod_fiscale
      into w_tipo_tributo
         , w_anno
         , w_cod_fiscale
      from pratiche_tributo prtr
     where prtr.pratica = a_pratica
           and tipo_tributo in ('ICI','TASI')
           and tipo_pratica = 'L'
           -- (VD - 17/12/2021): corretto test su pratica da trattare
           --and prtr.stato_accertamento is null
           and prtr.data_notifica is null
       ;
  EXCEPTION
     WHEN others THEN
        w_errore := 'Errore recupero dati pratica '||to_char(a_pratica);
        raise errore;
  end;
  w_data_scad_acconto := f_scadenza(w_anno, w_tipo_tributo, 'A', w_cod_fiscale);
  w_data_scad_saldo   := f_scadenza(w_anno, w_tipo_tributo, 'S', w_cod_fiscale);
  -- Si aggiorna la data della pratica
  begin
     update pratiche_tributo
        set data = p_data_rif_interessi
     where pratica = a_pratica;
  exception
    when others then
     w_errore := 'Errore in aggiornamento data pratica '||to_char(a_pratica);
     raise errore;
  end;
  -- Si ricerca l'importo dell'imposta evasa in acconto
  begin
    select importo
         , utente
      into w_importo
         , w_utente
      from sanzioni_pratica
     where pratica = a_pratica
       and cod_sanzione = 101;
  exception
    when others then
      w_importo := 0;
  end;
  -- Se esiste l'imposta evasa in acconto, si eliminano e si ricalcolano gli interessi
  if w_importo > 0 then
     delete from sanzioni_pratica
      where pratica = a_pratica
        and cod_sanzione = 198;
      --
     inserimento_interessi(a_pratica,NULL,w_data_scad_acconto,p_data_rif_interessi,w_importo,w_tipo_tributo,'A',w_utente);
  end if;
  -- Si ricerca l'importo dell'imposta evasa a saldo
  begin
    select importo
         , utente
      into w_importo
         , w_utente
      from sanzioni_pratica
     where pratica = a_pratica
       and cod_sanzione = 121;
  exception
    when others then
      w_importo := 0;
  end;
  -- Se esiste l'imposta evasa in acconto, si eliminano e si ricalcolano gli interessi
  if w_importo > 0 then
     delete from sanzioni_pratica
      where pratica = a_pratica
        and cod_sanzione = 199;
        --
       inserimento_interessi(a_pratica,NULL,w_data_scad_saldo,p_data_rif_interessi,w_importo,w_tipo_tributo,'S',w_utente);
  end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Ricalcolo Interessi Liquidazioni - Pratica '||to_char(a_pratica)||' '||'('||SQLERRM||')');
END;
/* End Procedure: RICALCOLO_INTERESSI */
/

