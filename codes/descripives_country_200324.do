* started:   20200324 | bzdiop
* last edit: 20200325 | bzdiop
* QA: 		 20200326 | pouguec

global countrylong "Senegal"
global countrylongfr "Sénégal"
global countrylong2 "senegal"
global countryshort "sen"
global day1 "28/02/2020" // Senegal 
global francophone "yes"
global popcountry 15860000 

global countrylong "Ghana"
global countrylongfr "Ghana"
global countrylong2 "ghana"
global countryshort "gha"
global day1 "13/03/2020" // Senegal 
global francophone "no"
global popcountry 29767108





* Globals to folders
global covid "/Users/binta/Documents/COVID19/covid19africa"
global raw "$covid/raw"
global docs "$covid/docs"
global logs "$covid/logs"
global output "$covid/output"
global graphs "$covid/graphs"
global tables "$covid/tables"
global do "$covid/codes"
global temp "$covid/temporary"
global pred "$do/solution_data_${countryshort}"


! mkdir "$graphs/${countryshort}"
/*
! mkdir "$raw"
*! mkdir "$data/interim"
*! mkdir "$data/processed"
*! mkdir "$docs"
! mkdir "$logs"
! mkdir "$output"
! mkdir "$graphs"
! mkdir "$do"
*! mkdir "$reports"
*! mkdir "$tables"
mkdir "$temp"
*/

	* Setting time global
		global month = month(date("`c(current_date)'", "DMY"))
		global day   = day(date("`c(current_date)'", "DMY")) 
		global year  = year(date("`c(current_date)'", "DMY")) 


			if ${month}<= 9 & ${day}<=9{ 
				global date "${year}0${month}0${day}"
				}

			if ${month}<= 9 & ${day}>9{ 
				global date "${year}0${month}${day}" 
				}

			if ${month}> 9 & ${day}<=9{ 
				global date "${year}${month}0${day}"  
			}

			if ${month}> 9 & ${day}>9{
				global date "${year}${month}${day}"  
				}
				
				

* Importing data for senegal 
import excel "${raw}/coviddaily_sen_${date}.xlsx", firstrow clear

	* Counting tests
	split newtests_totaltests, p("_") // tests are in the same variable
	rename (newtests_totaltests1 newtests_totaltests2) (newtests totaltests) // to match the names with the other dataset
	drop newtests_totaltests 
	
	* Date cleaning
	drop if missing(daterep) // formatting issue. Some rows are added at the end of the file
	format daterep %td 
	rename daterep date_stata
	replace country = "Senegal" 
	
save "$temp/coviddaily_sen_${date}.dta", replace





****************************************************************************************************************************************************************
* 	Data source: https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide
****************************************************************************************************************************************************************

