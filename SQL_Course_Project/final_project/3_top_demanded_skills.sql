WITH SkillDemand AS (
    -- Aggregate demand count for each skill
    SELECT 
        s.skills,
        COUNT(sj.job_id) AS demand_count
    FROM 
        job_postings_fact jp
    INNER JOIN 
        skills_job_dim sj ON jp.job_id = sj.job_id
    INNER JOIN 
        skills_dim s ON sj.skill_id = s.skill_id
    WHERE 
        jp.job_title_short = 'Data Analyst'  -- Filter for Data Analyst roles
        AND jp.job_work_from_home = TRUE     -- Filter for remote jobs
    GROUP BY 
        s.skills
),
RankedSkills AS (
    -- Rank skills by their demand count
    SELECT 
        skills,
        demand_count,
        RANK() OVER (ORDER BY demand_count DESC) AS skill_rank
    FROM 
        SkillDemand
)
-- Select the top 5 skills by rank
SELECT 
    skills,
    demand_count
FROM 
    RankedSkills
WHERE 
    skill_rank <= 5  -- Limit results to top 5 ranked skills
ORDER BY 
    skill_rank;
