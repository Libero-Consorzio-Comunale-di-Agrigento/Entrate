--liquibase formatted sql 
--changeset abrandolini:20250326_152423_trasmissione_rid_std stripComments:false runOnChange:true 
 
create or replace procedure TRASMISSIONE_RID_STD
/*************************************************************************
 NOME:        TRASMISSIONE_RID_STD
 DESCRIZIONE: Estrazione RID versione standard
 NOTE:
 Rev.    Date         Author      Note
 000     11/04/2018   VD          Prima emissione.
*************************************************************************/
( a_ruolo               IN number
, a_rata                IN number
, a_cod_sia             IN varchar2
, a_dati_iban_ente      IN varchar2
, a_creditor_id         IN varchar2
, a_num_righe          OUT number
) IS
w_data_elaborazione     varchar2(6);
w_numero_ord            varchar2(15);
w_importo_ruolo         number := 0;
w_numero                number := 0;
w_disposizioni          number := 0;
w_tot_importo           number := 0;
w_tot_record            number := 0;
w_progressivo           number := 0;
w_istat                 varchar2(6);
w_belfiore              varchar2(4);
w_supporto              varchar2(20);
w_denominazione_comune  varchar2(60);
w_indirizzo_ufficio_com varchar2(200);
w_descrizione_titr      varchar2(100);
w_abi_ricevente         varchar2(5);
w_cab_ricevente         varchar2(5);
w_cc_ricevente          varchar2(12);
CURSOR sel_ruco IS
select max(sogg.ni)                                                ni
      ,max(rpad(replace(nvl(sogg.cognome_nome,' '),'/',' '),60))
                                                           cognome_nome
      ,max(decode(arvi.cod_via
             ,null,substr(nvl(sogg.denominazione_via,' '),1,23)||
                   decode(sogg.num_civ
                         ,null,''
                              ,', '||substr(to_char(sogg.num_civ),1,5)||
                               decode(sogg.suffisso
                                     ,null,null
                                          ,'/'||substr(sogg.suffisso,1,2)
                                     )
                         )
                  ,substr(nvl(arvi.denom_uff,' '),1,23)||
                decode(sogg.num_civ
                         ,null,''
                              ,', '||substr(to_char(sogg.num_civ),1,5)||
                               decode(sogg.suffisso
                                     ,null,null
                                          ,'/'||substr(sogg.suffisso,1,2)
                                     )
                         )
             ))                                          indirizzo
      ,max(nvl(sogg.cap,nvl(comu.cap,0)))                cap
      ,max(substr(nvl(comu.denominazione,' '),1,20)||' '||
       decode(prov.sigla,null,null,'('||prov.sigla||')')) comune
      ,sum(lpad(to_char(nvl(ruco.importo,0)),13,'0'))    importo_ruolo
      ,max(lpad(to_char(nvl(deba.cod_abi,0)),5,'0'))     cod_abi
      ,max(lpad(to_char(nvl(deba.cod_cab,0)),5,'0'))     cod_cab
      ,max(lpad(nvl(deba.conto_corrente,'0'),12,'0'))    conto_corrente
      ,max(nvl(deba.cin_bancario,' '))                   cin_bancario
      ,max(deba.iban_paese)                              iban_paese
      ,max(lpad(to_char(nvl(deba.iban_cin_europa,0)),2,'0'))  iban_cin_europa
      ,max(ruol.anno_ruolo)                              anno_ruolo
      ,max(to_char(ruol.scadenza_prima_rata,'ddmmyy'))   data_scadenza
      ,max(to_char(ruol.scadenza_rata_2,'ddmmyy'))       data_scadenza_2
     ,max('0101'||substr(ruol.anno_ruolo,3,2))          data_sottoscrizione_mandato   -- lo mettiamo a 0101 dell'anno_ruolo non avendolo in tabella AB 16/04/2018
  from ad4_provincie            prov
      ,ad4_comuni               comu
      ,archivio_vie             arvi
      ,deleghe_bancarie         deba
      ,soggetti                 sogg
      ,contribuenti             cont
      ,ruoli                    ruol
      ,ruoli_contribuente       ruco
 where prov.provincia       (+) = comu.provincia_stato
   and comu.comune          (+) = sogg.cod_com_res
   and comu.provincia_stato (+) = sogg.cod_pro_res
   and arvi.cod_via         (+) = sogg.cod_via
   and sogg.ni                  = cont.ni
   and deba.cod_fiscale         = cont.cod_fiscale
   and deba.iban_paese           is not null
   and deba.iban_cin_europa      is not null
   and deba.cin_bancario         is not null
   and deba.cod_abi              is not null
   and deba.cod_cab              is not null
   and deba.conto_corrente       is not null
   and decode(deba.flag_delega_cessata,
              'S',nvl(data_ritiro_delega,to_date('01011900','ddmmyyyy')),
                  to_date('31122999','ddmmyyyy')) > ruol.data_emissione
   and cont.cod_fiscale         = ruco.cod_fiscale
   and ruco.ruolo               = ruol.ruolo
   and deba.tipo_tributo        = ruol.tipo_tributo
   and ruol.ruolo               = a_ruolo
 group by ruco.cod_fiscale
 order by
       2 --sogg.cognome_nome
      ,1 --sogg.ni
