--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_anomalie stripComments:false runOnChange:true 
 
create or replace function F_CONTA_ANOMALIE
/*************************************************************************
 NOME:        F_CONTA_ANOMALIE
 DESCRIZIONE: Conta il numero di anomalie presenti per codice fiscale,
              anno e oggetto_pratica indicati.
                            Se il contatore e' maggiore di zero restituisce 'S'.
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                     altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 000     23/09/2019   VD          Prima emissione.
 001     29/01/2020   DM          Escluse le anomalie con FLAG_OK = S
 002     03/02/2020   DM          Nella seconda query si devono considerare
                                  solo le anomalie con tipo_intervento = 'OGGETTO'
                                  ovvero per oggetti.
 003    13/09/2023    DM          #66773: disabilitato controllo su anomalie_ici
                                  (verrà riattivato nella 4.9.2 con il rilascio della #30754)
 004    13/09/2023    DM          #30754 attivata ricerca in anomalie_ici
*************************************************************************/
( a_cod_fiscale            varchar2
, a_anno                   number
, a_oggetto_pratica        number
, a_oggetto                number
) return string
is
  w_conta_pratiche         number;
  w_conta_oggetti          number;
  w_conta_anomalie_ici     number;
  w_conta_record           number   :=0;
begin
--
  select count(*)
    into w_conta_pratiche
    from anomalie_pratiche anpr
       , anomalie anom
       , anomalie_parametri anpa
   where anpr.id_anomalia = anom.id_anomalia
     and anom.id_anomalia_parametro = anpa.id_anomalia_parametro
     and nvl(anom.flag_ok, 'N') != 'S'
     and anpr.cod_fiscale        = a_cod_fiscale
     and anpa.anno               = a_anno
     and anpr.oggetto_pratica    = a_oggetto_pratica
  ;
  select count(*)
    into w_conta_oggetti
    from tipi_anomalia tian
       , anomalie anom
      , anomalie_parametri anpa
   where anom.id_anomalia_parametro = anpa.id_anomalia_parametro
     and tian.tipo_anomalia = anpa.id_tipo_anomalia
     and nvl(anom.flag_ok, 'N') != 'S'
     and tian.tipo_intervento = 'OGGETTO'
     and anpa.anno            = a_anno
     and anom.id_oggetto      = a_oggetto
  ;
  select count(*)
    into w_conta_anomalie_ici
    from anomalie_ici anic
   where anic.oggetto = a_oggetto
     and nvl(anic.flag_ok, 'N') != 'S'
     and anic.anno = a_anno
  ;
--
  w_conta_record := w_conta_pratiche + w_conta_oggetti + w_conta_anomalie_ici;
  if w_conta_record > 0 then
     return 'S';
  else
     return null;
  end if;
end;
/* End Function: F_CONTA_ANOMALIE */
/
