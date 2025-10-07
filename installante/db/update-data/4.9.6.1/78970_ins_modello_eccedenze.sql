--liquibase formatted sql
--changeset dmarotta:20250418_081453_78970_ins_modello_eccedenze endDelimiter:/

begin

  if install_common.check_tipo_tributo('TARSU') > 0 then
    
    if install_common.check_tipo_modello('COM_TARSU%') > 0 then
    
    --  COM_TARSU%  COMUNICAZIONE A RUOLO
    
      install_common.update_modello('TARSU','COM_RUOLO_DATI_ECCEDENZE','COM_TARSU%',null,null,'S','COM_RUOLO_DATI_ECCEDENZE','S','STAMPA_AVVISI_TARI.DATI_ECCEDENZE','S',null,null,'S');

      install_common.update_modello('TARSU','COM_RUOLO_DATI_RFID','COM_TARSU%',null,null,'S','COM_RUOLO_DATI_RFID','S','STAMPA_AVVISI_TARI.DATI_RFID','S',null,null,'S');
    
      install_common.update_modello('TARSU','COM_RUOLO_DIZ_TARIFFE_D','COM_TARSU%',null,null,'S','COM_RUOLO_DIZ_TARIFFE_D','S','STAMPA_AVVISI_TARI.DIZIONARIO_TARIFFE_DOM','S',null,null,'S');
      install_common.update_modello('TARSU','COM_RUOLO_DIZ_TARIFFE_ND','COM_TARSU%',null,null,'S','COM_RUOLO_DIZ_TARIFFE_ND','S','STAMPA_AVVISI_TARI.DIZIONARIO_TARIFFE_NON_DOM','S',null,null,'S');

      commit;

    end if;

  end if;

end;
/
