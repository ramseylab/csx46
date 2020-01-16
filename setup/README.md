# Setting up accounts for CSX46 students on the JupyterHUb server

## Extract user data from Canvas and export as TSV
```
cat 16_Sep_16_42_Grades-BIOLOGICAL_NETWORKS_(CS_446_X001_F2016).txt | perl extrcat_account_data_from_roster.pl > account_data.txt
```

## Generate shell script for making the Linux accounts

```
cat account_data.txt | perl make_accounts.pl > make_accounts.sh
sh make_accounts.sh
```
