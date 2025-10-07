--liquibase formatted sql 
--changeset abrandolini:20250326_152423_wrk_popolamento_tasi_imu_nr stripComments:false runOnChange:true 
 
create or replace procedure WRK_POPOLAMENTO_TASI_IMU_NR
( a_id   IN OUT   number
)
is
cursor_name    integer;
ret      integer;
begin -- Assegnazione Numero Progressivo
   if a_id is null then
       begin -- Assegnazione Numero Progressivo
          select nvl(max(id),0)+1
            into a_id
            from WRK_POPOLAMENTO_TASI_IMU
          ;
       end;
    end if;
end;
/* End Procedure: WRK_POPOLAMENTO_TASI_IMU_NR */
/

