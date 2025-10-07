--liquibase formatted sql 
--changeset abrandolini:20250326_152423_sostituzione_contribuente stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     SOSTITUZIONE_CONTRIBUENTE
/*************************************************************************
 NOME:        SOSTITUZIONE_CONTRIBUENTE

 DESCRIZIONE: Sostituisce un contribuente con un altro in tutte le tabelle
              collegate

 NOTE:        Se il messaggio non e' nullo, significa che si e' verificato
              un errore.

 Rev.    Date         Author      Note
 001     21/03/2024   AB          #69103
                                  Aggiunti due campi ni_old e ni_new nel lancio
                                  di contriuenti_cu
 000     28/04/2020   VD          Prima emissione
*************************************************************************/
( p_cod_fiscale_old               varchar2
, p_cod_fiscale_new               varchar2
, p_ni_old                        number
, p_ni_new                        number
, p_messaggio                     IN OUT varchar2
) is
  w_cf                            varchar2(16);
  w_ni                            number;
  w_conta                         number;
  errore                          exception;
begin
  p_messaggio := null;
  -- Controllo esistenza nuovo contribuente
  select count(*)
    into w_conta
    from contribuenti
   where ni          = p_ni_new
      or cod_fiscale = p_cod_fiscale_new;
  -- Se il risultato della select e' 0, significa che non esiste in CONTRIBUENTI
  -- un record con i nuovi NI o CF
  if w_conta = 0 then
     -- Aggiornamento Soggetti con dati contribuente
     begin
       update soggetti sogg
          set sogg.note = (select substr(sogg.note||' - Dati Contr. '||
                                  decode(cont.cod_contribuente,null,
                                         decode(cont.cod_controllo
                                               ,null,null
                                                    ,cont.cod_controllo),
                                         decode(cont.cod_controllo
                                               ,null,cont.cod_contribuente,
                                                     cont.cod_contribuente||' - '||
                                                     cont.cod_controllo)
                                        )||
                                  decode(cont.note
                                        ,null,null
                                             ,decode(cont.cod_contribuente||cont.cod_controllo
                                                    ,null,cont.note
                                                         ,' - '||cont.note)
                                        )
                                        ,1,200)
                             from contribuenti cont
                            where cont.ni = p_ni_old
                              and cont.cod_contribuente||cont.cod_controllo||cont.note
                                  is not null
                          )
        where sogg.ni = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Soggetti - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento Contribuenti con dati nuovo soggetto
     begin
       update contribuenti
          set ni               = p_ni_new,
              cod_fiscale      = p_cod_fiscale_new,
              cod_contribuente = null,
              cod_controllo    = null,
              note             = null
        where ni = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Contribuenti - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento familiari soggetto
     begin
       update familiari_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Familiari_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento recapiti soggetto
     begin
       update recapiti_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Recapiti_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     goto FINE;
  end if;
  -- Esistono dei record di CONTRIBUENTI con cd o ni nuovi
  w_conta := 0;
  select count(*)
    into w_conta
    from contribuenti
   where ni          = p_ni_new
     and cod_fiscale = p_cod_fiscale_new;

  -- Esiste un record in CONTRIBUENTI con uguale NI e CF
  if w_conta = 1 then
     begin
       contribuenti_cu(p_cod_fiscale_old, p_cod_fiscale_new, p_ni_old, p_ni_new);
     exception
       when others then
         raise;
     end;

     -- Aggiornamento Soggetti con i dati del nuovo contribuente
     begin
       update soggetti sogg
          set sogg.note = (select substr(sogg.note||' - Dati Contr. '||
                                  decode(cont.cod_contribuente
                                        ,null,decode(cont.cod_controllo
                                                    ,null,null
                                                         ,cont.cod_controllo)
                                             ,decode(cont.cod_controllo
                                                    ,null,cont.cod_contribuente
                                                         ,cont.cod_contribuente||' - '||
                                                          cont.cod_controllo)
                                        )||
                                  decode(cont.note
                                        ,null,null
                                             ,decode(cont.cod_contribuente||cont.cod_controllo
                                                    ,null,cont.note
                                                         ,' - '||cont.note)
                                        )
                                        ,1,200)
                             from contribuenti cont
                            where cont.cod_fiscale = p_cod_fiscale_old
                              and cont.cod_contribuente||cont.cod_controllo||cont.note
                                  is not null
                          )
        where sogg.ni = p_ni_old;
     exception
      when others then
        p_messaggio := substr('Upd. Soggetti - ni '||p_ni_old||' ('||sqlerrm,1,2000);
        raise errore;
     end;
     -- Aggiornamento familiari soggetto
     begin
       update familiari_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Familiari_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento recapiti soggetto
     begin
       update recapiti_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Recapiti_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Eliminazione vecchio contribuente
     begin
       delete contribuenti
        where cod_fiscale = p_cod_fiscale_old;
     exception
       when others then
         p_messaggio := substr('Del. Contribuenti - cf '||p_cod_fiscale_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     goto FINE;
  end if;
  -- Si controlla se esiste un record di contribuenti con lo stesso ni e c.f. diverso
  w_conta := 1;
  begin
    select cod_fiscale
      into w_cf
      from contribuenti
     where ni           = p_ni_new
       and cod_fiscale <> p_cod_fiscale_new;
  exception
    when others then
      w_conta := 0;
  end;
  -- Esiste un record in CONTRIBUENTI con uguale NI e diverso CF
  if w_conta = 1 then
     p_messaggio := 'Il Soggetto di destinazione con ni '||p_ni_new||
                    ' è già contribuente con Codice Fiscale '|| w_cf||'.'||
                    ' Intervenire sul Contribuente di Destinazione e poi'||
                    ' ripetere la sostituzione.';
     raise errore;
  end if;
-- Esiste un record di CONTRIBUENTI con c.f. nuovo e ni vecchio
  w_conta := 0;
  select count(*)
    into w_conta
    from contribuenti
   where cod_fiscale  = p_cod_fiscale_new
     and ni           = p_ni_old;
  -- Esiste un record in CONTRIBUENTI con diverso NI e uguale CF
  if w_conta = 1 then
     -- Aggiornamento Contribuenti
     begin
       update contribuenti
          set ni = p_ni_new
        where ni = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Contribuenti - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento familiari soggetto
     begin
       update familiari_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old;
     exception
       when others then
         p_messaggio := substr('Upd. Familiari_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
     -- Aggiornamento recapiti soggetto
     begin
       update recapiti_soggetto
          set ni               = p_ni_new
        where ni               = p_ni_old
         ;
     exception
       when others then
         p_messaggio := substr('Upd. Recapiti_soggetto - ni '||p_ni_old||' ('||sqlerrm,1,2000);
         raise errore;
     end;
  else
     select ni
       into w_ni
       from contribuenti
      where cod_fiscale = p_cod_fiscale_new;
     p_messaggio := 'Il Soggetto di destinazione con ni '||w_ni||
                    ' è già contribuente con Codice Fiscale '||p_cod_fiscale_new||'.'||
                    ' Intervenire sul Contribuente di Destinazione e poi'||
                    ' ripetere la sostituzione.';
     raise errore;
  end if;
  << FINE >>
  null;
exception
  when errore
    then null;
  when others
    then raise;
end;
/* End Procedure: SOSTITUZIONE_CONTRIBUENTE */
/
