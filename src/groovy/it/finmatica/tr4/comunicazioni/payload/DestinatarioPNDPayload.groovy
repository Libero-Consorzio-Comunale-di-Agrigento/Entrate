package it.finmatica.tr4.comunicazioni.payload


import grails.validation.Validateable
import it.finmatica.tr4.smartpnd.SmartPndService

@Validateable(nullable = true)
class DestinatarioPNDPayload extends DestinatarioPayload {
    String provincia

    static constraints = {
        cfiscPiva(nullable: false, blank: false)
        indirizzo(validator: { val, obj, errors ->
            if (!val) {
                return
            }
            def matcher = val =~ SmartPndService.INDIRIZZO_PND_NOT_ALLOWED_CHARS_MATCH_REGEX
            if (matcher.size() > 0) {
                def capturingGroup = matcher[0]
                def notAllowedCharacters = capturingGroup.collect({ it }).unique().join()
                errors.reject('not.allowed.characters',
                        ['indirizzo', obj.class.name, val, notAllowedCharacters] as Object[],
                        'La proprietà {0} contiene caratteri non consentiti {3}')
            }
        })
        cap(nullable: false, blank: false)
        provincia(nullable: false, blank: false, maxSize: 2, validator: { val, obj, errors ->
            if (!val) {
                return
            }
            def notCapitalChars = val.chars.findAll { singleChar ->
                if (!singleChar.isUpperCase()) {
                    return singleChar
                }
            }

            if (notCapitalChars.size() > 0) {
                def notAllowedCharacters = notCapitalChars.collect({ it }).join(', ')
                errors.reject('not.capital.characters',
                        ['provincia', obj.class.name, val, notAllowedCharacters] as Object[],
                        'La proprietà {0} contiene caratteri non maiuscoli [{3}]')
            }
        })
    }
}
