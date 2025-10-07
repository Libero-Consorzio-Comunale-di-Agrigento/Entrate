--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_allinea_dettagli_acc_tarsu stripComments:false runOnChange:true 
 
create or replace function F_ALLINEA_DETTAGLI_ACC_TARSU
/*************************************************************************
 NOME:        F_ALLINEA_DETTAGLI_ACC_TARSU
 DESCRIZIONE: Date due stringhe ritornate daf_get_dettagli_acc_tarsu_ogim
              le ricompone in modo da fare n righe su due colonne
 RITORNA:     varchar2            Stringa di dettaglio
 NOTE:        Utilizzata in PB nel modello di stampa avviso di accertamento
              TARSU.
 Rev.    Date         Author      Note
 000     15/12/2014   ET          Prima emissione.
*************************************************************************/
( p_fam_ogim_dic     varchar2
, p_fam_ogim_acc     varchar2)
RETURN VARCHAR2
IS
  w_fam_ogim_out     varchar2(4000);
  w_fam_ogim_dic     varchar2(4000);
  w_fam_ogim_acc     varchar2(4000);
  w_prompt           varchar2(20);
  w_pos_a_capo_dic   number;
  w_pos_a_capo_acc   number;
  w_riga_dic         varchar2(80);
  w_riga_acc         varchar2(80);
  w_larghezza_col    number := 41;
  w_lunghezza_prec   number;
  w_lunghezza_new    number;
  w_pos              number;
BEGIN
  w_fam_ogim_out := null;
  if p_fam_ogim_dic is null and p_fam_ogim_acc is null
  -- se le strighe sono entrambe nulle non dobbiamo fare nulla
  then null;
  else -- mi salvo la parte iniziale ('DETTAGLI   :')
       w_prompt       := nvl(substr(p_fam_ogim_dic,1,instr(p_fam_ogim_dic,':'))
                            ,substr(p_fam_ogim_acc,1,instr(p_fam_ogim_acc,':')))||'  ';
       -- Tolgo la parte iniziale dalle due stringhe
       w_fam_ogim_dic := ltrim(substr(p_fam_ogim_dic,instr(p_fam_ogim_dic,':')+1));
       w_fam_ogim_acc := ltrim(substr(p_fam_ogim_acc,instr(p_fam_ogim_dic,':')+1));
       -- Accorciamo la scritta Tariffa
       w_fam_ogim_dic := replace(w_fam_ogim_dic,'Tariffa','Tar.');
       w_fam_ogim_acc := replace(w_fam_ogim_acc,'Tariffa','Tar.');
       --Togliamo gli spazi non significativi
       --if instr(w_fam_ogim_dic,'Euro') = 0 then
          w_lunghezza_prec := length(w_fam_ogim_dic);
          w_lunghezza_new := 0;
          while w_lunghezza_prec != w_lunghezza_new loop
                w_lunghezza_prec := w_lunghezza_new;
                w_fam_ogim_dic := replace(w_fam_ogim_dic,'  ',' ');
                w_lunghezza_new := length(w_fam_ogim_dic);
          end loop;
       --end if;
       --if instr(w_fam_ogim_acc,'Euro') = 0 then
          w_lunghezza_prec := length(w_fam_ogim_acc);
          w_lunghezza_new := 0;
          while w_lunghezza_prec != w_lunghezza_new loop
                w_lunghezza_prec := w_lunghezza_new;
                w_fam_ogim_acc := replace(w_fam_ogim_acc,'  ',' ');
                w_lunghezza_new := length(w_fam_ogim_acc);
          end loop;
       --end if;
       loop
         -- cerco il primo [a_capo, o la fine della stringa
         w_pos_a_capo_dic := instr(w_fam_ogim_dic,'[a_capo')-1;
         if w_pos_a_capo_dic = -1
         then w_pos_a_capo_dic := length(w_fam_ogim_dic);
         end if;
         w_pos_a_capo_acc := instr(w_fam_ogim_acc,'[a_capo')-1;
         if w_pos_a_capo_acc = -1
         then w_pos_a_capo_acc := length(w_fam_ogim_acc);
         end if;
         w_riga_dic := null;
         w_riga_acc := null;
         if nvl(w_pos_a_capo_dic,0) != 0
         then --metto in w_riga_dic la riga in esame
              w_riga_dic := ltrim(substr(w_fam_ogim_dic,1,w_pos_a_capo_dic));
              -- tolgo i caratteri salvati in w_riga_dic dalla stringa
              w_fam_ogim_dic := ltrim(substr(w_fam_ogim_dic,w_pos_a_capo_dic+8));
         end if;
         if nvl(w_pos_a_capo_acc,0) != 0
         then --metto in w_riga_acc la riga in esame
              w_riga_acc := ltrim(substr(w_fam_ogim_acc,1,w_pos_a_capo_acc));
              -- tolgo i caratteri salvati in w_riga_acc dalla stringa
              w_fam_ogim_acc := ltrim(substr(w_fam_ogim_acc,w_pos_a_capo_acc+8));
         end if;
         -- togliamo le prime 2 cifre dell anno
         w_pos := instr(w_riga_dic,'/',1,2);
         if w_pos > 0
         then w_riga_dic := substr(w_riga_dic,1,w_pos)||substr(w_riga_dic,w_pos+3);
              w_pos := instr(w_riga_dic,'/',1,4);
              w_riga_dic := substr(w_riga_dic,1,w_pos)||substr(w_riga_dic,w_pos+3);
         end if;
         w_pos := instr(w_riga_acc,'/',1,2);
         if w_pos > 0
         then w_riga_acc := substr(w_riga_acc,1,w_pos)||substr(w_riga_acc,w_pos+3);
              w_pos := instr(w_riga_acc,'/',1,4);
              w_riga_acc := substr(w_riga_acc,1,w_pos)||substr(w_riga_acc,w_pos+3);
         end if;
         if w_riga_dic is null and w_riga_acc is null
         -- se sono entrambi nulli abbiamo finito di dividere le stringhe
         then exit;
         end if;
         if w_fam_ogim_out is null
         then w_fam_ogim_out := w_prompt;
         else w_fam_ogim_out := w_fam_ogim_out||'[a_capo'||lpad(' ',length(w_prompt),' ');
         end if;
         w_fam_ogim_out := w_fam_ogim_out
                           ||rpad(nvl(w_riga_acc,' '),w_larghezza_col,' ')
                           ||nvl(w_riga_dic,' ');
       end loop;
  end if;
  return w_fam_ogim_out;
END;
/* End Function: F_ALLINEA_DETTAGLI_ACC_TARSU */
/

