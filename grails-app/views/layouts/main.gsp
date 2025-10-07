<!doctype html>
<!--[if lt IE 7 ]> <html lang="en" class="no-js ie6"> <![endif]-->
<!--[if IE 7 ]>    <html lang="en" class="no-js ie7"> <![endif]-->
<!--[if IE 8 ]>    <html lang="en" class="no-js ie8"> <![endif]-->
<!--[if IE 9 ]>    <html lang="en" class="no-js ie9"> <![endif]-->
<!--[if (gt IE 9)|!(IE)]><!--> <html lang="en" class="no-js"><!--<![endif]-->
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<%--		<title><g:layoutTitle default="Grails"/></title>--%>
		<title><g:layoutTitle default='${message(code: "titoloApplicazione")}' /></title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
<%--		<link rel="shortcut icon" href="${resource(dir: 'images', file: 'favicon.ico')}" type="image/x-icon">--%>
		<link rel="shortcut icon" href="${resource(dir: 'images', file: 'faviconBlu.ico')}" type="image/x-icon"/>
<%--		<link rel="apple-touch-icon" href="${resource(dir: 'images', file: 'apple-touch-icon.png')}">--%>
<%--		<link rel="apple-touch-icon" sizes="114x114" href="${resource(dir: 'images', file: 'apple-touch-icon-retina.png')}">--%>
		<link rel="stylesheet" href="${resource(dir: 'css', file: 'main.css')}" type="text/css">
		<link rel="stylesheet" href="${resource(dir: 'css', file: 'mobile.css')}" type="text/css">
		<g:layoutHead/>
		<r:layoutResources />
	</head>
	<body>
<%--		<div id="grailsLogo" role="banner"><a href="http://grails.org"><img src="${resource(dir: 'images', file: 'grails_logo.png')}" alt="Grails"/></a></div> --%>
	 	<div id="top">	
			<img class='logoApplicazione' src="${resource(dir: 'images', file: 'logoApplicazione.png')}" alt="Logo applicazione"/>
			<div class='titoloApplicazione'>
				<div><g:message code="titoloApplicazione" /></div>
				<div class='descrizioneApplicazione'><g:message code="descrizioneApplicazione" /></div>
			</div>
			<a href="http://www.ads.it"><img class='logoAzienda' src="${resource(dir: 'images', file: 'logoAzienda.png')}" alt="http://www.ads.it"/></a>
		</div> 	
		<g:layoutBody/>
<%--		<div class="footer" role="contentinfo"></div> --%>
		<div id="spinner" class="spinner" style="display:none;"><g:message code="spinner.alt" default="Loading&hellip;"/></div>
		<g:javascript library="application"/>
		<r:layoutResources />
	</body>
</html>