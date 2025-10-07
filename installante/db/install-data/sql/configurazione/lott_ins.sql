--liquibase formatted sql
--changeset dmarotta:20250326_152438_lott_ins stripComments:false  endDelimiter:/
--validCheckSum: 1:any

ALTER TABLE locazioni_tipi_tracciato MODIFY(tracciato  DEFAULT 'X')
/

ALTER TABLE locazioni_tipi_tracciato DISABLE ALL TRIGGERS
/

INSERT INTO LOCAZIONI_TIPI_TRACCIATO ( TIPO_TRACCIATO, DATA_INIZIO, DATA_FINE, TITOLO_DOCUMENTO) SELECT 1,to_date('01/01/1900','dd/mm/yyyy'),to_date('31/07/2011','dd/mm/yyyy'),28 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM LOCAZIONI_TIPI_TRACCIATO WHERE TIPO_TRACCIATO=1)
/
DECLARE
   dep_clob Clob := empty_clob();
   dep_stringa1 varchar2(32767);
BEGIN
   dbms_lob.createTemporary(dep_clob,TRUE,dbms_lob.session);
   dep_stringa1 := '{
    "0": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "vuoto": {
            "da": 151,
            "a": 200
        }
    },
    "1": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione01": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "intestazione02": {
            "da": 151,
            "a": 156
        },
        "numeroRecord": {
            "da": 156,
            "a": 161
        },
        "vuoto": {
            "da": 161,
            "a": 200
        }
    },
    "A": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "dataReg": {
            "da": 16,
            "a": 26
        },
        "dataStipula": {
            "da": 26,
            "a": 36
        },
        "codiceOggetto": {
            "da": 36,
            "a": 38
        },
        "importoCanone": {
            "da": 38,
            "a": 53
        },
        "valutaCanone": {
            "da": 53,
            "a": 54
        },
        "tipoCanone": {
            "da": 54,
            "a": 55
        },
        "dataInizio": {
            "da": 55,
            "a": 65
        },
        "dataFine": {
            "da": 65,
            "a": 75
        },
        "comune": {
            "da": 75,
            "a": 79
        },
        "indirizzo": {
            "da": 79,
            "a": 119
        },
        "vuoto": {
            "da": 119,
            "a": 200
        }
    },
    "B": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "prgSoggetto": {
            "da": 16,
            "a": 19
        },
        "tipoSoggetto": {
            "da": 19,
            "a": 20
        },
        "codFiscale": {
            "da": 20,
            "a": 36
        },
        "sesso": {
            "da": 36,
            "a": 37
        },
        "cittaNasc": {
            "da": 37,
            "a": 67
        },
        "provNasc": {
            "da": 67,
            "a": 69
        },
        "dataNasc": {
            "da": 69,
            "a": 79
        },
        "cittaRes": {
            "da": 79,
            "a": 109
        },
        "provRes": {
            "da": 109,
            "a": 111
        },
        "indirizzoRes": {
            "da": 111,
            "a": 146
        },
        "numCivRes": {
            "da": 146,
            "a": 152
        },
        "dataSubentro": {
            "da": 152,
            "a": 162
        },
        "dataCessione": {
            "da": 162,
            "a": 172
        },
        "vuoto": {
            "da": 172,
            "a": 200
        }
    }
}
';
   dbms_lob.writeappend(dep_clob,length(dep_stringa1),dep_stringa1);
   update LOCAZIONI_TIPI_TRACCIATO set tracciato = dep_clob where TIPO_TRACCIATO=1;
END;
/
INSERT INTO LOCAZIONI_TIPI_TRACCIATO ( TIPO_TRACCIATO, DATA_INIZIO, DATA_FINE, TITOLO_DOCUMENTO) SELECT 2,to_date('01/08/2011','dd/mm/yyyy'),to_date('31/05/2012','dd/mm/yyyy'),28 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM LOCAZIONI_TIPI_TRACCIATO WHERE TIPO_TRACCIATO=2)
/
DECLARE
   dep_clob Clob := empty_clob();
   dep_stringa1 varchar2(32767);
