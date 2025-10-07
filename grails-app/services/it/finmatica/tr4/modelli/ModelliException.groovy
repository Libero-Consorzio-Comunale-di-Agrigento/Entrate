package it.finmatica.tr4.modelli

class ModelliException extends Exception {
    ModelliException(String message) {
        super(message)
    }

    ModelliException(String message, Throwable cause) {
        super(message, cause)
    }
}
