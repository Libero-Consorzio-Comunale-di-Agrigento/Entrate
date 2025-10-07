--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_raim stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_RAIM
(a_cod_fiscale      IN varchar2
,a_ogim             IN number
,a_data             IN date
,a_importo          IN number
,a_tipo_tributo     IN varchar2
,a_conto_corrente   IN number
,a_data_concessione IN date
,a_anno             IN number
,a_utente           IN varchar2
,a_importo_versato  IN OUT number
) IS
errore             exception;
fine               exception;
w_scad_1           date;
w_scad_2           date;
w_scad_3           date;
w_scad_4           date;
w_scad             date;
--w_dep_scad         date; --INUTILE
w_importo_1        number;
w_importo_2        number;
w_importo_3        number;
w_importo_4        number;
w_importo          number;
w_residuo          number;
w_importo_round_1  number;
w_importo_round_2  number;
w_importo_round_3  number;
w_importo_round_4  number;
w_importo_round    number;
w_residuo_round    number;
w_tot_rate         number;
--w_tot_importo      number; --MAI USATA
w_rata             number;
w_p0               varchar2(2);
w_res              varchar2(2);
w_err              varchar2(2000);
w_min_rata         number;
w_max_rata         number;
w_ind              number;
w_rata_imposta     number;
w_round            varchar2(1);
-- (VD - 18/06/2020): modifiche per Belluno
w_cod_belluno      varchar2(6) := '108009'; --'025006';
w_cod_cliente      varchar2(6);
w_tot_versato      number;
w_tot_interessi    number;
w_importo_base     number;
w_data_iniz        date;
w_data_fine        date;
w_importo_rata     number;
cursor sel_scad (p_tipo_tributo varchar2
               , p_anno number
               , p_0 varchar2) is
select scad.rata
     , scad.data_scadenza
  from scadenze scad
 where scad.tipo_tributo   = p_tipo_tributo
   and scad.anno           = p_anno
   and scad.rata     between decode(p_0
                                      , 'SI', 0
                                      , 1)
                         and decode(p_0
                                      , 'SI',0,4)
   and scad.tipo_scadenza  = 'V'
   and scad.rata           < 5
