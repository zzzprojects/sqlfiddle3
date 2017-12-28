#!/bin/sh

mysql -u root -ppassword mysql -ss -e "SELECT 'ready'"
