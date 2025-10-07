--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_sconto_conf stripComments:false runOnChange:true 
 
create or replace function F_GET_SCONTO_CONF
/*************************************************************************
 NOME:        F_GET_SCONTO_CONF
 DESCRIZIONE: Restituisce una stringa contenente le informazioni
              relative agli sgravi per conferimenti
              Attivato per Pontedera (stampa temporanea conferimenti)
                       e Bologna (prove ADS)
 RITORNA:     varchar2      Valore del campo richiesto
*************************************************************************/
( p_ruolo                   number
, p_cod_fiscale             varchar2
, p_sequenza                number
, p_sequenza_sgravio        number
, p_oggetto_imposta         number
, p_tipo_importo            varchar2 default null
) return varchar2
is
  d_return                  varchar2(200) := null;
  d_cod_istat               varchar2(6);
  d_conta_sgravi            number := 0;
  d_seq_sgravio             number;
  d_flag_stampa             varchar2(1);
  d_tipo_importo            varchar2(1);
begin
  --
  -- Se la sequenza sgravio passata è maggiore di 10, significa che si
  -- proviene dall'estrazione TARES Poste, quindi si sottrae 10 alla
  -- sequenza sgravio e si setta il flag_stampa a 'E' (Estrazione).
  -- In caso contrario si setta il flag_stampa a 'S' (Stampa)
  --
  if p_sequenza_sgravio > 10 then
     d_seq_sgravio := p_sequenza_sgravio - 10;
     d_flag_stampa := 'E';
  else
     d_seq_sgravio := p_sequenza_sgravio;
     d_flag_stampa := 'S';
  end if;
  --
  d_tipo_importo := nvl(p_tipo_importo,'N');
  --
  begin
    select lpad(pro_cliente,3,'0')||
           lpad(com_cliente,3,'0')
      into d_cod_istat
      from dati_generali;
  exception
    when others then
      raise_application_error(-20999,'Dati generali non presenti o multipli');
  end;
--
  if d_cod_istat in ('050029','037006') then
     for mot in (select decode(d_flag_stampa,'S',
                              '[a_capo'||
                              rpad(mosg.descrizione,65)||
                              lpad(translate(to_char(decode(d_tipo_importo
                                                    ,'N',sgra.importo -
                                                      nvl(sgra.addizionale_eca,0) -
                                                      nvl(sgra.maggiorazione_eca,0) -
                                                      nvl(sgra.addizionale_pro,0) -
                                                      nvl(sgra.iva,0) -
                                                      nvl(sgra.maggiorazione_tares,0)
                                                     ,'L',sgra.importo) * -1
                                                    , '9,999,990.00')
                                            ,',.'
                                            ,'.,'
                                            )
                                  ,15
                                  ),
                              mosg.descrizione||' E. '||
                              decode(d_tipo_importo
                                    ,'N',ltrim(translate(to_char((sgra.importo -
                                                 nvl(sgra.addizionale_eca,0) -
                                                 nvl(sgra.maggiorazione_eca,0) -
                                                 nvl(sgra.addizionale_pro,0) -
                                                 nvl(sgra.iva,0) -
                                                 nvl(sgra.maggiorazione_tares,0)
                                                ) * -1
                                               , '9,999,990.00')
                                       ,',.'
                                       ,'.,'
                                       ))
                                    ,'L',ltrim(translate(to_char(sgra.importo * -1
                                                                ,'9,999,990.00')
                                       ,',.'
                                       ,'.,'
                                       )))
                              ) riga_sgravio
                   from sgravi         sgra
                      , motivi_sgravio mosg
                  where sgra.ruolo            = p_ruolo
                    and sgra.cod_fiscale      = p_cod_fiscale
                    and sgra.sequenza         = p_sequenza
                    and sgra.motivo_sgravio   = mosg.motivo_sgravio
                    and nvl(substr(sgra.note,1,1),' ') = '*'
                  order by sgra.motivo_sgravio)
     loop
       d_conta_sgravi := d_conta_sgravi + 1;
       if d_conta_sgravi = d_seq_sgravio then
          d_return := mot.riga_sgravio;
       end if;
     end loop;
  else
     d_return := null;
  end if;
--
  return d_return;
--
end;
/* End Function: F_GET_SCONTO_CONF */
/

