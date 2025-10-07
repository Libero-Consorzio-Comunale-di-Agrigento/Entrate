--liquibase formatted sql 
--changeset abrandolini:20250326_152423_soggetti_trb_fi stripComments:false runOnChange:true context:"TRT2 or TRV2"
 
create or replace procedure SOGGETTI_TRB_FI
(a_tipo_residente      IN   number,
 a_matricola_old      IN   number,
 a_cod_fiscale_new      IN   varchar2,
 a_cognome_nome_new      IN   varchar2,
 a_sesso_new         IN   varchar2,
 a_cod_fam_new         IN   number,
 a_data_nas_new         IN   date,
 a_cod_pro_nas_new      IN   number,
 a_cod_com_nas_new      IN   number,
 a_cod_pro_res_new      IN   number,
 a_cod_com_res_new      IN   number,
 a_cap_new         IN   number,
 a_cod_prof_new         IN   number,
 a_denominazione_via_new   IN   varchar2,
 a_num_civ_new         IN   number,
 a_suffisso_new         IN   varchar2,
 a_interno_new         IN   number,
 a_partita_iva_new      IN   varchar2,
 a_rappresentante_new      IN   varchar2,
 a_indirizzo_rap_new      IN   varchar2,
 a_cod_pro_rap_new      IN   number,
 a_cod_com_rap_new      IN   number,
 a_cod_fiscale_rap_new      IN   varchar2,
 a_tipo_carica_new      IN   number,
 a_flag_esenzione_new      IN   varchar2,
 a_tipo_new         IN   varchar2,
 a_gruppo_utente_new      IN   varchar2,
 a_flag_cf_calcolato_new   IN   varchar2,
 a_data_variazione_new      IN   date,
 a_note_new         IN   varchar2,
 a_matricola_new      IN OUT   number
)
IS
w_carica   varchar2(60);
w_errore   varchar2(2000);
errore      exception;
BEGIN
 IF Trb_IntegrityPackage.GetNestLevel = 0 THEN
  IF a_tipo_residente = 1 THEN
     BEGIN
       select descrizione
         into w_carica
         from tipi_carica
        where tipo_carica = a_tipo_carica_new
       ;
     EXCEPTION
       WHEN no_data_found THEN
            null;
       WHEN others THEN
            w_errore := 'Errore in ricerca Tipi Carica '||
              '('||SQLERRM||')';
            RAISE errore;
     END;
     IF INSERTING THEN
   BEGIN
     update n01
        set numero = numero + 1
     ;
   EXCEPTION
     WHEN others THEN
          w_errore := 'Errore in inserimento N01 '||
            '('||SQLERRM||')';
          RAISE errore;
   END;
   IF SQL%notfound THEN
      BEGIN
        insert into n01 (numero)
        values (1)
        ;
      EXCEPTION
        WHEN others THEN
        w_errore := 'Errore in inserimento N01 '||
               '('||SQLERRM||')';
        RAISE errore;
      END;
   END IF;
        BEGIN
     select numero
       into a_matricola_new
       from n01
     ;
   EXCEPTION
     WHEN others THEN
          w_errore := 'Errore in ricerca N01 '||
            '('||SQLERRM||')';
          RAISE errore;
   END;
        BEGIN
     insert into ananre
            (matricola,cognome_nome,denominazione_via,
        num_civ,suffisso,interno,provincia,
        comune,cap,cod_prof,sesso,
             data_nascita,
        provincia_nascita,comune_nascita,tipo,
        data_ult_agg,cod_fiscale,
        partita_iva,cod_fam,rappresentante,
        indir_rappr,cod_pro_rappr,cod_com_rappr,
        carica,cod_fiscale_rappr,note_1,
        note_2,note_3,
        esenzione,gruppo_utente,
        cf_calcolato)
     values (a_matricola_new,a_cognome_nome_new,a_denominazione_via_new,
        a_num_civ_new,a_suffisso_new,a_interno_new,a_cod_pro_res_new,
         a_cod_com_res_new,a_cap_new,a_cod_prof_new,a_sesso_new,
        to_char(a_data_nas_new,'j'),
             a_cod_pro_nas_new,a_cod_com_nas_new,a_tipo_new,
        to_char(a_data_variazione_new,'j'),a_cod_fiscale_new,
        a_partita_iva_new,a_cod_fam_new,a_rappresentante_new,
        a_indirizzo_rap_new,a_cod_pro_rap_new,a_cod_com_rap_new,
        w_carica,a_cod_fiscale_rap_new,substr(a_note_new,1,60),
        substr(a_note_new,61,60),substr(a_note_new,121,60),
        a_flag_esenzione_new,a_gruppo_utente_new,
        a_flag_cf_calcolato_new)
     ;
      EXCEPTION
     WHEN others THEN
          w_errore := 'Errore in inserimento Anagrafe Non Residenti '||               '('||SQLERRM||')';
          RAISE errore;
        END;
     ELSIF UPDATING THEN
   BEGIN
     update ananre
        set matricola      = a_matricola_new,
       cognome_nome      = a_cognome_nome_new,
       denominazione_via   = a_denominazione_via_new,
       num_civ      = a_num_civ_new,
       suffisso      = a_suffisso_new,
       interno      = a_interno_new,
       provincia      = a_cod_pro_res_new,
       comune         = a_cod_com_res_new,
       cap         = a_cap_new,
       cod_prof      = a_cod_prof_new,
       sesso         = a_sesso_new,
            data_nascita      = to_char(a_data_nas_new,'j'),
       provincia_nascita   = a_cod_pro_nas_new,
       comune_nascita      = a_cod_com_nas_new,
       tipo         = a_tipo_new,
       data_ult_agg      = to_char(a_data_variazione_new,'j'),
       cod_fiscale      = a_cod_fiscale_new,
       partita_iva      = a_partita_iva_new,
       cod_fam      = a_cod_fam_new,
       rappresentante      = a_rappresentante_new,
       indir_rappr      = a_indirizzo_rap_new,
       cod_pro_rappr      = a_cod_pro_rap_new,
       cod_com_rappr      = a_cod_com_rap_new,
       carica         = w_carica,
       cod_fiscale_rappr   = a_cod_fiscale_rap_new,
       note_1         = substr(a_note_new,1,60),
       note_2         = substr(a_note_new,61,60),
       note_3       = substr(a_note_new,121,60),
       esenzione      = a_flag_esenzione_new,
       gruppo_utente      = a_gruppo_utente_new,
       cf_calcolato      = a_flag_cf_calcolato_new
      where matricola       = a_matricola_old
     ;
      EXCEPTION
     WHEN others THEN
          w_errore := 'Errore in aggiornamento Anagrafe Non Residenti '||
            '('||SQLERRM||')';
          RAISE errore;
        END;
     ELSIF DELETING THEN
        BEGIN
     delete ananre
      where matricola = a_matricola_old
     ;
        EXCEPTION
     WHEN others THEN
               w_errore := 'Errore in cancellazione Anagrafe Non Residenti '||
                 '('||SQLERRM||')';
                 RAISE errore;
        END;
     END IF;
  END IF;
 END IF;
EXCEPTION
  WHEN errore THEN
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       RAISE_APPLICATION_ERROR
    (-20999,SQLERRM);
END;
/* End Procedure: SOGGETTI_TRB_FI */
/

