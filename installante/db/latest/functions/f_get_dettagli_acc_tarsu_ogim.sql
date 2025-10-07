--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_dettagli_acc_tarsu_ogim stripComments:false runOnChange:true 
 
create or replace function F_GET_DETTAGLI_ACC_TARSU_OGIM
/*************************************************************************
 NOME:        F_GET_DETTAGLI_ACC_TARSU_OGIM
 DESCRIZIONE: Costruisce la stringa relativa ai dettagli TARSU (tariffe +
              familiari) per l'avviso di accertamento TARSU
 RITORNA:     varchar2            Stringa di dettaglio
 NOTE:        Utilizzata in PB nel modello di stampa avviso di accertamento
              TARSU.
 Rev.    Date         Author      Note
 004     26/06/2023   AB          #63043
                                  Invertito la nvl del dettaglio, prendendo prima
                                  faog e poi ogim, il numero dei familiari lo prendo
                                  tramite una nuova function f_get_num_fam_ogim
 003     06/05/2019   VD          Aggiunta gestione importi calcolati con
                                  tariffe
 002     07/12/2018   VD          Pontedera: modificata esposizione dati.
 001     19/12/2014   Betta T.    Corretta det. del tipo calcolo del ruolo
                                  corretta selezione della quota var
                                  (perdeva un chr)
 000     24/04/2014   XX          Prima emissione.
*************************************************************************/
( a_pratica                NUMBER,
  a_oggetto_imposta   IN   NUMBER
)
   RETURN VARCHAR2
IS
   w_str_fam_ogim         VARCHAR2 (4000) := '';
   w_str_dett_fam_fissa   VARCHAR2 (4000);
   w_str_dett_fam_var     VARCHAR2 (4000);
   w_coeff_fissa          VARCHAR2 (11);
   w_coeff_var            VARCHAR2 (11);
   w_str_mq_fissa         VARCHAR2 (10);
   w_str_mq_var           VARCHAR2 (10);
   w_spazi_var            VARCHAR2 (100) := lpad(' ',24);
   w_cont                 NUMBER         := 1;
   w_a_capo               VARCHAR2 (10)  := '[a_capo';
   w_cod_istat            varchar2(6);
   w_flag_tariffe         varchar2(1);
   CURSOR sel_familiari_ogim
   IS
   -- (VD - 06/05/2019): modificata query per gestione importi calcolati con
   --                    tariffe
   --                    Il primo carattere della stringa dettaglio_ogim/dettaglio_faog
   --                    identifica il tipo di calcolo: se è spazio, il calcolo è stato
   --                    effettuato con il vecchio metodo, se è "*" il calcolo è stato
   --                    effettuato con le tariffe.
      SELECT DISTINCT substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),1,1) flag_tipo_riga,
--                      DECODE (NVL (NVL (faog.numero_familiari,
--                                        ogpr.numero_familiari
--                                       ),
--                                   0
--                                  ),
                      DECODE(f_get_num_fam_ogim(ogim.oggetto_imposta, faog.dal),
                              0, '',
                                 'Fam. '
--                              || NVL (faog.numero_familiari,
--                                      ogpr.numero_familiari
--                                     )
                                 || f_get_num_fam_ogim(ogim.oggetto_imposta, faog.dal)
                                 || DECODE (faog.numero_familiari,
                                         NULL, '',
                                            ' Dal: '
                                         || TO_CHAR (faog.dal, 'dd/mm/yyyy')
                                         || ' al: '
                                         || TO_CHAR (faog.al, 'dd/mm/yyyy')
                                         || w_a_capo
                                         || ' '--LPAD (' ', 24)
                                        )
                            ) note2,
                      decode(instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff'),
                             0,substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                      instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Tariffa'),
                                      20
                                     )||
                               decode(nvl(ogim.perc_riduzione_pf,0),0,'',
                                      ' Perc.Rid. '||ltrim(translate(to_char(ogim.perc_riduzione_pf,'9999990.00'), ',.', '.,'))
                                     ),
                               SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                       instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff'),
                                       36
                                      )
                            ) dettaglio_fissa,
                      decode(instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff'),
                             0,substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                      instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Tariffa',1,2),
                                      20
                                     )||
                               decode(nvl(ogim.perc_riduzione_pv,0),0,'',
                                      ' Perc.Rid. '||ltrim(translate(to_char(ogim.perc_riduzione_pv,'9999990.00'), ',.', '.,'))
                                     ),
                               SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                       instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff',1,2),
                                       36
                                      )
                            ) dettaglio_var,
                      decode(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),1,1),
                             ' ',SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                         instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Imposta QF'),
                                         27
                                        ),
                                 SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                         instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Imposta QF'),
                                         24
                                        )
                            )  dett_imposta_fissa,
                      decode(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),1,1),
                             ' ',SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                         instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Imposta QV'),
                                         27
                                        ),
                                         SUBSTR (NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),
                                         instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Imposta QV'),
                                         24
                                        )
                            ) dett_imposta_var,
                      decode (instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff'),0, null,
                              to_number(replace(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim), 9, 8),',','')) / 10000 *
                              to_number(replace(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim), 25, 13),',','')) / 100000
                             ) tariffa_fissa,
                      decode (instr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim),'Coeff',1,2),0, null,
                              to_number(replace(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim), 73, 8),',','')) / 10000 *
                              to_number(replace(substr(NVL (faog.dettaglio_faog, ogim.dettaglio_ogim), 90, 13),',','')) / 100000
                             ) tariffa_var,
                      cate.flag_domestica, ogpr.consistenza mq, faog.dal,
                      faog.al
                 FROM oggetti_pratica ogpr,
                      oggetti_imposta ogim,
                      familiari_ogim faog,
                      categorie cate
                WHERE ogpr.pratica = a_pratica
                  AND ogpr.oggetto_pratica = ogim.oggetto_pratica
                  AND ogim.oggetto_imposta = a_oggetto_imposta
                  AND faog.oggetto_imposta(+) = ogim.oggetto_imposta
                  AND cate.tributo = ogpr.tributo
                  AND cate.categoria = ogpr.categoria
             ORDER BY faog.dal, faog.al;
