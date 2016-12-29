define ([
        "jquery", "underscore", "Backbone", "Handlebars", 
        "utils/openidconnect", "text!../templates/login.html"
    ],
    function ($,_,Backbone,Handlebars,openidconnect,loginTemplate) {

    var LoginView = Backbone.View.extend({
        initialize: function (options) {
            this.options = options;
            this.compiledTemplate = Handlebars.compile(loginTemplate);
        },
        events: {
            "click input[type=image]": "redirectToIDP"
        },
        render: function () {
            $(this.el).html(
                this.compiledTemplate({
                    resolvers: this.collection.toJSON()
                })
            );
            return this;
        },
        redirectToIDP: function (e) {
            e.preventDefault();

            var resolver = this.collection.find(function (r) {
                return r.get('name') === $(e.target).val();
            });

            window.location.href = resolver.get('authorization_endpoint') +
                                    '?response_type=code&scope=openid%20profile%20email' +
                                    '&redirect_uri=' + openidconnect.getRedirectUri() +
                                    '&state=' + resolver.get('name') +
                                    '&client_id=' + resolver.get('client_id');

        }
    });

    return LoginView;

});
