--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4CFA_s stripComments:false context:CFA endDelimiter:/
--validCheckSum: 1:any

declare
    cnt number;
begin
    select count(*) into cnt from all_synonyms where synonym_name='CFA_ACC_TRIBUTI';
    if cnt = 0 then
        execute immediate 'create synonym CFA_ACC_TRIBUTI                	for ${cfaUsername}.ACC_TRIBUTI';
    end if;

    select count(*) into cnt from all_synonyms where synonym_name='CFA_PROVVISORI_ENTRATA_TRIBUTI';
    if cnt = 0 then
        execute immediate 'create synonym CFA_PROVVISORI_ENTRATA_TRIBUTI   for ${cfaUsername}.PROVVISORI_ENTRATA_TRIBUTI';
    end if;

end;
/


