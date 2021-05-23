#!/bin/bash

klant_gegevens() {
    #Klantgegevens
    read -p "Klantnaam: " KLANTNAAM
    read -p "Environment type [test/acceptatie/productie]: " OMGEVING

    #Webserver Instellingen
    read -p "Wilt u webservers [true/false] ?: " WEBSERVERS
    if [ $WEBSERVERS == "true" ]; then
        read -p "Hoeveel webservers?: " WEBSERVERS_AANTAL
        read -p "Hoeveel geheugen wilt u?: " WEBSERVERS_MEMORY
    else
        WEBSERVERS_AANTAL=0
        WEBSERVERS_MEMORY=0
    fi

    #Loadbalancer Instellingen
    if [ "$OMGEVING" == "acceptatie" ] || [ "$OMGEVING" == "productie" ]; then
        read -p "Wilt u loadbalancers [true/false] ?: " LOADBALANCERS
        if [ $LOADBALANCERS == "true" ]; then
            read -p "Hoeveel loadbalancers?: " LOADBALANCERS_AANTAL
            read -p "Hoeveel geheugen wilt u?: " LOADBALANCERS_MEMORY
            read -p "Op welke poort draait de loadbalancer?: " LOADBALANCERS_PORT
            read -p "Op welke poort draait de stats van de loadbalancer?: " LOADBALANCERS_STATS_PORT
        else
            LOADBALANCERS_AANTAL=0
            LOADBALANCERS_MEMORY=0
            LOADBALANCERS_PORT=80
            LOADBALANCERS_STATS_PORT=8080
        fi
    fi

    #Database Instellingen
    read -p "Wilt u databaseservers [true/false] ?: " DATABASESERVERS
    if [ $DATABASESERVERS == "true" ]; then
        read -p "Hoeveel databaseservers?: " DATABASESERVERS_AANTAL
        read -p "Hoeveel geheugen wilt u?: " DATABASESERVERS_MEMORY
    else
        DATABASESERVERS_AANTAL=0
        DATABASESERVERS_MEMORY=0
    fi

    #Netwerk Instellingen
    read -p "Op welk netwerk wilt u draaien [x.x.x.] ?: " SUBNET
    DESTINATION="/home/sander/VM2/klanten/$KLANTNAAM/$OMGEVING"
}

copy_files() {
    mkdir --parents $DESTINATION
    cp /home/sander/VM2/templates/Vagrantfile $DESTINATION/Vagrantfile
    cp /home/sander/VM2/templates/ansible.cfg $DESTINATION/ansible.cfg
    inventoryfile
    echo "ENVIRONMENT=$OMGEVING" >>$DESTINATION/settings.txt
    echo "SUBNET=$SUBNET" >>$DESTINATION/settings.txt
    echo "WEBSERVERS=$WEBSERVERS" >>$DESTINATION/settings.txt
    echo "WEBSERVERS_AANTAL=$WEBSERVERS_AANTAL" >>$DESTINATION/settings.txt
    echo "WEBSERVERS_MEMORY=$WEBSERVERS_MEMORY" >>$DESTINATION/settings.txt
    echo "LOADBALANCERS=$LOADBALANCERS" >>$DESTINATION/settings.txt
    echo "LOADBALANCERS_AANTAL=$LOADBALANCERS_AANTAL" >>$DESTINATION/settings.txt
    echo "LOADBALANCERS_MEMORY=$LOADBALANCERS_MEMORY" >>$DESTINATION/settings.txt
    echo "LOADBALANCERS_PORT=$LOADBALANCERS_PORT" >>$DESTINATION/settings.txt
    echo "LOADBALANCERS_STATS_PORT=$LOADBALANCERS_STATS_PORT" >>$DESTINATION/settings.txt
    echo "DATABASESERVERS=$DATABASESERVERS" >>$DESTINATION/settings.txt
    echo "DATABASESERVERS_AANTAL=$DATABASESERVERS_AANTAL" >>$DESTINATION/settings.txt
    echo "DATABASESERVERS_MEMORY=$DATABASESERVERS_MEMORY" >>$DESTINATION/settings.txt
}

