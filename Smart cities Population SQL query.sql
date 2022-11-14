--Cleaning IMD SMart Cities Index dataset

SELECT COUNT(City) as Cities, SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) Nullscount 
FROM `robotic-parsec-350412.Smart_cities.IMD` 

SELECT LENGTH(string_field_0), string_field_0
FROM `robotic-parsec-350412.Smart_cities.TotalPopulation`
WHERE string_field_0 LIKE '%Czech Republic%' OR string_field_0 LIKE "%Slovak Republic%" OR string_field_0 LIKE "%Urka%" OR string_field_0  LIKE "%Kor%"

SELECT LENGTH(Country), Country
FROM `robotic-parsec-350412.Smart_cities.IMD`
WHERE Country LIKE '%Czec%' OR Country LIKE "%Slovak%" OR Country LIKE "%Urka%" OR Country LIKE "%Kor%"

---109 Smart Cities, 266 NULLS to be removed from IMD table
---Length of some cities'names appeared to be different as well, needed to use TRIM function 
---Some countris in IMD table has spelling errors and some countries` names do not correspond to those in Urban and Total population tables. Below, checking missing values and spelling errors to align names in all tables - make change to IMD table

SELECT TP.string_field_0  
FROM `robotic-parsec-350412.Smart_cities.TotalPopulation` as TP
FULL OUTER JOIN `robotic-parsec-350412.Smart_cities.UrbanPopulation` as UP ON TP.string_field_0=UP.string_field_0
WHERE TP.string_field_0 LIKE "%mraine%" OR TP.string_field_0 LIKE "%ech%" OR TP.string_field_0 LIKE "%Tur%" OR TP.string_field_0 LIKE "%Kore%" OR TP.string_field_0 LIKE "%Isr%" OR TP.string_field_0 LIKE "%Slov%"

UPDATE `robotic-parsec-350412.Smart_cities.IMD`
SET
Country='Korea, Rep.'
WHERE Country ='South Korea'

UPDATE `robotic-parsec-350412.Smart_cities.IMD`
SET
Country='Czech Republic'
WHERE Country ='Czechia'

UPDATE `robotic-parsec-350412.Smart_cities.IMD`
SET
Country='Israel'
WHERE Country ='Isreal'

UPDATE `robotic-parsec-350412.Smart_cities.TotalPopulation`
SET 
Country='Turkey'
WHERE Country='Turkiye'

UPDATE `robotic-parsec-350412.Smart_cities.IMD`
SET Contry='Slovak Republic'
WHERE Country='Slovakia'

UPDATE `robotic-parsec-350412.Smart_cities.IMD`
SET Country='Ukraine'
WHERE Country='United Kingdomraine'

-- Basic calculations. Using 2019 data as further on will use Climate-related data to connect, so both datasets represent the same period.

SELECT City, Country, Continent, Ranking2019, 
AVG(Ranking2020) OVER (PARTITION BY Country ORDER BY Country) AS AvgCountrySCRaiting20, AVG(Ranking2019) OVER (PARTITION BY Country ORDER BY Country) AS AvgScperCountryRaining19
FROM `robotic-parsec-350412.Smart_cities.IMD` 
WHERE Ranking2019 IS NOT NULL
ORDER BY Country

--Saved this table below as a View for Tableau. Replaced missing values with 0 in Ms Excel while uploading to avoid problems with visualization.

WITH SCIsummary AS 
  (SELECT COUNT(City) AS SCNo, Country, Continent, AVG(Ranking2020) AS AvgRank2020, AVG(Ranking2019) AS AvgRank2019, SUM(Population) AS SCPopulation 
  FROM `robotic-parsec-350412.Smart_cities.IMD` AS IMD
  WHERE City IS NOT NULL 
  GROUP BY Country, Continent
  ORDER BY SCNo DESC) 

SELECT DISTINCT IMD.City, IMD.Country, IMD.Continent, IMD.Ranking2019, IMD.Ranking2020, COUNT(City) OVER (PARTITION BY IMD.Country) as NumofSC, ((SCIsummary.SCPopulation/TTLPopulation.int64_field_63)*100) AS SCvsTTLPopulation19, UrbanPopulation.double_field_61 AS UrbanPopulation19, GHG.Y19 AS GHG19,
  CASE 
  WHEN CAST(IMD.Ranking2020 as int64)<= 28 THEN 1
  WHEN CAST(IMD.Ranking2020 as int64)> 28 AND CAST(IMD.Ranking2020 as int64)< 55 THEN 2
  WHEN CAST(IMD.Ranking2020 as int64)> 55 AND CAST(IMD.Ranking2020 as int64)< 83 THEN 3
  ELSE 4
  END Category
FROM `robotic-parsec-350412.Smart_cities.IMD` AS IMD
LEFT JOIN SCIsummary ON IMD.Country=SCIsummary.Country
LEFT JOIN `robotic-parsec-350412.Smart_cities.UrbanPopulation` AS UrbanPopulation ON IMD.Country=UrbanPopulation.string_field_0
LEFT JOIN `robotic-parsec-350412.Smart_cities.TotalPopulation` AS TTLPopulation ON IMD.Country=TTLPopulation.string_field_0
WHERE City IS NOT NULL
ORDER BY IMD.Ranking2020, IMD.Ranking2019

---Check of the new table created
SELECT*
FROM `robotic-parsec-350412.Smart_cities.SCS`

--Ranging the countries with smart cities by the percent of urban population living in smart cities. 
SELECT Country, AVG(SCvsTotalPopulation) AS SCPopulationPercent, (AVG(SCvsTotalPopulation/UrbanPopulation)*100) AS SCpercentinUrbanPopulation, COUNT(City) AS NumofSmartCities, AVG(UrbanPopulation) AS UrbanPopulationPercent, 
FROM `robotic-parsec-350412.Smart_cities.SCS`
GROUP BY Country
ORDER BY SCpercentinUrbanPopulation DESC

---Insight: percent of population of smart cities vs total varies significantly when compared to the total urban population percent

--Checking if there is any insights in 4 categories in terms of smart cities/urban population patterns
SELECT Category, 
MAX(SCvsTotalPopulation) AS MaxSCPopulationPercent, MAX((SCvsTotalPopulation/UrbanPopulation)*100) AS MaxSCpercentinUrbanPopulation, MAX(UrbanPopulation) AS MaxUrbanPopulationPercent,
MIN(SCvsTotalPopulation) AS MinSCPopulationPercent, MIN((SCvsTotalPopulation/UrbanPopulation)*100) AS MinSCpercentinUrbanPopulation, MIN(UrbanPopulation) AS MinUrbanPopulationPercent, 
AVG(SCvsTotalPopulation) AS AvgnSCPopulationPercent, AVG((SCvsTotalPopulation/UrbanPopulation)*100) AS AvgSCpercentinUrbanPopulation, AVG(UrbanPopulation) AS AvgUrbanPopulationPercent,   
COUNT(City) AS NumofSmartCities
FROM `robotic-parsec-350412.Smart_cities.SCS`
GROUP BY Category
ORDER BY AvgSCpercentinUrbanPopulation DESC


---Insight: popultion in smart cities of category 1 (1-28 rank) are twice as high as smart citie's population in other categories. That's more the average, maximum and minimun percent of urban population living in smart cities of the Category 1 is the highest (~20%) compated to other categories. At the same time, average population of smart cities distributed more or less equal when compred to the countries' urban population. 

--Calculating the average Urban population percent vs urban population living in Smart cities

SELECT ROUND(AVG(SCvsTotalPopulation), 0) AS SCPopulationPercent, ROUND(AVG(UrbanPopulation), 0) AS UrbanPopulationPercent, ROUND((AVG(SCvsTotalPopulation/UrbanPopulation)*100), 0) AS SCinUrbanPopulationPercent, COUNT(City) as SCcount
FROM `robotic-parsec-350412.Smart_cities.SCS`

---Looking at the average numbers for Continents including at GHG emissions to further explore Climate issue in part 2 of the project

SELECT s.Continent, COUNT(s.City) as NumofSC, ROUND(AVG(s.Ranking2019), 1) AS AvgRank19, ROUND(AVG(s.SCvsTotalPopulation), 1) AS SCpopultation, ROUND(AVG(s.UrbanPopulation), 1) AS AvgUrbanPopulation, ROUND((AVG(SCvsTotalPopulation/UrbanPopulation)*100), 0) AS SCinUrbanPopulation, CAST(AVG(g.double_field_9) AS int64) AS ContinentAvgGHG19
FROM `robotic-parsec-350412.Smart_cities.SCS` as s
JOIN `robotic-parsec-350412.Smart_cities.GHG` as g ON s.Country=g.string_field_0
GROUP BY Continent
ORDER BY ContinentAvgGHG19 DESC





<div class='tableauPlaceholder' id='viz1658063650709' style='position: relative'><noscript><a href='#'><img alt=' ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Sm&#47;SmartCitiesprojectpart1&#47;Dashboard1&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='site_root' value='' /><param name='name' value='SmartCitiesprojectpart1&#47;Dashboard1' /><param name='tabs' value='no' /><param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Sm&#47;SmartCitiesprojectpart1&#47;Dashboard1&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /><param name='language' value='en-US' /></object></div>                <script type='text/javascript'>                    var divElement = document.getElementById('viz1658063650709');                    var vizElement = divElement.getElementsByTagName('object')[0];                    if ( divElement.offsetWidth > 800 ) { vizElement.style.width='100%';vizElement.style.height=(divElement.offsetWidth*0.75)+'px';} else if ( divElement.offsetWidth > 500 ) { vizElement.style.width='100%';vizElement.style.height=(divElement.offsetWidth*0.75)+'px';} else { vizElement.style.width='100%';vizElement.style.height='927px';}                     var scriptElement = document.createElement('script');                    scriptElement.src = 'https://public.tableau.com/javascripts/api/viz_v1.js';                    vizElement.parentNode.insertBefore(scriptElement, vizElement);                </script>
