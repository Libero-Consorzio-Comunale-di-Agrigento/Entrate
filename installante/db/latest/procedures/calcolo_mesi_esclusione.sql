--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_mesi_esclusione stripComments:false runOnChange:true 
 
CREATE OR REPLACE PROCEDURE CALCOLO_MESI_ESCLUSIONE
/*************************************************************************
  Calcola le quote dei mesi di un immobile con esclusione parziale
  ----------------------------------------------------------------------
  Rev.  Date         Author   Note
  001   18/01/2024   RV       #66359
                              Modifcato per MP1S1 maggiore di MP1
                              Modificato per propagare il valore di MP1S in MP1S1 nel caso MEI = MPI
  000   12/10/2023   DM       #66659
                              Versione iniziale
*************************************************************************/
(mp_iniziali   in NUMBER,     -- Dati iniziali
 fp_iniziale   in VARCHAR2,
 mp1s_iniziali in NUMBER,
 me_iniziali   in NUMBER,
 mp1           out NUMBER,    -- Porzione con esclusione
 mp1s1         out NUMBER,
 me1           out NUMBER,
 fe1           out VARCHAR2,
 mp2           out NUMBER,    -- Porzione senza esclusione
 mp1s2         out NUMBER,
 me2           out NUMBER,
 fe2           out VARCHAR2)
IS

BEGIN

  -- Verifica 1
  IF mp_iniziali < 0 OR mp_iniziali > 12 THEN
    RAISE_APPLICATION_ERROR(-20001,
                            'MP_INIZIALI deve essere compreso tra 0 e 12');
  END IF;

  -- Verifica 2
  IF me_iniziali < 0 OR me_iniziali > mp_iniziali THEN
    RAISE_APPLICATION_ERROR(-20002,
                            'ME_INIZIALI deve essere compreso tra 0 e MP_INIZIALI');
  END IF;

  -- Verifica 3
  IF fp_iniziale IS NULL THEN
    IF mp1s_iniziali < 0 OR mp1s_iniziali > least(6, mp_iniziali) THEN
      RAISE_APPLICATION_ERROR(-20003,
                              'MP1S_INIZIALI deve essere compreso tra 0 e min(6, MP_INIZIALI)');
    END IF;
  ELSE
    IF mp1s_iniziali < 0 OR mp1s_iniziali > greatest(0, mp_iniziali - 6) THEN
      RAISE_APPLICATION_ERROR(-20003,
                              'MP1S_INIZIALI deve essere compreso tra 0 e max(0, MP_INIZIALI - 6)');
    END IF;
  END IF;

  -- Calcolo del valore di MP1
  IF me_iniziali = mp_iniziali THEN
    fe1 := 'S';
    mp1 := mp_iniziali;
    me1 := me_iniziali;
    mp1s1 := mp1s_iniziali;
  ELSE
    mp1 := me_iniziali;
    fe1 := 'S';

    IF fp_iniziale IS NULL THEN
      mp1s1 := null;
    ELSE
    --mp1s1 := greatest(0, mp_iniziali - 6);
      mp1s1 := least(greatest(0, mp_iniziali - 6), mp1);          -- Senno esce maggiore di mp1
    END IF;
    mp2 := mp_iniziali - me_iniziali;
    fe2 := NULL;

    IF fp_iniziale IS NULL THEN
      mp1s2 := null;
    ELSE
      mp1s2 := greatest(0, mp_iniziali - MP1 - 6);
    END IF;
    me2 := 0;
  END IF;

END;
/* End Procedure: CALCOLO_MESI_ESCLUSIONE */
/
