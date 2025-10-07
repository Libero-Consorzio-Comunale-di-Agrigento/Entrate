--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_periodo stripComments:false runOnChange:true 
 
create or replace function F_PERIODO
/******************************************************************************
   Rev. Data       Autore Descrizione
   ---- ---------- ------ -----------------------------------------------------
    1   06/07/2016 AB     Gestito w_gg_anno contentente i gg dell'anno
                          sulla base dell'ultimo giorno del mese di Febbraio
******************************************************************************/
(a_anno              IN number,
 a_data_decorrenza   IN date,
 a_data_cessazione   IN date,
 a_tipo_occupazione  IN varchar2,
 a_tipo_tributo      IN varchar2,
 a_flag_normalizzato IN varchar2)
 RETURN NUMBER
IS
w_dec_temp  date;
w_cess_temp date;
w_giorno    number;
w_mese      number;
w_periodo   number;
w_mesi_calcolo number;
w_comune    varchar2(6);
w_mm_inizio number;
w_mm_fine   number;
w_periodo_ceil number;
w_periodo_trunc number;
w_periodo_round number;
w_gg_anno number;
BEGIN  -- F_PERIODO
   BEGIN
      select lpad(to_char(pro_cliente),3,'0')
          || lpad(to_char(com_cliente),3,'0'),
             decode(to_char(last_day(to_date('02'||a_anno,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366))
        into w_comune,
             w_gg_anno
        from dati_generali
        ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
      Return 0;
   END;
   if a_tipo_tributo <> 'TARSU' then
      w_mesi_calcolo := 2;
   else
      begin
         select nvl(mesi_calcolo,2)
           into w_mesi_calcolo
           from carichi_tarsu
          where anno = a_anno
         ;
      exception
         when no_data_found then
            w_mesi_calcolo := 2;
      end;
   end if;
   --Mesi calcolo = 0 significa che dobbiamo calcolare la TARES giornalmente.
   --per ora questo calcolo viene fatto solo x il normalizzato
   --quindi assegno mesi_calcolo a 2 per non cambiare il calcolo tradizionale
   if w_mesi_calcolo = 0
      and a_flag_normalizzato is null then
      w_mesi_calcolo := 2;
   end if;
   w_dec_temp     := nvl(a_data_decorrenza,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_dec_temp     := greatest(w_dec_temp,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_cess_temp    := nvl(a_data_cessazione,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
   w_cess_temp    := least(w_cess_temp,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
--  dbms_output.put_line('w_dec_temp '||to_char(w_dec_temp,'dd/mm/yyyy')||' w_cess_temp '||to_char(w_cess_temp,'dd/mm/yyyy'));
   IF w_dec_temp  > to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
   OR w_cess_temp < to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
      Return 0;
   END IF;
   --Particolarita` per Pontassieve che calcola i bimestri anche per TOSAP
   if a_tipo_tributo = 'TOSAP' and a_tipo_occupazione <> 'T' and w_comune = '048033' then
      w_mm_inizio := to_number(to_char(w_dec_temp,'mm'));
      w_mm_fine   := to_number(to_char(w_cess_temp,'mm'));
      if w_mm_inizio in (2,4,6,8,10,12) then
         w_mm_inizio := w_mm_inizio - 1;
      end if;
      if w_mm_fine in (1,3,5,7,9,11) then
         w_mm_fine := w_mm_fine + 1;
      end if;
      w_periodo := w_mm_fine + 1 - w_mm_inizio;
      w_periodo := w_periodo / 12;
      Return w_periodo;
   end if;
   IF  a_tipo_tributo       = 'TARSU'
   and a_tipo_occupazione  <> 'T'
   and a_flag_normalizzato is null THEN
      w_mese    := to_number(to_char(w_dec_temp,'MM'));
      w_giorno  := to_number(to_char(w_dec_temp,'DD'));
      if w_mesi_calcolo = 2 then
         IF w_dec_temp > to_date('0111'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
            w_dec_temp := to_date('0101'||lpad(to_char(a_anno + 1),4,'0'),'ddmmyyyy');
         ELSIF NOT (w_giorno = 01 AND mod(w_mese,2) = 1) THEN
-- Se Mese pari allora si parte dal mese successivo altrimenti dal bimestre successivo
           w_mese :=  w_mese + mod(w_mese,2) + 1;
           w_dec_temp := to_date('01'||lpad(to_char(w_mese),2,0)||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
         END IF;
       else
       --w_mesi_calcolo != 2
         IF w_dec_temp > to_date('0112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
            w_dec_temp := to_date('0101'||lpad(to_char(a_anno + 1),4,'0'),'ddmmyyyy');
         ELSIF NOT (w_giorno = 01) THEN
           w_mese :=  w_mese + 1;
           w_dec_temp := to_date('01'||lpad(to_char(w_mese),2,0)||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
         END IF;
       end if;
   END IF;
   IF a_tipo_tributo       = 'TARSU'
   and a_tipo_occupazione  <> 'T'
   and a_flag_normalizzato is null THEN
       w_mese   := to_number(to_char(w_cess_temp+1,'MM'));
       w_giorno := to_number(to_char(w_cess_temp+1,'DD'));
       if w_mesi_calcolo = 2 then
          IF w_cess_temp + 1 > to_date('0111'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
             w_cess_temp := to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
          ELSIF NOT (w_giorno = 01 AND mod(w_mese,2) = 1) THEN
-- Se Mese pari allora si parte dal mese successivo altrimenti dal bimestre successivo
             w_mese :=  w_mese + mod(w_mese,2) + 1;
             w_cess_temp := to_date('01'||lpad(to_char(w_mese),2,0)||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') - 1;
          END IF;
       else
          IF w_cess_temp + 1 > to_date('0112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') THEN
             w_cess_temp := to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
          ELSIF NOT (w_giorno = 01) THEN
             w_mese :=  w_mese + 1;
             w_cess_temp := to_date('01'||lpad(to_char(w_mese),2,0)||lpad(to_char(a_anno),4,'0'),'ddmmyyyy') - 1;
          END IF;
       end if;
    END IF;
    IF a_tipo_occupazione = 'P' THEN
       if a_tipo_tributo =  'TARSU' and w_mesi_calcolo = 0 then
         w_periodo := (w_cess_temp - w_dec_temp + 1) / w_gg_anno;
        w_periodo_ceil := ceil(months_between(w_cess_temp,w_dec_temp))/12;
        w_periodo_trunc := trunc(months_between(w_cess_temp,w_dec_temp))/12;
        w_periodo_round := round(months_between(w_cess_temp,w_dec_temp))/12;
--         dbms_output.put_line('mesi_ calcolo = 0: w_dec_temp '||w_dec_temp||' w_cess_temp '||w_cess_temp||' w_periodo_ceil '||w_periodo_ceil||' w_periodo_trunc '||w_periodo_trunc||' w_periodo_round '||w_periodo_round);
       else
          if a_flag_normalizzato is null then
--             dbms_output.put_line('mesi_ calcolo = 0: w_dec_temp '||w_dec_temp||' w_cess_temp '||w_cess_temp||' w_periodo_ceil '||w_periodo_ceil||' w_periodo_trunc '||w_periodo_trunc||' w_periodo_round '||w_periodo_round);
             w_periodo := ceil(months_between(w_cess_temp,w_dec_temp))/12;
--             dbms_output.put_line('mesi_ calcolo <> 0: w_dec_temp '||w_dec_temp||' w_cess_temp '||w_cess_temp||' w_periodo '||w_periodo||' ceil '||ceil(months_between(w_cess_temp,w_dec_temp)));
          else
             w_periodo := round(months_between(w_cess_temp,w_dec_temp))/12;  --mettiamo la round per il normalizzato 12/11/13 AB e PM
          end if;
       end if;
    ELSE
           w_periodo := w_cess_temp - w_dec_temp + 1;
    END IF;
--            dbms_output.put_line('return: w_dec_temp '||to_date(w_dec_temp,'dd/mm/yyyy')||' w_cess_temp '||to_date(w_cess_temp,'dd/mm/yyyy')||' w_periodo '||w_periodo);
    return w_periodo;
END;
/* End Function: F_PERIODO */
/

