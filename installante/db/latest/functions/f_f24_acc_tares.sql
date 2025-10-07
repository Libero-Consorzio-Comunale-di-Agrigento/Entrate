--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_acc_tares stripComments:false runOnChange:true 
 
create or replace function F_F24_ACC_TARES
/*************************************************************************
 Descrizione: la funzione restituisce una stringa contenente codice
              tributo e importo ai fini della stampa dell'F24
 Versione  Data              Autore    Descrizione
 1         05/04/2016        VD        Aggiunto campo rateazione nella
                                       riga di output
**************************************************************************/
(a_riga                    number
,a_importo_tari_tassa      number
,a_interessi_tari_tassa    number
,a_sanzioni_tari_tassa     number
,a_importo_tariffa         number
,a_interessi_tariffa       number
,a_sanzioni_tariffa        number
,a_maggiorazione           number
,a_interessi_maggiorazione number
,a_sanzioni_maggiorazione  number
)
return varchar2
is
   w_importo_tari_tassa      varchar2(19);
   w_interessi_tari_tassa    varchar2(19);
   w_sanzioni_tari_tassa     varchar2(19);
   w_importo_tariffa         varchar2(19);
   w_interessi_tariffa       varchar2(19);
   w_sanzioni_tariffa        varchar2(19);
   w_maggiorazione           varchar2(19);
   w_interessi_maggiorazione varchar2(19);
   w_sanzioni_maggiorazione  varchar2(19);
TYPE type_riga IS TABLE OF varchar2(19)
INDEX BY binary_integer;
t_riga       type_riga;
i            binary_integer := 1;
begin
   w_importo_tari_tassa      := '3944'||to_char(round(a_importo_tari_tassa,0),'999999990')||'0101';
   w_interessi_tari_tassa    := '3945'||to_char(round(a_interessi_tari_tassa,0),'999999990');
   w_sanzioni_tari_tassa     := '3946'||to_char(round(a_sanzioni_tari_tassa,0),'999999990');
   w_importo_tariffa         := '3950'||to_char(round(a_importo_tariffa,0),'999999990')||'0101';
   w_interessi_tariffa       := '3951'||to_char(round(a_interessi_tariffa,0),'999999990');
   w_sanzioni_tariffa        := '3952'||to_char(round(a_sanzioni_tariffa,0),'999999990');
   w_maggiorazione           := '3955'||to_char(round(a_maggiorazione,0),'999999990')||'0101';
   w_interessi_maggiorazione := '3956'||to_char(round(a_interessi_maggiorazione,0),'999999990');
   w_sanzioni_maggiorazione  := '3957'||to_char(round(a_sanzioni_maggiorazione,0),'999999990');
   if nvl(a_importo_tari_tassa,0) > 0.49 then
      t_riga(to_char(i)) := w_importo_tari_tassa;
      i := i+1;
   end if;
   if nvl(a_interessi_tari_tassa,0) > 0.49  then
      t_riga(to_char(i)) := w_interessi_tari_tassa;
      i := i+1;
   end if;
   if nvl(a_sanzioni_tari_tassa,0) > 0.49  then
      t_riga(to_char(i)) := w_sanzioni_tari_tassa;
      i := i+1;
   end if;
   if nvl(a_importo_tariffa,0) > 0.49  then
      t_riga(to_char(i)) := w_importo_tariffa;
      i := i+1;
   end if;
   if nvl(a_interessi_tariffa,0) > 0.49  then
      t_riga(to_char(i)) := w_interessi_tariffa;
      i := i+1;
   end if;
   if nvl(a_sanzioni_tariffa,0) > 0.49 then
      t_riga(to_char(i)) := w_sanzioni_tariffa;
      i := i+1;
   end if;
   if nvl(a_maggiorazione,0) > 0.49 then
      t_riga(to_char(i)) := w_maggiorazione;
      i := i+1;
   end if;
   if nvl(a_interessi_maggiorazione,0) > 0.49 then
      t_riga(to_char(i)) := w_interessi_maggiorazione;
      i := i+1;
   end if;
   if nvl(a_sanzioni_maggiorazione,0) > 0.49  then
      t_riga(to_char(i)) := w_sanzioni_maggiorazione;
      i := i+1;
   end if;
   return t_riga(to_char(a_riga));
end;
/* End Function: F_F24_ACC_TARES */
/

