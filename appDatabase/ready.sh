#!/bin/bash

psql -U postgres postgres -A -t -c "SELECT 'ready'"
