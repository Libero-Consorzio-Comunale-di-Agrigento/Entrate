--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_scadenza stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_SCADENZA
/*************************************************************************
 NOME:        F_GET_DATA_SCADENZA
 DESCRIZIONE: Dati tipo tributo, anno, tipo versamento e tipo scadenza,
              restituisce la scadenza prevista in un parametro di I/O.
              La stringa di output contiene la descrizione dell'eventuale
              errore (Null = conclusione positiva).
 RITORNA:     varchar2              Descrizione errore
 NOTE:
 Rev.    Date         Author      Note
 000     18/05/2020   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo                  IN     varchar2
, a_anno                          IN     number
, a_tipo_vers                     IN     varchar2
, a_tipo_scad                     IN     varchar2
, a_data_scadenza                 IN OUT date
) return string
IS
  w_err                           varchar2(2000);
  w_data                          date;
BEGIN
   w_err := null;
   BEGIN
      select scad.data_scadenza
        into w_data
        from scadenze scad
       where scad.tipo_tributo    = a_tipo_tributo
         and scad.anno            = a_anno
         and nvl(scad.tipo_versamento,' ')
                                  = nvl(a_tipo_vers,' ')
         and scad.tipo_scadenza   = a_tipo_scad
      ;
      a_data_scadenza := w_data;
   EXCEPTION
      when no_data_found then
         if a_tipo_scad = 'V' then
            w_err := 'Scadenza di pagamento '||a_tipo_tributo||' ';
            if a_tipo_vers = 'A' then
               w_err := w_err||'in acconto';
            elsif a_tipo_vers = 'S' then
               w_err := w_err||'a saldo';
            else
               w_err := w_err||'unico';
            end if;
            w_err := w_err||' non prevista per anno '||to_char(a_anno);
         else
            w_err := 'Scadenza di presentazione denuncia '||a_tipo_tributo||' non prevista per anno '||
                     to_char(a_anno);
         end if;
      WHEN others THEN
         w_err := to_char(SQLCODE)||' - '||SQLERRM;
   END;
   return w_err;
END;
/* End Function: F_GET_DATA_SCADENZA */
/

