Unterstützte Tags und entsprechende `Dockerfile` Links
======================================================

 - [`4.3.6-1` (*4.3.6-1/Dockerfile*)](https://github.com/kurthuwig/docker-shopware/blob/4.3.6-1/Dockerfile)
 - [`4.3.4-1` (*4.3.4-1/Dockerfile*)](https://github.com/kurthuwig/docker-shopware/blob/4.3.4-1/Dockerfile)
 - [`4.3.2-1` (*4.3.2-1/Dockerfile*)](https://github.com/kurthuwig/docker-shopware/blob/4.3.2-1/Dockerfile)
 - [`latest` (*latest/Dockerfile*)](https://github.com/kurthuwig/docker-shopware/blob/master/Dockerfile)

Was ist Shopware?
=================

Shopware ist eine flexibel gestaltbare, leistungsfähige und skalierbare Softwarelösung, mit der Sie schnell und einfach einen Onlineshop für alle Anforderungen erstellen können.

Diese Anleitung beschreibt, wie Sie Shopware mit Docker starten.
Es empfiehlt sich, das Programm [docker-compose](http://docs.docker.com/compose/) zu installieren.
Wenn dieses Programm installiert ist, erstellen Sie die Datei `docker-compose.yml` und können dann die Container viel einfacher starten, als mit dem Docker-CLI.
Sollten Sie eine ältere Docker-Version verwenden, z.B. unter Ubuntu 14.04 LTS, dann verwenden Sie stattdessen [fig](http://www.fig.sh/index.html), der Vorgänger von `docker-compose`.
Die Bedienung ist identisch, Sie müssen lediglich in allen Beispielen den Text `docker-compose` durch `fig` ersetzen.
Dies gilt auch für den Dateinamen, sprich aus `docker-compose.yml` wird `fig.yml`.
Alle Befehle werden auch für die Docker-CLI beschrieben, falls Sie `docker-compose` nicht verwenden wollen.

Diese Anleitung beschreibt auch, wie sie einen passenden Datenbankserver für den Shop anlegen. Sollten Sie bereits einen haben, so überspringen Sie alles, was mit `shopwaredb` zu tun hat.

Die beschreibene Konfiguration legt alle persistenten Daten auf dem Docker-Host in dem Verzeichnis `/var/lib/docker/persistent-volumes/shopware/` ab.
Dieses sollte gesichert werden.

Installation
============

Vorbereitung für `docker-compose`
---------------------------------

Legen Sie ein Verzeichnis `shopware` auf Ihrem Docker Host an.
Erstellen Sie darin die Datei `docker-compose.yml` mit diesem Inhalt:

    shopwaredb:
      image: mysql:5.5
      
      environment:
       # hier bitte ein eigenes Passwort verwenden
       # Nach dem ersten Start bitte das Passwort entfernen, da es sonst als Umgebungsvariable für einen Angreifer zugreifbar wäre
       - MYSQL_ROOT_PASSWORD=bitte_aendern
       
      volumes:
       - /var/lib/docker/persistent-volumes/shopware/db:/var/lib/mysql

    dbclient:
      image: mysql:5.5
      links:
       - shopwaredb:mysql
      
      # hier bitte das gleiche Passwort, wie bei shopwaredb angeben
      command: sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -pbitte_aendern'

    shopware:
      image: kurthuwig/shopware:4.3.2-1
      
      environment:
       # hier bitte ein eigenes Passwort verwenden
       - PHPMYADMIN_PW=bitte_aendern
       
       # Vorgabewerte für den Datenbankzugriff
       # - DB_USER=shopware
       # - DB_PASSWORD=shopware
       # - DB_DATABASE=shopware
       # - DB_HOST=
       # - DB_PORT=3306
       
      volumes:
       - /var/lib/docker/persistent-volumes/shopware/shopware/var/www/html:/var/www/html
      links:
       - shopwaredb:db
      ports:
       - "80:80"

Bitte ändern Sie die `bitte_aendern` Passwörter.
Achten Sie darauf, bei `shopwaredb` und `dbclient` das gleiche Passwort zu verwenden.
Für `PHPMYADMIN_PW` sollten Sie ein anderes Passwort verwenden.
Entfernen Sie die Zeile mit `MYSQL_ROOT_PASSWORD` bei `shopwaredb` nach dem ersten Start, damit es einem Angreifer nicht als Umgebungsvariable zur Verfügung steht.

Datenbankserver anlegen und konfigurieren
-----------------------------------------

Sollten Sie einen bereits vorhandenen Datenbankserver verwenden, so müssen Sie die entsprechenden `DB_` Umgebungsvariablen einkommentieren und konfigurieren.
Diese Anleitung geht ab jetzt davon aus, dass Sie die Datenbank als dedizierten Docker-Container betreiben, womit beispielsweise die Anforderungen an die Passwörter geringer sind, da niemand sonst auf die Datenbank zugreifen kann.

Starten Sie den Datenbankserver mit

    docker-compose up -d shopwaredb

oder

    docker run \
      -d \
      --name shopware_shopwaredb_1 \
      -v /var/lib/docker/persistent-volumes/shopware/db:/var/lib/mysql \
      -e MYSQL_ROOT_PASSWORD=bitte_aendern \
      mysql:5.5

Verbinden Sie sich mit dem Datenbankserver mit

    docker-compose run --rm dbclient

oder (mit dem passenden Passwort)

    docker run \
      -it --rm \
      --link shopware_shopwaredb_1:db \
      mysql:5.5 \
      sh -c 'exec mysql -h"$DB_PORT_3306_TCP_ADDR" -P"$DB_PORT_3306_TCP_PORT" -uroot -pbitte_aendern'

Legen Sie eine Datenbank und einen Benutzer an:

    CREATE DATABASE shopware;
    GRANT ALL ON shopware.* TO 'shopware' IDENTIFIED BY 'shopware';
    exit

Der Text hinter `IDENTIFIED BY` ist das Passwort.
Sollten Sie ein anderes verwenden wollen, so müssen Sie beim Starten des Shopware-Containers die Umgebungsvariable `DB_PASSWORD` entsprechend setzen.

Shopware initialisieren
-----------------------

Beim ersten Start von Shopware muss die Datenbank initialisiert werden.
Leider werden hierbei vom Shopware-Installer die Zugangsdaten zur Datenbank nicht übernommen, so dass man sie von Hand eingeben muss.
Starten Sie den shopware Container mit

    docker-compose up -d shopware

oder

    docker run \
      -d \
      --name shopware_shopware_1 \
      -e PHPMYADMIN_PW=bitte_aendern \
      -v /var/lib/docker/persistent-volumes/shopware/shopware/var/www/html:/var/www/html \
      --link shopware_shopwaredb_1:db \
      -p 80:80 \
      kurthuwig/shopware:4.3.2-1

Öffnen Sie dann in einem Browser die URL [http://localhost/recovery/install/](http://localhost/recovery/install/).
Sollten Sie Docker nicht auf Ihrem Rechner betreiben, sondern auf einem anderen Server, so ersetzen Sie `localhost` durch den Namen oder die IP des Servers.
[Hier](http://wiki.shopware.com/Shopware-4-Installer_detail_874.html) finden Sie eine sehr gute Anleitung, wie der Installer zu bedienen ist:

1. Wählen Sie im ersten Schritt Ihre Sprache aus und klicken Sie auf "Weiter".
1. Scrollen Sie im zweiten Schritt ganz nach unten und klicken Sie auf "Weiter".
1. Geben Sie als *Datenbank Server* den Namen `db` an.
   Geben Sie als *Datenbank Benutzer*, *Datenbank Passwort* und *Datenbank Name* jeweils `shopware` ein und klicken Sie auf "Weiter"
1. Klicken Sie im nächsten Schritt auf "Starten" und sobald die beiden Läufe fertig sind, klicken Sie auf "Weiter".
1. Wählen Sie die gewünschte Lizenzart aus und klicken Sie auf "Weiter".
1. Passen Sie die Shopware Basis-Konfiguration nach Ihren Bedürfnissen an und klicken Sie auf "Weiter", um die Einrichtung abzuschließen.

phpMyAdmin
==========

Um die Datenbank mit phpMyAdmin zu verwalten, muss die Umgebungsvariable `PHPMYADMIN_PW` gesetzt sein.
Wenn sie nicht gesetzt ist, besteht keine Möglichkeit, sich an phpMyAdmin erfolgreich anzumelden.
phpMyAdmin ist unter der URL [http://localhost/phpmyadmin/](http://localhost/phpmyadmin/) erreichbar.
Sollten Sie Docker nicht auf Ihrem Rechner betreiben, sondern auf einem anderen Server, so ersetzen Sie `localhost` durch den Namen oder die IP des Servers.

Bei dem Zugriff auf phpmyadmin werden Sie zuerst von Ihrem Browser nach Zugangsdaten gefragt.
Der Benutzername ist `phpmyadmin` und das Passwort ist das aus der Umgebungsvariable `PHPMYADMIN_PW`.
Danach werden Sie nach den Zugangsdaten zur `shopware` Datenbank gefragt.
Geben Sie für beides `shopware` ein, es sei denn, Sie haben etwas anderes mit `DB_PASSWORD` gesetzt.

Kontakt
=======

Kurt Huwig (@GMail.com: kurthuwig)
