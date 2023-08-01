###################################################################################################################
#
#	A1. SQL Analysis Assesment - Business Analysis with Structured Data Course
# 	Author: Yunsik Choung
# 	Purpose of Document: DATA Normalization And Report Descriptive Statistics for build Model
#	Business Question: Do healthier foods cost less?
#
#	Analysis Requirements
#	--------------------------
#	1. Introduce the problem and define "healthy" and "cost".
#	
#	2. Answer the business question: Do healthier foods cost less?
# 	
#	3. Provide your top three actionable insights.
#	
###################################################################################################################
USE fmban_sql_analysis;

# 1. Cleansing Data and Descriptive Analytics for Analysis. 
WITH CLEANSED AS ( # Finalizing Cleansed Data Set
SELECT	ID
			,IF(category = 'NULL', 'Snacks', category) AS category
			,subcategory
			,product
			,CASE 
				WHEN ID IN (61, 70, 71) THEN CAST(servingsizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN servingsize # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				ELSE caloriesperserving 
				END AS caloriesperserving
			,CASE -- cleanse total weight
				WHEN id IN (26) THEN servingsize
				WHEN ID IN (87, 90, 92) THEN CAST(servingsizeunits AS DOUBLE)
				WHEN totalsizeunits IN ('oz', 'ml') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits = 'lb' AND servingsizeunits = 'oz' THEN servingsize * 28.35
				WHEN servingsizeunits = 'lb' THEN servingsize * 453.6
				WHEN totalsizeunits IN ('oz', 'fl oz') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits IN ('oz', 'fl oz') THEN servingsize * 28.35
				WHEN servingsizeunits = 'ml' THEN servingsize
				WHEN servingsizeunits = 'g' THEN servingsize
				WHEN servingsizeunits = 'grams' THEN servingsize
				WHEN totalsizeunits = 'unit' THEN servingsize
				WHEN category = 'Wine' AND totalsizeunits = 'NULL' THEN 5 * 28.35 # American standard size of 1 glass of wine
				WHEN category = 'Beer' AND totalsizeunits = 'NULL' THEN servingsize * 28.35
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' THEN servingsize
				WHEN servingsizeunits = 'oz' THEN servingsize * 28.35
				END AS  UNIFIED_SERVINGSIZE
			,CASE 
				WHEN ID IN (61, 70, 71) THEN servingsize # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN caloriesperserving # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN ID = 178 THEN ROUND(price / 100, 0) # 1 Frozen Foods for 599$ is weird. Convert to divide 100.
				WHEN category IN ('NULL', 'Beer', 'Wine') THEN ROUND(price * 100, 0) # This category has Doller data. Convert to Cent.
				ELSE price 
				END AS price
			,CASE
				WHEN ID = 3 THEN 28.35 * 3 # I Assume that 1 bunch = 3 oz
				WHEN totalsizeunits = 'lb' THEN totalsize * 453.6 # totalsizeunits has lb then multiply 453.6 USDA Formula
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both ml and g then use gram
				WHEN totalsizeunits = 'NULL' AND secondarysizeunits = 'grams' THEN totalsecondarysize # only use grams
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only have oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both l oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only gave fl oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'lt' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both lt and g then use gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize = totalsecondarysize THEN totalsecondarysize # Correct size data
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize > totalsecondarysize THEN totalsize # Something wrong in totalsecondarysize then use totalsize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize < totalsecondarysize THEN totalsecondarysize # Something wrong in totalsize then use totalsecondarysize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = '' THEN totalsize # only have ml. assume that 1 ml = 1 gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram.
				WHEN totalsizeunits = 'g' AND secondarysizeunits = '' THEN totalsize # only have gram.
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' AND secondarysizeunits = 'NULL' THEN totalsize # Snacks category doesn't give information for units. Assume that gram.
				WHEN category = 'Beer' THEN totalsize * servingsize * 28.35 # Assume that beer's unit is number of can. Then Beer can multiply serving size.
				WHEN category = 'Wine' THEN totalsize * 750 # Assume that wine's unit is number of bottle. Most wine bottle has 750ml.
				WHEN ID IN (61, 70, 71) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN totalsizeunits = 'unit' THEN NULL # I can't convert unit to gram. 
				END AS UNIFIED_SIZE
			,CASE 
				WHEN totalsizeunits IN ('ml', 'fl oz', 'lt') OR category IN ('Beer', 'Wine', 'Beverages') THEN 1 
				WHEN subcategory LIKE '%Ice cream%' THEN 1
				ELSE 0 END AS LIQUID_YN
			,CASE WHEN ID IN (87, 90, 92) THEN glutenfree ELSE vegan END AS vegan
			,CASE WHEN ID IN (87, 90, 92) THEN ketofriendly ELSE glutenfree END AS glutenfree
			,CASE WHEN ID IN (87, 90, 92) THEN vegetarian ELSE ketofriendly END AS ketofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN organic ELSE vegetarian END AS vegetarian
			,CASE WHEN ID IN (87, 90, 92) THEN dairyfree ELSE organic END AS organic
			,CASE WHEN ID IN (87, 90, 92) THEN sugarconscious ELSE dairyfree END AS dairyfree
			,CASE WHEN ID IN (87, 90, 92) THEN paleofriendly ELSE sugarconscious END AS sugarconscious
			,CASE WHEN ID IN (87, 90, 92) THEN wholefoodsdiet ELSE paleofriendly END AS paleofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN lowsodium ELSE wholefoodsdiet END AS wholefoodsdiet
			,CASE WHEN ID IN (87, 90, 92) THEN kosher ELSE lowsodium END AS lowsodium
			,CASE WHEN ID IN (87, 90, 92) THEN lowfat ELSE kosher END AS kosher
			,CASE WHEN ID IN (87, 90, 92) THEN ENGINE2 ELSE lowfat END AS lowfat
			,CASE WHEN ID IN (87, 90, 92) THEN price ELSE ENGINE2 END AS ENGINE2
			# Converting Each categories to Dummy Variables for analyzing Correlations and building Linear Model.
			,IF(category = 'Produce', 1, 0) AS PRODUCE 
			,IF(category = 'Dairy and Eggs', 1, 0) AS DAIRY_AND_EGGS
			,IF(category = 'Meat', 1, 0) AS MEAT
			,IF(category = 'Prepared Foods', 1, 0) AS PREPARED_FOODS
			,IF(category = 'Bread Rolls & Bakery', 1, 0) AS BREAD_AND_BAKERY
			,IF(category = 'Desserts', 1, 0) AS DESSERTS
			,IF(category = 'supplements', 1, 0) AS SUPPLEMENTS
			,IF(category = 'Frozen Foods', 1, 0) AS FROZEN_FOODS
			,IF(category = 'Beverages', 1, 0) AS BEVERAGES
			,IF(category = 'NULL', 1, 0) AS SNACKS_AND_CHIPS
			,IF(category = 'Beer', 1, 0) AS BEER
			,IF(category = 'Wine', 1, 0) AS WINE
  FROM	fmban_data
), RAW_DATA AS ( # Finalyzing Raw Dataset for Analysis
	SELECT	ID
				,category
				,subcategory
				,product
				,price / UNIFIED_SIZE * 453.6 AS UNIT_PRICE_CENT
				,UNIFIED_SIZE # Big packages then less cost. Common sense.
				,caloriesperserving / UNIFIED_SERVINGSIZE * 453.6 AS CALORY_PER_LB
				,caloriesperserving
				,UNIFIED_SERVINGSIZE
				,LIQUID_YN # Liquid product = 1 | Solid Product = 0
				,organic # USDA Organic 
				,lowfat # USHHS Suggestion
				,lowsodium # USHHS Suggestion
				,sugarconscious # USHHS Suggestion
				,glutenfree # USHHS Suggestion
				,PRODUCE 
				,DAIRY_AND_EGGS
				,MEAT
				,PREPARED_FOODS
				,BREAD_AND_BAKERY
				,DESSERTS
				,FROZEN_FOODS
				,BEVERAGES
				,SNACKS_AND_CHIPS
	  FROM	CLEANSED
	 WHERE	category NOT IN ('supplements') # Supplements are not food
	 			AND ID NOT IN (10) # Morel Mushroos are too expensive, Outlier. 
	 			AND UNIFIED_SERVINGSIZE IS NOT NULL # Unified servingsize NULL means that it has not servingsize information
	 			AND category NOT IN ('Beer', 'Wine') # Alchols are not healthy and not suggested by USHHS
)
# Descriptive Statistics in RAW DATA
SELECT	category
			,COUNT(id) AS N
			,ROUND(COUNT(id) * 100 / (SELECT COUNT(*) FROM RAW_DATA), 3) AS `PORTION(%)`
			,ROUND(AVG(UNIT_PRICE_CENT), 3) AS UNIT_PRICE_CENT_MEAN # PRICE PER LB IS FROM PCI REPORT
			,ROUND(AVG(UNIFIED_SIZE), 3) AS UNIFIED_SIZE_MEAN # MORE WEIGHT MAKES LESS COST 
			,ROUND(AVG(CALORY_PER_LB), 3) AS CALORY_PER_LB_MEAN # TOTAL CALORIES PER LB
			,ROUND(AVG(caloriesperserving), 3) AS CALORIES_PER_SERVING_MEAN # CALORIES PER SERVING
			,ROUND(AVG(`LIQUID_YN`), 3) AS LIQUID_YN # 1 = LIQUID PRODUCT | 0 = SOLID PRODUCT
			,ROUND(AVG(`glutenfree`), 3) AS GLUTENFREE
			,ROUND(AVG(`organic`), 3) AS ORGANIC
			,ROUND(AVG(`sugarconscious`), 3) AS SUGARCONSCIOUS
			,ROUND(AVG(`lowsodium`), 3) AS LOWSODIUM
			,ROUND(AVG(`lowfat`), 3) AS LOWFAT
  FROM	RAW_DATA
 GROUP
 	 BY	category
UNION
SELECT	'Total' 
			,COUNT(id) AS N
			,ROUND(COUNT(id) * 100 / (SELECT COUNT(*) FROM RAW_DATA), 3) AS `PORTION(%)`
			,ROUND(AVG(UNIT_PRICE_CENT), 3) AS UNIT_PRICE_CENT_MEAN # PRICE PER LB IS FROM PCI REPORT
			,ROUND(AVG(UNIFIED_SIZE), 3) AS UNIFIED_SIZE_MEAN # MORE WEIGHT MAKES LESS COST 
			,ROUND(AVG(CALORY_PER_LB), 3) AS CALORY_PER_LB_MEAN # TOTAL CALORIES PER LB
			,ROUND(AVG(caloriesperserving), 3) AS CALORIES_PER_SERVING_MEAN # CALORIES PER SERVING
			,ROUND(AVG(`LIQUID_YN`), 3) AS LIQUID_YN # 1 = LIQUID PRODUCT | 0 = SOLID PRODUCT
			,ROUND(AVG(`glutenfree`), 3) AS GLUTENFREE
			,ROUND(AVG(`organic`), 3) AS ORGANIC
			,ROUND(AVG(`sugarconscious`), 3) AS SUGARCONSCIOUS
			,ROUND(AVG(`lowsodium`), 3) AS LOWSODIUM
			,ROUND(AVG(`lowfat`), 3) AS LOWFAT
  FROM	RAW_DATA;
 	 
 	 
# BASE TABLE 
WITH CLEANSED AS ( # Finalizing Cleansed Data Set
SELECT	ID
			,IF(category = 'NULL', 'Snacks', category) AS category
			,subcategory
			,product
			,CASE 
				WHEN ID IN (61, 70, 71) THEN CAST(servingsizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN servingsize # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				ELSE caloriesperserving 
				END AS caloriesperserving
			,CASE -- cleanse total weight
				WHEN id IN (26) THEN servingsize
				WHEN ID IN (87, 90, 92) THEN CAST(servingsizeunits AS DOUBLE)
				WHEN totalsizeunits IN ('oz', 'ml') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits = 'lb' AND servingsizeunits = 'oz' THEN servingsize * 28.35
				WHEN servingsizeunits = 'lb' THEN servingsize * 453.6
				WHEN totalsizeunits IN ('oz', 'fl oz') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits IN ('oz', 'fl oz') THEN servingsize * 28.35
				WHEN servingsizeunits = 'ml' THEN servingsize
				WHEN servingsizeunits = 'g' THEN servingsize
				WHEN servingsizeunits = 'grams' THEN servingsize
				WHEN totalsizeunits = 'unit' THEN servingsize
				WHEN category = 'Wine' AND totalsizeunits = 'NULL' THEN 5 * 28.35 # American standard size of 1 glass of wine
				WHEN category = 'Beer' AND totalsizeunits = 'NULL' THEN servingsize * 28.35
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' THEN servingsize
				WHEN servingsizeunits = 'oz' THEN servingsize * 28.35
				END AS  UNIFIED_SERVINGSIZE
			,CASE 
				WHEN ID IN (61, 70, 71) THEN servingsize # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN caloriesperserving # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN ID = 178 THEN ROUND(price / 100, 0) # 1 Frozen Foods for 599$ is weird. Convert to divide 100.
				WHEN category IN ('NULL', 'Beer', 'Wine') THEN ROUND(price * 100, 0) # This category has Doller data. Convert to Cent.
				ELSE price 
				END AS price
			,CASE
				WHEN ID = 3 THEN 28.35 * 3 # I Assume that 1 bunch = 3 oz
				WHEN totalsizeunits = 'lb' THEN totalsize * 453.6 # totalsizeunits has lb then multiply 453.6 USDA Formula
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both ml and g then use gram
				WHEN totalsizeunits = 'NULL' AND secondarysizeunits = 'grams' THEN totalsecondarysize # only use grams
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only have oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both l oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only gave fl oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'lt' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both lt and g then use gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize = totalsecondarysize THEN totalsecondarysize # Correct size data
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize > totalsecondarysize THEN totalsize # Something wrong in totalsecondarysize then use totalsize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize < totalsecondarysize THEN totalsecondarysize # Something wrong in totalsize then use totalsecondarysize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = '' THEN totalsize # only have ml. assume that 1 ml = 1 gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram.
				WHEN totalsizeunits = 'g' AND secondarysizeunits = '' THEN totalsize # only have gram.
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' AND secondarysizeunits = 'NULL' THEN totalsize # Snacks category doesn't give information for units. Assume that gram.
				WHEN category = 'Beer' THEN totalsize * servingsize * 28.35 # Assume that beer's unit is number of can. Then Beer can multiply serving size.
				WHEN category = 'Wine' THEN totalsize * 750 # Assume that wine's unit is number of bottle. Most wine bottle has 750ml.
				WHEN ID IN (61, 70, 71) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN totalsizeunits = 'unit' THEN NULL # I can't convert unit to gram. 
				END AS UNIFIED_SIZE
			,CASE 
				WHEN totalsizeunits IN ('ml', 'fl oz', 'lt') OR category IN ('Beer', 'Wine', 'Beverages') THEN 1 
				WHEN subcategory LIKE '%Ice cream%' THEN 1
				ELSE 0 END AS LIQUID_YN
			,CASE WHEN ID IN (87, 90, 92) THEN glutenfree ELSE vegan END AS vegan
			,CASE WHEN ID IN (87, 90, 92) THEN ketofriendly ELSE glutenfree END AS glutenfree
			,CASE WHEN ID IN (87, 90, 92) THEN vegetarian ELSE ketofriendly END AS ketofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN organic ELSE vegetarian END AS vegetarian
			,CASE WHEN ID IN (87, 90, 92) THEN dairyfree ELSE organic END AS organic
			,CASE WHEN ID IN (87, 90, 92) THEN sugarconscious ELSE dairyfree END AS dairyfree
			,CASE WHEN ID IN (87, 90, 92) THEN paleofriendly ELSE sugarconscious END AS sugarconscious
			,CASE WHEN ID IN (87, 90, 92) THEN wholefoodsdiet ELSE paleofriendly END AS paleofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN lowsodium ELSE wholefoodsdiet END AS wholefoodsdiet
			,CASE WHEN ID IN (87, 90, 92) THEN kosher ELSE lowsodium END AS lowsodium
			,CASE WHEN ID IN (87, 90, 92) THEN lowfat ELSE kosher END AS kosher
			,CASE WHEN ID IN (87, 90, 92) THEN ENGINE2 ELSE lowfat END AS lowfat
			,CASE WHEN ID IN (87, 90, 92) THEN price ELSE ENGINE2 END AS ENGINE2
			# Converting Each categories to Dummy Variables for analyzing Correlations and building Linear Model.
			,IF(category = 'Produce', 1, 0) AS PRODUCE 
			,IF(category = 'Dairy and Eggs', 1, 0) AS DAIRY_AND_EGGS
			,IF(category = 'Meat', 1, 0) AS MEAT
			,IF(category = 'Prepared Foods', 1, 0) AS PREPARED_FOODS
			,IF(category = 'Bread Rolls & Bakery', 1, 0) AS BREAD_AND_BAKERY
			,IF(category = 'Desserts', 1, 0) AS DESSERTS
			,IF(category = 'supplements', 1, 0) AS SUPPLEMENTS
			,IF(category = 'Frozen Foods', 1, 0) AS FROZEN_FOODS
			,IF(category = 'Beverages', 1, 0) AS BEVERAGES
			,IF(category = 'NULL', 1, 0) AS SNACKS_AND_CHIPS
			,IF(category = 'Beer', 1, 0) AS BEER
			,IF(category = 'Wine', 1, 0) AS WINE
  FROM	fmban_data
), RAW_DATA AS ( # Finalyzing Raw Dataset for Analysis
	SELECT	ID
				,category
				,subcategory
				,product
				,price / UNIFIED_SIZE * 453.6 AS UNIT_PRICE_CENT
				,UNIFIED_SIZE # Big packages then less cost. Common sense.
				,caloriesperserving / UNIFIED_SERVINGSIZE * 453.6 AS CALORY_PER_LB
				,caloriesperserving
				,UNIFIED_SERVINGSIZE
				,LIQUID_YN # Liquid product = 1 | Solid Product = 0
				,organic # USDA Organic 
				,lowfat # USHHS Suggestion
				,lowsodium # USHHS Suggestion
				,sugarconscious # USHHS Suggestion
				,glutenfree # USHHS Suggestion
				,PRODUCE 
				,DAIRY_AND_EGGS
				,MEAT
				,PREPARED_FOODS
				,BREAD_AND_BAKERY
				,DESSERTS
				,FROZEN_FOODS
				,BEVERAGES
				,SNACKS_AND_CHIPS
	  FROM	CLEANSED
	 WHERE	category NOT IN ('supplements') # Supplements are not food
	 			AND ID NOT IN (10) # Morel Mushroos are too expensive, Outlier. 
	 			AND UNIFIED_SERVINGSIZE IS NOT NULL # Unified servingsize NULL means that it has not servingsize information
	 			AND category NOT IN ('Beer', 'Wine') # Alchols are not healthy and not suggested by USHHS
)
###################################################################################################
# Calculating Correlation between Unit price and each variable.
# ---------------------------------------------------------------------------
SELECT	*
			,CASE 
				WHEN ABS(`t_Value`) > 1.984 THEN 'p < .05' 
				WHEN ABS(`t_Value`) > 1.660 THEN 'p < .10' 
				ELSE '' END AS `Significant Score`
  FROM	(
			SELECT	'Unit Price Cent' AS Price
						,'UNIFIED_SIZE' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * UNIFIED_SIZE) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(UNIFIED_SIZE) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(UNIFIED_SIZE))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'CALORY_PER_LB' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * CALORY_PER_LB) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(CALORY_PER_LB) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(CALORY_PER_LB))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'caloriesperserving' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * caloriesperserving) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(caloriesperserving) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(caloriesperserving))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'organic' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * organic) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(organic) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(organic))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'lowfat' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * lowfat) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(lowfat) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(lowfat))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'lowsodium' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * lowsodium) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(lowsodium) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(lowsodium))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'sugarconscious' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * sugarconscious) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(sugarconscious) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(sugarconscious))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			UNION
			SELECT	'Unit Price Cent' AS Price
						,'glutenfree' AS Factors
						,ROUND(r, 3) AS Coefficient
						,N - 2 AS df
						,ROUND((r * SQRT(N - 2)) / (SQRT(1 - POWER(r, 2))), 3) AS t_Value -- Compare t_value in t-table df = N - 2
			  FROM	(
						SELECT	ROUND(( -- COVARIANCE
										(SUM(UNIT_PRICE_CENT * glutenfree) -- 
											/ (SELECT COUNT(*) - 1 FROM RAW_DATA)
										)
									 	- 
										(
											(SELECT SUM(UNIT_PRICE_CENT) 
												/ (COUNT(*)) FROM RAW_DATA) 
											*
											(SELECT SUM(glutenfree) 
											/ (COUNT(*) - 1) FROM RAW_DATA)
										)
									)
									/ SQRT( # VARIANCE MULTIPLE
										(VAR_SAMP(UNIT_PRICE_CENT) * VAR_SAMP(glutenfree))
									), 5) AS r
									,COUNT(*) AS N
						  FROM	RAW_DATA
						) AS BASE
			) AS CORR_TABLE
