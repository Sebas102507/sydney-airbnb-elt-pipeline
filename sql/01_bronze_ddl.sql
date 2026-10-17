-- Bronze Schema: For raw, unprocessed source data from various systems.
CREATE SCHEMA IF NOT EXISTS bronze;

-- Silver Schema: For cleaned, validated, and enriched data.
CREATE SCHEMA IF NOT EXISTS silver;

-- Gold Schema: For aggregated, business-ready data ready for analytics.
CREATE SCHEMA IF NOT EXISTS gold;

-- bronze.census_g01_nsw_lga_bronze definition

-- Drop table

-- DROP TABLE bronze.census_g01_nsw_lga_bronze;

CREATE TABLE bronze.census_g01_nsw_lga_bronze (
	"LGA_CODE_2016" text NULL,
	"Tot_P_M" int8 NULL,
	"Tot_P_F" int8 NULL,
	"Tot_P_P" int8 NULL,
	"Age_0_4_yr_M" int8 NULL,
	"Age_0_4_yr_F" int8 NULL,
	"Age_0_4_yr_P" int8 NULL,
	"Age_5_14_yr_M" int8 NULL,
	"Age_5_14_yr_F" int8 NULL,
	"Age_5_14_yr_P" int8 NULL,
	"Age_15_19_yr_M" int8 NULL,
	"Age_15_19_yr_F" int8 NULL,
	"Age_15_19_yr_P" int8 NULL,
	"Age_20_24_yr_M" int8 NULL,
	"Age_20_24_yr_F" int8 NULL,
	"Age_20_24_yr_P" int8 NULL,
	"Age_25_34_yr_M" int8 NULL,
	"Age_25_34_yr_F" int8 NULL,
	"Age_25_34_yr_P" int8 NULL,
	"Age_35_44_yr_M" int8 NULL,
	"Age_35_44_yr_F" int8 NULL,
	"Age_35_44_yr_P" int8 NULL,
	"Age_45_54_yr_M" int8 NULL,
	"Age_45_54_yr_F" int8 NULL,
	"Age_45_54_yr_P" int8 NULL,
	"Age_55_64_yr_M" int8 NULL,
	"Age_55_64_yr_F" int8 NULL,
	"Age_55_64_yr_P" int8 NULL,
	"Age_65_74_yr_M" int8 NULL,
	"Age_65_74_yr_F" int8 NULL,
	"Age_65_74_yr_P" int8 NULL,
	"Age_75_84_yr_M" int8 NULL,
	"Age_75_84_yr_F" int8 NULL,
	"Age_75_84_yr_P" int8 NULL,
	"Age_85ov_M" int8 NULL,
	"Age_85ov_F" int8 NULL,
	"Age_85ov_P" int8 NULL,
	"Counted_Census_Night_home_M" int8 NULL,
	"Counted_Census_Night_home_F" int8 NULL,
	"Counted_Census_Night_home_P" int8 NULL,
	"Count_Census_Nt_Ewhere_Aust_M" int8 NULL,
	"Count_Census_Nt_Ewhere_Aust_F" int8 NULL,
	"Count_Census_Nt_Ewhere_Aust_P" int8 NULL,
	"Indigenous_psns_Aboriginal_M" int8 NULL,
	"Indigenous_psns_Aboriginal_F" int8 NULL,
	"Indigenous_psns_Aboriginal_P" int8 NULL,
	"Indig_psns_Torres_Strait_Is_M" int8 NULL,
	"Indig_psns_Torres_Strait_Is_F" int8 NULL,
	"Indig_psns_Torres_Strait_Is_P" int8 NULL,
	"Indig_Bth_Abor_Torres_St_Is_M" int8 NULL,
	"Indig_Bth_Abor_Torres_St_Is_F" int8 NULL,
	"Indig_Bth_Abor_Torres_St_Is_P" int8 NULL,
	"Indigenous_P_Tot_M" int8 NULL,
	"Indigenous_P_Tot_F" int8 NULL,
	"Indigenous_P_Tot_P" int8 NULL,
	"Birthplace_Australia_M" int8 NULL,
	"Birthplace_Australia_F" int8 NULL,
	"Birthplace_Australia_P" int8 NULL,
	"Birthplace_Elsewhere_M" int8 NULL,
	"Birthplace_Elsewhere_F" int8 NULL,
	"Birthplace_Elsewhere_P" int8 NULL,
	"Lang_spoken_home_Eng_only_M" int8 NULL,
	"Lang_spoken_home_Eng_only_F" int8 NULL,
	"Lang_spoken_home_Eng_only_P" int8 NULL,
	"Lang_spoken_home_Oth_Lang_M" int8 NULL,
	"Lang_spoken_home_Oth_Lang_F" int8 NULL,
	"Lang_spoken_home_Oth_Lang_P" int8 NULL,
	"Australian_citizen_M" int8 NULL,
	"Australian_citizen_F" int8 NULL,
	"Australian_citizen_P" int8 NULL,
	"Age_psns_att_educ_inst_0_4_M" int8 NULL,
	"Age_psns_att_educ_inst_0_4_F" int8 NULL,
	"Age_psns_att_educ_inst_0_4_P" int8 NULL,
	"Age_psns_att_educ_inst_5_14_M" int8 NULL,
	"Age_psns_att_educ_inst_5_14_F" int8 NULL,
	"Age_psns_att_educ_inst_5_14_P" int8 NULL,
	"Age_psns_att_edu_inst_15_19_M" int8 NULL,
	"Age_psns_att_edu_inst_15_19_F" int8 NULL,
	"Age_psns_att_edu_inst_15_19_P" int8 NULL,
	"Age_psns_att_edu_inst_20_24_M" int8 NULL,
	"Age_psns_att_edu_inst_20_24_F" int8 NULL,
	"Age_psns_att_edu_inst_20_24_P" int8 NULL,
	"Age_psns_att_edu_inst_25_ov_M" int8 NULL,
	"Age_psns_att_edu_inst_25_ov_F" int8 NULL,
	"Age_psns_att_edu_inst_25_ov_P" int8 NULL,
	"High_yr_schl_comp_Yr_12_eq_M" int8 NULL,
	"High_yr_schl_comp_Yr_12_eq_F" int8 NULL,
	"High_yr_schl_comp_Yr_12_eq_P" int8 NULL,
	"High_yr_schl_comp_Yr_11_eq_M" int8 NULL,
	"High_yr_schl_comp_Yr_11_eq_F" int8 NULL,
	"High_yr_schl_comp_Yr_11_eq_P" int8 NULL,
	"High_yr_schl_comp_Yr_10_eq_M" int8 NULL,
	"High_yr_schl_comp_Yr_10_eq_F" int8 NULL,
	"High_yr_schl_comp_Yr_10_eq_P" int8 NULL,
	"High_yr_schl_comp_Yr_9_eq_M" int8 NULL,
	"High_yr_schl_comp_Yr_9_eq_F" int8 NULL,
	"High_yr_schl_comp_Yr_9_eq_P" int8 NULL,
	"High_yr_schl_comp_Yr_8_belw_M" int8 NULL,
	"High_yr_schl_comp_Yr_8_belw_F" int8 NULL,
	"High_yr_schl_comp_Yr_8_belw_P" int8 NULL,
	"High_yr_schl_comp_D_n_g_sch_M" int8 NULL,
	"High_yr_schl_comp_D_n_g_sch_F" int8 NULL,
	"High_yr_schl_comp_D_n_g_sch_P" int8 NULL,
	"Count_psns_occ_priv_dwgs_M" int8 NULL,
	"Count_psns_occ_priv_dwgs_F" int8 NULL,
	"Count_psns_occ_priv_dwgs_P" int8 NULL,
	"Count_Persons_other_dwgs_M" int8 NULL,
	"Count_Persons_other_dwgs_F" int8 NULL,
	"Count_Persons_other_dwgs_P" int8 NULL
);


