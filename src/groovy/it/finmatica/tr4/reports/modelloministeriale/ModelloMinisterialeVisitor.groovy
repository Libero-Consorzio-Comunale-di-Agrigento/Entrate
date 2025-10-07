package it.finmatica.tr4.reports.modelloministeriale

interface ModelloMinisterialeVisitor {
    def visit(ModelloMinisterialeIMUImmobile immobile)

    def visit(ModelloMinisterialeIMUContribuente contribuente)

    def visit(ModelloMinisterialeIMUDichiarante dichiarante)

    def visit(ModelloMinisterialeIMUContitolare contitolare)
}
