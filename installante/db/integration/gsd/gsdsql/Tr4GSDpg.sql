--liquibase formatted sql
--changeset dmarotta:20250326_152438_Tr4GSDpg stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

grant execute on IntegrityPackage 	to ${targetUsername}; 
grant execute on anaana_tr4_fi 	to ${targetUsername}; 
grant execute on anafam_tr4_fi 	to ${targetUsername}; 
grant execute on arcvie_tr4_fi 	to ${targetUsername};

grant execute on f_unita_territoriale to ${targetUsername} with grant option; 
grant execute on f_intestatario_interno to ${targetUsername} with grant option; 
grant execute on f_stato_interno to ${targetUsername} with grant option; 
grant execute on f_intestatario_ecografico to ${targetUsername} with grant option; 
grant execute on f_stato_ecografico to ${targetUsername} with grant option; 
grant execute on f_mov_fascia_al to ${targetUsername} with grant option; 
grant execute on f_matricola_md to ${targetUsername} with grant option; 
grant execute on f_matricola_pd to ${targetUsername} with grant option; 
