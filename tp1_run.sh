#!/bin/bash
# TP1 HDFS - execute toutes les activites et enregistre les sorties
# A lancer DANS le conteneur namenode

OUT=/tmp/tp1_sorties.txt
exec > >(tee $OUT) 2>&1

sep() { echo ""; echo "=============================================================="; echo ">>> $1"; echo "=============================================================="; }

sep "VERSION HADOOP"
hadoop version

sep "ACTIVITE 1 : etat du cluster"
hdfs dfsadmin -report

sep "ACTIVITE 2 : arborescence"
hdfs dfs -mkdir -p /atelier/input /atelier/output /atelier/archive /atelier/logs
hdfs dfs -mkdir -p /datalake/ventes/raw /datalake/ventes/processed /datalake/ventes/archive
echo "--- hdfs dfs -ls / ---"
hdfs dfs -ls /
echo "--- hdfs dfs -ls /atelier ---"
hdfs dfs -ls /atelier
echo "--- hdfs dfs -ls -R /datalake ---"
hdfs dfs -ls -R /datalake

sep "ACTIVITE 3 : fichiers CSV locaux"
mkdir -p /tmp/datasets
cat > /tmp/datasets/ventes_janvier.csv << 'EOF'
id_vente,date_vente,client,ville,categorie,produit,quantite,prix_unitaire,montant
1,2026-01-03,Ahmed,Casablanca,Informatique,Ordinateur,1,8500,8500
2,2026-01-05,Fatima,Rabat,Bureautique,Imprimante,1,2300,2300
3,2026-01-09,Youssef,Fes,Accessoire,Clavier,2,175,350
4,2026-01-15,Sara,Marrakech,Accessoire,Souris,3,60,180
5,2026-01-21,Omar,Casablanca,Informatique,Ecran,1,2200,2200
EOF
cat > /tmp/datasets/ventes_fevrier.csv << 'EOF'
id_vente,date_vente,client,ville,categorie,produit,quantite,prix_unitaire,montant
6,2026-02-02,Nadia,Tanger,Informatique,Ordinateur,1,7900,7900
7,2026-02-06,Hamza,Rabat,Bureautique,Scanner,1,1600,1600
8,2026-02-11,Imane,Agadir,Mobile,Tablette,1,3200,3200
9,2026-02-17,Karim,Casablanca,Mobile,Smartphone,1,4500,4500
10,2026-02-23,Hajar,Fes,Informatique,DisqueSSD,2,700,1400
EOF
cat > /tmp/datasets/ventes_mars.csv << 'EOF'
id_vente,date_vente,client,ville,categorie,produit,quantite,prix_unitaire,montant
11,2026-03-04,Ali,Casablanca,Informatique,PCPortable,1,9200,9200
12,2026-03-08,Mouna,Rabat,Accessoire,Casque,2,350,700
13,2026-03-13,Rachid,Tanger,Mobile,Smartphone,1,5100,5100
14,2026-03-19,Salma,Marrakech,Bureautique,Photocopieur,1,12000,12000
15,2026-03-25,Mehdi,Agadir,Accessoire,Souris,5,80,400
EOF
ls -lh /tmp/datasets
echo "--- contenu ventes_janvier.csv ---"
cat /tmp/datasets/ventes_janvier.csv

sep "ACTIVITE 4 : envoi vers HDFS"
hdfs dfs -put -f /tmp/datasets/ventes_janvier.csv /datalake/ventes/raw/
hdfs dfs -put -f /tmp/datasets/ventes_fevrier.csv /datalake/ventes/raw/
hdfs dfs -put -f /tmp/datasets/ventes_mars.csv /datalake/ventes/raw/
echo "--- hdfs dfs -ls /datalake/ventes/raw ---"
hdfs dfs -ls /datalake/ventes/raw
echo "--- hdfs dfs -cat ventes_janvier.csv ---"
hdfs dfs -cat /datalake/ventes/raw/ventes_janvier.csv
echo "--- hdfs dfs -head ventes_janvier.csv ---"
hdfs dfs -head /datalake/ventes/raw/ventes_janvier.csv

