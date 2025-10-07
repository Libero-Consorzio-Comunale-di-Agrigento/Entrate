--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_indirizzo_ni_al stripComments:false runOnChange:true 
 
create or replace function F_INDIRIZZO_NI_AL
(a_ni     IN number,
 a_data   IN date)
return varchar2
IS
w_data_j    number;
w_cod_via   number;
w_denom_uff varchar2(255);
w_num_civ   number;
w_suffisso  varchar2(255);
w_interno   number;
w_scala     varchar2(255);
w_piano     varchar2(255);
w_riga      varchar2(255);
begin
  w_data_j := to_char(a_data,'j');
  begin
    select fam.cod_via
         , fam.num_civ
         , fam.suffisso
         , fam.interno
         , fam.scala
         , fam.piano
         , vie.denom_uff
      into w_cod_via
         , w_num_civ
         , w_suffisso
         , w_interno
         , w_scala
         , w_piano
         , w_denom_uff
      from arcvie vie
         , anafam fam
         , anaana ana
         , soggetti sogg
     where vie.cod_via         = fam.cod_via
       and fam.cod_fam         = ana.cod_fam
       and fam.fascia          = ana.fascia
   --    and ana.matricola       = a_matricola
       and sogg.matricola      = ana.matricola
       and sogg.tipo_Residente = 0
       and sogg.ni=a_ni
       and ana.fascia + 0      = 1
       and ana.data_inizio_res    <= w_data_j
    ;
  exception
    when no_data_found then
     w_cod_via    := null;
     w_denom_uff  := null;
     w_num_civ    := null;
     w_suffisso   := null;
     w_interno    := null;
     w_scala      := null;
     w_piano      := null;
  end;
  if w_denom_uff is null then
     begin
       select eve.cod_via
            , eve.num_civ
            , eve.suffisso
            , eve.interno
            , eve.scala
            , eve.piano
            , vie.denom_uff
         into w_cod_via
            , w_num_civ
            , w_suffisso
            , w_interno
            , w_scala
            , w_piano
            , w_denom_uff
         from arcvie vie
            , anaeve eve
            , soggetti sogg
        where vie.cod_via    = eve.cod_via
     -- and eve.matricola    = a_matricola
      and sogg.tipo_Residente=0
      and sogg.matricola=eve.matricola
          and sogg.ni=a_ni
      and (eve.cod_mov    = 11 or (eve.cod_mov = 13 and eve.cod_eve = 52))
          and w_data_j         between eve.data_inizio and eve.data_eve
      and rownum         = 1
       ;
     exception
       when no_data_found then
        w_cod_via    := null;
        w_denom_uff  := null;
        w_num_civ    := null;
        w_suffisso   := null;
        w_interno    := null;
        w_scala      := null;
        w_piano      := null;
     end;
  end if;
  w_riga := nvl(lpad(w_cod_via,6,'0'),'      ')||
        nvl(lpad(w_num_civ,6,'0'),'      ');
  RETURN w_riga;
end;
/* End Function: F_INDIRIZZO_NI_AL */
/

