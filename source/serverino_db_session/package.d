module serverino_db_session;

import serverino;

import serverino_db_session.models;

struct DbSession
{
    string id;
    AuthenticityToken authenticityToken;

    this(Request request, Output output)
    {
        // Get Session ID from cookie
        id = request.cookie.read("sid", "");
        if (id.empty)
        {
            id = newRandom;
            output.setCookie(Cookie("sid", id));
        }
        Session.create(id);
        authenticityToken = new AuthenticityToken(this);
    }

    string get(string key, string defaultValue)
    {
        auto value = SessionData.get(id, key);
        if (value.isNull)
            return defaultValue;

        return value.get.value;
    }

    void set(string key, string value)
    {
        SessionData(id, key, value).create;
    }

    void remove(string key)
    {
        SessionData.delete_(id, key);
    }

    void destroy()
    {
        Session.delete_(id);
    }
}

string newRandom(int len = 32)
{
    import std.file;
    import std.digest;
    import std.string;

    return (cast(ubyte[])read("/dev/urandom", len)).toHexString.toLower;
}

// CSRF protection
class AuthenticityToken
{
    string sessionToken;
    DbSession session;

    this(DbSession session)
    {
        this.session = session;
        sessionToken = session.get("authenticity_token", "");
    }

    bool isValid(string token)
    {
        return sessionToken == token;
    }

    string token()
    {
        sessionToken = newRandom(86);
        session.set("authenticity_token", sessionToken);
        return sessionToken;
    }
}

