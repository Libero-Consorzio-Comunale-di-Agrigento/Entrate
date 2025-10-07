--liquibase formatted sql
--changeset dmarotta:20250326_152438_GSDTr4_v stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

create or replace FORCE view ANATRI as
select sogg.matricola,
       cont.cod_contribuente||decode(cont.cod_controllo,null,to_char(null),
                                     '-'||lpad(cont.cod_controllo,2,'0')) cod_contribuente,
       'TRB' tributo
  from soggetti sogg,contribuenti cont
 where sogg.tipo_residente 	= 0
   and sogg.ni 			= cont.ni
   and sogg.matricola		is not null
/

comment on table ANATRI is 'ANTR - Anagrafe Tributi'
/

update arcinp
   set valore    = 'S'
 where parametro = 'TRB'
/
