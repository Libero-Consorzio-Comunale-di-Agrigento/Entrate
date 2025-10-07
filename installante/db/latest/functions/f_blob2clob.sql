--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_blob2clob stripComments:false runOnChange:true 
 
create or replace function F_BLOB2CLOB
(L_BLOB BLOB)
RETURN CLOB IS
  L_CLOB         CLOB;
  L_SRC_OFFSET   NUMBER;
  L_DEST_OFFSET  NUMBER;
  V_LANG_CONTEXT NUMBER := DBMS_LOB.DEFAULT_LANG_CTX;
  L_WARNING      NUMBER;
  L_AMOUNT       NUMBER;
BEGIN
  DBMS_LOB.CREATETEMPORARY(L_CLOB, TRUE);
  L_SRC_OFFSET  := 1;
  L_DEST_OFFSET := 1;
  L_AMOUNT      := DBMS_LOB.GETLENGTH(L_BLOB);
  DBMS_LOB.CONVERTTOCLOB(L_CLOB,
                         L_BLOB,
                         L_AMOUNT,
                         L_SRC_OFFSET,
                         L_DEST_OFFSET,
                         1,
                         V_LANG_CONTEXT,
                         L_WARNING);
  RETURN L_CLOB;
END;
/* End Function: F_BLOB2CLOB */
/

