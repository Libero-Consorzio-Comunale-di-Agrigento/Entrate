--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_timp stripComments:false runOnChange:true 
 
create or replace function F_DESCRIZIONE_TIMP
/*************************************************************************
 NOME:        F_DESCRIZIONE_TIMP
 DESCRIZIONE: Ricevuti in ingresso il numero del modello e identificativo
              del parametro restituisce il testo personalizzato
 RITORNA:     number              Totale versato
 Rev.    Date         Author      Note
 001     29/09/2022   VD          Aggiunta gestione parametri sollecito
                                  TARSU: per questo modello non vengono
                                  gestiti parametri.
 000     XX/XX/XXXX   XX          Prima emissione.
*************************************************************************/
(a_modello       in number
,a_parametro    in varchar2)
return varchar2
is
--Testo personalizzato
w_testo varchar2(2000);
--Lunghezza massima del testo personalizzato
w_lunghezza_max number;
--Testo di default
w_testo_predefinito varchar2(2000);
--Descrizione_ord del modello
w_descrizione_ord varchar2(10);
begin
  -- (VD - 29/09/2022): aggiunta selezione tipo modello
  begin
    select demo.descrizione_ord
      into w_descrizione_ord
      from modelli demo
     where demo.modello = a_modello;
  exception
    when others then
      /*raise_application_error(-20999,'Modello '||a_modello||' non esistente'||
                                     ' ('||sqlerrm||')');*/
                                     return null;
  end;
  begin
     --Recupera la lunghezza massima e il testo predefinito
     select timp.lunghezza_max
          , timp.testo_predefinito
       into w_lunghezza_max
          , w_testo_predefinito
       from modelli mo
          , tipi_modello_parametri timp
      where timp.tipo_modello = mo.descrizione_ord
        and mo.modello = a_modello
        and timp.parametro = a_parametro
      ;
  exception
     when no_data_found then
       return null;
        /*select demo.descrizione_ord
          into w_descrizione_ord
          from modelli demo
         where demo.modello = a_modello
         ;*/
        /*if w_descrizione_ord = 'SOL_TARSU%' then
           return null;
        else
           RAISE_APPLICATION_ERROR (-20664, 'Parametro inesistente. '
           || 'Desc: ' || w_descrizione_ord || ' Par: ' || a_parametro || ' ('||SQLERRM||')');
        end if;*/
  end;
  --Recupera il testo personalizzato
  begin
    select rpad(nvl(modet.testo, ' '),w_lunghezza_max)
      into w_testo
      from modelli_dettaglio modet
          , tipi_modello_parametri timp
     where timp.parametro_id = modet.parametro_id
        and modet.modello = a_modello
       and timp.parametro = a_parametro
       ;
  exception
     when no_data_found then
       --Se non esiste alcuna personalizzazione si utilizza il testo predefinito
           w_testo := rpad(nvl(w_testo_predefinito, ' '),w_lunghezza_max);
     when others then
        RAISE_APPLICATION_ERROR (-20666, 'Errore nella ricerca dei parametri dei modelli' || ' Par: ' || a_parametro ||'('||SQLERRM||')');
  end;
  return (w_testo);
END;
/* End Function: F_DESCRIZIONE_TIMP */
/

