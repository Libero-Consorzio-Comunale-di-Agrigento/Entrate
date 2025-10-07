--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiorna_sanzioni_at stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     AGGIORNA_SANZIONI_AT
(a_pratica     in number
,a_flag        in varchar2
,a_utente      in varchar2
)
is
--
-- Il dato a_flag contiene i valori + o -; se + si inseriscono
-- o si incrementano le sanzioni, se - si eliminano o decrementano.
--
-- il dato a_pratica potrebbe essere anche nullo nel caso di inserimento
-- di nuova pratica.
--
-- Se pratica nuova o pratica di riferimento nulla, non si esegue alcuna
-- operazione, viceversa si va ad agire sulle singole sanzioni secondo
-- il codice della sanzione.
--
nPratica_Rif              number;
sEsiste                   varchar2(2);
nImporto                  number;
nSequenza                 number;
ntest                     number;
sTitr                      pratiche_tributo.tipo_tributo%type;
cursor sel_sapr (p_pratica number) is
select sapr.cod_sanzione
      ,sapr.sequenza_sanz
      ,sapr.importo
      ,sapr.percentuale
      ,sapr.riduzione
      ,sapr.riduzione_2
      ,sapr.note
  from sanzioni_pratica sapr
 where sapr.pratica = a_pratica
 order by
       sapr.cod_sanzione, sapr.sequenza_sanz
;
BEGIN
   BEGIN
      select pratica_rif, tipo_tributo
        into nPratica_Rif, sTitr
        from pratiche_tributo
       where pratica = a_pratica
      ;
   EXCEPTION
--
-- Caso di Pratica Nulla (nuova pratica).
--
      WHEN NO_DATA_FOUND THEN
         nPratica_Rif := null;
   END;
--
-- Solo se esiste la Pratica di Riferimento si va ad aggiornare
-- le sanzioni nella super-pratica.
--
   if nPratica_Rif is not null then
      for rec_sapr in sel_sapr(a_pratica)
      loop
         if rec_sapr.importo <> 0 then
            BEGIN
               select sapr.importo
                     ,'SI'
                 into nImporto
                     ,sEsiste
                 from sanzioni_pratica   sapr
                where sapr.cod_sanzione     = rec_sapr.cod_sanzione
                  and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
                  and sapr.pratica          = nPratica_Rif
                  and substr(sapr.note,1,5) = '<###>'
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  nImporto := 0;
                  sEsiste  := 'NO';
            END;
            if sEsiste = 'NO' then
               if a_flag = '+' then
                  SANZIONI_PRATICA_NR(nPratica_Rif,rec_sapr.cod_sanzione,rec_sapr.sequenza_sanz,nSequenza);
                  BEGIN
                     insert into sanzioni_pratica
                           (pratica,cod_sanzione,sequenza_sanz,sequenza,tipo_tributo,
                            oggetto_pratica,semestri,percentuale,
                            importo,riduzione,riduzione_2,ruolo,importo_ruolo,
                            utente,data_variazione,note
                           )
                     values(nPratica_Rif,rec_sapr.cod_sanzione,rec_sapr.sequenza_sanz,nSequenza,sTitr,
                            null,null,rec_sapr.percentuale,
                            rec_sapr.importo,rec_sapr.riduzione,rec_sapr.riduzione_2,null,null,
                            a_utente,trunc(sysdate),'<###>'||substr(rec_sapr.note,1,1995)
                          )
                     ;
                  EXCEPTION
                     WHEN OTHERS THEN
                        ROLLBACK;
                        RAISE_APPLICATION_ERROR(-20999,'Inserimento Sanzione '||SQLERRM);
                  END;
               else
                  null;
               end if;
            else
               if a_flag = '+' then
                  if nImporto + rec_sapr.importo = 0 then
                     BEGIN
                        delete from sanzioni_pratica sapr
                         where sapr.pratica          = nPratica_Rif
                           and sapr.cod_sanzione     = rec_sapr.cod_sanzione
                           and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
                           and substr(sapr.note,1,5) = '<###>'
                        ;
                     EXCEPTION
                        WHEN OTHERS THEN
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR(-20999,'Eliminazione Sanzione '||SQLERRM);
                     END;
                  else
                     BEGIN
                        update sanzioni_pratica   sapr
                           set sapr.importo          = sapr.importo + rec_sapr.importo
                              ,sapr.note             = '<###>'||substr(rec_sapr.note,1,1995)
                              ,sapr.utente           = a_utente
                              ,sapr.data_variazione  = trunc(sysdate)
                         where sapr.pratica          = nPratica_Rif
                           and sapr.cod_sanzione     = rec_sapr.cod_sanzione
                           and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
                           and substr(sapr.note,1,5) = '<###>'
                        ;
                     EXCEPTION
                        WHEN OTHERS THEN
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR(-20999,'Modifica Sanzione '||SQLERRM);
                     END;
                  end if;
               else
                  if rec_sapr.importo - nImporto = 0 then
                     BEGIN
                        delete from sanzioni_pratica sapr
                         where sapr.pratica          = nPratica_Rif
                           and sapr.cod_sanzione     = rec_sapr.cod_sanzione
                           and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
                           and substr(sapr.note,1,5) = '<###>'
                        ;
                     EXCEPTION
                        WHEN OTHERS THEN
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR(-20999,'Eliminazione Sanzione '||SQLERRM);
                     END;
                  else
                     BEGIN
                        update sanzioni_pratica      sapr
                           set sapr.importo          = sapr.importo - rec_sapr.importo
                              ,sapr.note             = '<###>'||substr(rec_sapr.note,1,1995)
                              ,sapr.utente           = a_utente
                              ,sapr.data_variazione  = trunc(sysdate)
                         where sapr.pratica          = nPratica_Rif
                           and sapr.cod_sanzione     = rec_sapr.cod_sanzione
                           and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
                           and substr(sapr.note,1,5) = '<###>'
                        ;
                     EXCEPTION
                        WHEN OTHERS THEN
                           ROLLBACK;
                           RAISE_APPLICATION_ERROR(-20999,'Modifica Sanzione '||SQLERRM);
                     END;
                  end if;
               end if;
            end if;
         end if;
      end loop;
   end if;
EXCEPTION
   WHEN OTHERS THEN
      rollback;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: AGGIORNA_SANZIONI_AT */
/
