--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_rendita_riog stripComments:false runOnChange:true 
 
create or replace function F_GET_RENDITA_RIOG
/*************************************************************************
 NOME:        F_GET_RENDITA_RIOG
 DESCRIZIONE: Restituisce la rendita da riferimenti_oggetto (RIOG) per
              l'oggetto e l'anno o la data indicati.
              In presenza di più rendite valide per anno, restituisce
              quella avente data di inizio validita' minore.
 Rev.    Date         Author      Note
 000     04/01/2021   VD          Prima emissione.
*************************************************************************/
(p_oggetto            IN number
,p_anno               IN number default null
,p_data               IN date   default null)
RETURN number
IS
w_rendita        NUMBER;
errore           exception;
w_errore         varchar2(2000);
BEGIN
   BEGIN
     if p_anno is not null then
        select riog.rendita
          into w_rendita
          from riferimenti_oggetto riog
         where riog.oggetto   = p_oggetto
           and p_anno between riog.da_anno and nvl(riog.a_anno,9999)
           and riog.inizio_validita = (select min(rio2.inizio_validita)
                                         from riferimenti_oggetto rio2
                                        where rio2.oggetto = p_oggetto
                                          and p_anno between rio2.da_anno and nvl(rio2.a_anno,9999))
        ;
     elsif p_data is not null then
        select riog.rendita
          into w_rendita
          from riferimenti_oggetto riog
         where riog.oggetto   = p_oggetto
           and p_data between riog.inizio_validita and nvl(riog.fine_validita,to_date('31129999','ddmmyyyy'))
        ;
     end if;
   EXCEPTION
      WHEN no_data_found THEN
         w_rendita := null;
      WHEN others THEN
         w_rendita := null;
   END;
   RETURN w_rendita ;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in recupero rendita '||
       ' ('||SQLERRM||')');
END;
/* End Function: F_GET_RENDITA_RIOG */
/