#Replace all settings in Vagrant file with variables
webservers() {
    sed -i "s/{{ webservers }}/$WEBSERVERS/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ webservers_aantal }}/$WEBSERVERS_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ webservers_memory }}/$WEBSERVERS_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Replace all settings in Vagrant file with variables
loadbalancers() {
    sed -i "s/{{ loadbalancers }}/$LOADBALANCERS/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ loadbalancers_aantal }}/$LOADBALANCERS_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ loadbalancers_memory }}/$LOADBALANCERS_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Replace all settings in Vagrant file with variables
databaseservers() {
    sed -i "s/{{ databaseservers }}/$DATABASESERVERS/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ databaseservers_aantal }}/$DATABASESERVERS_AANTAL/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ databaseservers_memory }}/$DATABASESERVERS_MEMORY/g" "$DESTINATION/Vagrantfile"
}

#Create Inventory.ini file
inventoryfile() {
    # Checks if Inventory.ini exists
    if [ -f "$DESTINATION/inventory.ini" ]; then
        echo "Inventory file exists, removing old inventory file now."
        rm $DESTINATION/inventory.ini
    fi

    #Create Inventory.ini
    touch $DESTINATION/inventory.ini

    #Webservers are enabled > adds to Inventory.ini
    if [ $WEBSERVERS == "true" ]; then
        echo "[webservers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $WEBSERVERS_AANTAL ]; do
            #Adding 5 -> Range
            echo "$SUBNET$(expr $COUNTER + 30)" >>$DESTINATION/inventory.ini
            COUNTER=$(expr $COUNTER + 1)
        done
        echo "" >>$DESTINATION/inventory.ini
    fi

    #Loadbalancers are enabled > adds to Inventory.ini
    if [ $LOADBALANCERS == "true" ]; then
        echo "[loadbalancers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $LOADBALANCERS_AANTAL ]; do
            #Adding 5 -> Range
            echo "$SUBNET$(expr $COUNTER + 2)" >>$DESTINATION/inventory.ini
            COUNTER=$(expr $COUNTER + 1)
        done
        echo "" >>$DESTINATION/inventory.ini
        echo "[loadbalancers:vars]" >>$DESTINATION/inventory.ini
        echo "bind_port=$LOADBALANCERS_PORT" >>$DESTINATION/inventory.ini
        echo "stats_port=$LOADBALANCERS_STATS_PORT" >>$DESTINATION/inventory.ini
        echo "" >>$DESTINATION/inventory.ini
    fi

    #Databaseservers are enabled > adds to Inventory.ini
    if [ $DATABASESERVERS == "true" ]; then
        echo "[databaseservers]" >>$DESTINATION/inventory.ini
        COUNTER=0
        while [ $COUNTER -lt $DATABASESERVERS_AANTAL ]; do
            #Adding 5 -> Range
            echo "$SUBNET$(expr $COUNTER + 10)" >>$DESTINATION/inventory.ini
            COUNTER=$(expr $COUNTER + 1)
        done
        echo "" >>$DESTINATION/inventory.ini
    fi
}

#Destroy Function
vagrant_destroy() {
    read -p "Wat is uw klantnaam? " BESTAANDEKLANT
    read -p "Welke omgeving wilt u verwijderen [test, acceptatie, productie]? " OMGEVINGVERWIJDEREN
    (cd "/home/sander/VM2/klanten/$BESTAANDEKLANT/$OMGEVINGVERWIJDEREN" && vagrant destroy)
    rm -r "/home/sander/VM2/klanten/$BESTAANDEKLANT"
    exit 0
}

#Edit Function
vagrant_edit() {
    read -p "Wat is uw klantnaam? " EDITKLANT
    read -p "Welke omgeving wilt u aanpassen [test, acceptatie, productie]? " EDITOMGEVING

    #Set Destination to current customer
    DESTINATION="/home/sander/VM2/klanten/$EDITKLANT/$EDITOMGEVING"

    #Copy information from settings.txt
    source "$DESTINATION/settings.txt"
    WEBSERVERS_AANTAL_OLD=$WEBSERVERS_AANTAL
    LOADBALANCERS_AANTAL_OLD=$LOADBALANCERS_AANTAL
    DATABASESERVERS_AANTAL_OLD=$DATABASESERVERS_AANTAL

    #Change customers webservers
    read -p "Wilt u de webservers aanpassen? [true/false]: " EDIT_WEBSERVERS

    if [ $EDIT_WEBSERVERS == "true" ]; then
        read -p "Hoeveel webservers wilt u? [Op dit moment zijn er $WEBSERVERS_AANTAL] " WEBSERVERS_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $WEBSERVERS_MEMORY] " WEBSERVERS_MEMORY
    fi

    #Change customers loadbalancers
    if [ "$EDITOMGEVING" == "acceptatie" ] || [ "$EDITOMGEVING" == "productie" ]; then
        read -p "Wilt u de loadbalancers aanpassen? [true/false]: " EDIT_LOADBALANCERS

        if [ $EDIT_LOADBALANCERS == "true" ]; then
            read -p "Hoeveel loadbalancers wilt u? [Op dit moment zijn er $LOADBALANCERS_AANTAL] " LOADBALANCERS_AANTAL
            read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $LOADBALANCERS_MEMORY] " LOADBALANCERS_MEMORY
            read -p "Op welke poort wilt u de loadbalancer? [Op dit moment staat hij op $LOADBALANCERS_PORT] " LOADBALANCERS_PORT
            read -p "Op welke poort wilt u de loadbalancer stats? [Op dit moment staat hij op $LOADBALANCERS_STATS_PORT] " LOADBALANCERS_PORT
        fi
    fi

    #Change customers databaseservers
    read -p "Wilt u de databaseservers aanpassen? [true/false]: " EDIT_DATABASESERVERS

    if [ $EDIT_DATABASESERVERS == "true" ]; then
        read -p "Hoeveel databaseservers wilt u? [Op dit moment zijn er $DATABASESERVERS_AANTAL] " DATABASESERVERS_AANTAL
        read -p "Hoeveel geheugen wilt u? [Op dit moment heeft u $DATABASESERVERS_MEMORY] " DATABASESERVERS_MEMORY
    fi

    while [ $WEBSERVERS_AANTAL -lt $WEBSERVERS_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$EDITKLANT-$EDITOMGEVING-web$WEBSERVERS_AANTAL_OLD" -f)
        WEBSERVERS_AANTAL_OLD=$(expr $WEBSERVERS_AANTAL_OLD - 1)
    done

    while [ $LOADBALANCERS_AANTAL -lt $LOADBALANCERS_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$EDITKLANT-$EDITOMGEVING-loadbalancer$LOADBALANCERS_AANTAL_OLD" -f)
        WEBSERVERS_AANTAL_OLD=$(expr $LOADBALANCERS_AANTAL_OLD - 1)
    done

    while [ $DATABASESERVERS_AANTAL -lt $DATABASESERVERS_AANTAL_OLD ]; do
        (cd $DESTINATION && vagrant destroy "$EDITKLANT-$EDITOMGEVING-database$DATABASESERVERS_AANTAL_OLD" -f)
        WEBSERVERS_AANTAL_OLD=$(expr $DATABASESERVERS_AANTAL_OLD - 1)
    done

    rm "$DESTINATION/Vagrantfile"
    rm "$DESTINATION/settings.txt"
    rm "$DESTINATION/inventory.ini"
    rm "$DESTINATION/ansible.cfg"
    copy_files
    sed -i "s/{{ hostname_default }}/$EDITKLANT-$EDITOMGEVING-/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ subnet }}/$SUBNET/g" "$DESTINATION/Vagrantfile"
    webservers
    loadbalancers
    databaseservers
    (cd $DESTINATION && vagrant reload)
    (cd $DESTINATION && vagrant up)
    (cd $DESTINATION && ansible-playbook /home/sander/VM2/playbooks/production.yml)
    exit 0
}

#Main file
vagrant_main() {
    klant_gegevens
    copy_files
    sed -i "s/{{ hostname_default }}/$KLANTNAAM-$OMGEVING-/g" "$DESTINATION/Vagrantfile"
    sed -i "s/{{ subnet }}/$SUBNET/g" "$DESTINATION/Vagrantfile"
    webservers
    loadbalancers
    databaseservers
    (cd $DESTINATION && vagrant up)
    (cd $DESTINATION && ansible-playbook /home/sander/VM2/playbooks/production.yml)
    exit 0
}

# Main Menu
echo "Welkom bij het Self-Service-Portal"
echo "1.) Nieuwe Klant"
echo "2.) Verwijder Klant"
echo "3.) Pas bestaande klant aan"
read -p "Kies welke service u nodig heeft: " KEUZE

if [ $KEUZE == "1" ]; then
    vagrant_main
elif [ $KEUZE == "2" ]; then
    vagrant_destroy
elif [ $KEUZE == "3" ]; then
    vagrant_edit
else
    exit 0
fi
