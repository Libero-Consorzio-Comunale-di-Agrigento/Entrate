--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_calcolo_detrazione_immobile stripComments:false runOnChange:true 
 
create or replace function F_CALCOLO_DETRAZIONE_IMMOBILE
(a_anno            in     number
,a_oggetto_pratica in     number
) Return number is
nContribuenti             number;
nDetrazione               number;
/*
    Dato un Oggetto Pratica ed un Anno,
    si restituisce la detrazione prevista
    ripartita per il numero di possidenti.
    Non viene effettuato il rapporto sulla
    base dei mesi di possesso.
*/
BEGIN
   BEGIN
      select detr.detrazione_base
        into nDetrazione
        from detrazioni detr
       where detr.anno     = a_anno
      ;
   EXCEPTION
      WHEN OTHERS THEN
         nDetrazione := 0;
   END;
   BEGIN
      select count(*)
        into nContribuenti
        from oggetti_contribuente ogco
       where ogco.oggetto_pratica = a_oggetto_pratica
         and ogco.anno            = a_anno
      ;
   END;
   if nContribuenti > 0 then
      return round(nDetrazione / nContribuenti,2);
   else
      return 0;
   end if;
END;
/* End Function: F_CALCOLO_DETRAZIONE_IMMOBILE */
/

