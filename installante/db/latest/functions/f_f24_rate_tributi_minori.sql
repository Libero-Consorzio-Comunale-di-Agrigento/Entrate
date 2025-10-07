--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_rate_tributi_minori stripComments:false runOnChange:true 
 
create or replace function F_F24_RATE_TRIBUTI_MINORI
/*************************************************************************
 NOME:        F_F24_RATE_TRIBUTI_MINORI
 DESCRIZIONE: Modello F24 pagamento tributi minori: determina gli importi
              divisi per codice tributo per l'imposta calcolata o la
              denuncia.
              Utilizzata in PB per w_f24_titr_stampa.
 PARAMETRI:   Riga                Numero della riga del modulo F24 da
                                  da stampare
              Tipo tributo        TOSAP/ICP
              Anno                Anno di riferimento
              Imposta occ.perm.   Imposta per occupazione permanente
              Imposta occ.temp.   Imposta per occupazione temporanea
 RITORNA:     varchar2            Stringa contenente il codice tributo e
                                  l'importo
 NOTE:
 Rev.    Date         Author      Note
 000     22/11/2019   VD          Prima emissione.
*************************************************************************/
(a_riga                number
,a_tipo_tributo        varchar2
,a_anno                number
,a_imposta_perm        number default null
,a_imposta_temp        number default null
)
return varchar2
is
w_imposta_perm       varchar2(19);
w_imposta_temp       varchar2(19);
w_cf24_permanente    varchar2(4);
w_cf24_temporanea    varchar2(4);
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   --
   -- Selezione codici F24 da nuovo dizionario
   --
   begin
     select min(decode(tipo_codice,'C',tributo_f24,'')) cf24_permanente,
            max(decode(tipo_codice,'C',tributo_f24,'')) cf24_temporanea
       into w_cf24_permanente
          , w_cf24_temporanea
       from codici_f24
      where tipo_tributo = a_tipo_tributo
        and descrizione_titr = f_descrizione_titr(a_tipo_tributo,a_anno);
   exception
     when others then
       if a_tipo_tributo = 'TOSAP' then
          w_cf24_permanente := '3931';
          w_cf24_temporanea := '3932';
       else
          w_cf24_permanente := '3964';
          w_cf24_temporanea := '3964';
       end if;
   end;
   w_imposta_perm      := w_cf24_permanente||to_char(round(a_imposta_perm,0),'999999990');
   w_imposta_temp      := w_cf24_temporanea||to_char(round(a_imposta_temp,0),'999999990');
   if nvl(round(a_imposta_perm,0),0) > 0 then
      t_riga(to_char(i)) := w_imposta_perm;
      i := i+1;
   end if;
   if nvl(round(a_imposta_temp,0),0) > 0 then
      t_riga(to_char(i)) := w_imposta_temp;
      i := i+1;
   end if;
   return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_RATE_TRIBUTI_MINORI */
/

