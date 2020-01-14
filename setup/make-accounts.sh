#!/bin/bash

cat ~/gradebook.txt | perl extract_account_data_from_roster.pl > ~/accounts.txt
cat ~/accounts.txt | perl make_accounts.pl > ~/make_accounts_generated.sh
