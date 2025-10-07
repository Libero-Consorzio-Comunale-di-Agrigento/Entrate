--liquibase formatted sql
--changeset dmarotta:20250623_100506_72454_update_tido stripComments:false

update titoli_documento tido
   set tido.nome_metodo = 'importaDichiarazioniEncEcPf'
 where tido.titolo_documento in (26, 36);
