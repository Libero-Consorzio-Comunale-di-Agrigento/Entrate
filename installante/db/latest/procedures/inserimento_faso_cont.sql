--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_faso_cont stripComments:false runOnChange:true 
 
create or replace procedure INSERIMENTO_FASO_CONT
(a_ni          in     number
,a_anno        in     number
,a_dal         in     date
,a_scad_parz   in     varchar2
,a_raggruppa   in     varchar2
,a_modalita_familiari in number
,a_stringa     in out varchar2
) is
-- Modalita_familiari può assumere i seguenti valori:
-- 1 - Data Evento
-- 2 - Mese successivo a Evento
-- 3 - Bimestre successivo a Evento
-- 4 - Semestre successivo a Evento
-- 5 - Mese sulla base del giorno 15
-- 09/12/14 AB Si controlla se esistono record in ANAEVE, controllo spostato qui,
--          prima era in f_numero_familiari_al
-- 24/09/14 Betta T. Modificato x dare una sola segnalazione di errore x Ni in caso
--               di elab. massiva: altrimenti (se elab. alla data evento) il primo Ni
--               esaurisce la stringa degli errori
-- 23/09/14 Betta Tinti e Piero Montosi. Modifiche per gestire il caso di numero di
--                                       familiari che va a 0
cursor sel_ni is
select distinct
       cont.ni
--      ,cont.cod_fiscale
      ,sogg.tipo_residente
      ,sogg.fascia
      ,sogg.data_ult_eve
  from contribuenti       cont
      ,soggetti           sogg
      ,pratiche_tributo   prtr
 where cont.cod_fiscale      = prtr.cod_fiscale
   and sogg.ni               = cont.ni
   and prtr.tipo_tributo||'' = 'TARSU'
   and cont.ni         between nvl(a_ni,0)
                           and nvl(a_ni,9999999999)
union
select distinct
       sogg.ni
--      ,sogg.cod_fiscale
      ,sogg.tipo_residente
      ,sogg.fascia
      ,sogg.data_ult_eve
  from soggetti           sogg
 where sogg.ni      = a_ni
 order by 1
;
type t_dal_t     is table of date      index by binary_integer;
type t_al_t      is table of date      index by binary_integer;
type t_nfam_t    is table of number    index by binary_integer;
t_dal                     t_dal_t;
t_al                      t_al_t;
t_nfam                    t_nfam_t;
bInd                      binary_integer;
type t_dal_t2    is table of date      index by binary_integer;
type t_al_t2     is table of date      index by binary_integer;
type t_nfam_t2   is table of number    index by binary_integer;
t_dal2                    t_dal_t2;
t_al2                     t_al_t2;
t_nfam2                   t_nfam_t2;
bInd2                     binary_integer;
bTot                      binary_integer;
dData                     date;
dData_15                  date := null;  -- serve solo se calcolo su Mese sulla base del giorno 15
dDal                      date;
dAl                       date;
dFine_Anno                date;
nAnno                     number;
nNi                       number;
nFam                      number;
nInizio_Loop              number;
nFine_Loop                number;
nConta                    number;
nTrattati                 number;
sStringa                  varchar2(2000);
nNi_err                   number;
w_modalita_familiari      number;
w_conta_anaeve            number;
BEGIN
   if a_dal > trunc(sysdate) then
      raise_application_error(-20999,'Impossibile inserire informazioni aventi '||
                                     'una data maggiore di quella corrente.');
   end if;
   if to_number(to_char(a_dal,'dd')) <> 1 then
      raise_application_error(-20999,'La data deve coincidere con un inizio mese.');
   end if;
   sStringa := null;
   nNi_err := null;
   nTrattati := 0;
   -- se modificata, salviamo su CARICHI_TARSU la modalità richiesta
   update carichi_tarsu
   set    modalita_familiari = a_modalita_familiari
   where  anno = a_anno
   and    nvl(modalita_familiari,99) != a_modalita_familiari
   ;
   commit;
--
-- Se c`e` richiesta di scadenze parziali, il periodo va dal mese della data
-- dei parametri al mese della data di sistema, altrimenti si tratta il solo
-- mese della data dei parametri.
--
   if a_scad_Parz = 'S' then
