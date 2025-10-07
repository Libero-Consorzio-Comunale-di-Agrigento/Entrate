--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_familiari_ogim stripComments:false runOnChange:true 
 
create or replace function F_GET_FAMILIARI_OGIM
/*************************************************************************
 NOME:        F_GET_FAMILIARI_OGIM
 DESCRIZIONE: Restituisce una stringa contenente le informazioni relative
              a familiari e valori per calcolo imposta per stampa
              comunicazione a ruolo TARSU
 PARAMETRI:   Oggetto imposta
 RITORNA:     varchar2            Stringa contenente i dati da stampare
                                  nella comunicazione a ruolo gia'
                                  formattati
 NOTE:
 Rev.    Date         Author      Note
 003     28/01/2019   VD          Modifiche per gestione ruoli calcolati
                                  con tariffa.
 002     10/12/2014   VD          Ingrandite variabili stringa per errore
                                  "numeric or value error"
 001     04/11/2014   Betta T.    (più Piero) Sistemata estrazione del numero
                                  di familiari: gli nvl erano invertiti:
                                  dobbiamo leggere prima faog e poi eventualmente
                                  ogpr
 000     01/12/2008   XX          Prima emissione.
*************************************************************************/
( a_ogim                          in number
) return varchar2
is
w_str_fam_ogim               varchar2(4000) := '';
w_str_dett_fam               varchar2(4000);
w_str_dett_fam1              varchar2(4000);
w_str_dett_fam2              varchar2(4000);
w_str_conferimenti           varchar2(4000);
w_coeff_fissa                varchar2(7);
w_coeff_var                  varchar2(7);
w_str_mq_fissa               varchar2(10);
w_str_mq_var                 varchar2(10);
w_lunghezza_prec             number;
w_lunghezza_new              number;
w_cont                       number := 1;
w_tipo_calcolo               varchar2(1);
w_flag_tariffa_base          varchar2(1);
w_flag_tariffe_ruolo         varchar2(1);
w_cod_istat                  varchar2(6);
w_riga_1                     varchar2(100);
w_riga_2                     varchar2(100);
w_riga_3                     varchar2(100);
w_riga_4                     varchar2(100);
 cursor sel_familiari_ogim(p_ogim number)
 is
    select decode(nvl(nvl(faog.numero_familiari,ogpr.numero_familiari),0),0,''
                , decode(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,1)
                , ' ','Familiari: '||nvl(faog.numero_familiari,ogpr.numero_familiari)
                      ||' Dal: '||to_char(decode(faog.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , faog.dal),'dd/mm/yy')
                      ||' al: '||to_char(decode(faog.numero_familiari
                                        , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                        , faog.al),'dd/mm/yy')
                      || '[a_capo'
                      || lpad(' ', 15)
                     ,'Numero '||nvl(faog.numero_familiari,ogpr.numero_familiari)
                      ||' Componenti dal: '||to_char(decode(faog.numero_familiari
                                         , null ,nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                                         , faog.dal),'dd/mm/yyyy')
                      ||' al '||to_char(decode(faog.numero_familiari
                                           , null ,nvl(ogva.al,to_date('31122999','ddmmyyyy'))
                                           , faog.al),'dd/mm/yyyy')
                      || '[a_capo'
                        )
                 ) note2
         , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,131) dettaglio
         , substr(nvl(faog.dettaglio_faog_base, ogim.dettaglio_ogim_base),1,151) dettaglio_base
         , substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),1,1)   flag_tipo_riga
         , rtrim(ltrim(substr(nvl(faog.dettaglio_faog, ogim.dettaglio_ogim),152)))  sconto_conf
         , nvl(nvl(faog.numero_familiari,ogpr.numero_familiari),0) num_familiari
         , ogim.perc_riduzione_pf
         , ogim.perc_riduzione_pv
         -- , decode (ogim.dettaglio_ogim
         --          , null, substr(faog.dettaglio_faog,1,131)
         --                 ,substr(ogim.dettaglio_ogim,1,131)) dettaglio
         , cate.flag_domestica
         , ogpr.consistenza                                                     mq
      from oggetti_pratica ogpr
          ,oggetti_imposta ogim
          ,familiari_ogim faog
          ,oggetti_validita ogva
          ,categorie cate
     where ogim.oggetto_imposta = p_ogim
       and ogpr.oggetto_pratica = ogim.oggetto_pratica
       and faog.oggetto_imposta(+) = ogim.oggetto_imposta
       and ogpr.oggetto_pratica = ogva.oggetto_pratica
       and cate.tributo         = ogpr.tributo
       and cate.categoria       = ogpr.categoria
  order by faog.dal, faog.al
  ;