* renaming files to something more sensible (but like, really?!)
local files : dir "$raw" files "COVID-19-geographic-disbtribution-worldwide-*.xlsx" 
local nfile: word count `files'
local j = 1	

while `j'<=`nfile'{
	local oldname: word `j' of `files'
	local newname0 = subinstr("`oldname'", "COVID-19-geographic-disbtribution-worldwide-", "coviddaily_", 1) 
	local newname  = subinstr("`newname0'", "-", "", .) 
	shell mv "$raw/`oldname'" "$raw/`newname'"
	local j = `j' + 1
}




* Importing data (I should probably write a script to download it from the site directly...)
import excel "${raw}/coviddaily_${date}.xlsx", firstrow clear

	* cleaning variable names 
	rename *, lower 
	rename countries country
	
	* dates
	format daterep %td 
	rename daterep date_stata
	drop day month year 

	* stores a local with all countries 
	levelsof country, local(countries)

	* Preserve: to generate a dataset with all dates for each country. 
	* Some of these dates are missing from the dataset -- so this way we know when they do
	preserve 
		keep date_stata 
		duplicates drop 
		sort date_stata 
		levelsof date_stata, local(dates)
		
		clear 
		quietly: gen country = ""
		quietly: gen date_stata = .
		foreach country in `countries' {
			foreach date in `dates' {
				quietly: set obs `=_N+1'
				quietly: replace date_stata = `date' if missing(date_stata)
				quietly: replace country = "`country'" if missing(country)
			}
		}
		format date %td
		
		tempfile countrydate
		save `countrydate'
		*save "$temp/countrydate.dta", replace
	restore 



	merge 1:1 country date_stata using "`countrydate'", nogen
	*merge 1:1 country date_stata using "$temp/countrydate.dta", nogen
	
	* Flagging countries that have at least one missing date
	gen missing_info0 = (missing(cases))
	bys country: egen missing_info = max(missing_info0)

	* I am assuming that when data is missing, the number of new cases is 0
	* probably a valid assumption in EU but definitely unsatisfactory in African countries
	replace cases = 0 if missing(cases)

	* This is creating a variable that sums previous cases
	gen total_cases = cases 
	bys country (date_stata): replace total_cases = total_cases + total_cases[_n-1] if country == country[_n-1]


	* dropping days prior to first case
	drop if total_cases == 0 
	
	* dropping data for senegal from this dataset to replace it by data from Sen ministry of health created in section 1
	drop if country == "Senegal"
	append using "$temp/coviddaily_sen_${date}.dta"

	
	* harmonizing country names (and cropping long names)
	replace country = lower(country)
	replace country = subinstr(country, "_and_", "", .)
	replace country = subinstr(country, "_", "", .)
	replace country = subinstr(country, "bosniaandherzegovina", "bosniaandherz", 1)
	replace country = subinstr(country, "casesonaninternationalconveyancejapan", "japanboat", 1)
	replace country = subinstr(country, "democraticrepublicofthecongo", "drc", 1)
	replace country = subinstr(country, "saintvincentthegrenadines", "stvincgrenadines", 1)
	replace country = subinstr(country, "unitedrepublicoftanzania", "tanzania", 1)
	replace country = subinstr(country, "unitedstatesofamerica", "usa", 1)
	replace country = subinstr(country, "centralafricanrepublic", "car", 1)
	replace country = subinstr(country, "unitedstatesvirginislands", "usvirgin", 1)

	
	
	* creating date of first case (given that now we have all days for all countries, we just count all all rows from day0)
	bys country (date_stata) : gen day_since_firstcase = _n - 1
	
	* harvesting date of first case
	gen dcase10 = date_stata if day_since_firstcase == 0
	by country: egen dcase1 = mean(dcase10) // min = mean = max (because missng for all other ones)
	format dcase1 %td
	

	drop dcase10 missing_info0 date_stata geoid source

	save "$temp/temp", replace // so that I dont have to run all of it to tweak graphs

	
	
	
	
	use "$temp/temp", clear
	
	
	* saving locals for graphs (dates)
	preserve 
	
		drop if country == "China" // for scale
		
		sum day_since_firstcase
		local days_asia = `r(max)'
		local days_europe = `days_asia' - 20
		local days_africa = `days_asia' - 63
		
		
	restore 


	*capture drop pop_data2018 // was added to new ECDC published data
	*capture drop countrycode
	
	

	gen ltotal_cases = log(total_cases)
	
	keep cases deaths total_cases ltotal_cases negtests casespermil active recovered newtests totaltests missing_info dcase1 day_since_firstcase country
	
	
	* to plot: need one country per column
	reshape wide cases deaths total_cases ltotal_cases negtests casespermil active recovered newtests totaltests missing_info dcase1 , i(day_since_firstcase) j(country, string)
	
	sum day_since_firstcase if !missing(total_casesghana)
	local days_${countrylong2} = `r(max)'
	
	destring newtestssenegal totaltestssenegal, replace



	* saving locals for graphs (cases) 
	sum total_casesitaly
	local cases_europe = `r(max)'
	local lcases_europe = log(`r(max)')
	display "`cases_europe'"

	sum total_casessouthkorea
	local cases_asia = `r(max)'
	local lcases_asia = log(`r(max)')
	display "`cases_asia'"

	sum total_casessenegal
	local cases_africa  = `r(max)' + 100
	local lcases_africa = log(`r(max)' + 100)
	display "`cases_africa'"
	
	sum total_cases${countrylong2}
	local cases_${countrylong2}  = `r(max)' + 100
	local lcases_${countrylong2} = log(`r(max)' + 100)
	display "`cases_africa'"
	

	sum total_casessouthafrica
	local cases_africa2  = `r(max)' + 100
	local lcases_africa2 = log(`r(max)' + 100)
	display "`cases_africa'"
	
	
	
	