-- a seconda del parametro modalità familiari il calcolo può essere eseguito
-- mensilmente, giornalmente, bimestralmente o semestralmente.
-- Le variabili possono quindi contenere il mese di inizio e fine
-- oppure il giorno (dell'anno) di inizio e fine, oppure il bimestre di inizio e
-- fine oppure il semestre di inizio e fine
--
-- Solo se l'anno di sistema è uguale a quello della data dei parametri il periodo va
-- dal mese della data dei parametri al mese della data di sistema, altrimenti il periodo
-- va dal mese della data dei parametri fino alla fine dell'anno  (Piero 28-03-06)
--
--
      dFine_Anno := to_date('31/12'||to_char(a_Dal,'yyyy'),'dd/mm/yyyy');
      w_modalita_familiari := a_modalita_familiari;
      if w_modalita_familiari = 1 then -- Data Evento
         nInizio_Loop      := to_number(to_char(a_Dal,'ddd'));
         nFine_Loop        := to_number(to_char(least(trunc(sysdate),dFine_Anno),'ddd'));
      elsif w_modalita_familiari = 2 then -- Mese successivo a Evento
         nInizio_Loop      := to_number(to_char(a_Dal,'mm'));
         nFine_Loop        := to_number(to_char(least(trunc(sysdate),dFine_Anno),'mm'));
      elsif w_modalita_familiari = 3 then -- Bimestre successivo a Evento
         nInizio_Loop      := trunc(to_number(to_char(a_Dal,'mm'))/2)+1;
         nFine_Loop        := trunc(to_number(to_char(least(trunc(sysdate),dFine_Anno),'mm'))/2);
      elsif w_modalita_familiari = 4 then -- Semestre successivo a Evento
         nInizio_Loop      := trunc(to_number(to_char(a_Dal,'mm'))/6)+1;
         nFine_Loop        := trunc(to_number(to_char(least(trunc(sysdate),dFine_Anno),'mm'))/6);
      else -- Mese sulla base del giorno 15
         nInizio_Loop      := to_number(to_char(a_Dal,'mm'));
         nFine_Loop        := to_number(to_char(least(trunc(sysdate),dFine_Anno),'mm'));
      end if;
   else
   -- se non si calcolano le scadenze parziali, il calcolo è sempre riferito solo al mese (come caso 2)
      w_modalita_familiari := 2;
      nInizio_Loop      := to_number(to_char(a_Dal,'mm'));
      nFine_Loop      := to_number(to_char(a_Dal,'mm'));
   end if;
--dbms_output.put_line('Periodo da '||to_char(nInizio_Loop)||' a '||to_char(nFine_Loop)||' / '||to_char(a_anno));
--dbms_output.put_line('Parziali '||a_scad_parz||' Raggruppamento '||a_raggruppa||' ni '||to_char(a_ni));
--  Si controlla se esistono record in ANAEVE, controllo spostato qui, prima era in f_numero_familiari_al AB 09/12/14
     BEGIN
      select count(*)
        into w_conta_anaeve
        from anaeve
       ;
     EXCEPTION
       WHEN others THEN
               RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca record in ANAEVE');
     END;
--
-- Si esaminano i Contribuenti TARSU.
--
   FOR rec_ni in sel_ni
   LOOP
      nNi := rec_ni.ni;
dbms_output.put_line('Soggetto: '||to_char(nNi));
      t_dal.delete;
      t_al.delete;
      t_nfam.delete;
      t_dal2.delete;
      t_al2.delete;
      t_nfam2.delete;
--
-- SI riempono le tabelle in rapporto ai mesi da trattare.
--
      bInd2 := 0;
      FOR bInd in nInizio_Loop .. nFine_Loop
      LOOP
         if w_modalita_familiari = 1 then -- Data Evento
            dData := to_date(bInd||'/'||lpad(to_char(a_anno),4,'0'),'ddd/yyyy');
            dData_15 := null;
         elsif w_modalita_familiari = 2 then -- Mese successivo a Evento
            dData := to_date('01'||lpad(to_char(bInd),2,'0')||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
            dData_15 := null;
         elsif w_modalita_familiari = 3 then -- Bimestre successivo a Evento
            dData := to_date('01'||lpad(to_char((bInd*2)-1),2,'0')||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
            dData_15 := null;
         elsif w_modalita_familiari = 4 then -- Semestre successivo a Evento
            dData := to_date('01'||lpad(to_char((bInd*6)-5),2,'0')||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
            dData_15 := null;
         else -- Mese sulla base del giorno 15
            dData := to_date('01'||lpad(to_char(bInd),2,'0')||lpad(to_char(a_anno),4,'0'),'ddmmyyyy');
            dData_15 := last_day(to_date('01'||lpad(to_char(bInd),2,'0')||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
                        -15; --deve essere familiare per almeno 15 giorni per entrare nel mese.
            --in questo caso, il primo e l'ultimo giorno del mese identificano sempre il periodo
            -- utilizziamo l'altra data (dData_15) per det. il numero di familiari
         end if;
         -- determiniamo il numero dei familiari alla data di inizio del periodo
         -- solo se calcolo è mese sulla base del giorno 15 usiamo la data det. in precedenza
         nFam  := F_NUMERO_FAMILIARI_AL(nNi,nvl(dData_15,dData),w_conta_anaeve);
         if SQLCODE <> 0 then
            raise_application_error(-20999,'Errore in f_numero_familiari_al del Soggetto con Ni '||to_char(nNi)||
                                           ' e data '||to_char(nvl(dData_15,dData),'dd/mm/yyyy'));
         end if;
         if nvl(nFam,0) <= 0 then
            nFam := 0;
         end if;
         if nFam = 0 and rec_ni.tipo_residente = 0 and rec_ni.fascia in (1,3) and rec_ni.data_ult_eve <= nvl(dData_15,dData) then
            if a_ni is null then
               if nNi != nvl(nNi_err,-99999999999999999) then -- Diamo una sola segnalazione x NI.
                  nNi_err := nNi;
                  if length(sStringa||chr(13)||chr(10)||'Ni '||to_char(nNi)||' senza familiari dal '||to_char(nvl(dData_15,dData),'dd/mm/yyyy')) > 1995 then
                     if substr(sStringa,length(sStringa) - 2) <> '...' then
                        sStringa := sStringa||' ...';
                     end if;
                  else
                     sStringa := sStringa||chr(13)||chr(10)||'Ni '||to_char(nNi)||' senza familiari dal '||to_char(nvl(dData_15,dData),'dd/mm/yyyy');
                  end if;
               end if;
            else
               RAISE_APPLICATION_ERROR(-20998,'Il Soggetto '||to_char(nNi)||
                                              ' non ha familiari al '||to_char(nvl(dData_15,dData),'dd/mm/yyyy'));
            end if;
         end if;
         bInd2 := bInd2 + 1;
         t_dal(bInd2)   := dData;
         if bInd = nFine_Loop then
            t_al(bInd2) := null;
         else
            if w_modalita_familiari = 1 then -- Data Evento
               t_al(bInd2) := dData;
            elsif w_modalita_familiari = 2 then -- Mese successivo a Evento
               t_al(bInd2) := last_day(dData);
            elsif w_modalita_familiari = 3 then -- Bimestre successivo a Evento
               t_al(bInd2) := last_day(add_months(dData,1));
            elsif w_modalita_familiari = 4 then -- Semestre successivo a Evento
               t_al(bInd2) := last_day(add_months(dData,5));
            else -- Mese sulla base del giorno 15
               t_al(bInd2) := last_day(dData);
            end if;
         end if;
         t_nfam(bInd2)  := nFam;
         dDal := t_dal(bInd2);
         dAl := t_al(bInd2);
         nFam := t_nFam(bInd2);
dbms_output.put_line('Carica Tabella '||to_char(bInd2)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam));
      END LOOP;
      bTot := bInd2;
--
-- Controllo che  non esistano periodi intersecanti coi periodi da inserire;
-- l`unico caso tollerato e` quello riferito ad un periodo intersecante  con
-- al nullo e dal < del primo periodo da inserire; in questo caso poi verra`
-- riportata la data del primo periodo inserito - 1 nella data al nulla.
-- In caso di presenza di periodo intersecante, viene posto = 0 il numero di
-- familiari del periodo in maniera da non essere trattato successivamente.
-- Gli elementi con numero di familiari significativo  vengono copiati nelle
-- tabelle relative.
--
      bInd2 := 0;
      FOR bInd in 1 .. bTot
      LOOP
         dDal  := t_dal(bInd);
         dAl   := t_al(bInd);
         dData := t_al(bInd); -- si memorizza al in dData perche` in faso esiste un dato con nome dal
         BEGIN
            select count(*)
              into nConta
              from familiari_soggetto faso
             where faso.ni                   = nNi
               and faso.anno                 = a_anno
               and trunc(faso.dal)          <= nvl(dData,to_date('31122999','ddmmyyyy'))
               and trunc(nvl(faso.al,to_date('31122999','ddmmyyyy')))
                                             >= dDal
               and (    trunc(faso.dal) between dDal
                                            and nvl(dData,to_date('31122999','ddmmyyyy'))
                    or  faso.al              is not null
                   )
            ;
            if nConta > 0 then
               t_nFam(bInd) := 0;
            end if;
            if t_nFam(bInd) > 0 then
               bInd2          := bInd2 + 1;
               t_dal2(bInd2)  := t_dal(bInd);
               t_al2(bInd2)   := t_al(bInd);
               t_nFam2(bInd2) := t_nFam(bInd);
            end if;
         END;
         nFam := t_nFam(bInd);
--dbms_output.put_line('Controllo Periodi '||to_char(bInd)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
--to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam)||' Conta '||to_char(nConta));
      END LOOP;
      bTot := bInd2;
dbms_output.put_line('Elementi Totali Validi = '||to_char(bTot));
--
-- Se sono rimasti periodi validi, si puliscono le tabelle di partenza
-- e si ricopia il primo elemento.
-- Se poi vi sono altri elementi (caso di scadenze parziali), allora si
-- riportano anch`essi nelle tabelle di partenza.
-- Se pero` e` stato richiesto dai parametri  di raggruppare per numero
-- di familiari, si esamina  se esistono  periodi successivi con uguale
-- numero di familiari; in questo caso, si procede al raggruppamento di
-- uno o piu` periodi consecutivi in uno unico.
--
      if bTot > 0 then
--         t_al2(bTot) := null;
         t_dal.delete;
         t_al.delete;
         t_nFam.delete;
         t_dal(1)    := t_dal2(1);
         t_al(1)     := t_al2(1);
         t_nFam(1)   := t_nFam2(1);
         bInd        := 1;
         dDal := t_dal(bInd);
         dAl := t_al(bInd);
         nFam := t_nFam(bInd);
dbms_output.put_line('Primo elemento '||to_char(bInd)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam));
         if a_scad_parz = 'S' and bTot > 1 then
            if a_raggruppa = 'S' then
               FOR bInd2 in 2 .. bTot
               LOOP
                  if t_nfam2(bInd2) = t_nFam(bInd) and t_dal2(bInd2) = t_al(bInd) + 1 then
                     t_al(bInd)     := t_al2(bInd2);
                  else
                     bInd           := bInd + 1;
                     t_dal(bInd)    := t_dal2(bInd2);
                     t_al(bInd)     := t_al2(bInd2);
                     t_nFam(bInd)   := t_nFam2(bInd2);
                  end if;
                  dDal := t_dal(bInd);
                  dAl := t_al(bInd);
                  nFam := t_nFam(bInd);
dbms_output.put_line('Raggruppa '||to_char(bInd)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam));
               END LOOP;
            else
               FOR bInd2 in 2 .. bTot
               LOOP
                  bInd           := bInd + 1;
                  t_dal(bInd)    := t_dal2(bInd2);
                  t_al(bInd)     := t_al2(bInd2);
                  t_nFam(bInd)   := t_nFam2(bInd2);
                  dDal := t_dal(bInd);
                  dAl := t_al(bInd);
                  nFam := t_nFam(bInd);
dbms_output.put_line('Non Raggruppa '||to_char(bInd)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam));
               END LOOP;
            end if;
         end if;
         bTot := bInd;
--
-- Analisi tabelle di lavoro.
--
         FOR bInd in 1 .. bTot
         LOOP
         dDal := t_dal(bInd);
         dAl := t_al(bInd);
         nFam := t_nFam(bInd);
dbms_output.put_line('Inserimenti '||to_char(bInd)||' Periodo '||to_char(dDal,'dd/mm/yyyy')||' - '||
to_char(dal,'dd/mm/yyyy')||' Fam '||to_char(nFam));
            dData := t_dal(bInd);
--
-- Sul primo periodo si controlla  se esiste  un periodo precedente con al
-- non definito; in questo caso si va ad aggiornare  il periodo precedente
-- mettendo  nella data al il valore della data minore tra la data dal del
-- primo periodo - 1 e la data di fine anno.
-- Non si cambia la data di variazione pere non far scattare il suppletivo
-- a fronte di una semplice chiusura di periodo.
--
            IF bInd = 1 THEN
               BEGIN
                  select faso.dal
                        ,faso.al
                        ,faso.anno
                    into dDal
                        ,dAl
                        ,nAnno
                    from familiari_soggetto faso
                   where faso.ni            = nNi
                     and faso.dal           =
                        (select max(fas2.dal)
                           from familiari_soggetto fas2
                          where fas2.ni     = nNi
                            and fas2.dal    < dData
                        )
                  ;
                  IF dAl is null then
                     BEGIN
                        update familiari_soggetto faso
                           set faso.al      = least(to_date('3112'||lpad(to_char(faso.anno),4,'0'),'ddmmyyyy')
                                                   ,dData - 1
                                                   )
                              ,faso.data_variazione
                                            = faso.data_variazione
                         where faso.ni      = nNi
                           and faso.anno    = nAnno
                           and faso.dal     = dDal
                        ;
                     END;
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     null;
               END;
            END IF;
            dAl := t_al(bInd);
--
-- Sull`ultimo periodo che normalmente andrebbe registrato con data al nulla
-- si va a verificare se esiste un periodo successivo. In caso affermativo la
-- data al dell`ultimo periodo non e` piu` nulla ma uguale alla minore tra la
-- data dal del periodo successivo - 1 e la data di fine anno.
--
            IF bInd = bTot THEN
               BEGIN
                  select faso.dal
                    into dDal
                    from familiari_soggetto faso
                   where faso.ni            = nNi
                     and faso.dal           =
                        (select min(fas2.dal)
                           from familiari_soggetto fas2
                          where fas2.ni     = nNi
                            and fas2.dal    > dData
                        )
                  ;
-- se il periodo non termina con la fine dell'anno, vuol dire che i familiari
-- sono andati a 0, quindi dobbiamo tenere la data al che abbiamo calcolato
                  dAl := least(nvl(dAl
                                  ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                  )
                              ,dDal - 1
                              );
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                       null;
--                     dAl := null;
               END;
            END IF;
            dDal := t_dal(bInd);
            nFam := t_nFam(bInd);
            BEGIN
dbms_output.put_line('Insert '||to_char(dDal,'dd/mm/yyyy')||' - '||to_char(dAl,'dd/mm/yyyy')||' Fam '||to_char(nFam));
               insert into familiari_soggetto
                     (ni,anno,dal,al,numero_familiari)
               values(nNi,a_anno,dDal,dAl,nFam)
               ;
            END;
            nTrattati := nTrattati + 1;
--            if mod(nTrattati,100) = 0 then
--               commit;
--            end if;
         END LOOP;
      end if;
   END LOOP;
   if sStringa is not null then
      sStringa := substr(sStringa,3);
   end if;
   if sStringa is null and nTrattati = 0 then
      sStringa := 'NO_TRATTATI';
   end if;
   a_stringa := sStringa;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20999,to_char(nNi)||' -- '||SQLERRM);
END;
/* End Procedure: INSERIMENTO_FASO_CONT */
/

