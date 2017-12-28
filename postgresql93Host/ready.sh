#!/bin/sh

psql -U postgres postgres -A -t -c "SELECT 'ready'"
