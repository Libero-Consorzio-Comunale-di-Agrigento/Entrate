--liquibase formatted sql
--changeset dmarotta:20250326_152438_Ad4BS_g stripComments:false
--validCheckSum: 1:any

-- Grant da AD4 a GC4 (Ad4_DB_g.sql)
declare
   d_errore varchar2(32000);
begin
   d_errore := admin_ad4.grant_to('${targetUsername}','DB');
   if d_errore is not null then
      raise_application_error(-20999,'Errori in assegnazione grant:'||d_errore);
   end if;
end;
/

-- Grant da AD4 a GC4 (Ad4_CM_g.sql)
declare
   d_errore varchar2(32000);
begin
   d_errore := admin_ad4.grant_to('${targetUsername}','CM');
   if d_errore is not null then
      raise_application_error(-20999,'Errori in assegnazione grant:'||d_errore);
   end if;
end;
/

-- Grant da AD4 a GC4 per banche e sportelli (Ad4_BS_g.sql)
declare
   d_errore varchar2(32000);
begin
   d_errore := admin_ad4.grant_to('${targetUsername}','BS');
   if d_errore is not null then
      raise_application_error(-20999,'Errori in assegnazione grant:'||d_errore);
   end if;
end;
/
