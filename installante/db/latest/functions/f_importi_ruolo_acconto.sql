--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_ruolo_acconto stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_RUOLO_ACCONTO
/*************************************************************************
 NOME:        F_IMPORTI_RUOLO_ACCONTO
 DESCRIZIONE: Determina gli importi di imposta e addizionali di un ruolo
              in acconto, relativi ad un singolo oggetto.
              Utilizzata nella stampa della comunicazione a ruolo TARSU
 PARAMETRI:   Codice fiscale
              Anno
              Decorrenza
              Cessazione
              Tipo tributo
              Oggetto
              Oggetto_pratica
              Oggetto_pratica_rif
              Flag_normalizzato
              Flag_tariffa_base
              Tipo                Identifica il tipo di importo che si
                                  vuole ottenere dalla funzione
                                  I - Imposta
                                  F - Quota fissa
                                  V - Quota variabile
 RITORNA:     number              Importo della tipologia prescelta
 NOTE:
 Rev.    Date         Author      Note
 000     13/03/2019   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale            varchar2
, p_anno_ruolo             number
, p_progr_emissione        number
, p_data_decorrenza        date
, p_data_cessazione        date
, p_tipo_tributo           varchar2
, p_oggetto                number
, p_oggetto_pratica        number
, p_oggetto_pratica_rif    number
, p_flag_normalizzato      varchar2
, p_flag_tariffa_base      varchar2
, p_tipo_importo           varchar2
) return number
is
  w_cod_istat              varchar2(6);
  w_data_cessazione        date;
  w_importo                number;
  w_importo_acconto        number;
  w_importo_acconto_pv     number;
  w_importo_acconto_pf     number;
  w_importo_acc_base       number;
  w_importo_acc_pv_base    number;
  w_importo_acc_pf_base    number;
  w_tipo_calcolo_acconto   varchar2(1);
  w_ruolo_acconto          number;
begin
  -- Per replicare la gestione della data di cessazione presente
  -- nell'emissione ruolo, si seleziona il codice ISTAT del cliente
  begin
    select lpad(to_char(pro_cliente),3,'0')||
           lpad(to_char(com_cliente),3,'0')
      into w_cod_istat
      from dati_generali;
  EXCEPTION
     WHEN others THEN
       w_cod_istat := '000000';
  END;
  if w_cod_istat = '017025' and p_tipo_tributo = 'TARSU' and p_anno_ruolo > 2007 and p_progr_emissione = 1 then
     if nvl(p_data_cessazione,to_date('3112'||to_char(p_anno_ruolo),'ddmmyyyy')) > to_date('3006'||to_char(p_anno_ruolo),'ddmmyyyy') then
        w_data_cessazione := to_date('3006'||to_char(p_anno_ruolo),'ddmmyyyy');
     else
        w_data_cessazione := p_data_cessazione;
     end if;
  else
     if p_data_cessazione is null then
        begin
          select ogva.al
            into w_data_cessazione
            from oggetti_validita ogva
           where ogva.cod_fiscale = p_cod_fiscale
             and ogva.tipo_tributo = p_tipo_tributo
             and ogva.oggetto = p_oggetto
             and ogva.dal = p_data_decorrenza;
        exception
          when others then
            w_data_cessazione := p_data_cessazione;
        end;
     else
        w_data_cessazione := p_data_cessazione;
     end if;
  end if;
--
  importi_ruolo_acconto(p_cod_fiscale
                       ,p_anno_ruolo
                       ,p_data_decorrenza
                       ,w_data_cessazione
                       ,p_tipo_tributo
                       ,p_oggetto
                       ,p_oggetto_pratica
                       ,p_oggetto_pratica_rif
                       ,p_flag_normalizzato
                       ,p_flag_tariffa_base
                       ,w_importo_acconto
                       ,w_importo_acconto_pv
                       ,w_importo_acconto_pf
                       ,w_importo_acc_base
                       ,w_importo_acc_pv_base
                       ,w_importo_acc_pf_base
                       ,w_tipo_calcolo_acconto
                       ,w_ruolo_acconto
                       );
--
  if p_tipo_importo = 'I' then
     w_importo := w_importo_acconto;
  elsif
     p_tipo_importo = 'F' then
     w_importo := w_importo_acconto_pf;
  else
     w_importo := w_importo_acconto_pv;
  end if;
--
  return w_importo;
--
end;
/* End Function: F_IMPORTI_RUOLO_ACCONTO */
/

