--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiorna_tipo_violazione stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     AGGIORNA_TIPO_VIOLAZIONE
/*******************************************************************************
 Rev. Data       Autore     Descrizione
 ---- ---------- ------     -----------------------------------------------------
  2   12/04/2024   AB       #57935
                            Aggiornamento del tipo_violazione anche in caso di delete
  1   13/05/2022   AB       Prima emissione, lanciata in Post Event nel trigger
                            OGGGETTI_PRATICA_TIU per aggiornare il nuovo campo
                            presente in PRATICHE_TRIBUTO
*************************************************************************/
(a_pratica      number
,a_ogpr_rif     number
,a_operazione   varchar2
)
is
w_conta number;
begin
--  dbms_output.put_line(a_pratica||' '||a_ogpr_rif||' '||a_operazione);
  IF a_operazione = 'I' then     --Insert
     begin
       update pratiche_tributo prtr
          set tipo_violazione = decode(a_ogpr_rif,-1,'OD','ID')
        where pratica = a_pratica
     --     and tipo_tributo = 'TARSU'  AB 16/05/2023 tolto il controllo ed eseguito per tutti i tributi
          and tipo_pratica = 'A'
          and tipo_evento = 'U'
       ;
     exception
        when others then null;
     end;
  ELSIF a_operazione = 'D' then  --Delete
     begin
       select count(*)
         into w_conta
         from oggetti_pratica ogpr
        where pratica = a_pratica
       ;
     exception
        when others then null;
     end;
     if w_conta = 0 then
        begin
          update pratiche_tributo prtr
             set tipo_violazione = null
           where pratica = a_pratica
             and tipo_pratica = 'A'
             and tipo_evento = 'U'
          ;
        exception
           when others then null;
        end;
     end if;
  END IF;
end;
/* End Procedure: AGGIORNA_TIPO_VIOLAZIONE */
/
