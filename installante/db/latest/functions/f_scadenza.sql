--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_scadenza stripComments:false runOnChange:true 
 
create or replace function F_SCADENZA
/*************************************************************************
 NOME:        F_SCADENZA
 DESCRIZIONE: Determina la scadenza dei versamenti in acconto/saldo
              tenendo conto degli eventi eccezionali
 RITORNA:     Data scadenza del tipo richiesto
 Versione  Data              Autore    Descrizione
 1         28/10/2016        VD        Aggiunto test tipo_scadenza in
                                       seleziona scadenze standard
 0         11/11/2013                  Prima emissione
*************************************************************************/
(p_anno             number,
 p_tipo_tributo     varchar2,
 p_tipo_versamento  varchar2,
 p_cod_fiscale      varchar2 default null,
 p_rata             number   default null
)
 return date
is
 w_data_scadenza    date;
 w_tipo_evento      varchar2(1);
begin
  begin
    select max(data_scadenza)
    into   w_data_scadenza
    from   scadenze
    where  anno            = p_anno
    and    tipo_versamento = p_tipo_versamento
    and    tipo_tributo    = p_tipo_tributo
    and    (  p_tipo_tributo in ('ICI','TASI')
           or nvl(rata,0)  = nvl(p_rata,0) --se ICI/IMU non testiamo la rata
           )
    and    (nvl(tipo_scadenza,' '),nvl(rata,1)) in
                                     (select tipo_evento,sequenza
                                        from eventi_contribuente
                                       where cod_fiscale = p_cod_fiscale
                                     )
    ;
  exception
     when others
        then w_data_scadenza := null;
  end;
  if w_data_scadenza is null then
     begin
       select max(data_scadenza)
       into   w_data_scadenza
       from   scadenze
       where  anno            = p_anno
       -- (VD 28/10/2016) - Aggiunto test su tipo_scadenza
       and    tipo_scadenza   = 'V'
       and    tipo_versamento = p_tipo_versamento
       and    tipo_tributo    = p_tipo_tributo
       and    (  p_tipo_tributo in ('ICI','TASI')
              or nvl(rata,0) = nvl(p_rata,0)  --se ICI/IMU non testiamo la rata
              )
        ;
     exception
        when others
           then w_data_scadenza := null;
     end;
  end if;
  return w_data_scadenza;
end;
/* End Function: F_SCADENZA */
/

