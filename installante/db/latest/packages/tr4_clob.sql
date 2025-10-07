--liquibase formatted sql 
--changeset abrandolini:20250326_152429_tr4_clob stripComments:false runOnChange:true 
 
create or replace package TR4_CLOB is
/******************************************************************************
 NOME:        HL7_XML
 DESCRIZIONE: PACKAGE HL7 TRASFORMAZIONE XML
 REVISIONI:
 Rev. Data        Autore    Descrizione
 ---- ----------  --------  --------------------------------------------------
 1    30/10/2008  PMONTOSI
******************************************************************************/
type list_char is table of varchar2(32000);
debug  boolean := false;
function ADD_CHAR
(in_clob            in clob
,in_text            in varchar2
) return clob;
function INSTR
(in_clob            in clob
,in_pattern         in varchar2
,in_start           in number default 1
,in_nth             in number default 1
,in_reverse         in number default 0
) return number;
function LENGTH
(in_clob            in clob
) return number;
function LPAD
(in_clob            in clob
,in_padded_length   in number
,in_pad_string      in varchar2 default ' '
) return clob;
function LTRIM
(in_clob             in clob
,in_trim_string      in varchar2 default ' '
) return clob;
function RTRIM
(in_clob             in clob
,in_trim_string      in varchar2 default ' '
) return clob;
function REPLACE
(in_clob            in clob
,in_search          in varchar2
,in_replace         in varchar2
) return clob;
function SUBSTR
(in_clob            in clob
,in_start           in number
,in_amount          in number default null
) return  clob;
function TO_CHAR
(in_clob              in clob
) return varchar2;
function TO_CLOB
(in_char              in varchar2
) return clob;
end;
/

create or replace package body TR4_CLOB is
procedure DEBUG_LINE
(in_text            in varchar2
)
is
 a number;
begin
  if debug then
    --dbms_output.put_line(in_text);
--    dbms_pipe.pack_message(in_text);
--    a := dbms_pipe.send_message('SA4_CLOB');
null;
  end if;
end;
function ADD_CHAR
(in_clob            in clob
,in_text            in varchar2
) return clob
is
  out_clob               clob := empty_clob();
  len                    binary_integer := 32000;
  text                   varchar2(32000);
begin
  dbms_lob.createTemporary(out_clob,TRUE,dbms_lob.session);
  if nvl(dbms_lob.getlength(in_clob),0) > 0 then
    out_clob := in_clob;
  end if;
  if in_text is not null then
    len := standard.length(in_text);
    dbms_lob.writeappend(out_clob, len, in_text);
  end if;
  return out_clob;
end;
function INSTR
(in_clob            in clob
,in_pattern         in varchar2
,in_start           in number default 1
,in_nth             in number default 1
,in_reverse         in number default 0
) return number
is
  out_pos     number;
  tmp_start   number := in_start;
  tmp_start2  number := in_start;
begin
  if in_start < 0 then
    tmp_start := dbms_lob.getlength(in_clob)+in_start;
  end if;
  if in_reverse = 0 then
    out_pos := dbms_lob.instr(in_clob,in_pattern,tmp_start,in_nth);
  else
    tmp_start2 := tmp_start;
    loop
      tmp_start2 := tmp_start2-1;
      exit when tmp_start = 0;
      out_pos := dbms_lob.instr(in_clob,in_pattern,tmp_start2,in_nth);
      exit when out_pos between 1 and tmp_start;
    end loop;
  end if;
  out_pos := nvl(out_pos,0);
  return out_pos;
end;
function LENGTH
(in_clob            in clob
) return number
is
begin
  return dbms_lob.getlength(in_clob);
end;
function LPAD
(in_clob            in clob
,in_padded_length   in number
,in_pad_string      in varchar2 default ' '
) return clob
is
  pragma autonomous_transaction;
  out_clob          clob   := empty_clob();
begin
  if (in_padded_length-length(in_clob)) <0 then
    return substr(in_clob,1,in_padded_length);
  end if;
  loop
    out_clob := add_char(out_clob,in_pad_string);
    exit when (length(out_clob) + length(in_clob)) > in_padded_length;
  end loop;
  dbms_lob.append(out_clob,in_clob);
  return substr(out_clob,length(out_clob)-in_padded_length+1);
end;
function LTRIM
(in_clob             in clob
,in_trim_string      in varchar2 default ' '
) return clob
is
  out_clob            clob  := in_clob;
  tmp_char            varchar2(32000);
  offset              number ;
begin
  for i in 1..length(in_clob)
  loop
    tmp_char := to_char(substr(out_clob,i,1));
    offset := i;
    exit when instr(in_trim_string,tmp_char) = 0;
  end loop;
  return substr(out_clob,offset,length(out_clob));
