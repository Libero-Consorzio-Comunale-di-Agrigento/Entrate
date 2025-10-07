--liquibase formatted sql 
--changeset abrandolini:20250326_152423_riob_to_riog stripComments:false runOnChange:true 
 
create or replace procedure RIOB_TO_RIOG
(p_oggetto NUMBER,
 p_data_ora DATE)
AS
BEGIN
   DELETE      riferimenti_oggetto
         WHERE oggetto = p_oggetto;
   FOR rec_riob IN (SELECT oggetto, inizio_validita, fine_validita, da_anno,
                           a_anno, rendita, anno_rendita, categoria_catasto,
                           classe_catasto, data_reg, data_reg_atti,
                           utente_riog, data_variazione_riog, note_riog
                      FROM riferimenti_oggetto_bk
                     WHERE oggetto = p_oggetto
                       AND data_ora_variazione = p_data_ora)
   LOOP
      INSERT INTO riferimenti_oggetto
                  (oggetto, inizio_validita,
                   fine_validita, da_anno,
                   a_anno, rendita, anno_rendita,
                   categoria_catasto, classe_catasto,
                   data_reg, data_reg_atti,
                   utente, data_variazione,
                   note
                  )
           VALUES (rec_riob.oggetto, rec_riob.inizio_validita,
                   rec_riob.fine_validita, rec_riob.da_anno,
                   rec_riob.a_anno, rec_riob.rendita, rec_riob.anno_rendita,
                   rec_riob.categoria_catasto, rec_riob.classe_catasto,
                   rec_riob.data_reg, rec_riob.data_reg_atti,
                   rec_riob.utente_riog, rec_riob.data_variazione_riog,
                   rec_riob.note_riog
                  );
   END LOOP;
   DELETE      riferimenti_oggetto_bk
         WHERE oggetto = p_oggetto AND data_ora_variazione = p_data_ora;
EXCEPTION
   WHEN OTHERS
   THEN
      RAISE;
END;
/* End Procedure: RIOB_TO_RIOG */
/

