import sqlite3
conn = sqlite3.connect('backend/sql_app.db')
c = conn.cursor()
c.execute('SELECT name FROM sqlite_master WHERE type=\"table\";')
print('Tables:', c.fetchall())
c.execute('SELECT COUNT(*) FROM intel_articles;')
print('Articles:', c.fetchall())
