WITH SkillMetrics AS (
    -- Aggregate demand count and average salary for each skill
    SELECT 
        s.skill_id,
        s.skills,
        COUNT(sj.job_id) AS demand_count,  -- Count of job postings requiring the skill
        ROUND(AVG(jp.salary_year_avg), 0) AS avg_salary  -- Average salary for jobs requiring the skill
    FROM 
        job_postings_fact jp
    INNER JOIN 
        skills_job_dim sj ON jp.job_id = sj.job_id
    INNER JOIN 
        skills_dim s ON sj.skill_id = s.skill_id
    WHERE 
        jp.job_title_short = 'Data Analyst'  -- Filter for Data Analyst roles
        AND jp.salary_year_avg IS NOT NULL  -- Ensure salary data is present
        AND jp.job_work_from_home = TRUE    -- Filter for remote jobs
    GROUP BY 
        s.skill_id, s.skills  -- Group by skill ID and skill name
    HAVING 
        COUNT(sj.job_id) > 10  -- Include only skills in demand (demand count > 10)
),
RankedSkills AS (
    -- Rank skills by average salary and then by demand count
    SELECT 
        skill_id,
        skills,
        demand_count,
        avg_salary,
        RANK() OVER (ORDER BY avg_salary DESC, demand_count DESC) AS skill_rank
    FROM 
        SkillMetrics
)
-- Select top 25 skills based on rank
SELECT 
    skill_id,
    skills,
    demand_count,
    avg_salary
FROM 
    RankedSkills
WHERE 
    skill_rank <= 25  -- Limit to top 25 ranked skills
ORDER BY 
    skill_rank;  -- Final output ordered by rank
