--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_versato_pratica stripComments:false runOnChange:true 
 
create or replace function F_VERSATO_PRATICA
/*************************************************************************
 NOME:        F_VERSATO_PRATICA
 DESCRIZIONE: Data una pratica, la funzione calcola il totale versato
              relativo alla pratica indicata.
              Se viene indicata anche la data di riferimento, il calcolo
              considera solo i versamenti effettuati fino a quella data.
 RITORNA:     number              Totale versato
 Rev.    Date         Author      Note
 001     10/07/2018   VD          Aggiunta gestione data di riferimento.
 000     01/12/2008   XX          Prima emissione.
*************************************************************************/
(a_pratica              in number
,a_data_rif             in date default null
) Return number is
nImporto                   number;
nConta                     number;
BEGIN
   if a_data_rif is null then
      BEGIN
        select sum(nvl(vers.importo_versato,0))
              ,count(*)
          into nImporto
              ,nConta
          from versamenti        vers
         where vers.pratica     = a_pratica
       ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nImporto := 0;
          nConta   := 0;
      END;
   else
      BEGIN
        select sum(nvl(vers.importo_versato,0))
              ,count(*)
          into nImporto
              ,nConta
          from versamenti        vers
         where vers.pratica     = a_pratica
           and vers.data_pagamento <= a_data_rif
       ;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nImporto := 0;
          nConta   := 0;
      END;
   end if;
   Return nImporto;
END;
/* End Function: F_VERSATO_PRATICA */
/

