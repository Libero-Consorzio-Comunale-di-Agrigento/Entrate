--liquibase formatted sql
--changeset dmarotta:20250326_152438_TR4TRB_dr stripComments:false context:CFA
--validCheckSum: 1:any

begin
    declare
        table_count number;
    begin
        select count(*) into table_count from all_tables where table_name = 'CFA_ACC_TRIBUTI' and owner = '${targetUsername}';
        if table_count > 0 then
            execute immediate 'drop table CFA_ACC_TRIBUTI';
        end if;
    end;

    -- Check if CFA_PROVVISORI_ENTRATA_TRIBUTI exists and drop it if it does
    declare
        table_count number;
    begin
        select count(*) into table_count from all_tables where table_name = 'CFA_PROVVISORI_ENTRATA_TRIBUTI' and owner = '${targetUsername}';
        if table_count > 0 then
            execute immediate 'drop table CFA_PROVVISORI_ENTRATA_TRIBUTI';
        end if;
    end;
end;
/