BEGIN
--06/07/2014 SC se il ruolo ha calcolo tradizionale
--questa funzione deve restituire null
   declare
      w_tipo_calcolo varchar2(1);
   begin
   -- 19/12/14 Betta T. il ruolo da prendere deve essere quello dell''oggetto imposta
   -- non quello della pratica che potrebbe essere la denuncia di 20 anni prima
      select distinct nvl(ruol.tipo_calcolo,'*')
        into w_tipo_calcolo
        from oggetti_imposta ogim,ruoli ruol
       where ogim.oggetto_imposta = a_oggetto_imposta
         and ogim.ruolo = ruol.ruolo
         ;
      /*select distinct nvl(ruol.tipo_calcolo,'*')
        into w_tipo_calcolo
        from pratiche_tributo prtr
           , ruoli_contribuente ruco
           , ruoli ruol
       where prtr.pratica = a_pratica
         and prtr.cod_fiscale = ruco.cod_fiscale
         and ruco.ruolo = ruol.ruolo
         and ruol.anno_ruolo = prtr.anno
         -- and ruol.tipo_emissione in ('T','S')
         and ruol.invio_consorzio is not null
         and ruol.tipo_tributo||'' = 'TARSU' --inutile
       ;*/
       if w_tipo_calcolo = 'T' then
          return null;
       end if;
   exception
   when too_many_rows then
      w_tipo_calcolo := 'N';
      --    select distinct nvl(tipo_calcolo,'*')
      --      into w_tipo_calcolo
      --      from pratiche_tributo prtr
      --         , ruoli_contribuente ruco
      --         , ruoli ruol
      --     where prtr.pratica = a_pratica
      --       and prtr.cod_fiscale = ruco.cod_fiscale
      --       and ruco.ruolo = ruol.ruolo
      --       and ruol.anno_ruolo = prtr.anno
      --       and ruol.invio_consorzio is not null
      --       and ruol.tipo_tributo||'' = 'TARSU' --inutile
      --     ;
      --     if w_tipo_calcolo = 'T' then
      --        return null;
      --     end if;
      --   exception
   when no_data_found then
      null;
   end;
   begin
     select lpad(to_char(pro_cliente),3,'0')||
            lpad(to_char(com_cliente),3,'0')
       into w_cod_istat
       from dati_generali;
   exception
     when others then
       null;
   end;
   -- (VD - 07/05/2019): Selezione flag calcolo imposta (con tariffe o no)
   BEGIN
     select flag_tariffe_ruolo
       into w_flag_tariffe
       from pratiche_tributo prtr,
            carichi_tarsu    cata
      where prtr.pratica = a_pratica
        and prtr.anno    = cata.anno;
   EXCEPTION
     when others then
       w_flag_tariffe := 'N';
   END;
   FOR rec_fam_ogim IN sel_familiari_ogim
   LOOP
      if w_cod_istat = '050029' then -- Pontedera
         IF (w_cont = 1)
         THEN
            w_str_fam_ogim := 'DETTAGLI        :       '|| rec_fam_ogim.note2;
         ELSE
            w_str_fam_ogim := w_str_fam_ogim || w_spazi_var || rec_fam_ogim.note2;
         END IF;
      ELSE
         IF rec_fam_ogim.flag_domestica IS NULL
         THEN
            w_str_mq_fissa :=
                            ' Mq' || TO_CHAR (ROUND (rec_fam_ogim.mq), 'B99999');
            w_str_mq_var := ' Mq' || TO_CHAR (ROUND (rec_fam_ogim.mq), 'B99999');
            if rec_fam_ogim.flag_tipo_riga = '*' and
               instr(rec_fam_ogim.dettaglio_fissa,'Coeff.') = 0 then
               w_coeff_fissa := 'QF: Euro/Mq';
               w_coeff_var   := 'QV: Euro/Mq';
            else
               w_coeff_fissa := 'Kc.';
               w_coeff_var := 'Kd.';
            end if;
         ELSE
            w_str_mq_fissa :=
                            ' Mq' || TO_CHAR (ROUND (rec_fam_ogim.mq), 'B99999');
            w_str_mq_var := '        ';
            if rec_fam_ogim.flag_tipo_riga = '*' and
               instr(rec_fam_ogim.dettaglio_fissa,'Coeff.') = 0 then
               w_coeff_fissa := 'QF: Euro/Mq';
               w_coeff_var   := 'QV: Euro   ';
            else
               w_coeff_fissa := 'Ka.';
               w_coeff_var := 'Kb.';
            end if;
         END IF;
         if rec_fam_ogim.flag_tipo_riga = '*' and
            instr(rec_fam_ogim.dettaglio_fissa,'Coeff.') = 0 then
            w_str_dett_fam_fissa :=
                  REPLACE (rec_fam_ogim.dettaglio_fissa, 'Tariffa', w_coeff_fissa);
            w_str_dett_fam_var :=
                  REPLACE (rec_fam_ogim.dettaglio_var, 'Tariffa', w_coeff_var);
         else
            IF instr(rec_fam_ogim.dettaglio_fissa,'Coeff.') = 0
            THEN
               w_str_dett_fam_fissa := '';
               w_str_dett_fam_var := '';
            ELSE
            --if w_cod_istat = '050029' then -- Pontedera
            --   w_str_dett_fam_fissa := '';
            --   w_str_dett_fam_var   := '';
            --   w_str_dett_fam_fissa := 'Tariffa QF: '||translate(ltrim(to_char(to_number(rec_fam_ogim.tariffa_fissa),'999,990.00000')),',.','.,');
            --   w_str_dett_fam_var   := 'Tariffa QV: '||translate(ltrim(to_char(to_number(rec_fam_ogim.tariffa_var),'999,990.00000')),',.','.,');
            --   w_str_dett_fam_fissa := 'Tariffa QF: '||to_char(to_number(rec_fam_ogim.tariffa_fissa),'999,990.00000');
            --   w_str_dett_fam_var   := 'Tariffa QV: '||translate(ltrim(to_char(rec_fam_ogim.tariffa_var,'999,990.00000')),',.','.,');
            --else
               w_str_dett_fam_fissa :=
                     REPLACE (rec_fam_ogim.dettaglio_fissa, 'Coeff.', w_coeff_fissa)
                     -- abbiamo spostato la consistenza nella stampa
                     --           || w_str_mq_fissa
                  ;
               w_str_dett_fam_var :=
                     REPLACE (rec_fam_ogim.dettaglio_var, 'Coeff.', w_coeff_var)
            --      || w_str_mq_var
                  ;
            --end if;
            end if;
         END IF;
         IF (w_cont = 1)
         THEN
            w_str_fam_ogim :=
                  'DETTAGLI        :       '
               || rec_fam_ogim.note2;
            if w_str_dett_fam_fissa is not null
            then
               if rec_fam_ogim.note2 is not null then
                  w_str_fam_ogim := RTRIM(w_str_fam_ogim)|| w_spazi_var
                  || LTRIM(w_str_dett_fam_fissa)
                  || w_a_capo;
               else
                  w_str_fam_ogim := w_str_fam_ogim
                  || LTRIM(w_str_dett_fam_fissa)
                  || w_a_capo;
               end if;
               --w_str_fam_ogim := w_str_fam_ogim
               --|| w_str_dett_fam_fissa
               --|| w_a_capo;
            end if;
         ELSE
            w_str_fam_ogim :=
                  w_str_fam_ogim
               || w_a_capo
               || w_spazi_var
               || rec_fam_ogim.note2;
            if w_str_dett_fam_fissa is not null
            then
               w_str_fam_ogim := w_str_fam_ogim|| substr(w_spazi_var, 1, length(w_spazi_var)-1)
               || LTRIM(w_str_dett_fam_fissa)
               --|| w_str_dett_fam_fissa
               || w_a_capo;
            end if;
         END IF;
         if rec_fam_ogim.note2 is not null then
            w_str_fam_ogim := w_str_fam_ogim|| w_spazi_var
                           || w_str_dett_fam_var;
         else
            w_str_fam_ogim := w_str_fam_ogim|| w_spazi_var --substr(w_spazi_var, 1, length(w_spazi_var)-1)
                           || w_str_dett_fam_var;
         end if;
      END IF;
      w_cont := w_cont + 1;
   END LOOP;
   --
   if ltrim(rtrim(w_str_fam_ogim)) = 'DETTAGLI        :' then
      w_str_fam_ogim := '';
   end if;
   --
   RETURN w_str_fam_ogim;
END;
/* End Function: F_GET_DETTAGLI_ACC_TARSU_OGIM */
/

