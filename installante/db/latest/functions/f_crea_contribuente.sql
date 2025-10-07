--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_crea_contribuente stripComments:false runOnChange:true 
 
create or replace function F_CREA_CONTRIBUENTE
/*************************************************************************
 NOME:        F_CREA_CONTRIBUENTE
 DESCRIZIONE: Utilizzata nelle procedure di caricamento versamenti da F24.
              Dato il codice fiscale di un contribuente:
              - si verifica se esiste in tabella CONTRIBUENTI
              - se non esiste, si verifica se esiste un soggetto con lo
                stesso codice fiscale
              - se non esiste, si verifica se esiste un soggetto con la
                partita IVA uguale al codice fiscale indicato
              - se non esiste, non si fa nulla
              - se esiste un soggetto con codice fiscale o partita IVA
                uguale al codice fiscale indicato, si controlla che non
                esista una riga in CONTRIBUENTI per l'ni determinato
              - se non esiste, si inserisce la riga di contribuenti.
 RITORNA:     number              Numero di mesi abitazione principale
 NOTE:
 Rev.    Date         Author      Note
 000     29/05/2019   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale                   varchar2
, p_errore                 in out varchar2
) return varchar2
is
  w_cod_fiscale            varchar2(16);
  w_cod_fiscale_cont       varchar2(16);
  w_ni                     number;
  w_conta_cont             number;
begin
  p_errore := null;
  -- Si verifica se esiste gia' una riga di CONTRIBUENTI con il codice
  -- fiscale indicato
  begin
    select count(1)
      into w_conta_cont
      from contribuenti
     where cod_fiscale = p_cod_fiscale
         ;
  exception
    when others then
      w_conta_cont := 0;
  end;
  -- Se il contribuente esiste, si restituisce lo stesso codice fiscale
  if w_conta_cont = 1 then
     return p_cod_fiscale;
  end if;
  -- Se esistono piu' contribuenti con lo stesso codice fiscale, si
  -- restituisce null e si valorizza il messaggio di errore
  if w_conta_cont > 1 then
     p_errore := 'Esistono piu'' contribuenti con lo stesso codice fiscale '||
                 p_cod_fiscale;
     return null;
  end if;
  -- Se il contribuente non esiste, si verifica l'esistenza dell'anagrafica
  -- nella tabella SOGGETTI per codice fiscale
  begin
    select nvl(max(ni),0)
      into w_ni
      from soggetti
     where nvl(cod_fiscale,' ') = p_cod_fiscale
     ;
  exception
    when others then
      w_ni := 0;
  end;
  -- Se il codice fiscale non esiste in tabella SOGGETTI, si verifica
  -- se esiste un soggetto con partita IVA uguale al codice fiscale
  -- indicato
  if w_ni = 0 then
     begin
       select nvl(max(ni),0)
         into w_ni
         from soggetti
        where nvl(partita_iva,' ') = p_cod_fiscale
        ;
     exception
       when others then
         w_ni := 0;
     end;
  end if;
  --
  if nvl(w_ni,0) > 0 then
     w_cod_fiscale := p_cod_fiscale;
     -- Se ho trovato un soggetto in anagrafe soggetti, verifico che
     -- non sia gia' presente in CONTRIBUENTI con un altro codice
     -- fiscale
     begin
       select 1
            , cod_fiscale
         into w_conta_cont
            , w_cod_fiscale_cont
         from contribuenti
        where ni = w_ni;
     exception
       when others then
         w_conta_cont := 0;
         w_cod_fiscale_cont := null;
     end;
     -- Se non esiste, si inserisce
     if w_conta_cont = 0 then
        begin
          insert into contribuenti
                 (cod_fiscale, ni)
          values (w_cod_fiscale,w_ni)
                ;
        exception
          when others then
            p_errore := 'Ins. CONTRIBUENTI (cf: '||w_cod_fiscale||
                        ', ni: '||to_char(w_ni)||') - '||sqlerrm;
        end;
     else
        if w_cod_fiscale <> w_cod_fiscale_cont then
           w_cod_fiscale := null;
           p_errore := 'Contribuente presente con codice fiscale diverso ('||
                       w_cod_fiscale_cont||')';
        end if;
     end if;
  else
     w_cod_fiscale := null;
  end if;
  --
  return w_cod_fiscale;
  --
end;
/* End Function: F_CREA_CONTRIBUENTE */
/

