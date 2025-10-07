--liquibase formatted sql 
--changeset abrandolini:20250326_152423_numera_pratiche stripComments:false runOnChange:true 
 
create or replace procedure NUMERA_PRATICHE
/*************************************************************************
  Rev.    Date         Author      Note
  1       12/06/2015   VD          Corretto test su codice fiscale
                                   passato come parametro (usava
                                   l'uguaglianza invece della like)
  2       29/03/2022   DM          Implementata numerazione su cognome/nome
  3       26/03/2024   RV          #55403
                                   Aggiunto gestione tipo_pratica 'S'
*************************************************************************/
(a_tipo_tributo    IN   varchar2,
 a_tipo_pratica    IN   varchar2,
 a_ni              IN   number,
 a_cod_fiscale     IN   varchar2,
 a_da_anno         IN   number,
 a_a_anno          IN   number,
 a_da_data         IN   date,
 a_a_data          IN   date,
 a_cognome_nome    IN   varchar2 default null)
IS
w_numero      number;
w_errore      varchar2(200);
errore         exception;
CURSOR sel_prtr IS
  select prtr.pratica
    from contribuenti cont,
         soggetti sogg,
         rapporti_tributo ratr,
         pratiche_tributo prtr
   where cont.ni         = nvl(a_ni,cont.ni)
     and cont.cod_fiscale      = ratr.cod_fiscale
     and cont.ni               = sogg.ni
     and ratr.cod_fiscale      like nvl(a_cod_fiscale,'%')
     and ratr.pratica          = prtr.pratica
     and prtr.tipo_tributo     = a_tipo_tributo
     and prtr.tipo_pratica     = a_tipo_pratica
     and prtr.anno   between nvl(a_da_anno,1) and nvl(a_a_anno,9999)
     and prtr.data   between nvl(a_da_data,to_date('01/01/1800','dd/mm/yyyy'))
               and nvl(a_a_data,to_date('31/12/9999','dd/mm/yyyy'))
     and (a_cognome_nome is null or sogg.cognome_nome_ric like a_cognome_nome)
      and prtr.numero      is null
   order by prtr.data, cont.cod_fiscale, prtr.anno
       ;
BEGIN
  BEGIN
    select to_number(max(lpad(nvl(prtr.numero,'0'), 15, ' ')))
      into w_numero
      from pratiche_tributo prtr
     where prtr.tipo_tributo   = a_tipo_tributo
       and prtr.tipo_pratica   in ('A','I','L','V','S')
      and translate(prtr.numero,'a1234567890', 'a') is null
      ;
  EXCEPTION
    WHEN others THEN
    w_errore := 'Errore in selezione ultimo numero di Pratiche Tributo';
         RAISE errore;
  END;
  FOR rec_prtr IN sel_prtr LOOP
      w_numero := w_numero + 1;
      BEGIN
         update pratiche_tributo
            set numero   = w_numero
          where pratica   = rec_prtr.pratica
         ;
      EXCEPTION
         WHEN others THEN
              w_errore := 'Errore in aggiornamento Pratiche Tributo';
              RAISE errore;
      END;
  END LOOP;
EXCEPTION
  WHEN ERRORE THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR (-20999,w_errore);
END;
/* End Procedure: NUMERA_PRATICHE */
/
