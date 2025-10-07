--liquibase formatted sql
--changeset dmarotta:20250923_080612_83085_smart_pnd_pagamenti_sequence stripComments:false

CREATE SEQUENCE SPND_PAG_SEQ
    START WITH 1
    INCREMENT BY 1
/
