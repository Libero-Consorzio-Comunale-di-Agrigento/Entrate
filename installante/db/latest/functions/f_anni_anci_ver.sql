--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_anni_anci_ver stripComments:false runOnChange:true 
 
create or replace function F_ANNI_ANCI_VER
return varchar2
--Genera un messaggio del genere:
--Fornitura: 1, Anno/i: ...
--Fornitura: 4, Anno/i: ...
is
--Contiene gli anni dove non esistono delle anomalie
cursor sel_anni_anci_ver is
select to_char( trunc( (progr_record/1000000), 0 ) ) fornitura,
       to_char( decode( sign(anno_fiscale - 100)
                       , -1, decode(sign(anno_fiscale - 92)
                       , 1, to_number('19'||anno_fiscale)
                       , to_number('20'||lpad(anno_fiscale,2,'0')))
                       , anno_fiscale) ) anno_fiscale
 from anci_ver
 where tipo_anomalia is NULL
 group by to_char( trunc( (progr_record/1000000), 0 ) ),
          to_char( decode( sign(anno_fiscale - 100)
                           , -1, decode(sign(anno_fiscale - 92)
                           , 1, to_number('19'||anno_fiscale)
                           , to_number('20'||lpad(anno_fiscale,2,'0')))
                           , anno_fiscale) )
       ;
w_return varchar2(1000) := ''; --Stringa di ritorno
old_forn int; --Serve per gestire l'andata a capo per ogni fornitura
BEGIN
  FOR rec_anni_anci_ver in sel_anni_anci_ver LOOP
       --Si aggiunge la fornitura ed ogni anno senza anomalie
       --alla stringa di ritorno
       if w_return is null then
          old_forn := rec_anni_anci_ver.fornitura;
            w_return := chr(010)
                   || 'Fornitura: '
                   || rec_anni_anci_ver.fornitura
                   || ', '
                   || 'Anno/i: '
                   || rec_anni_anci_ver.anno_fiscale;
        else
          if rec_anni_anci_ver.fornitura != old_forn then
             --Altra fornitura
             old_forn := rec_anni_anci_ver.fornitura;
             w_return := chr(010)
                         || w_return
                         || 'Fornitura: '
                         || rec_anni_anci_ver.fornitura
                         || ', '
                         || 'Anno/i: '
                         || rec_anni_anci_ver.anno_fiscale
                         || chr(010);
          else
             w_return := w_return
                      || ', '
                      || rec_anni_anci_ver.anno_fiscale;
          end if;
        end if;
  END LOOP;
  w_return := w_return || chr(010);
  return w_return;
EXCEPTION
  WHEN others THEN
     return null;
END;
/* End Function: F_ANNI_ANCI_VER */
/

