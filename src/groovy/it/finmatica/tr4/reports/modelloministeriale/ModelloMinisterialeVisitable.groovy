package it.finmatica.tr4.reports.modelloministeriale

interface ModelloMinisterialeVisitable {
    def accept(ModelloMinisterialeVisitor visitor)
}
