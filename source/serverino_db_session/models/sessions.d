module serverino_db_session.models.sessions;

import serverino_db_session.models.helpers;
import serverino_db_session.models.session_data;

struct Session
{
    string id;

    static void create(string id)
    {
        auto query = q"[
           INSERT INTO sessions(id)
           VALUES($1)
           ON CONFLICT(id) DO UPDATE
               SET accessedAt = current_timestamp
           RETURNING *
        ]";
        execute(query, id);
    }

    static Nullable!Session get(string id)
    {
        Nullable!Session session;

        string query = q"[
            SELECT *
            FROM sessions
            WHERE id = $1
        ]";
        auto rs = execute(query, id);
        if (rs.length > 0)
            session = rs[0].deserializeTo!Session;

        return session;
    }

    static void delete__(string id)
    {
        string query = q"[
            DELETE
            FROM sessions
            WHERE id = $1
        ]";

        execute(query, id);
        
        SessionData.deleteAll(id);
    }

    static void delete_(string id)
    {
        transaction({
                delete__(id);
            });
    }
}

