package it.finmatica.tr4.smartpnd

import grails.plugins.springsecurity.SpringSecurityService
import grails.rest.RestfulController
import org.apache.commons.logging.Log
import org.apache.commons.logging.LogFactory
import org.springframework.security.authentication.AnonymousAuthenticationToken
import org.springframework.security.authentication.AuthenticationDetailsSource
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.AuthenticationException
import org.springframework.security.core.codec.Base64
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource

import javax.servlet.http.HttpServletResponse

class AuthRestfulController extends RestfulController {
    private static Log logger = LogFactory.getLog(AuthRestfulController)

    def user

    SpringSecurityService springSecurityService
    AuthenticationManager authenticationManager

    private AuthenticationDetailsSource authenticationDetailsSource = new WebAuthenticationDetailsSource()
    private String credentialsCharset = "UTF-8"

    def beforeInterceptor = {
        authenticateViaBasicAuth()
        if (!springSecurityService.isLoggedIn()) {
            respond([status: 'KO', error: 'Unauthorized access!'], status: HttpServletResponse.SC_UNAUTHORIZED, formats: ['json'])
            return false
        }
        return true
    }

    private void authenticateViaBasicAuth() {
        String header = request.getHeader("Authorization")
        if (header != null && header.startsWith("Basic ")) {
            byte[] base64Token = header.substring(6).getBytes("UTF-8")
            String token = new String(Base64.decode(base64Token), this.credentialsCharset)
            String username = ""
            String password = ""
            int delim = token.indexOf(":")
            if (delim != -1) {
                username = token.substring(0, delim)
                password = token.substring(delim + 1)
            }

            logger.debug("Basic Authentication Authorization header found for user '${username}'")

            UsernamePasswordAuthenticationToken authRequest = new UsernamePasswordAuthenticationToken(username, password)
            authRequest.setDetails(this.authenticationDetailsSource.buildDetails(request))

            Authentication authResult
            try {
                authResult = this.authenticationManager.authenticate(authRequest)
            } catch (AuthenticationException var16) {
                logger.debug("Authentication request for user: " + username + " failed: " + var16.toString())
                SecurityContextHolder.getContext().setAuthentication((Authentication) null)
                return
            }

            logger.debug("Authentication success: " + authResult.toString())
            SecurityContextHolder.getContext().setAuthentication(authResult)

            user = username

        }
    }
}