-- bronze.census_g02_nsw_lga_bronze definition

-- Drop table

-- DROP TABLE bronze.census_g02_nsw_lga_bronze;

CREATE TABLE bronze.census_g02_nsw_lga_bronze (
	"LGA_CODE_2016" text NULL,
	"Median_age_persons" int8 NULL,
	"Median_mortgage_repay_monthly" int8 NULL,
	"Median_tot_prsnl_inc_weekly" int8 NULL,
	"Median_rent_weekly" int8 NULL,
	"Median_tot_fam_inc_weekly" int8 NULL,
	"Average_num_psns_per_bedroom" float8 NULL,
	"Median_tot_hhd_inc_weekly" int8 NULL,
	"Average_household_size" float8 NULL
);


-- bronze.listings_bronze definition

-- Drop table

-- DROP TABLE bronze.listings_bronze;

CREATE TABLE bronze.listings_bronze (
    "LISTING_ID" int8 NULL,
    "SCRAPE_ID" int8 NULL,
    "SCRAPED_DATE" varchar NULL,
    "HOST_ID" int8 NULL,
    "HOST_NAME" varchar NULL,
    "HOST_SINCE" varchar NULL,
    "HOST_IS_SUPERHOST" varchar NULL,
    "HOST_NEIGHBOURHOOD" varchar NULL,
    "LISTING_NEIGHBOURHOOD" varchar NULL,
    "PROPERTY_TYPE" varchar NULL,
    "ROOM_TYPE" varchar NULL,
    "ACCOMMODATES" int8 NULL,
    "PRICE" float8 NULL,
    "HAS_AVAILABILITY" varchar NULL,
    "AVAILABILITY_30" int8 NULL,
    "NUMBER_OF_REVIEWS" int8 NULL,
    "REVIEW_SCORES_RATING" float8 NULL,
    "REVIEW_SCORES_ACCURACY" float8 NULL,
    "REVIEW_SCORES_CLEANLINESS" float8 NULL,
    "REVIEW_SCORES_CHECKIN" float8 NULL,
    "REVIEW_SCORES_COMMUNICATION" float8 NULL,
    "REVIEW_SCORES_VALUE" float8 NULL,
    CONSTRAINT uq_listings_id_scraped_date UNIQUE ("LISTING_ID", "SCRAPED_DATE")
);