begin
  begin
    select lpad (to_char (pro_cliente), 3, '0')
        || lpad (to_char (com_cliente), 3, '0')
      into w_cod_istat
      from dati_generali;
  exception
    when others then
     w_cod_istat := '000000';
  end;
  begin
    select nvl(tipo_calcolo,'T')
         , nvl(flag_calcolo_tariffa_base,'N')
         , nvl(flag_tariffe_ruolo,'N')
      into w_tipo_calcolo
         , w_flag_tariffa_base
         , w_flag_tariffe_ruolo
      from oggetti_imposta ogim, ruoli ruol
     where ruol.ruolo = ogim.ruolo
       and ogim.oggetto_imposta = a_ogim
      ;
  EXCEPTION
    when others then
      w_tipo_calcolo := 'T';
      w_flag_tariffe_ruolo := 'N';
  END;
  IF w_tipo_calcolo != 'T' then -- estrae i dettagli da OGIM altrimenti null
      for rec_fam_ogim in sel_familiari_ogim(a_ogim)
       loop
         if rec_fam_ogim.flag_domestica is null then
            w_str_mq_fissa := 'Mq'||to_char(round(rec_fam_ogim.mq),'B99999');
            w_str_mq_var := 'Mq'||to_char(round(rec_fam_ogim.mq),'B99999');
            if w_flag_tariffe_ruolo = 'S' then
               w_coeff_fissa := 'Euro/Mq';
               w_coeff_var   := 'Euro/Mq';
            else
               w_coeff_fissa := 'Kc.';
               w_coeff_var := 'Kd.';
            end if;
         else
            w_str_mq_fissa := 'Mq'||to_char(round(rec_fam_ogim.mq),'B99999');
            w_str_mq_var := '        ';
            if w_flag_tariffe_ruolo = 'S' then
               w_coeff_fissa := 'Euro/Mq';
               w_coeff_var   := 'Euro   ';
            else
               w_coeff_fissa := 'Ka.';
               w_coeff_var := 'Kb.';
            end if;
         end if;
         if rec_fam_ogim.flag_tipo_riga = ' ' then
            w_str_dett_fam := replace(replace(replace('('||w_coeff_fissa || substr(rec_fam_ogim.dettaglio
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
            w_str_dett_fam1 := substr(w_str_dett_fam,1,instr(w_str_dett_fam,' - '));
            w_str_dett_fam2 := substr(w_str_dett_fam,instr(w_str_dett_fam,' - ')+3);
         else
            if w_flag_tariffe_ruolo = 'S' then
               w_riga_1 := 'QUOTA FISSA  : '||w_coeff_fissa||substr(rec_fam_ogim.dettaglio,9,13)||' * '||w_str_mq_fissa||
                           lpad(substr(rec_fam_ogim.dettaglio_base,62,14),34);
               w_riga_3 := 'QUOTA VAR.   : '||w_coeff_var||substr(rec_fam_ogim.dettaglio,74,13);
               if w_str_mq_var = '        ' then
                  w_riga_3 := w_riga_3||'   ';
               else
                  w_riga_3 := w_riga_3||' * ';
               end if;
               w_riga_3 := w_riga_3||w_str_mq_var||
                           lpad(substr(rec_fam_ogim.dettaglio_base,137,14),34);
               if ltrim(substr(rec_fam_ogim.dettaglio,27,14)) <> '0,00' then
                  w_riga_2 := '[a_capo'||'RIDUZIONE QF : Perc. '||
                              translate(to_char(rec_fam_ogim.perc_riduzione_pf,'9999990.00'), ',.', '.,')||
                              lpad('-'||ltrim(substr(rec_fam_ogim.dettaglio,27,14)),48);
               end if;
               if ltrim(substr(rec_fam_ogim.dettaglio,92,14)) <> '0,00' then
                  w_riga_4 := '[a_capo'||'RIDUZIONE QV : Perc. '||
                              translate(to_char(rec_fam_ogim.perc_riduzione_pv,'9999990.00'), ',.', '.,')||
                              lpad('-'||ltrim(substr(rec_fam_ogim.dettaglio,92,14)),48);
               end if;
            else
               w_str_dett_fam := replace(replace(replace(replace(rec_fam_ogim.dettaglio,'*Coeff.','QUOTA FISSA  : '||w_coeff_fissa)
                                                                ,'Imposta QF',w_str_mq_fissa||'      ')
                                                        ,'Coeff.',' - QUOTA VAR.   : '||w_coeff_var)
                                                ,'Imposta QV',w_str_mq_var||'      ');
               w_riga_1 := substr(w_str_dett_fam,1,instr(w_str_dett_fam,' - '));
               w_riga_3 := substr(w_str_dett_fam,instr(w_str_dett_fam,' - ')+3);
               -- (VD - 13/03/2019): con Salvatore si e' deciso di non stampare niente
               --                    in caso di ruolo gestito a coefficienti
               --if w_flag_tariffa_base = 'S' then
               --   if ltrim(substr(rec_fam_ogim.dettaglio_base,32,14)) <> '0,00' then
               --      w_riga_2 := '[a_capo'||'RIDUZIONE QF : '||lpad('-'||ltrim(substr(rec_fam_ogim.dettaglio_base,32,14)),65);
               --   end if;
               --   if ltrim(substr(rec_fam_ogim.dettaglio_base,107,14)) <> '0,00' then
               --      w_riga_4 := '[a_capo'||'RIDUZIONE QV : '||lpad('-'||ltrim(substr(rec_fam_ogim.dettaglio_base,97,14)),65);
               --   end if;
               --end if;
            end if;
         end if;
         -- w_lunghezza_prec := length(w_str_dett_fam);
         -- w_lunghezza_new := 0;
         -- while w_lunghezza_prec != w_lunghezza_new loop
         --       w_lunghezza_prec := w_lunghezza_new;
         --       w_str_dett_fam := replace(w_str_dett_fam,'  ',' ');
         --       w_lunghezza_new := length(w_str_dett_fam);
         -- end loop;
         if w_cont = 1 then
            if rec_fam_ogim.flag_tipo_riga = ' ' then
               w_str_fam_ogim := '[a_capoDETTAGLI  '
                           || lpad(' ', 5)
                           || rec_fam_ogim.note2
                           || w_str_dett_fam1
                           || '[a_capo'
                           || lpad(' ', 15)
                           || w_str_dett_fam2
                           ;
            else
               if rec_fam_ogim.num_familiari = 0 then
                  w_str_fam_ogim := '[a_capoDETTAGLI     : [a_capo';
               else
                  w_str_fam_ogim := '[a_capoDETT. COMP.  : ';
               end if;
               w_str_fam_ogim := w_str_fam_ogim
                              || rec_fam_ogim.note2
                              || w_riga_1
                              || w_riga_2
                              || '[a_capo'
                              || w_riga_3
                              || w_riga_4
                              ;
            end if;
         else
            if rec_fam_ogim.flag_tipo_riga = ' ' then
               w_str_fam_ogim := w_str_fam_ogim
                           || '[a_capo'
                           || lpad(' ', 15)
                           || rec_fam_ogim.note2
                           || w_str_dett_fam1
                           || '[a_capo'
                           || lpad(' ', 15)
                           || w_str_dett_fam2
                              ;
            else
               w_str_fam_ogim := w_str_fam_ogim
                           || '[a_capo'
                           || lpad(' ', 15)
                           || rec_fam_ogim.note2
                           || w_riga_1
                           || w_riga_2
                           || '[a_capo'
                           || w_riga_3
                           || w_riga_4
                              ;
            end if;
         end if;
         --
         -- Sistemazione della stringa relativa allo sconto per conferimenti:
         -- se lo sconto è diverso da zero si stampa il segno meno davanti
         -- all'importo
         --
         if rec_fam_ogim.sconto_conf is not null then
            if w_cod_istat = '015192' then
               w_str_conferimenti := replace(replace('('||rec_fam_ogim.sconto_conf,' Perc.','  Perc.'),' Sconto:',') Sconto:');
            else
               w_str_conferimenti := rec_fam_ogim.sconto_conf;
            end if;
            if substr(w_str_conferimenti,instr(w_str_conferimenti,' ',-1) + 1) <> '0,00' then
               w_str_conferimenti := substr(w_str_conferimenti,1,instr(w_str_conferimenti,' ',-1)-1)||'-'||
                                     substr(w_str_conferimenti,instr(w_str_conferimenti,' ',-1) + 1);
            end if;
            w_str_fam_ogim := w_str_fam_ogim
                        || '[a_capo'
                        || lpad(' ', 15)
                        || w_str_conferimenti
                        ;
         end if;
         w_cont := w_cont + 1;
       end loop;
   else
      w_str_fam_ogim := to_char(null);
   end if;
   --[a_capo viene convertito in Carriage Return da PowerBuilder
   return(w_str_fam_ogim);
end;
/* End Function: F_GET_FAMILIARI_OGIM */
/

