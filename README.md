# Spark na zajęcia: Algorytmy Big-Data

Po sklonowaniu repozytorium przejdź do katalogu z plikiem `compose.yaml` i wykonaj komendę

```bash
podman compose up -d
```

Po jej zakończeniu uruchom Podman Desktop, w zakładce "pods" powinien być widoczny
działający pod o nazwie `pod_spark`. Wejdź na stronę http://localhost:8787/ i 
zaloguj się podając użytkownika "root" i hasło "rstudio". Upewnij się
że wszystko działa łącząc się (i rozłączając) z serwerem Spark:

```R
library(sparklyr)
sc <- spark_connect("spark://spark-master:7077")
spark_disconnect(sc)
```