;
BEGIN
   BEGIN
      if a_rata <> 1 and a_rata <> 2 then
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'La Rata puo` essere solo 1 o 2.');
      end if;
   END;
   BEGIN
      select '1'
        into w_numero_ord
        from ruoli
       where ruolo            = a_ruolo
         and importo_lordo    = 'S'
         and nvl(rate,0)      = 2
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Ruolo Non previsto o non a Importo Lordo o '||
                                        'con numero di rate diverso da 2.');
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in consultazione Ruolo '||
                                        ' ('||SQLERRM||')');
   END;
   --
   -- Controllo parametri
   --
   BEGIN
      if nvl(length(a_cod_sia),0) <> 5 then
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Il codice SIA dell''ente deve essere di 5 caratteri');
      end if;
   END;
   BEGIN
      if nvl(length(a_dati_iban_ente),0) <> 27 then
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Dati IBAN dell''ente non corretti');
      end if;
   END;
   BEGIN
      select  '1'
            ,to_char(sysdate,'ddmmyy')
            ,lpad(to_char(dage.pro_cliente),3,'0')||
             lpad(to_char(dage.com_cliente),3,'0')
            ,comu.sigla_cfis
            ,comu.denominazione
            ,titr.indirizzo_ufficio
            ,titr.descrizione
        into w_numero_ord
            ,w_data_elaborazione
            ,w_istat
            ,w_belfiore
            ,w_denominazione_comune
            ,w_indirizzo_ufficio_com
            ,w_descrizione_titr
        from dati_generali dage
           , ad4_comuni    comu
           , tipi_tributo  titr
       where dage.pro_cliente  = comu.provincia_stato
         and dage.com_cliente  = comu.comune
         and titr.tipo_tributo = 'TARSU'
         ;
   EXCEPTION
      WHEN others THEN
         RAISE_APPLICATION_ERROR(-20999,'Errore in estrazione Dati Ente '||
                                        ' ('||SQLERRM||')');
   END;
   BEGIN
      si4.sql_execute('truncate table wrk_tras_anci');
   EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in pulizia tabella di lavoro '||
                                        ' ('||SQLERRM||')');
   END;
   w_supporto := w_belfiore||'_TARSU_RID.txt';
   --
   -- Composizione campi dell'ente
   --
   w_abi_ricevente := substr(a_dati_iban_ente,6,5);
   w_cab_ricevente := substr(a_dati_iban_ente,11,5);
   w_cc_ricevente  := substr(a_dati_iban_ente,16,12);
   --
   BEGIN
      w_progressivo := w_progressivo + 1;
      insert into wrk_tras_anci
            (anno,progressivo,dati)
      values(0
            ,w_progressivo
            ,' '
          || 'IR'
          || a_cod_sia
          || w_abi_ricevente
          || lpad(w_data_elaborazione,6,'0')
          || rpad(w_supporto,20,' ')
          || rpad(' ',6,' ')
          || rpad(' ',68,' ')
          || 'E'
          || rpad(' ',6,' ')
            )
      ;
   EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record IR) ' ||
                                        ' ('||SQLERRM||')');
   END;
   w_tot_record := w_tot_record + 1;
   FOR rec_ruco IN sel_ruco LOOP
      -- Verifica presenza scadenza seconda rata sul Ruolo
      if rec_ruco.data_scadenza_2 is null and a_rata = 2 then
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore: la scadenza seconda rata non è presente sul Ruolo!');
      end if;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      w_importo_ruolo := round(rec_ruco.importo_ruolo,0);
      if a_rata = 1 then
         w_importo_ruolo := round(w_importo_ruolo / 2,0) * 100;
      else
         w_importo_ruolo := (w_importo_ruolo - round(w_importo_ruolo / 2,0)) * 100;
      end if;
      w_numero := w_numero + 1;
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '10'
             || lpad(to_char(w_numero),7,'0')
             || rpad(' ',12,' ')
             || decode(a_rata
                      ,1,lpad(nvl(rec_ruco.data_scadenza,'0'),6,'0')
                        ,lpad(nvl(rec_ruco.data_scadenza_2,'0'),6,'0')
                      )
             || '50000'
             || lpad(to_char(nvl(w_importo_ruolo,0)),13,'0')
             || '-'
             -- Banca Assuntrice
             || w_abi_ricevente                                                 -- codice ABI banca
             || w_cab_ricevente                                                 -- codice CAB banca
             || w_cc_ricevente                                                  -- Conto
             -- Banca Domiciliataria
             || lpad(rec_ruco.cod_abi,5,'0')
             || lpad(rec_ruco.cod_cab,5,'0')
             || rpad(' ',12)                                                    -- rpad(rec_ruco.conto_corrente,12,' ')  Sul nuovo tracciato ABI è a spazio
             -- Azienda Creditrice
             || a_cod_sia                                                       -- codice SIA cliente
             || '4'
             || rpad(to_char(rec_ruco.ni),16,' ')
             || rpad(' ',6,' ')
             || 'E'
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 10) ' ||
                                           ' ('||SQLERRM||')');
      END;
      --
      -- Gestione record 16
      --
      BEGIN
        w_progressivo := w_progressivo + 1;
            insert into wrk_tras_anci
                  (anno,progressivo,dati)
            values(0
                  ,w_progressivo
              ,' '
              || '16'
              || lpad(to_char(w_numero),7,'0')
              || a_dati_iban_ente
              || rpad(' ',7,' ')
              || rpad(a_creditor_id,35)
              || rpad(' ',41,' ')
              )
              ;
      EXCEPTION
        WHEN others THEN
          ROLLBACK;
          RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 16) ' ||
                                         ' ('||SQLERRM||')');
      END;
      if rec_ruco.iban_paese is not null then  -- gestione record 17
         BEGIN
            w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
                ,w_progressivo
                ,' '
                || '17'
                || lpad(to_char(w_numero),7,'0')
                || lpad(nvl(rec_ruco.iban_paese,' '),2,' ')
                || rec_ruco.iban_cin_europa
                || rec_ruco.cin_bancario
                || lpad(rec_ruco.cod_abi,5,'0')
                || lpad(rec_ruco.cod_cab,5,'0')
                || lpad(rec_ruco.conto_corrente,12,'0')
                || 'RCUR'                        -- tipo sequenza
                || rec_ruco.data_sottoscrizione_mandato
                || rpad(' ',73,' ')
                  )
                  ;
         EXCEPTION
            WHEN others THEN
               ROLLBACK;
               RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 16) ' ||
                                           ' ('||SQLERRM||')');
         END;
      w_tot_record := w_tot_record + 1;
      end if;
      w_tot_importo := w_tot_importo + w_importo_ruolo;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '20'
             || lpad(to_char(w_numero),7,'0')
             || substr(rpad('COMUNE DI '||w_denominazione_comune||'   '||Upper(w_indirizzo_ufficio_com)
                           ,90,' ')
                      ,1,90)
             || rpad(' ',20,' ')
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 20) ' ||
                                           ' ('||SQLERRM||')');
      END;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '30'
             || lpad(to_char(w_numero),7,'0')
             || rpad(rec_ruco.cognome_nome,90,' ')
             || rpad(' ',20,' ')
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 30) ' ||
                                           ' ('||SQLERRM||')');
      END;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '40'
             || lpad(to_char(w_numero),7,'0')
             || rpad(rec_ruco.indirizzo,30,' ')
             || lpad(to_char(rec_ruco.cap),5,'0')
             || rpad(rec_ruco.comune,25,' ')
             || rpad(' ',50,' ')
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 40) ' ||
                                           ' ('||SQLERRM||')');
      END;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '50'
             || lpad(to_char(w_numero),7,'0')
             || decode(a_rata
                      ,1,rpad('TASSA RIFIUTI '||to_char(rec_ruco.anno_ruolo)
                              ||' - PRIMA RATA - SCADENZA IL '
                              ||lpad(rec_ruco.data_scadenza,6,0)
                             ,90,' ')
                        ,rpad('TASSA RIFIUTI '||to_char(rec_ruco.anno_ruolo)
                              ||' - SECONDA RATA - SCADENZA IL '
                              ||lpad(rec_ruco.data_scadenza_2,6,0)
                             ,90,' ')
                      )
             || rpad(' ',20,' ')
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 50) ' ||
                                           ' ('||SQLERRM||')');
      END;
      w_numero_ord := to_char(to_number(w_numero_ord) + 1);
      BEGIN
         w_progressivo := w_progressivo + 1;
         insert into wrk_tras_anci
               (anno,progressivo,dati)
         values(0
               ,w_progressivo
               ,' '
             || '70'
             || lpad(to_char(w_numero),7,'0')
             || rpad(' ',15,' ')
             || rpad(' ',95,' ')
               )
         ;
      EXCEPTION
         WHEN others THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record 70) ' ||
                                           ' ('||SQLERRM||')');
      END;
      w_tot_record := w_tot_record + 7;
   END LOOP;
   w_disposizioni := w_numero;
   w_numero_ord := to_char(to_number(w_numero_ord) + 1);
   w_tot_record := w_tot_record + 1;
   BEGIN
      w_progressivo := w_progressivo + 1;
      insert into wrk_tras_anci
            (anno,progressivo,dati)
      values(0
            ,w_progressivo
            ,' '
          || 'EF'
          || a_cod_sia
          || w_abi_ricevente
          || lpad(w_data_elaborazione,6,'0')
          || rpad(w_supporto,20,' ')
          || rpad(' ',6,' ')
          || lpad(to_char(w_disposizioni),7,'0')
          || lpad(to_char(w_tot_importo),15,'0')
          || rpad('0',15,'0')
          || lpad(to_char(w_tot_record),7,'0')
          || rpad(' ',24,' ')
          || 'E'
          || rpad(' ',6,' ')
            )
      ;
   EXCEPTION
      WHEN others THEN
         ROLLBACK;
         RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento dati (Record EF) ' ||
                                        ' ('||SQLERRM||')');
   END;
   a_num_righe := w_progressivo;
/* ------------------------------------- */
   COMMIT;
/* ------------------------------------- */
EXCEPTION
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Errore in Trasmissione RID' ||
                                     ' ('||SQLERRM||')');
END;
/* End Procedure: TRASMISSIONE_RID_STD */
/

