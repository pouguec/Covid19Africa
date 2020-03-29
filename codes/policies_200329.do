* Started:    200329 |bzdiop
* last edit:  200329 |bzdiop



* BSG dataset 
import excel "$raw/policies_200328.xlsx", firstrow clear

* variable cleaning 
rename *, lower 
rename countryname country 
sort country date 


* creating africa indicator
gen africa = 0
//missing mali malawi libya lesotho bisau comoros burundi Sao Tome and Principe
foreach country in Algeria	Angola	Benin	Botswana	"Burkina Faso"	Burundi	"Cape Verde"	Cameroon	"Central African Republic"	Chad	Comoros	Congo "Democratic Republic of Congo"	"Cote d'Ivoire"	Djibouti	Egypt	"Equatorial Guinea"	Eritrea	Swaziland	Ethiopia	Gabon	Gambia	Ghana	Guinea	"Guinea-Bissau"	Kenya	Lesotho	Liberia	Libya	Madagascar	Malawi	Mali	Mauritania	Mauritius	Morocco	Mozambique	Namibia	Niger	Nigeria	Rwanda	"Sao Tome and Principe"	Senegal	Seychelles	"Sierra Leone"	Somalia	"South Africa"	"South Sudan"	Sudan	Tanzania	Togo	Tunisia	Uganda	Zambia	Zimbabwe {
	display "`country'"
	replace africa = 1 if country == "`country'"
}

* keeping african countries 
keep if africa == 1   


* replacing indicator by date (to plot)
ds country countrycode date *notes, not
foreach var of varlist `r(varlist)' {
	cap replace `var' = . if `var' == 0
	cap replace `var' = date if !missing(`var')
	cap bys country (date): replace `var' = `var'[_n-1] if !missing(`var'[_n-1]) & country == country[_n-1] // getting the first day of introduction of the policy 
}


* keeping last date in the data 
bys country (date): gen n = _n 
bys country (date): gen N = _N 
keep if N == n
drop africa n N date ai // dropping useless variables 

dropmiss, force     // dropping  columns with all missing
dropmiss, force obs // dropping rows with all missing


order country confirmedcases s7_internationaltravelcontrols s6_restrictionsoninternalmove * *notes
br if inlist(country, "Senegal", "Ghana", "Kenya", "Cameroon", "South Africa")

//from @Clemence, plot: international travel controls and schools

