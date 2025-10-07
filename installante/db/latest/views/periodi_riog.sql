--liquibase formatted sql 
--changeset abrandolini:20250326_152401_periodi_riog stripComments:false runOnChange:true 
 
create or replace force view periodi_riog as
select wrkp.oggetto
   ,wrkp.inizio_validita
   ,lead(wrkp.inizio_validita - 1
  ,1
  ,to_date('31129999'
    ,'ddmmyyyy'
    )
  )
 over (partition by wrkp.oggetto order by wrkp.inizio_validita)
  fine_validita
   ,min(wrkp.inizio_validita_eff) inizio_validita_eff
  from (select rio1.oggetto
  ,decode(greatest(15
   ,to_number(to_char(rio1.inizio_validita
      ,'dd'
      ))
   )
   ,15, to_date('01' ||
    to_char(rio1.inizio_validita
     ,'mmyyyy'
     )
   ,'ddmmyyyy'
   )
   ,decode(last_day(rio1.inizio_validita)
    ,to_date('31129999','ddmmyyyy'),rio1.inizio_validita
    ,last_day(rio1.inizio_validita) + 1
    )
   )
    inizio_validita
  ,rio1.inizio_validita inizio_validita_eff
 from riferimenti_oggetto rio1
   where rio1.oggetto > 0
  and inizio_validita >= to_date('01011000'
     ,'ddmmyyyy'
     )
  union
  select rio2.oggetto
  ,decode(greatest(15
   ,to_number(to_char(rio2.fine_validita + 1
      ,'dd'
      ))
   )
   ,15, to_date('01' ||
    to_char(rio2.fine_validita + 1
     ,'mmyyyy'
     )
   ,'ddmmyyyy'
   )
   ,last_day(rio2.fine_validita) + 1
   )
  ,to_date(null)
 from riferimenti_oggetto rio2
   where nvl(rio2.fine_validita
   ,to_date('31129999'
  ,'ddmmyyyy'
  )
   ) < to_date('15129999'
  ,'ddmmyyyy'
  )
  and rio2.oggetto > 0
  and inizio_validita >= to_date('01011000'
     ,'ddmmyyyy'
     )
  union
  select rio3.oggetto
  ,to_date('01011800'
    ,'ddmmyyyy'
    )
  ,to_date(null) --to_date ('01011800', 'ddmmyyyy')
 from riferimenti_oggetto rio3
   where rio3.oggetto > 0
  and to_date('01011800'
    ,'ddmmyyyy'
    ) < (select min(inizio_validita)
  from riferimenti_oggetto riox
    where riox.oggetto = rio3.oggetto)) wrkp
 group by wrkp.oggetto
   ,wrkp.inizio_validita
;
comment on table PERIODI_RIOG is 'PERI - Periodi RIOG';

