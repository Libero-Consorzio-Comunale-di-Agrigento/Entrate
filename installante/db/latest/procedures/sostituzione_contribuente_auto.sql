--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sostituzione_contribuente_auto stripComments:false runOnChange:true 
 
create or replace procedure SOSTITUZIONE_CONTRIBUENTE_AUTO
(a_omonimi       varchar2,
 a_delete_nores    varchar2)
IS
CURSOR sel_ni(a_omonimi  varchar2) IS
    SELECT nores.ni           ni_nores,
           res.ni             ni_res,
           cres.ni            cont_ni_res,
           cres.cod_fiscale   cont_cod_fiscale_res,
           nores.cognome_nome nom_nores
      from soggetti     nores,
           soggetti     res,
           contribuenti cont,
           contribuenti cres
     where (res.fascia            = 1 or res.fascia = 2 and res.stato = 50)
      and res.tipo_residente     = 0
      and res.cod_fiscale        = nores.cod_fiscale
      and decode(a_omonimi,'SI',res.cognome_nome,nores.cognome_nome)
                                 = nores.cognome_nome
      and nores.tipo_residente   = 1
      and nores.ni               = cont.ni
      and res.ni                 = cres.ni (+)
      and not exists (select 1
                        from soggetti sogg_presso
                       where sogg_presso.ni_presso = nores.ni)
   ;
begin
   for rec_ni in sel_ni(a_omonimi) loop
-- Se i dati del cursore relativi alla tabella contribuenti del soggetto residente
-- non sono nulli (esiste il record), si segnala e si termina, perche` non e`
-- possibile stabilire quale sia il vero contribuente (se va bene quello che c`e`
-- o quello che si vuole sostituire).
      if rec_ni.cont_ni_res is not null then
         rollback;
         RAISE_APPLICATION_ERROR(-20999,
              'Il soggetto '||rec_ni.nom_nores||' con ni '||to_char(rec_ni.ni_nores)||
              ' e` gia` contribuente con ni '||to_char(rec_ni.ni_res)||' e codice fiscale '||
              rec_ni.cont_cod_fiscale_res);
      end if;
      BEGIN
          update contribuenti cont
             set cont.ni = rec_ni.ni_res
           where cont.ni = rec_ni.ni_nores
          ;
       EXCEPTION
           WHEN others THEN
            RollBack;
              RAISE_APPLICATION_ERROR
              (-20999,'Errore in Aggiornamento sulla Tabella: CONTRIBUENTI, NI: '||rec_ni.ni_nores);
      END;
      if a_delete_nores = 'SI' then -- Si desidera Eliminare i Soggetti non piu" Contribuenti
         BEGIN
       delete soggetti
             where ni = rec_ni.ni_nores
          and ni_presso is null
            ;
    IF SQL%FOUND THEN GOTO UPD_SOGGETTI;
         ELSE GOTO SALTA_UPD_SOGGETTI;
    END IF;
         EXCEPTION
            WHEN others THEN
               RollBack;
               RAISE_APPLICATION_ERROR
               (-20999,'Errore in Eliminazione nella Tabella: SOGGETTI, NI: '||rec_ni.ni_nores||' '||SQLERRM);
         END;
    << UPD_SOGGETTI >>
         BEGIN
            update soggetti
          set note = note||' Eliminazione NI='||rec_ni.ni_nores
        where ni = rec_ni.ni_res
       ;
         EXCEPTION
            WHEN others THEN
               RollBack;
               RAISE_APPLICATION_ERROR
               (-20999,'Errore in Aggiornamento nella Tabella: SOGGETTI, NI: '||rec_ni.ni_res||' '||SQLERRM);
         END;
    << SALTA_UPD_SOGGETTI >>
    null;
      end if;
   end loop;
end;
/* End Procedure: SOSTITUZIONE_CONTRIBUENTE_AUTO */
/

