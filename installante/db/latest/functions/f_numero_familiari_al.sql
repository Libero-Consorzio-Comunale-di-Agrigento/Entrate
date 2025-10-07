--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_numero_familiari_al stripComments:false runOnChange:true 
 
create or replace function F_NUMERO_FAMILIARI_AL
(a_ni           IN number,
 a_data         IN date,
 a_conta_anaeve IN number default 1
)
RETURN number
IS
familiari             number(3) := 0;
w_matricola          number;
w_conta_anaeve       number;
w_componenti       number := 0;
w_componenti_ana    number := 0;
w_componenti_eve    number := 0;
w_cod_fam          number := 0;
w_cod_mov          number := 0;
w_fascia          number := 0;
w_cod_istat   varchar2(6);
-- 09/12/14 - AB Aggiunto il nuovo parametro a_conta_anaeve
-- 23/09/14 - Betta T. Aggiunto test su cliente S.Donato per non fare la select count(*) da ANAEVE
BEGIN
   BEGIN
     select lpad(to_char(pro_cliente), 3, '0') ||
            lpad(to_char(com_cliente), 3, '0')
       into w_cod_istat
       from dati_generali;
   EXCEPTION
     WHEN others THEN
       null;
   END;
     BEGIN
    select fascia,cod_fam,matricola
      into w_fascia,w_cod_fam,w_matricola
      from soggetti
     where ni         = a_ni
       and tipo_residente = 0
    ;
  EXCEPTION
    WHEN others THEN
    RETURN -1;
  END;
--  aggiunto il nuovo parametro a_conta_anaeve in modo da fare l'operazione una sola volta prima del lancio della funztion AB 09/12/!4
     w_conta_anaeve := a_conta_anaeve;
--  if w_cod_istat in ('015192') then --S. Donato
--     w_conta_anaeve := 1;
--     -- a S. Donato abbiamo problemi di lentezza e sappiamo che anaeve è piena
--     -- quindi ci risparmiamo la select count
--  else
--     BEGIN
--      select count(*)
--        into w_conta_anaeve
--        from anaeve
--       ;
--     EXCEPTION
--       WHEN others THEN
--       RETURN -1;
--     END;
--  end if;
  IF a_data is null or w_conta_anaeve = 0 or
     w_cod_istat in ('048033'        --Pontassieve
                    ,'052028'        --San Gimignano
                     ) THEN
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
      if a_data is not null then
        select nvl(familiari,0) - nvl(count(ni),0)
        into   familiari
        from   soggetti a
        where  a.fascia = w_fascia
        and    a.cod_fam = w_cod_fam
        and    a.data_ult_eve > a_data
        ;
        select nvl(familiari,0) + nvl(count(ni),0)
        into   familiari
        from   soggetti a
        where  a.fascia = decode(w_fascia,1,2,3,4)
        and    a.cod_fam = w_cod_fam
        and    a.data_ult_eve > a_data
        ;
      end if;
    ELSE -- fascia not in (1,3)
      BEGIN
         select count(ni)
           into familiari
           from soggetti a
          where a.fascia  = decode(w_fascia,2,1,4,2)
            and a.cod_fam = w_cod_fam
         ;
       EXCEPTION
         WHEN OTHERS THEN
              RETURN -1;
       END;
      if a_data is not null then
        select nvl(familiari,0) - nvl(count(ni),0)
        into   familiari
        from   soggetti a
        where  a.fascia = decode(w_fascia,2,1,4,2)
        and    a.cod_fam = w_cod_fam
        and    a.data_ult_eve > a_data
        ;
        select nvl(familiari,0) + nvl(count(ni),0)
        into   familiari
        from   soggetti a
        where  a.fascia = w_fascia
        and    a.cod_fam = w_cod_fam
        and    a.data_ult_eve > a_data
        ;
      end if;
    END IF;
    RETURN familiari;
  ELSE
    begin
      select ana.fascia, decode(ana.fascia,1,10,12), ana.cod_fam
        into w_fascia, w_cod_mov, w_cod_fam
        from anaana ana
       where ana.matricola   = w_matricola
         and ana.data_inizio_fam  <= to_char(a_data,'j')
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
/* End Function: F_NUMERO_FAMILIARI_AL */
/