sep "ACTIVITE 5 : copier, deplacer, supprimer"
hdfs dfs -cp -f /datalake/ventes/raw/*.csv /datalake/ventes/archive/
echo "--- ls /datalake/ventes/archive ---"
hdfs dfs -ls /datalake/ventes/archive
echo "fichier temporaire" > /tmp/test.txt
hdfs dfs -put -f /tmp/test.txt /atelier/input/
hdfs dfs -mv /atelier/input/test.txt /atelier/archive/
echo "--- ls /atelier/input (doit etre vide) ---"
hdfs dfs -ls /atelier/input
echo "--- ls /atelier/archive ---"
hdfs dfs -ls /atelier/archive
hdfs dfs -rm /atelier/archive/test.txt
echo "--- ls /atelier/archive apres suppression ---"
hdfs dfs -ls /atelier/archive

sep "ACTIVITE 6 : telechargement vers le local"
mkdir -p /tmp/export
hdfs dfs -get -f /datalake/ventes/raw/ventes_janvier.csv /tmp/export/
ls -lh /tmp/export
cat /tmp/export/ventes_janvier.csv

sep "ACTIVITE 7 : taille des fichiers"
echo "--- hdfs dfs -du -h ---"
hdfs dfs -du -h /datalake/ventes/raw
echo "--- hdfs dfs -count ---"
hdfs dfs -count /datalake/ventes/raw
echo "--- hdfs dfs -ls -R /datalake/ventes ---"
hdfs dfs -ls -R /datalake/ventes

sep "ACTIVITE 8 : blocs HDFS"
echo "--- fsck sur ventes_janvier.csv ---"
hdfs fsck /datalake/ventes/raw/ventes_janvier.csv -files -blocks -locations
echo "--- fsck sur toute la zone raw ---"
hdfs fsck /datalake/ventes/raw -files -blocks -locations

sep "ACTIVITE 9 : facteur de replication"
echo "--- passage a replication 2 ---"
hdfs dfs -setrep -w 2 /datalake/ventes/raw/ventes_janvier.csv
hdfs fsck /datalake/ventes/raw/ventes_janvier.csv -files -blocks -locations
echo "--- retour a replication 3 ---"
hdfs dfs -setrep -w 3 /datalake/ventes/raw/ventes_janvier.csv
hdfs dfs -setrep -w 3 /datalake/ventes/raw/ventes_fevrier.csv
hdfs dfs -setrep -w 3 /datalake/ventes/raw/ventes_mars.csv
hdfs fsck /datalake/ventes/raw -files -blocks -locations

sep "EXERCICE DE SYNTHESE"
hdfs dfs -mkdir -p /exercice/raw /exercice/archive /exercice/export
cat > /tmp/clients.csv << 'EOF'
id_client,nom,ville,pays
1,Ahmed,Casablanca,Maroc
2,Fatima,Rabat,Maroc
3,Youssef,Fes,Maroc
4,Sara,Marrakech,Maroc
EOF
hdfs dfs -put -f /tmp/clients.csv /exercice/raw/
echo "--- lecture depuis HDFS ---"
hdfs dfs -cat /exercice/raw/clients.csv
hdfs dfs -cp -f /exercice/raw/clients.csv /exercice/archive/
mkdir -p /tmp/export_exercice
hdfs dfs -get -f /exercice/raw/clients.csv /tmp/export_exercice/
echo "--- fichier telecharge en local ---"
ls -lh /tmp/export_exercice
echo "--- LIVRABLE : hdfs dfs -ls -R /exercice ---"
hdfs dfs -ls -R /exercice
echo "--- hdfs dfs -du -h /exercice/raw ---"
hdfs dfs -du -h /exercice/raw
hdfs dfs -setrep -w 3 /exercice/raw/clients.csv
echo "--- LIVRABLE : fsck clients.csv ---"
hdfs fsck /exercice/raw/clients.csv -files -blocks -locations

sep "FIN - sorties enregistrees dans $OUT"