BEGIN
   dbms_lob.createTemporary(dep_clob,TRUE,dbms_lob.session);
   dep_stringa1 := '{
    "0": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "vuoto": {
            "da": 151,
            "a": 200
        }
    },
    "1": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione01": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "intestazione02": {
            "da": 151,
            "a": 156
        },
        "numeroRecord": {
            "da": 156,
            "a": 161
        },
        "vuoto": {
            "da": 161,
            "a": 200
        }
    },
    "A": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "dataReg": {
            "da": 16,
            "a": 26
        },
        "dataStipula": {
            "da": 26,
            "a": 36
        },
        "codiceOggetto": {
            "da": 36,
            "a": 38
        },
        "importoCanone": {
            "da": 38,
            "a": 53
        },
        "valutaCanone": {
            "da": 53,
            "a": 54
        },
        "tipoCanone": {
            "da": 54,
            "a": 55
        },
        "dataInizio": {
            "da": 55,
            "a": 65
        },
        "dataFine": {
            "da": 65,
            "a": 75
        },
        "vuoto": {
            "da": 75,
            "a": 200
        }
    },
    "I": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "prgImmobile": {
            "da": 16,
            "a": 19
        },
        "immAccatastamento": {
            "da": 19,
            "a": 20
        },
        "tipoCatasto": {
            "da": 20,
            "a": 21
        },
        "flagIP": {
            "da": 21,
            "a": 22
        },
        "codCatastale": {
            "da": 22,
            "a": 26
        },
        "sezUrbComCat": {
            "da": 26,
            "a": 29
        },
        "foglio": {
            "da": 29,
            "a": 33
        },
        "particellaNum": {
            "da": 33,
            "a": 38
        },
        "particellaDen": {
            "da": 38,
            "a": 42
        },
        "subalterno": {
            "da": 42,
            "a": 46
        },
        "indirizzo": {
            "da": 46,
            "a": 86
        },
        "vuoto": {
            "da": 86,
            "a": 200
        }
    },
    "B": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "prgSoggetto": {
            "da": 16,
            "a": 19
        },
        "tipoSoggetto": {
            "da": 19,
            "a": 20
        },
        "codFiscale": {
            "da": 20,
            "a": 36
        },
        "sesso": {
            "da": 36,
            "a": 37
        },
        "cittaNasc": {
            "da": 37,
            "a": 67
        },
        "provNasc": {
            "da": 67,
            "a": 69
        },
        "dataNasc": {
            "da": 69,
            "a": 79
        },
        "cittaRes": {
            "da": 79,
            "a": 109
        },
        "provRes": {
            "da": 109,
            "a": 111
        },
        "indirizzoRes": {
            "da": 111,
            "a": 146
        },
        "numCivRes": {
            "da": 146,
            "a": 152
        },
        "dataSubentro": {
            "da": 152,
            "a": 162
        },
        "dataCessione": {
            "da": 162,
            "a": 172
        },
        "vuoto": {
            "da": 172,
            "a": 200
        }
    }
}';
   dbms_lob.writeappend(dep_clob,length(dep_stringa1),dep_stringa1);
   update LOCAZIONI_TIPI_TRACCIATO set tracciato = dep_clob where TIPO_TRACCIATO=2;
END;
/
INSERT INTO LOCAZIONI_TIPI_TRACCIATO ( TIPO_TRACCIATO, DATA_INIZIO, DATA_FINE, TITOLO_DOCUMENTO) SELECT 3,to_date('01/06/2012','dd/mm/yyyy'),to_date('31/12/9999','dd/mm/yyyy'),28 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM LOCAZIONI_TIPI_TRACCIATO WHERE TIPO_TRACCIATO=3)
/
DECLARE
   dep_clob Clob := empty_clob();
   dep_stringa1 varchar2(32767);
