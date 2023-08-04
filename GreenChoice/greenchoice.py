import datetime
import pandas as pd

# Define files
file_path = os.path.dirname(os.path.abspath(sys.argv[0]))

raw_csv_file = file_path+"/meterstanden_stroom_2023.csv"
cons_high_file = file_path+"/energy_consumption_tarif_hoog_st.csv"
cons_low_file = file_path+"/energy_consumption_tarif_laag_st.csv"
prod_high_file = file_path+"/energy_production_tarif_hoog_st.csv"
prod_low_file = file_path+"/energy_production_tarif_laag_st.csv"

# Define start and end date
start_date = "01-01-1970"
end_date = "31-12-2099"

if __name__ == '__main__':
    df = pd.read_csv(raw_csv_file, sep=';', decimal='.', parse_dates=['OpnameDatum'])
    df = df.loc[(df['OpnameDatum'] >= datetime.datetime.strptime(start_date, "%d-%m-%Y")) & (
                df['OpnameDatum'] <= datetime.datetime.strptime(end_date, "%d-%m-%Y"))]

    # Transform the date into unix timestamp for Home-Assistant
    df['OpnameDatum'] = (df['OpnameDatum'].view('int64') / 1000000000)

    df_cons_high = df.filter(['OpnameDatum', 'StandNormaal'])
    df_cons_high.to_csv(cons_high_file, sep=',', decimal='.', header=False, index=False)

    df_cons_low = df.filter(['OpnameDatum', 'StandDal'])
    df_cons_low.to_csv(cons_low_file, sep=',', decimal='.', header=False, index=False)

    df_prod_high = df.filter(['OpnameDatum', 'TerugleveringNormaal'])
    df_prod_high.to_csv(prod_high_file, sep=',', decimal='.', header=False, index=False)

    df_prod_low = df.filter(['OpnameDatum', 'TerugleveringDal'])
    df_prod_low.to_csv(prod_low_file, sep=',', decimal='.', header=False, index=False)
