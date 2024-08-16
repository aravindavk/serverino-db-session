module serverino_db_session.models.db_versions;

import serverino_db_session.models.helpers;

struct DbVersion
{
    int id;

    static void initialize()
    {
        string query = q"[
            CREATE TABLE IF NOT EXISTS serverino_db_session_schema_migration (
                id            INTEGER NOT NULL,
                createdAt     TIMESTAMP DEFAULT current_timestamp
            )
        ]";
        execute(query);
    }

    void create()
    {
        auto query = "INSERT INTO serverino_db_session_schema_migration(id) VALUES($1)";
        execute(query, id);
    }

    static int get()
    {
        auto query = "SELECT * FROM serverino_db_session_schema_migration";
        auto rs = execute(query);
        if (rs.length > 0)
            return rs[0]["id"].as!PGinteger;

        return 0;
    }

    void update()
    {
        auto query = "UPDATE serverino_db_session_schema_migration SET id = $1, createdAt = current_timestamp";
        execute(query, id);
    }

    static void set(int versionId)
    {
        auto currentVersion = DbVersion.get;
        auto ver = DbVersion(versionId);
        if (currentVersion == 0)
        {
            ver.create;
            return;
        }

        if (currentVersion == versionId)
            return;

        ver.update;
    }
}
