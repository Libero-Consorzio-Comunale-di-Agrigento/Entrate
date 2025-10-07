--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_abilita_funzione stripComments:false runOnChange:true 
 
create or replace function F_ABILITA_FUNZIONE
/*************************************************************************
 NOME:        F_ABILITA_FUNZIONE
 DESCRIZIONE: Dato il nome convenzionale di una funzione dell'applicativo,
              restituisce 'S' se tale funzione e' abilitata per il cliente
              presente nella tabella DATI_GENERALI, altrimenti restituisce
              'N'
 RITORNA:     string              S = funzione abilitata
                                  N = funzione non abilitata
 NOTE:
 Rev.    Date         Author      Note
 004     27/11/2018   VD          Aggiunta nuova funzionalita per visualizzare
                                  informazioni da archivio CIVICI
                                  (CASALGRANDE - cod. '035012')
 003     21/08/2018   VD          Abilitate funzionalita' conferimenti
                                  CER per Fiorano Modenese (cod. 036013)
 002     04/09/2017   VD          Aggiunte nuove funzionalita' per
                                  conferimento PONTEDERA (cod. 050029)
 001     21/10/2016   VD          Aggiunte nuove funzionalita' per
                                  sperimentazione Poasco (San Donato
                                  Milanese - cod. 015192)
 000     14/04/2011               Prima emissione.
*************************************************************************/
(funzione     varchar2
)
return varchar2
is
w_istat  varchar2(6);
begin
   BEGIN
      select lpad(to_char(dage.pro_cliente),3,'0')||
             lpad(to_char(dage.com_cliente),3,'0')
        into w_istat
        from dati_generali dage
      ;
   EXCEPTION
      WHEN others THEN
         return 'N';
   END;
   if upper(funzione) = 'INSERIMENTO_VERSAMENTI_DELEGHE' then
      if w_istat = '108027'     -- Limbiate
      or w_istat = '037058'     -- Savigno
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'ASSOCIA_RUOLI' then
      if w_istat = '037054' then  -- San Lazzaro di Savena
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'STAMPA MAV (INC1)' then
      if w_istat = '037054' then  -- San Lazzaro di Savena
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'INSERIMENTO_CONTATTI_WEB' then
      if w_istat = '035012'   -- Casalgrande
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'DOCUMENTI_CONTRIBUENTE' then
--     if w_istat = '035012'   -- Casalgrande
--     or w_istat = '017025'   -- Bovezzo per prove
--     or w_istat = '033032'   -- Piacenza
--     or w_istat = '012070'   -- Gallarate demo
--     or w_istat = '015192'   -- San Donato Milanese
--     or w_istat = '037006'   -- Dologna prove
--     or w_istat = '040007'   -- Cesena demo
--     or w_istat = '037006'   -- Bologna per prove ADS
--     or w_istat = '033021'   -- Fiorenzuola
--     or w_istat = '107004'   -- Carloforte
--     or w_istat = '048035'   -- Reggello
--     or w_istat = '040020'   -- Mercato Saraceno
--
--     then
         return 'S';
--      else
--         return 'N';
--      end if;
   elsif upper(funzione) = 'F24_IN_DOCUMENTI' then
     if w_istat = '035012'   -- Casalgrande
     or w_istat = '017025'   -- Bovezzo per prove
     or w_istat = '033032'   -- Piacenza
     or w_istat = '012070'   -- Gallarate demo
     or w_istat = '040007'   -- Cesena demo
     or w_istat = '037006'   -- Bologna per prove ADS
     then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'F24_TASI_IN_DOCUMENTI' then
     if w_istat = '035012'   -- Casalgrande
     or w_istat = '040007'   -- Cesena demo
     or w_istat = '037006'   -- Bologna per prove ADS
     then
        return 'S';
     else
        return 'N';
     end if;
   elsif upper(funzione) = 'F24_COCO_STAMPA' then
      if w_istat = '015093'   -- Corsico
      or w_istat = '037006'   -- Bologna per prove ADS
