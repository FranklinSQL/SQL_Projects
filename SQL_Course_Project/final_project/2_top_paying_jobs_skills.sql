WITH RankedJobs AS (
    SELECT 
        j.job_id,
        j.job_title,
        j.salary_year_avg,
        c.name AS company_name,
        ROW_NUMBER() OVER (
            PARTITION BY j.job_title_short 
            ORDER BY j.salary_year_avg DESC
        ) AS rank
    FROM 
        job_postings_fact j
    LEFT JOIN 
        company_dim c ON j.company_id = c.company_id
    WHERE 
        j.job_title_short = 'Data Analyst' 
        AND j.job_location = 'Anywhere'
        AND j.salary_year_avg IS NOT NULL
)
SELECT 
    r.job_id,
    r.job_title,
    r.salary_year_avg,
    r.company_name,
    STRING_AGG(s.skills, ', ') AS associated_skills
FROM 
    RankedJobs r
INNER JOIN 
    skills_job_dim sj ON r.job_id = sj.job_id
INNER JOIN 
    skills_dim s ON sj.skill_id = s.skill_id
WHERE 
    r.rank <= 10
GROUP BY 
    r.job_id, r.job_title, r.salary_year_avg, r.company_name
ORDER BY 
    r.salary_year_avg DESC;
