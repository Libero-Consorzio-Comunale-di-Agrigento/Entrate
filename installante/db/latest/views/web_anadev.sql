--liquibase formatted sql 
--changeset abrandolini:20250326_152401_web_anadev stripComments:false runOnChange:true 
 
CREATE OR REPLACE FORCE VIEW WEB_ANADEV AS
SELECT cod_ev, descrizione, segnalazione,
       case
        when cod_ev in (1,  -- Nascita
                        2,  -- Immigrazione
                        3,  -- Reimmigrazione
                        4,  -- Reimmigrazione da AIRE
                        5,  -- Iscrizione d'Ufficio
                        6,  -- Iscrizione d'Ufficio AIRE
                        7,  -- Trasferimento AIRE da altro Comune
                        8,  -- Acquisto cittadinanza italiana
                        9,  -- Reiscrizione da Irreperibilita'
                        10, -- Residenza all'estero
                        11, -- Reiscrizione da mancato rinnovo
                        12,
                        13,
                        16,
                        17,
                        19,
                        50, -- Morte
                        51, -- Emigrazione
                        52, -- Emigrazione AIRE
                        53, -- Irreperibilita'
                        54, -- Irreperibilita' presunta
                        55, -- Immigrazione in altro Comune
                        56, -- Trasferimento AIRE in altro Comune
                        57, -- Perdita cittadinanza italiana
                        58,
                        59,
                        60,
                        61,
                        63,
                        64,
                        70, -- In attesa di iscrizione
                        71, -- Iscrizione annullata
                        72,
                        73
                        ) then 'S'
        else null
       end flag_stato
  FROM anadev
union
select -1,'CESSAZIONE ATTIVITA''',1,null
  from dual
/
comment on table WEB_ANADEV is 'WEB_ANADEV'
/
