--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_check_digit stripComments:false runOnChange:true 
 
create or replace function F_CHECK_DIGIT
(documento     varchar2
)
return varchar2
is
documentoDigit         varchar2(14);
begin
        select substr(
              to_char(10 -
                  mod(
                      ((substr(lpad(documento,12,'0'),2,1) +
                        substr(lpad(documento,12,'0'),4,1) +
                        substr(lpad(documento,12,'0'),6,1) +
                        substr(lpad(documento,12,'0'),8,1) +
                        substr(lpad(documento,12,'0'),10,1) +
                        substr(lpad(documento,12,'0'),12,1)) * 3) +
                       (substr(lpad(documento,12,'0'),1,1) +
                        substr(lpad(documento,12,'0'),3,1) +
                        substr(lpad(documento,12,'0'),5,1) +
                        substr(lpad(documento,12,'0'),7,1) +
                        substr(lpad(documento,12,'0'),9,1) +
                        substr(lpad(documento,12,'0'),11,1))
               ,10)
                )
               ,-1,1)
        into documentoDigit
          from dual
          ;
return documento || documentoDigit;
end;
/* End Function: F_CHECK_DIGIT */
/

