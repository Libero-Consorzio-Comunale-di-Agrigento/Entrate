--liquibase formatted sql
--changeset dmarotta:20250326_152438_TR4TRB_dr stripComments:false context:"TRT2 or TRV2"
--validCheckSum: 1:any

begin
    -- Check if N01 exists and drop it if it does
    declare
        table_count number;
    begin
        select count(*) into table_count from all_tables where table_name = 'N01' and owner = '${targetUsername}';
        if table_count > 0 then
            execute immediate 'drop table N01';
        end if;
    end;

    -- Check if ANANRE exists and drop it if it does
    declare
        table_count number;
    begin
        select count(*) into table_count from all_tables where table_name = 'ANANRE' and owner = '${targetUsername}';
        if table_count > 0 then
            execute immediate 'drop table ANANRE';
        end if;
    end;
end;
/
