# OAuth 2 client in written in bash and netcat

This is a proof-of-concept OAuth 2 client written in bash and netcat.
It integrates with Google.

# Local setup

## Prerequisites

A modern version of netcat is required to run this.
The one preinstalled on Mac OS X is not good enough.

```
brew install netcat
```

## Run

```
./start.sh
```

Go to [http://localhost:8998](http://localhost:8998).

Sign in to Google and authorize the app to access your profile info.

# Client registration at Google

Go to https://console.developers.google.com, set up a new project.

 - Create OAuth credentials, and specify a redirect_uri.
 - Make sure you add a support email on for the consent screen.
 - Enable the Google+ API.

You can revoke the access you granted to the client here: https://security.google.com/settings/security/permissions
