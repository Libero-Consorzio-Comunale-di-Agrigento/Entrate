--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_tributiweb stripComments:false runOnChange:true 
 
create or replace function F_F24_TRIBUTIWEB
/*************************************************************************
 NOME:        F_F24_TRIBUTIWEB
 DESCRIZIONE: TributiWeb: stampa modello F24 da folder "Imposte" di
              situazione contribuente
 PARAMETRI:   Tipo tributo        ICI/TASI
              Codice fiscale      Codice fiscale del contribuente
              Anno                Anno di riferimento
              Tipo versamento     A - Acconto, S - Saldo, U - Unico
              Dovuto Versato.     Solo per F24 a saldo
                                  D - Dovuto: calcola gli importi in base
                                      all'imposta dovuta (totale - acconto)
                                  V - Versato: calcola gli importi in base
                                      a quanto gia' eventualmente versato
                                      (totale - versato)
              Riga                Numero di riga dell'F24
 RITORNA:     varchar2            Stringa contenente il codice tributo e
                                  l'importo della riga dell'F24.
 NOTE:
 Rev.    Date         Author      Note
 001     14/04/2022   VD          Modificato richiamo procedure per calcolo
                                  importi: ora utilizza la procedure
                                  IMPORTI_IMU del package STAMPA_COM_IMPOSTA
                                  per ottenere anche il numero dei terreni e
                                  il numero delle aree fabbricabili
 000     29/04/2021   VD          Prima emissione.
*************************************************************************/
( a_tipo_tributo           in     varchar2
, a_cod_fiscale            in     varchar2
, a_anno                   in     number
, a_tipo_versamento        in     varchar2
, a_dovuto_versato         in     varchar2
, a_riga                   in     number
)
return varchar2
is
a_terreni_comu                    number;
a_terreni_erar                    number;
a_aree_comu                       number;
a_aree_erar                       number;
a_ab_comu                         number;
a_detrazione                      number;
a_rurali_comu                     number;
a_altri_comu                      number;
a_altri_erar                      number;
a_fabb_d_comu                     number;
a_fabb_d_erar                     number;
a_fabb_merce                      number;
a_interessi                       number;
a_sanzioni                        number;
a_num_terreni                     number;
a_num_aree                        number;
a_num_fabb_ab                     number;
a_num_fabb_rurali                 number;
a_num_fabb_altri                  number;
a_num_fabb_d                      number;
a_num_fabb_merce                  number;
w_ab_comu                         varchar2(29);
w_rurali_comu                     varchar2(19);
w_terreni_comu                    varchar2(19);
w_terreni_erar                    varchar2(19);
w_aree_comu                       varchar2(19);
w_aree_erar                       varchar2(19);
w_altri_comu                      varchar2(19);
w_altri_erar                      varchar2(19);
w_fabbricati_d_comu               varchar2(19);
w_fabbricati_d_erar               varchar2(19);
w_fabbricati_merce                varchar2(19);
w_interessi                       varchar2(19);
w_sanzioni                        varchar2(19);
TYPE type_riga IS TABLE OF varchar2(29)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
  if a_tipo_tributo = 'ICI' then
     /*importi_f24_imu ( a_cod_fiscale, a_anno, a_tipo_versamento
                     , a_terreni_comu, a_terreni_erar
                     , a_aree_comu, a_aree_erar
                     , a_ab_comu, a_detrazione, a_rurali_comu
                     , a_altri_comu, a_altri_erar
                     , a_num_fabb_ab, a_num_fabb_rurali, a_num_fabb_altri
                     , a_fabb_d_comu, a_fabb_d_erar, a_num_fabb_d
                     , a_fabb_merce, a_num_fabb_merce
                     , a_dovuto_versato);*/
     stampa_com_imposta.importi_f24_imu ( a_cod_fiscale, a_anno
                                        , a_tipo_versamento, a_dovuto_versato
                                        , a_terreni_comu, a_terreni_erar
                                        , a_aree_comu, a_aree_erar
                                        , a_ab_comu, a_detrazione, a_rurali_comu
                                        , a_altri_comu, a_altri_erar
                                        , a_fabb_d_comu, a_fabb_d_erar
                                        , a_fabb_merce
                                        , a_num_terreni, a_num_aree
                                        , a_num_fabb_ab, a_num_fabb_rurali, a_num_fabb_altri
                                        , a_num_fabb_d, a_num_fabb_merce
                                        );
     w_ab_comu           := '3912'||to_char(round(a_ab_comu,0),'999999990')||to_char(a_num_fabb_ab,'990')||to_char(round(a_detrazione,0),'999999990');
     w_rurali_comu       := '3913'||to_char(round(a_rurali_comu,0),'999999990')||to_char(a_num_fabb_rurali,'990');
     w_terreni_comu      := '3914'||to_char(round(a_terreni_comu,0),'999999990')||to_char(a_num_terreni,'990');
     w_terreni_erar      := '3915'||to_char(round(a_terreni_erar,0),'999999990')||to_char(a_num_terreni,'990');
     w_aree_comu         := '3916'||to_char(round(a_aree_comu,0),'999999990')||to_char(a_num_aree,'990');
     w_aree_erar         := '3917'||to_char(round(a_aree_erar,0),'999999990')||to_char(a_num_aree,'990');
     w_altri_comu        := '3918'||to_char(round(a_altri_comu,0),'999999990')||to_char(a_num_fabb_altri,'990');
     w_altri_erar        := '3919'||to_char(round(a_altri_erar,0),'999999990')||to_char(a_num_fabb_altri,'990');
     w_fabbricati_d_comu := '3930'||to_char(round(a_fabb_d_comu,0),'999999990')||to_char(a_num_fabb_d,'990');
     w_fabbricati_d_erar := '3925'||to_char(round(a_fabb_d_erar,0),'999999990')||to_char(a_num_fabb_d,'990');
     w_fabbricati_merce  := '3939'||to_char(round(a_fabb_merce,0),'999999990')||to_char(a_num_fabb_merce,'990');
     w_interessi         := '3923'||to_char(round(a_interessi,0),'999999990');
     w_sanzioni          := '3924'||to_char(round(a_sanzioni,0),'999999990');
     if nvl(round(a_ab_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_ab_comu;
        i := i+1;
     end if;
     if nvl(round(a_rurali_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_rurali_comu;
        i := i+1;
     end if;
     if nvl(round(a_terreni_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_terreni_comu;
        i := i+1;
     end if;
     if nvl(round(a_terreni_erar,0),0) > 0 then
        t_riga(to_char(i)) := w_terreni_erar;
        i := i+1;
     end if;
     if nvl(round(a_aree_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_aree_comu;
        i := i+1;
     end if;
     if nvl(round(a_aree_erar,0),0) > 0 then
        t_riga(to_char(i)) := w_aree_erar;
        i := i+1;
     end if;
     if nvl(round(a_altri_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_altri_comu;
        i := i+1;
     end if;
     if nvl(round(a_altri_erar,0),0) > 0 then
        t_riga(to_char(i)) := w_altri_erar;
        i := i+1;
     end if;
     if nvl(round(a_fabb_d_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_fabbricati_d_comu;
        i := i+1;
     end if;
     if nvl(round(a_fabb_d_erar,0),0) > 0 then
        t_riga(to_char(i)) := w_fabbricati_d_erar;
        i := i+1;
     end if;
     if nvl(round(a_fabb_merce,0),0) > 0 then
        t_riga(to_char(i)) := w_fabbricati_merce;
        i := i+1;
     end if;
     if nvl(round(a_interessi,0),0) > 0 then
        t_riga(to_char(i)) := w_interessi;
        i := i+1;
     end if;
     if nvl(round(a_sanzioni,0),0) > 0 then
        t_riga(to_char(i)) := w_sanzioni;
        i := i+1;
     end if;
  else
     stampa_com_imposta.importi_f24_tasi ( a_cod_fiscale, a_anno, a_tipo_versamento, a_dovuto_versato
                                         , a_terreni_comu, a_aree_comu
                                         , a_ab_comu, a_detrazione
                                         , a_rurali_comu, a_altri_comu
                                         , a_num_terreni, a_num_aree
                                         , a_num_fabb_ab, a_num_fabb_rurali
                                         , a_num_fabb_altri
                                         , a_fabb_d_comu, a_num_fabb_d
                                         );
     w_ab_comu           := '3958'||to_char(round(a_ab_comu,0),'999999990')||to_char(a_num_fabb_ab,'990')||to_char(round(a_detrazione,0),'999999990');
     w_rurali_comu       := '3959'||to_char(round(a_rurali_comu,0),'999999990')||to_char(a_num_fabb_rurali,'990');
     w_aree_comu         := '3960'||to_char(round(a_aree_comu,0),'999999990')||to_char(a_num_aree,'990');
     w_altri_comu        := '3961'||to_char(round(a_altri_comu,0),'999999990')||to_char(a_num_fabb_altri,'990');
     w_interessi         := '3962'||to_char(round(a_interessi,0),'999999990');
     w_sanzioni          := '3963'||to_char(round(a_sanzioni,0),'999999990');
     if nvl(round(a_ab_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_ab_comu;
        i := i+1;
     end if;
     if nvl(round(a_rurali_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_rurali_comu;
        i := i+1;
     end if;
     if nvl(round(a_aree_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_aree_comu;
        i := i+1;
     end if;
     if nvl(round(a_altri_comu,0),0) > 0 then
        t_riga(to_char(i)) := w_altri_comu;
        i := i+1;
     end if;
     if nvl(round(a_interessi,0),0) > 0 then
        t_riga(to_char(i)) := w_interessi;
        i := i+1;
     end if;
     if nvl(round(a_sanzioni,0),0) > 0 then
        t_riga(to_char(i)) := w_sanzioni;
        i := i+1;
     end if;
  end if;
  --
  return t_riga(to_char(a_riga));
  --
end;
/* End Function: F_F24_TRIBUTIWEB */
/