************************** English **************************	
	* Labels 
	label var total_casesgermany "Germany"
	label var total_casesfrance "France"
	label var ltotal_casesfrance "France"
	label var total_casesitaly "Italy"
	label var ltotal_casesitaly "Italy"
	label var total_casesspain "Spain"
	label var ltotal_casesspain "Spain"
	label var total_casesunitedkingdom "UK"
	label var day_since_firstcase "Days since first case"

	label var total_casessouthkorea "South Korea"
	label var ltotal_casessouthkorea "South Korea"
	label var total_casesmalaysia "Malaysia"
	label var total_casesjapan "Japan"
	label var total_casessingapore "Singapore"
	label var ltotal_casessingapore "Singapore"
	label var total_casestaiwan "Taiwan"

	label var total_cases${countrylong2} "${countrylong}"
	label var ltotal_cases${countrylong2} "${countrylong}"
	label var total_casesghana  "Ghana"
	label var total_casescotedivoire "Côte d'Ivoire"
	label var total_caseskenya  "Kenya"
	label var total_casessouthafrica "South-Africa"
	label var total_casesburkinafaso "Burkina Faso"
	label var total_casesmorocco "Morocco"
	label var total_casesalgeria "Algeria"
	label var total_casesegypt "Egypt"

	
	* data for SIR model 
	outsheet *${countrylong2} day_since_firstcase* missing_info* cases* deaths* missing_info* total_cases* dcase1* using "$temp/covid_${date}.csv", comma replace
		
	
	
