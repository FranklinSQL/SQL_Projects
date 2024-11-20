WITH SkillSalaries AS (
    -- Calculate the average salary for each skill
    SELECT 
        s.skills,
        ROUND(AVG(jp.salary_year_avg), 0) AS avg_salary
    FROM 
        job_postings_fact jp
    INNER JOIN 
        skills_job_dim sj ON jp.job_id = sj.job_id
    INNER JOIN 
        skills_dim s ON sj.skill_id = s.skill_id
    WHERE 
        jp.job_title_short = 'Data Analyst'  -- Filter for Data Analyst roles
        AND jp.salary_year_avg IS NOT NULL  -- Exclude jobs without salary data
        AND jp.job_work_from_home = TRUE    -- Filter for remote jobs
    GROUP BY 
        s.skills
),
RankedSkillSalaries AS (
    -- Rank skills by their average salary
    SELECT 
        skills,
        avg_salary,
        RANK() OVER (ORDER BY avg_salary DESC) AS salary_rank
    FROM 
        SkillSalaries
)
-- Select the top 25 skills by rank
SELECT 
    skills,
    avg_salary
FROM 
    RankedSkillSalaries
WHERE 
    salary_rank <= 25  -- Limit results to the top 25 skills
ORDER BY 
    salary_rank;
