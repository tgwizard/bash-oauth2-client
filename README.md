# OAuth 2 client in written in bash and netcat

This is a proof-of-concept OAuth 2 client written in bash and netcat.
It integrates with Valtech IDP, Valtech's identity provider.

# Local setup

## Prerequisites

```
brew install netcat
```

## Run

You need an active account at Valtech to run this as is. It should be easy to port
to other OAuth 2 providers.

Fetch the client secret for the Bash Test Client from https://stage-id-admin.valtech.com.

Run the server:

```
CLIENT_SECRET={insert client secret} ./start.sh
```

Go to http://localhost:8998.
