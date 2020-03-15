function(user, context, callback) {
  // TODO

	// NOTE the values to be interpolated into this template can be found here https://manage.auth0.com/dashboard/us/dev-iz7rs90r/applications/Dnte7NMlWZbkwId89rHhHT1FYb0w1if2/quickstart

  // (1) get a machine token
	var request = require("request");

	var options = { method: 'POST',
	  // TODO parametrize
	  url: 'https://dev-iz7rs90r.auth0.com/oauth/token',
	  headers: { 'content-type': 'application/json' },
	  body: '{"client_id":configuration.client_id,"client_secret":configuration.client_secret,"audience":configuration.audience,"grant_type":"client_credentials"}'
	};

	var a = request(options, function (error, response, body) {
		if (error) console.log("error");
	  // if (error) throw new Error(error);

	  console.log(body);
	});

	// gather OIDC properties

  if (user.email_verified) {
  	context.idToken[namespace + 'email'] = user.email;
  }
  if (user.phone_verified) {
  	context.idToken[namespace + 'phone'] = user.phone;
  }

	// send the OIDC profile to the 
	var request = require("request");

	var options = { method: 'POST',
	  url: 'http://users.services.ataper.net/',
	  headers: { authorization: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2Rldi1pejdyczkwci5hdXRoMC5jb20vIiwic3ViIjoiRG50ZTdOTWxXWmJrd0lkODlySGhIVDFGWWIwdzFpZjJAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vYXBpLWdhdGV3YXkuc2VydmljZXMuYXRhcGVyLm5ldC8iLCJpYXQiOjE1ODQyMjIzMTUsImV4cCI6MTU4NDMwODcxNSwiYXpwIjoiRG50ZTdOTWxXWmJrd0lkODlySGhIVDFGWWIwdzFpZjIiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.PmQABoy4YpzVHNpaLaRuLidLaOnzc7M1eqYgPwla-dw' },
	  body: { oidc_profile: user }
	};

	// request(options, function (error, response, body) {
	//   if (error) throw new Error(error);

	//   console.log(body);
	// });

	// (3)


  const namespace = 'https://ataper.net/';

  context.idToken[namespace + 'favorite_color'] = user.favorite_color;
  context.idToken[namespace + 'preferred_contact'] = user.user_metadata.preferred_contact;

  callback(null, user, context);
}
