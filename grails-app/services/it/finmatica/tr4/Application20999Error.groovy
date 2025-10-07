package it.finmatica.tr4

class Application20999Error extends Exception {

    def errorCode

    Application20999Error(String message, Integer errorCode = null) {
        super(message)
        this.errorCode = errorCode
    }


}
