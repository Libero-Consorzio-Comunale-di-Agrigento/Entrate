--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_pratica_at stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CARICA_PRATICA_AT
/***************************************************************************
  001   30/10/2024  AB      Aggiunto sequenza_sanz
***************************************************************************/
(a_pratica_ins     IN OUT number
,a_anno            IN     number
,a_data            IN     date
,a_cod_fiscale     IN     varchar2
,a_pratica         IN     number
,a_utente          IN     varchar2
,a_tipo_tributo    IN     varchar2
) is
w_errore                  varchar2(200) := null;
errore                    exception;
nSequenza                 number;
dData_Notifica            date;
cursor sel_sapr (p_pratica number) is
select sapr.cod_sanzione
      ,sapr.sequenza_sanz
      ,sapr.semestri
      ,sapr.percentuale
      ,sapr.importo
      ,sapr.riduzione
      ,sapr.riduzione_2
      ,sapr.note
  from sanzioni_pratica sapr
 where sapr.pratica     = p_pratica
 order by
       sapr.sequenza
;
BEGIN
--
-- Se la pratica da inserire non ha valore, significa che bisogna fare
-- una nuova pratica.
--
   if a_pratica_ins is null then
      dData_Notifica := null;
      PRATICHE_TRIBUTO_NR(a_pratica_ins);
      BEGIN
         insert into pratiche_tributo
               (pratica,cod_fiscale,anno,data,tipo_tributo,tipo_pratica,tipo_evento
               ,utente,data_variazione
               )
         values(a_pratica_ins,a_cod_fiscale,a_anno,a_data,a_tipo_tributo,'A','T'
               ,a_utente,trunc(sysdate)
               )
         ;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Inserimento di Pratiche Tributo '||SQLERRM);
      END;
      nSequenza := null;
      RAPPORTI_TRIBUTO_NR(a_pratica_ins,nSequenza);
      BEGIN
         insert into rapporti_tributo
               (pratica,sequenza,cod_fiscale,tipo_rapporto)
         values(a_pratica_ins,nSequenza,a_cod_fiscale,'E')
         ;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Inserimento di Rapporti Tributo '||SQLERRM);
      END;
   else
      BEGIN
         select prtr.data_notifica
           into dData_Notifica
           from pratiche_tributo prtr
          where prtr.pratica   = a_pratica_ins
         ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in Rilettura Pratica '||to_char(a_pratica_ins));
      END;
   end if;
--
-- Trattamento delle Sanzioni. Se esiste la sanzione con lo stesso codice, si va
-- ad incrementare importo (la percentuale e la riduzione si presume che non varino
-- da accertamento a accertamento); se non esiste invece la sanzione, si esegue
-- un inserimento.
--
   for rec_sapr in sel_sapr(a_pratica)
   loop
      BEGIN
         select sapr.sequenza
           into nSequenza
           from sanzioni_pratica         sapr
          where sapr.pratica             = a_pratica_ins
            and sapr.cod_sanzione        = rec_sapr.cod_sanzione
            and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
            and substr(sapr.note,1,5)    = '<###>'
         ;
         BEGIN
            update sanzioni_pratica      sapr
               set sapr.importo          = decode(to_char(sapr.importo)||to_char(rec_sapr.importo)
                                                 ,null,null
                                                      ,nvl(sapr.importo,0) + nvl(rec_sapr.importo,0)
                                                 )
                  ,sapr.note             = '<###>'||substr(rec_sapr.note,1,1995)
                  ,sapr.utente           = a_utente
                  ,sapr.data_variazione  = trunc(sysdate)
             where sapr.pratica          = a_pratica_ins
               and sapr.cod_sanzione     = rec_sapr.cod_sanzione
               and sapr.sequenza_sanz    = rec_sapr.sequenza_sanz
               and sapr.sequenza         = nSequenza
               and substr(sapr.note,1,5) = '<###>'
            ;
         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Aggiornamento di sanzioni Pratica ['||
                                              to_char(rec_sapr.cod_sanzione)||'] '||SQLERRM);
         END;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nSequenza := null;
            SANZIONI_PRATICA_NR(a_pratica_ins,rec_sapr.cod_sanzione,rec_sapr.sequenza_sanz,nSequenza);
            BEGIN
               insert into sanzioni_pratica
                     (pratica,cod_sanzione,sequenza_sanz,sequenza,tipo_tributo,semestri
                     ,percentuale,importo,riduzione,riduzione_2
                     ,utente,data_variazione,note
                     )
               values(a_pratica_ins,rec_sapr.cod_sanzione,rec_sapr.sequenza_sanz,nSequenza,a_tipo_tributo,null
                     ,rec_sapr.percentuale,rec_sapr.importo,rec_sapr.riduzione,rec_sapr.riduzione_2
                     ,a_utente,trunc(sysdate),'<###>'||substr(rec_sapr.note,1,1995)
                     )
               ;
            EXCEPTION
               WHEN OTHERS THEN
                  ROLLBACK;
                  RAISE_APPLICATION_ERROR(-20999,'Inserimento di sanzioni Pratica ['||
                                                 to_char(rec_sapr.cod_sanzione)||'] '||SQLERRM);
            END;
      END;
   end loop;
--
-- Aggiornamento della pratica di Riferimento nella Pratica inserita.
--
   BEGIN
      update pratiche_tributo prtr
         set prtr.pratica_rif    = a_pratica_ins
            ,prtr.data_notifica  = dData_Notifica
       where prtr.pratica        = a_pratica
      ;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Aggiornamento di Pratiche Tributo ['||
                                        to_char(a_pratica)||'] '||SQLERRM);
   END;
   if a_tipo_tributo = 'TARSU' then
       declare
       dep_tipo_calcolo varchar2(1);
       BEGIN
          select nvl(tipo_calcolo, 'T')
            into dep_tipo_calcolo
            from pratiche_tributo prtr
           where prtr.pratica_rif    = a_pratica_ins
             and rownum = 1
          ;
          update pratiche_tributo
             set tipo_calcolo = dep_tipo_calcolo
           where pratica = a_pratica_ins;
       EXCEPTION
          WHEN OTHERS THEN
             ROLLBACK;
             RAISE_APPLICATION_ERROR(-20999,'Aggiornamento di Pratiche Tributo Modifica del tipo calcolo ['||
                                            to_char(a_pratica_ins)||'] '||SQLERRM);
       END;
   end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore);
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,SQLERRM);
END;
/* End Procedure: CARICA_PRATICA_AT */
/
