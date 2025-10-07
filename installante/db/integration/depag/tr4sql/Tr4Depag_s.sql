--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4Depag_s stripComments:false context:DEPAG endDelimiter:/
--validCheckSum: 1:any

declare
    cnt number;
begin
    select count(*) into cnt from all_synonyms where synonym_name='DEPAG_DOVUTI';
    if cnt = 0 then
        execute immediate 'create synonym depag_dovuti                for ${depagUsername}.depag_dovuti';
    end if;

    select count(*) into cnt from all_synonyms where synonym_name='DEPAG_DOVUTI_ANNULLABILI';
    if cnt = 0 then
        execute immediate 'create synonym depag_dovuti_annullabili    for ${depagUsername}.depag_dovuti_annullabili';
    end if;

    select count(*) into cnt from all_synonyms where synonym_name='DEPAG_DOVUTI_PAGATI';
    if cnt = 0 then
        execute immediate 'create synonym depag_dovuti_pagati         for ${depagUsername}.depag_dovuti_pagati';
    end if;

    select count(*) into cnt from all_synonyms where synonym_name='DEPAG_SERVICE_PKG';
    if cnt = 0 then
        execute immediate 'create synonym depag_service_pkg           for ${depagUsername}.SERVICE_PKG';
    end if;
end;
/
