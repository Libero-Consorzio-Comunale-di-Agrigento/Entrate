--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_ctr_vers_ruoli_coattivi stripComments:false runOnChange:true 
 
create or replace function F_CTR_VERS_RUOLI_COATTIVI
/*************************************************************************
 Versione  Data        Autore    Descrizione
 001       10/03/2023  VM        (#60197) Se sanzione ha ruolo coattivo
                                 restituisci messaggio con avviso
*************************************************************************/
(      a_pratica in number,
       a_cod_fiscale in varchar2,
       a_log_documento in varchar2)
return varchar2
is
       w_result         varchar2(32767);
       w_numero         varchar2(15);
       w_tipo_pratica   varchar2(50);
       w_anno           number(4);
       w_ruolo          number(10);
begin
  w_result := a_log_documento;
  select max(ruol.ruolo),
         decode(max(prtr.tipo_pratica),
                'L',
                'Liquidazione',
                'A',
                'Accertamento',
                'S',
                'Sollecito',
                max(prtr.tipo_pratica)),
         max(prtr.numero),
         max(prtr.anno)
    into w_ruolo, w_tipo_pratica, w_numero, w_anno
    FROM pratiche_tributo prtr, sanzioni_pratica sapr, ruoli ruol
   where prtr.pratica = a_pratica
     and sapr.pratica = prtr.pratica
     and sapr.ruolo = ruol.ruolo
     and ruol.specie_ruolo = 1;
   if (w_ruolo is not null) then
    w_result := CASE WHEN a_log_documento IS NULL THEN '' ELSE (a_log_documento||chr(13)||chr(10)) END
                || w_tipo_pratica || ' '
                || 'Numero ' || w_numero || ' '
                || 'Anno ' || w_anno || ' '
                || ' del contribuente ' || a_cod_fiscale
                || ': inserito versamento su pratica già andata a ruolo.';
   end if;
  return(w_result);
end;
/* End Function: F_CTR_VERS_RUOLI_COATTIVI */
/

