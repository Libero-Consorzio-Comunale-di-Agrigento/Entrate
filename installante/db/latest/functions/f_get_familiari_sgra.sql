--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_familiari_sgra stripComments:false runOnChange:true 
 
create or replace function F_GET_FAMILIARI_SGRA
/*************************************************************************
 NOME:        F_GET_FAMILIARI_SGRA
 DESCRIZIONE: Dati i dati di uno sgravio, restituisce una stringa con
              il numero dei familiari a carico con i relativi periodi
              di validità
 RITORNA:     varchar2             Note
 *************************************************************************/
( a_ruolo                          in number
, a_cod_fiscale                    in varchar2
, a_sequenza                       in number
, a_sequenza_sgravio               in number)
return varchar2 is
  w_str_fam_sgra                   varchar2(4000) := '';
  w_str_dett_fam                   varchar2(4000);
  w_str_dett_fam1                  varchar2(4000);
  w_str_dett_fam2                  varchar2(4000);
  w_coeff_fissa                    varchar2(3);
  w_coeff_var                      varchar2(3);
  w_str_mq_fissa                   varchar2(10);
  w_str_mq_var                     varchar2(10);
  w_lunghezza_prec                 number;
  w_lunghezza_new                  number;
  w_cont                           number := 1;
  w_tipo_calcolo                   varchar2(1);
  w_imposta_dovuta                 number;
  cursor sel_familiari_sgra
  is
    select decode(nvl(nvl(fasg.numero_familiari,ogpr.numero_familiari),0),0,''
                , rpad('Familiari: '||nvl(fasg.numero_familiari,ogpr.numero_familiari),15)
                  ||' Dal: '||to_char(decode(fasg.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , fasg.dal),'dd/mm/yyyy')
                  ||' al: '||to_char(decode(fasg.numero_familiari
                                           , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                           , fasg.al),'dd/mm/yyyy')
                  || '[a_capo'
                  || lpad(' ', 15)) note2
         , substr(nvl(fasg.dettaglio_fasg, sgra.dettaglio_sgra),1,131) dettaglio
         , cate.flag_domestica
         , ogpr.consistenza mq
         , sgra.imposta_dovuta
      from oggetti_pratica  ogpr
         , familiari_sgra   fasg
         , oggetti_validita ogva
         , categorie        cate
         , sgravi           sgra
     where sgra.ruolo            = a_ruolo
       and sgra.cod_fiscale      = a_cod_fiscale
       and sgra.sequenza         = a_sequenza
       and sgra.sequenza_sgravio = a_sequenza_sgravio
       and fasg.ruolo            = sgra.ruolo
       and fasg.cod_fiscale      = sgra.cod_fiscale
       and fasg.sequenza         = sgra.sequenza
       and fasg.sequenza_sgravio = sgra.sequenza_sgravio
       and ogpr.oggetto_pratica  = sgra.ogpr_sgravio
       and ogpr.oggetto_pratica  = ogva.oggetto_pratica
       and cate.tributo          = ogpr.tributo
       and cate.categoria        = ogpr.categoria
     order by fasg.dal, fasg.al
  ;
begin
  begin
    select nvl(tipo_calcolo,'T')
      into w_tipo_calcolo
      from ruoli ruol
     where ruol.ruolo = a_ruolo
     ;
  exception
      when others then
          w_tipo_calcolo := 'T';
  end;
  if w_tipo_calcolo != 'T' then -- estrae i dettagli da OGIM altrimenti null
     for rec_fam_sgra in sel_familiari_sgra
       loop
         if rec_fam_sgra.flag_domestica is null then
            w_coeff_fissa := 'Kc.';
            w_coeff_var := 'Kd.';
            w_str_mq_fissa := 'Mq'||to_char(round(rec_fam_sgra.mq),'B99999');
            w_str_mq_var := 'Mq'||to_char(round(rec_fam_sgra.mq),'B99999');
         else
            w_coeff_fissa := 'Ka.';
            w_coeff_var := 'Kb.';
            w_str_mq_fissa := 'Mq'||to_char(round(rec_fam_sgra.mq),'B99999');
            w_str_mq_var := '        ';
         end if;
         w_str_dett_fam := replace(replace(replace('('||w_coeff_fissa || substr(rec_fam_sgra.dettaglio
                                                                               , 8
                                                                               )
                                                  ,'Imposta QF'
                                                  ,w_str_mq_fissa || ') QF:'
                                                  )
                                          ,'Coeff.'
                                          ,' - ('||w_coeff_var
                                          )
                                  ,'Imposta QV'
                                  ,w_str_mq_var || ') QV:'
                                  )
                           ;
         w_lunghezza_prec := length(w_str_dett_fam);
         w_lunghezza_new := 0;
--
         w_str_dett_fam1 := substr(w_str_dett_fam,1,instr(w_str_dett_fam,' - '));
         w_str_dett_fam2 := substr(w_str_dett_fam,instr(w_str_dett_fam,' - ')+3);
         if w_cont = 1 then
            w_imposta_dovuta := rec_fam_sgra.imposta_dovuta;
            w_str_fam_sgra := lpad(' ', 5)
                        || rec_fam_sgra.note2
                        || w_str_dett_fam1
                        || '[a_capo'
                        || lpad(' ', 15)
                        || w_str_dett_fam2
                        ;
         else
            w_str_fam_sgra := w_str_fam_sgra
                        || '[a_capo'
                        || lpad(' ', 15)
                        || rec_fam_sgra.note2
                        || w_str_dett_fam1
                        || '[a_capo'
                        || lpad(' ', 15)
                        || w_str_dett_fam2
                           ;
         end if;
         w_cont := w_cont + 1;
     end loop;
--;
     if nvl(w_imposta_dovuta,0) != 0 then
        w_str_fam_sgra := w_str_fam_sgra
                    || '[a_capo'
                    || 'IMPORTO NETTO                                                  '
                    || lpad(nvl(translate(ltrim(to_char(w_imposta_dovuta,'99,999,999,990.00')),'.,',',.'),' '),17,' ')
                    ;
     end if;
  else
     w_str_fam_sgra := null;
  end if;
  --[a_capo viene convertito in Carriage Return da PowerBuilder*/
  return(w_str_fam_sgra);
exception
  when others then
    return sqlerrm;
end;
/* End Function: F_GET_FAMILIARI_SGRA */
/

