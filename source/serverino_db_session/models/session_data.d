module serverino_db_session.models.session_data;

import serverino_db_session.models.helpers;

struct SessionData
{
    string sessionId;
    string key;
    string value;

    void create()
    {
        auto query = q"[
            INSERT INTO sessionData(sessionId, key, value)
            VALUES($1, $2, $3)
            ON CONFLICT(sessionId, key) DO UPDATE
            SET value = $4
            RETURNING *
        ]";

        auto rs = execute(query, sessionId, key, value, value);
    }

    static Nullable!SessionData get(string sessionId, string key)
    {
        Nullable!SessionData data;

        auto query = q"[
            SELECT *
            FROM sessionData
            WHERE sessionId = $1 AND
                  key = $2
        ]";
        auto rs = execute(query, sessionId, key);
        if (rs.length > 0)
            data = rs[0].deserializeTo!SessionData;

        return data;
    }

    static void delete_(string sessionId, string key)
    {
        auto query = q"[
            DELETE
            FROM sessionData
            WHERE sessionId = $1 AND key = $2
        ]";

        execute(query, sessionId, key);
    }

    static void deleteAll(string sessionId)
    {
        auto query = q"[
            DELETE
            FROM sessionData
            WHERE sessionId = $1
        ]";

        execute(query, sessionId);
    }
}