-- bronze.nsw_lga_code_bronze definition

-- Drop table

-- DROP TABLE bronze.nsw_lga_code_bronze;

CREATE TABLE bronze.nsw_lga_code_bronze (
	"LGA_CODE" int8 NULL,
	"LGA_NAME" text NULL
);


-- bronze.nsw_lga_suburb_bronze definition

-- Drop table

-- DROP TABLE bronze.nsw_lga_suburb_bronze;

CREATE TABLE bronze.nsw_lga_suburb_bronze (
	"LGA_NAME" text NULL,
	"SUBURB_NAME" text NULL
);


-- bronze.temp_listings_bronze definition

-- Drop table

-- DROP TABLE bronze.temp_listings_bronze;

CREATE TABLE bronze.temp_listings_bronze (
	"LISTING_ID" int8 NULL,
	"SCRAPE_ID" int8 NULL,
	"SCRAPED_DATE" text NULL,
	"HOST_ID" int8 NULL,
	"HOST_NAME" text NULL,
	"HOST_SINCE" text NULL,
	"HOST_IS_SUPERHOST" text NULL,
	"HOST_NEIGHBOURHOOD" text NULL,
	"LISTING_NEIGHBOURHOOD" text NULL,
	"PROPERTY_TYPE" text NULL,
	"ROOM_TYPE" text NULL,
	"ACCOMMODATES" int8 NULL,
	"PRICE" int8 NULL,
	"HAS_AVAILABILITY" text NULL,
	"AVAILABILITY_30" int8 NULL,
	"NUMBER_OF_REVIEWS" int8 NULL,
	"REVIEW_SCORES_RATING" float8 NULL,
	"REVIEW_SCORES_ACCURACY" float8 NULL,
	"REVIEW_SCORES_CLEANLINESS" float8 NULL,
	"REVIEW_SCORES_CHECKIN" float8 NULL,
	"REVIEW_SCORES_COMMUNICATION" float8 NULL,
	"REVIEW_SCORES_VALUE" float8 NULL
);