BEGIN
   dbms_lob.createTemporary(dep_clob,TRUE,dbms_lob.session);
   dep_stringa1 := '{
    "0": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "vuoto": {
            "da": 151,
            "a": 200
        }
    },
    "1": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "intestazione01": {
            "da": 1,
            "a": 141
        },
        "dataFile": {
            "da": 141,
            "a": 151
        },
        "intestazione02": {
            "da": 151,
            "a": 156
        },
        "numeroRecord": {
            "da": 156,
            "a": 161
        },
        "vuoto": {
            "da": 161,
            "a": 200
        }
    },
    "A": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "sottoNumeroReg": {
            "da": 16,
            "a": 19
        },
        "prgNegozio": {
            "da": 19,
            "a": 22
        },
        "dataReg": {
            "da": 22,
            "a": 32
        },
        "dataStipula": {
            "da": 32,
            "a": 42
        },
        "codiceOggetto": {
            "da": 42,
            "a": 44
        },
        "codNegozio": {
            "da": 44,
            "a": 48
        },
        "importoCanone": {
            "da": 48,
            "a": 63
        },
        "valutaCanone": {
            "da": 63,
            "a": 64
        },
        "tipoCanone": {
            "da": 64,
            "a": 65
        },
        "dataInizio": {
            "da": 65,
            "a": 75
        },
        "dataFine": {
            "da": 75,
            "a": 85
        },
        "vuoto": {
            "da": 85,
            "a": 200
        }
    },
    "I": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "sottoNumeroReg": {
            "da": 16,
            "a": 19
        },
        "prgNegozio": {
            "da": 19,
            "a": 22
        },
        "prgImmobile": {
            "da": 22,
            "a": 25
        },
        "immAccatastamento": {
            "da": 25,
            "a": 26
        },
        "tipoCatasto": {
            "da": 26,
            "a": 27
        },
        "flagIP": {
            "da": 27,
            "a": 28
        },
        "codCatastale": {
            "da": 28,
            "a": 32
        },
        "sezUrbComCat": {
            "da": 32,
            "a": 35
        },
        "foglio": {
            "da": 35,
            "a": 39
        },
        "particellaNum": {
            "da": 39,
            "a": 44
        },
        "particellaDen": {
            "da": 44,
            "a": 48
        },
        "subalterno": {
            "da": 48,
            "a": 52
        },
        "indirizzo": {
            "da": 52,
            "a": 92
        },
        "vuoto": {
            "da": 92,
            "a": 200
        }
    },
    "B": {
        "tipoRecord": {
            "da": 0,
            "a": 1
        },
        "ufficio": {
            "da": 1,
            "a": 4
        },
        "annoReg": {
            "da": 4,
            "a": 8
        },
        "serieReg": {
            "da": 8,
            "a": 10
        },
        "numeroReg": {
            "da": 10,
            "a": 16
        },
        "sottoNumeroReg": {
            "da": 16,
            "a": 19
        },
        "prgNegozio": {
            "da": 19,
            "a": 22
        },
        "prgSoggetto": {
            "da": 22,
            "a": 25
        },
        "tipoSoggetto": {
            "da": 25,
            "a": 26
        },
        "codFiscale": {
            "da": 26,
            "a": 42
        },
        "sesso": {
            "da": 42,
            "a": 43
        },
        "cittaNasc": {
            "da": 43,
            "a": 73
        },
        "provNasc": {
            "da": 73,
            "a": 75
        },
        "dataNasc": {
            "da": 75,
            "a": 85
        },
        "cittaRes": {
            "da": 85,
            "a": 115
        },
        "provRes": {
            "da": 115,
            "a": 117
        },
        "indirizzoRes": {
            "da": 117,
            "a": 152
        },
        "numCivRes": {
            "da": 152,
            "a": 158
        },
        "dataSubentro": {
            "da": 158,
            "a": 168
        },
        "dataCessione": {
            "da": 168,
            "a": 178
        },
        "vuoto": {
            "da": 178,
            "a": 200
        }
    }
}';
   dbms_lob.writeappend(dep_clob,length(dep_stringa1),dep_stringa1);
   update LOCAZIONI_TIPI_TRACCIATO set tracciato = dep_clob where TIPO_TRACCIATO=3;
END;
/
INSERT INTO LOCAZIONI_TIPI_TRACCIATO ( TIPO_TRACCIATO, DATA_INIZIO, DATA_FINE, TITOLO_DOCUMENTO) SELECT 4,to_date('01/01/1900','dd/mm/yyyy'),to_date('31/12/9999','dd/mm/yyyy'),30 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM LOCAZIONI_TIPI_TRACCIATO WHERE TIPO_TRACCIATO=4)
/
DECLARE
   dep_clob Clob := empty_clob();
   dep_stringa1 varchar2(32767);
