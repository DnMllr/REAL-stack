window.App = Ember.Application.create()

do
  <- App.Router.map

App.IndexRoute = Ember.Route.extend do
  model: -> <[ red yellow blue ]>