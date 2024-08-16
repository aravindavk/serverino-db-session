# Session management for Serverino based web applications

Add `serverino-db-session` to your project by running,

```
dub add serverino-db-session
```

Start the session in the first endpoint.

```d
DbSession session;

@endpoint @priority(100)
void startSessionHandler(Request request, Output output)
{
    session = new DbSession(request, output);
    
}
```

Set or get values to session store as required (Convert any value to string and store it).

```d
@endpoint @priority(50)
void authHandler(Request request, Output output)
{
    auto sessionUserId = session.get("userId", "0").to!long;
    if (sessionUserId > 0)
        return;

    // ...
}

@endpoint @route!"/login"
void loginHandler(Request request, Output output)
{
    auto user = getUserFromRequestParams(request);
    if (!user.isNull)
    {
        session.set("userId", user.get.id.to!string);
    }
    // ...
}
```

## Authenticity Token or CSRF token

Session also provides the framework to generate and validate the CSRF token.

```d
@endpoint @route!"/signup"
void signupHandler(Request request, Output output)
{
    if (request.method == Request.Method.Get)
    {
        auto csrfToken = session.authenticityToken.token;
        render("signup.html", csrfToken);
        return;
    }
    auto token = parseParamFromRequest(request, "authenticity_token");
    enforceHttp(session.authenticityToken.isValid(token), "Invalid authenticity token");
    // ..
}
```

## Destroy the session

```d
@endpoint @route!"/logout"
void logoutHandler(Request request, Output output)
{
    session.destroy;
    output.addHeader("location", "/");
    output.status = 302;
}
```