;
BEGIN
  w_err := null;
  BEGIN
     select lpad(to_char(pro_cliente),3,'0')||
            lpad(to_char(com_cliente),3,'0')
       into w_cod_cliente
       from dati_generali
          ;
  EXCEPTION
    WHEN OTHERS THEN
      w_err := 'Errore in selezione dati comune';
      RAISE ERRORE;
  END;
  BEGIN
    select max(scad.rata)
      into w_tot_rate
      from scadenze scad
     where scad.tipo_tributo = a_tipo_tributo
       and scad.anno         = a_anno
    ;
  EXCEPTION
    WHEN OTHERS THEN
       w_err := 'Errore in Conteggio Rate Imposta ('||SQLERRM||')';
       RAISE ERRORE;
  END;
  if w_tot_rate = 0 then
  --Pagamento in un'unica soluzione
     w_p0 := 'SI';
     w_tot_rate := 1;
  else
     w_p0 := 'NO';
  end if;
  begin
    select decode(a_tipo_tributo
                  ,'TARSU',flag_tariffa
                  ,'ICP',flag_canone
                  ,'TOSAP',flag_canone
                  ,null)
      into w_round
      from tipi_tributo
     where tipo_tributo = a_tipo_tributo
        ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       w_round := null;
    WHEN OTHERS THEN
       w_round := null;
  end;
  w_scad_1 := to_date('31122999','ddmmyyyy');
  w_scad_2 := to_date('31122999','ddmmyyyy');
  w_scad_3 := to_date('31122999','ddmmyyyy');
  w_scad_4 := to_date('31122999','ddmmyyyy');
  FOR rec_scad in sel_scad (a_tipo_tributo,a_anno,w_p0)
  LOOP
      if    rec_scad.rata in (0,1) then
            w_scad_1 := rec_scad.data_scadenza;
      elsif rec_scad.rata = 2 then
            w_scad_2 := rec_scad.data_scadenza;
      elsif rec_scad.rata = 3 then
            w_scad_3 := rec_scad.data_scadenza;
      else
            w_scad_4 := rec_scad.data_scadenza;
      end if;
  END LOOP;
  if a_data > w_scad_4 then
  --a_data = data di decorrenza
     w_scad_1 := to_date('31122999','ddmmyyyy');
     w_scad_2 := to_date('31122999','ddmmyyyy');
     w_scad_3 := to_date('31122999','ddmmyyyy');
     if a_data_concessione is null then
        w_scad_4 := to_date('31122999','ddmmyyyy');
        w_tot_rate := 0;
     else
        w_scad_4 := a_data_concessione;
        w_tot_rate := 1;
     end if;
  elsif a_data > w_scad_3 then
     w_scad_1 := to_date('31122999','ddmmyyyy');
     w_scad_2 := to_date('31122999','ddmmyyyy');
     w_scad_3 := to_date('31122999','ddmmyyyy');
     --(VD - 06/08/2020): corretta determinazione rate residue
     --w_tot_rate := 1;
     w_tot_rate := greatest(1,w_tot_rate - 3);
  elsif a_data > w_scad_2 then
     w_scad_1 := to_date('31122999','ddmmyyyy');
     w_scad_2 := to_date('31122999','ddmmyyyy');
     --(VD - 06/08/2020): corretta determinazione rate residue
     --w_tot_rate := 2;
     w_tot_rate := greatest(1,w_tot_rate - 2);
  elsif a_data > w_scad_1 then
     w_scad_1 := to_date('31122999','ddmmyyyy');
     --(VD - 06/08/2020): corretta determinazione rate residue
     --w_tot_rate := 3;
     w_tot_rate := greatest(1,w_tot_rate - 1);
  end if;
  if w_tot_rate = 0 then
     RAISE FINE;
  end if;
  if w_tot_rate = 1 then
     w_importo := 0;
     w_residuo := a_importo;
     w_importo_round := 0;
     w_residuo_round := round(a_importo,0);
  else
     w_importo := f_round(a_importo / w_tot_rate,1);
     w_residuo := a_importo - w_importo * (w_tot_rate - 1);
     w_importo_round := round(a_importo / w_tot_rate,0);
     w_residuo_round := round(a_importo) - w_importo_round * (w_tot_rate - 1);
  end if;
  w_importo_1 := 0;
  w_importo_2 := 0;
  w_importo_3 := 0;
  w_importo_4 := 0;
  w_min_rata  := 9;
  w_max_rata  := 0;
  w_ind := 0;
  w_res := 'SI';
  w_importo_round_1 := 0;
  w_importo_round_2 := 0;
  w_importo_round_3 := 0;
  w_importo_round_4 := 0;
  loop
     w_ind := w_ind + 1;
     if w_ind > 4 then
        exit;
     end if;
     if w_ind = 1 and w_scad_1 <> to_date('31122999','ddmmyyyy') then
        if w_res = 'SI' then
           w_res := 'NO';
           w_importo_1 := w_residuo;
           w_importo_round_1 := w_residuo_round;
        else
           w_importo_1 := w_importo;
           w_importo_round_1 := w_importo_round;
        end if;
        if w_ind < w_min_rata then
           w_min_rata := w_ind;
        end if;
        if w_ind > w_max_rata then
           w_max_rata := w_ind;
        end if;
     end if;
     if w_ind = 2 and w_scad_2 <> to_date('31122999','ddmmyyyy') then
        if w_res = 'SI' then
           w_res := 'NO';
           w_importo_2 := w_residuo;
           w_importo_round_2 := w_residuo_round;
        else
           w_importo_2 := w_importo;
           w_importo_round_2 := w_importo_round;
        end if;
        if w_ind < w_min_rata then
           w_min_rata := w_ind;
        end if;
        if w_ind > w_max_rata then
           w_max_rata := w_ind;
        end if;
     end if;
     if w_ind = 3 and w_scad_3 <> to_date('31122999','ddmmyyyy') then
        if w_res = 'SI' then
           w_res := 'NO';
           w_importo_3 := w_residuo;
           w_importo_round_3 := w_residuo_round;
        else
           w_importo_3 := w_importo;
           w_importo_round_3 := w_importo_round;
        end if;
        if w_ind < w_min_rata then
           w_min_rata := w_ind;
        end if;
        if w_ind > w_max_rata then
           w_max_rata := w_ind;
        end if;
     end if;
     if w_ind = 4 and w_scad_4 <> to_date('31122999','ddmmyyyy') then
        if w_res = 'SI' then
           w_res := 'NO';
           w_importo_4 := w_residuo;
           w_importo_round_4 := w_residuo_round;
        else
           w_importo_4 := w_importo;
           w_importo_round_4 := w_importo_round;
        end if;
        if w_ind < w_min_rata then
           w_min_rata := w_ind;
        end if;
        if w_ind > w_max_rata then
           w_max_rata := w_ind;
        end if;
     end if;
  end loop;
  --Trattamento della Data di Concessione.
  if a_data_concessione is not null then
     if    w_min_rata = 1 then
           --w_dep_scad := w_scad_1;
           w_scad_1 := to_date('0101'||to_char(w_scad_1,'yyyy'),'ddmmyyyy');
     elsif w_min_rata = 2 then
           --w_dep_scad := w_scad_2;
           w_scad_2 := to_date('0101'||to_char(w_scad_2,'yyyy'),'ddmmyyyy');
     elsif w_min_rata = 3 then
           --w_dep_scad := w_scad_3;
           w_scad_3 := to_date('0101'||to_char(w_scad_3,'yyyy'),'ddmmyyyy');
     else
           --w_dep_scad := w_scad_4;
           w_scad_4 := to_date('0101'||to_char(w_scad_4,'yyyy'),'ddmmyyyy');
     end if;
     w_ind := w_max_rata + 1;
     loop
        w_ind := w_ind - 1;
        if w_ind < w_min_rata then
           exit;
        end if;
        if    w_ind = 1 then
              w_importo := w_importo_1;
              w_importo_round := w_importo_round_1;
              w_scad    := w_scad_1;
        elsif w_ind = 2 then
              w_importo := w_importo_2;
              w_importo_round := w_importo_round_2;
              w_scad    := w_scad_2;
        elsif w_ind = 3 then
              w_importo := w_importo_3;
              w_importo_round := w_importo_round_3;
              w_scad    := w_scad_3;
        else
              w_importo := w_importo_4;
              w_importo_round := w_importo_round_4;
              w_scad    := w_scad_4;
        end if;
        if a_data_concessione > w_scad then
           if    w_ind = 4 then
                 w_importo_4 := w_importo_1 + w_importo_2 + w_importo_3 + w_importo_4;
                 w_importo_round_4 := w_importo_round_1 + w_importo_round_2 + w_importo_round_3 + w_importo_round_4;
                 w_scad_1 := to_date('31122999','ddmmyyyy');
                 w_scad_2 := to_date('31122999','ddmmyyyy');
                 w_scad_3 := to_date('31122999','ddmmyyyy');
                 w_scad_4 := a_data_concessione;
           elsif w_ind = 3 then
                 w_importo_3 := w_importo_1 + w_importo_2 + w_importo_3;
                 w_importo_round_3 := w_importo_round_1 + w_importo_round_2 + w_importo_round_3;
                 w_scad_1 := to_date('31122999','ddmmyyyy');
                 w_scad_2 := to_date('31122999','ddmmyyyy');
                 w_scad_3 := a_data_concessione;
           elsif w_ind = 2 then
                 w_importo_2 := w_importo_1 + w_importo_2;
                 w_importo_round_2 := w_importo_round_1 + w_importo_round_2;
                 w_scad_1 := to_date('31122999','ddmmyyyy');
                 w_scad_2 := a_data_concessione;
           else
                 w_scad_1 := a_data_concessione;
           end if;
           exit;
        end if;
     end loop;
  end if;
  -- (VD - 18/06/2020): Belluno. Solo per la TOSAP, si calcolano gli interessi
  --                    sulla seconda rata tenendo conto di eventuali versamenti.
  --                    Gli interessi calcolati si sommano all'imposta
  --                    dell'oggetto con imposta maggiore
  if w_cod_cliente = w_cod_belluno and
     a_tipo_tributo in ('ICP', 'TOSAP') then
     w_tot_versato := a_importo_versato;
  else
     w_tot_versato := 0;
  end if;
  w_ind := 0;
  loop
     w_ind := w_ind + 1;
     if w_ind > 4 then
        exit;
     end if;
     if    w_ind = 1 then
           w_importo := w_importo_1;
           w_importo_round := w_importo_round_1;
           w_scad    := w_scad_1;
     elsif w_ind = 2 then
           w_importo := w_importo_2;
           w_importo_round := w_importo_round_2;
           w_scad    := w_scad_2;
     elsif w_ind = 3 then
           w_importo := w_importo_3;
           w_importo_round := w_importo_round_3;
           w_scad    := w_scad_3;
     else
           w_importo := w_importo_4;
           w_importo_round := w_importo_round_4;
           w_scad    := w_scad_4;
     end if;
     if w_scad <> to_date('31122999','ddmmyyyy') then
        if w_ind = 1 then
           if w_p0 = 'SI' then
              w_rata := 0;
           else
              w_rata := 1;
           end if;
        else
           w_rata := w_ind;
        end if;
        if w_round is not null or a_anno < 2007 then
           w_importo_round := null;
        end if;
        -- (VD - 18/06/2020): Belluno. Se si sta trattando l'ultima rata,
        --                    si calcolano gli interessi legali e si sommano
        --                    all'imposta dell'oggetto con imposta maggiore
        w_tot_interessi := 0;
        if w_cod_cliente = w_cod_belluno and
           a_tipo_tributo in ('ICP', 'TOSAP') then
           if w_rata < w_max_rata then
              w_data_iniz := w_scad;
              if w_tot_versato > w_importo then
                 w_tot_versato := w_tot_versato - w_importo;
              else
                 w_tot_versato := 0;
              end if;
           else
              w_data_fine := w_scad;
              w_importo_base := w_importo;
              if w_tot_versato > 0 then
                 if w_tot_versato < w_importo then
                    w_importo_base := w_importo_base - w_tot_versato;
                    w_tot_versato := 0;
                 else
                    w_importo_base := 0;
                    w_tot_versato := w_tot_versato - w_importo;
                 end if;
              end if;
              if a_tipo_tributo = 'TOSAP' and w_importo_base > 0 then
                 for sel_int in (select inte.aliquota
                                      , greatest(inte.data_inizio,w_data_iniz) dal
                                      , least(inte.data_fine,w_data_fine) al
                                  from interessi inte
                                 where inte.tipo_tributo      = a_tipo_tributo
                                   and inte.data_inizio      <= w_data_fine
                                   and inte.data_fine        >= w_data_iniz
                                   and inte.tipo_interesse    = 'L'
                                 order by 2)
                 loop
                   w_tot_interessi := w_tot_interessi +
                                      round(w_importo_base * nvl(sel_int.aliquota,0) / 100 *
                                      (sel_int.al - sel_int.dal) / 365,2);
                 end loop;
              end if;
           end if;
           w_importo_rata := w_importo;
           w_importo := w_importo + w_tot_interessi;
           if w_tot_interessi > 0 then
              if a_ogim is null then
                 update oggetti_imposta ogim
                    set ogim.imposta = ogim.imposta + w_tot_interessi
                      , note = note||decode(note,'','',' - ')||'Interessi rata '||
                               w_rata||': '||to_char(w_tot_interessi,'999G990D00')||
                               ', Imposta prec.: '||to_char(ogim.imposta,'999G990D00')
                  where ogim.tipo_tributo = a_tipo_tributo
                    and ogim.cod_fiscale  = a_cod_fiscale
                    and ogim.anno         = a_anno
                    and ogim.utente       = '###'
                    and ogim.oggetto_imposta = (select max(y.oggetto_imposta)
                                                  from oggetti_imposta y
                                                 where y.tipo_tributo = a_tipo_tributo
                                                   and y.cod_fiscale = a_cod_fiscale
                                                   and y.anno = a_anno
                                                   and y.utente = '###'
                                                   and y.imposta = (select max(x.imposta)
                                                                      from oggetti_imposta x
                                                                     where x.tipo_tributo = a_tipo_tributo
                                                                       and x.cod_fiscale = a_cod_fiscale
                                                                       and x.anno = a_anno
                                                                       and x.utente = '###'
                                                                   )
                                                );
              else
                 update oggetti_imposta
                    set imposta = imposta + w_tot_interessi
                      , note = note||decode(note,'','',' - ')||'Interessi rata '||
                               w_rata||': '||to_char(w_tot_interessi,'999G990D00')||
                               ', Imposta prec.: '||to_char(imposta,'999G990D00')
                  where oggetto_imposta = a_ogim;
              end if;
           end if;
        end if;
        w_rata_imposta := null;
        RATE_IMPOSTA_NR(w_rata_imposta);
        insert into rate_imposta(rata_imposta
                               , cod_fiscale
                               , anno
                               , tipo_tributo
                               , rata
                               , oggetto_imposta
                               , imposta
                               , imposta_round
                               , conto_corrente
                               , note
                               , utente)
        values(w_rata_imposta
             , a_cod_fiscale
             , a_anno
             , a_tipo_tributo
             , w_rata
             , a_ogim
             , w_importo
             , w_importo_round
             , a_conto_corrente
             , decode(w_tot_interessi
                     ,0,''
                       ,'Interessi: '||to_char(w_tot_interessi,'990D99')||
                        ', Rata prec.: '||to_char(w_importo_rata,'999G990D00')||
                        ', Importo base: '||to_char(w_importo_base,'999G990D00'))
             , a_utente)
        ;
     end if;
  end loop;
  --
  a_importo_versato := w_tot_versato;
EXCEPTION
   WHEN FINE THEN
      null;
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_err);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: INSERIMENTO_RAIM */
/

