package messaggistica

class Messaggio implements Serializable {

    public static final TIPO = [EMAIL: 'E', APP_IO: 'AIO']

    def tipo
    def mittente
    def destinatario
    def copiaConoscenza
    def copiaConoscenzaNascosta
    def oggetto
    def testo
    def allegati = []
    def firma
}
