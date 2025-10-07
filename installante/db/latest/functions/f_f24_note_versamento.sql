--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_note_versamento stripComments:false runOnChange:true 
 
create or replace function F_F24_NOTE_VERSAMENTO
/*************************************************************************
 NOME:        F_F24_NOTE_VERSAMENTO
 DESCRIZIONE: Dato un identificativo operazione proveniente da file
              versamenti F24, e l'eventuale numero di pratica,
              restituisce una stringa contenente le note da inserire
              in tabella VERSAMENTI
 RITORNA:     varchar2             Note
              Se l'identificativo è vuoto restituisce null.
              Se si tratta di un sollecito, restituisce una stringa
              contenente "Sollecito del " seguito dalla data
              estratta dall'identificativo operazione
              Se si tratta di un'identificativo non emesso da TR4 e
              il numero di pratica è nullo, restituisce una stringa
              contenente "Id. Operazione " seguito dall'identificativo
              operazione
              Se il numero pratica non è nullo e il tipo versamento è
              "I", restituisce "Imposta"
              Se il numeroa pratica non è nullo e il tipo versamento è
              "S", restituisce "Sanzioni e Interessi"
 NOTE:        Composizione identificativo operazione:
              Per gli insolventi (solleciti):
              SOLLAAAANNYYYYMMDD
              Liquidazioni e accertamenti:
              LIQPAAAANNNNNNNNNN x Pratica
              ACCPAAAANNNNNNNNNN x Pratica
              ACCTAAAANNNNNNNNNN x quelle Totali IMU
              ACCAAAAANNNNNNNNNN X acc automatici (tipo_evento = 'A')
              ACCUAAAANNNNNNNNNN X acc manuali (tipo_evento = 'U')
              dove AAAA è l'anno della pratica e NNNNNNNNNNN è il numero Pratica
              COSAP/ICP:
              AAAARRSSSSSSSSSSSS   anno - rata - NI soggetto
 Rev.    Date         Author      Note
 007     30/08/2021   VD          Ripristinati id. e nome file nel campo note.
 006     29/03/2021   VD          Eliminati id. e nome file dal campo note.
 005     11/01/2021   VD          Aggiunta gestione nuovo campo
                                  note_versamento da wrk_versamenti: se
                                  presente viene inserita nella parte
                                  iniziale delle note.
 004     29/04/2019   VD          Aggiunta gestione rateazione errata in
                                  assenza di identificativo operazione.
 003     31/05/2018   VD          Aggiunta gestione note per versamenti
                                  TOSAP/ICP da F24.
 002     07/07/2015   VD          Modificata gestione id_operazione per
                                  sollecito: se gli ultimi 8 caratteri
                                  non sono una data, la nota viene cosi
                                  composta:
                                  'Sollecito: '|| id_operazione
                                  altrimenti rimane come prima
 001     22/12/2014   VD          Prima emissione.
*************************************************************************/
(p_id_operazione      varchar2
,p_pratica            number
,p_tipo_versamento    varchar2
,p_documento_id       number
,p_tipo_tributo       varchar2 default null
,p_cod_tributo        varchar2 default null
,p_rateazione         varchar2 default null
,p_note_versamento    varchar2 default null
)
  return varchar2
is
  d_note_versamento   varchar2(2000);
  d_nome_documento    documenti_caricati.nome_documento%type;
  d_data_sollecito    varchar2(8);
  d_numero_rata       number;
  d_totale_rate       number;
begin
--
-- Si seleziona il nome del documento caricato
-- (VD - 29/03/2021): eliminati id. e nome documento dal campo note
-- (VD - 30/08/2021): ripristinati id. e nome documento nel campo note
  if p_documento_id is not null then
     begin
       select nome_documento
         into d_nome_documento
         from documenti_caricati
        where documento_id = p_documento_id;
     exception
       when others then
         d_nome_documento := to_char(null);
     end;
  else
     d_nome_documento := to_char(null);
  end if;