**************** Continent panel: Africa Europe Asia
twoway (connected total_casesitaly day_since_firstcase, msize(small) )  ///
	   (connected total_casesspain day_since_firstcase, msize(small) )  ///
	   (connected total_casesgermany day_since_firstcase, msize(small) )  ///
	   (connected total_casesfrance day_since_firstcase, msize(small) )  ///
       (connected total_casesunitedkingdom day_since_firstcase, msize(small) ) ///	 
       ,  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 30 "30 days" 45 "45 days" 60 "60 days" 75 "75 days", ticks labsize(small)) yscale(range(50 200)) ylabel(0(10000)`cases_europe', ticks) legend(on ring(0) cols(1) pos(9)) graphregion(color(white)) ///
		title("Europe", size(small) color(black)) saving("$temp/totalcases_europe.gph" , replace) 
		

twoway (connected total_casessouthkorea day_since_firstcase, msize(small) )  ///
	   (connected total_casesmalaysia   day_since_firstcase, msize(small) )  ///
	   (connected total_casesjapan      day_since_firstcase, msize(small) )  ///
	   (connected total_casessingapore  day_since_firstcase, msize(small) )  ///
       (connected total_casestaiwan     day_since_firstcase, msize(small) ) ///	 
       ,  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 30 "30 days" 45 "45 days" 60 "60 days" 75 "75 days", ticks labsize(small)) ylabel(0(1000)`cases_asia', ticks) legend(on ring(0) cols(1) pos(9)) graphregion(color(white)) ///
		title("Asia", size(small) color(black)) saving("$temp/totalcases_asia.gph" , replace) 
		
	
twoway (connected total_casessenegal     day_since_firstcase, msize(small) )  ///
	   (connected total_casesghana       day_since_firstcase, msize(small) )  ///
	   (connected total_casescotedivoire day_since_firstcase, msize(small) )  ///
	   (connected total_caseskenya       day_since_firstcase, msize(small) )  ///
	   (connected total_casesburkinafaso day_since_firstcase, msize(small) ) ///
       ,  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 15 "15 days" 45 "45 days" 30 "30 days", ticks labsize(small)) yscale(range(50 200)) ylabel(0(25)`cases_africa', ticks) legend(on ring(0) cols(1) pos(3)) graphregion(color(white)) ///
		title("Africa: sample 1", size(small) color(black)) saving("$temp/totalcases_africa1.gph" , replace) 		
		
twoway (connected total_casessouthafrica day_since_firstcase, msize(small) )  ///
	   (connected total_casesegypt       day_since_firstcase, msize(small) )  ///
	   (connected total_casesalgeria     day_since_firstcase, msize(small) )  ///
	   (connected total_casesmorocco       day_since_firstcase, msize(small) )  ///
       ,  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 15 "15 days" 30 "30 days" 45 "45 days", ticks labsize(small)) yscale(range(50 200)) ylabel(0(200)`cases_africa2', ticks) legend(on ring(0) cols(1) pos(3)) graphregion(color(white)) ///
		title("Africa:  sample 2", size(small) color(black)) saving("$temp/totalcases_africa2.gph" , replace) 		

		
gr combine "$temp/totalcases_africa1.gph"  "$temp/totalcases_asia.gph" "$temp/totalcases_africa2.gph" "$temp/totalcases_europe.gph"  , graphregion(margin(zero ))  xcommon col(2) note("Sources: European CDC, Ministry of Health Senegal", size(vsmall))	
graph export "$graphs/trendpanel_${date}.png", replace
	
	
	
		
	* Graphing Senegal vs. other countries
	preserve 

		drop if day_since_firstcase > `days_${countrylong2}' // Time to date evolution of cases
				
		* locals for in graph labels
		local texty = `${countrylong2}' - 24 
		local textx = `${countrylong2}' + .25

				
			twoway (connected total_cases${countrylong2}     day_since_firstcase, msize(small) msymbol(diamond) mcolor(maroon) lcolor(maroon))  ///
				   (connected total_casesitaly       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   (connected total_casesspain       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   (connected total_casesfrance       day_since_firstcase, mcolor(blue) msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   ///
				   (connected total_casessouthkorea  day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  ///
				   (connected total_casessingapore   day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  ///
				   , text(`texty' `textx'  "${countrylong}", place(e))  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 15 "15 days" 30 "30 days", ticks labsize(small)) yscale(range(50 `cases_${countrylong2}')) ylabel(0(25)`cases_${countrylong2}', ticks) legend(on ring(0) cols(1) pos(4)) graphregion(color(white)) ///
				title("${countrylong} vs. rest of the world", size(small) color(black)) saving("$temp/totalcases_africa.gph" , replace) 		
		graph export "$graphs/${countryshort}_fr_vs_all_${date}.png", replace
		
		
		twoway (connected ltotal_cases${countrylong2}     day_since_firstcase, msize(small) msymbol(diamond) mcolor(maroon) lcolor(maroon))  ///
				   (connected ltotal_casesitaly       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   (connected ltotal_casesspain       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   (connected ltotal_casesfrance       day_since_firstcase, mcolor(blue) msize(tiny) lwidth(vthin) lcolor(blue))  ///
				   ///
				   (connected ltotal_casessouthkorea  day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  ///
				   (connected ltotal_casessingapore   day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  ///
				   ,  ylab(, labsize(vsmall)) legend(off) graphregion(color(white))  xlabel(0 "0 days" 15 "15 days" 30 "30 days", ticks labsize(small))  ylabel(0(1)`lcases_${countrylong2}', ticks) legend(on ring(0) cols(1) pos(4)) graphregion(color(white)) ytitle("log cases", size(small)) ///
				title("${countrylong} vs. rest of the world", size(small) color(black)) saving("$temp/totalcases_africa.gph" , replace) 		
		graph export "$graphs/${countryshort}_fr_vs_all_log_${date}.png", replace
		

	restore		

		
		
************************** French **************************	
		
label var total_casesgermany "Allemagne"
label var total_casesfrance "France"
label var total_casesitaly "Italie"
label var total_casesspain "Espagne"
label var total_casesunitedkingdom "Royaume-Uni"
label var day_since_firstcase "Nombre de jours depuis le premier cas"


label var total_cases${countrylong2} "${countrylongfr}"
label var total_casessouthkorea "Corée du Sud"
label var total_casesmalaysia "Malaisie"
label var total_casesjapan "Japon"
label var total_casessingapore "Singapour"


label var total_casessouthafrica "Afrique du Sud"
label var total_casesmorocco "Maroc"



* Graphing Senegal vs. other countries
preserve 

drop if day_since_firstcase > `days_${countrylong2}'
		

local texty = `cases_africa' - 24
local textx = `days_africa' + .25
			
	twoway (connected total_cases${countrylong2}     day_since_firstcase, msize(small) msymbol(diamond) mcolor(maroon) lcolor(maroon))  /// Senegal
		   ///
		   (connected total_casesitaly       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  /// Italy
		   (connected total_casesspain       day_since_firstcase, mcolor(blue)  msize(tiny) lwidth(vthin) lcolor(blue))  /// Spain
		   (connected total_casesfrance       day_since_firstcase, mcolor(blue) msize(tiny) lwidth(vthin) lcolor(blue))  /// France
		   ///
		   (connected total_casessouthkorea  day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  /// SKorea
		   (connected total_casessingapore   day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green))  /// Singapore
		   (connected total_casesmalaysia      day_since_firstcase, mcolor(green) msize(tiny) lwidth(vthin) lcolor(green)) /// Malaysia
		   , text(`texty' `textx'  "${countrylongfr}", place(e)) ylab(, labsize(vsmall)) graphregion(color(white))  xscale(range(1 10)) xlabel(0 "0 jours" 15 "15 Jours" 30 "30 jours", labsize(small)) yscale(range(50 `cases_${countrylong2}')) ylabel(0(25)`cases_${countrylong2}', ticks) legend(on ring(0) cols(1) pos(10) size(vsmall)) ///
			title("Le ${countrylongfr} comparé au reste du monde", size(small) color(black)) saving("$temp/totalcases_africa_fr.gph" , replace) 
			graph export "$graphs/${countryshort}_fr_vs_all_${date}.png", replace
			
			
			
*		gr combine "$temp/totalcases_africa_fr.gph" "$temp/totalcases_europe_fr.gph" "$temp/totalcases_asia_fr.gph" , graphregion(margin(zero ))  xcommon col(3) 
		*graph export "$graphs/trend_30dayspanel.png", replace
restore 


	
		
************************** Senegal **************************	

* Stacked bar graph senegal (deaths, recovered, active, negative tests)
graph bar deaths${countrylong2}  recovered${countrylong2} active${countrylong2} negtests${countrylong2} if day_since_firstcase < `days_africa', over(day_since_firstcase) blabel(bar, size(tiny) pos(center) format(%3.0f)) stack  legend(order(1 "Morts" 2 "Guérisons" 3 "Cas Actifs" 4 "Tests Négatifs" ) ring(0) row(1) pos(10) size(large))  legend(on ring(0) cols(1) pos(10) size(vsmall)) ytitle("")  title("${countrylongfr}" , size(small) color(black)) b1title("Nombre de jours depuis le premier cas") 
graph export "$graphs/${countrylong2}_breakdown.png", replace
			
	

			
****************************************************************************************************************************************************************
* 	RUNING PREDICTION DO FILE (GRAPHING PREDICTIONS)
****************************************************************************************************************************************************************	

do "$do/predictions_200326"
