--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_alog_ravv stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_ALOG_RAVV
      ( a_cod_fiscale   IN varchar2
      , a_ogpr_old      IN number
      , a_ogpr_new      IN number
      , a_tipo_tributo  in varchar2)
    IS
    w_errore         varchar2(2000);
    errore           exception;
CURSOR sel_alog
     ( p_cod_fiscale varchar2
     , p_ogpr_old    number ) IS
select alog.cod_fiscale
      ,alog.dal
      ,alog.al
      ,alog.tipo_aliquota
      ,alog.note
      ,alog.tipo_tributo
  from aliquote_ogco alog
 where alog.cod_fiscale     = p_cod_fiscale
   and alog.oggetto_pratica = p_ogpr_old
   and alog.tipo_tributo    = a_tipo_tributo
     ;
BEGIN
  FOR rec_alog
      IN sel_alog (a_cod_fiscale, a_ogpr_old)
  LOOP
    BEGIN
      insert into aliquote_ogco
            (cod_fiscale, oggetto_pratica, dal, al, tipo_aliquota, note, tipo_tributo )
      values (rec_alog.cod_fiscale, a_ogpr_new, rec_alog.dal, rec_alog.al, rec_alog.tipo_aliquota, rec_alog.note, rec_alog.tipo_tributo );
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento aliquote_ogco '||
                    ' per '||rec_alog.cod_fiscale||' - ('||SQLERRM||')';
        RAISE errore;
    END;
  END LOOP;
EXCEPTION
   WHEN errore THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Inserimento Aliquote Oggetto - ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_ALOG_RAVV */
/

