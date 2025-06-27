- project url: https://kqvjisvktfadoggphulj.supabase.co
- api key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtxdmppc3ZrdGZhZG9nZ3BodWxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3OTA5ODAsImV4cCI6MjA2NjM2Njk4MH0.vlBhIPqq0k1AB6wMzc00llmKSzmWKO2xUN9QdoOdStc

- password: U1eYPplMQa2ksaaM1YyT

´´´Javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://kqvjisvktfadoggphulj.supabase.co'
const supabaseKey = process.env.SUPABASE_KEY
const supabase = createClient(supabaseUrl, supabaseKey)
´´´


# Tipo de conexión:
- Conexión directa:
```
host:
db.kqvjisvktfadoggphulj.supabase.co

port:
5432

database:
postgres

user:
postgres

password:
U1eYPplMQa2ksaaM1YyT

```

- Conexión de agrupador de transacciones (Connection Pooling): 
```
host:
aws-0-us-east-2.pooler.supabase.com

port:
6543

database:
postgres

user:
postgres.kqvjisvktfadoggphulj

pool_mode:
transaction

password:
U1eYPplMQa2ksaaM1YyT

```

- Conexión de agrupador de sesiones (Session Pooling): 

```
host:
aws-0-us-east-2.pooler.supabase.com

port:
5432

database:
postgres

user:
postgres.kqvjisvktfadoggphulj

pool_mode:
session

password:
U1eYPplMQa2ksaaM1YyT

```



