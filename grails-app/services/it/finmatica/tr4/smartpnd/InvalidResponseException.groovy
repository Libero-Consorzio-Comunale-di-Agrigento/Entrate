package it.finmatica.tr4.smartpnd

class InvalidResponseException extends RuntimeException {
    InvalidResponseException(String message) {
        super(message)
    }
}
