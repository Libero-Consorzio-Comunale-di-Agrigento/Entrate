--liquibase formatted sql
--changeset dmarotta:20250326_152438_copa_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE COMUNICAZIONE_PARAMETRI DISABLE ALL TRIGGERS;

Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('CUNI','ACA','Accertamento automatico',null,'S',null,'A','STAMPA_ACCERTAMENTI_TRMI.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "CANONI": {
        "enabled" : false,
]')
|| TO_CLOB(q'[        "label": "Canoni",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "IMPOSTA_EVASA": {
        "enabled" : false,
        "label": "Imposta evasa",
        "sign]')
|| TO_CLOB(q'[ature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "SANZIONI_INTERESSI": {
        "enabled" : false,
        "label": "Interessi sanzioni",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "AGGI_DILAZIONI": {
        "enabled" : false,
        "label": "Aggi/dilazioni",
        "signature": {
          "P]')
|| TO_CLOB(q'[RATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('CUNI','ACC','Accertamento',null,'S',null,'A','STAMPA_ACCERTAMENTI_TRMI.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "CANONI": {
        "enabled" : false,
]')
|| TO_CLOB(q'[        "label": "Canoni",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "IMPOSTA_EVASA": {
        "enabled" : false,
        "label": "Imposta evasa",
        "sign]')
|| TO_CLOB(q'[ature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "SANZIONI_INTERESSI": {
        "enabled" : false,
        "label": "Interessi sanzioni",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "AGGI_DILAZIONI": {
        "enabled" : false,
        "label": "Aggi/dilazioni",
        "signature": {
          "P]')
|| TO_CLOB(q'[RATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('CUNI','LCO','Comunicazione di pagamento',null,'S',null,'C','STAMPA_AVVISI_CUNI.CONTRIBUENTE',TO_CLOB(q'[{
  "CONTRIBUENTE": {
    "enabled" : true,
    "label": "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO": "num",
      "ANNO": "num",
      "PRATICA_BASE": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "LISTA_CANONI": {
        "enabled" : false,
        "label": "Lista canoni",
        "signature": {
          "RUOLO": "num",
          "COD_FISCALE": "str"]')
|| TO_CLOB(q'[,
          "MODELLO": "num",
          "TIPO_TRIBUTO": "str",
          "ANNO_IMPOSTA": "num",
          "PRATICA_CANONE": "num"
        },
        "output": {
          "*": "*"
        },
        "functions": {
          "ELENCO_CANONI": {
            "enabled" : false,
            "label": "Elenco canoni",
            "signature": {
              "RUOLO": "num",
              "COD_FISCALE": "str",
              "MODELLO": "num",
              "TIPO_TRIBUTO": "str",
              "A]')
|| TO_CLOB(q'[NNO_IMPOSTA": "num",
              "PRATICA_CANONE": "num",
              "OGGETTO_BASE": "num"
            },
            "output": {
              "*": "*"
            }
          },
          "DATI_CANONI": {
            "enabled" : false,
            "label": "Dati canoni",
            "signature": {
              "RUOLO": "num",
              "COD_FISCALE": "str",
              "MODELLO": "num",
              "TIPO_TRIBUTO": "str",
              "ANNO_IMPOSTA": "num",
            ]')
|| TO_CLOB(q'[  "PRATICA_CANONE": "num",
              "OGGETTO_BASE": "num"
            },
            "output": {
              "*": "*"
            }
          }
        }
      },
      "DATI_RATE": {
        "enabled" : false,
        "label": "Rate",
        "signature": {
          "RUOLO": "num",
          "COD_FISCALE": "str",
          "MODELLO": "num",
          "TIPO_TRIBUTO": "str",
          "ANNO_IMPOSTA": "num",
          "PRATICA_CANONE": "num"
        },
        "output": {
          "]')
|| TO_CLOB(q'[*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('CUNI','SOL','Sollecito',null,'S',null,'T','STAMPA_SOLLECITI_TRMI.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "PRATICA": "num",
      "MODELLO": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "CANONI": {
        "enabled" : false,
        "label": "Canoni",
        "sign]')
|| TO_CLOB(q'[ature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','ACC','Accertamento',null,'S',null,'A','STAMPA_ACCERTAMENTI_ICI.MAN_PRINCIPALE',TO_CLOB(q'[{
  "MAN_PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE":"num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "MAN_CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE":"num"
        },
        "output": {
          "*": "*"
        }
      },
      "MAN_]')
|| TO_CLOB(q'[IMMOBILI": {
        "enabled" : false,
        "label": "Immobili",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "TIPI_OGGETTO": "str",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "MAN_RIEP_VERS": {
        "enabled" : false,
        "label": "Riepilo versamenti",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
]')
|| TO_CLOB(q'[        }
      },
      "MAN_SANZ_INT": {
        "enabled" : false,
        "label": "Interessi sanzioni",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "MAN_VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
]')
|| TO_CLOB(q'[        }
      },
      "MAN_VERSAMENTI_VUOTO": {
        "enabled" : false,
        "label": "Versamenti vuoto",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "ANNO": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "MAN_AGGI_DILAZIONE": {
        "enabled" : false,
        "label": "Aggi/Dilazione",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
]')
|| TO_CLOB(q'[        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','ACT','Accertamento totale',null,'S',null,'A',null, EMPTY_CLOB());
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','DEN','Denuncia',null,null,null,'D','STAMPA_DENUNCE_IMU.CONTRIBUENTE','{
  "CONTRIBUENTE": {
    "enabled": true,
    "label": "Contribuente",
    "signature": {
      "PRATICA": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "FRONTESPIZIO": {
        "enabled": true,
        "label": "Frontespizio",
        "signature": {
          "COD_FISCALE": "string",
          "PRATICA": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','LCO','Comunicazione di pagamento',null,null,null,'C',' STAMPA_COM_IMPOSTA.CONTRIBUENTE','{
  "CONTRIBUENTE": {
    "enabled": true,
    "label": "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO": "num",
      "ANNO": "num"
    },
    "output": {
      "*": "*"
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','LGE','Lettera generica',null,'S',null,'G','STAMPA_COMMON.CONTRIBUENTI_ENTE','{
  "CONTRIBUENTI_ENTE": {
    "enabled" : true,
    "label" : "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO_PRATICA": "num"
    },
    "output": {
      "*": "*"
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('ICI','LIQ','Liquidazione',null,'S',null,'L','STAMPA_LIQUIDAZIONI_IMU.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label" : "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "str",
      "MODELLO": "num",
      "MODELLO_RIMB": "num",
      "NI_EREDE": "num"
    },
    "output": {
      "*" : "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label" : "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE": "num"
        },
        "output": {
          "*": "*"
    ]')
|| TO_CLOB(q'[    }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label" : "Versamenti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "ANNO": "num"
        },
        "output": {
          "*" : "*"
        }
      },
      "IMPORTI_RIEP": {
        "enabled" : false,
        "label" : "Riepilogo Importi",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "ANNO": "num",
          "DATA": "str"
     ]')
|| TO_CLOB(q'[   },
        "output": {
          "*" : "*"
        },
        "functions": {
          "IMPORTI_RIEP_DEIM_COMUNE": {
            "enabled" : false,
            "label" : "Ripeilogo Importi Comune",
            "signature": {
              "COD_FISCALE": "str",
              "PRATICA": "num",
              "ANNO": "num",
              "DATA": "str",
              "DEIM_TOT_COMUNE": "str",
              "DEIM_VERS_TOT_COMUNE": "str",
              "DEIM_DIFF_TOT_COMUNE": "str",
              "S]')
|| TO_CLOB(q'[T_COMUNE": "str"
            },
            "output": {
              "*" : "*"
            }
          },
          "IMPORTI_RIEP_DEIM_STATO": {
            "enabled" : false,
            "label" : "Ripeilogo Importi Stato",
            "signature": {
              "COD_FISCALE": "str",
              "PRATICA": "num",
              "ANNO": "num",
              "DATA": "str",
              "DEIM_TOT_STATO": "str",
              "DEIM_VERS_TOT_STATO": "str",
              "DEIM_DIFF_TOT_STATO": "]')
|| TO_CLOB(q'[str",
              "ST_STATO": "str"
            },
            "output": {
              "*" : "*"
            }
          }
        }
      },
      "SANZIONI": {
        "enabled" : false,
        "label" : "Sanzioni",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*" : "*"
        }
      },
      "INTERESSI": {
        "enabled" : false,
        "label" : "Interessi",
        "signature": {
          "PRATICA": "num"
        },
        "output":]')
|| TO_CLOB(q'[ {
          "*" : "*"
        }
      },
      "INTERESSI_G_APPLICATI": {
        "enabled" : false,
        "label" : "Interessi Giorni Applicati",
        "signature": {
          "TIPO_TRIBUTO": "str",
          "ANNO": "num",
          "DATA": "str"
        },
        "output": {
          "*" : "*"
        }
      },
      "RIEPILOGO_DOVUTO": {
        "enabled" : false,
        "label" : "Riepilogo Dovuti",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
 ]')
|| TO_CLOB(q'[         "*" : "*"
        }
      },
      "RIEPILOGO_DA_VERSARE": {
        "enabled" : false,
        "label" : "Riepilogo da Versare",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*" : "*"
        }
      },
      "IMMOBILI": {
        "enabled" : false,
        "label" : "Immobili",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num"
        },
        "output": {
          "*" : "*"
        },
        "functions":]')
|| TO_CLOB(q'[ {
          "RIOG": {
            "enabled" : false,
            "label" : "Riog???",
            "signature": {
              "PRATICA": "num",
              "ANNO": "num",
              "OGGETTO": "num"
            },
            "output": {
              "*" : "*"
            }
          },
          "IMPOSTA_RENDITA": {
            "enabled" : false,
            "label" : "Imposta Rendita",
            "signature": {
              "PRATICA": "num",
              "OGGETTO": "num"
           ]')
|| TO_CLOB(q'[ },
            "output": {
              "*" : "*"
            }
          }
        }
      },
      "AGGI_DILAZIONE": {
        "enabled" : false,
        "label" : "Aggi/Dilazione",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*" : "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','ACA','Accertamento automatico',null,'S','S','A','STAMPA_ACCERTAMENTI_TARSU.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE" : "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE" : "num"
        },
        "output": {
          "*": "*"
        }
      },
      "OGGETTI"]')
|| TO_CLOB(q'[: {
        "enabled" : false,
        "label": "Oggetti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "ANNO": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "MODELLO": "num",
          "TOT_IMPOSTA": "str",
          "TOT]')
|| TO_CLOB(q'[_MAGG_TARES": "str"
        },
        "output": {
          "*": "*"
        }
      },
      "ADDIZ_INT": {
        "enabled" : false,
        "label": "Interessi addizionali",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        },
        "functions": {
          "ACC_IMPOSTA": {
            "enabled" : false,
            "label": "Accertamento imposta",
            "signature": {
              "PRATICA": "num]')
|| TO_CLOB(q'[",
              "MODELLO": "num"
            },
            "output": {
              "*": "*"
            }
          },
          "SANZ_INT": {
            "enabled" : false,
            "label": "Sanzioni/Interessi",
            "signature": {
              "PRATICA": "num",
              "MODELLO": "num"
            },
            "output": {
              "*": "*"
            }
          }
        }
      },
      "AGGI_DILAZIONI": {
        "enabled" : false,
        "label": "Aggi/Dilazi]')
|| TO_CLOB(q'[one",
        "signature": {
          "PRATICA": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','ACC','Accertamento',null,'S',null,'A','STAMPA_ACCERTAMENTI_TARSU.MAN_PRINCIPALE','{
  "MAN_PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE":"num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE":"num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','ACT','Accertamento totale',null,'S',null,'A','STAMPA_ACCERTAMENTI_TARSU.MAN_PRINCIPALE','{
  "MAN_PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "num",
      "MODELLO": "num",
      "NI_EREDE":"num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num",
          "NI_EREDE":"num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','APA','Avviso di pagamento (comunicazione a ruolo)',null,'S',null,'S','STAMPA_AVVISI_TARI.CONTRIBUENTE',TO_CLOB(q'[{
  "CONTRIBUENTE": {
    "enabled" : true,
    "label": "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "DATI_RUOLO": {
        "enabled" : true,
        "label": "Ruolo",
        "signature": {
          "RUOLO": "num",
          "COD_FISCALE": "str",
          "MODELLO": "num"
        },
        "o]')
|| TO_CLOB(q'[utput": {
          "*": "*"
        }
      },
      "DATI_RATE": {
        "enabled" : false,
        "label": "Rate",
        "signature": {
          "RUOLO": "num",
          "COD_FISCALE": "str",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "DATI_UTENZE": {
        "enabled" : false,
        "label": "Utenze",
        "signature": {
          "RUOLO": "num",
          "COD_FISCALE": "str",
          "MODELLO": "num"
     ]')
|| TO_CLOB(q'[   },
        "output": {
          "*": "*"
        },
        "functions": {
          "DATI_FAMILIARI": {
          "enabled" : false,
            "label": "Familiari",
            "signature": {
              "OGGETTO_IMPOSTA": "num",
              "MODELLO": "num"
            },
            "output": {
              "*": "*"
            }
          },
          "DATI_NON_DOM": {
            "enabled" : false,
            "label": "Non domiciliati",
            "signature]')
|| TO_CLOB(q'[": {
              "OGGETTO_IMPOSTA": "num",
              "MODELLO": "num"
            },
            "output": {
              "*": "*"
            }
          }
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','DEN','Denuncia',null,null,null,'D','STAMPA_DENUNCE_TARI.DATI_DENUNCIA','{
  "DATI_DENUNCIA": {
    "enabled": true,
    "label": "Dati denuncia",
    "signature": {
      "COD_FISCALE": "string",
      "PRATICA": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled": true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','LSG','Sgravio',null,null,null,'SG','STAMPA_SGRAVI.CONTRIBUENTE','{
  "CONTRIBUENTE": {
    "enabled": true,
    "label": "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO": "num"
    },
    "output": {
      "*": "*"
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TARSU','SOL','Sollecito',null,'S',null,'T','STAMPA_ACCERTAMENTI_TARSU.PRINCIPALE',TO_CLOB(q'[{
  "PRINCIPALE": {
    "enabled" : true,
    "label": "Principale",
    "signature": {
      "COD_FISCALE": "str",
      "PRATICA": "num",
      "MODELLO": "num",
      "MODELLO_TEMP": "num"
    },
    "output": {
      "*": "*"
    },
    "functions": {
      "CONTRIBUENTE": {
        "enabled" : true,
        "label": "Contribuente",
        "signature": {
          "PRATICA": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "OGGETTI": {
        "enable]')
|| TO_CLOB(q'[d" : false,
        "label": "Oggetti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "ANNO": "num",
          "MODELLO": "num"
        },
        "output": {
          "*": "*"
        }
      },
      "VERSAMENTI": {
        "enabled" : false,
        "label": "Versamenti",
        "signature": {
          "COD_FISCALE": "str",
          "PRATICA": "num",
          "MODELLO": "num",
          "TOT_IMPOSTA": "str",
          "TOT_MAGG_T]')
|| TO_CLOB(q'[ARES": "str"
        },
        "output": {
          "*": "*"
        }
      }
    }
  }
}]'));
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TRASV','LGE','Lettera generica',null,null,null,'G','STAMPA_COMMON.CONTRIBUENTI_ENTE','{
  "CONTRIBUENTI_ENTE": {
    "enabled" : true,
    "label" : "Contribuente",
    "signature": {
      "A_NI": "num",
      "TIPO_TRIBUTO": "str",
      "COD_FISCALE": "str",
      "RUOLO": "num",
      "MODELLO_PRATICA": "num"
    },
    "output": {
      "*": "*"
    }
  }
}');
Insert into COMUNICAZIONE_PARAMETRI (TIPO_TRIBUTO,TIPO_COMUNICAZIONE,DESCRIZIONE,FLAG_FIRMA,FLAG_PROTOCOLLO,FLAG_PEC,TIPO_DOCUMENTO,PKG_VARIABILI,VARIABILI_CLOB) values ('TRASV','RAI','Rateazione Accoglimento Istanza ',null,'S',null,'I',null, EMPTY_CLOB());

ALTER TABLE COMUNICAZIONE_PARAMETRI DISABLE ALL TRIGGERS;