--      or w_istat = '108012'   -- Brugherio
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'F24_COCO_STAMPA_TASI' then
      if w_istat = '012096'   -- Malnate
      or w_istat = '037054'   -- San Lazzaro
      or w_istat = '016003'   -- Albano Sant Alessandro
      or w_istat = '037052'   -- San Giorgio di Piano (8/5/15)
      or w_istat = '025006'   -- Belluno (8/5/15)
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'COM_COCO_TASI' then
      if w_istat = '037054'   -- San Lazzaro
      or w_istat = '037006'   -- Bologna per prove ADS
      then
          return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'COM_COCO_ICI' then
      if w_istat = '035012'   -- Casalgrande
      or w_istat = '037006'   -- Bologna per prove ADS
      or w_istat = '037055'   -- San Pietro in casale
      or w_istat = '016051'   -- Capriate San gervasio
      then
          return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'DETRAZIONE_MOBILE' then
      if w_istat = '017025'   -- Bovezzo
      or w_istat = '015192'   -- San Donato Milanese
      or w_istat = '108016'   -- Carnate
      or w_istat = '038009'   -- Formignana
      or w_istat = '038024'   -- Tresigallo
      or w_istat = '012096'   -- Malnate
      or w_istat = '012070'   -- Gallarate dem  o
      or w_istat = '037054'   -- San Lazzaro
      or w_istat = '037052'   -- San Giorgio di Piano
      or w_istat = '035036'   -- Rubiera
      or w_istat = '035012'   -- Casalgrande
      or w_istat = '015175'   -- Pioltello
      or w_istat = '040007'   -- Cesena demo
      or w_istat = '050029'   -- Pontedera
      or w_istat = '048033'   -- Pontassieve
      or w_istat = '052028'   -- San Gimignano
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'DETRAZIONE_MOBILE_POSS' then --per sapere a quale percentuale fare riferimento nei calcoli
      if w_istat = '017025'   -- Bovezzo
      or w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'ALIQUOTA_MOBILE' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   --
   -- (VD - 21/10/2016): nuove funzionalita per San Donato Milanese
   --
   elsif upper(funzione) = 'GESTIONE_CONFERIMENTI' then
      if w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'SITUAZIONE_CONFERIMENTI' then
      if w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'IMPORT_CONFERIMENTI' then
      if w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'COMPONENTI_SACCHI' then
      if w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'CONTRIBUENTI_RUOLO' then
      if w_istat = '015192'   -- San Donato Milanese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   --
   -- (VD - 04/09/2017): nuove funzionalita per Pontedera
   -- (VD - 21/08/2018): nuove funzionalita per Fiorano Modenese
   --
   elsif upper(funzione) = 'DIZIONARIO_CLASSIFICAZIONI_CER' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '036013'   -- Fiorano Modenese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'RIDUZIONI_CONFERIMENTI_CER' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '036013'   -- Fiorano Modenese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'GESTIONE_CONFERIMENTI_CER' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '036013'   -- Fiorano Modenese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'SITUAZIONE_CONFERIMENTI_CER' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '036013'   -- Fiorano Modenese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   elsif upper(funzione) = 'IMPORT_CONFERIMENTI_CER' then
      if w_istat = '050029'   -- Pontedera
      or w_istat = '036013'   -- Fiorano Modenese
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   --
   -- (VD - 04/09/2017): nuova funzionalita per Casalgrande
   --
   elsif upper(funzione) = 'VIS_ARC_CIVICI' then
      if w_istat = '035012'   -- Casalgrande
      or w_istat = '037006'   -- Bologna per prove ADS
      then
         return 'S';
      else
         return 'N';
      end if;
   else
      return 'N';
   end if;
end;
/* End Function: F_ABILITA_FUNZIONE */
/

