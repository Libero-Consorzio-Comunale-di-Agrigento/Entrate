--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4GSD_s stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

create synonym anaana    for ${gsdUsername}.anaana;
create synonym anadev    for ${gsdUsername}.anadev;
create synonym anadpr    for ${gsdUsername}.anadpr;
create synonym anadrp    for ${gsdUsername}.anadrp;
create synonym anadst    for ${gsdUsername}.anadst;
create synonym anaeve    for ${gsdUsername}.anaeve;
create synonym anafam    for ${gsdUsername}.anafam;
create synonym anaste    for ${gsdUsername}.anaste;
create synonym arcvie    for ${gsdUsername}.arcvie;
create synonym arcint    for ${gsdUsername}.arcint;
create synonym arccom    for ${gsdUsername}.arccom;
create synonym arcpro    for ${gsdUsername}.arcpro;

-- x TributiWeb: da verificare
create synonym anadce    for ${gsdUsername}.anadce;
create synonym anamov    for ${gsdUsername}.anamov;

-- x ftp trasmissioni
create synonym gsd_anaelac_v for ${gsdUsername}.anaelac_v;
create synonym gsd_tabrep    for ${gsdUsername}.tabrep;
