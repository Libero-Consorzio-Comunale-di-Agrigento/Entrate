--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_dic_anci stripComments:false runOnChange:true 
 
create or replace procedure CARICA_DIC_ANCI
(a_sezione_unica    IN      varchar2,
 a_conv             IN      varchar2,
 a_anno_denuncia    IN OUT  number
)
is
begin
   CARICA_DIC_ANCI_PK.CARICA_DIC_ANCI(a_sezione_unica, a_conv, a_anno_denuncia);
   EXCEPTION
     WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR
      (-20999,'Errore nel Caricamento Denunce ANCI '||
              '('||SQLERRM||')');
end;
/* End Procedure: CARICA_DIC_ANCI */
/

