--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cifre_lettere stripComments:false runOnChange:true 
 
create or replace function F_CIFRE_LETTERE
(a_importo IN number)
RETURN varchar2
IS
A_stringa    varchar2(256);
D_importo       varchar2(12);
D_importo_dec   varchar2(2);
D_cifra         number;
D_stringa       varchar2(256);
begin
   D_stringa := '';
   D_importo := lpad(to_char(trunc(A_importo)),12,'0');
   D_cifra := mod(round(A_importo,2),1) * 100;
   if D_cifra > 9 then
      D_importo_dec := rpad(to_char(mod(round(A_importo,2),1) * 100),2,'0');
   else
      D_importo_dec := lpad(to_char(mod(round(A_importo,2),1) * 100),2,'0');
   end if;
   for i in 1..12
   loop
      D_cifra := substr(D_importo,i,1);
      if i in (1,4,7,10) then
         if D_cifra = 2 then
            D_stringa := D_stringa||'due';
         elsif D_cifra = 3 then
               D_stringa := D_stringa||'tre';
         elsif D_cifra = 4 then
               D_stringa := D_stringa||'quattro';
         elsif D_cifra = 5 then
               D_stringa := D_stringa||'cinque';
         elsif D_cifra = 6 then
               D_stringa := D_stringa||'sei';
         elsif D_cifra = 7 then
               D_stringa := D_stringa||'sette';
         elsif D_cifra = 8 then
               D_stringa := D_stringa||'otto';
         elsif D_cifra = 9 then
               D_stringa := D_stringa||'nove';
         end if;
         if D_cifra != 0 then
            D_stringa := D_stringa||'cento';
         end if;
      elsif i in (2,5,8,11) then
            if D_cifra = 2 then
               D_stringa := D_stringa||'vent';
            elsif D_cifra = 3 then
                  D_stringa := D_stringa||'trent';
            elsif D_cifra = 4 then
                  D_stringa := D_stringa||'quarant';
            elsif D_cifra = 5 then
                  D_stringa := D_stringa||'cinquant';
            elsif D_cifra = 6 then
                  D_stringa := D_stringa||'sessant';
            elsif D_cifra = 7 then
                  D_stringa := D_stringa||'settant';
            elsif D_cifra = 8 then
                  D_stringa := D_stringa||'ottant';
            elsif D_cifra = 9 then
                  D_stringa := D_stringa||'novant';
            end if;
            if D_cifra = 2 then
               if substr(D_importo,i + 1,1) in (1,8) then
                  null;
               else
                  D_stringa := D_stringa||'i';
               end if;
            elsif D_cifra > 2 then
                  if substr(D_importo,i + 1,1) in (1,8) then
                     null;
                  else
                     D_stringa := D_stringa||'a';
                  end if;
            end if;
            if D_cifra = 1 then
               if substr(D_importo,i + 1,1) = 0 then
                  D_stringa := D_stringa||'dieci';
               elsif substr(D_importo,i + 1,1) = 1 then
                     D_stringa := D_stringa||'undici';
               elsif substr(D_importo,i + 1,1) = 2 then
                     D_stringa := D_stringa||'dodici';
               elsif substr(D_importo,i + 1,1) = 3 then
                     D_stringa := D_stringa||'tredici';
               elsif substr(D_importo,i + 1,1) = 4 then
                     D_stringa := D_stringa||'quattordici';
               elsif substr(D_importo,i + 1,1) = 5 then
                     D_stringa := D_stringa||'quindici';
               elsif substr(D_importo,i + 1,1) = 6 then
                     D_stringa := D_stringa||'sedici';
               elsif substr(D_importo,i + 1,1) = 7 then
                     D_stringa := D_stringa||'diciassette';
               elsif substr(D_importo,i + 1,1) = 8 then
                     D_stringa := D_stringa||'diciotto';
               elsif substr(D_importo,i + 1,1) = 9 then
                     D_stringa := D_stringa||'diciannove';
               end if;
            else
               if substr(D_importo,i + 1,1) = 1 then
                  if substr(D_importo,i - 1,3) = '001' then
                     if i not in (8,11) then
                        D_stringa := D_stringa||'un';
                     elsif i = 11 then
                        D_stringa := D_stringa||'uno';
                     end if;
                  else
                     D_stringa := D_stringa||'uno';
                  end if;
               elsif substr(D_importo,i + 1,1) = 2 then
                     D_stringa := D_stringa||'due';
               elsif substr(D_importo,i + 1,1) = 3 then
                     D_stringa := D_stringa||'tre';
               elsif substr(D_importo,i + 1,1) = 4 then
                     D_stringa := D_stringa||'quattro';
               elsif substr(D_importo,i + 1,1) = 5 then
                     D_stringa := D_stringa||'cinque';
               elsif substr(D_importo,i + 1,1) = 6 then
                     D_stringa := D_stringa||'sei';
               elsif substr(D_importo,i + 1,1) = 7 then
                     D_stringa := D_stringa||'sette';
               elsif substr(D_importo,i + 1,1) = 8 then
                     D_stringa := D_stringa||'otto';
               elsif substr(D_importo,i + 1,1) = 9 then
                     D_stringa := D_stringa||'nove';
               end if;
            end if;
      end if;
      if i = 2 then
         if substr(D_importo,1,3) = '000' then
            null;
         elsif substr(D_importo,1,3) = '001' then
               D_stringa := D_stringa||'miliardo';
            else
               D_stringa := D_stringa||'miliardi';
         end if;
      elsif i = 5 then
            if substr(D_importo,4,3) = '000' then
               null;
            elsif substr(D_importo,4,3) = '001' then
                  D_stringa := D_stringa||'milione';
               else
                  D_stringa := D_stringa||'milioni';
            end if;
      elsif i = 8 then
            IF substr(D_importo,7,3) = '000' then
               null;
            elsif substr(D_importo,7,3) = '001' then
                  D_stringa := D_stringa||'mille';
               else
                  D_stringa := D_stringa||'mila';
            end if;
      end if;
   end loop;
   if D_importo = '000000000000' then
      D_stringa := 'zero';
   end if;
   if D_importo_dec != '00' then
      D_stringa := D_stringa||' virgola ';
      D_cifra := substr(D_importo_dec,1,1);
      if substr(D_importo_dec,2,1) != 0 then
         if D_cifra = 0 then
            D_stringa := D_stringa||'zero';
         elsif D_cifra = 2 then
               D_stringa := D_stringa||'vent';
         elsif D_cifra = 3 then
               D_stringa := D_stringa||'trent';
         elsif D_cifra = 4 then
               D_stringa := D_stringa||'quarant';
         elsif D_cifra = 5 then
               D_stringa := D_stringa||'cinquant';
         elsif D_cifra = 6 then
               D_stringa := D_stringa||'sessant';
         elsif D_cifra = 7 then
               D_stringa := D_stringa||'settant';
         elsif D_cifra = 8 then
               D_stringa := D_stringa||'ottant';
         elsif D_cifra = 9 then
               D_stringa := D_stringa||'novant';
         end if;
         if D_cifra = 2 then
            if substr(D_importo_dec,2,1) in (1,8) then
               null;
            else
               D_stringa := D_stringa||'i';
            end if;
         elsif D_cifra > 2 then
               if substr(D_importo_dec,2,1) in (1,8) then
                  null;
               else
                  D_stringa := D_stringa||'a';
               end if;
         end if;
         if D_cifra = 1 then
            if substr(D_importo_dec,2,1) = 1 then
               D_stringa := D_stringa||'undici';
            elsif substr(D_importo_dec,2,1) = 2 then
                  D_stringa := D_stringa||'dodici';
            elsif substr(D_importo_dec,2,1) = 3 then
                  D_stringa := D_stringa||'tredici';
            elsif substr(D_importo_dec,2,1) = 4 then
                  D_stringa := D_stringa||'quattordici';
            elsif substr(D_importo_dec,2,1) = 5 then
                  D_stringa := D_stringa||'quindici';
            elsif substr(D_importo_dec,2,1) = 6 then
                  D_stringa := D_stringa||'sedici';
            elsif substr(D_importo_dec,2,1) = 7 then
                  D_stringa := D_stringa||'diciassette';
            elsif substr(D_importo_dec,2,1) = 8 then
                  D_stringa := D_stringa||'diciotto';
            elsif substr(D_importo_dec,2,1) = 9 then
                  D_stringa := D_stringa||'diciannove';
            end if;
         end if;
      end if;
      if D_cifra = 1 and
         substr(D_importo_dec,2,1) > 0 then
         null;
      else
         if substr(D_importo_dec,2,1) != 0 then
            D_cifra := substr(D_importo_dec,2,1);
         end if;
         if D_cifra = 1 then
            D_stringa := D_stringa||'uno';
         elsif D_cifra = 2 then
               D_stringa := D_stringa||'due';
         elsif D_cifra = 3 then
               D_stringa := D_stringa||'tre';
         elsif D_cifra = 4 then
               D_stringa := D_stringa||'quattro';
         elsif D_cifra = 5 then
               D_stringa := D_stringa||'cinque';
         elsif D_cifra = 6 then
               D_stringa := D_stringa||'sei';
         elsif D_cifra = 7 then
               D_stringa := D_stringa||'sette';
         elsif D_cifra = 8 then
               D_stringa := D_stringa||'otto';
         elsif D_cifra = 9 then
               D_stringa := D_stringa||'nove';
         end if;
      end if;
   end if;
   A_stringa := D_stringa;
 RETURN (a_stringa);
EXCEPTION
    WHEN OTHERS THEN
         RETURN null;
end;
/* End Function: F_CIFRE_LETTERE */
/

