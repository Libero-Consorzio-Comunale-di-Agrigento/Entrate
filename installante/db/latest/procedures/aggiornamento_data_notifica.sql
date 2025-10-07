--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_data_notifica stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_DATA_NOTIFICA
(a_tipo_tributo      IN    varchar2,
 a_tipo_pratica      IN    varchar2,
 a_ni                 IN    number,
 a_cod_fiscale       IN    varchar2,
 a_da_anno           IN    number,
 a_a_anno              IN    number,
 a_da_data           IN    date,
 a_a_data              IN    date,
 a_da_num            IN    varchar2,
 a_a_num              IN    varchar2,
 a_data_notifica     IN    date,
 a_cognome_nome      IN    varchar2 default null)
IS
w_errore         varchar2(200);
errore            exception;
  CURSOR sel_prtr IS
  select prtr.pratica
      , prtr.data
      , cont.cod_fiscale
    from contribuenti cont,
         rapporti_tributo ratr,
         pratiche_tributo prtr,
         soggetti sogg
   where cont.ni                = nvl(a_ni,cont.ni)
     and cont.cod_fiscale       = ratr.cod_fiscale
     and ratr.cod_fiscale    like nvl(a_cod_fiscale,ratr.cod_fiscale)
     and ratr.pratica           = prtr.pratica
     and sogg.ni                = cont.ni
     and prtr.tipo_tributo      = a_tipo_tributo
     and prtr.tipo_pratica      = a_tipo_pratica
     and prtr.anno   between nvl(a_da_anno,1) and nvl(a_a_anno,9999)
     and prtr.data   between nvl(a_da_data,to_date('01/01/1800','dd/mm/yyyy'))
                         and nvl(a_a_data,to_date('31/12/9999','dd/mm/yyyy'))
     and lpad(prtr.numero,15,' ') between a_da_num and a_a_num
     and (a_cognome_nome is null or sogg.cognome_nome_ric like a_cognome_nome)
     and prtr.numero      is not null
     and prtr.data_notifica is null
   order by prtr.data, cont.cod_fiscale, prtr.anno
       ;
  FUNCTION f_conta_vers(w_pratica number) RETURN number IS
  nRisultato          number;
  BEGIN
   BEGIN
       select count(*) righe
      into nRisultato
      from versamenti vers
      where vers.pratica = w_pratica;
      EXCEPTION
      WHEN OTHERS THEN
           RETURN -1;
   END;
   RETURN nRisultato;
  END f_conta_vers;
BEGIN
  FOR rec_prtr IN sel_prtr LOOP
    BEGIN
--    dbms_output.put_line('Pratica: ' || rec_prtr.pratica);
      IF a_data_notifica < rec_prtr.data THEN
        w_errore := 'Impossibile registrare. Data Notifica Minore della Data della pratica.';
        RAISE errore;
     ELSIF f_conta_vers(rec_prtr.pratica) > 0 THEN
        w_errore := 'Impossibile registrare. Esistono dei versamenti sulla pratica.';
      RAISE errore;
      ELSE
       update pratiche_tributo
        set data_notifica = a_data_notifica
        where pratica     = rec_prtr.pratica
        ;
      GESTIONE_NOOG_PRATICA(rec_prtr.cod_fiscale,rec_prtr.pratica,a_data_notifica,'D');
     END IF;
    END;
  END LOOP;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR
   (-20999,'Errore in Aggiornamento Data Notifica '||'('||SQLERRM||')');
END;
/* End Procedure: AGGIORNAMENTO_DATA_NOTIFICA */
/

