--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_residente_al stripComments:false runOnChange:true 
 
create or replace function F_RESIDENTE_AL
(a_ni             in  number
,a_data_rif       in  date
)
return number
IS
w_data_rif        date := a_data_rif;
w_data_rif_j      number := to_char(a_data_rif,'j');
w_matricola       number;
w_fascia          number;
w_stato           number;
w_data_ult_eve    date;
w_count_eve       number;
w_count_eve_matr  number;
w_max_cod_mov     number;
w_residente_al    number;
w_step            number;
begin
  begin
    select matricola, fascia, stato, data_ult_eve
      into w_matricola, w_fascia, w_stato, w_data_ult_eve
      from soggetti
     where ni = a_ni
    ;
    begin
      select 1
        into w_count_eve
       from anaeve
     where rownum = 1
     ;
    exception
      when no_data_found then
       w_count_eve := 0;
    end;
    select count(*)
      into w_count_eve_matr
      from anaeve
     where matricola = w_matricola
       and cod_mov   in (1,2,3,4)
       and data_eve  <= w_data_rif_j
    ;
  exception
    when others then
         w_residente_al := to_number(null);
w_step := 1;
  end;
  if w_fascia is not null and w_stato is not null and w_data_ult_eve is not null then
     if w_fascia not in (1,2,3,4) then
-- soggetti in attesa di iscrizione (fascia = 5) o non residenti (6-80)
        w_residente_al := 0;
w_step := 2;
     elsif w_fascia != 1 and w_data_ult_eve <= w_data_rif then
-- soggetti già cancellati dall'anagrafe (soggetti) nella data di riferimento
        w_residente_al := 0;
w_step := 3;
     elsif w_fascia = 1 and w_data_ult_eve <= w_data_rif then
-- soggetti già residenti in anagrafe (soggetti) nella data di riferimento
        w_residente_al := 1;
w_step := 4;
     elsif w_fascia = 1 and w_data_ult_eve > w_data_rif and w_stato = 1 then
-- soggetti iscritti per nascita dopo la data di riferimento
        w_residente_al := 0;
w_step := 5;
     elsif w_fascia = 1 and w_data_ult_eve > w_data_rif and w_stato != 1 then
-- iscritti per motivo diverso dalla nascita, dopo la data di riferimento
        goto ctr_eve;
     elsif w_fascia != 1 and w_data_ult_eve > w_data_rif then
-- cancellati dall'anagrafe dopo la data di riferimento
        goto ctr_eve;
     else
        w_residente_al := to_number(null);
w_step := 6;
     end if;
     goto fine;
<< ctr_eve >>
     if w_count_eve = 0 then
-- non esistono record in anaeve, quindi non è possibile ricostruire lo storico
        w_residente_al := to_number(null);
w_step := 7;
     elsif w_count_eve_matr = 0 then
-- il soggetto non ha storico in anaeve x il periodo procedente alla data di riferimento
        if w_fascia = 1 then
-- se oggi è residente, allora non lo era alla data di riferimento
           w_residente_al := 0;
w_step := 8;
        elsif w_fascia = 2 or (w_fascia = 3 and w_stato = 52) then
-- se oggi è emigrato / emigrato aire, si presume fosse residente dalla nascita
           w_residente_al := 1;
w_step := 9;
        else
-- in ogni altro caso non c'e' storico alla data di riferimento
           w_residente_al := 0;
w_step := 10;
        end if;
     elsif w_count_eve_matr > 0 then
-- si cerca l'evento precedente piu' vicino alla data di riferimento
        begin
          select max(cod_mov)
            into w_max_cod_mov
            from anaeve a
           where matricola = w_matricola
             and data_eve  = (select max(data_eve)
                                from anaeve b
                               where b.matricola = a.matricola
                                 and b.cod_mov   in (1,2,3,4)
                                 and b.data_eve  <= w_data_rif_j)
          ;
          if w_max_cod_mov = 1 then
             w_residente_al := 1;
w_step := 11;
          else
             w_residente_al := 0;
w_step := 12;
          end if;
        exception
          when others then
               w_residente_al := to_number(null);
w_step := 13;
        end;
     end if;
<< fine >>
null;
  end if;
  return w_residente_al;
--  return to_number(w_residente_al||'.'||w_step);
end;
/* End Function: F_RESIDENTE_AL */
/

