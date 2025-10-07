--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_numero_familiari_al_faso stripComments:false runOnChange:true 
 
create or replace function F_NUMERO_FAMILIARI_AL_FASO
/*************************************************************************
 NOME:        F_NUMERO_FAMILIARI_AL_FASO
 DESCRIZIONE: Dati un soggetto e una data, determina il numero dei
              familiari del soggetto alla data indicata, tenendo conto
              dell'eventuale integrazione con i demografici
 RITORNA:     number              Numero familiari
 NOTE:
 Rev.    Date         Author      Note
 000     01/12/2008               Prima emissione.
*************************************************************************/
( a_ni              IN number,
  a_data            IN date
)
RETURN number
IS
  familiari              number(3) := 0;
  w_matricola              number;
  w_conta_anaeve           number;
  w_componenti             number := 0;
  w_componenti_ana       number := 0;
  w_componenti_eve       number := 0;
  w_cod_fam                  number := 0;
  w_cod_mov                  number := 0;
  w_fascia                   number := 0;
  w_tipo_residente       number;
BEGIN
  BEGIN
    select fascia,cod_fam,matricola,tipo_residente
      into w_fascia,w_cod_fam,w_matricola,w_tipo_residente
      from soggetti
     where ni         = a_ni
     -- and tipo_residente = 0
    ;
  EXCEPTION
    WHEN others THEN
    RETURN -1;
  END;
  IF w_tipo_residente = 1 THEN
     BEGIN
       select numero_familiari
           into familiari
           from familiari_soggetto
          where ni = a_ni
          and a_data between dal and nvl(al,to_date('31129999','ddmmyyyy'))
         ;
     EXCEPTION
       when no_data_found then
           familiari := 2;
       when others then
           familiari := 2;
     END;
     RETURN familiari;
  END IF;
  BEGIN
   select count(*)
     into w_conta_anaeve
     from anaeve
    ;
  EXCEPTION
    WHEN others THEN
    RETURN -1;
  END;
  IF a_data is null or w_conta_anaeve = 0 THEN
    IF w_fascia in (1,3) THEN
       BEGIN
         select count(ni)
           into familiari
           from soggetti a
          where a.fascia  = w_fascia
            and a.cod_fam = w_cod_fam
         ;
       EXCEPTION
         WHEN OTHERS THEN
              RETURN -1;
       END;
    END IF;
    RETURN familiari;
  ELSE
    begin
      select ana.fascia, decode(ana.fascia,1,10,12), ana.cod_fam
        into w_fascia, w_cod_mov, w_cod_fam
        from anaana ana
       where ana.matricola   = w_matricola
         and ana.data_inizio_fam <= to_char(a_data,'j')
           and ana.data_inizio_fam is not null
      ;
    exception
      when no_data_found then
          w_cod_fam := 0;
      when others then
          w_cod_fam := 0;
    end;
    if w_cod_fam = 0 then
       begin
         select decode(eve.cod_mov, 10, 1, 3), eve.cod_mov, eve.cod_fam
           into w_fascia, w_cod_mov, w_cod_fam
           from anaeve eve
          where eve.matricola   = w_matricola
              and to_char(a_data,'j') between eve.data_inizio and eve.data_eve
            and eve.cod_mov    in (10,12)
         ;
       exception
         when no_data_found then
             w_cod_fam := 0;
         when others then
             w_cod_fam := 0;
       end;
    end if;
    if w_cod_fam > 0 then
       begin
         select count(*)
             into w_componenti_ana
             from anaana ana
            where ana.cod_fam = w_cod_fam
              and ana.fascia  = w_fascia
              and ana.data_inizio_fam <= to_char(a_data,'j')
         ;
       exception
         when no_data_found then
           w_componenti_ana := 0;
         when others then
           w_componenti_ana := 0;
       end;
       begin
         select count(*)
             into w_componenti_eve
             from anaeve eve
            where eve.cod_fam = w_cod_fam
              and eve.cod_mov = w_cod_mov
              and to_char(a_data,'j') between eve.data_inizio and eve.data_eve
         ;
       exception
         when no_data_found then
           w_componenti_eve := 0;
         when others then
           w_componenti_eve := 0;
       end;
       w_componenti := w_componenti_ana + w_componenti_eve;
    end if;
    return w_componenti;
  END IF;
END;
/* End Function: F_NUMERO_FAMILIARI_AL_FASO */
/

