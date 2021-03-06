#!/bin/bash


EMAIL=$1
PASSWORD=$2

TEST_HOST=$3
TEST_USERNAME=$4
TEST_PASSWORD=$5
WORKSPACE=$6

function install_katalon {
    if [ -d "/opt/katalon" ]; then
        echo "Katalon already installed"
    else
        echo "Installing katalon"
        mkdir -p /opt/katalon
        cd /opt/katalon
        wget http://download.katalon.com/5.4.0/Katalon_Studio_Linux_64-5.4.tar.gz
        tar -xvf Katalon_Studio_Linux_64-5.4.tar.gz
        chmod 700 Katalon_Studio_Linux_64-5.4/katalon
    fi
}

function install_ff {
    if ! [ -x "$(command -v xvfb)" ]; then
        echo "Installing FF & xvfb"
        apt-get install -y firefox xvfb
    else
        echo "FF & xvfb already installed"
    fi
}


function run_tests {
    sed -i -e "s/\${hostname}/$TEST_HOST/" -e "s/\${username}/$TEST_USERNAME/" -e "s/\${secret}/$TEST_PASSWORD/" "$WORKSPACE/tests/katalon/Gluu Gateway/Data Files/dev1TestData.dat"
    echo "/opt/katalon/Katalon_Studio_Linux_64-5.4/katalon --args -runMode=console -projectPath='$WORKSPACE/tests/katalon/Gluu Gateway/Gluu Gateway.prj' -reportFolder='$WORKSPACE/Reports' -reportFileName='report' -retry=0 -testSuitePath='$WORKSPACE/tests/katalon/Gluu Gateway/Test Suites/GG_tests' -browserType='Firefox (headless)' -email='$EMAIL' -password='$PASSWORD'"
    ln -sf /opt/jre /opt/katalon/Katalon_Studio_Linux_64-5.4/jre
    /opt/katalon/Katalon_Studio_Linux_64-5.4/katalon --args -runMode=console -projectPath="$WORKSPACE/tests/katalon/Gluu Gateway/Gluu Gateway.prj" -reportFolder="$WORKSPACE/Reports" -reportFileName="report" -retry=0 -testSuitePath="Test Suites/GG_Tests" -browserType="Firefox (headless)" -email="$EMAIL" -password="$PASSWORD"
}

install_ff
install_katalon
run_tests