BEGIN
   dbms_lob.createTemporary(dep_clob,TRUE,dbms_lob.session);
   dep_stringa1 := '{
   "0":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "intestazione":{
         "da":1,
         "a":80
      },
      "dataFile":{
         "da":80,
         "a":90
      },
      "vuoto":{
         "da":90,
         "a":100
      }
   },
   "1":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "intestazione01":{
         "da":1,
         "a":80
      },
      "dataFile":{
         "da":80,
         "a":90
      },
      "intestazione02":{
         "da":90,
         "a":95
      },
      "numeroRecord":{
         "da":95,
         "a":100
      }
   },
   "A":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "ufficio":{
         "da":1,
         "a":4
      },
      "annoReg":{
         "da":4,
         "a":8
      },
      "serieReg":{
         "da":8,
         "a":10
      },
      "numeroReg":{
         "da":10,
         "a":16
      },
      "sottoNumeroReg":{
         "da":16,
         "a":19
      },
      "prgNegozio":{
         "da":19,
         "a":22
      },
      "dataReg":{
         "da":22,
         "a":32
      },
      "dataStipula":{
         "da":32,
         "a":42
      },
      "codNegozio":{
         "da":42,
         "a":46
      },
      "importoCanone":{
         "da":46,
         "a":61
      },
      "valutaCanone":{
         "da":61,
         "a":62
      },
      "vuoto":{
         "da":62,
         "a":100
      }
   },
   "B":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "ufficio":{
         "da":1,
         "a":4
      },
      "annoReg":{
         "da":4,
         "a":8
      },
      "serieReg":{
         "da":8,
         "a":10
      },
      "numeroReg":{
         "da":10,
         "a":16
      },
      "sottoNumeroReg":{
         "da":16,
         "a":19
      },
      "prgNegozio":{
         "da":19,
         "a":22
      },
      "prgSoggetto":{
         "da":22,
         "a":25
      },
      "tipoSoggetto":{
         "da":25,
         "a":26
      },
      "codFiscale":{
         "da":26,
         "a":42
      },
      "dataSubentro":{
         "da":42,
         "a":52
      },
      "dataCessione":{
         "da":52,
         "a":62
      },
      "vuoto":{
         "da":62,
         "a":100
      }
   }
}';
   dbms_lob.writeappend(dep_clob,length(dep_stringa1),dep_stringa1);
   update LOCAZIONI_TIPI_TRACCIATO set tracciato = dep_clob where TIPO_TRACCIATO=4;
END;
/
INSERT INTO LOCAZIONI_TIPI_TRACCIATO ( TIPO_TRACCIATO, DATA_INIZIO, DATA_FINE, TITOLO_DOCUMENTO) SELECT 5,to_date('01/01/1900','dd/mm/yyyy'),to_date('31/12/9999','dd/mm/yyyy'),31 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM LOCAZIONI_TIPI_TRACCIATO WHERE TIPO_TRACCIATO=5)
/
DECLARE
   dep_clob Clob := empty_clob();
   dep_stringa1 varchar2(32767);
BEGIN
   dbms_lob.createTemporary(dep_clob,TRUE,dbms_lob.session);
   dep_stringa1 := '{
   "0":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "intestazione":{
         "da":1,
         "a":80
      },
      "dataFile":{
         "da":80,
         "a":90
      },
      "vuoto":{
         "da":90,
         "a":100
      }
   },
   "1":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "intestazione01":{
         "da":1,
         "a":80
      },
      "dataFile":{
         "da":80,
         "a":90
      },
      "intestazione02":{
         "da":90,
         "a":95
      },
      "numeroRecord":{
         "da":95,
         "a":100
      }
   },
   "A":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "ufficio":{
         "da":1,
         "a":4
      },
      "annoReg":{
         "da":4,
         "a":8
      },
      "serieReg":{
         "da":8,
         "a":10
      },
      "numeroReg":{
         "da":10,
         "a":16
      },
      "sottoNumeroReg":{
         "da":16,
         "a":19
      },
      "prgNegozio":{
         "da":19,
         "a":22
      },
      "dataReg":{
         "da":22,
         "a":32
      },
      "dataStipula":{
         "da":32,
         "a":42
      },
      "codNegozio":{
         "da":42,
         "a":46
      },
      "importoCanone":{
         "da":46,
         "a":61
      },
      "valutaCanone":{
         "da":61,
         "a":62
      },
      "vuoto":{
         "da":62,
         "a":100
      }
   },
   "B":{
      "tipoRecord":{
         "da":0,
         "a":1
      },
      "ufficio":{
         "da":1,
         "a":4
      },
      "annoReg":{
         "da":4,
         "a":8
      },
      "serieReg":{
         "da":8,
         "a":10
      },
      "numeroReg":{
         "da":10,
         "a":16
      },
      "sottoNumeroReg":{
         "da":16,
         "a":19
      },
      "prgNegozio":{
         "da":19,
         "a":22
      },
      "prgSoggetto":{
         "da":22,
         "a":25
      },
      "tipoSoggetto":{
         "da":25,
         "a":26
      },
      "codFiscale":{
         "da":26,
         "a":42
      },
      "dataSubentro":{
         "da":42,
         "a":52
      },
      "dataCessione":{
         "da":52,
         "a":62
      },
      "vuoto":{
         "da":62,
         "a":100
      }
   }
}';
   dbms_lob.writeappend(dep_clob,length(dep_stringa1),dep_stringa1);
   update LOCAZIONI_TIPI_TRACCIATO set tracciato = dep_clob where TIPO_TRACCIATO=5;
END;
/

ALTER TABLE LOCAZIONI_TIPI_TRACCIATO ENABLE ALL TRIGGERS
/

ALTER TABLE locazioni_tipi_tracciato MODIFY(tracciato  DEFAULT NULL)
/
