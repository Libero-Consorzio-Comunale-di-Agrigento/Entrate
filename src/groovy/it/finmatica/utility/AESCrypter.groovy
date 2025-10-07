package it.finmatica.utility

import javax.crypto.spec.SecretKeySpec;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.Cipher
 
// http://groovyconsole.appspot.com/script/5690449683546112

class AESCrypter {
 
	// Key must be exactly 16 bytes
	def expandKey (def secret) {
		
		if(secret == null || secret.trim().length() == 0) secret = "XYZ";
 
		while(secret.length() < 18)
			secret += secret
 
		return secret.substring(0, 16)
	}
 
	// Encrypts
	def encrypt (String plainText, String secret) {
 
		secret = expandKey(secret)
		
		def cipher = Cipher.getInstance("AES/CBC/PKCS5Padding", "SunJCE")
		SecretKeySpec key = new SecretKeySpec(secret.getBytes("UTF-8"), "AES")
		cipher.init(Cipher.ENCRYPT_MODE, key, new IvParameterSpec(secret.getBytes("UTF-8")))

		return cipher.doFinal(plainText.getBytes("UTF-8")).encodeHex().toString()
	}
 
	// Decrypts
	def decrypt (String cypherText, String secret) {
 
		byte[] decodedBytes = cypherText.decodeHex()
 
		secret = expandKey(secret)
		
		def cipher = Cipher.getInstance("AES/CBC/PKCS5Padding", "SunJCE")
		SecretKeySpec key = new SecretKeySpec(secret.getBytes("UTF-8"), "AES")
		cipher.init(Cipher.DECRYPT_MODE, key, new IvParameterSpec(secret.getBytes("UTF-8")))
 
		return new String(cipher.doFinal(decodedBytes), "UTF-8")
	}
}
