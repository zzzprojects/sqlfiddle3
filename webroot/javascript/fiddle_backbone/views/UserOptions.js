define ([
    "jquery",
    "Backbone",
    "Handlebars",
    "md5",
    "utils/openidconnect",
    "text!fiddle_backbone/templates/loginButton.html",
    "text!fiddle_backbone/templates/authenticatedUserOptions.html"
],
function ($,Backbone,Handlebars,md5,openidconnect,loginButtonTemplate,authenticatedUserOptionsTemplate) {

    var UserInfoView = Backbone.View.extend({
        initialize: function (options) {
            this.options = options;
            this.authCompiledTemplate = Handlebars.compile(authenticatedUserOptionsTemplate);
            this.loginButtonCompiledTemplate = Handlebars.compile(loginButtonTemplate);
        },
        events: {
            "click #logout": "logout",
            "click #myFiddles": "showMyFiddles"
        },
        renderAnonymous: function () {
            $(this.el).html(
                this.loginButtonCompiledTemplate()
            );

            this.options.oidc.fetch();

            return this;
        },
        renderAuthenticated: function (userDetails) {

            $(this.el).html(
                this.authCompiledTemplate({
                    gravatar: md5(decodeURIComponent(userDetails.email).toLowerCase()).toLowerCase(),
                    email: decodeURIComponent(userDetails.email)
                })
            );

            return this;
        },
        showMyFiddles: function (e) {
            e.preventDefault();
            this.options.myFiddleDialog.render(true);
        },
        logout: function (e) {
            e.preventDefault();
            this.options.myFiddleDialog.setAnonymous(true);
            openidconnect.removeTokens();
            this.renderAnonymous();
        }
    });

    return UserInfoView;

});
