#!/bin/bash
debconf-set-selections <<< 'mysql-server mysql-server/root_password password complemento'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password complemento'
