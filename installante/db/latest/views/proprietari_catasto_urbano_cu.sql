--liquibase formatted sql 
--changeset abrandolini:20250326_152401_proprietari_catasto_urbano_cu stripComments:false runOnChange:true 
 
create or replace view proprietari_catasto_urbano_cu as
select distinct
 partita id_immobile,
 partita id_soggetto,
 'P' tipo_soggetto,
 rtrim(ltrim(cognome))||'/'||rtrim(ltrim(nome)) cognome_nome,
 '' des_com_sede,
 '' sigla_pro_sede,
 rtrim(ltrim(cod_titolo)) cod_titolo,
 '' des_diritto,
 rtrim(ltrim(ltrim(numeratore,'0'))) numeratore,
 rtrim(ltrim(ltrim(denominatore,'0'))) denominatore,
 rtrim(ltrim(des_titolo)) des_titolo,
 to_date('') data_validita,
 to_date('') data_fine_validita,
 to_date(
   to_number(decode(rtrim(ltrim(data_nascita)),'','', decode(instr(data_nascita,'/'), 2,
   decode(instr(substr(data_nascita,3),'/'), 2,to_char(to_date(substr(data_nascita,1,
   decode(instr(data_nascita,' '), 0,10, instr(data_nascita,' ')-1)),'dd/mm/yyyy'),'j'), 3,
   to_char(to_date(substr(data_nascita,1, decode(instr(data_nascita,' '), 0,10,
   instr(data_nascita,' ')-1)),'dd/mm/yyyy'),'j'), ''), 3,
   decode(instr(substr(data_nascita,4),'/'), 2,
   to_char(to_date(substr(data_nascita,1, decode(instr(data_nascita,' '), 0,10,
   instr(data_nascita,' ')-1)),'dd/mm/yyyy'),'j'), 3,
   to_char(to_date(substr(data_nascita,1, decode(instr(data_nascita,' '), 0,10,
   instr(data_nascita,' ')-1)),'dd/mm/yyyy'),'j'), ''), '')))
   ,'j') data_nas,
 a.denominazione des_com_nas, p.sigla sigla_pro_nas, cod_fiscale,
 'F' tipo_immobile,
 to_char(partita) partita,
 cognome_nome_ric cognome_nome_ric,
 cod_fiscale cod_fiscale_ric,
 partita id_soggetto_ric
  from ad4_comuni a, ad4_provincie p, CUFISICA
 where a.sigla_cfis (+)  = luogo_nascita
   and p.provincia (+)   = a.provincia_stato
   and a.data_soppressione is null
union
select distinct
 partita,
 partita,
 'G' tipo_soggetto,
 rtrim(ltrim(cunonfis.denominazione)),
 a.denominazione,
 p.sigla,
 rtrim(ltrim(cod_titolo)),
 '',
 rtrim(ltrim(numeratore,'0')),
 rtrim(ltrim(denominatore,'0')),
 rtrim(ltrim(des_titolo)),
 to_date(''),
 to_date(''),
 to_date(''),
 '',
 '',
 cod_fiscale,
 'F',
 to_char(partita),
 denominazione_ric,
 cod_fiscale,
 partita
  from ad4_comuni a, ad4_provincie p, CUNONFIS
 where a.sigla_cfis (+) = sede
   and p.provincia (+) = a.provincia_stato
   and a.data_soppressione is null;
comment on table PROPRIETARI_CATASTO_URBANO_CU is 'Proprietari Catasto Urbano CU';
