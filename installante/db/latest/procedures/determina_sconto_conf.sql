--liquibase formatted sql 
--changeset abrandolini:20250326_152423_determina_sconto_conf stripComments:false runOnChange:true 
 
create or replace procedure DETERMINA_SCONTO_CONF
/*************************************************************************
 NOME:        DETERMINA_SCONTO_CONF
 DESCRIZIONE: San Donato Milanese - Sperimentazione Poasco
              Determina la eventuale percentuale di sconto
              per conferimento sacchi e il numero dei
              sacchi conferiti
 NOTE:
 Rev.    Date         Author      Note
 000     16/11/2016   VD          Prima emissione
*************************************************************************/
( a_unita_territoriale       number
, a_suddivisione             number
, a_cod_fiscale              varchar2
, a_oggetto                  number
, a_anno                     number
, a_tributo                  number
, a_categoria                number
, a_num_familiari            number
, a_perc_sconto              IN OUT number
, a_num_sacchi               IN OUT number
)
is
  w_flag_domestica           varchar2(1);
  w_suddivisione             number;
  w_perc_sconto              number;
  w_num_sacchi               number;
begin
  --
  -- Si controlla che l'oggetto sia relativo ad un'utenza domestica
  --
  begin
    select flag_domestica
      into w_flag_domestica
      from categorie
     where tributo = a_tributo
       and categoria = a_categoria;
  exception
    when others then
      w_flag_domestica := 'N';
  end;
--
-- Se si tratta di utenza domestica, si controlla se l'utenza
-- e' nella zona interessata dalla sperimentazione
--
  if w_flag_domestica = 'S' then
     begin
      select to_number(substr(f_unita_territoriale(a_unita_territoriale
                                                  ,ogge.cod_via
                                                  ,ogge.num_civ
                                                  ,ogge.suffisso
                                                  )
                             ,21,4)
                      )
        into w_suddivisione
        from oggetti ogge
       where ogge.oggetto = a_oggetto;
     exception
       when others then
         w_suddivisione := to_number(null);
     end;
  else
     w_suddivisione := to_number(null);
  end if;
--
-- Se la suddivisione trovata è uguale a quella
-- passata come parametro, significa che l'utenza
-- è da trattare
--
  if w_suddivisione is not null and
     w_suddivisione = a_suddivisione then
     begin
       select cosa.perc_sconto
            , conf.sacchi
         into w_perc_sconto
            , w_num_sacchi
         from componenti_sacchi cosa
            , conferimenti      conf
        where conf.cod_fiscale      = a_cod_fiscale
          and conf.anno             = a_anno
          and conf.anno             = cosa.anno
          and cosa.numero_familiari = least(a_num_familiari,6)
          and conf.sacchi between cosa.da_sacchi
                              and cosa.a_sacchi;
     exception
       when others then
         w_perc_sconto := to_number(null);
         w_num_sacchi  := to_number(null);
     end;
  else
     w_perc_sconto := to_number(null);
     w_num_sacchi  := to_number(null);
  end if;
--
  a_perc_sconto := w_perc_sconto;
  a_num_sacchi  := w_num_sacchi;
--
end;
/* End Procedure: DETERMINA_SCONTO_CONF */
/

