module serverino_db_session;

import serverino;

import serverino_db_session.models;

class DbSession
{
    import std.string;

    string id;
    AuthenticityToken authenticityToken;
    Request request;
    Output output;
    
    this(Request request, Output output, bool existing = false)
    {
        this.request = request;
        this.output = output;

        // Get Session ID from cookie
        id = request.cookie.read("sid", "");
        if (id.empty && !existing)
        {
            id = newRandom;
            output.setCookie(Cookie("sid", id).sameSite(Cookie.SameSite.Strict).httpOnly);
        }

        if (!id.empty)
            Session.create(id);

        authenticityToken = new AuthenticityToken(this);
    }

    static DbSession existing(Request request, Output output)
    {
        auto sess = new DbSession(request, output, true);
        return sess;
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
        id = "";
        output.setCookie(Cookie("sid", id).sameSite(Cookie.SameSite.Strict));
    }
}

private string newRandom(int len = 32)
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

    string newToken()
    {
        sessionToken = newRandom(86);
        session.set("authenticity_token", sessionToken);
        return sessionToken;
    }
}

void initializeServerinoSessionMigrations()
{
    import std.conv;
    import std.process;

    conn = new Connection(environment["DATABASE_URL"]);

    DbVersion.initialize; 
    auto currentVersion = DbVersion.get;

    foreach(idx; 0 .. MIGRATIONS.length.to!int)
    {
        // Already applied version
        if (idx + 1 <= currentVersion)
            continue;

        execute(MIGRATIONS[idx]);
        DbVersion.set(idx+1);
    }
}

