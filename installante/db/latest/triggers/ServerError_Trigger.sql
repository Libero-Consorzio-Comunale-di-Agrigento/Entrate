--liquibase formatted sql
--changeset dmarotta:20250508_152756_ServerError_Trigger stripComments:false runOnChange:true

CREATE OR REPLACE TRIGGER servererror_trigger
after servererror on SCHEMA 
/******************************************************************************
 NAME:        servererror_trigger
 DESCRIPTION: DB error trapping trigger.

 ANNOTATIONS: -
 REVISION:
 Rev. Date       Author Description
 ---- ---------- ------ ------------------------------------------------------
 0    14/03/2005 AV     First version.
******************************************************************************/
declare
begin
   DbC.ASSERTION( not DbC.AssertionOn or Servererror_Handler.TriggerIsEnabled );
   if Servererror_Handler.TriggerOn then
      Servererror_Handler.handle_error;
   end if;
end servererror_trigger;
/
