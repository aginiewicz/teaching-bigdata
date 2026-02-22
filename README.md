# HDFS na zajęcia: Algorytmy Big-Data (zima 2025/26)

Po sklonowaniu repozytorium przejdź do katalogu z plikiem `compose.yaml` i wykonaj komendę

```bash
podman compose up -d
```

Po jej zakończeniu uruchom Podman Desktop, w zakładce "pods" powinien być widoczny
działający pod o nazwie `pod_hdfs`. Wejdź na stronę http://localhost:9870/ i upewnij się
że wszystko działa, w zakładce "Overview" powinniśmy widzieć "active", jak i w zakładce
"Datanodes" powinno być "In service" (zielone odhaczenie) w tabelce z listą węzłów.
