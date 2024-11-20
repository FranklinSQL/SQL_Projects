WITH CompanyJobStats AS (
    SELECT 
        c.company_id,
        c.name AS company_name,
        COUNT(j.job_id) AS total_job_postings,
        COALESCE(AVG(j.salary_year_avg), 0) AS avg_salary_year,
        COALESCE(AVG(j.salary_hour_avg), 0) AS avg_salary_hour,
        ROUND(100.0 * SUM(CASE WHEN j.job_health_insurance THEN 1 ELSE 0 END) / NULLIF(COUNT(j.job_id), 0), 2) AS pct_with_health_insurance,
        ROUND(100.0 * SUM(CASE WHEN j.job_no_degree_mention THEN 1 ELSE 0 END) / NULLIF(COUNT(j.job_id), 0), 2) AS pct_no_degree_required
    FROM 
        public.company_dim c
    LEFT JOIN 
        public.job_postings_fact j ON c.company_id = j.company_id
    GROUP BY 
        c.company_id, c.name
),
RankedCompanies AS (
    SELECT 
        company_id,
        company_name,
        total_job_postings,
        avg_salary_year,
        avg_salary_hour,
        pct_with_health_insurance,
        pct_no_degree_required,
        RANK() OVER (ORDER BY total_job_postings DESC) AS company_rank
    FROM 
        CompanyJobStats
),
JobSkills AS (
    SELECT 
        j.job_id,
        j.company_id,
        COALESCE(STRING_AGG(s.skills, ', '), 'No skills listed') AS associated_skills
    FROM 
        public.job_postings_fact j
    LEFT JOIN 
        public.skills_job_dim sj ON j.job_id = sj.job_id
    LEFT JOIN 
        public.skills_dim s ON sj.skill_id = s.skill_id
    GROUP BY 
        j.job_id, j.company_id
)
SELECT 
    rc.company_rank,
    rc.company_name,
    rc.total_job_postings,
    rc.avg_salary_year,
    rc.avg_salary_hour,
    rc.pct_with_health_insurance,
    rc.pct_no_degree_required,
    j.job_id,
    j.job_title,
    j.job_location,
    j.job_posted_date,
    j.job_work_from_home,
    js.associated_skills
FROM 
    RankedCompanies rc
LEFT JOIN 
    public.job_postings_fact j ON rc.company_id = j.company_id
LEFT JOIN 
    JobSkills js ON j.job_id = js.job_id
ORDER BY 
    rc.company_rank, j.job_posted_date DESC;

