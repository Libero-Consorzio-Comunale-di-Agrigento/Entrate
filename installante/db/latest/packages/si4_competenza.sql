--liquibase formatted sql 
--changeset abrandolini:20250326_152429_si4_competenza stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE SI4_COMPETENZA IS
/******************************************************************************
 NOME:        SI4_COMPETENZA
 DESCRIZIONE: Package di gestione competenze sugli oggetti  di database
 ANNOTAZIONI: Versione V1.2
 REVISIONI:   valberico - giovedi 15 gennaio 2004 9.58.48
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 0     __/__/____  VA      Creazione.
 1    21/01/2005   VA     Gestione competenze ricorsive sui gruppi
 2    01/02/2005   VA     Introddotta Function Oggetti
******************************************************************************/
revisione varchar2(30) := 'V1.2';
Function  VERSIONE
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce la versione e la data di distribuzione del package.
 RITORNA:     stringa VARCHAR2 contenente versione e data.
 NOTE:        Il secondo numero della versione corrisponde alla revisione
              del package.
******************************************************************************/
RETURN VARCHAR2;
Pragma restrict_references(VERSIONE, WNDS, WNPS);
Function assegna
/******************************************************************************
 NOME:        assegna
 DESCRIZIONE: Registra la competenza per il soggetto (utente o gruppo) indicato, relativamente alla abilitazione di un determinato oggetto.
              - chiude periodo precedente alla data DAL - 1
              - sposta periodo successivo alla data AL+ 1
              - elimina periodi contenuti
              Return:
               0 : Inserimento corretto
              -1 : Tipo di abilitazione incompatibile con l'oggetto indicato
              -2 : Non esiste l'oggetto
              -3 : Non esiste il tipo di abilitazione
******************************************************************************/
( p_Tipo_Oggetto IN VARCHAR2
, p_Oggetto IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2
, p_Utente IN VARCHAR2
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Autore IN VARCHAR2
, p_Accesso IN VARCHAR2 DEFAULT 'S'
, p_Dal IN VARCHAR2 DEFAULT NULL
, p_Al IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER;
Function verifica
/******************************************************************************
 NOME:        verifica
 DESCRIZIONE: Verifica l'abilitazione di accesso ad una certa data restituendo il valore 1 o 0 in funzione del contenuto nel campo ACCESSO.
              Controlla prima l'accesso specifico per il Soggetto e poi per appartenenza ai diversi Gruppi.
              Se il ruolo e indicato in ingresso controlla l'esistenza di una competenza con quel ruolo o in assenza di questa, senza ruolo.
              Se il ruolo non e indicato in ingresso, per ogni gruppo acquisisce il Ruolo del Soggetto nel Gruppo
              Ritorna:
              1 : se esiste il diritto di accesso
              0 : se non esiste diritto di accesso
******************************************************************************/
( p_Tipo_Oggetto IN VARCHAR2
, p_Oggetto IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2
, p_Utente IN VARCHAR2
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Data IN VARCHAR2 DEFAULT to_char(sysdate,'dd/mm/yyyy'))
RETURN NUMBER;
Function get_tipo_abilitazione
/******************************************************************************
 NOME:        get_tipo_abilitazione
 DESCRIZIONE: Ritorna la descrizione della abilitazione richiesta.
              NULL : se l'abilitazione non esiste
******************************************************************************/
( p_tipo_abilitazione IN VARCHAR2)
RETURN VARCHAR2;
Function oggetti
/******************************************************************************
 NOME:        oggetti
 DESCRIZIONE: Ritorna una stringa con gli oggetti su cui l'utente
           ha una qualche competenza separati da un separatore parametrizzabile:
              Ritorna
           Stringa
******************************************************************************/
( p_Utente IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2 DEFAULT '%'
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Tipo_Oggetto IN VARCHAR2 DEFAULT '%'
, p_Oggetto IN VARCHAR2 DEFAULT'%'
, p_Data IN VARCHAR2 DEFAULT to_char(sysdate,'dd/mm/yyyy')
, p_separatore IN VARCHAR2 DEFAULT ';'
)
RETURN varchar2;
END SI4_COMPETENZA;
/

CREATE OR REPLACE PACKAGE BODY SI4_COMPETENZA IS
Function  VERSIONE
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce la versione e la data di distribuzione del package.
 RITORNA:     stringa VARCHAR2 contenente versione e data.
 NOTE:        Il secondo numero della versione corrisponde alla revisione
              del package.
******************************************************************************/
RETURN VARCHAR2
IS
BEGIN
   RETURN revisione;
END VERSIONE;
Function assegna
/******************************************************************************
 NOME:        assegna
 DESCRIZIONE: Registra la competenza per il soggetto (utente o gruppo) indicato, relativamente alla abilitazione di un determinato oggetto.
              - chiude periodo precedente alla data DAL - 1
              - sposta periodo successivo alla data AL+ 1
              - elimina periodi contenuti
              Return:
               0 : Inserimento corretto
              -1 : Tipo di abilitazione incompatibile con l'oggetto indicato
              -2 : Non esiste l'oggetto
              -3 : Non esiste il tipo di abilitazione
******************************************************************************/
( p_Tipo_Oggetto IN VARCHAR2
, p_Oggetto IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2
, p_Utente IN VARCHAR2
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Autore IN VARCHAR2
, p_Accesso IN VARCHAR2 DEFAULT 'S'
, p_Dal IN VARCHAR2 DEFAULT NULL
, p_Al IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER
IS
d_id_abilitazione number(10);
d_id_competenza   number(10);
d_errore          number(1);
d_esiste          number(1);
cursor c_periodi ( v_Tipo_Oggetto VARCHAR2
             , v_Oggetto VARCHAR2
             , v_Tipo_Abilitazione VARCHAR2
             , v_Utente VARCHAR2
             , v_Ruolo VARCHAR2
             , v_Dal VARCHAR2
             , v_Al VARCHAR2
             )
 IS
select comp.id_competenza,abil.id_abilitazione,accesso, dal, al
  from si4_competenze comp,
       si4_abilitazioni abil,
      si4_tipi_oggetto tiog,
      si4_tipi_abilitazione tiab
 where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
   and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
   and comp.id_abilitazione = abil.id_abilitazione
   and tiog.tipo_oggetto = v_Tipo_Oggetto
   and tiab.tipo_abilitazione = v_Tipo_Abilitazione
   and comp.utente = v_Utente
   and comp.oggetto = v_Oggetto
   and nvl(comp.ruolo,'x') = nvl(v_ruolo,'x')
   and nvl(comp.dal,to_date('2222222','j')) <= nvl(to_date(v_al,'dd/mm/yyyy'),to_date('3333333','j'))
   and nvl(comp.al,to_date('3333333','j')) >= nvl(to_date(v_dal,'dd/mm/yyyy'),to_date('2222222','j'))
   ;
BEGIN
   /*Estraggo id_abilitazione */
   select id_abilitazione
     into d_id_abilitazione
     from si4_abilitazioni abil,
          si4_tipi_oggetto tiog,
         si4_tipi_abilitazione tiab
    where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
      and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
      and tiog.tipo_oggetto = p_Tipo_Oggetto
      and tiab.tipo_abilitazione = p_Tipo_Abilitazione;
   /* Tratto i periodi con intersezione non nulla*/
   for v_periodi in c_periodi(p_Tipo_Oggetto
                             ,p_Oggetto
                       ,p_Tipo_Abilitazione
                       ,p_Utente
                       ,p_Ruolo
                       ,p_Dal
                       ,p_Al
                       ) loop
      if nvl(v_periodi.dal,to_date('2222222','j')) >= nvl(to_date(p_dal,'dd/mm/yyyy'),to_date('2222222','j'))
     and nvl(v_periodi.al,to_date('3333333','j'))  <= nvl(to_date(p_al,'dd/mm/yyyy'),to_date('3333333','j')) then
     /*Caso A)Periodo interamente contenuto nel nuovo*/
         delete from si4_competenze
          where id_competenza = v_periodi.id_competenza;
      elsif nvl(v_periodi.dal,to_date('2222222','j')) between nvl(to_date(p_dal,'dd/mm/yyyy'),to_date('2222222','j'))
        and  nvl(to_date(p_al,'dd/mm/yyyy'),to_date('3333333','j')) then
     /*Caso B)"Dal" contenuto nel nuovo intervallo*/
            update si4_competenze
               set dal = to_date(p_al,'dd/mm/yyyy') + 1
             where id_competenza = v_periodi.id_competenza;
      elsif nvl(v_periodi.al,to_date('3333333','j')) between nvl(to_date(p_dal,'dd/mm/yyyy'),to_date('2222222','j'))
        and  nvl(to_date(p_al,'dd/mm/yyyy'),to_date('3333333','j')) then
     /*Caso C)"Al" contenuto nel nuovo intervallo*/
            update si4_competenze
               set al = to_date(p_dal,'dd/mm/yyyy') -1
             where id_competenza = v_periodi.id_competenza;
      else
     /*Caso D)Periodo contiene il nuovo intervallo*/
           select COMP_SQ.nextval
           into d_id_competenza
             from dual;
           insert into si4_competenze
                (ID_COMPETENZA, ID_ABILITAZIONE, UTENTE, OGGETTO, ACCESSO, RUOLO, DAL, AL, DATA_AGGIORNAMENTO, UTENTE_AGGIORNAMENTO)
           values (d_id_competenza,v_periodi.id_abilitazione,p_Utente, p_Oggetto, v_periodi.accesso, p_ruolo,v_periodi.dal,to_date(p_dal,'dd/mm/yyyy')-1,sysdate,p_Autore);
           select COMP_SQ.nextval
           into d_id_competenza
             from dual;
           insert into si4_competenze
                (ID_COMPETENZA, ID_ABILITAZIONE, UTENTE, OGGETTO, ACCESSO, RUOLO, DAL, AL, DATA_AGGIORNAMENTO, UTENTE_AGGIORNAMENTO)
           values (d_id_competenza,v_periodi.id_abilitazione,p_Utente, p_Oggetto, v_periodi.accesso,p_Ruolo,to_date(p_al,'dd/mm/yyyy')+1,v_periodi.al,sysdate,p_Autore);
           delete from si4_competenze
            where id_competenza = v_periodi.id_competenza;
     end if;
   end loop;
   /*Inserimento nuovo periodo */
   select COMP_SQ.nextval
     into d_id_competenza
     from dual;
   insert into si4_competenze
                (ID_COMPETENZA, ID_ABILITAZIONE, UTENTE, OGGETTO, ACCESSO, RUOLO, DAL, AL, DATA_AGGIORNAMENTO, UTENTE_AGGIORNAMENTO)
   values (d_id_competenza, d_id_abilitazione, p_Utente, p_oggetto, p_accesso, p_ruolo, to_date(p_dal,'dd/mm/yyyy'), to_date(p_al,'dd/mm/yyyy'), sysdate, p_autore);
   commit;
   return 0;
EXCEPTION
   when no_data_found then
      d_errore := -1;
      BEGIN
      /*Non esiste il tipo di oggetto */
      select 1
       into d_esiste
       from si4_tipi_oggetto tiog
      where tiog.tipo_oggetto = p_tipo_oggetto;
      EXCEPTION when no_data_found then
      d_errore := -2;
      END;
      BEGIN
      /*Non esiste il tipo di abilitazione */
      select 1
       into d_esiste
       from si4_tipi_abilitazione tiab
      where tiab.tipo_abilitazione = p_tipo_abilitazione;
      EXCEPTION when no_data_found then
      d_errore := -3;
      END;
   return d_errore;
END assegna;
Function verifica
/******************************************************************************
 NOME:        verifica
 DESCRIZIONE: Verifica l'abilitazione di accesso ad una certa data restituendo il valore 1 o 0 in funzione del contenuto nel campo ACCESSO.
              Controlla prima l'accesso specifico per il Soggetto e poi per appartenenza ai diversi Gruppi.
              Se il ruolo e indicato in ingresso controlla l'esistenza di una competenza con quel ruolo o in assenza di questa, senza ruolo.
              Se il ruolo non e indicato in ingresso, per ogni gruppo acquisisce il Ruolo del Soggetto nel Gruppo
              Ritorna:
              1 : se esiste il diritto di accesso
              0 : se non esiste diritto di accesso
******************************************************************************/
( p_Tipo_Oggetto IN VARCHAR2
, p_Oggetto IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2
, p_Utente IN VARCHAR2
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Data IN VARCHAR2 DEFAULT to_char(sysdate,'dd/mm/yyyy'))
RETURN NUMBER
IS
d_diritto NUMBER(1) := 0;
d_ruolo   VARCHAR2(250);
/* Estraggo tutte le competenze sull'oggetto assegnate ad utenti di tipo Gruppi e Organizzazioni */
   cursor c_competenze ( v_Tipo_Oggetto VARCHAR2
                   , v_Oggetto VARCHAR2
                   , v_Tipo_Abilitazione VARCHAR2
                  , v_Data VARCHAR2
                   )
   IS
   select comp.utente, comp.ruolo, uten.tipo_utente
       from si4_competenze comp,
          si4_abilitazioni abil,
            si4_tipi_oggetto tiog,
            si4_tipi_abilitazione tiab,
           ad4_utenti uten
    where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
      and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
      and comp.id_abilitazione = abil.id_abilitazione
        and comp.utente = uten.utente
        and to_date(v_data,'dd/mm/yyyy') between nvl(dal,to_date('2222222','j'))
                                             and nvl(al ,to_date('3333333','j'))
      and tiog.tipo_oggetto = v_tipo_oggetto
        and tiab.tipo_abilitazione = v_tipo_abilitazione
        and comp.oggetto = v_oggetto
        and uten.tipo_utente in ('G','O')
        and accesso = 'S';
BEGIN
      /*Verifica l'esistenza di una competenza per utente e ruolo */
      select decode(accesso,'S',1,'N',0)
        into d_diritto
          from si4_competenze comp,
             si4_abilitazioni abil,
               si4_tipi_oggetto tiog,
               si4_tipi_abilitazione tiab
       where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
         and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
         and comp.id_abilitazione = abil.id_abilitazione
           and comp.utente = p_Utente
           and to_date(p_data,'dd/mm/yyyy') between nvl(dal,to_date('2222222','j'))
                                                and nvl(al ,to_date('3333333','j'))
         and tiog.tipo_oggetto = p_tipo_oggetto
           and tiab.tipo_abilitazione = p_tipo_abilitazione
           and comp.oggetto = p_oggetto
           and nvl(comp.ruolo,'x') = nvl(p_ruolo,'x');
      return d_diritto;
EXCEPTION
      when no_data_found then
      BEGIN
      /*Verifica l'esistenza di una competenza per utente e ruolo nullo */
      select decode(accesso,'S',1,'N',0)
        into d_diritto
          from si4_competenze comp,
             si4_abilitazioni abil,
               si4_tipi_oggetto tiog,
               si4_tipi_abilitazione tiab
       where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
         and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
         and comp.id_abilitazione = abil.id_abilitazione
           and comp.utente = p_Utente
           and to_date(p_data,'dd/mm/yyyy') between nvl(dal,to_date('2222222','j'))
                                                and nvl(al ,to_date('3333333','j'))
         and tiog.tipo_oggetto = p_tipo_oggetto
           and tiab.tipo_abilitazione = p_tipo_abilitazione
           and comp.oggetto = p_oggetto
        and comp.ruolo is null;
      return d_diritto;
      EXCEPTION
         when no_data_found then
           /*Verifica l'esistenza di una competenza per utente e/o ruolo */
         for v_competenze in c_competenze ( p_Tipo_Oggetto, p_Oggetto, p_Tipo_Abilitazione, p_Data)
             loop
            if v_competenze.tipo_utente = 'G' then
                    select decode(max(utente), null, 0, 1)
                     into d_diritto
                     from ad4_utenti_gruppo utgr
                    where utgr.gruppo = v_competenze.utente
                      and nvl(v_competenze.ruolo,nvl(p_ruolo,'x')) = nvl(p_ruolo,'x')
                   connect by prior gruppo = utente
                    start with utente = p_utente;
           else /* v_competenza.tipo_utente = 'O' */
            d_ruolo := si4_soggetto.get_ruolo(p_utente, v_competenze.utente);
            /*Se la funzione ritorna null, l'utente non appartiene a quell'organizzazione */
               if nvl(v_competenze.ruolo, d_ruolo) = d_ruolo then
                 d_diritto := 1;
               end if;
            end if;
            if d_diritto = 1 then
               exit;
            end if;
         end loop;
            return d_diritto;
      END;
END verifica;
Function get_tipo_abilitazione
/******************************************************************************
 NOME:        get_tipo_abilitazione
 DESCRIZIONE: Ritorna la descrizione della abilitazione richiesta.
              NULL : se l'abilitazione non esiste
******************************************************************************/
( p_tipo_abilitazione IN VARCHAR2)
RETURN VARCHAR2
IS
v_descrizione varchar2(2000);
BEGIN
   select descrizione
     into v_descrizione
     from si4_tipi_abilitazione
   where tipo_abilitazione = p_tipo_abilitazione
   ;
   return v_descrizione;
EXCEPTION
   when no_data_found then
   return null;
END get_tipo_abilitazione;
Function oggetti
/******************************************************************************
 NOME:        oggetti
 DESCRIZIONE: Ritorna una stringa con gli oggetti a cui l'utente è abilitato.
******************************************************************************/
( p_Utente IN VARCHAR2
, p_Tipo_Abilitazione IN VARCHAR2 DEFAULT '%'
, p_Ruolo IN VARCHAR2 DEFAULT NULL
, p_Tipo_Oggetto IN VARCHAR2 DEFAULT '%'
, p_Oggetto IN VARCHAR2 DEFAULT'%'
, p_Data IN VARCHAR2 DEFAULT to_char(sysdate,'dd/mm/yyyy')
, p_separatore IN VARCHAR2 DEFAULT ';'
)
RETURN varchar2
IS
sStringaT varchar2(32767);
begin
for c in (select p_utente utente
            from dual
        union
        select gruppo
            from ad4_utenti_gruppo
       start with utente = p_Utente
 connect by prior gruppo = utente) loop
   for c_comp in (   select comp.oggetto sStringa
                       from si4_competenze comp,
                            si4_abilitazioni abil,
                              si4_tipi_oggetto tiog,
                              si4_tipi_abilitazione tiab
                      where abil.id_tipo_oggetto = tiog.id_tipo_oggetto
                        and abil.id_tipo_abilitazione = tiab.id_tipo_abilitazione
                        and comp.id_abilitazione = abil.id_abilitazione
                          and to_date(nvl(p_Data,to_char(sysdate,'dd/mm/yyyy')),'dd/mm/yyyy') between nvl(dal,to_date('2222222','j'))
                                             and nvl(al ,to_date('3333333','j'))
                        and tiog.tipo_oggetto like nvl(p_Tipo_Oggetto,'%')
                        and tiab.tipo_abilitazione like nvl(p_Tipo_Abilitazione,'%')
                        and comp.oggetto like nvl(p_Oggetto,'%')
                        and accesso = 'S'
                       and nvl(comp.ruolo,'x') = nvl(p_Ruolo,'x')
                        and comp.utente  = c.utente) loop
      sStringaT := sStringaT||p_separatore||c_comp.sStringa;
   end loop;
end loop;
return ltrim(sStringaT,p_separatore);
END oggetti;
END SI4_COMPETENZA;
/

