requirejs.config({
    paths: {
        jquery: '../node_modules/jquery/dist/jquery',
        underscore: '../node_modules/lodash/index',
        utils: 'fiddle_backbone/utils'
    }
});

require(["jquery", "utils/openidconnect"], function ($, oidc) {
    oidc.getToken().always(function () {
        window.location.href = oidc.getMainUri();
    });
});