;

# BASE TABLE For Mean Comparison Analysis
WITH CLEANSED AS ( # Finalizing Cleansed Data Set
SELECT	ID
			,IF(category = 'NULL', 'Snacks', category) AS category
			,subcategory
			,product
			,CASE 
				WHEN ID IN (61, 70, 71) THEN CAST(servingsizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN servingsize # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				ELSE caloriesperserving 
				END AS caloriesperserving
			,CASE -- cleanse total weight
				WHEN id IN (26) THEN servingsize
				WHEN ID IN (87, 90, 92) THEN CAST(servingsizeunits AS DOUBLE)
				WHEN totalsizeunits IN ('oz', 'ml') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits = 'lb' AND servingsizeunits = 'oz' THEN servingsize * 28.35
				WHEN servingsizeunits = 'lb' THEN servingsize * 453.6
				WHEN totalsizeunits IN ('oz', 'fl oz') AND servingsizeunits = 'g' THEN servingsize
				WHEN totalsizeunits IN ('oz', 'fl oz') THEN servingsize * 28.35
				WHEN servingsizeunits = 'ml' THEN servingsize
				WHEN servingsizeunits = 'g' THEN servingsize
				WHEN servingsizeunits = 'grams' THEN servingsize
				WHEN totalsizeunits = 'unit' THEN servingsize
				WHEN category = 'Wine' AND totalsizeunits = 'NULL' THEN 5 * 28.35 # American standard size of 1 glass of wine
				WHEN category = 'Beer' AND totalsizeunits = 'NULL' THEN servingsize * 28.35
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' THEN servingsize
				WHEN servingsizeunits = 'oz' THEN servingsize * 28.35
				END AS  UNIFIED_SERVINGSIZE
			,CASE 
				WHEN ID IN (61, 70, 71) THEN servingsize # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN caloriesperserving # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN ID = 178 THEN ROUND(price / 100, 0) # 1 Frozen Foods for 599$ is weird. Convert to divide 100.
				WHEN category IN ('NULL', 'Beer', 'Wine') THEN ROUND(price * 100, 0) # This category has Doller data. Convert to Cent.
				ELSE price 
				END AS price
			,CASE
				WHEN ID = 3 THEN 28.35 * 3 # I Assume that 1 bunch = 3 oz
				WHEN totalsizeunits = 'lb' THEN totalsize * 453.6 # totalsizeunits has lb then multiply 453.6 USDA Formula
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both ml and g then use gram
				WHEN totalsizeunits = 'NULL' AND secondarysizeunits = 'grams' THEN totalsecondarysize # only use grams
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only have oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'g' THEN totalsize * 28.35 # have both l oz and grmas then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'fl oz' AND secondarysizeunits = 'NULL' THEN totalsize * 28.35 # Only gave fl oz then oz multiply 28.35 USDA formula
				WHEN totalsizeunits = 'lt' AND secondarysizeunits = 'g' THEN totalsecondarysize # have both lt and g then use gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize = totalsecondarysize THEN totalsecondarysize # Correct size data
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize > totalsecondarysize THEN totalsize # Something wrong in totalsecondarysize then use totalsize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'g' 
					AND totalsize < totalsecondarysize THEN totalsecondarysize # Something wrong in totalsize then use totalsecondarysize
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram
				WHEN totalsizeunits = 'ml' AND secondarysizeunits = '' THEN totalsize # only have ml. assume that 1 ml = 1 gram
				WHEN totalsizeunits = 'g' AND secondarysizeunits = 'NULL' THEN totalsize # only have gram.
				WHEN totalsizeunits = 'g' AND secondarysizeunits = '' THEN totalsize # only have gram.
				WHEN category = 'NULL' AND totalsizeunits = 'NULL' AND secondarysizeunits = 'NULL' THEN totalsize # Snacks category doesn't give information for units. Assume that gram.
				WHEN category = 'Beer' THEN totalsize * servingsize * 28.35 # Assume that beer's unit is number of can. Then Beer can multiply serving size.
				WHEN category = 'Wine' THEN totalsize * 750 # Assume that wine's unit is number of bottle. Most wine bottle has 750ml.
				WHEN ID IN (61, 70, 71) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 2 columns after price column.
				WHEN ID IN (87, 90, 92) THEN CAST(secondarysizeunits AS DOUBLE) # This data are weird. but I assume that it pushed right 1 columns after vegan column.
				WHEN totalsizeunits = 'unit' THEN NULL # I can't convert unit to gram. 
				END AS UNIFIED_SIZE
			,CASE 
				WHEN totalsizeunits IN ('ml', 'fl oz', 'lt') OR category IN ('Beer', 'Wine', 'Beverages') THEN 1 
				WHEN subcategory LIKE '%Ice cream%' THEN 1
				ELSE 0 END AS LIQUID_YN
			,CASE WHEN ID IN (87, 90, 92) THEN glutenfree ELSE vegan END AS vegan
			,CASE WHEN ID IN (87, 90, 92) THEN ketofriendly ELSE glutenfree END AS glutenfree
			,CASE WHEN ID IN (87, 90, 92) THEN vegetarian ELSE ketofriendly END AS ketofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN organic ELSE vegetarian END AS vegetarian
			,CASE WHEN ID IN (87, 90, 92) THEN dairyfree ELSE organic END AS organic
			,CASE WHEN ID IN (87, 90, 92) THEN sugarconscious ELSE dairyfree END AS dairyfree
			,CASE WHEN ID IN (87, 90, 92) THEN paleofriendly ELSE sugarconscious END AS sugarconscious
			,CASE WHEN ID IN (87, 90, 92) THEN wholefoodsdiet ELSE paleofriendly END AS paleofriendly
			,CASE WHEN ID IN (87, 90, 92) THEN lowsodium ELSE wholefoodsdiet END AS wholefoodsdiet
			,CASE WHEN ID IN (87, 90, 92) THEN kosher ELSE lowsodium END AS lowsodium
			,CASE WHEN ID IN (87, 90, 92) THEN lowfat ELSE kosher END AS kosher
			,CASE WHEN ID IN (87, 90, 92) THEN ENGINE2 ELSE lowfat END AS lowfat
			,CASE WHEN ID IN (87, 90, 92) THEN price ELSE ENGINE2 END AS ENGINE2
			# Converting Each categories to Dummy Variables for analyzing Correlations and building Linear Model.
			,IF(category = 'Produce', 1, 0) AS PRODUCE 
			,IF(category = 'Dairy and Eggs', 1, 0) AS DAIRY_AND_EGGS
			,IF(category = 'Meat', 1, 0) AS MEAT
			,IF(category = 'Prepared Foods', 1, 0) AS PREPARED_FOODS
			,IF(category = 'Bread Rolls & Bakery', 1, 0) AS BREAD_AND_BAKERY
			,IF(category = 'Desserts', 1, 0) AS DESSERTS
			,IF(category = 'supplements', 1, 0) AS SUPPLEMENTS
			,IF(category = 'Frozen Foods', 1, 0) AS FROZEN_FOODS
			,IF(category = 'Beverages', 1, 0) AS BEVERAGES
			,IF(category = 'NULL', 1, 0) AS SNACKS_AND_CHIPS
			,IF(category = 'Beer', 1, 0) AS BEER
			,IF(category = 'Wine', 1, 0) AS WINE
  FROM	fmban_data
), RAW_DATA AS ( # Finalyzing Raw Dataset for Analysis
	SELECT	ID
				,category
				,subcategory
				,product
				,price / UNIFIED_SIZE * 453.6 AS UNIT_PRICE_CENT
				,UNIFIED_SIZE # Big packages then less cost. Common sense.
				,caloriesperserving / UNIFIED_SERVINGSIZE * 453.6 AS CALORY_PER_LB
				,caloriesperserving
				,UNIFIED_SERVINGSIZE
				,LIQUID_YN # Liquid product = 1 | Solid Product = 0
				,organic # USDA Organic 
				,lowfat # USHHS Suggestion
				,lowsodium # USHHS Suggestion
				,sugarconscious # USHHS Suggestion
				,glutenfree # USHHS Suggestion
				,PRODUCE 
				,DAIRY_AND_EGGS
				,MEAT
				,PREPARED_FOODS
				,BREAD_AND_BAKERY
				,DESSERTS
				,FROZEN_FOODS
				,BEVERAGES
				,SNACKS_AND_CHIPS
				,CASE WHEN caloriesperserving > 
					(SELECT	AVG(caloriesperserving)  # MEDIAN OF CALORIES PER SERVING
					  FROM	(SELECT	PERCENT_RANK() OVER(ORDER BY caloriesperserving) AS PEC,caloriesperserving
								  FROM	CLEANSED) AS MM
					 WHERE	PEC BETWEEN 0.49 AND 0.51 LIMIT 1) 
					 THEN 1 # OVER MEDIAN CALORIES PER SERVING
					 ELSE 0 # UNDER MEDIAN CALORIES PER SERVING
					 END AS CALORY_GROUP
				,CASE WHEN UNIFIED_SIZE > 
					(SELECT	AVG(UNIFIED_SIZE) # MEDIAN OF UNIFIED SIZE
					  FROM	(SELECT	PERCENT_RANK() OVER(ORDER BY UNIFIED_SIZE) AS PEC,UNIFIED_SIZE
								  FROM	CLEANSED) AS MM
					 WHERE	PEC BETWEEN 0.49 AND 0.51 LIMIT 1) 
					 THEN 1 # OVER MEDIAN UNIFIED SIZE 
					 ELSE 0 # UNDER MEDIAN UNIFIED SIZE
					 END AS UNIFIED_SIZE_GROUP
	  FROM	CLEANSED
	 WHERE	category NOT IN ('supplements') # Supplements are not food
	 			AND ID NOT IN (10) # Morel Mushroos are too expensive, Outlier. 
	 			AND UNIFIED_SERVINGSIZE IS NOT NULL # Unified servingsize NULL means that it has not servingsize information
	 			AND category NOT IN ('Beer', 'Wine') # Alchols are not healthy and not suggested by USHHS
)
###################################################################################################
#	Mean Comparison Analysis for each Healthy Factors.
#  T-Test 
#		- t > 1.984 in DF 100 THEN p-value < 0.05 
#		- t > 1.660 in DF 100 THEN p-value < 0.10
# 	
###################################################################################################
SELECT	Factors # Each Factors 
			,Category # Group Number 1, 0 
			,N # Number of observation
			,MEAN_PRICE # Mean Price of each group's
			,CASE WHEN Category = 1 THEN GAP ELSE '' END AS GAP # Difference between two groups
			,CASE WHEN Category = 1 THEN `T-Value` ELSE '' END AS `T-Value` # T statistics
			,CASE 
				WHEN Category = 1 AND ABS(`T-Value`) > 1.984 THEN 'p < .05' 
				WHEN Category = 1 AND ABS(`T-Value`) > 1.660 THEN 'p < .10' 
				ELSE '' END AS `Significant Score` # Signifficant Test
  FROM	( 
			SELECT	'Organic' AS Factors
						,organic AS Category
						,COUNT(*) AS N
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE organic = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE organic = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE organic WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE organic WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE organic WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE organic WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE organic WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE organic WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	organic
			UNION
			SELECT	'Sugarconscious'
						,sugarconscious
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE sugarconscious = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE sugarconscious = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE sugarconscious WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE sugarconscious WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE sugarconscious WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE sugarconscious WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE sugarconscious WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE sugarconscious WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	sugarconscious
			UNION
			SELECT	'Low Fat'
						,lowfat
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE lowfat = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE lowfat = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE lowfat WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE lowfat WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE lowfat WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE lowfat WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE lowfat WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE lowfat WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	lowfat
			UNION
			SELECT	'Gluten Free'
						,glutenfree
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE glutenfree = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE glutenfree = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE glutenfree WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE glutenfree WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE glutenfree WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE glutenfree WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE glutenfree WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE glutenfree WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	glutenfree
			UNION
			SELECT	'Low Sodium'
						,lowsodium
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE lowsodium = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE lowsodium = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE lowsodium WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE lowsodium WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE lowsodium WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE lowsodium WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE lowsodium WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE lowsodium WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	lowsodium
			UNION
			SELECT	'CALORY_GROUP'
						,CALORY_GROUP
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE CALORY_GROUP = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE CALORY_GROUP = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE CALORY_GROUP WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE CALORY_GROUP WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE CALORY_GROUP WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE CALORY_GROUP WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE CALORY_GROUP WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_AVG
												,AVG(CASE CALORY_GROUP WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	CALORY_GROUP
			UNION
			SELECT	'UNIFIED_SIZE_GROUP'
						,UNIFIED_SIZE_GROUP
						,COUNT(*)
						,ROUND(AVG(UNIT_PRICE_CENT), 3) AS MEAN_PRICE
						,ROUND((SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE UNIFIED_SIZE_GROUP = 1) - (SELECT AVG(UNIT_PRICE_CENT) FROM RAW_DATA WHERE UNIFIED_SIZE_GROUP = 0), 3) AS GAP
						,ROUND((SELECT	(H1_AVG - H2_AVG)/(
										SQRT(((H1_N * H1_VAR^2 + H2_N * H2_VAR)/ (H1_N + H2_N - 2)) * 
											((H1_N + H2_N)/(H1_N * H2_N)))
									) AS t_Value
						  FROM	(
									SELECT	SUM(CASE UNIFIED_SIZE_GROUP WHEN 1 THEN 1 END) AS H1_N
												,SUM(CASE UNIFIED_SIZE_GROUP WHEN 0 THEN 1 END) AS H2_N
												,VARIANCE(CASE UNIFIED_SIZE_GROUP WHEN 1 THEN UNIT_PRICE_CENT END) AS H1_VAR
												,VARIANCE(CASE UNIFIED_SIZE_GROUP WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_VAR
												,AVG(CASE UNIFIED_SIZE_GROUP WHEN 1 THEN UNIT_PRICE_CENT END)
												
												 AS H1_AVG
												,AVG(CASE UNIFIED_SIZE_GROUP WHEN 0 THEN UNIT_PRICE_CENT END) AS H2_AVG
												
									  FROM	RAW_DATA
									) AS tTest), 3) AS `T-Value`
			  FROM	RAW_DATA 
			 GROUP
				 BY	UNIFIED_SIZE_GROUP
			 ORDER
			 	 BY	1, 2 DESC
			) AS FAN;

/* ----------------------------------------------------------------------------------------------
#	Multiple Regression Model
# 'Price per LB(Y) = Intercept 
							+ UNIFIED_SIZE(Numeric) + PRODUCE(Dummy) + DAIRY_AND_EGGS(Dummy) + MEAT(Dummy) + PREPARED_FOODS(Dummy)
							+ BREAD_AND_BAKERY(Dummy) + DESSERTS(Dummy) + FROZEN_FOODS(Dummy) + SNACKS_AND_CHIPS(Dummy)
							+ caloriesperserving(Numeric) 
							+ organic(Binominal) + lowfat(Binominal) + lowsodium(Binominal) + sugarconscious(Binominal) + glutenfree(Binominal)
							+ e
--------------------------------------------------------------------------------------------------------------------------------------- */
SELECT 'Regression Statistics' AS `Regression Summary`, '', '', '', '', '', '', '', '' 
UNION ALL
SELECT 'Multiple R', 			FORMAT(0.526847768149592, 3), '', '', '', '', '', '', '' 
UNION ALL
SELECT 'R Square', 				FORMAT(0.277568570804207, 3), '', '', '', '', '', '', '' 
UNION ALL
SELECT 'Adjusted R Square', 	FORMAT(0.225218467239294, 3), '', '', '', '', '', '', '' 
UNION ALL
SELECT 'Standard Error', 		FORMAT(1189.22414755254, 3), '', '', '', '', '', '', '' 
UNION ALL
SELECT 'Observations', 			FORMAT(223, 3), '', '', '', '', '', '', '' 
UNION ALL
SELECT '----------------------', '------------', '', '', '', '', '', '', '' 
UNION ALL
SELECT 'ANOVA', '', '', '', '', '', '', '', '' 
UNION ALL
SELECT '', 'df', 'SS', 'MS', 'F', 'Significance F', '', '', '' 
UNION ALL
SELECT 'Regression', 	FORMAT(15, 3),  FORMAT(112478998.635723, 3), FORMAT(7498599.90904821, 3), FORMAT(5.30215896249432, 3), FORMAT(5.84319496873729E-09, 3), '', '', '' 
UNION ALL
SELECT 'Residual', 		FORMAT(207, 3), FORMAT(292750593.136266, 3), FORMAT(1414254.07312206, 3), '', '', '', '', '' 
UNION ALL
SELECT 'Total', 			FORMAT(222, 3), FORMAT(405229591.771989, 3), '', '', '', '', '', '' 
UNION ALL
SELECT '----------------------', '------------', '------------', '-----------', '------------', '------------', '------------', '------------', '------------' 
UNION ALL
SELECT '', 'Coefficients', 'Standard Error', 't Stat', 'P-value', 'Lower 95%', 'Upper 95%', 'Lower 95.0%', 'Upper 95.0%' 
UNION ALL
SELECT 'Intercept', 				FORMAT(2943.94038669362, 3), FORMAT(341.631115959015, 3), FORMAT(8.61730752607091, 3), FORMAT(1.76837919683809E-15, 3), FORMAT(2270.41792401751, 3), FORMAT(3617.46284936974, 3), FORMAT(2270.41792401751, 3), FORMAT(3617.46284936974, 3) 
UNION ALL
SELECT 'UNIFIED_SIZE', 			FORMAT(-0.868150330494532, 3), FORMAT(0.161985984016725, 3), FORMAT(-5.35941634558268, 3), FORMAT(2.21770817899704E-07, 3), FORMAT(-1.18750414160068, 3), FORMAT(-0.548796519388382, 3), FORMAT(-1.18750414160068, 3), FORMAT(-0.548796519388382, 3) 
UNION ALL
SELECT 'PRODUCE', 				FORMAT(-552.140306489678, 3), FORMAT(431.369289062721, 3), FORMAT(-1.27997129255392, 3), FORMAT(0.201987827300545, 3), FORMAT(-1402.58071522348, 3), FORMAT(298.300102244122, 3), FORMAT(-1402.58071522348, 3), FORMAT(298.300102244122, 3) 
UNION ALL
SELECT 'DAIRY_AND_EGGS', 		FORMAT(-1128.23904023797, 3), FORMAT(352.281058995759, 3), FORMAT(-3.20266733458286, 3), FORMAT(0.00157649796773572, 3), FORMAT(-1822.75776328496, 3), FORMAT(-433.720317190985, 3), FORMAT(-1822.75776328496, 3), FORMAT(-433.720317190985, 3)
UNION ALL
SELECT 'MEAT', 					FORMAT(-445.089082120898, 3), FORMAT(359.44277474968, 3), FORMAT(-1.23827522317249, 3), FORMAT(0.217016508759085, 3), FORMAT(-1153.72705896603, 3), FORMAT(263.548894724233, 3), FORMAT(-1153.72705896603, 3), FORMAT(263.548894724233, 3)
UNION ALL
SELECT 'PREPARED_FOODS', 		FORMAT(-512.621735290065, 3), FORMAT(511.048730523491, 3), FORMAT(-1.00307799368754, 3), FORMAT(0.316994344585759, 3), FORMAT(-1520.14939729313, 3), FORMAT(494.905926712999, 3), FORMAT(-1520.14939729313, 3), FORMAT(494.905926712999, 3) 
UNION ALL
SELECT 'BREAD_AND_BAKERY', 	FORMAT(-1212.09467874811, 3), FORMAT(395.34646302573, 3), FORMAT(-3.06590495200464, 3), FORMAT(0.00245946459365056, 3), FORMAT(-1991.51643206207, 3), FORMAT(-432.672925434143, 3), FORMAT(-1991.51643206207, 3), FORMAT(-432.672925434143, 3) 
UNION ALL
SELECT 'DESSERTS', 				FORMAT(-609.896363792962, 3), FORMAT(397.500598729176, 3), FORMAT(-1.53432816388912, 3), FORMAT(0.126475922005137, 3), FORMAT(-1393.56497494905, 3), FORMAT(173.772247363124, 3), FORMAT(-1393.56497494905, 3), FORMAT(173.772247363124, 3) 
UNION ALL
SELECT 'FROZEN_FOODS', 			FORMAT(-1067.61009949039, 3), FORMAT(423.621456848355, 3), FORMAT(-2.52019835688485, 3), FORMAT(0.0124836312252087, 3), FORMAT(-1902.77573145577, 3), FORMAT(-232.444467525012, 3), FORMAT(-1902.77573145577, 3), FORMAT(-232.444467525012, 3) 
UNION ALL
SELECT 'SNACKS_AND_CHIPS', 	FORMAT(-500.435269034562, 3), FORMAT(378.179342809586, 3), FORMAT(-1.32327499782698, 3), FORMAT(0.187203690264923, 3), FORMAT(-1246.01220978637, 3), FORMAT(245.141671717242, 3), FORMAT(-1246.01220978637, 3), FORMAT(245.141671717242, 3) 
UNION ALL
SELECT 'caloriesperserving', 	FORMAT(-1.95715407644816, 3), FORMAT(0.87718840719732, 3), FORMAT(-2.23116728446219, 3), FORMAT(0.0267426839289791, 3), FORMAT(-3.6865225930951, 3), FORMAT(-0.227785559801228, 3), FORMAT(-3.6865225930951, 3), FORMAT(-0.227785559801228, 3) 
UNION ALL
SELECT 'organic', 				FORMAT(63.0458810227357, 3), FORMAT(184.118590910375, 3), FORMAT(0.342419962650188, 3), FORMAT(0.732382299323241, 3), FORMAT(-299.942151921221, 3), FORMAT(426.033913966693, 3), FORMAT(-299.942151921221, 3), FORMAT(426.033913966693, 3) 
UNION ALL
SELECT 'lowfat', 					FORMAT(-503.061547233353, 3), FORMAT(224.525403198941, 3), FORMAT(-2.24055514461147, 3), FORMAT(0.0261172639768965, 3), FORMAT(-945.711222370207, 3), FORMAT(-60.4118720964994, 3), FORMAT(-945.711222370207, 3), FORMAT(-60.4118720964994, 3) 
UNION ALL
SELECT 'lowsodium', 				FORMAT(-493.528615050561, 3), FORMAT(185.687050508866, 3), FORMAT(-2.65785155021888, 3), FORMAT(0.00847806488696315, 3), FORMAT(-859.608851022976, 3), FORMAT(-127.448379078146, 3), FORMAT(-859.608851022976, 3), FORMAT(-127.448379078146, 3) 
UNION ALL
SELECT 'sugarconscious', 		FORMAT(168.226132641079, 3), FORMAT(192.192941582845, 3), FORMAT(0.875298183458862, 3), FORMAT(0.382426178125587, 3), FORMAT(-210.680405074221, 3), FORMAT(547.132670356379, 3), FORMAT(-210.680405074221, 3), FORMAT(547.132670356379, 3) 
UNION ALL
SELECT 'glutenfree', 			FORMAT(210.308347034816, 3), FORMAT(204.934150536393, 3), FORMAT(1.02622401627233, 3), FORMAT(0.305983708961164, 3), FORMAT(-193.717361713179, 3), FORMAT(614.33405578281, 3), FORMAT(-193.717361713179, 3), FORMAT(614.33405578281, 3)
;