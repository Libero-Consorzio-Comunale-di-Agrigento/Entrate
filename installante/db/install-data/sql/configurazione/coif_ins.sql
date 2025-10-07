--liquibase formatted sql
--changeset dmarotta:20250326_152438_coif_ins stripComments:false
--validCheckSum: 1:any

ALTER TABLE coefficienti_contabili DISABLE ALL TRIGGERS;

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2023, 0.5600);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2022, 0.5600);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2007, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2008, 0.8000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2009, 0.8000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2010, 0.8000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2011, 1.0000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2012, 0.8000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2013, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2014, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2015, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2016, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2017, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2018, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2019, 0.6000);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2020, 0.5600);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2021, 0.5600);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2024, 0.5600);

insert into contributi_ifel (ANNO, ALIQUOTA)
values (2025, 0.5600);

ALTER TABLE coefficienti_contabili ENABLE ALL TRIGGERS;