end;
function RTRIM
(in_clob             in clob
,in_trim_string      in varchar2 default ' '
) return clob
is
  out_clob            clob  := in_clob;
  tmp_char            varchar2(32000);
  i_reverse           number := 0;
  offset              number ;
begin
  for i in 1..length(in_clob)
  loop
    i_reverse := (length(in_clob)-i)+1;
    tmp_char := to_char(substr(out_clob,i_reverse,1));
    offset := i_reverse;
    exit when instr(in_trim_string,tmp_char) = 0;
  end loop;
  return substr(out_clob,1,offset);
end;
function REPLACE
(in_clob            in clob
,in_search          in varchar2
,in_replace         in varchar2
) return clob
is
  tmp_clob               clob := in_clob;
  out_clob               clob;
  chardata               varchar2(32000);
  chunck_size            number := 30000;
  chunck                 number;
begin
  if in_clob is null then
    return out_clob;
  end if;
  if dbms_lob.getlength(in_clob) = 0 then
    return out_clob;
  end if;
  dbms_lob.createTemporary(out_clob,TRUE,dbms_lob.session);
  for i in 0..trunc(dbms_lob.getlength(tmp_clob)/chunck_size)
  loop
    chunck := chunck_size;
    exit when (chunck*i) = dbms_lob.getlength(tmp_clob);
    dbms_lob.read(tmp_clob,chunck,(chunck*i)+1,chardata);
    out_clob := add_char(out_clob,standard.replace(chardata,in_search,in_replace));
  end loop;
  -- giro sfasato
  chunck_size := 11000;
  tmp_clob := out_clob;
  out_clob := to_clob('');
  for i in 0..trunc(dbms_lob.getlength(tmp_clob)/chunck_size)
  loop
    chunck := chunck_size;
    exit when (chunck*i) = dbms_lob.getlength(tmp_clob);
    dbms_lob.read(tmp_clob,chunck,(chunck*i)+1,chardata);
    out_clob := add_char(out_clob,standard.replace(chardata,in_search,in_replace));
  end loop;
  return out_clob;
end;
function SUBSTR
(in_clob            in clob
,in_start           in number
,in_amount          in number default null
) return  clob
is
  tmp_amount        number;
  tmp_chunk         number := 4000;
  out_clob          clob;
begin
  if in_amount = 0 then
    return out_clob;
  end if;
  if in_start > dbms_lob.getlength(in_clob) then
    return out_clob;
  end if;
  tmp_amount := nvl(in_amount,(dbms_lob.getlength(in_clob)-in_start)+1);
  tmp_chunk := least(tmp_chunk,tmp_amount);
  for i in 0..trunc(tmp_amount/tmp_chunk)-1
  loop
    out_clob :=  out_clob||dbms_lob.substr(in_clob,tmp_chunk,in_start+(i*tmp_chunk));
  end loop;
  if mod(tmp_amount,tmp_chunk) > 0 then
    out_clob :=  out_clob||dbms_lob.substr(in_clob,mod(tmp_amount,tmp_chunk),in_start+((trunc(tmp_amount/tmp_chunk))*tmp_chunk));
  end if;
  return out_clob;
end;
function TO_CHAR
(in_clob              in clob
) return varchar2
is
  out_char               varchar2(32000) := null;
  len                    binary_integer := 32000;
begin
  if nvl(dbms_lob.getlength(in_clob),0) = 0 then
    out_char := null;
  else
    dbms_lob.read(in_clob,len,1,out_char);
  end if;
  return out_char;
end;
--function TO_CHAR
--(in_clob              in clob
--) return list_char
--is
--  out_char               list_char;
--  chunck_size            number := 30000;
--  chunck                 number;
--begin
--  if nvl(dbms_lob.getlength(in_clob),0) = 0 then
--    out_char(1) := null;
--  end if;
--  for i in 0..trunc(dbms_lob.getlength(in_clob)/chunck_size)
--  loop
--    chunck := chunck_size;
--    dbms_lob.read(in_clob,chunck,(chunck*i)+1,out_char(i+1));
--  end loop;
--  return out_char;
--end;
function TO_CLOB
(in_char              in varchar2
) return clob
is
  out_clob               clob := empty_clob();
  len                    binary_integer := 32000;
begin
  len := standard.length(in_char);
  dbms_lob.createTemporary(out_clob,TRUE,dbms_lob.session);
  if in_char is not null then
    dbms_lob.write(out_clob, len, 1, in_char);
  end if;
  return out_clob;
end;
--function TO_CLOB
--(in_char              in list_char
--) return clob
--is
--  out_clob               clob := empty_clob();
--  len                    binary_integer := 32000;
--begin
--  dbms_lob.createTemporary(out_clob,TRUE,dbms_lob.session);
--  if in_char(1) is not null then
--    for i in 1..in_char.count
--    loop
--      out_clob := add_char(out_clob,in_char(i));
--    end loop;
--  end if;
--  return out_clob;
--end;
end;
/

