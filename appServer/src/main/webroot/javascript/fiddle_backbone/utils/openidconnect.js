/*global localStorage, JSON */
define(["underscore", "jquery", "fiddle_backbone/models/OpenIDMResource"], function (_, $, idm) {
    return {
        getCookies: function () {
            var cookies = document.cookie.split(";");

            return _.chain(cookies)
                    .map(function (c) {
                        return c.split("=");
                    })
                    .object()
                    .value();
        },
        getSessionJWT: function () {
            return this.getCookies()["session-jwt"];
        },
        getURLParams: function () {
            return _.chain( window.location.search.replace(/^\?/, '').split("&") )
                .map(function (arg) {
                    return arg.split("=");
                })
                .object()
                .value();
        },
        getCode: function () {
            return this.getURLParams().code;
        },
        getRedirectUri: function () {
            return  window.location.protocol + "//" + window.location.host +
                    window.location.pathname.replace(/(\/index\.html)|(\/$)/, '/oauth.html');
        },
        getMainUri: function () {
            return  window.location.protocol + "//" + window.location.host +
                    window.location.pathname.replace(/(\/oauth\.html)|(\/$)/, '/');
        },
        getToken: function () {
            var params = this.getURLParams();
            return idm.serviceCall({
                "type": "POST",
                "url": "/oidc?_action=getToken&code=" + params.code + "&name=" + params.state + "&redirect_uri=" + this.getRedirectUri()
            }).then(function (result) {
                localStorage.setItem("oidcToken", JSON.stringify(result));
                return result;
            });
        },
        getTokenClaims: function (token) {
            var components = token && token.split(".");
            if (!components || components.length !== 3) {
                return null;
            }

            return JSON.parse(atob(components[1]));
        },
        getLoggedUserDetails: function () {
            var sessionJwt = this.getSessionJWT(),
                token = localStorage.getItem("oidcToken"),
                claims,
                oidcJwt = {};

            if (token) {
                token = JSON.parse(token);
                oidcJwt[token.header] = token.token;
                claims = this.getTokenClaims(token.token);

                claims = _.transform(claims, function (result, val, key) {
                    result[key] = encodeURIComponent(val);
                });

                return idm.serviceCall({
                    "url": "/login",
                    // only pass the oidcToken when there is no session-jwt cookie available
                    "headers": (sessionJwt === undefined) ? oidcJwt : {}
                })
                .then(
                    function (details) {
                        if (details.authorization.id !== encodeURIComponent(claims.iss) + ":" + encodeURIComponent(claims.sub)) {
                            localStorage.removeItem("oidcToken");
                            return null;
                        }
                        return claims;
                    },
                    function () {
                        localStorage.removeItem("oidcToken");
                    }
                );
            } else {
                return $.Deferred().reject();
            }
        },
        removeTokens: function () {
            document.cookie = "session-jwt=;expires=" + (new Date(0)).toUTCString() + ";path=/;domain=;";
            localStorage.removeItem("oidcToken");
        }
    };
});
