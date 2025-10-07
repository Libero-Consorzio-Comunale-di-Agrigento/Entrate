--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_coco_web stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_COCO_WEB
      ( a_tico              IN varchar2
      , a_anno              IN varchar2
      , a_tipo_tributo      IN varchar2)
    IS
    w_errore         varchar2(2000);
    errore           exception;
CURSOR sel_abil  IS
select distinct cont.cod_fiscale
  from contribuenti cont
     , tr4web_abilitazioni  abil
 where cont.cod_fiscale = abil.cod_fiscale
   and not exists (select 'x'
                     from contatti_contribuente coco
                    where coco.cod_fiscale   = cont.cod_fiscale
                      and nvl(coco.anno,-1)  = nvl(to_number(a_anno),-1)
                      and coco.tipo_contatto = a_tico
                  )
     ;
BEGIN
  FOR rec_abil IN sel_abil
  LOOP
    BEGIN
      insert into contatti_contribuente
            (cod_fiscale, data, anno, tipo_contatto, tipo_richiedente, tipo_tributo )
      values (rec_abil.cod_fiscale, trunc(sysdate), a_anno, a_tico, 1, a_tipo_tributo );
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore in inserimento contatti_contribuente '||
                    ' per '||rec_abil.cod_fiscale||' - ('||SQLERRM||')';
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
       (-20999,'Errore in Inserimento Contatti Web - ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_COCO_WEB */
/