-- Determinazione numero rate e rata pagata
  d_note_versamento := to_char(null);
  d_numero_rata := 0;
  d_totale_rate := 0;
  if p_id_operazione is not null then
     if afc.is_numeric(substr(p_id_operazione,9,2)) = 1 then
        d_numero_rata := to_number(substr(p_id_operazione,9,2));
        if d_numero_rata <> 0 then
           if p_rateazione is not null and
              afc.is_numeric(substr(p_rateazione,3,2)) = 1 then
              d_totale_rate := to_number(substr(p_rateazione,3,2));
           end if;
        end if;
     end if;
  end if;
--
  if p_id_operazione is null or
     p_id_operazione like 'RUOL%' then
     if p_rateazione is not null then
        d_note_versamento := d_note_versamento||'Rateazione orig. '||p_rateazione;
     end if;
  elsif nvl(p_tipo_tributo,'*') = 'TOSAP' then
     if p_cod_tributo = '3931' then
        d_note_versamento := d_note_versamento||'3931 - Occupazione permanente; ';
     elsif p_cod_tributo = '3932' then
        d_note_versamento := d_note_versamento||'3932 - Occupazione temporanea; ';
     end if;
     if afc.is_numeric(substr(p_rateazione,3,2)) = 1 then
        if to_number(substr(p_rateazione,3,2)) <> 1 then
           d_note_versamento := d_note_versamento||'Rate totali: '||to_number(substr(p_rateazione,3,2))||'; ';
        end if;
     end if;
  elsif p_id_operazione like 'SOLL%' then
     begin
       d_data_sollecito := to_char(to_date(substr(p_id_operazione,11,8),'yyyymmdd'),'dd/mm/yyyy');
     exception
       when others then
         d_data_sollecito := null;
     end;
     if d_note_versamento is not null then
        d_note_versamento := d_note_versamento||'; ';
     end if;
     if d_data_sollecito is null then
        d_note_versamento := d_note_versamento||'Sollecito: '||p_id_operazione||'; ';
     else
        d_note_versamento := d_note_versamento||'Sollecito del '||to_char(to_date(substr(p_id_operazione,11,8),'yyyymmdd'),'dd/mm/yyyy')||'; ';
     end if;
  elsif
     p_pratica is null and
     p_id_operazione is not null then
     d_note_versamento := d_note_versamento||'Id.Operazione: '||p_id_operazione||'; ';
  elsif
     p_tipo_versamento = 'I' then
     d_note_versamento := 'Imposta; ';
  elsif
     p_tipo_versamento = 'S' then
     d_note_versamento := 'Sanzioni e Interessi; ';
  end if;
--
  if d_totale_rate <> 0 then
     d_note_versamento := d_note_versamento||'Rata '||d_numero_rata||' di '||d_totale_rate||'; ';
  end if;
-- (VD - 29/03/2021): eliminati id. e nome documento dal campo note
-- (VD - 30/08/2021): ripristinati id. e nome documento nel campo note
  if d_nome_documento is not null then
     if d_note_versamento is not null then
        d_note_versamento := d_note_versamento||'; ';
     end if;
     d_note_versamento := d_note_versamento||'Doc. '||p_documento_id||' - '||d_nome_documento;
  end if;
--
-- (VD - 11/01/2021): se il parametro note_versamento e' valorizzato,
--                    viene memorizzato all'inizio delle note
  if p_note_versamento is not null then
     if d_note_versamento is not null then
        d_note_versamento := substr(p_note_versamento||';'||d_note_versamento,1,2000);
     else
        d_note_versamento := p_note_versamento;
     end if;
  end if;
  --dbms_output.put_line('Note versamento (5): '||d_note_versamento);
--
  return trim(d_note_versamento);
end;
/* End Function: F_F24_NOTE_VERSAMENTO */
/

