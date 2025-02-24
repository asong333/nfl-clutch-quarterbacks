-- Returns QBs ranked by EPA in 2-minute drills (pass and QB run plays), with minimum 70 plays under 2 min
-- (70 is avg num of 2 min drill QB plays by each team in each year, excluding garbage time. Essentially we are only showing QBs that played equivalent of 1 full NFL season)
-- Adjusting for garbage time by filtering out any plays in last 2 min of game where posteam is down by more than 1 possession, or winning
SELECT 
	(CASE
		WHEN play_type = 'pass' THEN passer_player_name
		WHEN play_type = 'run' THEN rusher_player_name
	END) AS quarterback,
	COUNT(passer_player_name) AS pass_att,
	COUNT(rusher_player_name) AS rush_att,
	COUNT(*) AS total_two_min_att, 
	ROUND(AVG(epa),
	2) AS two_min_avg_epa
FROM
	nfl_plays
WHERE 
	half_seconds_remaining <= 120
	AND 
		CASE
		WHEN game_half = 'Half2' THEN (posteam_score - defteam_score) > -8
		AND (posteam_score - defteam_score) < 1
		ELSE posteam_score IS NOT NULL
	END
	AND
	((play_type = 'run'
		AND qb_scramble IS TRUE)
	OR (play_type = 'pass'))
GROUP BY
	quarterback
HAVING
	COUNT(*) >= 70
ORDER BY
	two_min_avg_epa DESC;

-- RETURNS avg num of 2 min drill plays (pass or QB run) by each team in each year, excluding garbage time plays
SELECT
	AVG(num_plays)
FROM
	(
	SELECT
		date_part('year',
		game_date)AS YEAR,
		posteam,
		COUNT(*) AS num_plays
	FROM
		nfl_plays
	WHERE 
		half_seconds_remaining < 121
		AND 
			CASE
			WHEN game_half = 'Half2' THEN (posteam_score - defteam_score) > -8
				AND (posteam_score - defteam_score) < 1
				ELSE posteam_score IS NOT NULL
			END
				AND
		((play_type = 'run'
					AND qb_scramble IS TRUE)
				OR (play_type = 'pass'))
			GROUP BY
				YEAR,
				posteam
			ORDER BY
				YEAR ASC,
				posteam ASC
)

	-- Avg EPA for QB rushes only
SELECT 
	(CASE
		WHEN play_type = 'run' THEN rusher_player_name
	END) AS quarterback,
	COUNT(rusher_player_name) AS rush_att,
	ROUND(AVG(epa),
	2) AS two_min_rush_avg_epa
FROM
	nfl_plays
WHERE 
	half_seconds_remaining <= 120
	AND 
		CASE
		WHEN game_half = 'Half2' THEN (posteam_score - defteam_score) > -8
		AND (posteam_score - defteam_score) < 1
		ELSE posteam_score IS NOT NULL
	END
	AND
	(play_type = 'run'
		AND qb_scramble IS TRUE)
GROUP BY
	quarterback
HAVING
	COUNT(*) >= 1
ORDER BY
	two_min_rush_avg_epa DESC;
	
-- Most "clutch" QBs on the road (defined as 2 min drill at end of game, down 1 possession or less, on the road) 
-- with min 34 attempts (one year's worth of attempts, using same query above adjusted for away games)
SELECT 
	(CASE
		WHEN play_type = 'pass' THEN passer_player_name
		WHEN play_type = 'run' THEN rusher_player_name
	END) AS quarterback,
	COUNT(passer_player_name) AS pass_att,
	COUNT(rusher_player_name) AS rush_att,
	COUNT(*) AS total_endgame_att, 
	ROUND(AVG(epa),
	2) AS endgame_avg_epa
FROM
	nfl_plays
WHERE 
	half_seconds_remaining < 121
	AND game_half = 'Half2'
	AND(posteam_score - defteam_score) > -8
	AND (posteam_score - defteam_score) < 1
	AND ((play_type = 'run'
		AND qb_scramble IS TRUE)
	OR (play_type = 'pass'))
	AND posteam = away_team
GROUP BY
	quarterback
HAVING
	COUNT(*) > 34
ORDER BY
	endgame_avg_epa DESC;

-- Most "clutch" plays by X player
SELECT
	*
FROM
	nfl_plays
WHERE 
	half_seconds_remaining < 121
	AND game_half = 'Half2'
	AND(posteam_score - defteam_score) > -8
	AND (posteam_score - defteam_score) < 1
	AND ((play_type = 'run'
		AND qb_scramble IS TRUE)
	OR (play_type = 'pass'))
	AND posteam = away_team
	AND epa IS NOT NULL
ORDER BY
	epa ASC
LIMIT 100;
