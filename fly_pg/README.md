# Fly.io Postegres DB with pgvector and age

This is a docker image adding two postgres extensions:
- pgvector - similarity search
- age - graph query system using cypher

## Build and deploy
```bash
docker build . -t <DOCKER ACCOUNT>/pg-age-vec      
docker push <DOCKER ACCOUNT>/pg-age-vec:latest 
flyctl postgres create --image-ref <DOCKER ACCOUNT>/pg-age-vec:latest
```

## Activating the extensions

Enable the extension in the database (maybe using a migration system):
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS age;
```

And on every connection:
```sql
LOAD 'age';
SET search_path = ag_catalog, "$user", public;
```