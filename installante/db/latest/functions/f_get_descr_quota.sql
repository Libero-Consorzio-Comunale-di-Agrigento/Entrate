--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_descr_quota stripComments:false runOnChange:true 
 
create or replace function F_GET_DESCR_QUOTA
( a_quota_den              varchar2
, a_quota_liq              varchar2
, a_quota_acc              varchar2
) return varchar2
is
  w_conta                  number := 0;
  w_return                 varchar2(3);
begin
  if nvl(length(a_quota_den),0) > 15 then
     w_conta := w_conta + 1;
     w_return := '1';
  else
     w_return := '0';
  end if;
  if nvl(length(a_quota_liq),0) > 15 then
     w_conta := w_conta + 1;
     w_return := w_return||w_conta;
  else
     w_return := w_return||'0';
  end if;
  if nvl(length(a_quota_acc),0) > 15 then
     w_conta := w_conta + 1;
     w_return := w_return||w_conta;
  else
     w_return := w_return||'0';
  end if;
--
  return w_return;
--
end;
/* End Function: F_GET_DESCR_QUOTA */
/

