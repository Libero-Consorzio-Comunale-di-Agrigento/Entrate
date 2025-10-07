--liquibase formatted sql
--changeset dmarotta:20250326_152438_GSDTr4_s stripComments:false context:"TRG2 or TRV2"
--validCheckSum: 1:any

create synonym dati_generali    	for ${targetUsername}.dati_generali;
create synonym soggetti			    for ${targetUsername}.soggetti;
create synonym archivio_vie		    for ${targetUsername}.archivio_vie;
create synonym denominazioni_via    for ${targetUsername}.denominazioni_via;
create synonym contribuenti   	    for ${targetUsername}.contribuenti;
create synonym oggetti		   	    for ${targetUsername}.oggetti;

